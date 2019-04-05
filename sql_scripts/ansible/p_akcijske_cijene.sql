CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuidPos uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT uuid FROM {{ item_prodavnica }}.pos
          WHERE idvd='72' AND ref IS NULL AND dat_od=current_date
     LOOP
          RAISE INFO 'pos %', uuidPos;
          PERFORM {{ item_prodavnica }}.nivelacija_start_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_broj_stavki(uuidPos uuid) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
   nRows integer;
BEGIN
    SELECT count(item_id) FROM {{ item_prodavnica }}.pos_items WHERE dok_id=uuidPos
       INTO nRows;
    nRows := coalesce(nRows, 0);
    RETURN nRows;
END;
$$;

DROP FUNCTION IF EXISTS {{ item_prodavnica }}.nivelacija_start_create(uuidPos uuid);
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.nivelacija_start_create(uuidPos uuid) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar;
      cIdVd varchar;
      cBrDok varchar;
      dDatum date;
      cIdRoba varchar;
      dDat_od date;
      uuid2 uuid;
      nC numeric;
      nC2 numeric;
      nRbr integer;
      cBrDokNew varchar;
      dDatumNew date;
      nStanje numeric;
      nCount integer;
      rec_roba RECORD;
      nRows integer;
      cOpis varchar;
      nOsnovnaCijena numeric;
      cMsg varchar;
BEGIN
      -- pos dokument '72' sa ovim dok_id-om
      EXECUTE 'select idpos,idvd,brdok,datum,dat_od from {{ item_prodavnica }}.pos where dok_id=$1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_od;
      RAISE INFO 'nivelacija_start_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_od;

      nRows :=  {{ item_prodavnica }}.pos_broj_stavki(uuidPos);
      cOpis := 'ROWS:[' || btrim(to_char(nRows, '9999')) || ']';

      -- pos dokument nivelacije '29' kome je referenca ovaj dok_id ne smije postojati
      EXECUTE 'select dok_id from {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND ref=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;
      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_start dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_od;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);
      insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,ref,opis) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos,cOpis)
          RETURNING dok_id into uuid2;

      -- referenca na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos set ref=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      nCount := 0;
      -- proci kroz stavke dokumenta '72'
      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from {{ item_prodavnica }}.pos_items WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- aktuelna osnovna cijena;
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba);
         IF nStanje > 0 THEN -- osnovna cijena za artikal u pos
            nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal(cIdRoba);
            IF nOsnovnaCijena <> nC THEN
               cMsg := format('stara cijena %s u dokumentu i akutelna osnovna cijena %s se razlikuju?', nC, nOsnovnaCijena);
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_START', cMsg);
               RAISE INFO '%', cMsg;
            END IF;
         ELSE  -- na stanju nema artikla, koristi se stara cijena u zahtjevu za nivelaciju
            nOsnovnaCijena := nC;
         END IF;
         SELECT * FROM {{ item_prodavnica }}.roba
            WHERE id=cIdRoba
            INTO rec_roba;

         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nOsnovnaCijena, nC2, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
         nCount := nCount + 1;
      END LOOP;

      RETURN nCount;
END;
$$;


DROP FUNCTION IF EXISTS {{ item_prodavnica }}.nivelacija_end_create(uuidPos uuid);
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.nivelacija_end_create(uuidPos uuid) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar;
      cIdVd varchar;
      cBrDok varchar;
      dDatum date;
      cIdRoba varchar;
      dDat_do date;
      uuid2 uuid;
      nC numeric;
      nC2 numeric;
      nRbr integer;
      cBrDokNew varchar;
      dDatumNew date;
      nStanje numeric;
      nCount integer;
      nRows integer;
      cOpis varchar;
      nOsnovnaCijena numeric;
      cMsg varchar;
