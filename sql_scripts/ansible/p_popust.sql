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


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_istekao_popust_gen_99( dDatum date ) RETURNS void
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
      insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od)
           values(cIdPos, '99', cBrDokNew, dDatum, dDatum)
           RETURNING dok_id into uuidPos;
      nRbr := 1;
      FOR cIdRoba, nStanje, nCij, nNCij IN SELECT
           p.idroba, p.stanje, p.cijena, p.ncijena from {{ item_prodavnica }}.pos_artikli_istekao_popust( dDatum ) p
      LOOP
         -- trenutno aktuelna osnovna cijena je akcijkska
         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using uuidPos, cIdPos, '99', cBrDokNew, dDatum, nRbr, cIdRoba, nStanje, nCij, nNCij;
         nRbr := nRbr + 1;
      END LOOP;
      RETURN;
END;
$$;
