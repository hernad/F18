/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "inkey.ch"


// This static maintains the "current row" for ABrowse()
STATIC nRow


FUNCTION ABrowse( aArray, xw, yw, bUserF )

   LOCAL nT, nL, nB, nR
   LOCAL n, xRet, nOldNRow, nOldCursor  // Various
   LOCAL TB                             // TBrowse object
   LOCAL nRez, nKey := 0                 // Keystroke holder

   Box(, xw, yw )

   // Preserve cursor setting, turn off cursor
   nOldCursor := SetCursor( 0 )

   // Preserve static var (just in case), set it to 1
   nOldNRow := nRow
   nRow := 1

   nT := box_x_koord() + 1
   nL := box_y_koord() + 1
   nB := box_x_koord() + xw
   nR := box_y_koord() + yw


   // Create the TBrowse object
   TB := TBrowseNew( nT, nL, nB, nR )

   // The "skip" block just adds to (or subtracts from) nRow
   // (see ASkipTest() below)
   TB:SkipBlock := {| nSkip|                                             ;
      nSkip := ASkipTest( aArray, nRow, nSkip ),   ;
      nRow += nSkip,                             ;
      nSkip                                      ;
      }

   // The "go top" block sets nRow to 1
   TB:GoTopBlock := {|| nRow := 1 }

   // The "go bottom" block sets nRow to the length of the array
   TB:GoBottomBlock := {|| nRow := Len( aArray ) }

   // Create column blocks and add TBColumn objects to the TBrowse
   // (see ABrowseBlock() below)
   FOR n = 1 TO Len( aArray[ 1 ] )
      TB:AddColumn( TBColumnNew( "", ABrowseBlock( aArray, n ) ) )
   NEXT


   // Start the event handler loop
   DO WHILE .T.
      // nKey <> K_ESC

      // Stabilize
      nKey := 0
      DO WHILE ! TB:Stabilize()
         nKey := Inkey()
         IF nKey <> 0
            EXIT
         ENDIF
      ENDDO

      IF nKey == 0
         nKey := Inkey()
      ENDIF

      IF bUserF <> NIL
         nRez := Eval( bUserF, nKey )
      ELSE
         nRez := DE_CONT
      ENDIF

      // Process the directional keys
      IF TB:Stable

         DO CASE
         CASE ( nKey == K_DOWN )
            TB:Down()

         CASE ( nKey == K_UP )
            TB:Up()

         CASE ( nKey == K_RIGHT )
            TB:Right()

         CASE ( nKey == K_LEFT )
            TB:Left()

         CASE ( nKey == K_PGDN )
            TB:Right()
            TB:Down()

         CASE ( nKey == K_PGUP )
            TB:Right()
            TB:Up()

         CASE ( nKey == K_HOME )
            TB:Left()
            TB:Up()

         CASE ( nKey == K_END )
            TB:Left()
            TB:Down()

         ENDCASE



         DO CASE
         CASE nRez == DE_REFRESH
            TB:RefreshAll()
         CASE nRez == DE_ABORT .OR. nKey == K_CTRL_END .OR. nKey == K_ESC
            BoxC() ;  EXIT
         ENDCASE




      ENDIF

   ENDDO


   xRet := aArray[ nRow ]

   // Restore cursor setting
   SetCursor( nOldCursor )

   // Restore static var
   nRow := nOldNRow

   RETURN ( xRet )

/****f ARRAY/ABrowseBlock ****


*IME
   ABrowseBlock

*  ABrowseBlock( <a>, <x> ) -> bColumnBlock
*  Service funkcija for ABrowse().
*
*  Return a set/get block for  <a>[nRow, <x>]
*
*  This function works by returning a block that refers
*  to local variables <a> and <x> (the parameters). In
*  version 5.01 these local variables are preserved for
*  use by the block even after the function has returned.
*  The result is that each call to ABrowseBlock() returns
*  a block which has the passed values of <a> and <x> "bound"
*  to it for later use. The block defined here also refers to
*  the static variable nRow, used by ABrowse() to track the
*  array's "current row" while browsing.
*
*/

STATIC FUNCTION ABrowseBlock( a, x )
   RETURN ( {| p| IF( PCount() == 0, a[ nRow, x ], a[ nRow, x ] := p ) } )


//
// ASkipTest( <a>, <nCurrent>, <nSkip> ) -> nSkipsPossible
// Service funkcija for ABrowse().
//
// Given array <a> whose "current" row is <nCurrent>, determine
// whether it is possible to "skip" forward or backward by
// <nSkip> rows. Return the number of skips actually possible.
//

