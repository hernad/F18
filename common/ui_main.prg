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
#include "f18_color.ch"

MEMVAR m_x, m_y

THREAD STATIC aBoxStack := {}
THREAD STATIC s_aProzorFunkcijeStek := {}
THREAD STATIC aMsgStack := {}


FUNCTION box_x_koord( nSet )

   IF nSet != NIL
      m_x := nSet
   ENDIF

   RETURN m_x


FUNCTION box_y_koord( nSet )

   IF nSet != NIL
      m_y := nSet
   ENDIF

   RETURN m_y


FUNCTION ui_calc_xy( nVisina, nSirina )

   LOCAL nX, nY
   LOCAL nX2, nY2, lCentrirati := .F.

   nX := Row()
   nY := Col()

   IF nVisina < 0
      nVisina := -nVisina
      lCentrirati := .T.
   ENDIF

   // Odredi x koordinatu
   IF !lCentrirati .AND. ( ( f18_max_rows() - 2 - nX ) >=  ( nVisina + 2 ) )
      box_x_koord( nX + 1 )
      IF nSirina + nY + 3 <= f18_max_cols() - 4
         box_y_koord( nY + 3 )
      ELSEIF ( nX + 5 ) < ( f18_max_cols() - 2 ) .AND.  ( nY - nSirina > 0 )
         box_y_koord( nY - nSirina + 5 )
      ELSE
         box_y_koord( Int( ( f18_max_cols() - 2 - nSirina ) / 2 ) )
      END IF
   ELSE
      nX2 := Int( ( f18_max_rows() - 3 - nVisina ) / 2 + 1 )
      nY2 :=  Int( ( f18_max_cols() - nSirina - 2 ) / 2 )
      box_x_koord( nX2 )
      box_y_koord( nY2 )
   END IF

   RETURN .T.



FUNCTION range( nVal, nMin, nMax )

   LOCAL lRet

   IF ( nVal <= nMax ) .AND. ( nVal >= nMin )
      lRet := .T.
   ELSE
      lRet := .F.
   ENDIF

   RETURN lRet




/*
*   brief Ispisuje tekst i ceka <Sec> sekundi
*   param xPos je pozicija ukoliko se ne zeli centrirati poruka
*   note Maksimalna duzina jednog reda je 72 slova
*/

FUNCTION Msg( uText, nSec, xPos )

   LOCAL nLinija, msg_x1, msg_x2, msg_y1, msg_y2, cPom := Set( _SET_DEVICE )

   LOCAL nLen, nHashPos, aText := {}, nCnt, nBrRed := 0
   LOCAL cText

   cText := Unicode():New( uText, .T. ):getCpString()

   SET DEVICE TO SCREEN
   DO WHILE ( nHashPos := At ( "#", cText ) ) > 0
      AAdd ( aText, Left ( cText, nHashPos - 1 ) )
      cText := SubStr ( cText, nHashPos + 1 )
      nBrRed++
   END

   IF ! Empty ( cText )
      AAdd ( aText, cText )
      nBrRed++
   ENDIF

   nLinija := 0
   FOR nCnt := 1 TO Len ( aText )
      IF Len ( aText[ nCnt ] ) > nLinija
         nLinija := Len ( aText[ nCnt ] )
      ENDIF
   NEXT

   // nLinija:=Len(Text)
   IF xPos == NIL
      msg_x1 := 8 - Int ( nBrRed / 2 )
      msg_x2 := 13 + nBrRed - Int ( nBrRed / 2 )             // nBrRed >= 1
   ELSE
      msg_x1 := xPos
      msg_x2 := xPos + 5 + nBrRed
   ENDIF

   msg_y1 := ( f18_max_cols() - nLinija - 7 ) / 2
   msg_y2 := f18_max_cols() - msg_y1
   StackPush( aMsgStack, { iif( SetCursor() == 0, 0, iif( ReadInsert(), 2, 1 ) ), SetColor( f18_color_invert()  ), nLinija, ;
      SaveScreen( msg_x1, msg_y1, msg_x2, msg_y2 ) } )

   @ msg_x1, msg_y1 CLEAR TO msg_x2, msg_y2
   @ msg_x1 + 1, msg_y1 + 2 TO msg_x2 - 1, msg_y2 - 2 DOUBLE

   FOR nCnt := 1 TO nBrRed
      @ msg_x1 + 2 + nCnt, msg_y1 + 4 SAY PadC ( aText[ nCnt ], nLinija )
   NEXT
   Inkey( nSec )

   MsgC( msg_x1, msg_y1, msg_x2, msg_y2 )
   Set( _SET_DEVICE, cPom )

   RETURN .T.


