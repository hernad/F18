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

