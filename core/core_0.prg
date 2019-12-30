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


FUNCTION harbour_init()

   CLEAR SCREEN
   rddSetDefault( RDDENGINE )
   Set( _SET_AUTOPEN, .F.  )

   SET CENTURY OFF
   SET EPOCH TO 1980  // 81 - 1981,  79-2079
   SET DATE TO GERMAN

   f18_init_threads()
   Set( _SET_OSCODEPAGE, hb_cdpOS() )

// ? SET( _SET_OSCODEPAGE )

   hb_cdpSelect( "SL852" )
   // hb_SetTermCP( "SLISO" )

   SET DELETED ON

   SetCancel( .F. )
   
   MSetCursor( .T. )
   SET( _SET_EVENTMASK, HB_INKEY_ALL )

   SET DATE GERMAN
   SET SCOREBOARD OFF
   Set( _SET_CONFIRM, .T. )
   SET WRAP ON
   SET ESCAPE ON
   SET SOFTSEEK ON
   CLEAR TYPEAHEAD

   SetKey( K_F12, {|| k_f12() } )
   SetColor( f18_color_normal() )

   IF !is_electron_host()
      hb_idleAdd( {|| on_idle_dbf_refresh() } )  // BUG_CPU100
   ENDIF

   RETURN .T.


FUNCTION f18_ver_show( lShort )

   hb_default( @lShort, .T. )

   RETURN f18_ver() + + "/" + f18_harbour() + '/' + f18_arch() + iif( lShort, "", " " + f18_ver_date() )


FUNCTION f18_ver_info( lShort )

   RETURN "v(" + f18_ver( lShort ) + ")"


FUNCTION browse_dbf( cDbf )

   LOCAL cScr

   SAVE SCREEN TO cScr

   PushWA()
   SET SCOREBOARD ON
   my_dbSelectArea( cDbf )
   dbEdit()
   PopWA()
   RESTORE SCREEN FROM cScr

   RETURN Alias()


FUNCTION k_ctrl_f9()

   IF is_mac()
      RETURN hb_keyCode( "9" )
   ENDIF

   RETURN K_CTRL_F9

/*
    download_file( "http://download/test.zip", NIL ) => /home/bringout/.f18/wget_232X66.tmp

    ako je Error
*/

FUNCTION download_file( cUrl, cDestFile )

   LOCAL hFile
   LOCAL cFileName, lRet := .F.

   IF is_in_main_thread()
      Box( "#Download: " + AllTrim( Right( cUrl, 60 ) ), 2, 75 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY Left( cUrl, 72 )
   ELSE
      ?E "Download", cURL
   ENDIF
   
   // kreira se temp file
   hFile := hb_vfTempFile( @cFileName, my_home_root(), "wget_", ".tmp" )
   hb_vfClose( hFile )

   lRet := F18Admin():download_file( cUrl, "", cFileName )

   IF is_in_main_thread()
      BoxC()
   ENDIF

   IF lRet
      IF cDestFile != NIL
         COPY FILE ( cFileName ) TO ( cDestFile )
         RETURN cDestFile
      ELSE
         RETURN cFileName
      ENDIF
   ELSE
      RETURN ""
   ENDIF

   RETURN ""


FUNCTION get_platform()

   LOCAL cPlatform

   DO CASE
   CASE is_windows()
      cPlatform := "windows_386"
   CASE is_mac()
      cPlatform := "darwin_amd64"
   CASE is_linux()
      cPlatform := "linux_386"
   ENDCASE

   RETURN cPlatform


FUNCTION f18_exe_path()

   RETURN hb_FNameDir( hb_ProgName() )


FUNCTION f18_util_path()
   RETURN SLASH + ".." + SLASH + "F18_util" + SLASH

FUNCTION f18_template_path()
   RETURN SLASH + ".." + SLASH + "F18_template" + SLASH

FUNCTION f18_template_file_name( cTemplate )
   RETURN f18_exe_path() + f18_template_path() + cTemplate

FUNCTION is_gt_console()

#ifdef GT_DEFAULT_CONSOLE
   RETURN .T.
#else

   RETURN .F.
#endif


FUNCTION is_electron_host()

#ifdef ELECTRON_HOST
   RETURN .T.
#else

   RETURN .F.
#endif

/*
   my_rddname() -> "DBFCDX" ili "SQLMIX", IF default area used()
                   "unused", if !used()
*/
FUNCTION my_rddName()

   IF Used()
      RETURN rddName()
   ENDIF

   RETURN "unused"


// FUNCTION danasnji_datum()
// RETURN date()

/*
   Opis: vraća tekući datum sa servera

   danasnji_datum() => vraća vrijednost statičke varijable _datum

*/
FUNCTION danasnji_datum()

   RETURN datum_server()


FUNCTION set_cursor_on()

   LOCAL nCursor := SetCursor()

   IF nCursor == 0
       SetCursor( 1 )
   ENDIF

   Set( _SET_EVENTMASK, HB_INKEY_ALL )
   MSetCursor(.T.)

   RETURN .T.


FUNCTION set_cursor_off()

      LOCAL nCursor := SetCursor()
   
      IF nCursor <> 0
          // SetCursor( 1 )
          SetCursor( 0 )
          //MSetCursor(.F.)
      ENDIF
   
      RETURN .T.