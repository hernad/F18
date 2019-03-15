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

/* ------------------------------------------
  reset_semaphore_version( "konto")
  set version to -1
  -------------------------------------------
*/
FUNCTION server_log_write( cMessage, silent )

   LOCAL _ret
   LOCAL _result
   LOCAL cQuery
   LOCAL cTable
   LOCAL _user := f18_user()
   LOCAL hParams := hb_Hash()

   IF silent == NIL
      silent := .F.
   ENDIF

   cTable := f18_sql_schema( "log" )

   hParams[ "log" ] := .F.
   cMessage  := ProcName( 2 ) + "(" + AllTrim( Str( ProcLine( 2 ) ) ) + ") : " + cMessage
   cQuery := "INSERT INTO " + cTable + "(user_code, msg) VALUES(" +  sql_quote( _user ) + "," +  sql_quote( _u( cMessage ) ) + ")"
   _ret := run_sql_query( cQuery, hParams )

   RETURN .T.