STATIC FUNCTION ASkipTest( a, nCurrent, nSkip )

   IF ( nCurrent + nSkip < 1 )
      // Would skip past the top...
      RETURN ( -nCurrent + 1 )

   ELSEIF ( nCurrent + nSkip > Len( a ) )
      // Would skip past the bottom...
      RETURN ( Len( a ) - nCurrent )

   END

   // No problem

   RETURN ( nSkip )


//
// ABlock( <cName>, <nSubx> ) -> bABlock
//
// Given the name of a variable containing an array, and a
// subscript value, create a set/get block for the specified
// array element.
//
// NOTE: cName must be the name of a variable that is visible
// in macros (i.e. not a LOCAL or STATIC variable). Also, the
// variable must be visible anywhere where the block is to be
// used.
//
// NOTE: ABlock() may be used to make blocks for a nested array
// by including a subscript expression as part of cName:
//
// // to make a set/get block for a[i]
// b := ABlock( "a", i )
//
// // to make a set/get block for a[i][j]
// b :=- ABlock( "a[i]", j )
//
// NOTE: this function is provided for compatibility with the
// version 5.00 Array.prg. See the ABrowseBlock() function
// (above) for a method of "binding" an array to a block
// without using a macro.
//

FUNCTION ABlock( cName, nSubx )

   LOCAL cAXpr

   cAXpr := cName + "[" + LTrim( Str( nSubx ) ) + "]"

   RETURN &( "{ |p| IF(PCOUNT()==0, " + cAXpr + "," + cAXpr + ":=p) }" )



FUNCTION ABrowRow()
   RETURN nRow



//
// AMax( <aArray> ) --> nPos
// Return the subscript of the array element with the highest value.
//

FUNCTION AMax( aArray )

   LOCAL nLen, nPos, expLast, nElement

   DO CASE

      // Invalid argument
   CASE ValType( aArray ) <> "A"
      RETURN NIL

      // Empty argument
   CASE Empty( aArray )
      RETURN 0

   OTHERWISE
      nLen := Len( aArray )
      nPos := 1
      expLast := aArray[ 1 ]
      FOR nElement := 2 TO nLen
         IF aArray[ nElement ] > expLast
            nPos := nElement
            expLast := aArray[ nElement ]
         ENDIF
      NEXT

   ENDCASE

   RETURN nPos



//
// AMin( <aArray> ) --> nPos
// Return the subscript of the array element with the lowest value.
//

FUNCTION AMin( aArray )

   LOCAL nLen, nPos, expLast, nElement

   DO CASE

      // Invalid argument
   CASE ValType( aArray ) <> "A"
      RETURN NIL

      // Empty argument
   CASE Empty( aArray )
      RETURN 0

   OTHERWISE
      nLen := Len( aArray )
      nPos := 1
      expLast := aArray[ 1 ]
      FOR nElement := 2 TO nLen
         IF aArray[ nElement ] < expLast
            nPos := nElement
            expLast := aArray[ nElement ]
         ENDIF
      NEXT

   ENDCASE

   RETURN nPos



//
// AComp( <aArray>, <bComp>, [<nStart>], [<nStop>] ) --> valueElement
// Compares all elements of aArray using the bComp block from nStart to
// nStop (if specified, otherwise entire array) and returns the result.
// Several sample blocks are provided in Array.ch.
//

FUNCTION AComp( aArray, bComp, nStart, nStop )

   LOCAL value := aArray[ 1 ]

   AEval(                                                               ;
      aArray,                                                       ;
      {| x| value := IIF( Eval( bComp, x, value ), x, value ) },         ;
      nStart,                                                       ;
      nStop                                                         ;
      )

   RETURN( value )


/***
*  Dimensions( <aArray> ) --> aDims
*  Return an array of numeric values describing the dimensions of a
*  nested or multi-dimensional array, assuming the array has uniform
*  dimensions.
*/
FUNCTION array_dimensions( aArray )

   LOCAL aDims := {}

   DO WHILE ( ValType( aArray ) == "A" )
      AAdd( aDims, Len( aArray ) )
      aArray := aArray[ 1 ]
   ENDDO

   RETURN ( aDims )



//
// MABrowse( <aArray>, <nTop>, <nLeft>, <nBottom>, <nRight> ) --> value
//
// Browse a 2-dimensional array using TBrowse object and
// return the value of the highlighted array element.
//
// moguc je visestruki select  !!!
//


