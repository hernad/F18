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

FUNCTION pos_novi_broj_dokumenta( cIdPos, cIdTipDokumenta, dDatDok )

   LOCAL nBrojDokumenta := 0
   LOCAL _broj_doks := 0
   LOCAL cPosBrojacParam
   LOCAL _tmp, _rest
   LOCAL _ret := ""
   LOCAL nDbfArea := Select()

   IF dDatDok == NIL
      dDatDok := gDatum
   ENDIF

   cPosBrojacParam := "pos" + "/" + cIdPos + "/" + cIdTipDokumenta
   nBrojDokumenta := fetch_metric( cPosBrojacParam, nil, nBrojDokumenta )

   seek_pos_doks( cIdPos, cIdTipDokumenta, dDatDok )
   GO BOTTOM
   IF field->idpos == cIdPos .AND. field->idvd == cIdTipDokumenta .AND. DToS( field->datum ) == DToS( dDatDok )
      _broj_doks := Val( field->brdok )
   ELSE
      _broj_doks := 0
   ENDIF

   nBrojDokumenta := Max( nBrojDokumenta, _broj_doks )

   ++nBrojDokumenta
   _ret := PadL( AllTrim( Str( nBrojDokumenta ) ), 6  )

   set_metric( cPosBrojacParam, nil, nBrojDokumenta )

   SELECT ( nDbfArea )

   RETURN _ret


FUNCTION pos_set_param_broj_dokumenta()

   LOCAL cPosBrojacParam
   LOCAL nBrojDokumenta := 0
   LOCAL _broj_old
   LOCAL _id_pos := gIdPos
   LOCAL _tip_dok := "42"
   LOCAL GetList := {}

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:" GET _id_pos
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _tip_dok
   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   cPosBrojacParam := "pos" + "/" + _id_pos + "/" + _tip_dok
   nBrojDokumenta := fetch_metric( cPosBrojacParam, nil, nBrojDokumenta )
   _broj_old := nBrojDokumenta

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zadnji broj dokumenta:" GET nBrojDokumenta PICT "999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      IF nBrojDokumenta <> _broj_old
         set_metric( cPosBrojacParam, nil, nBrojDokumenta )
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION pos_reset_broj_dokumenta( cIdPos, tip_dok, broj_dok )

   LOCAL cPosBrojacParam
   LOCAL nBrojDokumenta := 0

   cPosBrojacParam := "pos" + "/" + cIdPos + "/" + tip_dok
   nBrojDokumenta := fetch_metric( cPosBrojacParam, nil, nBrojDokumenta )

   IF Val( AllTrim( broj_dok ) ) == nBrojDokumenta
      --nBrojDokumenta
      set_metric( cPosBrojacParam, nil, nBrojDokumenta )
   ENDIF

   RETURN .T.
