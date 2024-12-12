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


FUNCTION kalk_razmjena_podataka()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. generacija zavisnih dokumenata (kontiranje)      " )
   AAdd( _opcexe, {|| kalk_kontiranje_gen_finmat( .T. ) } )
   AAdd( _opc, "2. fakt -> kalk" )
   AAdd( _opcexe, {|| fakt_kalk() } )

   AAdd( _opc, "5. import vindija varaždin" )
   AAdd( _opcexe, {|| meni_import_vindija() } )
   AAdd( _opc, "6. import csv fajl " )
   AAdd( _opcexe, {|| meni_import_csv() } )
   AAdd( _opc, "-----------------------------------" )
   AAdd( _opcexe, nil )

   //AAdd( _opc, "A. kontiraj dokumente za period - u pripremu" )
   //AAdd( _opcexe, {|| kalk_kontiranje_dokumenata_period() } )

   AAdd( _opc, "K. kontiranje kalk->fin za period" )
   AAdd( _opcexe, {|| kontiranje_vise_dokumenata_period_auto() } )

   f18_menu( "rmod", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .T.


/*
STATIC FUNCTION mnu_prenos_tops_u_kalk()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. prenos podataka pos->kalk                        " )
   AAdd( _opcexe, {|| kalk_preuzmi_tops_dokumente() } )


   AAdd( _opc, "2. prenos podataka pos->kalk (razduzi automatski)" )
   AAdd( _opcexe, {|| kalk_preuzmi_tops_dokumente_auto() } )

  -- AAdd( _opc, "3. pos->kalk 96 po normativima za period " )
--   AAdd( _opcexe, {|| tops_nor_96() } )

   f18_menu( "rpka", .F., _izbor, _opc, _opcexe )

   RETURN .T.
*/
