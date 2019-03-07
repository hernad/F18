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



FUNCTION set_a_dbf_pos()

   set_a_dbf_pos_pos()
   set_a_dbf_pos_doks()


   // tabele sa strukturom sifarnika (id je primarni ključ)
   set_a_sql_sifarnik( "pos_strad", "STRAD", F_STRAD   )
   set_a_sql_sifarnik( "pos_osob", "OSOB", F_OSOB   )
   set_a_sql_sifarnik( "pos_kase", "KASE", F_KASE  )

   set_a_dbf_temp( "_pos_pripr",   "_POS_PRIPR", F__PRIPR  )
   set_a_dbf_temp( "pos_priprz",   "PRIPRZ", F_PRIPRZ  )

   RETURN .T.



FUNCTION set_a_dbf_pos_pos()

   LOCAL hItem, hAlgoritam, cTabela

   cTabela := "pos_pos"

   hItem := hb_Hash()

   hItem[ "alias" ] := "POS"
   hItem[ "table" ] := cTabela
   hItem[ "wa" ]    := F_POS
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   hItem[ "algoritam" ] := {}


   // algoritam 1 - default
   // CREATE_INDEX ("IDS_SEM", "IdPos+IdVd+dtos(datum)+BrDok+rbr", _alias )
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idpos + field->idvd + DToS( field->datum ) + field->brdok + STR(field->rbr,5,0) }
   hAlgoritam[ "dbf_key_empty_rec" ] := Space( 2 ) + Space( 2 ) + DToS( CToD( "" ) ) + Space( FIELD_LEN_POS_BRDOK ) + Space( FIELD_LEN_POS_RBR )

   hAlgoritam[ "dbf_key_fields" ] := { "idpos", "idvd", "datum", "brdok", {"rbr",5} }
   hAlgoritam[ "sql_in" ]         := "rpad( idpos,2) || rpad( idvd,2)  || to_char(datum, 'YYYYMMDD') || rpad(brdok," + AllTrim( Str( FIELD_LEN_POS_BRDOK ) ) + ") || lpad(rbr::char(5),5)"
   hAlgoritam[ "dbf_tag" ]        := "IDS_SEM"
   AAdd( hItem[ "algoritam" ], hAlgoritam )


   // algoritam 2 - dokument
   // CREATE_INDEX ("1", "IdPos+IdVd+dtos(datum)+BrDok+idroba", _alias )
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idpos + field->idvd + DToS( field->datum ) + field->brdok }
   hAlgoritam[ "dbf_key_fields" ] := { "idpos", "idvd", "datum", "brdok" }
   hAlgoritam[ "sql_in" ]    := "rpad(idpos,2) || rpad(idvd, 2) || to_char(datum, 'YYYYMMDD') || rpad(brdok, " + AllTrim( Str( FIELD_LEN_POS_BRDOK ) ) + ")"
   hAlgoritam[ "dbf_tag" ]    := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "idpos, idvd, datum, brdok, rbr"

   f18_dbfs_add( cTabela, @hItem )

   RETURN .T.



FUNCTION set_a_dbf_pos_doks()

   LOCAL hItem, hAlgoritam, cTabela

   cTabela := "pos_doks"

   hItem := hb_Hash()

   hItem[ "alias" ] := "POS_DOKS"
   hItem[ "table" ] := cTabela
   hItem[ "wa" ]    := F_POS_DOKS
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   hItem[ "algoritam" ] := {}

   // CREATE_INDEX ("1", "IdPos+IdVd+dtos(datum)+BrDok", _alias )

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idpos + field->idvd + DToS( field->datum ) + field->brdok }
   hAlgoritam[ "dbf_key_empty_rec" ] := Space( 2 ) + Space( 2 ) + DToS( CToD( "" ) ) + Space( FIELD_LEN_POS_BRDOK )

   hAlgoritam[ "dbf_key_fields" ] := { "idpos", "idvd", "datum", "brdok" }
   hAlgoritam[ "sql_in" ]         := "rpad( idpos,2) || rpad( idvd,2)  || to_char(datum, 'YYYYMMDD') || rpad(brdok," + AllTrim( Str( FIELD_LEN_POS_BRDOK ) ) + ")"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "idpos, idvd, datum, brdok"

   f18_dbfs_add( cTabela, @hItem )

   RETURN .T.





/*
FUNCTION set_a_dbf_pos_dokspf()

   LOCAL hItem, hAlgoritam, cTabela

   cTabela := "pos_dokspf"

   hItem := hb_Hash()

   hItem[ "alias" ] := "DOKSPF"
   hItem[ "table" ] := cTabela
   hItem[ "wa" ]    := F_DOKSPF
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // CREATE_INDEX( "1", "idpos+idvd+DToS(datum)+brdok", _alias )
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idpos + field->idvd + DToS( field->datum ) + field->brdok }
   hAlgoritam[ "dbf_key_fields" ] := { "idpos", "idvd", "datum", "brdok" }
   hAlgoritam[ "sql_in" ]         := "rpad( idpos,2) || rpad( idvd,2)  || to_char(datum, 'YYYYMMDD') || rpad(brdok," + AllTrim( Str( FIELD_LEN_POS_BRDOK ) ) + ")"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2
   // CREATE_INDEX( "2", "knaz", _alias )
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->knaz }
   hAlgoritam[ "dbf_key_fields" ] := { "knaz" }
   hAlgoritam[ "sql_in" ]         := "rpad( knaz, 35 )"
   hAlgoritam[ "dbf_tag" ]        := "2"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "idpos, idvd, datum, brdok"

   f18_dbfs_add( cTabela, @hItem )

   RETURN .T.
*/
