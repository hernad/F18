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


CLASS F18Admin

   VAR update_app_f18
   VAR cUpdateF18Version
   VAR update_app_templates
   VAR update_app_templates_version
   VAR update_app_info_file
   VAR update_app_script_file

   METHOD new()

   METHOD create_new_pg_db()
   METHOD drop_pg_db()
   METHOD delete_db_data_all()

   METHOD razdvajanje_sezona()

   METHOD relogin_as()
   METHOD relogin_as_admin()
   METHOD update_app()
   METHOD get_os_name()
   METHOD wget_download()
   // METHOD sql_cleanup()
   // METHOD sql_cleanup_all()

   DATA create_db_result

   PROTECTED:

   // METHOD update_db_download()
   // METHOD update_db_all()
   // METHOD update_db_company()
   // METHOD update_db_command()
   METHOD create_new_pg_db_params()

   METHOD update_app_form()
   METHOD f18_upd_download()
   // METHOD update_app_get_versions()
   METHOD update_app_run_script()
   METHOD update_app_run_app_update()
   // METHOD update_app_run_templates_update()
   METHOD update_app_unzip_templates()

   // DATA _new_db_params
   // DATA _update_params

ENDCLASS


METHOD F18Admin:New()

   ::create_db_result := {}

   IF ! ::relogin_as_admin( "postgres" )
      MsgBeep( "relogin postgresql as admin neuspjesno " )
      RETURN NIL
   ENDIF

   RETURN self

/*
-- METHOD F18Admin:sql_cleanup()

   LOCAL cQuery, oQuery, hDbServerParams, dCleanup, aQueries, cItem

   hDbServerParams := my_server_params()

   dCleanup := fetch_metric( "db_cleanup", NIL, CToD( "" ) )

#ifndef F18_DEBUG
   IF dCleanup >= Date()
      info_bar( "admin", "db_cleanup vec napravljen " + DToC( dCleanup ) )
      RETURN .F.
   ELSE
      info_bar( "admin", "db_cleanup START" )
   ENDIF
#endif

   IF ! ::relogin_as_admin( hDbServerParams[ "database" ] )
      // MsgBeep( "relogin as admin user neuspješno " )
      RETURN .F.
   ENDIF

   cQuery := "" // select max(version) from public.schema_migrations;"

   IF Left( hDbServerParams[ "database" ], 3 ) != "rg_" // ne dirati ramaglas radi RNAL koristenja semafora
      cQuery += "DROP SCHEMA IF EXISTS sem CASCADE;"

      FOR EACH cItem IN { "banke", "dest", "dopr", "epdv_kif", "epdv_kuf", "epdv_pdv", "epdv_sg_kif", "epdv_sg_kuf", ;
         "f18_rules", "fakt_doks", "fakt_doks2", "fakt_fakt", "fakt_ftxt", "fakt_gen_ug", "fakt_gen_ug_p", "fakt_rugov", ;
         "fakt_ugov", "fakt_upl", "fin_anal", "fin_sint", "fin_suban", "fin_nalog", "kalk_doks", "kalk_kalk", ;
         "kbenef", "koncij", "konto", "kred", "ld_ld", "ld_norsiht", "ld_obracuni", "ld_parobr", "ld_pk_data", "ld_pk_radn",;
         "ld_radkr", "ld_radn", "ld_radsat", "ld_radsiht", "ld_rj", "ld_tprsiht", "lokal", "ops", "os_amort", "os_k1",;
         "os_os", "os_promj", "os_reval", "partn", "por", "refer", "rj", "roba", "sast", "sifk", "sifv", ;
         "strspr", "tarifa", "tdok", "tippr", "tippr2", "tnal", "trfp", "trfp2", "trfp3", "valute", "vposla", "vprih" ;
         }
         cQuery += "DROP SEQUENCE IF EXISTS fmk.sem_ver_" + cItem + ";"
      NEXT

   ENDIF

   IF !Empty ( cQuery )
      oQuery := run_sql_query( cQuery )
      IF sql_error_in_query( oQuery, "DROP", sql_postgres_conn() )
         error_bar( "drop_db", "drop schema sem" )
         RETURN .F.
      ENDIF
   ENDIF

   aQueries := { ;
      "ALTER TABLE fmk.pos_doks  DROP COLUMN IF EXISTS funk;", ;
      "ALTER TABLE fmk.pos_doks  DROP COLUMN IF EXISTS fisc_st;"  ;
      }
   FOR EACH cQuery IN aQueries
      oQuery := run_sql_query( cQuery )
      IF sql_error_in_query( oQuery, "DROP", sql_postgres_conn() )
         error_bar( "alter_table", cQuery )
         RETURN .F.
      ENDIF
   NEXT

   info_bar( "admin", "db_cleanup END" )
   ::relogin_as( hDbServerParams[ "user" ],  hDbServerParams[ "password" ], hDbServerParams[ "database" ] )
   set_metric( "db_cleanup", NIL, Date() )

   RETURN self
*/

