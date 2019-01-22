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

STATIC s_cUtilName := "java"
STATIC s_cDirF18Util  // e.g. /home/hernad/F18/F18_util/java/
STATIC s_cProg // windows: java.cmd, darwin: java
STATIC s_cJavaOpts := "-Xmx128m"

#ifdef __PLATFORM__DARWIN
STATIC s_cSHA256sum := "27f6ebb02ba92889dead894dc1e19b948f58577951372e74ce9eebfeca947f80"
#endif

#ifdef __PLATFORM__WINDOWS
STATIC s_cSHA256sum :=  "1b69cb6f4e65acf52443b090c08e377b6366f1a21626f9907ecc3ddb891fe588"
#endif

#ifdef __PLATFORM__LINUX
STATIC s_cSHA256sum :=  "c02daaf31a7098d7e71dca1d8325c00c528596d2a29530a097c6962be9087931"
#endif

FUNCTION java_version()

   LOCAL hOutput := hb_Hash(), pRegex, aMatch
   LOCAL hRet := hb_Hash()

   f18_run( java_cmd() + " -version", @hOutput )

   hRet[ "version" ] := "-1"
   hRet[ "name" ] := "JAVAERR"

   pRegex := hb_regexComp( 'java version "(.*)"' ) // java version "1.8.0_131"
   aMatch := hb_regex( pRegex, hOutput[ "stderr" ] )
   IF Len( aMatch ) > 0
      hRet[ "version" ] := aMatch[ 2 ]
      hRet[ "name" ] := "java"
   ENDIF

   pRegex := hb_regexComp( 'openjdk version "(.*)"' ) // java version "1.8.0_131"
   aMatch := hb_regex( pRegex, hOutput[ "stderr" ] )
   IF Len( aMatch ) > 0
      hRet[ "version" ] := aMatch[ 2 ]
      hRet[ "name" ] := "openjdk"
   ENDIF

   RETURN hRet



FUNCTION java_cmd()

   check_java_download()

   //IF is_linux()
    //  RETURN "java " + s_cJavaOpts
   //ENDIF

   // RETURN s_cDirF18Util + s_cUtilName + SLASH + s_cProg + " " + s_cJavaOpts

   RETURN s_cDirF18Util + s_cUtilName + SLASH + "bin" + ;
      SLASH + "java" + iif( is_windows(), ".exe", "" ) + " " + s_cJavaOpts


FUNCTION check_java_download()

   LOCAL cUrl
   LOCAL cZip
   LOCAL cVersion := F18_UTIL_VER
   LOCAL cMySum
   LOCAL lDownload := .F.
   LOCAL cDownloadRazlog := "FILE"
   LOCAL cJavaCmd

   IF s_cDirF18Util == NIL
      s_cDirF18Util := f18_exe_path() + f18_util_path()
      s_cProg := "java" + iif( is_windows(), ".cmd", "" )
   ENDIF


   cUrl := F18_UTIL_URL_BASE
   cUrl += cVersion + "/" + s_cUtilName + "_" + get_platform() + ".zip"

   IF DirChange( s_cDirF18Util ) != 0  // e.g. $HOME/F18/F18_util
      IF MakeDir( s_cDirF18Util ) != 0
         MsgBeep( "Kreiranje dir: " + s_cDirF18Util + " neuspješno?! STOP" )
         RETURN .F.
      ENDIF
   ENDIF

   cJavaCmd := s_cDirF18Util + s_cUtilName + SLASH + s_cProg
   lDownload :=  !File( cJavaCmd )
   IF !lDownload
      cMySum := sha256sum( cJavaCmd )
      IF ( cMySum !=  s_cSHA256sum )
         MsgBeep( s_cProg + " sha256sum " + cJavaCmd + "## local:" + cMySum + "## remote:" + s_cSHA256sum )
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

   IF lDownload .AND. sha256sum( cJavaCmd ) != s_cSHA256sum
      MsgBeep( "ERROR sha256sum: " + cJavaCmd  + "##" + s_cSHA256sum )
      RETURN .F.
   ENDIF

   RETURN .T.
