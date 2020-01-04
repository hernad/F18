
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


------------------ CREATE TABLES --------------------------------------------


CREATE TABLE IF NOT EXISTS fmk.fakt_doks (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    partner character varying(200),
    datdok date,
    dindem character(3),
    iznos numeric(12,3),
    rabat numeric(12,3),
    rezerv character(1),
    m1 character(1),
    idpartner character(6),
    sifra character(6),
    brisano character(1),
    idvrstep character(2),
    datpl date,
    idpm character(15),
    oper_id integer,
    fisc_rn numeric(10,0),
    dat_isp date,
    dat_otpr date,
    dat_val date,
    fisc_st numeric(10,0),
    fisc_time character(10),
    fisc_date date,
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);

ALTER TABLE fmk.fakt_doks OWNER TO admin;

--
-- Name: fakt_doks2; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_doks2 (
    idfirma character(2),
    idtipdok character(2),
    brdok character varying(12),
    k1 character(15),
    k2 character(15),
    k3 character(15),
    k4 character(20),
    k5 character(20),
    n1 numeric(15,2),
    n2 numeric(15,2)
);

ALTER TABLE fmk.fakt_doks2 OWNER TO admin;

CREATE TABLE IF NOT EXISTS fmk.fakt_fakt (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    idpartner character(6),
    dindem character(3),
    zaokr numeric(1,0),
    rbr character(3) NOT NULL,
    podbr character(2),
    idroba character(10),
    serbr character(15),
    kolicina numeric(14,5),
    cijena numeric(14,5),
    rabat numeric(8,5),
    porez numeric(9,5),
    txt text,
    k1 character(4),
    k2 character(4),
    m1 character(1),
    brisano character(1),
    idroba_j character(10),
    idvrstep character(2),
    idpm character(15),
    c1 character(20),
    c2 character(20),
    c3 character(20),
    n1 numeric(10,3),
    n2 numeric(10,3),
    idrelac character(4)
);
ALTER TABLE fmk.fakt_fakt OWNER TO admin;

CREATE TABLE IF NOT EXISTS fmk.fakt_fakt_atributi (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character(12) NOT NULL,
    rbr character(3) NOT NULL,
    atribut character(50) NOT NULL,
    value character varying
);

ALTER TABLE fmk.fakt_fakt_atributi OWNER TO admin;

--
-- Name: fakt_ftxt; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_ftxt (
    id character(2),
    match_code character(10),
    naz character varying
);

ALTER TABLE fmk.fakt_ftxt OWNER TO admin;

--
-- Name: fakt_gen_ug; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_gen_ug (
    dat_obr date,
    dat_gen date,
    dat_u_fin date,
    kto_kup character(7),
    kto_dob character(7),
    opis character(100),
    brdok_od character(8),
    brdok_do character(8),
    fakt_br numeric(5,0),
    saldo numeric(15,5),
    saldo_pdv numeric(15,5),
    brisano character(1),
    dat_val date
);

ALTER TABLE fmk.fakt_gen_ug OWNER TO admin;

--
-- Name: fakt_gen_ug_p; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_gen_ug_p (
    dat_obr date,
    idpartner character(6),
    id_ugov character(10),
    saldo_kup numeric(15,5),
    saldo_dob numeric(15,5),
    d_p_upl_ku date,
    d_p_prom_k date,
    d_p_prom_d date,
    f_iznos numeric(15,5),
    f_iznos_pd numeric(15,5)
);

ALTER TABLE fmk.fakt_gen_ug_p OWNER TO admin;

--
-- Name: fakt_objekti; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_objekti (
    id character(10),
    naz character varying(100)
);

ALTER TABLE fmk.fakt_objekti OWNER TO admin;

--
-- Name: fakt_rugov; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_rugov (
    id character(10),
    idroba character(10),
    kolicina numeric(15,4),
    rabat numeric(6,3),
    porez numeric(5,2),
    k1 character(1),
    k2 character(2),
    dest character(6),
    cijena numeric(15,3)
);


ALTER TABLE fmk.fakt_rugov OWNER TO admin;

--
-- Name: fakt_ugov; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_ugov (
    id character(10) NOT NULL,
    datod date,
    idpartner character(6),
    datdo date,
    vrsta character(1),
    idtipdok character(2),
    naz character(20),
    aktivan character(1),
    dindem character(3),
    idtxt character(2),
    zaokr numeric(1,0),
    lab_prn character(1),
    iddodtxt character(2),
    a1 numeric(12,2),
    a2 numeric(12,2),
    b1 numeric(12,2),
    b2 numeric(12,2),
    txt2 character(2),
    txt3 character(2),
    txt4 character(2),
    f_nivo character(1),
    f_p_d_nivo numeric(5,0),
    dat_l_fakt date,
    def_dest character(6)
);

ALTER TABLE fmk.fakt_ugov OWNER TO admin;

--
-- Name: fakt_upl; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE IF NOT EXISTS fmk.fakt_upl (
    datupl date,
    idpartner character(6),
    opis character(100),
    iznos numeric(12,2)
);

ALTER TABLE fmk.fakt_upl OWNER TO admin;
