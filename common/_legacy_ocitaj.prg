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


FUNCTION ocitaj_izbaci( nObl, xKljuc, nPbr, lInd )

   // vraca trazeno polje (nPbr+1) iz
   // sifrarn.za zadanu vrijednost indeksa 'xKljuc'
   // Primjer : xRez:=ocitaj_izbaci(F_VALUTE,"D","naz2")

   LOCAL cPom := ""
   LOCAL xPom
   LOCAL xVrati

   IF lInd == NIL; lInd := .F. ; ENDIF
   //PRIVATE cPom := ""
   IF ValType( nPbr ) == "C"
      cPom := nPbr  // za makro evaluaciju mora biti priv varijabla
   ENDIF

   PushWA()
   SELECT ( nObl )
   SEEK xKljuc

   xPom := IIF( ValType( nPbr ) == "C", &cPom, FieldGet( 1 + nPbr ) )
   IF lInd
      xVrati := iif( Found(), xPom, Blank( xPom ) )
   ELSE
      xVrati := iif( Found(), xPom, Space( LENx( xPom ) ) )
   ENDIF
   PopWA()

   RETURN xVrati
