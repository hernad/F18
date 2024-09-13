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


CLASS TRnalMod FROM TAppMod

   VAR oSqlLog
   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD mStartUp
   METHOD programski_modul_osnovni_meni

ENDCLASS


METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self




METHOD mMenu()

   my_close_all_dbf()

   select (F_DOCS)
   IF my_use ("docs")
      set order to tag "1"
      SELECT docs
      USE
   ELSE
      Alert( "ne postoji rnal_docs")
   ENDIF

   my_close_all_dbf()

   rnal_set_params()

   ::mStartUp()

   ::programski_modul_osnovni_meni()

   RETURN NIL


// ------------------------------------------
// startup metoda
// ------------------------------------------
METHOD mStartUp()

   gen_rnal_rules()

   RETURN NIL



METHOD programski_modul_osnovni_meni()

   PRIVATE Izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   AAdd( opc, "1. unos/dorada naloga za proizvodnju  " )
   AAdd( opcexe, {|| ed_document( .T. ) } )
   AAdd( opc, "2. lista otvorenih naloga " )
   AAdd( opcexe, {|| rnal_lista_dokumenata( 1 ) } )
   AAdd( opc, "3. lista zatvorenih naloga " )
   AAdd( opcexe, {|| rnal_lista_dokumenata( 2 ) } )
   AAdd( opc, "4. izvještaji " )
   AAdd( opcexe, {|| m_rpt() } )
   AAdd( opc, "D. direktna dorada naloga  " )
   AAdd( opcexe, {|| ddor_nal() } )
   AAdd( opc, "S. štampa ažuriranog naloga  " )
   AAdd( opcexe, {|| prn_nal() } )
   AAdd( opc, "T. unos/obrada statusa naloga  " )
   AAdd( opcexe, {|| rnal_pregled_statusa_operacija() } )
   AAdd( opc, "------------------------------------" )
   AAdd( opcexe, {|| nil } )
   AAdd( opc, "S. šifarnici" )
   AAdd( opcexe, {|| m_sif() } )
   AAdd( opc, "------------------------------------" )
   AAdd( opcexe, {|| nil } )
   AAdd( opc, "9. administracija" )
   AAdd( opcexe, {|| rnal_mnu_admin() } )
   AAdd( opc, "------------------------------------" )
   AAdd( opcexe, {|| nil } )
   AAdd( opc, "X. parametri" )
   AAdd( opcexe, {|| m_par() } )

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "grn", .T. )

   RETURN .T.



METHOD set_module_gvars()


   PUBLIC gPicVrijednost := "9999999.99"
   // rnal - specif params section
   // firma podaci
   PUBLIC gFNaziv := Space( 40 )
   PUBLIC gFAdresa := Space( 40 )
   PUBLIC gFIdBroj := Space( 13 )
   PUBLIC gFTelefon := Space( 40 )
   PUBLIC gFEmail := Space( 40 )
   PUBLIC gFBanka1 := Space( 50 )
   PUBLIC gFBanka2 := Space( 50 )
   PUBLIC gFBanka3 := Space( 50 )
   PUBLIC gFBanka4 := Space( 50 )
   PUBLIC gFBanka5 := Space( 50 )
   PUBLIC gFPrRed1 := Space( 50 )
   PUBLIC gFPrRed2 := Space( 50 )

   // izgled dokumenta
   PUBLIC gDl_margina := 5
   PUBLIC gDd_redovi := 11
   PUBLIC gDg_margina := 0

   // ostali parametri
   PUBLIC gFnd_reset := 0
   PUBLIC gMaxHeigh := 3600
   PUBLIC gMaxWidth := 3600
   PUBLIC gDefNVM := 560
   PUBLIC gDefCity := "Sarajevo"

   // export parametri
   PUBLIC gExpOutDir := PadR( my_home(), 300 )
   PUBLIC gExpAlwOvWrite := "N"
   PUBLIC gFaKumDir := Space( 300 )
   PUBLIC gFaPrivDir := Space( 300 )
   PUBLIC gPoKumDir := Space( 300 )
   PUBLIC gPoPrivDir := Space( 300 )
   PUBLIC gBrusenoStakloDodaj := 3

   // default joker glass type
   PUBLIC gDefGlType
   // default joker glass tick
   PUBLIC gDefGlTick
   // default joker glass
   PUBLIC gGlassJoker
   // default frame joker
   PUBLIC gFrameJoker
   // joker glass LAMI
   PUBLIC gGlLamiJoker

   // joker brusenje
   PUBLIC gAopBrusenje
   // joker kaljenje
   PUBLIC gAopKaljenje

   // timeout kod azuriranja
   PUBLIC gInsTimeOut := 150

   // gn.zaok min/max
   PUBLIC gGnMin := 20
   PUBLIC gGnMax := 6000
   PUBLIC gGnStep := 30
   PUBLIC gGnUse := "D"
   PUBLIC gRnalOdt := "N"

   PUBLIC g3mmZaokUse := "D"
   PUBLIC gProfZaokUse := "D"

   rnal_set_params()

   ::super:setTGVars()


   gModul := "RNAL"


   // rules block i cols
   PUBLIC aRuleSpec := get_rule_field_cols_rnal()
   PUBLIC bRuleBlock := get_rule_field_block_rnal()

   RETURN .T.
