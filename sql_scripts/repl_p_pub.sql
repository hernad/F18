DO $$
BEGIN
   CREATE PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }};
EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ prod_schema }}_pos publikacija_{{ tekuca_godina } postoji replikacija';
   RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;


DO $$
BEGIN
   ALTER PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }} ADD TABLE {{ prod_schema }}.pos;
   ALTER PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }} ADD TABLE {{ prod_schema }}.pos_items;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tabele su vec ubacene u publikaciju {{ prod_schema }}_pos_{{ tekuca_godina }';
   RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;


DO $$
BEGIN
   ALTER PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }} ADD TABLE {{ prod_schema }}.roba;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tabela roba vec ubacene u publikaciju {{ prod_schema }}_pos_{{ tekuca_godina }}';
   RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;

DO $$
BEGIN
   ALTER PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }} ADD TABLE {{ prod_schema }}.pos_stanje;
   ALTER PUBLICATION {{ prod_schema }}_pos_{{ tekuca_godina }} ADD TABLE {{ prod_schema }}.pos_fisk_doks;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tabele pos_stanje i pos_fisk_doks vec ubacene u publikaciju {{ prod_schema }}_pos_{{ tekuca_godina }}';
   RAISE INFO '% %', SQLERRM, SQLSTATE;
END;
$$;
