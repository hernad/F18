/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION pos_unos_ispravka_racuna()

   LOCAL lRet
   LOCAL lNoviRacun := .T.

   SetKXLat( "'", "-" )

   o_pos_tables()

   SELECT _pos_pripr

   IF reccount2() <> 0 .AND. AllTrim( field->brdok ) == POS_BRDOK_PRIPREMA
      lNoviRacun := .F.
   ENDIF

   unos_stavki_racuna( lNoviRacun )

   SET KEY "'" to

   my_close_all_dbf()

   RETURN lRet



STATIC FUNCTION unos_stavki_racuna( lNovi )

   LOCAL cBrojRacuna

   SELECT _pos_pripr
   GO TOP

   IF lNovi
      cBrojRacuna := PadR( POS_BRDOK_PRIPREMA, FIELD_LEN_POS_BRDOK )
   ELSE
      cBrojRacuna := _pos_pripr->brdok
   ENDIF

altd()
   pos_unos_racuna( cBrojRacuna )

   RETURN .T.



FUNCTION zakljuci_pos_racun()

   LOCAL lRet := .F.
   LOCAL lOtvoriUnos := fetch_metric( "pos_konstantni_unos_racuna", my_user(), "N" ) == "D"
   LOCAL hParam := hb_Hash()

   O__POS_PRIPR
   my_dbf_pack()

   IF _pos_pripr->( RecCount2() ) == 0
      my_close_all_dbf()
      RETURN lRet
   ENDIF

   GO TOP

   hParam[ "idpos" ] := _pos_pripr->idpos
   hParam[ "idvd" ] := _pos_pripr->idvd
   hParam[ "datum" ] := _pos_pripr->datum
   hParam[ "brdok" ] := _pos_pripr->brdok
   hParam[ "idpartner" ] := Space( 6 )
   hParam[ "idvrstap" ] := "01"
   hParam[ "zakljuci" ] := "D"
   hParam[ "uplaceno" ] := 0

   form_zakljuci_racun( @hParam )

   IF hParam[ "zakljuci" ] == "D"
      lRet := azuriraj_stavke_racuna_i_napravi_fiskalni_racun( hParam )
   ENDIF

   my_close_all_dbf()

   IF lOtvoriUnos .AND. lRet
      pos_unos_ispravka_racuna()
      lRet := zakljuci_pos_racun()
   ENDIF

   RETURN lRet



STATIC FUNCTION azuriraj_stavke_racuna_i_napravi_fiskalni_racun( hParams )

   LOCAL _br_dok := hParams[ "brdok" ]
   LOCAL _id_pos := hParams[ "idpos" ]
   LOCAL _id_vrsta_p := hParams[ "idvrstap" ]
   LOCAL _id_partner := hParams[ "idpartner" ]
   LOCAL _uplaceno := hParams[ "uplaceno" ]
   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL cVrijemeRacuna
   LOCAL cBrojRacuna

   o_pos_tables()

   IF ( Len( aRabat ) > 0 )
      ReCalcRabat( _id_vrsta_p )
   ENDIF

   SELECT pos_doks

   cBrojRacuna := pos_novi_broj_dokumenta( _id_pos, POS_VD_RACUN )

   cVrijemeRacuna := PadR( Time(), 5 )

   lOk := pos_azuriraj_racun( _id_pos, cBrojRacuna, cVrijemeRacuna, _id_vrsta_p, _id_partner )

   IF !lOk
      MsgBeep( "Greška sa ažuriranjem računa u kumulativ !" )
      RETURN lRet
   ENDIF

   pos_racun_info( cBrojRacuna )


   IF fiscal_opt_active()
      pos_stampa_fiskalni_racun( _id_pos, danasnji_datum(), cBrojRacuna, _uplaceno )
   ENDIF

   my_close_all_dbf()

   RETURN lOk


STATIC FUNCTION pos_racun_info( cBrRn )

   info_bar( "pos", "POS račun broj: " + cBrRN )

   RETURN .T.


STATIC FUNCTION pos_stampa_fiskalni_racun( cIdPos, dDatum, cBrRn, nUplaceno )

   LOCAL nDeviceId
   LOCAL hDeviceParams
   LOCAL lRet := .F.
   LOCAL nError := 0

   nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )
   IF nDeviceId > 0
      hDeviceParams := get_fiscal_device_params( nDeviceId, my_user() )
      IF hDeviceParams == NIL
         RETURN lRet
      ENDIF
   ELSE
      RETURN lRet
   ENDIF

   nError := pos_fiskalni_racun( cIdPos, dDatum, cBrRn, hDeviceParams, nUplaceno )

   IF nError = -20
      IF Pitanje(, "Da li je nestalo trake u fiskalnom uređaju (D/N)?", "N" ) == "N"
         nError := 20
      ENDIF
   ENDIF

   IF nError > 0
      MsgBeep( "Greška pri štampi fiskalog računa " + cBrRn + " !?##Račun se iz tog razloga BRIŠE" )
      pos_povrat_rn( cBrRn, dDatum )
   ENDIF

   lRet := .T.

   RETURN lRet



