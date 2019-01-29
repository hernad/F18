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

THREAD STATIC s_lAlreadyRunStartup := .F. // startup funkcija vec pokrenuta

STATIC s_psqlServer_log := .F. // logiranje na server

STATIC s_cF18HomeRoot := NIL // za sve threadove identican cHomeRootDir
STATIC s_cF18HomeBackup := NIL // svi threadovi ista backup lokacija
STATIC s_cF18CurrentDirectory := NIL
STATIC s_lEshell := .F.

THREAD STATIC s_cF18Home := NIL // svaki thread ima svoj my home ovisno o tekucoj bazi

STATIC s_cRunOnStartParam


THREAD STATIC s_nF18FileHandle := NIL

STATIC __test_mode := .F.
STATIC __no_sql_mode := .F.

STATIC s_nMaxRows := 0
STATIC s_nMaxCols := 0

STATIC s_cFontName
STATIC s_nFontSize := 20
STATIC s_nFontWidth := 10

STATIC s_nDesktopRows := NIL
STATIC s_nDesktopCols := NIL

#ifdef F18_DEBUG
STATIC __log_level := F18_DEFAULT_LOG_LEVEL_DEBUG
#else
STATIC __log_level := F18_DEFAULT_LOG_LEVEL
#endif

FUNCTION f18_error_block()

   ErrorBlock( {| objError, lShowreport, lQuit | GlobalErrorHandler( objError, lShowReport, lQuit ) } )

   RETURN .T.


FUNCTION f18_init_app_opts()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, hb_UTF8ToStr( "1. vpn konekcija                         " ) )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, hb_UTF8ToStr( "2. rekonfiguriši server  " ) )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, hb_UTF8ToStr( "3. otvaranje nove firme  " ) )
   AAdd( aOpcExe, {|| NIL } )


   f18_menu( "mn", .F., _izbor, aOpc, aOpcExe  )

   RETURN .T.



FUNCTION post_login()

   LOCAL cDatabase := my_database()

   init_parameters_cache()
   IF is_in_main_thread()
      set_screen_dimensions()
   ENDIF
   set_sql_search_path()
   server_log_enable()

   // ~/.F18/empty38/
   set_f18_home( cDatabase )
   info_bar( "init", "home baze: " + my_home() )
   hb_gtInfo( HB_GTI_WINTITLE, "[ " + my_server_params()[ "user" ] + " ][ " + cDatabase + " ]" )
   set_a_dbfs()
   set_global_vars_1()
   set_global_screen_vars( .F. )
   set_global_vars_2()
   IF !parametri_organizacije( .F. )
      MsgBeep( "post_login error - parametri organizacije !" )
      RETURN .F.
   ENDIF
   set_vars_za_specificne_slucajeve()

   IF is_in_main_thread()

      thread_dbfs( hb_threadStart( @thread_create_dbfs() ) )
      // thread_dbfs( hb_threadStart( @f18_http_server() ) )

      thread_dbfs( hb_threadStart( @thread_f18_backup(), 1 ) ) // auto backup jedne organizacije
   ENDIF

   IF !check_server_db_version()
      RETURN .F.
   ENDIF

   F18Admin():sql_cleanup()

   set_sql_search_path()
   server_log_enable()
   set_init_fiscal_params()

   IF is_in_main_thread()
      run_on_start()
   ENDIF

   IF !set_parametre_f18_aplikacije( .T. )
      RETURN .F.
   ENDIF
   get_log_level_from_params()

   IF is_in_main_thread()
      set_hot_keys()
      crtaj_naslovni_ekran()
   ENDIF

   RETURN .T.


PROCEDURE post_login_cleanup()

   LOCAL cFiles
/*
   LOCAL aFileList, cLoc, aFile, cExt


   FOR EACH cExt IN { "txt", "pdf" }
      cLoc := my_home() + "F18_rpt_*." + cExt
      aFileList := hb_vfDirectory( cLoc )
      FOR EACH aFile IN aFileList
         FErase( my_home() + aFile[ 1 ] )
      NEXT

   NEXT
*/

   FOR EACH cFiles in { "F18_rpt_*.txt", "F18_rpt_*.pdf", "r_export_*.xlsx", "out_*.odt" }
      brisi_stare_fajlove( my_home(), cFiles, 1 )
   NEXT

   brisi_stare_fajlove( my_home_root(), "wget_*.tmp", 1 )

   RETURN


