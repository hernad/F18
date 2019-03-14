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


CREATE IF NOT EXISTS TABLE f18.partn
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
