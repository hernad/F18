#include "f18.ch"

/*
-- Table: fmk.fakt_ugov

-- DROP TABLE fmk.fakt_ugov;

CREATE TABLE fmk.fakt_ugov
(
  id character(10) NOT NULL,
  datod date,
  idpartner character(6),
  datdo date,
  vrsta character(1),
  idtipdok character(2),
  naz character(20),
  aktivan character(1),
  dindem character(3),
  idtxt character(2),
  zaokr numeric(1,0),
  lab_prn character(1),
  iddodtxt character(2),
  a1 numeric(12,2),
  a2 numeric(12,2),
  b1 numeric(12,2),
  b2 numeric(12,2),
  txt2 character(2),
  txt3 character(2),
  txt4 character(2),
  f_nivo character(1),
  f_p_d_nivo numeric(5,0),
  dat_l_fakt date,
  def_dest character(6),
  CONSTRAINT fakt_ugov_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fakt_ugov
  OWNER TO hernad;

-- Index: fmk.fakt_ugov_id1

-- DROP INDEX fmk.fakt_ugov_id1;

CREATE INDEX fakt_ugov_id1
  ON fmk.fakt_ugov
  USING btree
  (id COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default");


*/


/*

-- Table: fmk.fakt_rugov

-- DROP TABLE fmk.fakt_rugov;

CREATE TABLE fmk.fakt_rugov
(
  id character(10),
  idroba character(10),
  kolicina numeric(15,4),
  rabat numeric(6,3),
  porez numeric(5,2),
  k1 character(1),
  k2 character(2),
  dest character(6),
  cijena numeric(15,3)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fakt_rugov
  OWNER TO hernad;

-- Index: fmk.fakt_rugov_id1

-- DROP INDEX fmk.fakt_rugov_id1;

CREATE INDEX fakt_rugov_id1
  ON fmk.fakt_rugov
  USING btree
  (id COLLATE pg_catalog."default", idroba COLLATE pg_catalog."default");


*/


/*

-- Table: fmk.fakt_gen_ug

-- DROP TABLE fmk.fakt_gen_ug;

CREATE TABLE fmk.fakt_gen_ug
(
  dat_obr date,
  dat_gen date,
  dat_u_fin date,
  kto_kup character(7),
  kto_dob character(7),
  opis character(100),
  brdok_od character(8),
  brdok_do character(8),
  fakt_br numeric(5,0),
  saldo numeric(15,5),
  saldo_pdv numeric(15,5),
  brisano character(1),
  dat_val date
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fakt_gen_ug
  OWNER TO hernad;

-- Index: fmk.fakt_gen_ug_id1

-- DROP INDEX fmk.fakt_gen_ug_id1;

CREATE INDEX fakt_gen_ug_id1
  ON fmk.fakt_gen_ug
  USING btree
  (dat_obr, dat_gen);


*/


/*

-- Table: fmk.fakt_gen_ug_p

-- DROP TABLE fmk.fakt_gen_ug_p;

CREATE TABLE fmk.fakt_gen_ug_p
(
  dat_obr date,
  idpartner character(6),
  id_ugov character(10),
  saldo_kup numeric(15,5),
  saldo_dob numeric(15,5),
  d_p_upl_ku date,
  d_p_prom_k date,
  d_p_prom_d date,
  f_iznos numeric(15,5),
  f_iznos_pd numeric(15,5)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fakt_gen_ug_p
  OWNER TO hernad;

-- Index: fmk.fakt_gen_ug_p_id1

-- DROP INDEX fmk.fakt_gen_ug_p_id1;

CREATE INDEX fakt_gen_ug_p_id1
  ON fmk.fakt_gen_ug_p
  USING btree
  (dat_obr, idpartner COLLATE pg_catalog."default", id_ugov COLLATE pg_catalog."default");


*/


/*

-- Table: fmk.dest

-- DROP TABLE fmk.dest;

CREATE TABLE fmk.dest
(
  id character(6),
  idpartner character(6),
  naziv character(60),
  naziv2 character(60),
  mjesto character(20),
  adresa character(40),
  ptt character(10),
  telefon character(20),
  mobitel character(20),
  fax character(20)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.dest
  OWNER TO hernad;

-- Index: fmk.dest_id1

-- DROP INDEX fmk.dest_id1;

CREATE INDEX dest_id1
  ON fmk.dest
  USING btree
  (id COLLATE pg_catalog."default");


*/