BEGIN

      -- pos dokument '72'
      EXECUTE 'select idpos,idvd,brdok,datum, dat_od from {{ item_prodavnica }}.pos where dok_id = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_do;
      RAISE INFO 'nivelacija_end_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_do;

      nRows :=  {{ item_prodavnica }}.pos_broj_stavki(uuidPos);
      cOpis := 'ROWS:[' || btrim(to_char(nRows, '9999')) || ']';

      -- pos dokument nivelacije '29' sa ref_2 na dok_id ne smije postojati
      EXECUTE 'select uuid from {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND ref_2=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;

      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_end dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_do;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);
      insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,ref,opis) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos,cOpis)
          RETURNING dok_id into uuid2;

      -- referenca (2) na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos set ref_2=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      nCount := 0;
      -- prolazak kroz stavke dokumenta '72'
      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from {{ item_prodavnica }}.pos_items WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- trenutno aktuelna osnovna cijena je akcijska
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba);
         IF nStanje > 0 THEN -- osnovna cijena za artikal u pos
            nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal(cIdRoba);
            IF nOsnovnaCijena <> nC2 THEN
               cMsg := format('nova cijena %s u dokumentu i akutelna osnovna cijena %s se razlikuju?', nC, nOsnovnaCijena);
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_END', cMsg);
               RAISE INFO '%', cMsg;
            END IF;
         ELSE  -- na stanju nema artikla, koristi se stara cijena u zahtjevu za nivelaciju
            nOsnovnaCijena := nC2;
         END IF;
         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nC2, nC;
         nCount := nCount + 1;
      END LOOP;

      RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_storno(dDatum date, uuidUzrok72 uuid) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdPos varchar DEFAULT '1 ';
   rec_dok72 RECORD;
   cBrDokNew varchar;
   cIdRoba varchar;
   nCij numeric;
   nNCij numeric;
   nStanje numeric;
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
           nStanje := {{ item_prodavnica }}.pos_kalo(cIdRoba);
           IF nStanje <> 0 THEN
               IF cBrDokNew IS NULL THEN
                  cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '99', dDatum);
                  RAISE INFO 'zbog 72 storno 99: %', cBrDokNew;
                  nRbr := 1;
                  insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,opis,ref)
                       values(cIdPos, '99', cBrDokNew, dDatum, dDatum, 'GEN: zbog_72_gen_99_storno', uuidUzrok72)
                       RETURNING dok_id into uuidPos;
               END IF;

               nCij := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal(cIdRoba);
               -- storno 99
               EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                    using uuidPos, cIdPos, '99', cBrDokNew, dDatum, nRbr, cIdRoba, -nStanje, nCij, 0;
               nRbr := nRbr + 1;
               nCount := nCount + 1;
           END IF;

   END LOOP;
   RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_plus(dDatum date, uuidUzrok72 uuid) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdPos varchar DEFAULT '1 ';
   rec_dok99_storno RECORD;
   rec RECORD;
   cBrDokNew varchar;
   cIdRoba varchar;
   nCij numeric;
   uuidPos uuid;
   nCount integer;
BEGIN

   nCount := 0;
   --
   SELECT * FROM {{ item_prodavnica }}.pos where ref=uuidUzrok72 and idvd='99' and datum=dDatum
     INTO rec_dok99_storno;

   -- prolaz kroz dokument 99 storno
   FOR rec IN select * FROM {{ item_prodavnica }}.pos_items where idpos=rec_dok99_storno.idpos and idvd=rec_dok99_storno.idvd and brdok=rec_dok99_storno.brdok and datum=rec_dok99_storno.datum
   LOOP
         IF cBrDokNew IS NULL THEN
              cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '99', dDatum);
              RAISE INFO 'zbog 72 vratiti 99 plus: %', cBrDokNew;
              insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,opis,ref)
                       values(cIdPos, '99', cBrDokNew, dDatum, dDatum, 'GEN: zbog_72_gen_99_plus', rec_dok99_storno.dok_id)
                       RETURNING dok_id into uuidPos;
          END IF;

          nCij := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( rec.idroba );
          -- vratiti 99
          EXECUTE 'insert into {{ item_prodavnica }}.pos_items(dok_id,idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                using uuidPos, rec.idpos, '99', cBrDokNew, dDatum, rec.rbr, rec.idroba, -rec.kolicina, nCij, 0;

          nCount := nCount + 1;

   END LOOP;
   RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$

DECLARE
       uuid72 uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuid72 IN SELECT dok_id FROM {{ item_prodavnica }}.pos
          WHERE idvd='72' AND ref IS NULL AND dat_od = current_date
     LOOP
            RAISE INFO 'nivelacija_start 72: %', uuid72;

            -- storno 79
            PERFORM {{ item_prodavnica }}.pos_artikli_prekid_popust_zbog_72_gen_79_storno(current_date, uuid72);
            PERFORM {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_storno(current_date, uuid72);

            -- kreirati 29
            PERFORM {{ item_prodavnica }}.nivelacija_start_create( uuid72 );
            -- + 79 po novim cijenama
            PERFORM {{ item_prodavnica }}.pos_artikli_vratiti_popust_gen_79(current_date, uuid72);
            -- + 99 po novim cijenama
            PERFORM {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_plus(current_date, uuid72);

     END LOOP;

     RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_end() RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuidPos uuid;
BEGIN
     -- ref_2 nije popunjen => zavrsna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT dok_id FROM {{ item_prodavnica }}.pos
          WHERE idvd='72' AND ref_2 IS NULL AND dat_do = current_date
     LOOP
          RAISE INFO 'pos %', uuidPos;
          PERFORM {{ item_prodavnica }}.nivelacija_end_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$;
