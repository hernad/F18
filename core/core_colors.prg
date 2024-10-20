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

#include "f18_color.ch"

FUNCTION f18_color_normal( lMijenjajOnSezona )

   hb_default( @lMijenjajOnSezona, .F. )

   IF lMijenjajOnSezona .AND. !in_tekuca_godina()
      RETURN F18_COLOR_NORMAL_STARA_SEZONA
   ENDIF

   RETURN F18_COLOR_NORMAL


FUNCTION f18_color_invert( lMijenjajOnSezona )

   LOCAL cColor

   cColor := f18_color_normal( lMijenjajOnSezona )

   RETURN hb_ColorIndex( cColor, 4 ) + "," ;
      + hb_ColorIndex( cColor, 3 ) + ",";
      + hb_ColorIndex( cColor, 2 ) + ",";
      + hb_ColorIndex( cColor, 1 ) + ",";
      + hb_ColorIndex( cColor, 0 )


FUNCTION f18_color_i()
   RETURN "I"
