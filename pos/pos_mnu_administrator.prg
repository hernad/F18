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

FUNCTION pos_main_menu_admin()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. izvještaji                       " )
   AAdd( aOpcexe, {|| pos_izvjestaji() } )
   AAdd( aOpc, "2. pregled računa" )
   AAdd( aOpcexe, {|| pos_pregled_racuna_tabela() } )
   AAdd( aOpc, "L. lista ažuriranih dokumenata" )
   AAdd( aOpcexe, {|| pos_lista_azuriranih_dokumenata() } )
   AAdd( aOpc, "R. robno-materijalno poslovanje" )
   AAdd( aOpcexe, {|| pos_menu_robmat() } )
   AAdd( aOpc, "K. prenos realizacije u KALK" )
   AAdd( aOpcexe, {|| pos_kalk_prenos_realizacije() } )
   AAdd( aOpc, "S. šifarnici                  " )
   AAdd( aOpcexe, {|| pos_sifarnici() } )
   AAdd( aOpc, "A. administracija pos-a" )
   AAdd( aOpcexe, {|| pos_admin_menu() } )

   f18_menu( "posa", .F., nIzbor, aOpc, aOpcExe )


RETURN .T.


FUNCTION pos_admin_menu()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. parametri rada programa                        " )
   AAdd( aOpcexe, {|| pos_parametri() } )

   AAdd( aOpc, "R. setovanje brojača dokumenata" )
   AAdd( aOpcexe, {|| pos_set_param_broj_dokumenta() } )

   f18_menu( "padm", .F., nIzbor, aOpc, aOpcExe )

   RETURN .F.
