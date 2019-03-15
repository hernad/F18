-- f18 schema
CREATE SCHEMA IF NOT EXISTS f18;
ALTER SCHEMA f18 OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

CREATE TABLE IF NOT EXISTS f18.metric
(
    metric_id integer,
    metric_name text COLLATE pg_catalog."default",
    metric_value text COLLATE pg_catalog."default",
    metric_module text COLLATE pg_catalog."default"
);

CREATE SEQUENCE f18.metric_metric_id_seq;
ALTER SEQUENCE f18.metric_metric_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE f18.metric_metric_id_seq TO admin;
GRANT ALL ON SEQUENCE f18.metric_metric_id_seq TO xtrole;
ALTER TABLE f18.metric OWNER to admin;
GRANT ALL ON TABLE f18.metric TO xtrole;

CREATE OR REPLACE FUNCTION public.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM f18.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$$;

CREATE OR REPLACE FUNCTION public.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM f18.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM f18.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE f18.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO f18.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$$;

ALTER FUNCTION public.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION public.fetchmetrictext TO xtrole;

ALTER FUNCTION public.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION public.setmetric TO xtrole;


CREATE TABLE IF NOT EXISTS f18.partn
(
    partner_id uuid DEFAULT gen_random_uuid(),
    id character(6) COLLATE pg_catalog."default",
    naz character(250) COLLATE pg_catalog."default",
    naz2 character(250) COLLATE pg_catalog."default",
    ptt character(5) COLLATE pg_catalog."default",
    mjesto character(16) COLLATE pg_catalog."default",
    adresa character(24) COLLATE pg_catalog."default",
    ziror character(22) COLLATE pg_catalog."default",
    rejon character(4) COLLATE pg_catalog."default",
    telefon character(12) COLLATE pg_catalog."default",
    dziror character(22) COLLATE pg_catalog."default",
    fax character(12) COLLATE pg_catalog."default",
    mobtel character(20) COLLATE pg_catalog."default",
    idops character(4) COLLATE pg_catalog."default",
    _kup character(1) COLLATE pg_catalog."default",
    _dob character(1) COLLATE pg_catalog."default",
    _banka character(1) COLLATE pg_catalog."default",
    _radnik character(1) COLLATE pg_catalog."default",
    idrefer character(10) COLLATE pg_catalog."default"

);
ALTER TABLE f18.partn OWNER to admin;
GRANT ALL ON TABLE f18.partn TO xtrole;

-- public.partn
drop view if exists public.partn;
CREATE view public.partn  AS
  SELECT id, naz, naz2, ptt, mjesto, adresa, ziror, rejon, telefon, dziror, fax, mobtel,
         idops, _kup, _dob, _banka, _radnik, idrefer
FROM
  f18.partn;

CREATE OR REPLACE RULE public_partn_ins AS ON INSERT TO public.partn
        DO INSTEAD INSERT INTO f18.partn(
           id, naz, naz2, ptt, mjesto, adresa, ziror, rejon, telefon, dziror, fax, mobtel,
                 idops, _kup, _dob, _banka, _radnik, idrefer
        ) VALUES (
           NEW.id, NEW.naz, NEW.naz2, NEW.ptt, NEW.mjesto, NEW.adresa, NEW.ziror, NEW.rejon, NEW.telefon, NEW.dziror, NEW.fax, NEW.mobtel,
                NEW.idops, NEW._kup, NEW._dob, NEW._banka, NEW._radnik, NEW.idrefer
        );

GRANT ALL ON public.partn TO xtrole;


CREATE TABLE IF NOT EXISTS  f18.tarifa
(
    tarifa_id uuid DEFAULT gen_random_uuid(),
    id character(6) COLLATE pg_catalog."default",
    naz character(50) COLLATE pg_catalog."default",
    pdv numeric(6,2)
);

----  public.tarifa
drop view if exists public.tarifa;
CREATE view public.tarifa  AS SELECT
  id, naz, pdv
FROM
  f18.tarifa;

CREATE OR REPLACE RULE public_tarifa_ins AS ON INSERT TO public.tarifa
    DO INSTEAD INSERT INTO f18.tarifa(
      id, naz, pdv
    ) VALUES (
      NEW.id, NEW.naz, NEW.pdv
    );

GRANT ALL ON public.tarifa TO xtrole;


CREATE TABLE IF NOT EXISTS public.schema_migrations
(
    version integer NOT NULL,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY (version)
);

ALTER TABLE public.schema_migrations OWNER to admin;

GRANT ALL ON TABLE public.schema_migrations TO admin;
GRANT SELECT ON TABLE public.schema_migrations TO xtrole;


CREATE TABLE IF NOT EXISTS f18.valute
(
    id character(4) COLLATE pg_catalog."default",
    naz character(30) COLLATE pg_catalog."default",
    naz2 character(4) COLLATE pg_catalog."default",
    datum date,
    kurs1 numeric(18,8),
    kurs2 numeric(18,8),
    kurs3 numeric(18,8),
    tip character(1) COLLATE pg_catalog."default",
    valuta_id uuid DEFAULT gen_random_uuid()
);
ALTER TABLE f18.valute OWNER to admin;
GRANT ALL ON TABLE f18.valute TO admin;
GRANT ALL ON TABLE f18.valute TO xtrole;

-- public.valute
drop view if exists public.valute;
CREATE view public.valute  AS SELECT
  *
FROM
  f18.valute;

GRANT ALL ON public.valute TO xtrole;

CREATE SEQUENCE f18.log_id_seq;
ALTER SEQUENCE f18.log_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE f18.log_id_seq TO admin;
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
    ON fmk.log USING btree
    (l_time)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS log_user_code_idx
    ON fmk.log USING btree
    (user_code COLLATE pg_catalog."default")
    TABLESPACE pg_default;

-- fmk schema
CREATE SCHEMA IF NOT EXISTS fmk;
ALTER SCHEMA fmk OWNER TO admin;
GRANT ALL ON SCHEMA f18 TO xtrole;

-- fmk.log
drop view if exists fmk.log;
CREATE view fmk.log  AS SELECT
      *
    FROM
      f18.log;

GRANT ALL ON fmk.log TO xtrole;
