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

FUNCTION IniRPT()

   PUBLIC aTijelo := {}
   PUBLIC aTijeloP := {}
   PUBLIC aDetP := {}
   PUBLIC aDetUsl := {}
   PUBLIC aDetInit := {}
   PUBLIC aDetEnd := {}
   PUBLIC aDetCalc := {}
   PUBLIC aDetFor := {}
   PUBLIC aGH := {}
   PUBLIC aGF := {}
   PUBLIC aInitG := {}
   PUBLIC aGHP := {}
   PUBLIC aGFP := {}
   PUBLIC aUslG := {}
   PUBLIC aCalcG := {}

   RETURN



FUNCTION R2( cImeDef, cOutf, bFor, nDuzSif )



   LOCAL fpg, ng
   IF nDuzSif == NIL; nDuzSif := 0; ENDIF

   NBRG := Len( aInitG )
   ASize( aGF, NBRG )
   ASize( aGH, NBRG )


   ProcitajRep( cImeDef )

   fpg := .F.
   DO WHILE !Eof() .AND.  Eval( bFor )

      FOR ng := NBRG  TO  1 STEP -1
         IF Eval( aUslG[ ng ] ) .AND. fPG
            SKIP -1
            Ispisi( ng, @aGF, @aGFP )
            SKIP
         ENDIF
      NEXT

      FOR ng := 1  TO NBRG
         fPG := .T.
         IF Eval( aUslG[ ng ] )
            Eval( aInitG[ ng ] )
            Ispisi( ng, @aGH, @aGHP )
         ENDIF
         Eval( aCalcG[ ng ] )
      NEXT

      // sada idemo na tijelo
      PRIVATE nTekPT := 1
      FOR nT := 1 TO Len( aTijelo )
         IF aTijelo[ nT, 1 ] == "&"
            IspisiT( nt, nDuzSif )
         ELSEIF aTijelo[ nT, 1 ] $ "123"
            nDet := Val( aTijelo[ nT, 1 ] )
            Eval( aDetInit[ nDet ] )
            cTekRed := aTijelo[ nT, 2 ]
            IspisiD( nDet )
            Eval( aDetEnd[ nDet ] )
         ENDIF
      NEXT

      SKIP
   ENDDO

   IF fpg  // ako je izvr{en prolaz kroz grupu
      FOR i := NBRG TO 1  STEP -1 // footer
         SKIP -1
         Ispisi( i, @aGF, @aGFP )
         SKIP
      NEXT
   ENDIF

   RETURN NIL



FUNCTION Ispisi( nRedBr, aLinije, aPolja )

   //
   //
   // za grupa header,footer

   LOCAL i, nTekP, cTekRed, cC, nPreskoci

   NTEKP := 1
   NPRESKOCI := 0

   cTekRed := aLinije[ nRedBr ]

   FOR I := 1 TO Len( cTekRed )  // cTekRed je gornja varijabla
      IF NPRESKOCI == 0
         CC := SubStr( CTEKRED, I, 1 )
         IF CC == "#"
            XPOLJE := TOSTR(   Eval( ( aPolja[ nRedBr ] )[ NTEKP++ ] )    )
            QQOut( XPOLJE )
            NPRESKOCI := Len( XPOLJE ) -1
         ELSE
            IF cC <> "\"
               QQOut( CC )
            ENDIF
         ENDIF
      ELSE
         NPRESKOCI--
      ENDIF
   NEXT

   RETURN NIL


