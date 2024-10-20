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


FUNCTION epdv_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. partneri               " )
   AAdd( aOpcExe, {|| p_partner() } )
   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )

   AAdd( aOpc, "5. sheme generacije kuf" )
   AAdd( aOpcExe, {|| p_sg_kuf() } )
   AAdd( aOpc, "6. sheme generacije kif" )
   AAdd( aOpcExe, {|| p_sg_kif() } )

   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )

   AAdd( aOpc, "8. tarife" )
   AAdd( aOpcExe, {|| P_Tarifa() } )

   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )

   AAdd( aOpc, "S. sifk" )
   AAdd( aOpcExe, {|| P_SifK() } )

   f18_menu( "esif", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
