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



// -----------------------------------------------
// vraca tip algoritma iz sifrarnika poreza
// -----------------------------------------------
FUNCTION get_algoritam()

   LOCAL xRet := ""
   LOCAL nTArea := Select()

   select_o_por()

   IF por->( FieldPos( "ALGORITAM" ) ) <> 0
      xRet := field->algoritam
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// -----------------------------------------------
// vraca prirodu obracuna poreza
// -----------------------------------------------
FUNCTION get_pr_obracuna()

   LOCAL xRet := " "
   LOCAL nTArea := Select()

   select_o_por()

   IF por->( FieldPos( "POR_TIP" ) ) <> 0
      xRet := field->por_tip
   ENDIF

   SELECT ( nTArea )

   RETURN xRet


// -------------------------------------------
// obracun poreza
// cId - porez id
// nOsnNeto - osnovica neto
// nOsnOstalo - osnovica ostala primanja
// -------------------------------------------
FUNCTION obr_por( cId, nOsnNeto, nOsnOstalo )

   LOCAL aPor := {}
   LOCAL aPorTek := {}
   LOCAL cAlg := ""
   LOCAL cPrObr := ""
   LOCAL nPorTot := 0
   LOCAL nIznos := 0
   LOCAL i

   // uzmi koji je algoritam
   cAlg := get_algoritam()
   cPrObr := get_pr_obracuna()

   IF cPrObr == "N" .OR. cPrObr == " " .OR. cPrObr == "B"

      // osnovica je neto
      nIznos := nOsnNeto

   ELSEIF cPrObr == "2"

      // osnovica je ostala primanja
      nIznos := nOsnOstalo

   ELSEIF cPrObr == "P"

      // osnovica je neto + ostala primanja
      nIznos := nOsnNeto + nOsnOstalo

   ENDIF

   select_o_por()

   IF cAlg == "S"
      // stepenasti obracun
      aPortek := _get_portek( 2 )
      aPor := obr_por_st( aPorTek, nIznos )

   ELSE
      // standardni obracun
      aPorTek := _get_portek( 1 )
      aPor := obr_por_os( aPorTek, nIznos )

   ENDIF

   RETURN aPor

// ---------------------------------------------
// ispis poreza
// lWOpis - bez opisa id, naz
// ---------------------------------------------
FUNCTION isp_por( aPor, cPorType, cMargina, lIspis, lWOpis )

   LOCAL nRet := 0

   IF lIspis == nil
      lIspis := .T.
   ENDIF

   IF lWOpis == nil
      lWOpis := .F.
   ENDIF

   IF cPorType == "S"
      nRet := isp_por_st( aPor, cMargina, lIspis )
   ELSE
      nRet := isp_por_os( aPor, cMargina, lIspis, lWOpis )
   ENDIF

   RETURN nRet

// -----------------------------------------
// ispis poreza, osnovni obracun
// -----------------------------------------
STATIC FUNCTION isp_por_os( aPor, cMargina, lIspis, lWOpis )

   LOCAL nTotal := 0
   LOCAL i := 1

   IF lIspis == .T.

      ? cMargina

      IF lWOpis == .F.
         ?? aPor[ i, 1 ], "-", aPor[ i, 2 ]
         @ PRow(), PCol() + 1 SAY aPor[ i, 3 ] PICT "99.99%"
         nC1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY aPor[ i, 5 ] PICT gPici
         @ PRow(), PCol() + 1 SAY aPor[ i, 4 ] PICT gPici
      ELSE
         cTmp := aPor[ i, 2 ] + " " + ;
            AllTrim( Str( aPor[ i, 5 ] ) ) + ;
            " * " + AllTrim( Str( aPor[ i, 3 ], 2 ) ) + "%"
         @ PRow(), PCol() + 1 SAY Space( 10 ) + cTmp
      ENDIF
   ENDIF

   nTotal += aPor[ i, 4 ]

   IF nTotal < 0
      nTotal := 0
   ENDIF

   RETURN nTotal


