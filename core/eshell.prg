#include "f18.ch"

FUNCTION eshell_cmd( cCmd, cFile )

   LOCAL  nRow, nCol, cScr, lConsole

   lConsole := Set( _SET_CONSOLE, .T. )
   nRow := Row()
   nCol := Col()
   SAVE SCREEN TO cScr
   CLEAR SCREEN
   SetPRC( 0, 0 )
   @ 0, 0 SAY ""
   OutStd( "[vscode#" + cCmd + "]" + cFile + "[vscode#end]" )
   OutStd( "" )
   Inkey( 0.5 )
   RESTORE SCREEN FROM cScr
   SetPRC( nRow, nCol )
   @ nRow, nCol SAY ""
   Set( _SET_CONSOLE, lConsole )

   RETURN .T.
