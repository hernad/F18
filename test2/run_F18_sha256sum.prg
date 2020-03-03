?
? "OUTPUT: " + sha256sum( "run_F18_sha256sum.prg" )

FUNCTION sha256sum( cFile )

   LOCAL cCmd
   LOCAL hOutput := hb_Hash()
   LOCAL nRet
   LOCAL cProg := "/home/hernad/Downloads/F18_sha256sum"

   cCmd := cProg + " " + cFile

   ? "cmd=", cCmd

   nRet := f18_run( cCmd, @hOutput )

   RETURN hOutput[ "stdout" ]



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
      ? "win32_run:", cCommand
      nRet := __WIN32_SYSTEM( cCommand )
      ? "win32_run exit:", nRet
   ENDIF

   RETURN nRet
#endif

IF lAsync
   nRet := __run_system( cCommand + "&" ) // .AND. ( is_linux() .OR. is_mac()
ELSE
   /* hb_processRun( <cCommand>, [ <cStdIn> ], [ @<cStdOut> ], [ @<cStdErr> ], ;
                  [ <lDetach> ] ) --> <nResult> */
   nRet := hb_processRun( cCommand, NIL, @cStdOut, @cStdErr, lAsync )
ENDIF

? cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr

   IF nRet == 0
      ? "run1", cCommand  + " : " + cStdOut + " : " + cStdErr 
   ELSE
         ? "run1", cCommand  + " " + " : " + cStdOut + " : " + cStdErr
         cPrefixCmd := get_run_prefix_cmd( cCommand )

      // #ifdef __PLATFORM__UNIX
      IF lAsync
         nRet := __run_system( cPrefixCmd + cCommand + "&" )
      ELSE
         nRet := hb_processRun( cPrefixCmd + cCommand, NIL, @cStdOut, @cStdErr )
      ENDIF
      // # else
      // nRet := hb_processRun( cPrefixCmd + cCommand, NIL, @cStdOut, @cStdErr, lAsync )
      // #endif
      ? cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr


      IF nRet == 0
         ? "run2", cPrefixCmd + cCommand + " : " + cStdOut + " : " + cStdErr
      ELSE
         ? "run2", cPrefixCmd + cCommand  + " : " + cStdOut + " : " + cStdErr

         nRet := __run_system( cCommand )  // npr. copy komanda trazi system run a ne hbprocess run
         ? cCommand, nRet, "stdout:", cStdOut, "stderr:", cStdErr
         IF nRet <> 0
            ? "run3", cCommand + " : " + cStdOut + " : " + cStdErr
            cMsg := "ERR run cmd: " + cCommand + " : " + cStdOut + " : " + cStdErr
            ? cMsg, 2
         ENDIF

      ENDIF

   ENDIF

   IF ValType( hOutput ) == "H"
         hOutput[ "stdout" ] := cStdOut // hash matrica
         hOutput[ "stderr" ] := cStdErr
   ENDIF

   RETURN nRet



FUNCTION get_run_prefix_cmd( cCommand, lAsync )

   LOCAL cPrefix

   hb_default( @lAsync, .F. )


   IF cCommand != NIL .AND. Left( cCommand, 9 ) == "xdg-open "
      cPrefix := ""
   ELSE
      cPrefix := "xdg-open "
   ENDIF
    
 

   IF cCommand != NIL .AND. Left( cCommand, 4 ) == "java"
      cPrefix := "" // if java ..., ne treba start
   ENDIF

   IF cCommand != NIL .AND. Left( cCommand, 10 ) == "f18_editor"
         cPrefix := ""
   ENDIF


   RETURN cPrefix



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
