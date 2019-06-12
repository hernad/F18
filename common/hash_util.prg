/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION check_hash_key( rec, key )

   LOCAL cMsg

   IF !hb_HHasKey( rec, key )
      cMsg := RECI_GDJE_SAM + " record ne sadrzi key:" + key + " rec=" + pp( rec )
      Alert( cMsg )
      log_write( cMsg, 7 )
      RaiseError( cMsg )
      QUIT_1
   ENDIF

   RETURN .T.
