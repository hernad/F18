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

STATIC s_nMainWindow


FUNCTION open_main_window()

   IF s_nMainWindow != NIL
      WClose( s_nMainWindow )
   ENDIF
   s_nMainWindow := WOpen( 0, 0, MaxRow(), MaxCol() )
   WSelect( s_nMainWindow )

   RETURN s_nMainWindow


FUNCTION ispisi_velikim_slovima( cIzn, nStartX, nYRight, cColor )

   LOCAL cChar, nCnt
   LOCAL nY, nX, cOldColor

   hb_default( @cColor, f18_color_normal() )

   cOldColor := SetColor( cColor )

   nY := box_y_koord() + nYRight
   FOR nCnt := Len ( cIzn ) TO 1 STEP -1
      cChar := SubStr ( cIzn, nCnt, 1 )
      nX := box_x_koord() + nStartX + 2

      DO CASE
      CASE cChar = "1"
         nY -= 8
         @ nX++, nY + 1 SAY8 "██"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY + 2 SAY8 "█"
         @ nX++, nY SAY8 "█████"
      CASE cChar = "2"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY + 6   SAY8 "█"
         @ nX++, nY + 6   SAY8 "█"
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "3"
         nY -= 8
         @ nX++, nY SAY8 " ██████"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 2 SAY8 "████"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "4"
         nY -= 8
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"

      CASE cChar = "5"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "███████"
         @ nX++, nY + 6   SAY8 "█"
         @ nX++, nY + 6   SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "6"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "█"
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "7"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 5    SAY8 "█"
         @ nX++, nY + 4   SAY8 "█"
         @ nX++, nY + 3  SAY8 "█"
         @ nX++, nY + 2  SAY8 "█"
         @ nX++, nY + 1 SAY8 "█"
         @ nX++, nY SAY8 "█"
      CASE cChar = "8"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY + 1 SAY8 "█████"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "9"
         nY -= 8
         @ nX++, nY SAY8 "███████"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY + 6     SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "███████"
      CASE cChar = "0"
         nY -= 8
         @ nX++, nY + 1 SAY8 "█████"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY SAY8 "█" ; @ Row(), Col() + 5 SAY8 "█"
         @ nX++, nY + 1 SAY8 "█████"
      CASE cChar = "."
         nY -= 4
         nX += 7
         @ nX, nY SAY8 "███"
      CASE cChar = "-"
         nY -= 6
         nX += 3
         @ nX, nY SAY8 "█████"
      ENDCASE
   NEXT

   SetColor( cOldColor )

   RETURN .T.
