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


/* pos_get_popust_sve_varijante(aRabat, nCijena)
 *     Puni matricu aRabat popustima, u zavisnosti od varijante
 *   param: aRabat - matrica rabata: type array
  {idroba, nPopVar1, nPopVar2, nPopVar3, nPopVar4, nPopVar5, nPopVar6}
 *   param: nCijena - cijena artikla

FUNCTION pos_get_popust_sve_varijante( aRabat, nCijena )

   // prodji kroz svaku varijantu popusta i napuni matricu aRabat{}

   // 1. varijanta
   // Popust zadavanjem nove cijene
   GetPopZadavanjemNoveCijene( aRabat, nCijena )

   // 2. varijanta
   // Generalni popust za sve artikle
   GetPopGeneral( aRabat, nCijena )

   // 3. varijanta
   // Popust na osnovu polja "roba->N2"
   GetPopFromN2( aRabat, nCijena )

   // 4. varijanta
   // Popust preko odredjenog iznosa
   GetPopPrekoOdrIznosa( aRabat, nCijena )


   // 6. varijanta
   // Popust zadavanjem procenta
   pos_popust_varijanta_procenat( aRabat, nCijena )

   RETURN .T.
*/


/* GetPopZadavanjemNoveCijene(aRabat, nCijena)
 *     Popust zadavanjem nove cijene
 *   param: aRabat
 *   param: nCijena

FUNCTION GetPopZadavanjemNoveCijene( aRabat, nCijena )


   LOCAL nNovaCijena := 0

   IF ( gPopZCj == "D" .AND. roba->tip <> "T" )
      // u zavisnosti od set-a cijena koji se koristi
      // &("roba->cijena" + gIdCijena) == roba->cijena1
      nNovaCijena := Round( pos_get_mpc() - nCijena, gPopDec )
      AddToArrRabat( aRabat, roba->id, nNovaCijena )
   ENDIF

   RETURN .T.
*/

/* GetPopGeneral(aRabat, nCijena)
 *     Generalni popust za sve artikle
 *   param: aRabat
 *   param: nCijena

FUNCTION GetPopGeneral( aRabat, nCijena )

   LOCAL nNovaCijena := 0

   IF ( !Empty( gPopust ) .AND. gPopust <> 99 .AND. gPopust <> 0 )
      IF Pitanje(, "Generalni popust " + AllTrim( Str( gPopust ) ) + "% :: uracunati ?","D" ) == "D"
         nNovaCijena := Round( nCijena * ( gPopust ) / 100, gPopDec )
         AddToArrRabat( aRabat, roba->id, nil, nNovaCijena )
      ENDIF
   ENDIF

   RETURN
*/


/* GetPopFromN2(aRabat, nCijena)
 *     Popust na osnovu polja "roba->N2", gPopust=99 - gledaj sifrarnik
 *   param: aRabat
 *   param: nCijena

FUNCTION GetPopFromN2( aRabat, nCijena )


   LOCAL nNovaCijena := 0

   IF ( !Empty( gPopust ) .AND. gPopust == 99 )
      IF Pitanje(, "Uracunati popust od " + AllTrim( Str( roba->n2 ) ) + "% ?","D" ) == "D"
         nNovaCijena := Round( nCijena * ( roba->n2 ) / 100, gPopDec )
         AddToArrRabat( aRabat, roba->id, nil, nil, nNovaCijena )
      ENDIF
   ENDIF

   RETURN
*/


/* GetPopPrekoOdrIznosa(aRabat, nCijena)
 *     Varijanta popusta preko odredjenog iznosa
 *   param: aRabat
 *   param: nCijena

FUNCTION GetPopPrekoOdrIznosa( aRabat, nCijena )

   LOCAL nNovaCijena := 0

   IF VarPopPrekoOdrIzn() .AND. ispopprekoodrizn( nCijena )
      nNovaCijena := Round( nCijena * gPopIznP / 100, gPopDec )
      AddToArrRabat( aRabat, roba->id, nil, nil, nil, nNovaCijena )
   ENDIF

   RETURN
*/


