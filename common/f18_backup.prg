/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"
#include "f18_color.ch"

FUNCTION pg_dump_cmd()

   RETURN "pg_dump"


CLASS F18Backup

   METHOD New()

   METHOD do_backup_now()
   METHOD do_backup()

   METHOD backup_organizacija()
   METHOD backup_server()

   METHOD backup_to_removable()

   METHOD backup_in_progress_info()

   METHOD get_backup_path()
   METHOD get_backup_interval()
   // METHOD get_backup_type()
   METHOD get_backup_filename()
   METHOD get_last_backup_date()
   METHOD set_last_backup_date()
   METHOD get_removable_drive()
   METHOD get_windows_ping_time()

   METHOD Lock()
   METHOD UNLOCK()
   METHOD locked()

   VAR  nError       INIT 0
   VAR  nBackupType  INIT 1 // organizacija

   DATA cPath
   DATA cFileName
   DATA backup_interval

   DATA last_backup
   DATA removable_drive
   DATA ping_time

ENDCLASS



FUNCTION f18_backup_now()

   LOCAL oBackup := F18Backup():New()

   oBackup:do_backup_now()

   RETURN .T.


PROCEDURE thread_f18_backup( nBackupTipOrgIliSve )

   LOCAL oBackup
   LOCAL lAutoBackup := .T.

   DO WHILE !open_thread( "f18_backup" )
      ?E "ERROR open_thread f18_backup"
   ENDDO

   set_global_vars_0()

   oBackup := F18Backup():New()
   oBackup:nBackupType := nBackupTipOrgIliSve

   oBackup:get_backup_interval()
   oBackup:get_last_backup_date()
   oBackup:get_backup_path()

   // IF !start_now .AND.
   IF oBackup:backup_interval == 0 // nemam sta raditi ako ovaj interval ne postoji !
      // hb_gtSelect( s_pMainGt )
      info_bar( "backup", "backup 0" )
      // hb_idleSleep( 0.5 )
      RETURN
   ENDIF

   IF ( Date() - oBackup:backup_interval ) <= oBackup:last_backup
      // hb_gtSelect( s_pMainGt )
      info_bar( "backup", "backup <interval" )
      RETURN
   ENDIF

   // IF oBackup:get_backup_type( nBackupTipOrgIliSve )

   oBackup:do_backup()
   // ENDIF

   // IF is_terminal()
   // hb_gtSelect( s_pMainGt )
   // ENDIF

   IF oBackup:nError == 0
      info_bar( "backup", "backup END :)" )
   ELSE
      error_bar( "backup", "backup ERROR" )
   ENDIF
   // hb_idleSleep( 0.5 )
   close_thread( "f18_backup" )

   RETURN


METHOD F18Backup:New()

   ::backup_interval := 0
   ::last_backup := CToD( "" )
   ::removable_drive := ""
   ::ping_time := 0
   info_bar( "backup", "backup start" )

   RETURN SELF


METHOD F18Backup:do_backup_now()

   LOCAL nType := 1
   LOCAL nX
   LOCAL nY
   LOCAL GetList := {}

   Box( "#Backup NOW", 7, 60 )
   nX := box_x_koord() + 2
   nY := box_y_koord() + 2


   @ nX++, nY SAY "*** BACKUP procedura *** " + DToC( Date() )

   nX++

   @ nX++, nY SAY "Dostupne opcije:"
   @ nX++, nY SAY8 "   1 - backup trenutne organizacije"
   @ nX++, nY SAY8 "   0 - backup kompletnog servera"
   @ nX++, nY SAY8 "Vaš odabir:" GET nType VALID nType == 0 .OR. nType == 1 PICT "9"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // da li je backup vec pokrenut ?
   IF ::locked( .T. )
      IF Pitanje(, "Napravi unlock backup operacije (D/N)?", "N" ) == "N"
         RETURN .F.
      ENDIF
   ENDIF

   ::get_backup_path()
   ::get_backup_interval()

   ::nBackupType := nType
   ::do_backup()

   IF ::nError == 0
      info_bar( "backup", "backup END :)" )
      MsgBeep( "kreiran backup:##" + ::cPath + ::cFileName )
   ELSE
      error_bar( "backup", "backup ERROR" )
   ENDIF

   RETURN .T.


METHOD F18Backup:backup_in_progress_info()

   LOCAL cTxt

   cTxt := "Operacija backup-a u toku. Pokusajte ponovo..."

   RETURN cTxt



METHOD F18Backup:do_backup()

   LOCAL pMainGT

   // IF lAuto == NIL
   // lAuto := .T.
   // ENDIF

   ::Lock() // zakljucaj opciju backup-a da je samo jedan korisnik radi

   IF ::nBackupType == 1
      ::backup_organizacija()
   ELSE
      ::backup_server()
   ENDIF

   IF ::nError == 0
      ::set_last_backup_date()   // setuj datum kreiranja backup-a
   ENDIF

   ::unlock()  // otkljucaj nakon sto je backup napravljen

   RETURN .T.


