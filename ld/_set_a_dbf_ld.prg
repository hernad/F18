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


FUNCTION set_a_dbf_ld_sif()

   set_a_sql_sifarnik( "ld_rj", "LD_RJ", F_LD_RJ      )
   set_a_sql_sifarnik( "por", "POR", F_POR        )

   set_a_sql_sifarnik( "tippr", "TIPPR", F_TIPPR      )
   set_a_sql_sifarnik( "tippr2", "TIPPR2", F_TIPPR2     )
   set_a_sql_sifarnik( "kred", "KRED", F_KRED       )

   set_a_sql_sifarnik( "strspr", "STRSPR", F_STRSPR     )

   set_a_sql_sifarnik( "vposla", "VPOSLA", F_VPOSLA     )
   set_a_sql_sifarnik( "kbenef", "KBENEF", F_KBENEF     )

   RETURN .T.


FUNCTION set_a_dbf_ld()

   set_a_dbf_ld_ld()
   set_a_dbf_ld_parobr()
   set_a_dbf_ld_dopr()
   set_a_dbf_ld_radkr()
   set_a_dbf_ld_obracuni()
   //set_a_dbf_ld_pk_data()
   //set_a_dbf_ld_pk_radn()

   set_a_dbf_ld_radsat()
   set_a_dbf_ld_radsiht()

   set_a_dbf_ld_radn()

   set_a_dbf_temp( "_ld_radkr", "_RADKR", F__RADKR  )
   set_a_dbf_temp( "_ld_ld", "_LD", F__LD     )
   set_a_dbf_temp( "_ld_radn", "_RADN", F__RADN   )
   set_a_dbf_temp( "_ld_kred", "_KRED", F__KRED   )
   set_a_dbf_temp( "ld_ldsm", "LDSM", F_LDSM    )
   set_a_dbf_temp( "ld_opsld", "OPSLD", F_OPSLD   )
   set_a_dbf_temp( "ld_rekld", "REKLD", F_REKLD   )
   set_a_dbf_temp( "ld_rekldp", "REKLDP", F_REKLDP   )
   set_a_dbf_temp( "ldt22", "LDT22", F_LDT22    )
   set_a_dbf_temp( "exp_bank", "EXP_BANK", F_EXP_BANK  )
   set_a_dbf_temp( "_tmp", "_TMP", F__TMP  )

   set_a_sql_sifarnik( "ld_norsiht", "NORSIHT", F_NORSIHT   )
   set_a_sql_sifarnik( "ld_tprsiht", "TPRSIHT", F_TPRSIHT   )

   RETURN .T.


FUNCTION set_a_dbf_ld_ld()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_ld"

   hItem := hb_Hash()

   hItem[ "alias" ] := "LD"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_LD
   hItem[ "temp" ]  := .F.
   hItem[ "sif" ] := .F.
   hItem[ "sql" ] := .T.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| Str( field->godina, 4, 0 ) + field->idrj + Str( field->mjesec, 2, 0 ) + field->obr + field->idradn }
   hAlgoritam[ "dbf_key_empty_rec" ] := Str( 0, 4, 0 ) + Space( 2 ) + Str( 0, 2, 0 ) + " " + Space( 6 )
   hAlgoritam[ "dbf_key_fields" ] := { { "godina", 4 }, "idrj", { "mjesec", 2 }, "obr", "idradn" }
   hAlgoritam[ "sql_in" ]         := "lpad(godina::char(4), 4) || rpad(idrj, 2) || lpad(mjesec::char(2),2) || rpad(obr,1) || rpad(idradn,6)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2 - brisanje
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| Str( field->godina, 4, 0) + field->idrj + Str( field->mjesec, 2, 0 ) + field->obr }
   hAlgoritam[ "dbf_key_fields" ] := { { "godina", 4 }, "idrj", { "mjesec", 2 }, "obr" }
   hAlgoritam[ "sql_in" ]         := "lpad(godina::char(4), 4) || rpad(idrj, 2) || lpad(mjesec::char(2),2) || rpad(obr,1)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "godina, idrj, mjesec, obr"

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.


