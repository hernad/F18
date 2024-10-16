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



/* kalk_kartica_magacin_pomoc_unos_14()
 *  Magacinska kartica kao pomoc pri unosu 14-ke
 */

FUNCTION kalk_kartica_magacin_pomoc_unos_14()

   LOCAL nR1, nR2, nR3
   PRIVATE GetList := {}

   SELECT  roba
   nR1 := RecNo()
   SELECT kalk_pripr
   nR2 := RecNo()
   //SELECT tarifa
   //nR3 := RecNo()
   my_close_all_dbf()
   kalk_kartica_magacin( _IdFirma, _idroba, _IdKonto2 )
   o_kalk_edit()
   SELECT roba
   GO nR1
   SELECT kalk_pripr
   GO nR2
   //SELECT tarifa
   //GO nR3
   SELECT kalk_pripr

   RETURN NIL
