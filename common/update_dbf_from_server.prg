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


/*
   get data from sql server, push to dbf
*/

FUNCTION update_dbf_from_server( cTabela, cAlgoritam )

   //LOCAL cQuery
   LOCAL _counter
   LOCAL _rec
   LOCAL _qry_obj
   LOCAL _server := sql_data_conn()
   //LOCAL _seconds
   //LOCAL _x, _y
   LOCAL _ids
   LOCAL _fnd, _tmp_id
   LOCAL _count
   LOCAL _sql_tbl, _dbf_tbl
   LOCAL _offset
   LOCAL nSteps := 50000
   LOCAL _retry := 3
   LOCAL _key_blocks := {}
   LOCAL _key_block
   LOCAL nI, _fld, hDbfFields, _sql_order
   LOCAL _sql_in := {}
   LOCAL _queries
   LOCAL _dbf_index_tags := {}
   LOCAL _dbf_wa, _dbf_alias
   LOCAL _ids_queries
   LOCAL _table
   LOCAL hDbfRec
   LOCAL lRet

   hDbfRec  := get_a_dbf_rec( cTabela )
   hDbfFields := hDbfRec[ "dbf_fields" ]
   //_sql_fields := sql_fields( hDbfFields )
   _sql_order  := hDbfRec[ "sql_order" ]
   _dbf_wa     := hDbfRec[ "wa" ]
   _dbf_alias  := hDbfRec[ "alias" ]
   _sql_tbl    := f18_sql_schema( cTabela )

   //_x := f18_max_rows() - 15
   //_y := f18_max_cols() - 20

   IF cAlgoritam == NIL
      cAlgoritam := "FULL"
   ENDIF

   //_seconds := Seconds()

   //log_write( "START update_dbf_from_server: " + cAlgoritam, 9 )

   IF cAlgoritam == "FULL"

      //log_write( "iniciraj full synchro:" + cTabela, 8 )
      // full synchro ne treba otvorenu tabelu, on je ionako zapuje
      lRet := full_synchro ( cTabela, nSteps, " ALG_FULL " )

   ELSE
      //log_write( "iniciraj ids synchro:" + cTabela, 8 )
      lRet := ids_synchro  ( cTabela )
   ENDIF

   //log_write( "update_dbf_from_server table: " + cTabela + " synchro cache: " + Str( Seconds() - _seconds ), 5 )
   //log_write( "END update_dbf_from_server", 9 )

   RETURN lRet
