/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


FUNCTION send2comport( cStr )

   ? "dummy send2commport"

   RETURN

FUNCTION sql_azur()
   RETURN .T.

FUNCTION GathSQL()
   RETURN .T.

FUNCTION prnkod_on()
   RETURN

FUNCTION prnkod_off()
   RETURN

FUNCTION rloptlevel()
   RETURN 0

FUNCTION isRudnik()
   RETURN .F.

FUNCTION isKonsig()
   RETURN .F.

FUNCTION isStampa()
   RETURN .F.


FUNCTION PosTest()

   ? "Pos test (pos/main/2g/app.prg)"

   RETURN


FUNCTION replsql_dummy()
   RETURN


/* UpisiURF(cTekst,cFajl,lNoviRed,lNoviFajl)
 *     Upisi u report fajl
 *   param: cTekst    - tekst
 *   param: cFajl     - ime fajla
 *   param: lNoviRed  - da li prelaziti u novi red
 *   param: lNoviFajl - da li snimati u novi fajl
 */

FUNCTION UpisiURF( cTekst, cFajl, lNoviRed, lNoviFajl )

   StrFile( IF( lNoviRed, Chr( 13 ) + Chr( 10 ), "" ) + cTekst, cFajl, !lNoviFajl )

   RETURN

/* DiffMFV(cZn,cDiff)
 *     differences: memo vs field variable
 *   param: cZn
 *   param: cdiff
 */

FUNCTION DiffMFV( cZN, cDiff )

   LOCAL lVrati := .F.
   LOCAL i
   LOCAL aStruct

   IF cZn == NIL
      cZn := "_"
   ENDIF

   aStruct := dbStruct()

   FOR i := 1 TO Len( aStruct )
      cImeP := aStruct[ i, 1 ]
      IF !( cImeP == "BRISANO" )
         cVar := cZn + cImeP
         IF "U" $ Type( cVar )
            MsgBeep( "Greska:neuskladjene strukture baza!#" + ;
               "Pozovite servis bring.out !#" + ;
               "Funkcija: GATHER(), Alias: " + Alias() + ", Polje: " + cImeP )
         ELSE
            IF field->&cImeP <> &cVar
               lVrati := .T.
               cDiff += hb_eol() + "     "
               cDiff += cImeP + ": bilo=" + TRANS( field->&cImeP, "" ) + ", sada=" + TRANS( &cVar, "" )
            ENDIF
         ENDIF
      ENDIF
   NEXT

   RETURN lVrati


FUNCTION addoidfields()
   RETURN

FUNCTION OL_Yield()
   RETURN