FUNCTION thread_dbfs( pThreadID )

   IF pThreadID != nil
#ifdef F18_DEBUG_DEBUG
      ?E "thread_dbfs id", pThreadID
#endif
   ENDIF

   RETURN .T.



// -----------------------------------------------------------
// vraca informaciju o nivou logiranja aplikcije
// -----------------------------------------------------------
STATIC FUNCTION get_log_level_from_params()

#ifdef F18_DEBUG

   log_level( fetch_metric( "log_level", NIL, F18_DEFAULT_LOG_LEVEL_DEBUG ) )
#else
   log_level( fetch_metric( "log_level", NIL, F18_DEFAULT_LOG_LEVEL ) )
#endif

   RETURN .T.



FUNCTION set_screen_dimensions()

   LOCAL cMsg

   LOCAL nPixWidth  := hb_gtInfo( HB_GTI_DESKTOPWIDTH )
   LOCAL nPixHeight := hb_gtInfo( HB_GTI_DESKTOPHEIGHT )

   cMsg := "screen res: " + AllTrim( to_str( nPixWidth ) ) + " " + AllTrim( to_str( nPixHeight ) ) + " varijanta: "

   IF is_terminal() .OR. nPixWidth == NIL

      f18_max_rows( MaxRow() )
      f18_max_cols( MaxCol() )

      IF SetMode( f18_max_rows() + INFO_BAR_ROWS,  f18_max_cols() )
         ?E "TERM setovanje ekrana: setovan ekran po rezoluciji"
      ELSE
         ?E "TERM setovanje ekrana: ne mogu setovati ekran po trazenoj rezoluciji !"
      ENDIF

      RETURN .T.
   ENDIF

   // hb_gtInfo( HB_GTI_RESIZEMODE, HB_GTI_RESIZEMODE_ROWS )

   IF is_mac()
      font_name( "Courier" )
      font_weight_bold()
   ELSEIF is_windows()
      font_name( "Lucida Console" )
      // font_name( "Hack" )
      // font_name( "Consolas" )
      // font_weight_bold() ruzno
   ELSE
      font_name( "terminus" )
      font_weight_bold()
   ENDIF

   DO CASE

   CASE nPixWidth >= 3000 .AND. nPixHeight >= 1800

       IF is_linux()
         font_name("Liberation Mono")
         font_weight_bold()
         font_size(40)
         font_width(24)
         // linux zavrsi 45x24, 37 rows x 132 cols
         ?E cMsg + "HiDPI"
       ENDIF

   CASE nPixWidth >= 1440 .AND. nPixHeight >= 900

      IF is_mac()
         font_size( 24 )
         font_width( 12 )
         // f18_max_rows( 35 )
         // f18_max_cols( 119 )
      ELSE
         font_size( 24 )
         font_width( 12 )
         // f18_max_rows( 35 )
         // f18_max_cols( 119 )
      ENDIF
      ?E cMsg + "1"

   CASE nPixWidth >= 1280 .AND. nPixHeight >= 820

      IF is_mac()
         font_size( 20 )
         font_width( 12 )
         // f18_max_rows( 33 )
         // f18_max_cols( 110 )
         ?E cMsg + "2longMac"
      ELSE

         font_size( 24 )
         font_width( 12 )
         // f18_max_rows( 33 )
         // f18_max_cols( 105 )
         ?E cMsg + "2long"
      ENDIF

   CASE nPixWidth >= 1280 .AND. nPixHeight >= 800

      font_size( 24 )
      font_width( 12 )
      // f18_max_rows( 35 )
      // f18_max_cols( 115 )
      ?E cMsg + "2"

   CASE  nPixWidth >= 1024 .AND. nPixHeight >= 768

      font_size( 22 )
      font_width( 11 )
      // f18_max_rows( 35 )
      // f18_max_cols( 100 )

      ?E cMsg + "3"

   OTHERWISE

      font_size( 22 )
      font_width( 11 )
      // f18_max_rows( 35 )
      // f18_max_cols( 100 )

      ?E "init",  cMsg + "4"

   ENDCASE


   get_screen_resolution_from_config()

   // font_weight_bold()
   // ?E " set font_name: ", hb_gtInfo( HB_GTI_FONTNAME, font_name() )

   // #if  defined( __PLATFORM__WINDOWS ) .OR. defined( __PLATFORM__LINUX )
   // ?E " set font_width: ", hb_gtInfo( HB_GTI_FONTWIDTH, font_width() )
   // #endif
   // ?E " set font_size: ", hb_gtInfo( HB_GTI_FONTSIZE, font_size() )


   // Alert( hb_ValToStr( hb_gtInfo( HB_GTI_DESKTOPROWS ) ) + " / " + hb_ValToStr( hb_gtInfo( HB_GTI_DESKTOPCOLS ) ) )
   // hb_gtInfo( HB_GTI_ISFULLSCREEN, .T. )

   IF is_windows() // windowsi traze ovo ponavljanje setovanja da bi se settings "primili"
      font_size( 0 )
      font_width( 0 )
   ENDIF

   ?E " get0 font_name: ", hb_gtInfo( HB_GTI_FONTNAME )
   ?E " get0 font_size: ", hb_gtInfo( HB_GTI_FONTSIZE )
   ?E " get0 font_width: ", hb_gtInfo( HB_GTI_FONTWIDTH )
   ?E " get0 font_weight: ", hb_gtInfo( HB_GTI_FONTWEIGHT )


   IF SetMode( f18_max_rows( desktop_rows() - 1 ) + INFO_BAR_ROWS,  ;
         f18_max_cols( desktop_cols() - 3 ) )
      ?E "GUI1 setovanje ekrana: setovan ekran po rezoluciji", f18_max_rows(), f18_max_cols()
   ELSE
      // linux nece od prve!?
      SetMode( f18_max_rows( desktop_rows() - 1 ) + INFO_BAR_ROWS,  ;
         f18_max_cols( desktop_cols() - 3 ) )
      ?E "GUI2 set font_width: ", hb_gtInfo( HB_GTI_FONTWIDTH, font_width() )
   ENDIF

   ?E " get font_name: ", hb_gtInfo( HB_GTI_FONTNAME )
   ?E " get font_size: ", hb_gtInfo( HB_GTI_FONTSIZE )
   ?E " get font_width: ", hb_gtInfo( HB_GTI_FONTWIDTH )
   ?E " get font_weight: ", hb_gtInfo( HB_GTI_FONTWEIGHT )

   // hb_gtInfo( HB_GTI_ALTENTER, .T. )

   RETURN .T.


