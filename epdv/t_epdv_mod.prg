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



CLASS TEpdvMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS



METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self



METHOD mMenu()

   my_close_all_dbf()

   ::programski_modul_osnovni_meni()

   RETURN NIL


METHOD programski_modul_osnovni_meni()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. KUF unos/ispravka           " )
   AAdd( aOpcExe, {|| epdv_edit_kuf() } )
   AAdd( aOpc, "2. KIF unos/ispravka" )
   AAdd( aOpcExe, {|| epdv_edit_kif() } )
   AAdd( aOpc, "3. generacija dokumenata" )
   AAdd( aOpcExe, {|| epdv_generisanje() } )
   AAdd( aOpc, "4. izvještaji" )
   AAdd( aOpcExe, {|| epdv_izvjestaji() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "S. šifarnici" )
   AAdd( aOpcExe, {|| epdv_sifarnici() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "9. administracija baze podataka" )
   AAdd( aOpcExe, {|| epdv_admin_menu() } )
   AAdd( aOpc, "------------------------------------" )
   AAdd( aOpcExe, {|| NIL } )
   AAdd( aOpc, "X. parametri" )
   AAdd( aOpcExe, {|| epdv_parametri() } )


   f18_menu( "gpdv", .T., nIzbor, aOpc, aOpcExe )

   RETURN .T.




METHOD set_module_gvars()

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}
   PUBLIC gPicVrijednost := "9999999.99"
   PUBLIC gL_kto_dob := PadR( "541;", 100 )
   PUBLIC gL_kto_kup := PadR( "211;", 100 )
   PUBLIC gKt_updv := PadR( "260;", 100 )
   PUBLIC gKt_ipdv := PadR( "560;", 100 )

   epdv_update_sifre_params()

   o_params()
   Rpar( "p1", @gPicVrijednost )

   SELECT ( F_PARAMS )
   USE


   gModul := "EPDV"

   RETURN .T.
