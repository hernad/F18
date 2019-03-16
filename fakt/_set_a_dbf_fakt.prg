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


FUNCTION set_a_dbf_fakt()

   set_a_dbf_fakt_fakt()
   set_a_fakt_doks_doks2( "fakt_doks", "FAKT_DOKS", F_FAKT_DOKS )
   set_a_fakt_doks_doks2( "fakt_doks2", "FAKT_DOKS2", F_FAKT_DOKS2 )
   set_a_sql_fakt_ugov()
   set_a_sql_fakt_rugov()
   set_a_sql_fakt_dest()
   set_a_sql_fakt_gen_ug()
   set_a_sql_fakt_gen_ug_p()

   set_a_sql_sifarnik( "fakt_ftxt", "FAKT_FTXT", F_FAKT_FTXT   )

   set_a_dbf_temp( "fakt_kalpos",  "KALPOS", F_KALPOS  )
   set_a_dbf_temp( "fakt_pripr",   "FAKT_PRIPR", F_FAKT_PRIPR   )
   set_a_dbf_temp( "fakt_pripr2",  "FAKT_PRIPR2", F_FAKT_PRIPR2  )
   set_a_dbf_temp( "fakt_pripr9",  "FAKT_PRIPR9", F_FAKT_PRIPR9  )
   set_a_dbf_temp( "fakt_pormp",   "PORMP", F_PORMP )
   set_a_dbf_temp( "_fakt_partn",   "_PARTN", F__PARTN  )
   set_a_dbf_temp( "fakt_logk",   "LOGK", F_LOGK    )
   set_a_dbf_temp( "fakt_logkd",   "LOGKD", F_LOGKD   )
   set_a_dbf_temp( "fakt_upl",   "UPL", F_UPL     )
   set_a_dbf_temp( "fakt__fakt",   "_FAKT", F__FAKT   )
   set_a_dbf_temp( "fakt_attr", "FAKT_ATTR", F_FAKT_ATTR )
   set_a_dbf_temp( "labelu", "LABELU", F_LABELU )
   set_a_dbf_temp( "lab2",   "LAB2",   F_LABELU2 )

   // tabele razmjene podataka udaljene lokacije
   set_a_dbf_temp( "e_doks", "E_DOKS", F_TMP_E_DOKS )
   set_a_dbf_temp( "e_doks2", "E_DOKS2", F_TMP_E_DOKS2 )
   set_a_dbf_temp( "e_fakt", "E_FAKT", F_TMP_E_FAKT )
   set_a_dbf_temp( "e_kalk", "E_KALK", F_TMP_E_KALK )
   set_a_dbf_temp( "e_suban", "E_SUBAN", F_TMP_E_SUBAN )
   set_a_dbf_temp( "e_sint", "E_SINT", F_TMP_E_SINT )
   set_a_dbf_temp( "e_nalog", "E_NALOG", F_TMP_E_NALOG )
   set_a_dbf_temp( "e_anal", "E_ANAL", F_TMP_E_ANAL )
   set_a_dbf_temp( "e_roba", "E_ROBA", F_TMP_E_ROBA )
   set_a_dbf_temp( "e_konto", "E_KONTO", F_TMP_E_KONTO )
   set_a_dbf_temp( "e_partn", "E_PARTN", F_TMP_E_PARTN )
   set_a_dbf_temp( "e_sifk", "E_SIFK", F_TMP_E_SIFK )
   set_a_dbf_temp( "e_sifv", "E_SIFV", F_TMP_E_SIFV )

   RETURN .T.