/*
-- METHOD F18Admin:sql_cleanup_all()

   LOCAL cQuery, oQuery, cQueryForDb // ovaj query radi posao na pojedinoj bazi

   stop_refresh_operations()

   IF Pitanje(, "Konekcije svih korisnika na bazu biti prekinute! Nastaviti?", " " ) == "N"
      // start_refresh_operations()
      RETURN .F.
   ENDIF

   IF ! ::relogin_as_admin()
      // MsgBeep( "relogin as admin user neuspješno " )
      RETURN .F.
   ENDIF

   pg_terminate_all_data_db_connections()

   info_bar( "admin", "db_cleanup_all START" )

   cQueryForDb := "DROP SCHEMA IF EXISTS sem CASCADE;"
   cQueryForDb += "DROP SCHEMA IF EXISTS fmk_reports CASCADE;"
   cQueryForDb += "DROP SCHEMA IF EXISTS api CASCADE;"
   cQueryForDb += "DROP table IF EXISTS fmk.brojac;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_0;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_1;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_cin;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_defrjes;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_globusl;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_k1;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_k2;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_mz;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_nac;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_nerdan;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_obrazdef;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_promj;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_rj;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_rjes;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_rmj;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_rjrmj;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_rrasp;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_uslovi;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_ves;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_zanim;"
   cQueryForDb += "DROP table IF EXISTS fmk.kadev_doks;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_aops;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_aops_att;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_articles;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_contacts;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_customs;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_doc_it;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_doc_it2;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_doc_lit;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_doc_log;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_doc_ops;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_ops;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_docs;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_e_aops;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_e_att;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_e_gr_val;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_e_gr_att;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_e_groups;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_elements;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_objects;"
   cQueryForDb += "DROP table IF EXISTS fmk.rnal_ral;"
   cQueryForDb += "DROP table IF EXISTS public.locale;"

   cQuery := ""
   cQuery += "CREATE EXTENSION IF NOT EXISTS dblink;" + hb_eol()
   cQuery += "CREATE OR REPLACE FUNCTION F18_cleanup_databases()" + hb_eol()
   cQuery += " RETURNS VOID AS  " + hb_eol()
   cQuery += " $$" + hb_eol()
   cQuery += " DECLARE" + hb_eol()
   cQuery += "     v_db NAME; " + hb_eol()
   cQuery += "     cQuery VARCHAR;" + hb_eol()
   cQuery += " BEGIN" + hb_eol()
   cQuery += "     FOR v_db IN" + hb_eol()
   cQuery += "         SELECT datname FROM pg_catalog.pg_database WHERE datname NOT LIKE 'postgres' AND datname NOT LIKE 'rg_%' AND datname NOT LIKE 'ramaglas_%' AND datname NOT LIKE 'template_%' AND datname NOT LIKE 'rmu_%'" + hb_eol()
   cQuery += "     LOOP" + hb_eol()
   cQuery += "         raise notice 'Database: %', v_db;" + hb_eol()

   cQuery += "         cQuery := $Q$SELECT dblink_connect('dbname=$Q$ || v_db || $Q$');$Q$;" + hb_eol()
   cQuery += "         cQuery := cQuery || $Q$SELECT dblink_exec('" + cQueryForDb + "');$Q$;" + hb_eol()
   cQuery += "         cQuery := cQuery || $Q$SELECT dblink_disconnect();$Q$;" + hb_eol()
   cQuery += "         EXECUTE cQuery;" + hb_eol()
   cQuery += "     END LOOP;" + hb_eol()
   cQuery += " END;" + hb_eol()
   cQuery += " $$" + hb_eol()
   cQuery += " LANGUAGE 'plpgsql';" + hb_eol()


   // editor( NIL, cQuery )
   oQuery := postgres_sql_query( cQuery )

   cQuery := "select F18_cleanup_databases();" + hb_eol()
   oQuery := postgres_sql_query( cQuery )
   IF sql_error_in_query( oQuery, "SELECT", sql_postgres_conn() )
      error_bar( "admin", "sql_cleanup_all" )
      RETURN .F.
   ENDIF

   info_bar( "admin", "db_cleanup_all END" )

   // ::relogin_as( hDbServerParams[ "user" ],  hDbServerParams[ "password" ], hDbServerParams[ "database" ] )
   // start_refresh_operations()
   set_sql_search_path()

   RETURN .T.
*/

