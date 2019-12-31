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

FUNCTION is_mac_osx()

#ifdef __PLATFORM__DARWIN
   RETURN .T.
#else

   RETURN .F.
#endif


PROCEDURE OutMsg( hFile, cMsg )

   IF hFile == 1
      OutStd( cMsg )
   ELSEIF hFile == 2
      OutErr( cMsg )
   ELSE
      FWrite( hFile, cMsg )
   ENDIF

   RETURN




/* FilePath(cFile)
 *      Extract the full path name from a filename
 *  return cFilePath
 */

FUNCTION My_FilePath( cFile )

   LOCAL nPos, cFilePath

   nPos := RAt( SLASH, cFile )
   IF ( nPos != 0 )
      cFilePath := SubStr( cFile, 1, nPos )
   ELSE
      cFilePath := ""
   ENDIF

   RETURN cFilePath

FUNCTION ExFileName( cFile )

   LOCAL nPos, cFileName

   IF ( nPos := RAt( SLASH, cFile ) ) != 0
      cFileName := SubStr( cFile, nPos + 1 )
   ELSE
      cFileName := cFile
   ENDIF

   RETURN cFileName

FUNCTION AddBS( cPath )

   IF Right( cPath, 1 ) <> SLASH
      cPath := cPath + SLASH
   ENDIF



/* file ChangeEXT(cImeF,cExt, cExtNew, fBezAdd)
 *    Promjeni ekstenziju
 *
 *  param:s cImeF   ime fajla
 *  param:s cExt    polazna extenzija (obavezno 3 slova)
 *  param:s cExtNew nova extenzija
 *  param:s fBezAdd ako je .t. onda ce fajlu koji nema cExt dodati cExtNew
 *
 * \code
 *
 * ChangeEXT("SUBAN", "DBF", "CDX", .t.)
 * suban     -> suban.CDX
 *
 * ChangeEXT("SUBAN", "DBF", "CDX", .f.)
 * SUBAN     -> SUBAN
 *
 *
 * ChangeEXT("SUBAN.DBF", "DBF", "CDX", .t.)
 * SUBAN.DBF  -> SUBAN.CDX
 *
 *
 */

FUNCTION ChangeEXT( cImeF, cExt, cExtNew, fBezAdd )

   LOCAL cTacka

   IF fBezAdd == NIL
      fBezAdd := .T.
   ENDIF

   IF Empty( cExtNew )
      cTacka := ""
   ELSE
      cTacka := "."
   ENDIF
   cImeF := ToUnix( cImeF )

   cImeF := Trim( StrTran( cImeF, "." + cEXT, cTacka + cExtNew ) )
   IF !Empty( cTacka ) .AND.  Right( cImeF, 4 ) <> cTacka + cExtNew
      cImeF := cImeF + cTacka + cExtNew
   ENDIF

   RETURN  cImeF


FUNCTION IsDirectory( cDir1 )

   LOCAL cDirTek
   LOCAL lExists

   cDir1 := ToUnix( cDir1 )

   cDirTek := DirName()

   IF DirChange( cDir1 ) <> 0
      lExists := .F.
   ELSE
      lExists := .T.
   ENDIF

   DirChange( cDirTek )

   RETURN lExists



FUNCTION brisi_stare_fajlove( cDir, cFilesMatch, nDana )

   LOCAL cFile, nCnt, nCntNew

   IF cFilesMatch == NIL
      cFilesMatch := "*.*"
   ENDIF

   IF nDana == NIL
      nDana := 30
   ENDIF

   cDir := ToUnix( Trim( cDir ) )
   cFile := FileSeek( cDir + cFilesMatch )

   nCnt := 0
   nCntNew := 0
   DO WHILE !Empty( cFile )
      IF Date() - FileDate() > nDana
         nCnt++
         FileDelete( cDir + cFile )
      ELSE
         nCntNew++
      ENDIF
      cFile := FileSeek()
   ENDDO

   ?E  cDir + cFilesMatch,  "COUNT OLD DEL:", nCnt, " NEW:", nCntNew

   RETURN NIL


FUNCTION ToUnix( cFileName )
   RETURN cFileName


