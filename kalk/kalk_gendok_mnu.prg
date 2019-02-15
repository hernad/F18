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


FUNCTION kalk_mnu_generacija_dokumenta()

   LOCAL _Opc := {}
   LOCAL _opcexe := {}
   LOCAL _Izbor := 1

   AAdd( _opc, "1. magacin - generacija dokumenata    " )
   AAdd( _opcexe, {|| kalk_magacin_generacija_dokumenata() } )
   AAdd( _opc, "2. prodavnica - generacija dokumenata" )
   AAdd( _opcexe, {|| kalk_prod_generacija_dokumenata() } )
   AAdd( _opc, "4. storno kalk dokumenta" )
   AAdd( _opcexe, {|| storno_kalk_dokument() } )

   f18_menu( "mgend", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .T.
