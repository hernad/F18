#include "f18.ch"


STATIC s_cF18Verzija
STATIC s_cF18Varijanta
STATIC s_cF18VerzijaKanal
STATIC s_cDownloadVersion := NIL
STATIC s_cCheckUpdates := NIL

/*
   lForceRefresh - force refresh verzije sa interneta
*/

FUNCTION download_version( cUrl, lForceRefresh )

   LOCAL hFile
   LOCAL cFileName, oFile, cRead
   LOCAL pRegex := hb_regexComp( "(\d+).(\d+).(\d+)" )
   LOCAL aMatch

   hb_default( @lForceRefresh, .F. )

   IF !lForceRefresh .AND. s_cDownloadVersion != NIL
      RETURN s_cDownloadVersion
   ENDIF

   Box( "#Download VERSION", 2, 70 )
   hFile := hb_vfTempFile( @cFileName, my_home_root(), "wget_", ".txt" )
   hb_vfClose( hFile )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY Left( cUrl, 67 )

   IF !F18Admin():wget_download( cUrl, "",  cFileName )
      BoxC()
      RETURN ""
   ENDIF

   oFile := TFileRead():New( cFileName )
   oFile:Open()
   IF oFile:Error()
      BoxC()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFileName ) )
      RETURN ""
   ENDIF
   cRead := oFile:ReadLine()
   oFile:Close()
   FErase( cFileName )

   BoxC()

   aMatch := hb_regex( pRegex, cRead )
   IF Len( aMatch ) < 4 // aMatch[1]="2.3.500" aMatch[2]="2", aMatch[3]="3", aMatch[4]="500"
      MsgBeep( "VERSION format error (" + cRead + ")"  )
      RETURN ""
   ENDIF

   IF !Empty( cRead )
      s_cDownloadVersion := cRead
   ENDIF

   RETURN cRead


PROCEDURE f18_update_available_version()

   download_version( f18_download_url() + "/" + f18_version_file(), .T. )  // .T. - force refresh

   RETURN

FUNCTION f18_available_version()

   IF s_cDownloadVersion == NIL
      RETURN "0.0.0"
   ENDIF

   RETURN s_cDownloadVersion


FUNCTION f18_builtin_version_h()
   RETURN f18_version_h( f18_ver() )

FUNCTION f18_available_version_h()
   RETURN f18_version_h( f18_available_version() )

FUNCTION f18_version_h( cVersion )

   LOCAL pRegex := hb_regexComp( "(\d+).(\d+).(\d+)" )
   LOCAL aMatch
   LOCAL hVer := hb_Hash()

   aMatch := hb_regex( pRegex, cVersion )

   IF Len( aMatch ) > 0 // aMatch[1]="2.3.500" aMatch[2]="2", aMatch[3]="3", aMatch[4]="500"
      hVer[ "major" ] := Val( aMatch[ 2 ] )
      hVer[ "minor" ] := Val( aMatch[ 3 ] )
      hVer[ "patch" ] := Val( aMatch[ 4 ] )
   ENDIF

   RETURN hVer



FUNCTION f18_preporuci_upgrade( cVersion )

   LOCAL hVersion, hAvailableVersion

   IF !check_updates()
      cVersion := "0.0.0"
      RETURN .F.
   ENDIF

   cVersion := download_version( f18_download_url() + "/" + f18_version_file() )

   IF Empty( cVersion )
      cVersion := "0.0.0"
      RETURN .F.
   ENDIF

   IF cVersion == f18_ver()
      RETURN .F.
   ENDIF

   hVersion := f18_builtin_version_h()
   hAvailableVersion := f18_available_version_h()

   IF hVersion[ "major" ] != hAvailableVersion[ "major" ]
      RETURN .T.
   ENDIF
   IF hVersion[ "minor" ] != hAvailableVersion[ "minor" ]
      RETURN .T.
   ENDIF

   IF hVersion[ "patch" ] > hAvailableVersion[ "patch" ]
      RETURN .F. // ne raditi downgrade"
   ENDIF

   RETURN .T.



FUNCTION check_updates()

   IF s_cCheckUpdates == NIL // prvi poziv
      s_cCheckUpdates := fetch_metric( "F18_check_updates", my_user(), "D" )
   ELSE
      s_cCheckUpdates := "N" // nakon prvog poziva ne nuditi vise upgrade
   ENDIF

   RETURN s_cCheckUpdates == "D"



FUNCTION f18_verzija()

   IF s_cF18Verzija == NIL
      s_cF18Verzija := AllTrim( fetch_metric( "F18_verzija", NIL, F18_VERZIJA ) )
   ENDIF

   RETURN s_cF18Verzija


/*
   S - standard
   E - edge
   X - experiment
*/

FUNCTION f18_verzija_kanal()

   IF s_cF18VerzijaKanal == NIL
      s_cF18VerzijaKanal := AllTrim( fetch_metric( "F18_verzija_kanal", my_user(), "S" ) )
   ENDIF

   RETURN s_cF18VerzijaKanal



FUNCTION f18_varijanta()

   IF s_cF18Varijanta == NIL
      s_cF18Varijanta := AllTrim( fetch_metric( "F18_varijanta", NIL, F18_VARIJANTA ) )
   ENDIF

   RETURN s_cF18Varijanta


FUNCTION f18_varijanta_builtin()

   RETURN F18_VARIJANTA


/*
    za Verzija=3 => "https://raw.github.com/knowhow/F18_knowhow/3"
*/

FUNCTION f18_download_url()

   RETURN F18_GITHUB_DOWNLOAD_BASE_URL + f18_verzija() + "-" + f18_varijanta()


/*
   github/knowhow/F18_knowhow/branch/VERSION - stabilna Verzija
   github/knowhow/F18_knowhow/branch/VERSION_E - posljednja (edge) verzija
   github/knowhow/F18_knowhow/branch/VERSION_X - eXperimentalna verzija

*/

FUNCTION f18_version_file()

   LOCAL cFile := "VERSION"

   IF f18_verzija_kanal() $ "E X"
      cFile := cFile + "_" + f18_verzija_kanal()
   ENDIF

   RETURN cFile
