-- DO $$
-- BEGIN
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub DISABLE;
--   ALTER SUBSCRIPTION {{ item.name }}_pos_sub SET (slot_name = NONE);
-- EXCEPTION WHEN OTHERS THEN
--    RAISE INFO 'subskripcije garant nema';
-- END;
-- $$;

-- od 2020 treba ovako:
-- ALTER SUBSCRIPTION {{ item.name }}_pos_sub_{{ predhodna_godina }} DISABLE;

-- za sada radi 2019 treba ovako:
ALTER SUBSCRIPTION {{ item.name }}_pos_sub DISABLE;
