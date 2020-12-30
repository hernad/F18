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

FUNCTION pos_racun_unos_ispravka()


   IF !in_tekuca_godina()
      Alert(_u("Tekuća sezona: " + Alltrim(Str(tekuca_sezona())) + " <> " + Alltrim(Str(Year( danasnji_datum() ))) + " !?"))
      RETURN .F.
   ENDIF

   IF fetch_metric( "lock_POS", NIL, "N" ) == "D"
      Alert(_u("POS modul je zaključan!"))
      RETURN .F.
   ENDIF


   DO WHILE .T.
      // SetKXLat( "'", "-" )
      IF !o_pos_tables()
          Alert( "POS tabele se ne mogu otvoriti?!")
          RETURN .F.
      ENDIF
      
      SELECT _pos_pripr
      IF reccount2() <> 0
         IF AllTrim( field->brdok ) != POS_BRDOK_PRIPREMA
            GO TOP // ako je racun vracen u pripremu, inicijaliziraj brdok
            SET ORDER TO
            DO WHILE !Eof()
               RREPLACE brdok WITH POS_BRDOK_PRIPREMA
               SKIP
            ENDDO
            GO TOP
         ENDIF
      ENDIF

      // SET KEY "'" to
      my_close_all_dbf()
      pos_racun_sumarno_init()
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

   LOCAL lRet := .T.
   LOCAL hParam := hb_Hash()
   LOCAL cDokumentNaziv

   IF !pos_provjera_priprema()
      RETURN .F.
   ENDIF

   o_pos__pripr()
   my_dbf_pack()
   IF _pos_pripr->( RecCount2() ) == 0
      my_close_all_dbf()
      RETURN .F.
   ENDIF


   GO TOP
   hParam[ "idpos" ] := _pos_pripr->idpos
   hParam[ "idvd" ] := _pos_pripr->idvd
   hParam[ "datum" ] := _pos_pripr->datum
   hParam[ "brdok" ] := _pos_pripr->brdok
   hParam[ "idpartner" ] := Space( 6 )
   hParam[ "idvrstep" ] := "01"
   hParam[ "zakljuci" ] := "D"
   hParam[ "idpartner" ] := _pos_pripr->idpartner

   IF pos_form_zakljucenje_racuna( @hParam )

      o_pos_tables()
      hParam[ "idvd" ] := POS_IDVD_RACUN
      hParam[ "brdok" ] := pos_novi_broj_dokumenta( hParam[ "idpos" ], POS_IDVD_RACUN, hParam[ "datum" ] )
      hParam[ "vrijeme" ] := PadR( Time(), 5 )
      hParam[ "datum" ] := danasnji_datum()
      hParam[ "idpartner" ] := ""

      cDokumentNaziv := pos_dokument_sa_vrijeme( hParam )
      IF seek_pos_doks( hParam[ "idpos" ], hParam[ "idvd" ], hParam[ "datum" ], hParam[ "brdok" ] ) ;
            .OR. seek_pos_pos( hParam[ "idpos" ], hParam[ "idvd" ], hParam[ "datum" ], hParam[ "brdok" ] )
         MsgBeep( "Dokument: " + cDokumentNaziv + " već postoji?!" )
         RETURN .F.
      ENDIF

      IF !pos_azuriraj_racun( hParam )
         MsgBeep( "Greška sa ažuriranjem: " + pos_dokument( hParam ) )
         RETURN .F.
      ENDIF

      pos_racun_info( hParam )
      my_close_all_dbf()
   ELSE
      lRet := .F.
   ENDIF
   my_close_all_dbf()

   RETURN lRet


