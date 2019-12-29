/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION usex( cTable )
   RETURN my_use( cTable )


FUNCTION f18_create_dir( cLocation )

   LOCAL nLen
   LOCAL cTmp
   LOCAL nCreate

   IF ! hb_vfDirExists( cLocation )
      nCreate := DirMake( cLocation )
      IF nCreate <> 0
         log_write( "f18_create_dir, problem sa kreiranjem direktorija: (" + cLocation + ")", 5 )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION f18_help()

   ? "F18 parametri"
   ? "parametri"
   ? "-h host"
   // ? "-y port (default: 5432)"
   ? "-u user"
   ? "-p password"
   ? "-d database"
   // ? "-e schema (default: public)"
   // ? "-t fmk tables path"
   ? ""

   RETURN .T.

/*
 setup ulazne parametre F18
*/

FUNCTION set_f18_params( ... )

   LOCAL nI := 1
   LOCAL cVal, cQuery
   LOCAL cTok, hParams
   LOCAL cHostName, nPort, cDataBase, cUser, cPassWord
   LOCAL aOpcije, cOpcije

   hParams := hb_Hash()
   hParams[ "admin_user" ]  := "<undefined>"
   hParams[ "admin_password" ]  := "<undefined>"
   hParams[ "pos_pm" ] := Padr("1", 2)

   cOpcije := ""
   DO WHILE nI <= PCount()
      cOpcije += IIF(nI==0,"", " ") + hb_PValue( nI++ )
   ENDDO

   aOpcije := hb_ATokens( cOpcije, " ")

   nI := 1
   DO WHILE nI <= LEN( aOpcije )

      cTok := aOpcije[ nI++ ]

      DO CASE

      CASE cTok == NIL
         EXIT

      CASE cTok == "--no-sql"
         no_sql_mode( .T. )

      CASE cTok == "--test"
         test_mode( .T. )

      CASE cTok == "--help"
         f18_help()
         __Quit()

      CASE cTok == "--dbf-prefix"   // prefix privatni dbf
         dbf_prefix( aOpcije[ nI++ ] )

      CASE cTok == "--run-on-start"
         run_on_start_param( aOpcije[ nI++ ] )

      CASE cTok == "-h"
         cHostName := aOpcije[ nI++ ]
         set_f18_param( "host", cHostName )
         hParams[ "host" ] := cHostName

      CASE cTok == "-y"
         nPort := Val( aOpcije[ nI++ ] )
         // cParams += Space( 1 ) + "port=" + AllTrim( Str( nPort ) )
         set_f18_param( "port", nPort )
         hParams[ "port" ] := nPort

      CASE cTok == "-d"
         cDataBase := aOpcije[ nI++ ]
         set_f18_param( "database", cDatabase )
         hParams[ "database" ] := cDatabase

      CASE cTok == "-u"
         cUser := aOpcije[ nI++ ]
         set_f18_param( "user", cUser )
         hParams[ "user" ] := cUser

      CASE cTok == "-ua"
         cUser := aOpcije[ nI++ ]
         set_f18_param( "admin_user", cUser )
         hParams[ "admin_user" ]  := cUser

      CASE cTok == "-pa"
         cPassWord := aOpcije[ nI++ ]
         set_f18_param( "admin_password", cPassword )
         hParams[ "admin_password" ]  := cPassword

      CASE cTok == "-p"
         cPassWord := aOpcije[ nI++ ]
         set_f18_param( "password", cPassword )
         hParams[ "password" ]  := cPassword


         // CASE cTok == "-t"
         // cDBFDataPath := hb_PValue( nI++ )
         // hParams[ "dbf_path" ]  := cDBFDataPath

         // CASE cTok == "-e"
         // cSchema := hb_PValue( nI++ )
         // hParams[ "schema" ] := cSchema

      CASE cTok == "--show-postgresql-version"
         show_postgresql_version( hParams )
         __Quit()

      CASE cTok == "--set-pos"
         f18_sql_connect( hParams )
         cVal := aOpcije[ nI++ ]
         cQuery := "SELECT public.setmetric('pos_prod','" + cVal + "')"
         dbUseArea( .T., , cQuery, "INFO" )
         OutStd( "Parametar [pos_pod] postavljen: " + cVal )
         __Quit()

      CASE cTok == "--get-pos"
         f18_sql_connect( hParams )
         dbUseArea( .T., , "SELECT public.fetchmetrictext('pos_prod') AS prod", "INFO" )
         OutStd( "Parametar [pos_pod]: " +  field->prod )
         __Quit()

      CASE cTok == "--pos"
         set_f18_param( "run", "pos" )

      CASE cTok == "--pos-pm"
         set_f18_param( "pos_pm", aOpcije[ nI++ ] )

      CASE cTok == "--kalk"
         set_f18_param( "run", "kalk" )

      CASE cTok == "--fin"
         set_f18_param( "run", "fin" )

      CASE cTok == "--fakt"
         set_f18_param( "run", "fakt" )

      CASE cTok == "--epdv"
         set_f18_param( "run", "epdv" )

      CASE cTok == "--os"
         set_f18_param( "run", "os" )

      CASE cTok == "--ld"
         set_f18_param( "run", "ld" )

      CASE Left( cTok, 7 ) == "--json_"
         set_f18_param( "run", SubStr( cTok, 3 ) ) // json_konto, json_roba ...

      ENDCASE

   ENDDO

   RETURN hParams



