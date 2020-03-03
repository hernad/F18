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


FUNCTION export_sifarnik()

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
   LOCAL aDbfStruct, hField, nLen, nDec

   // PRIVATE cNazMemo := ""
   // PRIVATE RedBr

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
            // ELSE
            // IF aStruct[ i, 2 ] == "M"
            // @ box_x_koord() + 6, box_y_koord() + 3 SAY8 "Štampati " + aStruct[ i, 1 ] GET cStMemo PICT "@!" VALID cStMemo $ "DN"
            // READ
            // IF cStMemo == "D"
            // cNazMemo := aStruct[ i, 1 ]
            // ENDIF
            // ENDIF
         ENDIF
      NEXT

      // AAdd( aKol, { "R.br.", {|| Str( RedBr, 4 ) + "." }, .F., "C", 5, 0, 1, 1 } )
      j := 1
      FOR i := 1 TO Len( aStruct )
         IF aNDuzine[ i, 1 ] != nil
            ++j
            AAdd( aNDuzine[ i, 2 ], 1 )
            AAdd( aNDuzine[ i, 2 ], j )
            AAdd( aKol, aNDuzine[ i, 2 ] )
         ENDIF
      NEXT

      // IF !Empty( cNazMemo )
      // AAdd( aKol, { cNazMemo, {|| cTxt2 }, .F., "P", 30, 0, 1, ++j } )
      // ENDIF
   ELSE
      // AAdd( aKol, { "R.br.", {|| Str( RedBr, 4 ) + "." }, .F., "C", 5, 0, 1, 1 } )
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
                  IIF( SIFK->veza == "N", "P", ValType( xPom ) ), ;
                  IIF( SIFK->veza == "N", SIFK->duzina + 1, Max( SIFK->duzina, Len( Trim( ImeKol[ i, 1 ] ) ) ) ), ;
                  IIF( ValType( xPom ) == "N", SIFK->f_decimal, 0 ), 1, Kol[ i ] + 1 } )
               LOOP
            ENDIF
            nDuz1 := IIF( Len( ImeKol[ i ] ) > 4 .AND. ValType( ImeKol[ i, 5 ] ) == "N", ImeKol[ i, 5 ], LENx( xPom ) )
            nDuz2 := IF( Len( ImeKol[ i ] ) > 5 .AND. ValType( ImeKol[ i, 6 ] ) == "N", ImeKol[ i, 6 ], IF( ValType( xPom ) == "N", nDuz1 - At( ".", Str( xPom ) ), 0 ) )
            nPosRKol := 0

            AAdd( aKol, { ImeKol[ i, 1 ], ImeKol[ i, 2 ], IIF( Len( ImeKol[ i ] ) > 2 .AND. ValType( ImeKol[ i, 3 ] ) == "L", ImeKol[ i, 3 ], .F. ), ;
               IIF( Len( ImeKol[ i ] ) > 3 .AND. ValType( ImeKol[ i, 4 ] ) == "C" .AND. ImeKol[ i, 4 ] $ "N#C#D#P", ImeKol[ i, 4 ], IF( nDuz1 > 100, "P", ValType( xPom ) ) ), ;
               IIF( nDuz1 > 100, 100, nDuz1 ), nDuz2, 1, Kol[ i ] + 1 } )

         ENDIF
      NEXT
   ENDIF


   FOR i := 1 TO Len( aKol )
      IF aKol[ i, 7 ] == 1
         nSirIzvj += ( aKol[ i, 5 ] + 1 )
      ENDIF
   NEXT
   ++nSirIzvj

   IF cRazmak == "D"
      AAdd( aKol, { "", {|| " " }, .F., "C", aKol[ 1, 5 ], 0, 2, 1 } )
   ENDIF

   // AAdd( ImeKol, { PadR( "ID", 6 ),   {|| id },  "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) }    } )
   // AAdd( ImeKol, { PadR( "Naziv", 35 ),  {|| PadR( naz, 35 ) },  "naz" } )
   // Kol := { 1, 2 }

   aDbfStruct := {}
   FOR i := 1 TO Len( aKol )
      hField := get_field_from_a_kol( aKol[ i, 1 ] )
      IF hField[ "tip" ] == "C" .AND. hField[ "len" ] == 0
         nLen := Len( ToStr( Eval( aKol[ i, 2 ] ) ) )
         nDec := 0
      ELSE
         nLen := hField[ "len" ]
         nDec := hField[ "dec" ]
      ENDIF
      AAdd( aDbfStruct, { hField[ "name" ], hField[ "tip" ], nLen,  nDec } )
   NEXT

   xlsx_napuni( @aKol, @aDbfStruct )

   open_exported_xlsx()

   RETURN .T.






STATIC FUNCTION xlsx_napuni( aKol, aDbfStruct )

   LOCAL hRec, nArea, nKol, hField, xValue
   LOCAL nCnt

   xlsx_export_init( aDbfStruct, { {"Datum:", DtoC(Date())}, {"Lista:", Alias()} }, "lista_" + AllTrim(lower(Alias())) + ".xlsx"  )


   GO TOP
   nCnt := 0
   DO WHILE !Eof()

      nArea := Select()
      hRec := hb_hash()

      FOR nKol := 1 TO Len( aKol ) // { "ID", { || field->id }}
         Select( nArea )
         hField := get_field_from_a_kol( aKol[ nKol, 1 ] )
         IF hField[ "tip" ] == "N" // number
            xValue := Eval( aKol[ nKol, 2 ] )
            IF ValType( xValue ) == "C"
               xValue := Val( xValue )
            ENDIF
         ELSE // sve ostalo string
            xValue := ToStr( Eval( aKol[ nKol, 2 ] ) )
         ENDIF
         hRec[ Lower( hField[ "name" ] ) ] := xValue
      NEXT

      xlsx_export_do_fill_row( hRec )

      info_bar( "exp_sif", (nArea)->( Alias() ) + Str( ++nCnt, 5, 0 ) )

      Select( nArea )
      SKIP
   ENDDO

   

   RETURN .T.



FUNCTION get_field_from_a_kol( cKol1 )

   LOCAL cField, cTip := "C", hRet := hb_Hash(), nLen, nDec

   nLen := 0
   nDec := 0
   cField := AllTrim( Upper( cKol1 ) )
   cField := StrTran( cField, ".", "_" )
   cField := StrTran( cField, ":", "_" )
   cField := StrTran( cField, " ", "_" )
   cField := StrTran( cField, ",", "_" )
   cField := StrTran( cField, "?", "_" )
   cField := StrTran( cField, "#", "_" )
   cField := StrTran( cField, hb_UTF8ToStr( "Ž" ), "Z" )
   cField := StrTran( cField, hb_UTF8ToStr( "Č" ), "C" )
   cField := StrTran( cField, hb_UTF8ToStr( "Ć" ), "C" )
   cField := StrTran( cField, hb_UTF8ToStr( "Š" ), "S" )
   cField := StrTran( cField, hb_UTF8ToStr( "Đ" ), "DJ" )

   //cField := Left( cField, 10 )

   IF cField $ "VPC#MPC#VPC2#MPC1#MPC2#MPC3#NC#"
      cTip := "N"
      nLen := 12
      nDec := 3
   ENDIF

   hRet[ "name" ] := Upper( AllTrim( cField ) )
   hRet[ "tip" ] := cTip
   hRet[ "len" ] := nLen
   hRet[ "dec" ] := nDec

   RETURN hRet
