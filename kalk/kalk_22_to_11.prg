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
   LOCAL cBrDok := Space( FIELD_LEN_KALK_BRDOK )
   LOCAL GetList := {}
   LOCAL nRet

   Box(, 3, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj dokumenta 22: " GET cBrDok

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   cBrDok := PadL(AllTrim( cBrDok ), FIELD_LEN_KALK_BRDOK, '0')
   nRet := kalk_22_to_11( cBrDok )

   IF nRet == 0
      IF kalk_povrat_dokumenta_by_idfirma_idvd_brdok( cIdFirma, '11', cBrDok )
         MsgBeep( "U pripremi se nalazi dokument 11-" + cBrDok )
      ELSE
         MsgBeep( "11-" + cBrDok + "povrat u pripremu neuspješan?!" )
      ENDIF
   ELSE
      Alert( _u( "Neuspješno izvršenje operacije 22->11 Status:" + AllTrim(Str(nRet)) + " ?!" ) )
   ENDIF

   RETURN .T.


// FUNCTION public.kalk_22_to_11( cBrDok varchar ) RETURNS integer

FUNCTION kalk_22_to_11( cBrDok )

   LOCAL cQuery, oRet, oError, nRet := -999

   cQuery := "SELECT public.kalk_22_to_11(" + ;
      sql_quote( cBrDok ) + ")"


   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "SQL neuspješno izvršenje 22->11 [" + AllTrim( Str( nRet ) ) + "] ?" ) )
   END SEQUENCE

   RETURN nRet
