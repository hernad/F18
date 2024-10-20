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

/*
 *  Stampa tabele
 *
 *  code
 * ULAZI
 * aKol - niz definicija kolona, npr.
 * aKol:={  { "R.br."     , {|| rbr+"."             }, .f., "C",  5, 0, 1, 1},;
 *         { "PPU"       , {|| nPPU                }, .t., "N", 11, 2, 1, 2},;
 *         { "MPC"       , {|| roba->mpc           }, .f., "N", 11, 2, 1, 3},;
 *         { "MP iznos"  , {|| kolicina*roba->mpc  }, .t., "N", 11, 2, 1, 4} }
 * gdje je (i,1) - zaglavlje kolone
 *         (i,2) - blok koji vraca vrijednost za ispis
 *         (i,3) - logicka vrijednost za izbor sumiranja (.t.)
 *         (i,4) - tip promjenjive koju vraca blok (i,2)
 *         (i,5) - duzina promjenjive koju vraca blok (i,2) ili sirina kolone
 *         (i,6) - broj decimalnih mjesta kod numerickih vrijednosti
 *         (i,7) - broj reda u stavki u kom ce se stampati vrijednost
 *         (i,8) - broj kolone u stavki u kojoj ce se stampati vrijednost
 *         (i,9) - bSuma - sumiranje se vrsi po ovoj koloni
 * bZaRed   - blok koji se izvrsava pri svakom stampanju sloga (reda u tabeli)
 * nOdvoji  - lijeva margina
 * nCrtice  - nacin crtanja tabele ( 0 za crtice, 1 za linije, ostalo za tip
 *           tabele sa duplim linijama )
 * bUslov   - blok koji odredjuje do kog sloga ce se uzimati vrijednosti,
 *           vraca logicku vrijednost (ako je uvijek .t. kraj ce biti tek
 *           pri pojavljivanju EOF (kraj baze)   - "while" blok
 * lA4papir - sirina papira, ako je .t. radice se sa A4 papirom. Moze se
 *           zadati i "4" za A4, "3" za A3, "POS" za 40 znakova u redu
 * cNaslov  - zaglavlje tabele, ispisuje se samo ako je proslijedjen parametar
 * bfor     - blok koji odredjuje da li ce slog biti obradjivan u tabeli
 * nStr     - broj strane na kojoj se trenutno nalazimo, ako je -1 uopste se
 *           nece prelamati tabela (kontinuirani papir)
 * lOstr    - .f. znaci da ne treba ostranicavati posljednju stranu
 * lLinija  - .t. znaci da ce se stavke odvajati linijom
 * bSubTot  - blok koji vraca {.t.,cSubTxt} kada treba prikazati subtotal
 * nSlogova - broj slogova za obradu  koristi se samo za prikaz
 * cTabBr   - oznaka (naziv) za tabelu procenta uradjenog posla
 * lCTab    - horiz.centriranje tabele (.t. - da, .f. - ne)    nil->.t.
 * bZagl    - blok dodatnog zaglavlja koje ima prioritet nad zaglavljem
 *           koje se nalazi u ovoj f-ji
 *
 * blokovi se izvrsavaju ovim redom:   1. bUslov   2. bfor   3. bZaRed
 *
 */

