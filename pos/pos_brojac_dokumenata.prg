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

FUNCTION pos_novi_broj_dokumenta( cIdPos, cIdTipDokumenta, dDatDok )

   LOCAL nBrojDokumenta
   LOCAL cPosBrojacParam
   LOCAL cRet := ""
   LOCAL nDbfArea := Select()

   IF dDatDok == NIL
      dDatDok := danasnji_datum()
   ENDIF

   cPosBrojacParam := "pos" + "/" + cIdPos + "/" + cIdTipDokumenta
   nBrojDokumenta := fetch_metric( cPosBrojacParam, NIL, nBrojDokumenta )

   seek_pos_doks( cIdPos, cIdTipDokumenta, dDatDok )
   GO BOTTOM
   nBrojDokumenta := 0
   DO WHILE !Bof()
      IF hb_regexHas( "^\s*\d+", pos_doks->brdok )
         IF field->idpos == cIdPos .AND. field->idvd == cIdTipDokumenta .AND. DToS( field->datum ) == DToS( dDatDok )
            nBrojDokumenta := Val( pos_doks->brdok )
         ELSE
            nBrojDokumenta := 0
         ENDIF
         EXIT
      ENDIF
      SKIP -1
   ENDDO

   nBrojDokumenta := Max( nBrojDokumenta, 0 )
   ++nBrojDokumenta
   cRet := PadL( AllTrim( Str( nBrojDokumenta ) ),  FIELD_LEN_POS_BRDOK )
   set_metric( cPosBrojacParam, NIL, nBrojDokumenta )
   SELECT ( nDbfArea )

   RETURN cRet


FUNCTION pos_set_param_broj_dokumenta()

   LOCAL cPosBrojacParam
   LOCAL nBrojDokumenta := 0
   LOCAL nBrojDokumentaOld
   LOCAL cIdPos := pos_pm()
   LOCAL cIdTipDok := "42"
   LOCAL GetList := {}

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:" GET cIdPos
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdTipDok
   READ

   IF LastKey() == K_ESC
      BoxC()
      RETURN .F.
   ENDIF

   cPosBrojacParam := "pos" + "/" + cIdPos + "/" + cIdTipDok
   nBrojDokumenta := fetch_metric( cPosBrojacParam, NIL, nBrojDokumenta )
   nBrojDokumentaOld := nBrojDokumenta

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zadnji broj dokumenta:" GET nBrojDokumenta PICT "999999"
   READ

   BoxC()

   IF LastKey() != K_ESC
      IF nBrojDokumenta <> nBrojDokumentaOld
         set_metric( cPosBrojacParam, NIL, nBrojDokumenta )
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION pos_reset_broj_dokumenta( cIdPos, tip_dok, broj_dok )

   LOCAL cPosBrojacParam
   LOCAL nBrojDokumenta := 0

   cPosBrojacParam := "pos" + "/" + cIdPos + "/" + tip_dok
   nBrojDokumenta := fetch_metric( cPosBrojacParam, NIL, nBrojDokumenta )

   IF Val( AllTrim( broj_dok ) ) == nBrojDokumenta
      --nBrojDokumenta
      set_metric( cPosBrojacParam, NIL, nBrojDokumenta )
   ENDIF

   RETURN .T.
