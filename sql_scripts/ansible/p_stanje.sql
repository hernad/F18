
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_prijem_update_stanje(
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

IF ( NOT idvd IN ('02','03','80','89','22','90','IP') ) THEN
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
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(ulazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
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
-- ... OR (dat_od=$4 AND dat_do=$5) znaci da se moze retroaktivno poslati dokument kome je dat_od i dat_do odgovara nekoj transakciji
--                                  koju zelimo modifikovati
EXECUTE 'select id from {{ item_prodavnica }}.pos_stanje where (dat_od<=current_date AND dat_do>=current_date AND $4<=current_date AND dat_do=$5 )' ||
         ' AND idroba = $1 AND kol_ulaz-kol_izlaz <> 0 AND cijena=$2 AND ncijena=$3' ||
         ' ORDER BY kol_ulaz-kol_izlaz LIMIT 1'
      using idroba, cijena, ncijena, dat_od, dat_do
      INTO idRaspolozivo;

RAISE INFO 'in_pos_prijem_update_stanje + idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE
   -- u ovom narednom upitu cemo provjeriti postoji li ranija stavka koja moze biti i negativna
   -- koja je aktuelna
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND cijena = $2 AND ncijena = $3 AND kol_ulaz - kol_izlaz <> 0'
    using idroba, cijena, ncijena
    INTO idRaspolozivo;

   IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
        ' WHERE id=$2'
         USING kolicina, idRaspolozivo, dokument;
   ELSE
      EXECUTE 'insert into {{ item_prodavnica }}.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
        ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
   END IF;
END IF;

RETURN TRUE;

END;
$$;

-- delete from {{ item_prodavnica }}.pos_stanje;
--
-- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK00', '1', current_date-5, current_date-5, NULL,'R01', 40, 2.5, 0);
-- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '2', current_date, current_date, NULL,'R01', 100, 2.5, 0);
-- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '10', current_date, current_date, NULL,'R01',  50, 2.5, 0);
-- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK02', '1', current_date, current_date, NULL,'R01',  20, 2.0, 0);
-- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '1', current_date, current_date, NULL,'R02',  30,   3, 0);

-- select * from {{ item_prodavnica }}.pos_stanje;

-- select {{ item_prodavnica }}.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '10', current_date, current_date, NULL, 'R01',  50, 2.5, 0);

-- select * from {{ item_prodavnica }}.pos_stanje;