FUNCTION print_lista_2( aKol, bZaRed, nOdvoji, nCrtice, bUslov, lA4papir, cNaslov, bFor, nStr, lOstr, lLinija, bSubTot, nSlogova, cTabBr, lCTab, bZagl )

   LOCAL cOk, nKol := 0, i := 0, xPom, cTek1 := "Prenos sa str.", lMozeL := .F.
   LOCAL cTek2 := "U K U P N O:"
   LOCAL nDReda := 0
   LOCAL cTek3 := "Ukupno na str."
   LOCAL cPom
   LOCAL lPrenos := .F., cLM, cLM2, nMDReda, aPom := {}, nSuma, nRed := 0, j := 0, xPom1, xPom2
   LOCAL aPrZag := {}, aPrSum := {}, aPrStav := {}, nSubTot, xTot := { .F., "" }, lPRed := .F.
   LOCAL nPRed := 0, aPRed := {}, l := 0, nBrojacSlogova := 0
   LOCAL xPodvuci := "", cPodvuci := " "
   LOCAL lFor := .F., k := 0


   PRIVATE glNeSkipuj := .F.

   IF "U" $ Type( "gaDodStavke" ); gaDodStavke := {}; ENDIF
   IF "U" $ Type( "gaSubTotal" ); gaSubTotal := {}; ENDIF
   IF "U" $ Type( "gnRedova" ); gnRedova := 64; ENDIF
   IF "U" $ Type( "gbFIznos" ); gbFIznos := nil; ENDIF
   IF !( "U" $ Type( "dodatni_redovi_po_stranici()" ) )
      gnRedova := 64 + dodatni_redovi_po_stranici()
   ENDIF

   IF bSubTot == nil; bSubTot := {|| { .F., } }; xTot := { .F., }; ENDIF
   IF lLinija == nil; lLinija := .F. ; ENDIF
   IF lOstr == nil; lOstr := .T. ; ENDIF
   IF nStr == nil; nStr := 1; ENDIF
   IF nCrtice == nil; nCrtice := 1; ENDIF
   IF nOdvoji == nil; nOdvoji := 0; ENDIF

   IF bUslov == nil
      bUslov := {|| Inkey(), IIF( LastKey() == 27, PrekSaEsc(), .T. ) }
   ENDIF

   IF bZaRed == nil
      bZaRed := {|| .T. }
   ENDIF

   IF bFor == nil; bFor := {|| .T. }; ENDIF
   IF lCTab == nil; lCTab := .T. ; ENDIF
   IF lA4papir == nil; lA4papir := "4"; ENDIF
   IF ValType( lA4papir ) == "L"; lA4papir := IF( lA4papir, "4", "3" ); ENDIF
   IF nCrtice == 9; nStr := -1; lOstr := .F. ; ENDIF
   IF nSlogova != nil; Postotak( 1, nSlogova, cTabBr,,, .F. ); ENDIF

   AEval( aKol, {| x| xPom := x[ 8 ], xPom1 := x[ 5 ], xPom2 := x[ 3 ], iif( AScan( aPom, {| y| y[ 1 ] == xPom } ) == 0, Eval( {|| nDReda += xPom1, AAdd( aPom, { xPom, xPom1, xPom2 } ) } ), ), ;
      IIF( x[ 3 ], lPrenos := .T., ), IIF( x[ 8 ] > nKol, nKol := x[ 8 ], ), iif( x[ 7 ] > nRed, nRed := x[ 7 ], ), IF( x[ 4 ] == "P", lPRed := .T., ) } )
   ASort( aPom,,, {| x, y| x[ 1 ] < y[ 1 ] } )

   FOR i := 1 TO nRed
      FOR j := 1 TO nKol
         IF AScan( aKol, {| x| x[ 7 ] == i .AND. x[ 8 ] == j } ) == 0
            AAdd( aKol, { "", {|| "#" }, .F., "C", aPom[ j, 2 ], 0, i, j } )
         ENDIF
      NEXT
   NEXT

   ASort( aKol,,, {| x, y| 100 * x[ 7 ] + x[ 8 ] < 100 * y[ 7 ] + y[ 8 ] } )

   FOR i := 1 TO nKol
      FOR j := 1 TO nRed
         IF aKol[ ( j - 1 ) * nKol + i ][ 3 ]
            aPom[ i ][ 3 ] := .T.
            IF AScan( aPrSum, j ) == 0
               AAdd( aPrSum, j )
            ENDIF
         ENDIF
         IF !Empty( aKol[ ( j - 1 ) * nKol + i ][ 1 ] )
            IF AScan( aPrZag, j ) == 0
               AAdd( aPrZag, j )
            ENDIF
         ENDIF
         xPom := Eval( aKol[ ( j - 1 ) * nKol + i ][ 2 ] )
         IF ValType( xPom ) == "C"
            IF xPom != "#"
               IF AScan( aPrStav, j ) == 0
                  AAdd( aPrStav, j )
               ENDIF
            ELSE
               aKol[ ( j - 1 ) * nKol + i ][ 2 ] := {|| "" }
            ENDIF
         ELSE
            IF AScan( aPrStav, j ) == 0
               AAdd( aPrStav, j )
            ENDIF
         ENDIF
      NEXT
   NEXT

   ASort( aPrZag )
   ASort( aPrSum )
   ASort( aPrStav )

   nDReda += nKol + 1 + nOdvoji
   nMDReda := IF( lA4papir == "POS", 40, MDDReda( nDReda, lA4papir ) )
   cLM := iif( nMDReda - nDReda >= 0, Space( nOdvoji + Int( ( nMDReda - nDReda ) / 2 ) ), "" )
   cLM2 := iif( nMDReda - nDReda >= 0 .AND. !lCTab, Space( nOdvoji ), cLM )
   GuSt2( nDReda, lA4papir )

   IF nStr >= 0 .AND. ( PRow() > ( gnRedova + iif( gPrinter = "R", 2, 0 ) - 7 -Len( aPrStav ) -Len( aPrZag ) ) .OR. PRow() > ( gnRedova + IF( gPrinter = "R", 2, 0 ) -11 -Len( aPrStav ) -Len( aPrZag ) ) .AND. cNaslov != nil )
      IF gPrinter != "R"
         DO WHILE PRow() < gnRedova - 2; QOut(); ENDDO
         xPom := Str( nStr, 3 ) + ". strana"
         QOut( cLM + PadC( xPom, nDReda - nOdvoji ) )
      ENDIF
      gPFF()
      SetPRC( 0, 0 )
      IF !( bZagl == nil )
         Eval( bZagl )
      ENDIF
      ++nStr
   ENDIF

   IF nCrtice == 0
      cOk := { "-", "-", " ", "-", " ", "-", " ", "-", "-", " ", "-", " ", "-", "-", "-", " " }
   ELSEIF nCrtice == 1

      cOk := { "+", "-", "+", "+", ":", "+", "+", "+", "+", "+", "+", ":", "-", "+", "+", "+" }

   ELSEIF nCrtice == 9
      // rtf-fajlovi
      cOk := { " ", " ", " ", " ", "#", " ", " ", " ", " ", " ", " ", "#", " ", " ", " ", " " }
   ELSE
      cOk := { "+", "-", "+", "+", ":", "+", "+", "+", "+", "+", "+", ":", "-", "+", "+", "+" }
   ENDIF
   // 1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16

   nSuma := Array( nKol )
   AFill( nSuma, 0 )
   nSuma := AMFILL( nSuma, nRed )
   nSubTot := Array( nKol )
   AFill( nSubTot, 0 )
   nSubTot := AMFILL( nSubTot, nRed )

   IF cNaslov != nil
      QOut( cLM2 + cOk[ 1 ] + Replicate( cOk[ 2 ], nDReda - nOdvoji - 2 ) + cOk[ 4 ] )
      QOut( cLM2 + cOk[ 12 ] + Space( nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
      QOut( cLM2 + cOk[ 12 ] + PadC( AllTrim( cNaslov ), nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
      QOut( cLM2 + cOk[ 12 ] + Space( nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
   ENDIF
   i := 0; QOut( cLM2 + IF( cNaslov != nil, cOk[ 6 ], cOk[ 1 ] ) )
   AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, cOk[ 3 ], IF( cNaslov != nil, cOk[ 8 ], cOk[ 4 ] ) ) ) } )

   FOR j := 1 TO Len( aPrZag )
      i := 0; QOut( cLM2 + cOk[ 12 ] )
      AEval( aKol, {| x| ++i, QQOut( PadC( x[ 1 ], x[ 5 ] ) + IIF( i < nKol, cOk[ 5 ], cOk[ 12 ] ) ) }, ( aPrZag[ j ] -1 ) * nKol + 1, nKol )
   NEXT

   i := 0; QOut( cLM2 + cOk[ 6 ] )
   AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IIF( i < nKol, cOk[ 7 ], cOk[ 8 ] ) ) } )

   // idemo po bazi
   // -------------
   DO WHILE !Eof() .AND. Eval( bUslov )

      IF nSlogova != nil
         Postotak( 2, ++nBrojacSlogova )
      ENDIF


      IF !( lFor := Eval( bFor ) ) // evaluacija "ZA" bloka (korisnicke "FOR" funkcije)
         IF Empty( gaDodStavke ) .AND. Empty( gaSubTotal )
            IF !glNeSkipuj
               SKIP 1
            ENDIF
            LOOP
         ENDIF
      ENDIF

      IF lFor


         IF lMozeL; xTot := Eval( bSubTot ); ENDIF // evaluacija bloka internog subtotala


         xPodvuci := Eval( bZaRed ) // izvrsimo blok koji se izvrsava za svaku stavku koja se stampa
         // treba li na kraju izvrsiti podvlacenje
         // --------------------------------------
         IF ValType( xPodvuci ) == "C" .AND. Left( Upper( xPodvuci ), 7 ) == "PODVUCI"
            cPodvuci := Right( xPodvuci, 1 )
            xPodvuci := .T.
         ELSE
            xPodvuci := .F.
         ENDIF

      ENDIF

      // ako ima kolona koje moraju za jednu stavku ici u vise redova
      // potrebno je izracunati max.broj tih redova (nPRed)
      // ------------------------------------------------------------
      IF lFor .AND. lPRed
         aPRed := {}; nPRed := 0
         AEval( aKol, {| x| IIF( Left( x[ 4 ], 1 ) == "P", IIF( !Empty( xPom := LomiGa( Eval( x[ 2 ] ), IIF( Len( x[ 4 ] ) > 1, Val( SubStr( x[ 4 ], 2 ) ), 1 ), 0, x[ 5 ] ) ), AAdd( aPRed, { xPom, x[ 5 ], Len( xPom ) / x[ 5 ], x[ 8 ], Len( xPom ) / x[ 5 ], x[ 7 ] } ), ), ) } )
         ASort( aPRed,,, {| x, y| x[ 4 ] < y[ 4 ] } )
         AEval( aPRed, {| x| IIF( nPRed < x[ 3 ] + x[ 6 ] -1, nPRed := x[ 3 ] + x[ 6 ] -1, ) } )
      ENDIF

      // ispitivanje uslova za prelazak na novu stranicu
      // -----------------------------------------------
      IF lFor .AND. nStr >= 0 .AND. ( PRow() > gnRedova + IIF( gPrinter = "R", 2, 0 ) -IIF( xPodvuci, 1, 0 ) -5 -Max( Len( aPrStav ), nPRed ) -IIF( lPrenos, Len( aPrSum ) * IF( xTot[ 1 ], ( 2 + 1 / Len( aPrSum ) ), 1 ), 0 ) )
         NaSljedStranu( @lMozeL, @lPrenos, cLM2, cOk, aPom, nKol, @nStr, cLM, ;
            nDReda, nOdvoji, aPrSum, aKol, nSuma, cTek3, bZagl, ;
            cNaslov, aPrZag, cTek1, xTot )
      ENDIF

      IF lfor .AND. xTot[ 1 ] // stampanje internog subtotala
         // podvlacenje prije subtotala (ako nije prvi red na stranici)
         IF lMozeL
            i := 0; QOut( cLM2 + cOk[ 6 ] )
            AEval( aPom, {| x| ++i, ;
               QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 10 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
         ENDIF
         FOR j := 1 TO Len( aPrSum )
            i := 0
            cPom := ""
            AEval( aKol, {| x| ++i, ;
               cPom += IF( x[ 3 ], Str( nSubTot[ aPrSum[ j ] ][ i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !aPom[ i, 3 ] .AND. !aPom[ i + 1, 3 ], " ", cOk[ 5 ] ), cOk[ 12 ] ), nSubTot[ aPrSum[ j ] ][ i ] := 0 }, ( aPrSum[ j ] -1 ) * nKol + 1, nKol )
            xPom := IF( j == Len( aPrSum ), xTot[ 2 ], Space( Len( xTot[ 2 ] ) ) )
            QOut( cLM2 + cOk[ 12 ] + StrTran( cPom, Space( Len( xPom ) ), xPom, 1, 1 ) )
         NEXT
         i := 0
         QOut( cLM2 + cOk[ 6 ] )
         AEval( aPom, {| x| ++i, ;
            QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 3 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
         lMozeL := .F.
      ENDIF

      // odvajanje stavki linijom (ako je zadano i ako nije prvi red)
      // ------------------------------------------------------------
      IF lLinija .AND. lMozeL
         i := 0; QOut( cLM2 + cOk[ 14 ] )
         AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 13 ], x[ 2 ] ) + IF( i < nKol, cOk[ 16 ], cOk[ 15 ] ) ) } )
      ENDIF

      IF lFor

         // dvostruka petlja u kojoj se vrsi sabiranje totala, internih subtotala
         // i stampanje stavke  ( j=broj reda stavke, i=kolona stavke )
         // ---------------------------------------------------------------------
         FOR j := 1 TO Max( Len( aPrStav ), nPRed )
            QOut( cLM2 + cOk[ 12 ] )
            FOR i := 1 TO nKol
               IF j <= Len( aPrStav )
                  xPom := Eval( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 2 ] )
                  IF aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 3 ] .AND. ValType( xPom ) == "N"
                     IF Len( aKol[ ( aPrStav[ j ] -1 ) * nKol + i ] ) >= 9   // postoji bSuma
                        xPom := Eval( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 9 ] )
                     ENDIF
                     nSuma[ aPrStav[ j ] ][ i ] += xPom
                     IF xTot[ 2 ] != nil; nSubTot[ aPrStav[ j ] ][ i ] += xPom; ENDIF
                  ENDIF
                  xPom := Eval( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 2 ] )
                  IF aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 4 ] = "N"
                     IF ValType( xPom ) != "N" .OR. Round( xPom, aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 6 ] ) == 0 .AND. Right( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 4 ], 1 ) == "-"
                        QQOut( Space( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 5 ] ) )
                     ELSE
                        IF gbFIznos != nil
                           QQOut( Eval( gbFIznos, ;
                              xPom, ;
                              aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 5 ], ;
                              aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 6 ] );
                              )
                        ELSE
                           QQOut( Str( xPom, aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 5 ], aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 6 ] ) )
                        ENDIF
                     ENDIF
                  ELSEIF aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 4 ] == "C"
                     QQOut( PadR( xPom, aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 5 ] ) )
                  ELSEIF aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 4 ] == "D"
                     QQOut( PadC( DToC( xPom ), aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 5 ] ) )
                  ELSEIF Left( aKol[ ( aPrStav[ j ] -1 ) * nKol + i, 4 ], 1 ) == "P"
                     l := AScan( aPRed, {| x| x[ 4 ] == i } )
                     IF l > 0
                        xPom := IF( aPRed[ l, 3 ] > 0, SubStr( aPRed[ l, 1 ], ( aPRed[ l, 5 ] -aPRed[ l, 3 ] ) * aPRed[ l, 2 ] + 1, aPRed[ l, 2 ] ), Space( aPRed[ l, 2 ] ) )
                        --aPRed[l,3 ]
                        QQOut( xPom )
                     ELSE
                        QQOut( Space( aKol[ i, 5 ] ) )
                     ENDIF
                  ENDIF
               ELSE
                  IF ( l := AScan( aPRed, {| x| x[ 4 ] == i } ) ) != 0
                     xPom := IF( aPRed[ l, 3 ] > 0, SubStr( aPRed[ l, 1 ], ( aPRed[ l, 5 ] -aPRed[ l, 3 ] ) * aPRed[ l, 2 ] + 1, aPRed[ l, 2 ] ), Space( aPRed[ l, 2 ] ) )
                     --aPRed[l,3 ]
                     QQOut( xPom )
                  ELSE
                     QQOut( Space( aKol[ i, 5 ] ) )
                  ENDIF
               ENDIF
               QQOut( IF( i < nKol, cOk[ 5 ], cOk[ 12 ] ) )
            NEXT
         NEXT

      ENDIF

      // stampanje stavke koja sluzi samo za podvlacenje
      // -----------------------------------------------
      IF lfor .AND. xPodvuci
         i := 0
         QOut( cLM2 + cOk[ 12 ] )
         AEval( aPom, {| x| ++i, QQOut( Replicate( cPodvuci, x[ 2 ] ) + IF( i < nKol, cOk[ 5 ], cOk[ 12 ] ) ) } )
      ENDIF

      IF !( Empty( gaDodStavke ) )
         FOR j := 1 TO Len( gaDodStavke )
            // ispitaj da li je potreban prelazak na novu stranicu
            IF nStr >= 0 .AND. ( PRow() > gnRedova + IF( gPrinter = "R", 2, 0 ) -5 -1 -IF( lPrenos, 1, 0 ) )
               NaSljedStranu( @lMozeL, @lPrenos, cLM2, cOk, aPom, nKol, @nStr, cLM, ;
                  nDReda, nOdvoji, aPrSum, aKol, nSuma, cTek3, bZagl, ;
                  cNaslov, aPrZag, cTek1, xTot )
            ENDIF
            // odstampaj liniju za odvajanje ako je potrebno (samo za j==1)
            IF j == 1 .AND. lLinija .AND. lMozeL
               i := 0; QOut( cLM2 + cOk[ 14 ] )
               AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 13 ], x[ 2 ] ) + IF( i < nKol, cOk[ 16 ], cOk[ 15 ] ) ) } )
            ENDIF

            QOut( cLM2 + cOk[ 12 ] )
            FOR i := 1 TO nKol
               // izvrsi sumiranje
               xPom := gaDodStavke[ j, i ]
               IF aKol[ i, 3 ] .AND. xPom != nil
                  nSuma[ 1, i ] += xPom
               ENDIF
               // odstampaj stavku
               StStavku( aKol, xPom, i, nKol, cOk )
            NEXT
         NEXT
      ENDIF


      IF !( Empty( gaSubTotal ) )
         lMozeL := .T.
         FOR k := 1 TO Len( gaSubTotal )
            // ispitaj da li je potreban prelazak na novu stranicu
            IF nStr >= 0 .AND. ( PRow() > gnRedova + IF( gPrinter = "R", 2, 0 ) -5 -2 -IF( lPrenos, 1, 0 ) )
               IF k > 1
                  i := 0; QOut( cLM2 + cOk[ 6 ] )
                  AEval( aPom, {| x| ++i, ;
                     QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !( x[ 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N" ) .AND. !( aPom[ i + 1, 3 ] .OR. ValType( gaSubTotal[ k, i + 1 ] ) == "N" ), cOk[ 3 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
               ENDIF
               NaSljedStranu( @lMozeL, @lPrenos, cLM2, cOk, aPom, nKol, @nStr, cLM, ;
                  nDReda, nOdvoji, aPrSum, aKol, nSuma, cTek3, bZagl, ;
                  cNaslov, aPrZag, cTek1, { .T., } )
            ENDIF
            // podvlacenje prije subtotala (ako nije prvi red na stranici)
            IF lMozeL
               i := 0; QOut( cLM2 + cOk[ 6 ] )
               AEval( aPom, {| x| ++i, ;
                  QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !( x[ 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N" ) .AND. !( aPom[ i + 1, 3 ] .OR. ValType( gaSubTotal[ k, i + 1 ] ) == "N" ), cOk[ 10 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
            ELSEIF k > 1
               i := 0; QOut( cLM2 + cOk[ 6 ] )
               AEval( aPom, {| x| ++i, ;
                  QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !( x[ 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N" ) .AND. !( aPom[ i + 1, 3 ] .OR. ValType( gaSubTotal[ k, i + 1 ] ) == "N" ), cOk[ 2 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
            ENDIF
            // stampanje subtotala
            i := 0; cPom := ""
            AEval( aKol, {| x| ++i, ;
               cPom += IF( x[ 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N", Str( gaSubTotal[ k, i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !( aPom[ i, 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N" ) .AND. !( aPom[ i + 1, 3 ] .OR. ValType( gaSubTotal[ k, i + 1 ] ) == "N" ), " ", cOk[ 5 ] ), cOk[ 12 ] ) }, 1, nKol )
            xPom := ATail( gaSubTotal[ k ] )
            QOut( cLM2 + cOk[ 12 ] + StrTran( cPom, Space( Len( xPom ) ), xPom, 1, 1 ) )
            IF k == Len( gaSubTotal )
               i := 0; QOut( cLM2 + cOk[ 6 ] )
               AEval( aPom, {| x| ++i, ;
                  QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !( x[ 3 ] .OR. ValType( gaSubTotal[ k, i ] ) == "N" ) .AND. !( aPom[ i + 1, 3 ] .OR. ValType( gaSubTotal[ k, i + 1 ] ) == "N" ), cOk[ 3 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
            ENDIF
            lMozeL := .F.
         NEXT
         IF !glNeSkipuj
            SKIP 1
         ENDIF
         LOOP
      ENDIF

      lMozeL := .T.

      IF !glNeSkipuj; SKIP 1; ENDIF
   ENDDO  // kraj setnje po bazi

   IF nSlogova != nil
      Postotak( -1,,,,, .F. )
   ENDIF

   // na posljednjoj stranici prikazi interni subtotal ako treba
   // ----------------------------------------------------------
   IF xTot[ 2 ] != nil
      xTot := Eval( bSubTot )
      IF lMozeL
         i := 0; QOut( cLM2 + cOk[ 6 ] )
         AEval( aPom, {| x| ++i, ;
            QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 10 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
      ENDIF
      FOR j := 1 TO Len( aPrSum )
         i := 0; cPom := ""
         AEval( aKol, {| x| ++i, ;
            cPom += IF( x[ 3 ], Str( nSubTot[ aPrSum[ j ] ][ i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !aPom[ i, 3 ] .AND. !aPom[ i + 1, 3 ], " ", cOk[ 5 ] ), cOk[ 12 ] ) }, ( aPrSum[ j ] -1 ) * nKol + 1, nKol )
         xPom := IF( j == Len( aPrSum ), xTot[ 2 ], Space( Len( xTot[ 2 ] ) ) )
         QOut( cLM2 + cOk[ 12 ] + StrTran( cPom, Space( Len( xPom ) ), xPom, 1, 1 ) )
      NEXT
   ENDIF

   IF !lPrenos
      // zavrsi posljednju stranicu: bez sumiranja
      // -----------------------------------------
      i := 0; QOut( cLM2 + cOk[ 9 ] )
      AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, cOk[ 10 ], cOk[ 11 ] ) ) } )
      IF ( nStr >= 0 .AND. lOstr )
         IF gPrinter != "R"
            DO WHILE PRow() < gnRedova - 2; QOut(); ENDDO
            xPom := Str( nStr, 3 ) + ". strana"
            QOut( cLM + PadC( xPom, nDReda - nOdvoji ) )
         ENDIF
         gPFF()
         SetPRC( 0, 0 )
         IF !( bZagl == nil )
            Eval( bZagl )
         ENDIF
      ENDIF
   ELSE
      // zavrsi posljednju stranicu: prikazi sumiranje
      // ---------------------------------------------
      i := 0; QOut( cLM2 + cOk[ 6 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], IF( xTot[ 1 ], cOk[ 2 ], cOk[ 10 ] ), cOk[ 7 ] ), cOk[ 8 ] ) ) } )
      FOR j := 1 TO Len( aPrSum )
         i := 0; cPom := ""
         AEval( aKol, {| x| ++i, ;
            cPom += IF( x[ 3 ], Str( nSuma[ aPrSum[ j ] ][ i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !aPom[ i, 3 ] .AND. !aPom[ i + 1, 3 ], " ", cOk[ 5 ] ), cOk[ 12 ] ) }, ( aPrSum[ j ] -1 ) * nKol + 1, nKol )
         QOut( cLM2 + cOk[ 12 ] + IF( j == Len( aPrSum ), StrTran( cPom, Space( Len( cTek2 ) ), cTek2, 1, 1 ), cPom ) )
      NEXT
      i := 0; QOut( cLM2 + cOk[ 9 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 2 ], cOk[ 10 ] ), cOk[ 11 ] ) ) } )
   ENDIF

   RETURN nSuma



FUNCTION MDDReda( nZnak, lA4papir )


   nZnak = IF( lA4papir == "4", nZnak * 2 -1, IF( lA4papir == "L4", nZnak * 1.4545 -1, nZnak ) )

   RETURN Int( IF( nZnak < 161, 160, IF( nZnak < 193, 192, IF( nZnak < 275, 274, 320 ) ) ) / IF( lA4papir == "4", 2, IF( lA4papir == "L4", 1.4545, 1 ) ) )

   RETURN .T.



FUNCTION nPodStr( cPod, cStr )

   LOCAL nVrati := 0, nPod := Len( cPod )

   FOR i := 1 TO Len( cStr ) + 1 -nPod
      IF SubStr( cStr, i, nPod ) == cPod; nVrati++; ENDIF
   NEXT

   RETURN nVrati


// ---------------------------------------------------
// sredi kodove u matrici za prikaz na izvjestajim
// ---------------------------------------------------
STATIC FUNCTION sredi_crtice( arr, tip )

   LOCAL nI
   LOCAL _konv := fetch_metric( "proiz_fin_konverzija", my_user(), "N" )

#ifdef __PLATFORM__WINDOWS

   FOR nI := 1 TO Len( arr )
      IF _konv == "D"
         arr[ nI ] := to_win1250_encoding( arr[ nI ] )
      ENDIF
   NEXT

#endif

   RETURN .T.



FUNCTION PrekSaEsc()

   Msg( "Priprema izvjestaja prekinuta tipkom <Esc>!", 2 )

   RETURN .F.


FUNCTION NaSljedStranu( lMozeL, lPrenos, cLM2, cOk, aPom, nKol, nStr, cLM, nDReda, nOdvoji, aPrSum, aKol, nSuma, cTek3, bZagl, cNaslov, aPrZag, cTek1, xTot )

   LOCAL i, xPom, j, cPom

   lMozeL := .F.
   IF !lPrenos
      i := 0; QOut( cLM2 + cOk[ 9 ] )
      AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, cOk[ 10 ], cOk[ 11 ] ) ) } )
      IF gPrinter != "R"
         QOut(); QOut(); xPom := Str( nStr, 3 ) + ". strana"
         QOut( cLM + PadC( xPom, nDReda - nOdvoji ) )
      ENDIF
   ELSE
      i := 0; QOut( cLM2 + cOk[ 6 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 10 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
      FOR j := 1 TO Len( aPrSum )
         i := 0; cPom := ""
         AEval( aKol, {| x| ++i, ;
            cPom += IF( x[ 3 ], Str( nSuma[ aPrSum[ j ] ][ i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !aPom[ i, 3 ] .AND. !aPom[ i + 1, 3 ], " ", cOk[ 5 ] ), cOk[ 12 ] ) }, ( aPrSum[ j ] -1 ) * nKol + 1, nKol )
         xPom := IF( j == Len( aPrSum ), cTek3 + Str( nStr, 3 ) + ":", Space( Len( cTek3 ) + 4 ) )
         QOut( cLM2 + cOk[ 12 ] + StrTran( cPom, Space( Len( xPom ) ), xPom, 1, 1 ) )
      NEXT
      i := 0; QOut( cLM2 + cOk[ 9 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 2 ], cOk[ 10 ] ), cOk[ 11 ] ) ) } )
   ENDIF
   gPFF()
   SetPRC( 0, 0 )
   IF !( bZagl == nil )
      Eval( bZagl )
   ENDIF
   IF cNaslov != nil
      QOut( cLM2 + cOk[ 1 ] + Replicate( cOk[ 2 ], nDReda - nOdvoji - 2 ) + cOk[ 4 ] )
      QOut( cLM2 + cOk[ 12 ] + Space( nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
      QOut( cLM2 + cOk[ 12 ] + PadC( AllTrim( cNaslov ), nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
      QOut( cLM2 + cOk[ 12 ] + Space( nDReda - nOdvoji - 2 ) + cOk[ 12 ] )
   ENDIF
   i := 0; QOut( cLM2 + IF( cNaslov != nil, cOk[ 6 ], cOk[ 1 ] ) )
   AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, cOk[ 3 ], IF( cNaslov != nil, cOk[ 8 ], cOk[ 4 ] ) ) ) } )
   FOR j := 1 TO Len( aPrZag )
      i := 0; QOut( cLM2 + cOk[ 12 ] )
      AEval( aKol, {| x| ++i, QQOut( PadC( x[ 1 ], x[ 5 ] ) + IF( i < nKol, cOk[ 5 ], cOk[ 12 ] ) ) }, ( aPrZag[ j ] -1 ) * nKol + 1, nKol )
   NEXT
   IF !lPrenos
      i := 0; QOut( cLM2 + cOk[ 6 ] )
      AEval( aPom, {| x| ++i, QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, cOk[ 7 ], cOk[ 8 ] ) ) } )
   ELSE
      i := 0; QOut( cLM2 + cOk[ 6 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], cOk[ 10 ], cOk[ 7 ] ), cOk[ 8 ] ) ) } )
      FOR j := 1 TO Len( aPrSum )
         i := 0; cPom := ""
         AEval( aKol, {| x| ++i, ;
            cPom += IF( x[ 3 ], Str( nSuma[ aPrSum[ j ] ][ i ], x[ 5 ], x[ 6 ] ), Space( x[ 5 ] ) ) + IF( i < nKol, IF( !aPom[ i, 3 ] .AND. !aPom[ i + 1, 3 ], " ", cOk[ 5 ] ), cOk[ 12 ] ) }, ( aPrSum[ j ] -1 ) * nKol + 1, nKol )
         xPom := IF( j == Len( aPrSum ), cTek1 + Str( nStr, 3 ) + ":", Space( Len( cTek1 ) + 4 ) )
         QOut( cLM2 + cOk[ 12 ] + StrTran( cPom, Space( Len( xPom ) ), xPom, 1, 1 ) )
      NEXT
      i := 0; QOut( cLM2 + cOk[ 6 ] )
      AEval( aPom, {| x| ++i, ;
         QQOut( Replicate( cOk[ 2 ], x[ 2 ] ) + IF( i < nKol, IF( !x[ 3 ] .AND. !aPom[ i + 1, 3 ], IF( xTot[ 1 ], cOk[ 2 ], cOk[ 3 ] ), cOk[ 7 ] ), cOk[ 8 ] ) ) } )
   ENDIF
   ++nStr

   RETURN


