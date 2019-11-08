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

MEMVAR m

FUNCTION pos_kartica_artikla()

   LOCAL nStanje
   LOCAL nSign := 1
   LOCAL cSt
   LOCAL nVrijednost
   LOCAL nCijena := 0

   // LOCAL cRSdbf
   LOCAL cLM := ""
   LOCAL nSir := 40
   LOCAL cSiroki := "D"
   LOCAL cPPar
   LOCAL GetList := {}

   // PRIVATE cIdDio := Space( 2 )
   PRIVATE cIdOdj := Space( 2 )
   PRIVATE dDatum0 := gDatum
   PRIVATE dDatum1 := gDatum
   PRIVATE cPocSt := "D"

   nMDBrDok := 6

   // o_pos_kase()
   // o_sifk()
   // o_sifv()
   // o_roba()
   // o_pos_pos()

   cIdRoba := Space( 10 )
   cIdPos := gIdPos

   dDatum0 := fetch_metric( "pos_kartica_datum_od", my_user(), dDatum0 )
   dDatum1 := fetch_metric( "pos_kartica_datum_do", my_user(), dDatum1 )
   cIdRoba := fetch_metric( "pos_kartica_artikal", my_user(), cIdRoba )
   cPPar := fetch_metric( "pos_kartica_prikaz_partnera", my_user(), "N" )

   SET CURSOR ON

   Box(, 11, 60 )

   aNiz := {}

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prod.mjesto (prazno-svi) "  GET  cIdPos  VALID Empty( cIdPos ) .OR. p_pos_kase( cIdPos ) PICT "@!"
   READ

   @ box_x_koord() + 5, box_y_koord() + 6 SAY "Sifra artikla (prazno-svi)" GET cIdRoba VALID Empty( cIdRoba ) .OR. P_Roba( @cIdRoba ) PICT "@!"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "za period " GET dDatum0
   @ box_x_koord() + 7, Col() + 2 SAY "do " GET dDatum1
   @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "sa početnim stanjem D/N ?" GET cPocSt VALID cpocst $ "DN" PICT "@!"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Prikaz partnera D/N ?" GET cPPar VALID cPPar $ "DN" PICT "@!"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY8 "Široki papir    D/N ?" GET cSiroki VALID cSiroki $ "DN" PICT "@!"
   READ

   ESC_BCR

   set_metric( "pos_kartica_datum_od", my_user(), dDatum0 )
   set_metric( "pos_kartica_datum_do", my_user(), dDatum1 )
   set_metric( "pos_kartica_artikal", my_user(), cIdRoba )
   set_metric( "pos_kartica_prikaz_partnera", my_user(), "N" )
   BoxC()


   cU := R_U
   cI := R_I
   // cRSdbf := "ROBA"

   IF cPPar == "D"
      // o_pos_doks()
      // SELECT ( F_POS_DOKS )
      // SET ORDER TO TAG "1"
   ENDIF

   // SELECT POS
   // SET ORDER TO TAG "2"


   IF Empty( cIdRoba )
      // Seek2( cIdOdj )
      seek_pos_pos_2( cIdOdj )
   ELSE
      seek_pos_pos_2( cIdOdj, cIdRoba )
      // Seek2( cIdOdj + cIdRoba )
      IF pos->idroba <> cIdRoba
         MsgBeep( "Ne postoje traženi podaci !" )
         RETURN .F.
      ENDIF
   ENDIF

   EOF CRET

   START PRINT CRET

   // ZagFirma()

   ? PadC( "KARTICE ARTIKALA NA DAN " + FormDat1( gDatum ), nSir )
   ? PadC( "-----------------------------------", nSir )


   IF Empty( cIdPos )
      ? cLM + "PROD.MJESTO: " + cIdpos + "-" + "SVE"
   ELSE
      ? cLM + "PROD.MJESTO: " + cIdpos + "-" + find_pos_kasa_naz( cIdPos )
   ENDIF


   ? cLM + "ARTIKAL    : " + iif( Empty( cIdRoba ), "SVI", RTrim( cIdRoba ) )
   ? cLM + "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )
   ?

   cLM := ""
   ?

   ?? "Artikal"

   IF cSiroki == "D"
      ? cLM + " Datum   Dokum." + Space( nMDBrDok - 4 ) + "     Ulaz       Izlaz     Stanje"
   ELSE
      ? cLM + "Dokum." + Space( nMDBrDok - 4 ) + "     Ulaz       Izlaz     Stanje"
   ENDIF


   IF cPPar == "D"
      ?? "   Partner"
   ENDIF

   m := ""
   IF cSiroki == "D"
      m := m + Replicate( "-", 8 ) + " "  // datum
   ENDIF
   m := m + "---" + REPL( "-", nMDBrDok ) + " ---------- ---------- ----------"

   IF cPPar == "D"
      m += " --------"
   ENDIF


   DO WHILE !Eof() .AND. POS->IdOdj == cIdOdj
      nStanje := 0
      nVrijednost := 0
      fSt := .T.
      cIdRoba := POS->IdRoba
      nUlaz := nIzlaz := 0

      SELECT POS

      DO WHILE !Eof() .AND. POS->( IdOdj + IdRoba ) == ( cIdOdj + cIdRoba )
         IF ( pos->idvd == "96" )
            SKIP
            LOOP
         ENDIF

         IF cPocSt == "N"
            select_o_roba( cIdRoba )
            nCijena1 := pos_get_mpc()
            // SELECT POS
            nStanje := 0
            nVrijednost := 0

            // SEEK cIdOdj + cIdRoba + DToS( dDatum0 )
            seek_pos_pos_2( cIdOdj, cIdRoba, dDatum0 )

         ELSE
            DO WHILE !Eof() .AND. POS->( IdOdj + IdRoba ) == ( cIdOdj + cIdRoba ) .AND. POS->Datum < dDatum0
               // IF !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio
               // SKIP
               // LOOP
               // ENDIF
               IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
                  SKIP
                  LOOP
               ENDIF

               IF ( pos->idvd == "96" )
                  SKIP
                  LOOP
               ENDIF

               IF pos->idvd $ DOK_ULAZA
                  nStanje += POS->Kolicina

               ELSEIF pos->idvd $ "IN"

                  nStanje -= ( POS->Kolicina - POS->Kol2 )
                  nVrijednost += ( POS->Kol2 - POS->Kolicina ) * POS->Cijena

               ELSEIF pos->idvd $ DOK_IZLAZA
                  nStanje -= POS->Kolicina

               ELSEIF pos->IdVd == "NI"
                  // ne mijenja kolicinu
               ENDIF

               SKIP
            ENDDO

            select_o_roba( cIdRoba )
            nCijena1 := pos_get_mpc()

            IF fSt
               ? m
               ? cLM
               IF cSiroki == "D"
                  ?? Space( 8 ) + " "
               ENDIF
               ?? cIdRoba, PadR ( AllTrim ( Naz ) + " (" + AllTrim ( Jmj ) + ")", 32 )
               ? m
               nVrijednost := nStanje * nCijena1
               ?
               ?? PadL ( "Stanje do " + FormDat1 ( dDatum0 ), 29 ), ""
               ?? Str ( nStanje, 10, 3 )
               fSt := .F.
            ENDIF
            SELECT POS
         ENDIF // cPocSt

         DO WHILE !Eof() .AND. POS->( IdOdj + IdRoba ) == ( cIdOdj + cIdRoba ) .AND. POS->Datum <= dDatum1

            // IF !Empty( cIdDio ) .AND. POS->IdDio <> cIdDio
            // SKIP
            // LOOP
            // ENDIF

            IF ( !pos_admin() .AND. pos->idpos = "X" ) .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
               // (POS->IdPos="X" .and. AllTrim (cIdPos)<>"X") .or. ;  // ?MS
               SKIP
               LOOP
            ENDIF

            IF ( pos->idvd == "96" )
               SKIP
               LOOP
            ENDIF

            IF fSt
               // SELECT ( cRSdbf )
               select_o_roba( cIdRoba )
               ? m
               ? cLM + cIdRoba, PadR( AllTrim( Naz ) + " (" + AllTrim( Jmj ) + ")", 32 )
               ? m
               SELECT POS
               fSt := .F.
            ENDIF

            IF POS->idvd $ DOK_ULAZA

               ? cLM

               IF cSiroki == "D"
                  ?? DToC( pos->datum ) + " "
               ENDIF

               ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), nMDBrDok ), ""

               ?? Str ( POS->Kolicina, 10, 3 ), Space ( 10 ), ""
               nUlaz += POS->Kolicina

               nStanje += POS->Kolicina
               ?? Str ( nStanje, 10, 3 )

            ELSEIF POS->IdVd == "NI"

               ? cLM

               IF cSiroki == "D"
                  ?? DToC( pos->datum ) + " "
               ENDIF

               ?? POS->IdVd + "-" + PadR ( AllTrim( POS->BrDok ), nMDBrDok ), ""
               ?? "S:", Str ( POS->Cijena, 7, 2 ), "N:", Str ( POS->Ncijena, 7, 2 ), ;
                  Str ( nStanje, 10, 3 )


               SKIP
               LOOP

            ELSEIF POS->idvd $ "IN" + DOK_IZLAZA

               IF pos->idvd $ DOK_IZLAZA
                  nKol := POS->Kolicina
               ELSEIF POS->IdVd == "IN"
                  nKol := ( POS->Kolicina - POS->Kol2 )
               ENDIF

               IF pos->idvd == "IN" .AND. pos->kolicina == 0
                  nIzlaz += nStanje - nKol
                  nStanje -= nStanje - Abs( nKol )
               ELSE
                  nIzlaz += nKol
                  nStanje -= nKol
               ENDIF

               ? cLM
               IF cSiroki == "D"
                  ?? DToC( pos->datum ) + " "
               ENDIF

               ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), nMDBrDok ), ""
               ?? Space ( 10 ), Str ( nKol, 10, 3 ), Str ( nStanje, 10, 3 )

            ENDIF // izlaz, in

            IF cPPar == "D"
               ?? " "
               ?? ocitaj_izbaci( F_POS_DOKS, POS->( IdPos + IdVd + DToS( datum ) + BrDok ), "idgost" )
            ENDIF


            SKIP
         ENDDO

         ? m
         ? cLM

         IF cSiroki == "D"
            ?? Space( 8 ) + " "
         ENDIF

         ?? " UKUPNO", Str( nUlaz, 10, 3 ), Str( nIzlaz, 10, 3 ), Str( nStanje, 10, 3 )

         IF cSiroki == "D"
            ?  Space( 9 ) + "  Cij:", Str( nCijena1, 8, 2 ), "Ukupno:", Str ( nCijena1 * nStanje, 12, 3 )
         ELSE
            ?  "  Cij:", Str( nCijena1, 8, 2 ), "Ukupno:", Str ( nCijena1 * nStanje, 12, 3 )
         ENDIF

         ? m
         ?
         DO WHILE !Eof() .AND. POS->( IdOdj + IdRoba ) == ( cIdOdj + cIdRoba ) .AND. POS->Datum > dDatum1
            SKIP
         ENDDO

      ENDDO

      IF !Empty( cIdRoba )
         EXIT
      ENDIF

   ENDDO

   PaperFeed()
   ENDPRINT

   CLOSE ALL

   RETURN .T.