FUNCTION file_to_str( cFileName )

   LOCAL oFile, cSadrzaj

   cFileName := AllTrim( cFileName )
   oFile := TFileRead():New( cFileName )
   oFile:Open()
   IF oFile:Error()
      RETURN "READ_ERROR ?!"
   ENDIF

   cSadrzaj := ""
   DO WHILE oFile:MoreToRead()
      cSadrzaj += oFile:ReadLine()
   ENDDO

   oFile:Close()

   RETURN cSadrzaj


#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapifs.h"

HB_FUNC( FILEBASE )
{
   const char * szPath = hb_parc( 1 );
   if( szPath )
   {
      PHB_FNAME pFileName = hb_fsFNameSplit( szPath );
      hb_retc( pFileName->szName );
      hb_xfree( pFileName );
   }
   else
      hb_retc_null();
}

/* FileExt( <cFile> ) --> cFileExt
*/
HB_FUNC( FILEEXT )
{
   const char * szPath = hb_parc( 1 );
   if( szPath )
   {
      PHB_FNAME pFileName = hb_fsFNameSplit( szPath );
      if( pFileName->szExtension != NULL )
         hb_retc( pFileName->szExtension + 1 ); /* Skip the dot */
      else
         hb_retc_null();
      hb_xfree( pFileName );
   }
   else
      hb_retc_null();
}

#pragma ENDDUMP


#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapierr.h"
#include "hbapigt.h"
#include "hbapiitm.h"
#include "hbapifs.h"

/* TOFIX: The screen buffer handling is not right for all platforms (Windows)
          The output of the launched (MS-DOS?) app is not visible. */

HB_FUNC( __RUN_SYSTEM )
{
   const char * pszCommand = hb_parc( 1 );
   int iResult;

   if( pszCommand && hb_gtSuspend() == HB_SUCCESS )
   {
      char * pszFree = NULL;

      iResult = system( hb_osEncodeCP( pszCommand, &pszFree, NULL ) );

      hb_retni(iResult);

      if( pszFree )
         hb_xfree( pszFree );

      if( hb_gtResume() != HB_SUCCESS )
      {
         /* an error should be generated here !! Something like */
         /* hb_errRT_BASE_Ext1( EG_GTRESUME, 6002, NULL, HB_ERR_FUNCNAME, 0, EF_CANDEFAULT ); */
      }


   }
}

#pragma ENDDUMP


#ifdef __PLATFORM__WINDOWS
#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapierr.h"
#include "hbapigt.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "windows.h"


HB_FUNC( __WIN32_SYSTEM )
{

    const char * pszCommand = hb_parc( 1 );

    int iResult;
    DWORD exitCode;


   if( pszCommand && hb_gtSuspend() == HB_SUCCESS )
   {
      char * pszFree = NULL;

      STARTUPINFO si;
      PROCESS_INFORMATION pi;

      ZeroMemory( &si, sizeof(si) );
      si.cb = sizeof(si);
      ZeroMemory( &pi, sizeof(pi) );

      si.wShowWindow = SW_HIDE; // SW_HIDE, SW_SHOW
      si.dwFlags = STARTF_USESHOWWINDOW;
      si.lpTitle = pszCommand;

       // Start the child process.
       if ( !CreateProcess( NULL,   // No module name (use command line)
                  pszCommand,        // Command line
                  NULL,           // Process handle not inheritable
                  NULL,           // Thread handle not inheritable
                  FALSE,          // Set handle inheritance to FALSE
                  0,              // No creation flags
                  NULL,           // Use parent's environment block
                  NULL,           // Use parent's starting directory
                  &si,            // Pointer to STARTUPINFO structure
                  &pi )           // Pointer to PROCESS_INFORMATION structure
       )
       {
            printf( "CreateProcess %s failed (%d).\n", pszCommand, GetLastError() );

            iResult = 100;
            hb_retni(iResult);
            if( pszFree )  hb_xfree( pszFree );

            return;
        }

          //HWND console_name = FindWindow( NULL, pszTitle);
                //if(console_name) {
                //     printf( "nasao console name%s\n", pszTitle);
                //     ShowWindow(console_name, SW_MINIMIZE);
          //}

        // Wait until child process exits.
        WaitForSingleObject( pi.hProcess, INFINITE );

        GetExitCodeProcess( pi.hProcess, &exitCode );
        //printf( "exitcode =%d", exitCode );

        iResult = exitCode;

        // Close process and thread handles.
        CloseHandle( pi.hProcess );
        CloseHandle( pi.hThread );

        hb_retni( iResult );

        if( pszFree ) hb_xfree( pszFree );
        return;

   }
}

