

DO $$
BEGIN
   CREATE PUBLICATION {{ prod_schema }}_pos;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ prod_schema }}_pos publikacija postoji replikacija';
END;
$$;


DO $$
BEGIN
   ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE {{ prod_schema }}.pos;
   ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE {{ prod_schema }}.pos_items;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tabele su vec ubacene u publikaciju {{ prod_schema }}_pos';
END;
$$;


DO $$
BEGIN
   ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE {{ prod_schema }}.roba;
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'tabela roba vec ubacene u publikaciju {{ prod_schema }}_pos';
END;
$$;




