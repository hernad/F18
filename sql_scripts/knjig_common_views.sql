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


drop view if exists public.log;
CREATE view public.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON public.log TO xtrole;

-- f18.log
drop view if exists public.log;
CREATE view public.log  AS SELECT
      *
    FROM f18.log;

GRANT ALL ON public.log TO xtrole;


-- public.valute
drop view if exists public.valute;
CREATE view public.valute  AS SELECT
  *
FROM
  f18.valute;

GRANT ALL ON public.valute TO xtrole;