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


FUNCTION set_a_dbf_epdv()

   set_a_sql_epdv_pdv()

   // kuf i kif su tabele identične strukture
   set_a_sql_epdv_kuf_kif( "epdv_kuf", "KUF", F_KUF )
   set_a_sql_epdv_kuf_kif( "epdv_kif", "KIF", F_KIF )


   set_a_sql_sifarnik( "epdv_sg_kif", "SG_KIF", F_SG_KIF )
   set_a_sql_sifarnik( "epdv_sg_kuf", "SG_KUF", F_SG_KUF )

   // temp epdv tabele - ne idu na server
   set_a_dbf_temp( "epdv_p_kif", "P_KIF", F_P_KIF )
   set_a_dbf_temp( "epdv_p_kuf", "P_KUF", F_P_KUF )
   set_a_dbf_temp( "epdv_r_kuf", "R_KUF", F_R_KUF )
   set_a_dbf_temp( "epdv_r_kif", "R_KIF", F_R_KIF )
   set_a_dbf_temp( "epdv_r_pdv", "R_PDV", F_R_PDV )

   RETURN .T.



FUNCTION set_a_sql_epdv_pdv()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "epdv_pdv"

   hItem := hb_Hash()

   hItem[ "alias" ] := "PDV"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_PDV
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ]  := .T.
   hItem[ "sif" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| DToS( field->per_od ) + DToS( field->per_do ) }
   hAlgoritam[ "dbf_key_fields" ] := { "per_od", "per_do" }
   hAlgoritam[ "sql_in" ]         := "to_char(per_od, 'YYYYMMDD') || to_char(per_do, 'YYYYMMDD')"
   hAlgoritam[ "dbf_tag" ]        := "PERIOD"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "per_od, per_do"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.


FUNCTION set_a_sql_epdv_kuf_kif( cTable, cAlias, nWa )

   LOCAL hItem, hAlgoritam


   hItem := hb_Hash()

   hItem[ "alias" ] := cAlias
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := nWa
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ]  := .T.
   hItem[ "sif" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| Str( field->br_dok, 6 ) + Str( field->r_br, 6 ) }
   hAlgoritam[ "dbf_key_fields" ] := { { "br_dok", 6 }, { "r_br", 6 } }
   hAlgoritam[ "sql_in" ]         := "lpad(br_dok::char(6), 6) || lpad(r_br::char(6),6)"
   hAlgoritam[ "dbf_tag" ]        := "BR_DOK"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2 - povrat dokumenta
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| Str( field->br_dok, 6 ) }
   hAlgoritam[ "dbf_key_fields" ] := { { "br_dok", 6 } }
   hAlgoritam[ "sql_in" ]         := "lpad( br_dok::char(6), 6 )"
   hAlgoritam[ "dbf_tag" ]        := "BR_DOK"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "br_dok, r_br, datum"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.
