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



FUNCTION fakt_pregled_dokumenata()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. štampa azuriranog dokumenta                               " )
   AAdd( aOpcExe, {|| fakt_stampa_azuriranog() } )
   AAdd( aOpc, "2. pregled liste dokumenata" )
   AAdd( aOpcExe, {|| fakt_pregled_liste_dokumenata() } )
   AAdd( aOpc, "3. štampa/export odt dokumenata po zadanom uslovu" )
   AAdd( aOpcExe, {|| stdokodt_grupno() } )

   f18_menu( "stfak", .F., nIzbor, aOpc, aOpcExe )

   my_close_all_dbf()

   RETURN .F.


FUNCTION fakt_ostale_operacije_doks()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. povrat dokumenta u pripremu       " )
   AAdd( aOpcExe, {|| Povrat_fakt_dokumenta() } )

   AAdd( aOpc, "2. povrat dokumenata prema kriteriju " )
   AAdd( aOpcExe, {|| IIF( spec_funkcije_sifra(), fakt_povrat_po_kriteriju(), nil ) } )


   AAdd( aOpc, "A. administrativne opcije " )
   AAdd( aOpcExe, {|| fakt_admin_menu() } )


   f18_menu( "ostop", .F., nIzbor, aOpc, aOpcExe )

   RETURN .F.
