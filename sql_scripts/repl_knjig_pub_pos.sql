DO $$
BEGIN

CREATE PUBLICATION {{ item.name }}_pos_knjig;
ALTER PUBLICATION {{ item.name }}_pos_knjig ADD TABLE {{ item.name }}.pos_knjig;
ALTER PUBLICATION {{ item.name }}_pos_knjig ADD TABLE {{ item.name }}.pos_items_knjig;


EXCEPTION WHEN OTHERS THEN
   RAISE INFO '{{ item.name }}_pos_knjig publikacija postoji replikaciju postoji';
END;
$$;
