

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.patch_metric_id_seq_pos() RETURNS integer
LANGUAGE plpgsql
 AS $$
DECLARE
   nMax integer;
BEGIN

    -- public.metric
    select MAX(metric_id) + 1 from f18.metric INTO nMax;
    IF nMax IS NOT NULL THEN
       EXECUTE 'ALTER SEQUENCE f18.metric_metric_id_seq RESTART WITH ' || nMax;
    END IF;

    -- p2.metric
    select MAX(metric_id) + 1 from {{ item_prodavnica }}.metric INTO nMax;
    IF nMax IS NOT NULL THEN
       EXECUTE 'ALTER SEQUENCE {{ item_prodavnica }}.metric_metric_id_seq RESTART WITH ' || nMax;
    ELSE
        nMax := 0;
    END IF;

   RETURN nMax;
END;
$$;