#pragma ENDDUMP
#endif


/*
  f18_run( 'lo_dbf_xlsx.cmd "c:\temp\test.dbf" "c:\temp"')
*/

FUNCTION f18_run( cCommand, hOutput, lAsync )

   LOCAL nRet := -1
   LOCAL cStdOut := "", cStdErr := ""
   LOCAL cPrefixCmd
   LOCAL cMsg, nI, nNumArgs

   IF lAsync == NIL
      lAsync := .F. // default sync execute
   ENDIF


#ifdef __PLATFORM__WINDOWS

   IF Left( cCommand, 4 ) == "copy"
      RETURN hb_run( cCommand )
   ENDIF

   IF ValType( hOutput ) == "H"
      nRet := hb_processRun( cCommand, NIL, @cStdOut, @cStdErr )
      hOutput[ "stdout" ] := cStdOut
      hOutput[ "stderr" ] := cStdErr
   ELSE
      IF Left( cCommand, 4 ) != "cmd " .AND. Left( cCommand, 5 ) != "start"
         cCommand := "cmd /c " + cCommand
         IF lAsync
            cCommand := "start " + cCommand
         ENDIF
      ENDIF
      ?E "win32_run:", cCommand

      nRet := __WIN32_SYSTEM( cCommand )
      ?E "win32_run exit:", nRet
   ENDIF

   RETURN nRet

#else // linux

altd()
   IF lAsync
      nRet := __run_system( cCommand + "&" ) // .AND. ( is_linux() .OR. is_mac()
   ELSE
      /* hb_processRun( <cCommand>, [ <cStdIn> ], [ @<cStdOut> ], [ @<cStdErr> ], ;
                     [ <lDetach> ] ) --> <nResult> */
      nRet := hb_processRun( cCommand, NIL, @cStdOut, @cStdErr, lAsync )
   ENDIF

   ?E cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr

   IF nRet == 0
      info_bar( "run1", cCommand  + " : " + cStdOut + " : " + cStdErr )
   ELSE
      error_bar( "run1", cCommand  + " " + " : " + cStdOut + " : " + cStdErr )
      cPrefixCmd := get_run_prefix_cmd( cCommand )

      IF lAsync
         nRet := __run_system( cPrefixCmd + cCommand + "&" )
      ELSE
         nRet := hb_processRun( cPrefixCmd + cCommand, NIL, @cStdOut, @cStdErr )
      ENDIF

      ?E cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr


      IF nRet == 0
         info_bar( "run2", cPrefixCmd + cCommand + " : " + cStdOut + " : " + cStdErr )
      ELSE
         // error_bar( "run2", cPrefixCmd + cCommand  + " : " + cStdOut + " : " + cStdErr )
         log_write_file("run2:" + cPrefixCmd + cCommand  + " : " + cStdOut + " : " + cStdErr, 2 )

         nRet := __run_system( cCommand )  // npr. copy komanda trazi system run a ne hbprocess run
         //?E cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr
         IF nRet <> 0
            // error_bar( "run3", cCommand + " : " + cStdOut + " : " + cStdErr )
            cMsg := "ERR run3 cmd: " + cCommand + " : " + cStdOut + " : " + cStdErr
            log_write_file( cMsg, 2 )

            cCommand := "LD_LIBRARY_PATH= " + cCommand
            nRet := __run_system( cCommand )
            IF nRet <> 0
              error_bar( "run4:", cCommand + " : " + cStdOut + " : " + cStdErr )
              cMsg := "ERR run4 cmd: " + cCommand + " : " + cStdOut + " : " + cStdErr
              log_write_file( cMsg, 2 )
            ENDIF
         ENDIF

   ENDIF

   ENDIF

   IF ValType( hOutput ) == "H"
   hOutput[ "stdout" ] := cStdOut // hash matrica
   hOutput[ "stderr" ] := cStdErr
   ENDIF
