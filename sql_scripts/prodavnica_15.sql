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
    brdok character varying(8) NOT NULL,
    datum date,
    idPartner character varying(6),
    idradnik character varying(4),
    idvrstep character(2),
    vrijeme character varying(5),
    brdokStorn character varying(8),
    fisc_rn numeric(10,0),
    ukupno numeric(15,5),
    brFaktP varchar(10),
    opis varchar(100),
    dat_od date,
    dat_do date
);
ALTER TABLE p15.pos_doks OWNER TO admin;

CREATE TABLE IF NOT EXISTS p15.pos_pos (
    idpos character varying(2),
    idvd character varying(2),
    brdok character varying(8),
    datum date,
    idroba character(10),
    idtarifa character(6),
    kolicina numeric(18,3),
    kol2 numeric(18,3),
    cijena numeric(10,3),
    ncijena numeric(10,3),
    rbr integer NOT NULL,
    robanaz varchar,
    jmj varchar
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

CREATE TABLE IF NOT EXISTS p15.vrstep (
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
   brdok character varying(8) NOT NULL,
   datum date,
   idPartner character varying(6),
   idradnik character varying(4),
   idvrstep character(2),
   vrijeme character varying(5),
   brdokStorn character varying(8),
   fisc_rn numeric(10,0),
   ukupno numeric(15,5),
   brFaktP varchar(10),
   opis varchar(100),
   dat_od date,
   dat_do date
);
ALTER TABLE p15.pos_doks_knjig OWNER TO admin;
CREATE INDEX pos_doks_id1_knjig ON p15.pos_doks_knjig USING btree (idpos, idvd, datum, brdok);
CREATE INDEX pos_doks_id2_knjig ON p15.pos_doks_knjig USING btree (idvd, datum);
CREATE INDEX pos_doks_id3_knjig ON p15.pos_doks_knjig USING btree (idPartner, datum);
CREATE INDEX pos_doks_id6_knjig ON p15.pos_doks_knjig USING btree (datum);

GRANT ALL ON TABLE p15.pos_doks_knjig TO xtrole;

CREATE TABLE IF NOT EXISTS p15.pos_pos_knjig (
   idpos character varying(2),
   idvd character varying(2),
   brdok character varying(8),
   datum date,
   idroba character(10),
   idtarifa character(6),
   kolicina numeric(18,3),
   kol2 numeric(18,3),
   cijena numeric(10,3),
   ncijena numeric(10,3),
   rbr integer,
   robanaz varchar,
   jmj varchar
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
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS dat_od date;
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS dat_do date;
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
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS dat_od date;
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS dat_do date;
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
ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idradnik;
--update p15.pos_pos set rbr = lpad(ltrim(rbr),3);
--ALTER TABLE p15.pos_pos ALTER COLUMN rbr TYPE character(3);
--ALTER TABLE p15.pos_pos ALTER COLUMN rbr TYPE integer;
ALTER TABLE p15.pos_pos ALTER COLUMN rbr SET NOT NULL;
ALTER TABLE p15.pos_pos ADD COLUMN IF NOT EXISTS robanaz varchar;


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
ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idradnik;
--update p15.pos_pos_knjig set rbr = lpad(ltrim(rbr),3);
--ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr TYPE character(3);
ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr SET NOT NULL;
ALTER TABLE p15.pos_pos_knjig ADD COLUMN IF NOT EXISTS robanaz varchar;

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
-- on kalk_kalk update p15.pos_pos_knjig,
-- idvd = 19 - nivelacija prodavnica,
--        02 - pocetno stanje prodavnica
--        21 - zahtjev za prijem robe iz magacina
--        80 - prijem prodavnica
--        79 - odobreno snizenje
--        72 - akcijske cijene
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION f18.on_kalk_kalk_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    cijena decimal;
    ncijena decimal;
    barkodRoba varchar DEFAULT '';
    robaNaz varchar;
    robaJmj varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '19' ) AND ( NEW.idvd <> '02' ) AND ( NEW.idvd <> '21' ) AND ( NEW.idvd <> '80' ) AND ( NEW.idvd <> '79' ) AND ( NEW.idvd <> '72' ) THEN
     RETURN NULL;
   END IF;
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=NEW.PKonto;
   SELECT barkod, naz, jmj INTO barkodRoba, robaNaz, robaJmj
          from fmk.roba where id=NEW.idroba;
ELSE
   IF ( OLD.idvd <> '19' ) AND ( OLD.idvd <> '02' ) AND ( OLD.idvd <> '21' ) AND ( OLD.idvd <> '80' ) AND ( OLD.idvd <> '79' ) AND ( OLD.idvd <> '72' ) THEN
      RETURN NULL;
   END IF;
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=OLD.PKonto;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete % prodavnica %', OLD.idvd, idPos;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_pos_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datdok, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update % prodavnica!? %', NEW.idvd, idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert % prodavnica % % %', NEW.idvd, idPos, NEW.idroba, public.barkod_ean13_to_num(barkodRoba,3);
      IF ( NEW.idvd = '19' ) OR ( NEW.idvd = '79' ) OR ( NEW.idvd = '72' ) THEN
        cijena := NEW.fcj;  -- stara cijena
        ncijena := NEW.mpcsapp + NEW.fcj; -- nova cijena
      ELSE
        cijena := NEW.mpcsapp;
        ncijena := 0;
      END IF;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_pos_knjig(idpos,idvd,brdok,datum,rbr,idroba,kolicina,cijena,ncijena,kol2,idtarifa,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.rbr, NEW.idroba, NEW.kolicina, cijena, ncijena, public.barkod_ean13_to_num(barkodRoba,3), NEW.idtarifa, robaNaz,robaJmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


---------------------------------------------------------------------------------------
-- on kalk_doks update p15.pos_doks_knjig
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION f18.on_kalk_doks_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
      IF ( NEW.idvd <> '19' ) AND ( NEW.idvd <> '02' ) AND ( NEW.idvd <> '21' ) AND ( NEW.idvd <> '80' ) AND ( NEW.idvd <> '79' ) AND ( NEW.idvd <> '72' ) THEN
         RETURN NULL;
      END IF;
      SELECT idprodmjes INTO idPos
            from fmk.koncij where id=NEW.PKonto;
ELSE
     IF ( OLD.idvd <> '19' ) AND ( OLD.idvd <> '02' ) AND ( OLD.idvd <> '21' ) AND ( OLD.idvd <> '80' ) AND ( OLD.idvd <> '79' ) AND ( OLD.idvd <> '72' ) THEN
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
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks_knjig(idpos,idvd,brdok,datum,brFaktP,dat_od,dat_do,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8)'
            USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.brFaktP, NEW.dat_od, NEW.dat_do, NEW.opis;

      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- f18.kalk_kalk -> p15.pos_pos_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_crud on f18.kalk_kalk;
CREATE TRIGGER t_kalk_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON f18.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE f18.on_kalk_kalk_crud();

-- f18.kalk_doks -> p15.pos_doks_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_doks_crud on f18.kalk_doks;
CREATE TRIGGER t_kalk_doks_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON f18.kalk_doks
      FOR EACH ROW EXECUTE PROCEDURE f18.on_kalk_doks_crud();


-- test

-- step 1
-- insert into public.kalk_doks(idfirma, idvd, brdok, datdok, brfaktP, pkonto) values('10', '11', 'BRDOK01', current_date, 'FAKTP01', '13322');
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 1, '13322', 'R01', 10,  2);
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 2, '13322', 'R02', 20,  3);

