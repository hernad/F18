/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


/*
    cKontoUslov := "13201;13202;"
    parsiraj_sql( "mkonto", cKontoUslov, .F. )

    parsiraj_sql( "br_dok", 3 ) => br_dok=3
*/
FUNCTION parsiraj_sql( cFieldName, xConditionParam, lNot )

   LOCAL cRet := ""
   LOCAL aConditions
   LOCAL lPrazno := .F.
   LOCAL cCondition
   LOCAL lTackaZarez := .F.

   IF xConditionParam == NIL
      xConditionParam := ""
   ENDIF
   IF lNot == NIL
      lNot := .F.
   ENDIF

   IF ValType( xConditionParam ) == "N" // numeric
      cRet += cFieldName

      IF lNot
         cRet += "<>"
      ELSE
         cRet += "="
      ENDIF
      cRet += sql_quote( xConditionParam )
      RETURN cRet
   ENDIF

   IF ";" $ xConditionParam
      xConditionParam := Trim( xConditionParam )
      lTacKaZarez := .T.
   ELSEIF Len( xConditionParam ) > 99 // dugacki uslov Idkonto=SPACE(100) param, znaci da je uslov za vise konta
      xConditionParam := Trim( xConditionParam )
   ENDIF

   aConditions := TOKTONIZ( xConditionParam, ";" )

   IF Len( xConditionParam ) == 0 // "ako se proslijedi prazan string ''", ali ako se proslijedi '      ' to je validan partner u suban kartici
      lPrazno := .T.
   ENDIF

   FOR EACH cCondition in aConditions

      IF lPrazno .OR. Len( cCondition ) == 0
         LOOP
      ENDIF

      cRet += "  OR " + cFieldName

      IF lTackaZarez
         IF lNot
            cRet += " NOT "
         ENDIF
         cRet += " LIKE " + sql_quote( Trim( cCondition ) + "%" )
      ELSE
         IF lNot
            cRet += " <> "
         ELSE
            cRet += " = "
         ENDIF
         cRet += sql_quote( cCondition )
      ENDIF

   NEXT

   cRet := Right( cRet, Len( cRet ) - 5 ) // " OR  Idkonto LIKE '2110%'" => "Idkonto LIKE '2110%'"

   IF " OR " $ cRet  // "Idkonto LIKE '2110%' OR  IdPartner LIKE '12589%'" => "(Idkonto LIKE '2110%' OR  IdPartner LIKE '12589%')"
      cRet := " (" + cRet + ") "
   ENDIF

   IF Empty( cRet )
      cRet := " TRUE "
   ENDIF

   RETURN cRet



FUNCTION parsiraj_sql_date_interval( cFieldName, date1, date2 )

   LOCAL cRet := ""

   // datdok BETWEEN '2012-02-01' AND '2012-05-01'

   // dva su datuma
   IF PCount() > 2

      IF date1 == NIL
         date1 := CToD( "" )
      ENDIF
      IF date2 == NIL
         date2 := CToD( "" )
      ENDIF


      IF DToC( date1 ) == DToC( CToD( "" ) ) .AND. DToC( date2 ) == DToC( CToD( "" ) ) // oba su prazna
         cRet := "TRUE"
         // samo prvi je prazan
      ELSEIF DToC( date1 ) == DToC( CToD( "" ) )
         cRet := cFieldName + " <= " + sql_quote( date2 )
         // drugi je prazan
      ELSEIF DToC( date2 ) == DToC( CToD( "" ) )
         cRet := cFieldName + " >= " + sql_quote( date1 )
         // imamo dva regularna datuma
      ELSE
         // ako su razliciti datumi
         IF DToC( date1 ) <> DToC( date2 )
            cRet := cFieldName + " BETWEEN " + sql_quote( date1 ) + " AND " + sql_quote( date2 )
            // ako su identicni, samo nam jedan treba u LIKE klauzuli
         ELSE
            cRet := cFieldName + "::char(20) LIKE " + sql_quote( _sql_date_str( date1 ) + "%" )
         ENDIF
      ENDIF

   ELSEIF PCount() <= 1
      cRet := "TRUE" // samo jedan datumski uslov
   ELSE
      cRet := cFieldName + "::char(20) LIKE " + sql_quote( _sql_date_str( date1 ) + "%" )
   ENDIF

   RETURN "(" + cRet + ")"
