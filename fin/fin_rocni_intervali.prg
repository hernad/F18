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

FUNCTION fin_rocni_intervali_meni()

   LOCAL aOpc := {}
   LOCAL aOpcexe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. specifikacija dugovanja partnera po ročnim intervalima " )
   AAdd( aOpcexe, {|| specif_dugovanja_po_rocnim_intervalima() } )

   AAdd( aOpc, "2. kartica dugovanja kupaca valuta/van valute                  " )
   AAdd( aOpcexe, {|| fin_spec_otv_stavke_rocni_intervali( .T. ) } )
   AAdd( aOpc, "3. specifikacija dugovanja kupaca valuta/van valute" )
   AAdd( aOpcexe, {|| fin_spec_otv_stavke_rocni_intervali( .F. ) } )

   f18_menu( "spri", .F., nIzbor, aOpc, aOpcexe )

   RETURN .T.


// -------------------------------
// ispis rocnosti
// -------------------------------
FUNCTION IspisRoc2( i )

   LOCAL cVrati

   IF i == 1
      cVrati := " DO " + Str( nDoDana1, 3 )
   ELSEIF i == 2
      cVrati := " DO " + Str( nDoDana2, 3 )
   ELSEIF i == 3
      cVrati := " DO " + Str( nDoDana3, 3 )
   ELSEIF i == 4
      cVrati := " DO " + Str( nDoDana4, 3 )
   ELSE
      cVrati := " PR." + Str( nDoDana4, 3 )
   ENDIF

   RETURN cVrati + " DANA"


// -------------------------------------
// ispis rocnosti
// -------------------------------------
FUNCTION RRocnost()

   LOCAL nDana := Abs( iif( datval_prazan(), datdok, datval ) - dNaDan ), nVrati

   IF nDana <= nDoDana1
      nVrati := 1
   ELSEIF nDana <= nDoDana2
      nVrati := 2
   ELSEIF nDana <= nDoDana3
      nVrati := 3
   ELSEIF nDana <= nDoDana4
      nVrati := 4
   ELSE
      nVrati := 5
   ENDIF

   RETURN nVrati

FUNCTION IspisRocnosti()

   LOCAL cRocnost := Rocnost(), cVrati

   IF cRocnost == "999"
      cVrati := " PREKO " + Str( nDoDana4, 3 ) + " DANA"
   ELSE
      cVrati := " DO " + cRocnost + " DANA"
   ENDIF

   RETURN cVrati



FUNCTION Rocnost()

   LOCAL nDana := Abs( iif( datval_prazan(), datdok, datval ) - dNaDan ), cVrati

   IF nDana <= nDoDana1
      cVrati := Str( nDoDana1, 3 )
   ELSEIF nDana <= nDoDana2
      cVrati := Str( nDoDana2, 3 )
   ELSEIF nDana <= nDoDana3
      cVrati := Str( nDoDana3, 3 )
   ELSEIF nDana <= nDoDana4
      cVrati := Str( nDoDana4, 3 )
   ELSE
      cVrati := "999"
   ENDIF

   RETURN cVrati
