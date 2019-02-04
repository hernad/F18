CREATE SCHEMA IF NOT EXISTS p15;

ALTER SCHEMA p15 OWNER TO admin;

CREATE TABLE IF NOT EXISTS  p15.roba (
    id character(10) NOT NULL,
    match_code character(10),
    sifradob character(20),
    naz character varying(250),
    jmj character(3),
    idtarifa character(6),
    nc numeric(18,8),
    vpc numeric(18,8),
    mpc numeric(18,8),
    tip character(1),
    carina numeric(5,2),
    opis text,
    vpc2 numeric(18,8),
    mpc2 numeric(18,8),
    mpc3 numeric(18,8),
    k1 character(4),
    k2 character(4),
    n1 numeric(12,2),
    n2 numeric(12,2),
    plc numeric(18,8),
    mink numeric(12,2),
    _m1_ character(1),
    barkod character(13),
    zanivel numeric(18,8),
    zaniv2 numeric(18,8),
    trosk1 numeric(15,5),
    trosk2 numeric(15,5),
    trosk3 numeric(15,5),
    trosk4 numeric(15,5),
    trosk5 numeric(15,5),
    fisc_plu numeric(10,0),
    k7 character(4),
    k8 character(4),
    k9 character(4),
    strings numeric(10,0),
    idkonto character(7),
    mpc4 numeric(18,8),
    mpc5 numeric(18,8),
    mpc6 numeric(18,8),
    mpc7 numeric(18,8),
    mpc8 numeric(18,8),
    mpc9 numeric(18,8)
);
ALTER TABLE p15.roba OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_doks (
    idpos character varying(2) NOT NULL,
    idvd character varying(2) NOT NULL,
    brdok character varying(6) NOT NULL,
    datum date,
    idPartner character varying(6),
    idradnik character varying(4),
    idvrstep character(2),
    -- m1 character varying(1),
    placen character(1),
    prebacen character(1),
    -- smjena character varying(1),
    -- sto character varying(3),
    vrijeme character varying(5),
    brdokStorn character varying(8),
    --c_2 character varying(10),
    --c_3 character varying(50),
    fisc_rn numeric(10,0),
    -- zak_br numeric(6,0),
    -- sto_br numeric(3,0),
    -- funk numeric(3,0),
    -- fisc_st character(10),
    rabat numeric(15,5),
    ukupno numeric(15,5)
);
ALTER TABLE p15.pos_doks OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_dokspf (
    idpos character(2),
    idvd character(2),
    datum date,
    brdok character(6),
    knaz character varying(35),
    kadr character varying(35),
    kidbr character(13),
    datisp date
);
ALTER TABLE p15.pos_dokspf OWNER TO admin;


CREATE TABLE IF NOT EXISTS  p15.pos_kase (
    id character varying(2),
    naz character varying(15),
    ppath character varying(50)
);
ALTER TABLE p15.pos_kase OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_odj (
    id character varying(2),
    naz character varying(25),
    zaduzuje character(1),
    idkonto character varying(7)
);
ALTER TABLE p15.pos_odj OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_osob (
    id character varying(4),
    korsif character varying(6),
    naz character varying(40),
    status character(2)
);
ALTER TABLE p15.pos_osob OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_pos (
    idpos character varying(2),
    idvd character varying(2),
    brdok character varying(6),
    datum date,
    idcijena character varying(1),
    --idodj character(2),
    idradnik character varying(4),
    idroba character(10),
    idtarifa character(6),
    -- m1 character varying(1),
    mu_i character varying(1),
    prebacen character varying(1),
    -- smjena character varying(1),
    kolicina numeric(18,3),
    kol2 numeric(18,3),
    cijena numeric(10,3),
    ncijena numeric(10,3),
    rbr character varying(5)
);
ALTER TABLE p15.pos_pos OWNER TO admin;


CREATE TABLE IF NOT EXISTS p15.pos_strad (
    id character varying(2),
    naz character varying(15),
    prioritet character(1)
);
ALTER TABLE p15.pos_strad OWNER TO admin;


CREATE TABLE p15.vrstep (
    id character(2),
    naz character(20)
);
ALTER TABLE p15.vrstep OWNER TO admin;

GRANT ALL ON SCHEMA p15 TO xtrole;
GRANT ALL ON TABLE p15.roba TO xtrole;
GRANT ALL ON TABLE p15.pos_doks TO xtrole;
GRANT ALL ON TABLE p15.pos_dokspf TO xtrole;
GRANT ALL ON TABLE p15.pos_pos TO xtrole;
GRANT ALL ON TABLE p15.pos_strad TO xtrole;
GRANT ALL ON TABLE p15.pos_osob TO xtrole;
GRANT ALL ON TABLE p15.pos_odj TO xtrole;
GRANT ALL ON TABLE p15.pos_kase TO xtrole;
GRANT ALL ON TABLE p15.vrstep TO xtrole;


