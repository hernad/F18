
CREATE TABLE IF NOT EXISTS p15.pos_stanje (
   id SERIAL,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   roba_id uuid,
   ulazi text[],
   izlazi text[],
   kol_ulaz numeric(18,3),
   kol_izlaz numeric(18,3),
   cijena numeric(10,3),
   ncijena numeric(10,3)
);
ALTER TABLE p15.pos_stanje OWNER TO admin;
GRANT ALL ON TABLE p15.pos_stanje TO xtrole;
GRANT ALL ON SEQUENCE p15.pos_stanje_id_seq TO xtrole;

ALTER TABLE p15.pos_stanje ALTER COLUMN dat_od SET NOT NULL;
ALTER TABLE p15.pos_pos ALTER COLUMN idroba SET NOT NULL;
ALTER TABLE p15.pos_pos ALTER COLUMN cijena SET NOT NULL;

CREATE OR REPLACE FUNCTION p15.pos_prijem_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric,
   ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
BEGIN

IF ( idvd <> '02' ) AND ( idvd <> '80' ) AND ( idvd <> '89' ) AND ( idvd <> '22' ) THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF dat_od IS NULL then
  dat_do := '1999-01-01';
END IF;
IF dat_do IS NULL then
  dat_do := '3999-01-01';
END IF;

IF transakcija = '-' THEN -- on delete pos_pos stavka
   -- treba da se poklope sve ove stavke: idroba / cijena / ncijena / dat_do, a da zadani dat_od bude >= od analiziranog
   RAISE INFO 'in_pos_prijem_update_stanje delete = % % % % % %', dokument, idroba, cijena, ncijena, dat_od, dat_do;
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(ulazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- slijedi + transakcija on insert pos_pos
-- (dat_od <= current_date AND dat_do >= current_date) = aktuelna cijena
-- novi dat_od mora biti >= dat_od analiziranog zapisa, novi dat_do = dat_do zapisa
-- 'ORDER BY kol_ulaz - kol_izlaz LIMIT 1' obezbjedjuje da stavke koji su negativne
-- (znaci nedostaju im ulazi) napunimo ulazom, LIMIT 1 - stavka sa najmanjom kolicinom
--
--  $4 <= current_date => dat_od otpremnice manji ili jednak danasnjem datumu, znaci da je aktuelan
EXECUTE  'select id from p' || idPos || '.pos_stanje where  (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND kol_ulaz - kol_izlaz <> 0 AND cijena = $2 AND  ncijena = $3 AND $4 <= current_date AND dat_do = $5' ||
         ' ORDER BY kol_ulaz - kol_izlaz LIMIT 1'
      using idroba, cijena, ncijena, dat_od, dat_do
      INTO idRaspolozivo;

RAISE INFO 'in_pos_prijem_update_stanje + idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE
   -- u ovom narednom upitu cemo provjeriti postoji li ranija stavka koja moze biti i negativna
   -- koja je aktuelna
   EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND ncijena = $3 AND kol_ulaz - kol_izlaz <> 0'
    using idroba, cijena, ncijena
    INTO idRaspolozivo;

   IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
        ' WHERE id=$2'
         USING kolicina, idRaspolozivo, dokument;
   ELSE
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
        ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
   END IF;
END IF;

RETURN TRUE;

END;
$$;

-- delete from p15.pos_stanje;
--
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK00', '1', current_date-5, current_date-5, NULL,'R01', 40, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '2', current_date, current_date, NULL,'R01', 100, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '10', current_date, current_date, NULL,'R01',  50, 2.5, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '1', current_date, current_date, NULL,'R01',  20, 2.0, 0);
-- select p15.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '1', current_date, current_date, NULL,'R02',  30,   3, 0);

-- select * from p15.pos_stanje;

-- select p15.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '10', current_date, current_date, NULL, 'R01',  50, 2.5, 0);

-- select * from p15.pos_stanje;

-- select id, ulazi from p15.pos_stanje where '15-11-BRDOK01-20190211' = ANY(ulazi)


CREATE OR REPLACE FUNCTION p15.pos_izlaz_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric, ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
   dat_do date DEFAULT '3999-01-01';
BEGIN

