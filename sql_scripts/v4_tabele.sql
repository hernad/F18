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
