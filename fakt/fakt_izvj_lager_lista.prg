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

MEMVAR dDatOd, dDatDo

FUNCTION fakt_lager_lista()

   PARAMETERS lPocStanje, cIdFirma, qqRoba, dDatOd, dDatDo

   LOCAL nKU, nKI, lSaberiKol
   LOCAL GetList := {}
   LOCAL aPorezi := {}, cPoTar := "N"
   LOCAL oPdf, xPrintOpt, bZagl

   IF !is_legacy_ptxt()
      oPDF := PDFClass():New()
      xPrintOpt := hb_Hash()
      xPrintOpt[ "tip" ] := "PDF"
      xPrintOpt[ "layout" ] := "portrait"
      xPrintOpt[ "opdf" ] := oPDF
      xPrintOpt[ "left_space" ] := 0
   ENDIF

   bZagl := {|| fakt_zagl_lager_lista() }

   PRIVATE nRezerv, nRevers
   PRIVATE nUl, nIzl, nRbr, cRR, nCol1 := 0
   PRIVATE m := ""

   // tekuca strana
   PRIVATE nStr := 0
   PRIVATE cProred := "N"
   PRIVATE nGrZn := 99
   PRIVATE cLastIdRoba := ""

   lBezUlaza := .F.

   IF lPocStanje == NIL
      lPocStanje := .F.
   ELSE
      lPocStanje := .T.
      o_fakt_pripr()
      nRbrPst := 0
      cBrDokPocStanje := "00001   "
      Box(, 2, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Generacija poc. stanja  - broj dokumenta 00 -" GET cBrDokPocStanje
      READ
      BoxC()
   ENDIF

   IF lPocStanje
      // PRIVATE fId_J := .F.
      // IF my_get_from_ini( "SifRoba", "ID_J", "N" ) == "D"
      // fId_J := .T.
      // ENDIF
   ENDIF


   lSaberikol := .F.
   nKU := nKI := 0

   cIdfirma := self_organizacija_id()
   qqRoba := ""
   dDatOd := CToD( "" )
   dDatDo := Date()


   cSaldo0 := "N"
   qqPartn := Space( 20 )
   PRIVATE qqTipdok := "  "

   Box(, 20, 66 )

   o_params()
   PRIVATE cSection := "5"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}
   Params1()


   RPar( "c1", @cIdFirma )
   RPar( "c2", @qqRoba )
   RPar( "c7", @qqPartn )
   RPar( "c8", @qqTipDok )
   RPar( "d1", @dDatOd )
   RPar( "d2", @dDatDo )


   qqRoba := PadR( qqRoba, 60 )
   qqPartn := PadR( qqPartn, 20 )
   qqTipDok := PadR( qqTipDok, 2 )

   cRR := "N"
   cUI := "S"

   PRIVATE cTipVPC := "1"

   cK1 := cK2 := Space( 4 )

   DO WHILE .T.

      fakt_getlist_rj_read( box_x_koord() + 1, box_y_koord() + 2, @GetList, @cIdFirma )

      // IF gNW $ "DR"
      // @ box_x_koord() + 1, box_y_koord() + 2 SAY "RJ (prazno svi) " GET cIdFirma valid {|| Empty( cIdFirma ) .OR. cidfirma == self_organizacija_id() .OR. P_RJ( @cIdFirma ), cIdFirma := Left( cIdFirma, 2 ), .T. }
      // ELSE
      // @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
      // ENDIF
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Roba   "  GET qqRoba   PICT "@!S40"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Naziv partnera (prazno - svi)"  GET qqPartn   PICT "@!"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tip dokumenta (prazno - svi)"  GET qqTipdok
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Od datuma "  GET dDatOd
      @ box_x_koord() + 5, Col() + 1 SAY "do"  GET dDatDo

      IF lBezUlaza
         cRR := "N"
      ELSE
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prikaz rezervacija, reversa (D)"
         @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz bez rezervacija, reversa (N)"
         @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz fakturisanog na osnovu otpremnica (F) "  GET cRR   PICT "@!" VALID cRR $ "DNF"
      ENDIF

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikaz stavki sa stanjem 0 (D/N)    "  GET cSaldo0 PICT "@!" VALID cSaldo0 $ "DN"
      IF gVarC $ "12"
         @ box_x_koord() + 11, box_y_koord() + 2 SAY "Stanje prikazati sa Cijenom 1/2 (1/2) "  GET cTipVpc PICT "@!" VALID cTipVPC $ "12"
      ENDIF
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Napraviti prored (D/N)    "  GET cProred PICT "@!" VALID cProred $ "DN"
      IF !lPocStanje
         @ box_x_koord() + 13, box_y_koord() + 2 SAY "Prikaz grupacija, grupa ima (99-ne prikazivati)" GET nGrZn PICT "99"
         @ box_x_koord() + 13, box_y_koord() + 53 SAY "znakova"
      ENDIF
      IF gDK1 == "D"
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "K1" GET  cK1 PICT "@!"
         @ box_x_koord() + 14, box_y_koord() + 15 SAY "K2" GET  cK2 PICT "@!"
      ENDIF

      cPopis := "N"
      @ box_x_koord() + 15, box_y_koord() + 2 SAY "Prikazati obrazac za popis D/N" GET  cPopis PICT "@!" VALID cPopis $ "DN"

      cRealizacija := "N"
      IF !lBezUlaza
         @ Row() + 1, box_y_koord() + 2 SAY "Prikazati realizaciju " GET  cRealizacija PICT "@!" VALID cRealizacija $ "DN"
      ENDIF

      cSintetika := "N"

      IF !lPocStanje .AND. cSintetika == "D"
         @ Row() + 1, box_y_koord() + 2 SAY "Sinteticki prikaz? (D/N) " GET  cSintetika PICT "@!" VALID cSintetika $ "DN"
      ELSE
         cSintetika := "N"
      ENDIF

      IF !lBezUlaza
         @ Row() + 1, box_y_koord() + 2 SAY "Prikaz kolicina (U-samo ulaz, I-samo izlaz, S-sve)" GET cUI VALID cUI $ "UIS" PICT "@!"
      ELSE
         cUI := "S"
      ENDIF

      @ Row() + 1, box_y_koord() + 2 SAY "Prikaz stanja po tarifama? (D/N)" GET cPoTar VALID cPoTar $ "DN" PICT "@!"

      READ

      ESC_BCR
      // IF fID_J
      // aUsl1 := Parsiraj( qqRoba, "IdRoba_J" )
      // ELSE
      aUsl1 := Parsiraj( qqRoba, "IdRoba" )
      // ENDIF

      IF aUsl1 <> NIL
         EXIT
      ENDIF

   ENDDO

   IF lBezUlaza
      m := "---- ---------- ----------------------------------------" + " ----------- ---"
   ELSE

      IF cRR $ "NF"
         m := "---- ---------- ----------------------------------------" + iif( cUI == "S", " ----------- -----------", "" ) + " ----------- --- --------- -----------"
      ELSE
         m := "---- ---------- ----------------------------------------" + " ----------- ----------- ----------- ----------- --- --------- -----------"
      ENDIF

      IF gVarC == "4"
         m += " " + Replicate( "-", 12 )
      ENDIF

      IF cRealizacija == "D"
         m += " " + Replicate( "-", 12 ) + " " + Replicate( "-", 12 )
      ENDIF
   ENDIF


   SELECT params
   qqRoba := Trim( qqRoba )


   WPar( "c1", cIdFirma )
   WPar( "c2", qqRoba )
   WPar( "c7", qqPartn )
   WPar( "c8", qqTipDok )
   WPar( "d1", dDatOd )
   WPar( "d2", dDatDo )

   USE

   BoxC()

   //fSMark := .F.
   //IF Right( qqRoba, 1 ) = "*"
      // izvrsena je markacija robe ..
  //    fSMark := .T.
   //ENDIF


   PRIVATE cFilt := ".t."

   IF aUsl1 <> ".t."
      cFilt += ".and." + aUsl1
   ENDIF

   IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
      cFilt += ".and. DatDok>=" + dbf_quote( dDatOd ) + ".and. DatDok<=" + dbf_quote( dDatDo )
   ENDIF

   find_fakt_za_period( cIdFirma, dDatOd, dDatDo, NIL, NIL, "3" )

   IF cFilt == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilt
   ENDIF
   GO TOP
   EOF CRET

   IF HB_ISHASH( xPrintOpt )
      xPrintOpt[ "header" ] := "FAKT Lager lista " + my_database() + " na dan " + DToC( Date() ) + " za period od " + DToC( dDatOd ) + " - " + DToC( dDatDo )
   ENDIF

   IF !start_print( xPrintOpt )
      RETURN .F.
   ENDIF

   Eval( bZagl )

   _cijena := 0
   _cijena2 := 0

   nRbr := 0
   nIzn := 0
   nIzn2 := 0
   nIznR := 0 // iznos rabata
   nRezerv := nRevers := 0
   qqPartn := Trim( qqPartn )
   cidfirma := Trim( cidfirma )

   IF cSintetika == "D"
      bWhile1 := {|| !Eof() .AND. Left( cIdroba, gnDS ) == Left( IdRoba, gnDS )  }
   ELSE
      // IF fId_J
      // bWhile1 := {|| !Eof() .AND. cIdRoba == IdRoba_J + IdRoba }
      // ELSE
      bWhile1 := {|| !Eof() .AND. cIdRoba == IdRoba }
      // ENDIF
   ENDIF

   DO WHILE !Eof()
      // IF fID_J
      // cIdRoba := IdRoba_J + IdRoba
      // ELSE
      cIdRoba := IdRoba
      // ENDIF

      IF cSintetika == "D"
         fakt_set_pozicija_sif_roba( cIdRoba, .T. )
         SELECT FAKT
      ENDIF

      nUl := nIzl := 0
      nRezerv := nRevers := 0
      // nReal1 realizacija , nReal2 - rabat
      nReal1 := 0
      nReal2 := 0

      IF cSintetika == "D"
         bWhile1 := {|| !Eof() .AND. ;
            Left( cIdroba, gnDS ) == Left( IdRoba, gnDS ) }
      ELSE
         // IF fId_J
         // bWhile1 := {|| !Eof() .AND. cIdRoba == IdRoba_J + IdRoba  }
         // ELSE
         bWhile1 := {|| !Eof() .AND. cIdRoba == IdRoba }
         // ENDIF
      ENDIF

      DO WHILE Eval( bWhile1 )

         IF !Empty( qqTipDok )
            IF idtipdok <> qqTipDok
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( cidfirma )
            IF idfirma <> cidfirma
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( qqPartn )
            seek_fakt_doks( fakt->IdFirma, fakt->idtipdok, fakt->brdok )
            SELECT fakt

            IF !( fakt_doks->partner = qqPartn )
               SKIP
               LOOP
            ENDIF
         ENDIF

         // atributi
         IF !Empty( cK1 ); IF ck1 <> K1; skip; loop; end; END

         IF !Empty( cK2 ); IF ck2 <> K2;  skip; loop; end; END

         IF !Empty( cIdRoba )
            IF cRR <> "F"
               // ulaz
               IF idtipdok = "0"
                  nUl += kolicina
                  IF lSaberikol .AND. !( roba->K2 = 'X' )
                     nKU += kolicina
                  ENDIF
                  // izlaz faktura
               ELSEIF idtipdok = "1"
                  IF !( serbr = "*" .AND. idtipdok == "10" ) // za fakture na osnovu otpremnice ne racunaj izlaz
                     nIzl += kolicina
                     nReal1 += Round( kolicina * Cijena, fakt_zaokruzenje() )
                     nReal2 += Round( kolicina * Cijena * ( Rabat / 100 ), fakt_zaokruzenje() )
                     IF lSaberikol .AND. !( roba->K2 = 'X' )
                        nKI += kolicina
                     ENDIF
                  ENDIF
               ELSEIF idtipdok $ "20#27"
                  IF serbr = "*"
                     nRezerv += kolicina
                  ENDIF
               ELSEIF idtipdok == "21"
                  nRevers += kolicina
                  IF lSaberikol .AND. !( roba->K2 = 'X' )
                     nKI += kolicina
                  ENDIF
               ENDIF
            ELSE
               // za fakture na osnovu otpremince ne racunaj izlaz
               IF ( serbr = "*" .AND. idtipdok == "10" )
                  nIzl += kolicina
                  // finansijski da !
                  nReal1 += Round( kolicina * Cijena, fakt_zaokruzenje() )
                  nReal2 += Round( kolicina * Cijena * ( Rabat / 100 ), fakt_zaokruzenje() )
                  IF lSaberikol .AND. !( roba->K2 = 'X' )
                     nKI += kolicina
                  ENDIF
               ENDIF
            ENDIF // crr=="F"
         ENDIF  // empty(
         SKIP
      ENDDO

      check_nova_strana( bZagl, oPDF )

      IF !Empty( cIdRoba )
         IF !( cSaldo0 == "N" .AND. ( nUl - nIzl ) == 0 )
            // IF fID_J
            // fakt_set_pozicija_sif_roba( SubStr( cIdRoba, 11 ), ( cSintetika == "D" ) )
            // desni dio sifre je interna sifra
            // ELSE
            fakt_set_pozicija_sif_roba( cIdRoba, ( cSintetika == "D" ) )
            // ENDIF

            IF nGrZn <> 99 .AND. ( Empty( cLastIdRoba ) .OR. Left( cLastIdRoba, nGrZn ) <> Left( cIdRoba, nGrZn ) )

               PushWA()
               select_o_roba( Left( cIdRoba, nGrZn ) )
               IF Found() .AND. Right( Trim( id ), 1 ) == "."
                  cNazivGrupacije := Left( cIdRoba, nGrZn ) + " " + naz
               ELSE
                  cNazivGrupacije := Left( cIdRoba, nGrZn )
               ENDIF
               PopWA()
               IF cProred == "D"
                  ? Space( gnLMarg ); ?? m
               ENDIF
               ? Space( gnLMarg )
               ?? "GRUPA ARTIKALA: " + cNazivGrupacije
               cLastIdRoba := cIdRoba
            ENDIF
            SELECT FAKT
            IF cProred == "D"
               ? Space( gnLMarg ); ?? m
            ENDIF
            ? Space( gnLMarg )
            ?? Str( ++nRbr, 4 ), ;
               IF( cSintetika == "D" .AND. ROBA->tip == "S", ;
               ROBA->id, Left( cidroba, 10 ) ), PadR( ROBA->naz, 40 )

            IF cRR $ "NF" .AND. !lBezUlaza
               IF cUI $ "US"
                  @ PRow(), PCol() + 1 SAY nUl  PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
               ENDIF
               IF cUI $ "IS"
                  @ PRow(), PCol() + 1 SAY nIzl PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
               ENDIF
            ENDIF

            IF lBezUlaza
               nCol1 := PCol() + 1
            ENDIF
            IF cUI == "S"
               @ PRow(), PCol() + 1 SAY nUl - nIzl PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
            ENDIF

            IF cRR == "D"
               @ PRow(), PCol() + 1 SAY nRevers PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
               @ PRow(), PCol() + 1 SAY nRezerv PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
               @ PRow(), PCol() + 1 SAY nUl - nIzl - nRevers - nRezerv PICT iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
            ENDIF
            @ PRow(), PCol() + 1 SAY roba->jmj
            IF cTipVPC == "2" .AND.  roba->( FieldPos( "vpc2" ) <> 0 )
               _cijena := roba->vpc2
            ELSE
               _cijena := IF ( !Empty( cIdFirma ), fakt_mpc_iz_sifrarnika(), roba->vpc )
            ENDIF
            IF gVarC == "4"
               _cijena2 := roba->mpc
            ENDIF

            IF lPocStanje
               SELECT fakt_pripr
               IF cRR = "D"
                  nPrenesi := -nRevers - nRezerv
               ELSE
                  nPrenesi := nUl - nIzl
               ENDIF
               IF Round( nPrenesi, 4 ) <> 0
                  APPEND BLANK
                  REPLACE idfirma WITH cidfirma, idroba WITH Left( cIdRoba, 10 ), ;
                     datdok WITH dDatDo + 1, ;
                     idtipdok WITH "00", brdok WITH cBrDokPocStanje, ;
                     cijena WITH _cijena, ;
                     dindem WITH "KM ", ;
                     Rbr WITH rbr_u_char( ++nRbrPst ), ;
                     kolicina WITH nPrenesi

                  // IF fId_J
                  // REPLACE idroba_J WITH Left( cIdRoba, 10 ), ;
                  // idroba WITH SubStr( cIdroba, 11 )
                  // ENDIF
                  REPLACE txt   WITH Chr( 16 ) + "" + Chr( 17 ) + ;
                     Chr( 16 ) + "" + Chr( 17 ) + Chr( 16 ) + "POCETNO STANJE" + Chr( 17 ) + ;
                     Chr( 16 ) + "" + Chr( 17 ) + Chr( 16 ) + "" + Chr( 17 )

               ENDIF
               SELECT fakt
            ENDIF

            IF cPoTar == "D"
               nMpv := ( nUl - nIzl ) * roba->mpc
               nPom := AScan( aPorezi, {| x | x[ 1 ] == roba->idTarifa } )
               IF nPom > 0
                  aPorezi[ nPom, 2 ] := aPorezi[ nPom, 2 ] + nMpv
               ELSE
                  AAdd( aPorezi, { roba->idTarifa, nMpv } )
               ENDIF
            ENDIF

            IF cRealizacija == "D"
               IF nIzl > 0
                  @ PRow(), PCol() + 1 SAY ( nReal1 - nReal2 ) / nIzl  PICT "99999.999"
               ELSE
                  @ PRow(), PCol() + 1 SAY 0  PICT "99999.999"
               ENDIF
               nCol1 := PCol() + 1
               @ PRow(), nCol1 SAY nReal1  PICT fakt_pic_iznos()
               @ PRow(), PCol() + 1 SAY nReal2  PICT fakt_pic_iznos()
               @ PRow(), PCol() + 1 SAY nReal1 - nReal2  PICT fakt_pic_iznos()
               nIzn += nReal1
               nIznR += nReal2
            ELSE
               nPomSt := IF( cUI == "S", nUl - nIzl, IF( cUI == "I", nIzl, nUl ) )
               IF !lBezUlaza
                  @ PRow(), PCol() + 1 SAY _cijena  PICT "99999.999"
                  nCol1 := PCol() + 1
                  @ PRow(), nCol1 SAY nPomSt * _cijena   PICT iif( cPopis == "N", fakt_pic_iznos(), Replicate( "_", Len( fakt_pic_iznos() ) ) )
               ENDIF
               nIzn += nPomSt * _cijena
               IF gVarC == "4" // uporedo
                  IF !lBezUlaza
                     @ PRow(), PCol() + 1 SAY _cijena2   PICT fakt_pic_iznos()
                  ENDIF
                  nIzn2 += nPomSt * _cijena2
               ENDIF
            ENDIF

         ENDIF
      ENDIF

   ENDDO


   check_nova_strana( bZagl, oPDF )

   IF !lBezUlaza
      ? Space( gnLMarg )
      ?? m
      ? Space( gnLMarg )
      ?? " Ukupno:"
      IF cPopis == "N"
         @ PRow(), nCol1 SAY nIzn  PICT fakt_pic_iznos()
         IF cRealizacija == "D"
            @ PRow(), PCol() + 1 SAY nIznR  PICT fakt_pic_iznos()
            @ PRow(), PCol() + 1 SAY nIzn - nIznR  PICT fakt_pic_iznos()
         ENDIF
         IF gVarC == "4"
            ? Space( gnLMarg )

            ?? " Ukupno  PV:"


            @ PRow(), nCol1 SAY nIzn2  PICT fakt_pic_iznos()
         ENDIF
      ENDIF
   ENDIF

   ? Space( gnLMarg )
   ?? m

   IF lSaberikol
      ? Space( gnLMarg ); ?? " Ukupno (kolicine):"
      IF lBezUlaza
         @ PRow(), nCol1 SAY nKU - nKI PICTURE iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
      ELSE
         IF cUI $ "US"
            @ PRow(), nCol1 - ( Len( fakt_pic_iznos() ) + 1 ) * 4 - 2  SAY nKU  PICTURE iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
         ENDIF
         IF cUI $ "IS"
            IF cUI == "I"
               @ PRow(), nCol1 - ( Len( fakt_pic_iznos() ) + 1 ) * 4 - 2 SAY nKI  PICTURE iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
            ELSE
               @ PRow(), PCol() + 1 SAY nKI  PICTURE iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
            ENDIF
         ENDIF
         IF cUI == "S"
            @ PRow(), PCol() + 1 SAY nKU - nKI PICTURE iif( cPopis == "N", fakt_pic_kolicina(), Replicate( "_", Len( fakt_pic_kolicina() ) ) )
         ENDIF
      ENDIF
      ? Space( gnLMarg )
      ?? m
   ENDIF

   IF cPoTar == "D"

      check_nova_strana( bZagl, oPDF )

      ?
      z0 := "Rekapitulacija stanja po tarifama:"
      ? z0
      m := "------" + REPL( " " + REPL( "-", Len( gPicProc ) ), 3 ) + REPL( " " + REPL( "-", Len( fakt_pic_iznos() ) ), 5 )
      ? m
      z1 := "Tarifa" + PadC( "PPP%", Len( gPicProc ) + 1 ) + PadC( "PPU%", Len( gPicProc ) + 1 ) + PadC( "PP%", Len( gPicProc ) + 1 ) + PadC( "MPV", Len( fakt_pic_iznos() ) + 1 ) + PadC( "PPP", Len( fakt_pic_iznos() ) + 1 ) + PadC( "PPU", Len( fakt_pic_iznos() ) + 1 ) + PadC( "PP", Len( fakt_pic_iznos() ) + 1 ) + PadC( "MPV+por", Len( fakt_pic_iznos() ) + 1 )
      ? z1
      ? m
      ASort( aPorezi, {| x, y | x[ 1 ] < y[ 1 ] } )
      nUMPV := nUMPV0 := nUPor1 := nUPor2 := nUPor3 := 0
      FOR i := 1 TO Len( aPorezi )
         IF check_nova_strana( bZagl, oPDF )
            ?
            ? z0
            ? m
            ? z1
            ? m
         ENDIF
         select_o_tarifa( aPorezi[ i, 1 ] )
         fakt_vt_porezi()
         nMPV := aPorezi[ i, 2 ]
         nMPV0 := Round( nMPV / ( 1 + _PDV ) , fakt_zaokruzenje() )
         nPor1 := Round( nMPV / ( 1 + _PDV ) * _PDV, fakt_zaokruzenje() )
         nPor2 := Round( 0, fakt_zaokruzenje() )
         nPor3 := Round( 0, fakt_zaokruzenje() )
         ? aPorezi[ i, 1 ], TRANS( 100 * _PDV, gPicProc ), TRANS( 0,  gPicProc ), TRANS( 0, gPicProc ), TRANS( nMPV0, fakt_pic_iznos() ), TRANS( nPor1, fakt_pic_iznos() ), TRANS( nPor2, fakt_pic_iznos() ), TRANS( nPor3, fakt_pic_iznos() ), TRANS( nMPV, fakt_pic_iznos() )
         nUMPV += nMPV
         nUMPV0 += nMPV0
         nUPor1 += nPor1
         nUPor2 += nPor2
         nUPor3 += nPor3
      NEXT
      ? m
      ? PadR( "UKUPNO:", 3 * ( Len( gPicProc ) + 1 ) + 6 ), TRANS( nUMPV0, fakt_pic_iznos() ), TRANS( nUPor1, fakt_pic_iznos() ), TRANS( nUPor2, fakt_pic_iznos() ), TRANS( nUPor3, fakt_pic_iznos() ), TRANS( nUMPV, fakt_pic_iznos() )
      ?
   ENDIF

   end_print( xPrintOpt )

   my_close_all_dbf()

   RETURN .T.



