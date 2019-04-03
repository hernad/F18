-- select p2.pos_artikal_istekao_popust('S00361', current_date);
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikal_istekao_popust(cIdRoba varchar, dDatum date) RETURNS numeric
       LANGUAGE plpgsql
       AS $$
DECLARE
   nStanje numeric;
BEGIN
   EXECUTE 'SELECT sum(kol_ulaz-kol_izlaz) as stanje FROM {{ item_prodavnica }}.pos_stanje' ||
           ' WHERE rtrim(idroba)=$1 AND ncijena<>0 AND $2>dat_do' ||
           ' AND kol_ulaz-kol_izlaz>0'
           USING trim(cIdroba), dDatum
           INTO nStanje;

   IF nStanje IS NOT NULL THEN
      RETURN nStanje;
   ELSE
      RETURN 0;
   END IF;
END;
$$;



-- select * from p2.pos_artikli_istekao_popust(current_date);

DROP FUNCTION IF EXISTS {{ item_prodavnica }}.pos_artikli_istekao_popust;
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_istekao_popust(dDatum date) RETURNS table( idroba varchar, cijena numeric, ncijena numeric, stanje numeric)
       LANGUAGE plpgsql
       AS $$
DECLARE
   nStanje numeric;
BEGIN

   -- SELECT idroba, sum(kol_ulaz-kol_izlaz) as stanje FROM p2.pos_stanje
   --    WHERE kol_ulaz-kol_izlaz>0 AND ncijena<>0 AND dat_do<current_date AND rtrim(idroba)=trim('S00361')
   --    GROUP BY idroba
   --    ORDER BY idroba;
   RETURN QUERY SELECT pos_stanje.idroba, pos_stanje.cijena, pos_stanje.ncijena, sum(kol_ulaz-kol_izlaz) as stanje FROM {{ item_prodavnica }}.pos_stanje
           WHERE kol_ulaz-kol_izlaz>0 AND pos_stanje.ncijena<>0 AND dat_do<dDatum
           GROUP BY pos_stanje.idroba, pos_stanje.cijena, pos_stanje.ncijena
           ORDER BY pos_stanje.idroba;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_istekao_popust_gen_99( dDatum date ) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
     cIdPos varchar DEFAULT '1 ';
     cBrDokNew varchar;
     nStanje numeric;
     cIdRoba varchar;
     nCij numeric;
     nNCij numeric;
     nRbr integer;
     uuidPos uuid;

BEGIN
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '99', dDatum);
      nRbr := 0;
      FOR cIdRoba, nStanje, nCij, nNCij IN SELECT
           p.idroba, p.stanje, p.cijena, p.ncijena from {{ item_prodavnica }}.pos_artikli_istekao_popust( dDatum ) p
      LOOP
         nRbr := nRbr + 1;
         IF (nRbr = 1) THEN
            insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od)
               values(cIdPos, '99', cBrDokNew, dDatum, dDatum)
               RETURNING dok_id into uuidPos;
         END IF;
         -- neispravna roba se iznosi po osnovnoj cijeni na skladiste kala; skladiste kala je unutar prodavnice
         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
             using uuidPos, cIdPos, '99', cBrDokNew, dDatum, nRbr, cIdRoba, nStanje, nCij, 0;

      END LOOP;
      RETURN nRbr;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_istekao_popust_gen_79_storno(dDatum date) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdPos varchar DEFAULT '1 ';
   cBrDokNew varchar;
   cIdRoba varchar;
   dDatOd date;
   dDatDo date;
   nCij numeric;
   nNCij numeric;
   nStanje numeric;
   dDatOdDokument date;
   dDatDoDokument date;
   nRbr integer;
   uuidPos uuid;
   nCount integer;
BEGIN

   nCount := 0;
   FOR cIdRoba, nCij, nNCij, nStanje, dDatOd, dDatDo IN SELECT pos_stanje.idroba, pos_stanje.cijena, pos_stanje.ncijena, kol_ulaz-kol_izlaz as stanje, dat_od, coalesce(dat_do,'3999-01-01')
           FROM {{ item_prodavnica }}.pos_stanje
           WHERE kol_ulaz-kol_izlaz>0 AND pos_stanje.ncijena<>0 AND dat_do<dDatum
           ORDER BY dat_od, dat_do
   LOOP
            IF dDatOdDokument IS NULL OR ( dDatOdDokument <> dDatOd OR dDatDoDokument <> dDatDo ) THEN
               dDatOdDokument := dDatOd;
               dDatDoDokument := dDatDo;
               cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '79', dDatum);
               RAISE INFO 'storno 79: % % %', cBrDokNew, dDatOdDokument, dDatDoDokument;
               nRbr := 1;
               insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,dat_do,opis)
                    values(cIdPos, '79', cBrDokNew, dDatum, dDatOdDokument, dDatDoDokument, 'GEN: istekao_popust_gen_79_storno')
                    RETURNING dok_id into uuidPos;
            END IF;

            -- storno 79 => 'ugasiti' snizenje
            EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                using uuidPos, cIdPos, '79', cBrDokNew, dDatum, nRbr, cIdRoba, -nStanje, nCij, nNCij;
            nRbr := nRbr + 1;
            nCount := nCount + 1;
   END LOOP;
   RETURN nCount;

END;
$$;

-- CREATE OR REPLACE FUNCTION p2.test_table() returns table(brdok varchar)
-- LANGUAGE plpgsql
-- AS $$
-- DECLARE
-- BEGIN
--   RETURN QUERY select '00001'::varchar as brdok
--          UNION select '00002'::varchar as brdok;
--
-- END;
-- $$;



-- select * from p2.test_array_to_table('{01,02}'::varchar[]);
--
-- CREATE OR REPLACE FUNCTION p2.test_array_to_table( aBrDoks varchar[] )
--   RETURNS table(brdok varchar)
--   LANGUAGE plpgsql
--   AS
-- $$
-- BEGIN
--   RETURN QUERY SELECT * FROM unnest( aBrDoks ) as brdok;
-- END;
-- $$;


-- select * from p2.test_array_to_table_2();
--
-- CREATE OR REPLACE FUNCTION p2.test_array_to_table_2()
--   RETURNS table(brdok varchar)
--   LANGUAGE plpgsql
--   AS
-- $$
-- DECLARE
--   aBrDoks varchar[] DEFAULT '{}';
-- BEGIN
--
--   aBrDoks := array_append(aBrDoks, 'hello');
--   aBrDoks := array_append(aBrDoks, 'world');
--
--   RETURN QUERY SELECT * FROM unnest( aBrDoks ) as brdok;
-- END;
-- $$;



-- DROP TYPE IF EXISTS test_type CASCADE;
--
-- CREATE TYPE test_type AS
-- (
--        brdok VARCHAR,
--        cnt integer
-- );
--
-- CREATE OR REPLACE FUNCTION p2.test_array_to_table_3()
--   RETURNS table(brdok varchar, cnt integer)
--   LANGUAGE plpgsql
--    AS
--   $$
--  DECLARE
--    aItem  test_type;
--    aBrDoks test_type[] DEFAULT '{}';
--    BEGIN
--    aItem := ('hello', 1);
--    aBrDoks := array_append(aBrDoks, aItem);
--    aItem := ('world', '2');
--    aBrDoks := array_append(aBrDoks, aItem);
--
--    RETURN QUERY SELECT * FROM unnest( aBrDoks );
-- END;
-- $$;
