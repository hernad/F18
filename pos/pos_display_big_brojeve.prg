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

FUNCTION gSjeciStr()

   IF gPrinter == "R"
      Beep( 1 )
      FF
   ELSE
      QQOut( gSjeciStr )
   ENDIF

   RETURN .T.



FUNCTION gOtvorStr()

   IF gPrinter <> "R"
      QQOut( gOtvorStr )
   ENDIF

   RETURN .T.



FUNCTION PaperFeed()

   FOR i := 1 TO nFeedLines
      ?
   NEXT
   IF gPrinter == "R"
      Beep( 1 )
      FF
   ELSE
      gSjeciStr()
   ENDIF

   RETURN .T.



FUNCTION IncID( cId, cPadCh )

   IF cPadCh == nil
      cPadCh := " "
   ELSE
      cPadCh := cPadCh
   ENDIF

   RETURN ( PadL( Val( AllTrim( cID ) ) + 1, Len( cID ), cPadCh ) )


FUNCTION DecID( cId, cPadCh )

   IF cPadCh == nil
      cPadCh := " "
   ELSE
      cPadCh := cPadCh
   ENDIF

   RETURN ( PadL( Val( AllTrim( cID ) ) - 1, Len( cID ), cPadCh ) )



FUNCTION pos_set_naziv_domaca_valuta()

   // LOCAL lOpened

   select_o_valute()
   PushWA()

   // lOpened := .T.

   // IF !Used()
   // o_valute()
   // lOpened := .F.
   // ENDIF

   SET ORDER TO TAG "NAZ"
   GO TOP

   Seek2( "D" )
   gDomValuta := AllTrim( naz2 )

   GO TOP

   PopWA()

   RETURN .T.


FUNCTION ispis_veliki_brojevi_iznos( nIznos, nRow, nCol )

   LOCAL cIznos
   LOCAL nCnt, cChar, nNextY
   LOCAL nColClean

   IF nCol == nil
      nCol := 76
   ENDIF

   cIznos := AllTrim( Transform( nIznos, "9999999.99" ) )
   nNextY := box_y_koord() + nCol

   nColClean := ( f18_max_cols() - 1 ) / 2

   @ box_x_koord() + nRow + 0, nColClean SAY PadR( "", nColClean )
   @ box_x_koord() + nRow + 1, nColClean SAY PadR( "", nColClean )
   @ box_x_koord() + nRow + 2, nColClean SAY PadR( "", nColClean )
   @ box_x_koord() + nRow + 3, nColClean SAY PadR( "", nColClean )
   @ box_x_koord() + nRow + 4, nColClean SAY PadR( "", nColClean )

   FOR nCnt := Len( cIznos ) TO 1 STEP -1

      cChar := SubStr( cIznos, nCnt, 1 )

      DO CASE
         // https://en.wikipedia.org/wiki/Block_Elements

      CASE cChar = "1"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 " ██"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "  █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "  █"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "  █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 " ██"

      CASE cChar = "2"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "█"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "3"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 " ███"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "4"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "█"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "   █"

      CASE cChar = "5"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "6"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "7"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "  █"
         @ box_x_koord() + nRow + 3, nNextY SAY8 " █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "█"

      CASE cChar = "8"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 " ██ "
         @ box_x_koord() + nRow + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "9"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "   █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "0"

         nNextY -= 5
         @ box_x_koord() + nRow + 0, nNextY SAY8 "████"
         @ box_x_koord() + nRow + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 2, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + nRow + 4, nNextY SAY8 "████"

      CASE cChar = "."

         nNextY -= 2
         @ box_x_koord() + nRow + 4, nNextY SAY8 "█"

      CASE cChar = "-"

         nNextY -= 4
         @ box_x_koord() + nRow + 2, nNextY SAY8 "███"

      ENDCASE
   NEXT

   RETURN .T.


