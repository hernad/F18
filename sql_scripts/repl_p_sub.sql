DO $$
BEGIN

  -- delete from f18.partn;
  -- delete from f18.valute;
  -- delete from f18.tarifa;
  -- delete from f18.sifk;
  -- delete from f18.sifv;
  CREATE SUBSCRIPTION "{{ prod_schema }}_f18_sifre_sub"
     CONNECTION 'host={{ knjig_server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ knjig_server_db }}' PUBLICATION f18_sifre;


EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija {{ prod_schema }}_f18_sifre_sub garant postoji';
END;
$$;

ALTER SUBSCRIPTION {{ prod_schema }}_f18_sifre_sub REFRESH PUBLICATION;

DO $$
BEGIN

  -- delete from {{ prod_schema }}.pos_knjig;
  -- delete from {{ prod_schema }}.pos_items_knjig;
  CREATE SUBSCRIPTION "{{ prod_schema }}_pos_knjig_sub"
      CONNECTION 'host={{ knjig_server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ knjig_server_db }}' PUBLICATION {{ prod_schema }}_pos_knjig;


EXCEPTION WHEN OTHERS THEN
    RAISE INFO 'subskripcija {{ prod_schema }}_pos_knjig_sub garant postoji';
END;
$$;

ALTER SUBSCRIPTION {{ prod_schema }}_pos_knjig_sub REFRESH PUBLICATION;
