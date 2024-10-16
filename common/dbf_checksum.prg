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


FUNCTION check_recno_and_fix( cDbfAlias, nCntSql, nCntDbf )

   LOCAL aDbfRec
   LOCAL _sql_table
   LOCAL cErrMsg
   LOCAL lRet := .T.

   aDbfRec :=  get_a_dbf_rec( cDbfAlias )
   _sql_table :=  my_server_params()[ "schema" ] + "." + aDbfRec[ "table" ]

   IF nCntSql <> nCntDbf

      cErrMsg := "alias: " + aDbfRec[ "alias" ] + " cnt_dbf: " + AllTrim( Str( nCntDbf, 10, 0 ) ) + " "
      cErrMsg += "sql_tbl: " + _sql_table + " cnt_sql: " + AllTrim( Str( nCntSql, 10 ) )


      IF nCntDbf > 0 .AND. Abs( nCntDbf - nCntSql ) == 1
         error_bar( "check_recno_diff", "1DIFF: " + cDbfAlias + "  jedan zapis razlike?!" )
      ENDIF

      // TODO: vratiti ili izbrisati notify_podrska( cErrMsg )
      IF nCntDbf > 0
         error_bar( "check_recno_diff", cErrMsg )
      ELSE
         info_bar( "check_recno_diff", cErrMsg )
      ENDIF
      lRet := full_synchro( aDbfRec[ "table" ], 50000, "dbf_cnt_before: " + AllTrim( Str( nCntDbf, 10, 0 ) ) )

   ENDIF

   RETURN lRet
