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
#define PRINT_LEFT_SPACE 2

STATIC REP1_LEN
STATIC PICD

MEMVAR th1, th2, th3, th4, th5
MEMVAR M6, M7, M8, M9, M10

MEMVAR d4ps, p4ps, d4tp, p4tp, d4kp, p4kp
MEMVAR d1ps, p1ps, d1tp, p1tp, d1kp, p1kp
MEMVAR d3ps, p3ps, d3tp, p3tp, d3kp, p3kp
MEMVAR d2ps, p2ps, d2tp, p2tp, d2kp, p2kp
MEMVAR gFinRj

FUNCTION fin_bb_subanalitika_pdf( hParams )

   LOCAL cIdFirma := hParams[ "idfirma" ]
   LOCAL dDatOd := hParams[ "datum_od" ]
   LOCAL dDatDo := hParams[ "datum_do" ]
   LOCAL qqKonto := hParams[ "konto" ]
   LOCAL cIdRj := hParams[ "id_rj" ]
   LOCAL lExpRpt := hParams[ "export_dbf" ]
   LOCAL lNule := hParams[ "saldo_nula" ]
   LOCAL lPodKlas := hParams[ "podklase" ]
   LOCAL cFormat := hParams[ "format" ]
   LOCAL aExpFields, cLaunch, cKlKonto, cSinKonto, cIdKonto, cIdPartner
   LOCAL cFilter, aUsl1, nStr := 0
   LOCAL b, b1, b2
   LOCAL nValuta := hParams[ "valuta" ]
   LOCAL nBBK := 1
   LOCAL bZagl, xPrintOpt
   LOCAL nSlog, nUkupno, cFilt, cFilt1, cSort1

   PRIVATE M6, M7, M8, M9, M10

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nMarza, nMarza2

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   IF cFormat == "1"  // landscape
      xPrintOpt[ "layout" ] := "landscape"
      xPrintOpt[ "font_size" ] := 5.5
   ELSE
      xPrintOpt[ "layout" ] := "landscape"
      xPrintOpt[ "font_size" ] := 8
   ENDIF

   xPrintOpt[ "opdf" ] := s_oPDF
   legacy_ptxt( .F. )

   IF f18_start_print( NIL, xPrintOpt,  "FIN bruto bilans subanalitika za period: " + DToC( dDatOd ) + " - " + DToC( dDatDo )  + "  NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| zagl( hParams ) }

   PICD := FormPicL( gPicBHD, 15 )

   IF gFinRj == "D" .AND. ( "." $ cIdRj )
      cIdRj := Trim( StrTran( cIdRj, ".", "" ) )
   ENDIF

   IF cFormat $ "1#3"
      REP1_LEN := 236
      th1 := "------ ------- -------- --------------------------------------------------- -------------- ----------------- --------------------------------- ------------------------------- ------------------------------- -------------------------------"
      th2 := "*R.   * KONTO *PARTNER *     NAZIV KONTA ILI PARTNERA                      *    MJESTO    *      ADRESA     *        POČETNO STANJE           *         TEKUĆI PROMET         *       KUMULATIVNI PROMET      *            SALDO             *"
      th3 := "                                                                                                             --------------------------------- ------------------------------- ------------------------------- -------------------------------"
      th4 := "*BR.  *       *        *                                                   *              *                 *    DUGUJE       *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *   POTRAŽUJE  *"
      th5 := "------ ------- -------- --------------------------------------------------- -------------- ----------------- ----------------- --------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   ELSE
      REP1_LEN := 158
      th1 := "------ ------- -------- -------------------------------------- --------------------------------- ------------------------------- -------------------------------"
      th2 := "*R.   * KONTO *PARTNER *    NAZIV KONTA ILI PARTNERA          *        POČETNO STANJE           *       KUMULATIVNI PROMET      *            SALDO             *"
      th3 := "                                                               --------------------------------- ------------------------------- -------------------------------"
      th4 := "*BR.  *       *        *                                      *    DUGUJE       *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *   POTRAŽUJE  *"
      th5 := "------ ------- -------- -------------------------------------- ----------------- --------------- --------------- --------------- --------------- ---------------"
   ENDIF

   M6 := "--------- --------------- --------------- --------------- --------------- --------------- --------------- --------------- ---------------"
   M7 := "*        *          POČETNO STANJE       *         TEKUĆI PROMET         *        KUMULATIVNI PROMET     *            SALDO             *"
   M8 := "  KLASA   ------------------------------- ------------------------------- ------------------------------- -------------------------------"
   M9 := "*        *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *   POTRAŽUJE   *    DUGUJE     *   POTRAŽUJE   *     DUGUJE    *    POTRAŽUJE *"
   M10 := "--------- --------------- --------------- --------------- --------------- --------------- --------------- --------------- ---------------"


   IF lExpRpt
      aExpFields := struktura_pomocne_tabele_eksporta()
      IF !create_dbf_r_export( aExpFields )
         RETURN .F.
      ENDIF
   ENDIF

   o_sql_suban_kto_partner( cIdFirma )
   IF !o_bruto_bilans_klase()
      MsgBeep( "ERROR otvaranje pomoćne tabele BBKLAS !?" )
      RETURN .F.
   ENDIF

   SELECT BBKLAS
   my_dbf_zap()

   cFilter := ""

   SELECT SUBAN

   IF gFinRj == "D" .AND. Len( cIdrj ) <> 0
      cFilter += iif( Empty( cFilter ), "", ".and." ) + "idrj=" + dbf_quote( cIdRj )
   ENDIF

   IF !Empty( qqKonto )
      aUsl1 := Parsiraj( qqKonto, "idkonto" )
      IF aUsl1 <> ".t."
         cFilter += iif( Empty( cFilter ), "", ".and." ) + aUsl1
      ENDIF
   ENDIF

   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      cFilter += iif( Empty( cFilter ), "", ".and." ) + "DATDOK>=CTOD('" + DToC( dDatOd ) + "') .and. DATDOK<=CTOD('" + DToC( dDatDo ) + "')"
   ENDIF

   IF !Empty( cFilter ) .AND. Len( cIdFirma ) == 2
      SET FILTER TO &cFilter
   ENDIF

   IF Len( cIdFirma ) < 2
      SELECT SUBAN
      Box(, 2, 30 )
      nSlog := 0
      nUkupno := RECCOUNT2()
      cFilt := iif( Empty( cFilter ), "IDFIRMA=" + dbf_quote( cIdFirma ), cFilter + ".and.IDFIRMA=" + dbf_quote( cIdFirma ) )
      cSort1 := "IdKonto+IdPartner+dtos(DatDok)+BrNal+STR(RBr,5)"
      INDEX ON &cSort1 TO "SUBTMP" FOR &cFilt Eval( fin_tek_rec_2() ) EVERY 1
      GO TOP
      BoxC()
   ELSE
      GO TOP
   ENDIF

   EOF CRET

   nStr := 0
   B := 0
   B1 := 0
   B2 := 0

   SELECT SUBAN

   D1S := D2S := D3S := D4S := 0
   P1S := P2S := P3S := P4S := 0
   D4PS := P4PS := D4TP := P4TP := D4KP := P4KP := 0
   nCol1 := 50

   Eval( bZagl )
   DO WHILE !Eof() .AND. IdFirma == cIdFirma

      // PS - pocetno stanje
      // TP - tekuci promet
      // KP - kumulativni promet
      // S - saldo

      D3PS := P3PS := D3TP := P3TP := D3KP := P3KP := D3S := P3S := 0
      cKlKonto := Left( IdKonto, 1 )

      check_nova_strana( bZagl, s_oPDF )
      DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cKlKonto == Left( IdKonto, 1 )

         cSinKonto := Left( IdKonto, 3 )
         D2PS := P2PS := D2TP := P2TP := D2KP := P2KP := D2S := P2S := 0
         check_nova_strana( bZagl, s_oPDF )

         DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cSinKonto == Left( IdKonto, 3 )

            check_nova_strana( bZagl, s_oPDF )
            cIdKonto := IdKonto
            D1PS := P1PS := D1TP := P1TP := D1KP := P1KP := D1S := P1S := 0
            DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cIdKonto == IdKonto

               check_nova_strana( bZagl, s_oPDF )
               cIdPartner := field->IdPartner
               D0PS := P0PS := D0TP := P0TP := D0KP := P0KP := D0S := P0S := 0

               DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cIdKonto == IdKonto .AND. cIdPartner == field->IdPartner

                  IF nValuta == 1
                     IF D_P = "1"
                        D0KP += IznosBHD * nBBK
                     ELSE
                        P0KP += IznosBHD * nBBK
                     ENDIF
                  ELSE
                     IF D_P = "1"
                        D0KP += IznosDEM
                     ELSE
                        P0KP += IznosDEM
                     ENDIF
                  ENDIF

                  IF nValuta == 1
                     IF IdVN = "00"
                        IF D_P == "1"
                           D0PS += IznosBHD * nBBK
                        ELSE
                           P0PS += IznosBHD * nBBK
                        ENDIF
                     ELSE
                        IF D_P == "1"
                           D0TP += IznosBHD * nBBK
                        ELSE
                           P0TP += IznosBHD * nBBK
                        ENDIF
                     ENDIF
                  ELSE

                     IF IdVN = "00"
                        IF D_P == "1"
                           D0PS += IznosDEM
                        ELSE
                           P0PS += IznosDEM
                        ENDIF
                     ELSE
                        IF D_P == "1"
                           D0TP += IznosDEM
                        ELSE
                           P0TP += IznosDEM
                        ENDIF
                     ENDIF
                  ENDIF

                  SKIP
               ENDDO

               check_nova_strana( bZagl, s_oPDF )
               IF ( !lNule .AND. Round( D0KP - P0KP, 2 ) == 0 )

               ELSE
                  @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
                  @ PRow(), PCol() SAY  ++B  PICTURE '999999'
                  @ PRow(), PCol() + 1 SAY cIdKonto
                  @ PRow(), PCol() + 1 SAY cIdPartner
                  select_o_partner( cIdPartner )

                  IF cFormat == "2" // A4
                     @ PRow(), PCol() + 1 SAY PadR( naz, 48 - Len ( cIdPartner ) )
                  ELSE
                     @ PRow(), PCol() + 1 SAY PadR( naz, 30 )
                     @ PRow(), PCol() + 1 SAY PadR( naz2, 22 )
                     @ PRow(), PCol() + 1 SAY Mjesto
                     @ PRow(), PCol() + 1 SAY Adresa PICTURE 'XXXXXXXXXXXXXXXXX'
                  ENDIF

                  SELECT SUBAN
                  nCol1 := PCol() + 1
                  @ PRow(), PCol() + 1 SAY D0PS PICTURE PicD
                  @ PRow(), PCol() + 1 SAY P0PS PICTURE PicD
                  IF cFormat == "1" // A3
                     @ PRow(), PCol() + 1 SAY D0TP PICTURE PicD
                     @ PRow(), PCol() + 1 SAY P0TP PICTURE PicD
                  ENDIF

                  @ PRow(), PCol() + 1 SAY D0KP PICTURE PicD
                  @ PRow(), PCol() + 1 SAY P0KP PICTURE PicD

                  D0S := D0KP - P0KP

                  IF D0S >= 0
                     P0S := 0
                  ELSE
                     P0S := -D0S
                     D0S := 0
                  ENDIF

                  @ PRow(), PCol() + 1 SAY D0S PICTURE PicD
                  @ PRow(), PCol() + 1 SAY P0S PICTURE PicD

                  D1PS += D0PS; P1PS += P0PS; D1TP += D0TP; P1TP += P0TP; D1KP += D0KP; P1KP += P0KP

                  IF lExpRpt .AND. !Empty( cIdPartner )
                     dodaj_stavku_u_tabelu_eksporta( cIdKonto, cIdPartner, partn->naz, D0PS, P0PS, D0KP, P0KP, D0S, P0S )
                  ENDIF
               ENDIF

            ENDDO

            check_nova_strana( bZagl, s_oPDF )

            @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
            @ PRow(), PCol() + 4 SAY Replicate( "-", REP1_LEN - 2 )
            @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
            @ PRow(), PCol() + 2 SAY ++B1 PICTURE '999999'
            @ PRow(), PCol() + 1 SAY cIdKonto

            select_o_konto( cIdKonto )

            IF cFormat == "1"
               @ PRow(), PCol() + 1 SAY naz
            ELSE
               @ PRow(), PCol() + 1 SAY Left ( naz, 47 )
            ENDIF

            SELECT SUBAN

            @ PRow(), nCol1   SAY D1PS PICTURE PicD
            @ PRow(), PCol() + 1  SAY P1PS PICTURE PicD

            IF cFormat == "1"
               @ PRow(), PCol() + 1  SAY D1TP PICTURE PicD
               @ PRow(), PCol() + 1  SAY P1TP PICTURE PicD
            ENDIF

            @ PRow(), PCol() + 1  SAY D1KP PICTURE PicD
            @ PRow(), PCol() + 1  SAY P1KP PICTURE PicD

            D1S := D1KP - P1KP

            IF D1S >= 0
               P1S := 0
               D2S += D1S
               D3S += D1S
               D4S += D1S
            ELSE
               P1S := -D1S
               D1S := 0
               P2S += P1S
               P3S += P1S
               P4S += P1S
            ENDIF

            @ PRow(), PCol() + 1 SAY D1S PICTURE PicD
            @ PRow(), PCol() + 1 SAY P1S PICTURE PicD

            @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
            @ PRow(), PCol() + 4 SAY Replicate( "-", REP1_LEN - 2 )

            SELECT SUBAN
            D2PS += D1PS
            P2PS += P1PS
            D2TP += D1TP
            P2TP += P1TP
            D2KP += D1KP
            P2KP += P1KP

            IF lExpRpt
               dodaj_stavku_u_tabelu_eksporta( cIdKonto, "", konto->naz, D1PS, P1PS, D1KP, P1KP, D1S, P1S )
            ENDIF

         ENDDO

         check_nova_strana( bZagl, s_oPDF )

         @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
         @ PRow(), PCol() + 6 SAY Replicate( "=", REP1_LEN - 4 )

         @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
         @ PRow(), PCol() + 4 SAY ++B2 PICTURE '999999'; ?? "."
         @ PRow(), PCol() + 1 SAY cSinKonto

         select_o_konto( cSinKonto )
         IF cFormat == "1"
            @ PRow(), PCol() + 1 SAY Left( naz, 50 )
         ELSE
            @ PRow(), PCol() + 1 SAY Left( naz, 44 )
         ENDIF

         SELECT SUBAN

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
         @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
         @ PRow(), PCol() + 6 SAY Replicate( "=", REP1_LEN - 4 )

         SELECT SUBAN

         D3PS += D2PS
         P3PS += P2PS
         D3TP += D2TP
         P3TP += P2TP
         D3KP += D2KP
         P3KP += P2KP

         IF lExpRpt
            dodaj_stavku_u_tabelu_eksporta( cSinKonto, "", konto->naz, D2PS, P2PS, D2KP, P2KP, D2S, P2S )
         ENDIF

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

      SELECT SUBAN
      IF lPodKlas
         ?U Space( PRINT_LEFT_SPACE ) + th5
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
         ?U Space( PRINT_LEFT_SPACE ) + th5
      ENDIF

      D4PS += D3PS
      P4PS += P3PS
      D4TP += D3TP
      P4TP += P3TP
      D4KP += D3KP
      P4KP += P3KP

      IF lExpRpt
         dodaj_stavku_u_tabelu_eksporta( cKlKonto, "", konto->naz, D3PS, P3PS, D3KP, P3KP, D3S, P3S )
      ENDIF

   ENDDO

   check_nova_strana( bZagl, s_oPDF )
   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   ??U th5

   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   @ PRow() + 1, PCol() + 8 SAY "UKUPNO:"
   @ PRow(), nCol1 SAY D4PS PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4PS PICTURE PicD
   IF cFormat == "1"
      @ PRow(), PCol() + 1 SAY D4TP PICTURE PicD
      @ PRow(), PCol() + 1 SAY P4TP PICTURE PicD
   ENDIF
   @ PRow(), PCol() + 1 SAY D4KP PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4KP PICTURE PicD
   @ PRow(), PCol() + 1 SAY D4S PICTURE PicD
   @ PRow(), PCol() + 1 SAY P4S PICTURE PicD
   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE ) + th5

   IF lExpRpt
      dodaj_stavku_u_tabelu_eksporta( "UKUPNO", "", "", D4PS, P4PS, D4KP, P4KP, D4S, P4S )
   ENDIF

   IF !check_nova_strana( bZagl, s_oPDF, .F., 5 )
      ?
      ?
   ENDIF

   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   ?? "REKAPITULACIJA PO KLASAMA NA DAN:"
   @ PRow(), PCol() + 2 SAY Date()

   ?U Space( PRINT_LEFT_SPACE ) + M6
   ?U Space( PRINT_LEFT_SPACE ) + M7
   ?U Space( PRINT_LEFT_SPACE ) + M8
   ?U Space( PRINT_LEFT_SPACE ) + M9
   ?U Space( PRINT_LEFT_SPACE ) + M10

   SELECT BBKLAS
   GO TOP
   nPocDug := nPocPot := nTekPDug := nTekPPot := nKumPDug := nKumPPot := nSalPDug := nSalPPot := 0

   DO WHILE !Eof()

      check_nova_strana( bZagl, s_oPDF )
      @ PRow() + 1, 4  SAY Space( PRINT_LEFT_SPACE ) + IdKlasa
      @ PRow(), PCol() + 5 SAY PocDug               PICTURE PicD
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

   check_nova_strana( bZagl, s_oPDF )
   ?U Space( PRINT_LEFT_SPACE ) + M10

   ? Space( PRINT_LEFT_SPACE ) + "UKUPNO:"
   @ PRow(), PCol() + 3 SAY  nPocDug    PICTURE PicD
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

   IF lExpRpt
      open_r_export_table()
   ENDIF

   RETURN .T.



