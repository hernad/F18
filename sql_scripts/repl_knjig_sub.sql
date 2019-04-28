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
    ALTER SUBSCRIPTION {{ item.name }}_pos_sub REFRESH PUBLICATION;
EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija {{ item.name }}_pos_sub ne postoji?!';
    RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;