-- step 2
-- select * from p15.pos_doks_knjig;
-- step 3
-- select * from p15.pos_pos_knjig;

-- step 4
-- delete from public.kalk_kalk where brdok='BRDOK01';
-- delete from public.kalk_doks where brdok='BRDOK01';

-- step 5
-- select * from p15.pos_doks_knjig;
-- step 6
-- select * from p15.pos_pos_knjig;


CREATE TABLE IF NOT EXISTS p15.pos_stanje (
   id SERIAL,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   ulazi text[],
   izlazi text[],
   kol_ulaz numeric(18,3),
   kol_izlaz numeric(18,3),
   cijena numeric(10,3),
   ncijena numeric(10,3)
);
ALTER TABLE p15.pos_stanje OWNER TO admin;
GRANT ALL ON TABLE p15.pos_stanje TO xtrole;
GRANT ALL ON SEQUENCE p15.pos_stanje_id_seq TO xtrole;

ALTER TABLE p15.pos_stanje ALTER COLUMN dat_od SET NOT NULL;
ALTER TABLE p15.pos_pos ALTER COLUMN idroba SET NOT NULL;
ALTER TABLE p15.pos_pos ALTER COLUMN cijena SET NOT NULL;


----------- TRIGERI na strani prodavnice POS_KNJIG -> POS ! -----------------------------------------------------

