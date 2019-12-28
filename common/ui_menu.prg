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
      nIzbor := meni_0( cIzp, aOpc, aOpcExe, nIzbor, .F. )

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

      ENDCASE

   ENDDO

   RETURN .T.



FUNCTION f18_menu_sa_priv_vars_opc_opcexe_izbor( cIzp, lMain )

   // pretpostavljamo privatne varijable Izbor, Opc, OpcExe

   RETURN f18_menu( cIzp, lMain, Izbor, Opc, OpcExe )



FUNCTION meni_fiksna_lokacija( nX1, nY1, aOpc, nIzb )

   LOCAL nOpcija := 0, nYm := 0
   LOCAL nX2

   nOpcija := Len( aOpc )
   AEval( aOpc, {| x | iif( Len( x ) > nYm, nYm := Len( x ), ) } )

   nX2 := nX1 + nOpcija + 1

   IF nX2 > f18_max_rows() - 2
      nX2 := f18_max_rows() - 2
   ENDIF

   box_crno_na_zuto( nX1, nY1, nX2, nY1 + nYm + 1,,,,,, 0 )
   nIzb := meni_0_inkey_draw( nX1 + 1, nY1 + 1, nX2, nY1 + nYm, aOpc, NIL, nIzb )
   box_crno_na_zuto_end()

   RETURN nIzb

/*
 *
 *  Prikazuje zadati meni, vraca odabranu opciju
 *
 *  cMeniId  - identifikacija menija     C
 *  aOpc   - niz opcija za nIzbor       {}
 *  nOdabranaStavka  - Broj pocetne pozicije     N
 *  lInvert     - da li je meni f18_color_invert() ovan  L
 *
 *  Broj izabrane opcije, 0 kraj
 *

*/

FUNCTION meni_0( cMeniId, aOpc, aOpcExe, nOdabranaStavka, lInvert )

   LOCAL nMeniSirina
   LOCAL nUIMeniVelicina
   LOCAL cOldColor
   LOCAL cLocalColor
   LOCAL cLocalInvertedColor
   LOCAL nChar
   LOCAL cMeniItem

   // LOCAL ItemSav
   LOCAL aMenu := {}
   LOCAL cPom := Set( _SET_DEVICE )
 
   SET DEVICE TO SCREEN

   /*
   IF nPovratak == NIL
      nPovratak := 0
   ENDIF
   IF nMaxVR == NIL
      nMaxVR := 16
   ENDIF
   IF aFiksneKoordinate == NIL
      aFiksneKoordinate := {}
   ENDIF
   IF Len( aFiksneKoordinate ) == 2
      lFiksneKoordinate := .T.
   ENDIF
   */

   nUIMeniVelicina := iif( Len( aOpc ) > 18, 18, Len( aOpc ) )

   IF ValType( aOpc[ 1 ] ) == "B"
      cMeniItem := Eval( aOpc[ 1 ] )
   ELSE
      cMeniItem := aOpc[ 1 ]
   ENDIF
   nMeniSirina := Len( cMeniItem ) + 1

   IF lInvert == NIL
      lInvert := .F.
   ENDIF

   cLocalColor  := iif( lInvert, f18_color_invert(), f18_color_normal() )
   cLocalInvertedColor := iif( lInvert, f18_color_normal(), f18_color_invert() )

   cOldColor := SetColor( cLocalColor )
   
   // Ako se meni zove prvi put, upisi ga na stek
   IF Len( aMenuStack ) == 0 .OR. ( Len( aMenuStack ) <> 0 .AND. cMeniId <> ( StackTop( aMenuStack ) )[ 1 ] )
      
      ui_calc_xy( nUIMeniVelicina, nMeniSirina ) // odredi koordinate menija
      
      StackPush( aMenuStack, { cMeniId, ;
         box_x_koord(), ;
         box_y_koord(), ;
         SaveScreen( box_x_koord(), box_y_koord(), box_x_koord() + nUIMeniVelicina + 2, box_y_koord() + nMeniSirina + 4), ;
         nOdabranaStavka ;
         } )

   ELSE
      aMenu := StackTop( aMenuStack ) // Ako se meni ne zove prvi put, uzmi koordinate sa steka
      box_x_koord( aMenu[ 2 ] )
      box_y_koord( aMenu[ 3 ] )

   END IF
   
   SetColor( cLocalColor )
   nOdabranaStavka := meni_0_inkey_draw(  box_x_koord() + 1, box_y_koord() + 2, box_x_koord() + nUIMeniVelicina + 1, box_y_koord() + nMeniSirina + 1, aOpc, aOpcExe, nOdabranaStavka, .T.)

   //nTekucaStavkaMeni := nOdabranaStavka // nTekucaStavkaMeni := RetItem( nOdabranaStavka )

   aMenu := StackTop( aMenuStack )
   box_x_koord( aMenu[ 2 ] )
   box_y_koord( aMenu[ 3 ] )
   aMenu[ 5 ] := nOdabranaStavka

   @ box_x_koord(), box_y_koord() TO box_x_koord() + nUIMeniVelicina + 1, box_y_koord() + nMeniSirina + 3

   /*
   IF nTekucaStavkaMeni <> 0 // Ako nije pritisnuto ESC, <-, ->, oznaci izabranu opciju
      IF ValType( aOpc[ nTekucaStavkaMeni ] ) == "B"
         cMeniItem := Eval( aOpc[ nTekucaStavkaMeni ] )
      ELSE
         cMeniItem := aOpc[ nTekucaStavkaMeni ]
      ENDIF
      SetColor( cLocalInvertedColor )
      @ box_x_koord() + Min( nTekucaStavkaMeni, nMaxVR ), box_y_koord() + 1 SAY8 " " + cMeniItem + " "
      @ box_x_koord() + Min( nTekucaStavkaMeni, nMaxVR ), box_y_koord() + 2 SAY ""
   END IF

   nChar := LastKey()
   */
  
   IF nOdabranaStavka == 0 //.OR. nTekucaStavkaMeni == nPovratak  // Ako je ESC meni treba odmah izbrisati (nOdabranaStavka=0),  skini meni sa steka
      @ box_x_koord(), box_y_koord() CLEAR TO box_x_koord() + nUIMeniVelicina + 2, box_y_koord() + nMeniSirina + 4
      aMenu := StackPop( aMenuStack )
      RestScreen( box_x_koord(), box_y_koord(), box_x_koord() + nUIMeniVelicina + 2, box_y_koord() + nMeniSirina + 4, aMenu[ 4 ] )
   END IF

   SetColor( cOldColor )
   Set( _SET_DEVICE, cPom )

   RETURN nOdabranaStavka