FUNCTION set_a_sql_fakt_ugov()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "fakt_ugov"
   hItem := hb_Hash()
   hItem[ "alias" ] := "UGOV"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_UGOV
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()

   hAlgoritam[ "dbf_key_block" ]  := {|| field->id + field->idpartner }
   hAlgoritam[ "dbf_key_fields" ] := { "id", "idpartner" }
   hAlgoritam[ "sql_in" ]         := "rpad(id,10) || rpad(idpartner,6)"
   hAlgoritam[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "id, idpartner"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.


FUNCTION set_a_sql_fakt_rugov()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "fakt_rugov"

   hItem := hb_Hash()

   hItem[ "alias" ] := "RUGOV"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_RUGOV
   hItem[ "sql" ] := .T.
   hItem[ "temp" ]  := .F.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()

   // funkcija a_rugov() definise dbf polja
   hAlgoritam[ "dbf_key_block" ]  := {|| field->id + field->idroba + field->dest }
   hAlgoritam[ "dbf_key_fields" ] := { "id", "idroba", "dest" }
   hAlgoritam[ "sql_in" ]         := "rpad(id,10) || rpad(idroba,10) || rpad(dest,6)"
   hAlgoritam[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlgoritam )
   hItem[ "sql_order" ] := "id, idroba, dest"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.



FUNCTION set_a_sql_fakt_dest()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "dest"
   hItem := hb_Hash()

   hItem[ "alias" ] := "DEST"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_DEST
   hItem[ "sql" ] := .T.
   hItem[ "temp" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()

   // funkcija a_dest() definise dbf polja
   hAlgoritam[ "dbf_key_block" ]  := {|| field->id + field->idpartner }
   hAlgoritam[ "dbf_key_fields" ] := { "id", "idpartner" }
   hAlgoritam[ "sql_in" ]         := "rpad(id,6) || rpad(idpartner,6)"
   hAlgoritam[ "dbf_tag" ]        := "ID"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "id, idpartner"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.


FUNCTION set_a_sql_fakt_gen_ug()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "fakt_gen_ug"

   hItem := hb_Hash()

   hItem[ "alias" ] := "GEN_UG"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_GEN_UG
   hItem[ "sql" ] := .T.
   hItem[ "temp" ]  := .F.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()

   // funkcija a_genug() definise dbf polja

   hAlgoritam[ "dbf_key_block" ]  := {|| DToS( field->dat_obr ) }
   hAlgoritam[ "dbf_key_fields" ] := { "dat_obr" }
   hAlgoritam[ "sql_in" ]         := "to_char(dat_obr, 'YYYYMMDD')"
   hAlgoritam[ "dbf_tag" ]        := "DAT_OBR"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "dat_obr"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.



FUNCTION set_a_sql_fakt_gen_ug_p()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "fakt_gen_ug_p"

   hItem := hb_Hash()

   hItem[ "alias" ] := "GEN_UG_P"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_G_UG_P
   hItem[ "sql" ] := .T.
   hItem[ "temp" ]  := .F.
   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| DToS( field->dat_obr ) + id_ugov + idpartner }
   hAlgoritam[ "dbf_key_fields" ] := { "dat_obr", "id_ugov", "idpartner" }
   hAlgoritam[ "sql_in" ]         := "to_char(dat_obr, 'YYYYMMDD') || rpad(id_ugov,10) || rpad(idpartner,6)"

   // CREATE_INDEX("DAT_OBR","DTOS(DAT_OBR)+ID_UGOV+IDPARTNER", "GEN_UG_P")
   hAlgoritam[ "dbf_tag" ]        := "DAT_OBR"

   AAdd( hItem[ "algoritam" ], hAlgoritam )
   hItem[ "sql_order" ] := "dat_obr, id_ugov, idpartner"

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.




FUNCTION set_a_dbf_fakt_fakt()

   LOCAL hItem, hAlgoritam, cTable

   cTable := "fakt_fakt"

   hItem := hb_Hash()
   hItem[ "alias" ] := "FAKT"
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := F_FAKT
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idfirma + field->idtipdok + field->brdok + field->rbr }
   hAlgoritam[ "dbf_key_fields" ] := { "idfirma", "idtipdok", "brdok", "rbr" }
   hAlgoritam[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idtipdok,2)  || rpad(brdok,8) || lpad(rbr,3)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   // algoritam 2 - nivo dokumenta
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idfirma + field->idtipdok + field->brdok }
   hAlgoritam[ "dbf_key_fields" ] := { "idfirma", "idtipdok", "brdok" }
   hAlgoritam[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idtipdok,2)  || rpad(brdok,8)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "idfirma, idtipdok, brdok, rbr"
   hItem[ "blacklisted" ] := { "fisc_rn", "dok_veza", "opis", "brisano" } // fisc_rn se ne nalazi u fakt, nego u fakt_doks

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.



FUNCTION set_a_fakt_doks_doks2( cTabela, cAlias, nWa )

   LOCAL hItem, hAlgoritam, cTable

   cTable := cTabela
   hItem := hb_Hash()

   hItem[ "alias" ] := cAlias
   hItem[ "table" ] := cTable
   hItem[ "wa" ]    := nWa
   hItem[ "temp" ]  := .F.
   hItem[ "sql" ] := .T.

   hItem[ "algoritam" ] := {}

   // algoritam 1 - default
   // -------------------------------------------------------------------------------
   hAlgoritam := hb_Hash()
   hAlgoritam[ "dbf_key_block" ]  := {|| field->idfirma + field->idtipdok + field->brdok }
   hAlgoritam[ "dbf_key_fields" ] := { "idfirma", "idtipdok", "brdok" }
   hAlgoritam[ "sql_in" ]         := "rpad( idfirma,2) || rpad( idtipdok,2)  || rpad(brdok,8)"
   hAlgoritam[ "dbf_tag" ]        := "1"
   AAdd( hItem[ "algoritam" ], hAlgoritam )

   hItem[ "sql_order" ] := "idfirma, idtipdok, brdok"
   hItem[ "blacklisted" ] := { "dok_veza", "brisano", "obradjeno", "korisnik", "sifra" } // polja obradjen i korisnik su autogenerisana na serverskoj strani
   // polje sifra izbaciti

   f18_dbfs_add( cTable, @hItem )

   RETURN .T.
