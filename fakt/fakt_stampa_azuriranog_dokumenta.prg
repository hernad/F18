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


FUNCTION fakt_stampa_azuriranog()

   PRIVATE cIdFirma, cIdTipDok, cBrDok

   cIdFirma := self_organizacija_id()
   cIdTipDok := "10"
   cBrdok := Space( 8 )

   Box( "", 2, 35 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY " RJ-tip-broj:" GET cIdFirma
   @ box_x_koord() + 2, Col() + 1 SAY "-" GET cIdTipDok
   @ box_x_koord() + 2, Col() + 1 SAY "-" GET cBrDok
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   my_close_all_dbf()

   fakt_stamp_txt_dokumenta( cIdFirma, cIdTipDok, cBrDok )

   SELECT F_FAKT_PRIPR
   IF Used()
      USE
   ENDIF

   RETURN .T.
