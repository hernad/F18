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

STATIC s_nServerVersion


FUNCTION server_db_version( lInit )

   LOCAL cQuery
   LOCAL oRet

   hb_default( @lInit, .F. )

   IF lInit .OR. HB_ISNIL( s_nServerVersion )
       s_nServerVersion := fetch_metric( "db_version", NIL, 1 )
      // cQuery := "SELECT max(version) from public.schema_migrations"
      // oRet := run_sql_query( cQuery )
      // IF sql_error_in_query( oRet, "SELECT" )
      //    s_nServerVersion := -1
      // ELSE
      //    s_nServerVersion := oRet:FieldGet( 1 )
      // ENDIF
   ENDIF

   RETURN s_nServerVersion



FUNCTION check_server_db_version()

   LOCAL nServerDbVersion, nKlijentRequestDbVer
   LOCAL cMsg

   info_bar( "init", "check_server_db_version" )
   nKlijentRequestDbVer := server_db_ver_klijent()

   nServerDbVersion := server_db_version()
   IF nServerDbVersion < 0
      error_bar( "server_db", "server_db_version < 0")
      RETURN .F.
   ENDIF

   IF ( nKlijentRequestDbVer > nServerDbVersion )

      cMsg := "F18 klijent trazi verziju " + AllTrim(Str(nKlijentRequestDbVer)) + " server db je verzije: " + AllTrim(Str(nServerDbVersion))

      ?E cMsg
      error_bar( "init", "serverdb: " + AllTrim(Str(nServerDbVersion)) )

      MsgBeep( cMsg )
      OutMsg( 1, cMsg + hb_eol() )
      RETURN .T.
   ENDIF

   RETURN .T.
