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


// --------------------------------------------------------------
// * nToLongC(nN)
// * Pretvara broj u LONG (C-ovski prikaz long integera)
// --------------------------------------------------------------
FUNCTION nToLongC( nN )

   LOCAL cStr := "", i

   FOR i := 1 TO 4
      nDig := nN - Int( nN / 256 ) * 256
      cStr += Chr( nDig )
      nN := Int( nN / 256 )
   NEXT

   RETURN cStr



FUNCTION CLongToN( cLong )

   LOCAL i, nExp

   nRez := 0
   FOR i := 1 TO 4
      nExp := 1
      FOR j := 1 TO i - 1
         nExp *= 256
      NEXT
      nRez += Asc( SubStr( cLong, i, 1 ) ) * nExp
   NEXT

   RETURN nRez



FUNCTION Sleep( nSleep )

   LOCAL nStart, nCh

   nStart := Seconds()
   DO WHILE .T.
      IF nSleep < 0.0001
         EXIT
      ELSE
         nCh := Inkey( nSleep )

         // if nCh<>0
         // Keyboard chr(nCh)
         // endif
         IF ( Seconds() -nStart ) >= nSleep
            EXIT
         ELSE
            nSleep := nSleep - ( Seconds() -nStart )
         ENDIF
      ENDIF

   ENDDO

   RETURN




FUNCTION NotImp()

   MsgBeep( "Not implemented ?" )

   RETURN



// ----------------------------------------
// upisi text u fajl
// ----------------------------------------
FUNCTION write_2_file( nH, cText, lNoviRed )

   LOCAL cNRed := Chr( 13 ) + Chr( 10 )

   IF lNoviRed
      FWrite( nH, cText + cNRed )
   ELSE
      FWrite( nH, cText )
   ENDIF

   RETURN

// ----------------------------------------------
// kreiranje fajla
// ----------------------------------------------
FUNCTION create_file( cFilePath, nH )

   nH := FCreate( cFilePath )
   IF nH == -1
      MsgBeep( "Greska pri kreiranju fajla !!!" )
      RETURN
   ENDIF

   RETURN

// -------------------------------------------------
// zatvaranje fajla
// --------------------------------------------------
FUNCTION close_file( nH )

   FClose( nH )

   RETURN


// -------------------------------------------------
// -------------------------------------------------
FUNCTION Run( cmd )

   RETURN __Run( cmd )


// ---------------------------------------------------------------
// vraca fajl iz matrice na osnovu direktorija prema filteru
// ---------------------------------------------------------------
FUNCTION get_file_list_array( cPath, cFilter, cFile, lSilent )

   LOCAL nPx := box_x_koord()
   LOCAL nPy := box_y_koord()

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF Empty( cFilter )
      cFilter := "*.*"
   ENDIF

   OpcF := {}

   aFiles := Directory( cPath + cFilter )

   // da li postoje templejti
   IF Len( aFiles ) == 0
      log_write( "template list: na lokaciji " + cPath + " ne postoji niti jedan template, po filteru: " + cFilter, 9 )
      MsgBeep( "Ne postoji definisan niti jedan template na lokciji:#" + cPath + "#po filteru: " + cFilter )
      RETURN 0
   ENDIF

   // sortiraj po datumu
   ASort( aFiles,,, {| x, y| x[ 3 ] > y[ 3 ] } )
   AEval( aFiles, {| elem| AAdd( OpcF, PadR( elem[ 1 ], 15 ) + " " + DToS( elem[ 3 ] ) ) }, 1 )
   // sortiraj listu po datumu
   ASort( OpcF,,, {| x, y| Right( x, 10 ) > Right( y, 10 ) } )

   h := Array( Len( OpcF ) )
   FOR i := 1 TO Len( h )
      h[ i ] := ""
   NEXT

   // selekcija fajla
   IzbF := 1
   lRet := .F.

   IF Len( opcF ) > 1
      DO WHILE .T. .AND. LastKey() != K_ESC
         IzbF := meni_0( "imp", OpcF, NIL, IzbF, .F. )
         IF IzbF == 0
            EXIT
         ELSE
            cFile := Trim( Left( OpcF[ IzbF ], 15 ) )
            IF lSilent == .T. .OR. ( lSilent == .F. .AND. Pitanje(, "Koristiti ovaj fajl ?", "D" ) == "D" )
               IzbF := 0
               lRet := .T.
            ENDIF
         ENDIF
      ENDDO
   ELSE
      cFile := Trim( Left( OpcF[ IzbF ], 15 ) )
      lRet := .T.
      IzbF := 0
   ENDIF

   box_x_koord( nPx )
   box_y_koord(  nPy )

   IF lRet
      RETURN 1
   ELSE
      RETURN 0
   ENDIF

   RETURN 1



