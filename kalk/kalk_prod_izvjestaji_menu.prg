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


FUNCTION kalk_izvjestaji_prodavnice_menu()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. kartica - prodavnica                          " )
   AAdd( aOpcExe, {|| kalk_kartica_prodavnica() } )
   AAdd( aOpc, "2. lager lista prodavnica" )
   AAdd( aOpcExe, {|| kalk_lager_lista_prodavnica() } )
   AAdd( aOpc, "3. finansijsko stanje prodavnice" )
   AAdd( aOpcExe, {|| kalk_finansijsko_stanje_prodavnice() } )

   AAdd( aOpc, "4. trgovačka knjiga na malo" )
   AAdd( aOpcExe, {|| kalk_tkm() } )

   AAdd( aOpc, "5. pregled asortimana za dobavljača" )
   AAdd( aOpcExe, {|| asortiman_dobavljac_mp() } )

   AAdd( aOpc, "N. najprometniji artikli u prodavnicama" )
   AAdd( aOpcExe, {|| naprometniji_artikli_prodavnica() } )

   AAdd( aOpc,  "V. pregled za više objekata" )
   AAdd( aOpcExe, {|| kalk_prodavnica_pregled_vise_objekata() } )

   AAdd( aOpc,  "K. ukalkulisani porez prodavnice" )
   AAdd( aOpcExe, {|| kalk_ukalkulisani_porez_prodavnice() } )

   AAdd( aOpc,  "R. realizovani porez prodavnice" )
   AAdd( aOpcExe, {|| kalk_realizovani_porez_prodavnice() } )

   f18_menu( "izp", .F., nIzbor, aOpc, aOpcExe )

   RETURN NIL




/*
 pregledi za vise objekata
*/

FUNCTION kalk_prodavnica_pregled_vise_objekata()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   AAdd( aOpc, "1. sintetička lager lista                  " )
   AAdd( aOpcExe, {|| sint_lager_lista_prodavnice() } )
   AAdd( aOpc, "2. rekapitulacija fin stanja po objektima" )
   AAdd( aOpcExe, {|| Rfinansijsko_stanje_prodavnica() } )

/*
   AAdd( aOpc, "3. dnevni promet za sve objekte" )
   AAdd( aOpcExe, {|| kalk_dnevni_promet_prodavnice() } )
  */

/*
   AAdd( aOpc, "4. pregled prometa prodavnica za period" )
   AAdd( aOpcExe, {|| PPProd() } )
*/

/*
   AAdd( aOpc, "5. (vise)dnevni promet za sve objekte" )
   AAdd( aOpcExe, {|| PromPeriod() } )
*/

   f18_menu( "prsi", .F., nIzbor, aOpc, aOpcExe )

   RETURN NIL
