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

FUNCTION kalk_22_to_11_unos()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cBrDokNew
   LOCAL aPKontoBrDok

   aPKontoBrDok := kalk_22_neobradjeni_odabir_iz_liste()
   IF Empty( aPKontoBrDok[ 2 ] )
      MsgBeep( "Nema dokumenata za obradu [22]->[11]" )
      RETURN .F.
   ENDIF

   cBrDokNew := kalk_22_to_11( aPKontoBrDok[ 1 ], aPKontoBrDok[ 2 ] )

   IF Left( cBrDokNew, 1 ) <> "-"
      IF kalk_povrat_dokumenta_by_idfirma_idvd_brdok( cIdFirma, '11', cBrDokNew )
         MsgBeep( "U pripremi se nalazi dokument 11-" + cBrDokNew )
         kalk_pripr_obrada( .F. )
      ELSE
         MsgBeep( "11-" + cBrDokNew + "povrat u pripremu neuspješan?!"  )
      ENDIF
   ELSE
      Alert( _u( "Neuspješno izvršenje operacije 22->11 Status:" + cBrDokNew + " ?!" ) )
   ENDIF

   RETURN .T.


// FUNCTION public.kalk_22_to_11( cBrDok varchar ) RETURNS varchar
// ako je sve ok vrati cBrDokNew, ako ima greska vrati string error-a kao npr: '-1'

FUNCTION kalk_22_to_11( cPKonto, cBrDok )

   LOCAL cQuery, oRet, oError, cRet := '-999'

   cQuery := "SELECT public.kalk_22_to_11(" + ;
      sql_quote( cPKonto ) + "," + ;
      sql_quote( cBrDok ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         cRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno izvršenje 22->11 [" + cRet + "] ?" ) )
   END SEQUENCE

   RETURN cRet


FUNCTION kalk_22_neobradjeni_odabir_iz_liste()

   LOCAL GetList := {}
   LOCAL aLista, nI
   LOCAL aMeni := {}
   LOCAL nIzbor := 1
   LOCAL nRet := 0

   aLista := kalk_22_get_lista()
   IF Len( aLista ) == 0
      RETURN  { "", "" }
   ENDIF

   FOR nI := 1 TO Len( aLista )
      AAdd( aMeni, PadR( aLista[ nI ][ "pkonto" ] + ": " + DToC( aLista[ nI ][ "datdok" ] ) + " /" + aLista[ nI ][ "brdok" ] + " - " + aLista[ nI ][ "brfaktp" ], 40 ) )
   NEXT

   nRet := meni_fiksna_lokacija( box_x_koord() + 5, box_y_koord() + 10, aMeni, nIzbor )
   IF nRet == 0
      RETURN { "", "" }
   ENDIF

   RETURN { aLista[ nRet ][ "pkonto" ], aLista[ nRet ][ "brdok" ] }

// FUNCTION public.kalk_71_to_79_dokumenti( nProdavnica integer, dDatum date )
// RETURNS TABLE (brdok varchar, prodavnica varchar, mjesec varchar, dan varchar, broj varchar )

FUNCTION kalk_22_get_lista()

   LOCAL cQuery, oData, oRow, oError, hRec, aLista := {}

   cQuery := "SELECT * FROM public.kalk_22_neobradjeni_dokumenti()";

      oData := run_sql_query( cQuery )
   DO WHILE !oData:Eof()
      oRow := oData:GetRow()
      hRec := hb_Hash()
      hRec[ "pkonto" ] := oRow:FieldGet( oRow:FieldPos( "pkonto" ) )
      hRec[ "brdok" ] := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
      hRec[ "datdok" ] := oRow:FieldGet( oRow:FieldPos( "datdok" ) )
      hRec[ "brfaktp" ] := oRow:FieldGet( oRow:FieldPos( "brfaktp" ) )
      AAdd( aLista, hRec )
      oData:skip()
   ENDDO()

   RETURN aLista
