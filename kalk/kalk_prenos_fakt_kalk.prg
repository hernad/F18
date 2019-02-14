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

FUNCTION fakt_kalk()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}

   AAdd( Opc, "1. magacin fakt->kalk         " )
   AAdd( opcexe, {|| prenos_fakt_kalk_magacin() } )
   AAdd( Opc, "2. prodavnica fakt->kalk" )
   AAdd( opcexe, {||  prenos_fakt_kalk_prodavnica()  } )

   AAdd( Opc, "3. proizvodnja fakt->kalk" )
   AAdd( opcexe, {||  menu_fakt_kalk_prenos_normativi() } )


   PRIVATE Izbor := 1
   f18_menu_sa_priv_vars_opc_opcexe_izbor( "faka" )
   CLOSERET

   RETURN .T.
