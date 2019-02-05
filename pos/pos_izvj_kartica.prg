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

STATIC s_oPDF

MEMVAR m

FUNCTION pos_kartica_artikla()

   LOCAL nPredhodnoStanjeKolicina
   LOCAL nSign := 1
   LOCAL cSt
   LOCAL nPredhodnaVrijednost
   LOCAL nCijena := 0
   LOCAL dNaDatum
   LOCAL xPrintOpt
   LOCAL bZagl

   LOCAL cLijevaMargina := ""
   LOCAL nSir := 40

   // LOCAL cPPar
   LOCAL GetList := {}

   PRIVATE dDatum0 := danasnji_datum()
   PRIVATE dDatum1 := danasnji_datum()
   PRIVATE cPredhodnoStanje := "D"

   nPosDuzinaBrojaDokumenta :=  FIELD_LEN_POS_BRDOK

   cIdRoba := Space( 10 )
   cIdPos := gIdPos

   dDatum0 := fetch_metric( "pos_kartica_datum_od", my_user(), dDatum0 )
   dDatum1 := fetch_metric( "pos_kartica_datum_do", my_user(), dDatum1 )
   cIdRoba := fetch_metric( "pos_kartica_artikal", my_user(), cIdRoba )
   // cPPar := fetch_metric( "pos_kartica_prikaz_partnera", my_user(), "N" )

   SET CURSOR ON

   Box(, 11, 60 )

   aNiz := {}

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prod.mjesto (prazno-svi) "  GET  cIdPos  VALID Empty( cIdPos ) .OR. p_pos_kase( cIdPos ) PICT "@!"
   READ
   @ box_x_koord() + 5, box_y_koord() + 6 SAY "Sifra artikla (prazno-svi)" GET cIdRoba VALID Empty( cIdRoba ) .OR. P_Roba( @cIdRoba ) PICT "@!"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "za period " GET dDatum0
   @ box_x_koord() + 7, Col() + 2 SAY "do " GET dDatum1
   @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "sa predhodnim stanjem D/N ?" GET cPredhodnoStanje VALID cPredhodnoStanje $ "DN" PICT "@!"
   // @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Prikaz partnera D/N ?" GET cPPar VALID cPPar $ "DN" PICT "@!"
   READ

   ESC_BCR

   set_metric( "pos_kartica_datum_od", my_user(), dDatum0 )
   set_metric( "pos_kartica_datum_do", my_user(), dDatum1 )
   set_metric( "pos_kartica_artikal", my_user(), cIdRoba )
   set_metric( "pos_kartica_prikaz_partnera", my_user(), "N" )
   BoxC()

   IF Empty( cIdRoba )
      seek_pos_pos_2( NIL )
   ELSE
      seek_pos_pos_2( cIdRoba )
      IF pos->idroba <> cIdRoba
         MsgBeep( "Ne postoje traženi podaci !" )
         RETURN .F.
      ENDIF
   ENDIF

   EOF CRET

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  "POS [" + cIdPos + "] KARTICE ARTIKALA NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   IF Empty( cIdPos )
      ? cLijevaMargina + "PROD.MJESTO: " + cIdpos + "-" + "SVE"
   ELSE
      ? cLijevaMargina + "PROD.MJESTO: " + cIdpos + "-" + find_pos_kasa_naz( cIdPos )
   ENDIF

   ? cLijevaMargina + "ARTIKAL    : " + iif( Empty( cIdRoba ), "SVI", RTrim( cIdRoba ) )
   ? cLijevaMargina + "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )
   ?

   cLijevaMargina := ""

   m := Replicate( "-", 8 ) + " "
   m += "-------- ---------- ---------- ---------- ---------- ----------"

   bZagl := {|| pos_zagl_kartica(cLijevaMargina) }
   Eval( bZagl )

   DO WHILE !Eof()

      nPredhodnoStanjeKolicina := 0
      nPredhodnaVrijednost := 0

      cIdRobaT := POS->IdRoba
      select_o_roba( cIdRoba )
      nCijena1 := pos_get_mpc()

      nPredhodnoStanjeKolicina := 0
      nPredhodnaVrijednost := 0
      nStanjeKolicina := 0

      SELECT POS

      check_nova_strana( bZagl, s_oPDF )
      ?
      ? m
      ? cLijevaMargina
      ?? Space( 8 ) + " "
      select_o_roba( cIdRobaT )
      SELECT POS
      ?? cIdRobaT, PadR ( AllTrim ( roba->Naz ) + " (" + AllTrim ( roba->Jmj ) + ")", 32 )
      ? m

      // izracunati predhodno stanje
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRobaT .AND. POS->Datum < dDatum0

         IF  cPredhodnoStanje == "N" .OR. ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
            SKIP
            LOOP
         ENDIF

         IF pos->idvd $ POS_IDVD_ULAZI
            nPredhodnoStanjeKolicina += POS->Kolicina
            nPredhodnaVrijednost += POS->Kolicina * pos->cijena

         ELSEIF pos->idvd $ "IN"

            nPredhodnoStanjeKolicina -= ( POS->Kolicina - POS->Kol2 )
            nPredhodnaVrijednost += ( POS->Kol2 - POS->Kolicina ) * POS->Cijena

         ELSEIF pos->idvd $ "42"
            nPredhodnoStanjeKolicina -= POS->Kolicina
            nPredhodnaVrijednost -= POS->Kolicina * pos->cijena

         ELSEIF pos->IdVd == "NI"
            nPredhodnaVrijednost += POS->Kolicina * ( pos->ncijena - pos->cijena )
         ENDIF

         SKIP
      ENDDO

      ?
      ?? PadL ( "Stanje do " + FormDat1 ( dDatum0 ) + " : ", 40 )
      ?? Str ( nPredhodnoStanjeKolicina, 10, 2 ) + " "
      IF Round( nPredhodnoStanjeKolicina, 4 ) != 0
         nCijena := nPredhodnaVrijednost / nPredhodnoStanjeKolicina
      ELSE
         nCijena := 0
      ENDIF
      ?? Str ( nCijena, 10, 2 ) + " "
      ?? Str ( nPredhodnaVrijednost, 10, 2 )

      nStanjeKolicina := nPredhodnoStanjeKolicina
      nUlaz := nIzlaz := 0
      nVrijednost := nPredhodnaVrijednost

      // zadani interval
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRobaT .AND. POS->Datum >= dDatum0 .AND. POS->Datum <= dDatum1

         check_nova_strana( bZagl, s_oPDF )
         IF ( !Empty( cIdPos ) .AND. IdPos <> cIdPos )
            SKIP
            LOOP
         ENDIF

         IF POS->idvd $ "00#16"

            ? cLijevaMargina
            ?? DToC( pos->datum ) + " "
            ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), nPosDuzinaBrojaDokumenta ), ""
            ?? Str ( POS->Kolicina, 10, 3 ), Space ( 10 ), ""
            nUlaz += POS->Kolicina
            nStanjeKolicina += POS->Kolicina
            nVrijednost += POS->Kolicina * pos->cijena
            ?? Str ( nStanjeKolicina, 10, 2 ) + " "
            ?? Str ( pos->cijena, 10, 2 ) + " "
            ?? Str ( nVrijednost, 10, 2 )

         ELSEIF POS->IdVd == "NI"

            ? cLijevaMargina
            ?? DToC( pos->datum ) + " "
            ?? POS->IdVd + "-" + PadR ( AllTrim( POS->BrDok ), nPosDuzinaBrojaDokumenta ), ""
            ?? "S:", Str ( POS->Cijena, 7, 2 ), "N:", Str ( POS->Ncijena, 7, 2 ), Str ( nStanjeKolicina, 10, 3 )
            nVrijednost += pos->kolicina * ( pos->ncijena - pos->cijena )
            ?? Str ( pos->ncijena - pos->cijena, 10, 2 ) + " "
            ?? Str ( nVrijednost, 10, 2 )

            SKIP
            LOOP

         ELSEIF POS->idvd $ "IN" + "42#98"

            IF pos->idvd $ "42#98"
               nKol := POS->Kolicina
            ELSEIF POS->IdVd == "IN"
               nKol := POS->Kolicina - POS->Kol2
            ENDIF

            nIzlaz += nKol
            nStanjeKolicina -= nKol
            nVrijednost -= nKol * pos->Cijena

            check_nova_strana( bZagl, s_oPDF )
            ? cLijevaMargina
            ?? DToC( pos->datum ) + " "
            ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), nPosDuzinaBrojaDokumenta ), ""
            ?? Space ( 10 )
            ?? Str ( nKol, 10, 2 ) + " "
            ?? Str ( nStanjeKolicina, 10, 2 ) + " "
            ?? Str ( pos->cijena, 10, 2 ) + " "
            ?? Str ( nVrijednost, 10, 2 )

         ENDIF

         SKIP
      ENDDO

      DO WHILE !Eof() .AND. POS->IdRoba == cIdRobaT .AND. POS->Datum > dDatum1
         SKIP
      ENDDO

      check_nova_strana( bZagl, s_oPDF )

      ? m
      ? cLijevaMargina
      ?? PadL( "UKUPNO:", 18 )
      ?? Str( nUlaz, 10, 2 ) + " "
      ?? Str( nIzlaz, 10, 2 ) + " "
      ?? Str( nStanjeKolicina, 10, 2 ) + " "
      IF Round( nStanjeKolicina, 4 ) != 0
         nCijena := nVrijednost / nStanjeKolicina
      ELSE
         nCijena := 0
      ENDIF
      ?? Str( nCijena, 10, 2 ) + " "
      ?? Str( nVrijednost, 10, 2 ) + " "
      ? m
      ?

   ENDDO

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


FUNCTION pos_zagl_kartica(cLijevaMargina)

   ? m
   ? cLijevaMargina + " Datum   Dokum." + Space( nPosDuzinaBrojaDokumenta - 4 ) + "     Ulaz       Izlaz     Stanje     Cijena  Vrijednost"
   ? m

   RETURN .T.
