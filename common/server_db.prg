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

   LOCAL _qry
   LOCAL _ret

   hb_default( @lInit, .F. )

   IF lInit .OR. HB_ISNIL( s_nServerVersion )
      _qry := "SELECT max(version) from public.schema_migrations"
      _ret := run_sql_query( _qry )
      IF sql_error_in_query( _ret, "SELECT" )
         s_nServerVersion := -1
      ELSE
         s_nServerVersion := _ret:FieldGet( 1 )
      ENDIF
   ENDIF

   RETURN s_nServerVersion



FUNCTION check_server_db_version()

   LOCAL _server_db_num, _server_db_str, _f18_required_server_str, _f18_required_server_num
   LOCAL _msg

   info_bar( "init", "check_server_db_version" )
   _f18_required_server_num := get_version_num( server_db_ver_major(), server_db_ver_minor(), server_db_ver_patch() )

   _server_db_num := server_db_version()

   IF _server_db_num < 0
      error_bar( "server_db", "server_db_version < 0")
      RETURN .F.
   ENDIF

   IF ( _f18_required_server_num > _server_db_num )

      _f18_required_server_str := get_version_str( _f18_required_server_num )
      _server_db_str := get_version_str( _server_db_num )

      _msg := "F18 klijent trazi verziju " + _f18_required_server_str + " server db je verzije: " + _server_db_str

      ?E _msg
      error_bar( "init", "serverdb: " + _server_db_str )

      MsgBeep( _msg )

      OutMsg( 1, _msg + hb_eol() )
      RETURN .T.
   ENDIF

   RETURN .T.
