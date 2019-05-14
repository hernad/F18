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

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. generacija zavisnih dokumenata (kontiranje)          " )
   AAdd( aOpcExe, {|| kalk_kontiranje_gen_finmat( .T. ) } )
   AAdd( aOpc, "2. fakt -> kalk" )
   AAdd( aOpcExe, {|| fakt_kalk() } )

   IF is_kalk_tops_generacija_kalk_11_na_osnovu_pos_42()
      AAdd( aOpc, "4. pos -> kalk razduženje prodavnice na osnovu pos" )
      AAdd( aOpcExe, {|| kalk_razduzi_prodavnicu_na_osnovu_pos_prodaje() } )
  else
     AAdd( aOpc, "4. pos -> kalk razduženje prodavnice" )
     AAdd( aOpcExe, {|| kalk_prenos_iz_pos_u_kalk() } )
   ENDIF


   //AAdd( aOpc, "5. kalk -> pos" )
   //AAdd( aOpcExe, {|| kalk_tops_meni() } )

   AAdd( aOpc, "6. import csv fajl " )
   AAdd( aOpcExe, {|| meni_import_csv() } )
   AAdd( aOpc, "-----------------------------------" )
   AAdd( aOpcExe, NIL )

   // AAdd( aOpc, "A. kontiraj dokumente za period - u pripremu" )
   // AAdd( aOpcExe, {|| kalk_kontiranje_dokumenata_period() } )

   AAdd( aOpc, "K. kontiranje kalk->fin za period" )
   AAdd( aOpcExe, {|| kontiranje_vise_dokumenata_period_auto() } )

   AAdd( aOpc, "V. import vindija varaždin" )
   AAdd( aOpcexe, {|| meni_import_vindija() } )

   f18_menu( "rmod", .F., nIzbor, aOpc, aOpcExe )

   my_close_all_dbf()

   RETURN .T.


/*
STATIC FUNCTION mnu_prenos_tops_u_kalk()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

--   AAdd( aOpc, "1. prenos podataka pos->kalk                        " )
--   AAdd( aOpcExe, {|| kalk_prenos_iz_pos_u_kalk() } )


   AAdd( aOpc, "2. prenos podataka pos->kalk (razduzi automatski)" )
   AAdd( aOpcExe, {|| kalk_preuzmi_tops_dokumente_auto() } )

  -- AAdd( aOpc, "3. pos->kalk 96 po normativima za period " )
--   AAdd( aOpcExe, {|| tops_nor_96() } )

   f18_menu( "rpka", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.
*/
