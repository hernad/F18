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

STATIC s_cUtilName := "psql"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/f18_editor/
STATIC s_cProg // windows: run.cmd

#ifdef __PLATFORM__WINDOWS
STATIC s_cSHA256sum := "3ef67ef61f05255f59551396b93238201f778f7b933cb677f56d01356cfb9672"  // psql/run.cmd 0002
#else
STATIC s_cSHA256sum := "XX"
#endif



FUNCTION pg_dump_cmd( cTxt )

   LOCAL cCmd

   check_prog_download()

   IF !is_windows()
      cCmd := "pg_dump"
   ELSE
      cCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg + " pg_dump"
      IF ! File( s_cDirF18Util + s_cUtilName + SLASH + s_cProg )
         ?E "Error NO CMD: " + s_cDirF18Util + s_cUtilName + SLASH + s_cProg + "!? STOP"
         RETURN "psql_no_run_cmd"
      ENDIF
   ENDIF

   RETURN cCmd


STATIC FUNCTION check_prog_download()

   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload := .F.
   LOCAL cDownloadRazlog := "FILE"

   IF !is_windows()
      RETURN .T.
   ENDIF

   IF s_cDirF18Util == NIL
      s_cDirF18Util := f18_exe_path() + "F18_util" + SLASH
      s_cProg := "run" + iif( is_windows(), ".cmd", "" )
   ENDIF

   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + "_" + get_platform() + ".zip"

   IF DirChange( s_cDirF18Util ) != 0
      IF MakeDir( s_cDirF18Util ) != 0
         ?E "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP"
         RETURN .F.
      ENDIF
   ENDIF

   lDownload :=  !File( s_cDirF18Util + s_cUtilName + SLASH + s_cProg )
   IF !lDownload
      cMySum := sha256sum( s_cDirF18Util + s_cUtilName + SLASH + s_cProg )
      IF ( cMySum !=  s_cSHA256sum )
         ?E s_cUtilName + " sha256sum " + s_cDirF18Util + s_cUtilName + SLASH + s_cProg + "## local:" + cMySum + "## remote:" + s_cSHA256sum
         lDownload := .T.
         cDownloadRazlog := "SUM"
      ENDIF
   ENDIF

   IF lDownload
      //IF cDownloadRazlog == "SUM" .AND. Pitanje(, "Downloadovati " + s_cProg + " novu verzija?", "D" ) == "N"
      //   lDownload := .F.
      //ENDIF

      //IF lDownload
         cZip := download_file( cUrl, NIL )
         IF !Empty( cZip )
            unzip_files( cZip, "", s_cDirF18Util, {}, .T. )
         ELSE
            MsgBeep( "Error download " + s_cProg + "##" + cUrl )
         ENDIF
      //ENDIF
   ENDIF

   IF lDownload .AND. sha256sum( s_cDirF18Util + s_cUtilName + SLASH + s_cProg ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + s_cDirF18Util + s_cUtilName + SLASH + s_cProg  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