STATIC FUNCTION get_screen_resolution_from_config()

   LOCAL cParamName

   LOCAL hIniParams := hb_Hash()

   hIniParams[ "max_rows" ] := nil
   hIniParams[ "max_cols" ] := nil
   hIniParams[ "font_name" ] := nil
   hIniParams[ "font_width" ] := nil
   hIniParams[ "font_size" ] := nil

   IF !f18_ini_config_read( F18_SCREEN_INI_SECTION, @hIniParams, .T. )
      ?E "screen resolution: problem sa ini read"
      RETURN .F.
   ENDIF

   // setuj varijable iz inija
   IF hIniParams[ "max_rows" ] != nil
      s_nMaxRows := Val( hIniParams[ "max_rows" ] )
   ENDIF

   IF hIniParams[ "max_cols" ] != nil
      s_nMaxCols := Val( hIniParams[ "max_cols" ] )
   ENDIF

   IF hIniParams[ "font_name" ] != nil
      font_name( hIniParams[ "font_name" ] )
   ENDIF

   cParamName := "font_width"
   IF hIniParams[ cParamName ] != nil
      font_width( Val( hIniParams[ cParamName ] ) )
   ENDIF

   cParamName := "font_size"
   IF hIniParams[ cParamName ] != nil
      font_size( Val( hIniParams[ cParamName ] ) )
   ENDIF

   RETURN .T.