FUNCTION fakt_zagl_lager_lista()

   LOCAL cPomZK

   IF is_legacy_ptxt()
      ?
      P_COND
      ? Space( 4 ), "   FAKT: Lager lista robe na dan", Date(), "      za period od", DToC( dDatOd ), "-", DToC( dDatDo ), Space( 6 ), "Strana:", Str( ++nStr, 3 )
      ?
   ENDIF

   IF cUI == "U"
      ? Space( 4 ), "         (prikaz samo ulaza)"
      ?
   ELSEIF cUI == "I"
      ? Space( 4 ), "         (prikaz samo izlaza)"
      ?
   ENDIF

   IF cRR == "D"
      P_COND2
   ELSE
      P_COND
   ENDIF

   IF cRealizacija == "D"
      P_COND2
      ?
      ? Space( gnLMarg )
      ?? "**** FINANSIJSKI: PRIKAZ REALIZACIJE *****"
      ?
   ENDIF

   ? Space( gnLMarg )
   IspisFirme( cidfirma )

   IF !Empty( qqRoba )
      ? Space( gnLMarg )
      ?? "Roba:", qqRoba
   ENDIF

   IF !Empty( cK1 )
      ?
      ? Space( gnlmarg ), "- Roba sa osobinom K1:", ck1
   ENDIF

   IF !Empty( cK2 )
      ?
      ? Space( gnlmarg ), "- Roba sa osobinom K2:", ck2
   ENDIF

   ?
   IF cRealizacija == "N" .AND. cTipVPC == "2" .AND.  roba->( FieldPos( "vpc2" ) <> 0 )
      ? Space( gnlmarg )
      ?? "U CJENOVNIKU SU PRIKAZANE CIJENE: " + cTipVPC
   ENDIF

   ?
   ? Space( gnLMarg )
   ?? m
   ? Space( gnLMarg )

   IF lBezUlaza
      ?? "R.br  Sifra       Naziv                                  "  + "  Stanje    jmj     "
   ELSE
      cPomZK := iif( cUI $ "US", PadC( "Ulaz", 12 ), "" ) + ;
         IF( cUI $ "IS", PadC( "Izlaz", 12 ), "" ) + ;
         IF( cUI $ "S", PadC( "Stanje", 12 ), "" )
      IF cRR $ "NF"

         ?? "R.br  Sifra       Naziv                                  " + cPomZK + "jmj     " + "Cij." + ;
            iif( cREalizacija == "N", "      Iznos", "       PV        Rabat      Realizovano" )

      ELSE
         ?? "R.br  Sifra       Naziv                                  " + "  Stanje       Revers    Rezervac.   Ostalo     jmj     " +  "Cij.  Cij." + "*Stanje"
      ENDIF
      IF gVarC == "4"
         ?? PadC( "MPV", 13 )
      ENDIF
   ENDIF

   ? Space( gnLMarg )
   ?? m

   RETURN .T.




