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


/*

FUNCTION PrenosFin()

   LOCAL cStranaBitna
   LOCAL lStranaBitna
   PRIVATE fK1 := fk2 := fk3 := fk4 := "N"

   o_params()
   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}


   RPar( "k1", @fk1 )
   RPar( "k2", @fk2 )
   RPar( "k3", @fk3 )
   RPar( "k4", @fk4 )
   SELECT params
   USE

   PRIVATE cK1 := cK2 := "9"
   PRIVATE cK3 := cK4 := "99"

   IF my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
      ck3 := "999"
   ENDIF

   O_PKONTO
   P_PKonto()

   cStranaBitna := "N"
   cKlDuguje := fetch_metric( "fin_klasa_duguje", NIL, "2" )
   cKlPotraz := fetch_metric( "fin_klasa_potrazuje", NIL, "5" )

   Box(, 12, 60 )
   nMjesta := 3
   ddatDo := Date()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Navedite koje grupacije konta se isto ponasaju:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Grupisem konte na (broj mjesta)" GET nMjesta PICT "9"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum do kojeg se promet prenosi" GET dDatDo

   IF fk1 == "D"; @ box_x_koord() + 7, box_y_koord() + 2   SAY "K1 (9 svi) :" GET cK1; ENDIF
   IF fk2 == "D"; @ box_x_koord() + 7, Col() + 2 SAY "K2 (9 svi) :" GET cK2; ENDIF
   IF fk3 == "D"; @ box_x_koord() + 8, box_y_koord() + 2   SAY "K3 (" + ck3 + " svi):" GET cK3; ENDIF
   IF fk4 == "D"; @ box_x_koord() + 8, Col() + 1 SAY "K4 (99 svi):" GET cK4; ENDIF

   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Klasa konta duguje " GET cKlDuguje PICT "9"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Klasa konta potraz " GET cKlPotraz PICT "9"

   @ box_x_koord() + 12, box_y_koord() + 2 SAY "Saldo strane valute je bitan ?" GET cStranaBitna ;
      PICT "@!" ;
      VALID cStranaBitna $ "DN"

   READ
   ESC_BCR

   BoxC()

   // snimi parametre
   set_metric( "fin_klasa_duguje", NIL, cKlDuguje )
   set_metric( "fin_klasa_potrazuje", NIL, cKlPotraz )

   lStranaBitna := ( cStranaBitna == "D" )

   IF ck1 == "9"
      ck1 := ""
   ENDIF
   IF ck2 == "9"
      ck2 := ""
   ENDIF
   IF ck3 == REPL( "9", Len( ck3 ) )
      ck3 := ""
   ELSE
      ck3 := k3u256( ck3 )
   ENDIF
   IF ck4 == "99"
      ck4 := ""
   ENDIF

   lPrenos4 := lPrenos5 := lPrenos6 := .F.

   SELECT ( F_PKONTO )
   GO TOP

   DO WHILE !Eof()
      IF tip == "4"
         lPrenos4 := .T.
      ENDIF
      IF tip == "5"
         lPrenos5 := .T.
      ENDIF
      IF tip == "6"
         lPrenos6 := .T.
      ENDIF
      SKIP 1
   ENDDO

   cFilter := ".t."

   IF fk1 == "D" .AND. Len( ck1 ) <> 0
      cFilter += " .and. k1='" + ck1 + "'"
   ENDIF

   IF fk2 == "D" .AND. Len( ck2 ) <> 0
      cFilter += " .and. k2='" + ck2 + "'"
   ENDIF

   IF fk3 == "D" .AND. Len( ck3 ) <> 0
      cFilter += " .and. k3='" + ck3 + "'"
   ENDIF

   IF fk4 == "D" .AND. Len( ck4 ) <> 0
      cFilter += " .and. k4='" + ck4 + "'"
   ENDIF

   IF lPrenos4 .OR. lPrenos5 .OR. lPrenos6
      // SELECT ( F_SUBAN )
      // usex ( "suban" )
      find_suban_by_broj_dokumenta( self_organizacija_id() )
      IF lPrenos4
         INDEX ON idfirma + idkonto + idpartner + idrj + funk + fond TO SUBSUB
      ENDIF
      IF lPrenos5
         INDEX ON idfirma + idkonto + idpartner + idrj + fond TO SUBSUB5
      ENDIF
      IF lPrenos6
         INDEX ON idfirma + idkonto + idpartner + idrj TO SUBSUB6
      ENDIF
      // USE
      // SELECT ( F_SUBAN )
      // usex ( "suban" )
      IF lPrenos4
         SET INDEX TO SUBSUB
         SET ORDER TO TAG "SUBSUB"
      ENDIF
      IF lPrenos5
         SET INDEX TO SUBSUB5
         SET ORDER TO TAG "SUBSUB5"
      ENDIF
      IF lPrenos6
         SET INDEX TO SUBSUB6
         SET ORDER TO TAG "SUBSUB6"
      ENDIF
   ELSE

      find_suban_by_konto_partner( self_organizacija_id() )

      // SELECT ( F_SUBAN )
      // usex ( "suban" )
      // SET ORDER TO TAG "3" - IdFirma+IdKonto+IdPartner+BrDok+dtos(DatDok)"
   ENDIF

   IF !( cFilter == ".t." )
      SELECT ( F_SUBAN )
      SET FILTER TO &( cFilter )
   ENDIF

   // SELECT ( F_PKONTO )
   // use ( "pkonto" )
   // SET ORDER TO TAG "ID"
   O_PKONTO

   o_fin_pripr()

   IF reccount2() <> 0
      MsgBeep( "Priprema mora biti prazna" )
      my_close_all_dbf()
   ENDIF

   my_dbf_zap()
   SET ORDER TO 0

   start_print()

   ?
   ? "Prolazim kroz bazu...."

   SELECT suban
   GO TOP

   lVodeSeRJ := FieldPos( "IDRJ" ) > 0

   Postotak( 1, RECCOUNT2(), "Generacija pocetnog stanja" )

   nProslo := 0

   GO TOP
   // idfirma, idkonto, idpartner, datdok

   dDatVal := CToD( "" )

   // ----------------------------------- petlja 1
   DO WHILE !Eof()

      nRbr := ZadnjiRBR()
      cIdFirma := idfirma

      // ----------------------------------- petlja 2
      DO WHILE !Eof() .AND. cIdFirma == IdFirma

         cIdKonto := IdKonto
         cTipPr := "0" // tip prenosa
         SELECT pkonto
         SEEK Left( cIdKonto, nMjesta )
         IF Found()        // 1 - otvorene stavke, 2 - saldo partnera,
            cTipPr := tip     // 3 - otv.st.bez sabiranja,
         ENDIF             // 4 - salda po konto+partner+rj+funkcija+fond
         // 5 - salda po konto+partner+rj+fond
         // 6 - salda po konto+partner+rj
         SELECT suban

         IF cTipPr == "4"    // mijenjam sort za ovu varijantu
            SET ORDER TO TAG "SUBSUB"
            SEEK cIdFirma + cIdKonto
         ELSEIF cTipPr == "5"    // mijenjam sort za ovu varijantu
            SET ORDER TO TAG "SUBSUB5"
            SEEK cIdFirma + cIdKonto
         ELSEIF cTipPr == "6"    // mijenjam sort za ovu varijantu
            SET ORDER TO TAG "SUBSUB6"
            SEEK cIdFirma + cIdKonto
         ELSEIF lPrenos4 .OR. lPrenos5 .OR. lPrenos6   // standardni sort
            SET ORDER TO TAG "3"
            SEEK cIdFirma + cIdKonto
         ENDIF

         nDin := nDem := 0
         // KONTO....pocinje

         // ----------------------------------- petlja 3
         DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto

            cIdPartner := IdPartner
            ? "Konto:", cidkonto, "    Partner:", cidpartner
            IF cTipPr $ "2"    // sabirem po konto+partner
               nDin := 0
               nDem := 0
            ENDIF

            IF ctippr == "3"
               cSUBk1 := k1
               cSUBk2 := k2
               cSUBk3 := k3
               cSUBk4 := k4

               IF Otvst == " "
                  Scatter()
                  SELECT fin_pripr
                  APPEND BLANK
                  Gather()
                  RREPLACE rbr WITH  ++nRbr, ;
                     idvn WITH "00", ;
                     brnal WITH "00000001"

                  SELECT suban
               ENDIF

               Postotak( 2, ++nProslo )
               SKIP 1

            ELSE // tipppr=="3#

               cSUBk1 := k1
               cSUBk2 := k2
               cSUBk3 := k3
               cSUBk4 := k4

               // ----------------------------------- petlja 4
               DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdPartner == cIdPartner

                  cSUBk1 := k1
                  cSUBk2 := k2
                  cSUBk3 := k3
                  cSUBk4 := k4

                  // tip prenosa otvorene stavke - "1"

                  IF cTipPr == "1"
                     cBrDok := Brdok
                     nDin := 0
                     nDem := 0
                     cOtvSt := otvSt
                     // pretpostavlja se da sve stavke jednog
                     // dokumenta imaju isti znak - otvoren ili zatvoren
                     cTekucaRJ := ""
                     // ----------------------------------- petlja 5
                     dDatVal := CToD( "" )

                     DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. ;
                           IdPartner == cIdPartner .AND. BrDok == cBrDok

                        IF Empty( dDatVal )

                           // konto kupaca
                           IF ( Left( IdKonto, 1 ) == cKlDuguje ) .AND. ( d_p == "1" )
                        --      IF IsVindija()
                      --           IF Empty( DatVal ) .AND. !( IsVindija() .AND. idvn == "09" )
                                    dDatVal := datdok
                                 ELSE
                                    dDatVal := fix_dat_var( datval, .T. )
                                 ENDIF
                              ELSE
                                 IF Empty( fix_dat_var( DatVal, .T. ) )
                                    dDatVal := datdok
                                 ELSE
                                    dDatVal := datval
                                 ENDIF
                              ENDIF
                           ENDIF

                           // konto dobavljaca
                           IF ( Left( IdKonto, 1 ) == cKlPotraz ) .AND. ( d_p == "2" )
                              IF Empty( DatVal )
                                 dDatVal := datdok
                              ELSE
                                 dDatVal := datval
                              ENDIF
                           ENDIF

                        ENDIF

                        nDin += iif( d_p == "1", iznosbhd, -iznosbhd )
                        nDem += iif( d_p == "1", iznosdem, -iznosdem )

                        IF lVodeSeRJ .AND. Empty( cTekucaRJ )
                           cTekucaRJ := IDRJ
                        ENDIF
                        Postotak( 2, ++nProslo )
                        SKIP 1

                     ENDDO // brdok
                     // ----------------------------------- petlja 5

                     // if cOtvSt=="9"
                     IF Round( nDin, 3 ) <> 0  // ako saldo nije 0
                        SELECT fin_pripr
                        APPEND BLANK
                        REPLACE  idfirma WITH cidfirma, ;
                           idvn WITH "00", ;
                           brnal WITH "00000001", ;
                           rbr WITH ++nRbr, ;
                           idkonto WITH cIdkonto, ;
                           idpartner WITH cidpartner, ;
                           brdok  WITH cBrDok, ;
                           datdok WITH dDatDo + 1, ;
                           datval WITH dDatVal

                        IF !( cFilter == ".t." )
                           REPLACE  k1 WITH cSUBk1, ;
                              k2 WITH cSUBk2, ;
                              k3 WITH cSUBk3, ;
                              k4 WITH cSUBk4
                        ENDIF

                        IF cTipPr == "1"
                           IF Left( IdKonto, 1 ) == cKlPotraz
                              // konto dobavljaca
                              REPLACE d_p WITH "2", iznosbhd WITH -nDin, iznosdem WITH -nDem
                           ELSE
                              // konto kupca
                              REPLACE d_p WITH "1", iznosbhd WITH nDin, iznosdem WITH nDem
                           ENDIF

                        ELSE
                           // cTipPr <> "1"
                           IF nDin >= 0
                              REPLACE d_p WITH "1", iznosbhd WITH nDin, iznosdem WITH nDem
                           ELSE
                              REPLACE d_p WITH "2", iznosbhd WITH -nDin, iznosdem WITH -nDem
                           ENDIF
                        ENDIF

                        IF lVodeSeRj
                           REPLACE IDRJ WITH cTekucaRJ
                        ENDIF
                        SELECT suban
                     ENDIF  // limit
                     // endif // cotvst=="9"

                  ENDIF  // cTipPr=="1"

                  IF cTipPr == "4"
                     cIDRJ := IDRJ
                     cFunk := FUNK
                     cFond := FOND
                     nDin := 0; nDem := 0

                     // ----------------------------------- petlja 6
                     DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdPartner == cIdPartner ;
                           .AND. cIDRJ == IDRJ .AND. cFunk == FUNK .AND. cFond == FOND

                        nDin += iif( d_p == "1", iznosbhd, -iznosbhd )
                        nDem += iif( d_p == "1", iznosdem, -iznosdem )
                        Postotak( 2, ++nProslo )
                        SKIP 1

                     ENDDO // brdok
                     // ----------------------------------- petlja 6

                     IF Round( nDin, 3 ) <> 0  // ako saldo nije 0
                        SELECT fin_pripr
                        APPEND BLANK
                        REPLACE  idfirma WITH cidfirma, ;
                           idvn WITH "00", ;
                           brnal WITH "00000001", ;
                           rbr WITH ++nRbr, ;
                           idkonto WITH cIdkonto, ;
                           idpartner WITH cidpartner, ;
                           idrj WITH cIDRJ, ;
                           funk WITH cFunk, ;
                           fond WITH cFond, ;
                           datdok WITH dDatDo + 1

                        IF !( cFilter == ".t." )
                           REPLACE  k1 WITH cSUBk1, ;
                              k2 WITH cSUBk2, ;
                              k3 WITH cSUBk3, ;
                              k4 WITH cSUBk4
                        ENDIF
                        IF nDin >= 0
                           REPLACE d_p WITH "1", iznosbhd WITH nDin, iznosdem WITH nDem
                        ELSE
                           REPLACE d_p WITH "2", iznosbhd WITH -nDin, iznosdem WITH -nDem
                        ENDIF // ndin
                        SELECT suban
                     ENDIF  // limit

                  ENDIF  // cTipPr=="4"

                  IF cTipPr == "5"
                     cIDRJ := IDRJ
                     cFond := FOND
                     nDin := 0; nDem := 0

                     // ----------------------------------- petlja 6
                     DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdPartner == cIdPartner ;
                           .AND. cIDRJ == IDRJ .AND. cFond == FOND

                        nDin += iif( d_p == "1", iznosbhd, -iznosbhd )
                        nDem += iif( d_p == "1", iznosdem, -iznosdem )
                        Postotak( 2, ++nProslo )
                        SKIP 1

                     ENDDO // brdok
                     // ----------------------------------- petlja 6

                     IF Round( nDin, 3 ) <> 0  // ako saldo nije 0
                        SELECT fin_pripr
                        APPEND BLANK
                        REPLACE  idfirma WITH cidfirma, ;
                           idvn WITH "00", ;
                           brnal WITH "00000001", ;
                           rbr WITH ++nRbr, ;
                           idkonto WITH cIdkonto, ;
                           idpartner WITH cidpartner, ;
                           idrj WITH cIDRJ, ;
                           fond WITH cFond, ;
                           datdok WITH dDatDo + 1
                        IF !( cFilter == ".t." )
                           REPLACE  k1 WITH cSUBk1, ;
                              k2 WITH cSUBk2, ;
                              k3 WITH cSUBk3, ;
                              k4 WITH cSUBk4
                        ENDIF
                        IF nDin >= 0
                           REPLACE d_p WITH "1", iznosbhd WITH nDin, iznosdem WITH nDem
                        ELSE
                           REPLACE d_p WITH "2", iznosbhd WITH -nDin, iznosdem WITH -nDem
                        ENDIF // ndin
                        SELECT suban
                     ENDIF  // limit

                  ENDIF  // cTipPr=="5"

                  IF cTipPr == "6"
                     cIDRJ := IDRJ
                     nDin := 0; nDem := 0

                     // ----------------------------------- petlja 6
                     DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdPartner == cIdPartner ;
                           .AND. cIDRJ == IDRJ

                        nDin += iif( d_p == "1", iznosbhd, -iznosbhd )
                        nDem += iif( d_p == "1", iznosdem, -iznosdem )
                        Postotak( 2, ++nProslo )
                        SKIP 1

                     ENDDO // brdok
                     // ----------------------------------- petlja 6

                     IF Round( nDin, 3 ) <> 0  // ako saldo nije 0
                        SELECT fin_pripr
                        APPEND BLANK
                        REPLACE  idfirma WITH cidfirma, ;
                           idvn WITH "00", ;
                           brnal WITH "00000001", ;
                           rbr WITH ++nRbr, ;
                           idkonto WITH cIdkonto, ;
                           idpartner WITH cidpartner, ;
                           idrj WITH cIDRJ, ;
                           datdok WITH dDatDo + 1
                        IF !( cFilter == ".t." )
                           REPLACE  k1 WITH cSUBk1, ;
                              k2 WITH cSUBk2, ;
                              k3 WITH cSUBk3, ;
                              k4 WITH cSUBk4
                        ENDIF
                        IF nDin >= 0
                           REPLACE d_p WITH "1", iznosbhd WITH nDin, iznosdem WITH nDem
                        ELSE
                           REPLACE d_p WITH "2", iznosbhd WITH -nDin, iznosdem WITH -nDem
                        ENDIF // ndin
                        SELECT suban
                     ENDIF  // limit

                  ENDIF  // cTipPr=="6"

                  IF cTipPr $ "02"
                     IF d_p == "1"
                        nDin += iznosbhd
                        nDem += IznosDEM
                     ENDIF
                     IF d_p == "2"
                        nDin -= iznosbhd
                        nDem -= IznosDEM
                     ENDIF
                     SKIP 1
                     Postotak( 2, ++nProslo )
                  ENDIF

               ENDDO // konto, partner
               // ----------------------------------- petlja 4

            ENDIF    // tippr=="3"

            IF cTipPr == "2"  // sabirem po konto+partner
               IF ( Round( nDin, 2 ) <> 0 ) .OR. ( ( Round( nDem, 2 ) <> 0 ) .AND. lStranaBitna )
                  SELECT fin_pripr
                  APPEND BLANK
                  REPLACE rbr WITH  Str( ++nRbr, 5 ), ;
                     idkonto WITH cIdkonto, ;
                     idpartner WITH cidpartner, ;
                     datdok WITH dDatDo + 1, ;
                     idfirma WITH cidfirma, ;
                     idvn WITH "00", idtipdok WITH "00", ;
                     brnal WITH "00000001"
                  IF !( cFilter == ".t." )
                     REPLACE  k1 WITH cSUBk1, ;
                        k2 WITH cSUBk2, ;
                        k3 WITH cSUBk3, ;
                        k4 WITH cSUBk4
                  ENDIF

                  IF nDin >= 0
                     REPLACE d_p WITH "1", ;
                        iznosbhd WITH nDin, ;
                        iznosdem WITH nDem
                  ELSE
                     REPLACE d_p WITH "2", ;
                        iznosbhd WITH -nDin, ;
                        iznosdem WITH -nDem
                  ENDIF // ndin

                  SELECT suban
               ENDIF // <> 0
            ENDIF

         ENDDO // konto
         // ----------------------------------- petlja 3

         IF cTipPr == "0"  // sabirem po konto bez obzira na partnera
            IF ( Round( nDin, 2 ) <> 0 ) .OR. ( Round( nDem, 2 ) <> 0  .AND. lStranaBitna )
               SELECT fin_pripr
               APPEND BLANK
               REPLACE rbr WITH  Str( ++nRbr, 5 ), ;
                  idkonto WITH cIdkonto, ;
                  datdok WITH dDatDo + 1, ;
                  idfirma WITH cidfirma, ;
                  idvn WITH "00", idtipdok WITH "00", ;
                  brnal WITH "00000001"
               IF !( cFilter == ".t." )
                  REPLACE  k1 WITH cSUBk1, ;
                     k2 WITH cSUBk2, ;
                     k3 WITH cSUBk3, ;
                     k4 WITH cSUBk4
               ENDIF
               IF nDin >= 0
                  REPLACE d_p WITH "1", ;
                     iznosbhd WITH nDin, ;
                     iznosdem WITH nDem
               ELSE
                  REPLACE d_p WITH "2", ;
                     iznosbhd WITH -nDin, ;
                     iznosdem WITH -nDem
               ENDIF // ndin
               SELECT suban
            ENDIF // <> 0
         ENDIF

      ENDDO // firma
      // ----------------------------------- petlja 2

   ENDDO // eof
   // ----------------------------------- petlja 1

   Postotak( 0 )

   end_print()

   my_close_all_dbf()

   RETURN



// ----------------------------------------------------------------
// kreiranje pomocne tabele temp77
// ----------------------------------------------------------------




FUNCTION ZadnjiRBR()

   LOCAL nZRBR := 0
   LOCAL nObl := Select()

   o_fin_pripr()
   GO BOTTOM
   nZRBR := Val( rbr )
   SELECT ( nObl )

   RETURN ( nZRBR )
*/
