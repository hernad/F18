CREATE OR REPLACE FUNCTION {{ item.name }}.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM {{ item.name }}.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$$;

ALTER FUNCTION {{ item.name }}.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION {{ item.name }}.fetchmetrictext TO xtrole;


CREATE OR REPLACE FUNCTION {{ item.name }}.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM {{ item.name }}.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM {{ item.name }}.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE {{ item.name }}.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO {{ item.name }}.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$$;


ALTER FUNCTION {{ item.name }}.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION {{ item.name }}.setmetric TO xtrole;


CREATE OR REPLACE FUNCTION {{ item.name }}.pos_novi_broj_dokumenta(cIdPos varchar, cIdVd varchar, dDatum date) RETURNS varchar
  LANGUAGE plpgsql
  AS $$

DECLARE
   cBrDok varchar;
BEGIN

    SELECT brdok from {{ item.name }}.pos_doks where idvd=cIdVd and datum=dDatum order by brdok desc limit 1
           INTO cBrDok;
    IF cBrdok IS NULL THEN
        cBrDok := to_char(1, '99999999');
    ELSE
        cBrDok := to_char( to_number(cBrDok, '09999999') + 1, '99999999');
    END IF;

    RETURN lpad(btrim(cBrDok), 8, ' ');

END;
$$;


CREATE OR REPLACE FUNCTION {{ item.name }}.pos_dostupno_artikal_za_cijenu(cIdRoba varchar, nCijena numeric, nNCijena numeric) RETURNS numeric
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
-- insert into {{ item.name }}.pos_doks(idpos, idvd, brdok, datum) values('1 ', '42', 'XX', current_date );

-- SET
-- select {{ item.name }}.broj_fiskalnog_racuna( '1 ', '42', current_date, lpad('2',8), 102 );
-- GET
-- select {{ item.name }}.broj_fiskalnog_racuna( '1 ', '42', current_date, 'XX', NULL );

-- select * from {{ item.name }}.pos_doks;
-- select * from {{ item.name }}.pos_fisk_doks;


CREATE OR REPLACE FUNCTION {{ item.name }}.broj_fiskalnog_racuna( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, nBrojRacuna integer) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   posUUID uuid;
   fiskUUID uuid;
BEGIN

SELECT dok_id FROM {{ item.name }}.pos
   WHERE idpos=cIdPos AND idvd=cIdVd AND datum=dDatDok AND brDok=cBrDok
   INTO posUUID;

IF posUUID IS NULL THEN
     RAISE INFO 'pos % % % % ne postoji ?!', cIdPos, cIdVd, dDatDok, cBrDok;
     RETURN 0;
END IF;

-- get broj racuna
IF nBrojRacuna IS NULL THEN
    SELECT broj_rn FROM {{ item.name }}.pos_fisk_doks where ref_pos_dok=posUUID
      INTO nBrojRacuna;
    RETURN COALESCE( nBrojRacuna, 0);
END IF;

IF ( nBrojRacuna = -1 ) THEN -- insert null vrijednost za broj fiskalnog racuna
    nBrojRacuna := NULL;
END IF;

SELECT dok_id FROM {{ item.name }}.pos_fisk_doks
   WHERE ref_pos_dok = posUUID
   INTO fiskUUID;

IF fiskUUID IS NULL THEN
    INSERT INTO {{ item.name }}.pos_fisk_doks(ref_pos_dok, broj_rn) VALUES(posUUID, nBrojRacuna);
ELSE
    UPDATE {{ item.name }}.pos_fisk_doks set broj_rn=nBrojRacuna, obradjeno=now() WHERE ref_pos_dok=posUUID;
END IF;

RETURN COALESCE( nBrojRacuna, 0);

END;
$$;