FUNCTION MsgO( cText, nSec, lUtf )

   LOCAL nLen
   LOCAL msg_x1
   LOCAL msg_x2
   LOCAL msg_y1
   LOCAL msg_y2
   LOCAL cPom

   IF lUtf == NIL
      lUtf := .T.
   ENDIF

   cPom := Set( _SET_DEVICE )

   SET DEVICE TO SCREEN

   IF lUtf
      cText := hb_UTF8ToStr( cText )
   ENDIF

   nLen := Len( cText )

   msg_x1 := 8
   msg_x2 := 14

   msg_y1 := ( f18_max_cols()  - nLen - 7 ) / 2
   msg_y2 := f18_max_cols() - msg_y1


   StackPush( aMsgStack, ;
      { iif( SetCursor() == 0, 0, iif( ReadInsert(), 2, 1 ) ), SetColor( f18_color_invert()  ), nLen, ;
      SaveScreen( msg_x1, msg_y1, msg_x2, msg_y2 ) } )

   @ msg_x1, msg_y1 CLEAR TO msg_x2, msg_y2

   @ msg_x1 + 1, msg_y1 + 2 TO msg_x2 - 1, msg_y2 - 2 DOUBLE
   @ msg_x1 + 3, msg_y1 + 4 SAY cText

   SET CURSOR OFF
   Set( _SET_DEVICE, cPom )

   RETURN .T.


FUNCTION MsgC( msg_x1, msg_y1, msg_x2, msg_y2 )

   LOCAL aMsgPar
   LOCAL nLen

   IF Len( aMsgStack ) > 0
      aMsgPar := StackPop( aMsgStack )

      IF msg_x1 == NIL
         nLen := aMsgPar[ 3 ]
         RestScreen( 8, ( f18_max_cols() - nLen - 7 ) / 2, 14, f18_max_cols() - ( f18_max_cols() - nLen - 7 ) / 2, aMsgPar[ 4 ] )
      ELSE
         RestScreen ( msg_x1, msg_y1, msg_x2, msg_y2, aMsgPar[ 4 ] )
      ENDIF

      SetCursor( iif( aMsgPar[ 1 ] == 0, 0, iif( ReadInsert(), 2, 1 ) ) )
      SetColor( aMsgPar[ 2 ] )
   ENDIF

   RETURN .T.


/* Box(cBoxId, N, nSirina, Inv, aOpcijeIliCPoruka, cHelpT)
 *     Otvara prozor cBoxId dimenzija (N x nSirina), f18_color_invert() ovan
 *         (Inv=.T. ili ne)
 *
 *   param: aOpcijeIliCPoruka - tip C -> prikaz poruke
 *   param: A -> ispisuje opcije pomocu fje prikaz_dostupnih_opcija_crno_na_zuto
 *   param: cBoxId se ne koristi
 */

FUNCTION Box( cBoxId, nVisina, nSirina, lInvert, aOpcijeIliCPoruka, cHelpT )

   LOCAL nX1, nY1, nX2, nY2
   LOCAL cColor, cSetDevice, cNaslovBoxa
   LOCAL _m_x, _m_y

   // , nXVisina

   cSetDevice := Set( _SET_DEVICE )
   cNaslovBoxa := ""

   IF cBoxId <> NIL .AND. Left( cBoxId, 1 ) == "#"
      cNaslovBoxa := SubStr( cBoxId, 2 )
   ENDIF

   SET DEVICE TO SCREEN

   // _m_x := box_x_koord()
   // _m_y := box_y_koord()
   // nXVisina := nVisina

   IF ValType( cBoxId ) == "C" .AND. "<CENTAR>" $ cBoxId
      ui_calc_xy( - nVisina, nSirina )
   ELSE
      ui_calc_xy( nVisina, nSirina )
   ENDIF

   // stvori prostor za prikaz
   IF ValType( aOpcijeIliCPoruka ) == "A"
      cBoxId := prikaz_dostupnih_opcija_crno_na_zuto( aOpcijeIliCPoruka )
      IF box_x_koord() + nVisina > f18_max_rows() - 3 - cBoxId
         box_x_koord(  f18_max_rows() - 4 - cBoxId - nVisina )
         IF box_x_koord() < 1
            nVisina := f18_max_rows() - 5 - cBoxId
            box_x_koord( 1 )
         ENDIF
      ENDIF
   ENDIF

   IF  aOpcijeIliCPoruka == NIL
      aOpcijeIliCPoruka := ""
   ENDIF


   StackPush( aBoxStack, ;
      {  box_x_koord(), ;
      box_y_koord(), ;
      nVisina,   ;
      nSirina, ;
      SaveScreen( m_x, m_y, m_x + nVisina + 1, m_Y + nSirina + 2 ), ;
      iif( ValType( aOpcijeIliCPoruka ) != "A", "", cBoxId ), ;
      Row(), ;
      Col(), ;
      iif( SetCursor() == 0, 0, iif( ReadInsert(), 2, 1 ) ), ;
      SetColor(), ;
      cHelpT;
      } )

   IF lInvert == NIL
      lInvert := .F.
   ENDIF

   cColor := iif ( lInvert, f18_color_invert(), f18_color_normal() )
   SetColor( cColor )
   Scroll( box_x_koord(), box_y_koord(), box_x_koord() + nVisina + 1, box_y_koord() + nSirina + 2 )
   @ box_x_koord(), box_y_koord() TO box_x_koord() + nVisina + 1, box_y_koord() + nSirina + 2 DOUBLE

   IF !Empty( cNaslovBoxa )
      @ box_x_koord(), box_y_koord() + 2 SAY8 cNaslovBoxa COLOR "GR+/B"
   ENDIF

   Set( _SET_DEVICE, cSetDevice )

   RETURN .T.



