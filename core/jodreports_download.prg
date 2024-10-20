/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cUtilName := "jodreports"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/jod
STATIC s_cProg // jodreports/jodreports/jodreports-cli.jar


STATIC s_cSHA256sum := "cc6687a8e975f5f7802910ddb8658a5ea33f3adbcfe0b71f67431d8f880eec7f" // jodreports/jodreports-cli.jar


FUNCTION jodreports_cli()

   check_java_download()
   check_jodreports_download()

   RETURN s_cDirF18Util + s_cUtilName + SLASH + s_cProg


FUNCTION jodconverter_cli()

   check_java_download()
   check_jodreports_download()

   RETURN s_cDirF18Util + s_cUtilName + SLASH + "jodconverter-cli.jar"


FUNCTION check_jodreports_download()

   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload := .F.
   LOCAL cDownloadRazlog := "FILE"
   LOCAL cJodReportsCliCmd

   IF s_cDirF18Util == NIL
      s_cDirF18Util := f18_exe_path() + f18_util_path()
      s_cProg := "jodreports-cli.jar"
   ENDIF


   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + ".zip"

   IF DirChange( s_cDirF18Util ) != 0  // e.g. $HOME/F18/F18_util
      IF MakeDir( s_cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   cJodReportsCliCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg
   lDownload :=  !File( cJodReportsCliCmd )
   IF !lDownload
      cMySum := sha256sum( cJodReportsCliCmd )
      IF ( cMySum !=  s_cSHA256sum )
         MsgBeep( s_cProg + " sha256sum " + cJodReportsCliCmd + "## local:" + cMySum + "## remote:" + s_cSHA256sum )
         lDownload := .T.
         cDownloadRazlog := "SUM"
      ENDIF
   ENDIF

   IF lDownload
      IF cDownloadRazlog == "SUM" .AND. Pitanje(, "Downloadovati " + s_cProg + " novu verzija?", "D" ) == "N"
         lDownload := .F.
      ENDIF

      IF lDownload
         cZip := download_file( cUrl, NIL )
         IF !Empty( cZip )
            unzip_files( cZip, "", s_cDirF18Util, {}, .T. )
         ELSE
            MsgBeep( "Error download " + s_cProg + "##" + cUrl )
         ENDIF
      ENDIF
   ENDIF

   IF lDownload .AND. sha256sum( cJodReportsCliCmd ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + cJodReportsCliCmd  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
