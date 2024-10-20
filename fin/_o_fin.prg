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


FUNCTION o_fin_ios()

   RETURN o_dbf_table( F_IOS, { "IOS", "ios" }, "1" )


FUNCTION o_fin_pnalog()

   RETURN o_dbf_table( F_PNALOG, { "PNALOG", "fin_pnalog" }, "1" )


FUNCTION o_fin_psint()

   RETURN o_dbf_table( F_PSINT, { "PSINT", "fin_psint" }, "1" )


FUNCTION o_fin_panal()

   RETURN o_dbf_table( F_PANAL, { "PANAL", "fin_panal" }, "1" )


FUNCTION o_fin_psuban()

   RETURN o_dbf_table( F_PSUBAN, { "PSUBAN", "fin_psuban" }, "1" )


FUNCTION o_fin_pripr()

   RETURN o_dbf_table( F_FIN_PRIPR, "fin_pripr", "1" )

FUNCTION select_o_fin_pripr()

   RETURN select_o_dbf( "FIN_PRIPR", F_FIN_PRIPR, "fin_pripr", "1" )


FUNCTION select_o_kam_kamat()

   RETURN select_o_dbf( "KAM_KAMAT", F_KAMAT, "kam_kamat", "1" )


FUNCTION select_o_kam_pripr()

   RETURN select_o_dbf( "KAM_PRIPR", F_KAMPRIPR, "kam_pripr", "1" )


FUNCTION o_bruto_bilans_klase()

   SELECT F_BBKLAS
   USE
   RETURN o_dbf_table( F_BBKLAS, "bbklas", "1" )



FUNCTION o_nalog( lSql, cIdVN )

   hb_default( @lSql, .F. )

   IF lSql
      RETURN use_sql_fin_nalog( cIdVN, .T. )
   ENDIF

   // RETURN o_dbf_table( F_NALOG, "nalog", "1" )

   RETURN use_sql_nalog()


FUNCTION o_suban()

   // RETURN o_dbf_table( F_SUBAN, "suban", "1" )

   RETURN use_sql_suban()

FUNCTION o_anal()

   // RETURN o_dbf_table( F_ANAL, "anal", "1" )

   RETURN use_sql_anal()


FUNCTION o_sint()

   // RETURN o_dbf_table( F_SINT, "sint", "1" )

   RETURN use_sql_sint()


/*
FUNCTION o_ulimit()
   RETURN o_dbf_table( F_ULIMIT, "ulimit", "ID" )
*/



/*
FUNCTION o_funk()
   RETURN o_dbf_table( F_FUNK, "funk", "ID" )


FUNCTION o_fond()
   RETURN o_dbf_table( F_FOND, "fond", "ID" )
*/

FUNCTION o_ostav()
   RETURN o_dbf_table( F_OSTAV, "ostav", "1" )
