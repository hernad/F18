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

STATIC saVrsteInvaliditeta := ;
      {                        ;
      "invalid rada",          ;
      "ratni vojni invalid",   ;
      "civilni invalid"        ;
      }

FUNCTION valid_stepen_invaliditeta( nStepen )

   nStepen := Round( nStepen, 0 )

   IF ( nStepen >= 0 )
      RETURN .T.
   ELSE
      MsgBeep( "Stepen invaliditeta: treba biti >= 0" )
   ENDIF

   RETURN .F.


FUNCTION valid_vrsta_invaliditeta( nVrsta )

   LOCAL cVrsta := get_vrsta_invaliditeta( nVrsta )
   LOCAL cTmp, cItem, nCnt

   IF ( Empty( cVrsta ) )
      cTmp := "Vrste invaliditeta:#"
      nCnt := 1
      FOR EACH cItem IN saVrsteInvaliditeta
         cTmp += Str( nCnt++, 2, 0 ) + "." + cItem + "#"
      NEXT
      MsgBeep( cTmp )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION get_vrsta_invaliditeta( nVrsta )

   IF nVrsta < 1 .OR. nVrsta > Len( saVrsteInvaliditeta )
      RETURN ""
   ENDIF

   RETURN saVrsteInvaliditeta[ nVrsta ]
