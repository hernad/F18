
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.logiraj( cUser varchar, cPrefix varchar, cMsg text) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN

   insert into public.log(user_code, msg) values(cUser, cPrefix || ': ' || cMsg);
   RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM {{ item_prodavnica }}.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$$;

ALTER FUNCTION {{ item_prodavnica }}.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION {{ item_prodavnica }}.fetchmetrictext TO xtrole;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM {{ item_prodavnica }}.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM {{ item_prodavnica }}.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE {{ item_prodavnica }}.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO {{ item_prodavnica }}.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$$;


ALTER FUNCTION {{ item_prodavnica }}.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION {{ item_prodavnica }}.setmetric TO xtrole;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos varchar, cIdVd varchar, dDatum date) RETURNS varchar
  LANGUAGE plpgsql
  AS $$
DECLARE
   cBrDok varchar;
BEGIN
    -- left(brdok,1)=' ' => ignorisati KALK dokumente kao npr 0000002, 02040201
    SELECT brdok from {{ item_prodavnica }}.pos where left(brdok,1)=' ' and idvd=cIdVd and datum=dDatum order by brdok desc limit 1
           INTO cBrDok;
    IF cBrdok IS NULL THEN
        cBrDok := to_char(1, '99999999');
    ELSE
        cBrDok := to_char( to_number(cBrDok, '09999999') + 1, '99999999');
    END IF;
    RETURN lpad(btrim(cBrDok), 8, ' ');
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_dostupno_artikal_za_cijenu(cIdRoba varchar, nCijena numeric, nNCijena numeric) RETURNS numeric
       LANGUAGE plpgsql
       AS $$

DECLARE
   nStanje numeric;
BEGIN
   EXECUTE 'SELECT kol_ulaz-kol_izlaz as stanje FROM {{ item_prodavnica }}.pos_stanje' ||
           ' WHERE rtrim(idroba)=$1  AND cijena=$2 AND ncijena=$3 AND current_date>=dat_od AND current_date<=dat_do' ||
           ' AND kol_ulaz - kol_izlaz <> 0'
           USING trim(cIdroba), nCijena, nNCijena
           INTO nStanje;

   IF nStanje IS NOT NULL THEN
         RETURN nStanje;
   ELSE
         RETURN 0;
   END IF;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba varchar) RETURNS numeric
       LANGUAGE plpgsql
       AS $$
DECLARE
   nStanje numeric;
BEGIN
   SELECT sum(kol_ulaz-kol_izlaz) as stanje FROM  {{ item_prodavnica }}.pos_stanje
        WHERE trim(idroba)=Trim( cIdRoba )
        AND kol_ulaz-kol_izlaz <> 0
        GROUP BY idroba
        INTO nStanje;
   RETURN coalesce(nStanje, 0);
END;
$$;

-- select * from p2.pos_items i left join p2.pos d
--  on i.idpos=d.idpos and i.idvd=d.idvd and i.brdok=d.brdok and i.datum=d.datum
--  where d.obradjeno > (select max(obradjeno) from p2.pos where idvd='02');

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_kalo(cIdRoba varchar) RETURNS numeric
       LANGUAGE plpgsql
       AS $$

DECLARE
   nStartTime timestamp with time zone;
   nKalo numeric;
BEGIN

   select max(obradjeno) from {{ item_prodavnica }}.pos where idvd='02'
     INTO nStartTime;

   SELECT sum(kolicina) from {{ item_prodavnica }}.pos_items i left join {{ item_prodavnica }}.pos d
     on i.idpos=d.idpos and i.idvd=d.idvd and i.brdok=d.brdok and i.datum=d.datum
    where idroba=cIdRoba AND d.idvd='99' AND d.obradjeno > nStartTime
    INTO nKalo;

   RETURN coalesce(nKalo, 0);
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_dostupno_artikal_sa_kalo(cIdRoba varchar) RETURNS numeric
       LANGUAGE plpgsql
       AS $$
DECLARE
   nStanje numeric;
   nKalo numeric;
BEGIN
   nStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba);
   nKalo := {{ item_prodavnica }}.pos_kalo(cIdRoba);
   RETURN coalesce(nStanje + nKalo, 0);