STATIC FUNCTION dodaj_stavku_u_tabelu_eksporta( cKonto, cIdPart, cNaziv, nPsDug, nPsPot, nKumDug, nKumPot, nSldDug, nSldPot )

   LOCAL nArr

   nArr := Select()
   o_r_export()
   APPEND BLANK
   REPLACE field->konto WITH cKonto
   REPLACE field->idpart WITH cIdPart
   REPLACE field->naziv WITH cNaziv
   REPLACE field->psdug WITH nPsDug
   REPLACE field->pspot WITH nPsPot
   REPLACE field->kumdug WITH nKumDug
   REPLACE field->kumpot WITH nKumPot
   REPLACE field->slddug WITH nSldDug
   REPLACE field->sldpot WITH nSldPot

   SELECT ( nArr )

   RETURN .T.



STATIC FUNCTION struktura_pomocne_tabele_eksporta()

   aFields := {}
   AAdd( aFields, { "konto", "C", 7, 0 } )
   AAdd( aFields, { "idpart", "C", 6, 0 } )
   AAdd( aFields, { "naziv", "C", 40, 0 } )
   AAdd( aFields, { "psdug", "N", 15, 2 } )
   AAdd( aFields, { "pspot", "N", 15, 2 } )
   AAdd( aFields, { "kumdug", "N", 15, 2 } )
   AAdd( aFields, { "kumpot", "N", 15, 2 } )
   AAdd( aFields, { "slddug", "N", 15, 2 } )
   AAdd( aFields, { "sldpot", "N", 15, 2 } )

   RETURN aFields


STATIC FUNCTION zagl( hParams )

   zagl_organizacija( PRINT_LEFT_SPACE )

   IF !Empty( hParams[ "konto" ] )
      ? "Odabrana konta: " + AllTrim( hParams[ "konto" ] )
   ENDIF

   IF gFinRj == "D" .AND. Len( hParams[ "id_rj" ] ) <> 0
      ? "Radna jedinica ='" + hParams[ "id_rj" ] + "'"
   ENDIF

   ?U Space( PRINT_LEFT_SPACE ) + th1
   ?U Space( PRINT_LEFT_SPACE ) + th2
   ?U Space( PRINT_LEFT_SPACE ) + th3
   ?U Space( PRINT_LEFT_SPACE ) + th4
   ?U Space( PRINT_LEFT_SPACE ) + th5

   RETURN .T.