// -----------------------------------------------------------------
// uslovi izvjestaja lager lista
// -----------------------------------------------------------------
FUNCTION fakt_lager_lista_vars( hParams, lPocetnoStanje )

   LOCAL _ret := 1
   LOCAL nX := 1
   LOCAL _id_firma, _usl_roba, _usl_partn, _usl_tip_dok
   LOCAL _date_from, _date_to
   LOCAL _stavke_nula, _tip_prikaza
   LOCAL _date_ps
   LOCAL GetList := {}

   IF lPocetnoStanje == NIL
      // nije pocetno stanje
      _date_ps := NIL
      lPocetnoStanje := .F.
      _date_from := fetch_metric( "fakt_lager_lista_datum_od", my_user(), Date() )
      _date_to := fetch_metric( "fakt_lager_lista_datum_do", my_user(), Date() )
   ELSE
      // pocetno stanje je u pitanju
      _date_ps := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
      _date_from := CToD( "01.01." + AllTrim( Str( Year( Date() ) - 1 ) ) )
      _date_to := CToD( "31.12." + AllTrim( Str( Year( Date() ) - 1 ) ) )
   ENDIF

   _stavke_nula := "N"
   _tip_prikaza := "S"
   _usl_roba := Space( 300 )
   _usl_partn := Space( 300 )
   _usl_tip_dok := Space( 200 )
   _id_firma := self_organizacija_id()

   Box(, 10, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "RJ (prazno-sve): " GET _id_firma VALID {|| Empty( _id_firma ), P_RJ( @_id_firma ), _id_firma := Left( _id_firma, 2 ), .T. }

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od:" GET _date_from
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET _date_to
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Roba   " GET _usl_roba PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Naziv partnera (prazno - svi)" GET _usl_partn PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Tip dokumenta (prazno - svi)" GET _usl_tip_dok PICT "@S40"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz stavki sa stanjem 0 (D/N)    " GET _stavke_nula PICT "@!" VALID _stavke_nula $ "DN"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz količina ( U-samo ulaz, I-samo izlaz, S-sve )" GET _tip_prikaza VALID _tip_prikaza $ "UIS" PICT "@!"

   IF lPocetnoStanje
      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Datum početnog stanja:" GET _date_ps
   ENDIF

   READ

   BoxC()

   IF LastKey() == K_ESC
      _ret := 0
   ENDIF

   // snimi db parametre
   // nemoj ako je pocetno stanje u pitanju...
   IF !lPocetnoStanje
      set_metric( "fakt_lager_lista_datum_od", my_user(), _date_from )
      set_metric( "fakt_lager_lista_datum_do", my_user(), _date_to )
   ENDIF

   // snimi parametre
   hParams[ "datum_od" ] := _date_from
   hParams[ "datum_do" ] := _date_to
   hParams[ "datum_ps" ] := _date_ps
   hParams[ "artikli" ] := _usl_roba
   hParams[ "partneri" ] := _usl_partn
   hParams[ "dokumenti" ] := _usl_tip_dok
   hParams[ "stavke_nula" ] := _stavke_nula
   hParams[ "tip_prikaza" ] := _tip_prikaza
   hParams[ "id_firma" ] := _id_firma

   RETURN _ret


// -----------------------------------------------------------------
// generisanje xml fajla za lager listu
// -----------------------------------------------------------------
STATIC FUNCTION lager_lista_xml( table, hParams )

   LOCAL _ret := .T.
   LOCAL _row
   LOCAL cIdRoba, _ulaz, _izlaz, _stanje
   LOCAL _count := 0
   LOCAL _t_ulaz := 0
   LOCAL _t_izlaz := 0
   LOCAL _t_stanje := 0

   // o_roba()
   // o_partner()

   // ima li zapisa...
   IF table:LastRec() == 0
      RETURN .F.
   ENDIF

   create_xml( _xml )
   xml_subnode( "lager", .F. )

   // podaci zaglavlja...
   // xml_node( "firma", self_organizacija_id() )
   // xml_node( "datum_od", self_organizacija_id() )
   // xml_node( "datum_do", self_organizacija_id() )
   // xml_node( "roba", self_organizacija_id() )

   table:GoTo( 1 )

   DO WHILE !table:Eof()

      _row := table:GetRow()

      cIdRoba := _row:FieldGet( _row:FieldPos( "idroba" ) )
      _ulaz := _row:FieldGet( _row:FieldPos( "ulaz" ) )
      _izlaz := _row:FieldGet( _row:FieldPos( "izlaz" ) )

      IF hParams[ "tip_prikaza" ] == "U"
         _izlaz := 0
      ELSEIF hParams[ "tip_prikaza" ] == "I"
         _ulaz := 0
      ENDIF

      _stanje := ( _ulaz - _izlaz )

      _t_stanje += _stanje
      _t_ulaz += _ulaz
      _t_izlaz += _izlaz

      select_o_roba( cIdRoba )

      _cijena := roba->vpc

      // sta sa uslugama ???
      IF roba->tip == "U"
      ENDIF

      IF hParams[ "stavke_nula" ] == "N" .AND. Round( _stanje, 2 ) == 0
         table:Skip()
         LOOP
      ENDIF

      xml_subnode( "item", .F. )

      xml_node( "rbr", AllTrim( Str( ++_count ) ) )
      xml_node( "id", to_xml_encoding( cIdRoba ) )
      xml_node( "naz", to_xml_encoding( roba->naz ) )
      xml_node( "jmj", to_xml_encoding( roba->jmj ) )
      xml_node( "ulaz", Str( _ulaz, 12, 2 ) )
      xml_node( "izlaz", Str( _izlaz, 12, 2 ) )
      xml_node( "stanje", Str( _stanje, 12, 2 ) )
      xml_node( "cijena", Str( _cijena, 12, 2 ) )

      xml_subnode( "item", .T. )

      table:Skip()

   ENDDO

   // totali lagerice
   xml_node( "t_ulaz", Str( _t_ulaz, 12, 2 ) )
   xml_node( "t_izlaz", Str( _t_izlaz, 12, 2 ) )
   xml_node( "t_stanje", Str( _t_stanje, 12, 2 ) )

   xml_subnode( "lager", .T. )
   close_xml()

   RETURN _ret



FUNCTION fakt_lager_lista_sql( hParams, lPocetnoStanje )

   LOCAL _table
   LOCAL _tek_database := my_server_params()[ "database" ]
   LOCAL hDbParams := my_server_params()

   IF hParams == NIL
      IF fakt_lager_lista_vars( @hParams ) == 0
         RETURN .F.
      ENDIF
   ENDIF

   IF lPocetnoStanje == NIL
      lPocetnoStanje := .F.
   ENDIF

   _table := fakt_lager_lista_get_data( hParams, lPocetnoStanje )

   RETURN _table



STATIC FUNCTION fakt_lager_lista_get_data( hParams, lPocetnoStanje )

   LOCAL _tek_database := my_server_params()[ "database" ]
   LOCAL hDbParams := my_server_params()
   LOCAL _table, cQuery, _server
   LOCAL _date_from, _date_to, _data_ps
   LOCAL _id_firma, _usl_roba, _usl_partn, _usl_tip_dok

   _date_from := hParams[ "datum_od" ]
   _date_to := hParams[ "datum_do" ]
   _id_firma := hParams[ "id_firma" ]
   _usl_roba := hParams[ "artikli" ]
   _usl_partn := hParams[ "partneri" ]
   _usl_tip_dok := hParams[ "dokumenti" ]
   _date_ps := hParams[ "datum_ps" ]

   IF lPocetnoStanje == NIL
      lPocetnoStanje := .F.
   ENDIF

   IF lPocetnoStanje
      my_server_logout()
      hDbParams[ "database" ] := Left( _tek_database, Len( _tek_database ) - 4 ) + AllTrim( Str( Year( _date_from ) ) )
      my_server_params( hDbParams )
      my_server_login( hDbParams )
      set_sql_search_path()
   ENDIF

   _server := sql_data_conn()

   cQuery := "SELECT " + ;
      "f.idroba, r.naz, " + ;
      "SUM( CASE " + ;
      "WHEN idtipdok LIKE '0%' THEN kolicina  " + ;
      "END ) as ulaz, " + ;
      "SUM( CASE " + ;
      "WHEN idtipdok LIKE '1%' THEN kolicina " + ;
      "END ) as izlaz, " + ;
      "r.jmj, " + ;
      "r.vpc " + ;
      "FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt f " + ;
      "LEFT JOIN " + F18_PSQL_SCHEMA_DOT + "roba r ON f.idroba = r.id "

   cQuery += " WHERE "
   cQuery += _sql_cond_parse( "idfirma", _id_firma )
   cQuery += " AND " + _sql_date_parse( "datdok", _date_from, _date_to )

   IF !Empty( _usl_roba )
      cQuery += " AND " + _sql_cond_parse( "idroba", _usl_roba )
   ENDIF

   IF !Empty( _usl_partn )
      cQuery += " AND " + _sql_cond_parse( "idpartner", _usl_partn )
   ENDIF

   IF !Empty( _usl_tip_dok )
      cQuery += " AND " + _sql_cond_parse( "idtipdok", _usl_tip_dok )
   ENDIF

   cQuery += " GROUP BY f.idroba, r.naz, r.jmj, r.vpc "
   cQuery += " ORDER BY f.idroba "

   _table := run_sql_query( cQuery )
   IF sql_error_in_query( _table )
      _table := NIL
   ENDIF

   IF lPocetnoStanje
      my_server_logout()
      hDbParams[ "database" ] := Left( _tek_database, Len( _tek_database ) - 4 ) + AllTrim( Str( Year( _date_ps ) ) )
      my_server_params( hDbParams )
      my_server_login( hDbParams )
      set_sql_search_path()
   ENDIF

   RETURN _table



FUNCTION fakt_vt_porezi()

   PUBLIC _PDV := tarifa->pdv / 100

   RETURN .T.
