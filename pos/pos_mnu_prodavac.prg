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

FUNCTION pos_main_menu_prodavac()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. priprema računa                        " )
   AAdd( aOpcExe, {|| pos_unos_ispravka_racuna() } )

   AAdd( aOpc, "2. pregled ažuriranih računa  " )
   AAdd( aOpcExe, {|| pos_pregled_racuna( .F. ) } )

   AAdd( aOpc, "R. trenutna realizacija radnika" )
   AAdd( aOpcExe, {|| pos_realizacija_radnik( .T., "P" ) } )

   AAdd( aOpc, "A. trenutna realizacija po artiklima" )
   AAdd( aOpcExe, {|| pos_realizacija_radnik( .T., "R" ) } )

   IF fiscal_opt_active()
      AAdd( aOpc, "F. fiskalne funkcije - prodavac" )
      AAdd( aOpcExe, {|| fiskalni_izvjestaji_komande( .T., .T. ) } )
   ENDIF

   f18_menu( "posp", .F., nIzbor, aOpc, aOpcExe )

   CLOSE ALL

   RETURN .T.
