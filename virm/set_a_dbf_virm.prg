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



FUNCTION set_a_dbf_virm()

   LOCAL hAlg

   set_a_dbf_virm_jprih()

   set_a_sql_sifarnik( "vrprim", "VRPRIM", F_VRPRIM )
   set_a_sql_sifarnik( "ldvirm", "LDVIRM", F_LDVIRM )
   // set_a_dbf_sifarnik( "kalvir", "KALVIR", F_KALVIR )

   set_a_dbf_temp( "virm_pripr", "VIRM_PRIPR", F_VIPRIPR )
   set_a_dbf_temp( "izlaz", "IZLAZ", F_IZLAZ )

   RETURN .T.


STATIC FUNCTION set_a_dbf_virm_jprih()

   LOCAL hItem, hAlg, cTable

   cTable := "jprih"
   hItem := hb_Hash()

   hItem[ "table" ] := cTable
   hItem[ "alias" ] := "JPRIH"
   hItem[ "wa" ]    := F_JPRIH
   hItem[ "sql" ] := .T.
   hItem[ "temp" ]  := .F.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlg := hb_Hash()
   hAlg[ "dbf_key_block" ]  := {|| field->id + field->idops + field->idkan + field->idn0 + field->racun }
   hAlg[ "dbf_key_fields" ] := { "id", "idops", "idkan", "idn0", "racun" }
   hAlg[ "sql_in" ]         := " rpad(id, 6) || rpad(idops, 3) || rpad( idkan, 2 ) || rpad( idn0, 1 ) || rpad( racun, 16 ) "
   hAlg[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlg )

   hItem[ "sql_order" ] := "id, idops "

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.
