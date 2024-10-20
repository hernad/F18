/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR M

STATIC picdem := "9999999999.99"

/*
   cVarijantaKamatnogRacuna: Z - zatezne kamate
*/

FUNCTION fin_kamate_obracun_sa_kamatni_list( cIdPartner, lPrintKamatniList, cVarijantaKamatnogRacuna )

   LOCAL nKamataUkupnoBrDok := 0, nKamataUkupnoNaDan
   LOCAL cTxtPdv
   LOCAL cTxtUkupno
   LOCAL hParams := hb_Hash()
   LOCAL nOstatakRacuna
   LOCAL hRec
   LOCAL nOsnDug, nKamataUkupno
   LOCAL nGlavn, dDatOd, dDatDo
   LOCAL lPrvaStavkaZaBrDok
   LOCAL nGlavnicaZaBrDok
   LOCAL i, cM1, nCol1
   LOCAL cBrDok

   IF lPrintKamatniList == NIL
      lPrintKamatniList := .T.
   ENDIF

   nGlavn := 2892359.28
   dDatOd := CToD( "01.02.92" )
   dDatDo := CToD( "30.09.96" )

   O_KS
   SELECT ks
   SET ORDER TO TAG "2"

   nStr := 0

   IF lPrintKamatniList

      nPdvTotal := nKamate * ( 17 / 100 )

      cTxtPdv := "PDV (17%)"
      cTxtPdv += " "
      cTxtPdv += Replicate( ".", 44 )
      cTxtPdv += Str( nPdvTotal, 12, 2 )
      cTxtPdv += " KM"

      cTxtUkupno := "Ukupno sa PDV"
      cTxtUkupno += " "
      cTxtUkupno += Replicate( ".", 40 )
      cTxtUkupno += Str( nKamate + nPdvTotal, 12, 2 )
      cTxtUkupno += " KM"

      ?
      P_10CPI
      ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
      ?

      select_o_partner( cIdPartner )

      cPom := Trim( partn->adresa )

      IF !Empty( partn->telefon )
         cPom += ", TEL:" + partn->telefon
      ENDIF

      cPom := PadR( cPom, 42 )
      dDatPom := fin_kam_datum_obracuna()

   ENDIF

   SELECT kam_pripr
   SEEK cIdPartner // kam_pripr

   IF lPrintKamatniList

      IF PRow() > 40
         FF
         ?
         P_10CPI
         ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
         ?
      ENDIF

      P_10CPI
      B_ON
      select_o_partner( cIdPartner )
      hRec := dbf_get_rec()
      SELECT kam_pripr

      ? PadC( "KAMATNI LIST KUPAC: " + AllTrim( hRec[ "id" ] + " - " + AllTrim( hRec[ "naz" ] ) ) + " " + DToC( fin_kam_datum_obracuna() ), 80 )
      B_OFF

      IF fin_kam_prikaz_kumulativ() == "N"
         P_12CPI
      ELSE
         P_COND
      ENDIF

      ?
      ?
      ?

      IF cVarijantaKamatnogRacuna == "Z"
         m := " ---------- -------- -------- --- ------------- ------------- -------- ------- -------------" + iif( fin_kam_prikaz_kumulativ() == "D", " -------------", "" )
      ELSE
         m := " ---------- -------- -------- --- ------------- ------------- -------- -------------" + iif( fin_kam_prikaz_kumulativ() == "D", " -------------", "" )
      ENDIF

      NStrana( "1" )

   ENDIF

   nKamataUkupno := 0
   nOstatakRacuna := 0
   SELECT kam_pripr
   cIdPartner := field->idpartner

   // IF !lPrintKamatniList
   nOsnDug := kam_pripr->osndug
   // ENDIF

   DO WHILE !Eof() .AND. field->idpartner == cIdPartner

      fStampajBr := .T.
      lPrvaStavkaZaBrDok := .T.

      // nKamataZaBrDok := 0
      nKamataUkupnoBrDok := 0
      cBrDok := field->brdok
      cM1 := field->m1
      nOstatakRacuna := kam_pripr->osnovica

      DO WHILE !Eof() .AND. field->idpartner == cIdpartner .AND. field->brdok == cBrDok

         dDatOd := kam_pripr->datod
         dDatdo := kam_pripr->datdo
         nOstatakRacuna := kam_pripr->osnovica

         IF lPrvaStavkaZaBrDok
            nGlavnicaZaBrDok := kam_pripr->osnovica
            lPrvaStavkaZaBrDok := .F.
         ELSE

            IF cVarijantaKamatnogRacuna == "Z"
               nGlavnicaZaBrDok := kam_pripr->osnovica + nKamataUkupnoBrDok
            ELSE
               nGlavnicaZaBrDok := kam_pripr->osnovica
            ENDIF
         ENDIF

         nGlavn := nGlavnicaZaBrDok

         SELECT ks
         SEEK DToS( dDatOd )

         IF dDatOd < field->DatOd .OR. Eof()
            SKIP -1
         ENDIF

         DO WHILE .T.

            dDDatDo := Min( field->DatDO, dDatDo )
            nPeriod := dDDatDo - dDatOd + 1

            IF ( cVarijantaKamatnogRacuna == "P" )
               IF ( Prestupna( Year( dDatOd ) ) )
                  nExp := 366
               ELSE
                  nExp := 365
               ENDIF
            ELSE
               IF field->tip == "G"
                  IF field->duz == 0
                     nExp := 365
                  ELSE
                     nExp := field->duz
                  ENDIF
               ELSEIF field->tip == "M"
                  IF field->duz == 0
                     dExp := "01."
                     IF Month( ddDatdo ) == 12
                        dExp += "01." + AllTrim( Str( Year( dDDatdo ) + 1 ) )
                     ELSE
                        dExp += AllTrim( Str( Month( dDDatdo ) + 1 ) ) + "." + AllTrim( Str( Year( dDDatdo ) ) )
                     ENDIF
                     nExp := Day( CToD( dExp ) - 1 )
                  ELSE
                     nExp := field->duz
                  ENDIF
               ELSEIF field->tip == "3"
                  nExp := field->duz
               ELSE
                  nExp := field->duz
               ENDIF
            ENDIF

            IF field->den <> 0 .AND. dDatOd == field->datod
               IF lPrintKamatniList
                  ? "********* Izvrsena Denominacija osnovice sa koeficijentom:", den, "****"
               ENDIF
               nOstatakRacuna := Round( nOstatakRacuna * field->den, 2 )
               nGlavn := Round( nGlavn * field->den, 2 )
               nKamataUkupnoBrDok := Round( nKamataUkupnoBrDok * field->den, 2 )
            ENDIF

            IF ( cVarijantaKamatnogRacuna == "Z" )
               nKKam := ( ( 1 + field->stkam / 100 ) ^ ( nPeriod / nExp ) - 1.00000 )
               nIznKam := nKKam * nGlavn
            ELSE
               nKStopa := field->stkam / 100
               // cPom777 := my_get_from_ini( "KAM", "FormulaZaProstuKamatu", "nGlavn*nKStopa*nPeriod/nExp", KUMPATH )
               // nIznKam := &( cPom777 )
               nIznKam := nGlavn * nKStopa * nPeriod / nExp

            ENDIF

            nIznKam := Round( nIznKam, 2 )

            IF lPrintKamatniList

               IF PRow() > 55
                  FF
                  Nstrana()
               ENDIF

               IF fStampajbr
                  ? " " + cBrdok + " "
                  fStampajBr := .F.
               ELSE
                  ? " " + Space( 10 ) + " "
               ENDIF

               ?? dDatOd, dDDatDo

               @ PRow(), PCol() + 1 SAY nPeriod PICT "999"
               @ PRow(), PCol() + 1 SAY nOstatakRacuna PICT picdem
               @ PRow(), PCol() + 1 SAY nGlavn PICT picdem

               IF ( cVarijantaKamatnogRacuna == "Z" )
                  @ PRow(), PCol() + 1 SAY field->tip
                  @ PRow(), PCol() + 1 SAY field->stkam PICT "999.99"
                  @ PRow(), PCol() + 1 SAY nKKam * 100 PICT "9999.99"
               ELSE
                  @ PRow(), PCol() + 1 SAY field->stkam PICT "999.99"
               ENDIF

               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY nIznKam PICT picdem

            ENDIF

            IF ( cVarijantaKamatnogRacuna == "Z" )
               nGlavnicaZaBrDok += nIznKam
            ENDIF

            // nKamataZaBrDok += nIznKam
            nKamataUkupnoBrDok += nIznKam

            IF ( cVarijantaKamatnogRacuna == "Z" )
               nGlavn += nIznKam
            ENDIF

            IF lPrintKamatniList .AND. fin_kam_prikaz_kumulativ() == "D"
               @ PRow(), PCol() + 1 SAY nKamataUkupnoBrDok PICT picdem
            ENDIF

            IF dDatDo <= field->DatDo
               SELECT kam_pripr
               EXIT
            ENDIF

            SKIP

            IF Eof()
               error_bar( "KAM_OBR", "PARTNER: " + kam_pripr->idpartner + ", BR.DOK.: " + kam_pripr->brdok + ;
                  "#GRESKA : Fali datumski interval u kam.stopama!" )
               EXIT
            ENDIF

            dDatOd := field->DatOd

         ENDDO

         SELECT kam_pripr
         SKIP

      ENDDO

      nKamataUkupnoNaDan := fin_kam_iznos_na_dan( nKamataUkupnoBrDok, fin_kam_datum_obracuna(), iif( Empty( cM1 ), KS->datdo, KS2->datdo ), cM1 )

      IF lPrintKamatniList
         IF PRow() > 59
            FF
            Nstrana()
         ENDIF
         ? m
         ? " UKUPNO ZA", cBrdok
         @ PRow(), nCol1 SAY nKamataUkupnoBrDok  PICT picdem

         ? " UKUPNO NA DAN", fin_kam_datum_obracuna(), ":"
         @ PRow(), nCol1 SAY nKamataUkupnoNaDan PICT picdem
         ? m
      ENDIF

      nKamataUkupno += nKamataUkupnoBrDok

      SELECT kam_pripr

   ENDDO

   IF lPrintKamatniList

      IF PRow() > 54
         FF
         NStrana()
      ENDIF

      ? m
      ? " SVEUKUPNO KAMATA NA DAN " + DToC( fin_kam_datum_obracuna() ) + ":"
      @ PRow(), PCol() SAY nOsnDug PICT picdem
      @ PRow(), nCol1  SAY nKamataUkupno PICT picdem
      ? m

      P_10CPI

      IF PRow() < 62 + dodatni_redovi_po_stranici()
         FOR i := 1 TO 62 + dodatni_redovi_po_stranici() - PRow()
            ?
         NEXT
      ENDIF

      _potpis()

      FF


      select_o_partner( PadR( self_organizacija_id(), 6 ) )
      hRec := dbf_get_rec( .T. )
      hParams[ "naziv" ] := hRec[ "naz" ]
      hParams[ "adresa" ] := hRec[ "adresa" ]
      hParams[ "tel" ] := hRec[ "telefon" ]
      hParams[ "fax" ] := hRec[ "fax" ]
      hParams[ "idbr" ] := get_partn_idbr( PadR( self_organizacija_id(), 6 ) )
      hParams[ "mjesto" ] := hRec[ "mjesto" ]
      hParams[ "ptt" ] := hRec[ "ptt" ]
      hParams[ "ziror" ] := hRec[ "ziror" ]
      hParams[ "datum" ] := fin_kam_datum_obracuna()

      select_o_partner( cIdPartner )
      hRec := dbf_get_rec( .T. )
      hParams[ "kupac_1" ] := hRec[ "id" ] + " - " + hRec[ "naz" ]
      hParams[ "kupac_2" ] := hRec[ "ptt" ] + " " + hRec[ "mjesto" ]
      hParams[ "kupac_3" ] := hRec[ "adresa" ]
      hParams[ "kupac_idbr" ] := get_partn_idbr( cIdPartner )

      hParams[ "osndug" ] := nOsnDug
      hParams[ "kamate" ] := nKamataUkupno

      print_opomena_pred_tuzbu( hParams )


      IF PRow() < 62 + dodatni_redovi_po_stranici()
         FOR i := 1 TO 62 + dodatni_redovi_po_stranici() - PRow()
            ?
         NEXT
      ENDIF

      _potpis()
      SELECT kam_pripr
   ENDIF

   // IF !lPrintKamatniList
   nKamate := nKamataUkupno
   // ENDIF

   RETURN nKamataUkupno



