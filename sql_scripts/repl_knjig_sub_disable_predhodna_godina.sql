-- DO $$
-- BEGIN
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub DISABLE;
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub SET (slot_name = NONE);
-- EXCEPTION WHEN OTHERS THEN
--    RAISE INFO 'subskripcije garant nema';
-- END;
-- $$;


ALTER SUBSCRIPTION {{ item.name }}_pos_sub DISABLE;
