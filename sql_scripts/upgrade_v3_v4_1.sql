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