END;
$$;

-- harbour FUNCTION pos_set_broj_fiskalnog_racuna( cIdPos, cIdVd, dDatDok, cBrDok, nBrojRacuna )
-- TEST:
-- insert into {{ item_prodavnica }}.pos_doks(idpos, idvd, brdok, datum) values('1 ', '42', 'XX', current_date );

-- SET
-- select {{ item_prodavnica }}.broj_fiskalnog_racuna( '1 ', '42', current_date, lpad('2',8), 102 );
-- GET
-- select {{ item_prodavnica }}.broj_fiskalnog_racuna( '1 ', '42', current_date, 'XX', NULL );

-- select * from {{ item_prodavnica }}.pos_doks;
-- select * from {{ item_prodavnica }}.pos_fisk_doks;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.broj_fiskalnog_racuna( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, nBrojRacuna integer) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   posUUID uuid;
   fiskUUID uuid;
BEGIN

SELECT dok_id FROM {{ item_prodavnica }}.pos
   WHERE idpos=cIdPos AND idvd=cIdVd AND datum=dDatDok AND brDok=cBrDok
   INTO posUUID;

IF posUUID IS NULL THEN
     RAISE INFO 'pos % % % % ne postoji ?!', cIdPos, cIdVd, dDatDok, cBrDok;
     RETURN 0;
END IF;

-- get broj racuna
IF nBrojRacuna IS NULL THEN
    SELECT broj_rn FROM {{ item_prodavnica }}.pos_fisk_doks where ref_pos_dok=posUUID
      INTO nBrojRacuna;
    RETURN COALESCE( nBrojRacuna, 0);
END IF;

IF ( nBrojRacuna = -1 ) THEN -- insert null vrijednost za broj fiskalnog racuna
    nBrojRacuna := NULL;
END IF;

SELECT dok_id FROM {{ item_prodavnica }}.pos_fisk_doks
   WHERE ref_pos_dok = posUUID
   INTO fiskUUID;

IF fiskUUID IS NULL THEN
    INSERT INTO {{ item_prodavnica }}.pos_fisk_doks(ref_pos_dok, broj_rn) VALUES(posUUID, nBrojRacuna);
ELSE
    UPDATE {{ item_prodavnica }}.pos_fisk_doks set broj_rn=nBrojRacuna, obradjeno=now() WHERE ref_pos_dok=posUUID;
END IF;

RETURN COALESCE( nBrojRacuna, 0);

