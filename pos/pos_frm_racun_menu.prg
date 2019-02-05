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

   LOCAL lStalnoUnos := fetch_metric( "pos_konstantni_unos_racuna", my_user(), "N" ) == "D"

   DO WHILE .T.

      //SetKXLat( "'", "-" )
      o_pos_tables()
      SELECT _pos_pripr
      IF reccount2() <> 0
         IF AllTrim( field->brdok ) != POS_BRDOK_PRIPREMA
            GO TOP // ako je racun vracen u pripremu, inicijaliziraj brdok
            DO WHILE !Eof()
               RREPLACE brdok WITH POS_BRDOK_PRIPREMA
            ENDDO
            GO TOP
         ENDIF
      ENDIF

      //SET KEY "'" to
      my_close_all_dbf()

      IF pos_racun_unos_browse( POS_BRDOK_PRIPREMA )
         IF !pos_zakljuci_racun()
            EXIT
         ENDIF
      ELSE
         EXIT
      ENDIF


   ENDDO

   RETURN .T.


FUNCTION pos_zakljuci_racun()

   LOCAL lRet

   LOCAL hParam := hb_Hash()

   o_pos__pripr()
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
   hParam[ "idvrstep" ] := "01"
   hParam[ "zakljuci" ] := "D"
   hParam[ "uplaceno" ] := 0
   hParam[ "idpartner" ] := _pos_pripr->idpartner

   IF pos_form_zakljucenje_racuna( @hParam )
      lRet := azuriraj_stavke_racuna_i_napravi_fiskalni_racun( hParam )
   ELSE
      lRet := .F.
   ENDIF

   my_close_all_dbf()

   RETURN lRet


STATIC FUNCTION azuriraj_stavke_racuna_i_napravi_fiskalni_racun( hParams )

   LOCAL lOk := .T.
   LOCAL cVrijeme
   LOCAL cBrDok

   o_pos_tables()

   SELECT pos_doks

   cBrDok := pos_novi_broj_dokumenta( hParams[ "idpos" ], POS_IDVD_RACUN )
   cVrijeme := PadR( Time(), 5 )

   lOk := pos_azuriraj_racun( hParams[ "idpos" ], cBrDok, cVrijeme, hParams[ "idvrstep" ], hParams[ "idpartner" ] )

   IF !lOk
      MsgBeep( "Greška sa ažuriranjem računa u kumulativ !" )
      RETURN .F.
   ENDIF

   pos_racun_info( cBrDok )

   IF fiscal_opt_active()
      pos_stampa_fiskalni_racun( hParams )
   ENDIF
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_racun_info( cBrRn )

   info_bar( "pos", "POS račun broj: " + cBrRN )

   RETURN .T.


STATIC FUNCTION pos_stampa_fiskalni_racun( hParams )

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

   nError := pos_fiskalni_racun( hParams[ "idpos" ], hParams[ "datum" ], hParams[ "brdok" ], hDeviceParams, hParams[ "uplaceno" ] )
   IF nError == -20
      IF Pitanje(, "Da li je nestalo trake u fiskalnom uređaju (D/N)?", "N" ) == "N"
         nError := 20
      ENDIF
   ENDIF
   IF nError > 0
      MsgBeep( "Greška pri štampi fiskalog računa " + hParams[ "brdok" ] + " !?##Račun se iz tog razloga BRIŠE" )
      pos_povrat_racuna( hParams[ "idpos" ], hParams[ "brdok" ], hParams[ "datum" ] )
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



STATIC FUNCTION pos_form_zakljucenje_racuna( hParams )

   LOCAL lUnesiKupca := .F.
   LOCAL _id_vd := hParams[ "idvd" ]
   LOCAL _id_pos := hParams[ "idpos" ]
   LOCAL _br_dok := hParams[ "brdok" ]
   LOCAL _dat_dok := hParams[ "datum" ]
   LOCAL cIdVrsteP := hParams[ "idvrstep" ]
   LOCAL cIdPartner := hParams[ "idpartner" ]
   LOCAL nUplaceno := hParams[ "uplaceno" ]
   LOCAL cAzuriratiDN := "D"
   LOCAL GetList := {}

   Box(, 8, 67 )

   SET CURSOR ON

   // 01 - gotovina
   // KT - kartica
   // VR - virman
   // CK - cek
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "ZAKLJUČENJE RAČUNA" COLOR "BG+/B"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Način plaćanja (01/KT/VR...):" GET cIdVrsteP PICT "@!" VALID p_vrstep( @cIdVrsteP )

   READ

   IF cIdVrsteP <> gGotPlac
      lUnesiKupca := .T.
   ENDIF

   IF lUnesiKupca
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kupac:" GET cIdPartner PICT "@!" VALID p_partner( @cIdPartner )
   ELSE
      cIdPartner := Space( FIELD_LEN_PARTNER_ID )
   ENDIF

   @ nX := box_x_koord() + 5, nY := box_y_koord() + 2 SAY8 "Primljeni novac:" GET nUplaceno PICT "9999999.99" ;
      VALID {|| IIF ( nUplaceno <> 0, ispisi_iznos_i_kusur_za_kupca( nUplaceno, koliko_treba_povrata_kupcu( hParams ), nX, nY ), .T. ), .T. }

   @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Ažurirati POS račun (D/N) ?" GET cAzuriratiDN PICT "@!" VALID cAzuriratiDN $ "DN"
   READ

   BoxC()

   IF LastKey() == K_ESC .OR. cAzuriratiDN == "N"
      RETURN .F.
   ENDIF

   hParams[ "zakljuci" ] := "D"
   hParams[ "idpartner" ] := cIdPartner
   hParams[ "idvrstep" ] := cIdVrsteP
   hParams[ "uplaceno" ] := nUplaceno

   RETURN .T.
