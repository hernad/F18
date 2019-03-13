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
drop function if exists pgp_pub_decrypt_bytea;

drop extension if exists pgcrypto;
create extension pgcrypto;


-- f18 schema
CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

-- f18.fetchmetrictext, f18.setmetric
CREATE TABLE IF NOT EXISTS f18.metric  AS TABLE fmk.metric;
GRANT ALL ON TABLE f18.metric TO xtrole;
GRANT ALL ON TABLE f18.kalk_doks TO xtrole;
DROP TABLE IF EXISTS fmk.metric;

DO $$
DECLARE
  iMax integer;
BEGIN
  select max(metric_id) from f18.metric
    INTO iMax;
  EXECUTE 'CREATE SEQUENCE IF NOT EXISTS f18.metric_metric_id_seq START ' || to_char(iMax+1, '999999');
	ALTER sequence f18.metric_metric_id_seq OWNER TO admin;
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

ALTER TABLE f18.kalk_doks ALTER COLUMN obradjeno TYPE timestamp with time zone;
ALTER TABLE f18.kalk_doks ALTER COLUMN obradjeno SET DEFAULT now();
ALTER TABLE f18.kalk_doks ALTER COLUMN korisnik SET DEFAULT current_user;

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


-- kalk_doks, kalk_kalk - dok_id
ALTER TABLE f18.kalk_doks ADD COLUMN dok_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.kalk_kalk ADD COLUMN dok_id uuid;

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
ALTER TABLE f18.valute DROP COLUMN IF EXISTS match_code CASCADE;

--- f18.konto  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.konto AS  TABLE fmk.konto;
ALTER TABLE f18.konto OWNER TO admin;
GRANT ALL ON TABLE f18.konto TO xtrole;
DROP TABLE IF EXISTS fmk.konto;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS match_code CASCADE;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS pozbilu CASCADE;
ALTER TABLE f18.konto DROP COLUMN IF EXISTS pozbils CASCADE;


--- f18.tnal  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.tnal AS  TABLE fmk.tnal;
ALTER TABLE f18.tnal OWNER TO admin;
GRANT ALL ON TABLE f18.tnal TO xtrole;
DROP TABLE IF EXISTS fmk.tnal;
ALTER TABLE f18.tnal DROP COLUMN IF EXISTS match_code CASCADE;

--- f18.tdok  --------------------------------------------------
CREATE TABLE IF NOT EXISTS f18.tdok AS  TABLE fmk.tdok;
ALTER TABLE f18.tdok OWNER TO admin;
GRANT ALL ON TABLE f18.tdok TO xtrole;
DROP TABLE IF EXISTS fmk.tdok;
ALTER TABLE f18.tdok DROP COLUMN IF EXISTS match_code CASCADE;

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
ALTER TABLE f18.trfp DROP COLUMN IF EXISTS match_code CASCADE;

