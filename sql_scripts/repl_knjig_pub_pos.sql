GRANT ALL ON SCHEMA {{ item.name }} TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA {{ item.name }} TO replikant;

DO $$
BEGIN

CREATE PUBLICATION {{ item.name }}_pos_knjig_{{ tekuca_godina }};
EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ item.name }}_pos_knjig_{{ tekuca_godina }} publikacija postoji';
END;
$$;


DO $$
BEGIN

ALTER PUBLICATION {{ item.name }}_pos_knjig_{{ tekuca_godina }} ADD TABLE {{ item.name }}.pos_knjig;
ALTER PUBLICATION {{ item.name }}_pos_knjig_{{ tekuca_godina }} ADD TABLE {{ item.name }}.pos_items_knjig;
-- ALTER PUBLICATION {{ item.name }}_pos_knjig ADD TABLE {{ item.name }}.roba;

EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ item.name }}_pos_knjig_{{ tekuca_godina }} tabele publikovane';
END;
$$;


DO $$
BEGIN

ALTER PUBLICATION {{ item.name }}_pos_knjig DROP TABLE {{ item.name }}.roba;

EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ item.name }}_pos_knjig roba uklonjena';
END;
$$;