/*
FUNCTION pos_popust_varijanta_procenat( aRabat, nCijena )

   LOCAL nNovaCijena := 0

   IF gPopProc == "D"
      nPopProc := pos_get_popust_procenat()
      nNovaCijena = Round( nCijena * nPopProc / 100, gPopDec )
      AddToArrRabat( aRabat, roba->id, nil, nil, nil, nil, nil, nNovaCijena )
   ENDIF

   RETURN .T.
*/


/* AddToArrRabat(aRabat, cIdRoba, nPopVar1, nPopVar2, nPopVar3, nPopVar4, nPopVar5, nPopVar6)
 *     Puni matricu aRabat{} vrijednostima popusta nPopVarN
 *   param: aRabat - matrica
 *   param: cIdRoba - id artikla
 *   param: nPopVar1 - iznos popusta zadavanja nove cijene
 *   param: nPopVar2 - iznos generalnog popusta
 *   param: nPopVar3 - iznos popusta na osnovu polja N2
 *   param: nPopVar4 - iznos popusta preko odredjenog iznosa
 *   param: nPopVar5 - iznos popusta za clanove
 *   param: nPopVar6 - iznos popusta zadavanjem procenta

FUNCTION AddToArrRabat( aRabat, cIdRoba, nPopVar1, nPopVar2, nPopVar3, nPopVar4, nPopVar5, nPopVar6 )


   // ako je neki od parametara nPopVar(N)==NIL setuj na 0
   IF nPopVar1 == NIL
      nPopVar1 := 0
   ENDIF
   IF nPopVar2 == NIL
      nPopVar2 := 0
   ENDIF
   IF nPopVar3 == NIL
      nPopVar3 := 0
   ENDIF
   IF nPopVar4 == NIL
      nPopVar4 := 0
   ENDIF
   IF nPopVar5 == NIL
      nPopVar5 := 0
   ENDIF
   IF nPopVar6 == NIL
      nPopVar6 := 0
   ENDIF

   IF ( Len( aRabat ) > 0 )
      // posto vec nesto ima u matrici prvo pretrazi...
      nPosition := AScan( aRabat, {| aValue| aValue[ 1 ] == cIdRoba } )
      IF nPosition <> 0
         IF aRabat[ nPosition, 2 ] == 0
            aRabat[ nPosition, 2 ] := nPopVar1
         ENDIF
         IF aRabat[ nPosition, 3 ] == 0
            aRabat[ nPosition, 3 ] := nPopVar2
         ENDIF
         IF aRabat[ nPosition, 4 ] == 0
            aRabat[ nPosition, 4 ] := nPopVar3
         ENDIF
         IF aRabat[ nPosition, 5 ] == 0
            aRabat[ nPosition, 5 ] := nPopVar4
         ENDIF
         IF aRabat[ nPosition, 6 ] == 0
            aRabat[ nPosition, 6 ] := nPopVar5
         ENDIF
         IF aRabat[ nPosition, 7 ] == 0
            aRabat[ nPosition, 7 ] := nPopVar6
         ENDIF
      ELSE
         AAdd( aRabat, { cIdRoba, nPopVar1, nPopVar2, nPopVar3, nPopVar4, nPopVar5, nPopVar6 } )
      ENDIF
   ELSE
      AAdd( aRabat, { cIdRoba, nPopVar1, nPopVar2, nPopVar3, nPopVar4, nPopVar5, nPopVar6 } )
   ENDIF

   RETURN
*/


/* RptArrRabat(aRabat)
 *     Stampa matricu aRabat, sluzi samo za testiranje!!!
 *   param: aRabat

FUNCTION RptArrRabat( aRabat )

   START PRINT CRET

   ? "Test :: matrica rabata"
   ? "-------------------------------------------------"
   ?

   FOR i := 1 TO Len( aRabat )
      ? aRabat[ i, 1 ], aRabat[ i, 2 ], aRabat[ i, 3 ], ;
         aRabat[ i, 4 ], aRabat[ i, 5 ], aRabat[ i, 6 ], aRabat[ i, 7 ]
   NEXT
   ?
   ?

   ENDPRINT

   RETURN

*/