-- on p15.pos_doks_knjig -> p15.pos_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_doks_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar := '15';
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
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks(idpos,idvd,brdok,datum,brFaktP,dat_od,dat_do,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.brFaktP, NEW.dat_od, NEW.dat_do, NEW.opis;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


CREATE OR REPLACE FUNCTION p15.pos_prijem_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric,
   ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
BEGIN

IF ( idvd <> '02' ) AND ( idvd <> '80' ) AND ( idvd <> '89' ) AND ( idvd <> '22' ) THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF dat_od IS NULL then
  dat_do := '1999-01-01';
END IF;
IF dat_do IS NULL then
  dat_do := '3999-01-01';
END IF;

IF transakcija = '-' THEN -- on delete pos_pos stavka
   -- treba da se poklope sve ove stavke: idroba / cijena / ncijena / dat_do, a da zadani dat_od bude >= od analiziranog
   RAISE INFO 'in_pos_prijem_update_stanje delete = % % % % % %', dokument, idroba, cijena, ncijena, dat_od, dat_do;
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(ulazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- slijedi + transakcija on insert pos_pos
-- (dat_od <= current_date AND dat_do >= current_date) = aktuelna cijena
-- novi dat_od mora biti >= dat_od analiziranog zapisa, novi dat_do = dat_do zapisa
-- 'ORDER BY kol_ulaz - kol_izlaz LIMIT 1' obezbjedjuje da stavke koji su negativne
-- (znaci nedostaju im ulazi) napunimo ulazom, LIMIT 1 - stavka sa najmanjom kolicinom
--
--  $4 <= current_date => dat_od otpremnice manji ili jednak danasnjem datumu, znaci da je aktuelan
EXECUTE  'select id from p' || idPos || '.pos_stanje where  (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND kol_ulaz - kol_izlaz <> 0 AND cijena = $2 AND  ncijena = $3 AND $4 <= current_date AND dat_do = $5' ||
         ' ORDER BY kol_ulaz - kol_izlaz LIMIT 1'
      using idroba, cijena, ncijena, dat_od, dat_do
      INTO idRaspolozivo;

RAISE INFO 'in_pos_prijem_update_stanje + idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE
   -- u ovom narednom upitu cemo provjeriti postoji li ranija stavka koja moze biti i negativna
   -- koja je aktuelna
   EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND ncijena = $3 AND kol_ulaz - kol_izlaz <> 0'
    using idroba, cijena, ncijena
    INTO idRaspolozivo;

   IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
        ' WHERE id=$2'
         USING kolicina, idRaspolozivo, dokument;
   ELSE
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
        ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
   END IF;
END IF;

RETURN TRUE;

END;
$$;

-- delete from p15.pos_stanje;
--
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK00', '1', current_date-5, current_date-5, NULL,'R01', 40, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '2', current_date, current_date, NULL,'R01', 100, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '10', current_date, current_date, NULL,'R01',  50, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '1', current_date, current_date, NULL,'R01',  20, 2.0, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '1', current_date, current_date, NULL,'R02',  30,   3, 0);

-- select * from p15.pos_stanje;

-- select p15.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '10', current_date, current_date, NULL, 'R01',  50, 2.5, 0);

-- select * from p15.pos_stanje;

-- select id, ulazi from p15.pos_stanje where '15-11-BRDOK01-20190211' = ANY(ulazi)


CREATE OR REPLACE FUNCTION p15.pos_izlaz_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric, ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
   dat_do date DEFAULT '3999-01-01';
BEGIN

IF ( idvd <> '42' )  THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF (transakcija = '-') THEN -- on delete pos_pos stavka
   RAISE INFO 'pos_stanje % % % %', dokument, idroba, cijena, ncijena;
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(izlazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- slijedi + transakcija on insert pos_pos
-- (dat_od <= current_date AND dat_do >= current_date ) - cijena je aktuelna
EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND kol_ulaz - kol_izlaz > 0 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

RAISE INFO 'idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE -- kod izlaza se insert desava samo ako ako roba ide u minus !

  -- u ovom naraednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu
  EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
           ' VALUES($1,$2,$3,$4,$5,0,$6,$7,$8)'
           USING datum, dat_do, idroba, '{}'::text[], dokumenti, kolicina, cijena, ncijena, dat_do;
  END IF;

END IF;

RETURN TRUE;

END;
$$;

-- prodaja
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD01', '1', current_date, 'R01', 60, 2.5, 0);
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD03', '5',current_date, 'R02', 20, 3, 0);
--
-- -- robe ima, ali ce je ova transakcija otjerati u minus
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD90', '1', current_date, 'R01', 500, 2.5, 0);
-- -- nastavljamo sa minusom; minus se gomila na jednoj stavki
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD91', '1', current_date, 'R01',  40, 2.5, 0);
--
-- -- ove robe nema na stanju
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD10', '1', current_date, 'R03', 10, 30, 0);
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD11', '15', current_date, 'R03', 20, 30, 0);



CREATE OR REPLACE FUNCTION p15.pos_promjena_cijena_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric,
   ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
BEGIN

IF ( idvd <> '19' ) AND ( idvd <> '29' ) AND ( idvd <> '79' ) THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF dat_od IS NULL then
  dat_do := '1999-01-01';
END IF;
IF dat_do IS NULL then
  dat_do := '3999-01-01';
END IF;

IF transakcija = '-' THEN -- on delete pos_pos stavka

   RAISE INFO 'delete = % % % % % %', dokument, idroba, cijena, ncijena, dat_od, dat_do;
   -- (1) ponistiti izlaz koji je nivelacija napravila
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(izlazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument ulaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   -- (2) ponistiti ulaz koji je nivelacija napravila
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(ulazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument izlaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- raspoloziva roba po starim cijenama, kolicina treba biti > 0
-- ncijena=0, gledaju se samo OSNOVNE cijene
EXECUTE  'select id from p' || idPos || '.pos_stanje where  (dat_od <= current_date AND dat_do >= current_date )' ||
         ' AND idroba = $1 AND kol_ulaz - kol_izlaz > 0 AND cijena = $2 AND  ncijena = 0 AND $3 <= current_date AND $4 <= dat_do' ||
         ' ORDER BY kol_ulaz - kol_izlaz LIMIT 1'
      using idroba, cijena, dat_od, dat_do
      INTO idRaspolozivo;

RAISE INFO 'idDokument = % % %', idRaspolozivo, dat_od, dat_do;

IF NOT idRaspolozivo IS NULL then
  -- umanjiti - 'iznijeti' zalihu po starim cijenama
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;
  -- dodati zalihu po novim cijenama
  IF ( idvd = '19' ) OR ( idvd = '29' ) THEN
      cijena := ncijena; -- nivelacija - nova cijena postaje osnovna
      ncijena := 0;
  END IF;

  -- u ovom narednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu
  EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      -- ako postoji onda ovu nivelaciju dodati na tu predhodnu prodaju
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
             ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
          USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
  END IF;


ELSE
  -- nema dostupne zalihe za promjenu ?!
  RAISE INFO 'ERROR_PROMJENA_CIJENA: nema dostupne zalihe za promjenu cijena % % % %', idvd, brdok, dat_od, dat_do;
END IF;

RETURN TRUE;

END;
$$;


---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on p15.pos_pos_knjig -> p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_pos_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar := '15';
    robaId varchar;
    robaCijena numeric;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_pos_knjig prodavnica % %', idPos, OLD.idvd;
      EXECUTE 'DELETE FROM p' || idPos || '.pos_pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_pos_knjig prodavnica!? %', idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'FIRST insert/update roba u prodavnici';
      EXECUTE 'SELECT id from p' || idPos || '.roba WHERE id=$1'
         USING NEW.idroba
         INTO robaId;

      IF (NEW.idvd = '19') THEN
         robaCijena := NEW.ncijena;
      ELSE
         robaCijena := NEW.cijena;
      END IF;

      IF NOT robaId IS NULL THEN -- roba postoji u sifarniku
         EXECUTE 'UPDATE p' || idPos || '.roba  SET barkod=$2, idtarifa=$3, naz=$4, mpc=$5, jmj=$6 WHERE id=$1'
           USING robaId, public.num_to_barkod_ean13(NEW.kol2, 3), NEW.idtarifa, NEW.robanaz, robaCijena, NEW.jmj;
      ELSE
         EXECUTE 'INSERT INTO p' || idPos || '.roba(id,barkod,mpc,idtarifa,naz,jmj) values($1,$2,$3,$4,$5,$6)'
           USING NEW.idroba, public.num_to_barkod_ean13(NEW.kol2, 3), robaCijena, NEW.idtarifa, NEW.robanaz, NEW.jmj;
      END IF;

      RAISE INFO 'insert pos_pos_knjig prodavnica % %', idPos, NEW.idvd;
      EXECUTE 'INSERT INTO p' || idPos || '.pos_pos(idpos,idvd,brdok,datum,rbr,idroba,idtarifa,kolicina,cijena,ncijena,kol2,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr, NEW.idroba, NEW.idtarifa,NEW.kolicina, NEW.cijena, NEW.ncijena, NEW.kol2, NEW.robanaz, NEW.jmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks_knjig -> p15.pos_doks
DROP TRIGGER IF EXISTS pos_doks_knjig_crud on p15.pos_doks_knjig;
CREATE TRIGGER pos_doks_knjig_insert_update_delete
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_doks_knjig
      FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_doks_knjig_crud();

-- p15.pos_pos_knjig -> p15.pos_pos
DROP TRIGGER IF EXISTS pos_pos_knjig_crud on p15.pos_pos_knjig;
CREATE TRIGGER pos_pos_knjig_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_pos_knjig
   FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_pos_knjig_crud();

-- POS 42 - racuni, zbirno u KALK
-- SELECT public.kalk_brdok_iz_pos('15', '49', '4', current_date); => 150214
-- POS 71 - dokument, zahtjev za snizenje - pojedinacno u KALK
-- SELECT public.kalk_brdok_iz_pos('15', '71', '    3', current_date); => 15021403

CREATE OR REPLACE FUNCTION public.kalk_brdok_iz_pos(
   idpos varchar,
   idvdKalk varchar,
   posBrdok varchar,
   datum date) RETURNS varchar

LANGUAGE plpgsql
AS $$
DECLARE
  brdok varchar;
BEGIN

IF ( idvdKalk = '49' ) THEN
  -- 01.02.2019, idpos=15 -> 150201
  SELECT TO_CHAR(datum, idpos || 'mmdd' ) INTO brDok;
ELSIF ( ( idvdKalk = '71' ) OR ( idvdKalk = '61' ) OR ( idvdKalk = '22' ) OR ( idvdKalk = '29' ) ) THEN
   -- 01.02.2019, brdok='      3' -> 15020103
   SELECT TO_CHAR(datum, idpos || 'mmdd' ) || lpad(btrim(posBrdok), 2, '0') INTO brDok;
ELSE
   RAISE EXCEPTION 'ERROR kalk_brdok_iz_pos % % % %', idPos, idvdKalk, posBrdok, datum;
END IF;

RETURN brDok;

END;
$$

----------- TRIGERI na strani knjigovodstva POS_DOKS - KALK_DOKS ! -----------------------------------------------------

-- on p15.pos_doks -> f18.kalk_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_doks_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
       idFirma varchar;
       idvdKalk varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   --  42 - prodaja, 71-zahtjev snizenje, 61-zahtjev narudzba, 22 -pos potvrda prijema magacin, 29 - pos nivelacija
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '71' ) AND ( NEW.idvd <> '61' ) AND ( NEW.idvd <> '22' ) AND ( NEW.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
  IF ( NEW.idvd = '42') THEN
       idvdKalk := '49';
   ELSE
       idvdKalk := NEW.idvd;
   END IF;
   SELECT public.kalk_brdok_iz_pos(NEW.idpos, idvdKalk, NEW.brdok, NEW.datum)
          INTO brDok;
ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '71' ) AND ( OLD.idvd <> '61' ) AND ( OLD.idvd <> '22' ) AND ( OLD.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
      from fmk.koncij where idprodmjes=OLD.idpos;
   IF ( OLD.idvd = '42') THEN
        idvdKalk := '49';
    ELSE
        idvdKalk := OLD.idvd;
    END IF;
    SELECT public.kalk_brdok_iz_pos(OLD.idpos, idvdKalk, OLD.brdok, OLD.datum)
         INTO brDok;
END IF;

SELECT fmk.fetchmetrictext('org_id') INTO idFirma;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_doks % % % % %', idFirma, pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE idfirma=$1 AND pkonto=$2 AND idvd=$3 AND datdok=$4 AND brdok=$5'
            USING idFirma, pKonto, idvdKalk, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_doks !? % % %', pKonto, brDok, idvdKalk;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
         RAISE INFO 'FIRST delete kalk_doks % % % %', idFirma, pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE idFirma=$1 AND pkonto=$2 AND idvd=$3 AND datdok=$4 AND brDok=$5'
                USING idFirma, pKonto, idvdKalk, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_doks % % % %', idFirma, pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_doks(idfirma,idvd,brdok,datdok,pkonto,dat_od,dat_do,idPartner,brFaktP,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                     USING idFirma, idvdKalk, brDok, NEW.datum, pKonto, NEW.dat_od, NEW.dat_do, NEW.idPartner, NEW.brFaktP, NEW.opis;
         RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


--- fmk.rbr_to_char(45) -> ' 45'
-- CREATE OR REPLACE FUNCTION fmk.rbr_to_char(num integer) RETURNS varchar
--     LANGUAGE plpgsql
-- AS $$
-- BEGIN
--     BEGIN
--         RETURN lpad(btrim(to_char(num, '999')),3);
--     EXCEPTION WHEN OTHERS THEN
--         RAISE NOTICE 'Invalid integer value: "%".  Returning ***.', num;
--         RETURN '***';
--     END;
-- RETURN '***';
-- END;
-- $$;


CREATE OR REPLACE FUNCTION public.barkod_ean13_to_num(barkod varchar, dec_mjesta integer) returns numeric
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    -- 1234567890123 => 1234567890.123
    IF (dec_mjesta = 3) THEN
      RETURN to_number(barkod, '0999999999999') / 1000;
    ELSE
      RETURN to_number(barkod, '0999999999999') / 1000000;
    END IF;
  EXCEPTION WHEN OTHERS THEN
       RETURN -1;
  END;
END;
$$;

CREATE OR REPLACE FUNCTION public.num_to_barkod_ean13(barkod numeric, dec_mjesta integer) returns text
LANGUAGE plpgsql
AS $$
BEGIN
   IF (barkod < 0) THEN
      RETURN '';
   ELSE
      ---  1234567890.123 => 1234567890123
      IF (dec_mjesta = 3) THEN
         RETURN replace(btrim(to_char(barkod , '0999999999.990')), '.','');
      ELSE
         RETURN replace(btrim(to_char(barkod , '0999999.999990')), '.','');
      END IF;
   END IF;
END;
$$;



----------- TRIGERI na strani kase radi pracenja stanja -----------------------------------------------------

-- on p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_kasa_pos_pos_insert_update_delete() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
    idPos varchar := '15';
    lRet boolean;
    datOd date;
    datDo date;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF (NEW.idvd <> '42') AND (NEW.idvd <> '02') AND (NEW.idvd <> '22') AND (NEW.idvd <> '80') AND (NEW.idvd <> '29') AND (NEW.idvd <> '19') AND (NEW.idvd <> '79') AND (NEW.idvd <> '89')  THEN   -- 42, 11, 80, 19, 79, 89
      RETURN NULL;
   END IF;
ELSE
   IF (OLD.idvd <> '42') AND ( OLD.idvd <> '02') AND ( OLD.idvd <> '22') AND (OLD.idvd <> '80') AND (OLD.idvd <> '29') AND (OLD.idvd <> '19') AND (OLD.idvd <> '79') AND (OLD.idvd <> '89')  THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'DELETE') AND ( OLD.idvd = '42' ) THEN
      RAISE INFO 'delete izlaz pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select p15.pos_izlaz_update_stanje('-', '15', '42', 'PROD91', '5', current_date, 'R01',  40, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''-'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
         USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum,  OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
         INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( (OLD.idvd='02') OR (OLD.idvd='22') OR (OLD.idvd='80') OR (OLD.idvd='89') ) THEN
      RAISE INFO 'delete pos_prijem_update_stanje  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select p15.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '999', current_date, current_date, NULL, 'R01',  50, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''-'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
               USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
               INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( (OLD.idvd = '19') OR (OLD.idvd = '29') OR (OLD.idvd='79') ) THEN
        RAISE INFO 'delete pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
        EXECUTE 'SELECT p' || idPos || '.pos_promjena_cijena_update_stanje(''-'', $1,$2,$3,$4,$5,$5,NULL,$6,$7,$8,$9)'
                   USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
                   INTO lRet;
        -- RAISE INFO 'delete  ret=%', lRet;
        RETURN OLD;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd = '42' ) THEN
       RAISE INFO 'update 42 pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr ;
       RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( (NEW.idvd = '02') OR (NEW.idvd = '22') OR (NEW.idvd = '80') OR (NEW.idvd = '89') ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( (NEW.idvd = '19') OR (NEW.idvd = '29') OR (NEW.idvd = '79') ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN
        RAISE INFO 'insert 42 pos_pos  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD10', '999', current_date, 'R03', 10, 30, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
              USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum,  NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
              INTO lRet;
        RAISE INFO 'insert 42 ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( (NEW.idvd = '02') OR (NEW.idvd = '22') OR ( NEW.idvd = '80') OR ( NEW.idvd = '89') ) THEN
        RAISE INFO 'insert pos_prijem_update_stanje % % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.rbr;
        -- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '999', current_date, current_date, NULL,'R01', 100, 2.5, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''+'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
             RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( (NEW.idvd = '19') OR (NEW.idvd = '29') OR (NEW.idvd = '79') ) THEN
        RAISE INFO 'insert pos_pos % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- u pos_doks se nalazi dat_od, dat_do
        EXECUTE 'SELECT dat_od, dat_do FROM p' || idPos || '.pos_doks WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
           USING idPos, NEW.idvd, NEW.brdok, NEW.datum
           INTO datOd, datDo;
        IF datOd IS NULL THEN
           RAISE EXCEPTION 'pos_doks % % % % NE postoji?!', idPos, NEW.idvd, NEW.brdok, NEW.datum;
        END IF;

        EXECUTE 'SELECT p' || idPos || '.pos_promjena_cijena_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, datOd, datDo, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
        RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;

-- p15.pos_pos na kasi
DROP TRIGGER IF EXISTS  kasa_pos_pos_insert_update_delete on p15.pos_pos;
CREATE TRIGGER kasa_pos_pos_insert_update_delete
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_pos
      FOR EACH ROW EXECUTE PROCEDURE p15.on_kasa_pos_pos_insert_update_delete();



----------- TRIGERI na strani knjigovodstva POS - KALK_KALK ! -----------------------------------------------------

-- on p15.pos_pos -> f18.kalk_kalk
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_pos_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
       pdvStopa numeric;
       idFirma varchar;
       idvdKalk varchar;
       pUI varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '71' ) AND ( NEW.idvd <> '61' ) AND ( NEW.idvd <> '22' ) AND ( NEW.idvd <> '29' ) THEN -- samo 42-prodaja, 71-zahtjev za snizenje, 61-zahtjev narudzba, 22-pos potvrda prijema magacin
      RETURN NULL;
   END IF;
   IF ( NEW.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := NEW.idvd;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
   brDok := public.kalk_brdok_iz_pos(NEW.idpos, idvdKalk, NEW.brdok, NEW.datum);

ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '71' ) AND ( OLD.idvd <> '61' ) AND ( OLD.idvd <> '22' ) AND ( OLD.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   IF ( OLD.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := OLD.idvd;
   END IF;
   SELECT id INTO pKonto
       from fmk.koncij where idprodmjes=OLD.idpos;
   brDok := public.kalk_brdok_iz_pos(OLD.idpos, idvdKalk, OLD.brdok, OLD.datum);
END IF;

SELECT fmk.fetchmetrictext('org_id') INTO idFirma;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_kalk % % % %', pKonto, idVdKalk, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING pKonto, idvdKalk, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_kalk !? % % %', pKonto, brDok, idvdKalk;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN -- 42 POS => 49 KALK
         RAISE INFO 'FIRST delete kalk_kalk % % % %', idvdKalk, pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, idvdKalk, NEW.datum, brDok;
         RAISE INFO 'THEN insert POS 42 => kalk_kalk % % % % %', NEW.idpos, idvdKalk, brDok, NEW.datum, pKonto;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj) ' ||
                 '(SELECT $1 as idfirma, $2 as idvd,' ||
                 ' (row_number() over (order by idroba))::integer as rbr,' ||
                 ' $3 as brdok, $4 as datdok,$6 as pkonto, idroba, idtarifa, cijena as mpcsapp, sum(kolicina) as kolicina, ' ||
                 ' cijena/(1 + tarifa.pdv/100) as mpc, 0.00000001 as nc, 0.00000001 as fcj' ||
                 ' FROM p' || NEW.idpos || '.pos_pos ' ||
                 ' LEFT JOIN public.tarifa on pos_pos.idtarifa = tarifa.id' ||
                 ' WHERE idvd=''42'' AND datum=$4 AND idpos=$5' ||
                 ' GROUP BY idroba,idtarifa,cijena,ncijena,tarifa.pdv' ||
                 ' ORDER BY idroba)'
              USING idFirma, idvdKalk, brDok, NEW.datum, NEW.idpos, pKonto;
         RETURN NEW;

  ELSIF (TG_OP = 'INSERT') AND  (( NEW.idvd = '61' ) OR ( NEW.idvd = '22' )) THEN

                EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                       USING NEW.idtarifa
                       INTO pdvStopa;
                RAISE INFO 'THEN insert kalk_kalk % % % % %', NEW.idpos, idvdKalk, pKonto, brDok, NEW.datum;
                -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
                -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
                EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc) ' ||
                         'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $12/100), $11)'
                        USING idFirma, idvdKalk, NEW.rbr, brDok, NEW.datum, pKonto, NEW.idroba, NEW.idtarifa,
                        NEW.cijena, NEW.kolicina, 0, pdvStopa;
                 RETURN NEW;

  -- 71 - zahtjev snizenje, 29 - pos nivelacija generisana na osnovu akcijskih cijena
  ELSIF (TG_OP = 'INSERT') AND (( NEW.idvd = '71' ) OR ( NEW.idvd = '29' )) THEN

         IF (NEW.idvd = '29') THEN
             pUI := '3';
         ELSE
             pUI := '%';
         END IF;
         EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                USING NEW.idtarifa
                INTO pdvStopa;
         RAISE INFO 'THEN insert kalk_kalk % % % % %', NEW.idpos, idvdKalk, pKonto, brDok, NEW.datum;
         -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
         -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj, pu_i) ' ||
                  'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $13/100), $11, $12, $13)'
                 USING idFirma, idvdKalk, NEW.rbr, brDok, NEW.datum, pKonto, NEW.idroba, NEW.idtarifa,
                 NEW.ncijena-NEW.cijena, NEW.kolicina, 0, NEW.cijena, pdvStopa, pUI;
          RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks -> f18.kalk_doks
DROP TRIGGER IF EXISTS  pos_doks_crud on p15.pos_doks;
CREATE TRIGGER pos_doks_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_doks
   FOR EACH ROW EXECUTE PROCEDURE public.on_pos_doks_crud();

-- p15.pos_pos -> f18.kalk_kalk
DROP TRIGGER IF EXISTS  pos_pos_crud on p15.pos_pos;
CREATE TRIGGER pos_pos_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_pos
      FOR EACH ROW EXECUTE PROCEDURE public.on_pos_pos_crud();

-- test pos->knjig

-- step 1
-- delete from p15.pos_doks where brdok='BRDOK01' and idvd='42';
-- insert into p15.pos_doks(idpos, idvd, brdok, datum) values('15', '42', 'BRDOK01', current_date);
-- insert into p15.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '42', 'BRDOK01', current_date, '  1', 'R01', 5, 2.5, 0, 'PDV17');

-- step 3
-- select * from p15.pos_doks where datum=current_date and idvd='42';

-- step 4
-- select * from f18.kalk_doks where brdok=TO_CHAR(current_date, 'ddmm/15') and idvd='42';

-- delete from p15.pos_pos where brdok='BRDOK01';

-- insert into p15.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '89', '       4', current_date, '  1', 'R01', 5, 2.5, 0.5, 'PDV17');


