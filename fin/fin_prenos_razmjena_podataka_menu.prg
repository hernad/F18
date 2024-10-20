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



FUNCTION fin_razmjena_podataka_meni()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. fakt->fin                              " )
   AAdd( aOpcExe, {|| fakt_fin_prenos() } )
   //AAdd( aOpc, "2. ld->fin " )
   //AAdd( aOpcExe, {|| LdFin() } )
   AAdd( aOpc, "3. import txt elektronsko bankarstvo bbi" )
   AAdd( aOpcExe, {|| import_elektronsko_bankarstvo_bbi() } )

   //AAdd( aOpc, "4. export dbf (svi nalozi) " )
   //AAdd( aOpcExe, {|| st_sv_nal() } )
  //AAdd( aOpc, "6. pos->fin " )
   //AAdd( aOpcExe, {|| PosFin() } )

   f18_menu( "fraz", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.



/*
 *     Prenos prometa pologa

FUNCTION PosFin()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. pos polozi                   " )
   AAdd( aOpcExe, {|| PromVP2Fin() } )

   f18_menu( "pofi", .F., nIzbor, aOpc, aOpcExe )

   RETURN
*/
