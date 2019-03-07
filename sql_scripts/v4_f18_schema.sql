-- f18 schema
CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

-- f18.fetchmetrictext, f18.setmetric
CREATE TABLE IF NOT EXISTS f18.metric  AS TABLE fmk.metric;
GRANT ALL ON TABLE f18.metric TO xtrole;
GRANT ALL ON TABLE f18.kalk_doks TO xtrole;
DROP TABLE IF EXISTS fmk.metric;

delete from f18.metric where metric_id IS null;
ALTER TABLE f18.metric ALTER COLUMN metric_id SET NOT NULL;
ALTER TABLE f18.metric ALTER COLUMN metric_id SET DEFAULT nextval(('metric_metric_id_seq'::text)::regclass);

---------------------------- f18.kalk ---------------------------------------------

CREATE TABLE IF NOT EXISTS f18.kalk_kalk  AS TABLE fmk.kalk_kalk;
CREATE TABLE IF NOT EXISTS f18.kalk_doks  AS TABLE fmk.kalk_doks;
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

CREATE INDEX IF NOT EXISTS kalk_kalk_datdok ON f18.kalk_kalk USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_kalk_id1 ON f18.kalk_kalk USING btree (idfirma, idvd, brdok, rbr, mkonto, pkonto);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto ON f18.kalk_kalk USING btree (idfirma, mkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto ON f18.kalk_kalk USING btree (idfirma, pkonto, idroba);

CREATE INDEX IF NOT EXISTS kalk_doks_datdok ON f18.kalk_doks USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_doks_id1 ON f18.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);


-- kalk podbr out
ALTER TABLE IF EXISTS f18.kalk_doks DROP COLUMN IF EXISTS podbr;
ALTER TABLE IF EXISTS f18.kalk_kalk DROP COLUMN IF EXISTS podbr;

ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datfaktp date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datval date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS dat_od date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS dat_do date;
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS opis text;

------------------------------------------------------------------------
-- kalk_kalk, kalk_doks cleanup datumska polja
-----------------------------------------------------------------------
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datfaktp;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datkurs;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS roktr;



--- f18.tarifa --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.tarifa AS  TABLE fmk.tarifa;
ALTER TABLE f18.tarifa OWNER TO admin;
GRANT ALL ON TABLE f18.tarifa TO xtrole;

alter table f18.tarifa drop column if exists match_code;
alter table f18.tarifa drop column if exists ppp;
alter table f18.tarifa drop column if exists vpp;
alter table f18.tarifa drop column if exists mpp;
alter table f18.tarifa drop column if exists dlruc;
alter table f18.tarifa drop column if exists zpp;

DROP TABLE IF EXISTS fmk.tarifa;

DO $$
BEGIN
  BEGIN
    alter table fmk.tarifa rename column opp TO pdv;
   EXCEPTION WHEN others THEN RAISE NOTICE 'tarifa column already renamed opp->pdv';
  END;
END $$;

--- f18.koncij  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.koncij AS  TABLE fmk.koncij;
ALTER TABLE f18.koncij OWNER TO admin;
GRANT ALL ON TABLE f18.koncij TO xtrole;
DROP TABLE IF EXISTS fmk.koncij;
alter table f18.koncij drop column if exists match_code CASCADE;
alter table f18.koncij add column if not exists prod integer;

--- f18.roba  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.roba AS  TABLE fmk.roba;
ALTER TABLE f18.roba OWNER TO admin;
GRANT ALL ON TABLE f18.roba TO xtrole;
DROP TABLE IF EXISTS fmk.roba;

--- f18.partn  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.partn AS  TABLE fmk.partn;
ALTER TABLE f18.partn OWNER TO admin;
GRANT ALL ON TABLE f18.partn TO xtrole;
DROP TABLE IF EXISTS fmk.partn;

--- f18.valute  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.valute AS  TABLE fmk.valute;
ALTER TABLE f18.valute OWNER TO admin;
GRANT ALL ON TABLE f18.valute TO xtrole;
DROP TABLE IF EXISTS fmk.valute;

--- f18.konto  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.konto AS  TABLE fmk.konto;
ALTER TABLE f18.konto OWNER TO admin;
GRANT ALL ON TABLE f18.konto TO xtrole;
DROP TABLE IF EXISTS fmk.konto;

--- f18.tnal  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.tnal AS  TABLE fmk.tnal;
ALTER TABLE f18.tnal OWNER TO admin;
GRANT ALL ON TABLE f18.tnal TO xtrole;
DROP TABLE IF EXISTS fmk.tnal;

--- f18.tdok  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.tdok AS  TABLE fmk.tdok;
ALTER TABLE f18.tdok OWNER TO admin;
GRANT ALL ON TABLE f18.tdok TO xtrole;
DROP TABLE IF EXISTS fmk.tdok;

--- f18.sifk  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.sifk AS  TABLE fmk.sifk;
ALTER TABLE f18.sifk OWNER TO admin;
GRANT ALL ON TABLE f18.sifk TO xtrole;
DROP TABLE IF EXISTS fmk.sifk;

--- f18.sifv  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.sifv AS  TABLE fmk.sifv;
ALTER TABLE f18.sifv OWNER TO admin;
GRANT ALL ON TABLE f18.sifv TO xtrole;
DROP TABLE IF EXISTS fmk.sifv;

--- f18.trfp  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.trfp AS  TABLE fmk.trfp;
ALTER TABLE f18.trfp OWNER TO admin;
GRANT ALL ON TABLE f18.trfp TO xtrole;
DROP TABLE IF EXISTS fmk.trfp;
