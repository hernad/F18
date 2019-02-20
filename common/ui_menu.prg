/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

THREAD STATIC aMenuStack := {} // thread safe

MEMVAR goModul

FUNCTION f18_menu( cIzp, lOsnovniMeni, nIzbor, aOpc, aOpcExe )

   LOCAL cOdgovor
   LOCAL nMenuExeOpcija

   IF lOsnovniMeni == NIL
      lOsnovniMeni := .F.
   ENDIF

   IF lOsnovniMeni
      @ 4, 5 SAY ""
   ENDIF

   DO WHILE .T.
      nIzbor := meni_0( cIzp, aOpc, nIzbor, .F. )

      DO CASE
      CASE nIzbor == 0
         IF lOsnovniMeni
            cOdgovor := Pitanje( "", "Želite izaći iz programa ?", 'N' )
            IF cOdgovor == "D"
               RETURN .F.
            ELSEIF cOdgovor == "L"
               nIzbor := 1
               @ 4, 5 SAY ""
               LOOP
            ELSE
               nIzbor := 1
               @ 4, 5 SAY ""
               LOOP
            ENDIF
         ELSE
            EXIT
         ENDIF

      OTHERWISE

         IF aOpcExe[ nIzbor ] <> nil
            nMenuExeOpcija := aOpcExe[ nIzbor ]

            IF ValType( nMenuExeOpcija ) == "B"
               Eval( nMenuExeOpcija )
            ELSE
               MsgBeep( "meni čudan ?" + hb_ValToStr( nIzbor ) )
            ENDIF

         ENDIF

      ENDCASE

   ENDDO

   RETURN .T.



FUNCTION f18_menu_sa_priv_vars_opc_opcexe_izbor( cIzp, lMain )

   // pretpostavljamo privatne varijable Izbor, Opc, OpcExe

   RETURN f18_menu( cIzp, lMain, Izbor, Opc, OpcExe )



FUNCTION meni_fiksna_lokacija( nX1, nY1, aNiz, nIzb )

   LOCAL nOpcija := 0, nYm := 0

   nOpcija := Len( aNiz )
   AEval( aNiz, {| x | iif( Len( x ) > nYm, nYm := Len( x ), ) } )

   box_crno_na_zuto( nX1, nY1, nX1 + nOpcija + 1, nY1 + nYm + 1,,,,,, 0 )
   nIzb := meni_0_inkey( nX1 + 1, nY1 + 1, nX1 + nOpcija + 1, nY1 + nYm, aNiz, nIzb )
   box_crno_na_zuto_end()

   RETURN nIzb

/*
 *
 *  Prikazuje zadati meni, vraca odabranu opciju
 *
 *  cMeniId  - identifikacija menija     C
 *  aItems   - niz opcija za nIzbor       {}
 *  nItemNo  - Broj pocetne pozicije     N
 *  lInvert     - da li je meni f18_color_invert() ovan  L
 *
 *  Broj izabrane opcije, 0 kraj
 *

*/

