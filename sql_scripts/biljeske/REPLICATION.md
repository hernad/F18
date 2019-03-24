-- ##############
--     server
-- ##############


-- strana knjigovodstvo

GRANT ALL ON SCHEMA f18 TO replikant;
REVOKE ALL PRIVILEGES ON DATABASE "vindija_2019" FROM replikant;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM replikant;
GRANT ALL PRIVILEGES ON DATABASE "vindija_2019" TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA f18 TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA p16 TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO replikant;


-- strana prodavnice

GRANT ALL ON SCHEMA f18 TO replikant;
REVOKE ALL PRIVILEGES ON DATABASE "p16.vindija_2019" FROM replikant;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM replikant;
GRANT ALL PRIVILEGES ON DATABASE "p16.vindija_2019" TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA f18 TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA p16 TO replikant;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO replikant;



-- f18 schema publication na strani knjigovodstva

DROP PUBLICATION IF EXISTS f18_publication;
CREATE PUBLICATION f18_publication;
ALTER PUBLICATION  f18_publication ADD TABLE f18.valute ;
ALTER PUBLICATION  f18_publication ADD TABLE f18.partn ;
ALTER PUBLICATION  f18_publication ADD TABLE f18.tarifa ;

-- pos publication na strani knjigovodstva

DROP PUBLICATION IF EXISTS p16_publication;
CREATE PUBLICATION p16_publication;
ALTER PUBLICATION p16_publication ADD TABLE p16.pos_knjig;
ALTER PUBLICATION p16_publication ADD TABLE p16.pos_items_knjig;


-- na strani POS se subscribamo

CREATE SUBSCRIPTION "f18_subscription"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION f18_publication;
CREATE SUBSCRIPTION "p16_subscription"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION p16_publication;


-- svaka subskripcija mora imati posebno ime


CREATE SUBSCRIPTION "f18_subscription2"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION f18_publication;


-- ##############
--     POS
-- ##############




-- ##############
--     PROVJERA
-- ##############


select count (*)  from f18.valute
UNION ALL
select count (*)  from f18.tarifa
UNION ALL
select count (*)  from f18.partn
UNION ALL
select count (*)  from p16.pos_knjig
UNION ALL
select count (*)  from p16.pos_items_knjig;

-- ##############
--     RESET
--     Mora se dropati SUBSCRIPTION + obrisati tabele
-- ##############

DROP SUBSCRIPTION IF EXISTS "p16_subscription";
DROP SUBSCRIPTION IF EXISTS "f18_subscription";
delete  from f18.partn;
delete  from f18.valute;
delete  from f18.tarifa;
delete  from p16.pos_knjig;
delete  from p16.pos_items_knjig;

CREATE SUBSCRIPTION "f18_subscription"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION f18_publication;
CREATE SUBSCRIPTION "p16_subscription"  CONNECTION 'host=192.168.124.164 port=5432 user=replikant password=324GFD664 dbname=vindija_2019' PUBLICATION p16_publication;
