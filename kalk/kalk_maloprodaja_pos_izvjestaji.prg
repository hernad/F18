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

STATIC s_nPosProdavnica := 0

MEMVAR ImeKol, Kol, Ch
MEMVAR wId, wIdTarifa, wTip, wBarKod

FUNCTION kalk_maloprodaja_pos_izvjestaji()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc,   "1. kartica          " )
   AAdd( aOpcExe, {|| pos_kartica_artikla() } )

   AAdd( aOpc,   "2. lager lista" )
   AAdd( aOpcExe, {|| pos_stanje_artikala() } )

   f18_menu( "m2", .F.,  nIzbor, aOpc, aOpcExe )

   RETURN .T.
