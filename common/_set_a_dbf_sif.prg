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

FUNCTION set_a_dbf_sif()

   LOCAL hRec

   set_a_sql_sifarnik( "adres", "ADRES", F_ADRES    )

   set_a_sql_sifarnik( "roba", "ROBA", F_ROBA    )

   /*
      ROBA_P - alias tabele roba koji se koristi u sastavnicama

      roba _p hack se koristi u ovoj sekvenci kod dbf update server:
      IF " _p" $ cTabela  // HACK "roba _p"
        cTabela := StrTran( cTabela, " _p", "" )
       ENDIF
   */
   set_a_sql_sifarnik( "roba _p", "ROBA_P", F_ROBA_P   )

   set_a_sql_sifarnik( "konto", "KONTO", F_KONTO      )
   set_a_sql_sifarnik( "partn", "PARTN", F_PARTN    )

   hRec := hb_Hash()
   hRec[ "dbf_key_fields" ] := { "id", "id2" }
   hRec[ "dbf_tag" ]        := "ID"
   hRec[ "sql_in" ]        := "rpad( id, 10 ) || rpad(id2, 10)"
   hRec[ "dbf_key_block" ] := {|| field->id + field->id2 }
   set_a_sql_sifarnik( "sast", "SAST", F_SAST, hRec  )

   hRec := hb_Hash()
   hRec[ "dbf_key_fields" ] := { { "rule_id", 10, 0 } }
   hRec[ "dbf_tag" ]        := "1"
   hRec[ "sql" ]            := .T.
   hRec[ "sql_in" ]        := "rpad(rule_id::char(10),10)"
   hRec[ "dbf_key_block" ] := {|| Str( field->rule_id, 10, 0 ) }

   set_a_sql_sifarnik( "f18_rules", "FMKRULES", F_RULES, hRec  )
   set_a_sql_sifarnik( "rj", "RJ", F_RJ         )
   set_a_sql_sifarnik( "lokal", "LOKAL", F_LOKAL  )
   set_a_sql_sifarnik( "ops", "OPS", F_OPS        )
   set_a_sql_sifarnik( "banke", "BANKE", F_BANKE      )
   set_a_sql_sifarnik( "refer", "REFER", F_REFER      )
   set_a_sql_sifarnik( "tnal", "TNAL", F_TNAL       )
   set_a_sql_sifarnik( "tdok", "TDOK", F_TDOK       )
   set_a_sql_sifarnik( "tarifa", "TARIFA", F_TARIFA     )
   set_a_sql_sifarnik( "koncij", "KONCIJ", F_KONCIJ     )
   set_a_sql_sifarnik( "vrstep", "VRSTEP", F_VRSTEP     )
   set_a_sql_sifarnik( "pkonto", "PKONTO", F_PKONTO     )
   set_a_sql_sifarnik( "valute", "VALUTE", F_VALUTE     )
   set_a_sql_sifarnik( "fakt_objekti", "FAKT_OBJEKTI", F_FAKT_OBJEKTI   )


   set_a_dbf_temp     ( "relation",  "RELATION", F_RELATION   )
   set_a_dbf_temp     ( "barkod",  "BARKOD", F_BARKOD  )
   //set_a_dbf_temp     ( "strings",  "STRINGS", F_STRINGS    )

   RETURN .T.
