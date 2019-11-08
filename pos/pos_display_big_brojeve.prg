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



FUNCTION SetNazDVal()

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

   Seek2( "P" )
   gStrValuta := AllTrim( naz2 )

   // IF !lOpened
   // USE
   // ENDIF

   PopWA()

   RETURN .T.



FUNCTION ispisi_donji_dio_forme_unosa( txt, row )

   IF row == nil
      row := 1
   ENDIF

   @ box_x_koord() + ( f18_max_rows() - 12 ) + row, 2 SAY PadR( txt, f18_max_cols() / 2 )

   RETURN .T.


FUNCTION ispisi_iznos_veliki_brojevi( iznos, row, col )

   LOCAL cIznos
   LOCAL nCnt, cChar, nNextY

   IF col == nil
      col := 76
   ENDIF

   cIznos := AllTrim( Transform( iznos, "9999999.99" ) )
   nNextY := box_y_koord() + col

   @ box_x_koord() + row + 0, f18_max_cols() / 2 SAY PadR( "", f18_max_cols() / 2 )
   @ box_x_koord() + row + 1, f18_max_cols() / 2 SAY PadR( "", f18_max_cols() / 2 )
   @ box_x_koord() + row + 2, f18_max_cols() / 2 SAY PadR( "", f18_max_cols() / 2 )
   @ box_x_koord() + row + 3, f18_max_cols() / 2 SAY PadR( "", f18_max_cols() / 2 )
   @ box_x_koord() + row + 4, f18_max_cols() / 2 SAY PadR( "", f18_max_cols() / 2 )

   FOR nCnt := Len( cIznos ) TO 1 STEP -1

      cChar := SubStr( cIznos, nCnt, 1 )

      DO CASE
         // https://en.wikipedia.org/wiki/Block_Elements

      CASE cChar = "1"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 " ██"
         @ box_x_koord() + row + 1, nNextY SAY8 "  █"
         @ box_x_koord() + row + 2, nNextY SAY8 "  █"
         @ box_x_koord() + row + 3, nNextY SAY8 "  █"
         @ box_x_koord() + row + 4, nNextY SAY8 " ██"

      CASE cChar = "2"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "   █"
         @ box_x_koord() + row + 2, nNextY SAY8 "████"
         @ box_x_koord() + row + 3, nNextY SAY8 "█"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "3"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "   █"
         @ box_x_koord() + row + 2, nNextY SAY8 " ███"
         @ box_x_koord() + row + 3, nNextY SAY8 "   █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "4"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "█"
         @ box_x_koord() + row + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 2, nNextY SAY8 "████"
         @ box_x_koord() + row + 3, nNextY SAY8 "   █"
         @ box_x_koord() + row + 4, nNextY SAY8 "   █"

      CASE cChar = "5"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "█"
         @ box_x_koord() + row + 2, nNextY SAY8 "████"
         @ box_x_koord() + row + 3, nNextY SAY8 "   █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "6"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "█"
         @ box_x_koord() + row + 2, nNextY SAY8 "████"
         @ box_x_koord() + row + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "7"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "   █"
         @ box_x_koord() + row + 2, nNextY SAY8 "  █"
         @ box_x_koord() + row + 3, nNextY SAY8 " █"
         @ box_x_koord() + row + 4, nNextY SAY8 "█"

      CASE cChar = "8"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 2, nNextY SAY8 " ██ "
         @ box_x_koord() + row + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "9"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 2, nNextY SAY8 "████"
         @ box_x_koord() + row + 3, nNextY SAY8 "   █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "0"

         nNextY -= 5
         @ box_x_koord() + row + 0, nNextY SAY8 "████"
         @ box_x_koord() + row + 1, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 2, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 3, nNextY SAY8 "█  █"
         @ box_x_koord() + row + 4, nNextY SAY8 "████"

      CASE cChar = "."

         nNextY -= 2
         @ box_x_koord() + row + 4, nNextY SAY8 "█"

      CASE cChar = "-"

         nNextY -= 4
         @ box_x_koord() + row + 2, nNextY SAY8 "███"

      ENDCASE
   NEXT

   RETURN .T.



