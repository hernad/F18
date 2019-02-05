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

CLASS TVirmMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS


METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self


METHOD mMenu()

   PRIVATE Izbor
   PRIVATE lPodBugom

   Izbor := 1

   ::programski_modul_osnovni_meni()

   RETURN NIL



METHOD programski_modul_osnovni_meni

   PRIVATE opc := {}
   PRIVATE opcexe := {}

   AAdd( opc,   "1. priprema virmana                         " )
   AAdd( opcexe, {|| unos_virmana() } )
   AAdd( opc,   "2. moduli - razmjena podataka " )
   AAdd( opcexe, {|| virm_razmjena_podataka() } )
   AAdd( opc,   "3. export podataka za banku" )
   AAdd( opcexe, {|| virm_export_banke() } )
   AAdd( opc, "------------------------------------" )
   AAdd( opcexe, nil )
   AAdd( opc,   "4. šifarnici" )
   AAdd( opcexe, {|| virm_sifarnici() } )
   AAdd( opc, "------------------------------------" )
   AAdd( opcexe, nil )
   AAdd( opc,   "X. parametri" )
   AAdd( opcexe, {|| virm_parametri() } )

   PRIVATE Izbor := 1

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "gvir", .T. )

   RETURN .T.


METHOD set_module_gvars()

   virm_set_global_vars()

   RETURN .T.



FUNCTION virm_set_global_vars()

   PUBLIC gMjesto := Space( 16 )
   PUBLIC gOrgJed := Space( 17 )
   PUBLIC gINulu := "N"
   PUBLIC gPici := "9,999,999,999,999,999.99"
   PUBLIC gIDU := "D"
   PUBLIC gVirmFirma

   gMjesto := fetch_metric( "virm_mjesto_uplate", nil, PadR( "Sarajevo", 100 ) )
   gOrgJed := fetch_metric( "virm_org_jedinica", nil, PadR( "--", 17 ) )
   gPici := fetch_metric( "virm_iznos_pict", nil, gPici )
   gINulu := fetch_metric( "virm_stampati_nule", nil, gINulu )
   gIDU := fetch_metric( "virm_sys_datum_uplate", nil, gIDU )
   //danasnji_datum() := fetch_metric( "virm_init_datum_uplate", nil, danasnji_datum() )
   gVirmFirma := PadR( fetch_metric( "virm_org_id", nil, "" ), 6 )

   RETURN .T.