-- select kalk_dok_id('10','11','00000100', '2018-01-09');
CREATE OR REPLACE FUNCTION public.kalk_dok_id(cIdFirma varchar, cIdVD varchar, cBrDok varchar, dDatDok date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM f18.kalk_doks WHERE idfirma=$1 AND idvd=$2 AND brdok=$3 AND datdok=$4'
     USING cIdFirma, cIdVd, cBrDok, dDatDok
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
   END IF;

   RETURN dok_id;
END;
$$


ALTER TABLE f18.partn ADD COLUMN partn_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
ALTER TABLE f18.konto ADD COLUMN konto_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
ALTER TABLE f18.partn ADD COLUMN partner_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
ALTER TABLE f18.roba ADD COLUMN roba_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY;

CREATE TABLE IF NOT EXISTS f18.fakt_fisk_doks (
    dok_id uuid DEFAULT gen_random_uuid(),
    ref_fakt_dok uuid,
    broj_rn integer,
    ref_storno_fisk_dok uuid,
    partner_id uuid,
    ukupno real,
    popust real,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);
ALTER TABLE f18.fakt_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE f18.fakt_fisk_doks TO xtrole;

CREATE TABLE IF NOT EXISTS p15.pos_fisk_doks (
    dok_id uuid DEFAULT gen_random_uuid(),
    ref_pos_dok uuid,
    broj_rn integer,
    ref_storno_fisk_dok uuid,
    partner_id uuid,
    ukupno real,
    popust real,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);
ALTER TABLE p15.pos_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE p15.pos_fisk_doks TO xtrole;



-- kalk_doks sevence za brojace dokumenata
-- f18.kalk_brdok_seq_02, f18.kalk_brdok_seq_21, f18.kalk_brdok_seq_22
DO $$
DECLARE
  cIdVd text;
  nMaxBrDok integer;
  cQuery text;
BEGIN
  FOR cIdVd IN SELECT unnest('{"02","21","72"}'::text[])
  LOOP
     RAISE info 'idvd=%', cIdVd;
	 SELECT COALESCE(max(to_number(regexp_replace(brdok, '\D', '', 'g'),'9999999')),0) from f18.kalk_doks where idvd=cIdVd
		  INTO nMaxBrDok;
	 RAISE INFO '%', to_char(nMaxBrDok + 1, '999999999');
	 cQuery := 'CREATE SEQUENCE IF NOT EXISTS f18.kalk_brdok_seq_' || cIdVd || ' START ' || to_char(nMaxBrDok + 1, '999999999');
	 RAISE INFO '%', cQuery;
	 EXECUTE cQuery;
	 cQuery := 'ALTER SEQUENCE f18.kalk_brdok_seq_' || cIdVd || ' OWNER to admin';
	 EXECUTE cQuery;
	 cQuery := 'GRANT ALL ON SEQUENCE f18.kalk_brdok_seq_' || cIdVd || ' TO xtrole';
	 EXECUTE cQuery;
  END LOOP;
END;
$$


-- select * from kalk_prod_stanje_sa_kartice('13325', '003189');

CREATE OR REPLACE FUNCTION public.kalk_prod_stanje_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS table( count integer, nv_dug numeric, nv_pot numeric, mpv_dug numeric, mpv_pot numeric, kol_dug numeric, kol_pot numeric, mpc_sa_pdv numeric )
   LANGUAGE plpgsql
AS $$
DECLARE
   cIdVd varchar;
   nKolicina numeric;
   nKolicina2 numeric;
   nKolicinaUlaz numeric DEFAULT 0.0;
   nKolicinaIzlaz numeric DEFAULT 0.0;
   nNVUlaz numeric DEFAULT 0.0;
   nNVIzlaz numeric DEFAULT 0.0;
   nMPVUlaz numeric DEFAULT 0.0;
   nMPVIzlaz numeric DEFAULT 0.0;
   nNC numeric;
   nMpc numeric;
   nMpcStara numeric;
   cPUI varchar;
   nCount integer DEFAULT 0;

BEGIN
  FOR cIdVd, nKolicina, nKolicina2, nNc, nMpc, nMpcStara, cPUI IN SELECT idvd, kolicina, gkolicin2, nc, mpcsapp, fcj, pu_i as start_mpc from kalk_kalk
     WHERE pkonto=cPKonto AND idroba=cIdRoba
  LOOP

    CASE cPUI
     WHEN '1' THEN
         nKolicinaUlaz := nKolicinaUlaz + nKolicina;
         nNvUlaz := nNvUlaz + nKolicina * nNc;
         nMpvUlaz := nMpvUlaz + nKolicina * nMpc;
     WHEN '5' THEN
         nKolicinaIzlaz := nKolicinaIzlaz + nKolicina;
         nNvIzlaz := nNvIzlaz + nKolicina * nNc;
         nMpvIzlaz := nMpvIzlaz + nKolicina * nMpc;
     WHEN '3' THEN
         nMpvUlaz := nMpvUlaz + nKolicina * ( nMpcStara + nMpc) ;
     WHEN 'I' THEN
         nKolicinaIzlaz := nKolicinaIzlaz + nKolicina2;
         nMpvIzlaz := nMpvIzlaz + nKolicina2 * nMpc;
         nNvIzlaz := nNvIzlaz + nKolicina2 * nNc;
    END CASE;
    nCount := nCount + 1;

  END LOOP;

  IF (nKolicinaUlaz-nKolicinaIzlaz) <>0 THEN
     nMpc := ROUND((nMpvUlaz-nMpvIzlaz)/(nKolicinaUlaz-nKolicinaIzlaz), 2);
  ELSE
     nMpc := 0;
  END IF;

  RETURN QUERY SELECT nCount, nNvUlaz, nNvIzlaz, nMpvUlaz, nMpvIzlaz, nKolicinaUlaz, nKolicinaIzlaz, nMpc;
END;
$$;


-- select kalk_prod_mpc_sa_kartice('13325', '003189');

CREATE OR REPLACE FUNCTION public.kalk_prod_mpc_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS numeric
   LANGUAGE plpgsql
AS $$
DECLARE
   nMpc numeric;
BEGIN
  select CASE WHEN (kol_dug-kol_pot)<>0 THEN ROUND((mpv_dug-mpv_pot)/(kol_dug-kol_pot), 2) ELSE 0 END from public.kalk_prod_stanje_sa_kartice( cPKonto, cIdRoba )
     INTO nMpc;
  RETURN nMpc;
END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_prod_kolicina_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS numeric
   LANGUAGE plpgsql
AS $$
DECLARE
   nKolicina numeric;
BEGIN
  select  ROUND(kol_dug-kol_pot, 4) from public.kalk_prod_stanje_sa_kartice( cPKonto, cIdRoba )
     INTO nKolicina;
  RETURN nKolicina;
END;
$$;





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