-- TARIFE CLEANUP --

CREATE TABLE IF NOT EXISTS public.tarifa AS  TABLE fmk.tarifa;
ALTER TABLE public.tarifa OWNER TO admin;
GRANT ALL ON TABLE public.tarifa TO xtrole;

alter table public.tarifa drop column if exists match_code;
alter table public.tarifa drop column if exists ppp;
alter table public.tarifa drop column if exists vpp;
alter table public.tarifa drop column if exists mpp;
alter table public.tarifa drop column if exists dlruc;
alter table public.tarifa drop column if exists zpp;

DO $$
BEGIN
  BEGIN
    alter table public.tarifa rename column opp TO pdv;
   EXCEPTION WHEN others THEN RAISE NOTICE 'tarifa column already renamed opp->pdv';
  END;
END $$;

------------------------------------------------------------------------
-- kalk_kalk, kalk_doks cleanup datumska polja
-----------------------------------------------------------------------
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datfaktp;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datkurs;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS roktr;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datfaktp date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datval date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS dat_od date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS dat_do date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS opis text;

DO $$
DECLARE
  nCount numeric;
BEGIN
    BEGIN
      SELECT count(*) as count from f18.kalk_kalk where btrim(coalesce(idzaduz2,''))<>''
        INTO nCount;
      IF (nCount > 1) THEN
         RAISE EXCEPTION 'kalk idzaduz2 se koristi % !?', nCount
            USING HINT = 'Vjerovatno ima veze sa pracenjem proizvodnje';
      END IF;
      ALTER TABLE f18.kalk_doks DROP COLUMN idzaduz;
      ALTER TABLE f18.kalk_doks DROP COLUMN idzaduz2;
      ALTER TABLE f18.kalk_doks DROP COLUMN sifra;

      ALTER TABLE f18.kalk_kalk DROP COLUMN idzaduz;
      ALTER TABLE f18.kalk_kalk DROP COLUMN idzaduz2;
      ALTER TABLE f18.kalk_kalk DROP COLUMN fcj3;
      ALTER TABLE f18.kalk_kalk DROP COLUMN vpcsap;

	EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'idzaduz2 garant ne postoji';
	END;
