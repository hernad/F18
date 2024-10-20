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

FUNCTION fakt_izvjestaji()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. stanje robe                                          " )
   AAdd( aOpcExe, {|| fakt_stanje_robe() } )
   AAdd( aOpc, "2. lager lista - specifikacija   " )
   AAdd( aOpcExe, {|| fakt_lager_lista() } )
   AAdd( aOpc, "3. kartica" )
   AAdd( aOpcExe, {|| fakt_kartica() } )
   AAdd( aOpc, "5. uporedna lager lista fakt <-> kalk" )
   AAdd( aOpcExe, {|| fakt_uporedna_lista_fakt_kalk( .F. ) } )
   AAdd( aOpc, "6. realizacija kumulativno po partnerima" )
   AAdd( aOpcExe, {|| fakt_real_kumulativno_po_partnerima() } )

   AAdd( aOpc, "7. specifikacija prodaje - realizacija po količinama" )
   AAdd( aOpcExe, {|| fakt_specif_prodaje_real_kolicina() } )

   AAdd( aOpc, "8. količinski pregled isporuke robe po partnerima " )
   AAdd( aOpcExe, {|| fakt_kol_pregled_isporuke_robe_partneri() } )
   AAdd( aOpc, "9. realizacija maloprodaje " )
   AAdd( aOpcExe, {|| fakt_real_maloprodaje() } )

   IF fiscal_opt_active()
      AAdd( aOpc, "F. fiskalni izvještaji i komande " )
      AAdd( aOpcExe, {|| fiskalni_izvjestaji_komande() } )
   ENDIF

   //PRIVATE fID_J := .F.

   f18_menu( "izvj", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