FUNCTION BoxC()

   LOCAL aBoxPar[ 11 ], cSetDevice
   LOCAL nVisina, nSirina

   cSetDevice := Set( _SET_DEVICE )
   SET DEVICE TO SCREEN

   aBoxPar := StackPop( aBoxStack )
   box_x_koord( aBoxPar[ 1 ] )
   box_y_koord( aBoxPar[ 2 ] )
   nVisina := aBoxPar[ 3 ]
   nSirina := aBoxPar[ 4 ]

   Scroll( m_x, m_y, m_x + nVisina + 1, m_y + nSirina + 2 )
   RestScreen( m_x, m_y, m_x + nVisina + 1, m_y + nSirina + 2, aBoxPar[ 5 ] )

   @ aBoxPar[ 7 ], aBoxPar[ 8 ] SAY ""
   SetCursor( iif( aBoxPar[ 9 ] == 0, 0, iif( ReadInsert(), 2, 1 ) ) )
   SetColor( aBoxPar[ 10 ] )

   IF ValType( aBoxPar[ 6 ] ) == "N"
      box_crno_na_zuto_end()
   ENDIF

   IF !StackIsEmpty( aBoxStack )
      aBoxPar := StackTop( aBoxStack )
      box_x_koord( aBoxPar[ 1 ] )
      box_y_koord( aBoxPar[ 2 ] )
      nVisina := aBoxPar[ 3 ]
      nSirina := aBoxPar[ 4 ]
   ENDIF

   Set( _SET_DEVICE, cSetDevice )

   RETURN .T.


/*  prikaz_dostupnih_opcija_crno_na_zuto(aNiz)
 *  prikaz opcija u Browse-u
 *
 *  aNiz:={"<c-N> Novi","<a-A> Ispravka"}
 *
 */

FUNCTION prikaz_dostupnih_opcija_crno_na_zuto( aNiz )

   LOCAL nI := 0, j := 0, nCol := 0, nOmax := 0
   LOCAL nBrKol, nOduz, nBrRed, xVrati := ""

   IF ValType( aNiz ) == "A"

      AEval( aNiz, {| x | iif( Len( x ) > nOmax, nOmax := Len( x ), ) } )

      nBrKol := Int( f18_max_cols() / ( nOmax + 1 ) )
      nBrRed := Int( Len( aNiz ) / nBrKol ) + iif( Mod( Len( aNiz ), nBrKol ) != 0, 1, 0 )
      nOduz := iif( nOmax < 10, 10, iif( nOmax < 16, 16, iif( nOmax < 20, 20, iif( nOmax < 27, 27, 40 ) ) ) )

      box_crno_na_zuto( f18_max_rows() - 3 - nBrRed, 0,  f18_max_rows() - 2, f18_max_cols(),,, Space( 9 ), , F18_COLOR_TEKST )

      FOR nI := 1 TO nBrRed * nBrKol
         IF Mod( nI - 1, nBrKol ) == 0
            Eval( {|| ++j, nCol := 0 } )
         ELSE
            nCol += nOduz
         ENDIF

         IF nI > Len( aNiz )
            AAdd( aNiz, "" )
         ENDIF

         IF aNiz[ nI ] == NIL
            aNiz[ nI ] := ""
         ENDIF
         @ f18_max_rows() - 3 - nBrRed + j, nCol + 1 SAY " " + PadR( aNiz[ nI ], nOduz - 2 )

         IF Mod( nI - 1, nBrKol ) != nBrKol - 1
            @ Row(), Col() SAY  hb_UTF8ToStrBox( BROWSE_COL_SEP )
         ENDIF
      NEXT

      // FOR i := 1 TO nBrKol
      // @ f18_max_rows() - 3 - nBrRed, ( i - 1 ) * nOduz SAY Replicate( hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), ;
      // nOduz - iif( i == nBrKol, 0, 1 ) ) + iif( i == nBrKol, "", hb_UTF8ToStrBox(BROWSE_COL_SEP) )
      // NEXT

      xVrati := nBrRed + 1
   ENDIF

   RETURN xVrati


FUNCTION BoxCLS()

   LOCAL aBoxPar[ 11 ]

   aBoxPar := aBoxStack[ Len( aBoxStack ) ]

   @ aBoxPar[ 1 ] + 1, aBoxPar[ 2 ] + 1 CLEAR TO aBoxPar[ 1 ] + aBoxPar[ 3 ], aBoxPar[ 2 ] + aBoxPar[ 4 ] + 1

   RETURN .T.



FUNCTION Beep( nPuta )

   LOCAL nI

   FOR nI := 1 TO nPuta
      f18_tone( 300, 1 )
   NEXT

   RETURN .T.



FUNCTION f18_tone( nFreq, nTimes )

#ifdef __PLATFORM__WINDOWS

   // ?E "tone je bugovita trace-print-dialog-1"

   RETURN Tone( nFreq, nTimes )
