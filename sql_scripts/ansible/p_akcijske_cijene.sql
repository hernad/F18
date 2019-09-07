


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
      cIdTarifa varchar;
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

      --dDatumNew := dDat_od;
      dDatumNew := current_date;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);
      insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,ref,opis) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos,cOpis)
          RETURNING dok_id into uuid2;

      -- referenca na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos set ref=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      nCount := 0;
      -- proci kroz stavke dokumenta '72'
      FOR nRbr, cIdRoba, nC, nC2, cIdTarifa IN SELECT rbr,idRoba,cijena,ncijena,idtarifa from {{ item_prodavnica }}.pos_items WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- aktuelna osnovna cijena;
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba);
         IF nStanje > 0 THEN -- osnovna cijena za artikal u pos
            nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal(cIdRoba);
            IF nOsnovnaCijena <> nC THEN
               cMsg := format(' %s : stara cijena %s u dokumentu i akutelna osnovna cijena %s se razlikuju?', cIdRoba, nC, nOsnovnaCijena);
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_START', cMsg);
               RAISE INFO '%', cMsg;
            END IF;
         ELSIF nStanje < 0 THEN
            cMsg := format('%s: stanje negativno %s !? stara cijena %s ostaje na snazi', cIdRoba, nStanje, nC);
            PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_START_STANJE', cMsg);
            --CONTINUE;
            --negativno stanje, ostaviti staru cijenu!
            nOsnovnaCijena := nC;
            nC2 := nC;
         ELSE  -- na stanju nema artikla, koristi se stara cijena u zahtjevu za nivelaciju
            nOsnovnaCijena := nC;
            nStanje := 0; -- ako je stanje negativno, napraviti nultu nivelaciju
         END IF;
         SELECT * FROM {{ item_prodavnica }}.roba
            WHERE id=cIdRoba
            INTO rec_roba;

         -- IF rec_roba.idtarifa IS NULL THEN
         -- bilo je slucajeva da se ovo desi (idtarifa u roba nedefinisana - uzrok mi je nepoznat)
         -- zato cemo koristiti idtarifa iz 72-ke
         -- END IF;

         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nOsnovnaCijena, nC2, rec_roba.naz, cIdTarifa, rec_roba.jmj;
         nCount := nCount + 1;
      END LOOP;

      RETURN nCount;
END;
$$;



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
      rec_roba RECORD;
      nRows integer;
      cOpis varchar;
      nOsnovnaCijena numeric;
      cMsg varchar;
      cIdTarifa varchar;
BEGIN

      -- pos dokument '72'
      EXECUTE 'select idpos,idvd,brdok,datum,dat_do from {{ item_prodavnica }}.pos where dok_id = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_do;
      RAISE INFO 'nivelacija_end_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_do;

      nRows :=  {{ item_prodavnica }}.pos_broj_stavki(uuidPos);
      cOpis := 'ROWS:[' || btrim(to_char(nRows, '9999')) || ']';

      -- pos dokument nivelacije '29' sa ref_2 na dok_id ne smije postojati
      EXECUTE 'select dok_id from {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND ref_2=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;

      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_end dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := current_date;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);
      insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,ref,opis) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos,cOpis)
          RETURNING dok_id into uuid2;

      -- referenca (2) na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos set ref_2=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      nCount := 0;
      -- prolazak kroz stavke dokumenta '72'
      FOR nRbr, cIdRoba, nC, nC2, cIdTarifa IN SELECT rbr,idRoba,cijena,ncijena,idtarifa from {{ item_prodavnica }}.pos_items WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- trenutno aktuelna osnovna cijena je akcijska
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba);
         IF nStanje > 0 THEN -- osnovna cijena za artikal u pos
            nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal(cIdRoba);
            IF nOsnovnaCijena <> nC2 THEN
               cMsg := format('%s : nova cijena nC=%s, nC2=%s u dokumentu i aktuelna osnovna cijena %s se razlikuju! NIV-NA-NIV', cIdRoba, nC, nC2, nOsnovnaCijena);
               PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_END', cMsg);
               nC := nOsnovnaCijena; -- napraviti nivelaciju bez efekta; npr nC=8, nC2=6, nOsnovnaCijena=7 =>   nOsnovnaCijena=7, nC=7
               RAISE INFO '%', cMsg;
            END IF;
         ELSIF nStanje < 0 THEN
             cMsg := format('%s: stanje negativno %s !? stara cijena %s ostaje na snazi', cIdRoba, nStanje, nC);
             PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_72_ZNIV_END_STANJE', cMsg);
             --CONTINUE;
             --negativno stanje, ostaviti staru cijenu!
             nOsnovnaCijena := nC;
             -- nC := nC;
         ELSE  -- na stanju nema artikla, koristi se nova cijena u zahtjevu za nivelaciju
            nOsnovnaCijena := nC2;
         END IF;

         SELECT * FROM {{ item_prodavnica }}.roba
            WHERE id=cIdRoba
            INTO rec_roba;

         EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nOsnovnaCijena, nC, rec_roba.naz, cIdTarifa, rec_roba.jmj;
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



CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() RETURNS integer
       LANGUAGE plpgsql
       AS $$

DECLARE
       uuid72 uuid;
       nCount integer;
BEGIN
     nCount := 0;
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuid72 IN SELECT dok_id FROM {{ item_prodavnica }}.pos
          WHERE idvd='72' AND ref IS NULL AND dat_od<=current_date -- tekuci datum je jednak ili veci od dat_od
          ORDER BY obradjeno
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
            nCount := nCount + 1;
     END LOOP;

     RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_end() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuid72 uuid;
       nCount integer;
BEGIN
     nCount := 0;
     -- ref_2 nije popunjen => zavrsna nivelacija nije napravljena, a planirana je za danas
     FOR uuid72 IN SELECT dok_id FROM {{ item_prodavnica }}.pos
          WHERE idvd='72' AND ( ref_2 IS NULL ) AND ( dat_do IS NOT NULL ) AND dat_do<current_date -- dat_do=15.05 => 16.05 ujutro end nivelacija
          ORDER BY obradjeno
     LOOP
          RAISE INFO 'nivelacija_end %', uuid72;

          -- storno 79
          PERFORM {{ item_prodavnica }}.pos_artikli_prekid_popust_zbog_72_gen_79_storno(current_date, uuid72);
          PERFORM {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_storno(current_date, uuid72);

          PERFORM {{ item_prodavnica }}.nivelacija_end_create( uuid72 );

          -- + 79 po novim cijenama
          PERFORM {{ item_prodavnica }}.pos_artikli_vratiti_popust_gen_79(current_date, uuid72);
          -- + 99 po novim cijenama
          PERFORM {{ item_prodavnica }}.pos_artikli_zbog_72_gen_99_plus(current_date, uuid72);
          nCount := nCount + 1;
     END LOOP;

     RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_nivelacija_29_ref_dokument( dDatum date, cBrDok varchar ) RETURNS varchar
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuid29 uuid;
       dDatum72 date;
       cBrDok72 varchar;
BEGIN

   SELECT dok_id FROM {{ item_prodavnica }}.pos WHERE datum=dDatum AND idvd='29' AND brdok=cBrDok
       INTO uuid29;

   -- datum i broj 72-ke
   SELECT datum, brdok FROM {{ item_prodavnica }}.pos WHERE ref=uuid29
       INTO dDatum72, cBrDok72;
   
   IF cBrDok72 IS NULL THEN
      SELECT datum, brdok FROM {{ item_prodavnica }}.pos WHERE ref_2=uuid29
       INTO dDatum72, cBrDok72;
      
      IF cBrDok IS NULL THEN
         RETURN 'ERR_NO_REF' ;
      ELSE
         RETURN 'ref_2: ' || dDatum72 || '/72-' || cBrDok72;
      END IF;
   ELSE
      RETURN 'ref  : ' || dDatum72 || '/72-' || cBrDok72;
   END IF;

END;
$$;