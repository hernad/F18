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

FUNCTION use_sql_rnal_ral()

   LOCAL cSql
   LOCAL aDbf := rnal_a_ral()
   LOCAL cTable := "rnal_ral"

   cSql := "SELECT "
   cSql += sql_from_adbf( @aDbf )
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + "" + cTable + " ORDER BY id"


   SELECT F_RAL
   use_sql( cTable, cSql, "RAL" )

   INDEX ON STR(field->id,5,0)+STR(field->gl_tick,2,0) TAG "1" TO (cTable)
   INDEX ON field->descr TAG "2" TO (cTable)

   SET ORDER TO TAG "1"

   RETURN .T.
