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



//FUNCTION o_fakt_dbf()
//   RETURN o_dbf_table( F_FAKT, "fakt", "1" )


// "fakt_fakt", "FAKT", F_FAKT


FUNCTION o_fakt_pripr()

   SELECT ( F_FAKT_PRIPR )
   IF Used()
      RETURN .T.
   ENDIF

   my_use ( "fakt_pripr", NIL, .F. )
   SET ORDER TO TAG "1"

   RETURN .T.



FUNCTION select_o_fakt_pripr()

   select_o_dbf( "FAKT_PRIPR", F_FAKT_PRIPR, "fakt_pripr", "1" )
   IF Alias() != "FAKT_PRIPR"
      Alert( "Nije FAKT_PRIPR2 ?!" )
      RETURN .F.
   ENDIF

   RETURN .T.
