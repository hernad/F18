-- DROP SUBSCRIPTION IF EXISTS "p2_pos_sub";

CREATE SUBSCRIPTION "{{ item.name }}_pos_sub_{{ tekuca_godina }}"  
      CONNECTION 'host={{ item.server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ item.db }}' PUBLICATION {{ item.name }}_pos;

-- provjera
-- select * from pg_subscription;