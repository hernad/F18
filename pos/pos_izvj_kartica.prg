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

STATIC s_oPDF, s_nKol2

MEMVAR m
MEMVAR dDatum0, dDatum1, cIdRoba, cIdPos, cPredhodnoStanje

FUNCTION pos_kartica_artikla()

   LOCAL nVrijednost, nPredhodnaVrijednost
   LOCAL nKol, s_nKol2, nCijena
   LOCAL xPrintOpt
   LOCAL bZagl
   LOCAL cLijevaMargina := ""
   LOCAL GetList := {}
   LOCAL cIdRobaT
   LOCAL nPredhodnoStanjeUlaz, nPredhodnoStanjeIzlaz
   LOCAL nPredhodnoStanjeKolicina, nStanjeKolicina
   LOCAL nUlazKolicina, nIzlazKolicina
   LOCAL cQuery

   PRIVATE dDatum0 := danasnji_datum()
   PRIVATE dDatum1 := danasnji_datum()
   PRIVATE cPredhodnoStanje := "D"

   cIdRoba := Space( 10 )
   cIdPos := pos_pm()

   dDatum0 := fetch_metric( "pos_kartica_datum_od", my_user(), dDatum0 )
   dDatum1 := fetch_metric( "pos_kartica_datum_do", my_user(), dDatum1 )
   cIdRoba := fetch_metric( "pos_kartica_artikal", my_user(), cIdRoba )
   // cPPar := fetch_metric( "pos_kartica_prikaz_partnera", my_user(), "N" )

   SET CURSOR ON

   Box(, 11, 60 )

   @ box_x_koord() + 5, box_y_koord() + 6 SAY8 "Šifra artikla (prazno-svi)" GET cIdRoba VALID Empty( cIdRoba ) .OR. P_Roba( @cIdRoba ) PICT "@!"
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

   // 21-ce ne gledati
   cQuery := "select * from "  + f18_sql_schema( "pos_items" ) + ;
      " left join " + f18_sql_schema( "pos" ) + " on pos_items.idpos=pos.idpos and pos_items.idvd=pos.idvd and pos_items.brdok=pos.brdok and pos_items.datum=pos.datum" + ;
      " WHERE pos.idvd <> '21' AND pos.datum<=" + sql_quote( dDatum1 )
   IF !Empty( cIdRoba )
      cQuery += " AND rtrim(idroba)=" + sql_quote( Trim( cIdRoba ) )
   ENDIF
   cQuery += " order by idroba, pos.datum, pos.obradjeno  "

   // IF Empty( cIdRoba )
   // seek_pos_pos_2( NIL )
   // ELSE
   // seek_pos_pos_2( cIdRoba )
   // IF pos->idroba <> cIdRoba
   // MsgBeep( "Ne postoje traženi podaci !" )
   // RETURN .F.
   // ENDIF
   // ENDIF
   SELECT F_POS
   USE
   dbUseArea_run_query( cQuery, F_POS, "POS" )


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

   // IF Empty( cIdPos )
   // ? cLijevaMargina + "PROD.MJESTO: " + cIdpos + "-" + "SVE"
   // ELSE
   ? cLijevaMargina + "PROD.MJESTO: " + cIdpos
   // ENDIF

   ? cLijevaMargina + "ARTIKAL    : " + iif( Empty( cIdRoba ), "SVI", RTrim( cIdRoba ) )
   ? cLijevaMargina + "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )
   ?

   cLijevaMargina := ""

   m := Replicate( "-", 8 ) + " " + "----------- ---------- ---------- ---------- ---------- ----------"

   bZagl := {|| pos_zagl_kartica( cLijevaMargina ) }
   Eval( bZagl )

   DO WHILE !Eof()

      cIdRobaT := POS->IdRoba
      select_o_roba( cIdRoba )
      SELECT POS

      nPredhodnoStanjeUlaz := 0
      nPredhodnoStanjeIzlaz := 0
      nPredhodnaVrijednost := 0
      nStanjeKolicina := 0

      check_nova_strana( bZagl, s_oPDF, .F., 8 )
      ?
      ? m
      ? cLijevaMargina
      ??
      select_o_roba( cIdRobaT )
      SELECT POS
      ?? cIdRobaT, PadR ( AllTrim ( roba->Naz ) + " (" + AllTrim ( roba->Jmj ) + ")", 60 )
      ? m

      // izračunati predhodno stanje
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRobaT .AND. POS->Datum < dDatum0

         IF cPredhodnoStanje == "N" .OR. ( !Empty( cIdPos ) .AND. pos->IdPos <> cIdPos )
            SKIP
            LOOP
         ENDIF
         pos_stanje_proracun_kartica( @nPredhodnoStanjeUlaz, @nPredhodnoStanjeIzlaz, @nStanjeKolicina, @nPredhodnaVrijednost, .F. )
         SKIP
      ENDDO

      check_nova_strana( bZagl, s_oPDF, .F., 3 )
      ?
      ?? PadL ( "Stanje do " + FormDat1 ( dDatum0 ) + " : ", 43 )

      nPredhodnoStanjeKolicina := nPredhodnoStanjeUlaz - nPredhodnoStanjeIzlaz
      ?? Str ( nPredhodnoStanjeKolicina, 10, 2 ) + " "
      IF Round( nPredhodnoStanjeKolicina, 4 ) != 0
         nCijena := nPredhodnaVrijednost / nPredhodnoStanjeKolicina
      ELSE
         nCijena := 0
      ENDIF
      ?? Str ( nCijena, 10, 2 ) + " "
      ?? Str ( nPredhodnaVrijednost, 10, 2 )

      nUlazKolicina := nPredhodnoStanjeUlaz
      nIzlazKolicina := nPredhodnoStanjeIzlaz
      nVrijednost := nPredhodnaVrijednost

      // zadani interval
      DO WHILE !Eof() .AND. POS->IdRoba == cIdRobaT .AND. POS->Datum >= dDatum0 .AND. POS->Datum <= dDatum1
         check_nova_strana( bZagl, s_oPDF )
         pos_stanje_proracun_kartica( @nUlazKolicina, @nIzlazKolicina, @nStanjeKolicina, @nVrijednost, .T. )
         SKIP
      ENDDO

      check_nova_strana( bZagl, s_oPDF, .F., 3 )
      ? m
      ? cLijevaMargina
      ?? PadL( "UKUPNO:", 21 )
      ?? Str( nUlazKolicina, 10, 2 ) + " "
      ?? Str( nIzlazKolicina, 10, 2 ) + " "
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