FUNCTION IspisiT( nRedBr, nDuzSif )

   //
   // Ispisi tijelo

   LOCAL i, cC, nPreskoci, nMemoLin, nLinPredh, fUMemu, nMemoLen
   NPRESKOCI := 0
   cTekRed := aTijelo[ nRedBr, 2 ]
   nLinPredh := 1
   nMemoLin := 0
   fUMemu := .F.
   FOR I := 1 TO Len( cTekRed )  // cTekRed je gornja varijabla
      IF NPRESKOCI == 0
         CC := SubStr( CTEKRED, I, 1 )
         IF cC == Chr( 10 )
            IF fUMemu
               QQOut( Chr( 10 ) )
               i := nLinPredh
               LOOP
            ELSE
               nLinPredh := i
            ENDIF
         ENDIF
         IF CC == "#" .AND. ValType( aTijeloP[ NTEKPT ] ) == "A"
            fUMemu := .T.
            IF nMemoLin == 0
               xMemo := Eval( aTijeloP[ NTEKPT, 1 ] )
               nMemoLen := aTijeloP[ NTEKPT, 2 ]
               nMemoCount := MLCount( xMemo, nMemoLen )
               IF nmemocount == 0
                  fUMemu := .F.
                  QQOut( " " )
                  NTEKPT++
               ENDIF
            ENDIF
            IF nMemoLin < nMemoCount
               QQOut( Left( MemoLine( xMemo, nMemoLen, ++nMemoLin ), nMemoLen ) )
               nPreskoci := nMemoLen - 1 + nDuzSif
               IF nMemoLin == nMemoCount
                  fUMemu := .F.
                  nMemoLin := 0
                  NTEKPT++
               ENDIF
            ENDIF
         ELSEIF CC == "#"
            XPOLJE := TOSTR(   Eval( aTijeloP[ NTEKPT++ ] )    )
            QQOut( XPOLJE )
            NPRESKOCI := Len( XPOLJE ) -1 + nDuzSif
         ELSE
            IF cC <> "\"
               QQOut( CC )
            ENDIF
         ENDIF
      ELSE
         NPRESKOCI--
      ENDIF
   NEXT

   RETURN



FUNCTION IspisiD( nRedBr )

   // Ispisi detalj

   LOCAL i, nTekP, nLinPoc, cC, nPreskoci, nMemoLin, nLinPredh, fUMemu, nMemoLen

   DO WHILE Eval( aDetUsl[ nRedBr ] )

      IF aDetFor[ nRedBr ] == NIL .OR. Eval( aDetFor[ nRedBr ] )
         Eval( aDetCalc[ nRedBr ] )
         NTEKP := 1
         NPRESKOCI := 0
         nLinPredh := 1
         nMemoLin := 0
         fUMemu := .F.
         FOR I := 1 TO Len( cTekRed )  // cTekRed je gornja varijabla
            IF NPRESKOCI == 0
               CC := SubStr( CTEKRED, I, 1 )
               IF cC == Chr( 10 )
                  IF fUMemu
                     QQOut( Chr( 10 ) )
                     i := nLinPredh
                     LOOP
                  ELSE
                     nLinPredh := i
                  ENDIF
               ENDIF

               IF CC == "#" .AND. ValType( aDetP[ nRedBr, NTEKP ] ) == "A"
                  fUMemu := .T.
                  IF nMemoLin == 0
                     xMemo := Eval( aDetP[ nRedBr, NTEKP, 1 ] )
                     nMemoLen := ( aDetP[ nRedBr, NTEKP ] )[ 2 ]
                     nMemoCount := MLCount( xMemo, 60 )
                     IF nmemocount == 0
                        fUMemu := .F.
                        QQOut( " " )
                        NTEKP++
                     ENDIF
                  ENDIF
                  IF nMemoLin < nMemoCount
                     QQOut( MemoLine( xMemo, nMemoLen, ++nMemoLin ) )
                     nPreskoci := nMemoLen - 1
                     IF nMemoLin == nMemoCount
                        nMemoLin := 0
                        fUMemu := .F.
                        NTEKP++
                     ENDIF
                  ENDIF

               ELSEIF cC == "#"
                  XPOLJE := TOSTR(   Eval( ( aDetP[ nRedBr ] )[ NTEKP++ ] )    )
                  QQOut( XPOLJE )
                  NPRESKOCI := Len( XPOLJE ) -1
               ELSE
                  IF cC <> "\"
                     QQOut( CC )
                  ENDIF
               ENDIF

            ELSE
               NPRESKOCI--
            ENDIF
         NEXT
      ENDIF // aDetFor

      SKIP
   ENDDO

   RETURN


