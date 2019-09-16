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

CLASS TFinMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS


METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self



METHOD mMenu()

   //auto_kzb()
   my_close_all_dbf()

   ::programski_modul_osnovni_meni()

   RETURN NIL


METHOD programski_modul_osnovni_meni()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
     LOCAL cSeparator := Replicate( "-", 50)


   AAdd( aOpc, "1. unos/ispravka dokumenta                         " )
   AAdd( aOpcExe, {|| fin_unos_naloga() } )
   AAdd( aOpc, "2. izvještaji" )
   AAdd( aOpcExe, {|| fin_izvjestaji() } )
   AAdd( aOpc, "3. pregled i kontrola dokumenata" )
   AAdd( aOpcExe, {|| fin_pregled_dokumenata_meni() } )
   AAdd( aOpc, "4. generacija dokumenata" )
   AAdd( aOpcExe, {|| MnuGenDok() } )
   AAdd( aOpc, "5. moduli - razmjena podataka" )
   AAdd( aOpcExe, {|| fin_razmjena_podataka_meni() } )
   AAdd( aOpc, "6. ostale operacije nad dokumentima" )
   AAdd( aOpcExe, {|| fin_ostale_operacije_meni() } )

   AAdd( aOpc, "O. otvorene stavke" )
   AAdd( aOpcExe, {|| fin_otvorene_stavke_meni() } )

   AAdd( aOpc, "R. udaljene lokacije - razmjena podataka " )
   AAdd( aOpcExe, {|| fin_udaljena_razmjena_podataka() } )
   AAdd( aOpc, cSeparator )
   AAdd( aOpcExe, {|| nil } )
   AAdd( aOpc, "S. matični podaci (šifarnici)" )
   AAdd( aOpcExe, {|| MnuSifrarnik() } )

   AAdd( aOpc, "A. kontrolni izvještaji" )
   AAdd( aOpcExe, {|| fin_kontrolni_izvjestaji_meni() } )

   AAdd( aOpc, cSeparator )
   AAdd( aOpcExe, {|| nil } )
   AAdd( aOpc, "K. kontrola zbira finansijskih transakcija" )
   AAdd( aOpcExe, {|| fin_kontrola_zbira_tabele_prometa( .T. ) } )
   AAdd( aOpc, "P. povrat dokumenta u pripremu" )
   AAdd( aOpcExe, {|| fin_povrat_naloga() } )


   AAdd( aOpc, cSeparator )
   AAdd( aOpcExe, {|| nil } )
   AAdd( aOpc, "X. parametri" )
   AAdd( aOpcExe, {|| mnu_fin_params() } )

   f18_menu( "gfin", .T., nIzbor, aOpc, aOpcExe )

   RETURN .T.



METHOD set_module_gvars()


   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   PUBLIC aRuleCols := get_rule_field_cols_fin()
   PUBLIC bRuleBlock := get_rule_field_block_fin()

   ::super:setTGVars()

   fin_read_params()


   gModul := "FIN"

   fin_params( .T. )

   info_bar( "FIN", "params in cache: " + Alltrim( Str( params_in_cache() ) ) )
   RETURN .T.
