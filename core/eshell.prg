#include "f18.ch"

FUNCTION eshell_cmd( cCmd, cFile )

   LOCAL  nRow, nCol, cScr, lConsole

   lConsole := Set( _SET_CONSOLE, .T. )
   nRow := Row()
   nCol := Col()
   SAVE SCREEN TO cScr
   // CLEAR SCREEN
   SetPRC( 0, 0 )
   // @ 0, 0 SAY ""
   Inkey( 0.05 )
   OutStd( "[vscode#" + cCmd + "]" + cFile + "[vscode#end]" )
   // OutStd( "" )
   // IF is_windows()
   // Inkey( 0.1 )
   // ENDIF
   RESTORE SCREEN FROM cScr
   SetPRC( nRow, nCol )
   @ nRow, nCol SAY ""

   Set( _SET_CONSOLE, lConsole )

   RETURN .T.
