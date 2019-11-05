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

MEMVAR ImeKol

FUNCTION browse_stavka_formiraj_getlist( cVariableName, GetList, lZabraniIspravke, aZabIsp, lShowPGroup, Ch, nGet, nI, nTekRed )

   LOCAL bWhen, bValid, cGetPictureCode
   LOCAL nRed, nKolona
   LOCAL cWhenSifk, cValidSifk
   LOCAL bWhenSifk, bValidSifk
   LOCAL bVariableEval := MemVarBlock( cVariableName )
   LOCAL cFieldName
   LOCAL tmpRec
   LOCAL aFieldLen, nFieldWidth
   LOCAL nXP, nYP

   // uzmi when, valid kodne blokove
   IF ( Ch == K_F2 .AND. lZabraniIspravke .AND. AScan( aZabIsp, Upper( ImeKol[ nI, BROWSE_IMEKOL_IME_VARIJABLE ] ) ) > 0 )
      bWhen := {|| .F. }
   ELSEIF ( Len( ImeKol[ nI ] ) < BROWSE_IMEKOL_WHEN .OR. ImeKol[ nI, BROWSE_IMEKOL_WHEN ] == NIL )
      bWhen := {|| .T. }
   ELSE
      bWhen := Imekol[ nI, BROWSE_IMEKOL_WHEN ]
   ENDIF

   IF ( Len( ImeKol[ nI ] ) < BROWSE_IMEKOL_VALID .OR. ImeKol[ nI, BROWSE_IMEKOL_VALID ] == NIL )
      bValid := {|| .T. }
   ELSE
      bValid := Imekol[ nI, BROWSE_IMEKOL_VALID ]
   ENDIF

   bVariableEval := MemVarBlock( cVariableName )

   IF bVariableEval == NIL
      MsgBeep( "Varijabla nedefinisana :" + cVariableName )
   ENDIF

   cFieldName := SubStr( cVariableName, 2 ) // wID -> ID
   cGetPictureCode := get_field_get_picture_code( Alias(), cFieldName )
   aFieldLen := get_field_len( Alias(), cFieldName )
   IF aFieldLen != NIL .AND. aFieldLen[ 1 ] == "C"
      nFieldWidth := aFieldLen[ 2 ] // char polje sirina
   ENDIF

   IF cGetPictureCode ==  "@S50" .OR. Len( ToStr( Eval( bVariableEval ) ) ) > 50
      cGetPictureCode :=  "@S50"
      @ box_x_koord() + nTekRed + 1, box_y_koord() + 67 SAY ">" // Chr( 16 )  // strelica >
   ENDIF

   IF Len( ImeKol[ nI ] ) >= 7 .AND. ImeKol[ nI, BROWSE_IMEKOL_KOLONA_U_PICTURE_CODE ] <> NIL
      cGetPictureCode := ImeKol[ nI, BROWSE_IMEKOL_KOLONA_U_PICTURE_CODE ]
   ENDIF

   nRed := 1
   nKolona := 1

   IF Len( ImeKol[ nI ] ) >= BROWSE_IMEKOL_KOLONA_U_POSTOJECEM_REDU .AND. Imekol[ nI, BROWSE_IMEKOL_KOLONA_U_POSTOJECEM_REDU ] <> NIL
      nKolona := ImeKol[ nI, BROWSE_IMEKOL_KOLONA_U_POSTOJECEM_REDU ] + 1
      nRed := 0
   ENDIF

   IF nKolona == 1
      nTekRed++
   ENDIF

   IF lShowPGroup
      nXP := nTekRed
      nYP := nKolona
   ENDIF


   IF lShowPGroup  // stampaj grupu za stavku "GRUP"
      p_gr( &cVariableName, box_x_koord() + nXP, box_y_koord() + nYP + 1 )
   ENDIF

   IF "wSifk_" $ cVariableName

      IzSifKWV( Alias(), SubStr( cVariableName, 7 ), @cWhenSifk, @cValidSifk )

      IF !Empty( cWhenSifk )
         bWhenSifk := & ( "{|| " + cWhenSifk + "}" )
      ELSE
         bWhenSifk := bWhen
      ENDIF

      IF !Empty( cValidSifk )
         bValidSifk := & ( "{|| " + cValidSifk + "}" )
      ELSE
         bValidSifk := bValid
      ENDIF
   ELSE
      bWhenSifk := bWhen
      bValidSifk := bValid
   ENDIF

   @ box_x_koord() + nTekRed, box_y_koord() + nKolona SAY  iif( nKolona > 1, "  " + AllTrim( ImeKol[ nI, 1 ] ), PadL( AllTrim( ImeKol[ nI, 1 ] ), 15 ) )  + " "

   IF &cVariableName == NIL
      tmpRec = RecNo()
      GO BOTTOM
      SKIP
      &cVariableName := Eval( ImeKol[ nI, 2 ] )
      GO tmpRec
   ENDIF

   IF ValType( &cVariableName ) == "C"
      IF nFieldWidth != NIL // znamo koja je potrebna sirina polja
         // ovo je potrebno radi char varying polja koje vrate trimovan string, npr "abc", za edit treba full width string Padr( "abc", 250 )
         &cVariableName = PadR( &cVariableName, nFieldWidth )
      ENDIF
   ENDIF

   IF ValType( &cVariableName ) == "C" .AND. F18_SQL_ENCODING == "UTF8" // samo ako sql vraca UTF8 stringove izvrsiti ovu konverziju
      &cVariableName = hb_UTF8ToStr( &cVariableName ) // F18 SQL ENCODING UTF8
   ENDIF


   //IF "wduzina" $ cVariableName DEBUG sifk->duzina
   //    AltD()
   //ENDIF

   AAdd( GetList, _GET_( &cVariableName, cVariableName,  cGetPictureCode, bValidSifk, bWhenSifk ) ) ;;
      ATail( GetList ):display()

   RETURN .T.