FUNCTION pos_stanje_proracun_kartica( nUlaz, nIzlaz, nStanjeKolicina, nVrijednost, lPrint )

   LOCAL nPopust, nCijenaNeto

   IF pos->idvd == POS_IDVD_POCETNO_STANJE_PRODAVNICA
      nUlaz := POS->Kolicina
      nVrijednost := POS->Kolicina * POS->Cijena
      nIzlaz := 0
      nStanjeKolicina := POS->Kolicina

      IF lPrint
         ?
         ?? DToC( pos->datum ) + " "
         ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), FIELD_LEN_POS_BRDOK ), ""
         ?? Str ( POS->Kolicina, 10, 3 ), Space ( 10 ), ""
         ?? Str ( nStanjeKolicina, 10, 2 ) + " "
         ?? Str ( pos->cijena, 10, 2 ) + " "
         ?? Str ( nVrijednost, 10, 2 )
      ENDIF

   ELSEIF POS->idvd $ POS_IDVD_ULAZI
      nUlaz += POS->Kolicina
      nVrijednost += POS->Kolicina * POS->Cijena
      nStanjeKolicina += POS->Kolicina

      IF lPrint
         ?
         ?? DToC( pos->datum ) + " "
         ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), FIELD_LEN_POS_BRDOK ), ""
         ?? Str ( POS->Kolicina, 10, 3 ), Space ( 10 ), ""
         ?? Str ( nStanjeKolicina, 10, 2 ) + " "
         ?? Str ( pos->cijena, 10, 2 ) + " "
         ?? Str ( nVrijednost, 10, 2 )
      ENDIF


   ELSEIF POS->IdVd $ POS_IDVD_NIVELACIJE_SNIZENJA
      nVrijednost += POS->Kolicina * ( POS->Cijena - POS->Cijena )

      IF lPrint
         ?
         ?? DToC( pos->datum ) + " "
         ?? POS->IdVd + "-" + PadR ( AllTrim( POS->BrDok ), FIELD_LEN_POS_BRDOK )
         s_nKol2 := PCol()
         ?? " S:", Str ( POS->Cijena, 7, 2 ), "N:", Str( POS->Ncijena, 7, 2 )
         @ PRow() + 1, s_nKol2 + 1 SAY PadR( "Niv.Kol:", 10 ) + " "
         ?? Str( pos->kolicina, 10, 3 ) + " "
         ?? Str ( nStanjeKolicina, 10, 2 ) + " "
         nVrijednost += pos->kolicina * ( pos->ncijena - pos->cijena )
         ?? Str ( pos->ncijena - pos->cijena, 10, 2 ) + " "
         ?? Str ( nVrijednost, 10, 2 )
      ENDIF

   ELSEIF POS->IdVd == POS_IDVD_RACUN
      nIzlaz += POS->Kolicina
      IF pos->ncijena <> 0
         nPopust := Round( ( pos->cijena - pos->ncijena ) / pos->cijena * 100, 2 )
         nCijenaNeto := pos->ncijena
      ELSE
         nCijenaNeto := pos->cijena
         nPopust := 0
      ENDIF
      nVrijednost -= POS->Kolicina * nCijenaNeto
      nStanjeKolicina -= POS->Kolicina

      IF lPrint
         ?
         ?? DToC( pos->datum ) + " "
         ?? POS->IdVd + "-" + PadR( AllTrim( POS->BrDok ), FIELD_LEN_POS_BRDOK ), ""
         IF nPopust <> 0
            ?? "P:" + Str( nPopust, 5, 2 ) + "%" + Space( 3 )
         ELSE
            ?? Space( 11 )
         END IF
         ?? Str ( pos->kolicina, 10, 3 ) + " "
         ?? Str ( nStanjeKolicina, 10, 2 ) + " "
         ?? Str ( nCijenaNeto, 10, 2 ) + " "
         ?? Str ( nVrijednost, 10, 2 )
      ENDIF

   ENDIF

   RETURN .T.



FUNCTION pos_zagl_kartica( cLijevaMargina )

   ? m
   ? cLijevaMargina + " Datum    Dokument       Ulaz       Izlaz     Stanje    Cijena   Vrijednost"
   ? m

   RETURN .T.
