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


/*
FUNCTION o_jprih()
   RETURN o_dbf_table( F_JPRIH, "jprih", "ID" )

*/


FUNCTION o_vrprim( cId )

   SELECT ( F_VRPRIM )

   IF !use_sql_sif ( "vrprim", .T., "VRPRIM", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION o_jprih()

   SELECT ( F_JPRIH )

   IF !use_sql_sif ( "jprih" )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"

   RETURN .T.


FUNCTION select_o_jprih()

   SELECT ( F_JPRIH )
   IF Used()
      RETURN .T.
   ENDIF

   RETURN o_jprih()



FUNCTION o_ldvirm()

   SELECT ( F_LDVIRM )

   IF !use_sql_sif ( "ldvirm" )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"

   RETURN .T.




FUNCTION o_virm_pripr()

   RETURN o_dbf_table( F_VIPRIPR, "virm_pripr", "1" )


FUNCTION select_o_virm_pripr()

   RETURN select_o_dbf( "VIRM_PRIPR", F_VIPRIPR, "virm_pripr", "1" )
