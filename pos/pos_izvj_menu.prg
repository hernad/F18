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

FUNCTION pos_izvjestaji()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcexe := {}

   AAdd( aOpc, "1. realizacija                               " )
   AAdd( aOpcexe, {|| pos_menu_realizacija() } )
   AAdd( aOpc, "2. stanje artikala" )
   AAdd( aOpcexe, {|| pos_stanje_artikala() } )

   AAdd( aOpc, "4. kartice artikala" )
   AAdd( aOpcexe, {|| pos_kartica_artikla() } )
   AAdd( aOpc, "5. porezi po tarifama" )
   AAdd( aOpcexe, {||  pos_pdv_po_tarifama() } )

   AAdd( aOpc, "7. stanje partnera" )
   AAdd( aOpcexe, {|| pos_rpt_stanje_partnera() } )
   AAdd( aOpc, "A. štampa azuriranih dokumenata" )
   AAdd( aOpcexe, {|| pos_lista_azuriranih_dokumenata() } )

   AAdd( aOpc, "-------------------" )
   AAdd( aOpcexe, NIL )

   IF fiscal_opt_active()
      AAdd( aOpc, "F. fiskalni izvještaji i komande" )
      AAdd( aOpcexe, {|| fiskalni_izvjestaji_komande( .F., .T. ) } )
   ENDIF

   f18_menu( "izvt", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
