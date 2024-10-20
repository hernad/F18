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


/*  print_lista(Zaglavlje,ImeDat,bFor,fIndex,lBezUpita)
 *

 *OPIS
 * a) Vrsi se odabir vrste izlaza  (D/N/V/E)
 * b) Formira se izlazni fajl
 * c) prikazuje se na ekranu (N,V,E) ili stampa na printer (D), ili salje
 *    PTXT-u (R)
 *
 *ULAZI
 *bFor - uslov za prikaz zapisa
 *
 *KORISTIM
 * Koristi i sljedece public varijable
 *
 *- Kol - sarzi raspored polja,
 *        npr:
 *     Kol:={0,1,0,2.............}
 *
 *- RKol (opciono)
 *      [1] broj kolone u kojoj se prikazuje (iz niza Kol)
 *      [2] naziv kolone (kolona 2 u nizu ImeKol)
 *      [3] "D" ako ne moze stati podatak u sirinu kolone tj.
 *          ko treba omoguciti prelamanje u vise redova
 *      [4] sirina kolone koja se uzima u obzir ako je [3] "D"
 *
 */

FUNCTION print_lista( Zaglavlje, ImeDat, bFor, fIndex, lBezUpita )

   LOCAL i, j, k
   LOCAL bErrorHandler
   LOCAL bLastHandler
   LOCAL objErrorInfo
   LOCAL nStr
   LOCAL nSort
   LOCAL cStMemo := "N"
   LOCAL aKol := {}
   LOCAL xPom
   LOCAL nDuz1
   LOCAL nDuz2
   LOCAL cRazmak := "N"
   LOCAL nSlogova
   LOCAL nSirIzvj := 0

   PRIVATE cNazMemo := ""
   PRIVATE RedBr
   PRIVATE Getlist := {}

   IF lBezUpita == nil
      lBezUpita := .F.
   ENDIF
   IF fIndex == nil
      fIndex := .T.
   ENDIF
   IF Zaglavlje == nil
      Zaglavlje := ""
   ENDIF
   IF ImeDat == nil
      ImeDat := ""
   ENDIF
   IF "U" $ Type( "gOdvTab" )
      gOdvTab := "N"
   ENDIF
   IF "U" $ Type( "RKol" )
      RKol := nil
   ENDIF
   IF "U" $ Type( "gPostotak" )
      gPostotak := "N"
   ENDIF

   IF !lBezUpita
      Zaglavlje := PadR( Zaglavlje, 70 )
      nColStr := 80
      nSort := "ID       "
      Box(, 8, 76, .T. )
      set_cursor_on()
      @ box_x_koord() + 1, box_y_koord() + 20 SAY8 "Tekst koji se štampa kao naslov:"
      @ box_x_koord() + 2, box_y_koord() + 3  GET Zaglavlje
      cValid := ""
      IF fIndex
         FOR i := 1 TO 10
            IF Upper( ordName( i ) ) <> "BRISAN"
               cValid += "#" + Upper( ordName( i ) )
            ENDIF
         NEXT
         @ box_x_koord() + 3, box_y_koord() + 3  SAY8 "Način sortiranja (ID/NAZ):" GET nSort VALID   AllTrim( nSort ) $ cValid PICT "@!"
      ENDIF
      @ box_x_koord() + 4, box_y_koord() + 3  SAY8 "Odvajati redove linijom (D/N) ?" GET gOdvTab VALID gOdvTab $ "DN" PICTURE "@!"
      @ box_x_koord() + 5, box_y_koord() + 3  SAY8 "Razmak između redova    (D/N) ?" GET cRazmak VALID cRazmak $ "DN" PICTURE "@!"
      READ

   ENDIF

   lImaSifK := .F.
   IF AScan( ImeKol, {| x | Len( x ) > 2 .AND. ValType( x[ 3 ] ) == "C" .AND. "SIFK->" $ x[ 3 ] } ) <> 0
      lImaSifK := .T.
   ENDIF

   IF Len( ImeKol[ 1 ] ) > 2 .AND. !lImaSifK

      PRIVATE aStruct := dbStruct(), aNDuzine[ FCount(), 2 ], cTxt2
      FOR i := 1 TO Len( aStruct )

         k := AScan( ImeKol, {| x | Field( i ) == Upper( x[ 3 ] ) } ) // treci element jednog reda u matrici imekol

         j := iif( k <> 0, Kol[ k ], 0 )

         IF j <> 0
            xPom := Eval( ImeKol[ k, 2 ] )
            aNDuzine[ j, 1 ] := Max( Len( ImeKol[ k, 1 ] ), Len( iif( ValType( xPom ) == "D", DToC( xPom ), IF( ValType( xPom ) == "N", Str( xPom ), xPom ) ) ) )
            IF aNDuzine[ j, 1 ] > 100
               aNDuzine[ j, 1 ] := 100
               aNDuzine[ j, 2 ] := { ImeKol[ k, 1 ], ImeKol[ k, 2 ], .F., ;
                  "P", ;
                  aNDuzine[ j, 1 ], iif( aStruct[ i, 2 ] == "N", aStruct[ i, 4 ], 0 ) }
            ELSE
               aNDuzine[ j, 2 ] := { ImeKol[ k, 1 ], ImeKol[ k, 2 ], .F., ValType( Eval( ImeKol[ k, 2 ] ) ), aNDuzine[ j, 1 ], iif( aStruct[ i, 2 ] == "N", aStruct[ i, 4 ], 0 ) }
            ENDIF
         ELSE
            IF aStruct[ i, 2 ] == "M"
               @ box_x_koord() + 6, box_y_koord() + 3 SAY8 "Štampati " + aStruct[ i, 1 ] GET cStMemo PICT "@!" VALID cStMemo $ "DN"
               READ
               IF cStMemo == "D"
                  cNazMemo := aStruct[ i, 1 ]
               ENDIF
            ENDIF
         ENDIF
      NEXT

      AAdd( aKol, { "R.br.", {|| Str( RedBr, 4 ) + "." }, .F., "C", 5, 0, 1, 1 } )
      j := 1
      FOR i := 1 TO Len( aStruct )
         IF aNDuzine[ i, 1 ] != nil
            ++j
            AAdd( aNDuzine[ i, 2 ], 1 ); AAdd( aNDuzine[ i, 2 ], j )
            AAdd( aKol, aNDuzine[ i, 2 ] )
         ENDIF
      NEXT

      IF !Empty( cNazMemo )
         AAdd( aKol, { cNazMemo, {|| cTxt2 }, .F., "P", 30, 0, 1, ++j } )
      ENDIF
   ELSE
      AAdd( aKol, { "R.br.", {|| Str( RedBr, 4 ) + "." }, .F., "C", 5, 0, 1, 1 } )
      aPom := {}
      FOR i := 1 TO Len( Kol ); AAdd( aPom, { Kol[ i ], i } ); NEXT
      ASort( aPom,,, {| x, y | x[ 1 ] < y[ 1 ] } )
      j := 0
      FOR i := 1 TO Len( Kol )
         IF aPom[ i, 1 ] > 0
            ++j
            aPom[ i, 1 ] := j
         ENDIF
      NEXT
      ASort( aPom,,, {| x, y | x[ 2 ] < y[ 2 ] } )
      FOR i := 1 TO Len( Kol )
         Kol[ i ] := aPom[ i, 1 ]
      NEXT
      aPom := {}
      FOR i := 1 TO Len( Kol )
         IF Kol[ i ] > 0
            xPom := Eval( ImeKol[ i, 2 ] )
            IF Len( ImeKol[ i ] ) > 2 .AND. ValType( ImeKol[ i, 3 ] ) == "C" .AND. "SIFK->" $ ImeKol[ i, 3 ]
               AAdd( aKol, { ImeKol[ i, 1 ], ImeKol[ i, 2 ], IF( Len( ImeKol[ i ] ) > 2 .AND. ValType( ImeKol[ i, 3 ] ) == "L", ImeKol[ i, 3 ], .F. ), ;
                  IF( SIFK->veza == "N", "P", ValType( xPom ) ), ;
                  IF( SIFK->veza == "N", SIFK->duzina + 1, Max( SIFK->duzina, Len( Trim( ImeKol[ i, 1 ] ) ) ) ), ;
                  IF( ValType( xPom ) == "N", SIFK->f_decimal, 0 ), 1, Kol[ i ] + 1 } )
               LOOP
            ENDIF
            nDuz1 := IF( Len( ImeKol[ i ] ) > 4 .AND. ValType( ImeKol[ i, 5 ] ) == "N", ImeKol[ i, 5 ], LENx( xPom ) )
            nDuz2 := IF( Len( ImeKol[ i ] ) > 5 .AND. ValType( ImeKol[ i, 6 ] ) == "N", ImeKol[ i, 6 ], IF( ValType( xPom ) == "N", nDuz1 - At( ".", Str( xPom ) ), 0 ) )
            nPosRKol := 0
            IF RKol != NIL .AND. TrebaPrelom( Kol[ i ], @nPosRKol )
               AAdd( aKol, { ImeKol[ i, 1 ], ImeKol[ i, 2 ], IF( Len( ImeKol[ i ] ) > 2, ImeKol[ i, 3 ], .F. ), ;
                  "P", ;
                  RKol[ nPosRKol, 4 ], nDuz2, 1, Kol[ i ] + 1 } )
            ELSE
               AAdd( aKol, { ImeKol[ i, 1 ], ImeKol[ i, 2 ], IF( Len( ImeKol[ i ] ) > 2 .AND. ValType( ImeKol[ i, 3 ] ) == "L", ImeKol[ i, 3 ], .F. ), ;
                  IF( Len( ImeKol[ i ] ) > 3 .AND. ValType( ImeKol[ i, 4 ] ) == "C" .AND. ImeKol[ i, 4 ] $ "N#C#D#P", ImeKol[ i, 4 ], IF( nDuz1 > 100, "P", ValType( xPom ) ) ), ;
                  IF( nDuz1 > 100, 100, nDuz1 ), nDuz2, 1, Kol[ i ] + 1 } )
            ENDIF
         ENDIF
      NEXT
   ENDIF

   BoxC()
   IF !lBezUpita
      IF !start_print()
         RETURN .F.
      ENDIF
   ENDIF

   FOR i := 1 TO Len( aKol )
      IF aKol[ i, 7 ] == 1
         nSirIzvj += ( aKol[ i, 5 ] + 1 )
      ENDIF
   NEXT
   ++nSirIzvj

   IF "U" $ Type( "gnLMarg" )
      gnLMarg := 0
   ENDIF
   IF "U" $ Type( "gA43" )
      gA43 := "4"
   ENDIF
   IF "U" $ Type( "gTabela" )
      gTabela := 0
   ENDIF
   IF "U" $ Type( "gOstr" )
      gOstr := "D"
   ENDIF

   IF lBezUpita
      gOstr := "N"
   ENDIF

   IF gPrinter == "L" .OR. gA43 == "4" .AND. nSirIzvj > 165
      gPO_Land()
   ENDIF

   IF !Empty( Zaglavlje )
      QQOut( Space( gnLMarg ) )
      gP10CPI()
      gPB_ON()
      QQOut( PadC( AllTrim( Zaglavlje ), 79 * IIF( gA43 == "4", 1, 2 ) - gnLMarg ) )
      gPB_OFF()
      QOut()
   ENDIF
   IF fIndex
      FOR i := 1 TO 10
         IF Upper( Trim( ordKey( i ) ) ) == Upper( Trim( nSort ) )
            nSort := i
            EXIT
         ENDIF
      NEXT
      dbSetOrder( nSort )
   ENDIF
   COUNT TO nSlogova
   GO TOP
   RedBr := 0
   IF cRazmak == "D"
      AAdd( aKol, { "", {|| " " }, .F., "C", aKol[ 1, 5 ], 0, 2, 1 } )
   ENDIF


   print_lista_2( aKol, {|| ZaRedBlok() }, gnLMarg, iif( Upper( Right( AllTrim( Set( _SET_PRINTFILE ) ), 3 ) ) == "RTF", 9, gTabela ), ;
      , iif( gPrinter == "L", "L4", gA43 == "4" ), ,, iif( gOstr == "N", - 1, ),, gOdvTab == "D",, nSlogova, "Kreiranje tabele" )

   IF ( gPrinter == "L" .OR. gA43 == "4" .AND. nSirIzvj > 165 )
      gPO_Port()
   ENDIF

   IF !lBezUpita
      end_print()
   ENDIF

   RETURN NIL


