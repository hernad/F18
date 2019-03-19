CREATE PUBLICATION {{ prod_schema }}_pos;
ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE p16.roba ;
ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE p16.pos;
ALTER PUBLICATION {{ prod_schema }}_pos ADD TABLE p16.pos_items;