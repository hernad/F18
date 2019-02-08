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
   LOCAL nDbfArea := Select()
   LOCAL xPrintOpt, bZagl
   LOCAL aLines
   LOCAL nFinZad
   LOCAL nCol := 50
   LOCAL cNazDok

   nRobaNazivSirina := 40
   cLM := ""

   IF !hParams[ "priprema" ]
      IF !seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok, "1", "PRIPRZ" )
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

      ?U  cLM + PRIPRZ->IdRoba + " "
      ??U PadR( AllTrim( roba->Naz ), nRobaNazivSirina - 1 ) + "  "
      ??U roba->Jmj + " "
      ??U TRANS( PRIPRZ->Kolicina, cPicKol ) + " "
      ??U TRANS( PRIPRZ->Cijena, cPicIzn ) + " "
      nCol := PCol() - 1
      ??U TRANS( PRIPRZ->Kolicina * PRIPRZ->cijena, cPicIzn )

      nFinZad += PRIPRZ->Kolicina * PRIPRZ->Cijena
      pos_setuj_tarife( PRIPRZ->IdRoba, PRIPRZ->Kolicina * PRIPRZ->Cijena, @aTarife )
      SKIP
   ENDDO

   ?U cLine2

   ?U cLM
   ?? "    UKUPNO:"
   @ PRow() + 1, nCol SAY TRANS( nFinZad, cPicIzn )
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

   SELECT ( nDbfArea )

   RETURN .T.

/*
FUNCTION pos_stampa_zaduzenja( cIdVd, cBrDok )

   LOCAL nPrevRec
   LOCAL cKoje
   LOCAL nFinZad
   LOCAL lPredispozicija := .F.
   LOCAL aTarife := {}
   LOCAL nPPP
   LOCAL nPPU
   LOCAL nOsn
   LOCAL nPP
   LOCAL cLinija := "---------- ----------------- --- -------- -------- --------"
   LOCAL cPom
   LOCAL xPrintOpt
   LOCAL bZagl

   nPPP := 0
   nPPU := 0
   nOsn := 0
   nPP := 0

   SELECT PRIPRZ

   IF RecCount2() == 0
      RETURN .F.
   ENDIF

   nPrevRec := RecNo()
   GO TOP
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  "Zaduženje priprema: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   cPom := ""
   cPom += pos_naslov_dok_zaduzenja( cIdVd )
   cPom += pos_dokument_naziv( cIdVd )
   cPom += AllTrim( PRIPRZ->IdPos ) + "-" + AllTrim ( cBrDok )

   ?U PadC( cPom, 40 )
   ?? " " + PadL ( FormDat1 ( PRIPRZ->Datum ), 39 )
   ?

   bZagl := {|| zagl( cLinija ) }
   Eval( bZagl )

   nFinZad := 0
   SELECT PRIPRZ
   GoTop2()
   DO WHILE ! Eof()

      nIzn := priprz->cijena * priprz->kolicina
      pos_setuj_tarife( priprz->IdRoba, nIzn, @aTarife, @nPPP, @nPPU, @nOsn, @nPP )

      check_nova_strana( bZagl, s_oPDF )
      IF !lPredispozicija
         ? priprz->idroba, PadR ( priprz->RobaNaz, 17 ), priprz->JMJ, ""
         ?? Transform ( priprz->Kolicina, "99999.99" ) + " "
         ?? Transform ( priprz->cijena, "99999.99" ) + " "
         ?? Transform ( priprz->cijena * priprz->Kolicina, "99999.99" )
         ? cLinija
      ENDIF
      nFinZad += PRIPRZ->Kolicina * priprz->Cijena

      SKIP 1

   ENDDO

   check_nova_strana( bZagl, s_oPDF )
   ? cLinija
   ?U PadL ( "UKUPNO ZADUŽENJE (" + Trim ( gDomValuta ) + ")", 29 ), ;
      TRANS ( nFinZad, "999,999.99" )
   ? cLinija

   check_nova_strana( bZagl, s_oPDF )
   pos_rekapitulacija_tarifa( aTarife )

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? " Primio " + PadL ( "Predao", 31 )
   ?
   ? PadL ( AllTrim ( gKorIme ), 39 )

   f18_end_print( NIL, xPrintOpt )

   o_pos_priprz()
   GO nPrevRec

   RETURN .T.
*/

/*
STATIC FUNCTION zagl( cLinija )

   ?U cLinija
   ?U " Sifra      Naziv            JMJ Količina  Cijena    Iznos  Ukupno"
   ?U cLinija

   RETURN .T.
*/


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