/*

MaxRow() - daje max rows - 1, MaxCol() - max cols - 1
Ako je MaxRow() = 35, MaxCols() = 132,
tada treba setovati ekran sa: SetMode( 35 + 1, 132 + 1)


f18_max_rows() daje broj redova za ispis dostupan aplikaciji.

Zadnja dva reda su rezervisana za info bar i error bar:

Kada je f18_max_rows() = 34, tada je MaxRow() = 34 + 2 - 1 = 35
Kada je f18_max_cols() = 133, tada je MaxCol() = 133 - 1 = 132

*/

FUNCTION f18_max_rows( nX )

   // LOCAL nGTH := hb_gtInfo( HB_GTI_VIEWMAXHEIGHT )

   IF ValType( nX ) == "N"
      s_nMaxRows := nX - INFO_BAR_ROWS + 1
   ENDIF

   // RETURN  Max( nGTH - INFO_BAR_ROWS + 1, s_nMaxRows )

   RETURN s_nMaxRows



FUNCTION f18_max_cols( nY )

   // LOCAL nGTW := hb_gtInfo( HB_GTI_VIEWMAXWIDTH )

   IF ValType( nY ) == "N"
      s_nMaxCols := nY + 1
   ENDIF

   // RETURN Max( nGTW + 1, s_nMaxCols )

   RETURN s_nMaxCols



FUNCTION font_name( cFontName )

   ?E " s_font_name:", s_cFontName
   IF ValType( cFontName ) == "C"
      s_cFontName := cFontName
      s_cFontName := hb_gtInfo( HB_GTI_FONTNAME, s_cFontName )
      ?E " get font_name: ", s_cFontName
   ENDIF

   RETURN s_cFontName



/*
   font_size( 24 ) -> prvi pokusaj
   font_size( 0 ) ->  ponovi zadnji pokusaj
*/

FUNCTION font_size( nSize )

   LOCAL nDodaj := 0

   IF is_windows()
      nDodaj := 2 // iz nekog razloga ovo ne pije vode ako ne dodam
   ENDIF
   ?E " s_font_size:", s_nFontSize
   IF ValType( nSize ) == "N"
      IF nSize > 0
         s_nFontSize := hb_gtInfo( HB_GTI_FONTSIZE, nSize + nDodaj )
         s_nFontSize := nSize
      ELSE
         s_nFontSize := hb_gtInfo( HB_GTI_FONTSIZE, s_nFontSize + nDodaj )
      ENDIF
      ?E " get font_size: ", s_nFontSize
   ENDIF

   RETURN s_nFontSize


FUNCTION font_width( nWidth )

   ?E " s_font_width:", s_nFontWidth
   IF ValType( nWidth ) == "N"
      IF nWidth > 0
         s_nFontWidth := hb_gtInfo( HB_GTI_FONTWIDTH, nWidth )
         s_nFontWidth := nWidth
      ELSE
         s_nFontWidth := hb_gtInfo( HB_GTI_FONTWIDTH, s_nFontWidth )
      ENDIF
      ?E " get font_width: ", s_nFontWidth
   ENDIF

   RETURN s_nFontWidth




FUNCTION font_weight_bold()

   IF is_terminal()
      RETURN .F.
   ENDIF

   ?E " set font_weight: ", hb_gtInfo( HB_GTI_FONTWEIGHT, HB_GTI_FONTW_BOLD )

   RETURN .T.

FUNCTION desktop_rows()

   IF s_nDesktopRows == NIL
      s_nDesktopRows := hb_gtInfo( HB_GTI_DESKTOPROWS )

      IF is_linux() // linux moram spustiti da bi info_bar i error_bar bile vidljive
         s_nDesktopRows -= 3
      ENDIF
   ENDIF

   RETURN s_nDesktopRows



FUNCTION desktop_cols()

   IF s_nDesktopCols == NIL
      s_nDesktopCols := hb_gtInfo( HB_GTI_DESKTOPCOLS )
   ENDIF

   RETURN s_nDesktopCols


FUNCTION log_level( x )

   IF ValType( x ) == "N"
      __log_level := x
   ENDIF

   RETURN __log_level



FUNCTION my_home( cHome )

   IF cHome != NIL
      s_cF18Home := cHome
   ENDIF

   RETURN s_cF18Home