FUNCTION ispisi_iznos_racuna_box( iznos )

   LOCAL cIzn
   LOCAL nCnt, Char, NextY
   LOCAL nPrevRow := Row()
   LOCAL nPrevCol := Col()

   SetPos ( 0, 0 )

   BOX (, 9, 77 )

   cIzn := AllTrim ( Transform ( iznos, "9999999.99" ) )

   @ box_x_koord(), box_y_koord() + 28 SAY8 "  IZNOS RAČUNA JE  " COLOR f18_color_invert()

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



FUNCTION SkloniIznRac()

   BoxC()

   RETURN .T.



/*
 *     Promjena seta cijena
 *  todo Ovu funkciju treba ugasiti, zajedno sa konceptom vise setova cijena, to treba generalno revidirati jer prakticno niko i ne koristi, a knjigovodstveno je sporno


-- FUNCTION PromIdCijena()

   LOCAL i := 0, j := Len( SC_Opisi )
   LOCAL cbsstara := ShemaBoja( "B1" )

   box_crno_na_zuto( 5, 1, 6 + j + 2, 78, "SETOVI CIJENA", cbnaslova,, cbokvira, cbteksta, 0 )
   FOR i := 1 TO j
      @ 6 + i, 2 SAY IF( Val( gIdCijena ) == i, "->", "  " ) + ;
         Str( i, 3 ) + ". " + PadR( SC_Opisi[ i ], 40 ) + ;
         IF( Val( gIdCijena ) == i, " <- tekuci set", "" )
   NEXT
   VarEdit( { { "Oznaka seta cijena", "gIdCijena", "VAL(gIdCijena)>0.and.VAL(gIdCijena)<=LEN(SC_Opisi)",, } }, ;
      6 + j + 3, 1, 6 + j + 7, 78, "IZBOR SETA CIJENA", "B1" )
   Prozor0()
   ShemaBoja( cBsstara )
   pos_status_traka()

   RETURN .T.

*/



FUNCTION NazivRobe( cIdRoba )

   LOCAL nCurr := Select()

   select_o_roba( cIdRoba )
   SELECT nCurr

   RETURN ( roba->Naz )



FUNCTION Godina_2( dDatum )

   // 01.01.99 -> "99"
   // 01.01.00 -> "00"

   RETURN PadL( AllTrim( Str( Year( dDatum ) % 100, 2, 0 ) ), 2, "0" )



FUNCTION NenapPop()

   // RETURN iif( gPopVar = "A", "NENAPLACENO:", "     POPUST:" )

   RETURN  "     POPUST:"



FUNCTION pos_set_user( cKorSif, nSifLen, cLevel )

   // o_pos_strad()
   // o_pos_osob()

   cKorSif := CryptSC( PadR( Upper( Trim( cKorSif ) ), nSifLen ) )

   IF find_pos_osob_by_korsif( cKorSif )
      gIdRadnik := field->ID
      gKorIme   := field->Naz
      gSTRAD  := AllTrim ( field->STATUS )
      // SELECT STRAD
      IF select_o_pos_strad( OSOB->STATUS )
         cLevel := field->prioritet
      ELSE
         cLevel := L_PRODAVAC
         gSTRAD := "K"
      ENDIF
      // SELECT OSOB
      RETURN 1
   ELSE
      MsgBeep ( "Unijeta je nepostojeća lozinka !" )
      // SELECT OSOB
      RETURN 0
   ENDIF

   RETURN 0


FUNCTION pos_status_traka()

   LOCAL _x := f18_max_rows() - 3
   LOCAL _y := 0

   @ 1, _y + 1 SAY8 "RADI:" + PadR( LTrim( gKorIme ), 31 ) +  " CIJENE:" + gIdCijena + " DATUM:" + DToC( gDatum ) + " KASA-PM:" + gIdPos

   IF gIdPos == "X "
      @ _x, _y + 1 SAY8 PadC( "$$$ --- PRODAJNO MJESTO X ! --- $$$", f18_max_cols() - 2, "█" )
   ELSE
      @ _x, _y + 1 SAY8 Replicate( "█", f18_max_cols() - 2 )
   ENDIF

   @ _x - 1, _y + 1 SAY PadC ( Razrijedi ( gKorIme ), f18_max_cols() - 2 ) COLOR f18_color_invert()

   RETURN .T.