METHOD F18Admin:update_app()

   LOCAL hF18UpdateParams := hb_Hash()

   // LOCAL _hF18UpdateParams := hb_Hash()
   LOCAL cUpdateFile := ""
   LOCAL lOk := .F.

   // ::update_app_info_file := "UPDATE_INFO"
   ::update_app_script_file := "f18_upd.sh"

#ifdef __PLATFORM__WINDOWS
   ::update_app_script_file := "f18_upd.bat"
#endif

   IF !::f18_upd_download()
      MsgBeep( "Problem sa download-om skripti. Provjerite internet koneciju." )
      RETURN SELF
   ENDIF

   // hF18UpdateParams := ::update_app_get_versions()

   hF18UpdateParams[ "f18" ] := f18_available_version()
   hF18UpdateParams[ "url" ] := F18_DOWNLOAD_URL_BASE

   IF hF18UpdateParams == NIL
      RETURN SELF
   ENDIF

   IF !::update_app_form( hF18UpdateParams )
      RETURN SELF
   ENDIF

/*
   IF ::update_app_templates
      ::update_app_run_templates_update( hF18UpdateParams )
   ENDIF
*/

   IF ::update_app_f18
      ::update_app_run_app_update( hF18UpdateParams )
   ENDIF

   // s_cDownloadVersion := NIL

   RETURN SELF



METHOD F18Admin:update_app_unzip_templates( destination_path, location_path, cFileName )

   LOCAL cCmd
   LOCAL _args := "-jxf"

   MsgO( "Vršim update template fajlova ..." )

#ifdef __PLATFORM__WINDOWS

   DirChange( destination_path )

   cCmd := "bunzip2 -f " + location_path + cFileName
   hb_run( cCmd )

   cCmd := "tar xvf " + StrTran( cFileName, ".bz2", "" )
   hb_run( cCmd )

#else

   cCmd := "tar -C " + location_path + " " + _args + " " + location_path + cFileName
   hb_run( cCmd )

#endif

   MsgC()

   RETURN SELF



METHOD F18Admin:update_app_run_app_update( hF18Params )

   LOCAL cUpdateFile := "F18_#OS#_#VER#.gz"

   IF ::cUpdateF18Version == "#LAST#"
      ::cUpdateF18Version := hF18Params[ "f18" ]
   ENDIF

#ifdef __PLATFORM__LINUX
   cUpdateFile := StrTran( cUpdateFile, "#OS#", ::get_os_name() + "_i686" )
#else
   cUpdateFile := StrTran( cUpdateFile, "#OS#", ::get_os_name() )
#endif

   cUpdateFile := StrTran( cUpdateFile, "#VER#", ::cUpdateF18Version )

// IF ::cUpdateF18Version == f18_ver()
// MsgBeep( "Verzija aplikacije " + f18_ver() + " je vec instalirana !" )
// RETURN SELF
// ENDIF

   IF !::wget_download( hF18Params[ "url" ], cUpdateFile, my_home_root() + cUpdateFile, .T., .T. )
      RETURN SELF
   ENDIF

   ::update_app_run_script( my_home_root() + cUpdateFile )

   RETURN SELF



METHOD F18Admin:update_app_run_script( cUpdate )

   LOCAL cUrl := my_home_root() + ::update_app_script_file

#ifdef __PLATFORM__WINDOWS

   cUrl := 'start cmd /C ""' + cUrl
   cUrl += '" "' + cUpdate + '""'
#else
#ifdef __PLATFORM__LINUX
   cUrl := "bash " + cUrl
#endif
   cUrl += " " + cUpdate
#endif

#ifdef __PLATFORM__UNIX
   cUrl := cUrl + " &"
#endif

   Msg( "F18 ce se sada zatvoriti#Nakon update procesa ponovo otvorite F18", 4 )

   hb_run( cUrl )

   QUIT_1

   RETURN SELF



