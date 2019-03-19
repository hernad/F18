

DO $$
BEGIN

CREATE PUBLICATION {{ prod_schema }}_pos;
ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE p16.pos;
ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE p16.pos_items;

EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'f18_sifre publikacija postoji replikacija';
END;
$$;

