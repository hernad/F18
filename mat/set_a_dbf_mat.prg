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


FUNCTION set_a_dbf_mat()

   // kumulativne tabele
   set_a_dbf_mat_suban()
   set_a_dbf_mat_anal()
   set_a_dbf_mat_sint()
   set_a_dbf_mat_nalog()

   // sifarnici
   set_a_dbf_sifarnik( "mat_karkon", "KARKON", F_KARKON  )

   // temporary
   set_a_dbf_temp( "mat_pripr", "MAT_PRIPR",       F_MAT_PRIPR   )
   set_a_dbf_temp( "mat_invent", "MAT_INVENT",       F_MAT_INVENT   )
   set_a_dbf_temp( "mat_pnalog", "MAT_PNALOG",       F_MAT_PNALOG   )
   set_a_dbf_temp( "mat_psint", "MAT_PSINT",       F_MAT_PSINT   )
   set_a_dbf_temp( "mat_panal", "MAT_PANAL",       F_MAT_PANAL   )
   set_a_dbf_temp( "mat_psuban", "MAT_PSUBAN",       F_MAT_PSUBAN   )

   RETURN .T.



// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
FUNCTION set_a_dbf_mat_suban()

   LOCAL _alg, _tbl

   _tbl := "mat_suban"

   _item := hb_Hash()

   _item[ "alias" ] := "MAT_SUBAN"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_MAT_SUBAN

   // temporary tabela - nema semafora
   _item[ "temp" ]  := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal + field->rbr }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", "rbr" }
   _alg[ "sql_in" ]         := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4) || lpad(rbr, 4)"
   _alg[ "dbf_tag" ]        := "4"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4)"
   _alg[ "dbf_tag" ]    := "4"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
FUNCTION set_a_dbf_mat_anal()

   LOCAL _item
   LOCAL _alg, _tbl

   _tbl := "mat_anal"

   _item := hb_Hash()

   _item[ "alias" ] := "MAT_ANAL"
   _item[ "wa" ]    := F_MAT_ANAL
   _item[ "table" ] := _tbl
   // temporary tabela - nema semafora
   _item[ "temp" ]  := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal + field->rbr }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", "rbr" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4) || lpad(rbr, 4)"
   _alg[ "dbf_tag" ]   := "2"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4)"
   _alg[ "dbf_tag" ]    := "2"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
FUNCTION set_a_dbf_mat_sint()

   LOCAL _alg, _tbl, _item

   _tbl := "mat_sint"

   _item := hb_Hash()

   _item[ "alias" ] := "MAT_SINT"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_MAT_SINT

   // temporary tabela - nema semafora
   _item[ "temp" ]  := .F.


   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal + field->rbr }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", "rbr" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4) || lpad(rbr, 4)"
   _alg[ "dbf_tag" ]   := "2"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4)"
   _alg[ "dbf_tag" ]    := "2"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
FUNCTION set_a_dbf_mat_nalog()

   LOCAL _alg, _tbl
   LOCAL _itm

   _tbl := "mat_nalog"

   _item := hb_Hash()

   _item[ "alias" ] := "MAT_NALOG"
   _item[ "wa" ]    := F_MAT_NALOG
   _item[ "table" ] := _tbl

   // temporary tabela - nema semafora
   _item[ "temp" ]  := .F.


   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]         := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 4)"
   _alg[ "dbf_tag" ]        := "1"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "idfirma, idvn, brnal"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.