METHOD F18Admin:update_app_form( hF18UpdateParams )

   LOCAL lOk := .F.
   LOCAL nVerzijaMajor := 2
   LOCAL nVerzijaMinor := 3
   LOCAL nVerzijaPatch := Space( 10 )
   LOCAL _t_ver_prim := 1
   LOCAL _t_ver_sec := 5
   LOCAL _t_ver_third := Space( 10 )
   LOCAL nX := 1
   LOCAL cColorApp, cColorTemplate, cLine
   LOCAL cUpdateF18, cUpdateTemplate, nPos
   LOCAL pRegex := hb_regexComp( "(\d+).(\d+).(\d+)" )
   LOCAL aMatch
   LOCAL GetList := {}

   cUpdateF18 := "D"
   // cUpdateTemplate := "N"
   cColorApp := "W/G+"
   cColorTemplate := "W/G+"

   aMatch := hb_regex( pRegex, hF18UpdateParams[ "f18" ] )

   IF Len( aMatch ) > 0 // aMatch[1]="2.3.500" aMatch[2]="2", aMatch[3]="3", aMatch[4]="500"
      nVerzijaMajor := Val( aMatch[ 2 ] )
      nVerzijaMinor := Val( aMatch[ 3 ] )
      nVerzijaPatch := Val( aMatch[ 4 ] )
   ENDIF

   // IF f18_ver() < hF18UpdateParams[ "f18" ]
   cColorApp := "W/R+"
   // ENDIF
   // IF f18_template_ver() < hF18UpdateParams[ "templates" ]
   // cColorTemplate := "W/R+"
   // ENDIF

   Box(, 10, 65 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "## UPGRADE F18 klijenta ##", 64 ) COLOR f18_color_i()
   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY cLine := ( Replicate( "-", 10 ) + " " + Replicate( "-", 20 ) + " " + Replicate( "-", 20 ) )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "[INFO]", 10 ) + "/" + PadC( "Trenutna", 20 ) + "/" + PadC( "Dostupna", 20 )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY cLine
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "F18", 10 ) + " " + PadC( f18_ver(), 20 )
   @ box_x_koord() + nX, Col() SAY " "
   @ box_x_koord() + nX, Col() SAY PadC( hF18UpdateParams[ "f18" ], 20 ) COLOR cColorApp

/*
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadR( "template", 10 ) + " " + PadC( f18_template_ver(), 20 )
   @ box_x_koord() + nX, Col() SAY " "
   @ box_x_koord() + nX, Col() SAY PadC( hF18UpdateParams[ "templates" ], 20 ) COLOR cColorTemplate
*/

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY cLine

   nX += 2
   nPos := nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "       Update F18 ?" GET cUpdateF18 PICT "@!" VALID cUpdateF18 $ "DN"

   READ

   IF cUpdateF18 == "D"
      @ box_x_koord() + nX, box_y_koord() + 25 SAY "VERZIJA:" GET nVerzijaMajor PICT "999" VALID nVerzijaMajor > 0
      @ box_x_koord() + nX, Col() + 1 SAY "." GET nVerzijaMinor PICT "999" VALID nVerzijaMinor >= 0
      @ box_x_koord() + nX, Col() + 1 SAY "." GET nVerzijaPatch PICT "9999"
   ENDIF

/*
   ++nX
   ++nX
   nPos := nX

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "  Update template ?" GET cUpdateTemplate PICT "@!" VALID cUpdateTemplate $ "DN"
*/

   READ

/*
   IF cUpdateTemplate == "D"
      @ box_x_koord() + nX, box_y_koord() + 25 SAY "VERZIJA:" GET _t_ver_prim PICT "99" VALID _t_ver_prim > 0
      @ box_x_koord() + nX, Col() + 1 SAY "." GET _t_ver_sec PICT "99" VALID _t_ver_sec > 0
      @ box_x_koord() + nX, Col() + 1 SAY "." GET _t_ver_third PICT "@S10"
      READ

   ENDIF
*/

   BoxC()

   IF LastKey() == K_ESC
      RETURN lOk
   ENDIF

   ::update_app_f18 := ( cUpdateF18 == "D" ) // setuj postavke
   // ::update_app_templates := ( cUpdateTemplate == "D" )

   IF ::update_app_f18
      IF !Empty( nVerzijaPatch )
         // zadana verzija
         ::cUpdateF18Version := AllTrim( Str( nVerzijaMajor ) ) + ;
            "." + ;
            AllTrim( Str( nVerzijaMinor ) ) + ;
            "." + ;
            AllTrim( Str( nVerzijaPatch ) )
      ELSE
         ::cUpdateF18Version := "#LAST#"
      ENDIF

      lOk := .T.

   ENDIF

/*
   IF ::update_app_templates  // sastavi mi verziju
      IF !Empty( _t_ver_third ) // zadana verzija
         ::update_app_templates_version := AllTrim( Str( _t_ver_prim ) ) + "." +  AllTrim( Str( _t_ver_sec ) ) + "." +  AllTrim( _t_ver_third )
      ELSE
         ::update_app_templates_version := "#LAST#"
      ENDIF
      lOk := .T.
   ENDIF
*/

   RETURN lOk




METHOD F18Admin:f18_upd_download()

   LOCAL lOk := .F.
   LOCAL cPath := my_home_root()
   LOCAL cUrl
   LOCAL _script
   LOCAL hF18UpdateParams
   LOCAL _silent := .T.
   LOCAL _always_erase := .T.