#else

   RETURN NIL
#endif


FUNCTION CentrTxt( tekst, lin )

   LOCAL kol

   IF tekst <> NIL
      IF Len( tekst ) > f18_max_cols()
         kol := 0
      ELSE
         kol := Int( ( f18_max_cols() - Len( tekst ) ) / 2 )
      ENDIF
      @ lin, 0 SAY Replicate( Chr( 32 ), f18_max_cols() )
      @ lin, kol SAY tekst
   ENDIF

   RETURN .T.



FUNCTION box_crno_na_zuto( v1, h1, v2, h2, cNaslov, cBojaN, cOkvir, cBojaO, cBojaT, nKursor )

   LOCAL cOutputDevice := Set( _SET_DEVICE )

   SET DEVICE TO SCREEN

   IF cBojaN == NIL
      cBojaN := F18_COLOR_P1
   ENDIF

   IF cOkvir == NIL
      cOkvir := B_SINGLE + " "
   ENDIF

   IF nKursor == NIL
      nKursor := SetCursor()
   ENDIF

   StackPush( s_aProzorFunkcijeStek, { Row(), Col(), v1, h1, v2, h2, SaveScreen( v1, h1, v2, h2 ), SetColor( cBojaT ), SetCursor( nKursor ) } )

   DispBox( v1, h1, v2, h2, cOkvir, cBojaO )

   @ v1 + 1, h1 + 1 CLEAR TO v2 - 1, h2 - 1

   IF cNaslov != NIL
      @ v1, ( h2 + h1 + -1 - Len( cNaslov ) ) / 2 SAY " " + cNaslov + " " COLOR cBojaN
   ENDIF

   Set( _SET_DEVICE, cOutputDevice )

   RETURN .T.



FUNCTION box_crno_na_zuto_end()

   LOCAL aStack := StackPop( s_aProzorFunkcijeStek )
   LOCAL cOutputDevice := Set( _SET_DEVICE )

   SET DEVICE TO SCREEN
   RestScreen( aStack[ 3 ], aStack[ 4 ], aStack[ 5 ], aStack[ 6 ], aStack[ 7 ] )
   SetColor( aStack[ 8 ] )
   SetCursor( aStack[ 9 ] )
   @ aStack[ 1 ], aStack[ 2 ] SAY ""
   Set( _SET_DEVICE, cOutputDevice )

   RETURN .T.



/* Postotak(nIndik,nUkupno,cTekst,cBNasl,cBOkv,lZvuk)
*      Prikaz procenta uradjenog posla
*
* Ova fja omogucava prikaz procenta uradjenog posla, sto je efektno
* kod stanja cekanja da program uradi neki posao. Pise se najmanje tri puta
* u dijelu programa gdje se rjesava taj dugotrajni posao, s tim da se prvi
* parametar stavlja da je 1 pri prvom pozivu, 2 pri drugom, a 0 pri okoncanju
* posla. Pri prvom pozivu ove procedure potrebno je jos navesti i cio broj
* koji oznacava kolicinu posla koji treba biti uradjen, kao i tekst koji
* opisuje sta se radi. Pri drugom pozivu koji se nalazi najcesce u nekoj
* petlji drugi parametar je cio broj koji govori o kolicini uradjenog posla.
* Zadnji poziv ima samo parametar 0 i oznacava kraj posla.
*
* \code
*
*  O_RADOVI
*  Postotak(1,RECCOUNT2(),"Formiranje cijena")
*  GO TOP
*  DBEVAL({|| NCijene(FIELDGET(3),FIELDGET(1)),Postotak(2,++nPosto)})
*  Postotak(0)
*
* \encode
*
*/

FUNCTION Postotak( nIndik, nUkupno, cTekst, cBNasl, cBOkv, lZvuk )

   STATIC nCilj, cKraj, cNas, cOkv
   LOCAL nKara := 0, cPom := Set( _SET_DEVICE )

   IF lZvuk == NIL; lZvuk := .T. ; ENDIF
   SET DEVICE TO SCREEN

   DO CASE
   CASE nIndik == 1

      cOkv := iif( cBOkv == NIL, F18_COLOR_OKVIR, cBOkv )
      cNas := iif( cBNasl == NIL, F18_COLOR_NASLOV, cBNasl )
      nCilj := nUkupno
      cKraj := cTekst + " zavrseno."
      box_crno_na_zuto( 10, 13, 14, 66, cTekst + " u toku...", cNas, , cOkv, F18_COLOR_TEKST, 0 )
      @ 12, 15 SAY Replicate( "X", 50 ) COLOR F18_COLOR_STATUS
      IF lZvuk
         f18_tone( 1900, 0 )
      ENDIF

   CASE nIndik == 2

      nKara = Int( 50 * nUkupno / nCilj )
      @ 12, 15 SAY Replicate( "|", nKara ) COLOR "B/BG"
      @ 13, 37 SAY Str( 2 * nKara, 3 ) + " %" COLOR "B/W"

   CASE nIndik <= 0

      @ 10, ( f18_max_cols() - 2 - Len( cKraj ) ) / 2 SAY " " + cKraj + " " COLOR cNas
      IF lZvuk
         f18_tone( 2000, 0 )
      ENDIF

      IF nIndik == 0
         @ 14, 28 SAY "<pritisnite neku tipku>" COLOR iif( Int( Seconds() * 1.5 ) % 2 == 0, "W/", "W+/" ) + Right( cOkv, 1 )
         Inkey( 0 )
      ENDIF
      box_crno_na_zuto_end()
      nCilj := 0; cKraj := ""
   ENDCASE
   Set( _SET_DEVICE, cPom )

   RETURN .T.