END;
$$;



-- pgcrypto

drop function if exists digest(bytea, text);
drop function if exists digest(text, text);
DROP FUNCTION if exists hmac(bytea, bytea, text);
DROP FUNCTION if exists hmac(text,text,text);
drop function if exists crypt(text,text);
drop function if exists gen_salt(text);
drop function if exists gen_salt(text,integer);
drop function if exists encrypt(bytea,bytea,text);
drop function if exists encrypt(bytea,bytea,bytea,text);
drop function if exists decrypt(bytea,bytea,bytea,text);
drop function if exists decrypt(bytea,bytea,text);
drop function if exists encrypt_iv(bytea,bytea,bytea,text);
drop function if exists decrypt_iv(bytea,bytea,bytea,text);

drop function if exists pgp_pub_decrypt(bytea,bytea);
drop function if exists pgp_pub_decrypt(bytea,bytea,text);
drop function if exists pgp_pub_decrypt(bytea,bytea,text,text);
drop function if exists pgp_pub_decrypt_bytea(bytea,bytea);
drop function if exists pgp_pub_decrypt_bytea(bytea,bytea,text);

drop function if exists pgp_pub_encrypt(text,bytea);
drop function if exists pgp_pub_encrypt(text,bytea,text);
drop function if exists pgp_pub_encrypt(text,bytea,text,text);

