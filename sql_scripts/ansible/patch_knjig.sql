

CREATE OR REPLACE FUNCTION patch_metric_id_seq() RETURNS integer
LANGUAGE plpgsql
 AS $$
DECLARE
   nMax integer;
BEGIN

    select MAX(metric_id) + 1 from f18.metric INTO nMax;

    EXECUTE 'ALTER SEQUENCE f18.metric_metric_id_seq RESTART WITH ' || nMax;


   RETURN nMax;
END;
$$;