CREATE OR REPLACE FUNCTION fmk.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM fmk.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$_$;


CREATE OR REPLACE FUNCTION fmk.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM fmk.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM fmk.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE fmk.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO fmk.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$_$;

ALTER FUNCTION fmk.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION fmk.fetchmetrictext TO xtrole;

ALTER FUNCTION fmk.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION fmk.setmetric TO xtrole;

-----------------------------------------------------
-- pos_pos_knjig, pos_doks_knjig
----------------------------------------------------

CREATE TABLE p15.pos_pos_knjig (
   idpos character varying(2),
   idvd character varying(2),
   brdok character varying(6),
   datum date,
   idcijena character varying(1),
   --idodj character(2),
   idradnik character varying(4),
   idroba character(10),
   idtarifa character(6),
   -- m1 character varying(1),
   mu_i character varying(1),
   prebacen character varying(1),
   -- smjena character varying(1),
   -- brdokStorn character varying(8),
   --c_2 character varying(10),
   --c_3 character varying(50),
   kolicina numeric(18,3),
   kol2 numeric(18,3),
   cijena numeric(10,3),
   ncijena numeric(10,3),
   rbr character varying(5)
);
ALTER TABLE p15.pos_pos_knjig OWNER TO admin;
CREATE INDEX pos_pos_id1_knjig ON p15.pos_pos_knjig USING btree (idpos, idvd, datum, brdok, idroba, idcijena);
CREATE INDEX pos_pos_id2_knjig ON p15.pos_pos_knjig USING btree (idroba, datum);
CREATE INDEX pos_pos_id3_knjig ON p15.pos_pos_knjig USING btree (prebacen);
CREATE INDEX pos_pos_id4_knjig ON p15.pos_pos_knjig USING btree (datum);
CREATE INDEX pos_pos_id5_knjig ON p15.pos_pos_knjig USING btree (idpos, idroba, datum);
CREATE INDEX pos_pos_id6_knjig ON p15.pos_pos_knjig USING btree (idroba);
GRANT ALL ON TABLE p15.pos_pos_knjig TO xtrole;

CREATE TABLE p15.pos_doks_knjig (
   idpos character varying(2) NOT NULL,
   idvd character varying(2) NOT NULL,
   brdok character varying(6) NOT NULL,
   datum date,
   idPartner character varying(6),
   idradnik character varying(4),
   idvrstep character(2),
   -- m1 character varying(1),
   placen character(1),
   prebacen character(1),
   -- smjena character varying(1),
   vrijeme character varying(5),
   brdokStorn character varying(8),
   --c_2 character varying(10),
   --c_3 character varying(50),
   fisc_rn numeric(10,0),
   rabat numeric(15,5),
   ukupno numeric(15,5)
);
ALTER TABLE p15.pos_doks_knjig OWNER TO admin;
CREATE INDEX pos_doks_id1_knjig ON p15.pos_doks_knjig USING btree (idpos, idvd, datum, brdok);
CREATE INDEX pos_doks_id2_knjig ON p15.pos_doks_knjig USING btree (idvd, datum);
CREATE INDEX pos_doks_id3_knjig ON p15.pos_doks_knjig USING btree (idPartner, placen, datum);
-- CREATE INDEX pos_doks_id4_knjig ON p15.pos_doks_knjig USING btree (idvd, m1);
CREATE INDEX pos_doks_id5_knjig ON p15.pos_doks_knjig USING btree (prebacen);
CREATE INDEX pos_doks_id6_knjig ON p15.pos_doks_knjig USING btree (datum);


ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS funk;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS sto;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS sto_br;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS zak_br;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS idgost;
ALTER TABLE p15.pos_doks ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS idpartner varchar(6);
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS brdokStorn varchar(8);
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS smjena;

ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS funk;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS sto;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS sto_br;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS zak_br;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS idgost;
ALTER TABLE p15.pos_doks_knjig ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS idpartner varchar(6);
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS brdokStorn varchar(8);
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS smjena;

ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS iddio;
ALTER TABLE p15.pos_pos ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS smjena;

ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS iddio;
ALTER TABLE p15.pos_pos_knjig ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS smjena;

DROP TABLE IF EXISTS p15.pos_dokspf;
