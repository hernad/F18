/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION set_a_dbf_params()

   set_a_dbf_temp( "params",   "PARAMS", F_PARAMS    )
   set_a_dbf_temp( "gparams",   "GPARAMS", F_GPARAMS   )
   set_a_dbf_temp( "kparams",   "KPARAMS", F_KPARAMS   )
   set_a_dbf_temp( "secur",   "SECUR", F_SECUR     )

   RETURN .T.
