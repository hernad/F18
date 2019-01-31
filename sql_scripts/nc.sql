-- select (nv_u-nv_i)/(ulaz-izlaz) from sp_konto_stanje( 'm', rpad('1320', 7), rpad('TEST', 10), '2015-03-05');


-- drop FUNCTION konto_stanje( mag_prod varchar(1), param_konto varchar(7),  param_idroba varchar(10), param_datum date );
-- drop type ulaz_izlaz;

create type ulaz_izlaz as (ulaz double precision, izlaz double precision, nv_u double precision, nv_i double precision);

drop table IF EXISTS konto_roba_stanje;

CREATE TABLE konto_roba_stanje (
    idkonto     varchar(7),
    idroba      varchar(10),
    datum       date,
    tip         char(1),
    ulaz        double precision,
    izlaz       double precision,
    nv_u        double precision,
    nv_i        double precision,
    vpc         double precision,
    mpc_sa_pdv  double precision,
    primary key (datum, idkonto, idroba),
    CONSTRAINT mag_ili_prod CHECK (tip = 'm' OR tip = 'p')
);


ALTER TABLE konto_roba_stanje OWNER TO xtrole;

CREATE OR REPLACE FUNCTION sp_konto_stanje( mag_prod varchar(1), param_konto varchar(7),  param_idroba varchar(10), param_datum date )
  RETURNS  SETOF ulaz_izlaz AS $body$

DECLARE
  row RECORD;
  tek_godina integer;
  tek_mjesec integer;
  predhodni_datum date;
  predhodni_mjesec integer;
  predhodna_godina integer;
  table_name text := 'fmk.kalk_kalk';
  table_stanje_name text := 'konto_roba_stanje';
  nUlaz double precision := 0;
  nIzlaz double precision := 0;
  nNV_u  double precision := 0;
  nNV_i double precision := 0;
  row_ui ulaz_izlaz;
  datum_posljednje_stanje date := '1900-01-01';
BEGIN