FUNCTION file_path_quote( cPath )

   IF ( At( " ", cPath ) != 0 ) .AND. ( At( '"', cPath ) == 0 )
      RETURN  '"' + cPath + '"'
   ENDIF

   RETURN cPath



FUNCTION my_home_root( cHomeRootDir )

   IF cHomeRootDir != NIL
      s_cF18HomeRoot := cHomeRootDir
   ENDIF

   IF HB_ISNIL( s_cF18HomeRoot )
      set_f18_home_root()
   ENDIF

   RETURN s_cF18HomeRoot


FUNCTION set_f18_current_directory()

   s_cF18CurrentDirectory := iif( is_windows(), hb_CurDrive() + ":" + SLASH, "/" ) + CurDir()

   ?E "current directory:", s_cF18CurrentDirectory

   RETURN s_cF18CurrentDirectory


FUNCTION f18_current_directory()

   RETURN s_cF18CurrentDirectory


FUNCTION set_f18_home_root()

   LOCAL cHome, cF18eShell

/*
#ifdef __PLATFORM__WINDOWS
   cHome := hb_DirSepAdd( GetEnv( "USERPROFILE" ) )
#else
   cHome := hb_DirSepAdd( GetEnv( "HOME" ) )
#endif

   cHome := hb_DirSepAdd( cHome + ".f18" )
*/
   cHome:=GetEnv('F18_HOME')

   IF Empty(cHome)
     Alert('F18_HOME envar - lokacija podataka nije definisana!?')
     QUIT_1
   ENDIF

   cF18eShell := GetEnv('F18_ESHELL')
   IF cF18eShell == "1"
      s_lEshell := .T.
   ENDIF

   cHome := hb_DirSepAdd(cHome)

   f18_create_dir( cHome )
   my_home_root( cHome )

   RETURN .T.


FUNCTION is_in_eshell()

    RETURN s_lEshell


FUNCTION my_home_backup( cF18HomeBackup )

   IF cF18HomeBackup != NIL
      s_cF18HomeBackup := cF18HomeBackup
   ENDIF

   RETURN s_cF18HomeBackup




FUNCTION set_f18_home_backup( cDatabase )

   LOCAL cHomeDir := hb_DirSepAdd( my_home_root() + "backup" )

   f18_create_dir( cHomeDir )

   IF cDatabase <> NIL
      cHomeDir := hb_DirSepAdd( cHomeDir + cDatabase )
      f18_create_dir( cHomeDir )
   ENDIF

   my_home_backup( cHomeDir )

   RETURN .T.




// ---------------------------
// ~/.F18/bringout1
// ~/.F18/rg1
// ~/.F18/test
// ---------------------------
FUNCTION set_f18_home( cDatabase )

   LOCAL cHomeDir

   IF cDatabase <> NIL
      cHomeDir := hb_DirSepAdd( my_home_root() + cDatabase )
      f18_create_dir( cHomeDir )
   ENDIF

   my_home( cHomeDir )

   RETURN .T.



FUNCTION dummy_error_handler()
   RETURN {| err | Break( err ) }


FUNCTION test_mode( tm )

   IF tm != nil
      __test_mode := tm
   ENDIF

   RETURN __test_mode


FUNCTION no_sql_mode( val )

   IF val != nil
      __no_sql_mode := val
   ENDIF

   RETURN __no_sql_mode





FUNCTION log_write( cMsg, nLevel, lSilent )

   LOCAL _msg_time

   IF nLevel == NIL
      // uzmi defaultni
      nLevel := log_level()
   ENDIF

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   // treba li logirati ?
   IF nLevel > log_level()
      RETURN .T.
   ENDIF

   _msg_time := DToC( Date() )
   _msg_time += ", "
   _msg_time += PadR( Time(), 8 )
   _msg_time += ": "

   // time ide samo u fajl, ne na server
   // ovdje ima neki problem #30139 iskljucujem dok ne skontamo
   // baca mi ove poruke u outf.txt
   // FWRITE( s_nF18FileHandle, _msg_time + cMsg + hb_eol() )

   IF server_log()
      server_log_write( cMsg, lSilent )
   ENDIF

   ?E _msg_time, cMsg

   RETURN .T.


