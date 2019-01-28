/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// ----------------------------------
// fix brnal
// ----------------------------------
FUNCTION fin_fix_broj_naloga( cBrNal )

   IF Right( AllTrim( cBrNal ), 1 ) == "*"
      cBrNal := StrTran( cBrNal, "*", "" )
      cBrNal := PadL( AllTrim( cBrNal ), 8 )
   ELSEIF Left( AllTrim( cBrNal ), 1 ) == "*"
      cBrNal := StrTran( cBrNal, "*", "" )
      cBrNal := PadR( AllTrim( cBrNal ), 8 )
   ELSE
      IF !Empty( AllTrim( cBrNal ) ) .AND. Len( AllTrim( cBrNal ) ) < 8
         cBrNal := PadL( AllTrim( cBrNal ), 8, "0" )
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION Izvj0()

   RETURN fin_izvjestaji()


FUNCTION Preknjizenje()

   RETURN fin_preknjizenje_konta()


// ------------------------------------------------------
// stampa ostatka opisa
// ------------------------------------------------------
FUNCTION fin_print_ostatak_opisa( cO, nCO, bUslov, nSir )

   IF nSir == NIL
      nSir := 20
   ENDIF

   DO WHILE Len( cO ) > nSir
      IF bUslov != NIL
         Eval( bUslov )
      ENDIF
      cO := SubStr( cO, nSir + 1 )
      IF !Empty( PadR( cO, nSir ) )
         @ PRow() + 1, nCO SAY PadR( cO, nSir )
      ENDIF
   ENDDO

   RETURN .T.


// -----------------------------------------------
// ispis gresaka nakon provjere
// -----------------------------------------------
STATIC FUNCTION _ispisi_greske( a_error )

   LOCAL nI

   IF Len( a_error ) == 0 .OR. a_error == NIL
      RETURN .T.
   ENDIF

   IF !start_print()
      RETURN .F.
   ENDIF

   ?
   ? "Pregled ispravnosti podataka:"
   ? "============================="
   ?
   ? "Potrebno odraditi korekciju sljedecih naloga:"
   ? "---------------------------------------------"

   FOR nI := 1 TO Len( a_error )

      ? PadL( "tabela: " + a_error[ nI, 1 ], 15 ) + ", " + a_error[ nI, 2 ]

   NEXT

   ?
   ? "NAPOMENA:"
   ? "========="
   ? "Naloge je potrebno vratiti u pripremu, provjeriti njihovu ispravnost"
   ? "sa papirnim kopijama te zatim ponovo azurirati."

   FF
   end_print()

   RETURN .T.


FUNCTION fin_storno_naloga()

   RETURN fin_povrat_naloga( .T. )


// ---------------------------------------------
// vraca unos granicnog datuma za report
// ---------------------------------------------
STATIC FUNCTION _g_gr_date()

   LOCAL dDate := Date()
   LOCAL GetList := {}

   Box(, 1, 45 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi granicni datum" GET dDate
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN NIL
   ENDIF

   RETURN dDate


FUNCTION BBMnoziSaK( cTip )

   LOCAL nArr := Select()

   IF cTip == valuta_domaca_skraceni_naziv() .AND. my_get_from_ini( "FIN", "BrutoBilansUDrugojValuti", "N", KUMPATH ) == "D"
      Box(, 5, 70 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Pomocna valuta      " GET cBBV PICT "@!" VALID ImaUSifVal( cBBV )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Omjer pomocna/domaca" GET nBBK WHEN {|| nBBK := OmjerVal2( cBBV, cTip ), .T. } PICT "999999999.999999999"
      READ
      BoxC()
   ELSE
      cBBV := cTip
      nBBK := 1
   ENDIF

   SELECT ( nArr )

   RETURN
