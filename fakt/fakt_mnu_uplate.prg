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
FUNCTION mnu_fakt_uplate()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. evidentiranje uplata                   " )
   AAdd( _opcexe, {|| fakt_uplate() } )
   AAdd( _opc, "2. lista salda kupaca" )


  // AAdd( _opcexe, {|| SaldaKupaca() } )
  // AAdd( _opc, "3. pocetno stanje za evidenciju uplata" )

   //AAdd( _opcexe, {|| GPSUplata() } )


   f18_menu( "upl", .F., _izbor, _opc, _opcexe )

   CLOSERET

   RETURN .F.

*/
