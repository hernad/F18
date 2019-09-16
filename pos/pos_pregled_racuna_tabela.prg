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


FUNCTION pos_pregled_racuna_tabela()

   LOCAL fScope := .T.
   LOCAL GetList := {}
   LOCAL cFilterDatumOdDo
   LOCAL dDatOd, dDatDo
   LOCAL hParams := hb_Hash()

   o_pos__pripr()
   dDatOd := Date()
   dDatDo := Date()

   // qIdRoba := Space( FIELD_ROBA_ID_LENGTH )

   SET CURSOR ON

   Box(, 2, 60 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datumski period:" GET dDatOd
   @ box_x_koord() + 2, Col() + 2 SAY "-" GET dDatDo
   READ

   BoxC()

   IF LastKey() == K_ESC
      CLOSE ALL
      RETURN .F.
   ENDIF

   // cFilterDatumOdDo := ""

   // IF !Empty( dDatOd ) .AND. !Empty( dDatDo )
   // cFilterDatumOdDo := "datum >= " + _filter_quote( dDatOD ) + " .and. datum <= " + _filter_quote( dDatDo )
   // ENDIF

   hParams[ "idpos" ] := pos_pm()
   hParams[ "idvd" ] := POS_IDVD_RACUN
   hParams[ "dat_od" ] := dDatOd
   hParams[ "dat_do" ] := dDatDo
   hParams[ "browse" ] := .T.

   pos_lista_racuna( hParams )

   my_close_all_dbf()

   RETURN .T.
