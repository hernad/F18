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


FUNCTION epdv_izvjestaji()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. kuf lista dokumenata " )
   AAdd( aOpcExe, {|| epdv_r_lista( "KUF" ) } )
   AAdd( aOpc, "2. kuf" )
   AAdd( aOpcExe, {|| epdv_rpt_kuf() } )

   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )


   AAdd( aOpc, "3. kif lista dokumenata " )
   AAdd( aOpcExe, {|| epdv_r_lista( "KIF" ) } )
   AAdd( aOpc, "4. kif" )
   AAdd( aOpcExe, {|| epdv_rpt_kif() } )

   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )

   AAdd( aOpc, "5. prijava pdv-a" )
   AAdd( aOpcExe, {|| epdv_pdv_prijava() } )

   AAdd( aOpc, "-------------------------" )
   AAdd( aOpcExe, {|| NIL } )


   f18_menu( "erpt", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
