-- DO $$
-- BEGIN
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub DISABLE;
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub SET (slot_name = NONE);
-- EXCEPTION WHEN OTHERS THEN
--    RAISE INFO 'subskripcije garant nema';
-- END;
-- $$;


DO $$
BEGIN

-- DROP SUBSCRIPTION IF EXISTS "{{ item.name }}_pos_sub";
CREATE SUBSCRIPTION "{{ item.name }}_pos_sub"  
   CONNECTION 'host={{ item.server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ item.db }}' PUBLICATION {{ item.name }}_pos;

EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija garant postoji';
END;
$$;


ALTER SUBSCRIPTION {{ item.name }}_pos_sub REFRESH PUBLICATION;