/* LomiGa(cTekst,nOrig,nLin,nDuz)
 *    Formatira tekst u varijabli 'cTekst'
 *
 * To se radi prema zeljenom ispisu u 'nLin'
 * redova duzine 'nDuz'. Pri tom uklanja znak "-" koji se javlja pri
 * lomljenju rijeci. 'nOrig' je broj redova proslog formata 'cTekst'-a.
 * Ako nLin nije zadano ili je 0, nLin se formira prema duzini teksta
 *
 */
FUNCTION LomiGa( cTekst, nOrig, nLin, nDuz )

   LOCAL nTek := Len( cTekst ), aPom := {}, i := 0, nDO, cPom := "", cPom2 := ""

   IF nLin == NIL; nLin := 0; ENDIF


   nDO := Int( nTek / nOrig )
   FOR i := 1 TO nOrig
      AAdd( aPom, SubStr( cTekst, ( i - 1 ) * nDO + 1, nDO ) )
      cPom := AllTrim( aPom[ i ] )
      IF Right( cPom, 1 ) == "-" .AND. !( SubStr( cPom, - 2, 1 ) $ " 1234567890" )
         aPom[ i ] := Left( cPom, Len( cPom ) - 1 )
      ELSEIF Right( cPom, 1 ) == "-" .AND. Empty( SubStr( cPom, - 2, 1 ) )
         aPom[ i ] := cPom + " "
      ELSEIF Right( cPom, 1 ) != "-"
         aPom[ i ] := cPom + " "
      ELSE
         aPom[ i ] := cPom
      ENDIF
   NEXT
   cPom := ""; cTekst := ""; AEval( aPom, {| x | cPom += x } )
   cPom2 := RTrim( cPom )
   IF nLin == 0; nLin := Int( Len( cPom ) / nDuz ) + iif( Mod( Len( cPom ), nDuz ) != 0, 1, 0 ); ENDIF
   cPom2 := PadR( cPom2, nLin * nDuz )

   i := 0
   DO WHILE .T.
      ++i
      cPom := MemoLine( cPom2, nDuz, i )
      IF Len( cPom ) < 1 .OR. Empty( cPom ) .AND. i > nLin
         EXIT
      ELSE
         cTekst += cPom
      ENDIF
   ENDDO

   RETURN cTekst


/* KudaDalje(cTekst, aOpc, cPom)
 *  Meni od maksimalno 15 opcija opisanih u nizu aOpc
 *
 * Naslov menija je
 * cTekst, a cPom je oznaka za "Help"
 * Vraca redni broj opcije koja je izabrana. Na pritisak <Esc> vraca se
 * broj zadnje opcije u nizu (kao da je ona izabrana).
 */

FUNCTION KudaDalje( cTekst, aOpc, cPom )

   LOCAL nVrati := 1, nTipka, i := 0, nOpc := Len( aOpc ), nRedova := 1, p := 0
   LOCAL nXp := 0, aTxt := {}, cPom1, cPom2

   FOR i := 1 TO nOpc
      cPom1 := PadC( AllTrim( MemoLine( aOpc[ i ], 16, 1 ) ), 16 )
      cPom2 := PadC( AllTrim( MemoLine( aOpc[ i ], 16, 2 ) ), 16 )
      AAdd( aTxt, { cPom1, cPom2 } )
   NEXT
   nRedova := Int( ( nOpc - 1 ) / 3 + 1 )
   nXp := Int( ( f18_max_rows() - nRedova * 4 - 2 ) / 2 ) + 2
   box_crno_na_zuto( nXp - 2, 4, nXp + 1 + 4 * nRedova, 75,, "N/W", "²ß²²²Ü²² ", "N/W", "W/W", 0 )
   @ nXp - 1, 5 SAY PadC( cTekst, 70 ) COLOR "N/W"
   DO WHILE .T.
      FOR j = 1 TO nRedova
         FOR i = 1 TO 3
            IF ( p := 3 * ( j - 1 ) + i ) <= nOpc
               DispBox( nXp + 1 + 4 * ( j - 1 ), 22 * i - 13, nXp + 4 + 4 * ( j - 1 ), 22 * i + 4, 1, iif( p == nVrati, "W+/N", "N/W" ) )
               @ nXp + 2 + 4 * ( j - 1 ), 22 * i - 12 SAY aTxt[ p, 1 ] COLOR iif( p == nVrati, "W+/N", "N/W" )
               @ nXp + 3 + 4 * ( j - 1 ), 22 * i - 12 SAY aTxt[ p, 2 ] COLOR iif( p == nVrati, "W+/N", "N/W" )
            ENDIF
         NEXT
      NEXT

