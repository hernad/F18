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

MEMVAR GetList

THREAD STATIC s_psqlServer := NIL  // glavni thread
THREAD STATIC s_pgsqlServerPostgresDb := NIL
STATIC s_psqlServer_params := NIL  // parametri trebaju biti dostupni novim threadovima

THREAD STATIC s_psqlServerDbfThread := NIL // svaka thread konekcija zasebna
THREAD STATIC s_psqlServer_params_thread := NIL  // svaka thread konekcija ce zapamtiti svoje parametre

STATIC s_nSQLConnections := 0
STATIC s_aSQLConnections := {}
STATIC s_mtxMutex


FUNCTION sql_data_conn( oServer )

   LOCAL oError
   LOCAL nI, cMsg, cLogMsg := ""

   IF !is_in_main_thread()
      IF oServer <> NIL
         s_psqlServerDbfThread := oServer
      ENDIF
      RETURN s_psqlServerDbfThread
   ENDIF

   IF oServer <> NIL
      s_psqlServer := oServer
   ENDIF

   RETURN s_psqlServer



FUNCTION sql_postgres_conn( oServer )

   IF oServer <> NIL
      s_pgsqlServerPostgresDb := oServer
   ENDIF

   RETURN s_pgsqlServerPostgresDb


FUNCTION server_postgres_db_close()

   RETURN my_server_close( 0 )


FUNCTION my_server_close( nConnType )

   LOCAL oServer, pDb, nPos

   hb_default( @nConnType, 1 )

   IF nConnType == 1
      oServer := sql_data_conn()  // db organizacija
   ELSE
      oServer := sql_postgres_conn()
   ENDIF

   IF is_var_objekat_tpqserver( oServer )
      pDb := oServer:pDb
      IF HB_ISNIL( pDb )
         ?E "TPQSERVER pDb IS NIL", s_nSQLConnections
         RETURN .F.
      ENDIF
      IF hb_mutexLock( s_mtxMutex )
         s_nSQLConnections--
         nPos := AScan( s_aSQLConnections, {| item |  item[ 1 ] == oServer } )
         IF nPos > 0
#ifdef F18_DEBUG_SQL
            ?E "CCCCCCCCCCCCCCCCCLOSE TPQSERVER CLOSE CONNECTION port:", s_aSQLConnections[ nPos, 2 ]
#endif
            ADel( s_aSQLConnections, nPos )
            ASize( s_aSQLConnections, Len( s_aSQLConnections ) - 1 )
         ENDIF
         hb_mutexUnlock( s_mtxMutex )
      ENDIF

      oServer:close()
      oServer := NIL

#ifdef F18_DEBUG_THREAD
      ?E Replicate( iif( is_in_main_thread(), "%", "t" ), 50 ), "TPQSERVER " + iif( is_in_main_thread(), "", "THREAD " ), "CLOSE", ;
         iif( nConnType == 0, "POSTGRES DB", "DATA DB" ), pDb, s_nSQLConnections
#endif


   ELSE
      ?E "ERROR: server is not TPQServer objekat ?!"
   ENDIF

   IF !is_in_main_thread()
      s_psqlServerDbfThread := NIL
   ENDIF

   RETURN .T.


FUNCTION my_database()

   LOCAL hParams := my_server_params()

   IF ValType( hParams ) == "H" .AND. hb_HHasKey( hParams, "database" )
      RETURN hParams[ "database" ]
   ENDIF

   RETURN "?undefined?"


FUNCTION my_server_logout( nConnType )

   RETURN my_server_close( nConnType )



FUNCTION num_sql_connections()
   RETURN Len( s_aSQLConnections )

PROCEDURE print_sql_connections()

   LOCAL aConnection

   IF hb_mutexLock( s_mtxMutex )
      ?E "SQL connections:"
      FOR EACH aConnection IN s_aSQLConnections
         IF ValType( aConnection ) == "A"
            ?E aConnection[ 1 ], aConnection[ 2 ]
         ELSE
            ?E ValType( aConnection )
         ENDIF
      NEXT
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   RETURN

/*
 set_get server_params
*/

FUNCTION my_server_params( hSqlParams )

   LOCAL cKey

   IF !is_in_main_thread()
      IF hSqlParams <> NIL
         FOR EACH cKey in hSqlParams:Keys
            s_psqlServer_params_thread[ cKey ] := hSqlParams[ cKey ]
         NEXT
      ELSE
         IF HB_ISNIL( s_psqlServer_params_thread )
            s_psqlServer_params_thread := hb_HClone( s_psqlServer_params )
         ENDIF
      ENDIF
      RETURN s_psqlServer_params_thread // svaki thread treba zapamtiti svoje parametre
   ENDIF

   IF hSqlParams <> NIL
      FOR EACH cKey in hSqlParams:Keys
         s_psqlServer_params[ cKey ] := hSqlParams[ cKey ]
      NEXT
   ENDIF

   RETURN hb_HClone( s_psqlServer_params )


