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

FUNCTION set_a_dbf_kalk()

   set_a_sql_kalk_kalk()
   set_a_sql_kalk_doks( "kalk_doks", "KALK_DOKS", F_KALK_DOKS  )
   //set_a_sql_kalk_doks_doks2( "kalk_doks2", "KALK_DOKS2", F_KALK_DOKS2 )
   set_a_sql_trfp( "trfp", "TRFP", F_TRFP )
   set_a_sql_trfp( "trfp2", "TRFP2", F_TRFP2 )

  // set_a_sql_sifarnik( "trfp3", "TRFP3", F_TRFP3      )
   set_a_sql_sifarnik( "objekti", "OBJEKTI", F_OBJEKTI    )

   set_a_dbf_temp( "kalk_imp_temp", "KALK_IMP_TEMP", F_KALK_IMP_TEMP )
   set_a_dbf_temp( "_kalk_kalk", "_KALK", F__KALK        )
   set_a_dbf_temp( "kalk_pripr", "KALK_PRIPR", F_KALK_PRIPR   )
   set_a_dbf_temp( "kalk_pripr2", "KALK_PRIPR2", F_KALK_PRIPR2  )
   set_a_dbf_temp( "kalk_pripr9", "KALK_PRIPR9", F_KALK_PRIPR9  )
   set_a_dbf_temp( "kalk_pript", "PRIPT", F_PRIPT       )

   set_a_dbf_temp( "kalk_pormp", "PORMP", F_PORMP        )

   set_a_dbf_temp( "kalk_ppprod", "PPPROD", F_PPPROD        )
   set_a_dbf_temp( "prodaja", "PRODAJA", F_PRODAJA        )

   set_a_dbf_temp( "kalk_pobjekti", "POBJEKTI", F_POBJEKTI      )
   set_a_dbf_temp( "kalk_prodnc", "PRODNC", F_PRODNC        )
   set_a_dbf_temp( "kalk_rvrsta", "RVRSTA", F_RVRSTA        )
   set_a_dbf_temp( "cache", "CACHE", F_CACHE         )

   set_a_dbf_temp( "kalk_rekap1", "REKAP1", F_REKAP1        )
   set_a_dbf_temp( "kalk_rekap2", "REKAP2", F_REKAP2        )
   set_a_dbf_temp( "kalk_reka22", "REKA22", F_REKA22        )

   set_a_dbf_temp( "kalk_r_uio", "R_UIO", F_R_UIO         )
   set_a_dbf_temp( "kalk_rpt_tmp", "RPT_TMP", F_RPT_TMP       )

   set_a_dbf_temp( "kalk_kartica", "KALK_KARTICA", F_KALK_KARTICA )

   set_a_dbf_temp( "topska", "TOPSKA", F_TMP_TOPSKA )
   set_a_dbf_temp( "katops", "KATOPS", F_TMP_KATOPS )

   RETURN .T.



FUNCTION set_a_sql_kalk_kalk()

   LOCAL hItem, hAlg, _tbl

   _tbl := "kalk_kalk"
   hItem := hb_Hash()

   hItem[ "alias" ] := "KALK"
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := F_KALK
   hItem[ "temp" ]  := .F.
   hItem[ "sif" ] := .F.
   hItem[ "sql" ] := .T.
   // hItem[ "sql" ] := .T.  BUG_CPU100
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // t_kalk_db.prg
   // -------------------------------------------------------------------------------
   hAlg := hb_Hash()
   hAlg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvd + field->brdok + STR(field->rbr,5,0) }
   hAlg[ "dbf_key_empty_rec" ] := SPACE( 2 ) + SPACE( 2 ) + SPACE( FIELD_LEN_KALK_BRDOK ) + SPACE( FIELD_LEN_KALK_RBR )
   hAlg[ "dbf_key_fields" ] := { "idfirma", "idvd", "brdok", {"rbr",5} }
   hAlg[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idvd,2)  || rpad(brdok,8) || lpad(rbr::char(5),5)"
   hAlg[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlg )


   // algoritam 2
   // -------------------------------------------------------------------------------
   hAlg := hb_Hash()
   hAlg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvd + field->brdok }
   hAlg[ "dbf_key_fields" ] := { "idfirma", "idvd", "brdok" }
   hAlg[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idvd,2)  || rpad(brdok,8)"
   hAlg[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlg )

   hItem[ "sql_order" ] := "idfirma, idvd, brdok, rbr"

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.


FUNCTION set_a_sql_kalk_doks( table, alias, wa )

   LOCAL hItem, hAlg, _tbl

   _tbl := table
   hItem := hb_Hash()
   hItem[ "alias" ] := alias
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := wa
   hItem[ "temp" ]  := .F.
   hItem[ "sif" ] := .F.
   hItem[ "sql" ] := .T.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // t_kalk_db.prg
   // -------------------------------------------------------------------------------
   hAlg := hb_Hash()
   hAlg[ "dbf_key_block" ]  := {|| field->idfirma + field->idvd + field->brdok }
   hAlg[ "dbf_key_empty_rec" ] := SPACE( 2 ) + SPACE( 2 ) + SPACE( FIELD_LEN_KALK_BRDOK )
   hAlg[ "dbf_key_fields" ] := { "idfirma", "idvd", "brdok" }
   hAlg[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idvd,2)  || rpad(brdok,8)"
   hAlg[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlg )
   hItem[ "sql_order" ] := "idfirma, idvd, brdok"
   hItem[ "blacklisted" ] := { "obradjeno", "korisnik" } // polja obradjen i korisnik su autogenerisana na serverskoj strani


   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.


FUNCTION set_a_sql_trfp( table, alias, wa )

   LOCAL hItem, hAlg, _tbl

   _tbl := table

   hItem := hb_Hash()
   hItem[ "alias" ] := alias
   hItem[ "table" ] := _tbl
   hItem[ "wa" ]    := wa
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.
   hItem[ "sif" ] := .F.
   hItem[ "chk0" ] := .F.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlg := hb_Hash()
   hAlg[ "dbf_key_block" ]  := {|| field->idvd + field->shema + field->idkonto + field->id + field->idtarifa + field->idvn + field->naz }
   hAlg[ "dbf_key_fields" ] := { "idvd", "shema", "idkonto", "id", "idtarifa", "idvn", "naz" }
   hAlg[ "sql_in" ]         := " rpad( idvd,2) || rpad( shema,1)  || rpad(idkonto,8) || rpad(id,60) || rpad(idtarifa,6) || rpad(idvn,2) || rpad(naz,20) "
   hAlg[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlg )

   hItem[ "sql_order" ] := "idvd, shema, idkonto, id, idtarifa"

   f18_dbfs_add( _tbl, @hItem )

   RETURN .T.
