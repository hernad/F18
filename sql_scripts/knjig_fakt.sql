
DO $$ BEGIN

CREATE TYPE my_type AS (/* fields go here */);

CREATE TYPE public.ulaz_izlaz AS (
	ulaz double precision,
	izlaz double precision,
	nv_u double precision,
	nv_i double precision
);

ALTER TYPE public.ulaz_izlaz OWNER TO admin;

CREATE TYPE public.t_dugovanje AS (
	konto_id character varying,
	partner_naz character varying,
	referent_naz character varying,
	partner_id character varying,
	i_pocstanje numeric(16,2),
	i_dospjelo numeric(16,2),
	i_nedospjelo numeric(16,2),
	i_ukupno numeric(16,2),
	valuta date,
	rok_pl integer
);

ALTER TYPE public.t_dugovanje OWNER TO admin;

EXCEPTION
    WHEN duplicate_object THEN null;
END $$;




--
-- Name: konto_roba_stanje; Type: TABLE; Schema: public; Owner: xtrole
--

--   idkonto     idroba   datum       tip     ulaz     izlaz   nv_u    nv_i   vpc   mpc_sa_pdv
--    13322       R01      01.02.19    p       10         3      9      2.7    1.5      2
--
--
CREATE TABLE IF NOT EXISTS public.konto_roba_stanje (
    idkonto character varying(7) NOT NULL,
    idroba character varying(10) NOT NULL,
    datum date NOT NULL,
    tip character(1),
    ulaz double precision,
    izlaz double precision,
    nv_u double precision,
    nv_i double precision,
    vpc double precision,
    mpc_sa_pdv double precision,
    CONSTRAINT mag_ili_prod CHECK (((tip = 'm'::bpchar) OR (tip = 'p'::bpchar)))
);


ALTER TABLE public.konto_roba_stanje OWNER TO xtrole;

--
-- Name: cleanup_konto_roba_stanje(); Type: FUNCTION; Schema: public; Owner: admin
--
CREATE OR REPLACE FUNCTION public.cleanup_konto_roba_stanje() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$

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
  -- RAISE NOTICE 'NEW: %', NEW;
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
     datum_limit := OLD.datdok;  -- umjesto min funkcije
     IF NEW.datdok < datum_limit  THEN
        datum_limit := NEW.datdok;
     END IF;

     mkonto := NEW.mkonto;
     pkonto := NEW.pkonto;
     mkonto_old := OLD.mkonto;
     pkonto_old := OLD.pkonto;
     -- RAISE NOTICE 'UPDATE: %', NEW;
     return_rec := NEW;
  END IF;
END IF;


-- sve datume koji su veci i koji pripadaju istom mjesecu kao datum koji se brise

-- ako imamo sljedece stavke na kartici artikla/konta:
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
$_$;


ALTER FUNCTION public.cleanup_konto_roba_stanje() OWNER TO admin;


-- CREATE TRIGGER trig_cleanup_konto_roba_stanje BEFORE INSERT OR DELETE OR UPDATE ON fmk.kalk_kalk
--   FOR EACH ROW EXECUTE PROCEDURE public.cleanup_konto_roba_stanje();


--
-- Name: sp_konto_stanje(character varying, character varying, character varying, date); Type: FUNCTION; Schema: public; Owner: admin
--
CREATE OR REPLACE FUNCTION public.sp_konto_stanje(mag_prod character varying, param_konto character varying, param_idroba character varying, param_datum date) RETURNS SETOF public.ulaz_izlaz
    LANGUAGE plpgsql
    AS $$

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
$$;


ALTER FUNCTION public.sp_konto_stanje(mag_prod character varying, param_konto character varying, param_idroba character varying, param_datum date) OWNER TO admin;

