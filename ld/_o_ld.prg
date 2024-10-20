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

STATIC s_cObracun := " "  // obracun 1 ili 2, ili " "


/*

FUNCTION o_ld()

   SELECT ( F_LD )
   my_use ( "ld" )
   SET ORDER TO TAG "1"

   RETURN .T.
*/


// FUNCTION select_o_ld()
// RETURN  select_o_dbf( "LD", F_LD, "ld_ld", "1" )



FUNCTION o_banke( cId )

   SELECT ( F_BANKE )
   use_sql_sif  ( "banke", .T., "BANKE", cId )
   SET ORDER TO TAG "ID"

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.



FUNCTION o_ld_radn( cId )

   SELECT ( F_RADN )

   IF !use_sql_sif ( "ld_radn", .T., "RADN", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "1"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.

FUNCTION o_radn( cId )
   RETURN o_ld_radn( cId )


FUNCTION select_o_ld_radn( cId )

   SELECT ( F_RADN )

   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_ld_radn( cId )


FUNCTION select_o_radn( cID )
   RETURN select_o_ld_radn( cId )



/*

-- Table: fmk.ld_radn

-- DROP TABLE fmk.ld_radn;

CREATE TABLE fmk.ld_radn
(
  id character(6) NOT NULL,
  match_code character(10),
  naz character(20),
  imerod character(15),
  ime character(15),
  brbod numeric(11,2),
  kminrad numeric(7,2),
  idstrspr character(3),
  idvposla character(2),
  idopsst character(4),
  idopsrad character(4),
  pol character(1),
  matbr character(13),
  datod date,
  k1 character(1),
  k2 character(1),
  k3 character(2),
  k4 character(2),
  rmjesto character(30),
  brknjiz character(12),
  brtekr character(20),
  isplata character(2),
  idbanka character(6),
  porol numeric(5,2),
  n1 numeric(12,2),
  n2 numeric(12,2),
  n3 numeric(12,2),
  osnbol numeric(11,4),
  idrj character(2),
  streetname character(40),
  streetnum character(6),
  hiredfrom date,
  hiredto date,
  klo numeric(5,2),
  tiprada character(1),
  sp_koef numeric(5,2),
  opor character(1),
  trosk character(1),
  aktivan character(1),
  ben_srmj character(20),
  s1 character(10),
  s2 character(10),
  s3 character(10),
  s4 character(10),
  s5 character(10),
  s6 character(10),
  s7 character(10),
  s8 character(10),
  s9 character(10),
  st_invalid integer,
  vr_invalid integer,
  CONSTRAINT ld_radn_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.ld_radn
  OWNER TO admin;
GRANT ALL ON TABLE fmk.ld_radn TO admin;
GRANT ALL ON TABLE fmk.ld_radn TO xtrole;

-- Index: fmk.ld_radn_id1

-- DROP INDEX fmk.ld_radn_id1;

CREATE INDEX ld_radn_id1
  ON fmk.ld_radn
  USING btree
  (id COLLATE pg_catalog."default");

*/

FUNCTION find_radn_by_naz_or_id( cId )

   LOCAL cAlias := "RADN"
   LOCAL cTable := "ld_radn"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( cTable )

   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE aktivan<>'N' and ( id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql
   cSqlQuery += " OR ime ilike " + cIdSql + ")"


   IF !use_sql( cTable, cSqlQuery, cAlias )
      RETURN .F.
   ENDIF

   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN .T.



FUNCTION o_kred( cId )

   SELECT ( F_KRED )

   IF !use_sql_sif ( "kred", .T., "KRED", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION select_o_kred( cId )

   SELECT ( F_KRED )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_kred( cId )



FUNCTION o_ld_rj( cId )

   SELECT ( F_LD_RJ )

   IF !use_sql_sif ( "ld_rj", .T., "LD_RJ", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION select_o_ld_rj( cId )

   SELECT ( F_LD_RJ )

   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_ld_rj( cId )


FUNCTION o_por( cId )

   SELECT ( F_POR )

   IF !use_sql_sif ( "por", .T., "POR", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"

   RETURN .T.


FUNCTION select_o_por( cId )

   SELECT ( F_POR )

   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_por( cId )



FUNCTION o_dopr( cId )

   SELECT ( F_DOPR )

   IF !use_sql_sif ( "dopr", .T., "DOPR", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"

   RETURN .T.


FUNCTION select_o_dopr( cId )

   SELECT ( F_DOPR )

   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_dopr( cId )



FUNCTION open_rekld()

   RETURN o_dbf_table( F_REKLD, "rekld", "1" )


FUNCTION select_o_rekld()

   RETURN select_o_dbf( "REKLD", F_REKLD, "rekld", "1" )



FUNCTION o_str_spr( cId )

   SELECT ( F_STRSPR )

   IF !use_sql_sif ( "strspr", .T., "STRSPR", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.



FUNCTION select_o_str_spr( cId )

   SELECT ( F_STRSPR )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_str_spr( cId )


FUNCTION o_ld_vrste_posla( cId )

   SELECT ( F_VPOSLA )
   IF !use_sql_sif ( "vposla", .T., "VPOSLA", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION o_vposla( cId )
   RETURN o_ld_vrste_posla( cId )


FUNCTION select_o_vposla( cId )

   SELECT ( F_VPOSLA )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_vposla( cId )




FUNCTION o_koef_beneficiranog_radnog_staza( cId )

   SELECT ( F_KBENEF )

   IF !use_sql_sif ( "kbenef", .T., "KBENEF", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION o_kbenef( cId )
   RETURN o_koef_beneficiranog_radnog_staza( cId )


FUNCTION select_o_kbenef( cId )

   SELECT ( F_KBENEF )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_kbenef( cId )



FUNCTION o_ld_parametri_obracuna( cSeek )

   SELECT ( F_PAROBR )

   IF !use_sql_sif ( "ld_parobr", .T., "PAROBR" )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cSeek != NIL
      SEEK cSeek
   ENDIF

   RETURN .T.


FUNCTION o_parobr( cSeek )

   RETURN o_ld_parametri_obracuna( cSeek )


FUNCTION select_o_parobr( cSeek )

   SELECT ( F_PAROBR )
   IF Used()
      IF RecCount() > 1 .AND. cSeek == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_ld_parametri_obracuna( cSeek )



FUNCTION o_tippr( cId )

   SELECT ( F_TIPPR )

   IF !use_sql_sif ( "tippr", .T., "TIPPR", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION select_o_tippr( cId )

   SELECT ( F_TIPPR )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   IF s_cObracun <> "1" .AND. !Empty( s_cObracun )
      RETURN o_tippr2( cId, "TIPPR" )
   ENDIF

   RETURN o_tippr( cId )


FUNCTION select_o_tippr2( cId )

   SELECT ( F_TIPPR2 )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_tippr2( cId )


FUNCTION o_tippr2( cId, cAlias )

   IF cAlias == NIL
      cAlias := "TIPPR2"
   ENDIF

   IF cAlias == "TIPPR2"
      SELECT ( F_TIPPR2 )
   ELSE
      SELECT ( F_TIPPR )
   ENDIF

   IF !use_sql_sif ( "tippr2", .T., cAlias, cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.



FUNCTION set_tippr_ili_tippr2( cObracun )

   s_cObracun := cObracun
/*
   SELECT ( F_TIPPR )
   IF Used()
      USE
   ENDIF

   SELECT ( F_TIPPR2 )
   IF Used()
      USE
   ENDIF

   IF cObracun <> "1" .AND. !Empty( cObracun )
      SELECT ( F_TIPPR2 )
      IF !use_sql_sif ( "tippr2", .T., "TIPPR" )
         RETURN .F.
      ENDIF
   ELSE
      SELECT ( F_TIPPR )
      IF !use_sql_sif ( "tippr" )
         RETURN .F.
      ENDIF
   ENDIF

   SELECT TIPPR
   SET ORDER TO TAG "ID"
*/

   RETURN .T.



FUNCTION o_ld_obracuni( cSeek )

   LOCAL cAlias := "LD_OBRACUNI"

   SELECT ( F_LD_OBRACUNI )
   IF !use_sql_sif ( "ld_obracuni", .T., cAlias )
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "RJ"
   IF cSeek != NIL
      SEEK cSeek
   ENDIF

   RETURN .T.