drop function if exists pgp_pub_encrypt_bytea(bytea,bytea);
drop function if exists pgp_pub_encrypt_bytea(bytea,bytea,text);

drop function if exists pgp_sym_decrypt(bytea,text);
drop function if exists pgp_sym_decrypt(bytea,text,text);

drop function if exists pgp_sym_decrypt_bytea(bytea,text);
drop function if exists pgp_sym_decrypt_bytea(bytea,text,text);

drop function if exists pgp_sym_encrypt(text,text);
drop function if exists pgp_sym_encrypt(text,text,text);

drop function if exists pgp_sym_encrypt_bytea(bytea,text);
drop function if exists pgp_sym_encrypt_bytea(bytea,text,text);

drop function if exists pgp_key_id(bytea);
drop function if exists armor(bytea);
drop function if exists dearmor(text);

drop extension if exists pgcrypto;
create extension pgcrypto;


ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS  uuid uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS ref uuid;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS ref_2 uuid;

ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid();
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS ref uuid;
ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS ref_2 uuid;

ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid();
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS ref uuid;
ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS ref_2 uuid;



CREATE OR REPLACE FUNCTION p15.pos_novi_broj_dokumenta(cIdPos varchar, cIdVd varchar, dDatum date) RETURNS varchar
  LANGUAGE plpgsql
  AS $$

DECLARE
   cBrDok varchar;
BEGIN

    SELECT brdok from p15.pos_doks where idvd=cIdVd and datum=dDatum order by brdok desc limit 1
           INTO cBrDok;
    IF cBrdok IS NULL THEN
        cBrDok := to_char(1, '99999999');
    ELSE
        cBrDok := to_char( to_number(cBrDok, '09999999') + 1, '99999999');
    END IF;

    RETURN lpad(btrim(cBrDok), 8, ' ');

END;
$$


CREATE OR REPLACE FUNCTION p15.pos_dostupno_artikal_za_cijenu(cIdRoba varchar, nCijena numeric, nNCijena numeric) RETURNS numeric
       LANGUAGE plpgsql
       AS $$

DECLARE
   idPos varchar DEFAULT '15';
   nStanje numeric;
BEGIN
   EXECUTE 'SELECT kol_ulaz-kol_izlaz as stanje FROM p' || idPos || '.pos_stanje' ||
           ' WHERE rtrim(idroba)=$1  AND cijena=$2 AND ncijena=$3 AND current_date>=dat_od AND current_date<=dat_do' ||
           ' AND kol_ulaz - kol_izlaz <> 0'
           USING trim(cIdroba), nCijena, nNCijena
           INTO nStanje;

   IF nStanje IS NOT NULL THEN
         RETURN nStanje;
   ELSE
         RETURN 0;
   END IF;
END;
$$


CREATE OR REPLACE FUNCTION p15.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuidPos uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT uuid FROM p15.pos_doks
          WHERE idvd='72' AND ref IS NULL AND dat_od = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM p15.nivelacija_start_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$


CREATE OR REPLACE FUNCTION p15.nivelacija_start_create(uuidPos uuid) RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar;
      cIdVd varchar;
      cBrDok varchar;
      dDatum date;
      cIdRoba varchar;
      dDat_od date;
      uuid2 uuid;
      nC numeric;
      nC2 numeric;
      nRbr integer;
      cBrDokNew varchar;
      dDatumNew date;
      nStanje numeric;
BEGIN

      EXECUTE 'select idpos,idvd,brdok,datum, dat_od from p15.pos_doks where uuid = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_od;
      RAISE INFO 'nivelacija_start_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_od;

      EXECUTE 'select uuid from p15.pos_doks WHERE idpos=$1 AND idvd=$2 AND ref=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;

      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_start dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_od;
      cBrDokNew := p15.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);

      insert into p15.pos_doks(idPos,idVd,brDok,datum,dat_od,ref) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos)
          RETURNING uuid into uuid2;

      -- referenca na '29' unutar dokumenta idvd '72'
      EXECUTE 'update p15.pos_doks set ref=$2 WHERE uuid=$1'
         USING uuidPos, uuid2;

      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from p15.pos_pos WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- aktuelna osnovna cijena;
         nStanje := p15.pos_dostupno_artikal_za_cijenu(cIdRoba, nC, 0.00);
         EXECUTE 'insert into p15.pos_pos(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nC, nC2;
      END LOOP;

      RETURN;
END;
$$

CREATE OR REPLACE FUNCTION p15.nivelacija_end_create(uuidPos uuid) RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar;
      cIdVd varchar;
      cBrDok varchar;
      dDatum date;
      cIdRoba varchar;
      dDat_do date;
      uuid2 uuid;
      nC numeric;
      nC2 numeric;
      nRbr integer;
      cBrDokNew varchar;
      dDatumNew date;
      nStanje numeric;
BEGIN

      EXECUTE 'select idpos,idvd,brdok,datum, dat_od from p15.pos_doks where uuid = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_do;
      RAISE INFO 'nivelacija_end_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_do;

      EXECUTE 'select uuid from p15.pos_doks WHERE idpos=$1 AND idvd=$2 AND ref_2=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;

      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_end dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_do;
      cBrDokNew := p15.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);

      insert into p15.pos_doks(idPos,idVd,brDok,datum,dat_od,ref) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos)
          RETURNING uuid into uuid2;

      -- referenca (2) na '29' unutar dokumenta idvd '72'
      EXECUTE 'update p15.pos_doks set ref_2=$2 WHERE uuid=$1'
         USING uuidPos, uuid2;

      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from p15.pos_pos WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- trenutno aktuelna osnovna cijena je akcijkska
         nStanje := p15.pos_dostupno_artikal_za_cijenu(cIdRoba, nC2, 0);
         EXECUTE 'insert into p15.pos_pos(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nC2, nC;
      END LOOP;

      RETURN;
END;
$$


CREATE OR REPLACE FUNCTION p15.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$

DECLARE
       uuidPos uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT uuid FROM p15.pos_doks
          WHERE idvd='72' AND ref IS NULL AND dat_od = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM p15.nivelacija_start_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$


CREATE OR REPLACE FUNCTION p15.cron_akcijske_cijene_nivelacija_end() RETURNS void
       LANGUAGE plpgsql
       AS $$

DECLARE
       uuidPos uuid;
BEGIN
     -- ref_2 nije popunjen => zavrsna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT uuid FROM p15.pos_doks
          WHERE idvd='72' AND ref_2 IS NULL AND dat_do = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM p15.nivelacija_end_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$