FUNCTION f18_baza_server_host()
   RETURN    "[" + my_server_params()[ "database" ] + "] " + my_server_params()[ "host" ] + ":" + AllTrim( Str( my_server_params()[ "port" ] ), 5 )


FUNCTION tekuca_sezona()

   LOCAL hDbServerParams
   LOCAL pRegex
   LOCAL aMatch

   hDbServerParams := my_server_params()
   pRegex := hb_regexComp( "(.*)_(\d+)" )
   IF !hb_HHasKey( hDbServerParams, "database" )
      RETURN( Year( Date() ) )
   ENDIF

   aMatch := hb_regex( pRegex, hDbServerParams[ "database" ] )

   IF Len( aMatch ) > 0 // aMatch[1]="test_2016" aMatch[2]="test", aMatch[3]="2016"
      RETURN Val( aMatch[ 3 ] )
   ENDIF

   RETURN -1


FUNCTION in_tekuca_godina()

   RETURN tekuca_sezona() == Year( Date() )



FUNCTION my_server_login( hSqlParams, nConnType )

   LOCAL oServer
   LOCAL oQry, hParams

   IF hSqlParams == NIL
      hSqlParams := my_server_params()
   ENDIF

   IF !hb_HHasKey( hSqlParams, "host" )
      Alert( "my server login hSqlParams ERROR" + pp( hSqlParams ) )
      QUIT
   ENDIF

   IF nConnType == NIL
      nConnType := 1
   ENDIF


   IF nConnType == 0
      hSqlParams[ "database" ] := "postgres"
      hSqlParams[ "schema" ] := "public"
   ENDIF

   oServer := TPQServer():New( hSqlParams[ "host" ], ;
      hSqlParams[ "database" ], ;
      hSqlParams[ "user" ], ;
      hSqlParams[ "password" ], ;
      hSqlParams[ "port" ], ;
      hSqlParams[ "schema" ] )

#ifdef F18_DEBUG_SQL
   ?E Replicate( iif( is_in_main_thread(), "m", "." ), 60 ), "TPQSERVER NEW", iif( is_in_main_thread(), "", "THREAD" ), hSqlParams[ "database" ], oServer:pDb, s_nSQLConnections
#endif

   IF  !oServer:NetErr() .AND. Empty( oServer:ErrorMsg() )

      IF nConnType == 0
         sql_postgres_conn( oServer )
      ELSE
         sql_data_conn( oServer ) // konekcija za organizaciju
         // info_bar( "login", "server connection ok: " + hSqlParams[ "user" ] + " / " + iif ( nConnType == 1, hSqlParams[ "database" ], "postgres" ) + " / verzija aplikacije: " + f18_ver(), 1 )
      ENDIF

      hParams := hb_Hash()
      hParams[ "server" ] := oServer
      oQry := run_sql_query( "SELECT current_user, inet_client_port()", hParams )
#ifdef F18_DEBUG_SQL
      ??E " user:", oQry:FieldGet( 1 ), " client port", oQry:FieldGet( 2 )
#endif
      IF hb_mutexLock( s_mtxMutex )
         s_nSQLConnections++
         AAdd( s_aSQLConnections, { oServer,  oQry:FieldGet( 1 ), oQry:FieldGet( 2 ) } )
         hb_mutexUnlock( s_mtxMutex )
      ENDIF

      RETURN .T.

   ELSE
      error_bar( "login", "error server connection: " + oServer:ErrorMsg() )
      RETURN .F.
   ENDIF

   RETURN .T.



FUNCTION f18_promjena_sezone()

   LOCAL oLogin := my_login()

   oLogin:promjena_sezone()

   RETURN .T.



/*
FUNCTION my_server_search_path()

   LOCAL cKey := "search_path"

   IF !hb_HHasKey( s_psqlServer_params, cKey )
      s_psqlServer_params[ cKey ] := F18_PSQL_SCHEMA + ",public"
   ENDIF

   RETURN s_psqlServer_params[ cKey ]
*/

FUNCTION f18_user( lAdmin )

   IF lAdmin == NIL
      lAdmin := .F.
   ENDIF
   IF lAdmin
      RETURN  get_f18_param( "admin_user" )
   ENDIF

   IF !hb_HHasKey(s_psqlServer_params, "user")
      RETURN "unknown"
   ENDIF

   RETURN s_psqlServer_params[ "user" ]

FUNCTION f18_password( lAdmin )

   IF lAdmin == NIL
      lAdmin := .F.
   ENDIF

   IF lAdmin
      RETURN  get_f18_param( "admin_password" )
   ENDIF

   RETURN s_psqlServer_params[ "password" ]

FUNCTION f18_database()
   RETURN s_psqlServer_params[ "database" ]


FUNCTION f18_curr_session()
   RETURN s_psqlServer_params[ "session" ]


FUNCTION my_user()
   RETURN f18_user()


INIT PROCEDURE init_my_sql_server()

   //OutStd('init-4' + hb_eol())
   s_mtxMutex := hb_mutexCreate()
   s_psqlServer_params := hb_Hash()

   RETURN
