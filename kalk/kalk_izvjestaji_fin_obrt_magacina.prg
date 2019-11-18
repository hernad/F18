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



// Pregled finansijskog obrta magacin/prodavnica
FUNCTION kalk_finansijski_obrt()

   LOCAL nOpseg
   LOCAL nKorekcija := 1
   LOCAL cLegenda

   // aMersed
   LOCAL nRekaRecCount

   PRIVATE  nCol1 := 0
   PRIVATE PicCDEM := kalk_prosiri_pic_cjena_za_2()
   PRIVATE PicProc := gPicProc
   PRIVATE PicDEM := kalk_prosiri_pic_iznos_za_2()
   PRIVATE Pickol := "@ 999999"
   // sirina kolone "+povecanje -snizenje" je za 3
   // karaktera veca od ostalih, tj. ima vise cifara
   PRIVATE PicPSDEM := Replicate( "9", 3 ) + PicDEM
   PRIVATE dDatOd := Date()
   PRIVATE dDatDo := Date()
   PRIVATE qqKonto := PadR( "13;", 60 )
   PRIVATE qqRoba := Space( 60 )
   PRIVATE cIdKPovrata := Space( 7 )
   PRIVATE ck7 := "N"
   // P-prodajna (bez poreza)
   // N-nabavna
   PRIVATE cCijena := "P"
   PRIVATE cVpRab := "N"
   PRIVATE cPlVrsta := Space( 1 )
   PRIVATE cK9 := Space( 3 )
   PRIVATE cGrupeK1 := Space( 45 )
   PRIVATE cPrDatOd := "N"
   PRIVATE PREDOVA2 := 62

   // o_sifk()
