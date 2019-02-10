/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


FUNCTION kalk_pregled_dokumenata()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. štampa ažuriranog dokumenta              " )
   AAdd( aOpcExe, {|| kalk_stampa_azuriranog_dokumenta() } )

   AAdd( aOpc, "2. štampa liste dokumenata" )
   AAdd( aOpcExe, {|| kalk_stampa_liste_dokumenata() } )

/*
   AAdd( aOpc, "3. pregled dokumenata po hronologiji obrade" )
   AAdd( aOpcExe, {|| kalk_pregled_dokumenata_hronoloski() } )
*/

   AAdd( aOpc, "4. pregled dokumenata - tabelarni pregled" )
   AAdd( aOpcExe, {|| kalk_pregled_dokumenata_tabela() } )

/*
   AAdd( aOpc, "5. radni nalozi " )
   AAdd( aOpcExe, {|| BrowseRn() } )
*/

   AAdd( aOpc, "8. kalkulacija cijena" )
   AAdd( aOpcExe, {|| kalkulacija_cijena() } )

   f18_menu( "razp", .F., nIzbor, aOpc, aOpcExe )

   //my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_ostale_operacije_doks()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. povrat dokumenta u pripremu" )
   AAdd( aOpcExe, {|| kalk_povrat_dokumenta() } )


   AAdd( aOpc, "S. pregled smeća " )
   AAdd( aOpcExe, {|| kalk_pregled_smece_pripr9() } )


   f18_menu( "mazd", .F., nIzbor, aOpc, aOpcExe )

   //my_close_all_dbf()

   RETURN .T.