FUNCTION o_ugov( cUgovId, cIdPartner, nArea, cAlias )

   LOCAL cTable := "fakt_ugov"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   IF nArea == NIL
      nArea := F_UGOV
   ENDIF

   IF cAlias == NIL
      cAlias := "UGOV"
   ENDIF

   IF cUgovId != NIL
      cSql += " WHERE id=" + sql_quote( cUgovId )
      IF cIdPartner != NIL
         cSql += " AND idpartner=" + sql_quote( cIdPartner )
      ENDIF
   ENDIF

   Select( nArea )
   use_sql( cTable, cSql, cAlias )

   INDEX ON field->Id + field->idpartner TAG "ID" TO ( cAlias )
   INDEX ON field->Idpartner + field->id TAG "NAZ" TO ( cAlias )
   INDEX ON field->naz TAG "NAZ2" TO ( cAlias )
   INDEX ON field->idpartner TAG "PARTNER" TO ( cAlias )
   INDEX ON field->aktivan TAG "AKTIVAN" TO ( cAlias )
   SET ORDER TO TAG "ID"
   GO TOP

   RETURN !Eof()


FUNCTION o_ugov_partner( cIdPartner )

   LOCAL cTable := "fakt_ugov", cAlias := "UGOV"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   cSql += " WHERE idpartner=" + sql_quote( cIdPartner )

   SELECT F_UGOV
   use_sql( cTable, cSql, cAlias )

   INDEX ON field->idpartner TAG "PARTNER" TO ( cAlias )
   SET ORDER TO TAG "PARTNER"
   GO TOP

   RETURN !Eof()


FUNCTION o_aktivni_ugovori()

   LOCAL cTable := "fakt_ugov", cAlias := "UGOV"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   cSql += " WHERE aktivan='D'"

   SELECT F_UGOV
   use_sql( cTable, cSql, cAlias )

   INDEX ON field->Id + field->idpartner TAG "ID" TO ( cAlias )
   INDEX ON field->Idpartner + field->id TAG "NAZ" TO ( cAlias )
   INDEX ON field->naz TAG "NAZ2" TO ( cAlias )
   INDEX ON field->idpartner TAG "PARTNER" TO ( cAlias )
   INDEX ON field->aktivan TAG "AKTIVAN" TO ( cAlias )
   SET ORDER TO TAG "ID"
   GO TOP

   RETURN !Eof()


FUNCTION o_rugov( cIdUgov, cIdRoba, cDest )

   LOCAL cTable := "fakt_rugov", cAlias := "RUGOV"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   IF cIdUgov != NIL
      cSql += " WHERE id=" + sql_quote( cIdUgov )
      IF cIdRoba != NIL
         cSql += " AND idroba=" + sql_quote( cIdRoba )
      ENDIF
      IF cDest != NIL
         cSql += " AND dest=" + sql_quote( cDest )
      ENDIF
   ENDIF

   SELECT F_RUGOV
   use_sql( cTable, cSql, cAlias )
   INDEX ON field->Id + field->idroba + field->dest TAG "ID" TO ( cAlias )
   INDEX ON field->IdRoba TAG "IDROBA" TO ( cAlias )

   SET ORDER TO TAG "ID"
   GO TOP

   RETURN !Eof()



FUNCTION o_rugov_roba( cIdRoba )

   LOCAL cTable := "fakt_rugov", cAlias := "RUGOV"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   cSql += " WHERE idroba=" + sql_quote( cIdRoba )

   SELECT F_RUGOV
   use_sql( cTable, cSql, cAlias )
   INDEX ON field->Id + field->idroba + field->dest TAG "ID" TO ( cAlias )
   INDEX ON field->IdRoba TAG "IDROBA" TO ( cAlias )

   SET ORDER TO TAG "IDROBA"
   GO TOP

   RETURN !Eof()


