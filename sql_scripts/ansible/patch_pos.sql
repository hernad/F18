

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.patch_metric_id_seq_pos() RETURNS integer
LANGUAGE plpgsql
 AS $$
DECLARE
   nMax integer;
BEGIN

    -- p2.metric
    select MAX(metric_id) + 1 from {{ item_prodavnica }}.metric INTO nMax;
    EXECUTE 'ALTER SEQUENCE {{ item_prodavnica }}.metric_metric_id_seq RESTART WITH ' || nMax;

    -- public.metric
    select MAX(metric_id) + 1 from public.metric INTO nMax;
    EXECUTE 'ALTER SEQUENCE public.metric_metric_id_seq RESTART WITH ' || nMax;


   RETURN nMax;
END;
$$;