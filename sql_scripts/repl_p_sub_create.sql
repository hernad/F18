-- delete from f18.partn;
-- delete from f18.valute;
-- delete from f18.tarifa;
-- delete from f18.sifk;
-- delete from f18.sifv;
CREATE SUBSCRIPTION "{{ prod_schema }}_f18_sifre_sub"
     CONNECTION 'host={{ knjig_server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ knjig_server_db }}' PUBLICATION f18_sifre;

-- delete from {{ prod_schema }}.pos_knjig;
-- delete from {{ prod_schema }}.pos_items_knjig;
CREATE SUBSCRIPTION "{{ prod_schema }}_pos_knjig_sub"
      CONNECTION 'host={{ knjig_server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ knjig_server_db }}' PUBLICATION {{ prod_schema }}_pos_knjig;

-- provjera
-- select * from pg_subscription;