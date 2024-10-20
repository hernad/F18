/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

THREAD STATIC s_hParametri := NIL
THREAD STATIC s_nErrorCount := 0
THREAD STATIC s_lProvjeriPrefix := .T.

FUNCTION fetch_metric( cSection, cUser, xDefaultValue )

   LOCAL cPrefix

   cPrefix := params_prefix( .F. )
   IF cPrefix == "XYZ"
      RETURN "undefined"
   ENDIF

   RETURN f18_fetch_metric( cPrefix, cSection, cUser, xDefaultValue )


FUNCTION f18_fetch_metric( cPrefix, cSection, cUser, xDefaultValue )

   LOCAL cQuery
   LOCAL oQuery
   LOCAL cField
   LOCAL xRet

   IF xDefaultValue == NIL
      xDefaultValue := ""
   ENDIF

   IF cUser != NIL
      IF cUser == "<>"
         cSection += "/" + f18_user()
      ELSE
         cSection += "/" + cUser
      ENDIF
   ENDIF

   IF s_hParametri == NIL
      init_parameters_cache()
   ENDIF

   IF hb_HHasKey( s_hParametri, cSection ) .AND. !parametar_dinamican( cSection )
#ifdef F18_DEBUG_PARAMS
      ?E "fetch param cache hit: ", cSection
#endif
      RETURN s_hParametri[ cSection ]
   ENDIF

   cQuery := "SELECT " +  cPrefix + ".fetchmetrictext(" + sql_quote( cSection )  + ")"
   oQuery := run_sql_query( cQuery )

   IF sql_error_in_query( oQuery, "SELECT" )
      s_nErrorCount++
      RETURN xDefaultValue
   ELSE
      s_nErrorCount := 0
   ENDIF


   IF sql_query_bez_zapisa( oQuery )
      RETURN xDefaultValue
   ENDIF

   cField := oQuery:FieldGet( 1 )

   IF cField == "!!notfound!!"
      xRet := xDefaultValue
   ELSE

      xRet := str_to_val( cField, xDefaultValue )
      s_hParametri[ cSection ] :=  xRet
   ENDIF

   RETURN xRet


FUNCTION fetch_metric_error()
   RETURN s_nErrorCount



FUNCTION parametar_dinamican( cSectionIn )

   IF "auto_plu_" $ cSectionIn
      RETURN .T.
   ENDIF

   IF "_doc_no" $ cSectionIn
      RETURN .T.
   ENDIF

   IF "_brojac_" $ cSectionIn  // brojaci se moraju uvijek citati sa servera
      RETURN .T.
   ENDIF
   IF "_counter_" $ cSectionIn
      RETURN .T.
   ENDIF

   IF "_counter_" $ cSectionIn
      RETURN .T.
   ENDIF

   IF "f18_backup_" $ cSectionIn
      RETURN .T.
   ENDIF

   IF "lock_" $ cSectionIn
      RETURN .T.
   ENDIF

   IF Left( cSectionIn, 5 ) == "fakt/"  // fakt brojaci
      RETURN .T.
   ENDIF

   RETURN .F.


FUNCTION set_metric( cSection, cUser, xValue )

   LOCAL cPrefix

   cPrefix := params_prefix()

   RETURN f18_set_metric( cPrefix, cSection, cUser, xValue )


FUNCTION f18_set_metric( cPrefix, cSection, cUser, xValue )

   LOCAL oQry
   LOCAL cQuery
   LOCAL cValue

   IF cUser != NIL
      IF cUser == "<>"
         cSection += "/" + f18_user()
      ELSE
         cSection += "/" + cUser
      ENDIF
   ENDIF

   SET CENTURY ON
   cValue := hb_ValToStr( xValue )
   SET CENTURY OFF

   cQuery := "SELECT " + cPrefix + ".setmetric(" + sql_quote( cSection ) + "," + sql_quote( cValue ) +  ")"
   oQry := run_sql_query( cQuery )
   IF sql_error_in_query( oQry, "SELECT" )
      RETURN .F.
   ENDIF

   IF s_hParametri == NIL
      init_parameters_cache()
   ENDIF
   s_hParametri[ cSection ] := xValue

   RETURN .T.



STATIC FUNCTION params_prefix( lExit )

   LOCAL cPrefix, cError

   IF lExit == NIL
      lExit := .T.
   ENDIF

   IF programski_modul() == "POS"
      cPrefix := pos_prodavnica_sql_schema()
   ELSE
      cPrefix := "public"
   ENDIF

   IF s_lProvjeriPrefix
      IF !sql_schema_exists( cPrefix )
         IF lExit
           cError := "SQL Schema " + cPrefix + " NE POSTOJI ?!"
           ?E cError
           Alert( cError )
           QUIT_1
         ELSE
           RETURN "XYZ"
         ENDIF
      ENDIF
      s_lProvjeriPrefix := .F.
   ENDIF

   RETURN cPrefix


STATIC FUNCTION str_to_val( xValue, xDefaultValue )

   LOCAL cValType := ValType( xDefaultValue )

   DO CASE
   CASE cValType == "C"
      RETURN hb_UTF8ToStr( xValue )
   CASE cValType == "N"
      RETURN Val( xValue )
   CASE cValType == "D"
      RETURN CToD( xValue )
   CASE cValType == "L"
      IF Lower( xValue ) == ".t."
         RETURN .T.
      ELSE
         RETURN .F.
      ENDIF
   END CASE

   RETURN NIL


// ----------------------------------------------------------
// set/get globalne parametre F18
// ----------------------------------------------------------
FUNCTION get_set_global_param( cParamName, xValue, xDefaultValue )

   LOCAL cRet

   IF xValue == NIL
      cRet := fetch_metric( cParamName, NIL, xDefaultValue )
   ELSE
      set_metric( cParamName, NIL, xValue )
      cRet := xValue
   ENDIF

   RETURN cRet


// ----------------------------------------------------------
// set/get user parametre F18
// ----------------------------------------------------------
FUNCTION get_set_user_param( cParamName, xValue, xDefaultValue )

   LOCAL cRet

   IF xValue == NIL
      cRet := fetch_metric( cParamName, my_user(), xDefaultValue )
   ELSE
      set_metric( cParamName, my_user(), xValue )
      cRet := xValue
   ENDIF

   RETURN cRet




FUNCTION init_parameters_cache()

   s_hParametri := hb_Hash()
   organizacija_params_init()

   RETURN .T.


FUNCTION params_in_cache()

   LOCAL cKey, nCnt := 0

   FOR EACH cKey IN s_hParametri:Keys
      nCnt++
   NEXT

   RETURN nCnt