/*
--FUNCTION retitem( nOdabranaStavka )

   LOCAL nRetItem
   LOCAL cAction

   DO CASE
   CASE RANGE( nOdabranaStavka, 10000, 10999 )
      cAction := "K_CTRL_N"
   CASE RANGE( nOdabranaStavka, 20000, 20999 )
      cAction := "K_F2"
   CASE RANGE( nOdabranaStavka, 30000, 30999 )
      cAction := "K_CTRL_T"
   OTHERWISE
      cAction := ""
   ENDCASE

   DO CASE
   CASE cAction == "K_CTRL_N"
      nRetItem := nOdabranaStavka - 10000
   CASE cAction == "K_F2"
      nRetItem := nOdabranaStavka - 20000
   CASE cAction == "K_CTRL_T"
      nRetItem := nOdabranaStavka - 30000
   OTHERWISE
      nRetItem := nOdabranaStavka
   ENDCASE

   RETURN nRetItem
*/


FUNCTION meni_0_inkey_draw( nX1, nY1, nX2, nY2, aOpc, aOpcExe, nOdabranaStavka, lOkvir )

   LOCAL nI, nWidth, nBrStavkiMeni, nOldCurs, cOldColor, nOldItemNo, cSavC
   LOCAL nGornja
   LOCAL nUIMeniVelicina
   LOCAL cMeniItem
   LOCAL cPrvaTriSlova
   LOCAL lPrvoCrtanje
   LOCAL lIzvrsiOpciju
   LOCAL cColor
   LOCAL lNagore, lNaDole
   // LOCAL nCtrlKeyVal := 0
   LOCAL nChar
   LOCAL nStart, nEnd, nStep
   LOCAL aRows
   //LOCAL lExitFromMeni

   hb_default( @lOkvir, .F. ) // iscrtavanje okvira

   //IF nOdabranaStavka == 0
   //   RETURN nOdabranaStavka
   //ENDIF

   //lExitFromMeni := .F.
   lIzvrsiOpciju := .F.
   lPrvoCrtanje := .T.

   nOldCurs := iif( SetCursor() == 0, 0, iif( ReadInsert(), 2, 1 ) )
   cOldColor := SetColor()
   
   @ nX1, nY1 CLEAR TO nX2 - 1, nY2
   set_cursor_off()

   lNaGore := .F.
   lNaDole := .T.
   DO WHILE .T.

      nWidth := nY2 - nY1
      nBrStavkiMeni := Len( aOpc )
      nUIMeniVelicina := nX2 - nX1
      nGornja := iif( nOdabranaStavka > nUIMeniVelicina, nOdabranaStavka - nUIMeniVelicina + 1, 1 )

      IF lOkvir
        meni_0_okvir( nX1, nY1, nX2, nY2, .F. )
      ENDIF

      IF in_calc()
         hb_idleSleep( 0.5 )
         LOOP
      ENDIF

      IF nUIMeniVelicina < nBrStavkiMeni
         @  nX2, nY1 + Int( nWidth / 2 ) SAY iif( nGornja == 1, " ^ ", iif( nOdabranaStavka == nBrStavkiMeni, " v ", " v " ) )
         @  nX1 - 1, nY1 + Int( nWidth / 2 ) SAY iif( nGornja == 1, " v ", iif( nOdabranaStavka == nBrStavkiMeni, " ^ ", " ^ " ) )
      ENDIF

      IF lNaGore
         nEnd := nGornja 
         nStart := nUIMeniVelicina + nGornja - 1
         nStep := -1
      ELSE   
         nStart := nGornja 
         nEnd := nUIMeniVelicina + nGornja - 1
         nStep := 1
      ENDIF


      FOR nI := nStart TO nEnd STEP nStep
         IF nI <= nBrStavkiMeni .AND. (lPrvoCrtanje .OR. range( nI, nOdabranaStavka-1, nOdabranaStavka+1))
            // range - ako nije prvo crtanje, onda treba samo ispis stavke iznad, ispod i odabir

               IF nI == nOdabranaStavka // odabrana stavka
                  IF Left( cOldColor, 3 ) == Left( f18_color_normal(), 3 )
                     cColor := f18_color_invert()
                  ELSE
                     cColor := f18_color_normal()
                  ENDIF
               ELSE
                  cColor := cOldColor
               ENDIF
               
               IF ValType( aOpc[ nI ] ) == "B"
                  cMeniItem := Eval( aOpc[ nI ] )
               ELSE
                  cMeniItem := aOpc[ nI ]
               ENDIF
               @ nX1 + nI - nGornja, nY1 SAY PadRU( cMeniItem, nWidth ) COLOR cColor
              
         ENDIF
      NEXT

      IF lIzvrsiOpciju
         IF aOpcExe <> NIL // execute opcija
           IF aOpcExe[ nOdabranaStavka ] <> NIL

            @ nX1 + Min( nOdabranaStavka, 16 ) - 1, nY1 + 1 SAY ""
            IF ValType( aOpcExe[ nOdabranaStavka ] ) == "B"
               Eval( aOpcExe[ nOdabranaStavka ] )
            ELSE
               MsgBeep( "meni čudan ?" + hb_ValToStr( nOdabranaStavka ) )
            ENDIF
           ENDIF
         ENDIF
      ENDIF

      // SetColor( f18_color_invert() )
      SetColor( cOldColor )

      //IF lExitFromMeni
      //  EXIT
      //ENDIF

      lIzvrsiOpciju := .F.

      nChar := hb_keyStd(Inkey( 0, hb_bitOr( hb_bitOr( INKEY_KEYBOARD, INKEY_LDOWN ), HB_INKEY_EXT ) )  )

      //info_bar("mouse", "mrow:" + Str(MRow(),3,0) + "mcol:" + Str(MCol(),3,0)) 
      IF nChar == K_LDBLCLK
         FOR nI := nStart TO nEnd STEP nStep
            IF MRow() == nX1 + nI - nGornja
               nChar := -1
               lIzvrsiOpciju := .T.
               IF nI > nOdabranaStavka
                  lNaDole := .T.
                  lNaGore := .F.
               ELSE
                  lNaGore := .F.
                  lNaDole := .T.
               ENDIF
               nOdabranaStavka := nI
            ENDIF
         NEXT
      ENDIF


      IF ValType( goModul ) == "O"
         goModul:GProc( nChar )
      ENDIF
 
      
      // nOldItemNo := nOdabranaStavka
      DO CASE
      CASE nChar == K_ESC
         nOdabranaStavka := 0
         EXIT
      CASE nChar == K_HOME
         nOdabranaStavka := 1
         lNaGore := .T.
      CASE nChar == K_END
         nOdabranaStavka := nBrStavkiMeni
         lNaDole := .T.
      CASE nChar == K_DOWN
         nOdabranaStavka++
         lNaDole := .T.
      CASE nChar == K_UP
         nOdabranaStavka--
         lNaGore := .T.
      CASE nChar == K_ENTER
         lIzvrsiOpciju := .T.

      CASE IsAlpha( Chr( nChar ) ) .OR. IsDigit( Chr( nChar ) )
         FOR nI := 1 TO nBrStavkiMeni
            IF IsDigit( Chr( nChar ) ) // cifra
               IF ValType( aOpc[ nI ] ) == "C"
                  cPrvaTriSlova := Left( aOpc[ nI ], 3 )
               ELSE
                  cPrvaTriSlova := Left( Eval( aOpc[ nI ] ), 3 )
               ENDIF
               IF Chr( nChar ) $ cPrvaTriSlova
                  IF nI > nOdabranaStavka
                     lNaDole := .T.
                  ELSE
                     lNaGore := .T.
                  ENDIF
                  nOdabranaStavka := nI  // broja u stavki samo u prva 3 karaktera
                  lIzvrsiOpciju := .T.
                  lPrvoCrtanje := .T.
               ENDIF
            ELSE
               IF ValType(aOpc[ nI ]) == "C"  .AND. Upper( Chr( nChar ) ) $ Left( aOpc[ nI ], 3 ) // veliko slovo se trazi u prva tri znaka
                  IF nI > nOdabranaStavka
                     lNaDole := .T.
                  ELSE
                     lNaGore := .T.
                  ENDIF
                  nOdabranaStavka := nI
                  lIzvrsiOpciju := .T.
                  lPrvoCrtanje := .T.
               ENDIF
            ENDIF
         NEXT

      ENDCASE

      IF nOdabranaStavka > nBrStavkiMeni
         nOdabranaStavka--
      ENDIF
      IF nOdabranaStavka < 1
           nOdabranaStavka++
      ENDIF

      nGornja := iif( nOdabranaStavka > nUIMeniVelicina, nOdabranaStavka - nUIMeniVelicina + 1, 1 )

      IF aOpcExe == NIL
         EXIT
      ENDIF
   ENDDO

   SetCursor( iif( nOldCurs == 0, 0, iif( ReadInsert(), 2, 1 ) ) )
   SetColor( cOldColor )

   RETURN nOdabranaStavka // + nCtrlKeyVal



STATIC FUNCTION meni_0_okvir( nX1, nY1, nX2, nY2 )

   LOCAL nI, nMeniSirina := nY2 - nY1

   // @ nX1 - 1, nY1 - 2 CLEAR TO nX2, nY2 + 2
   @ nX1, nY1 - 1 CLEAR TO nX2 - 1, nY1 - 1 // ispis lijeve praznine (#) :  |#1. opcija 1 %|
   @ nX1,  nY2   CLEAR TO nX2 - 1, nY2 + 1 // ispis desne praznine (%)  :  |#2. opcija 2 %|
   

   @ nX1 - 1, nY1 - 2 TO nX2, nY2 + 2 DOUBLE // okvir duple linije

    FOR nI := 1 TO ( nX2 - nX1 + 2 )
         @ nX1 + nI - 1, nY1 + nMeniSirina + 3 SAY Chr( 177 ) // sjena desno
    NEXT
    @ nX2 + 1, nY1 - 1 SAY Replicate( Chr( 177 ), nMeniSirina + 5 ) // sjena dno


   RETURN .T.
