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



-- uuidUzrok72 : dokumnet koji je uzrokovao storniranje

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_prekid_popust_zbog_72_gen_79_storno(dDatum date, uuidUzrok72 uuid) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdPos varchar DEFAULT '1 ';
   rec_dok72 RECORD;
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
   SELECT * FROM {{ item_prodavnica }}.pos where dok_id=uuidUzrok72
     INTO rec_dok72;

   -- prolaz kroz dokument 72
   FOR cIdRoba IN select idroba FROM {{ item_prodavnica }}.pos_items where idpos=rec_dok72.idpos and idvd=rec_dok72.idvd and brdok=rec_dok72.brdok and datum=rec_dok72.datum
   LOOP
           -- prolaz kroz stavke za koje postoji snizenje
           FOR nCij, nNCij, nStanje, dDatOd, dDatDo IN
              SELECT pos_stanje.cijena, pos_stanje.ncijena, kol_ulaz-kol_izlaz as stanje, dat_od, coalesce(dat_do,'3999-01-01')
              FROM {{ item_prodavnica }}.pos_stanje
              WHERE kol_ulaz-kol_izlaz>0 AND pos_stanje.ncijena<>0 AND idroba=cIdRoba
           LOOP
               IF dDatOdDokument IS NULL OR ( dDatOdDokument <> dDatOd OR dDatDoDokument <> dDatDo ) THEN
                  dDatOdDokument := dDatOd;
                  dDatDoDokument := dDatDo;
                  cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '79', dDatum);
                  RAISE INFO 'storno svi 79: % % %', cBrDokNew, dDatOdDokument, dDatDoDokument;
                  nRbr := 1;
                  insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,dat_do,opis,ref)
                       values(cIdPos, '79', cBrDokNew, dDatum, dDatOdDokument, dDatDoDokument, 'GEN: stop_popust_zbog_72_gen_79_storno', uuidUzrok72)
                       RETURNING dok_id into uuidPos;
               END IF;
               -- storno 79 => 'ugasiti' snizenje
               EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                    using uuidPos, cIdPos, '79', cBrDokNew, dDatum, nRbr, cIdRoba, -nStanje, nCij, nNCij;
               nRbr := nRbr + 1;
               nCount := nCount + 1;
            END LOOP;
   END LOOP;
   RETURN nCount;

END;
$$;



-- pos 79 storno dokument -> pos 79 plus dokument po aktuelnim osnovnim cijenama

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_79_storno_to_79( uuidSrc uuid ) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
    rec_dok RECORD;
    rec RECORD;
    dokIdCheck uuid;
    nCij numeric;
    nNCij numeric;
    uuidNewDok uuid;
    cBrDokNew varchar;
