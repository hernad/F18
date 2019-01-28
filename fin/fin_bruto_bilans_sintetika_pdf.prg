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
MEMVAR d1ps, p1ps, d1tp, p1tp, d1kp, p1kp
MEMVAR d4ps, p4ps, d4tp, p4tp, d4kp, p4kp
MEMVAR d3ps, p3ps, d3tp, p3tp, d3kp, p3kp
MEMVAR d2ps, p2ps, d2tp, p2tp, d2kp, p2kp
MEMVAR gFinRj

FUNCTION fin_bb_sintetika_pdf( hParams )

   LOCAL nPom
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
   LOCAL nColNaz
   LOCAL bZagl, xPrintOpt
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
      M2 := "*REDNI*   KONTO   *                  NAZIV SINTETIČKOG KONTA                *        POČETNO STANJE         *         TEKUĆI PROMET         *       KUMULATIVNI PROMET      *            SALDO             *"
      M3 := "                                                                             ------------------------------- ------------------------------- ------------------------------- -------------------------------"
      M4 := "*BROJ *           *                                                         *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE  *"
      M5 := "------ ----------- --------------------------------------------------------- --------------- --------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ELSE
      M1 := "---- --------------------------------------------------------- ------------------------------- ------------------------------- -------------------------------"
      M2 := "    *                                                         *        POČETNO STANJE         *       KUMULATIVNI PROMET      *            SALDO             *"
      M3 := "    *                   SINTETIČKI KONTO                       ------------------------------- ------------------------------- -------------------------------"
      M4 := "    *                                                         *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE  *"
      M5 := "---- --------------------------------------------------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ENDIF

   fin_bb_set_m6_do_m10_vars()
   o_bruto_bilans_klase()

   IF gFinRj == "D" .AND. Len( cIdRJ ) <> 0
      otvori_sint_anal_kroz_temp( .T., "IDRJ='" + cIdRJ + "'" )
   ELSE
      MsgO( "Preuzimanje podataka sa SQL servera ..." )
      find_sint_by_konto_za_period( cIdFirma, NIL, dDatOd, dDatDo )
      MsgC()
   ENDIF

   cFilter := ""
   IF !( Empty( qqKonto ) )
      aUsl1 := Parsiraj( qqKonto, "idkonto" )
      cFilter += ( iif( Empty( cFilter ), "", ".and." ) + aUsl1 )
   ENDIF

   IF !Empty( cFilter )
      SET FILTER TO &cFilter
   ENDIF

   GO TOP
   EOF CRET

   nStr := 0
   nBroj := 1
   D1S := D2S := D3S := D4S := P1S := P2S := P3S := P4S := 0
   D4PS := P4PS := D4TP := P4TP := D4KP := P4KP := D4S := P4S := 0
   nCol1 := 50

   SELECT BBKLAS
   my_dbf_zap()
   SELECT sint

   IF f18_start_print( NIL, xPrintOpt,  "FIN bruto bilans SINTETIKA za period: " + DToC( dDatOd ) + " - " + DToC( dDatDo )  + "  NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF
   Eval( bZagl )
   DO WHILE !Eof() .AND. sint->IdFirma == cIdFirma

      cKlKonto := Left( IdKonto, 1 )
      D3PS := P3PS := D3TP := P3TP := D3KP := P3KP := D3S := P3S := 0

      check_nova_strana( bZagl, s_oPDF )
      DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cKlKonto == Left( IdKonto, 1 )

         cIdKonto := sint->IdKonto
         D1PS := P1PS := D1TP := P1TP := D1KP := P1KP := D1S := P1S := 0

         check_nova_strana( bZagl, s_oPDF )
         DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cIdKonto == Left( IdKonto, 3 )
            IF nValuta == 1
               Dug := DugBHD * nBBK
               Pot := PotBHD * nBBK
            ELSE
               Dug := DUGDEM
               Pot := POTDEM
            ENDIF
            D1KP += Dug
            P1KP += Pot
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
         IF cFormat == "1"
            @ PRow() + 1, PRINT_LEFT_SPACE + 1 SAY nBroj PICTURE '9999'
            ?? "."
            @ PRow(), 10 + PRINT_LEFT_SPACE SAY cIdKonto
            select_o_konto( cIdKonto )
            @ PRow(), 19 + PRINT_LEFT_SPACE SAY KONTO->naz
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY D1PS PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1PS PICTURE PicD
            @ PRow(), PCol() + 1 SAY D1TP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1TP PICTURE PicD
            @ PRow(), PCol() + 1 SAY D1KP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1KP PICTURE PicD
            D1S := D1KP - P1KP
            IF D1S >= 0
               P1S := 0
               D3S += D1S
               D4S += D1S
            ELSE
               P1S := -D1S
               D1S := 0
               P3S += P1S
               P4S += P1S
            ENDIF
            @ PRow(), PCol() + 1 SAY D1S PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1S PICTURE PicD

         ELSE
            @ PRow() + 1, PRINT_LEFT_SPACE + 1 SAY cIdKonto
            select_o_konto( cIdKonto )
            nColNaz := PCol() + 1
            @ PRow(), PCol() + 1 SAY KONTO->naz
            nCol1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY D1PS PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1PS PICTURE PicD
            @ PRow(), PCol() + 1 SAY D1KP PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1KP PICTURE PicD
            D1S := D1KP - P1KP
            IF D1S >= 0
               P1S := 0
               D3S += D1S
               D4S += D1S
            ELSE
               P1S := -D1S
               D1S := 0
               P3S += P1S
               P4S += P1S
            ENDIF
            @ PRow(), PCol() + 1 SAY D1S PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1S PICTURE PicD


         ENDIF

         SELECT SINT
         D3PS += D1PS
         P3PS += P1PS
         D3TP += D1TP
         P3TP += P1TP
         D3KP += D1KP
         P3KP += P1KP
         ++nBroj

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

      SELECT SINT

      IF lPodKlas

         ?U Space( PRINT_LEFT_SPACE ) + M5
         ? Space( PRINT_LEFT_SPACE ) + "UKUPNO KLASA " + cKlKonto
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

   ?U SPACE(PRINT_LEFT_SPACE) + M5
   ? SPACE(PRINT_LEFT_SPACE) + "UKUPNO:"

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
   ?U SPACE(PRINT_LEFT_SPACE) + M5
   nPom := d4ps - p4ps
   @ PRow() + 1, nCol1   SAY iif( nPom > 0, nPom, 0 ) PICTURE PicD
   @ PRow(), PCol() + 1 SAY iif( nPom < 0, - nPom, 0 ) PICTURE PicD

   nPom := d4tp - p4tp
   IF cFormat == "1"
      @ PRow(), PCol() + 1 SAY iif( nPom > 0, nPom, 0 ) PICTURE PicD
      @ PRow(), PCol() + 1 SAY iif( nPom < 0, - nPom, 0 ) PICTURE PicD
   ENDIF

   nPom := d4kp - p4kp
   @ PRow(), PCol() + 1 SAY iif( nPom > 0, nPom, 0 ) PICTURE PicD
   @ PRow(), PCol() + 1 SAY iif( nPom < 0, - nPom, 0 ) PICTURE PicD
   nPom := d4s - p4s
   @ PRow(), PCol() + 1 SAY iif( nPom > 0, nPom, 0 ) PICTURE PicD
   @ PRow(), PCol() + 1 SAY iif( nPom < 0, - nPom, 0 ) PICTURE PicD
   ?U Space( PRINT_LEFT_SPACE ) + M5

   check_nova_strana( NIL, s_oPDF, .T.) // nova strana
   ?
   ?
   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   ??U "REKAPITULACIJA PO KLASAMA NA DAN: "
   ?? Date()

   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M6, "--------- --------------- --------------- --------------- --------------- --------------- ---------------" )
   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M7, "*        *          POČETNO STANJE       *        KUMULATIVNI PROMET     *            SALDO             *" )
   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M8, "  KLASA   ------------------------------- ------------------------------- -------------------------------" )
   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M9, "*        *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *    POTRAŽUJE *" )
   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M10, "--------- --------------- --------------- --------------- --------------- --------------- ---------------" )

   SELECT BBKLAS
   GO TOP

   nPocDug := nPocPot := nTekPDug := nTekPPot := nKumPDug := nKumPPot := nSalPDug := nSalPPot := 0
   DO WHILE !Eof()

      check_nova_strana( bZagl, s_oPDF )
      @ PRow() + 1, 4    SAY Space( PRINT_LEFT_SPACE ) + IdKlasa
      @ PRow(), 10 + PRINT_LEFT_SPACE   SAY PocDug               PICTURE PicD
      @ PRow(), PCol() + 1 SAY PocPot               PICTURE PicD
      IF cFormat == "1"
         @ PRow(), PCol() + 1 SAY TekPDug              PICTURE PicD
         @ PRow(), PCol() + 1 SAY TekPPot              PICTURE PicD
      ENDIF
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

   ?U Space( PRINT_LEFT_SPACE ) + iif( cFormat == "1", M10, "--------- --------------- --------------- --------------- --------------- --------------- ---------------" )
   ? Space( PRINT_LEFT_SPACE ) + "UKUPNO:"
   @ PRow(), PCol() + 3   SAY  nPocDug    PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nPocPot    PICTURE PicD
   IF cFormat == "1"
      @ PRow(), PCol() + 1 SAY  nTekPDug   PICTURE PicD
      @ PRow(), PCol() + 1 SAY  nTekPPot   PICTURE PicD
   ENDIF
   @ PRow(), PCol() + 1 SAY  nKumPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nKumPPot   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPDug   PICTURE PicD
   @ PRow(), PCol() + 1 SAY  nSalPPot   PICTURE PicD
   ?U Space( PRINT_LEFT_SPACE ) + IIF( cFormat == "1", M10, "--------- --------------- --------------- --------------- --------------- --------------- ---------------" )

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

   SELECT SINT

   ?U Space( PRINT_LEFT_SPACE ) + M1
   ?U Space( PRINT_LEFT_SPACE ) + M2
   ?U Space( PRINT_LEFT_SPACE ) + M3
   ?U Space( PRINT_LEFT_SPACE ) + M4
   ?U Space( PRINT_LEFT_SPACE ) + M5

   RETURN .T.