// ------------------------------------
// ispis poreza, stepenasti obracun
// ------------------------------------
STATIC FUNCTION isp_por_st( aPor, cMargina, lIspis )

   LOCAL i
   LOCAL nTotal := 0
   LOCAL cPom := ""

   IF Len( aPor ) == 0
      RETURN 0
   ENDIF

   IF lIspis == .T.

      ? cMargina + aPor[ 1, 1 ] + " - " + aPor[ 1, 2 ]
      ?? "( Obracun stepen.poreza )"
      ? cMargina + Replicate( "-", 60 )

   ENDIF

   FOR i := 1 TO Len( aPor )

      IF lIspis == .T.

         nRazlika := aPor[ i, 3 ] - aPor[ i, 4 ]

         ? cMargina + "("

         @ PRow(), PCol() + 1 SAY aPor[ i, 3 ] PICT "9999.99"
         @ PRow(), PCol() + 1 SAY " - "
         @ PRow(), PCol() + 1 SAY aPor[ i, 4 ] PICT "9999.99"
         @ PRow(), PCol() + 1 SAY ") = "
         @ PRow(), PCol() + 1 SAY nRazlika PICT "9999.99"
         @ PRow(), PCol() + 1 SAY " * "
         @ PRow(), PCol() + 1 SAY aPor[ i, 5 ] PICT "99.99%"
         @ PRow(), PCol() + 1 SAY " ="
         @ PRow(), PCol() + 1 SAY aPor[ i, 6 ] PICT gPici
      ENDIF

      nTotal += aPor[ i, 6 ]

   NEXT


   IF lIspis == .T. .AND. Round( nTotal, 2 ) <> 0

      ? cMargina + Replicate( "-", 60 )
      cPom := "Ukupno poreske obaveze:"
      ? cMargina + cPom

      @ PRow(), PCol() + ( 60 - Len( cPom ) - Len( gPici ) ) SAY nTotal PICT gPici
      ? cMargina + Replicate( "-", 60 )

   ENDIF

   RETURN nTotal



// ---------------------------------------------------
// obracun standardni poreza
// ---------------------------------------------------
STATIC FUNCTION obr_por_os( aPorTek, nIznos )

   LOCAL aPor := {}
   LOCAL nPorIznos
   LOCAL nDLimit := 0
   LOCAL nPor := 0
   LOCAL i := 1

   nDLimit := aPorTek[ i, 4 ]
   nPor := aPorTek[ i, 3 ]
   nOsnovica := Max( nIznos, PAROBR->prosld * gPDLimit / 100 )

   // nPorIznos := MAX( nDLimit, ROUND( nPor/100 * MAX( nIznos, PAROBR->PROSLD * gPDLIMIT / 100), gZaok2 ))

   nPorIznos := nIznos * nPor / 100
   nPorIznos := Round( nPorIznos, 2 )

   AAdd( aPor, { aPorTek[ i, 1 ], aPorTek[ i, 2 ], ;
      nPor, nPorIznos, nOsnovica } )

   RETURN aPor



// ------------------------------------------------
// obracunaj porez stepenasti
// aPorTek - matrica sa poreznim stopama i limitima
// nIznos - obracunska osnovica
// ------------------------------------------------
STATIC FUNCTION obr_por_st( aPorTek, nIznos )

   LOCAL aPor := {}
   LOCAL i
   LOCAL nDLimit := 0
   LOCAL nGLimit := 0
   LOCAL nStopa := 0
   LOCAL nPom

   FOR i := 1 TO Len( aPorTek )

      nDLimit := aPorTek[ i, 4 ]
      nGLimit := aPorTek[ i, 5 ]

      nStopa := aPorTek[ i, 3 ]

      cPorSifra := aPorTek[ i, 1 ]
      cPorNaz := aPorTek[ i, 2 ]

      IF i == 1
         IF nIznos < nDLimit
            EXIT
         ENDIF
      ENDIF

      IF ( nIznos > nDLimit .AND. nIznos < nGLimit )

         nPom := nIznos - nDLimit
         nPorIznos := nPom * ( nStopa / 100 )

         AAdd( aPor, { cPorSifra, cPorNaz, ;
            nIznos, nDLimit, nStopa, nPorIznos } )

         EXIT

      ELSE
         nPom := nGLimit - nDLimit
         nPorIznos := nPom * ( nStopa / 100 )

         AAdd( aPor, { cPorSifra, cPorNaz, ;
            nGLimit, nDLimit, nStopa, nPorIznos } )

      ENDIF

   NEXT

   RETURN aPor



// -------------------------------------------
// vraca matricu sa porezima i stopama
//
// aPor := { nStopa, nLimitMin, nLimitMax }
// nvar - varijanta 1 - standardna
// varijanta 2 - stepenasti
// -------------------------------------------
STATIC FUNCTION _get_portek( nVar )

   LOCAL aPor := {}
   LOCAL i
   LOCAL nStopa
   LOCAL nLimit
   LOCAL nLimitPr
   LOCAL cPom

   IF nVar == 2
      FOR i := 1 TO 5

         cPom := "S_STO_" + AllTrim( Str( i ) )
         nStopa := &cPom

         cPom := "S_IZN_" + AllTrim( Str( i ) )
         nLimit := &cPom

         IF nStopa <> 0

            // prethodna stopa
            cPom := "S_IZN_" + AllTrim( Str( i - 1 ) )
            nLimitPr := &cPom

            AAdd( aPor, { por->id, por->naz, nStopa, nLimitPr, nLimit } )
         ENDIF

      NEXT

   ELSE

      nStopa := field->iznos
      AAdd( aPor, { por->id, por->naz, nStopa, por->dlimit } )

   ENDIF

   RETURN aPor
