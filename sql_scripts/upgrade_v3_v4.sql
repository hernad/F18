-- f18 schema
CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

-- f18.fetchmetrictext, f18.setmetric
SELECT public.create_table_from_then_drop( 'fmk.metric', 'f18.metric' );
ALTER TABLE f18.metric OWNER TO admin;
GRANT ALL ON TABLE f18.metric TO xtrole;

DO $$
DECLARE
  iMax integer;
BEGIN
  select max(metric_id) from f18.metric
    INTO iMax;
  EXECUTE 'CREATE SEQUENCE IF NOT EXISTS f18.metric_metric_id_seq START ' || to_char(iMax+1, '999999');
	ALTER sequence f18.metric_metric_id_seq OWNER TO admin;
  GRANT ALL ON SEQUENCE f18.metric_metric_id_seq TO xtrole;
  ALTER sequence f18.metric_metric_id_seq OWNED BY f18.metric.metric_id;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS metric_metric_id ON f18.metric USING btree(metric_id);
GRANT ALL ON SEQUENCE f18.metric_metric_id_seq TO xtrole;

delete from f18.metric where metric_id IS null;
ALTER TABLE f18.metric ALTER COLUMN metric_id SET NOT NULL;
ALTER TABLE f18.metric ALTER COLUMN metric_id SET DEFAULT nextval(('f18.metric_metric_id_seq'::text)::regclass);
ALTER TABLE f18.metric  DROP CONSTRAINT IF EXISTS metric_id_unique;
ALTER TABLE f18.metric  ADD CONSTRAINT metric_id_unique UNIQUE (metric_id);

---------------------------- f18.kalk ---------------------------------------------

SELECT public.create_table_from_then_drop( 'fmk.kalk_kalk', 'f18.kalk_kalk' );
SELECT public.create_table_from_then_drop( 'fmk.kalk_doks', 'f18.kalk_doks' );
GRANT ALL ON TABLE f18.kalk_kalk TO xtrole;
GRANT ALL ON TABLE f18.kalk_doks TO xtrole;

DELETE from f18.kalk_kalk where brdok is null or btrim(brdok)='';
DELETE from f18.kalk_doks where brdok is null or btrim(brdok)='';

ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datfaktp date;

CREATE OR REPLACE FUNCTION datfaktp_from_kalk_kalk(cIdFirma varchar, cIdVd varchar, cBrDok varchar ) RETURNS date
LANGUAGE plpgsql
AS $$
DECLARE
   dDatFaktP date;
BEGIN
   SELECT datfaktp from f18.kalk_kalk where idfirma=cIdFirma and idvd=cIdVd and brdok=cBrDok LIMIT 1
      INTO dDatFaktP;

  RETURN dDatFaktP;
END;
$$;


DO $$
DECLARE
   nRbr numeric;
BEGIN

    -- check if rbr is char, ako nije STOP => exception
   select to_number(rbr, '999') from f18.kalk_kalk LIMIT 1
      INTO nRbr;

   update f18.kalk_doks set datfaktp=datfaktp_from_kalk_kalk(idfirma, idvd, brdok);

   alter table f18.kalk_kalk rename column rbr to c_rbr;
   alter table f18.kalk_kalk add column rbr integer;
   update f18.kalk_kalk set rbr = to_number(c_rbr, '999') WHERE rbr is NULL;
   alter table f18.kalk_kalk drop column c_rbr;

EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'rbr is not char';

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

DROP VIEW IF EXISTS public.kalk_doks;
DROP VIEW IF EXISTS fmk.kalk_doks;
ALTER TABLE f18.kalk_doks ALTER COLUMN obradjeno TYPE timestamp with time zone;
ALTER TABLE f18.kalk_doks ALTER COLUMN obradjeno SET DEFAULT now();
ALTER TABLE f18.kalk_doks ALTER COLUMN korisnik SET DEFAULT current_user;