METHOD F18Backup:backup_organizacija()

   LOCAL lOk := .F.
   LOCAL cCmd := ""
   LOCAL hServerParams := my_server_params()
   LOCAL cHost := hServerParams[ "host" ]
   LOCAL nPort := hServerParams[ "port" ]
   LOCAL cDataBase := hServerParams[ "database" ]
   LOCAL cAdminUser := "admin"
   LOCAL nX := 7
   LOCAL nY := 2
   LOCAL nI, cBackupFile
   LOCAL _color_ok := F18_COLOR_BACKUP_OK
   LOCAL _color_err := F18_COLOR_BACKUP_ERROR
   LOCAL cLine := Replicate( "-", 70 )

   ::get_backup_filename()
   ::get_windows_ping_time()
   ::get_removable_drive()

   if f18_user(.T.) == "<undefined>"
       RETURN .F.
   ENDIF
   IF is_windows()
      cCmd += "set pgusername=" + f18_user(.T.) + "&set PGPASSWORD=" + f18_password(.T.) + "&"
      IF ::ping_time > 0
         cCmd += "ping -n " + AllTrim( Str( ::ping_time ) ) + " 8.8.8.8&"
      ENDIF
   ELSE
      cCmd += "export pgusername=" + f18_user(.T.) + ";export PGPASSWORD=" + f18_password(.T.) + ";"
   ENDIF

   cBackupFile := ::cPath + ::cFileName

   if is_windows()
       cBackupFile := StrTran( cBackupFile, "\", "//" )
   endif

   cCmd += pg_dump_cmd() + " "
   cCmd += " -h " + AllTrim( cHost )
   cCmd += " -p " + AllTrim( Str( nPort ) )
   cCmd += " -U " + f18_user()
   cCmd += " -w "
   cCmd += " -F c "
   cCmd += " -b "
   cCmd += ' -f "' + cBackupFile + '"'
   cCmd += ' "' + cDataBase + '"'

   FErase( ::cPath + ::cFileName )

   info_bar( "back", "backup u toku .. " + Right( ::cPath + ::cFileName, 60 ) )



   ::nError := hb_run_in_background_gt( cCmd )

   IF ::nError == 0
      // IF File( ::cPath + ::cFileName )
      info_bar( "backup", ::cPath + ::cFileName + " OK" )

      IF !Empty( ::removable_drive )
         IF ::backup_to_removable()
            info_bar( "backup", "prenos na " + ::removable_drive + " OK" )
         ELSE
            error_bar( "backup", "prenos na " + ::removable_drive + " ERR" )
         ENDIF
      ENDIF
   ELSE
      error_bar( "backup", ::cPath + ::cFileName + " ERROR" )
   ENDIF


   RETURN lOk


METHOD F18Backup:backup_server()

   LOCAL lOk := .F.
   LOCAL cCmd := ""
   LOCAL hServerParams := my_server_params()
   LOCAL cHost := hServerParams[ "host" ]
   LOCAL nPort := hServerParams[ "port" ]
   //LOCAL cDataBase := hServerParams[ "database" ]
   LOCAL cAdminUser := "admin"
   LOCAL nX := 7
   LOCAL nY := 2
   LOCAL nI, cBackupFile
   LOCAL cLine := Replicate( "-", 70 )
   LOCAL _color_ok := "W+/B+"
   LOCAL _color_err := "W+/R+"

   if f18_user(.T.) == "<undefined>"
       RETURN .F.
   ENDIF

   ::get_backup_filename()
   ::get_windows_ping_time()
   ::get_removable_drive()

   F18Admin():sql_cleanup_all()

   F18Admin():relogin_as( hServerParams[ "user" ],  hServerParams[ "password" ], hServerParams[ "database" ] )

   FErase( ::cPath + ::cFileName )
   Sleep( 1 )

   IF is_windows()
      cCmd += "set pgusername=" + f18_user(.T.) + "&set PGPASSWORD=" + f18_password(.T.) + "&"
      IF ::ping_time > 0
         cCmd += "ping -n " + AllTrim( Str( ::ping_time ) ) + " 8.8.8.8&"
      ENDIF
   ELSE
      cCmd += "export pgusername=" + f18_user(.T.) + ";export PGPASSWORD=" + f18_password(.T.) + ";"
   ENDIF


   cBackupFile := ::cPath + ::cFileName

   IF is_windows()
      cBackupFile := StrTran( cBackupFile, "\", "//" )
   ENDIF

   cCmd += "pg_dumpall"
   cCmd += " -h " + AllTrim( cHost )
   cCmd += " -p " + AllTrim( Str( nPort ) )
   cCmd += " -U " + AllTrim( cAdminUser )
   cCmd += " -w "
   cCmd += ' -f "' + cBackupFile + '"'

   ::nError := hb_run_in_background_gt( cCmd )


   IF ::nError == 0
      info_bar( "backup", ::cPath + ::cFileName + " OK" )

      IF !Empty( ::removable_drive )
         IF ::backup_to_removable()
            info_bar( "backup", "prenos na " + ::removable_drive + " OK" )
         ELSE
            error_bar( "backup", "prenos na " + ::removable_drive + " ERR" )
         ENDIF
      ENDIF
   ELSE
      error_bar( "backup", ::cPath + ::cFileName + " ERROR" )
   ENDIF

   RETURN lOk


METHOD F18Backup:backup_to_removable()

   LOCAL lOk := .F.
   LOCAL _res

   IF Empty( ::removable_drive )
      RETURN lOk
   ENDIF

   _res := FileCopy( ::cPath + ::cFileName, ::removable_drive + ::cFileName )
   Sleep( 1 )

   IF !File( ::removable_drive + ::cFileName )
   ELSE
      log_write( "backup to removable drive ok", 6 )
      lOk := .T.
   ENDIF

   RETURN lOk


METHOD F18Backup:get_windows_ping_time()

   ::ping_time := fetch_metric( "backup_windows_ping_time", my_user(), 0 )

   RETURN .T.


METHOD F18Backup:get_removable_drive()

   ::removable_drive := fetch_metric( "backup_removable_drive", my_user(), "" )

   RETURN .T.

METHOD F18Backup:get_backup_path()

   LOCAL _path
   LOCAL cDataBase

   IF ::nBackupType == 0
      set_f18_home_backup()
      ::cPath := my_home_backup()
   ELSE
      cDataBase := my_server_params()[ "database" ]
      set_f18_home_backup( cDataBase )
      ::cPath := my_home_backup()
   ENDIF

   RETURN .T.


METHOD F18Backup:get_backup_filename()

   LOCAL _name
   LOCAL _tmp
   LOCAL hServerParams := my_server_params()
   LOCAL nI

   _tmp := "server"

   IF ::nBackupType == 1
      _tmp := AllTrim( hServerParams[ "database" ] )
   ENDIF

   FOR nI := 1 TO 99
      _name := _tmp + "_" + DToS( Date() ) + "_" + PadL( AllTrim( Str( nI ) ), 2, "0" ) + ".backup"

      IF !File( ::cPath + _name )
         EXIT
      ENDIF

   NEXT

   ::cFileName := _name

   RETURN _name


METHOD F18Backup:get_backup_interval()

   LOCAL _param := "backup_company_interval"

   IF ::nBackupType == 0
      _param := "backup_server_interval"
   ENDIF

   ::backup_interval := fetch_metric( _param, my_user(), 0 )

   RETURN .T.




METHOD F18Backup:Lock()

   set_metric( "f18_backup_lock_status", my_user(), 1 )

   RETURN .T.


METHOD F18Backup:unlock()

   set_metric( "f18_backup_lock_status", my_user(), 0 )

   RETURN .T.


METHOD F18Backup:locked( lInfo )

   LOCAL lRet := .F.
   LOCAL _lock := fetch_metric( "f18_backup_lock_status", my_user(), 0 )

   IF lInfo == NIL
      lInfo := .F.
   ENDIF

   IF _lock > 0

      IF lInfo
         MsgBeep( "Operacija backup-a vec pokrenuta !#Prekidam operaciju !" )
      ENDIF

      lRet := .T.

   ENDIF

   RETURN lRet



METHOD F18Backup:set_last_backup_date()

   LOCAL nType := "company"

   IF ::nBackupType == 0
      nType := "server"
   ENDIF

   ?E "set", "f18_backup_date_" + nType, my_user(), Date()
   ?E set_metric( "f18_backup_date_" + nType, my_user(), Date() )

   RETURN .T.


METHOD F18Backup:get_last_backup_date()

   LOCAL nType := "company"

   IF ::nBackupType == 0
      nType := "server"
   ENDIF

   ::last_backup := fetch_metric( "f18_backup_date_" + nType, my_user(), CToD( "" ) )
   ?E "get ", "f18_backup_date_" + nType, my_user(), ::last_backup

   RETURN .T.


FUNCTION f18_gt_background()
   RETURN "NUL"


STATIC FUNCTION hb_run_in_background_gt( cCmd )

   LOCAL nError
   LOCAL pGT := NIL, pMainGT := NIL

   IF is_windows()
      RETURN f18_run( cCmd )
   ENDIF

// IF is_terminal()

   pGT := hb_gtCreate( f18_gt_background() )
   pMainGT := hb_gtSelect( pGT )

   /*
      ELSE
         s_pGT := hb_gtCreate( f18_gt() )
         s_pMainGT := hb_gtSelect( s_pGT )
         hb_gtReload( s_pGT )
         _set_color()
      ENDIF
   */

// IF s_pGT != NIL .AND. is_terminal()
// hb_gtSelect( s_pGT )
// ENDIF

   nError := hb_run( cCmd )
   ?E "RET=", nError, cCmd
// IF nError != 0
// error_bar( "backup", cCmd )
// ENDIF
// IF s_pMainGT != NIL .AND. is_terminal()
   hb_gtSelect( pMainGT )
// ENDIF

   RETURN nError


STATIC FUNCTION _set_color()

   LOCAL _color := F18_COLOR_BACKUP

   SetColor( _color )
   CLEAR SCREEN

   RETURN .T.
