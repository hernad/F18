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
#include "f18_color.ch"

REQUEST ARRAYRDD

STATIC aErrors := {}
STATIC aInfos := {}


FUNCTION empty_info_bar()

   aErrors := {}

   RETURN .T.


FUNCTION empty_error_bar()

   aInfos := {}

   RETURN .T.



FUNCTION info_bar( cDoc, cMsg )

   LOCAL lPrinter, lConsole, cDevice, nCursor

   hb_default( @cMsg, "" )

   nCursor := SetCursor()
   lPrinter :=  Set( _SET_PRINTER,  .F. )
   lConsole := Set( _SET_CONSOLE, .T. )
   cDevice := Set( _SET_DEVICE, "SCREEN" )

   // SET DEVICE TO PRINTER

   // SET PRINTER TO ( cFileName )
   // SET PRINTER ON
   set_cursor_off()

   @ f18_max_rows(), 1 SAY8  "> " + PadC( Left( cMsg, MaxCol() - 6 ), MaxCol() - 5 ) + " <" COLOR F18_COLOR_INFO_PANEL

   IF Empty( cMsg ) .OR. cMsg == "info_bar"
      RETURN .T.
   ENDIF

   Set( _SET_PRINTER,  lPrinter )
   Set( _SET_CONSOLE, lConsole )
   Set( _SET_DEVICE, cDevice )
   SetCursor( nCursor )

   IF Len( aInfos ) > INFO_MESSAGES_LENGTH
      ADel( aInfos, 1 )
      ASize( aInfos, Len( aInfos ) - 1 )
   ENDIF
   AAdd( aInfos, { Time(), cDoc, cMsg } )

   RETURN .T.



FUNCTION error_bar( cDoc, cMsg )

   LOCAL lPrinter, lConsole, cDevice

   // Beep( 2 )
   /* TODO:  : Object destructor failure ;

   1 (b)THREAD_DBF_REFRESH / 661
 2 TONE / 0
 3 BEEP / 433
 4 ERROR_BAR / 57
 5 FILL_DBF_FROM_SERVER / 436
 6 FULL_SYNCHRO / 82
 7 UPDATE_DBF_FROM_SERVER / 70
 8 DBF_REFRESH / 723
 9 THREAD_DBF_REFRESH / 662
 */

   hb_default( @cMsg, "" )

   lPrinter   :=  Set( _SET_PRINTER,  .F. )
   lConsole := Set( _SET_CONSOLE, .T. )
   cDevice := Set( _SET_DEVICE, "SCREEN" )

   @ f18_max_rows() + 1, 1 SAY8  "> " + PadC( Left( cMsg, MaxCol() - 6 ), MaxCol() - 5 ) + " <" ;
      COLOR iif( Empty( cMsg ), F18_COLOR_INFO_PANEL, F18_COLOR_ERROR_PANEL )

   Set( _SET_PRINTER,  lPrinter )
   Set( _SET_CONSOLE, lConsole )
   Set( _SET_DEVICE, cDevice )

   IF Empty( cMsg ) .OR. cMsg == "error_bar"
      RETURN .T.
   ENDIF

   IF Len( aErrors ) > ERROR_MESSAGES_LENGTH
      ADel( aErrors, 1 )
      ASize( aErrors, Len( aErrors ) - 1 )
   ENDIF
   AAdd( aErrors, { Time(), cDoc, cMsg } )

   RETURN .F.  // ako se koristi u validaciji treba da vrati .F.


FUNCTION show_infos()

   LOCAL cScr

   PushWA()

   dbCreate( "a_infos.dbf", a_struct(), "ARRAYRDD", .T., "a_infos" ) // Create it and leave opened
   AEval( aInfos, {| item |  dbAppend(), field->TIME := item[ 1 ], field->doc := item[ 2 ], field->MESSAGE := _u( item[ 3 ] ) } )
   SAVE SCREEN TO cScr
   IF Used()
      dbEdit()
   ELSE
      ?E "array rdd a_infos.dbf error !"
   ENDIF
   RESTORE SCREEN FROM cScr
   USE

   PopWa()

   RETURN .T.

FUNCTION show_errors()

   LOCAL cScr

   PushWa()

   dbCreate( "a_errors.dbf", a_struct(), "ARRAYRDD", .T., "a_errors" )
   AEval( aErrors, {| item |  dbAppend(), field->TIME := item[ 1 ], field->doc := item[ 2 ], field->MESSAGE := _u( item[ 3 ] ) } )
   SAVE SCREEN TO cScr
   IF Used()
      dbEdit()
   ELSE
      ?E "array rdd a_errors.dbf error !"
   ENDIF
   RESTORE SCREEN FROM cScr
   USE

   PopWa()

   RETURN .T.




STATIC FUNCTION a_struct()

   RETURN { ;
      { "TIME", "C", 8, 0 }, ;
      { "DOC", "C", 18, 0 }, ;
      { "MESSAGE", "C", f18_max_cols() - 4 - 9 - 19, 0 } ;
      }