CREATE INDEX IF NOT EXISTS kalk_kalk_datdok ON f18.kalk_kalk USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_kalk_id1 ON f18.kalk_kalk USING btree (idfirma, idvd, brdok, rbr, mkonto, pkonto);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto ON f18.kalk_kalk USING btree (idfirma, mkonto, idroba);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto_roba ON f18.kalk_kalk USING btree (mkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto ON f18.kalk_kalk USING btree (idfirma, pkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto_roba ON f18.kalk_kalk USING btree (pkonto, idroba);

CREATE INDEX IF NOT EXISTS kalk_doks_datdok ON f18.kalk_doks USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_doks_id1 ON f18.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);

-- kalk podbr out
ALTER TABLE IF EXISTS f18.kalk_doks DROP COLUMN IF EXISTS podbr;
ALTER TABLE IF EXISTS f18.kalk_kalk DROP COLUMN IF EXISTS podbr;

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


-- kalk_doks, kalk_kalk - dok_id
ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS dok_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.kalk_doks ALTER COLUMN dok_id SET DEFAULT gen_random_uuid();

ALTER TABLE f18.kalk_kalk ADD COLUMN IF NOT EXISTS  dok_id uuid;



--- f18.tarifa --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.tarifa', 'f18.tarifa' );
ALTER TABLE f18.tarifa OWNER TO admin;
GRANT ALL ON TABLE f18.tarifa TO xtrole;

alter table f18.tarifa drop column if exists match_code;
alter table f18.tarifa drop column if exists ppp;
alter table f18.tarifa drop column if exists vpp;
alter table f18.tarifa drop column if exists mpp;
alter table f18.tarifa drop column if exists dlruc;
alter table f18.tarifa drop column if exists zpp;

DO $$
BEGIN
  BEGIN
    alter table f18.tarifa rename column opp TO pdv;
    EXCEPTION WHEN others THEN RAISE NOTICE 'tarifa column already renamed opp->pdv';
  END;
END $$;
ALTER TABLE f18.tarifa ADD COLUMN IF NOT EXISTS tarifa_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.tarifa ALTER COLUMN tarifa_id SET DEFAULT gen_random_uuid();

--- f18.koncij  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.koncij', 'f18.koncij' );
ALTER TABLE f18.koncij OWNER TO admin;
GRANT ALL ON TABLE f18.koncij TO xtrole;
alter table f18.koncij drop column if exists match_code CASCADE;
alter table f18.koncij add column if not exists prod integer;
ALTER TABLE f18.koncij ADD COLUMN IF NOT EXISTS koncij_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.koncij ALTER COLUMN koncij_id SET DEFAULT gen_random_uuid();

--- f18.roba  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.roba', 'f18.roba' );
ALTER TABLE f18.roba OWNER TO admin;
GRANT ALL ON TABLE f18.roba TO xtrole;
ALTER TABLE f18.roba DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.roba ADD COLUMN IF NOT EXISTS roba_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.roba ALTER COLUMN roba_id SET DEFAULT gen_random_uuid();

--- f18.partn  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.partn', 'f18.partn' );
ALTER TABLE f18.partn OWNER TO admin;
GRANT ALL ON TABLE f18.partn TO xtrole;
ALTER TABLE f18.partn DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.partn ADD COLUMN IF NOT EXISTS partner_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.tarifa ALTER COLUMN partner_id SET DEFAULT gen_random_uuid();

--- f18.valute  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.valute', 'f18.valute' );
ALTER TABLE f18.valute OWNER TO admin;
GRANT ALL ON TABLE f18.valute TO xtrole;
ALTER TABLE f18.valute DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.valute ADD COLUMN IF NOT EXISTS valuta_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.valute ALTER COLUMN valuta_id SET DEFAULT gen_random_uuid();

--- f18.konto  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.konto', 'f18.konto' );
ALTER TABLE f18.konto OWNER TO admin;
GRANT ALL ON TABLE f18.konto TO xtrole;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS pozbilu CASCADE;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS pozbils CASCADE;
ALTER TABLE f18.konto ADD COLUMN IF NOT EXISTS konto_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.konto ALTER COLUMN konto_id SET DEFAULT gen_random_uuid();


--- f18.tnal  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.tnal', 'f18.tnal' );
ALTER TABLE f18.tnal OWNER TO admin;
GRANT ALL ON TABLE f18.tnal TO xtrole;
ALTER TABLE f18.tnal DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.tnal ADD COLUMN IF NOT EXISTS tnal_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.tnal ALTER COLUMN tnal_id SET DEFAULT gen_random_uuid();

--- f18.tdok  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.tdok', 'f18.tdok' );
ALTER TABLE f18.tdok OWNER TO admin;
GRANT ALL ON TABLE f18.tdok TO xtrole;
ALTER TABLE f18.tdok DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.tdok ADD COLUMN IF NOT EXISTS tdok_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.tdok ALTER COLUMN tdok_id SET DEFAULT gen_random_uuid();

--- f18.sifk  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.sifk', 'f18.sifk' );
ALTER TABLE f18.sifk OWNER TO admin;
GRANT ALL ON TABLE f18.sifk TO xtrole;

--- f18.sifv  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.sifv', 'f18.sifv' );
ALTER TABLE f18.sifv OWNER TO admin;
GRANT ALL ON TABLE f18.sifv TO xtrole;

--- f18.trfp  --------------------------------------------------
SELECT public.create_table_from_then_drop( 'fmk.trfp', 'f18.trfp' );
ALTER TABLE f18.trfp OWNER TO admin;
GRANT ALL ON TABLE f18.trfp TO xtrole;
ALTER TABLE f18.trfp DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.trfp ADD COLUMN IF NOT EXISTS trfp_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.trfp ALTER COLUMN trfp_id SET DEFAULT gen_random_uuid();


-- ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS  uuid uuid DEFAULT gen_random_uuid();
-- ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS ref uuid;
-- ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS ref_2 uuid;
--
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid();
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS ref uuid;
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS ref_2 uuid;
--
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid();
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS ref uuid;
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS ref_2 uuid;
