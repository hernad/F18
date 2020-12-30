/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_dDatumNaServeru

/*
   Opis: vraća/setuje statičku varijablu s_dDatumNaServeru

   Usage:
      datum_server() => vraća vrijednost statičke varijable s_dDatumNaServeru
      datum_server(.T.) => iščitava vrijednost sa sql servera i setuje statičku varijablu s_dDatumNaServeru

*/
FUNCTION datum_server( lSet )

   IF lSet == NIL
      lSet := .F.
   ENDIF

   IF lSet .OR. s_dDatumNaServeru == NIL
      s_dDatumNaServeru := datum_server_sql()
   ENDIF

   RETURN s_dDatumNaServeru



STATIC FUNCTION datum_server_sql()

   LOCAL cQuery := "SELECT CURRENT_DATE;"
   LOCAL oQuery

   oQuery := run_sql_query( cQuery )

   IF sql_error_in_query( oQuery )
      RETURN Date()
   ENDIF

   RETURN oQuery:FieldGet( 1 )