-- select id, ulazi from {{ item_prodavnica }}.pos_stanje where '15-11-BRDOK01-20190211' = ANY(ulazi)


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_izlaz_update_stanje(
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

IF ( NOT idvd IN ('42','90','IP','99') )  THEN -- 42 prodaja, 90 (kada je manjak), 99 - kalo stanje za prodaju umanjeno
        RETURN FALSE;
END IF;

dokument := (btrim(idpos) || '-' || idvd || '-' || btrim(brdok) || '-' || to_char(datum, 'yyyymmdd'))::text || '-' || btrim(to_char(rbr,'99999'));
dokumenti := dokumenti || dokument;

IF (transakcija = '-') THEN -- on delete pos_pos stavka
   RAISE INFO 'pos_stanje % % % %', dokument, idroba, cijena, ncijena;
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(izlazi) AND idroba = $2 AND cijena = $3 AND ncijena = $4'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'idDokument = %', idDokument;

   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN TRUE;
END IF;

-- slijedi + transakcija on insert pos_pos
-- (dat_od <= current_date AND dat_do >= current_date ) - cijena je aktuelna
EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where (dat_od <= current_date AND dat_do >= current_date ) AND idroba = $1 AND kol_ulaz - kol_izlaz > 0 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

RAISE INFO 'idDokument = %', idRaspolozivo;

IF NOT idRaspolozivo IS NULL then
  EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

ELSE -- kod izlaza se insert desava samo ako ako roba ide u minus !

  -- u ovom narednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu
  EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where (dat_od<=current_date AND dat_do>=current_date ) AND idroba=$1 AND cijena = $2 AND  ncijena = $3'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz + $1, izlazi = izlazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into {{ item_prodavnica }}.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
           ' VALUES($1,$2,$3,$4,$5,0,$6,$7,$8)'
           USING datum, dat_do, idroba, '{}'::text[], dokumenti, kolicina, cijena, ncijena, dat_do;
  END IF;

END IF;

RETURN TRUE;

END;
$$;

-- prodaja
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', 'PROD01', '1', current_date, 'R01', 60, 2.5, 0);
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', 'PROD03', '5',current_date, 'R02', 20, 3, 0);
--
-- -- robe ima, ali ce je ova transakcija otjerati u minus
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', 'PROD90', '1', current_date, 'R01', 500, 2.5, 0);
-- -- nastavljamo sa minusom; minus se gomila na jednoj stavki
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', '1','PROD91', '1', current_date, 'R01',  40, 2.5, 0);
--
-- -- ove robe nema na stanju
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', '1','PROD10', '1', current_date, 'R03', 10, 30, 0);
-- select {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', '1','PROD11', '15', current_date, 'R03', 20, 30, 0);

DROP FUNCTION IF EXISTS {{ item_prodavnica }}.pos_promjena_cijena_update_stanje;

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_promjena_cijena_update_stanje(
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
   ncijena numeric) RETURNS numeric

LANGUAGE plpgsql
AS $$
DECLARE
   dokumenti text[] DEFAULT '{}';
   dokument text;
   idDokument bigint;
   idRaspolozivo bigint;
   cMsg text;
   nStanje decimal;
   idRaspolozivoPatchMinus bigint;
   nStanjePatchMinus decimal;
BEGIN

IF ( NOT idvd IN ('19','29','79') ) THEN -- knjig nivelacija, pos nivelacija, snizenje
        RETURN -1;
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
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(izlazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument ulaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   -- (2) ponistiti ulaz koji je nivelacija napravila
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(ulazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument izlaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   RETURN kolicina;
END IF;


IF idvd = '79' AND dat_od > current_date THEN -- ako se odobrava snizenje unaprijed
   cMsg := format('%s-%s %s kol: %s cij: %s ncij: %s dat_od: %s dat_do: %s', idvd, brdok, idroba, kolicina, cijena, ncijena, dat_od, dat_do);
   PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'SKIP_79_UNAPRIJED', cMsg);
   RETURN -1;
END IF;


-- PATCH fix minus istekao popust PATCH PATCH --
EXECUTE  'select id, -kol_ulaz+kol_izlaz as stanje from {{ item_prodavnica }}.pos_stanje WHERE ' ||
         '(pos_stanje.ncijena<>0 AND pos_stanje.dat_od<current_date AND pos_stanje.dat_do<current_date AND pos_stanje.cijena=$2)' ||
         ' AND pos_stanje.idroba=$1 AND pos_stanje.kol_ulaz-pos_stanje.kol_izlaz<0' ||
         ' ORDER BY kol_ulaz-kol_izlaz LIMIT 1'
      using idroba, ncijena
      INTO idRaspolozivoPatchMinus, nStanjePatchMinus;

IF NOT idRaspolozivoPatchMinus IS NULL THEN
  RAISE INFO 'PATCH MINUS! = % % % kol: % cij: % ncij: %', idroba, idRaspolozivoPatchMinus, nStanjePatchMinus, kolicina, cijena, ncijena;
ELSE
  -- raspoloziva roba po starim cijenama, kolicina treba biti > 0
  -- ncijena=0, gledaju se samo DOSADASNJE OSNOVNE cijene
  EXECUTE  'select id, kol_ulaz-kol_izlaz as stanje from {{ item_prodavnica }}.pos_stanje WHERE ' ||
         '(ncijena=0 AND dat_od<=current_date AND dat_do>=current_date AND $3<=current_date AND $4<=dat_do AND cijena=$2)' ||
         ' AND idroba=$1 AND kol_ulaz-kol_izlaz>0' ||
         ' ORDER BY kol_ulaz-kol_izlaz LIMIT 1'
      using idroba, cijena, dat_od, dat_do
      INTO idRaspolozivo, nStanje;

   RAISE INFO 'pos_stanje id: %  idroba: % dat_od: % dat_do: % cij: % stanje: % kol: %', idRaspolozivo, idroba, dat_od, dat_do, cijena, nStanje, kolicina;
END IF;


IF (NOT idRaspolozivo IS NULL) AND (nStanje < kolicina) THEN
    IF idvd = '79' THEN -- odobrenje snizenja se primjenjuje na dostupnu kolicinu
       kolicina := nStanje;
    ELSE
       cMsg := format('%s-%s %s kol: %s cij: %s ncij: %s dat_od: %s dat_do: %s - DOSTUPNO: %s', idvd, brdok, idroba, kolicina, cijena, ncijena, dat_od, dat_do, nStanje);
       PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_PROMJENA_CIJENA_KOLICINA', cMsg);
       RETURN -1;
    END IF;
END IF;

IF NOT idRaspolozivo IS NULL THEN
    -- umanjiti - 'iznijeti' zalihu po starim cijenama
    EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz+$1,izlazi=izlazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

  -- dodati zalihu po novim cijenama
  IF ( idvd IN ('19','29') ) THEN
      cijena := ncijena; -- nivelacija - nova cijena postaje osnovna
      ncijena := 0;
  END IF;

  -- u ovom narednom upitu cemo provjeriti postoji li ranija prodaja ovog artikla u minusu po novim cijenama
  EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where (dat_od<=current_date AND dat_do>=current_date) AND idroba=$1 AND cijena=$2 AND ncijena=$3' ||
      ' order by id desc limit 1'
      using idroba, cijena, ncijena
      INTO idRaspolozivo;

  IF NOT idRaspolozivo IS NULL THEN
      -- ako postoji onda ovu nivelaciju dodati na tu predhodnu prodaju
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz + $1, ulazi = ulazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
  ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
      EXECUTE 'insert into {{ item_prodavnica }}.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
             ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
          USING dat_od, dat_do, idroba, dokumenti, '{}'::text[], kolicina, 0, cijena, ncijena;
  END IF;

ELSIF (NOT idRaspolozivoPatchMinus IS NULL) AND (kolicina = nStanjePatchMinus) AND (idvd = '29') THEN
   -- PATCH PATCH PATCH
   -- umanjiti - ugasiti minusnu zalihu istekao stari popust

   EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz-$1,izlazi=izlazi || $3' ||
   ' WHERE id=$2'
    USING kolicina, idRaspolozivoPatchMinus, dokument;


    cijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( idroba );
    ncijena := 0;

    -- naci stavku pos_stanje po osnovnoj cijeni
    EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where (dat_od<=current_date AND dat_do>=current_date) AND idroba=$1 AND cijena=$2 AND ncijena=$3' ||
        ' order by id desc limit 1'
        using idroba, cijena, ncijena
        INTO idRaspolozivo;

    IF NOT idRaspolozivo IS NULL THEN
        -- ako postoji onda ovu nivelaciju ODUZETI za tu prodaju sa isteklim popustom
        EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz - $1, ulazi = ulazi || $3' ||
            ' WHERE id=$2'
            USING kolicina, idRaspolozivo, dokument;
    ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
        RAISE EXCEPTION 'ERROR FIX -POPUST % kol: % cij: %', idroba, kolicina, cijena;
    END IF;

ELSE
  -- nema dostupne zalihe za promjenu ?!
  cMsg := format('%s-%s %s kol: %s cij: %s ncij: %s dat_od: %s dat_do: %s', idvd, brdok, idroba, kolicina, cijena, ncijena, dat_od, dat_do);
  PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_79', cMsg);
  RAISE INFO 'ERROR_PROMJENA_CIJENA: nema dostupne zalihe za promjenu cijena % % % %', idvd, brdok, dat_od, dat_do;
  RETURN -1;
END IF;

RETURN kolicina;

END;
$$;


-- storno promjena cijena
-- parametar kolicina je uvijek < 0
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_promjena_cijena_storno_update_stanje(
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
   cMsg text;
BEGIN

IF ( NOT idvd IN ('19','29','79') ) THEN -- knjig nivelacija, pos nivelacija, snizenje
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
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(izlazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument ulaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_izlaz=kol_izlaz - $3, izlazi=array_remove(izlazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;

   -- (2) ponistiti ulaz koji je nivelacija napravila
   EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where $1 = ANY(ulazi) AND idroba = $2'
     using dokument, idroba, cijena, ncijena
     INTO idDokument;
   RAISE INFO 'pos_promjena_cijena idDokument izlaza= %', idDokument;
   IF NOT idDokument IS NULL then -- brisanje efekte dokumenta za ovaj artikal i ove cijene
      EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz - $3, ulazi=array_remove(ulazi, $2)' ||
             ' WHERE id=$1'
           USING idDokument, dokument, kolicina;
   END IF;
   RETURN TRUE;
END IF;


EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje WHERE ' ||
         '(dat_od=$3 AND dat_do=$4 AND cijena=$2 AND ncijena=$5)' ||
         ' AND idroba=$1 AND kol_ulaz-kol_izlaz>0' ||
         ' ORDER BY kol_ulaz-kol_izlaz LIMIT 1'
      using idroba, cijena, dat_od, dat_do, ncijena
      INTO idRaspolozivo;

RAISE INFO 'stornirati idDokument = % % %', idRaspolozivo, dat_od, dat_do;

IF NOT idRaspolozivo IS NULL then
     -- u slucaju storna locirali smo stavku po snizenoj cijeni
     -- storniramo ulaz
     EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz+$1,ulazi=ulazi || $3' ||
       ' WHERE id=$2'
        USING kolicina, idRaspolozivo, dokument;

     -- stornirati izlaz zalihe po starim cijenama
     -- u ovom narednom upitu cemo traziti stare cijene
     EXECUTE  'select id from {{ item_prodavnica }}.pos_stanje where dat_do>=$3 AND idroba=$1 AND cijena=$2 AND ncijena=0'
      using idroba, cijena, dat_do
      INTO idRaspolozivo;

     -- zaduziti kao ulaz po staroj cijeni za iznos -kolicina (sto je > 0)
     kolicina := -kolicina;

     IF NOT idRaspolozivo IS NULL THEN
        -- ako postoji onda povecati ulaz
        RAISE INFO 'povecati ulaz za % po staroj cijeni %', kolicina, cijena;
        EXECUTE 'update {{ item_prodavnica }}.pos_stanje set kol_ulaz=kol_ulaz+$1, ulazi=ulazi || $3' ||
          ' WHERE id=$2'
          USING kolicina, idRaspolozivo, dokument;
     ELSE -- nema 'kompatibilnih' stavki stanja (ni roba na stanju, ni prodaja u minus)
        EXECUTE 'insert into {{ item_prodavnica }}.pos_stanje(dat_od,dat_do,idroba,ulazi,izlazi,kol_ulaz,kol_izlaz,cijena,ncijena)' ||
             ' VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
          USING dat_od, dat_do, idroba, dokumenti,'{}'::text[], kolicina,0,cijena,0;
     END IF;

ELSE
  -- nema dostupne zalihe za storno promjenu ?!
  cMsg := format('%s-%s %s kol: %s cij: %s ncij: %s dat_od: %s dat_do: %s', idvd, brdok, idroba, kolicina, cijena, ncijena, dat_od, dat_do);
  PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_STORNO_PROMJENA_CIJENA', cMsg);
  RAISE INFO 'ERROR_STORNO_PROMJENA_CIJENA: nema dostupne zalihe za promjenu cijena storno % % % %', idvd, brdok, dat_od, dat_do;
END IF;

RETURN TRUE;

END;
$$;




CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fix_pos_stanje() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar DEFAULT '1 ';
      nCount integer;
      rec_stanje RECORD;
      rec_roba RECORD;
      cIdRoba varchar;
      nOsnovnaCijena numeric;
      nStanje numeric;
      cBrDokNew varchar;
      dDatum date;
      nRbr integer;
      uuidPos uuid;
      nStaraCijena numeric;
      nNovaCijena numeric;
      nDostupnaKolicina numeric;
      cMsg varchar;
      lInsertovano boolean;
BEGIN

      nCount := 0;
      cIdRoba := 'X#X';
      cBrDokNew := NULL;
      dDatum := current_date;
      nRbr := 1;
      lInsertovano := FALSE;

      FOR rec_stanje IN SELECT id, dat_od, dat_do, idroba, roba_id, ulazi, izlazi, kol_ulaz, kol_izlaz, cijena, ncijena from {{ item_prodavnica }}.pos_stanje
                           UNION
                        SELECT 0 id, current_date dat_od, current_date dat_do, 'X#X' idroba, null roba_id, '{}'::text[] ulazi, '{}'::text[] izlazi, 0 kol_ulaz, 0 kol_izlaz, 9999 cijena, 0 ncijena
                        ORDER BY idroba
      LOOP
         -- ovaj union dole se radi zato da uvijek prodje kroz ovaj if nakon odredjenog artikla
         IF cIdRoba <> rec_stanje.idroba THEN
           IF cIdRoba <> 'X#X' AND lInsertovano THEN
              -- uvijek na kraju zadati stavku sa kolicinom 0 i aktuelnom osnovnom cijenom da se ne bi promijenila osnovna cijena
              nStanje := 0;
              EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                using cIdPos, '29', cBrDokNew, dDatum, uuidPos, nRbr, cIdRoba, nStanje, nOsnovnaCijena, nOsnovnaCijena, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
                nRbr := nRbr + 1;
           END IF;
           cIdRoba := rec_stanje.idroba;
           nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba );
           nDostupnaKolicina := {{ item_prodavnica }}.pos_dostupno_artikal_za_cijenu(cIdRoba, nOsnovnaCijena, 0);
           lInsertovano := FALSE;
           IF nOsnovnaCijena = 0 THEN
              CONTINUE;
           END IF;
         END IF;

         nStanje := rec_stanje.kol_ulaz - rec_stanje.kol_izlaz;
         IF nStanje <> 0 AND rec_stanje.cijena <> nOsnovnaCijena AND (rec_stanje.ncijena = 0) THEN
            -- stavka koja je bila osnovna cijena je 'ziva' a nije po aktuelnoj osnovnoj cijeni

            -- ili stavka sa popustom kod koje je negativno stanje a popust je istekao
            -- OR (rec_stanje.ncijena<>0 and nStanje < 0 and dat_do < current_date)) THEN

            IF nStanje > 0 THEN
               nStaraCijena := rec_stanje.cijena;
               nNovaCijena := nOsnovnaCijena;
            ELSE
               nStaraCijena := nOsnovnaCijena;
               nNovaCijena := rec_stanje.cijena;
               nStanje := - nStanje;
               IF nDostupnaKolicina - nStanje > 0 THEN
                 nDostupnaKolicina := nDostupnaKolicina - nStanje;
               ELSE
                  cMsg := format('%s : cij: %s stanje: %s', cIdRoba, rec_stanje.cijena, -nStanje);
                  PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_FIX_POS_STANJE', cMsg);
                  RAISE INFO 'preskacemo % % % nema dovoljno osnovne kolicine', cIdRoba, rec_stanje.cijena, -nStanje;
                  CONTINUE;
               END IF;
            END IF;

            IF cBrDokNew IS NULL THEN
               cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatum);
               insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,opis)
                    values(cIdPos, '29', cBrDokNew, dDatum, dDatum, 'GEN: fix pos_stanje')
                    RETURNING dok_id into uuidPos;
            END IF;

            SELECT * FROM {{ item_prodavnica }}.roba
               WHERE id=cIdRoba
               INTO rec_roba;

            EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                 using cIdPos, '29', cBrDokNew, dDatum, uuidPos, nRbr, cIdRoba, nStanje, nStaraCijena, nNovaCijena, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
             lInsertovano := TRUE;
             nRbr := nRbr + 1;
             nCount := nCount + 1;

         END IF;


      END LOOP;

      RETURN nCount;
END;
$$;




CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fix_pos_stanje_patch_minus_popust_istekao() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar DEFAULT '1 ';
      nCount integer;
      rec_stanje RECORD;
      rec_roba RECORD;
      cIdRoba varchar;
      nOsnovnaCijena numeric;
      nStanje numeric;
      cBrDokNew varchar;
      dDatum date;
      nRbr integer;
      uuidPos uuid;
      nStaraCijena numeric;
      nNovaCijena numeric;
      nDostupnaKolicina numeric;
      cMsg varchar;
      lInsertovano boolean;
BEGIN

      nCount := 0;
      cIdRoba := 'X#X';
      cBrDokNew := NULL;
      dDatum := current_date;
      nRbr := 1;
      lInsertovano := FALSE;

      FOR rec_stanje IN SELECT id, dat_od, dat_do, idroba, roba_id, ulazi, izlazi, kol_ulaz, kol_izlaz, cijena, ncijena from {{ item_prodavnica }}.pos_stanje
                           UNION
                        SELECT 0 id, current_date dat_od, current_date dat_do, 'X#X' idroba, null roba_id, '{}'::text[] ulazi, '{}'::text[] izlazi, 0 kol_ulaz, 0 kol_izlaz, 9999 cijena, 0 ncijena
                        ORDER BY idroba
      LOOP
         -- ovaj union dole se radi zato da uvijek prodje kroz ovaj if nakon odredjenog artikla
         IF cIdRoba <> rec_stanje.idroba THEN
           IF cIdRoba <> 'X#X' AND lInsertovano THEN
              -- uvijek na kraju zadati stavku sa kolicinom 0 i aktuelnom osnovnom cijenom da se ne bi promijenila osnovna cijena
              nStanje := 0;
              EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                using cIdPos, '29', cBrDokNew, dDatum, uuidPos, nRbr, cIdRoba, nStanje, nOsnovnaCijena, nOsnovnaCijena, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
                nRbr := nRbr + 1;
           END IF;
           cIdRoba := rec_stanje.idroba;
           nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba );
           nDostupnaKolicina := {{ item_prodavnica }}.pos_dostupno_artikal_za_cijenu(cIdRoba, nOsnovnaCijena, 0);
           lInsertovano := FALSE;
           IF nOsnovnaCijena = 0 THEN
              CONTINUE;
           END IF;
         END IF;

         nStanje := rec_stanje.kol_ulaz - rec_stanje.kol_izlaz;
         IF nStanje < 0 AND rec_stanje.ncijena <> 0 AND rec_stanje.dat_do < current_date THEN

            -- stavka sa popustom kod koje je negativno stanje a popust je istekao
            --nStaraCijena := nOsnovnaCijena;
            nStaraCijena := rec_stanje.cijena;
            nNovaCijena := rec_stanje.cijena;
            nStanje := - nStanje;
            IF nDostupnaKolicina - nStanje >= 0 THEN
                 nDostupnaKolicina := nDostupnaKolicina - nStanje;
            ELSE
                  cMsg := format('%s : cij: %s stanje: %s', cIdRoba, rec_stanje.cijena, -nStanje);
                  PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_FIX_POS_STANJE-POPUST', cMsg);
                  RAISE INFO 'preskacemo % % % nema dovoljno osnovne kolicine', cIdRoba, rec_stanje.cijena, -nStanje;
                  CONTINUE;
            END IF;

            IF cBrDokNew IS NULL THEN
               cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '29', dDatum);
               insert into {{ item_prodavnica }}.pos(idPos,idVd,brDok,datum,dat_od,opis)
                    values(cIdPos, '29', cBrDokNew, dDatum, dDatum, 'GEN: fix pos_stanje patch -popust')
                    RETURNING dok_id into uuidPos;
            END IF;

            SELECT * FROM {{ item_prodavnica }}.roba
               WHERE id=cIdRoba
               INTO rec_roba;

            EXECUTE 'insert into {{ item_prodavnica }}.pos_items(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                 using cIdPos, '29', cBrDokNew, dDatum, uuidPos, nRbr, cIdRoba, nStanje, nStaraCijena, nNovaCijena, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
             lInsertovano := TRUE;
             nRbr := nRbr + 1;
             nCount := nCount + 1;

         END IF;


      END LOOP;

      RETURN nCount;
