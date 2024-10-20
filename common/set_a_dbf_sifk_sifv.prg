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

FUNCTION set_a_dbf_sifk_sifv()

   set_a_dbf_sifk()
   set_a_dbf_sifv()

   RETURN .T.



FUNCTION set_a_dbf_sifk()

   LOCAL _alg, _tbl, _item

   _tbl := "sifk"

   _item := hb_Hash()

   _item[ "alias" ] := "SIFK"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_SIFK
   _item[ "sql" ]   := .T.
   _item[ "temp" ]  := .F.
   _item[ "sif" ] := .T.
   _item[ "chk0" ]  := .F.
   _item[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->id + field->oznaka }
   _alg[ "dbf_key_fields" ] := { "id", "oznaka" }
   _alg[ "sql_in" ]        := "rpad(id,8) || rpad(oznaka,4)"
   // "2", "idradn + idkred + naosnovu + str(godina) + str(mjesec)"
   _alg[ "dbf_tag" ]        := "ID2"
   AAdd( _item[ "algoritam" ], _alg )

   f18_dbfs_add( _tbl, @_item )



FUNCTION set_a_dbf_sifv()

   LOCAL _alg, _tbl, _item

   _tbl := "sifv"

   _item := hb_Hash()

   _item[ "alias" ] := "SIFV"
   _item[ "table" ] := _tbl
   _item[ "wa" ]    := F_SIFV
   _item[ "sql" ]   := .T.
   _item[ "chk0" ]  := .F.
   _item[ "sif" ] := .F.
   _item[ "temp" ]  := .F.
   _item[ "algoritam" ] := {}


   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->id + field->oznaka + field->idsif + field->naz }
   _alg[ "dbf_key_fields" ] := { "id", "oznaka", "idsif", "naz" }
   _alg[ "sql_in" ]        := "rpad(id,8) || rpad(oznaka,4) || rpad(idsif,15) || rpad(naz,50)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )

   // algoritam 2 - brisi sve stavke sa kljucem id + oznaka + idsif
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->id + field->oznaka + field->idsif }
   _alg[ "dbf_key_fields" ] := { "id", "oznaka", "idsif" }
   _alg[ "sql_in" ]        := "rpad(id,8) || rpad(oznaka,4) || rpad(idsif,15)"
   _alg[ "dbf_tag" ]        := "ID"
   AAdd( _item[ "algoritam" ], _alg )


   // algoritam 3 - brisi sve stavke sa kljucem id + oznaka + idsif
   // -------------------------------------------------------------------------------
   _alg := hb_Hash()
   _alg[ "dbf_key_block" ]  := {|| field->id + field->idsif }
   _alg[ "dbf_key_fields" ] := { "id", "idsif" }
   _alg[ "sql_in" ]        := "rpad(id,8) || rpad(idsif,15)"
   _alg[ "dbf_tag" ]        := "IDIDSIF"
   AAdd( _item[ "algoritam" ], _alg )


   f18_dbfs_add( _tbl, @_item )

   RETURN .T.
