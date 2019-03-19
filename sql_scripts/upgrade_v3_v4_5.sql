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
ALTER TABLE f18.partn ALTER COLUMN partner_id SET DEFAULT gen_random_uuid();

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

ALTER TABLE f18.sifk ADD COLUMN IF NOT EXISTS sifk_id uuid DEFAULT gen_random_uuid();
ALTER TABLE f18.sifv ADD COLUMN IF NOT EXISTS sifv_id uuid DEFAULT gen_random_uuid();

ALTER TABLE f18.sifv ALTER COLUMN sifv_id SET DEFAULT gen_random_uuid();
ALTER TABLE f18.sifk ALTER COLUMN sifk_id SET DEFAULT gen_random_uuid();


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
