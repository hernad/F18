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
CREATE INDEX pos_doks_id3_knjig ON p15.pos_doks_knjig USING btree (idPartner, datum);
CREATE INDEX pos_doks_id6_knjig ON p15.pos_doks_knjig USING btree (datum);

GRANT ALL ON TABLE p15.pos_doks_knjig TO xtrole;

CREATE TABLE p15.pos_pos_knjig (
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
   rbr character varying(5)
);
ALTER TABLE p15.pos_pos_knjig OWNER TO admin;
CREATE INDEX pos_pos_id1_knjig ON p15.pos_pos_knjig USING btree (idpos, idvd, datum, brdok, idroba);
CREATE INDEX pos_pos_id2_knjig ON p15.pos_pos_knjig USING btree (idroba, datum);
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
ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS placen;

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
ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS placen;


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
update p15.pos_pos set rbr = lpad(ltrim(rbr),3);
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
update p15.pos_pos_knjig set rbr = lpad(ltrim(rbr),3);
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
-- on kalk_kalk update p15.pos_pos_knjig, idvd = 11,19
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_kalk_kalk_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    sql varchar;
    cijena decimal;
    ncijena decimal;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '11' ) OR ( NEW.idvd <> '19' ) THEN
     RETURN NULL;
   END IF;
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=NEW.PKonto;
ELSE
   IF ( OLD.idvd <> '11' ) OR ( OLD.idvd <> '19' ) THEN
      RETURN NULL;
   END IF;
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=OLD.PKonto;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete prodavnica %', idPos;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_pos_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datdok, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update prodavnica!? %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN

      RAISE INFO 'insert prodavnica %', idPos;
      IF ( NEW.idvd = '19' ) THEN
        cijena := NEW.fcj;  -- stara cijena
        ncijena := NEW.mpcsapp + NEW.fcj; -- nova cijena
      ELSE
        cijena := NEW.mpcsapp;
        ncijena := 0;
      END IF;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_pos_knjig(idpos,idvd,brdok,datum,rbr,idroba,kolicina,cijena,ncijena) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.rbr, NEW.idroba, NEW.kolicina, cijena, ncijena;
      -- RAISE INFO 'sql: %', sql;

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
      IF ( NEW.idvd <> '11' ) OR ( NEW.idvd <> '19' ) THEN
         RETURN NULL;
      END IF;
      SELECT idprodmjes INTO idPos
            from fmk.koncij where id=NEW.PKonto;
ELSE
     IF ( OLD.idvd <> '11' ) OR ( OLD.idvd <> '19' ) THEN
        RETURN NULL;
     END IF;
      SELECT idprodmjes INTO idPos
            from fmk.koncij where id=OLD.PKonto;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete doks prodavnica %', idPos;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_doks_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
             USING idpos, OLD.idvd, OLD.brdok, OLD.datdok;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update doks prodavnica!? %', idPos;
          RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert doks prodavnica %', idPos;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks_knjig(idpos,idvd,brdok,datum,brFaktP) VALUES($1,$2,$3,$4,$5)'
            USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.brFaktP;
      RAISE INFO 'sql: %', sql;

      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- fmk.kalk_kalk -> p15.pos_pos
DROP TRIGGER IF EXISTS pos_insert_update_delete on fmk.kalk_kalk;
CREATE TRIGGER pos_insert_update_delete
   AFTER INSERT OR DELETE OR UPDATE
   ON fmk.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE public.on_kalk_kalk_insert_update_delete();

-- fmk.kalk_doks -> p15.pos_doks
DROP TRIGGER IF EXISTS pos_doks_insert_update_delete on fmk.kalk_doks;
CREATE TRIGGER pos_doks_insert_update_delete
      AFTER INSERT OR DELETE OR UPDATE
      ON fmk.kalk_doks
      FOR EACH ROW EXECUTE PROCEDURE public.on_kalk_doks_insert_update_delete();


-- test

-- step 1
-- insert into fmk.kalk_doks(idfirma, idvd, brdok, datdok, brfaktP, pkonto) values('10', '11', 'BRDOK01', current_date, 'FAKTP01', '13322');
-- insert into fmk.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 1, '13322', 'R01', 10,  2);
-- insert into fmk.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 2, '13322', 'R02', 20,  3);

-- step 2
-- select * from p15.pos_doks_knjig;
-- step 3
-- select * from p15.pos_pos_knjig;

-- step 4
-- delete from fmk.kalk_kalk where brdok='BRDOK01';
-- delete from fmk.kalk_doks where brdok='BRDOK01';

-- step 5
-- select * from p15.pos_doks_knjig;
-- step 6
-- select * from p15.pos_pos_knjig;


----------- TRIGERI na strani prodavnice POS_KNJIG -> POS ! -----------------------------------------------------

-- on p15.pos_doks_knjig -> p15.pos_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_doks_knjig_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar := '15';
    sql varchar;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_doks_knjig prodavnica %', idPos;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_doks WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datum;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_doks_knjig prodavnica!? %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert pos_doks_knjig prodavnica %', idPos;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks(idpos,idvd,brdok,datum,brFaktP) VALUES($1,$2,$3,$4,$5)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.brFaktP;
      RAISE INFO 'sql: %', sql;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;

