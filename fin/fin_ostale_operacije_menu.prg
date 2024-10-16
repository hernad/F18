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

FUNCTION fin_ostale_operacije_meni()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. povrat dokumenta u pripremu                " )
   AAdd( _opcexe, {|| fin_povrat_naloga() } )
   AAdd( _opc, "2. preknjiženje     " )
   AAdd( _opcexe, {|| Preknjizenje() } )

/*
   AAdd( _opc, "3. prebacivanje kartica" )
   AAdd( _opcexe, {|| Prebfin_kartica() } )
*/

   AAdd( _opc, "4. otvorene stavke" )
   AAdd( _opcexe, {|| fin_otvorene_stavke_meni() } )

   AAdd( _opc, "5. obrada kamata " )
   AAdd( _opcexe, {|| fin_kamate_menu() } )

   f18_menu( "oop", .F., _izbor, _opc, _opcexe )

   RETURN .T.
