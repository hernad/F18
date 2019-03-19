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

CREATE SEQUENCE IF NOT EXISTS f18.log_id_seq;
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
GRANT ALL ON TABLE f18.log TO admin;
GRANT ALL ON TABLE f18.log TO xtrole;

CREATE INDEX IF NOT EXISTS log_l_time_idx
    ON f18.log USING btree (l_time);

CREATE INDEX IF NOT EXISTS log_user_code_idx
    ON f18.log USING btree(user_code COLLATE pg_catalog."default");

-- kalk_doks sevence za brojace dokumenata
-- koristi FUNCTION public.kalk_novi_brdok(cIdVd varchar)
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
$$;

DO $$
BEGIN
   ALTER TABLE f18.partn ALTER COLUMN partner_id SET DEFAULT gen_random_uuid();
   ALTER TABLE f18.partn ADD PRIMARY KEY (partner_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'partn primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.konto ALTER COLUMN konto_id SET DEFAULT gen_random_uuid();
   ALTER TABLE f18.konto ADD PRIMARY KEY (konto_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'konto primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.tarifa ADD PRIMARY KEY (tarifa_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tarifa primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.valute ADD PRIMARY KEY (valuta_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'valuta primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.sifk ADD PRIMARY KEY (sifk_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'sifk primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.sifv ADD PRIMARY KEY (sifv_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'sifv primary key garant postoji';
END;
$$;

DO $$
BEGIN
   ALTER TABLE f18.kalk_kalk ADD COLUMN IF NOT EXISTS item_id uuid DEFAULT gen_random_uuid();
   ALTER TABLE f18.kalk_kalk ADD PRIMARY KEY (item_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'f18.kalk_kalk primary item_id garant postoji';
END;
$$;


DO $$
BEGIN
   update f18.kalk_doks set dok_id=gen_random_uuid() where dok_id is null;
   ALTER TABLE f18.kalk_doks ADD PRIMARY KEY (dok_id);

EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'f18.kalk_doks dok_id primary key garant postoji';
END;
$$;
