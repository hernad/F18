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


/*
 setovanje temporary tabela koje koriste svi moduli
*/

FUNCTION set_a_dbf_temporary()

   LOCAL _rec

   set_a_dbf_temp( "doksrc",  "DOKSRC", F_DOKSRC     )
   set_a_dbf_temp( "p_doksrc",  "P_DOKSRC", F_P_DOKSRC   )
   set_a_dbf_temp( "p_update",  "P_UPDATE", F_P_UPDATE   )
   set_a_dbf_temp( "finmat",  "FINMAT", F_FINMAT     )
   set_a_dbf_temp( "r_export",  "R_EXPORT", F_R_EXP      )
   set_a_dbf_temp( "pom2",  "POM2", F_POM2       )
   set_a_dbf_temp( "pom",   "POM", F_POM  )
   set_a_dbf_temp( "dracun",  "DRN", F_DRN        )
   set_a_dbf_temp( "racun",  "RN", F_RN         )
   set_a_dbf_temp( "dracuntext",  "DRNTEXT", F_DRNTEXT    )

   RETURN .T.