/* CalcArrRabat(aRabat, lPopVar1, lPopVar2, lPopVar3, lPopVar4, lPopVar5, lPopVar6)
 *     Kalkulise kompletan iznos rabata za sve stavke
 *   param: aRabat - matrica rabata
 *   param: lPopVar1 - .t. racunaj 1 varijantu
 *   param: lPopVar2 - .t. racunaj 2 varijantu
 *   param: lPopVar3 - .t. racunaj 3 varijantu
 *   param: lPopVar4 - .t. racunaj 4 varijantu
 *   param: lPopVar5 - .t. racunaj 5 varijantu
 *   param: lPopVar6 - .t. racunaj 6 varijantu

FUNCTION CalcArrRabat( aRabat, lPopVar1, lPopVar2, lPopVar3, lPopVar4, lPopVar5, lPopVar6 )


   LOCAL nIznos := 0


   FOR i := 1 TO Len( aRabat )
      IF lPopVar1
         nIznos += aRabat[ i, 2 ]
      ENDIF
      IF lPopVar2
         nIznos += aRabat[ i, 3 ]
      ENDIF
      IF lPopVar3
         nIznos += aRabat[ i, 4 ]
      ENDIF
      IF lPopVar4
         nIznos += aRabat[ i, 5 ]
      ENDIF
      IF lPopVar5
         nIznos += aRabat[ i, 6 ]
      ENDIF
      IF lPopVar6
         nIznos += aRabat[ i, 7 ]
      ENDIF
   NEXT

   RETURN nIznos
*/


/* CalcRabatForArticle(aRabat, cIdRoba, lPopVar1, lPopVar2, lPopVar3, lPopVar4, lPopVar5, lPopVar6)
 *     Kalkulise rabat za samo jedan artikal
 *   param: aRabat
 *   param: cIdRoba
 *   param: lPopVar1
 *   param: lPopVar2
 *   param: lPopVar3
 *   param: lPopVar4
 *   param: lPopVar5
 *   param: lPopVar6

FUNCTION CalcRabatForArticle( aRabat, cIdRoba, lPopVar1, lPopVar2, lPopVar3, lPopVar4, lPopVar5, lPopVar6 )


   LOCAL nIznos := 0
   LOCAL nPosition := 0

   nPosition := AScan( aRabat, {| Value| Value[ 1 ] == cIdRoba } )

   IF nPosition <> 0
      IF lPopVar1
         nIznos := aRabat[ nPosition, 2 ]
      ENDIF
      IF lPopVar2
         nIznos += aRabat[ nPosition, 3 ]
      ENDIF
      IF lPopVar3
         nIznos += aRabat[ nPosition, 4 ]
      ENDIF
      IF lPopVar4
         nIznos += aRabat[ nPosition, 5 ]
      ENDIF
      IF lPopVar5
         nIznos += aRabat[ nPosition, 6 ]
      ENDIF
      IF lPopVar6
         nIznos += aRabat[ nPosition, 7 ]
      ENDIF
   ENDIF

   RETURN nIznos
*/

//
// Provjerava da li je tacnan uslov za popust preko odredjenog iznosa
//

/*
FUNCTION IsPopPrekoOdrIzn( nTotal )

   LOCAL lReslut := .F.

   // iznos moze biti 100 i -100, ako je storno
   IF Abs( nTotal ) > gPopIzn
      lResult := .T.
   ELSE
      lResult := .F.
   ENDIF

   RETURN lResult

*/

/*
// Provjerava da li se uzima u obzir varijanta popusta preko odredjenog iznosa
FUNCTION VarPopPrekoOdrIzn()

   LOCAL _ok := .F.

   IF ( gPopIzn > 0 .AND. gPopIznP > 0 )
      _ok := .T.
   ELSE
      _ok := .F.
   ENDIF

   RETURN _ok

*/