#ifndef TEST
      CLEAR TYPEAHEAD // kuda dalje
#endif
      nTipka := Inkey( 0 )

      DO CASE
      CASE nTipka == K_UP
         nVrati -= 3; iif( nVrati < 1, nVrati += 3, )
      CASE nTipka == K_DOWN
         nVrati += 3; iif( nVrati > nOpc, nVrati -= 3, )
      CASE nTipka == K_LEFT
         nVrati--; iif( nVrati < 1, nVrati++, )
      CASE nTipka == K_RIGHT
         nVrati++; iif( nVrati > nOpc, nVrati--, )
      CASE nTipka == K_ENTER
         EXIT
      CASE nTipka == K_ESC
         nVrati := nOpc
         EXIT
      ENDCASE
   ENDDO
   box_crno_na_zuto_end()

   RETURN nVrati





FUNCTION LENx( xVrij )

   LOCAL cTip := ValType( xVrij )

   RETURN iif( cTip == "D", 8, iif( cTip == "N", Len( Str( xVrij ) ), Len( xVrij ) ) )



FUNCTION SrediDat( d_ulazni )

   LOCAL pomocni

   IF Empty( d_ulazni ) == .F.
      pomocni := Stuff( DToC( d_ulazni ), 7, 0, Str( Int( Year( d_ulazni ) / 100 ), 2, 0 ) ) + ".godine"
   ELSE
      pomocni := Space( 17 )
   ENDIF

   RETURN pomocni


FUNCTION AutoSifra( nObl, cSifra )

   IF cSifra != NIL .AND. Len( AllTrim( cSifra ) ) > 1 .AND. gAutoSif == "D"
      PushWA()
      SELECT ( nObl )
      SEEK cSifra
      IF !Found()
         KEYBOARD Chr( K_CTRL_N ) + AllTrim( cSifra )
      ENDIF
      PopWA()
   ENDIF

   RETURN .T.



FUNCTION CistiTipke()

   KEYBOARD Chr( 0 )
   DO WHILE !Inkey() == 0; ENDDO

   RETURN .T.


FUNCTION AMFILL( aNiz, nElem )

   LOCAL i := 0, rNiz := {}, aPom := {}

   FOR i := 1 TO nElem
      AEval( aNiz, {| x | AAdd( aPom, x ) } )
      AAdd( rNiz, aPom )
      aPom := {}
   NEXT

   RETURN rNiz




FUNCTION Zvuk( nTip )

   IF nTip == NIL; nTip := 0; ENDIF
   DO CASE
   CASE nTip == 1
      f18_tone( 400, 2 )
   CASE nTip == 2
      f18_tone( 500, 2 )
   CASE nTip == 3
      f18_tone( 600, 2 )
   CASE nTip == 4
      f18_tone( 700, 2 )
   ENDCASE

   RETURN .T.



FUNCTION ShemaBoja( cIzbor )

   LOCAL cVrati := cBShema

   IF IsColor()
      DO CASE
      CASE cIzbor == "B1"
         cbnaslova := "GR+/N"
         cbokvira  := "GR+/N"
         cbteksta  := "W/N  ,R/BG ,,,B/W"
      CASE cIzbor == "B2"
         cbnaslova := "N/G"
         cbokvira  := "N/G"
         cbteksta  := "W+/G ,R/BG ,,,B/W"
      CASE cIzbor == "B3"
         cbnaslova := "R+/N"
         cbokvira  := "R+/N"
         cbteksta  := "N/GR ,R/BG ,,,B/W"
      CASE cIzbor == "B4"
         cbnaslova := "B/BG"
         cbokvira  := "B/W"
         cbteksta  := "B/W  ,R/BG ,,,B/W"
      CASE cIzbor == "B5"
         cbnaslova := "B/W"
         cbokvira  := "R/W"
         cbteksta  := "GR+/N,R/BG ,,,B/W"
      CASE cIzbor == "B6"
         cbnaslova := "B/W"
         cbokvira  := "R/W"
         cbteksta  := "W/N,R/BG ,,,B/W"
      CASE cIzbor == "B7"
         cbnaslova := "B/W"
         cbokvira  := "R/W"
         cbteksta  := "N/G,R+/N ,,,B/W"
      OTHERWISE
      ENDCASE
   ELSE
      cbnaslova := "N/W"
      cbokvira  := "N/W"
      cbteksta  := "W/N  ,N/W  ,,,N/W"
   ENDIF
   cbshema := cIzbor

   RETURN cVrati



FUNCTION NForma1( cPic )

   LOCAL nPoz := 0, i := 0

   cPic := AllTrim( cPic )
   nPoz := At( ".", cPic )
   IF nPoz == 0 .AND. !Empty( cPic ); nPoz := Len( cPic ) + 1; ENDIF
   FOR i := 1 TO Int( ( nPoz - 2 ) / 3 )
      cPic := Stuff( cPic, nPoz - i * 3, 0, " " )
   NEXT

   RETURN cPic


