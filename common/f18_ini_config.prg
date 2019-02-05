#include "f18.ch"

#define INI_FNAME "f18_config.ini"


FUNCTION f18_ini_config_read( cSection, hIniParams, lGlobalno )

   LOCAL cTmpIniSection
   LOCAL cTmpKey
   LOCAL cIniFile
   LOCAL cIniRead

   IF get_f18_param("run") != "<undefined>" // command line parametri, ignorisati ini
      RETURN .T.
   ENDIF

   IF ( lGlobalno == NIL ) .OR. ( lGlobalno == .F. )
      cIniFile := my_home() + INI_FNAME
   ELSE
      cIniFile := my_home_root() + INI_FNAME
   ENDIF

   IF !File( cIniFile )
      error_bar( "ini", "ini ne postoji: " + cIniFile )
      RETURN .F.
   ELSE
      cIniRead := hb_iniRead( cIniFile )
   ENDIF


   IF Empty( cIniRead )
      log_write( "Fajl je prazan: " + cIniFile )

   ELSE
      IF hb_HHasKey( cIniRead, cSection )

         cTmpIniSection := cIniRead[ cSection ]
         FOR EACH cTmpKey in hIniParams:Keys
            // napuni ini sa onim sto si procitao
            IF hb_HHasKey( cTmpIniSection, cTmpKey )
               hIniParams[ cTmpKey ] := cTmpIniSection[ cTmpKey ]
            ENDIF
         NEXT

      ENDIF
   ENDIF

   RETURN .T.


FUNCTION f18_ini_config_write( cSection, hIniParams, lGlobalno )

   LOCAL cTmpKey
   LOCAL cIniFile
   LOCAL cIniRead

   IF ( lGlobalno == NIL ) .OR. ( lGlobalno == .F. )
      cIniFile := my_home() + INI_FNAME
   ELSE
      cIniFile := my_home_root() + INI_FNAME
   ENDIF

   cIniRead := hb_iniRead( cIniFile )

   IF Empty( cIniRead )
      cIniRead := hb_Hash()
   ENDIF

   IF !hb_HHasKey( cIniRead, cSection )
      cIniRead[ cSection ] := hb_Hash()
   ENDIF

   // napuni cIniRead sa vrijednostima iz ini matrice
   FOR EACH cTmpKey in hIniParams:Keys
      cIniRead[ cSection ][ cTmpKey ] := hIniParams[ cTmpKey ]
   NEXT


   IF !hb_iniWrite( cIniFile, cIniRead, "#F18 config", "#end of config" )
      log_write( "Ne mogu snimiti ini fajl "  + cIniFile )
      RETURN .F.
   ENDIF

   RETURN .T.
