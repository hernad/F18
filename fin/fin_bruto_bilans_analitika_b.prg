/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

STATIC PICD
STATIC REP1_LEN := 158


FUNCTION fin_bb_analitika_b( hParams )

   LOCAL cIdFirma := hParams[ "idfirma" ]
   LOCAL dDatOd := hParams[ "datum_od" ]
   LOCAL dDatDo := hParams[ "datum_do" ]
   LOCAL qqKonto := hParams[ "konto" ]
   LOCAL cIdRj := hParams[ "id_rj" ]
   LOCAL lNule := hParams[ "saldo_nula" ]
   LOCAL lPodKlas := hParams[ "podklase" ]
   LOCAL cFormat := hParams[ "format" ]
   LOCAL cKlKonto, cSinKonto, cIdKonto, cIdPartner
   LOCAL cFilter, aUsl1, nStr := 0
   LOCAL b, b1, b2
   LOCAL nValuta := hParams[ "valuta" ]
   LOCAL nBBK := 1
   LOCAL aNaziv, nColNaz

   PRIVATE M6, M7, M8, M9, M10

   PICD := FormPicL( gPicBHD, 15 )

   IF gFinRj == "D" .AND. ( "." $ cIdRj )
      cIdRj := Trim( StrTran( cIdRj, ".", "" ) )
   ENDIF

   IF cFormat == "1"
      M1 := "------ ----------- --------------------------------------------------------- ------------------------------- ------------------------------- ------------------------------- -------------------------------"
      M2 := "*REDNI*   KONTO   *                NAZIV ANALITIČKOG KONTA                  *        POČETNO STANJE         *         TEKUĆI PROMET         *       KUMULATIVNI PROMET      *            SALDO             *"
      M3 := "                                                                             ------------------------------- ------------------------------- ------------------------------- -------------------------------"
      M4 := "*BROJ *           *                                                         *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE  *"
      M5 := "------ ----------- --------------------------------------------------------- --------------- --------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ELSE
      M1 := "------ ----------- ---------------------------------------- ------------------------------- ------------------------------- -------------------------------"
      M2 := "*REDNI*   KONTO   *         NAZIV ANALITICKOG KONTA        *        POČETNO STANJE         *       KUMULATIVNI PROMET      *            SALDO             *"
      M3 := "                                                            ------------------------------- ------------------------------- -------------------------------"
      M4 := "*BROJ *           *                                        *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE  *"
      M5 := "------ ----------- ---------------------------------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ENDIF

   fin_bb_set_m6_do_m10_vars()

   //o_konto()
   //o_partner()
   o_bruto_bilans_klase()

   IF gFinRj == "D" .AND. Len( cIdRJ ) <> 0
      otvori_sint_anal_kroz_temp( .F., "IDRJ='" + cIdRJ + "'" )
   ELSE
      MsgO( "Preuzimanje podataka sa SQL servera ..." )
      find_anal_za_period( cIdFirma, dDatOd, dDatDo, "idfirma,idkonto" )
      MsgC()
   ENDIF

   SELECT BBKLAS
   my_dbf_zap()

   SELECT ANAL

   cFilter := ""

   IF !( Empty( qqkonto ) )
      aUsl1 := Parsiraj( qqKonto, "idkonto" )
      IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
         cFilter += ( iif( Empty( cFilter ), "", ".and." ) + ;
            aUsl1 + ".and. DATNAL>=" + dbf_quote( dDatOd ) + " .and. DATNAL<=" + dbf_quote( dDatDo ) )
      ELSE
         cFilter += ( iif( Empty( cFilter ), "", ".and." ) + aUsl1 )
      ENDIF
   ELSEIF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      cFilter += ( iif( Empty( cFilter ), "", ".and." ) + "DATNAL>=" + dbf_quote( dDatOd ) + " .and. DATNAL<=" + dbf_quote( dDatDo ) )
   ENDIF

   IF Len( cIdFirma ) < 2
      SELECT ANAL
      Box(, 2, 30 )
      nSlog := 0
      nUkupno := RECCOUNT2()
      cFilt := iif( Empty( cFilter ), "IDFIRMA=" + dbf_quote( cIdFirma ), cFilter + ".and.IDFIRMA=" + dbf_quote( cIdFirma ) )
      cSort1 := "IdKonto+dtos(DatNal)"
      INDEX ON &cSort1 TO "ANATMP" FOR &cFilt Eval( fin_tek_rec_2() ) EVERY 1
      GO TOP
      BoxC()
   ELSE
      SET FILTER TO &cFilter
      GO TOP
   ENDIF

   EOF CRET

   nStr := 0

   IF !start_print()
      RETURN .F.
   ENDIF

   B := 0
   D1S := D2S := D3S := D4S := P1S := P2S := P3S := P4S := 0
   D4PS := P4PS := D4TP := P4TP := D4KP := P4KP := D4S := P4S := 0

   nCol1 := 50

   DO WHILE !Eof() .AND. IdFirma == cIdFirma

      IF PRow() == 0
         zagl_bb_anal( hParams, @nStr )
      ENDIF

      cKlKonto := Left( IdKonto, 1 )
      D3PS := P3PS := D3TP := P3TP := D3KP := P3KP := D3S := P3S := 0

      DO WHILE !Eof() .AND. IdFirma = cIdFirma .AND. cKlKonto == Left( IdKonto, 1 )

         cSinKonto := Left( idkonto, 3 )

         D2PS := P2PS := D2TP := P2TP := D2KP := P2KP := D2S := P2S := 0

         DO WHILE !Eof() .AND. IdFirma = cIdFirma .AND. cSinKonto == Left( idkonto, 3 )

            cIdKonto := IdKonto

            D1PS := P1PS := D1TP := P1TP := D1KP := P1KP := D1S := P1S := 0

            DO WHILE !Eof() .AND. IdFirma = cIdFirma .AND. cIdKonto == IdKonto
               IF nValuta == 1
                  Dug := DugBHD * nBBK
                  Pot := PotBHD * nBBK
               ELSE
                  Dug := DUGDEM
                  Pot := POTDEM
               ENDIF
               D1KP = D1KP + Dug
               P1KP = P1KP + Pot
               IF IdVN = "00"
                  D1PS += Dug
                  P1PS += Pot
               ELSE
                  D1TP += Dug
                  P1TP += Pot
               ENDIF
               SKIP
            ENDDO

            @ PRow() + 1, 1 SAY ++B PICTURE '9999'
            ?? "."
            @ PRow(), 10 SAY cIdKonto

            select_o_konto( cIdKonto )

            IF cFormat == "1"
               @ PRow(), 19 SAY naz
            ELSE
               @ PRow(), 19 SAY PadR( naz, 40 )
            ENDIF

            SELECT ANAL

            nCol1 := PCol() + 1

            @ PRow(), PCol() + 1 SAY D1PS PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1PS PICTURE PicD

            IF cFormat == "1"
               @ PRow(), PCol() + 1 SAY D1TP PICTURE PicD
               @ PRow(), PCol() + 1 SAY P1TP PICTURE PicD
            ENDIF

            @ PRow(), PCol() + 1 SAY D1KP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1KP PICTURE PicD

            D1S = D1KP - P1KP

            IF D1S >= 0
               P1S := 0
               D2S += D1S
               D3S += D1S
               D4S += D1S
            ELSE
               P1S := -D1S
               D1S := 0
               P1S := P1KP - D1KP
               P2S += P1S
               P3S += P1S
               P4S += P1S
            ENDIF

            @ PRow(), PCol() + 1 SAY D1S PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1S PICTURE PicD

            D2PS = D2PS + D1PS
            P2PS = P2PS + P1PS
            D2TP = D2TP + D1TP
            P2TP = P2TP + P1TP
            D2KP = D2KP + D1KP
            P2KP = P2KP + P1KP

            IF PRow() > 65 + dodatni_redovi_po_stranici()
               FF
               zagl_bb_anal( hParams, @nStr )
            ENDIF

         ENDDO

         IF PRow() > 61 + dodatni_redovi_po_stranici()
            FF
            zagl_bb_anal( hParams, @nStr )
         ENDIF

         ?U M5
         @ PRow() + 1, 10 SAY cSinKonto
         @ PRow(), nCol1    SAY D2PS PICTURE PicD
         @ PRow(), PCol() + 1 SAY P2PS PICTURE PicD
         IF cFormat == "1"
            @ PRow(), PCol() + 1 SAY D2TP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P2TP PICTURE PicD
         ENDIF
         @ PRow(), PCol() + 1 SAY D2KP PICTURE PicD
         @ PRow(), PCol() + 1 SAY P2KP PICTURE PicD
         @ PRow(), PCol() + 1 SAY D2S PICTURE PicD
         @ PRow(), PCol() + 1 SAY P2S PICTURE PicD
         ?U M5

         D3PS = D3PS + D2PS
         P3PS = P3PS + P2PS
         D3TP = D3TP + D2TP
         P3TP = P3TP + P2TP
         D3KP = D3KP + D2KP
         P3KP = P3KP + P2KP

      ENDDO

      SELECT BBKLAS
      APPEND BLANK
      RREPLACE IdKlasa WITH cKlKonto, ;
         PocDug  WITH D3PS, ;
         PocPot  WITH P3PS, ;
         TekPDug WITH D3TP, ;
         TekPPot WITH P3TP, ;
         KumPDug WITH D3KP, ;
         KumPPot WITH P3KP, ;
         SalPDug WITH D3S, ;
         SalPPot WITH P3S

      SELECT ANAL

      IF lPodKlas

         ?U M5
         ?U "UKUPNO KLASA " + cklkonto

         @ PRow(), nCol1    SAY D3PS PICTURE PicD
         @ PRow(), PCol() + 1 SAY P3PS PICTURE PicD

         IF cFormat == "1"
            @ PRow(), PCol() + 1 SAY D3TP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P3TP PICTURE PicD
         ENDIF

         @ PRow(), PCol() + 1 SAY D3KP PICTURE PicD
         @ PRow(), PCol() + 1 SAY P3KP PICTURE PicD
         @ PRow(), PCol() + 1 SAY D3S PICTURE PicD
         @ PRow(), PCol() + 1 SAY P3S PICTURE PicD

         ?U M5

      ENDIF

      D4PS += D3PS
      P4PS += P3PS
      D4TP += D3TP
      P4TP += P3TP
      D4KP += D3KP
      P4KP += P3KP

   ENDDO

   IF PRow() > 61 + dodatni_redovi_po_stranici()
      FF
      zagl_bb_anal( hParams, @nStr )
   ENDIF

   ?U M5
   ?U "UKUPNO:"
   @ PRow(), nCol1    SAY D4PS PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4PS PICTURE PicD
   IF cFormat == "1"
      @ PRow(), PCol() + 1 SAY D4TP PICTURE PicD
      @ PRow(), PCol() + 1 SAY P4TP PICTURE PicD
   ENDIF
   @ PRow(), PCol() + 1 SAY D4KP PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4KP PICTURE PicD
   @ PRow(), PCol() + 1 SAY D4S PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4S PICTURE PicD
   ?U M5

   IF PRow() > 55 + dodatni_redovi_po_stranici()
      FF
   ELSE
      ?
      ?
   ENDIF

   ?? "REKAPITULACIJA PO KLASAMA NA DAN: "
   ?? Date()
   ?U  M6
   ?U  M7
   ?U  M8
   ?U  M9
   ?U  M10

   SELECT BBKLAS
   GO TOP

   nPocDug := nPocPot := nTekPDug := nTekPPot := nKumPDug := nKumPPot := nSalPDug := nSalPPot := 0

   DO WHILE !Eof()
      @ PRow() + 1, 4   SAY IdKlasa
      @ PRow(), 10       SAY PocDug               PICTURE PicD
      @ PRow(), PCol() + 1 SAY PocPot               PICTURE PicD
      @ PRow(), PCol() + 1 SAY TekPDug              PICTURE PicD
      @ PRow(), PCol() + 1 SAY TekPPot              PICTURE PicD
      @ PRow(), PCol() + 1 SAY KumPDug              PICTURE PicD
      @ PRow(), PCol() + 1 SAY KumPPot              PICTURE PicD
      @ PRow(), PCol() + 1 SAY SalPDug              PICTURE PicD
      @ PRow(), PCol() + 1 SAY SalPPot              PICTURE PicD

      nPocDug   += PocDug
      nPocPot   += PocPot
      nTekPDug  += TekPDug
      nTekPPot  += TekPPot
      nKumPDug  += KumPDug
      nKumPPot  += KumPPot
      nSalPDug  += SalPDug
      nSalPPot  += SalPPot
      SKIP
   ENDDO

   ?U M10
   ? "UKUPNO:"
   @ PRow(), 10       SAY  nPocDug    PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nPocPot    PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nTekPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nTekPPot   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nKumPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nKumPPot   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPPot   PICTURE PicD
   ?U M10

   FF
   end_print()

   my_close_all_dbf()

   RETURN