END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fisk_dok_id( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS text
 LANGUAGE plpgsql
 AS $$
DECLARE
   posUUID uuid;
BEGIN

SELECT pos_fisk_doks.dok_id FROM {{ item_prodavnica }}.pos
   LEFT JOIN {{ item_prodavnica }}.pos_fisk_doks
   ON {{ item_prodavnica }}.pos_fisk_doks.ref_pos_dok = {{ item_prodavnica }}.pos.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO posUUID;

IF posUUID IS NULL THEN
     RAISE INFO 'pos % % % % ne postoji ?!', cIdPos, cIdVd, dDatDok, cBrDok;
     RETURN '';
END IF;

RETURN posUUID::text;

END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_is_storno( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS boolean
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidStorno uuid;
BEGIN

SELECT pos_fisk_doks.ref_storno_fisk_dok FROM {{ item_prodavnica }}.pos
   LEFT JOIN {{ item_prodavnica }}.pos_fisk_doks
   ON {{ item_prodavnica }}.pos_fisk_doks.ref_pos_dok = {{ item_prodavnica }}.pos.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO uuidStorno;

IF uuidStorno IS NULL THEN
     RETURN FALSE;
END IF;

RETURN TRUE;

END;
$$;


-- SELECT {{ item_prodavnica }}.pos_storno_broj_rn( '1 ','42','2019-03-15','       8' );  => 101

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_storno_broj_rn( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   iStornoBrojRn integer;
BEGIN

SELECT fisk2.broj_rn FROM {{ item_prodavnica }}.pos
   LEFT JOIN {{ item_prodavnica }}.pos_fisk_doks as fisk1
   ON fisk1.ref_pos_dok = {{ item_prodavnica }}.pos.dok_id
   LEFT JOIN {{ item_prodavnica }}.pos_fisk_doks as fisk2
   ON fisk1.ref_storno_fisk_dok = fisk2.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO iStornoBrojRn;

IF iStornoBrojRn IS NULL THEN
     RETURN 0;
END IF;

RETURN iStornoBrojRn;

END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fisk_broj_rn_by_storno_ref( uuidFiskStorniran text ) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   nBrojRacuna integer;
   nCount integer;
BEGIN

SELECT count(*) FROM {{ item_prodavnica }}.pos_fisk_doks
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO nCount;

IF (nCount = 0) THEN
      RETURN 0; -- uopste nema pos_fisk_doks zapisa
END IF;

SELECT broj_rn FROM {{ item_prodavnica }}.pos_fisk_doks
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO nBrojRacuna;

RETURN COALESCE(nBrojRacuna, -1); -- pos_fisk_doks zapis broj_rn moze biti NULL

END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.set_ref_storno_fisk_dok( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, uuidFiskStorniran text ) RETURNS void
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidFiskNovi uuid;
BEGIN

  uuidFiskNovi := {{ item_prodavnica }}.fisk_dok_id( cIdPos, cIdVd, dDatDok, cBrDok);
  UPDATE {{ item_prodavnica }}.pos_fisk_doks SET ref_storno_fisk_dok = uuidFiskStorniran::uuid
      WHERE dok_id = uuidFiskNovi;

END;
$$;


-- select pos_dok_id('1 ','42','       1', '2018-01-09');
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_dok_id(cIdPos varchar, cIdVD varchar, cBrDok varchar, dDatum date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
     USING cIdPos, cIdVd, cBrDok, dDatum
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'pos_doks %-%-% od % NE postoji?!', cIdPos, cIdVd, cBrDok, dDatum;
   END IF;

   RETURN dok_id;
END;
$$;



-- =========================== 21, 22 ===============================================================================


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_postoji_dokument_by_brfaktp( cIdVd varchar, cBrFaktP varchar) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  rec_dok RECORD;
BEGIN
   select * from {{ item_prodavnica }}.pos where brfaktp=cBrFaktP and idvd=cIdVd
     INTO rec_dok;

   IF rec_dok.dok_id is null THEN
       RAISE INFO 'NE POSTOJI idvd % sa brfaktp: % ?', cIdVd, cBrFaktP;
       RETURN False;
   END IF;

   RETURN True;
END;
$$;



-- p2.pos_dostupna_osnovna_cijena_za_artikal( 'K12330') => 0 ako nema na stanju pos; odnosno cijenu koja je trenutno vazeca u pos

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba varchar) RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
   nCijenaMem numeric;
   nCijenaSif numeric;
   dDatOd date;
   dDatDo date;
BEGIN

   -- ako robe ima na stanju, ako se radi o stavkama bez popusta (ncijena=0)
   -- LIMIT 1 jer se ocekuje da ovih zapisa moze biti samo 1
   -- ista roba moze biti na stanju samo po jednoj osnovnoj cijeni

   -- order by id DESC obezbjedjuje da u slucaju nekonzistentnog stanja u kome postoji
   -- vise osnovnih cijena sa stanjem > 0, da se uzme ona najmladja - najkasnije napravljena stavka iz pos_stanje
   SELECT cijena dat_od, dat_do FROM {{ item_prodavnica }}.pos_stanje
      WHERE rtrim(idroba)=rtrim(cIdRoba)
      AND kol_ulaz-kol_izlaz > 0
      AND dat_od<=current_date AND dat_do>=current_date
      AND ncijena=0
      ORDER BY id DESC
      LIMIT 1
      INTO nCijenaMem, dDatOd, dDatDo;

    IF nCijenaMem IS NULL THEN

      -- ako ima stanje minus, gledati tu cijenu iz pos_stanje
      SELECT cijena dat_od, dat_do FROM {{ item_prodavnica }}.pos_stanje
        WHERE rtrim(idroba)=rtrim(cIdRoba)
        AND kol_ulaz-kol_izlaz < 0
        AND dat_od<=current_date AND dat_do>=current_date
        AND ncijena=0
        ORDER BY id DESC
        LIMIT 1
        INTO nCijenaMem, dDatOd, dDatDo;

      -- ovo je stvaralo bug - kada je stanje 0 i posalje se nivelacija na stanje 0
      -- SELECT cijena from {{ item_prodavnica }}.pos_items  
      --   LEFT JOIN {{ item_prodavnica }}.pos on pos.dok_id=pos_items.dok_id
      --   WHERE pos_items.idvd='42' and rtrim(idroba)=rtrim(cIdRoba)
      --   ORDER BY obradjeno DESC
      --   LIMIT 1
      --   INTO nCijenaMem;

      IF nCijenaMem IS NULL THEN -- nema transakcija sa stanjem > 0 u pos_stanje, ili stanjem < 0 pos_stanje, tada sifarnik citati
        SELECT mpc from {{ item_prodavnica }}.roba WHERE rtrim(id)=rtrim(cIdRoba)
           INTO nCijenaSif;
        IF nCijenaSif IS NULL THEN -- cijene nema ni u p2.pos_stanje ni u p2.roba
           RETURN 0;
        ELSE
           RETURN nCijenaSif;
        END IF;
      END IF;

    END IF;

    RAISE INFO 'Dostupno za % % % %', cIdRoba, nCijenaMem, dDatOd, dDatDo;
    RETURN nCijenaMem;

END;
$$;

-- 1) radnik 00010 odbija prijem:
-- select p2.pos_21_to_22( '20567431', '0010', false );
-- generise se samo p2.pos stavka 22, sa opisom: ODBIJENO: 0010

-- 2) radnik 00010 potvrdjuje prijem:
-- select p2.pos_21_to_22( '20567431', '0010', true );
-- generise se samo p2.pos stavka 22, sa opisom: PRIJEM: 0010

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_21_to_22( cBrFaktP varchar, cIdRadnik varchar, lPreuzimaSe boolean) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
    rec_dok RECORD;
    rec RECORD;
    cOpis varchar;
    nPosCijena numeric;
    dDatum date;
    lPovratKalo boolean;
    cBrDokKalo varchar;
BEGIN
     dDatum := current_date;
     select * from {{ item_prodavnica }}.pos where brfaktp=cBrFaktP and idvd='21'
        INTO rec_dok;

     IF rec_dok.dok_id is NULL  THEN
         RAISE INFO 'NE POSTOJI 21 sa brfaktp: % ?', cBrFaktP;
         RETURN -1;
     END IF;

     IF {{ item_prodavnica }}.pos_postoji_dokument_by_brfaktp( '22', cBrFaktP )  THEN
         RAISE INFO 'VEC POSTOJI 22 sa brfaktp: % ?', cBrFaktP;
         RETURN -2;
     END IF;

     cOpis := btrim( coalesce( rec_dok.opis, '' ) );
     IF cOpis = '780' THEN -- povratnica neispravne robe
       lPovratKalo := True;
       cOpis := cOpis || ' - POVRAT ROBE U MAGACIN ';
     ELSE
       lPovratKalo := False;
     END IF;
     IF lPreuzimaSe THEN
        cOpis := cOpis || ': PRIJEM RADNIK: ' || cIdRadnik;
     ELSE
        cOpis := cOpis || ': ODBIJENO RADNIK: ' || cIdRadnik;
     END IF;

     INSERT INTO {{ item_prodavnica }}.pos(ref, idpos, idvd, brdok, datum, brfaktp, opis, dat_od, dat_do, idpartner)
         VALUES(rec_dok.dok_id, rec_dok.idpos, '22', rec_dok.brdok, dDatum, rec_dok.brfaktp, cOpis, rec_dok.dat_od, rec_dok.dat_do, rec_dok.idpartner);

      IF lPovratKalo THEN -- radi se o povratu neispravne robe u magacin
        cBrDokKalo := {{ item_prodavnica }}.pos_novi_broj_dokumenta(rec_dok.idpos, '99', dDatum);
        INSERT INTO {{ item_prodavnica }}.pos(ref, idpos, idvd, brdok, datum, brfaktp, opis, dat_od, dat_do, idpartner)
                VALUES(rec_dok.dok_id, rec_dok.idpos, '99', cBrDokKalo, dDatum, rec_dok.brfaktp, cOpis, rec_dok.dat_od, rec_dok.dat_do, rec_dok.idpartner);
      END IF;

     IF lPreuzimaSe THEN
        -- ako se roba preuzima stavke se pune
        FOR rec IN
            SELECT * from {{ item_prodavnica }}.pos_items
            WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum
        LOOP

            nPosCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( rec.idroba );
            IF (nPosCijena = 0) THEN  -- ove robe nema na stanju, prihvati cijenu koju je donio dokument 21 iz knjigovodstva
               nPosCijena := rec.cijena;
            END IF;
            INSERT INTO {{ item_prodavnica }}.pos_items(idpos, idvd, brdok, datum, rbr, kolicina, idroba, idtarifa, cijena, ncijena, kol2, robanaz, jmj)
              VALUES(rec.idpos, '22', rec.brdok, dDatum, rec.rbr, rec.kolicina, rec.idroba, rec.idtarifa, nPosCijena, 0, rec.kol2, rec.robanaz, rec.jmj);

            IF lPovratKalo THEN -- stavke povrata neispravne robe u magacin
              INSERT INTO {{ item_prodavnica }}.pos_items(idpos, idvd, brdok, datum, rbr, kolicina, idroba, idtarifa, cijena, ncijena, kol2, robanaz, jmj)
                  VALUES(rec_dok.idpos, '99', cBrDokKalo, dDatum, rec.rbr, rec.kolicina, rec.idroba, rec.idtarifa, nPosCijena, 0, rec.kol2, rec.robanaz, rec.jmj);
            END IF;
        END LOOP;
     ELSE
        --ako se ne prihvata items se ne pune
        RAISE INFO 'Prijem otkazan % !', cBrFaktP;
        RETURN 10;
     END IF;

     RETURN 0;
END;
$$;



-- servisna funkcija prvenstveno
-- select p2.pos_delete_by_idvd_brfakt( '22', '20567431');

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_delete_by_idvd_brfakt( cIdVd varchar, cBrFaktP varchar) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
    rec_dok RECORD;
    rec RECORD;
BEGIN

     IF btrim(cBrFaktP) = '' THEN
        RETURN -100;
     END IF;

     IF NOT {{ item_prodavnica }}.pos_postoji_dokument_by_brfaktp( cIdVd, cBrFaktP )  THEN
         RAISE INFO 'NE POSTOJI % sa brfaktp: % ?', cIdVd, cBrFaktP;
         RETURN -1;
     END IF;

     SELECT * from {{ item_prodavnica }}.pos where idvd=cIdVd and brfaktp=cBrFaktP
        INTO rec_dok;

     DELETE from {{ item_prodavnica }}.pos WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum;
     DELETE from {{ item_prodavnica }}.pos_items WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum;

     RETURN 0;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.run_cron() RETURNS void
  LANGUAGE plpgsql
  AS $$
DECLARE
   nCount99 integer;
   nCount79 integer;
   nNivStart integer;
   nNivEnd integer;
   nPopustNaknadno integer;

BEGIN
   -- PERFORM {{ item_prodavnica }}.setmetric('run_cron_time', now()::text);

  SELECT {{ item_prodavnica }}.pos_artikli_istekao_popust_gen_99(current_date)
      INTO nCount99;

  SELECT  {{ item_prodavnica }}.pos_artikli_istekao_popust_gen_79_storno(current_date)
      INTO nCount79;

  -- ako imamo dva zahtjeva za nivelaciju za isti artikal na isti dan od kojih jedna zavrsava, 
  -- a druga pocinje (sto je prakticno nastavak akcije), prvo treba zavrsiti staru akciju, pa onda poceti novu
  SELECT {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_end()
      INTO nNivEnd;

  SELECT {{ item_prodavnica }}.cron_akcijske_cijene_nivelacija_start()
       INTO nNivStart;


   SELECT {{ item_prodavnica }}.pos_popust_naknadna_obrada()
      INTO nPopustNaknadno;

   RAISE INFO 'run_cron gen_99 %, gen_79 storno %, niv_start: %, niv_end: %, popust_naknadno %', nCount99, nCount79, nNivStart, nNivEnd, nPopustNaknadno;
   RETURN;
END;
$$;

DROP FUNCTION IF EXISTS {{ item_prodavnica }}.pos_21_neobradjeni_dokumenti();

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_21_neobradjeni_dokumenti() RETURNS TABLE(brdok varchar, datum date, brfaktp varchar, storno boolean, opis varchar )
LANGUAGE plpgsql
AS $$
DECLARE
  cIdFirma varchar;
  nRet integer;
BEGIN

    RETURN QUERY select p21.brdok::varchar, p21.datum::date, p21.brfaktp::varchar, (items.kolicina<0) as storno, p21.opis from {{ item_prodavnica }}.pos p21
        left join {{ item_prodavnica }}.pos p22
        on p22.ref=p21.dok_id
        left join {{ item_prodavnica }}.pos_items items
        on p21.dok_id = items.dok_id and items.rbr = 1
        where p21.idvd='21' and p22.brfaktp IS null;

END;
$$;



-- svi artikli, period '2019-05-26' - '2019-12-31'
-- select * from p2.pos_artikal_stanje( '', '2019-05-26', '2019-12-31' );

-- artikli koji pocinju sa '0'
-- select * from p2.pos_artikal_stanje( '0', '2019-05-26', '2019-12-31' );

-- jedan artikal
-- select * from p2.pos_artikal_stanje( '0000000001', '2019-05-26', '2019-12-31' );

-- DROP FUNCTION p2.pos_artikal_stanje

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_artikal_stanje( cIdRoba varchar, dDatOD date, dDatDo date )
    RETURNS TABLE(idroba varchar, p_prijem numeric, p_povrat numeric, p_ulaz_ostalo numeric,
                  p_realizacija numeric, p_popust numeric, p_izlaz_ostalo numeric, p_kalo numeric,
                  p_realizacija_v numeric, p_popust_v numeric, p_vrijednost numeric,
                  prijem numeric, povrat numeric, ulaz_ostalo numeric,
                  realizacija numeric, popust numeric, izlaz_ostalo numeric, kalo numeric,
                  realizacija_v numeric, popust_v numeric, vrijednost numeric)
LANGUAGE plpgsql
AS $$
DECLARE

  nTPrijem numeric;
  nTPovrat numeric;
  nTUlazOstalo numeric;
  nTrealizacija numeric;
  nTPopust numeric;
  nTIzlazOstalo numeric;
  nTKalo numeric;
  nTRealizacijaV numeric;
  nTPopustV numeric;
  nTVrijednost numeric;

  nPPrijem numeric;
  nPPovrat numeric;
  nPUlazOstalo numeric;
  nPrealizacija numeric;
  nPPopust numeric;
  nPIzlazOstalo numeric;
  nPKalo numeric;
  nPRealizacijaV numeric;
  nPPopustV numeric;
  nPVrijednost numeric;

  nPrijem numeric;
  nPovrat numeric;
  nUlazOstalo numeric;
  nrealizacija numeric;
  nPopust numeric;
  nIzlazOstalo numeric;
  nKalo numeric;
  nRealizacijaV numeric;
  nPopustV numeric;
  nVrijednost numeric;

  rec_roba RECORD;
  rec RECORD;
  nCnt integer;
  lInit boolean;
BEGIN


  FOR rec_roba IN
    SELECT * FROM {{ item_prodavnica }}.roba WHERE id like trim( cIdRoba ) || '%'
      ORDER BY id
  LOOP
    nCnt := 0;
    nPPrijem := 0;
    nPPovrat := 0;
    nPUlazOstalo := 0;
    nPrealizacija := 0;
    nPPopust := 0;
    nPIzlazOstalo := 0;
    nPKalo := 0;
    nPRealizacijaV := 0;
    nPPopustV := 0;
    nPVrijednost := 0;

    nPrijem := 0;
    nPovrat := 0;
    nUlazOstalo := 0;
    nrealizacija := 0;
    nPopust := 0;
    nIzlazOstalo := 0;
    nKalo := 0;
    nRealizacijaV := 0;
    nPopustV := 0;
    nVrijednost := 0;

    FOR rec IN
      SELECT *, date(pos.obradjeno) as datum_obrade, to_char(pos.obradjeno, 'HH24:MI') as vrij_obrade, pos.dat_od, pos.dat_do
        FROM {{ item_prodavnica }}.pos_items
         LEFT JOIN  {{ item_prodavnica }}.pos
         ON pos_items.idpos=pos.idpos and pos_items.idvd=pos.idvd and pos_items.brdok=pos.brdok and pos_items.datum=pos.datum
         WHERE pos.idvd <> '21'
         AND rtrim(pos_items.idroba)=Trim( rec_roba.id )
         ORDER BY pos_items.idroba, pos.datum, pos.obradjeno, pos.idvd, pos.brdok
    LOOP
        nCnt := nCnt + 1;

        nTPrijem := 0;
        nTPovrat := 0;
        nTUlazOstalo := 0;
        nTrealizacija := 0;
        nTPopust := 0;
        nTIzlazOstalo := 0;
        nTKalo := 0;
        nTRealizacijaV := 0;
        nTPopustV := 0;
        nTVrijednost := 0;

        lInit := False;

        CASE
         WHEN rec.idvd = '02' THEN
            lInit := True;
            nTUlazOstalo := rec.kolicina;
            nTVrijednost := rec.kolicina * rec.cijena;

         WHEN rec.idvd IN ('22', '89') THEN
            If rec.kolicina < 0 AND trim(rec.opis) LIKE '780 %'  THEN -- povrat kalo
               nTPovrat := ABS( rec.kolicina );
            ELSE
               nTPrijem := rec.kolicina;
            END IF;
            nTVrijednost := rec.kolicina * rec.cijena;

         WHEN rec.idvd = '42' THEN
             nTrealizacija := rec.kolicina;
             IF rec.ncijena <> 0 THEN
                nTPopust := rec.kolicina;
                nTPopustV := rec.kolicina * (rec.cijena - rec.ncijena);
             END IF;
             nTRealizacijaV := rec.kolicina * rec.cijena;
             nTVrijednost := - rec.kolicina * rec.cijena;

         WHEN rec.idvd IN ('90','IP') THEN
            IF rec.kolicina - rec.kol2 > 0 THEN
                -- visak
                nTUlazOstalo := rec.kolicina - rec.kol2;
            ELSE
                nTIzlazOstalo := - (rec.kolicina - rec.kol2);
            END IF;
            nTVrijednost := nTUlazOstalo * rec.cijena - nTIzlazOstalo * rec.cijena;

         WHEN rec.idvd IN ('19', '29') THEN

            nTVrijednost := (rec.ncijena - rec.cijena) * rec.kolicina;

         WHEN rec.idvd = '99' THEN

            nTKalo := rec.kolicina;
            nTVrijednost := 0;

         WHEN rec.idvd = '80' THEN

            nTUlazOstalo := rec.kolicina;
            nTVrijednost := nTUlazOstalo * rec.cijena;

        ELSE
            nTVrijednost := 0;
        END CASE;

        IF rec.datum < dDatOd THEN
           IF lInit THEN
                nPPrijem := 0;
                nPPovrat := 0;
                nPUlazOstalo := 0;
                nPrealizacija := 0;
                nPPopust := 0;
                nPIzlazOstalo := 0;
                nPKalo := 0;
                nPRealizacijaV := 0;
                nPPopustV := 0;
                nPVrijednost := 0;
          END IF;
          nPPrijem := nPPrijem +nTPrijem;
          nPPovrat := nPPovrat +nTPovrat;
          nPUlazOstalo := nPUlazOstalo +nTUlazOstalo;
          nPrealizacija := nPrealizacija + nTrealizacija;
          nPPopust := nPPopust + nTPopust;
          nPIzlazOstalo := nPIzlazOstalo + nTIzlazOstalo;
          nPKalo := nPKalo + nTKalo;
          nPRealizacijaV := nPRealizacijaV + nTrealizacijaV;
          nPPopustV := nPPopustV + nTPopustV;
          nPVrijednost := nPVrijednost + nTVrijednost;

        ELSIF rec.datum >= dDatOd AND rec.datum <= dDatDo THEN

          -- razmatrani datumski period
          IF lInit THEN
               nPPrijem := 0;
               nPPovrat := 0;
               nPUlazOstalo := 0;
               nPrealizacija := 0;
               nPPopust := 0;
               nPIzlazOstalo := 0;
               nPKalo := 0;
               nPRealizacijaV := 0;
               nPPopustV := 0;
               nPVrijednost := 0;

               nPrijem := 0;
               nPovrat := 0;
               nUlazOstalo := 0;
               nrealizacija := 0;
               nPopust := 0;
               nIzlazOstalo := 0;
               nKalo := 0;
               nRealizacijaV := 0;
               nPopustV := 0;
               nVrijednost := 0;
          END IF;

          nPrijem := nPrijem + nTPrijem;
          nPovrat := nPovrat + nTPovrat;
          nUlazOstalo := nUlazOstalo + nTUlazOstalo;
          nRealizacija := nRealizacija + nTrealizacija;
          nPopust := nPopust + nTPopust;
          nIzlazOstalo := nIzlazOstalo + nTIzlazOstalo;
          nKalo := nKalo + nTKalo;
          nRealizacijaV := nRealizacijaV + nTRealizacijaV;
          nPopustV := nPopustV + nTPopustV;
          nVrijednost := nVrijednost + nTVrijednost;

        END IF;

    END LOOP;

    -- RAISE NOTICE '% %', rec_roba.id, nPVrijednost + nVrijednost;

    RETURN QUERY SELECT rec_roba.id::varchar,
                nPPrijem,
                nPPovrat,
                nPUlazOstalo,
                nPRealizacija,
                nPPopust,
                nPIzlazOstalo,
                nPKalo,
                nPRealizacijaV,
                nPPopustV,
                nPVrijednost,

                nPrijem,
                nPovrat,
                nUlazOstalo,
                nRealizacija,
                nPopust,
                nIzlazOstalo,
                nKalo,
                nRealizacijaV,
                nPopustV,
                nVrijednost;
  END LOOP;

END;
$$;


CREATE OR REPLACE FUNCTION public.prodavnica_nc( nProdavnica integer, cIdRoba varchar, dDatDo date )
    RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE

cPKonto varchar;
rec RECORD;
nNV numeric;
nKolicina numeric;
nLastUlazNC numeric;

BEGIN

SELECT id INTO cPKonto
       from public.koncij where prod=nProdavnica;

nNV := 0;
nKolicina := 0;
nLastUlazNC := 0;

FOR rec IN
   SELECT nc, kolicina, pu_i, gkolicin2 from kalk_kalk
          WHERE trim(idroba) = trim(cIdRoba) and pkonto = cPKonto and datdok <= dDatDo
LOOP

    CASE
        WHEN rec.pu_i = '1' THEN
           nNV := nNV +  rec.nc * rec.kolicina;
           nKolicina := nKolicina + rec.kolicina;
           nLastUlazNC := rec.nc;

        WHEN rec.pu_i = '5' THEN
          nNV := nNV - rec.nc * rec.kolicina;
          nKolicina := nKolicina - rec.kolicina;

        WHEN rec.pu_i = 'I' THEN
          nNV := nNV - rec.nc * rec.gkolicin2;
          nKolicina := nKolicina - rec.gkolicin2;
        ELSE
          nNV := nNV + 0;
     END CASE;
END LOOP;

IF nKolicina <> 0 THEN
   RETURN ROUND(nNV / nKolicina, 4);

ELSE
   IF round(nNV, 4) <> 0 THEN
      IF nLastUlazNC > 0 THEN -- kolicina 0, ali NV postoji - iskoristiti nc zadnjeg ulaza
         RETURN nLastUlazNC;
      ELSE
        RETURN -1.00;
      END IF;
   ELSE
      RETURN 0;
   END IF;
END IF;


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