FUNCTION meni_0( cMeniId, aItems, nItemNo, lInvert, cHelpT, nPovratak, aFixKoo, nMaxVR )

   LOCAL nLength
   LOCAL nN1
   LOCAL cOldColor
   LOCAL cLocalColor
   LOCAL cLocalInvertedColor
   LOCAL nTItemNo
   LOCAL nChar
   LOCAL cMeniItem

   // LOCAL ItemSav
   LOCAL aMenu := {}
   LOCAL cPom := Set( _SET_DEVICE )
   LOCAL lFiksneKoordinate := .F.

   SET DEVICE TO SCREEN

   IF nPovratak == NIL
      nPovratak := 0
   ENDIF
   IF nMaxVR == NIL
      nMaxVR := 16
   ENDIF
   IF aFixKoo == NIL
      aFixKoo := {}
   ENDIF
   IF Len( aFixKoo ) == 2
      lFiksneKoordinate := .T.
   ENDIF

   nN1 := iif( Len( aItems ) > nMaxVR, nMaxVR, Len( aItems ) )

   IF ValType( aItems[ 1 ] ) == "B"
      cMeniItem := Eval( aItems[ 1 ] )
   ELSE
      cMeniItem := aItems[ 1 ]
   ENDIF
   nLength := Len( cMeniItem ) + 1

   IF lInvert == NIL
      lInvert := .F.
   ENDIF

   cLocalColor  := iif( lInvert, f18_color_invert(), f18_color_normal() )
   cLocalInvertedColor := iif( lInvert, f18_color_normal(), f18_color_invert() )

   cOldColor := SetColor( cLocalColor )

   // Ako se meni zove prvi put, upisi ga na stek
   IF Len( aMenuStack ) == 0 .OR. ( Len( aMenuStack ) <> 0 .AND. cMeniId <> ( StackTop( aMenuStack ) )[ 1 ] )
      IF lFiksneKoordinate
         box_x_koord( aFixKoo[ 1 ] )
         box_y_koord(  aFixKoo[ 2 ] )
      ELSE

         Calc_xy( nN1, nLength ) // odredi koordinate menija
      ENDIF

      StackPush( aMenuStack, { cMeniId, ;
         box_x_koord(), ;
         box_y_koord(), ;
         SaveScreen( box_x_koord(), box_y_koord(), box_x_koord() + nN1 + 2 - iif( lFiksneKoordinate, 1, 0 ), box_y_koord() + nLength + 4 - iif( lFiksneKoordinate, 1, 0 ) ), ;
         nItemNo, ;
         cHelpT;
         } )

   ELSE
      aMenu := StackTop( aMenuStack ) // Ako se meni ne zove prvi put, uzmi koordinate sa steka
      box_x_koord( aMenu[ 2 ] )
      box_y_koord(  aMenu[ 3 ] )

   END IF

   SetColor( f18_color_invert() )

   IF nItemNo == 0
      CentrTxt( h[ 1 ], f18_max_rows() - 1 )
   END IF

   SetColor( cLocalColor )

   nItemNo := meni_0_inkey(  box_x_koord() + 1, box_y_koord() + 2, box_x_koord() + nN1 + 1, box_y_koord() + nLength + 1, aItems, nItemNo, .T., lFiksneKoordinate )


   nTItemNo := nItemNo // nTItemNo := RetItem( nItemNo )

   aMenu := StackTop( aMenuStack )
   box_x_koord( aMenu[ 2 ] )
   box_y_koord( aMenu[ 3 ] )
   aMenu[ 5 ] := nTItemNo

   @ box_x_koord(), box_y_koord() TO box_x_koord() + nN1 + 1, box_y_koord() + nLength + 3

   IF nTItemNo <> 0 // Ako nije pritisnuto ESC, <-, ->, oznaci izabranu opciju
      IF ValType( aItems[ nTItemNo ] ) == "B"
         cMeniItem := Eval( aItems[ nTItemNo ] )
      ELSE
         cMeniItem := aItems[ nTItemNo ]
      ENDIF
      SetColor( cLocalInvertedColor )
      @ box_x_koord() + Min( nTItemNo, nMaxVR ), box_y_koord() + 1 SAY8 " " + cMeniItem + " "
      @ box_x_koord() + Min( nTItemNo, nMaxVR ), box_y_koord() + 2 SAY ""
   END IF

   nChar := LastKey()

   IF nChar == K_ESC .OR. nTItemNo == 0 .OR. nTItemNo == nPovratak  // Ako je ESC meni treba odmah izbrisati (nItemNo=0),  skini meni sa steka
      @ box_x_koord(), box_y_koord() CLEAR TO box_x_koord() + nN1 + 2 - iif( lFiksneKoordinate, 1, 0 ), box_y_koord() + nLength + 4 - iif( lFiksneKoordinate, 1, 0 )
      aMenu := StackPop( aMenuStack )

      RestScreen( box_x_koord(), box_y_koord(), box_x_koord() + nN1 + 2 - iif( lFiksneKoordinate, 1, 0 ), box_y_koord() + nLength + 4 - iif( lFiksneKoordinate, 1, 0 ), aMenu[ 4 ] )
   END IF

   SetColor( cOldColor )
   Set( _SET_DEVICE, cPom )

   RETURN nItemNo


/*
--FUNCTION retitem( nItemNo )

   LOCAL nRetItem
   LOCAL cAction

   DO CASE
   CASE RANGE( nItemNo, 10000, 10999 )
      cAction := "K_CTRL_N"
   CASE RANGE( nItemNo, 20000, 20999 )
      cAction := "K_F2"
   CASE RANGE( nItemNo, 30000, 30999 )
      cAction := "K_CTRL_T"
   OTHERWISE
      cAction := ""
   ENDCASE

   DO CASE
   CASE cAction == "K_CTRL_N"
      nRetItem := nItemNo - 10000
   CASE cAction == "K_F2"
      nRetItem := nItemNo - 20000
   CASE cAction == "K_CTRL_T"
      nRetItem := nItemNo - 30000
   OTHERWISE
      nRetItem := nItemNo
   ENDCASE

   RETURN nRetItem
*/


