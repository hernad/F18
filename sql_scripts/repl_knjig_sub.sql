DROP SUBSCRIPTION IF EXISTS "{{ item.name }}_pos_sub";
CREATE SUBSCRIPTION "{{ item.name }}_pos_sub"  
   CONNECTION 'host={{ item.server }} port=5432 user={{ replikant }} password={{ replikant_pwd }} dbname={{ item.db }}' PUBLICATION {{ item.name }}_pos;
