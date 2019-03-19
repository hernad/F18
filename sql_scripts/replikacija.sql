
--------------------------------------------
-- KNJIGOVODSTVO      =>   PRODAVNICA
---------------------------------------------
--    publisher       ->   subscriber
----------------------------------------------
--   f18.valute           f18.valute
--   f18.partn            f18.partn
--   f18.tarifa           f18.tarifa

--  p15.pos_knjig         p15.pos_knjig
--  p15.pos_items_knjig   p15.pos_items_knjig

--  p15.roba              p15.roba


--------------------------------------------
-- KNJIGOVODSTVO      <=   PRODAVNICA
---------------------------------------------

---------------------------------------------
--   subscriber       <-   publisher
----------------------------------------------
--     p15.pos               p15.pos
--     p15.pos_items         p15.pos_items


-- serverside

DROP PUBLICATION IF EXISTS p16_publication;
REVOKE ALL PRIVILEGES ON DATABASE "vindija_2019" FROM replikant;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM replikant;
DROP ROLE IF EXISTS replikant;
CREATE ROLE replikant WITH REPLICATION LOGIN PASSWORD '324GFD664';
GRANT ALL PRIVILEGES ON DATABASE "vindija_2019" TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO replikant;
CREATE PUBLICATION p16_publication;
ALTER PUBLICATION p16_publication ADD TABLE f18.valute ;
ALTER PUBLICATION p16_publication ADD TABLE f18.partn ;
ALTER PUBLICATION p16_publication ADD TABLE f18.tarifa ;


DROP SUBSCRIPTION IF EXISTS "p16_subscription";
CREATE SUBSCRIPTION "p16_subscription"  CONNECTION 'host=192.168.124.223 port=5432 user=replikant password=324GFD664 dbname=p16.vindija_2019' PUBLICATION p16_publication;





-- posside

DROP PUBLICATION IF EXISTS p16_publication;
REVOKE ALL PRIVILEGES ON DATABASE "p16.vindija_2019" FROM replikant;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM replikant;
DROP ROLE IF EXISTS replikant;
CREATE ROLE replikant WITH REPLICATION LOGIN PASSWORD '324GFD664';
GRANT ALL PRIVILEGES ON DATABASE "p16.vindija_2019" TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO replikant;
CREATE PUBLICATION p16_publication;
ALTER PUBLICATION p16_publication ADD TABLE p16.pos;
ALTER PUBLICATION p16_publication ADD TABLE p16.pos_items;

DROP SUBSCRIPTION IF EXISTS "p16_subscription";
CREATE SUBSCRIPTION "p16_subscription"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION p16_publication;
