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

#include "f18.ch"


STATIC aOperators := { "#", ">=", ">", "<", ">", "<>", "!=", "$", "--", "*", "?" }
STATIC aTokens := { ";", ".I.", ".ILI." }
STATIC aToken2 := { ".or.", ".and.", ".or." }

/*

   Usage:

   Parsiraj( "2;3;", "IdRoba" ) => IdRoba='2' .OR. IdRoba='3'


   Parsiraj( cSifra, cImeSifre, cTip, lRekurzivno, nSifWA )
   - lRekurzivno - rekurzivni poziv
   - nSifWA: npr. F_ROBA


*/

FUNCTION Parsiraj( cFilterUpit, cImeSifre, cTip, lRekurzivno ) // , nSifWA )

   LOCAL cStartSifra, cOperator, nPoz1, nPos, nPoz1End, nSiflen
   LOCAL cIzraz, cLijevo, cDesno
   LOCAL cProlaz, nLen, cIza

   LOCAL cVeznik := "", cToken := "", cIddd

   IF lRekurzivno == NIL
      lRekurzivno := .F.
   ENDIF

   IF ValType( cFilterUpit ) != "C"
      RETURN NIL
   ENDIF

   cFilterUpit := Trim( cFilterUpit )

   //IF nSifWA == NIL .AND. !Empty( cFilterUpit ) .AND. Right( cFilterUpit, 1 ) <> ";"
   IF !Empty( cFilterUpit ) .AND. Right( cFilterUpit, 1 ) <> ";"
      cFilterUpit := cFilterUpit + ";"
   ENDIF

   IF !lRekurzivno
      cStartSifra := cFilterUpit
   ENDIF

