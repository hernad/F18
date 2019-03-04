/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION set_a_dbf_fin()

   set_a_sql_fin_suban()
   set_a_sql_fin_anal()
   set_a_sql_fin_sint()
   set_a_sql_fin_nalog()

   set_a_sql_sifarnik( "fin_funk", "FUNK",       F_FUNK       )
   set_a_sql_sifarnik( "fin_fond", "FOND",       F_FOND       )

   set_a_sql_sifarnik( "ks", "KS",       F_KS         )

   set_a_dbf_temp( "fin_konto", "_KONTO",       F__KONTO   )
   set_a_dbf_temp( "fin_partn", "_PARTN",       F__PARTN   )
   set_a_dbf_temp( "fin_pripr", "FIN_PRIPR", F_FIN_PRIPR  )
   set_a_dbf_temp( "fin_psuban", "PSUBAN",       F_PSUBAN     )
   set_a_dbf_temp( "fin_panal", "PANAL",       F_PANAL      )
   set_a_dbf_temp( "fin_psint", "PSINT",       F_PSINT      )
   set_a_dbf_temp( "fin_pnalog", "PNALOG",       F_PNALOG     )

   set_a_dbf_temp( "fin_bbklas", "BBKLAS",       F_BBKLAS       )
   set_a_dbf_temp( "fin_ios", "IOS",       F_IOS    )
   set_a_dbf_temp( "fin_ostav", "OSTAV",       F_OSTAV     )
   set_a_dbf_temp( "fin_osuban", "OSUBAN",       F_OSUBAN    )
   set_a_dbf_temp( "fin_komp_dug", "KOMP_DUG",       F_FIN_KOMP_DUG     )
   set_a_dbf_temp( "fin_komp_pot", "KOMP_POT",       F_FIN_KOMP_POT     )
   set_a_dbf_temp( "kam_pripr", "KAM_PRIPR", F_KAMPRIPR  )
   set_a_dbf_temp( "kam_kamat", "KAM_KAMAT", F_KAMAT )

   RETURN .T.



FUNCTION set_a_sql_fin_suban()

   LOCAL _alg, _tbl, _item

   _tbl := "fin_suban"

   _item := hb_Hash()

   _item[ "alias" ] := "SUBAN"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_SUBAN
   _item[ "temp" ]  := .F.
   _item[ "algoritam" ] := {}
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .T.

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal + STR(field->rbr,5,0) }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", {"rbr",5} }
   _alg[ "sql_in" ]         := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8) || lpad(rbr::char(5),5)"
   _alg[ "dbf_tag" ]        := "4"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8)"
   _alg[ "dbf_tag" ]    := "4"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


FUNCTION set_a_sql_fin_anal()

   LOCAL _item
   LOCAL _alg, _tbl

   _tbl := "fin_anal"

   _item := hb_Hash()

   _item[ "alias" ] := "ANAL"
   _item[ "wa" ]    := F_ANAL
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .T.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal + field->rbr }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", "rbr" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8) || lpad(rbr, 3)"
   _alg[ "dbf_tag" ]   := "2"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8)"
   _alg[ "dbf_tag" ]    := "2"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.



FUNCTION set_a_sql_fin_sint()

   LOCAL _alg, _tbl, _item

   _tbl := "fin_sint"

   _item := hb_Hash()

   _item[ "alias" ] := "SINT"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_SINT
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .T.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal + field->rbr }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal", "rbr" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8) || lpad(rbr, 3)"
   _alg[ "dbf_tag" ]   := "2"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 2 - dokument
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]    := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8)"
   _alg[ "dbf_tag" ]    := "2"
   AAdd( _item[ "algoritam" ], _alg )

   // za full sinhronizaciju trebamo jedinstveni poredak
   _item[ "sql_order" ] := "idfirma, idvn, brnal, rbr"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.




FUNCTION set_a_sql_fin_nalog()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_nalog"

   _item := hb_Hash()

   _item[ "alias" ] := "NALOG"
   _item[ "wa" ]    := F_NALOG
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .T.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idfirma + field->idvn + field->brnal }
   _alg[ "dbf_key_fields" ] := { "idfirma", "idvn", "brnal" }
   _alg[ "sql_in" ]         := "rpad(idfirma,2) || rpad(idvn, 2) || rpad(brnal, 8)"
   _alg[ "dbf_tag" ]        := "1"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "idfirma, idvn, brnal"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


/*
FUNCTION set_a_dbf_fin_parek()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_parek"

   _item := hb_Hash()

   _item[ "alias" ] := "PAREK"
   _item[ "wa" ]    := F_PAREK
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idpartija }
   _alg[ "dbf_key_fields" ] := { "idpartija" }
   _alg[ "sql_in" ]         := "rpad(idpartija,6)"
   _alg[ "dbf_tag" ]        := "1"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "idpartija"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


FUNCTION set_a_dbf_fin_koliz()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_koliz"

   _item := hb_Hash()

   _item[ "alias" ] := "KOLIZ"
   _item[ "wa" ]    := F_KOLIZ
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->id }
   _alg[ "dbf_key_fields" ] := { "id" }
   _alg[ "sql_in" ]         := "rpad(id,2)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "id"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.



FUNCTION set_a_dbf_fin_koniz()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_koniz"

   _item := hb_Hash()

   _item[ "alias" ] := "KONIZ"
   _item[ "wa" ]    := F_KONIZ
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->id }
   _alg[ "dbf_key_fields" ] := { "id" }
   _alg[ "sql_in" ]         := "rpad(id,20)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "id"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.




FUNCTION set_a_dbf_fin_zagli()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_zagli"

   _item := hb_Hash()
   _item[ "alias" ] := "ZAGLI"
   _item[ "wa" ]    := F_ZAGLI
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->id }
   _alg[ "dbf_key_fields" ] := { "id" }
   _alg[ "sql_in" ]         := "rpad(id,2)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "id"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


FUNCTION set_a_dbf_fin_izvje()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_izvje"

   _item := hb_Hash()

   _item[ "alias" ] := "IZVJE"
   _item[ "wa" ]    := F_IZVJE
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->id }
   _alg[ "dbf_key_fields" ] := { "id" }
   _alg[ "sql_in" ]         := "rpad(id,2)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "id"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.


FUNCTION set_a_dbf_fin_budzet()

   LOCAL _alg, _tbl, _item
   LOCAL _itm

   _tbl := "fin_budzet"

   _item := hb_Hash()

   _item[ "alias" ] := "BUDZET"
   _item[ "wa" ]    := F_BUDZET
   _item[ "table" ] := _tbl
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "sql" ] := .F.

   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ] := {|| field->idrj + field->idkonto }
   _alg[ "dbf_key_fields" ] := { "idrj", "idkonto" }
   _alg[ "sql_in" ]         := "rpad( idrj, 6 ) || rpad( idkonto, 7 )"
   _alg[ "dbf_tag" ]        := "1"
   AAdd( _item[ "algoritam" ], _alg )

   _item[ "sql_order" ] := "idrj, idkonto"

   f18_dbfs_add( _tbl, @_item )

   RETURN .T.
*/