IF ( idvd <> '42' )  THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF (transakcija = '-') THEN -- on delete pos_pos stavka
   RAISE INFO 'pos_stanje % % % %', dokument, idroba, cijena, ncijena;
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(izlazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- slijedi + transakcija on insert pos_pos
-- (dat_od <= current_date AND dat_do >= current_date ) - cijena je aktuelna
EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND kol_ulaz - kol_izlaz > 0 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

RAISE INFO 'idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE -- kod izlaza se insert desava samo ako ako roba ide u minus !

  -- u ovom naraednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu
  EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
           ' VALUES($1,$2,$3,$4,$5,0,$6,$7,$8)'
           USING datum, dat_do, idroba, '{}'::text[], dokumenti, kolicina, cijena, ncijena, dat_do;
  END IF;

END IF;

RETURN TRUE;

END;
$$;

-- prodaja
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD01', '1', current_date, 'R01', 60, 2.5, 0);
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD03', '5',current_date, 'R02', 20, 3, 0);
--
-- -- robe ima, ali ce je ova transakcija otjerati u minus
-- select p15.pos_izlaz_update_stanje('+', '15', '42', 'PROD90', '1', current_date, 'R01', 500, 2.5, 0);
-- -- nastavljamo sa minusom; minus se gomila na jednoj stavki
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD91', '1', current_date, 'R01',  40, 2.5, 0);
--
-- -- ove robe nema na stanju
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD10', '1', current_date, 'R03', 10, 30, 0);
-- select p15.pos_izlaz_update_stanje('+', '15', '42', '1','PROD11', '15', current_date, 'R03', 20, 30, 0);


CREATE OR REPLACE FUNCTION p15.pos_promjena_cijena_update_stanje(
   transakcija character(1),
   idpos character(2),
   idvd character(2),
   brdok character(8),
   rbr integer,
   datum date,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   kolicina numeric,
   cijena numeric,
   ncijena numeric) RETURNS boolean

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
BEGIN

IF ( idvd <> '19' ) AND ( idvd <> '29' ) AND ( idvd <> '79' ) THEN
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF dat_od IS NULL then
  dat_do := '1999-01-01';
END IF;
IF dat_do IS NULL then
  dat_do := '3999-01-01';
END IF;

IF transakcija = '-' THEN -- on delete pos_pos stavka

   RAISE INFO 'delete = % % % % % %', dokument, idroba, cijena, ncijena, dat_od, dat_do;
   -- (1) ponistiti izlaz koji je nivelacija napravila
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(izlazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument ulaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   -- (2) ponistiti ulaz koji je nivelacija napravila
   EXECUTE  'select id from p' || idPos || '.pos_stanje where $1 = ANY(ulazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument izlaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- raspoloziva roba po starim cijenama, kolicina treba biti > 0
-- ncijena=0, gledaju se samo OSNOVNE cijene
EXECUTE  'select id from p' || idPos || '.pos_stanje where  (dat_od <= current_date AND dat_do >= current_date )' ||
         ' AND idroba = $1 AND kol_ulaz - kol_izlaz > 0 AND cijena = $2 AND  ncijena = 0 AND $3 <= current_date AND $4 <= dat_do' ||
         ' ORDER BY kol_ulaz - kol_izlaz LIMIT 1'
      using idroba, cijena, dat_od, dat_do
      INTO idRaspolozivo;

RAISE INFO 'idDokument = % % %', idRaspolozivo, dat_od, dat_do;

IF NOT idRaspolozivo IS NULL then
  -- umanjiti - 'iznijeti' zalihu po starim cijenama
  EXECUTE 'update p' || idPos || '.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;
  -- dodati zalihu po novim cijenama
  IF ( idvd = '19' ) OR ( idvd = '29' ) THEN
      cijena := ncijena; -- nivelacija - nova cijena postaje osnovna
      ncijena := 0;
  END IF;

  -- u ovom narednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu
  EXECUTE  'select id from p' || idPos || '.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      -- ako postoji onda ovu nivelaciju dodati na tu predhodnu prodaju
      EXECUTE 'update p' || idPos || '.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into p' || idPos || '.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
             ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
          USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
  END IF;


ELSE
  -- nema dostupne zalihe za promjenu ?!
  RAISE INFO 'ERROR_PROMJENA_CIJENA: nema dostupne zalihe za promjenu cijena % % % %', idvd, brdok, dat_od, dat_do;
END IF;

RETURN TRUE;

END;
$$;