#endif

   RETURN nRet


FUNCTION windows_run_invisible( cProg, cArgumenti, cStdOut, cStdErr, lAsync )

   LOCAL nBytes := 0, cBuf := Space( 4 ), lStaraVerzija := .F.
   LOCAL cDirF18Util := f18_exe_path() + f18_util_path()
   LOCAL cStart, cCmd
   LOCAL nH, cArg, cArg2
   LOCAL cVer := "'006"

   hb_default( @lAsync, .F. )
   IF DirChange( cDirF18Util ) != 0  // e.g. F18.exe/F18_util
      IF MakeDir( cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + cDirF18Util + " neuspješno?! STOP" )
         RETURN -1
      ENDIF
   ENDIF

   IF !is_windows()
      RETURN -1
   ENDIF

   cArg := Token( cArgumenti, ";", 1 )
   cArg2 := Token( cArgumenti, ";", 2 )

   IF File( cDirF18Util + "run_invisible.vbs" )
      nH := FOpen( cDirF18Util + "run_invisible.vbs" )
      nBytes := FRead( nH, @cBuf, 4 )
      FClose( nH )
      IF nBytes < 4 .OR. cBuf != cVer
         lStaraVerzija := .T.
      ENDIF
   ENDIF

   IF lStaraVerzija .OR. !File( cDirF18Util + "run_invisible.vbs" )
      nH := FCreate( cDirF18Util + "run_invisible.vbs" )

      FWrite( nH, cVer + hb_eol() )
      FWrite( nH, 'Dim cArg1, cArg2, cArg3, cArg4, cUserProfile, cShortUserProfile' + hb_eol() )
      FWrite( nH, 'Set objShell = WScript.CreateObject("WScript.Shell")' + hb_eol() )
      FWrite( nH, 'Set fso = CreateObject("Scripting.FileSystemObject")' + hb_eol() )
      FWrite( nH, 'cUserProfile=objShell.ExpandEnvironmentStrings("%UserProfile%")' + hb_eol() )

      // https://www.codeproject.com/Tips/44521/Get-DOS-short-name-with-VbScript

      FWrite( nH, 'if fso is nothing then' + hb_eol() )
      FWrite( nH, '   WScript.echo "fso not object?!"' + hb_eol() )
      FWrite( nH, 'end if' + hb_eol() )

      FWrite( nH, 'On Error Resume Next' + hb_eol() )
      FWrite( nH, 'Set fsoFile = fso.GetFile( cUserProfile )' + hb_eol() )
      FWrite( nH, 'if Err.number <> 0 then' + hb_eol() )
      FWrite( nH, '        Set fsoFile = fso.GetFolder( cUserProfile )' + hb_eol() )
      FWrite( nH, 'end if' + hb_eol() )
      FWrite( nH, 'if fsoFile is not nothing then' + hb_eol() )
      FWrite( nH, '   cShortUserProfile = fsoFile.ShortPath' + hb_eol() )
      FWrite( nH, 'end if' + hb_eol() )
      // ' WScript.echo objShell.Environment("System").Item("NUMBER_OF_PROCESSORS")
      FWrite( nH, 'cArg1=replace(Wscript.arguments(0),cUserProfile,cShortUserProfile)' + hb_eol() )
      FWrite( nH, 'cArg2=replace(Wscript.arguments(1),cUserProfile,cShortUserProfile)' + hb_eol() )
      FWrite( nH, 'cArg3=replace(Wscript.arguments(2),cUserProfile,cShortUserProfile)' + hb_eol() )
      FWrite( nH, 'cArg4=replace(Wscript.arguments(3),cUserProfile,cShortUserProfile)' + hb_eol() )
      FWrite( nH, 'objShell.Run cArg1 & " " & cArg2 & " " & cArg3 & " " & cArg4, 0, True' )

      FClose( nH )
   ENDIF

   cCmd := 'wscript '
   cCmd += cDirF18Util + 'run_invisible.vbs '

   IF lAsync
      cCmd += '"cmd /c start" '
   ELSE
      cCmd += '"cmd /c" '
   ENDIF


   cCmd += '"' + cProg + '" "' + cArg + '" "' + cArg2 + '"'

   ?E cCmd

   RETURN hb_processRun( cCmd, NIL, @cStdOut, @cStdErr, lAsync )