FUNCTION ZaRedBlok()

   ++RedBr

   WhileEvent( RedBr, NIL )

   IF !Empty( cNazMemo )
      cTxt2 := UkloniRet( cNazMemo, .F. )
   ENDIF

   RETURN .T.


FUNCTION UkloniRet( xTekst, lPrazno )

   LOCAL cTekst

   IF lPrazno == nil; lPrazno := .F. ; ENDIF
   IF ValType( xTekst ) == "B"
      cTekst := StrTran( Eval( xTekst ), Chr( 13 ) + Chr( 10 ), "" )
   ELSE
      cTekst := StrTran( &xTekst, Chr( 13 ) + Chr( 10 ), "" )
   ENDIF
   IF lPrazno
      cTekst := StrTran( cTekst, NRED_DOS, NRED_DOS + Space( 7 ) )
   ELSE
      cTekst := StrTran( cTekst, NRED_DOS, " " )
   ENDIF

   RETURN cTekst



STATIC FUNCTION Karaktera( cK )

   IF cK == "10"
      RETURN 80
   ELSEIF cK == "12"
      RETURN 92
   ELSEIF cK == "17"
      RETURN 132
   ELSEIF cK == "20"
      RETURN 156
   ENDIF


FUNCTION sifarnik_izbor_polja( Kol, cImef )

   LOCAL i
   PRIVATE aOBjG, cKolona, Kl

   Kl := Array( Len( Kol ) )
   ACopy( Kol, Kl )

   IF File( cImef + MEMOEXT )
      RESTORE FROM &cImeF ADDITIVE // ucitavanje string kolona
      FOR i := 1 TO Len( Kl )
         IF ValType( cKolona ) == "C"
            Kl[ i ] := Val( SubStr( cKolona, ( i - 1 ) * 2 + 1, 2 ) )
         ELSE
            Kl[ i ] := 0
         ENDIF
      NEXT
   ENDIF

   nDiv := Int( Len( Kol ) / 3 + 1 )
   wx := nDiv + 2

   BOX( '', wx, 77, .T., "", "Izbor polja za prikaz" )
   set_cursor_on()

   Odg = ' '

   aObjG := Array( Len( Kl ) + 1 )

   FOR i := 1 TO Len( Kl )
      j := ( i - 1 ) % nDiv
      cIDx := AllTrim( Str( i ) )
      IF i / nDiv <= 1
         ystep = 25
      ELSEIF i / nDiv <= 2
         yStep = 51
      ELSEIF i / nDiv <= 3
         yStep = 76
      ELSE
         ? "Preveliki broj kolona ...(izl.prg)"
         QUIT_1
      ENDIF
      aObjG[ i ] := GetNew( box_x_koord() + j + 1, box_y_koord() + yStep )
      @ aObjG[ i ]:row, ( aObjG[ i ]:col ) - 22 SAY PadR( AllTrim( ImeKol[ i, 1 ] ), 20 )
      aObjG[ i ]:name := "Kl[" + cIdx + "]"

      b1 := "Kl[" + cIdx + "]"                                                    // 3
      aObjG[ i ]:block := {| cVal | IF( PCount() == 0, &b1., &b1. := cVal ) }               // 3

      aObjG[ i ]:PICTURE := "99"
      aObjG[ i ]:postBlock := {| nVal | DobraKol( @Kl, &cIdx. ) }

      aObjG[ i ]:display()
   NEXT

   aObjG[ Len( Kl ) + 1 ] := GetNew()
   aObjG[ Len( Kl ) + 1 ]:row := box_x_koord() + wx
   aObjG[ Len( Kl ) + 1 ]:col := box_y_koord() + 40
   aObjG[ Len( Kl ) + 1 ]:name := "Odg"
   aObjG[ Len( Kl ) + 1 ]:block := {| cVal | iif( cVal == NIL, Odg, Odg := cVal ) }
   aObjG[ Len( Kl ) + 1 ]:display()
   @ box_x_koord() + wx, box_y_koord() + 8 SAY 'Kraj - <PgDown>, Nuliraj-<F5>'
   SET KEY K_F5  TO Nuliraj()
   ReadModal( aObjG )
   SET KEY K_F5
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   END IF

   cKolona := ""
   AEval( Kl, {| broj | cKolona := cKolona + Str( Broj, 2 ) } )
   // Pretvaranje matrice u jedan string radi mogu}nosti pohranjivanja
   // matrice kao karakterne memorijske varijable
   SAVE  ALL LIKE cKolona TO &cImeF

   ACopy( Kl, Kol )

   RETURN .T.


