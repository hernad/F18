CREATE OR REPLACE FUNCTION p15.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM p15.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$$;

ALTER FUNCTION p15.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION p15.fetchmetrictext TO xtrole;


CREATE OR REPLACE FUNCTION p15.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM p15.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM p15.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE p15.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO p15.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$$;


ALTER FUNCTION p15.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION p15.setmetric TO xtrole;


CREATE OR REPLACE FUNCTION p15.pos_novi_broj_dokumenta(cIdPos varchar, cIdVd varchar, dDatum date) RETURNS varchar
  LANGUAGE plpgsql
  AS $$

DECLARE
   cBrDok varchar;
BEGIN

    SELECT brdok from p15.pos_doks where idvd=cIdVd and datum=dDatum order by brdok desc limit 1
           INTO cBrDok;
    IF cBrdok IS NULL THEN
        cBrDok := to_char(1, '99999999');
    ELSE
        cBrDok := to_char( to_number(cBrDok, '09999999') + 1, '99999999');
    END IF;

    RETURN lpad(btrim(cBrDok), 8, ' ');

END;
$$;


CREATE OR REPLACE FUNCTION p15.pos_dostupno_artikal_za_cijenu(cIdRoba varchar, nCijena numeric, nNCijena numeric) RETURNS numeric
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
-- insert into p15.pos_doks(idpos, idvd, brdok, datum) values('1 ', '42', 'XX', current_date );

-- SET
-- select p15.broj_fiskalnog_racuna( '1 ', '42', current_date, 'XX', 102 );
-- GET
-- select p15.broj_fiskalnog_racuna( '1 ', '42', current_date, 'XX', NULL );

-- select * from p15.pos_doks;
-- select * from p15.pos_fisk_doks;

CREATE OR REPLACE FUNCTION p15.broj_fiskalnog_racuna( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, nBrojRacuna integer) RETURNS integer
 LANGUAGE plpgsql
 AS $$
DECLARE
   posUUID uuid;
   fiskUUID uuid;
BEGIN

SELECT dok_id FROM p15.pos_doks
   WHERE idpos=cIdPos AND idvd=cIdVd AND datum=dDatDok AND brDok=cBrDok
   INTO posUUID;

IF posUUID IS NULL THEN
     RAISE EXCEPTION 'pos_doks % % % % ne postoji ?!', cIdPos, cIdVd, dDatDok, cBrDok;
END IF;

-- get broj racuna
IF nBrojRacuna IS NULL THEN
    SELECT broj_rn FROM p15.pos_fisk_doks where ref_pos_dok=posUUID
      INTO nBrojRacuna;
    RETURN nBrojRacuna;
END IF;

SELECT dok_id FROM p15.pos_fisk_doks
   WHERE ref_pos_dok = posUUID
   INTO fiskUUID;

IF fiskUUID IS NULL THEN
    INSERT INTO p15.pos_fisk_doks(ref_pos_dok, broj_rn) VALUES(posUUID, nBrojRacuna);
ELSE
    UPDATE p15.pos_fisk_doks set broj_rn=nBrojRacuna, obradjeno=now() WHERE ref_pos_dok=posUUID;
END IF;

RETURN nBrojRacuna;

END;
$$;


-- select pos_dok_id('1 ','42','       1', '2018-01-09');
CREATE OR REPLACE FUNCTION p15.pos_dok_id(cIdPos varchar, cIdVD varchar, cBrDok varchar, dDatum date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM p15.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
     USING cIdPos, cIdVd, cBrDok, dDatum
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'pos_doks %-%-% od % NE postoji?!', cIdPos, cIdVd, cBrDok, dDatum;
   END IF;

   RETURN dok_id;
END;
$$;
