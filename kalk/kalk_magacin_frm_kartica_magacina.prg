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


FUNCTION kalk_kartica_magacin_u_pripremi()

   LOCAL nR1
   LOCAL nR2
   LOCAL nR3
   LOCAL cIdFirma := Space( 2 )
   LOCAL cIdroba := Space( 10 )
   LOCAL cKonto := Space( 7 )
   PRIVATE GetList := {}

/*
   SELECT  roba
   nR1 := RecNo()

   SELECT kalk_pripr
   nR2 := RecNo()

--   SELECT tarifa
   nR3 := RecNo()
*/

   PushWa()

   IF Empty( kalk_pripr->mkonto )
      Box(, 2, 50 )
      cIdFirma := self_organizacija_id()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "KARTICA MAGACIN"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Kartica konto-artikal" GET cKonto
      @ box_x_koord() + 2, Col() + 2 SAY "-" GET cIdRoba
      READ
      BoxC()
   ELSE
      cIdFirma := kalk_pripr->idfirma
      cKonto := kalk_pripr->mkonto
      cIdRoba := kalk_pripr->idroba
   ENDIF

   my_close_all_dbf()

   kalk_kartica_magacin( cIdFirma, cIdRoba, cKonto )

   o_kalk_edit()

/*
   SELECT roba
   GO nR1

   SELECT kalk_pripr
   GO nR2

--   SELECT tarifa
   GO nR3
*/
   PopWa()
   //SELECT kalk_pripr

   RETURN .T.
