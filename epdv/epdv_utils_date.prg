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


// Ako je dan < 10
// return { 01.predhodni_mjesec , zadnji.predhodni_mjesec}
// else
// return { 01.tekuci_mjesec, danasnji dan }

FUNCTION epdv_rpt_d_interval ( dToday )

   LOCAL nDay, nFDOm
   LOCAL dDatOd, dDatDo

   nDay := Day( dToday )
   nFDOm := BOM( dToday )

   IF nDay < 10
      // prvi dan u tekucem mjesecu - 1
      dDatDo := nFDom - 1
      // prvi dan u proslom mjesecu
      dDatOd := BOM( dDatDo )

   ELSE
      dDatOd := nFDom
      dDatDo := dToday
   ENDIF

   RETURN { dDatOd, dDatDo }