/*
   IF  nSifWA <> NIL .AND. Right( Trim( cFilterUpit ), 1 ) <> ";" .AND. !lRekurzivno

      IF !Empty( cFilterUpit )
         nPos := AtToken( cFilterUpit, ";" )  // 12121;21212;1A -> 1A
         nSiflen := Len( cFilterUpit )
         PushWA()
         SELECT ( nSifWA )
         IF nPos <> 0
            cIddd := PadR( SubStr( cFilterUpit, nPos ), Len( field->id ) )
            cFilterUpit := Left( cFilterUpit, nPos - 1 )
         ELSE
            cIddd := PadR( cFilterUpit, Len( field->id ) )
            cFilterUpit := ""
         ENDIF

         SET ORDER TO TAG "ID"
         PRIVATE ImeKol := { { "ID  ",  {|| id },    "id"    },  { "Naziv:", {|| naz },  "naz"     } }
         PRIVATE Kol := { 1, 2 }
         p_sifra( nSifWA, 1, 10, 77, "Odredi šifru:", @cIddd )
         cFilterUpit := cFilterUpit + cIddd + ";"

         cFilterUpit := PadR( cFilterUpit, nSiflen )
         PopWa()
         RETURN NIL
      ELSE
         RETURN NIL
      ENDIF
   ENDIF
*/

   cIzraz := ""
   IF cTip == NIL;  cTip := "C";  ENDIF
   cFilterUpit := Trim( cFilterUpit )
   nLen := Len( cFilterUpit )

   DO WHILE nLen > 0
      cProlaz := ""
      IF Left( cFilterUpit, 1 ) <> "#"  // ove izraze ne razbijaj
         Zagrade( @cFilterUpit, @nPoz1, @nPoz1end )
      ELSE
         nPoz1 := 0
         nPoz1End := 0
      ENDIF
      // (>10.I.<11);
      IF nPoz1 > 0 .AND. nPoz1End > nPoz1

         cLijevo := SubStr( cFilterUpit, 1, nPoz1 - 1 )
         cDesno := SubStr( cFilterUpit, nPoz1 + 1, nPoz1end - nPoz1 - 1 )
         cIza :=   SubStr( cFilterUpit, nPoz1end + 1 )

         IF !Empty( clijevo )
            VeznikRight( @cLijevo, @cVeznik )
            cIzraz += Parsiraj( cLijevo, cImeSifre, cTip, .T. ) + cVeznik
         ENDIF
         cIzraz += "("

         VeznikRight( @cDesno, @cVeznik )
         cIzraz += Parsiraj( cDesno, cImeSifre, cTip, .T. )
         cIzraz += ")"

         IF !Empty( cIza )
            VeznikLeft( @cIza, @cVeznik )
            cIzraz += cVeznik
            cIzraz += Parsiraj( cIza, cImeSifre, cTip, .T. )
         ENDIF

         cFilterUpit := "" // sve je rijeseno
         cProlaz := "("
      ENDIF

      IF nPoz1 = -999
         cProlaz := "DE"
      ENDIF

      cOperator := PrviOperator( cFilterUpit, @nPoz1 )

      IF cOperator == "#"
         IF Empty( cProlaz ) .AND. nPoz1 > 0
            nPoz1end := Nexttoken( @cFilterUpit, @cToken )
            cDesno := SubStr( cFilterUpit, nPoz1 + 1, nPoz1end - nPoz1 - 1 )
            cFilterUpit := SubStr( cFilterUpit, nPoz1End + 1 )
            cIzraz += cDesno
            cProlaz += "#"
         ENDIF
      ENDIF

      IF cOperator $ "< > >= <= <> !=" .AND. Empty( cProlaz ) .AND. npoz1 > 0

         nPoz1end := NextToken( @cFilterUpit, @cToken )
         cDesno := SubStr( cFilterUpit, nPoz1 + Len( cOperator ), nPoz1end - nPoz1 - Len( cOperator ) )
         DO CASE
         CASE cTip == "C"
            cIzraz += cImeSifre + cOperator + "'" + cDesno + "'"
         CASE cTip == "N"
            cIzraz += cImeSifre + cOperator + cDesno
         CASE cTip == "D"
            cIzraz += cImeSifre + cOperator + "CTOD('" + cDesno + "')"
         ENDCASE

         cFilterUpit := SubStr( cFilterUpit, nPoz1End + Len( cOperator ) )
         cProlaz += cOperator
      ENDIF

      IF cOperator == "--" .AND. Empty( cProlaz ) .AND. npoz1 > 0

         nPoz1end := NextToken( @cFilterUpit, @cToken )
         cLijevo := Left( cFilterUpit, nPoz1 - 1 )
         cDesno := SubStr( cFilterUpit, nPoz1 + 2, nPoz1end - nPoz1 - 2 )
         DO CASE
         CASE cTip == "C"
            cIzraz += "(" + cImeSifre + ">='" + cLijevo + "'.and." + cImeSifre + "<='" + cDesno + "')"
         CASE cTip == "N"
            cIzraz += "(" + cImeSifre + ">=" + cLijevo + ".and." + cImeSifre + "<=" + cDesno + ")"
         CASE cTip == "D"
            cIzraz += "(" + cImeSifre + ">=CTOD('" + cLijevo + "').and." + cImeSifre + "<=CTOD('" + cDesno + "'))"
         ENDCASE

         cFilterUpit := SubStr( cFilterUpit, nPoz1End + 1 )
         cProlaz += "O"
      ENDIF

      IF cOperator == "$" .AND. Empty( cProlaz ) .AND. npoz1 > 0
         nPoz1end := NextToken( @cFilterUpit, @cToken )
         cLijevo := Left( cFilterUpit, nPoz1 - 1 )
         cDesno := SubStr( cFilterUpit, nPoz1 + 1, nPoz1end - nPoz1 - 1 )
         IF cTip == "C"
            cIzraz += "'" + cDesno + "'$" + cImeSifre
         ELSE
            cProlaz := "DE"  // Data error
         ENDIF
         cFilterUpit := SubStr( cFilterUpit, nPoz1End + 1 )
         cProlaz += "$"
      ENDIF

      // debug - fix error "Undefined function/LIKE"
      //IF cOperator $ "*?" .AND. Empty( cProlaz ) .AND. npoz1 > 0
      //   nPoz1 := 1
      //   nPoz1end := NextToken( @cFilterUpit, @cToken )
      //   cLijevo := Left( cFilterUpit, nPoz1End - 1 )
      //   IF cTip == "C"
      //      cIzraz += "LIKE('" + cLijevo + "'," + cImeSifre + ")"
      //   ELSE
      //      cProlaz := "DE"  // Data error
      //   ENDIF
      //   cFilterUpit := SubStr( cFilterUpit, nPoz1End + 1 )
      //   cProlaz += "?"
      //ENDIF

      IF cOperator == "" .AND. cProlaz == "" // nista od gornjih operatora
         nPoz1 := NextToken( @cFilterUpit, @cToken )
         IF nPoz1 > 0
            cLijevo := Left( cFilterUpit, nPoz1 - 1 )
            DO CASE
            CASE cTip == "C"
               cIzraz += cImeSifre + "='" + clijevo + "'"
            CASE cTip == "N"
               cIzraz += cImeSifre + "==" + clijevo
            CASE cTip == "D"
               cIzraz += cImeSifre + "==CTOD('" + clijevo + "')"
            ENDCASE
            cFilterUpit := SubStr( cFilterUpit, nPoz1 + 1 )
            cProlaz := "V"
         ENDIF
      ENDIF

      IF cProlaz == "" .OR. Left( cProlaz, 2 ) == "DE"

         MsgO( "Greška u sintaksi !!!" )
         Beep( 4 )
         Inkey()
         MsgC()
         RETURN NIL

      ELSE
         IF !Empty( cFilterUpit ) // vezni izraz
            cIzraz += cToken
         ENDIF
         nLen := Len( cFilterUpit )
      ENDIF

   ENDDO

   IF !Empty( cIzraz )
      IF !lRekurzivno // nije rekurzivni poziv
         cIzraz := "(" + cIzraz + ")"
         cFilterUpit := cStartSifra
         RETURN cIzraz
      ENDIF
   ELSE
      RETURN ".t."
   ENDIF

   RETURN ".t."



