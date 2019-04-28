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

STATIC s_cUtilName := "yarg"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/yarg
STATIC s_cProg // windows: yarg/bin/yarg.bat, darwin: yarg/bin/yarg

#ifdef __PLATFORM__WINDOWS
STATIC s_cSHA256sum := "9e067c6ae624e34952074393d9d2ed8c4ac6fa58bcdbb9d0c6b9c5940c9856e0" // yarg/bin/yarg.bat
#endif

#ifdef __PLATFORM__UNIX
STATIC s_cSHA256sum := "28ebffd2a04408b95cf20ec55c07154847008eb34bd8e2e08a8dab0dbeb21243" // yarg/bin/yarg
#endif


FUNCTION yarg_cmd()

   check_java_download()
   check_yarg_download()

   RETURN s_cDirF18Util + s_cUtilName + SLASH + s_cProg

FUNCTION check_yarg_download()

   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload
   LOCAL cDownloadRazlog := "FILE"
   LOCAL cYargCmd

   IF s_cDirF18Util == NIL
      s_cDirF18Util := f18_exe_path() + f18_util_path()
      s_cProg := "bin" + SLASH + s_cUtilName + iif( is_windows(), ".bat", "" )
   ENDIF


   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + ".zip"

   IF DirChange( s_cDirF18Util ) != 0  // e.g. $HOME/F18/F18_util
      IF MakeDir( s_cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   cYargCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg
   lDownload := !File( cYargCmd )
   IF !lDownload
      cMySum := sha256sum( cYargCmd )
      IF ( cMySum !=  s_cSHA256sum )
         MsgBeep( s_cProg + " sha256sum " + cYargCmd + "## local:" + cMySum + "## remote:" + s_cSHA256sum )
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

   IF lDownload .AND. sha256sum( cYargCmd ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + cYargCmd  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
