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


FUNCTION pos_izvjestaji()

   PRIVATE Izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   AAdd( opc, "1. realizacija                               " )
   AAdd( opcexe, {|| pos_menu_realizacija() } )

   // IF gVrstaRS == "K"
   // AAdd( opc, "----------------------------" )
   // AAdd( opcexe, nil )
   // AAdd( opc, "3. najprometniji artikli" )
   // AAdd( opcexe, {|| pos_top_narudzbe() } )
   // AAdd( opc, "4. štampa azuriranih dokumenata" )
   // AAdd( opcexe, {|| pos_lista_azuriranih_dokumenata() } )
   // ELSE
   // server, samostalna kasa TOPS

   AAdd( opc, "2. stanje artikala ukupno" )
   AAdd( opcexe, {|| pos_stanje_artikala() } )

   // IF gVodiOdj == "D"
   AAdd( opc, "3. stanje artikala po odjeljenjima" )
   AAdd( opcexe, {|| pos_stanje_artikala_po_odjeljenjima() } )
   // ELSE
   // AAdd( opc, "--------------------" )
   // AAdd( opcexe, nil )
   // ENDIF

   AAdd( opc, "4. kartice artikala" )
   AAdd( opcexe, {|| pos_kartica_artikla() } )
   AAdd( opc, "5. porezi po tarifama" )
   AAdd( opcexe, {||  pos_pdv_po_tarifama() } )
   AAdd( opc, "6. najprometniji artikli" )
   AAdd( opcexe, {|| pos_top_narudzbe() } )
   AAdd( opc, "7. stanje partnera" )
   AAdd( opcexe, {|| pos_rpt_stanje_partnera() } )
   AAdd( opc, "A. štampa azuriranih dokumenata" )
   AAdd( opcexe, {|| pos_lista_azuriranih_dokumenata() } )
   // ENDIF

   AAdd( opc, "-------------------" )
   AAdd( opcexe, NIL )

   IF gPVrsteP
      AAdd( opc, "N. pregled prometa po vrstama plaćanja" )
      AAdd( opcexe, {|| pos_pregled_prometa_po_vrstama_placanja() } )
   ENDIF

   IF fiscal_opt_active()
      AAdd( opc, "F. fiskalni izvještaji i komande" )
      AAdd( opcexe, {|| fiskalni_izvjestaji_komande( NIL, .T. ) } )
   ENDIF

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "izvt" )

   RETURN .T.
