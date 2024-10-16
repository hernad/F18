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


FUNCTION kalk_kartica_prodavnica_f6()

   LOCAL nR1
   LOCAL nR2
   LOCAL nR3
   LOCAL cIdFirma := Space( 2 )
   LOCAL cIdRoba := Space( 10 )
   LOCAL cKonto := Space( 7 )
   LOCAL GetList := {}

   //SELECT  roba
   //nR1 := RecNo()
   SELECT kalk_pripr
   nR2 := RecNo()
   //SELECT tarifa
   //nR3 := RecNo()

   IF Empty( kalk_pripr->pkonto )
      Box(, 2, 50 )
      cIdFirma := self_organizacija_id()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "KARTICA PRODAVNICA"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Kartica konto-artikal" GET cKonto
      @ box_x_koord() + 2, Col() + 2 SAY "-" GET cIdRoba
      READ
      BoxC()
   ELSE
      cIdFirma := kalk_pripr->idfirma
      cKonto := kalk_pripr->pkonto
      cIdRoba := kalk_pripr->idroba
   ENDIF

   my_close_all_dbf()

   kalk_kartica_prodavnica( cIdFirma, cIdRoba, cKonto )

   o_kalk_edit()
   //SELECT roba
   //GO nR1

   SELECT kalk_pripr
   GO nR2

   //SELECT tarifa
   //GO nR3

   SELECT kalk_pripr

   RETURN