FUNCTION NForma2( cPic )

   RETURN ( cPic := StrTran( NForma1( cPic ), " ", "," ) )


FUNCTION FormPicL( cPic, nDuz )

   LOCAL nDec, cVrati, i, lZarez := .F., lPrazno := .F.

   cPic := AllTrim( cPic )
   nDec := RAt( "9", cPic ) - At( ".", cPic )
   IF nDec >= Len( cPic ) .OR. nDec < 0; nDec := 0; ENDIF
   cVrati := Space( nDuz )
   IF At( ",", cPic ) != 0
      lZarez := .T.
   ELSEIF At( " ", cPic ) != 0
      lPrazno := .T.
   ENDIF
   FOR i := 1 TO nDuz
      IF i == nDec + 1 .AND. nDec != 0
         cVrati := Stuff( cVrati, nDuz - i + 1, 1, "." )
      ELSEIF i > nDec + 2 .AND. Mod( i - iif( nDec == 0, 0, nDec + 1 ), 4 ) == 0 .AND. lZarez .AND. i != nDuz
         cVrati := Stuff( cVrati, nDuz - i + 1, 1, "," )
      ELSEIF i > nDec + 2 .AND. Mod( i - iif( nDec == 0, 0, nDec + 1 ), 4 ) == 0 .AND. lPrazno
         cVrati := Stuff( cVrati, nDuz - i + 1, 1, " " )
      ELSE
         cVrati := Stuff( cVrati, nDuz - i + 1, 1, "9" )
      ENDIF
   NEXT

   RETURN cVrati



FUNCTION VarEdit( aNiz, nX1, nY1, nX2, nY2, cNaslov, cBoje )

   LOCAL GetList := {}
   LOCAL cBsstara := ShemaBoja( cBoje )
   LOCAL nP := 0
   LOCAL cPomUI := Set( _SET_DEVICE )
   LOCAL cPom
   LOCAL cPom1 := 0
   LOCAL cPom3 := 0
   LOCAL cPom4 := 0
   LOCAL cPom5 := 0
   LOCAL i, nLen


   PushWa()
   SET DEVICE TO SCREEN
   box_crno_na_zuto( nX1, nY1, nX2, nY2, _u( cNaslov ), cBNaslova,, cBOkvira, cBTeksta, 2 )
   FOR i := 1 TO Len( aNiz )
      cPom := aNiz[ i, 2 ]
      IF aNiz[ i, 3 ] == NIL .OR. Len( aNiz[ i, 3 ] ) == 0
         aNiz[ i, 3 ] := ".t."
      ENDIF
      IF aNiz[ i, 4 ] == NIL .OR. Len( aNiz[ i, 4 ] ) == 0
         aNiz[ i, 4 ] := ""
      ENDIF
      IF aNiz[ i, 5 ] == NIL .OR. Len( aNiz[ i, 5 ] ) == 0
         aNiz[ i, 5 ] := ".t."
      ENDIF

      IF "##" $ aNiz[ i, 3 ]
         nP := At( "##", aNiz[ i, 3 ] )
         cPom3 := "ValGeta(" + Left( aNiz[ i, 3 ], nP - 1 ) + ",'" + SubStr( aNiz[ i, 3 ], nP + 2 ) + "')"
      ELSE
         cPom3 := aNiz[ i, 3 ]
      ENDIF

      cPom1 := aNiz[ i, 1 ]
      cPom4 := aNiz[ i, 4 ]
      cPom5 := aNiz[ i, 5 ]
      nLen := nY2 - nY1 - 4 - iif( "S" $ cPom4, DuzMaske( cPom4 ), iif( Empty( cPom4 ), LENx( &( cPom ) ), Len( Transform( &cPom, cPom4 ) ) ) )

      @ nX1 + 1 + i, nY1 + 2 SAY PadR( _u(cPom1), nLen, "." ) GET &cPom WHEN &cPom5 VALID &cPom3 PICT cPom4
   NEXT
   //PRIVATE MGetList := GetList
   READ
   box_crno_na_zuto_end()
   ShemaBoja( cBsstara )
   Set( _SET_DEVICE, cPomUI )

   PopWa()

   RETURN iif( LastKey() != K_ESC, .T., .F. )


FUNCTION ValGeta( lUslov, cPoruka )

   IF !lUslov; Msg( cPoruka, 3 ); ENDIF

   RETURN lUslov

FUNCTION DuzMaske( cPicture )

   LOCAL nPozS := At( "S", cPicture )

   RETURN Val( SubStr( cPicture, nPozS + 1 ) )



FUNCTION MsgBeep( cMsg, lClearTypeahead )

   LOCAL _set

   hb_default( @lClearTypeahead, .T. )

#ifndef TEST
   IF lClearTypeahead
      Beep( 2 )
      CLEAR TYPEAHEAD // MsgBeep
   ENDIF
#endif

