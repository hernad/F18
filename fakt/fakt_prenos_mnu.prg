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


FUNCTION fakt_razmjena_podataka()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. kalk <-> fakt                  " )
   AAdd( _opcexe, {|| kalk_fakt() } )
   AAdd( _opc, "3. import barkod terminal" )
   AAdd( _opcexe, {|| fakt_import_bterm() } )
   AAdd( _opc, "4. export barkod terminal" )
   AAdd( _opcexe, {|| fakt_export_bterm() } )

   f18_menu( "rpod", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .T.
