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

FIELD idfirma, idvn, brnal, datnal


/*

-- Table: fmk.fin_suban

-- DROP TABLE fmk.fin_suban;

CREATE TABLE fmk.fin_suban
(
  idfirma character varying(2) NOT NULL,
  idvn character varying(2) NOT NULL,
  brnal character varying(8) NOT NULL,
  idkonto character varying(7),
  idpartner character varying(6),
  rbr integer NOT NULL,
  idtipdok character(2),
  brdok character varying(20),
  datdok date,
  datval date,
  otvst character(1),
  d_p character(1),
  iznosbhd numeric(17,2),
  iznosdem numeric(15,2),
  opis character varying(500),
  k1 character(1),
  k2 character(1),
  k3 character(2),
  k4 character(2),
  m1 character(1),
  m2 character(1),
  idrj character(6),
  funk character(5),
  fond character(4),
  CONSTRAINT fin_suban_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fin_suban
  OWNER TO admin;
GRANT ALL ON TABLE fmk.fin_suban TO admin;
GRANT ALL ON TABLE fmk.fin_suban TO xtrole;

-- Index: fmk.fin_suban_brnal

-- DROP INDEX fmk.fin_suban_brnal;

CREATE INDEX fin_suban_brnal
  ON fmk.fin_suban
  USING btree
  (idfirma COLLATE pg_catalog."default", idvn COLLATE pg_catalog."default", brnal COLLATE pg_catalog."default", rbr);

-- Index: fmk.fin_suban_datdok

-- DROP INDEX fmk.fin_suban_datdok;

CREATE INDEX fin_suban_datdok
  ON fmk.fin_suban
  USING btree
  (datdok);

-- Index: fmk.fin_suban_datval_datdok

-- DROP INDEX fmk.fin_suban_datval_datdok;

CREATE INDEX fin_suban_datval_datdok
  ON fmk.fin_suban
  USING btree
  (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", (COALESCE(datval, datdok)), brdok COLLATE pg_catalog."default");

-- Index: fmk.fin_suban_id1

-- DROP INDEX fmk.fin_suban_id1;

CREATE INDEX fin_suban_id1
  ON fmk.fin_suban
  USING btree
  (idfirma COLLATE pg_catalog."default", idvn COLLATE pg_catalog."default", brnal COLLATE pg_catalog."default", rbr);

-- Index: fmk.fin_suban_konto_partner

-- DROP INDEX fmk.fin_suban_konto_partner;

CREATE INDEX fin_suban_konto_partner
  ON fmk.fin_suban
  USING btree
  (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", datdok);

-- Index: fmk.fin_suban_konto_partner_brdok

-- DROP INDEX fmk.fin_suban_konto_partner_brdok;

CREATE INDEX fin_suban_konto_partner_brdok
  ON fmk.fin_suban
  USING btree
  (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", brdok COLLATE pg_catalog."default", datdok);

-- Index: fmk.fin_suban_otvrst

-- DROP INDEX fmk.fin_suban_otvrst;

CREATE INDEX fin_suban_otvrst
  ON fmk.fin_suban
  USING btree
  (btrim(idkonto::text) COLLATE pg_catalog."default", btrim(idpartner::text) COLLATE pg_catalog."default", btrim(brdok::text) COLLATE pg_catalog."default");


-- Trigger: suban_insert_upate_delete on fmk.fin_suban

-- DROP TRIGGER suban_insert_upate_delete ON fmk.fin_suban;

CREATE TRIGGER suban_insert_upate_delete
  AFTER INSERT OR UPDATE OR DELETE
  ON fmk.fin_suban
  FOR EACH ROW
  EXECUTE PROCEDURE public.on_suban_insert_update_delete();



*/