END;
$$;



CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.fix_pos_stanje_prema_kartica() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar DEFAULT '1 ';
      nCount integer;
      rec_roba RECORD;
      cIdRoba varchar;
      nOsnovnaCijena numeric;
      nPosStanjeStanje numeric;
      nKarticaStanje numeric;
      cMsg varchar;

BEGIN

      nCount := 0;

      FOR rec_roba IN SELECT * from {{ item_prodavnica }}.roba
            ORDER BY id
      LOOP

        cIdRoba := rec_roba.id;
        nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba );
        nPosStanjeStanje := {{ item_prodavnica }}.pos_dostupno_artikal(cIdRoba ); -- raspolozivo_stanje prema pos stanje

        -- select prijem-povrat+ulaz_ostalo as ulaz, realizacija+izlaz_ostalo as izlaz, kalo,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) as knjig_stanje,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) - kalo as raspolozivo_stanje,
        --   round( vrijednost/(prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)), 4) as cijena from p4.pos_artikal_stanje( 'P47402', '1900-01-01', current_date );

        -- raspolozivo_stanje prema kartici
        EXECUTE  'SELECT prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)-kalo as raspolozivo_stanje from {{ item_prodavnica }}.pos_artikal_stanje( $1, $2, $3 )'
          USING cIdRoba, '1900-01-01'::date, current_date
          INTO nKarticaStanje;

        IF nPosStanjeStanje <> nKarticaStanje THEN
          EXECUTE 'SELECT {{ item_prodavnica }}.pos_prijem_update_stanje(''+'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
               USING cIdPos, '80', 'FIX_KART', 999, current_date, cIdRoba, nKarticaStanje - nPosStanjeStanje, nOsnovnaCijena, 0;

          cMsg := format('%s : cij: %s kartica stanje: %s, pos_stanje: %s, razlika: %s', cIdRoba, nOsnovnaCijena, nKarticaStanje, nPosStanjeStanje, nKarticaStanje - nPosStanjeStanje);
          PERFORM {{ item_prodavnica }}.logiraj( current_user::varchar, 'ERROR_FIX_POS_STANJE_KARTICA', cMsg);
          RAISE INFO 'ERROR_FIX_POS_STANJE_KARTICA: %', cMsg;

          nCount := nCount + 1;
        END IF;


      END LOOP;

      RETURN nCount;