FUNCTION server_log()
   RETURN s_psqlServer_log


FUNCTION server_log_disable()

   s_psqlServer_log := .F.

   RETURN .T.

FUNCTION server_log_enable()

   s_psqlServer_log := .T.

   RETURN .T.



FUNCTION log_create()

   IF ( s_nF18FileHandle := FCreate( F18_LOG_FILE ) ) == -1
      error_bar( "log", "Cannot create log file: " + F18_LOG_FILE )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION log_close()

   FClose( s_nF18FileHandle )

   RETURN .T.



FUNCTION log_handle( handle )

   IF handle != NIL
      s_nF18FileHandle := handle
   ENDIF

   RETURN s_nF18FileHandle



FUNCTION set_hot_keys()

   info_bar( "init", "setting up hot keys" )
   SetKey( K_SH_F1, {|| f18_kalkulator() } )
   SetKey( K_SH_F6, {|| f18_promjena_sezone() } )
   SetKey( K_F1, {|| k_f1() } )

   hb_SetKey( hb_keyNew( "C", HB_KF_CTRL ), {|| set_clipboard() } )
   hb_SetKey( hb_keyNew( "V", HB_KF_CTRL ), {|| get_clipboard() } )

   //nKey := inkey(0, hb_bitOr( HB_INKEY_ALL, HB_INKEY_EXT ))
   //MsgBeep( AllTrim( Str( nKey ) ) )
   //hb_keyNew( "C", HB_KF_CTRL )

   info_bar( "init", "setting up hot keys - end" )

   RETURN .T.



FUNCTION run_on_start_param( cParam )

   IF cParam != NIL
      s_cRunOnStartParam := cParam
   ENDIF

   RETURN s_cRunOnStartParam


FUNCTION run_on_start()

   LOCAL _ini, _fakt_doks, cRun, oModul
   LOCAL cModul

   IF s_lAlreadyRunStartup
      RETURN .F.
   ENDIF

   s_lAlreadyRunStartup := .T.

   // _ini := hb_Hash()
   // _ini[ "run" ] := ""
   // _ini[ "modul" ] := "FIN"

   IF run_on_start_param() == NIL
      RETURN .F.
   ENDIF
   // f18_ini_config_read( "startup" + iif( test_mode(), "_test", "" ), @_ini, .F. )

   // cRun := _ini[ "run" ]
   cRun := run_on_start_param()

   IF Empty( cRun )
      RETURN .F.
   ENDIF


   info_bar( "init", "run_on_start" )

   IF Left( cRun, 5 ) == "kalk_"
      cModul := "KALK"
   ELSEIF Left( cRun, 5 ) == "fakt_"
      cModul := "FAKT"
   ELSEIF Left( cRun, 4 ) == "fin_"
      cModul := "FIN"
   ELSEIF Left( cRun, 3 ) == "pos"
      cModul := "TOPS"
   ELSE
      cModul := "KALK"
   ENDIF



   SWITCH cModul
   CASE "FIN"
      oModul := TFinMod():new( NIL, "FIN", f18_ver(), f18_ver_date(), my_user(), "dummy" )
      EXIT
   CASE "KALK"
      oModul := TKalkMod():new( NIL, "KALK", f18_ver(), f18_ver_date(), my_user(), "dummy" )
      EXIT
   CASE "FAKT"
      oModul := TFaktMod():new( NIL, "FAKT", f18_ver(), f18_ver_date(), my_user(), "dummy" )
      EXIT
   CASE "TOPS"
      oModul := TFaktMod():new( NIL, "TOPS", f18_ver(), f18_ver_date(), my_user(), "dummy" )
      EXIT

   ENDSWITCH

   goModul := oModul
   gModul := oModul:cName

   SWITCH ( cRun )


   CASE "pos_run"
       goModul:run()

   CASE "fakt_pretvori_otpremnice_u_racun"
      _fakt_doks := FaktDokumenti():New()
      _fakt_doks:pretvori_otpremnice_u_racun()

   OTHERWISE
      IF !Empty( cRun )
         &cRun
      ENDIF
   END

   info_bar( "init", "run_on_start_end" )

   RETURN .T.
