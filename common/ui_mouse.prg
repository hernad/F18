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

/*
   lMouseOver - .T. - dovoljno je da je mouse na poziciji dugmeta
*/

FUNCTION MINRECT( nTop, nLeft, nBott, nRight, lMouseOver )

   LOCAL lInside := .F.
   LOCAL nKey

   hb_default( @lMouseOver, .T. )

   IF MRow() >= nTop .AND. MRow() <= nBott
      IF MCol() >= nLeft .AND. MCol() <= nRight
         IF lMouseOver
            lInside := .T.
         ELSE
            nKey := Inkey( 0.1, hb_bitOr( INKEY_LDOWN, INKEY_LUP  ) )
            IF nKey == K_LBUTTONDOWN
               lInside := .T.
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN( lInside )
