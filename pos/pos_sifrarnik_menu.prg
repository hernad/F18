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

FUNCTION pos_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcexe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. robe/artikli                " )
   AAdd( aOpcexe, {|| P_Roba() } )
   AAdd( aOpc, "2. tarife" )
   AAdd( aOpcexe, {|| P_Tarifa() } )
   AAdd( aOpc, "3. vrste plaćanja" )
   AAdd( aOpcexe, {|| P_VrsteP() } )

   IF pos_admin()
      AAdd( aOpc, "5. partneri" )
      AAdd( aOpcexe, {|| p_partner() } )
      AAdd( aOpc, "A. statusi radnika" )
      AAdd( aOpcexe, {|| p_pos_strad() } )
      AAdd( aOpc, "B. osoblje" )
      AAdd( aOpcexe, {|| P_Osob() } )
   ENDIF

   f18_menu( "sift", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
