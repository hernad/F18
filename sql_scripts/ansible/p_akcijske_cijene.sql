CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
       uuidPos uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT uuid FROM {{ item_prodavnica }}.pos_doks
          WHERE idvd='72' AND ref IS NULL AND dat_od = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM {{ item_prodavnica }}.nivelacija_start_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.nivelacija_start_create(uuidPos uuid) RETURNS void
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
BEGIN
      -- pos dokument '72' sa ovim dok_id-om
      EXECUTE 'select idpos,idvd,brdok,datum,dat_od from {{ item_prodavnica }}.pos_doks where dok_id = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_od;
      RAISE INFO 'nivelacija_start_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_od;

      -- pos dokument nivelacije '29' kome je referenca ovaj dok_id ne smije postojati
      EXECUTE 'select dok_id from {{ item_prodavnica }}.pos_doks WHERE idpos=$1 AND idvd=$2 AND ref=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;
      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_start dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_od;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);
      insert into {{ item_prodavnica }}.pos_doks(idPos,idVd,brDok,datum,dat_od,ref) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos)
          RETURNING uuid into uuid2;

      -- referenca na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos_doks set ref=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from {{ item_prodavnica }}.pos_pos WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- aktuelna osnovna cijena;
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal_za_cijenu(cIdRoba, nC, 0.00);
         EXECUTE 'insert into {{ item_prodavnica }}.pos_pos(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nC, nC2;
      END LOOP;

      RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.nivelacija_end_create(uuidPos uuid) RETURNS void
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
BEGIN

      -- pos dokument '72'
      EXECUTE 'select idpos,idvd,brdok,datum, dat_od from {{ item_prodavnica }}.pos_doks where dok_id = $1'
         USING uuidPos
         INTO cIdPos, cIdVd, cBrDok, dDatum, dDat_do;
      RAISE INFO 'nivelacija_end_create %-%-%-% ; dat_od: %', cIdPos, cIdvd, cBrDok, dDatum, dDat_do;

      -- pos dokument nivelacije '29' sa ref_2 na dok_id ne smije postojati
      EXECUTE 'select uuid from {{ item_prodavnica }}.pos_doks WHERE idpos=$1 AND idvd=$2 AND ref_2=$3'
          USING cIdPos, '29', uuidPos
          INTO uuid2;

      IF uuid2 IS NOT NULL THEN
          RAISE EXCEPTION 'ERROR nivelacija_end dokument vec postoji: % % % %', cIdPos, '29', cBrDok, dDatum;
      END IF;

      dDatumNew := dDat_do;
      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatumNew);

      insert into {{ item_prodavnica }}.pos_doks(idPos,idVd,brDok,datum,dat_od,ref) values(cIdPos,'29',cBrDokNew,dDatumNew,dDatumNew,uuidPos)
          RETURNING uuid into uuid2;

      -- referenca (2) na '29' unutar dokumenta idvd '72'
      EXECUTE 'update {{ item_prodavnica }}.pos_doks set ref_2=$2 WHERE dok_id=$1'
         USING uuidPos, uuid2;

      FOR nRbr, cIdRoba, nC, nC2 IN SELECT rbr,idRoba,cijena,ncijena from {{ item_prodavnica }}.pos_pos WHERE idpos=cIdPos AND idvd=cIdVd AND brdok=cBrDok AND datum=dDatum
      LOOP
         -- trenutno aktuelna osnovna cijena je akcijkska
         nStanje := {{ item_prodavnica }}.pos_dostupno_artikal_za_cijenu(cIdRoba, nC2, 0);
         EXECUTE 'insert into {{ item_prodavnica }}.pos_pos(idPos,idVd,brDok,datum,rbr,idRoba,kolicina,cijena,ncijena) values($1,$2,$3,$4,$5,$6,$7,$8,$9)'
             using cIdPos, '29', cBrDokNew, dDatumNew, nRbr, cIdRoba, nStanje, nC2, nC;
      END LOOP;

      RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start() RETURNS void
       LANGUAGE plpgsql
       AS $$

DECLARE
       uuidPos uuid;
BEGIN
     -- ref nije popunjen => startna nivelacija nije napravljena, a planirana je za danas
     FOR uuidPos IN SELECT dok_id FROM {{ item_prodavnica }}.pos_doks
          WHERE idvd='72' AND ref IS NULL AND dat_od = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM {{ item_prodavnica }}.nivelacija_start_create( uuidPos );
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
     FOR uuidPos IN SELECT dok_id FROM {{ item_prodavnica }}.pos_doks
          WHERE idvd='72' AND ref_2 IS NULL AND dat_do = current_date
     LOOP
            RAISE INFO 'pos_doks %', uuidPos;
            PERFORM {{ item_prodavnica }}.nivelacija_end_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$;
