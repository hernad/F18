CREATE SCHEMA IF NOT EXISTS p15;

ALTER SCHEMA p15 OWNER TO admin;

CREATE TABLE IF NOT EXISTS  p15.roba (
    id character(10) NOT NULL,
    sifradob character(20),
    naz character varying(250),
    jmj character(3),
    idtarifa character(6),
    mpc numeric(18,8),
    tip character(1),
    opis text,
    mink numeric(12,2),
    barkod character(13),
    fisc_plu numeric(10,0),
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
    placen character(1),
    vrijeme character varying(5),
    brdokStorn character varying(8),
    fisc_rn numeric(10,0),
    ukupno numeric(15,5),
    brFaktP varchar(10),
    opis varchar(100)
);
ALTER TABLE p15.pos_doks OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_pos (
    idpos character varying(2),
    idvd character varying(2),
    brdok character varying(6),
    datum date,
    idradnik character varying(4),
    idroba character(10),
    idtarifa character(6),
    kolicina numeric(18,3),
    kol2 numeric(18,3),
    cijena numeric(10,3),
    ncijena numeric(10,3),
    rbr character(3) NOT NULL
);
ALTER TABLE p15.pos_pos OWNER TO admin;

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

CREATE TABLE p15.pos_doks_knjig (
   idpos character varying(2) NOT NULL,
   idvd character varying(2) NOT NULL,
   brdok character varying(6) NOT NULL,
   datum date,
   idPartner character varying(6),
   idradnik character varying(4),
   idvrstep character(2),
   placen character(1),
   vrijeme character varying(5),
   brdokStorn character varying(8),
   fisc_rn numeric(10,0),
   ukupno numeric(15,5),
   brFaktP varchar(10),
   opis varchar(100)
);
ALTER TABLE p15.pos_doks_knjig OWNER TO admin;
CREATE INDEX pos_doks_id1_knjig ON p15.pos_doks_knjig USING btree (idpos, idvd, datum, brdok);
CREATE INDEX pos_doks_id2_knjig ON p15.pos_doks_knjig USING btree (idvd, datum);
CREATE INDEX pos_doks_id3_knjig ON p15.pos_doks_knjig USING btree (idPartner, placen, datum);
-- CREATE INDEX pos_doks_id4_knjig ON p15.pos_doks_knjig USING btree (idvd, m1);
-- CREATE INDEX pos_doks_id5_knjig ON p15.pos_doks_knjig USING btree (prebacen);
CREATE INDEX pos_doks_id6_knjig ON p15.pos_doks_knjig USING btree (datum);


CREATE TABLE p15.pos_pos_knjig (
   idpos character varying(2),
   idvd character varying(2),
   brdok character varying(6),
   datum date,
   -- idcijena character varying(1),
   --idodj character(2),
   idradnik character varying(4),
   idroba character(10),
   idtarifa character(6),
   -- m1 character varying(1),
   -- mu_i character varying(1),
   -- prebacen character varying(1),
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
CREATE INDEX pos_pos_id1_knjig ON p15.pos_pos_knjig USING btree (idpos, idvd, datum, brdok, idroba);
CREATE INDEX pos_pos_id2_knjig ON p15.pos_pos_knjig USING btree (idroba, datum);
-- CREATE INDEX pos_pos_id3_knjig ON p15.pos_pos_knjig USING btree (prebacen);
CREATE INDEX pos_pos_id4_knjig ON p15.pos_pos_knjig USING btree (datum);
CREATE INDEX pos_pos_id5_knjig ON p15.pos_pos_knjig USING btree (idpos, idroba, datum);
CREATE INDEX pos_pos_id6_knjig ON p15.pos_pos_knjig USING btree (idroba);
GRANT ALL ON TABLE p15.pos_pos_knjig TO xtrole;



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
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS rabat;
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS prebacen;
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS brFaktP varchar(10);
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS opis varchar(100);

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
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS rabat;
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS prebacen;
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS brFaktP varchar(10);
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS opis varchar(100);


ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS iddio;
ALTER TABLE p15.pos_pos ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS smjena;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS prebacen;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS mu_i;
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idcijena;
ALTER TABLE p15.pos_pos ALTER COLUMN rbr TYPE character(3);
ALTER TABLE p15.pos_pos ALTER COLUMN rbr SET NOT NULL;

ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS iddio;
ALTER TABLE p15.pos_pos_knjig ALTER COLUMN brdok TYPE varchar(8);
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_1;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_2;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_3;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS m1;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idodj;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS smjena;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS prebacen;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS mu_i;
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idcijena;
ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr TYPE character(3);
ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr SET NOT NULL;

ALTER TABLE p15.roba DROP COLUMN IF EXISTS k1;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS k2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS k7;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS k8;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS k9;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS n1;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS n2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS match_code;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS nc;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS vpc;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS carina;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS vpc2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc3;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc4;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc5;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc6;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc7;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc8;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS mpc9;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS _m1_;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS plc;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS zanivel;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS zaniv2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS trosk1;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS trosk2;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS trosk3;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS trosk4;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS trosk5;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS strings;
ALTER TABLE p15.roba DROP COLUMN IF EXISTS idkonto;


DROP TABLE IF EXISTS p15.pos_dokspf;

---------------------------------------------------------------------------------------
-- on kalk_kalk update p15.pos_pos_knjig
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_kalk_kalk_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    sql varchar;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=NEW.PKonto;
ELSE
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=OLD.PKonto;
END IF;


IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete prodavnica %', idPos;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update prodavnica %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN

      RAISE INFO 'insert prodavnica %', idPos;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_pos_knjig(idpos,idvd,brdok,datum,brFaktP,idroba,kolicina,cijena) VALUES($1,$2,$3,$4,$5,$6,$7)'
              USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.idroba, NEW.kolicina, NEW.mpcsapp;
      RAISE INFO 'sql: %', sql;

      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


---------------------------------------------------------------------------------------
-- on kalk_doks update p15.pos_doks_knjig
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_kalk_doks_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    sql varchar;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=NEW.PKonto;
ELSE
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=OLD.PKonto;
END IF;


IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete prodavnica %', idPos;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update prodavnica %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN

      RAISE INFO 'insert prodavnica %', idPos;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks_knjig(idpos,idvd,brdok,datum,brFaktP,idroba,kolicina,cijena) VALUES($1,$2,$3,$4,$5)'
              USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.brFaktP;
      RAISE INFO 'sql: %', sql;

      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;

-- fmk.kalk_kalk -> p15.pos_pos
CREATE TRIGGER pos_insert_upate_delete
   AFTER INSERT OR DELETE OR UPDATE
   ON fmk.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE public.on_kalk_kalk_insert_update_delete();


-- test
-- insert into fmk.kalk_doks(idfirma, idvd, brdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'XX', 1, '13322', 'R01', 10,  2)
-- insert into fmk.kalk_kalk(idfirma, idvd, brdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'XX', 1, '13322', 'R01', 10,  2)
--- delete from fmk.kalk_kalk where brdok='XX';



-- DO $$
-- BEGIN
--
--   BEGIN
--     ALTER TABLE p15.pos_pos_knjig ADD CONSTRAINT rbr NOT NULL;
--   EXCEPTION
--     WHEN duplicate_object THEN RAISE NOTICE 'Table constraint foo.bar already exists';
--   END;
--
-- END $$;
