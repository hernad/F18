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


FUNCTION pos_menu_realizacija()

   PRIVATE opc := {}
   PRIVATE opcexe := {}
   PRIVATE Izbor := 1

   AAdd( opc, "1. kase             " )
   AAdd( opcexe, {|| realizacija_kase() } )
   //AAdd( opc, "2. odjeljenja" )
   //AAdd( opcexe, {|| realizacija_odjeljenja() } )
   AAdd( opc, "3. radnici" )
   AAdd( opcexe, {|| pos_realizacija_radnik( .F. ) } )

// #ifdef DEPR
// AAdd( opc, "4. dijelovi objekta " )
// AAdd( opcexe, {|| realizacija_dio_objekta() } )
// #else
   AAdd( opc, "------ " )
   AAdd( opcexe, NIL )
// #endif



   f18_menu_sa_priv_vars_opc_opcexe_izbor( "real" )

   RETURN .F.
