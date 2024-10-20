/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

CLASS Unicode

   METHOD New( xVal, lUtf8 )
   METHOD SET( xVal, lUtf8 )
   METHOD getString()
   METHOD getCpString()
   METHOD PadR( nNum )
   METHOD is_unicode()
   METHOD toScreen()
   DATA lUtf8
   DATA cString

ENDCLASS

METHOD Unicode:New( xVal, lUtf8 )

   ::lUtF8 := .T.

   ::Set( xVal, lUtf8 )

   RETURN Self

METHOD Unicode:is_unicode()

   RETURN ::lUtf8


METHOD Unicode:getString()

   LOCAL cRet

   IF ::lUtf8
      cRet := ::cString
   ELSE
      cRet := hb_StrToUTF8( ::cString )
   ENDIF

   RETURN cRet


METHOD Unicode:getCpString()

   LOCAL cRet

   IF ::lUtf8
      cRet := hb_UTF8ToStr( ::cString )
   ELSE
      cRet := ::cString
   ENDIF

   RETURN cRet


/*
   oUnicode:toScreen() => prikazuje naša slova na ekran
*/

METHOD Unicode:toScreen()

   RETURN ::getCpString()


METHOD Unicode:PadR( nNum )

   LOCAL cStr := ::getCpString()

   // pretvori u CP string, pa ga PadR-aj, pa ga vrati kao UTF-8

   RETURN hb_StrToUTF8( PadR( cStr, nNum ) )


METHOD Unicode:Set( xVal, lUtf8 )

   IF lUtf8 == NIL
      lUtf8 := .T.
   ENDIF


   SWITCH ValType( xVal )
   CASE "C"
      ::cString := xVal
      ::lUtf8 := lUtf8
      EXIT

   CASE "O"
      ::cString := xVal:getString()
      ::lUtf8 := .T.
      EXIT

   OTHERWISE
      ::cString := NIL

   END SWITCH

   RETURN .T.


FUNCTION PadrU( xStr, nNum )

  LOCAL uStr

  // utf8 string vraća padr
  uStr := Unicode():New( xStr ):padr( nNum )

  RETURN hb_Utf8ToStr( uStr )