END;
$$;



CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.error_pos_stanje_prema_kartica() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar DEFAULT '1 ';
      nCount integer;
      rec_roba RECORD;
      cIdRoba varchar;
      nKarticaCijena numeric;
      nOsnovnaCijena numeric;
      nPosStanjeStanje numeric;
      nKarticaStanje numeric;
      cMsg varchar;

BEGIN

      nCount := 0;

      FOR rec_roba IN SELECT * from {{ item_prodavnica }}.roba
            ORDER BY id
      LOOP

        cIdRoba := rec_roba.id;
        nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba );
        nPosStanjeStanje := {{ item_prodavnica }}.pos_dostupno_artikal( cIdRoba ); -- raspolozivo_stanje prema pos stanje

        -- select prijem-povrat+ulaz_ostalo as ulaz, realizacija+izlaz_ostalo as izlaz, kalo,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) as knjig_stanje,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) - kalo as raspolozivo_stanje,
        --   round( vrijednost/(prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)), 4) as cijena from p4.pos_artikal_stanje( 'P47402', '1900-01-01', current_date );

        -- raspolozivo_stanje prema pos kartici artikla
        EXECUTE  'SELECT prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) as knjig_stanje,' ||
           'case when (prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)) = 0 then 0 else round( vrijednost/(prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)), 4) end as cijena'
           ' FROM {{ item_prodavnica }}.pos_artikal_stanje( $1, $2, $3 )'

          USING cIdRoba, '1900-01-01'::date, current_date
          INTO nKarticaStanje, nKarticaCijena;

        IF nKarticaCijena<>0 AND nOsnovnaCijena <> nKarticaCijena THEN

          cMsg := format('%s : osnovna cijena: %s KARTICA knjig stanje: %s,  cijena: %s pos_stanje: %s', cIdRoba, nOsnovnaCijena, nKarticaStanje, nKarticaCijena, nPosStanjeStanje);
          RAISE INFO 'ERROR_POS_STANJE_KARTICA: %', cMsg;

          nCount := nCount + 1;
        END IF;


      END LOOP;

      RETURN nCount;
