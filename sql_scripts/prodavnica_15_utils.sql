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
$$



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
$$


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
$$