FOR row IN
  EXECUTE 'SELECT * FROM '  || table_stanje_name || ' WHERE idkonto = '''  || param_konto ||
   ''' AND idroba = ''' || param_idroba  ||
   ''' AND datum=(SELECT max(datum) FROM ' || table_stanje_name ||
   ' WHERE idkonto = '''  || param_konto ||
   ''' AND idroba = ''' || param_idroba  || ''' AND datum<=''' || param_datum || ''')'
LOOP

datum_posljednje_stanje := row.datum;
-- RAISE NOTICE 'nasao stanje na datum: %', datum_posljednje_stanje;

nUlaz := coalesce(row.ulaz,0);
nIzlaz := coalesce(row.izlaz,0);
nNV_u := coalesce(row.nv_u,0);
nNV_i := coalesce(row.nv_i,0);


END LOOP;

predhodna_godina := 0;
predhodni_mjesec := 0;

FOR row IN
  EXECUTE 'SELECT datdok, pu_i, mu_i, nc, kolicina FROM '  || table_name || ' WHERE ' || mag_prod || 'konto = '''  || param_konto ||
  ''' AND idroba = ''' || param_idroba  || ''' AND datdok<=''' || param_datum || ''''
  ' AND datdok>''' || datum_posljednje_stanje || ''' order by datdok'
LOOP

tek_godina := date_part( 'year', row.datdok );
tek_mjesec := date_part( 'month', row.datdok );

-- kraj mjeseca
IF predhodna_godina > 0 AND ( (predhodna_godina < tek_godina) OR (predhodni_mjesec < tek_mjesec) ) THEN


--RAISE NOTICE 'konto: %, roba: %, predh dat: % datum: % predh kolicina: %, %', param_mkonto, param_idroba, predhodni_datum, row.datdok, nUlaz, nIzlaz;
INSERT INTO konto_roba_stanje(idkonto, idroba, datum, tip, ulaz, izlaz, nv_u, nv_i)
VALUES( param_konto,  param_idroba, predhodni_datum, mag_prod, nUlaz, nIzlaz, nNV_u, nNV_i );

END IF;


IF (( mag_prod = 'm' AND row.mu_i = '1') OR ( mag_prod = 'p' AND row.pu_i = '1') ) THEN
  nUlaz := nUlaz + coalesce(row.kolicina, 0);
  nNV_u := nNV_u + coalesce(row.kolicina, 0) * coalesce(row.nc, 0) ;
ELSIF (( mag_prod = 'm' AND row.mu_i = '5') OR ( mag_prod = 'p' AND row.pu_i = '5') ) THEN
  nIzlaz := nIzlaz + coalesce(row.kolicina, 0);
  nNV_i := nNV_i + coalesce(row.kolicina, 0) * coalesce(row.nc, 0) ;
END IF;

predhodna_godina := tek_godina;
predhodni_mjesec := tek_mjesec;
predhodni_datum := row.datdok;

-- RAISE NOTICE 'datum: % kolicina: %, %', row.datdok, nUlaz, nIzlaz;
END LOOP;

row_ui.ulaz := nUlaz;
row_ui.izlaz := nIzlaz;
row_ui.nv_u := nNV_u;
row_ui.nv_i := nNV_i;

RETURN next row_ui;
RETURN;

END
$body$
LANGUAGE plpgsql;


-------

CREATE OR REPLACE FUNCTION cleanup_konto_roba_stanje()
  RETURNS TRIGGER AS $$

DECLARE
  datum_limit date := '1900-01-01';
  mkonto varchar(7);
  pkonto varchar(7);
  mkonto_old varchar(7);
  pkonto_old varchar(7);
  return_rec RECORD;

BEGIN

--RAISE NOTICE 'TG_OP: %', TG_OP;

IF TG_OP = 'INSERT' THEN
  -- sve stavke u konto_roba_stanje koje imaju datum >= od ovoga
  -- vise nisu validne
  RAISE NOTICE 'NEW: %', NEW;
  datum_limit := NEW.datdok;
  pkonto := NEW.pkonto;
  mkonto := NEW.mkonto;
  pkonto_old := 'XX';
  mkonto_old := 'XX';
  return_rec := NEW;
ELSE
  IF TG_OP = 'DELETE' THEN
     datum_limit := OLD.datdok;
     mkonto := 'XX';
     pkonto := 'XX';
     mkonto_old := OLD.mkonto;
     pkonto_old := OLD.pkonto;
     -- RAISE NOTICE 'DELETE: %', OLD;
     return_rec := OLD;
  ELSE
     datum_limit := MIN( OLD.datdok, NEW.datdok );
     mkonto := NEW.mkonto;
     pkonto := NEW.pkonto;
     mkonto_old := OLD.mkonto;
     pkonto_old := OLD.pkonto;
     -- RAISE NOTICE 'UPDATE: %', NEW;
     return_rec := NEW;
  END IF;
END IF;


-- sve datume koji su veci i koji pripadaju istom mjesecu kao datum koji se brise

-- ako imam sljedece stavke na kartici artikla/konta:
-- 21.01.2015 100, stanje 100
-- 15.02.2015 100, stanje 200
-- 10.03.2015 200, stanje 400
-- u konto_roba_stanje imaju dvije stavke: 21.01.2015/100 kom, 15.02.2015/200 kom
-- Ako na to stanje dodam stavku 25.01.2015/50 kom
-- treba u izbrisati konto_roba_stanje sve > od 25.01.2015 ali i sve stavke iz januara 2015

EXECUTE 'DELETE from konto_roba_stanje WHERE (datum>=$1 OR (date_part( ''year'', datum)=date_part( ''year'', $1) AND date_part( ''month'', datum)=date_part( ''month'', $1)))  AND idkonto in ($2, $3, $4, $5)'
  USING datum_limit, mkonto, pkonto, mkonto_old, pkonto_old;


RETURN return_rec;

EXCEPTION when others then
    raise exception 'Error u trigeru: % : %', SQLERRM, SQLSTATE;
end;
$$ LANGUAGE plpgsql;


DROP TRIGGER trig_cleanup_konto_roba_stanje on fmk.kalk_kalk;

CREATE TRIGGER trig_cleanup_konto_roba_stanje
  BEFORE INSERT OR UPDATE OR DELETE ON fmk.kalk_kalk
    FOR EACH ROW
      EXECUTE PROCEDURE cleanup_konto_roba_stanje();