FUNCTION o_sql_suban_kto_partner( cIdFirma )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   hParams[ "order_by" ] := "IdFirma,IdKonto,IdPartner,DatDok,BrNal,RBr"
   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   IF !use_sql_suban( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()


FUNCTION find_suban_za_period( cIdFirma, dDatOd, dDatDo, cOrderBy, cWhere )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idFirma,IdVN,BrNal,Rbr" )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF dDatOd != NIL
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF dDatDo != NIL
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := cOrderBy

   hParams[ "indeks" ] := .F.

   IF cWhere != NIL
      hParams[ "where" ] := cWhere
   ENDIF

   IF !use_sql_suban( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()






FUNCTION find_sint_by_konto_za_period( cIdFirma, cIdKonto, dDatOd, dDatDo, cOrderBy )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idFirma,idkonto,datnal" )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdKonto <> NIL
      hParams[ "idkonto" ] := cIdKonto
   ENDIF

   IF dDatOd != NIL
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF dDatDo != NIL
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := cOrderBy // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   IF !use_sql_sint( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()



FUNCTION find_anal_by_konto( cIdFirma, cIdKonto )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdKonto <> NIL
      hParams[ "idkonto" ] := cIdKonto
   ENDIF

   hParams[ "order_by" ] := "datnal" // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := .T. // ne trositi vrijeme na kreiranje indeksa

   IF !use_sql_anal( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()



FUNCTION find_suban_by_konto_partner( xIdFirma, cIdKonto, cIdPartner, cBrDok, cOrderBy, lIndeks )

   LOCAL hParams := hb_Hash()

   IF xIdFirma != NIL
      IF ValType( xIdFirma ) == "C"
         hParams[ "idfirma" ] := xIdFirma
         hb_default( @cOrderBy, "IdFirma,IdKonto,IdPartner,brdok" )
         hb_default( @lIndeks, .F. )
      ELSE
         hParams := hb_HClone( xIdFirma )
         IF !use_sql_suban( hParams )
            RETURN .F.
         ENDIF
         GO TOP
         RETURN !Eof()
      ENDIF
   ENDIF

   IF cIdKonto <> NIL
      hParams[ "idkonto" ] := cIdKonto
   ENDIF

   IF cIdPartner <> NIL
      hParams[ "idpartner" ] := cIdPartner
   ENDIF

   IF cBrDok <> NIL
      hParams[ "brdok" ] := cBrDok
   ENDIF

   hParams[ "order_by" ] := cOrderBy // ako ima vise brojeva dokumenata sortiraj po njima
   hParams[ "indeks" ] := lIndeks

   IF !use_sql_suban( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()



FUNCTION find_anal_za_period( cIdFirma, dDatOd, dDatDo, cOrderBy )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idFirma,idkonto" )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF dDatOd != NIL
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF dDatDo != NIL
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := cOrderBy

   hParams[ "indeks" ] := .F.
   IF !use_sql_anal( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()


FUNCTION find_nalog_za_period( cIdFirma, cIdVN, dDatOd, dDatDo, cOrderBy, cAlias )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idFirma,IdVN,BrNal" )
   hb_default( @cAlias, "NALOG" )

   hParams[ "alias" ] := cAlias

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdFirma <> NIL
      hParams[ "idvn" ] := cIdVN
   ENDIF

   IF dDatOd != NIL
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF dDatDo != NIL
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := cOrderBy

   hParams[ "indeks" ] := .F.
   IF !use_sql_nalog( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()


FUNCTION find_nalog_by_broj_dokumenta( cIdFirma, cIdVN, cBrNal, cOrderBy )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "idfirma,idvn,brnal" )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVN <> NIL
      hParams[ "idvn" ] := cIdvn
   ENDIF

   IF cBrNal <> NIL
      hParams[ "brnal" ] := cBrNal
   ENDIF

   hParams[ "order_by" ] :=  cOrderBy // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   IF !use_sql_nalog( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()


FUNCTION find_sint_by_broj_dokumenta( cIdFirma, cIdVN, cBrNal )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVN <> NIL
      hParams[ "idvn" ] := cIdvn
   ENDIF

   IF cBrNal <> NIL
      hParams[ "brnal" ] := cBrNal
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvn,brnal,rbr" // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   IF use_sql_sint( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()


FUNCTION find_anal_by_broj_dokumenta( cIdFirma, cIdVN, cBrNal, cAlias )

   LOCAL hParams := hb_Hash()

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVN <> NIL
      hParams[ "idvn" ] := cIdvn
   ENDIF

   IF cBrNal <> NIL
      hParams[ "brnal" ] := cBrNal
   ENDIF

   IF cAlias <> NIL
      hParams[ "alias" ] := cAlias
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvn,brnal,rbr" // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := .F. // ne trositi vrijeme na kreiranje indeksa

   IF !use_sql_anal( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()


FUNCTION find_suban_by_broj_dokumenta( cIdFirma, cIdVN, cBrNal, lIndex )

   LOCAL hParams := hb_Hash()

   hb_default( @lIndex, .F. )

   IF cIdFirma <> NIL
      hParams[ "idfirma" ] := cIdFirma
   ENDIF

   IF cIdVN <> NIL
      hParams[ "idvn" ] := cIdvn
   ENDIF

   IF cBrNal <> NIL
      hParams[ "brnal" ] := cBrNal
   ENDIF

   hParams[ "order_by" ] := "idfirma,idvn,brnal,rbr" // ako ima vise brojeva dokumenata sortiraj po njima

   hParams[ "indeks" ] := lIndex  // ne trositi vrijeme na kreiranje indeksa, osim ako se ne naglasi

   IF !use_sql_suban( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()



FUNCTION use_sql_fin_nalog( cIdVN, lMakeIndex )

   LOCAL cSql
   LOCAL cTable := "fin_nalog"
   LOCAL cAlias := "NALOG"

   IF lMakeIndex == NIL
      lMakeIndex := .T.
   ENDIF

   cSql := "SELECT "
   cSql += "  idfirma, idvn, brnal, sifra, "
   cSql += "  COALESCE(datnal,('1900-01-01'::date)) AS datnal, "
   cSql += "  COALESCE(dugbhd,0)::numeric(17,2) AS dugbhd, "
   cSql += "  COALESCE(potbhd,0)::numeric(17,2) AS potbhd, "
   cSql += "  COALESCE(dugdem,0)::numeric(15,2) AS dugdem, "
   cSql += "  COALESCE(potdem,0)::numeric(15,2) AS potdem "
   cSql += "FROM " + F18_PSQL_SCHEMA_DOT + cTable
   IF cIdVN != NIL .AND. !Empty( cIdVN )
      cSql += " WHERE IdVN=" + sql_quote( cIdVN )
   ENDIF
   cSQL += " ORDER BY idfirma, idvn, brnal"

   SELECT F_NALOG
   IF !use_sql( cTable, cSql, cAlias )
      RETURN .F.
   ENDIF

   IF lMakeIndex
      INDEX ON IdFirma + IdVn + BrNal TAG 1 TO ( cAlias )
      INDEX ON IdFirma + Str( Val( BrNal ), 8 ) + idvn TAG 2 TO ( cAlias )
      INDEX ON DToS( datnal ) + IdFirma + idvn + brnal TAG 3 TO ( cAlias )
      INDEX ON datnal TAG 4 TO ( cAlias )
      SET ORDER TO TAG 1
      GO TOP
   ENDIF

   RETURN .T.


/* --- nalog -- */


FUNCTION use_sql_nalog( hParams )

   LOCAL cTable := "fin_nalog"
   LOCAL cAlias := "NALOG"
   LOCAL cWhere, cOrder
   LOCAL cSql


/*
CREATE TABLE fmk.fin_nalog
(
  idfirma character(2) NOT NULL,
  idvn character(2) NOT NULL,
  brnal character(8) NOT NULL,
  datnal date,
  dugbhd numeric(17,2),
  potbhd numeric(17,2),
  dugdem numeric(15,2),
  potdem numeric(15,2),
  sifra character(6)
)
*/

   default_if_nil( @hParams, hb_Hash() )

   cSql := "SELECT "
   cSql += coalesce_char_zarez( "idfirma", 2 )
   cSql += coalesce_char_zarez( "idvn", 2 )
   cSql += coalesce_char_zarez( "brnal", 8 )
   cSql += coalesce_char_zarez( "sifra", 8 )
   cSql += "datnal, "
   cSql += coalesce_num_num_zarez( "dugbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "potbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "dugdem", 15, 2  )
   cSql += coalesce_num_num( "potdem", 15, 2  )

   cSql += " FROM fmk." + cTable


   cWhere := use_sql_nalog_where( hParams )
   cOrder := use_sql_nalog_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cAlias := hParams[ "alias" ]
      SELECT 0
   ELSE
      SELECT ( F_NALOG )
   ENDIF

   IF !use_sql( cTable, cSql, cAlias )
      RETURN .F.
   ENDIF

   IF is_sql_rdd_treba_indeks( hParams )

      INDEX ON idFirma + IdVN + BrNal  TAG "1" TO cTable
      INDEX ON IdFirma + Str( Val( BrNal ), 8 ) + idvn  TAG "2" TO cTable
      INDEX ON DToS( datnal ) + IdFirma + idvn + brnal  TAG "3" TO cTable
      INDEX ON datnal  TAG "4" TO cTable

      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   RETURN .T.


STATIC FUNCTION use_sql_nalog_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY idfirma,idvn,brnal"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_nalog_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere := parsiraj_sql( "idfirma", hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvn" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idvn", hParams[ "idvn" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brnal" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "brnal", hParams[ "brnal" ] )
   ENDIF


   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql_date_interval( "datnal", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   RETURN cWhere


/* --- sint -- */

FUNCTION use_sql_sint( hParams )

   LOCAL cTable := "SINT"
   LOCAL cWhere, cOrder
   LOCAL cSql


/*
CREATE TABLE fmk.fin_sint
(
  idfirma character(2) NOT NULL,
  idkonto character(3),
  idvn character(2) NOT NULL,
  brnal character(8) NOT NULL,
  rbr character varying(4) NOT NULL,
  datnal date,
  dugbhd numeric(17,2),
  potbhd numeric(17,2),
  dugdem numeric(15,2),
  potdem numeric(15,2)
)

*/

   default_if_nil( @hParams, hb_Hash() )

   cSql := "SELECT "
   cSql += coalesce_char_zarez( "idfirma", 2 )
   cSql += coalesce_char_zarez( "idvn", 2 )
   cSql += coalesce_char_zarez( "brnal", 8 )
   cSql += coalesce_char_zarez( "idkonto", 3 )
   cSql += coalesce_char_zarez( "rbr", 4 )
   cSql += "datnal, "
   cSql += coalesce_num_num_zarez( "dugbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "potbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "dugdem", 15, 2  )
   cSql += coalesce_num_num( "potdem", 15, 2  )

   cSql += " FROM fmk.fin_sint"


   cWhere := use_sql_sint_where( hParams )
   cOrder := use_sql_sint_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cTable := hParams[ "alias" ]
   ENDIF

   SELECT ( F_SINT )

   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON  IdFirma + IdKonto + DToS( DatNal )  TAG "1" TO cTable
      INDEX ON idFirma + IdVN + BrNal + Rbr  TAG "2" TO cTable
      INDEX ON idFirma + DToS( DatNal )  TAG "3" TO cTable
      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   RETURN .T.


STATIC FUNCTION use_sql_sint_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY idfirma,idvn,brnal"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_sint_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere := parsiraj_sql( "idfirma", hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvn" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idvn", hParams[ "idvn" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brnal" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "brnal", hParams[ "brnal" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idkonto" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idkonto", hParams[ "idkonto" ] )
   ENDIF


   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql_date_interval( "datnal", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   RETURN cWhere


/* --- anal -- */

FUNCTION use_sql_anal( hParams )

   LOCAL cTable := "fin_anal"
   LOCAL cWhere, cOrder
   LOCAL cSql
   LOCAL cAlias := "ANAL"


/*
CREATE TABLE fmk.fin_anal
(
  idfirma character(2) NOT NULL,
  idkonto character(7),
  idvn character(2) NOT NULL,
  brnal character(8) NOT NULL,
  rbr character varying(4) NOT NULL,
  datnal date,
  dugbhd numeric(17,2),
  potbhd numeric(17,2),
  dugdem numeric(15,2),
  potdem numeric(15,2)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fin_anal
  OWNER TO admin;
GRANT ALL ON TABLE fmk.fin_anal TO admin;
GRANT ALL ON TABLE fmk.fin_anal TO xtrole;

*/

   default_if_nil( @hParams, hb_Hash() )

   cSql := "SELECT "
   cSql += coalesce_char_zarez( "idfirma", 2 )
   cSql += coalesce_char_zarez( "idvn", 2 )
   cSql += coalesce_char_zarez( "brnal", 8 )
   cSql += coalesce_char_zarez( "idkonto", 7 )
   cSql += coalesce_char_zarez( "rbr", 4 )
   cSql += "datnal, "
   cSql += coalesce_num_num_zarez( "dugbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "potbhd", 17, 2 )
   cSql += coalesce_num_num_zarez( "dugdem", 15, 2  )
   cSql += coalesce_num_num( "potdem", 15, 2  )

   cSql += " FROM fmk.fin_anal"


   cWhere := use_sql_anal_where( hParams )
   cOrder := use_sql_anal_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cAlias := hParams[ "alias" ]
   ENDIF

   SELECT ( F_ANAL )
   IF !use_sql( cTable, cSql, cAlias )
      RETURN .F.
   ENDIF

   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON  IdFirma + IdKonto + DToS( DatNal )  TAG "1" TO cTable
      INDEX ON idFirma + IdVN + BrNal + Rbr  TAG "2" TO cTable
      INDEX ON idFirma + DToS( DatNal )  TAG "3" TO cTable
      INDEX ON  Idkonto  TAG "4" TO cTable
      INDEX ON  DatNal  TAG "5" TO cTable

      SET ORDER TO TAG "1"
   ENDIF
   GO TOP

   RETURN .T.





STATIC FUNCTION use_sql_anal_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY idfirma,idvn,brnal"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_anal_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere := parsiraj_sql( "idfirma", hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvn" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idvn", hParams[ "idvn" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brnal" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "brnal", hParams[ "brnal" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idkonto" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idkonto", hParams[ "idkonto" ] )
   ENDIF


   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql_date_interval( "datnal", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   RETURN cWhere


FUNCTION use_sql_suban( hParams )

   LOCAL cTable := "fin_suban"
   LOCAL cAlias := "SUBAN"
   LOCAL nWa := F_SUBAN
   LOCAL cWhere, cOrder
   LOCAL cSql

   default_if_nil( @hParams, hb_Hash() )

   cSql := "SELECT "
   cSql += coalesce_char_zarez( "idfirma", 2 )
   cSql += coalesce_char_zarez( "idvn", 2 )
   cSql += coalesce_char_zarez( "brnal", 8 )
   cSql += coalesce_char_zarez( "idkonto", 7 )
   cSql += coalesce_char_zarez( "idpartner", 6 )
   cSql += coalesce_int_zarez( "rbr" )
   cSql += coalesce_char_zarez( "idtipdok", 2 )
   cSql += coalesce_char_zarez( "brdok", 20 )
   cSql += "coalesce(datdok, TO_DATE('','yyyymmdd')) as datdok, coalesce( datval, TO_DATE('','yyyymmdd')) as datval,"
   // cSql += "datdok,datval,"

   cSql += coalesce_char_zarez( "otvst", 1 )
   cSql += coalesce_char_zarez( "d_p", 1 )

   cSql += coalesce_char_zarez( "opis", 500 )
   cSql += coalesce_char_zarez( "k1", 1 )
   cSql += coalesce_char_zarez( "k2", 1 )
   cSql += coalesce_char_zarez( "k3", 2 )
   cSql += coalesce_char_zarez( "k4", 2 )
   cSql += coalesce_char_zarez( "m1", 1 )
   cSql += coalesce_char_zarez( "m2", 2 )
   cSql += coalesce_char_zarez( "idrj", 6 )
   cSql += coalesce_char_zarez( "funk", 5 )
   cSql += coalesce_char_zarez( "fond", 4 )

   cSql += coalesce_num_num_zarez( "iznosbhd", 17, 2 )
   cSql += coalesce_num_num( "iznosdem", 15, 2  )

   cSql += " FROM fmk.fin_suban"


   cWhere := use_sql_suban_where( hParams )
   cOrder := use_sql_suban_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cAlias := hParams[ "alias" ]
   ENDIF
   IF hb_HHasKey( hParams, "alias" )
      nWa := hParams[ "wa" ]
      SELECT ( nWa )
   ELSE
      SELECT ( F_SUBAN )
   ENDIF

   IF !use_sql( cTable, cSql, cAlias )
      RETURN .F.
   ENDIF

   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON IdFirma + IdKonto + IdPartner + DToS( DatDok ) + BrNal + Str( RBr, 5 )  TAG "1" TO cTable
      INDEX ON IdFirma + IdPartner + IdKonto  TAG "2" TO cTable
      INDEX ON IdFirma + IdKonto + IdPartner + BrDok + DToS( DatDok )  TAG "3" TO cTable
      INDEX ON idFirma + IdVN + BrNal + Str( Rbr, 5 )  TAG "4" TO cTable
      INDEX ON idFirma + IdKonto + DToS( DatDok ) + idpartner  TAG "5" TO cTable
      INDEX ON IdKonto  TAG "6" TO cTable
      INDEX ON Idpartner  TAG "7" TO cTable
      INDEX ON Datdok  TAG "8" TO cTable
      INDEX ON idfirma + idkonto + idrj + idpartner + DToS( datdok ) + brnal + Str( rbr, 5 )  TAG "9" TO cTable
      INDEX ON idFirma + IdVN + BrNal + idkonto + DToS( datdok )  TAG "10" TO cTable

      SET ORDER TO TAG "1"
   ENDIF

   GO TOP

   RETURN .T.

STATIC FUNCTION use_sql_suban_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY idvn,brnal"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_suban_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "idfirma" )
      cWhere := parsiraj_sql( "idfirma", hParams[ "idfirma" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idvn" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idvn", hParams[ "idvn" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brnal" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "brnal", hParams[ "brnal" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idkonto" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idkonto", hParams[ "idkonto" ] )
   ENDIF

   IF hb_HHasKey( hParams, "idpartner" )
   altd()
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "idpartner", hParams[ "idpartner" ] )
   ENDIF

   IF hb_HHasKey( hParams, "brdok" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "rpad(brdok,20)", hParams[ "brdok" ] )
   ENDIF

   IF hb_HHasKey( hParams, "otvst" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "otvst", hParams[ "otvst" ] )
   ENDIF

   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql_date_interval( "datdok", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   IF hb_HHasKey( hParams, "where" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) +  hParams[ "where" ]
   ENDIF

   RETURN cWhere




FUNCTION datval_prazan()

   RETURN Empty( fix_dat_var( field->datval, .T. ) )


FUNCTION get_datval_field()

   RETURN fix_dat_var( field->DatVal, .T. )
