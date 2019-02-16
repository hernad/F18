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


/*
 napuni tablu sa servera
  nStepSize - broj zapisa koji se citaju u jednom query-u
*/
FUNCTION full_synchro( cDbfTable, nStepSize, cInfo )

   LOCAL _seconds
   LOCAL nCountSql
   LOCAL _offset
   LOCAL cQuery
   LOCAL _sql_table, _sql_fields
   LOCAL aDbfRec
   LOCAL _sql_order
   LOCAL _opened
   LOCAL _sql_fetch_time, _dbf_write_time
   LOCAL _msg
   LOCAL lRet := .T.
   LOCAL hParams := hb_Hash()

   IF nStepSize == NIL
      nStepSize := 20000
   ENDIF

#ifdef F18_DEBUG
  ?E "full_sync start", cDbfTable
#endif

   IF !nuliraj_ids_and_update_my_semaphore_ver( cDbfTable )
      RETURN .F.
   ENDIF
   // transakcija treba da se ne bi vidjele promjene koje prave drugi
   // ako nemam transakcije onda se moze desiti ovo:
   // 1) odabarem 100 000 zapisa i pocnem ih uzimati po redu (po dokumentima)
   // 2) drugi korisnik izmijeni neki stari dokument u sredini prenosa i u njega doda 500 stavki
   // 4) ja cu pokupiti 100 000 stavki a necu posljednjih 500
   // 3) ako nema transakcije ja cu pokupiti tu promjenu, sa transakcijom ja tu promjenu neću vidjeti

   _sql_table  := f18_sql_schema( cDbfTable )
   aDbfRec  := get_a_dbf_rec( cDbfTable )
   _sql_fields := sql_fields( aDbfRec[ "dbf_fields" ] )

   _sql_order  := aDbfRec[ "sql_order" ]

   IF !open_exclusive_zap_close( aDbfRec ) // nuliranje tabele
      unset_a_dbf_rec_chk0( aDbfRec[ "table" ] )
      RETURN .F.
   ENDIF

   hParams[ "tran_name" ] := "full_" + cDbfTable + ":" + cInfo

   run_sql_query( "BEGIN; SET TRANSACTION ISOLATION LEVEL SERIALIZABLE", hParams )

/*
   ERROR:  SET TRANSACTION ISOLATION LEVEL must be called before any query
STATEMENT:  BEGIN; SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
WARNING:  there is already a transaction in progress
*/

   nCountSql := table_count( _sql_table, "true" )


   ?E "START full_synchro table: " + cDbfTable + "/ sql count: " + AllTrim( Str( nCountSql ) )

   _seconds := Seconds()

   IF _sql_fields == NIL
      run_sql_query( "ROLLBACK", hParams )
      _msg := "sql_fields za " + _sql_table + " nije setovan ... sinhro nije moguć"
      ?E "full_synchro: " + _msg
      unset_a_dbf_rec_chk0( aDbfRec[ "table" ] )
      ?E _msg
      RaiseError( _msg )
   ENDIF

   info_bar( "fsync:" + cDbfTable, "START: " + cDbfTable  + " : " + cInfo + " sql_cnt:" + AllTrim( Str( nCountSql, 10, 0 ) ) )

   FOR _offset := 0 TO nCountSql STEP nStepSize

      cQuery :=  "SELECT " + _sql_fields + " FROM " + _sql_table
      cQuery += " ORDER BY " + _sql_order
      cQuery += " LIMIT " + Str( nStepSize ) + " OFFSET " + Str( _offset )

      // log_write( "GET FROM SQL full_synchro tabela: " + cDbfTable + " " + AllTrim( Str( _offset ) ) + " / qry: " + cQuery, 7 )

      lRet := fill_dbf_from_server( cDbfTable, cQuery, @_sql_fetch_time, @_dbf_write_time, .T. )

      IF !lRet
         run_sql_query( "ROLLBACK", hParams )
         error_bar( "fsync:" + cDbfTable, "ERROR-END full_synchro: " + cDbfTable )
         unset_a_dbf_rec_chk0( aDbfRec[ "table" ] )
         RETURN lRet
      ENDIF

      info_bar( "fsync:" + cDbfTable, "STEP full_synchro tabela: " + cDbfTable + " " + AllTrim( Str( _offset + nStepSize ) ) + " / " + AllTrim( Str( nCountSql ) ) )

   NEXT

#ifdef F18_DEBUG_SYNC
   nCountSql := table_count( _sql_table, "true" )
   ?E "full_synchro sql (END transaction): ", cDbfTable, "/ sql_tbl_cnt: ", AllTrim( Str( nCountSql ) )
#endif

   run_sql_query( "COMMIT", hParams )

   nCountSql := table_count( _sql_table, "true" )
#ifdef F18_DEBUG_SYNC
   ?E "sql cnt (END transaction): " + cDbfTable + "/ sql count: " + AllTrim( Str( nCountSql ) )
#endif

   info_bar( "fsync", "END full_synchro: " + cDbfTable +  " cnt: " + AllTrim( Str( nCountSql ) ) )
   set_a_dbf_rec_chk0( aDbfRec[ "table" ] )

   RETURN lRet