// o_sifv()
// o_roba()

   cLegenda := "D"

   o_params()
   PRIVATE cSection := "F"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   Params1()
   RPar( "c1", @cIdKPovrata )
   RPar( "c2", @qqKonto )
   RPar( "c4", @cCijena )
   RPar( "d1", @dDatOd )
   RPar( "d2", @dDatDo )
   RPar( "d3", @cVpRab )
   RPar( "d4", @cPrDatOd )

   cLegenda := "D"
   cKolDN := "N"

   Box(, 17, 75 )
   set_cursor_on()
   cNObjekat := Space( 20 )
   cKartica := "D"
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konta prodavnice:" GET qqKonto PICT "@!S50"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "tekuci promet je period:" GET dDatOd
      @ box_x_koord() + 3, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kriterij za robu :" GET qqRoba PICT "@!S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Magacin u koji se vrsi povrat rekl. robe:" GET cIdKPovrata PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz kolicina:" GET cKolDN PICT "@!" VALID cKolDN $ "DN"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Cijena (P-prodajna,N-nabavna):" GET cCijena PICT "@!" VALID cCijena $ "PN"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "VP sa uracunatim rabatom (D/N)?" GET cVpRab PICT "@!" VALID cVpRab $ "DN"
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Prodaja pocinje od 'Datum od' (D/N)?" GET cPrDatOd PICT "@!" VALID cPrDatOd $ "DN"
      READ
      nKorekcija := 12 / ( Month( dDatDo ) - Month( dDatOd ) + 1 )
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Korekcija (12/broj radnih mjeseci):" GET nKorekcija PICT "999.99"
      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Ostampati legendu za kolone " GET cLegenda PICT "@!" VALID cLegenda $ "DN"
      @ box_x_koord() + 14, box_y_koord() + 2 SAY "Uslov po pl.vrsta " GET cPlVrsta PICT "@!"
      @ box_x_koord() + 15, box_y_koord() + 2 SAY "Izdvoji grupe: " GET cGrupeK1
      @ box_x_koord() + 16, box_y_koord() + 2 SAY "(npr. 0001;0006;0019;)"
      @ box_x_koord() + 17, box_y_koord() + 2 SAY "Uslov po K9 " GET cK9 PICT "@!"
      READ
      ESC_BCR
      aUsl1 := Parsiraj( qqKonto, "pkonto" )
      aUsl2 := Parsiraj( qqKonto, "mkonto" )
      aUslR := Parsiraj( qqRoba, "IdRoba" )
      IF aUsl1 <> NIL .AND. aUslR <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   WPar( "c1", cidKPovrata )
   WPar( "c2", qqKonto )
   WPar( "c4", cCijena )
   WPar( "d1", dDatOd )
   WPar( "d2", dDatDo )
   WPar( "d3", cVpRab )
   WPar( "d4", cPrDatOd )

   SELECT params
   USE

   //PRIVATE fSMark := .F.
   //IF Right( Trim( qqRoba ), 1 ) = "*"
  //    fSMark := .T.
   //ENDIF

   CreTblRek2()

   O_REKAP2
   O_REKA22
   //o_koncij()
   // o_roba()
   //o_konto()
   //o_tarifa()
   // o_kalk()
   o_k1()
   kalk_o_objekti()

   lVpRabat := .F.
   IF cVpRab == "D"
      lVpRabat := .T.
   ENDIF
   lPrDatumOd := .F.
   IF cPrDatOd == "D"
      lPrDatumOd := .T.
   ENDIF

   kalk_gen_rekap_2( .T., cCijena, lPrDatumOd, lVpRabat )

   // setuj liniju za izvjestaj
   aLineArgs := {}
   AAdd( aLineArgs, { 25, "GRUPACIJA", "" } )
   AAdd( aLineArgs, { Len( PicDem ), "POCETNA", "ZALIHA" } )
   AAdd( aLineArgs, { Len( PicDem ), "NABAVKA", "MAGACIN" } )
   AAdd( aLineArgs, { Len( PicDem ), "ZADUZENJE", "PROD." } )
   IF cCijena == "P"
      AAdd( aLineArgs, { Len( PicDem ), "MALOPROD.", "RUC" } )
   ENDIF
   AAdd( aLineArgs, { Len( PicDem ), "KUMULAT.", "PRODAJA" } )
   IF cCijena == "P"
      AAdd( aLineArgs, { Len( PicDem ), "OSTVARENI", "RUC" } )
   ENDIF
   AAdd( aLineArgs, { Len( PicDem ), "ZALIHA", "REK.ROBE" } )
   AAdd( aLineArgs, { Len( PicDem ), "ZALIHA", "NA DAN" } )
   IF cCijena == "P"
      AAdd( aLineArgs, { Len( PicPSDEM ), "+POVECANJE", "-SNIZENJE" } )
   ENDIF
   AAdd( aLineArgs, { Len( PicDem ), "PROSJECNA", "ZALIHA" } )
   AAdd( aLineArgs, { Len( PicDem ), "GOD.KEOF", "OBRTA" } )

   PRIVATE m := SetRptLineAndText( aLineArgs, 0 )
   PRIVATE cZText1 := SetRptLineAndText( aLineArgs, 1 )
   PRIVATE cZText2 := SetRptLineAndText( aLineArgs, 2 )

   SELECT reka22
   SET ORDER TO TAG "1"

   GO TOP

   gaZagFix := { 9, 4 }
   start PRINT cret
   ?

   IF gPrinter = "R"
      PREDOVA2 = 62
      ?? "#%PORTR#"
   ENDIF

   nStr := 0
   ZagOPomF()
   nCol1 := 10

   SELECT reka22

   nRekaRecCount = RecCount()

   GO TOP
   nT1 := 0
   nT2 := 0
   nT3 := 0
   nT3R := 0
   nT4R := 0
   nT4 := 0
   nT5 := 0
   nT6 := 0
   nT7 := 0
   nK1 := 0
   nK2 := 0
   nK3 := 0
   nK3R := 0
   nK4R := 0
   nK4 := 0
   nK5 := 0
   nK6 := 0
   nT2a := 0
   nK2a := 0
   nT2b := 0
   lIzdvojiGrupe := .F.

   DO WHILE !Eof()
      cG1 := g1
      IF ( !Empty( cGrupeK1 ) .AND. At( cG1, cGrupeK1 ) <> 0 )
         SKIP
         LOOP
      ENDIF

      IF PRow() > PREDOVA2
         FF
         ZagOPomF()
      ENDIF

      ? cG1
      SELECT k1
      HSEEK cG1
      SELECT reka22
      @ PRow(), PCol() + 1 SAY k1->naz
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY zalihaf  PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nabavf   PICT picdem
         @ PRow(), PCol() + 1 SAY pnabavf  PICT picdem
         @ PRow(), PCol() + 1 SAY omprucf  PICT picdem
      ELSE
         @ PRow(), PCol() + 1 SAY nabavf   PICT picdem
         @ PRow(), PCol() + 1 SAY pnabavf  PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY prodkumf  PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY orucf     PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY stanjrf  PICT picdem
      @ PRow(), PCol() + 1 SAY stanjef  PICT picdem
      IF cCijena == "P"
         // povisenje
         @ PRow(), PCol() + 1 SAY povecanje - snizenje  PICT PicPSDEM
      ENDIF

      // prosjecna zaliha
      @ PRow(), PCol() + 1 SAY proszalf PICT picdem

      // koef obrta na dan
      @ PRow(), PCol() + 1 SAY KOBrDan * nKorekcija PICT picdem

      IF ckolDN == "D"

         IF PRow() > PREDOVA2
            FF
            ZagOPomF()
         ENDIF

         @ PRow() + 1, nCol1 SAY zalihak PICT StrTran( picdem, ".", "9" )
         IF cCijena == "P"
            @ PRow(), PCol() + 1 SAY nabavk  PICT StrTran( picdem, ".", "9" )
            @ PRow(), PCol() + 1 SAY pnabavk  PICT StrTran( picdem, ".", "9" )
            @ PRow(), PCol() + 1 SAY 0  PICT StrTran( picdem, ".", "9" )
         ELSE
            @ PRow(), PCol() + 1 SAY nabavk  PICT StrTran( picdem, ".", "9" )
            @ PRow(), PCol() + 1 SAY pnabavk  PICT StrTran( picdem, ".", "9" )
         ENDIF
         @ PRow(), PCol() + 1 SAY prodkumk  PICT StrTran( picdem, ".", "9" )
         IF cCijena == "P"
            @ PRow(), PCol() + 1 SAY 0     PICT StrTran( picdem, ".", "9" )
         ENDIF
         @ PRow(), PCol() + 1 SAY stanjrk  PICT StrTran( picdem, ".", "9" )
         @ PRow(), PCol() + 1 SAY stanjek  PICT StrTran( picdem, ".", "9" )
         IF cCijena == "P"
            @ PRow(), PCol() + 1 SAY 0  PICT StrTran( PicPSDEM, ".", "9" )  // povisenje
         ENDIF
         @ PRow(), PCol() + 1 SAY proszalk PICT StrTran( picdem, ".", "9" )  // prosje�na zaliha
         IF proszalk > 0
            @ PRow(), PCol() + 1 SAY prodkumk / proszalk * nKorekcija PICT picdem  // koef.kol.obrta
         ELSE
            IF nRekaRecCount == 1 // jedini u grupi
               @ PRow(), PCol() + 1 SAY 0 PICT picdem  // koef.kol.obrta
            ELSE
               @ PRow(), PCol() + 1 SAY PadC( "?", Len( picdem ) )  // koef.kol.obrta
            ENDIF
         ENDIF
         ?
      ENDIF

      nT1 += zalihaf

      nT2 += nabavf
      nT2a += pnabavf
      nT2b += omprucf

      nT3 += prodkumf
      nT3R += orucf
      nT4R += stanjrf
      nT4 += stanjef
      nT5 += povecanje - snizenje
      nT6 += ProsZalf

      nK1 += zalihak
      nK2 += nabavk
      nK2a += pnabavk
      nK3 += prodkumk
      nK3R += 0
      nK4R += stanjrk
      nK4 += stanjek
      nK5 += 0
      nK6 += ProsZalk
      SKIP

   ENDDO

   IF PRow() > ( PREDOVA2 - 5 )
      FF
      ZagOPomF()
   ENDIF

   ? m
   ? "UKUPNO"

   // nije sigurno da ce proci kroz gornji if
   // postaviti ispravno poravananje
   nCol1 := 26

   @ PRow(), nCol1 SAY  nT1 PICT picdem
   @ PRow(), PCol() + 1 SAY  nT2 PICT picdem
   @ PRow(), PCol() + 1 SAY  nT2a PICT picdem
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY nT2b  PICT StrTran( picdem, ".", "9" )
   ENDIF
   @ PRow(), PCol() + 1 SAY  nT3 PICT picdem
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY  nT3R PICT picdem
   ENDIF
   @ PRow(), PCol() + 1 SAY  nT4R PICT picdem
   @ PRow(), PCol() + 1 SAY  nT4 PICT picdem
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY  nT5 PICT PicPSDEM // povecanje/snizenje
   ENDIF
   @ PRow(), PCol() + 1 SAY  nT6 PICT picdem

   nOpseg := Int( ( dDatDo - dDatOd + 2 ) / 30 )

   IF !( nT6 == 0 )
      // nT7:=nT3/nT6*12/nOpseg   // prodaja/przaliha * 12
      nT7 := nT3 / nT6 * nKorekcija
      // t3 - kumulativna prodaja / t6 prosjecne zaliha
      @ PRow(), PCol() + 1 SAY  nT7 PICT picdem
   ENDIF

   ? "KOLIC "
   @ PRow(), nCol1 SAY  nK1 PICT StrTran( picdem, ".", "9" )
   @ PRow(), PCol() + 1 SAY  nK2 PICT StrTran( picdem, ".", "9" )
   @ PRow(), PCol() + 1 SAY  nK2a PICT StrTran( picdem, ".", "9" )
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY  0 PICT StrTran( picdem, ".", "9" )
   ENDIF
   @ PRow(), PCol() + 1 SAY  nK3 PICT StrTran( picdem, ".", "9" )
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY  nK3R PICT StrTran( picdem, ".", "9" )
   ENDIF
   @ PRow(), PCol() + 1 SAY  nK4R PICT StrTran( picdem, ".", "9" )
   @ PRow(), PCol() + 1 SAY  nK4 PICT StrTran( picdem, ".", "9" )
   IF cCijena == "P"
      @ PRow(), PCol() + 1 SAY  nK5 PICT StrTran( PicPSDEM, ".", "9" )
   ENDIF
   @ PRow(), PCol() + 1 SAY  nK6 PICT StrTran( picdem, ".", "9" )
   IF nK6 > 0
      @ PRow(), PCol() + 1 SAY nK3 / nK6 * nKorekcija PICT picdem  // koef.kol.obrta
   ELSE
      IF nRekaRecCount == 1 // jedini u grupi
         @ PRow(), PCol() + 1 SAY 0 PICT picdem  // koef.kol.obrta
      ELSE
         @ PRow(), PCol() + 1 SAY PadC( "?", Len( picdem ) )  // koef.kol.obrta
      ENDIF
   ENDIF

   ? m
   ?
   IF !Empty( cGrupeK1 )
      ? "IZDVOJENE GRUPE:"
      ? m
      nZalihaF := nNabavF := nPNabavF := nOmPrucF := nProdKumF := nORucF := nStanjeRF := nStanjeF := nPovSni := nProsZalF := nKoBrDan := nZalihaK := nNabavK := nPNabavK := nProdKumK := nStanjeRK := nStanjeK := nProsZalK := 0
      SELECT reka22
      GO TOP
      DO WHILE !Eof()
         cGK1 := g1
         IF At( cGK1, cGrupeK1 ) <> 0
            ? cGK1
            SELECT k1
            HSEEK cGK1
            SELECT reka22
            @ PRow(), PCol() + 1 SAY k1->naz
            nCol := PCol() + 1
            @ PRow(), PCol() + 1 SAY zalihaf  PICT picdem
            nZalihaF += zalihaf
            nZalihaK += zalihak
            IF cCijena == "P"
               @ PRow(), PCol() + 1 SAY nabavf   PICT picdem
               @ PRow(), PCol() + 1 SAY pnabavf  PICT picdem
               @ PRow(), PCol() + 1 SAY omprucf  PICT picdem
            ELSE
               @ PRow(), PCol() + 1 SAY nabavf   PICT picdem
               @ PRow(), PCol() + 1 SAY pnabavf  PICT picdem
            ENDIF
            nNabavF += nabavf
            nPNabavF += pnabavf
            nOmPrucF += omprucf
            nNabavK += nabavk
            nPNabavK += pnabavk
            @ PRow(), PCol() + 1 SAY prodkumf  PICT picdem
            nProdKumF += prodkumf
            nProdKumK += prodkumk
            IF cCijena == "P"
               @ PRow(), PCol() + 1 SAY orucf     PICT picdem
               nORucF += orucf
            ENDIF
            @ PRow(), PCol() + 1 SAY stanjrf  PICT picdem
            @ PRow(), PCol() + 1 SAY stanjef  PICT picdem
            nStanjeRF += stanjrf
            nStanjeRK += stanjrk
            nStanjeF += stanjef
            nStanjeK += stanjek
            IF cCijena == "P"
               @ PRow(), PCol() + 1 SAY povecanje - snizenje  PICT PicPSDEM
               nPovSni += povecanje - snizenje
            ENDIF
            @ PRow(), PCol() + 1 SAY proszalf PICT picdem
            @ PRow(), PCol() + 1 SAY KOBrDan * nKorekcija PICT picdem
            nProsZalF += proszalf
            nProsZalK += proszalk
            nKoBrDan += kobrdan * nKorekcija
            SKIP
         ELSE
            SKIP
            LOOP
         ENDIF
      ENDDO
      ? m
      ? "UKUPNO"
      @ PRow(), nCol1 SAY nZalihaF PICT picdem
      @ PRow(), PCol() + 1 SAY nNabavF PICT picdem
      @ PRow(), PCol() + 1 SAY nPNabavF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nOmPrucF PICT StrTran( picdem, ".", "9" )
      ENDIF
      @ PRow(), PCol() + 1 SAY nProdKumF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nORucF PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY nStanjeRF PICT picdem
      @ PRow(), PCol() + 1 SAY nStanjeF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nPovSni PICT PicPSDEM
      ENDIF
      @ PRow(), PCol() + 1 SAY nProsZalF PICT picdem
      nOpseg := Int( ( dDatDo - dDatOd + 2 ) / 30 )
      IF !( nT6 == 0 )
         nT7 := nT3 / nT6 * nKorekcija
         @ PRow(), PCol() + 1 SAY nKoBrDan PICT picdem
      ENDIF
      ? "KOLIC"
      @ PRow(), nCol1 SAY nZalihaK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY nNabavK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY nPNabavK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY nProdKumK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY nStanjeRK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY nStanjeK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT PicPSDEM
      ENDIF
      @ PRow(), PCol() + 1 SAY nProsZalK PICT StrTran( picdem, ".", "9" )
      IF nProsZalK > 0
         @ PRow(), PCol() + 1 SAY nProdKumK / nProsZalK * nKorekcija PICT picdem
      ELSE
         @ PRow(), PCol() + 1 SAY PadC( "?", Len( picdem ) )  // koef.kol.obrta
      ENDIF
      ? m
      ?
      ?
      ? "UKUPNO + UKUPNO IZDVOJENO"
      ? m
      ? "UKUPNO"
      @ PRow(), nCol1 SAY  nT1 + nZalihaF PICT picdem
      @ PRow(), PCol() + 1 SAY  nT2 + nNabavF PICT picdem
      @ PRow(), PCol() + 1 SAY  nT2a + nPNabavF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nT2b + nOmPrucF PICT StrTran( picdem, ".", "9" )
      ENDIF
      @ PRow(), PCol() + 1 SAY  nT3 + nProdKumF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY nT3R + nORucF PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY  nT4R + nStanjeRF PICT picdem
      @ PRow(), PCol() + 1 SAY  nT4 + nStanjeF PICT picdem
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY  nT5 + nPovSni PICT PicPSDEM
      ENDIF
      @ PRow(), PCol() + 1 SAY  nT6 + nProsZalF PICT picdem
      nOpseg := Int( ( dDatDo - dDatOd + 2 ) / 30 )
      IF !( nT6 == 0 )
         nT7 := nT3 / nT6 * nKorekcija
         @ PRow(), PCol() + 1 SAY nT7 + nKoBrDan PICT picdem
      ENDIF
      ? "KOLIC"
      @ PRow(), nCol1 SAY  nK1 + nZalihaK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY  nK2 + nNabavK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY  nK2a + nPNabavK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY  nK3 + nProdKumK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem
      ENDIF
      @ PRow(), PCol() + 1 SAY  nK4R + nStanjeRK PICT StrTran( picdem, ".", "9" )
      @ PRow(), PCol() + 1 SAY  nK4 + nStanjeK PICT StrTran( picdem, ".", "9" )
      IF cCijena == "P"
         @ PRow(), PCol() + 1 SAY 0 PICT PicPSDEM
      ENDIF
      @ PRow(), PCol() + 1 SAY  nK6 + nProsZalK PICT StrTran( picdem, ".", "9" )
      IF ( nProsZalK > 0 )
         IF nRekaRecCount == 1 // jedini u grupi
            @ PRow(), PCol() + 1 SAY ( nProdKumK / nProsZalK * nKorekcija ) PICT picdem
         ELSE
            IF ( nK6 > 0 )
               @ PRow(), PCol() + 1 SAY ( nK3 / nK6 * nKorekcija ) + ( nProdKumK / nProsZalK * nKorekcija ) PICT picdem
            ELSE
               @ PRow(), PCol() + 1 SAY PadC( "?", Len( picdem ) )  // koef.kol.obrta
            ENDIF
         ENDIF
      ELSE
         @ PRow(), PCol() + 1 SAY PadC( "?", Len( picdem ) )  // koef.kol.obrta
      ENDIF
      ? m
      ?
   ENDIF


   IF ( cLegenda == "D" )
      IF PRow() > ( PREDOVA2 - 12 )
         FF
         ZagOPomF()
      ENDIF
      Legenda()
   ENDIF

   ENDPRINT
   my_close_all_dbf()

   RETURN


STATIC FUNCTION Legenda()

   // {

   ? "Legenda:"
   ? "( 1) Pocetna zaliha: sadrzi stanje zalihe na Datum-od i to "
   ? "     SVI magacini i SVE prodavnice"
   ? "( 2) Nabavka magacin: sumira SAMO ulaze od dobavljaca"
   ? "( 3) Zaduz. prodavnica: sumira sva zaduzenja u prodavnice"
   ? "( 4) Maloprodajni RUC - ruc koji je ukalkulisan u prodavnice pri zaduzenju"
   ? "( 5) Kumulativna prodaja - ostvarena prodaja u MAG + PROD"
   ? "( 6) Zaliha reklamirane robe - stanje zaliha po vpc na skladistu reklam.r."
   ? "( 7) Zaliha na dan - ukupno stanje zaliha - SVI magacini i SVE prod."
   ? "( 8) povecanje, snizenje - suma povecanja i snizenja cijena"
   ? "( 9) prosjecna zaliha u toku zadatog perioda"
   ? "(10) Godisnji koeficijent obrta = (5)/(9)*zadana korekcija"

   FF

   RETURN
// }


/* ZagOPoMF()
 *     Zaglavlje obrta
 */

FUNCTION ZagOPoMF()

   // {
   P_10CPI
   // if gPrinter<>"R"
   // B_ON
   // endif
   ?? tip_organizacije() + ":", self_organizacija_naziv(), Space( 40 ), "Strana:" + Str( ++nStr, 3 )
   ?
   ?  "Pregled FINANSIJSKOG OBRTA za period:", dDatOd, "-", dDAtDo
   IspisNaDan( 10 )
   ?
   IF ( cCijena == "P" )
      ?  "Obracun prometa utvrdjen po cijenama sa ukalkulisanom marzom BEZ POREZA"
   ELSE
      ?  "Obracun prometa utvrdjen po nabavnim cijenama"
   ENDIF
   ?
   IF ( qqRoba == NIL )
      qqRoba := ""
   ENDIF
   ? "Kriterij za Objekat:", Trim( qqKonto ), "Robu:", Trim( qqRoba )
   ?
   IF cCijena == "P"
      P_COND2
   ELSE
      P_COND
   ENDIF
   ? m

   ? cZText1
   ? cZText2

/*
if (cCijena=="P")
 ? "    GRUPACIJA               POCETNA      NABAVKA        ZADUZ.          MALOPROD.          KUMULAT.       OSTVARENI          ZALIHA           ZALIHA         +POVECANJE       PROSJECNA      GOD. KOEF."
 ? "                            ZALIHA       MAGACIN      PRODAVNICE           RUC             PRODAJA          RUC              REKL.R           NA DAN         -SNIZENJE          ZALIHA         OBRTA  "
else
 ? "    GRUPACIJA               POCETNA      NABAVKA        ZADUZ.          KUMULAT.          ZALIHA          ZALIHA          PROSJECNA      GOD. KOEF."
 ? "                            ZALIHA       MAGACIN      PRODAVNICA        PRODAJA           REKL.R          NA DAN            ZALIHA         OBRTA  "
endif
*/

   ? m

   RETURN
// }
