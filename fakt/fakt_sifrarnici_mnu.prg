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


FUNCTION fakt_sifrarnik()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. opći šifarnici              " )
   AAdd( aOpcExe, {|| opci_sifarnici() } )

   AAdd( aOpc, "2. robno-materijalno poslovanje " )
   AAdd( aOpcExe, {|| sif_roba_tarife_koncij_sast() } )

   AAdd( aOpc, "3. fakt->txt" )
   AAdd( aOpcExe, {|| OSifFtxt(), p_fakt_ftxt() } )

   AAdd( aOpc, "U. ugovori" )
   AAdd( aOpcExe, {|| ugov_sif_meni() } )


   f18_menu( "fasi", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