FUNCTION pp( x )

   LOCAL _key, nI
   LOCAL _tmp
   LOCAL _type

   _tmp := ""

   _type := ValType( x )

   IF _type == "H"
      _tmp += "(hash): "
      FOR EACH _key in x:Keys
         _tmp +=  pp( _key ) + " / " + pp( x[ _key ] ) + " ; "
      NEXT
      RETURN _tmp
   ENDIF

   IF _type  == "A"
      _tmp += "(array): "
      FOR nI := 1 TO Len( x )
         _tmp +=  AllTrim( pp( nI ) ) + " / " + pp( x[ nI ] ) + " ; "
      NEXT
      RETURN _tmp
   ENDIF

   IF _type $ "CLDNM"
      RETURN hb_ValToStr( x )
   ENDIF

   RETURN "?" + _type + "?"



// --------------------------------------
// aktiviranje vpn podrske
// --------------------------------------
FUNCTION vpn_support( set_params )

   LOCAL _conn_name := PadR( "bringout podrska", 50 )
   LOCAL _status := 0
   LOCAL _ok

#ifdef __PLATFORM__WINDOWS

   MsgBeep( "Opcija nije omogucena !" )

   RETURN
#endif

IF set_params == NIL
set_params := .T.
ENDIF

IF set_params
_conn_name := fetch_metric( "vpn_support_conn_name", my_user(), _conn_name )
_status := fetch_metric( "vpn_support_last_status", my_user(), _status )
ELSE
_status := 1
ENDIF

IF set_params

IF _status == 0
_status := 1
ELSE
_status := 0
ENDIF

Box(, 2, 65 )
@ box_x_koord() + 1, box_y_koord() + 2 SAY "Konekcija:" GET _conn_name PICT "@S50" VALID !Empty( _conn_name )
@ box_x_koord() + 2, box_y_koord() + 2 SAY "[1] aktivirati [0] prekinuti" GET _status PICT "9"
READ
BoxC()

IF LastKey() == K_ESC
RETURN
ENDIF

ENDIF

IF set_params
set_metric( "vpn_support_conn_name", my_user(), _conn_name )
ENDIF

// startaj vpn konekciju
_ok := _vpn_start_stop( _status, _conn_name )

// ako je sve ok snimi parametar u bazu
IF _ok == 0 .AND. set_params
set_metric( "vpn_support_last_status", my_user(), _status )
ENDIF

   RETURN .T.



// ------------------------------------------------
// stopira ili starta vpn konekciju
// status : 0 - off, 1 - on
// ------------------------------------------------
STATIC FUNCTION _vpn_start_stop( STATUS, conn_name )

   LOCAL cCmd
   LOCAL _err
   LOCAL _up_dn := "up"

   IF STATUS == 0
      _up_dn := "down"
   ENDIF

   cCmd := 'nmcli con ' + _up_dn + ' id "' + AllTrim( conn_name ) + '"'

   _err := f18_run( cCmd )

   IF _err <> 0
      MsgBeep( "Problem sa vpn konekcijom:#" + AllTrim( conn_name ) + " !???" )
      RETURN _err
   ENDIF

   RETURN _err