FUNCTION MABrowse( aArray, nT, nL, nB, nR )

   // This static maintains the "current row" for ABrowse()
   LOCAL n, nOldNRow, nOldCursor  // Various
   LOCAL o                              // TBrowse object
   LOCAL nKey := 0                      // Keystroke holder
   LOCAL cScrAbr
   LOCAL nTekuciRed := 1
   LOCAL nStep := nB - nT -1
   LOCAL nI
   LOCAL oCol

   // Preserve cursor setting, turn off cursor
   nOldCursor := SetCursor( 0 )

   // Preserve static var (just in case), set it to 1
   nOldNRow := nRow
   nRow := 1

   // Handle omitted parameters
   nT := IF( nT == NIL, 0, nT )
   nL := IF( nL == NIL, 0, nL )
   nB := IF( nB == NIL, f18_max_rows(), nB )
   nR := IF( nR == NIL, f18_max_cols(), nR )

   // Create the TBrowse object
   o := TBrowseNew( nT + 1, nL + 1, nB -1, nR -1 )

   // The "skip" block just adds to (or subtracts from) nRow
   // (see ASkipTest() below)
   o:SkipBlock := {| nSkip|                                             ;
      nSkip := ASkipTest( aArray, nRow, nSkip ),   ;
      nRow += nSkip,                             ;
      nSkip                                      ;
      }

   // The "go top" block sets nRow to 1
   o:GoTopBlock := {|| nRow := 1 }

   // The "go bottom" block sets nRow to the length of the array
   o:GoBottomBlock := {|| nRow := Len( aArray ) }

   // Create column blocks and add TBColumn objects to the TBrowse
   // (see ABrowseBlock() below)
   FOR n = 1 TO Len( aArray[ 1 ] )
      oCol := TBColumnNew( "", ABrowseBlock( aArray, n ) )
      // oCol:colorBlock := { || IF( aArray[ n, 2 ] == "*" , { 5, 2 }, { 1, 2 } ) }
      o:AddColumn( oCol )
   NEXT

   // Start the event handler loop
   DO WHILE nKey <> K_ESC .AND. nKey <> K_RETURN

      // Stabilize
      nKey := 0
      DO WHILE ! o:Stabilize()
         nKey := Inkey()
         IF nKey <> 0
            EXIT
         ENDIF
      ENDDO

      IF nKey == 0
         nKey := Inkey()
      ENDIF

      // Process the directional keys
      IF o:Stable

         DO CASE
         CASE ( nKey == Asc( ' ' ) )
            f18_tone( 300, 1 )
            aArray[ nTekuciRed, 2 ] := IF( aArray[ nTekuciRed, 2 ] == '*', ' ', '*' )
            o:RefreshCurrent()

         CASE ( nKey == K_DOWN )
            o:Down()
            nTekuciRed++

         CASE ( nKey == K_UP )
            o:Up()
            nTekuciRed--

         CASE ( nKey == K_RIGHT )
            o:Right()

         CASE ( nKey == K_LEFT )
            o:Left()

         ENDCASE

         IF nTEkuciRed > Len( aArray )
            nTekuciRed := Len( aArray )
         ENDIF
         IF nTekuciRed < 1
            nTekuciRed := 1
         ENDIF


      ENDIF

   ENDDO

   // Restore cursor setting
   SetCursor( nOldCursor )

   // Restore static var
   nRow := nOldNRow

   RETURN ( nTekuciRed )



/*
*   StackNew() --> aStack
*   Create a new stack
*/
FUNCTION StackNew()
   RETURN {}

/**
*   StackPush( <aStack>, <exp> ) --> aStack
*   Push a new value onto the stack
*/
FUNCTION StackPush( aStack, exp )


   RETURN AAdd( aStack, exp ) // Add new element to the stack array and then return the array


/**
*   StackPop( <aStack> ) --> value
*   Pop a value from the stack
*
*   Return NIL if nothing is on the stack.
*/
FUNCTION StackPop( aStack )

   LOCAL valueLast, nLen := Len( aStack )

   // Check for underflow condition
   IF nLen == 0
      RETURN NIL
   ENDIF

   // Get the last element value
   valueLast := aStack[ nLen ]

   // Remove the last element by shrinking the stack
   ASize( aStack, nLen -1 )

   // Return the last element's value

   RETURN valueLast


/*
*  StackIsEmpty( <aStack> ) --> lEmpty
*  Determine if a stack has no members
*
*/
FUNCTION StackIsEmpty( aStack )
   RETURN Empty( aStack )


/*
*  StackGetTop( <aStack> ) --> value
*  Retrieve top stack member without removing
*
*/
FUNCTION StackGetTop( aStack )

   //
   // Return the value of the last element in the stack array

   RETURN ATail( aStack )


FUNCTION StackTop( aStack )

   //
   // StackTop( <aStack> ) --> value
   // Retrieve top stack member without removing
   //
   //

   //
   // Return the value of the last element in the stack array

   RETURN ATail( aStack )
