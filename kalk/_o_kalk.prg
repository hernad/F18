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

FUNCTION o_kalk()

   RETURN use_sql_kalk()


FUNCTION o_kalk_doks()

   RETURN use_sql_kalk_doks()


// FUNCTION o_kalk_doks2()
//
// RETURN use_sql_kalk_doks2()


// FUNCTION select_o_kalk_doks2()
//
// SELECT ( F_KALK_DOKS2 )
// IF Used()
// RETURN .T.
// ENDIF
//
// RETURN o_kalk_doks2()


FUNCTION o_kalk_imp_temp()

   RETURN o_dbf_table( F_KALK_IMP_TEMP, "kalk_imp_temp", NIL )


FUNCTION select_o_kalk_imp_temp()

   RETURN select_o_dbf( "KALK_IMP_TEMP", F_KALK_IMP_TEMP, "kalk_imp_temp", NIL )


FUNCTION o_kalk_pript()
   RETURN o_dbf_table( F_PRIPT, { "PRIPT", "kalk_pript" }, "1" )


FUNCTION select_o_kalk_pript()
   RETURN select_o_dbf( "PRIPT", F_PRIPT, { "PRIPT", "kalk_pript" }, "1" )



FUNCTION open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok )

   RETURN kalk_otvori_kumulativ_kao_pripremu( cIdFirma, cIdVd, cBrDok )


FUNCTION o_kalk_pripr()

   RETURN o_dbf_table( F_KALK_PRIPR, "kalk_pripr", "1" )


FUNCTION o_kalk_pripr2()

   RETURN o_dbf_table( F_KALK_PRIPR, "kalk_pripr2", "1" )


FUNCTION o_kalk_pripr9()

   RETURN o_dbf_table( F_KALK_PRIPR, "kalk_pripr9", "1" )


FUNCTION select_o_kalk_pripr()

   RETURN select_o_dbf( "KALK_PRIPR", F_KALK_PRIPR, "kalk_pripr", "1" )

FUNCTION select_o_kalk_pripr2()

   RETURN select_o_dbf( "KALK_PRIPR2", F_KALK_PRIPR9, "kalk_pripr2", "1" )


FUNCTION select_o_kalk_pripr9()

   RETURN select_o_dbf( "KALK_PRIPR9", F_KALK_PRIPR9, "kalk_pripr9", "1" )


FUNCTION o_kalk_kartica()

   RETURN o_dbf_table( F_KALK_DOKS, "kalk_kartica", "ID" )


FUNCTION o_finmat()

   RETURN o_dbf_table( F_FINMAT, "finmat", "1" )