STATIC FUNCTION StStavku( aKol, xPom, i, nKol, cOk )

   // {
   IF xPom == nil
      QQOut( Space( aKol[ i, 5 ] ) )
   ELSEIF aKol[ i, 4 ] = "N"
      IF ValType( xPom ) != "N" .OR. Round( xPom, aKol[ i, 6 ] ) == 0 .AND. Right( aKol[ i, 4 ], 1 ) == "-"
         QQOut( Space( aKol[ i, 5 ] ) )
      ELSE
         IF gbFIznos != nil
            QQOut( Eval( gbFIznos, ;
               xPom, ;
               aKol[ i, 5 ], ;
               aKol[ i, 6 ] );
               )
         ELSE
            QQOut( Str( xPom, aKol[ i, 5 ], aKol[ i, 6 ] ) )
         ENDIF
      ENDIF
   ELSEIF aKol[ i, 4 ] == "C"
      QQOut( PadR( xPom, aKol[ i, 5 ] ) )
   ELSEIF aKol[ i, 4 ] == "D"
      QQOut( PadC( DToC( xPom ), aKol[ i, 5 ] ) )
   ENDIF
   QQOut( IF( i < nKol, cOk[ 5 ], cOk[ 12 ] ) )

   RETURN .T.


FUNCTION DajRed( tekst, kljuc )

   LOCAL cVrati := "", nPom := 0, nPoc := 0

   nPom := At( kljuc, tekst )
   nPoc := RAt( NRED_DOS, Left( tekst, nPom ) )
   nKraj := At(  NRED_DOS, SubStr( tekst, nPom ) )
   nPoc := IF( nPoc == 0, 1, nPoc + 2 )
   nKraj := IF( nKraj == 0, Len( tekst ), nPom - 1 + nKraj + 1 )
   cVrati := SubStr( tekst, nPoc, nKraj - nPoc + 1 )

   RETURN cVrati


FUNCTION WhileEvent( nValue, nCnt )
   RETURN .T.