END;
$$;

-- select p2.gen_pocetno_stanje(); # -> nRbrErr - broj stavki sa errorom;

-- select * from public.pos_tmp;
-- stanje:
-- select * from public.pos_items_tmp;

-- stavke sa karticom van integriteta:
-- select * from pos_items_error_tmp; 


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.gen_pocetno_stanje() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
      cIdPos varchar DEFAULT '1 ';
      rec_roba RECORD;
      cIdRoba varchar;
      nKarticaCijena numeric;
      nOsnovnaCijena numeric;
      nPosStanjeStanje numeric;
      nKarticaStanje numeric;
      cMsg varchar;
      cBrDokNew varchar;
      dDatum date;
      uuidPos uuid;
      nRbr integer;
      nRbrErr integer;

BEGIN

      DROP TABLE IF EXISTS public.pos_tmp;
      DROP TABLE IF EXISTS public.pos_items_tmp;
      DROP TABLE IF EXISTS public.pos_items_error_tmp;
      CREATE TABLE public.pos_tmp AS TABLE {{ item_prodavnica }}.pos WITH NO DATA;
      CREATE TABLE public.pos_items_tmp AS TABLE {{ item_prodavnica }}.pos_items WITH NO DATA;
      CREATE TABLE public.pos_items_error_tmp AS TABLE {{ item_prodavnica }}.pos_items WITH NO DATA;

      -- now: 2020-01-02 => 2020-01-01
      -- SELECT date_trunc('MONTH',now())::DATE;
      dDatum :=  date_trunc('MONTH',now())::DATE;

      cBrDokNew := {{ item_prodavnica }}.pos_novi_broj_dokumenta(cIdPos, '02', dDatum);
      
      insert into public.pos_tmp(idPos,idVd,brDok,datum,dat_od,opis,korisnik)
                  values(cIdPos, '02', cBrDokNew, dDatum, dDatum, 'GEN pocetno stanje', current_user)
               RETURNING dok_id into uuidPos;

      nRbr := 0;
      nRbrErr := 0;

      FOR rec_roba IN SELECT * from {{ item_prodavnica }}.roba
            ORDER BY id
      LOOP

        cIdRoba := rec_roba.id;
        nOsnovnaCijena := {{ item_prodavnica }}.pos_dostupna_osnovna_cijena_za_artikal( cIdRoba );
        nPosStanjeStanje := {{ item_prodavnica }}.pos_dostupno_artikal( cIdRoba ); -- raspolozivo_stanje prema pos stanje

        -- select prijem-povrat+ulaz_ostalo as ulaz, realizacija+izlaz_ostalo as izlaz, kalo,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) as knjig_stanje,
        --   prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) - kalo as raspolozivo_stanje,
        --   round( vrijednost/(prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)), 4) as cijena from p4.pos_artikal_stanje( 'P47402', '1900-01-01', current_date );

        -- raspolozivo_stanje prema pos kartici artikla
        EXECUTE  'SELECT prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo) as knjig_stanje,' ||
           'case when (prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)) = 0 then 0 else round( vrijednost/(prijem-povrat+ulaz_ostalo-(realizacija+izlaz_ostalo)), 4) end as cijena'
           ' FROM {{ item_prodavnica }}.pos_artikal_stanje( $1, $2, $3 )'

         USING cIdRoba, '1900-01-01'::date, current_date
         INTO nKarticaStanje, nKarticaCijena;

         IF nKarticaCijena<>0 AND nOsnovnaCijena <> nKarticaCijena THEN
             nRbrErr := nRbrErr + 1;
             EXECUTE 'insert into public.pos_items_error_tmp(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                 using cIdPos, '02', cBrDokNew, dDatum, uuidPos, nRbrErr, cIdRoba, 
                       nKarticaStanje, nOsnovnaCijena, nKarticaCijena, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
 
            cMsg := format('%s : osnovna cijena: %s KARTICA knjig stanje: %s,  cijena: %s pos_stanje: %s', cIdRoba, nOsnovnaCijena, nKarticaStanje, nKarticaCijena, nPosStanjeStanje);
            RAISE INFO 'ERROR_POS_STANJE_KARTICA: %', cMsg;
         END IF;

         IF nKarticaStanje <> 0 THEN
            nRbr := nRbr + 1;
            EXECUTE 'insert into public.pos_items_tmp(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
                     using cIdPos, '02', cBrDokNew, dDatum, uuidPos, nRbr, cIdRoba, 
                       nKarticaStanje, nOsnovnaCijena, 0, rec_roba.naz, rec_roba.idtarifa, rec_roba.jmj;
         END IF;
      END LOOP;

      RETURN nRbrErr;
