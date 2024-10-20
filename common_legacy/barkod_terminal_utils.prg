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




// -----------------------------------------------------
// puni matricu sa redom csv formatiranog
// -----------------------------------------------------
FUNCTION csvrow2arr( cRow, cDelimiter )

   LOCAL aArr := {}
   LOCAL i
   LOCAL cTmp := ""
   LOCAL cWord := ""
   LOCAL nStart := 1

   FOR i := 1 TO Len( cRow )

      cTmp := SubStr( cRow, nStart, 1 )

      // ako je cTmp = ";" ili je iscurio niz - kraj stringa
      IF cTmp == cDelimiter .OR. i == Len( cRow )

         // ako je iscurio - dodaj i zadnji karakter u word
         IF i == Len( cRow )
            cWord += cTmp
         ENDIF

         // dodaj u matricu
         AAdd( aArr, cWord )
         cWord := ""

      ELSE
         cWord += cTmp
      ENDIF

      ++ nStart

   NEXT

   RETURN aArr


// ----------------------------------------------
// vraca numerik na osnovu txt polja
// ----------------------------------------------
FUNCTION _g_num( cVal )

   cVal := StrTran( cVal, ",", "." )

   RETURN Val( cVal )