FUNCTION preduzece()

   LOCAL _t_arr := Select()

   //P_10CPI
   //B_ON

   ? AllTrim( tip_organizacije() ) + ": "
   ?? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )

   //B_OFF
   ?

   SELECT ( _t_arr )

   RETURN .T.



FUNCTION rbr_u_num( cRBr )

   IF Left( cRbr, 1 ) > "9"
      RETURN  ( Asc( Left( cRbr, 1 ) ) - 65 + 10 ) * 100  + Val( SubStr( cRbr, 2, 2 ) )
   ELSE
      RETURN Val( cRbr )
   ENDIF


FUNCTION rbr_u_char( nRbr )

   LOCAL nOst

   IF nRbr > 999
      nOst := nRbr % 100
      RETURN Chr( Int( nRbr / 100 ) - 10 + 65 ) + PadL( AllTrim ( Str( nOst, 2 ) ), 2, "0" )
   ELSE
      RETURN Str( nRbr, 3, 0 )
   ENDIF


/*
 provjera rednog broja u tabeli
*/

FUNCTION provjeri_redni_broj()

   LOCAL _ok := .T.
   LOCAL _tmp

   DO WHILE !Eof()

      _tmp := field->rbr

      SKIP 1

      IF _tmp == field->rbr
         _ok := .F.
         RETURN _ok
      ENDIF

   ENDDO

   RETURN _ok



// da li postoji fajl u chk lokaciji, vraca oznaku
// X - nije obradjen
FUNCTION UChkPostoji()
   RETURN "X"



FUNCTION NazProdObj()

   LOCAL cVrati := ""

   cVrati := Trim( cTxt3a )
   SELECT fakt_pripr

   RETURN cVrati




// -------------------------------------------------
// potpis na dokumentima
// -------------------------------------------------
FUNCTION dok_potpis( nLen, cPad, cRow1, cRow2 )

   IF nLen == nil
      nLen := 80
   ENDIF

   IF cPad == nil
      cPad := "L"
   ENDIF

   IF cRow1 == nil
      cRow1 := "Potpis:"
   ENDIF

   IF cRow2 == nil
      cRow2 := "__________________"
   ENDIF

   IF cPad == "L"
      ? PadL( cRow1, nLen )
      ? PadL( cRow2, nLen )
   ELSEIF cPad == "R"
      ? PadR( cRow1, nLen )
      ? PadR( cRow2, nLen )
   ELSE
      ? PadL( cRow1, nLen )
      ? PadL( cRow2, nLen )
   ENDIF

   RETURN .T.



// ovo treba ukinuti skroz
FUNCTION OtkljucajBug()
   RETURN


// ----------------------------------------------------
// upisi tekst u fajl
// ----------------------------------------------------
FUNCTION write2file( nH, cText, lNewRow )

#define NROW CHR(13) + CHR(10)

   IF lNewRow == .T.
      FWrite( nH, cText + NROW )
   ELSE
      FWrite( nH, cText )
   ENDIF

   RETURN


FUNCTION printfile()
   RETURN
