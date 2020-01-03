DO $$
BEGIN
   ALTER SUBSCRIPTION {{ prod_schema }}_f18_sifre_sub_{{ tekuca_godina }} REFRESH PUBLICATION;
EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija {{ prod_schema }}_f18_sifre_sub_{{ tekuca_godina }} ne postoji ?!';
    RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;

DO $$
BEGIN
    ALTER SUBSCRIPTION {{ prod_schema }}_pos_knjig_sub_{{ tekuca_godina }} REFRESH PUBLICATION;
EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija {{ prod_schema }}_pos_knjig_sub_{{ tekuca_godina }} ne postoji ?!';
    RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;