FUNCTION get_field_get_picture_code( cAlias, cField )

   LOCAL aFieldLen := get_field_len( cAlias, Lower( cField ) )

   //IF Upper( cField ) == "DUZINA" .AND. cAlias == "SIFK"
   //    AltD()
   //ENDIF

   IF aFieldLen == NIL
      RETURN ""
   ENDIF

   IF aFieldLen[ 1 ] == "C"
      IF aFieldLen[ 2 ] > 50
         RETURN "@S50"
      ENDIF
      RETURN Replicate( "X", aFieldLen[ 2 ] )
   ENDIF

   IF ( aFieldLen[ 1 ] $ "NBY" )
      IF aFieldLen[ 3 ] == 0
         RETURN Replicate( "9", aFieldLen[ 2 ] )
      ELSE
         RETURN Replicate( "9", aFieldLen[ 2 ] - aFieldLen[ 3 ] - 1 ) + "." + Replicate( "9", aFieldLen[ 3 ] ) // numeric 999999999.99999999
      ENDIF
   ENDIF

   RETURN "" // nije numeric ni char



FUNCTION get_field_len( cAlias, cField )

   LOCAL hDbfRec := get_a_dbf_rec( cAlias ), hLens

   IF !hb_HHasKey( hDbfRec, "dbf_fields_len" ) .OR. hDbfRec[ "dbf_fields_len" ] == NIL
      RETURN NIL
   ENDIF

   hLens := hDbfRec[ "dbf_fields_len" ]
   IF !hb_HHasKey( hLens, Lower( cField ) ) // to hibridna polaj sifk_gr1, sifk_gr2 itd.
      // Alert( "tabela " + cAlias + " ne sadrzi polje: " + cField + " ?!" )
      RETURN NIL
   ENDIF

   RETURN hDbfRec[ "dbf_fields_len" ][ Lower( cField ) ] // { "B", 18, 8} ili NIL