FUNCTION get_run_prefix_cmd( cCommand, lAsync )

   LOCAL cPrefix

   hb_default( @lAsync, .F. )

   IF is_windows()
      // cPrefix := "cmd /c "
      IF cCommand != NIL .AND. Left( cCommand, 6 ) == "start "
         cPrefix := ""  // sprijeciti duplo "start start program"
      ELSEIF cCommand != NIL .AND. Left( cCommand, 4 ) == "cmd "
         cPrefix := ""
      ELSE
         // IF lAsync
         cPrefix := 'start "" '
         // ELSE
         // https://stackoverflow.com/questions/324539/how-can-i-run-a-program-from-a-batch-file-without-leaving-the-console-open-after
         // cPrefix := 'cmd /c '
         // ENDIF
      ENDIF
   ELSE
      IF is_mac()
         IF cCommand != NIL .AND. Left( cCommand, 5 ) == "open "
            cPrefix := ""
         ELSE
            cPrefix := "open "
         ENDIF
      ELSE
         IF cCommand != NIL .AND. Left( cCommand, 9 ) == "xdg-open "
            cPrefix := ""
         ELSE
            cPrefix := "xdg-open "
         ENDIF
      ENDIF
   ENDIF

   IF cCommand != NIL .AND. Left( cCommand, 4 ) == "java"
      cPrefix := "" // if java ..., ne treba start
   ENDIF

   IF cCommand != NIL .AND. Left( cCommand, 10 ) == "f18_editor"
      IF is_linux() .OR. is_mac()  // if f18_editor ..., samo windows sa prefix start
         cPrefix := ""
      ENDIF
   ENDIF


   RETURN cPrefix


/*
    run_cmd_with_prefix( "f18_editor test.txt" ) => "f18_editor.cmd test.txt"
*/
FUNCTION get_run_cmd_with_prefix( cCommand, lAsync )

   LOCAL cCmdWithPrefix := get_run_prefix_cmd( cCommand, lAsync ) + cCommand

   // IF is_windows()
   // cCmdWithPrefix := StrTran( cCmdWithPrefix, "start f18_editor", "f18_editor.cmd" )
   // ENDIF

   RETURN cCmdWithPrefix


FUNCTION f18_open_document( cDocument )

   LOCAL cPrefixCmd
   LOCAL cMsg

   cPrefixCmd := get_run_prefix_cmd()
   cDocument := file_path_quote( cDocument )

   RETURN f18_run( cPrefixCmd + " " + file_path_quote( cDocument ), NIL, .T. )



FUNCTION open_folder( cFolder )

   LOCAL cCmd

   cFolder := file_path_quote( cFolder )

   RETURN f18_open_document( cFolder )



FUNCTION f18_open_mime_document( cDocument )

   LOCAL cCmd := "", nError, cPrefixCmd

   // IF Pitanje(, "Otvoriti " + AllTrim( cDocument ) + " ?", "D" ) == "N"
   // RETURN .F.
   // ENDIF

/*
#ifdef __PLATFORM__UNIX

#ifdef __PLATFORM__DARWIN
   cCmd += "open " + cDocument
#else
   cCmd += "xdg-open " + cDocument + " &"
#endif

#else __PLATFORM__WINDOWS

   cCmd += "cmd /c " + cDocument

#endif
*/

   // cDocument := file_path_quote( cDocument )

   IF is_windows()
      nError := f18_run( cCmd + " " + file_path_quote( cDocument ), NIL, .T. )
   ELSE
      cPrefixCmd := get_run_prefix_cmd()
      cCmd += cPrefixCmd
      nError := f18_run( cCmd + " " + file_path_quote( cDocument ), NIL, .T. ) // async
   ENDIF

   IF nError <> 0
      MsgBeep( "Problem sa otvaranjem dokumenta !#Greška: " + AllTrim( Str( nError ) ) )
      RETURN nError
   ENDIF

   RETURN nError
