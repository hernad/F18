/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR PicDEM, picBHD, gPicBHD

FUNCTION fin_kartice_menu()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   PRIVATE picDEM := FormPicL( pic_iznos_eur(), 12 )
   PRIVATE picBHD := FormPicL( gPicBHD, 16 )

   AAdd( _opc, "1. subanalitička kartica                         " )
   AAdd( _opcexe, {|| fin_suban_kartica( .F. ) } )
   AAdd( _opc, "O. kartica otvorenih stavki" )
   AAdd( _opcexe, {|| fin_suban_kartica( .T. ) } )

   AAdd( _opc, "A. analitika" )
   AAdd( _opcexe, {|| fin_anal_kartica() } )
   AAdd( _opc, "S. sintetika" )
   AAdd( _opcexe, {|| fin_sint_kartica() } )
   AAdd( _opc, "M. sintetika - po mjesecima" )
   AAdd( _opcexe, {|| fin_sint_kart_po_mjesecima() } )

   f18_menu( "fin_kart", .F., _izbor, _opc, _opcexe )

   RETURN .T.