STATIC FUNCTION koliko_treba_povrata_kupcu( hParams )

   LOCAL nDbfArea := Select()
   LOCAL nTrec := RecNo()
   LOCAL _id_pos := hParams[ "idpos" ]
   LOCAL _id_vd := hParams[ "idvd" ]
   LOCAL _br_dok := hParams[ "brdok" ]
   LOCAL _dat_dok := hParams[ "datum" ]
   LOCAL _total := 0
   LOCAL _iznos := 0
   LOCAL _popust := 0

   SELECT _pos_pripr
   GO TOP
   DO WHILE !Eof() .AND. AllTrim( field->brdok ) == POS_BRDOK_PRIPREMA
      _iznos += field->kolicina * field->cijena
      _popust += field->kolicina * field->ncijena
      SKIP
   ENDDO

   _total := ( _iznos - _popust )

   SELECT ( nDbfArea )
   GO ( nTrec )

   RETURN _total


STATIC FUNCTION ispisi_iznos_i_kusur_za_kupca( uplaceno, iznos_rn, pos_x, pos_y )

   LOCAL _vratiti := uplaceno - iznos_rn

   IF uplaceno <> 0
      @ pos_x, pos_y + 28 SAY "Iznos RN: " + AllTrim( Str( iznos_rn, 12, 2 ) ) + ;
         " vratiti: " + AllTrim( Str( _vratiti, 12, 2 ) ) ;
         COLOR "BR+/B"
   ENDIF

   RETURN .T.



STATIC FUNCTION form_zakljuci_racun( hParams )

   LOCAL _def_partner := .F.
   LOCAL _id_vd := hParams[ "idvd" ]
   LOCAL _id_pos := hParams[ "idpos" ]
   LOCAL _br_dok := hParams[ "brdok" ]
   LOCAL _dat_dok := hParams[ "datum" ]
   LOCAL _ok := hParams[ "zakljuci" ]
   LOCAL _id_vrsta_p := hParams[ "idvrstap" ]
   LOCAL _id_partner := hParams[ "idpartner" ]
   LOCAL _uplaceno := hParams[ "uplaceno" ]
   LOCAL GetList := {}

   _id_vrsta_p := gGotPlac


   Box(, 8, 67 )

   SET CURSOR ON

   // 01 - gotovina
   // KT - kartica
   // VR - virman
   // CK - cek

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "FORMA ZAKLJUČENJA RAČUNA" COLOR "BG+/B"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Način plaćanja (01/KT/VR...):" GET _id_vrsta_p PICT "@!" VALID p_vrstep( @_id_vrsta_p )

   READ

   IF _id_vrsta_p <> gGotPlac
      _def_partner := .T.
   ENDIF

   IF _def_partner
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kupac:" GET _id_partner PICT "@!" VALID p_partner( @_id_partner )
   ELSE
      _id_partner := Space( 6 )
   ENDIF

   @ _x_pos := box_x_koord() + 5, _y_pos := box_y_koord() + 2 SAY8 "Kupac uplatio:" GET _uplaceno PICT "9999999.99" ;
      VALID {|| IF ( _uplaceno <> 0, ispisi_iznos_i_kusur_za_kupca( _uplaceno, koliko_treba_povrata_kupcu( hParams ), _x_pos, _y_pos ), .T. ), .T. }

   @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Ažurirati POS račun (D/N) ?" GET _ok PICT "@!" VALID _ok $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ok := "D"
   ENDIF

   hParams[ "zakljuci" ] := _ok
   hParams[ "idpartner" ] := _id_partner
   hParams[ "idvrstap" ] := _id_vrsta_p
   hParams[ "uplaceno" ] := _uplaceno

   RETURN .T.



FUNCTION pos_racun_obiljezen()

   IF AScan ( aVezani, {| x | x[ 1 ] + DToS( x[ 4 ] ) + x[ 2 ] == pos_doks->( IdPos + DToS( datum ) + BrDok ) } ) > 0
      RETURN .T.
   ENDIF

   RETURN .F.



FUNCTION StrValuta( cNaz2, dDat )

   LOCAL nTekSel

   nTekSel := Select()
   SELECT valute
   SET ORDER TO TAG "NAZ2"
   cNaz2 := PadR( cNaz2, 4 )
   SEEK PadR( cNaz2, 4 ) + DToS( dDat ) // valute
   IF valute->naz2 <> cnaz2
      SKIP -1
   ENDIF
   SELECT ( nTekSel )
   IF valute->naz2 <> cnaz2
      RETURN 0
   ELSE
      RETURN valute->kurs1
   ENDIF