STATIC FUNCTION ispisi_iznos_i_kusur_za_kupca( nUplaceno, nIznosRacuna, nX, nY )

   LOCAL nVratiti := nUplaceno - nIznosRacuna

   IF nUplaceno <> 0
      @ nX, nY + 28 SAY "Iznos RN: " + AllTrim( Str( nIznosRacuna, 12, 2 ) ) + ;
         " vratiti: " + AllTrim( Str( nVratiti, 12, 2 ) ) ;
         COLOR "BR+/B"
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_form_zakljucenje_racuna( hParams )

   LOCAL lUnesiKupca := .F.
   LOCAL nX, nY
   LOCAL cIdVd := hParams[ "idvd" ]
   LOCAL cIdPos := hParams[ "idpos" ]
   LOCAL cBrDok := hParams[ "brdok" ]
   LOCAL dDatum := hParams[ "datum" ]
   LOCAL cIdVrsteP := hParams[ "idvrstep" ]
   LOCAL cIdPartner := hParams[ "idpartner" ]
   LOCAL nUplaceno := 0
   LOCAL cAzuriratiDN := "D"
   LOCAL GetList := {}
   LOCAL cFiskalniIzdatDN := " "
   LOCAL nFiskalniBroj := 0

   Box(, 10, 67 )

   set_cursor_on()
   // 01 - gotovina
   // KT - kartica
   // VR - virman
   // CK - cek
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "ZAKLJUČENJE RAČUNA" COLOR "BG+/B"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Način plaćanja (01/KT):" GET cIdVrsteP PICT "@!" VALID p_vrstep( @cIdVrsteP )

   READ

   IF cIdVrsteP <> POS_IDVRSTEP_GOTOVINSKO_PLACANJE
      lUnesiKupca := .T.
   ENDIF

   IF lUnesiKupca
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kupac:" GET cIdPartner PICT "@!" VALID p_partner( @cIdPartner )
   ELSE
      cIdPartner := Space( FIELD_LEN_PARTNER_ID )
   ENDIF

   @ nX := box_x_koord() + 5, nY := box_y_koord() + 2 SAY8 "Primljeni novac:" GET nUplaceno PICT "9999999.99" ;
      VALID {|| pos_valid_primljeni_novac( nUplaceno, nX, nY ) }

   SELECT _pos_pripr
   GO TOP
   IF !Empty(_pos_pripr->opis)
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Zahtjev za štampu na fiskalni printer je već ranije upućen. Da li"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "je kupac dobio fiskalni račun D/N ?" GET cFiskalniIzdatDN  PICT "@!" VALID cFiskalniIzdatDN $ "DN"
      @ box_x_koord() + 8, col() + 2 SAY8 "Broj fiskalnog: " GET nFiskalniBroj ;
         WHEN { || IIF(cFiskalniIzdatDN == "D", .T., .F.) } VALID nFiskalniBroj > 0
   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Ažurirati POS račun (D/N) ?" GET cAzuriratiDN PICT "@!" VALID cAzuriratiDN $ "DN"
   READ

   BoxC()

   IF LastKey() == K_ESC .OR. cAzuriratiDN == "N"
      RETURN .F.
   ENDIF

   hParams[ "zakljuci" ] := "D"
   hParams[ "idpartner" ] := cIdPartner
   hParams[ "idvrstep" ] := cIdVrsteP
   hParams[ "uplaceno" ] := nUplaceno
   hParams[ "fiskalni_izdat" ] := (cFiskalniIzdatDN == "D")
   hParams[ "fiskalni_broj" ] := nFiskalniBroj

   RETURN .T.


STATIC FUNCTION pos_valid_primljeni_novac( nUplaceno, nX, nY )

   IF nUplaceno <> 0
      ispisi_iznos_i_kusur_za_kupca( nUplaceno, koliko_treba_povrata_kupcu(), nX, nY )
   ENDIF

   RETURN .T.


STATIC FUNCTION koliko_treba_povrata_kupcu()

   LOCAL nDbfArea := Select()
   LOCAL nTrec := RecNo()

   LOCAL nIznos := 0
   LOCAL nPopust := 0
   LOCAL nIznosNeto

   SELECT _pos_pripr
   GO TOP
   DO WHILE !Eof() .AND. AllTrim( _pos_pripr->brdok ) == POS_BRDOK_PRIPREMA
      nIznos += _pos_pripr->kolicina * _pos_pripr->cijena
      nPopust += _pos_pripr->kolicina * pos_popust( _pos_pripr->cijena, _pos_pripr->ncijena )
      SKIP
   ENDDO

   nIznosNeto := nIznos - nPopust
   SELECT ( nDbfArea )
   GO ( nTrec )

   RETURN nIznosNeto