FUNCTION ProcitajRep( cImef )

   LOCAL nH := FOpen( cImeF )
   LOCAL cBuf := Space( 512 )
   LOCAL nPreskoci := 0
   LOCAL cTekRed := ""
   LOCAL cTipL := "&", cTipL2
   LOCAL cC := ""

   DO WHILE .T.
      nB := FRead( nH, @cBuf, 512 )
      FOR i := 1 TO nB
         IF cC == "\"
            cC := "\" + SubStr( cBuf, i, 1 )
         ELSE
            cC := SubStr( cBuf, i, 1 )
         ENDIF
         IF Len( cC ) == 2
            IF cTipL <> cC
               IF !Empty( cTekRed )
                  cTipL2 := SubStr( cTipL, 2, 1 )
                  IF ChSub( cTipL2, "a" ) >= 0
                     aGF[ ChSub( cTipL2, "`" ) ] := cTekRed
                  ELSEIF ChSub( cTipL2, "A" ) >= 0
                     aGH[ ChSub( cTipL2, "@" ) ] := cTekRed
                  ELSE
                     AAdd( aTijelo, { SubStr( cTipL, 2, 1 ), cTekRed } )
                  ENDIF
               ENDIF
               cTekRed := ""
               cTipL := cC
            ENDIF
         ELSE
            IF cC <> "\"
               cTekRed += cC
            ENDIF
         ENDIF
      NEXT
      IF nB < 512; exit; ENDIF
   ENDDO

   IF !Empty( cTekRed )
      cTipL2 := SubStr( cTipL, 2, 1 )
      IF ChSub( cTipL2, "a" ) >= 0
         aGF[ ChSub( cTipL2, "`" ) ] := cTekRed
      ELSEIF ChSub( cTipL2, "A" ) >= 0
         aGH[ ChSub( cTipL2, "@" ) ] := cTekRed
      ELSE
         AAdd( aTijelo, { SubStr( cTipL, 2, 1 ), cTekRed } )
      ENDIF
   ENDIF
   cTekRed := ""
   cTipL := cC
   FClose( nH )

   RETURN


/* SetRptLineAndText(aLineArgs, nVariant)
 *     vraca liniju po definisanoj matrici
 *   param: aLineArgs - matrica argumenata
 *   param: nVariant - varijanta, 0 - linija, 1 - prvi red izvjestaja, 2 - drugi red izvjestaja
 *  \example: aLineArgs := {2, 5, 5, 3}
 *            ret: -- ----- ----- ---
 */

FUNCTION SetRptLineAndText( aLineArgs, nVariant, cDelimiter )

   LOCAL cLine := ""

   IF nVariant == nil
      // po def. je linija
      nVariant := 0
   ENDIF
   IF cDelimiter == nil
      cDelimiter := " "
   ENDIF

   FOR i := 1 TO Len( aLineArgs )
      IF nVariant == 0
         cLine += Replicate( "-", aLineArgs[ i, 1 ] )
      ELSEIF nVariant == 1
         nEmptyFill := aLineArgs[ i, 1 ] - Len( aLineArgs[ i, 2 ] )
         cLine += aLineArgs[ i, 2 ] + Space( nEmptyFill )
      ELSEIF nVariant == 2
         nEmptyFill := aLineArgs[ i, 1 ] - Len( aLineArgs[ i, 3 ] )
         cLine += aLineArgs[ i, 3 ] + Space( nEmptyFill )
      ELSEIF nVariant == 3
         nEmptyFill := aLineArgs[ i, 1 ] - Len( aLineArgs[ i, 4 ] )
         cLine += aLineArgs[ i, 4 ] + Space( nEmptyFill )
      ENDIF

      IF i <> Len( aLineArgs )
         IF nVariant == 0
            cLine += " "
         ELSE
            cLine += cDelimiter
         ENDIF
      ENDIF
   NEXT

   RETURN cLine