FUNCTION zagl_bb_anal( hParams, nStr )

   ?
   P_COND2

   ??U "FIN: ANALITIČKI BRUTO BILANS U VALUTI '" + IF( hParams[ "valuta" ] == 1, valuta_domaca_skraceni_naziv(), ValPomocna() ) + "'"

   IF !( Empty( hParams[ "datum_od" ] ) .AND. Empty( hParams[ "datum_do" ] ) )
      ?? " ZA PERIOD OD", hParams[ "datum_od" ], "-", hParams[ "datum_do" ]
   ENDIF

   ?? " NA DAN: "
   ?? Date()
   ?? " (v.B)"

   @ PRow(), REP1_LEN - 15 SAY "Str:" + Str( ++nStr, 3 )

   // IF gNW == "D"
   ? "Firma:", self_organizacija_id(), self_organizacija_naziv()
   /*
    ELSE
      ? "Firma:"
      @ PRow(), PCol() + 2 SAY hParams[ "idfirma" ]
      -- SELECT PARTN
      -- HSEEK hParams[ "idfirma" ]
      @ PRow(), PCol() + 2 SAY Naz
      @ PRow(), PCol() + 2 SAY Naz2
   ENDIF
   */

   IF !Empty( hParams[ "konto" ] )
      ? "Odabrana konta: " + AllTrim( hParams[ "konto" ] )
   ENDIF

   IF gFinRj == "D" .AND. Len( hParams[ "id_rj" ] ) <> 0
      ? "Radna jedinica ='" + hParams[ "id_rj" ] + "'"
   ENDIF

   SELECT ANAL

   ?U M1
   ?U M2
   ?U M3
   ?U M4
   ?U M5

   RETURN .T.
