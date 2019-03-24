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

FUNCTION kalk_49_to_42_unos()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL nProdavnica := 0
   LOCAL dDatum := danasnji_datum() - 1
   LOCAL GetList := {}
   LOCAL cProd
   LOCAL cBrDok

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Prodavnica: " GET nProdavnica PICT "999" VALID nProdavnica > 0
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Datum: " GET dDatum

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cProd := "[" + AllTrim( Str( nProdavnica ) ) + "]"
   cBrDok := kalk_49_to_42( nProdavnica, dDatum )

   IF Len(Alltrim(cBrDok)) == 8
      IF kalk_povrat_dokumenta_by_idfirma_idvd_brdok( cIdFirma, '42', cBrDok )
         MsgBeep( "U pripremi se nalazi izgenerisan dokument 42-" + cBrDok + " za prodavnicu" + cProd )
      ELSE
         MsgBeep( "42 " + cBrDok + "povrat u pripremu neuspješan?!" )
      ENDIF
   ELSE
      Alert( _u( "Neuspješno izvršenje operacije 49->42 Status:" + cBrDok + " ?!") )
   ENDIF

   RETURN .T.


// FUNCTION public.kalk_49_to_42( nProdavnica integer, dDatum date) RETURNS integer

FUNCTION kalk_49_to_42( nProdavnica, dDatum )

   LOCAL cQuery, oRet, oError, cRet := ""

   cQuery := "SELECT public.kalk_49_to_42(" + ;
      sql_quote( nProdavnica ) + "," + ;
      sql_quote( dDatum ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         cRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno izvršenje 49->42 [" + AllTrim( Str( nProdavnica ) ) + "] ?" ) )
   END SEQUENCE

   RETURN cRet