/*
 * function DobraKol(Kol,i)
 * Nalazenje kolona koje se stampaju, Koristi je sifarnik_izbor_polja
 */

FUNCTION DobraKol( Kol, i )

   LOCAL nNum
   LOCAL k

   IF Kol[ i ] = 0 ; RETURN .T. ; END IF
   nNum := 0
   FOR k := 1 TO Len( Kol )
      IF Kol[ i ] = Kol[ k ] ; nNum++; END IF
   NEXT
   IF nNum > 1
      RETURN .F.
   ELSE
      IF Kol[ i ] > Len( Kol )
         RETURN .F.
      ENDIF
      RETURN .T.
   END IF

   RETURN .T.


FUNCTION Nuliraj()

   LOCAL i

   FOR i := 1 TO Len( Kl )
      Kl[ i ] := 0
   NEXT
   AEval( aObjG, {| oE |  oE:Display() } )

   RETURN .T.


STATIC FUNCTION TrebaPrelom( nPos, nPosRKol )

   LOCAL lVrati := .F., i := 0

   FOR i := 1 TO Len( RKol )
      IF RKol[ i, 1 ] == nPos
         IF RKol[ i, 3 ] == "D"; lVrati := .T. ; nPosRKol := i ; ENDIF
         EXIT
      ENDIF
   NEXT

   RETURN lVrati
