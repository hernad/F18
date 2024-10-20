/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION fin_izvjestaji()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. kartica                      " )
   AAdd( aOpcExe, {|| fin_kartice_menu() } )

   AAdd( aOpc, "2. bruto bilansi" )
   AAdd( aOpcExe, {|| FinBrutoBilans():New():print() } )

   AAdd( aOpc, "3. specifikacije" )
   AAdd( aOpcExe, {|| fin_menu_specifikacije() } )

   AAdd( aOpc, "4. ročni intervali" )
   AAdd( aOpcExe, {|| fin_rocni_intervali_meni() } )

// AAdd( aOpc, "5. proizvoljni izvještaji" )
// AAdd( aOpcExe, {|| ProizvFin() } )

   AAdd( aOpc, "6. dnevnik naloga" )
   AAdd( aOpcExe, {|| fin_dnevnik_naloga() } )

   AAdd( aOpc, "7. ostali izvještaji" )
   AAdd( aOpcExe, {|| fin_izvjestaji_ostali() } )

   AAdd( aOpc, "8. blagajnički nalog" )
   AAdd( aOpcExe, {|| blag_azur() } )


   f18_menu( "fizvj", .F., nIzbor, aOpc, aOpcExe )

   RETURN .F.
