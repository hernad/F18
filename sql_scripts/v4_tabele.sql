-- f18 schema
CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

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

CREATE SEQUENCE f18.log_id_seq;
ALTER SEQUENCE f18.log_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE f18.log_id_seq TO xtrole;

CREATE TABLE IF NOT EXISTS f18.log
(
    id bigint NOT NULL DEFAULT nextval('f18.log_id_seq'::regclass),
    user_code character varying(20) COLLATE pg_catalog."default" NOT NULL,
    l_time timestamp without time zone DEFAULT now(),
    msg text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT log_pkey PRIMARY KEY (id)
);

ALTER TABLE f18.log OWNER to admin;
GRANT ALL ON TABLE fmk.log TO admin;
GRANT ALL ON TABLE fmk.log TO xtrole;

CREATE INDEX IF NOT EXISTS log_l_time_idx
    ON fmk.log USING btree (l_time);

CREATE INDEX IF NOT EXISTS log_user_code_idx
    ON fmk.log USING btree(user_code COLLATE pg_catalog."default");