---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on p15.pos_pos_knjig -> p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_pos_knjig_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar := '15';
    sql varchar;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_pos_knjig prodavnica %', idPos;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_pos_knjig prodavnica!? %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert pos_pos_knjig prodavnica %', idPos;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_pos(idpos,idvd,brdok,datum,rbr,idroba,kolicina,cijena,ncijena) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena;
      RAISE INFO 'sql: %', sql;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks_knjig -> p15.pos_doks
DROP TRIGGER IF EXISTS pos_doks_knjig_insert_update_delete on p15.pos_doks_knjig;
CREATE TRIGGER pos_doks_knjig_insert_update_delete
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_doks_knjig
      FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_doks_knjig_insert_update_delete();

-- p15.pos_pos_knjig -> p15.pos_pos
DROP TRIGGER IF EXISTS pos_pos_knjig_insert_update_delete on p15.pos_pos_knjig;
CREATE TRIGGER pos_pos_knjig_insert_update_delete
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_pos_knjig
   FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_pos_knjig_insert_update_delete();



----------- TRIGERI na strani knjigovodstva POS_DOKS - KALK_DOKS ! -----------------------------------------------------

-- on p15.pos_doks -> fmk.kalk_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_doks_insert_update_delete() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) THEN -- samo 42-ke
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
   -- 01.02.2019, idpos=15 -> 0102/15
   SELECT TO_CHAR(NEW.datum, 'ddmm/' || NEW.idpos ) INTO brDok;
ELSE
   IF ( OLD.idvd <> '42' ) THEN -- samo 42-ke
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
       from fmk.koncij where idprodmjes=OLD.idpos;
   SELECT TO_CHAR(OLD.datum, 'ddmm/' || OLD.idpos ) INTO brDok;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_doks %  %  % %', pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING pKonto, OLD.idvd, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_doks !? % %', pKonto, brDok;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
         RAISE INFO 'FIRST delete kalk_doks  % % %', pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, NEW.idvd, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_doks S0 % % %', pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_doks(idfirma,idvd,brdok,datdok,pkonto) VALUES($1,$2,$3,$4,$5)'
                     USING 'S0', NEW.idvd, brDok, NEW.datum, pKonto;
         RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


--- fmk.rbr_to_char(45) -> ' 45'
CREATE OR REPLACE FUNCTION fmk.rbr_to_char(num integer) RETURNS varchar
    LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        RETURN lpad(btrim(to_char(num, '999')),3);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid integer value: "%".  Returning ***.', num;
        RETURN '***';
    END;
RETURN '***';
END;
$$;


----------- TRIGERI na strani knjigovodstva POS - KALK_KALK ! -----------------------------------------------------

-- on p15.pos_pos -> fmk.kalk_kalk
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_pos_insert_update_delete() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) THEN -- samo 42-ke
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
   -- 01.02.2019, idpos=15 -> 0102/15
   SELECT TO_CHAR(NEW.datum, 'ddmm/' || NEW.idpos ) INTO brDok;
ELSE
   IF ( OLD.idvd <> '42' ) THEN -- samo 42-ke
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
       from fmk.koncij where idprodmjes=OLD.idpos;
   SELECT TO_CHAR(OLD.datum, 'ddmm/' || OLD.idpos ) INTO brDok;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_kalk %  %  % %', pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING pKonto, OLD.idvd, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_kalk !? % %', pKonto, brDok;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
         RAISE INFO 'FIRST delete kalk_kalk  % % %', pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, NEW.idvd, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_kalk S0 % % %', pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina) ' ||
                 '(SELECT $1 as idfirma, $2 as idvd,' ||
                 ' (fmk.rbr_to_char( (row_number() over (order by idroba))::integer))::character(3) as rbr,' ||
                 ' $3 as brdok, $4 as datdok,$6 as pkonto, idroba, idtarifa, cijena as mpcsapp, sum(kolicina) as kolicina ' ||
                 ' FROM p' || NEW.idpos || '.pos_pos ' ||
                 ' WHERE idvd=$2 AND datum=$4 AND idpos=$5' ||
                 ' GROUP BY idroba,idtarifa,cijena,ncijena' ||
                 ' ORDER BY idroba)'
              USING 'S0', NEW.idvd, brDok, NEW.datum, NEW.idpos, pKonto;
         RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks -> fmk.kalk_doks
DROP TRIGGER IF EXISTS  pos_doks_insert_update_delete on p15.pos_doks;
CREATE TRIGGER pos_doks_insert_update_delete
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_doks
   FOR EACH ROW EXECUTE PROCEDURE public.on_pos_doks_insert_update_delete();

-- p15.pos_pos -> fmk.kalk_kalk
DROP TRIGGER IF EXISTS  pos_pos_insert_update_delete on p15.pos_pos;
CREATE TRIGGER pos_pos_insert_update_delete
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_pos
      FOR EACH ROW EXECUTE PROCEDURE public.on_pos_pos_insert_update_delete();

-- test pos->knjig

-- step 1
-- delete from p15.pos_doks where brdok='BRDOK01' and idvd='42';
-- insert into p15.pos_doks(idpos, idvd, brdok, datum) values('15', '42', 'BRDOK01', current_date);
-- insert into p15.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '42', 'BRDOK01', current_date, '  1', 'R01', 5, 2.5, 0, 'PDV17');

-- step 3
-- select * from p15.pos_doks where datum=current_date and idvd='42';

-- step 4
-- select * from fmk.kalk_doks where brdok=TO_CHAR(current_date, 'ddmm/15') and idvd='42';

-- delete from p15.pos_pos where brdok='BRDOK01';


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
