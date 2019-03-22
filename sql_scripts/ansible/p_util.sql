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

    SELECT brdok from {{ item_prodavnica }}.pos_doks where idvd=cIdVd and datum=dDatum order by brdok desc limit 1
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
   idPos varchar DEFAULT '15';
   nStanje numeric;
BEGIN
   EXECUTE 'SELECT kol_ulaz-kol_izlaz as stanje FROM p' || idPos || '.pos_stanje' ||
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

BEGIN

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

     IF lPreuzimaSe THEN
        cOpis := 'PRIJEM: ' || cIdRadnik;
     ELSE
        cOpis := 'ODBIJENO: ' || cIdRadnik;
     END IF;


     INSERT INTO {{ item_prodavnica }}.pos(ref, idpos, idvd, brdok, datum, brfaktp, opis, dat_od, dat_do)
         VALUES(rec_dok.dok_id, rec_dok.idpos, '22', rec_dok.brdok, rec_dok.datum, rec_dok.brfaktp, cOpis, rec_dok.dat_od, rec_dok.dat_do);

     IF lPreuzimaSe THEN
        -- ako se roba preuzima stavke se pune
        FOR rec IN
            SELECT * from {{ item_prodavnica }}.pos_items
            WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum
        LOOP
            INSERT INTO {{ item_prodavnica }}.pos_items(idpos, idvd, brdok, datum, rbr, kolicina, idroba, idtarifa, cijena, ncijena, kol2, robanaz, jmj)
              VALUES(rec.idpos, '22', rec.brdok, rec.datum, rec.rbr, rec.kolicina, rec.idroba, rec.idtarifa, rec.cijena, rec.ncijena, rec.kol2, rec.robanaz, rec.jmj);

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