STATIC FUNCTION _potpis()

   ?  PadC( "     Obradio:                                 Direktor:    ", 80 )
   ?
   ?  PadC( "_____________________                    __________________", 80 )
   ?

   RETURN .T.



STATIC FUNCTION NStrana( cTip, cVarijantaKamatnogRacuna )

   IF cTip == NIL
      cTip := ""
   ENDIF

   IF cTip == ""
      ?
      P_10CPI
      ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
      ?
   ENDIF

   IF cTip == "1" .OR. cTip = ""

      IF fin_kam_prikaz_kumulativ() == "N"
         P_12CPI
      ELSE
         P_COND
      ENDIF

      ? m

      IF cVarijantaKamatnogRacuna == "Z"
         ? "   Broj          Period      dana     ostatak       kamatna   Tip kam  Konform.    Iznos    " + iif( fin_kam_prikaz_kumulativ() == "D", "   kumulativ   ", "" )
         ? "  racuna                              racuna       osnovica   i stopa   koef       kamate   " + iif( fin_kam_prikaz_kumulativ() == "D", "    kamate     ", "" )

      ELSE
         ? "   Broj          Period      dana     ostatak       kamatna    Stopa       Iznos    " + iif( fin_kam_prikaz_kumulativ() == "D", "   kumulativ   ", "" )
         ? "  racuna                              racuna       osnovica                kamate   " + iif( fin_kam_prikaz_kumulativ() == "D", "    kamate     ", "" )
      ENDIF

      ? m

   ENDIF

   RETURN .T.



FUNCTION fin_kam_iznos_na_dan( nIznos, dTrazeni, dProsli, cM1 )

   // * dtrazeni = 30.06.98
   // * dprosli  = 15.05.94
   // * znaci: uracunati sve denominacije od 15.05.94 do 30.06.98
   LOCAL nK := 1

   PushWA()
   SELECT KS
   GO TOP
   DO WHILE !Eof()
      IF DToS( dTrazeni ) < DToS( field->DatOd )
         EXIT
      ELSEIF DToS( dProsli ) >= DToS( field->DatOd )
         SKIP 1
         LOOP
      ENDIF
      IF field->den <> 0
         nK := nK * field->den
      ENDIF
      SKIP 1
   ENDDO
   PopWA()

   RETURN nIznos * nK
