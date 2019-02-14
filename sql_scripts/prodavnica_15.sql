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
    opis varchar(100),
    dat_od date,
    dat_do date
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
CREATE OR REPLACE FUNCTION public.on_kalk_kalk_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    sql varchar;
    cijena decimal;
    ncijena decimal;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '11' ) AND ( NEW.idvd <> '19' ) THEN  -- samo 11, 19
     RETURN NULL;
   END IF;
   SELECT idprodmjes INTO idPos
          from fmk.koncij where id=NEW.PKonto;
ELSE
   IF ( OLD.idvd <> '11' ) AND ( OLD.idvd <> '19' ) THEN
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
      RAISE INFO 'insert % prodavnica %', NEW.idvd, idPos;
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
CREATE OR REPLACE FUNCTION public.on_kalk_doks_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar;
    sql varchar;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
      IF ( NEW.idvd <> '11' ) AND ( NEW.idvd <> '19' ) THEN -- samo 11, 19
         RETURN NULL;
      END IF;
      SELECT idprodmjes INTO idPos
            from fmk.koncij where id=NEW.PKonto;
ELSE
     IF ( OLD.idvd <> '11' ) AND ( OLD.idvd <> '19' ) THEN
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


-- fmk.kalk_kalk -> p15.pos_pos_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_crud on fmk.kalk_kalk;
CREATE TRIGGER t_kalk_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON fmk.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE public.on_kalk_kalk_crud();

-- fmk.kalk_doks -> p15.pos_doks_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_doks_crud on fmk.kalk_doks;
CREATE TRIGGER t_kalk_doks_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON fmk.kalk_doks
      FOR EACH ROW EXECUTE PROCEDURE public.on_kalk_doks_crud();


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
CREATE OR REPLACE FUNCTION p15.on_pos_doks_knjig_insert_update_delete() RETURNS trigger
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
      EXECUTE 'INSERT INTO p' || idPos || '.pos_doks(idpos,idvd,brdok,datum,brFaktP) VALUES($1,$2,$3,$4,$5)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.brFaktP;
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
   rbr character(3),
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

IF ( idvd <> '11' )  THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(rbr);
dokumenti := dokumenti || dokument;

IF dat_od IS NULL then
  dat_do := '1999-01-01';
END IF;
IF dat_do IS NULL then
  dat_do := '3999-01-01';
END IF;

IF transakcija = '-' THEN -- on delete pos_pos stavka
   -- treba da se poklope sve ove stavke: idroba / cijena / ncijena / dat_do, a da zadani dat_od bude >= od analiziranog
   RAISE INFO 'delete = % % % % % %', dokument, idroba, cijena, ncijena, dat_od, dat_do;
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

RAISE INFO 'idDokument = %', idRaspolozivo;

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
   rbr character(3),
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

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(rbr);
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



---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on p15.pos_pos_knjig -> p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_pos_knjig_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar := '15';
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


-- SELECT public.kalk_brdok_iz_pos('15', '42', '4', current_date); => 1402/15
-- SELECT public.kalk_brdok_iz_pos('15', '89', '    3', current_date); => 1402/3

CREATE OR REPLACE FUNCTION public.kalk_brdok_iz_pos(
   idpos varchar,
   idvd varchar,
   posBrdok varchar,
   datum date) RETURNS varchar

LANGUAGE plpgsql
AS $$
DECLARE
  brdok varchar;
BEGIN

IF ( idvd = '42' ) THEN
  -- 01.02.2019, idpos=15 -> 0102/15
  SELECT TO_CHAR(datum, 'ddmm/' || idpos ) INTO brDok;
ELSIF ( idvd = '89' ) THEN
   -- 01.02.2019, brdok='      3' -> 0102/3
   SELECT TO_CHAR(datum, 'ddmm/' || btrim(posBrdok) ) INTO brDok;
END IF;

RETURN brDok;

END;
$$

----------- TRIGERI na strani knjigovodstva POS_DOKS - KALK_DOKS ! -----------------------------------------------------

-- on p15.pos_doks -> fmk.kalk_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_doks_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '89' ) THEN -- samo 42-ke, 89
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
   SELECT public.kalk_brdok_iz_pos(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum)
          INTO brDok;
ELSE
   IF ( OLD.idvd <> '42' ) AND ( NEW.idvd <> '89' ) THEN -- samo 42-ke, 89
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
       from fmk.koncij where idprodmjes=OLD.idpos;
   SELECT public.kalk_brdok_iz_pos(OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum)
        INTO brDok;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_doks % % % % %', OLD.idpos, pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE idfirma=$1 pkonto=$2 AND idvd=$3 AND datdok=$4 AND brdok=$5'
            USING OLD.idpos, pKonto, OLD.idvd, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_doks !? % % %', pKonto, brDok, NEW.idvd;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
         RAISE INFO 'FIRST delete kalk_doks % % % %', NEW.idvd, pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, NEW.idvd, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_doks % % % %', pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_doks(idfirma,idvd,brdok,datdok,pkonto) VALUES($1,$2,$3,$4,$5)'
                     USING NEW.idpos, NEW.idvd, brDok, NEW.datum, pKonto;
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


----------- TRIGERI na strani kase radi pracenja stanja -----------------------------------------------------