---------------------------- f18.kalk ---------------------------------------------

CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
CREATE TABLE IF NOT EXISTS f18.kalk_kalk  AS TABLE fmk.kalk_kalk;
CREATE TABLE IF NOT EXISTS f18.kalk_doks  AS TABLE fmk.kalk_doks;
GRANT ALL ON SCHEMA f18 TO xtrole;
GRANT ALL ON TABLE f18.kalk_kalk TO xtrole;
GRANT ALL ON TABLE f18.kalk_doks TO xtrole;
DROP TABLE IF EXISTS fmk.kalk_kalk;
DROP TABLE IF EXISTS fmk.kalk_doks;

DO $$
BEGIN
      BEGIN
        -- check if rbr is char, ako nije STOP => exception
        select btrim(rbr) from f18.kalk_kalk;
        alter table f18.kalk_kalk rename column rbr to c_rbr;
        alter table f18.kalk_kalk add column rbr integer;
        update f18.kalk_kalk set rbr = to_number(c_rbr, '999') WHERE rbr is NULL;
        alter table f18.kalk_kalk drop column c_rbr;

  	EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'rbr is not char';
  	END;
END;
$$;

CREATE INDEX IF NOT EXISTS kalk_kalk_datdok ON f18.kalk_kalk USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_kalk_id1 ON f18.kalk_kalk USING btree (idfirma, idvd, brdok, rbr, mkonto, pkonto);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto ON f18.kalk_kalk USING btree (idfirma, mkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto ON f18.kalk_kalk USING btree (idfirma, pkonto, idroba);

CREATE INDEX IF NOT EXISTS kalk_doks_datdok ON f18.kalk_doks USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_doks_id1 ON f18.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);

--------------------------------------------------------------------------------
-- F18 v3 legacy public.kalk_kalk, kalk_doks updatable views
-------------------------------------------------------------------------------
drop view if exists fmk.kalk_kalk;
CREATE view fmk.kalk_kalk  AS SELECT
     idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
     brfaktp, idpartner,
     lpad(btrim(to_char(rbr,'999')), 3) as rbr,
     kolicina, gkolicina, gkolicin2,
     fcj, fcj2,
     trabat,rabat,
     tprevoz,prevoz,
     tprevoz2,prevoz2,
     tbanktr,banktr,
     tspedtr,spedtr,
     tcardaz,cardaz,
     tzavtr,zavtr,
     tmarza,marza,
     nc, vpc,
     rabatv,
     tmarza2, marza2,
     mpc, idtarifa,
     mpcsapp,
     mkonto,pkonto,mu_i,pu_i,
     error
FROM
  f18.kalk_kalk;

CREATE OR REPLACE RULE fmk_kalk_kalk_ins AS ON INSERT TO fmk.kalk_kalk
      DO INSTEAD INSERT INTO f18.kalk_kalk(
         idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
         brfaktp, idpartner,
         rbr,
         kolicina, gkolicina, gkolicin2,
         fcj, fcj2,
         trabat,rabat,
         tprevoz,prevoz,
         tprevoz2,prevoz2,
         tbanktr,banktr,
         tspedtr,spedtr,
         tcardaz,cardaz,
         tzavtr,zavtr,
         tmarza,marza,
         nc, vpc,
         rabatv,
         tmarza2, marza2,
         mpc, idtarifa,
         mpcsapp,
         mkonto,pkonto,mu_i,pu_i,
         error
      ) VALUES (
        NEW.idfirma, NEW.idroba, NEW.idkonto, NEW.idkonto2, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.idpartner,
        to_number(NEW.rbr,'999'),
        NEW.kolicina, NEW.gkolicina, NEW.gkolicin2,
        NEW.fcj, NEW.fcj2,
        NEW.trabat, NEW.rabat,
        NEW.tprevoz, NEW.prevoz,
        NEW.tprevoz2, NEW.prevoz2,
        NEW.tbanktr, NEW.banktr,
        NEW.tspedtr, NEW.spedtr,
        NEW.tcardaz, NEW.cardaz,
        NEW.tzavtr, NEW.zavtr,
        NEW.tmarza, NEW.marza,
        NEW.nc, NEW.vpc,
        NEW.rabatv,
        NEW.tmarza2, NEW.marza2,
        NEW.mpc, NEW.idtarifa,
        NEW.mpcsapp,
        NEW.mkonto, NEW.pkonto, NEW.mu_i,NEW.pu_i,
        NEW.error   );

GRANT ALL ON fmk.kalk_kalk TO xtrole;

----------------------  public.kalk_doks ----------------------------------
DROP VIEW if exists fmk.kalk_doks;
CREATE view fmk.kalk_doks  AS SELECT
idfirma, idvd, brdok, datdok,
brfaktp, datfaktp, idpartner, datval,
dat_od, dat_do,
opis,
pkonto,mkonto,
nv,vpv,rabat,mpv,
obradjeno,
korisnik
FROM
  f18.kalk_doks;

CREATE OR REPLACE RULE fmk_kalk_doks_ins AS ON INSERT TO f18.kalk_doks
      DO INSTEAD INSERT INTO f18.kalk_doks(
        idfirma, idvd, brdok, datdok,
        brfaktp, datfaktp, idpartner, datval,
        dat_od, dat_do,
        opis,
        pkonto,mkonto,
        nv,vpv,rabat,mpv,
        obradjeno,
        korisnik
      ) VALUES (
        NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.datfaktp, NEW.idpartner, NEW.datval,
        NEW.dat_od, NEW.dat_do,
        NEW.opis,
        NEW.pkonto, NEW.mkonto,
        NEW.nv, NEW.vpv, NEW.rabat, NEW.mpv,
        NEW.obradjeno,
        NEW.korisnik   );


GRANT ALL ON fmk.kalk_doks TO xtrole;


--------------------------------------------------------------------------------
-- F18 v4 public kalk_kalk, kalk_doks updatable views
-------------------------------------------------------------------------------
drop view if exists public.kalk_kalk;
CREATE view public.kalk_kalk  AS SELECT
     idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
     brfaktp, idpartner,
     rbr,
     kolicina, gkolicina, gkolicin2,
     fcj, fcj2,
     trabat,rabat,
     tprevoz,prevoz,
     tprevoz2,prevoz2,
     tbanktr,banktr,
     tspedtr,spedtr,
     tcardaz,cardaz,
     tzavtr,zavtr,
     tmarza,marza,
     nc, vpc,
     rabatv,
     tmarza2, marza2,
     mpc, idtarifa,
     mpcsapp,
     mkonto,pkonto,mu_i,pu_i,
     error
FROM
  f18.kalk_kalk;

