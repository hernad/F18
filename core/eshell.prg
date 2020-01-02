#include "f18.ch"

FUNCTION eshell_cmd( cCmd, cFile )


   IF cFile == NIL
      cFile := ""
   ENDIF
   
   hb_gtInfo( HB_GTI_WINTITLE, "[vscode#" + cCmd + "]" + cFile + "[vscode#end]" )

   RETURN .T.
