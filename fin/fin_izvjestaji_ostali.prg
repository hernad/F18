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


FUNCTION fin_izvjestaji_ostali()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. pregled promjena na računu               " )
   AAdd( aOpcExe, {|| fin_pregled_promjena_na_racunu() } )

   IF ( IsRamaGlas() )
      AAdd( aOpc, "P. specifikacije za pogonsko knjigovodstvo" )
      AAdd( aOpcExe, {|| IzvjPogonK() } )
   ENDIF

   f18_menu( "fost", .F., nIzbor, aOpc, aOpcExe )

   RETURN .F.