FUNCTION o_gen_ug( dDatObr, dDatGen )

   LOCAL cTable := "fakt_gen_ug", cAlias := "GEN_UG"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   IF dDatObr != NIL
      cSql += " WHERE dat_obr=" + sql_quote( dDatObr )
   ENDIF

   IF dDatGen != NIL
      cSql += " WHERE dat_gen=" + sql_quote( dDatGen )
   ENDIF

   SELECT F_GEN_UG

   use_sql( cTable, cSql, cAlias )
   INDEX ON DToS( field->dat_obr )  TAG "DAT_OBR" TO ( cAlias )
   INDEX ON DToS( field->dat_gen ) TAG "DAT_GEN" TO ( cAlias )

   SET ORDER TO TAG "DAT_GEN"
   GO TOP

   RETURN !Eof()


FUNCTION get_zadnje_fakturisanje_po_ugovoru()

   LOCAL nTArea := Select(), dGen, cTable := "fakt_gen_ug", cAlias := "POM"

   LOCAL cSql := "select max(dat_gen) AS MAX_DAT_GEN from " + f18_sql_schema( cTable )

   SELECT F_POM
   use_sql( "GEN_UG", cSql, cAlias )
   dGen := field->max_dat_gen
   // LOCAL dGen

   // SELECT gen_ug
   // SET ORDER TO TAG "dat_obr"
   // GO BOTTOM
   // dGen := field->dat_gen
   USE

   SELECT ( nTArea )

   RETURN dGen



FUNCTION o_gen_ug_zadnji()

   LOCAL dDatMax := get_zadnje_fakturisanje_po_ugovoru()

   RETURN o_gen_ug( dDatMax )


FUNCTION o_gen_ug_p( dDatObr, cUgovId, cIdPartner )

   LOCAL cTable := "fakt_gen_ug_p", cAlias := "GEN_UG_P"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

// SEEK DToS( dPObr ) + cUgovId + ugov->IdPartner

   IF dDatObr != NIL
      cSql += " WHERE dat_obr=" + sql_quote( dDatObr )

      IF cUgovId != NIL
         cSql += " AND id_ugov=" + sql_quote( cUgovId )
      ENDIF

      IF cIdPartner != NIL
         cSql += " AND idpartner=" + sql_quote( cIdPartner )
      ENDIF
   ENDIF

   SELECT F_G_UG_P
   use_sql( cTable, cSql, cAlias )

   INDEX ON DToS( field->dat_obr ) + field->ID_UGOV + field->IDPARTNER TAG "DAT_OBR" TO ( cAlias )

   SET ORDER TO TAG "DAT_OBR"
   GO TOP

   RETURN !Eof()


/*
   ugovori: destinacije
*/

FUNCTION o_dest()

   LOCAL cTabela := "dest"

   SELECT ( F_DEST )
   IF !use_sql_sif  ( cTabela )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF

   // "ID", "IDPARTNER + ID"
   // "IDDEST", "ID"

   SET ORDER TO TAG "IDDEST"
   GO TOP

   RETURN !Eof()


FUNCTION find_zadnja_destinacija()

   LOCAL cMaxId
   LOCAL cTable := "dest", cAlias := "POM"
   LOCAL cSql := "select max(id) as max_id from " + f18_sql_schema( cTable )

   SELECT F_POM
   use_sql( cTable, cSql, cAlias )

   cMaxId := field->max_id
   USE

   RETURN cMaxId


FUNCTION o_dest_partner( cIdPartner )

   LOCAL cTable := "dest", cAlias := "DEST"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   cSql += " WHERE idpartner=" + sql_quote( cIdPartner )

   SELECT F_DEST
   use_sql( cTable, cSql, cAlias )

   INDEX ON  field->IDPARTNER + field->ID  TAG "ID" TO ( cAlias )
   INDEX ON  field->ID  TAG "IDDEST" TO ( cAlias )

   RETURN !Eof()



FUNCTION find_dest_by_iddest_idpartn( cIdDestinacija, cIdPartner )

   LOCAL cTable := "dest", cAlias := "DEST"
   LOCAL cSql := "select * from " + f18_sql_schema( cTable )

   cSql += " WHERE idpartner=" + sql_quote( cIdPartner )
   cSql += " AND id=" + sql_quote( cIdDestinacija )

   SELECT F_DEST
   use_sql( cTable, cSql, cAlias )

   GO TOP

   RETURN !Eof()
