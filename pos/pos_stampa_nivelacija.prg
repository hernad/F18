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

   LOCAL cNaslov
   LOCAL cIdPos, cIdVd, dDatum, cBrDok // , cBrFaktP

   cIdPos := hParams[ "idpos" ]
   cIdVd  := hParams[ "idvd" ]
   cBrDok := hParams[ "brdok" ]
   dDatum := hParams[ "datum" ]
   // cBrFaktP := hParams["brfaktp"]

   cNaslov := "POS NIVELACIJA " + cIdPos + "-" + cIdVd + "-" + cBrDok + " od " + DToC( dDatum ) + "   NA DAN " + DToC( danasnji_datum() )
   PushWA()

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
   seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok )

   DO WHILE !Eof() .AND. pos->idpos == cIdPos .AND. pos->idvd == cIdVd .AND. pos->datum == dDatum .AND. pos->brDok == cBrDok

      check_nova_strana( bZagl, s_oPDF )
      cIdRoba := pos->idRoba
      select_o_roba( cIdRoba )
      SELECT POS
      ? pos->rbr, cIdRoba
      ?? PadR( roba->naz, s_cRobaNazDuzina ) + " "
      ?? Transform( pos->kolicina, s_cPicKolicina ) + " "
      ?? Transform( pos->cijena, s_cPicCijena ) + " "
      ?? Transform( pos->ncijena, s_cPicCijena ) + " "
      ?? Transform( pos->ncijena - pos->cijena, s_cPicCijena ) + " "
      nCol := pcol()
      ?? Transform( pos->kolicina * (pos->ncijena - pos->cijena), s_cPicIznos )
      nUkupno += pos->kolicina * ( pos->ncijena - pos->cijena )

      SKIP
   ENDDO
   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   zagl( "-" )
   ?U "  UKUPNO DOKUMENT:"

    @ prow(), nCol SAY Transform( nUkupno, s_cPicIznos )
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