BEGIN
     select * from {{ item_prodavnica }}.pos where dok_id=uuidSrc
        INTO rec_dok;

     IF rec_dok.dok_id is NULL  THEN
         RAISE INFO 'NE POSTOJI 79 sa uuidSrc % ?', uuidSrc;
         RETURN -1;
     END IF;

     select dok_id from {{ item_prodavnica }}.pos where ref=uuidSrc
        INTO dokIdCheck;

     IF dokIdCheck IS NOT NULL  THEN
         RAISE INFO 'VEC POSTOJI izgenerisan 79 na osnovu 79-storno: % ?', dokIdCheck;
         RETURN -2;
     END IF;

     cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(rec_dok.idpos, rec_dok.idvd, current_date );
     INSERT INTO {{ item_prodavnica }}.pos(ref, idpos, idvd, brdok, datum, brfaktp, opis, dat_od, dat_do, idpartner)
         VALUES( uuidSrc, rec_dok.idpos, rec_dok.idvd, cBrDokNew, rec_dok.datum, rec_dok.brfaktp, rec_dok.opis, rec_dok.dat_od, rec_dok.dat_do, rec_dok.idpartner)
         RETURNING dok_id
         INTO uuidNewDok;

     FOR rec IN
            SELECT * from {{ item_prodavnica }}.pos_items
            WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum
     LOOP
            nCij := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( rec.idroba );
            nNCij := rec.ncijena;
            IF (nCij = 0) THEN
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'SKIP_GEN_79_CIJENA', format('%s-%s-%s Osnovna cijena 0 ?!', rec_dok.idpos, rec_dok.idvd, rec_dok.brdok));
            ELSIF (nNCij >= nCij) THEN
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'SKIP_GEN_79_CIJENA', format('%s-%s-%s Nova cijena %s >= osnovna %s', rec_dok.idpos, rec_dok.idvd, rec_dok.brdok, nNCij, nCij));
            ELSE
               INSERT INTO {{ item_prodavnica }}.pos_items(dok_id, idpos, idvd, brdok, datum, rbr, kolicina, idroba, idtarifa, cijena, ncijena, kol2, robanaz, jmj)
                 VALUES(uuidNewDok, rec_dok.idpos, rec_dok.idvd, cBrDokNew, rec_dok.datum, rec.rbr, -rec.kolicina, rec.idroba, rec.idtarifa, nCij, nNCij, rec.kol2, rec.robanaz, rec.jmj);
            END IF;
     END LOOP;
     RETURN 0;
END;
$$;

-- za sve storno dokumente izgenerisani na osnovu uuidUzrok72 napraviti nova snizenja

DROP FUNCTION IF EXISTS {{ item_prodavnica }}.pos_artikli_vratiti_popust_gen_79(date,uuid);
DROP FUNCTION IF EXISTS {{ item_prodavnica }}.pos_artikli_vratiti_popust_gen_79(uuidUzrok72 uuid);

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_vratiti_popust_gen_79(dDatum date, uuidUzrok72 uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
   nRet integer;
   uuid79 uuid;
   nCount integer;
BEGIN
   nCount := 0;
   -- svi dokumenti 79 koje je generisalo snizenje cijena '29' sa dok_id=uuidUzrok72
   FOR uuid79 IN SELECT dok_id FROM {{ item_prodavnica }}.pos WHERE ref=uuidUzrok72 and idvd='79' and datum=dDatum
   LOOP
        SELECT {{ item_prodavnica }}.pos_79_storno_to_79( uuid79 )
           INTO nRet;
        RAISE INFO 'pos_79_storno_to_79 % %', uuid79, nRet;
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




CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_popust_naknadna_obrada() RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
   nCount integer;
   rec RECORD;
   rec_dok RECORD;
   nKolPromCijena decimal;
BEGIN

nCount := 0;

FOR rec IN
        SELECT * FROM {{ item_prodavnica }}.pos_items
            WHERE idvd='79' and kolicina > 0 and kol2 = -99999.999
LOOP
     --SELECT {{ item_prodavnica }}.pos_79_storno_to_79( uuid79 )
      --  INTO nRet;
     -- RAISE INFO 'pos_79_storno_to_79 % %', uuid79, nRet;
     select * from {{ item_prodavnica }}.pos where dok_id=rec.dok_id
        INTO rec_dok;

     IF rec_dok.dat_od <= current_date THEN
         EXECUTE 'SELECT {{ item_prodavnica }}.pos_promjena_cijena_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'
           USING rec.idPos, rec.idvd, rec.brdok, rec.rbr, rec.datum, rec_dok.dat_od, rec_dok.dat_do, rec.idroba, rec.kolicina, rec.cijena, rec.ncijena
            INTO nKolPromCijena;

       IF nKolPromCijena < 0 THEN -- ako je bilo gresaka onda je odobrena kolicina 0
           nKolPromCijena := 0;
       END IF;

       EXECUTE 'UPDATE {{ item_prodavnica }}.pos_items set kol2=$2 WHERE item_id=$1'
             USING rec.item_id, nKolPromCijena;

        nCount := nCount + 1;
      END IF;


END LOOP;

RETURN nCount;

END;
$$;