FUNCTION ispisi_iznos_racuna_box( nIznos )

   LOCAL cIzn
   LOCAL nCnt, Char, NextY
   LOCAL nPrevRow := Row()
   LOCAL nPrevCol := Col()

   SetPos ( 0, 0 )

   BOX (, 9, 77 )

   cIzn := AllTrim ( Transform ( nIznos, "9999999.99" ) )

   @ box_x_koord(), box_y_koord() + 28 SAY8 "  nIznos RAČUNA JE  " COLOR f18_color_invert()

   NextY := box_y_koord() + 76

   FOR nCnt := Len ( cIzn ) TO 1 STEP -1
      Char := SubStr ( cIzn, nCnt, 1 )
      DO CASE
      CASE Char = "1"
         NextY -= 6
         @ box_x_koord() + 2, NextY SAY8 " ██"
         @ box_x_koord() + 3, NextY SAY8 "  █"
         @ box_x_koord() + 4, NextY SAY8 "  █"
         @ box_x_koord() + 5, NextY SAY8 "  █"
         @ box_x_koord() + 6, NextY SAY8 "  █"
         @ box_x_koord() + 7, NextY SAY8 "  █"
         @ box_x_koord() + 8, NextY SAY8 "  █"
         @ box_x_koord() + 9, NextY SAY8 "█████"
      CASE Char = "2"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "      █"
         @ box_x_koord() + 4, NextY SAY8 "      █"
         @ box_x_koord() + 5, NextY SAY8 "███████"
         @ box_x_koord() + 6, NextY SAY8 "█"
         @ box_x_koord() + 7, NextY SAY8 "█"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "3"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 " ██████"
         @ box_x_koord() + 3, NextY SAY8 "      █"
         @ box_x_koord() + 4, NextY SAY8 "      █"
         @ box_x_koord() + 5, NextY SAY8 "  ████"
         @ box_x_koord() + 6, NextY SAY8 "      █"
         @ box_x_koord() + 7, NextY SAY8 "      █"
         @ box_x_koord() + 8, NextY SAY8 "      █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "4"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "█"
         @ box_x_koord() + 3, NextY SAY8 "█"
         @ box_x_koord() + 4, NextY SAY8 "█     █"
         @ box_x_koord() + 5, NextY SAY8 "█     █"
         @ box_x_koord() + 6, NextY SAY8 "███████"
         @ box_x_koord() + 7, NextY SAY8 "      █"
         @ box_x_koord() + 8, NextY SAY8 "      █"
         @ box_x_koord() + 9, NextY SAY8 "      █"
      CASE Char = "5"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "█"
         @ box_x_koord() + 4, NextY SAY8 "█"
         @ box_x_koord() + 5, NextY SAY8 "███████"
         @ box_x_koord() + 6, NextY SAY8 "      █"
         @ box_x_koord() + 7, NextY SAY8 "      █"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "6"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "█"
         @ box_x_koord() + 4, NextY SAY8 "█"
         @ box_x_koord() + 5, NextY SAY8 "███████"
         @ box_x_koord() + 6, NextY SAY8 "█     █"
         @ box_x_koord() + 7, NextY SAY8 "█     █"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "7"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "      █"
         @ box_x_koord() + 4, NextY SAY8 "     █"
         @ box_x_koord() + 5, NextY SAY8 "    █"
         @ box_x_koord() + 6, NextY SAY8 "   █"
         @ box_x_koord() + 7, NextY SAY8 "  █"
         @ box_x_koord() + 8, NextY SAY8 " █"
         @ box_x_koord() + 9, NextY SAY8 "█"
      CASE Char = "8"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "█     █"
         @ box_x_koord() + 4, NextY SAY8 "█     █"
         @ box_x_koord() + 5, NextY SAY8 " █████ "
         @ box_x_koord() + 6, NextY SAY8 "█     █"
         @ box_x_koord() + 7, NextY SAY8 "█     █"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "9"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 "███████"
         @ box_x_koord() + 3, NextY SAY8 "█     █"
         @ box_x_koord() + 4, NextY SAY8 "█     █"
         @ box_x_koord() + 5, NextY SAY8 "███████"
         @ box_x_koord() + 6, NextY SAY8 "      █"
         @ box_x_koord() + 7, NextY SAY8 "      █"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 "███████"
      CASE Char = "0"
         NextY -= 8
         @ box_x_koord() + 2, NextY SAY8 " █████ "
         @ box_x_koord() + 3, NextY SAY8 "█     █"
         @ box_x_koord() + 4, NextY SAY8 "█     █"
         @ box_x_koord() + 5, NextY SAY8 "█     █"
         @ box_x_koord() + 6, NextY SAY8 "█     █"
         @ box_x_koord() + 7, NextY SAY8 "█     █"
         @ box_x_koord() + 8, NextY SAY8 "█     █"
         @ box_x_koord() + 9, NextY SAY8 " █████"
      CASE Char = "."
         NextY -= 4
         @ box_x_koord() + 9, NextY SAY8 "███"
      CASE Char = "-"
         NextY -= 6
         @ box_x_koord() + 5, NextY SAY8 "█████"
      ENDCASE
   NEXT

   SetPos ( nPrevRow, nPrevCol )

   RETURN .T.



FUNCTION NazivRobe( cIdRoba )

   LOCAL nCurr := Select()

   select_o_roba( cIdRoba )
   SELECT nCurr

   RETURN ( roba->Naz )



FUNCTION Godina_2( dDatum )

   // 01.01.99 -> "99"
   // 01.01.00 -> "00"

   RETURN PadL( AllTrim( Str( Year( dDatum ) % 100, 2, 0 ) ), 2, "0" )