/*

INKEY_MOVE          Mouse motion events are allowed
 50  *        INKEY_LDOWN         The mouse left click down event is allowed
 51  *        INKEY_LUP           The mouse left click up event is allowed
 52  *        INKEY_RDOWN         The mouse right click down event is allowed
 53  *        INKEY_RUP           The mouse right click up event is allowed
 54  *        INKEY_KEYBOARD      All keyboard events are allowed
 55  *        INKEY_ALL           All mouse and keyboard events are allowed
 56  *        HB_INKEY_EXTENDED   Extended keyboard codes are used.

*/

   _set := Set( _SET_EVENTMASK, INKEY_KEYBOARD )
   IF Len( cMsg ) > f18_max_cols() - 11 .AND.  ( At( cMsg, "#" ) == 0 )
      cMsg := SubStr( cMsg, 1, f18_max_cols() - 11 ) + "#" + SubStr( cMsg, f18_max_cols() - 10, f18_max_cols() - 11 ) + "#..."
   ENDIF

#ifdef TEST
   Msg( cMsg, 1 )
#else
   Msg( cMsg, 20 )
#endif

   Set( _SET_EVENTMASK, _set )

   RETURN .T.


FUNCTION show_it( cItem, nPadR )

   IF nPadR <> nil
      cItem := PadR( cItem, nPadR )
   ENDIF

   @ Row(), Col() + 3 SAY cItem

   RETURN .T.

FUNCTION UGlavnomMeniju()

   LOCAL i
   LOCAL fRet := .T.

   IF programski_modul() == "LD"
      RETURN fRet
   ENDIF

   PushWA()
   FOR i := 1 TO 100
      SELECT ( i )
      IF Used()
         MsgBeep( "Ova opcija je raspoloziva samo iz osnovnog menija" )
         fRet := .F.
         EXIT
      ENDIF
   NEXT
   PopWa()

   RETURN fret








/*
 *  brief Token pretvori u matricu
 *  param cTok - string tokena
 *  param cSN - separator nizova
 *  param cSE - separator elemenata
 */

FUNCTION TokUNiz( cTok, cSN, cSE )

   LOCAL aNiz := {}, nN := 0, nE := 0, aPom := {}, nI := 0, nJ := 0, cTE := "", cE := ""

   IF cSN == NIL ; cSN := ";" ; ENDIF
   IF cSE == NIL ; cSE := "." ; ENDIF
   nN := NumToken( cTok, cSN )
   FOR nI := 1 TO nN
      cTE := Token( cTok, cSN, nI )
      nE  := NumToken( cTE, cSE )
      aPom := {}
      FOR nJ := 1 TO nE
         cE := Token( cTE, cSE, nJ )
         AAdd( aPom, cE )
      NEXT
      AAdd( aNiz, aPom )
   NEXT

   RETURN ( aNiz )





FUNCTION MsgBeep2( cTXT )

   @ f18_max_rows() - 1, 0 SAY PadL( cTXT, f18_max_cols() ) COLOR "R/W"
   f18_tone( 900, 0.3 )

   RETURN .T.


FUNCTION say_from_valid( x, y, cString, nP )

   LOCAL pX := Row(), pY := Col()

   IF nP == 40 .AND. ( x == 11 .AND. y == 23 .OR. x == 12 .AND. y == 23 .OR. x == 12 .AND. y == 24 .OR. x == 12 .AND. y == 25 )
      nP += 6
   ENDIF
   IF nP == NIL
      nP := 0
   ENDIF
   @ m_x + x, m_y + y SAY iif( nP > 0, Space( nP ), "" )
   @ m_x + x, m_y + y SAY cString
   SetPos( pX, pY )

   RETURN .T.



FUNCTION IzreziPath( cPath, cTekst )

   LOCAL nPom

   IF Left( cTekst, 1 ) <> SLASH
      cTekst := SLASH + cTekst
   ENDIF
   nPom := At( cTekst, cPath )
   IF nPom > 0
      cPath := Left( cPath, nPom - 1 )
   ENDIF

   RETURN cPath




FUNCTION pos_form_browse( nT, nL, nB, nR, aImeKol, aKol, aHFCS, nFreeze, bIstakni )

   LOCAL oBrowse     // browse object
   LOCAL oColumn     // column object
   LOCAL k
   LOCAL i

   oBrowse := TBrowseDB( nT, nL, nB, nR )

   FOR k := 1 TO Len( aKol )
      i := AScan( aKol, k )
      IF i <> 0
         oColumn := TBColumnNew( aImeKol[ i, 1 ], aImeKol[ i, 2 ] )
         IF bIstakni <> nil
            oColumn:colorBlock := {|| iif ( Eval ( bIstakni ), { 5, 2 }, { 1, 2 } ) }
         ENDIF
         IF aHFCS[ 1 ] <> nil
            oColumn:headSep := aHFCS[ 1 ]
         ENDIF
         IF aHFCS[ 2 ] <> nil
            oColumn:footSep := aHFCS[ 2 ]
         ENDIF
         IF aHFCS[ 3 ] <> nil
            oColumn:colSep := aHFCS[ 3 ]
         ENDIF
         oBrowse:addColumn ( oColumn )
      ENDIF
   NEXT

   IF nFreeze == nil
      oBrowse:Freeze := 1
   ELSE
      oBrowse:Freeze := nFreeze
   ENDIF

   RETURN ( oBrowse )
