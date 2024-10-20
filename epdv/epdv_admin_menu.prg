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


FUNCTION epdv_admin_menu()


   LOCAL aOpc := {}
    LOCAL aOpcexe := {}
   LOCAL nIzbor := 1


   AAdd( aOpc, "1. renumeracija g_r_br KUF" )
   AAdd( aOpcexe, {|| epdv_renumeracija_rbr_globalni( "KUF" ) } )
   AAdd( aOpc, "2. renumeracija g_r_br KIF" )
   AAdd( aOpcexe, {|| epdv_renumeracija_rbr_globalni( "KIF" ) } )

   f18_menu( "eadm", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION epdv_renumeracija_rbr_globalni( cTblName )

   IF Pitanje(, "Izvršiti renumeriranje ? " + cTblName, "N" ) == "D"
      IF spec_funkcije_sifra( "RNGR" )
         epdv_renumeracija_g_r_br( cTblName )
      ELSE
         MsgBeep( "Pogrešna lozinka, nista od posla ..." )
      ENDIF
   ENDIF

   RETURN .T.
