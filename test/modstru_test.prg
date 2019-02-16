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

STATIC _table_name := "f18_test"

FUNCTION create_test_f18_dbf()

   LOCAL _dbf_struct := {}
   LOCAL nI

   // tabele sa strukturom sifarnika (id je primarni ključ)
   set_a_dbf_sifarnik( _table_name, "F18_TEST", 500      )



   AAdd( _dbf_struct,      { 'ID',  'C',   2,  0 } )
   AAdd( _dbf_struct,      { 'NAZ', 'C',  10,  0 } )

   // moramo inicijalno napuniti semafor
   reset_semaphore_version( _table_name )

   DBCREATE2( _table_name, _dbf_struct )

   CREATE_INDEX( "ID",  "id", _table_name )
   CREATE_INDEX( "NAZ", "naz", _table_name )

   my_usex( _table_name )

   FOR nI := 1 TO 50
      APPEND BLANK
      REPLACE id WITH Str( nI, 2 )
      REPLACE naz WITH "naz" + Str( nI, 2 )
   NEXT

   RETURN .F.

FUNCTION modstru_test()

   LOCAL _ini_params
   LOCAL _current_dbf_ver, _new_dbf_ver
   LOCAL _ini_section := "DBF_version"

   create_sql_table_f18_test()
   create_semaphore( _table_name )
   create_test_f18_dbf()

   modstru( { "*" + _table_name, "C ID C 2 0  ID C 5 0",  "A NAZ2 C 40 0" } )

   SELECT 9000
   my_use( _table_name, _table_name )

   TEST_LINE( FieldPos( "NAZ2" ) > 0 .AND. Len( Eval( FieldBlock( "ID" ) ) ) == 5,  .T. )
   USE

   RETURN


// ------------------------------------
// ------------------------------------
FUNCTION create_sql_table_f18_test()

   LOCAL cQuery, _ret

   cQuery := "drop table if exists fmk.f18_test;"
   cQuery += "create table f18_test ("
   cQuery += "id varchar(2), naz varchar(40)"
   cQuery += "); "
   cQuery += "GRANT ALL ON TABLE fmk.f18_test TO xtrole;"

   _ret := run_sql_query( cQuery )

   IF ValType( _ret )  == "O"
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF
