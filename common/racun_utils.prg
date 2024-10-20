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
#include "f18_color.ch"


/* pos_show_iznos_racuna_velikim_slovima(nIznos)
 *     Ispisuje iznos racuna velikim slovima
 */

FUNCTION pos_show_iznos_racuna_velikim_slovima( nIznos )

   LOCAL cIzn, nCnt, Char, NextY, nPrevRow := Row(), nPrevCol := Col()

   SetPos ( 0, 0 )

   Box (, 9, 77 )
   cIzn := AllTrim ( Transform ( nIznos, "9999999.99" ) )
   @ box_x_koord(), box_y_koord() + 28 SAY8 "  IZNOS RAČUNA JE  " COLOR f18_color_invert()

   ispisi_velikim_slovima( cIzn, 0, f18_max_cols() -7 )

   SetPos ( nPrevRow, nPrevCol )

   RETURN .T.



// sekvenca za cjepanje trake
FUNCTION sjeci_traku( cSekv )

   IF Empty( cSekv )
      RETURN .F.
   ENDIF

   IF gPrinter <> "R"
      QQOut( cSekv )
   ENDIF

   RETURN .T.



// otvaranje ladice
FUNCTION otvori_ladicu( cSekv )


   IF Empty( cSekv )
      RETURN
   ENDIF

   IF gPrinter <> "R"
      QQOut( cSekv )
   ENDIF

   RETURN .T.


// ----------------------------------------------
// zaokruzenje na 5 pf
// ----------------------------------------------
FUNCTION zaokr_5pf( nIznos )

   LOCAL nRet := 0
   LOCAL nTmp := 0

   nTmp := Round( nIznos * 2, 1 ) / 2
   nRet := ( nIznos - nTmp )

   RETURN nRet