/*
   info_bar( "upd", "download " +  ::update_app_info_file )

   MsgO( "preuzimanje podataka o aktuelnoj verziji ..." )
   cUrl := f18_download_url() + "/"
   IF !::wget_download( cUrl, ::update_app_info_file, cPath + ::update_app_info_file, _always_erase, _silent )
      MsgC()
      RETURN .F.
   ENDIF
*/

   info_bar( "upd", "download " +  ::update_app_script_file )
   cUrl := f18_download_url() + "/scripts/"
   IF !::wget_download( cUrl, ::update_app_script_file, cPath + ::update_app_script_file, _always_erase, _silent )
      MsgC()
      RETURN .F.
   ENDIF
   MsgC()

   RETURN .T.



METHOD F18Admin:get_os_name()

   LOCAL _os := "Ubuntu"

#ifdef __PLATFORM__WINDOWS

   _os := "Windows"
#endif

#ifdef __PLATFORM__DARWIN
   _os := "MacOSX"
#endif

   RETURN _os




METHOD F18Admin:wget_download( cUrl, cFileName, cLocalFileName, lEraseFile, silent, only_newer )

   LOCAL lOk := .F.
   LOCAL cCmd
   LOCAL nFileHandle, nLength

   // IF lEraseFile == NIL
   // lEraseFile := .F.
   // ENDIF

   // IF silent == NIL
   // silent := .F.
   // ENDIF

   // IF only_newer == NIL
   // only_newer := .F.
   // ENDIF

   // IF lEraseFile
   // FErase( cLocalFileName )
   // Sleep( 1 )
   // ENDIF

   cCmd := "wget "

// #ifdef __PLATFORM__WINDOWS
   cCmd += " -q  --tries=4 --timeout=4  --no-cache --no-check-certificate "
// #endif

   cCmd += cUrl + cFileName // http://test.com/FILE

   cCmd += " -O "

   IF f18_run( cCmd + " " + file_path_quote( cLocalFileName ) ) != 0
      MsgBeep( "Error: " + cCmd  + "?!" )
      RETURN .F.
   ENDIF
   // Sleep( 1 )

   IF !File( cLocalFileName )
      error_bar( "upd", "Fajl " + cLocalFileName + " nije download-ovan !" )
      RETURN .F.
   ENDIF

   nFileHandle := FOpen( cLocalFileName ) // provjeri velicinu fajla

   IF nFileHandle >= 0
      nLength := FSeek( nFileHandle, 0, FS_END )
      FSeek( nFileHandle, 0 )
      FClose( nFileHandle )
      IF nLength <= 0
         error_bar( "upd", "Fajl " + cLocalFileName + " download ERROR!" )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.



METHOD F18Admin:razdvajanje_sezona()

   LOCAL hParams
   LOCAL oTableDatabases := {}
   LOCAL nI
   LOCAL hDbServerParams, cTekuciUser, cTekucaPassword, cTekucaDb
   LOCAL cQuery
   LOCAL nFromSezona, nToSezona
   LOCAL cDatabaseFrom, cDatabaseTo
   LOCAL _db := Space( 100 )
   LOCAL cDeletePostojecaDbDN := "N"
   LOCAL _count := 0
   LOCAL aRezultati := {}
   LOCAL oRow
   LOCAL lConfirmEnter
   LOCAL GetList := {}

    IF f18_user(.T.) == "<undefined>"
        MsgBeep("Nemate administratorska prava. STOP!")
        RETURN .T.
    ENDIF

#ifndef F18_DEBUG

   IF !spec_funkcije_sifra( "ADMIN" )
      MsgBeep( "Opcija zaštićena šifrom !" )
      RETURN .F.
   ENDIF
