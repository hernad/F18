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

FUNCTION pos_stampa_zaduzenja( hParams )

   LOCAL lPredispozicija := .F.
   LOCAL nRobaNazivSirina := 40
   LOCAL cLm := Space ( 5 )
   LOCAL cPicKol := "9999999.999"
   LOCAL cPicIzn := "99999999.99"
   LOCAL aTarife := {}
   LOCAL cRobaNaStanju := "N"
   LOCAL cLine
   LOCAL cLine2
   LOCAL xPrintOpt, bZagl
   LOCAL aLines
   LOCAL nFinZad
   LOCAL nCol := 50
   LOCAL cNazDok

   nRobaNazivSirina := 40
   cLM := ""

   PushWa()
   IF !hParams[ "priprema" ]
      IF !seek_pos_pos( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ], "1", "PRIPRZ" )
         PopWa()
         RETURN .F.
      ENDIF
   ENDIF

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9

   cNazDok := pos_dokument_naziv( hParams[ "idvd" ] ) + " " + AllTrim( hParams[ "idpos" ] ) + "-" + hParams[ "idvd" ] + "-" + AllTrim( hParams[ "brdok" ] )
   cNazDok += " od: " + FormDat1 ( hParams[ "datum" ] )

   IF f18_start_print( NIL, xPrintOpt,  cNazDok + " Štampa na dan: " + DToC( Date() ) ) == "X"
      PopWa()
      RETURN .F.
   ENDIF

   select_o_partner( hParams[ "idpartner" ] )
   ? "Partner:", hParams[ "idpartner" ], AllTrim( partn->naz )

   ?? "  Broj fakture:", hParams[ "brfaktp" ]
   ?  "Opis:", _u( hParams[ "opis" ] )

   aLines := get_pos_linija_podvuci( nRobaNazivSirina, cPicKol, cPicIzn )
   cLine := aLines[ 1 ]
   cLine2 := aLines[ 2 ]

   bZagl := {|| QOutU( cLM + cLine2 ), QOutU( cLM + cLine ), QOutU( cLM + cLine2 ) }

   nFinZad := 0
   SELECT PRIPRZ
   GO TOP

   Eval( bZagl )
   DO WHILE ! Eof() .AND. PRIPRZ->IdPos + PRIPRZ->IdVd + DToS( PRIPRZ->datum ) + PRIPRZ->BrDok  == hParams[ "idpos" ] + hParams[ "idvd" ] + DToS( hParams[ "datum" ] ) + hParams[ "brdok" ]

      check_nova_strana( bZagl, s_oPDF )
      select_o_roba( PRIPRZ->IdRoba )
      SELECT PRIPRZ

      ?  cLM + PRIPRZ->IdRoba + " "
      ?? PadR( AllTrim( roba->Naz ), nRobaNazivSirina - 1 ) + "  "
      ?? roba->Jmj + " "
      ?? TRANS( PRIPRZ->Kolicina, cPicKol ) + " "
      ?? TRANS( PRIPRZ->Cijena, cPicIzn ) + " "
      nCol := PCol() - 1
      ?? TRANS( PRIPRZ->Kolicina * PRIPRZ->cijena, cPicIzn )

      nFinZad += PRIPRZ->Kolicina * PRIPRZ->Cijena
      pos_setuj_tarife( PRIPRZ->IdRoba, PRIPRZ->Kolicina * PRIPRZ->Cijena, @aTarife )
      SKIP
   ENDDO

   ?U cLine2

   ?U cLM
   ?? "    UKUPNO:"
   @ PRow(), nCol SAY TRANS( nFinZad, cPicIzn )
   ?U cLine2
   ?

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   pos_rekapitulacija_tarifa( aTarife )

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ?
   ??U "        Primio:                               Predao:"
   select_o_pos_osob( hParams[ "idradnik" ] )
   ?U  "                                        " + AllTrim ( OSOB->Naz )

   f18_end_print( NIL, xPrintOpt )

   SELECT PRIPRZ
   USE
   PopWa()

   RETURN .T.


STATIC FUNCTION get_pos_linija_podvuci( nRobaNazivSirina, cPicKol, cPicIzn )

   LOCAL cLine, cLine2

   cLine := PadC( "Šifra", 10 )
   cLine2 := Replicate( "-", 10 )

   cLine  += "  " + PadC( "Naziv", nRobaNazivSirina )
   cLine2 += " " + Replicate( "-", nRobaNazivSirina )

   cLine  += " " + PadR( "JMJ", 3 )
   cLine2 += " " + Replicate( "-", 3 )

   cLine  += " " + PadC( "Količina", Len( cPicKol ) )
   cLine2 += " " + Replicate( "-", Len( cPicKol ) )

   cLine  += "  " + PadC( "Cijena", Len( cPicIzn ) )
   cLine2 += " " + Replicate( "-", Len( cPicIzn ) )

   cLine  += "  " + PadC( "Vrijednost", Len( cPicIzn ) )
   cLine2 += " " + Replicate( "-", Len( cPicIzn ) )

   RETURN { cLine, cLine2 }
