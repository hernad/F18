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

STATIC s_oPDF
STATIC PRINT_LEFT_SPACE := 0

STATIC PICD
STATIC REP1_LEN := 158

MEMVAR M1, M2, M3, M4, M5
MEMVAR d4ps, p4ps, d4tp, p4tp, d4kp, p4kp
MEMVAR d1ps, p1ps, d1tp, p1tp, d1kp, p1kp
MEMVAR d3ps, p3ps, d3tp, p3tp, d3kp, p3kp
MEMVAR d2ps, p2ps, d2tp, p2tp, d2kp, p2kp
MEMVAR gFinRj

FUNCTION fin_bb_analitika_pdf( hParams )

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
   LOCAL nBroj, b1, b2
   LOCAL nValuta := hParams[ "valuta" ]
   LOCAL nBBK := 1
   LOCAL aNaziv, nColNaz
   LOCAL bZagl, xPrintOpt
   LOCAL nSlog, nUkupno, cFilt, cFilt1, cSort1
   LOCAL nCol1

   PRIVATE M6, M7, M8, M9, M10

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   IF cFormat == "1"  // sa tekucim prometom
      xPrintOpt[ "layout" ] := "landscape"
      xPrintOpt[ "font_size" ] := 6.5
   ELSE
      xPrintOpt[ "layout" ] := "landscape"
      xPrintOpt[ "font_size" ] := 8
      PRINT_LEFT_SPACE := 2
   ENDIF
   xPrintOpt[ "opdf" ] := s_oPDF
   legacy_ptxt( .F. )

   bZagl := {|| zagl( hParams ) }

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
   nBroj := 0
   D1S := D2S := D3S := D4S := P1S := P2S := P3S := P4S := 0
   D4PS := P4PS := D4TP := P4TP := D4KP := P4KP := D4S := P4S := 0
   nCol1 := 50

   IF f18_start_print( NIL, xPrintOpt,  "FIN bruto bilans ANALITIKA za period: " + DToC( dDatOd ) + " - " + DToC( dDatDo )  + "  NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF
   Eval( bZagl )

   DO WHILE !Eof() .AND. IdFirma == cIdFirma

      cKlKonto := Left( IdKonto, 1 )
      D3PS := P3PS := D3TP := P3TP := D3KP := P3KP := D3S := P3S := 0

      check_nova_strana( bZagl, s_oPDF )
      DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cKlKonto == Left( IdKonto, 1 )

         cSinKonto := Left( idkonto, 3 )

         D2PS := P2PS := D2TP := P2TP := D2KP := P2KP := D2S := P2S := 0

         check_nova_strana( bZagl, s_oPDF )
         DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cSinKonto == Left( idkonto, 3 )

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

            check_nova_strana( bZagl, s_oPDF )
            @ PRow() + 1, PRINT_LEFT_SPACE + 1 SAY ++nBroj PICTURE '9999'
            ?? "."
            @ PRow(), PRINT_LEFT_SPACE + 10 SAY cIdKonto
            select_o_konto( cIdKonto )

            IF cFormat == "1"
               @ PRow(), PRINT_LEFT_SPACE + 19 SAY konto->naz
            ELSE
               @ PRow(), PRINT_LEFT_SPACE + 19 SAY PadR( naz, 40 )
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
         ENDDO
         ?U SPACE(PRINT_LEFT_SPACE) + M5

         check_nova_strana( bZagl, s_oPDF )
         @ PRow() + 1, PRINT_LEFT_SPACE + 10 SAY cSinKonto
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
         ?U Space( PRINT_LEFT_SPACE ) + M5

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
         ?U Space( PRINT_LEFT_SPACE ) + M5
         ?U Space( PRINT_LEFT_SPACE ) + "UKUPNO KLASA " + cKlkonto

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

         ?U Space( PRINT_LEFT_SPACE ) + M5
      ENDIF

      D4PS += D3PS
      P4PS += P3PS
      D4TP += D3TP
      P4TP += P3TP
      D4KP += D3KP
      P4KP += P3KP

   ENDDO

   check_nova_strana( bZagl, s_oPDF )

   ?U Space( PRINT_LEFT_SPACE ) + M5
   ?U Space( PRINT_LEFT_SPACE ) + "UKUPNO:"
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
   ?U Space( PRINT_LEFT_SPACE ) + M5

   check_nova_strana( NIL, s_oPDF, .T. ) // nova strana


   ?
   ?
   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   ?? "REKAPITULACIJA PO KLASAMA NA DAN: "
   ?? Date()
   ?U Space( PRINT_LEFT_SPACE ) +   M6
   ?U Space( PRINT_LEFT_SPACE ) +   M7
   ?U Space( PRINT_LEFT_SPACE ) +   M8
   ?U Space( PRINT_LEFT_SPACE ) +   M9
   ?U Space( PRINT_LEFT_SPACE ) +   M10

   SELECT BBKLAS
   GO TOP

   nPocDug := nPocPot := nTekPDug := nTekPPot := nKumPDug := nKumPPot := nSalPDug := nSalPPot := 0

   DO WHILE !Eof()
      check_nova_strana( bZagl, s_oPDF )
      @ PRow() + 1, 4   SAY Space( PRINT_LEFT_SPACE ) + IdKlasa
      @ PRow(), 10 + PRINT_LEFT_SPACE  SAY PocDug               PICTURE PicD
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

   ?U Space( PRINT_LEFT_SPACE ) + M10
   ?U Space( PRINT_LEFT_SPACE ) + "UKUPNO:"
   @ PRow(), PCol() + 3   SAY  nPocDug    PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nPocPot    PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nTekPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nTekPPot   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nKumPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nKumPPot   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPPot   PICTURE PicD
   ?U Space( PRINT_LEFT_SPACE ) + M10

   f18_end_print( NIL, xPrintOpt )

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION zagl( hParams )

   zagl_organizacija( PRINT_LEFT_SPACE )

   IF !Empty( hParams[ "konto" ] )
      ? "Odabrana konta: " + AllTrim( hParams[ "konto" ] )
   ENDIF

   IF gFinRj == "D" .AND. Len( hParams[ "id_rj" ] ) <> 0
      ? "Radna jedinica ='" + hParams[ "id_rj" ] + "'"
   ENDIF

   SELECT ANAL

   ?U Space( PRINT_LEFT_SPACE ) + M1
   ?U Space( PRINT_LEFT_SPACE ) + M2
   ?U Space( PRINT_LEFT_SPACE ) + M3
   ?U Space( PRINT_LEFT_SPACE ) + M4
   ?U Space( PRINT_LEFT_SPACE ) + M5

   RETURN .T.