FUNCTION PrviOperator( cSifra, nPoz1 )

   LOCAL i
   LOCAL cRet := ""

   nPoz1 := 999
   FOR i := 1 TO Len( aOperators )
      nPom := At( aOperators[ i ], cSifra )
      IF npom > 0 .AND. nPom < nPoz1
         nPoz1 := nPom
         cRet := aOperators[ i ]
      ENDIF
   NEXT
   FOR i := 1 TO Len( aTokens ) // veznici
      nPom := At( aTokens[ i ], cSifra )
      IF npom > 0 .AND. nPom < nPoz1
         nPoz1 := 1  // ispred svih operatora nalazi se veznik .i. .ili ;
         cRet := ""
      ENDIF
   NEXT

   RETURN cRet  // npr "$"



FUNCTION  Zagrade( cSifra, nPoz1, nPoz1end )

   // cSifra = 930239(3332('3232323))

   LOCAL i, nBracket
   nPoz1 := At( "(", cSifra )
   IF nPoz1 = 0
      nPoz1End := 0
      RETURN
   ENDIF
   nBracket := 1
   FOR i := npoz1 + 1 TO Len( cSifra )
      IF SubStr( cSifra, i, 1 ) == ")"
         nBracket--
      ENDIF
      IF nBracket == 0
         nPoz1End := i
         EXIT
      ENDIF
      IF SubStr( cSifra, i, 1 ) == "("
         nBracket++
      ENDIF
   NEXT
   IF nBracket <> 0  // greska u sintaksi
      nPoz1   := 999
      nPoz1End := 999
   ENDIF
   IF SubStr( cSifra, nPoz1End + 1 ) = ";"
      cSifra := Left( cSifra, npoz1End ) + SubStr( cSifra, npoz1End + 2 )
   ENDIF

   RETURN NIL



STATIC FUNCTION VeznikRight( cLijevo, cVeznik )

   // 456.I. -> 456;  cVeznik:=".and."

   IF Right( cLijevo, 1 ) == ";"
      cVeznik := ".or."
   ENDIF
   IF Right( cLijevo, 3 ) == ".I."
      cVeznik := ".and."
      cLijevo := Left( cLijevo, Len( clijevo ) - 3 ) + ";"
   ENDIF
   IF Right( cLijevo, 5 ) == ".ILI."
      cVeznik := ".or."
      cLijevo := Left( cLijevo, Len( clijevo ) - 5 ) + ";"
   ENDIF
   IF Right( cLijevo, 1 ) <> ";" .AND. Right( cLijevo, 1 ) <> ")"
      cLijevo += ";"  // dodaj ; da izraz bude regularan
   ENDIF
   IF Right( clijevo, 2 ) == ");"
      cLijevo := Left( clijevo, Len( clijevo - 1 ) )
   ENDIF


STATIC FUNCTION VeznikLeft( cIza, cVeznik )

   //
   // .I.456;  ->  456;   cVeznik:=".and."

   IF Left( cIza, 1 ) == ";"
      cVeznik := ".or."
      cIza := SubStr( cIza, 2 )
   ENDIF
   IF Left( cIza, 3 ) == ".I."
      cVeznik := ".and."
      cIza := SubStr( cIza, 4 )
   ENDIF
   IF Left( cIza, 5 ) == ".ILI."
      cVeznik := ".or."
      cIza := SubStr( cIza, 6 )
   ENDIF
   IF Right( cIza, 1 ) <> ";" .AND. Right( cIza, 1 ) <> ")"
      cIza += ";"  // dodaj ; da izraz bude regularan
   ENDIF
   IF Right( ciza, 2 ) == ");"
      ciza := Left( ciza, Len( ciza - 1 ) )
   ENDIF

FUNCTION NextToken( cSif, cVeznik )

   LOCAL i := 0, nPoz := 9999, nPom := 0, iTek

   FOR i := 1 TO Len( aTokens )
      nPom := At( aTokens[ i ], Upper( cSif ) )
      IF nPom > 0 .AND. nPom < nPoz
         nPoz := nPom
         cVeznik := aToken2[ i ]
         itek := i
      ENDIF
   NEXT

   IF nPoz = 9999;  nPoz := 0; ENDIF

   IF nPoz <> 0
      cSif := Left( cSif, nPoz - 1 ) + ";" + SubStr( cSif, nPoz + Len( aTokens[ itek ] ) )
   ENDIF

   RETURN nPoz



FUNCTION Tacno( cIzraz, xVar )

   LOCAL lRet, xVal := ""

   IF ValType( xVar ) == "B"
      xVal := Eval( xVar )
   ENDIF

   cIzraz := StrTran( cIzraz, "Eval(xVar)", "'" + xVal + "'" )

   lRet := &cIzraz

   IF ValType( lRet ) == "L"
      RETURN lRet
   ENDIF

   RETURN .F.



FUNCTION TacnoN( cIzraz, bIni, bWhile, bSkip, bEnd )

   LOCAL i, fRez := .F.

   LOCAL cPom

   IF cIzraz = ".t."
      RETURN .T.
   ENDIF

   Eval( bIni )

   DO WHILE Eval( bWhile )
      fRez := &cIzraz
      Eval( bSkip )
   ENDDO

   Eval( bEnd )

   RETURN fRez
