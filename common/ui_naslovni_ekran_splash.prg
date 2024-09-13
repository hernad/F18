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


FUNCTION naslovni_ekran_splash_screen( cNaslov, cVer )

   //LOCAL lInvert
   LOCAL nWin
   LOCAL nXStart, nYStart


   nXStart := MAXROW() / 2 - 10
   nYStart := MAXCOL() / 2 - 30

   nWin := WOpen( nXStart, nYStart, nXStart + 20, nYStart + 70 )
   WBox()

   WSelect( nWin )
   //SetColor( f18_color_invert() )
   DispBox( 0, 0, MaxRow(), MaxCol(), Replicate( " ", 9 ) )
   SetPos( 0, 0 )

   //Box( , 12, 60, lInvert )
   set_cursor_off()

   @  2, 2 SAY PadC( cNaslov, 60 )
   @  3, 2 SAY PadC( "Verzija: " + cVer, 60 )
   @  5, 2 SAY PadC( "bring.out d.o.o. Sarajevo (" + f18_dev_period() + ")", 60 )
   @  7, 2 SAY PadC( "Juraja Najtharta 3, Sarajevo, BiH", 60 )
   @  8, 2 SAY PadC( "tel: 061/477-105, 061/141-311", 60 )
   // @  9, 2 SAY PadC( "web: http://bring.out.ba", 60 )
   @ 10, 2 SAY PadC( "email: podrska@bring.out.ba", 60)

  Inkey( 5 )

  WClose( nWin )

#ifdef F18_DEBUG
   ?E  "maxrow: " + hb_valToStr(MaxRow()) + " maxcol: " + hb_valToStr(MaxCol())
#endif
   //BoxC()

   RETURN .T.
