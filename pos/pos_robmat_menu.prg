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


FUNCTION pos_menu_robmat()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}
   PRIVATE Izbor := 1

   AAdd( opc, "1. unos dokumenata        " )
   AAdd( opcexe, {|| pos_menu_dokumenti() } )
   AAdd( opc, "2. generacija dokumenata" )
   AAdd( opcexe, {|| pos_menu_gendok() } )

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "mrbm" )

   RETURN .T.



FUNCTION pos_menu_gendok()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}
   PRIVATE Izbor := 1

   AAdd( opc, "1. generacija dokumenta početnog stanja     " )
   AAdd( opcexe, {|| pos_pocetno_stanje() } )
   //AAdd( opc, "2. import sifrarnika ROBA iz fmk-tops     " )
   //AAdd( opcexe, {|| pos_import_fmk_roba() } )

   Izbor := 1
   f18_menu_sa_priv_vars_opc_opcexe_izbor( "gdok" )

   RETURN .T.