CREATE OR REPLACE RULE public_kalk_kalk_ins AS ON INSERT TO f18.kalk_kalk
      DO INSTEAD INSERT INTO f18.kalk_kalk(
         idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
         brfaktp, idpartner,
         rbr,
         kolicina, gkolicina, gkolicin2,
         fcj, fcj2,
         trabat,rabat,
         tprevoz,prevoz,
         tprevoz2,prevoz2,
         tbanktr,banktr,
         tspedtr,spedtr,
         tcardaz,cardaz,
         tzavtr,zavtr,
         tmarza,marza,
         nc, vpc,
         rabatv,
         tmarza2, marza2,
         mpc, idtarifa,
         mpcsapp,
         mkonto,pkonto,mu_i,pu_i,
         error
      ) VALUES (
        NEW.idfirma, NEW.idroba, NEW.idkonto, NEW.idkonto2, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.idpartner,
        NEW.rbr,
        NEW.kolicina, NEW.gkolicina, NEW.gkolicin2,
        NEW.fcj, NEW.fcj2,
        NEW.trabat, NEW.rabat,
        NEW.tprevoz, NEW.prevoz,
        NEW.tprevoz2, NEW.prevoz2,
        NEW.tbanktr, NEW.banktr,
        NEW.tspedtr, NEW.spedtr,
        NEW.tcardaz, NEW.cardaz,
        NEW.tzavtr, NEW.zavtr,
        NEW.tmarza, NEW.marza,
        NEW.nc, NEW.vpc,
        NEW.rabatv,
        NEW.tmarza2, NEW.marza2,
        NEW.mpc, NEW.idtarifa,
        NEW.mpcsapp,
        NEW.mkonto, NEW.pkonto, NEW.mu_i,NEW.pu_i,
        NEW.error   );

GRANT ALL ON public.kalk_kalk TO xtrole;

----------------------  public.kalk_doks ----------------------------------
DROP VIEW if exists public.kalk_doks;
CREATE view public.kalk_doks  AS SELECT
idfirma, idvd, brdok, datdok,
brfaktp, datfaktp, idpartner, datval,
dat_od, dat_do,
opis,
pkonto,mkonto,
nv,vpv,rabat,mpv,
obradjeno,
korisnik
FROM
  f18.kalk_doks;

CREATE OR REPLACE RULE public_kalk_doks_ins AS ON INSERT TO public.kalk_doks
      DO INSTEAD INSERT INTO f18.kalk_doks(
        idfirma, idvd, brdok, datdok,
        brfaktp, datfaktp, idpartner, datval,
        dat_od, dat_do,
        opis,
        pkonto,mkonto,
        nv,vpv,rabat,mpv,
        obradjeno,
        korisnik
      ) VALUES (
        NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.datfaktp, NEW.idpartner, NEW.datval,
        NEW.dat_od, NEW.dat_do,
        NEW.opis,
        NEW.pkonto, NEW.mkonto,
        NEW.nv, NEW.vpv, NEW.rabat, NEW.mpv,
        NEW.obradjeno,
        NEW.korisnik   );


GRANT ALL ON public.kalk_doks TO xtrole;

-- kalk podbr out
ALTER TABLE IF EXISTS f18.kalk_doks DROP COLUMN IF EXISTS podbr;
ALTER TABLE IF EXISTS f18.kalk_kalk DROP COLUMN IF EXISTS podbr;



--- MSSQL FOREIGN TABLES ----------------------------------

CREATE EXTENSION tds_fdw;

drop server if exists mssql1 CASCADE;
create server mssql1 foreign data wrapper tds_fdw options (servername '192.168.124.1', port '1433',
		database 'Sarajevo', tds_version '7.1', character_set 'UTF-8');
CREATE USER MAPPING FOR postgres SERVER mssql1 OPTIONS (username 'sa', password 'test01Pwd');

DROP FOREIGN TABLE IF EXISTS mssql1_kupac;
CREATE FOREIGN TABLE mssql1_kupac(nazpp varchar, mjesto varchar, ulica varchar, siff integer, prod integer) SERVER mssql1
   options (query 'SELECT nazpp,mjesto,ulica,siff,prod from [dbo].[kupac]', row_estimate_method 'showplan_all');


CREATE OR REPLACE FUNCTION public.mssql_int_to_date(iDat integer) RETURNS date
   LANGUAGE plpgsql
   AS $$
   DECLARE
     nYear integer;
     nMonth integer;
     nDay integer;
   BEGIN
       nYear := iDat / 10^4;
       nMonth := (iDat - nYear * 10^4) / 10^2;
       nDay := iDat - nYear * 10^4 - nMonth * 10^2;
       nYear := 2000 + nYear;
       RETURN (to_char(nYear,'0999') || to_char(nMonth, '09') || to_char(nDay,'09'))::date;

END;
$$

-- select * from public.sfak_by_brf(2018232);

DROP FUNCTION IF EXISTS public.sfak_by_brf(bigint);
CREATE OR REPLACE FUNCTION public.sfak_by_brf(brfIn bigint) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd date, rel integer)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT rb,prod,ident,kold,cijena,brf,datd,rel from [dbo].[SFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_sfak_' || cBrF || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd integer, rel integer) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena, brf, public.mssql_int_to_date(datd), rel from mssql1_sfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cBrF;
END;
$$



-- select * from public.gfak_by_brf(2018232);

DROP FUNCTION IF EXISTS public.gfak_by_brf(bigint);

CREATE OR REPLACE FUNCTION public.gfak_by_brf(brfIn bigint) RETURNS TABLE (vcij integer, siff integer, datfk date, dvo date, datk date, valdat date, brf bigint, ts timestamp)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT vcij,siff,datfk,dvo,datk,valdat,brf,ts from [dbo].[GFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_gfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_gfak_' || cBrF || '(vcij integer, siff integer, datfk integer, dvo integer, datk integer, valdat integer, brf bigint,ts timestamp) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT vcij,siff,public.mssql_int_to_date(datfk),public.mssql_int_to_date(dvo),public.mssql_int_to_date(datk),public.mssql_int_to_date(valdat),brf,ts from mssql1_gfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_gfak_' || cBrF;
END;
$$


-- select * from public.sfak_by_brf(2018232) as sfak
--  LEFT JOIN public.gfak_by_brf(2018232) as gfak
--  ON sfak.brf=gfak.brf;


-- select * from public.sfak_prodavnice_by_datum('2018-10-16');

DROP FUNCTION IF EXISTS public.sfak_prodavnice_by_datum(datum date);
CREATE OR REPLACE FUNCTION public.sfak_prodavnice_by_datum(datum date) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd date, rel integer, siff integer, kp integer)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cDatum text;
BEGIN

cDatum := to_char(datum, 'yymmdd');
-- gfak.KP - magacin SA (40), BL (598), Bihac (942)
-- prod < 199 => prodavnica
-- select count(*) FROM [Sarajevo].[dbo].[SFAK] LEFT JOIN [Sarajevo].[dbo].[GFAK] ON sfak.brf=gfak.brf  where datd=181016
-- siff=2000 => neka od prodavnica
cQuery := 'SELECT rb,prod,ident,kold,cijena,sfak.brf,datd,rel,siff,kp from [dbo].[SFAK]' ||
          ' LEFT JOIN [dbo].[GFAK] ON sfak.brf=gfak.brf' ||
          ' WHERE prod>0 AND prod<199 AND siff=20000 AND datd=' || cDatum;

-- select count(*) FROM [Sarajevo].[dbo].[SFAK] LEFT JOIN [Sarajevo].[dbo].[GFAK] ON sfak.brf=gfak.brf  where datd=181016

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cDatum;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_sfak_' || cDatum || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd integer, rel integer, siff integer, kp integer) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena, brf, public.mssql_int_to_date(datd),rel,siff,kp from mssql1_sfak_' || cDatum;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cDatum;
END;
$$
