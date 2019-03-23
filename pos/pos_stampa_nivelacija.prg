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
STATIC s_cPicCijena := "999999.99"
STATIC s_cPicIznos := "9999999.99"
STATIC s_cPicKolicina := "9999999.99"
STATIC s_cRobaNazDuzina := 45

FUNCTION pos_stampa_nivelacija( hParams )

   LOCAL cIdRoba, nUkupno
   LOCAL xPrintOpt, bZagl
   LOCAL nCol := 50
   LOCAL nCnt

   LOCAL cNaslov
   LOCAL cIdPos, cIdVd, dDatum, cBrDok // , cBrFaktP

   cIdPos := hParams[ "idpos" ]
   cIdVd  := hParams[ "idvd" ]
   cBrDok := hParams[ "brdok" ]
   dDatum := hParams[ "datum" ]
   // cBrFaktP := hParams["brfaktp"]

   cNaslov := pos_dokument_naziv( cIdVd )
   cNaslov += " " + AllTrim( cIdPos ) + "-" + AllTrim( cIdVd ) + "-" + AllTrim( cBrDok ) + " od " + DToC( dDatum ) + "   NA DAN " + DToC( danasnji_datum() )
   PushWA()
   IF !hParams[ "priprema" ]
      IF !seek_pos_pos( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ], "1", "PRIPRZ" )
         RETURN .F.
      ENDIF
   ENDIF

   bZagl := {|| zagl() }
   nUkupno := 0
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 8
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   Eval( bZagl )
   SELECT PRIPRZ
   nCnt := 0
   DO WHILE !Eof() .AND. PRIPRZ->idpos == cIdPos .AND. PRIPRZ->idvd == cIdVd .AND. PRIPRZ->datum == dDatum .AND. PRIPRZ->brDok == cBrDok

      check_nova_strana( bZagl, s_oPDF )
      cIdRoba := PRIPRZ->idRoba
      select_o_roba( cIdRoba )
      SELECT PRIPRZ
      nCnt++
      ? Transform( nCnt, "99999" ), cIdRoba
      ?? PadR( roba->naz, s_cRobaNazDuzina ) + " "
      ?? Transform( PRIPRZ->kolicina, s_cPicKolicina ) + " "
      ?? Transform( PRIPRZ->cijena, s_cPicCijena ) + " "
      ?? Transform( PRIPRZ->ncijena, s_cPicCijena ) + " "
      ?? Transform( PRIPRZ->ncijena - PRIPRZ->cijena, s_cPicCijena ) + " "
      nCol := PCol()
      ?? Transform( PRIPRZ->kolicina * ( PRIPRZ->ncijena - PRIPRZ->cijena ), s_cPicIznos )
      nUkupno += PRIPRZ->kolicina * ( PRIPRZ->ncijena - PRIPRZ->cijena )
      SKIP
   ENDDO
   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   zagl( "-" )
   ?U "  UKUPNO DOKUMENT:"

   @ PRow(), nCol SAY Transform( nUkupno, s_cPicIznos )
   zagl( "-" )

   PopWa()
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl( cSamoLinija )

   LOCAL cLinija := "", cKolone := ""
   LOCAL nLen

   IF cSamoLinija == NIL
      cSamoLinija := "sve"
   ENDIF

   nLen := FIELD_LEN_POS_RBR
   cLinija += Replicate( "-", nLen )
   cKolone += PadC( "Rbr", nLen )

   nLen := 10
   cLinija += " " + Replicate( "-", nLen )
   cKolone += " " + PadC( "Roba", nLen )

   nLen := s_cRobaNazDuzina
   cLinija += " " + Replicate( "-",  nLen )
   cKolone += " " + PadC( "Naziv", nLen )

   nLen := Len( s_cPicKolicina )
   cLinija += " " + Replicate( "-", nLen )
   cKolone += " " + PadC( "količina", nLen )

   nLen := Len( s_cPicCijena )
   cLinija += " " + Replicate( "-", nLen )
   cKolone += " " + PadC( "Cijena", nLen )

   nLen := Len( s_cPicCijena )
   cLinija += " " + Replicate( "-",  nLen )
   cKolone += " " + PadC( "Nova.C", nLen )

   nLen := Len( s_cPicCijena )
   cLinija += " " + Replicate( "-",  nLen )
   cKolone += " " + PadC( "Razlika.C", nLen )

   nLen := Len( s_cPicIznos )
   cLinija += " " + Replicate( "-", nLen )
   cKolone += " " + PadC( "Razlika", nLen )

   IF cSamoLinija == "-"
      ?U cLinija
      RETURN .T.
   ENDIF

   ?U cLinija
   ?U cKolone
   ?U cLinija

   RETURN .T.