/*
FUNCTION pos_get_popust_procenat()


   LOCAL GetList := {}
   LOCAL nPopProc := 0

   Box(, 1, 23 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Popust (%)" GET nPopProc PICT "999.99"
   READ
   BoxC()

   RETURN nPopProc
*/


/* ShowRabatOnForm(nx, ny)
 *     Prikazuje iznos rabata na formi unosa
 *   param: nx
 *   param: ny

FUNCTION ShowRabatOnForm( nx, ny )

   LOCAL nCijena := 0
   LOCAL nPopust := 0

   nCijena := _cijena
   nPopust := CalcRabatForArticle( aRabat, _idRoba, .T., .T., .T., .T., .T., .T. )
   _ncijena := nPopust

   IF ( nPopust <> 0 )
      @ nx, ny SAY "Popust :"
      @ nx, Col() + 1 SAY _nCijena PICT "99999.999"
      @ nx + 1, ny SAY  "Cij-Pop:"
      @ nx + 1, Col() + 1 SAY _Cijena - _nCijena PICT "99999.999"
   ELSE
      @ nx, ny SAY Space( 20 )
      @ nx + 1, ny SAY Space( 20 )
   ENDIF

   RETURN

*/



/* RecalcRabat
 *     Rekalkulise vrijednost rabata prije azuriranja i stampanja racuna. Ovo je neophodno radi varijante popusta preko odredjenog iznosa.


FUNCTION RecalcRabat( cIdVrsteP )

   LOCAL nNIznos := 0
   LOCAL nIznNar := 0
   LOCAL nPopust := 0

   IF cIdVrsteP == NIL
      cIdVrsteP := ""
   ENDIF

   // prvo vidi koliki je iznos racuna
   SELECT _pos_pripr
   GO TOP
   DO WHILE !Eof()
      _IdVrsteP := cIdVrsteP
      nIznNar += cijena * kolicina
      nPopust += ncijena * kolicina
      SKIP
   ENDDO

   GO TOP
   DO WHILE !Eof()
      IF VarPopPrekoOdrIzn()
         IF !IsPopPrekoOdrIzn( nIznNar - nPopust ) .OR. ( IsPopPrekoOdrIzn( nIznNar - nPopust ) .AND. cIdVrsteP <> "01" )
            IF Len( aRabat ) > 0
               nNIznos := CalcRabatForArticle( aRabat, idroba, .T., .T., .T., .F., .T., .T. )
            ELSE
               nNIznos := 0
            ENDIF
            Scatter()
            _ncijena := nNIznos
            Gather()
         ENDIF
         SKIP

      ELSE
         SKIP
         LOOP
      ENDIF
   ENDDO

   RETURN
*/


/* Scan_PriprForRabat(aRabat)
 *     Ako ima nezakljucenih racuna u _PRIPR napuni matricu aRabat
 *   param: aRabat - matrica rabata

FUNCTION Scan_PriprForRabat( aRabat )


   SELECT _pos_pripr
   IF ( RecCount() > 0 )
      DO WHILE !Eof()
         pos_get_popust_sve_varijante( aRabat, field->cijena )
         SKIP
      ENDDO

   ENDIF

   RETURN .T.

// -----------------------------------------
// vraca popust po vrsti placanja
// -----------------------------------------
FUNCTION get_vrpl_popust( cIdVrPlac, nPopust )

   LOCAL nTArea := Select()
   LOCAL cPom
   LOCAL nPos
   LOCAL cTmp
   LOCAL cPopust
   LOCAL i

   select_o_vrstep( cIdVrPlac )

   // naz #P#05#
   cPom := AllTrim( field->naz )
   nPos := At( "#P#", cPom )
   cPopust := ""

   IF nPos > 0

      FOR i := 1 TO Len( cPom )

         cTmp := SubStr( cPom, nPos + 2 + i, 1 )

         IF cTmp == "#"
            EXIT
         ENDIF

         cPopust += cTmp
      NEXT

      nPopust := Val( cPopust )

   ENDIF

   SELECT ( nTArea )

   RETURN
*/
