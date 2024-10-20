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

#include "f18.ch"

FUNCTION MnuGenDok()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. generacija dokumenta početnog stanja                          " )
   AAdd( _opcexe, {|| fin_pocetno_stanje_sql() } )
/*
   AAdd( _opc, "2. generacija dokumenta početnog stanja (stara opcija/legacy)" )
   AAdd( _opcexe, {|| GenPocStanja() } )
*/
   AAdd( _opc, "S. generisanje storna naloga " )
   AAdd( _opcexe, {|| fin_storno_naloga() } )

   f18_menu( "gdk", .F., _izbor, _opc, _opcexe )

   RETURN .T.