END;
$$;


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.import_pocetno_stanje() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
 
BEGIN
      INSERT INTO {{ item_prodavnica }}.pos_knjig(idPos,idVd,brDok,datum,dat_od,opis,korisnik)
           SELECT idPos,idVd,brDok,datum,dat_od,opis,korisnik
              FROM public.pos_tmp;

      INSERT INTO {{ item_prodavnica }}.pos_items_knjig(idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj)
           SELECT idPos,idVd,brDok,datum,dok_id,rbr,idRoba,kolicina,cijena,ncijena,robanaz,idtarifa,jmj
              FROM public.pos_items_tmp;

      RETURN 0;
END;
$$;


------  public.roba_tmp sadrzi barkodove

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.patch_barkod_by_roba_tmp() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   rec_roba RECORD;
   nCount integer;
   cBarKod varchar;
BEGIN

      nCount := 0;

      FOR rec_roba IN SELECT * from {{ item_prodavnica }}.roba
                        ORDER BY id
      LOOP
         -- p2.roba nema barkod
         IF rec_roba.barkod IS NULL THEN
            -- uzeti barkod iz roba_tmp

            SELECT barkod FROM public.roba_tmp WHERE id=rec_roba.id
                INTO cBarkod;
         
            -- update p2.roba
            UPDATE {{ item_prodavnica }}.roba SET barkod=cBarkod WHERE id=rec_roba.id;
            nCount := nCount + 1; 
         END IF;
      END LOOP;
  
      RETURN nCount;
END;
$$;


------  public.roba_tmp sadrzi barkodove

CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.patch_nepostojece_sifre_by_roba_tmp() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   rec_roba RECORD;
   nCount integer;
   cId varchar;
BEGIN

      nCount := 0;
      -- prodji kroz roba_tmp
      FOR rec_roba IN SELECT * from public.roba_tmp
                     ORDER BY id
      LOOP

         SELECT id FROM {{ item_prodavnica }}.roba WHERE id=rec_roba.id
                INTO cId;

         -- p2.roba nema ovog artikla, dodati ga iz roba_tmp
         IF cId IS NULL THEN
           INSERT INTO {{ item_prodavnica }}.roba(id, sifradob, naz, jmj, idtarifa, mpc, tip, opis, barkod, fisc_plu)
              VALUES( rec_roba.id, rec_roba.sifradob, rec_roba.naz, rec_roba.jmj, rec_roba.idtarifa, rec_roba.mpc, rec_roba.tip, rec_roba.opis, rec_roba.barkod, rec_roba.fisc_plu );
            nCount := nCount + 1; 
         END IF;
      END LOOP;
  
      RETURN nCount;
END;
$$;







