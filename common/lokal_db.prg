/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION g_lokal_fields()

   LOCAL aDbf := {}

   AAdd( aDBf, { "id", "C",   2,  0 } )
   // id stringa
   AAdd( aDBf, { "id_str", "N",   6,  0 } )
   // string
   AAdd( aDBf, { "naz", "C",   200,  0 } )

   RETURN aDbf