FUNCTION f18_copy_to_desktop( cFilePath, cFileName, cOutputFile )

   LOCAL cDesktopPath

   create_f18_dokumenti_on_desktop( @cDesktopPath )

   IF cOutputFile == NIL
      cOutputFile := ""
   ENDIF

   IF Empty( cOutputFile )
      cOutputFile := cFileName
   ENDIF

   FileCopy( cFilePath + cFileName, cDesktopPath + cOutputFile )

   RETURN .T.




FUNCTION create_f18_dokumenti_on_desktop( s_cDesktopPath )

   LOCAL _home_path
   LOCAL _desk_path := ""
   LOCAL _desk_folder := "F18_dokumenti"
   LOCAL _cre

#ifdef __PLATFORM__WINDOWS

   _home_path := hb_DirSepAdd( GetEnv( "USERPROFILE" ) )
   _desk_path := _home_path + "Desktop" + SLASH
#else
   _home_path := hb_DirSepAdd( GetEnv( "HOME" ) )
   _desk_path := _home_path + "Desktop" + SLASH
   IF DirChange( _desk_path ) != 0
      _desk_path := _home_path + "Radna površ" + SLASH
   ENDIF
#endif

   s_cDesktopPath := _desk_path + _desk_folder + SLASH

   IF DirChange( '"' + s_cDesktopPath + '"' ) != 0
      _cre := MakeDir( s_cDesktopPath )
   ENDIF

   DirChange( my_home() )

   RETURN .T.



PROCEDURE f18_sql_connect( hParams )

   LOCAL oServer, pConn

   oServer := TPQServer():New( hParams[ "host" ], hParams[ "database" ], hParams[ "user" ], hParams[ "password" ] )
   pConn := oServer:pDB
   rddSetDefault( "SQLMIX" )
   // postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
   IF rddInfo( 1001, { "POSTGRESQL", pConn } ) == 0
      ? "Could not connect to the server"
      RETURN
   ENDIF

   RETURN

PROCEDURE show_postgresql_version( hParams )

   f18_sql_connect()
   dbUseArea( .T., , "SELECT version() AS ver", "INFO" )
   OutStd( field->ver )

   RETURN


PROCEDURE run_module()

   LOCAL cModul := get_f18_param( "run" )
   LOCAL oLogin
   LOCAL aRet, hRec

   harbour_init()
   init_parameters_cache()
   set_f18_current_directory()
   set_f18_home_root()
   set_global_vars_0()
   f18_error_block()

   set_screen_dimensions()

   oLogin := my_login()
   oLogin:connect_user_database()

   IF cModul == "json_konto"
      select_o_konto()
      aRet := {}
      DO WHILE !Eof()
         hRec := hb_Hash()
         hRec[ "id" ] := hb_StrToUTF8( field->id )
         hRec[ "naz" ] := hb_StrToUTF8( field->naz )
         AAdd( aRet, hRec )
         SKIP
      ENDDO
      OutErr( e"\n" )
      OutErr( e"========F18_json:======\n" )
      OutErr( hb_jsonEncode( aRet ) )
      RETURN
   ENDIF

   IF cModul == "json_roba"
      select_o_roba()
      aRet := {}
      DO WHILE !Eof()
         hRec := hb_Hash()
         hRec[ "id" ] := hb_StrToUTF8( field->id )
         hRec[ "naz" ] := hb_StrToUTF8( field->naz )
         AAdd( aRet, hRec )
         SKIP
      ENDDO
      OutErr( e"\n" )
      OutErr( e"========F18_json:======\n" )
      OutErr( hb_jsonEncode( aRet ) )
      RETURN
   ENDIF


   IF cModul == "pos"
      set_metric( "main_menu_pos", my_user(), "D" )
      MainPos( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "fin"
      set_metric( "main_menu_fin", my_user(), "D" )
      MainFin( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "kalk"
      set_metric( "main_menu_kalk", my_user(), "D" )
      MainKalk( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "fakt"
      set_metric( "main_menu_fakt", my_user(), "D" )
      MainFakt( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "epdv"
      set_metric( "main_menu_epdv", my_user(), "D" )
      MainEPdv( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "os"
      set_metric( "main_menu_os", my_user(), "D" )
      MainOs( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ELSEIF cModul == "ld"
      set_metric( "main_menu_ld", my_user(), "D" )
      MainLd( my_user(), "dummy", get_f18_param( "p3" ),  get_f18_param( "p4" ),  get_f18_param( "p5" ),  get_f18_param( "p6" ),  get_f18_param( "p7" ) )
   ENDIF

   RETURN
