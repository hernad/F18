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

FUNCTION begin_sql_tran_lock_tables( aTables )

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( aTables, .T. )
      run_sql_query( "ROLLBACK" )
      error_bar( "sem", "LOCK ERROR: " + pp( aTables ) )
      RETURN .F.
   ENDIF

   RETURN .T.

/*


  koristenje f18_lock_tables( arr ), f18_unlock_tables( arr )

  if !f18_lock_tables( {"pos_doks", "pos_pos"} )
     -- prekidamo operaciju
  endif

  sql_table_update(nil, "BEGIN")
       update_rec_server_and_dbf( ALIAS(), _rec, 1, "CONT" )
       OLD: f18_unlock_tables( {"pos_doks", "pos_pos"} )
  run_sql_query( "COMMIT" )

  ako imamo samo jedan zapis, jednu tabelu, transakcija i lockovanje
  se desavaju unutar funkcije update_rec_server_and_dbf:

       update_rec_server_and_dbf( ALIAS(), _rec, 1, "FULL" )

  na isti nacin se koristi i u kombinaciji sa:

        delete_rec_server_and_dbf()


  sql_table_update(nil, "BEGIN")
     f18_lock_tables( { "rnal_vako", "rnal_nako" }, .T. }
  run_sql_query( "COMMIT" )

*/

FUNCTION f18_lock_tables( aTables )

   LOCAL _ok := .T.
   LOCAL nI, _tbl, _dbf_rec

   IF Len( aTables ) == NIL
      RETURN .T.
   ENDIF

   FOR nI := 1 TO Len( aTables )
      _dbf_rec := get_a_dbf_rec( aTables[ nI ], .T. )
      _tbl := _dbf_rec[ "table" ]
      IF !_dbf_rec[ "sql" ]
         unlock_semaphore( _tbl )
         IF !lock_semaphore( _tbl )
            error_bar( "lock", "ERR LOCK: " + _tbl )
            ?E "ERROR: neuspjesan lock tabela " + pp( aTables ), "zapeo na:", _tbl
            RETURN .F.
         ENDIF
      ENDIF
   NEXT

   RETURN .T.


/*
   unlokovanje tabela:

   OLD: f18_unlock_tables( {"pos_pos", "pos_doks"} )

*/

FUNCTION f18_unlock_tables( aTables )

   LOCAL nI, _tbl, _dbf_rec
   LOCAL cMsg

   IF Len( aTables ) == NIL
      RETURN .F.
   ENDIF

   FOR nI := 1 TO Len( aTables )
      _dbf_rec := get_a_dbf_rec( aTables[ nI ], .T. )
      _tbl := _dbf_rec[ "table" ]
      IF !_dbf_rec[ "sql" ]
         IF !unlock_semaphore( _tbl )
            RETURN .F.
         ENDIF
      ENDIF
   NEXT

   cMsg := "uspjesno izvrseno oslobadjanje tabela " + pp( aTables )
   // log_write( cMsg, 7 )

#ifdef F18_DEBUG
   ?E cMsg
#endif

   RETURN .T.