FUNCTION meni_0_inkey( nX1, nY1, nX2, nY2, aItems, nItemNo, lOkvir, lFiksneKoordinate )

   LOCAL nI, nWidth, nLen, nOldCurs, cOldColor, nOldItemNo, cSavC
   LOCAL nGornja
   LOCAL nVisina
   LOCAL cMeniItem

   // LOCAL nCtrlKeyVal := 0
   LOCAL nChar
   LOCAL lExitFromMeni

   hb_default( @lOkvir, .F. ) // iscrtavanje okvira

   IF nItemNo == 0
      RETURN nItemNo
   ENDIF

   lExitFromMeni := .F.

   nOldCurs := iif( SetCursor() == 0, 0, iif( ReadInsert(), 2, 1 ) )
   cOldColor := SetColor()
   SET CURSOR OFF

   @ nX1, nY1 CLEAR TO nX2 - 1, nY2

   DO WHILE .T.

      nWidth := nY2 - nY1
      nLen := Len( aItems )
      nVisina := nX2 - nX1
      nGornja := iif( nItemNo > nVisina, nItemNo - nVisina + 1, 1 )

      IF lOkvir
         meni_0_okvir( nX1, nY1, nX2, nY2, lFiksneKoordinate )
      ENDIF

      IF in_calc()
         hb_idleSleep( 0.5 )
         LOOP
      ENDIF

      IF nVisina < nLen
         @  nX2, nY1 + Int( nWidth / 2 ) SAY iif( nGornja == 1, " ^ ", iif( nItemNo == nLen, " v ", " v " ) )
         @  nX1 - 1, nY1 + Int( nWidth / 2 ) SAY iif( nGornja == 1, " v ", iif( nItemNo == nLen, " ^ ", " ^ " ) )
      ENDIF

      FOR nI := nGornja TO nVisina + nGornja - 1
         IF nI == nItemNo
            IF Left( cOldColor, 3 ) == Left( f18_color_normal(), 3 )
               SetColor( f18_color_invert()  )
            ELSE
               SetColor( f18_color_normal() )
            ENDIF
         ELSE
            SetColor( cOldColor )
         ENDIF
         IF nLen >= nI
            IF ValType( aItems[ nI ] ) == "B"
               cMeniItem := Eval( aItems[ nI ] )
            ELSE
               cMeniItem := aItems[ nI ]
            ENDIF
            @ nX1 + nI - nGornja, nY1 SAY PadRU( cMeniItem, nWidth )
         ENDIF
      NEXT

      SetColor( f18_color_invert() )
      SetColor( cOldColor )

      IF lExitFromMeni
         EXIT
      ENDIF

      nChar := Inkey( 0 )

      IF ValType( goModul ) == "O"
         goModul:GProc( nChar )
      ENDIF

      nOldItemNo := nItemNo
      DO CASE
      CASE nChar == K_ESC
         nItemNo := 0
         EXIT
      CASE nChar == K_HOME
         nItemNo := 1
      CASE nChar == K_END
         nItemNo := nLen
      CASE nChar == K_DOWN
         nItemNo++
      CASE nChar == K_UP
         nItemNo--

      CASE nChar == K_ENTER
         EXIT

      CASE IsAlpha( Chr( nChar ) ) .OR. IsDigit( Chr( nChar ) )
         FOR nI := 1 TO nLen
            IF IsDigit( Chr( nChar ) ) // cifra
               IF Chr( nChar ) $ Left( aItems[ nI ], 3 ) // provjera postojanja
                  nItemNo := nI  // broja u stavki samo u prva 3 karaktera
                  lExitFromMeni := .T.
               ENDIF
            ELSE // veliko slovo se trazi po citavom stringu - promijenjeno
               IF ( aItems[ nI ] <> NIL ) .AND. Upper( Chr( nChar ) ) $ Left( aItems[ nI ], 3 )
                  nItemNo := nI
                  lExitFromMeni := .T.
               ENDIF
            ENDIF
         NEXT

         // CASE nChar == K_CTRL_N
         // nCtrlKeyVal := 10000
         // EXIT

         // CASE nChar == K_F2
         // nCtrlKeyVal := 20000
         // EXIT

         // CASE nChar == K_CTRL_T
         // nCtrlKeyVal := 30000
         // EXIT

      ENDCASE

      IF nItemNo > nLen
         nItemNo--
      ENDIF
      IF nItemNo < 1; nItemNo++; ENDIF

      nGornja := iif( nItemNo > nVisina, nItemNo - nVisina + 1, 1 )

   ENDDO

   SetCursor( iif( nOldCurs == 0, 0, iif( ReadInsert(), 2, 1 ) ) )
   SetColor( cOldColor )

   RETURN nItemNo // + nCtrlKeyVal




STATIC FUNCTION meni_0_okvir( nX1, nY1, nX2, nY2, lFiksneKoordinate )

   LOCAL nI, nLength := nY2 - nY1

   // @ nX1 - 1, nY1 - 2 CLEAR TO nX2, nY2 + 2
   @ nX1, nY1 - 1 CLEAR TO nX2 - 1, nY1 - 1 // ispis lijeve praznine (#) :  |#1. opcija 1 %|
   @ nX1,  nY2     CLEAR TO nX2 - 1, nY2 + 1 // ispis desne praznine (%)  :  |#2. opcija 2 %|
   IF lFiksneKoordinate
      @ nX1 - 1, nY1 - 2 TO nX2, nY2 + 2
   ELSE

      @ nX1 - 1, nY1 - 2 TO nX2, nY2 + 2 DOUBLE // okvir duple linije

      FOR nI := 1 TO ( nX2 - nX1 + 2 )
         @ nX1 + nI - 1, nY1 + nLength + 3 SAY Chr( 177 ) // sjena desno
      NEXT
      @ nX2 + 1, nY1 - 1 SAY Replicate( Chr( 177 ), nLength + 5 ) // sjena dno

   ENDIF

   RETURN .T.