CREATE OR REPLACE FUNCTION {{ item.name }}.fisk_dok_id( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS text
 LANGUAGE plpgsql
 AS $$
DECLARE
   posUUID uuid;
BEGIN

SELECT pos_fisk_doks.dok_id FROM {{ item.name }}.pos
   LEFT JOIN {{ item.name }}.pos_fisk_doks
   ON {{ item.name }}.pos_fisk_doks.ref_pos_dok = {{ item.name }}.pos.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO posUUID;

IF posUUID IS NULL THEN
     RAISE INFO 'pos % % % % ne postoji ?!', cIdPos, cIdVd, dDatDok, cBrDok;
     RETURN '';
END IF;

RETURN posUUID::text;

END;
$$;


CREATE OR REPLACE FUNCTION {{ item.name }}.pos_is_storno( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS boolean
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidStorno uuid;
BEGIN

SELECT pos_fisk_doks.ref_storno_fisk_dok FROM {{ item.name }}.pos
   LEFT JOIN {{ item.name }}.pos_fisk_doks
   ON {{ item.name }}.pos_fisk_doks.ref_pos_dok = {{ item.name }}.pos.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO uuidStorno;

IF uuidStorno IS NULL THEN
     RETURN FALSE;
END IF;

RETURN TRUE;

END;
$$;


-- SELECT {{ item.name }}.pos_storno_broj_rn( '1 ','42','2019-03-15','       8' );  => 101

CREATE OR REPLACE FUNCTION {{ item.name }}.pos_storno_broj_rn( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   iStornoBrojRn integer;
BEGIN

SELECT fisk2.broj_rn FROM {{ item.name }}.pos
   LEFT JOIN {{ item.name }}.pos_fisk_doks as fisk1
   ON fisk1.ref_pos_dok = {{ item.name }}.pos.dok_id
   LEFT JOIN {{ item.name }}.pos_fisk_doks as fisk2
   ON fisk1.ref_storno_fisk_dok = fisk2.dok_id
   WHERE pos.idpos=cIdPos AND pos.idvd=cIdVd AND pos.datum=dDatDok AND pos.brDok=cBrDok
   INTO iStornoBrojRn;

IF iStornoBrojRn IS NULL THEN
     RETURN 0;
END IF;

RETURN iStornoBrojRn;

END;
$$;


CREATE OR REPLACE FUNCTION {{ item.name }}.fisk_broj_rn_by_storno_ref( uuidFiskStorniran text ) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   nBrojRacuna integer;
   nCount integer;
BEGIN

SELECT count(*) FROM {{ item.name }}.pos_fisk_doks
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO nCount;

IF (nCount = 0) THEN
      RETURN 0; -- uopste nema pos_fisk_doks zapisa
END IF;

SELECT broj_rn FROM {{ item.name }}.pos_fisk_doks
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO nBrojRacuna;

RETURN COALESCE(nBrojRacuna, -1); -- pos_fisk_doks zapis broj_rn moze biti NULL

END;
$$;


CREATE OR REPLACE FUNCTION {{ item.name }}.set_ref_storno_fisk_dok( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, uuidFiskStorniran text ) RETURNS void
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidFiskNovi uuid;
BEGIN

  uuidFiskNovi := {{ item.name }}.fisk_dok_id( cIdPos, cIdVd, dDatDok, cBrDok);

  UPDATE {{ item.name }}.pos_fisk_doks SET ref_storno_fisk_dok = uuidFiskStorniran::uuid
      WHERE dok_id = uuidFiskNovi;

END;
$$;


-- select pos_dok_id('1 ','42','       1', '2018-01-09');
CREATE OR REPLACE FUNCTION {{ item.name }}.pos_dok_id(cIdPos varchar, cIdVD varchar, cBrDok varchar, dDatum date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM {{ item.name }}.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
     USING cIdPos, cIdVd, cBrDok, dDatum
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'pos_doks %-%-% od % NE postoji?!', cIdPos, cIdVd, cBrDok, dDatum;
   END IF;

   RETURN dok_id;
END;
$$;