FUNCTION set_a_dbf_ld_radn()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_radn"

   hItem := hb_Hash()

   hItem[ "alias" ] := "RADN"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_RADN
   hItem[ "temp" ]  := .F.
   hItem[ "algoritam" ] := {}
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .T.

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->id }
   hAlgoritam[ "dbf_key_fields" ] := { "id" }
   hAlgoritam[ "sql_in" ]         := "rpad(id, 6)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_ld_parobr()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_parobr"
   hItem := hb_Hash()

   hItem[ "alias" ] := "PAROBR"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_PAROBR
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->id + field->godina + field->obr }
   hAlgoritam[ "dbf_key_fields" ] := { "id", "godina", "obr" }
   hAlgoritam[ "sql_in" ]         := "rpad(id, 2) || rpad(godina, 4) || rpad(obr, 1)"
   hAlgoritam[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_ld_dopr()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "dopr"

   hItem := hb_Hash()

   hItem[ "alias" ] := "DOPR"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_DOPR
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->id + field->naz + field->tiprada }
   hAlgoritam[ "dbf_key_fields" ] := { "id", "naz", "tiprada" }
   hAlgoritam[ "sql_in" ]         := "rpad(id, 2) || rpad(naz, 20) || rpad(tiprada, 1)"
   hAlgoritam[ "dbf_tag" ]        := "1"

   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.




FUNCTION set_a_dbf_ld_obracuni()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_obracuni"

   hItem := hb_Hash()

   hItem[ "alias" ] := "LD_OBRACUNI"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_LD_OBRACUNI
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->rj + Str( field->godina, 4, 0 ) + Str( field->mjesec, 2, 0 ) + field->status + field->obr }
   hAlgoritam[ "dbf_key_fields" ] := { "rj", { "godina", 4 }, { "mjesec", 2 }, "status", "obr" }
   hAlgoritam[ "sql_in" ]         := "rpad(rj, 2) || lpad(godina::char(4),4) || lpad(mjesec::char(2),2) || rpad(status, 1) || rpad(obr, 1)"
   hAlgoritam[ "dbf_tag" ]        := "RJ"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.

/*
FUNCTION set_a_dbf_ld_pk_radn()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_pk_radn"

   hItem := hb_Hash()

   hItem[ "alias" ] := "PK_RADN"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_PK_RADN
   hItem[ "sql" ] := .F.
   hItem[ "sif" ] := .F.

   hItem[ "temp" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn" }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn, 6)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_ld_pk_data()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_pk_data"

   hItem := hb_Hash()

   hItem[ "alias" ] := "PK_DATA"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_PK_DATA
   hItem[ "sql" ] := .F.
   hItem[ "sif" ] := .F.

   hItem[ "temp" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn + field->ident + Str( field->rbr, 2 ) }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn", "ident", { "rbr", 2 } }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn, 6) || rpad(ident, 1) || lpad(rbr::char(2),2)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2 - brisanje podataka
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn" }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn, 6)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.
*/

FUNCTION set_a_dbf_ld_radsat()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_radsat"

   hItem := hb_Hash()

   hItem[ "alias" ] := "RADSAT"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_RADSAT
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   hItem[ "temp" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn" }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn, 6)"
   hAlgoritam[ "dbf_tag" ]        := "IDRADN"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_ld_radsiht()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_radsiht"

   hItem := hb_Hash()

   hItem[ "alias" ] := "RADSIHT"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_RADSIHT
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idkonto + Str( field->godina, 4 ) + Str( field->mjesec, 2 ) + field->idradn }
   hAlgoritam[ "dbf_key_fields" ] := { "idkonto", { "godina", 4 }, { "mjesec", 2 }, "idradn" }
   hAlgoritam[ "sql_in" ]         := "rpad(idkonto, 7) || lpad(godina::char(4),4) || lpad(mjesec::char(2),2) || rpad(idradn, 6)"
   hAlgoritam[ "dbf_tag" ]        := "2"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_ld_radkr()

   LOCAL hAlgoritam, _tbl, hItem

   _tbl := "ld_radkr"

   hItem := hb_Hash()

   hItem[ "alias" ] := "RADKR"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_RADKR
   hItem[ "temp" ]  := .F.
   hItem[ "algoritam" ] := {}
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   // algoritam 1
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn + field->idkred + field->naosnovu + Str( field->godina, 4, 0 ) + Str( field->mjesec, 2, 0 ) }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn", "idkred", "naosnovu", { "godina", 4 }, { "mjesec", 2 } }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn,6) || rpad(idkred,6) || rpad(naosnovu, 20) || lpad(godina::char(4),4) || lpad(mjesec::char(2),2)"
   hAlgoritam[ "dbf_tag" ]        := "2"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idradn + field->idkred + field->naosnovu }
   hAlgoritam[ "dbf_key_fields" ] := { "idradn", "idkred", "naosnovu" }
   hAlgoritam[ "sql_in" ]         := "rpad(idradn,6) || rpad(idkred,6) || rpad(naosnovu, 20) "
   hAlgoritam[ "dbf_tag" ]        := "2"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.
