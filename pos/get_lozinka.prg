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

FUNCTION pos_get_lozinka( nSiflen )

   LOCAL cKorsif, nChar

   cKorsif := ""
   Box(, 2, 30 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "POS Lozinka: "

   DO WHILE .T.

      nChar := Inkey( 0 )
#ifdef F18_DEBUG
      ?E "pos_get_lozinka", nChar
#endif

      IF nChar == K_ESC
         cKorsif := ""

      ELSEIF nChar == K_F12
         k_f12()

      ELSEIF nChar == K_F1
         k_f1()

      ELSEIF ( nChar == 0 ) .OR. ( nChar > 128 )
         LOOP

      ELSEIF ( nChar == K_ENTER )
         EXIT

      ELSEIF ( nChar == K_BS )
         cKorSif := Left( cKorsif, Len( cKorsif ) - 1 )

      ELSE

         IF Len( cKorsif ) >= nSifLen // max 15 znakova
            Beep( 1 )
         ENDIF

         IF ( nChar > 1 )
            cKorsif := cKorSif + Chr( nChar )
         ENDIF

      ENDIF

      @ box_x_koord() + 2, box_y_koord() + 15 SAY PadR( Replicate( "*", Len( cKorSif ) ), nSifLen )
      IF ( nChar == K_ESC )
         LOOP
      ENDIF

   ENDDO

   BoxC()

   set_cursor_on()

   RETURN PadR( cKorSif, nSifLen )
