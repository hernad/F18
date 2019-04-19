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

STATIC s_cUtilName := "pdf"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/LO/
STATIC s_cProg // windows: lo.cmd, darwin: lo

#ifdef __PLATFORM__WINDOWS
STATIC s_cSHA256sum := "7c983e88a4f3ee60035db62957aaf2380714b2be264a8fae852fda082c22664a"  // pdf/pdf.cmd
#endif


FUNCTION PDF_open_dokument( cFile )

   LOCAL cCmd, nRet

   IF is_in_eshell()
      eshell_cmd( "pdf.view", cFile )
      RETURN 0
   ENDIF

   IF is_windows()
      cCmd := PDF_cmd()
      nRet := windows_run_invisible( cCmd, cFile )
   ELSE
      nRet := f18_open_mime_document( cFile )
   ENDIF

   RETURN nRet



FUNCTION PDF_cmd()

   check_PDF_download()

   RETURN s_cDirF18Util + s_cUtilName + SLASH + s_cProg

FUNCTION check_PDF_download()

   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload := .F.
   LOCAL cDownloadRazlog := "FILE"
   LOCAL cPDFCmd

   IF s_cDirF18Util == NIL
      s_cDirF18Util := f18_exe_path() + f18_util_path()
      s_cProg := "pdf" + iif( is_windows(), ".cmd", "" )
   ENDIF

   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + "_" + get_platform() + ".zip"

   IF DirChange( s_cDirF18Util ) != 0  // e.g. $HOME/F18/F18_util
      IF MakeDir( s_cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   cPDFCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg
   lDownload :=  !File( cPDFCmd )
   IF !lDownload
      cMySum := sha256sum( cPDFCmd )
      IF ( cMySum !=  s_cSHA256sum )
         MsgBeep( s_cProg + " sha256sum " + cPDFCmd + "## local:" + cMySum + "## remote:" + s_cSHA256sum )
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

   IF lDownload .AND. sha256sum( cPDFCmd ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + cPDFCmd  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