#endif

   stop_refresh_operations()

   nFromSezona := Year( Date() ) - 1
   nToSezona := Year( Date() )

   set_cursor_on()
   lConfirmEnter := Set( _SET_CONFIRM, .T. )


   Box(, 7, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Otvaranje baze za novu sezonu ***" COLOR f18_color_i()
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Vrši se prenos sa godine:" GET nFromSezona PICT "9999"
   @ box_x_koord() + 3, Col() + 1 SAY8 "na godinu:" GET nToSezona PICT "9999" VALID ( nToSezona > nFromSezona .AND. nToSezona - nFromSezona == 1 )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Baza (prazno-sve):" GET _db PICT "@S30"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Ako baza postoji, pobriši je ? (D/N)" GET cDeletePostojecaDbDN VALID cDeletePostojecaDbDN $ "DN" PICT "@!"
   READ
   BoxC()

   Set( _SET_CONFIRM, lConfirmEnter )

   IF LastKey() == K_ESC
      start_refresh_operations()
      RETURN .F.
   ENDIF

   IF Pitanje(, "Konekcije svih korisnika na bazu biti prekinute! Nastaviti?", " " ) == "N"
      start_refresh_operations()
      RETURN .F.
   ENDIF

   pg_terminate_all_data_db_connections()

   hDbServerParams := my_server_params()
   cTekuciUser := hDbServerParams[ "user" ]
   cTekucaPassword := hDbServerParams[ "password" ]
   cTekucaDb := hDbServerParams[ "database" ]

   IF !::relogin_as_admin()
      // Alert( "login kao admin neuspješan !?" )
      start_refresh_operations()
      RETURN .F.
   ENDIF

   cQuery := "SELECT datname FROM pg_database "

   IF Empty( _db )
      cQuery += "WHERE datname LIKE '%_" + AllTrim( Str( nFromSezona ) ) + "' "
   ELSE
      cQuery += "WHERE datname = " + sql_quote( AllTrim( _db ) + "_" + AllTrim( Str( nFromSezona ) ) )
   ENDIF
   cQuery += "ORDER BY datname;"


   oTableDatabases := postgres_sql_query( cQuery )
   oTableDatabases:GoTo( 1 )

   // treba da imamo listu baza,  uzmemo sa select-om sve sto ima npr. 2013, i onda cemo provrtiti te baze i napraviti 2014
   Box(, 3, 65 )

   DO WHILE !oTableDatabases:Eof()

      oRow := oTableDatabases:GetRow()

      // test_2013
      cDatabaseFrom := AllTrim( oRow:FieldGet( 1 ) )
      // test_2014
      cDatabaseTo := StrTran( cDatabaseFrom, "_" + AllTrim( Str( nFromSezona ) ), "_" + AllTrim( Str( nToSezona ) ) )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY Space( 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Kreiranje baze: " +  cDatabaseFrom + " > " + cDatabaseTo


      hParams := hb_Hash()
      hParams[ "db_type" ] := 1 // init parametri za razdvajanje, pocetno stanje je 1
      hParams[ "db_name" ] := cDatabaseTo
      hParams[ "db_template" ] := cDatabaseFrom
      hParams[ "db_drop" ] := cDeletePostojecaDbDN
      hParams[ "db_comment" ] := ""

      IF ! ::create_new_pg_db( hParams )
         AAdd( aRezultati, { cDatabaseTo, cDatabaseFrom, "ERR" } )
         error_bar( "nova_sezona", cDatabaseFrom + " -> " + cDatabaseTo )
      ELSE
         ++_count
      ENDIF

      oTableDatabases:Skip()

   ENDDO

   BoxC()

   ::relogin_as( cTekuciUser, cTekucaPassword, cTekucaDb )

   IF Len( aRezultati ) > 0
      MsgBeep( "Postoje greške kod otvaranja sezone !" )
   ENDIF

   IF _count > 0
      MsgBeep( "Uspješno kreirano " + AllTrim( Str( _count ) ) + " baza" )
   ENDIF

   start_refresh_operations()

   RETURN .T.



METHOD F18Admin:create_new_pg_db( hDb )

   LOCAL cDatabaseName, cDatabaseTemplate, lDbDrop, nDatabaseType, cDatabaseComment
   LOCAL cQuery
   LOCAL oQuery, aRezultati
   LOCAL _db_params, cTekuciUser, cTekucaPassword, cTekucaDb

   // 1) hF18Params read
   // ===============================================================
   IF hDb == NIL

      IF !spec_funkcije_sifra( "ADMIN" )
         MsgBeep( "Opcija zasticena !" )
         RETURN .F.
      ENDIF

      hDb := hb_Hash()

      IF !::create_new_pg_db_params( @hDb ) // CREATE DATABASE name OWNER admin TEMPLATE templ;
         RETURN .F.
      ENDIF

   ENDIF

   cDatabaseName := hDb[ "db_name" ]
   cDatabaseTemplate := hDb[ "db_template" ]
   lDbDrop := hDb[ "db_drop" ] == "D"
   nDatabaseType := hDb[ "db_type" ]
   cDatabaseComment := hDb[ "db_comment" ]

   IF Empty( cDatabaseTemplate ) .OR. Left( cDatabaseTemplate, 5 ) == "empty"
      nDatabaseType := 0 // ovo ce biti prazna baza uvijek
   ENDIF

   IF ! ::relogin_as_admin( "postgres" )
      RETURN .F.
   ENDIF

   IF lDbDrop
      IF !::drop_pg_db( cDatabaseName )
         RETURN .F.
      ENDIF
   ELSE

      cQuery := "SELECT COUNT(*) FROM pg_database "
      cQuery += "WHERE datname = " + sql_quote( cDatabaseName )
      oQuery := postgres_sql_query( cQuery )
      IF oQuery:GetRow( 1 ):FieldGet( 1 ) > 0
         error_bar( "nova_sezona", "baza " + cDatabaseName + " vec postoji" )
         RETURN .F. // baza vec postoji
      ENDIF
   ENDIF

   cQuery := "CREATE DATABASE " + cDatabaseName + " OWNER admin"
   IF !Empty( cDatabaseTemplate )
      cQuery += " TEMPLATE " + cDatabaseTemplate
   ENDIF
   cQuery += ";"

   info_bar( "nova_sezona", "db create: " + cDatabaseName  )
   oQuery := postgres_sql_query( cQuery )
   IF sql_error_in_query( oQuery, "CREATE", sql_postgres_conn() )
      RETURN .F.
   ENDIF

   cQuery := "GRANT ALL ON DATABASE " + cDatabaseName + " TO admin;"
   cQuery += "GRANT ALL ON DATABASE " + cDatabaseName + " TO xtrole WITH GRANT OPTION;"

   info_bar( "nova_sezona", "grant admin, xtrole: " + cDatabaseName )
   oQuery := postgres_sql_query( cQuery )
   IF sql_error_in_query( oQuery, "GRANT", sql_postgres_conn() )
      RETURN .F.
   ENDIF

   IF !Empty( cDatabaseComment )
      cQuery := "COMMENT ON DATABASE " + cDatabaseName + " IS " + sql_quote( hb_StrToUTF8( cDatabaseComment ) ) + ";"
      info_bar( "nova_sezona", "Postavljam opis baze..." )
      run_sql_query( cQuery )
   ENDIF

   IF nDatabaseType > 0
      info_bar( "nova_sezona", "brisanje podataka " + cDatabaseName )
      ::delete_db_data_all( cDatabaseName, nDatabaseType )
   ENDIF

   RETURN .T.



METHOD F18Admin:relogin_as_admin( cDatabase )

   LOCAL hSqlParams := my_server_params()
   LOCAL nConnType := 1

   IF f18_user(.T.) == "<undefined>"
      RETURN .F.
   ENDIF

   hb_default( @cDatabase, "postgres" )

   IF cDatabase == "postgres"
      nConnType := 0
   ENDIF

   my_server_logout( nConnType )

   hSqlParams[ "user" ] := f18_user(.T.)
   hSqlParams[ "password" ] := f18_password(.T.)
   hSqlParams[ "database" ] := cDatabase

   IF my_server_login( hSqlParams, nConnType )
      IF cDatabase != "postgres" .AND. "_" $ cDatabase // database koja sadrzi F18 podatke
         set_sql_search_path()
      ENDIF

      RETURN .T.
   ENDIF

   RETURN .F.


METHOD F18Admin:relogin_as( cUser, cPwd, cDatabase )

   LOCAL hSqlParams := my_server_params()
   LOCAL nConnType := 1

   IF cDatabase == "postgres"
      nConnType := 0
   ENDIF

   my_server_logout( nConnType )

   hSqlParams[ "user" ] := cUser
   hSqlParams[ "password" ] := cPwd

   IF cDatabase <> NIL
      hSqlParams[ "database" ] := cDatabase
   ENDIF

   RETURN my_server_login( hSqlParams, nConnType )


METHOD F18Admin:drop_pg_db( cDatabaseName )

   LOCAL cQry, oQry
   LOCAL hDbServerParams
   LOCAL GetList := {}

   IF cDatabaseName == NIL

      IF !spec_funkcije_sifra( "ADMIN" )
         MsgBeep( "Opcija zasticena !" )
         RETURN .F.
      ENDIF

      // treba mi db name ?
      cDatabaseName := Space( 30 )

      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Naziv baze:" GET cDatabaseName VALID !Empty( cDatabaseName )
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      cDatabaseName := AllTrim( cDatabaseName )

      IF Pitanje(, "100% sigurni da zelite izbrisati bazu '" + cDatabaseName + "' ?", "N" ) == "N"
         RETURN .F.
      ENDIF

   ENDIF

   IF ! ::relogin_as_admin( "postgres" )
      RETURN .F.
   ENDIF

   cQry := "DROP DATABASE IF EXISTS " + cDatabaseName + ";"

   oQry := postgres_sql_query( cQry )

   IF sql_error_in_query( oQry, "DROP", sql_postgres_conn() )
      error_bar( "drop_db", "drop db: " + cDatabaseName )
      RETURN .F.
   ENDIF

   RETURN .T.


METHOD F18Admin:delete_db_data_all( cDatabaseName, nDataType )

   LOCAL oRet
   LOCAL cQuery
   LOCAL _pg_srv

   IF cDatabaseName == NIL
      ?E "Opcija delete_db_data_all zahtjeva naziv baze ..."
      RETURN .F.
   ENDIF

   // nDataType
   // 1 - pocetno stanje
   // 2 - brisi sve podatke
   IF nDataType == NIL
      nDataType := 1
   ENDIF


   IF !::relogin_as_admin( AllTrim( cDatabaseName ) )
      RETURN .F.
   ENDIF

   // tabele prometa - potrebno nulirati kod reseta podataka
   cQuery := ""
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "kalk_kalk;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "kalk_doks;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "kalk_doks2;"

   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "pos_doks;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "pos_dokspf;"

   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt_atributi;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fakt_doks;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fakt_doks2;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt;"

   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fin_suban;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fin_anal;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fin_sint;"
   cQuery += "DELETE FROM " + f18_sql_schema("fin_nalog") + ";"

   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "mat_suban;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "mat_anal;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "mat_sint;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "mat_nalog;"

   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_docs;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_it;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_it2;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_ops;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_log;"
   // cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_lit;"

   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "epdv_kuf;"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "epdv_kif;"

   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'fin/%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'kalk/%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'fakt/%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'pos/%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'epdv/%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE 'rnal_doc_no';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE '%auto_plu%';"
   cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "metric WHERE metric_name LIKE '%lock%';"

   cQuery += "DELETE FROM " + f18_sql_schema("log") + ";"


   IF nDataType > 1 // ako je potrebno brisati sve

      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "os_os;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "os_promj;"

      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "sii_sii;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "sii_promj;"

      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "ld_ld;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "ld_radn;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "ld_pk_data;"
      cQuery += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "ld_pk_radn;"

      cQuery += "DELETE FROM " + f18_sql_schema( "roba" ) + ";"
      cQuery += "DELETE FROM " + f18_sql_schema( "partn" ) + ";"
      cQuery += "DELETE FROM " + f18_sql_schema( "sifv" ) + ";"

   ENDIF

   info_bar( "nova_sezona", "brisanje podataka " + cDatabaseName )
   oRet := run_sql_query( cQuery )
   IF sql_error_in_query( oRet, "DELETE" )
      RETURN .F.
   ENDIF

   RETURN .T.


METHOD F18Admin:create_new_pg_db_params( hParams )

   LOCAL lOk := .F.
   LOCAL nX := 1
   LOCAL cDatabaseName := Space( 50 )
   LOCAL cDatabaseTemplate := Space( 50 )
   LOCAL cDatabaseSezona := AllTrim( Str( Year( Date() ) ) )
   LOCAL cDatabaseComment := Space( 100 )
   LOCAL lDbDrop := "N"
   LOCAL nDatabaseType := 1

   // LOCAL cDatabaseName
   LOCAL GetList := {}

   Box(, 12, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** KREIRANJE NOVE BAZE PODATAKA ***"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Naziv nove baze:" GET cDatabaseName VALID _new_db_valid( cDatabaseName ) PICT "@S30"
   @ box_x_koord() + nX, Col() + 1 SAY "godina:" GET cDatabaseSezona PICT "@S4" VALID !Empty( cDatabaseSezona )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Opis baze (*):" GET cDatabaseComment PICT "@S50"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koristiti kao uzorak postojeću bazu (*):"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Naziv:" GET cDatabaseTemplate PICT "@S40"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Brisi bazu ako vec postoji ! (D/N)" GET lDbDrop VALID lDbDrop $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pražnjenje podataka (1) pocetno stanje (2) sve" GET nDatabaseType PICT "9"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** opcije markirane kao (*) nisu obavezne"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN lOk
   ENDIF

   cDatabaseName := AllTrim( cDatabaseName ) + "_" + AllTrim( cDatabaseSezona )    // formiranje strina naziva baze

   // template empty
   IF Empty( cDatabaseTemplate )
      cDatabaseTemplate := "empty"
   ENDIF

   // - zaista nema template !
   IF AllTrim( cDatabaseTemplate ) == "!"
      cDatabaseTemplate := ""
   ENDIF

   hParams[ "db_name" ] := AllTrim( cDatabaseName )
   hParams[ "db_template" ] := AllTrim( cDatabaseTemplate )
   hParams[ "db_drop" ] := lDbDrop
   hParams[ "db_type" ] := nDatabaseType
   hParams[ "db_comment" ] := AllTrim( cDatabaseComment )

   lOk := .T.

   RETURN lOk





STATIC FUNCTION _new_db_valid( cDatabaseName )

   LOCAL lOk := .F.

   IF Empty( cDatabaseName )
      MsgBeep( "Naziv baze ne može biti prazno !" )
      RETURN lOk
   ENDIF

   IF ( "-" $ cDatabaseName .OR. ;
         "?" $ cDatabaseName .OR. ;
         ":" $ cDatabaseName .OR. ;
         "," $ cDatabaseName .OR. ;
         "." $ cDatabaseName )

      MsgBeep( "Naziv baze ne moze sadržavati znakove .:- itd... !" )
      RETURN lOk

   ENDIF

   lOk := .T.

   RETURN lOk