-- on p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_kasa_pos_pos_insert_update_delete() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
    idPos varchar := '15';
    lRet boolean;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '11' ) THEN -- samo 42, 11
      RETURN NULL;
   END IF;
ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '11' ) THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'DELETE') AND ( OLD.idvd = '42' ) THEN
      RAISE INFO 'delete izlaz pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select p15.pos_izlaz_update_stanje('-', '15', '42', 'PROD91', '5', current_date, 'R01',  40, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''-'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
         USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum,  OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
         INTO lRet;
      RAISE INFO 'delete ret=%', lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( OLD.idvd = '11' ) THEN
      RAISE INFO 'delete 11 pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select p15.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '999', current_date, current_date, NULL, 'R01',  50, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''-'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
               USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
               INTO lRet;
      RAISE INFO 'delete 11 ret=%', lRet;
      RETURN OLD;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd = '42' ) THEN
       RAISE INFO 'update 42 pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr ;
       RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd = '11' ) THEN
        RAISE INFO 'update 11 pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN
        RAISE INFO 'insert 42 pos_pos  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD10', '999', current_date, 'R03', 10, 30, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
              USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum,  NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
              INTO lRet;
        RAISE INFO 'insert 42 ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '11' ) THEN
        RAISE INFO 'insert 11 pos_pos % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '999', current_date, current_date, NULL,'R01', 100, 2.5, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''+'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
             RAISE INFO 'insert 11 ret=%', lRet;
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

-- on p15.pos_pos -> fmk.kalk_kalk
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_pos_pos_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'fmk';
       pKonto varchar;
       brDok varchar;
       pdvStopa numeric;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '89' ) THEN -- samo 42-ke, 89
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from fmk.koncij where idprodmjes=NEW.idpos;
   brDok := public.kalk_brdok_iz_pos(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum);
ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '89' ) THEN -- samo 42-ke, 89
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
       from fmk.koncij where idprodmjes=OLD.idpos;
   brDok := public.kalk_brdok_iz_pos(OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum);
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_kalk % % % %', pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING pKonto, OLD.idvd, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_kalk !? % %', pKonto, brDok;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN
         RAISE INFO 'FIRST delete kalk_kalk  % % %', pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, NEW.idvd, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_kalk 42 % % % %', NEW.idpos, pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj) ' ||
                 '(SELECT $1 as idfirma, $2 as idvd,' ||
                 ' (fmk.rbr_to_char( (row_number() over (order by idroba))::integer))::character(3) as rbr,' ||
                 ' $3 as brdok, $4 as datdok,$6 as pkonto, idroba, idtarifa, cijena as mpcsapp, sum(kolicina) as kolicina, ' ||
                 ' cijena/(1 + tarifa.pdv/100) as mpc, 0.00000001 as nc, 0.00000001 as fcj' ||
                 ' FROM p' || NEW.idpos || '.pos_pos ' ||
                 ' LEFT JOIN public.tarifa on pos_pos.idtarifa = tarifa.id' ||
                 ' WHERE idvd=$2 AND datum=$4 AND idpos=$5' ||
                 ' GROUP BY idroba,idtarifa,cijena,ncijena,tarifa.pdv' ||
                 ' ORDER BY idroba)'
              USING NEW.idpos, NEW.idvd, brDok, NEW.datum, NEW.idpos, pKonto;
         RETURN NEW;

  ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '89' ) THEN

         EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                USING NEW.idtarifa
                INTO pdvStopa;

         RAISE INFO 'THEN insert kalk_kalk 89 % % % %', NEW.idpos, pKonto, brDok, NEW.datum;
         -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
         -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj) ' ||
                  'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $13/100), $11, $12)'
                 USING NEW.idpos, NEW.idvd, NEW.rbr, brDok, NEW.datum, pKonto, NEW.idroba, NEW.idtarifa,
                 -NEW.ncijena, NEW.kolicina, 0, NEW.cijena, pdvStopa;
          RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks -> fmk.kalk_doks
DROP TRIGGER IF EXISTS  pos_doks_crud on p15.pos_doks;
CREATE TRIGGER pos_doks_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_doks
   FOR EACH ROW EXECUTE PROCEDURE public.on_pos_doks_crud();

-- p15.pos_pos -> fmk.kalk_kalk
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
-- select * from fmk.kalk_doks where brdok=TO_CHAR(current_date, 'ddmm/15') and idvd='42';

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
ALTER TABLE fmk.kalk_kalk DROP COLUMN IF EXISTS datfaktp;
ALTER TABLE fmk.kalk_kalk DROP COLUMN IF EXISTS datkurs;
ALTER TABLE fmk.kalk_kalk DROP COLUMN IF EXISTS roktr;
ALTER TABLE fmk.kalk_doks ADD COLUMN IF NOT EXISTS datfaktp date;
ALTER TABLE fmk.kalk_doks ADD COLUMN IF NOT EXISTS datval date;
ALTER TABLE fmk.kalk_doks ADD COLUMN IF NOT EXISTS dat_od date;
ALTER TABLE fmk.kalk_doks ADD COLUMN IF NOT EXISTS dat_do date;
ALTER TABLE fmk.kalk_doks ADD COLUMN IF NOT EXISTS opis text;

DO $$
DECLARE
  nCount numeric;
BEGIN
    BEGIN
      SELECT count(*) as count from fmk.kalk_kalk where btrim(coalesce(idzaduz2,''))<>''
        INTO nCount;
      IF (nCount > 1) THEN
         RAISE EXCEPTION 'kalk idzaduz2 se koristi % !?', nCount
            USING HINT = 'Vjerovatno ima veze sa pracenjem proizvodnje';
      END IF;
      ALTER TABLE fmk.kalk_doks DROP COLUMN idzaduz;
      ALTER TABLE fmk.kalk_doks DROP COLUMN idzaduz2;
      ALTER TABLE fmk.kalk_doks DROP COLUMN sifra;

      ALTER TABLE fmk.kalk_kalk DROP COLUMN idzaduz;
      ALTER TABLE fmk.kalk_kalk DROP COLUMN idzaduz2;
      ALTER TABLE fmk.kalk_kalk DROP COLUMN fcj3;

	EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'idzaduz2 garant ne postoji';
	END;
END;
$$;
