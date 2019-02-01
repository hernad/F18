--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.5


--
-- Name: ulaz_izlaz; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.ulaz_izlaz AS (
	ulaz double precision,
	izlaz double precision,
	nv_u double precision,
	nv_i double precision
);


ALTER TYPE public.ulaz_izlaz OWNER TO admin;



--
-- Name: cleanup_konto_roba_stanje(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.cleanup_konto_roba_stanje() RETURNS trigger
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


CREATE FUNCTION public.fakt_dokument_promijeni_datum(param_firma character varying, param_tip character varying, param_brdok character varying, param_datum_stari date, param_datum_novi date, param_datum_otpremnica_novi date, param_datum_valuta_novi date) RETURNS integer[]
    LANGUAGE plpgsql
    AS $_$

DECLARE
   row RECORD;
   fakt_table_name text := 'fmk.fakt_fakt';
   fakt_doks_table_name text := 'fmk.fakt_doks';
   cWhere text ;
   nCntFakt integer;
   nCntFaktDoks integer;
   aTxt text[];
   cElement text;
   cTxt text := '';
   nTxt int := 0;
   nArrLength int;
   cXml text := '';
   nBrDokLen int := 12;

BEGIN

cWhere := ' WHERE idTipDok = ''' || param_tip || ''' AND idFirma = ''' || param_firma ||
     ''' AND brDok =''' || rpad( param_brdok, nBrDokLen)  ||  ''' AND datDok =''' || param_datum_stari || ''' ';

RAISE NOTICE 'WHERE Izraz: %', cWhere;
RAISE NOTICE 'radna jedinica % / tip dokumenta: % / broj dokumenta % / stari-postojeci datum: % ', param_firma, param_tip, param_brdok, param_datum_stari;

FOR row IN
  EXECUTE 'SELECT count(*) AS cnt FROM ' || fakt_table_name || cWhere
LOOP

nCntFakt := row.cnt;
-- RAISE NOTICE 'nasao fakt stavke na datum: %', nCntFakt;
END LOOP;

RAISE NOTICE 'get podaci pohranjeni u rbr=1';
FOR row IN
  EXECUTE 'SELECT txt FROM ' || fakt_table_name || cWhere || ' AND rbr=lpad(''1'', 3)'
LOOP

   aTxt := regexp_split_to_array(  row.txt,  '\x11' ) ;
   nArrLength := array_length( aTxt, 1)  - 1;
   --RAISE NOTICE 'nasao u rbr=1 matricu od : %',  array_length( aTxt, 1);
   cTxt := '';

   -- prvi elemenat preskociti
   FOR nTxt IN 1 .. nArrLength
   LOOP
     cElement := regexp_replace( aTxt[ nTxt ], E'\\x10', '');
     cElement := regexp_replace( cElement, E'\\x11', '');

     IF (nTxt = 7) THEN
        cElement := to_char( param_datum_otpremnica_novi, 'DD.MM.YY');
     END IF;

     IF (nTxt = 9) THEN
        cElement := to_char( param_datum_valuta_novi, 'DD.MM.YY');
     END IF;

     IF NOT ( cElement ~ '^<memo>' ) THEN
       -- cXml := concat( cXml, '<item>', cElement, '</item>' );
       cElement := concat( chr(16), cElement, chr(17) ); 
       cTxt := concat( cTxt, cElement );
     END IF;

   END LOOP;

   -- cXml := concat( '<memo>', cXml, '</memo>');
   -- cTxt := concat( cTxt, chr(16), cXml, chr(17) ); 
   --RAISE NOTICE 'cTxt = %',  cTxt;

END LOOP;
-- end rbr=1

FOR row IN
  EXECUTE 'SELECT count(*) AS cnt FROM ' || fakt_doks_table_name || cWhere
LOOP
 nCntFaktDoks := row.cnt;
 -- RAISE NOTICE 'nasao fakt dokumente %', nCntFaktDoks;
END LOOP;

EXECUTE 'UPDATE ' || fakt_table_name || ' set datdok = $1'  || cWhere
 USING param_datum_novi;

EXECUTE 'UPDATE ' || fakt_table_name || ' set  txt = $1'  || cWhere || ' AND rbr=lpad(''1'', 3)'
 USING cTxt;

EXECUTE 'UPDATE ' || fakt_doks_table_name || ' set datdok = $1' || cWhere 
USING param_datum_novi;

--PERFORM pg_sleep(4);

RETURN Array[ nCntFakt, nCntFaktDoks, nArrLength ];

END

$_$;


ALTER FUNCTION public.fakt_dokument_promijeni_datum(param_firma character varying, param_tip character varying, param_brdok character varying, param_datum_stari date, param_datum_novi date, param_datum_otpremnica_novi date, param_datum_valuta_novi date) OWNER TO xtrole;

--
-- Name: fakt_faktura_stavke(text, text); Type: FUNCTION; Schema: public; Owner: hernad
--

CREATE FUNCTION public.fakt_faktura_stavke(param_idfirma text, param_brdok text) RETURNS TABLE(datum date, idpartner character varying, partner character varying, kolicina real, porez real, rabat real, cijena real)
    LANGUAGE plpgsql
    AS $$ 
    BEGIN
    RETURN QUERY SELECT
       fmk.fakt_doks.datdok::date, fmk.fakt_doks.idpartner::varchar, fmk.fakt_doks.partner::varchar, 
       fmk.fakt_fakt.kolicina::real, fmk.fakt_fakt.porez::real, fmk.fakt_fakt.rabat::real, fmk.fakt_fakt.cijena::real 
    FROM fmk.fakt_fakt inner join fmk.fakt_doks on 
( fmk.fakt_fakt.idfirma=fmk.fakt_doks.idfirma and fmk.fakt_fakt.idtipdok=fmk.fakt_doks.idtipdok and fmk.fakt_fakt.brdok=fmk.fakt_doks.brdok)
    where fmk.fakt_doks.idfirma = param_idfirma and fmk.fakt_doks.brdok = rpad(param_brdok, 12) and fmk.fakt_doks.idtipdok='10';
    END;
    $$;


ALTER FUNCTION public.fakt_faktura_stavke(param_idfirma text, param_brdok text) OWNER TO hernad;

--
-- Name: fakt_get_datumi(character varying, character varying); Type: FUNCTION; Schema: public; Owner: hernad
--

CREATE FUNCTION public.fakt_get_datumi(param_tip character varying, param_brdok character varying) RETURNS date[]
    LANGUAGE plpgsql
    AS $$

DECLARE
   row RECORD;
   fakt_table_name text := 'fmk.fakt_fakt';
   cWhere text ;
   aTxt text[];
   nArrLength integer;
   nTxt integer;
   dDatDok date;
   dDatOtpr date;
   dDatVal date;
   cElement text;

BEGIN

cWhere := ' WHERE idTipDok = ''' || param_tip || ''' AND brDok =' || ' ''' || rpad( param_brdok, 12)  ||  ''' ';

FOR row IN
  EXECUTE 'SELECT datdok, txt FROM ' || fakt_table_name || cWhere || ' AND rbr=lpad(''1'', 3)'
LOOP

   dDatDok := row.datdok;
   aTxt := regexp_split_to_array(  row.txt,  '\x11' ) ;
   nArrLength := array_length( aTxt, 1) - 1;
   RAISE NOTICE 'nasao u rbr=1 matricu od : %',  array_length( aTxt, 1);

   FOR nTxt IN 2 .. nArrLength
   LOOP

     cElement := regexp_replace( aTxt[ nTxt ], E'\\x10', '');
     cElement := regexp_replace( cElement, E'\\x11', '');

     --RAISE NOTICE 'Element %: %', nTxt, cElement;

     IF (nTxt = 7) THEN
        IF ( cElement ~ '\d+\.\d+\.\d+' ) THEN
          dDatOtpr := to_date( cElement, 'DD.MM.YY');
        ELSE
          dDatOtpr := '1900-01-01'::date;
        END IF;
     END IF;

     IF (nTxt = 9 ) THEN
        IF ( cElement ~ '\d+\.\d+\.\d+' ) THEN
          dDatVal := to_date( cElement, 'DD.MM.YY');
        ELSE
          dDatVal := '1900-01-01'::date;
        END IF;
     END IF;

   END LOOP;

END LOOP;

--PERFORM pg_sleep( 5 );

RETURN Array [ dDatDok, dDatOtpr, dDatVal ];

END

$$;


ALTER FUNCTION public.fakt_get_datumi(param_tip character varying, param_brdok character varying) OWNER TO hernad;

--
-- Name: get_sifk(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.get_sifk(param_id character varying, param_oznaka character varying, param_sif character varying, OUT vrijednost text) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE
  row RECORD;
  table_name text := 'fmk.sifv';
BEGIN

vrijednost := '';

FOR row IN
  EXECUTE 'SELECT naz FROM '  || table_name || ' WHERE id = '''  || param_id ||
   ''' AND oznaka = ''' || param_oznaka || ''' AND idsif = ''' || param_sif || ''' ORDER by naz'
LOOP

vrijednost := vrijednost || row.naz;
END LOOP;

END
$$;


ALTER FUNCTION public.get_sifk(param_id character varying, param_oznaka character varying, param_sif character varying, OUT vrijednost text) OWNER TO admin;


CREATE FUNCTION public.on_suban_insert_update_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

        IF (TG_OP = 'DELETE') THEN
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            PERFORM zatvori_otvst( NEW.IdKonto, NEW.IdPartner, NEW.BrDok );
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$$;


ALTER FUNCTION public.on_suban_insert_update_delete() OWNER TO admin;



--
-- Name: t_dugovanje; Type: TYPE; Schema: public; Owner: admin
--

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



--
-- Name: convert_to_integer(text); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.convert_to_integer(v_input text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_int_value INTEGER DEFAULT 0;
BEGIN
    BEGIN
        v_int_value := v_input::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid integer value: "%".  Returning 0.', v_input;
        RETURN 0;
    END;
RETURN v_int_value;
END;
$$;


ALTER FUNCTION public.convert_to_integer(v_input text) OWNER TO admin;


--
-- Name: sp_dugovanja(date, date, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sp_dugovanja(date, date, character varying, character varying) RETURNS SETOF public.t_dugovanje
    LANGUAGE sql
    AS $_$
SELECT idkonto::varchar as konto_id, partn.naz::varchar as partner_naz, refer.naz::varchar as referent_naz, idpartner::varchar as partner_id,
pocstanje::numeric(16,2) as i_pocstanje, dospjelo::numeric(16,2) as i_dospjelo,
nedospjelo::numeric(16,2) as i_nedospjelo,
(dospjelo+nedospjelo+pocstanje)::numeric(16,2) as i_ukupno, valuta,
 convert_to_integer(get_sifk( 'PARTN', 'ROKP', idpartner  )) AS rok_pl  from
(
select idkonto, idpartner, (dug_0.sp_duguje_stanje_2).*  from
(
   SELECT  idkonto, idpartner, sp_duguje_stanje_2( kto_partner.idkonto, kto_partner.idpartner, $1, $2)  FROM
     (select  distinct on (idkonto, idpartner) idkonto, idpartner
      from fmk.fin_suban where  trim(idpartner)<>'' and trim(idkonto) LIKE $3 and trim(idpartner) LIKE $4
      order by idkonto, idpartner) as kto_partner
) as dug_0
) as dugovanja
LEFT JOIN fmk.partn ON partn.id=dugovanja.idpartner
LEFT OUTER JOIN fmk.refer ON (partn.idrefer = refer.id);
$_$;


ALTER FUNCTION public.sp_dugovanja(date, date, character varying, character varying) OWNER TO admin;

--
-- Name: sp_duguje_stanje(character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sp_duguje_stanje(param_konto character varying, param_partner character varying, OUT dospjelo double precision, OUT nedospjelo double precision, OUT valuta date) RETURNS record
    LANGUAGE plpgsql
    AS $$

DECLARE
  row RECORD;
  table_name text := 'fmk.fin_suban';
  nCnt integer := 0;
  nDospjelo double precision := 0;
  nNeDospjelo double precision := 0;
  dValuta date := '1900-01-01';
BEGIN

nDospjelo := 0;
nNeDospjelo := 0;
nCnt := 0;
--RAISE NOTICE 'start param_konto, param_partner: % %', param_konto, param_partner;
--PERFORM pg_sleep(1);

FOR row IN
  EXECUTE 'SELECT iznosbhd, datval,datdok,d_p, otvst FROM '  || table_name || ' WHERE idkonto = '''  || param_konto ||
   ''' AND idpartner = ''' || param_partner || ''' ORDER BY idfirma,idkonto,idpartner,brdok,datdok'
LOOP

IF (row.d_p = '1') THEN

  IF COALESCE( row.datval, row.datdok ) > now()  THEN -- nije dospijelo
     nNeDospjelo := nNeDospjelo + row.iznosbhd;
     IF COALESCE(row.datval, row.datdok) > dValuta THEN
        dValuta :=  COALESCE(row.datval, row.datdok);
     END IF;

  ELSE
     nDospjelo := nDospjelo + row.iznosbhd;
     IF extract( year from dValuta) < 1990 THEN
        dValuta := COALESCE( row.datval, row.datdok );
     END IF;
  END IF;

END IF;

IF (row.d_p = '2') THEN  -- uplata
  nDospjelo := nDospjelo - row.iznosbhd;
  --- dValuta := row.datval
END IF;

nCnt := nCnt + 1;

END LOOP;

dospjelo := nDospjelo;
nedospjelo := nNeDospjelo;
valuta := dValuta;
END
$$;


ALTER FUNCTION public.sp_duguje_stanje(param_konto character varying, param_partner character varying, OUT dospjelo double precision, OUT nedospjelo double precision, OUT valuta date) OWNER TO admin;

--
-- Name: sp_duguje_stanje_2(character varying, character varying, date, date); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sp_duguje_stanje_2(param_konto character varying, param_partner character varying, param_dat_od date, param_dat_do date, OUT pocstanje double precision, OUT dospjelo double precision, OUT nedospjelo double precision, OUT valuta date) RETURNS record
    LANGUAGE plpgsql
    AS $$

DECLARE
  row RECORD;
  table_name text := 'fmk.fin_suban';
  nCnt integer := 0;
  --nPocStanje double precision;
  nDospjelo double precision;
  nNeDospjelo double precision;
  nStanjePredhodno double precision := 0;
  dValuta date;
  dRowValuta date;
  nRowIznos double precision;
BEGIN

--nPocStanje := 0;
nDospjelo := 0;
nNeDospjelo := 0;

-- dValuta := (EXTRACT(YEAR FROM param_dat_do::date)::text || '-12-31')::date;  -- krecemo od datuma 31.12.2016
dValuta := param_dat_do::date + 200;  -- krecemo od datuma do + 200 dana

nCnt := 0;
--RAISE NOTICE 'start param_konto, param_partner: % %', param_konto, param_partner;
--PERFORM pg_sleep(1);

-- suma zatvorenih stavki - ako je ovo lose uradjeno, neka taj saldo bude pocetna vrijednost dospjelih potrazivanja
--select sum(CASE WHEN d_p='1' THEN iznosbhd ELSE -iznosbhd END) INTO row FROM fmk.fin_suban where otvst='9' and idpartner like '102125%'
EXECUTE 'SELECT sum(CASE WHEN d_p=''1'' THEN iznosbhd ELSE -iznosbhd END) FROM '  || table_name || ' WHERE idkonto = '''  || param_konto ||
   ''' AND idpartner = ''' || param_partner || ''' AND datdok BETWEEN ''' || param_dat_od ||
   ''' AND '''  || param_dat_do || ''' and otvst=''9''' INTO row;

nDospjelo := COALESCE( row.sum, 0);
--RAISE NOTICE 'suma zatvorenih stavki %', row.sum;

-- suma negativnih stavki storno duguje koje su dospjele na dan
EXECUTE 'SELECT sum(CASE WHEN d_p=''1'' THEN iznosbhd ELSE -iznosbhd END) FROM '  || table_name || ' WHERE idkonto = '''  || param_konto ||
   ''' AND idpartner = ''' || param_partner || ''' AND datdok BETWEEN ''' || param_dat_od ||
   ''' AND '''  || param_dat_do
   || ''' AND (d_p=''1'' AND iznosbhd<0) AND coalesce(datval,datdok)<='''
   || param_dat_do || ''' AND otvst='' ''' INTO row;
nDospjelo := nDospjelo + COALESCE( row.sum, 0);
--RAISE NOTICE 'suma negativnih stavki dospjelo % na dan %', row.sum, param_dat_do;

FOR row IN
  -- sve stavke osim storno duguju koje su vec obuhvacene: AND NOT (d_p=''1'' AND iznosbhd<0) AND COALESCE(datval,datdok)<= ...)
  EXECUTE 'SELECT iznosbhd,datval,datdok,d_p,idvn,otvst,brdok FROM '  || table_name || ' WHERE idkonto = '''  || param_konto ||
   ''' AND idpartner = ''' || param_partner || ''' AND datdok BETWEEN ''' || param_dat_od ||
   ''' AND '''  || param_dat_do || ''' AND NOT ((d_p=''1'' AND iznosbhd<0) AND COALESCE(datval,datdok)<=''' || param_dat_do || ''') AND otvst='' '' ORDER BY idfirma,idkonto,idpartner,datdok,brdok'
LOOP

nCnt := nCnt + 1;
--RAISE NOTICE 'start cnt: % datval, datdok: % %, % / % / %', nCnt, row.datdok, row.datval, row.otvst, row.d_p, row.iznosbhd;

dRowValuta := COALESCE(row.datval, row.datdok);
nRowIznos := COALESCE(row.iznosbhd, 0);

IF (row.d_p = '1') THEN

   IF (nRowIznos > 0) AND (dValuta > dRowValuta) THEN
        --RAISE NOTICE 'set valuta prve otvorene stavke - otvorene stavke sa najnizim datumom set valuta: % tekuca valuta: %', dValuta, dRowValuta;
        dValuta :=  dRowValuta;
   END IF;

  IF dRowValuta > param_dat_do  THEN -- nije dospijelo do dat_do
     nNeDospjelo := nNeDospjelo + nRowIznos;
  ELSE
     nDospjelo := nDospjelo + nRowIznos;
  END IF;

ELSE
  --IF (row.d_p = '2') THEN  -- potrazuje -> uplata, ili storno izlaza
  IF dRowValuta > param_dat_do  THEN
     nNeDospjelo := nNeDospjelo - nRowIznos;
  ELSE
     nDospjelo := nDospjelo - nRowIznos;
  END IF;

END IF;

IF ( nStanjePredhodno < 0) AND (dValuta < dRowValuta)  THEN
   -- u predhodnoj stavci saldo dospjelo je bio u minusu, znaci kupac u avansu gledajuci dospjele obaveze
   -- zato pomjeri datum valute nagore
   --RAISE NOTICE 'u predhodnoj stavci je saldo bio u minusu postavljam valutu %', dRowValuta;

   dValuta :=  dRowValuta;
END IF;

--RAISE NOTICE 'dospjelo: brdok % datdok % dospjelo %  stanje predhodno % valuta  % row-valuta %', row.brdok, row.datdok, nDospjelo, nStanjePredhodno, dValuta, dRowValuta;
nStanjePredhodno := nDospjelo + nNedospjelo;

END LOOP;

IF nDospjelo < 0 THEN
   -- Kada je dospjeli dug negativan, iznos minusa dospjelog duga u minusu oduzeti od nedospjelog
   -- kako bi bio jednak  Ukupnom
   nNedospjelo := nNedospjelo + nDospjelo;
   nDospjelo := 0;
END IF;

pocstanje := 0;
dospjelo := nDospjelo;
nedospjelo := nNeDospjelo;
valuta := dValuta;
END
$$;


ALTER FUNCTION public.sp_duguje_stanje_2(param_konto character varying, param_partner character varying, param_dat_od date, param_dat_do date, OUT pocstanje double precision, OUT dospjelo double precision, OUT nedospjelo double precision, OUT valuta date) OWNER TO admin;

--
-- Name: sp_konto_stanje(character varying, character varying, character varying, date); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.sp_konto_stanje(mag_prod character varying, param_konto character varying, param_idroba character varying, param_datum date) RETURNS SETOF public.ulaz_izlaz
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


--
-- Name: zatvori_otvst(text, text, text); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.zatvori_otvst(cidkonto text, cidpartner text, cbrdok text) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE

row record;
nCnt integer := 0;
nSaldo numeric(16,2) := 0;
cWhere text;

BEGIN

cIdKonto := TRIM( cIdKonto );
cIdPartner := TRIM( cIdPartner );
cBrDok := TRIM( cBrDok );
cWhere := 'trim(idkonto)=''' || cIdKonto || ''' and trim(idpartner)=''' || cIdPartner || ''' and trim(brdok)=''' || cBrDok || ''' ';

IF cBrdok = '' THEN
   RETURN 0;
END IF;

FOR row IN
      EXECUTE 'select * from fmk.fin_suban where ' || cWhere
LOOP
      nCnt := nCnt + 1;
      --RAISE NOTICE '% - % - % / % / % / % / %', row.idkonto, row.idpartner, row.rbr, row.brdok, row.otvst, row.iznosbhd, row.d_p;

      IF row.d_p = '1' THEN
          nSaldo := nSaldo + row.iznosbhd;
      ELSE
          nSaldo := nSaldo - row.iznosbhd;
      END IF;

END LOOP;

IF nSaldo = 0 THEN
   EXECUTE 'update fmk.fin_suban set otvst=''9'' WHERE ' || cWhere;
   nCnt := nCnt + 10000;
END IF;

RETURN nCnt;
END;
$$;


ALTER FUNCTION public.zatvori_otvst(cidkonto text, cidpartner text, cbrdok text) OWNER TO admin;

--
-- Name: accnt_accnt_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

--
-- Name: konto_roba_stanje; Type: TABLE; Schema: public; Owner: xtrole
--

CREATE TABLE public.konto_roba_stanje (
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.schema_migrations (
    version integer NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO admin;



--
-- Name: usrpref; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.usrpref (
    usrpref_id integer DEFAULT nextval(('usrpref_usrpref_id_seq'::text)::regclass) NOT NULL,
    usrpref_name text,
    usrpref_value text,
    usrpref_username text
);


ALTER TABLE public.usrpref OWNER TO admin;

--
-- Name: TABLE usrpref; Type: COMMENT; Schema: public; Owner: admin
--

COMMENT ON TABLE public.usrpref IS 'User Preferences information';


--
-- Name: usr; Type: VIEW; Schema: public; Owner: admin
--

CREATE VIEW public.usr AS
 SELECT (pg_user.usesysid)::integer AS usr_id,
    (pg_user.usename)::text AS usr_username,
    COALESCE(( SELECT usrpref.usrpref_value
           FROM public.usrpref
          WHERE ((usrpref.usrpref_username = (pg_user.usename)::text) AND (usrpref.usrpref_name = 'propername'::text))), ''::text) AS usr_propername,
    NULL::text AS usr_passwd,
    0::integer AS usr_locale_id,
    COALESCE(( SELECT usrpref.usrpref_value
           FROM public.usrpref
          WHERE ((usrpref.usrpref_username = (pg_user.usename)::text) AND (usrpref.usrpref_name = 'initials'::text))), ''::text) AS usr_initials,
    COALESCE(( SELECT
                CASE
                    WHEN (usrpref.usrpref_value = 't'::text) THEN true
                    ELSE false
                END AS "case"
           FROM public.usrpref
          WHERE ((usrpref.usrpref_username = (pg_user.usename)::text) AND (usrpref.usrpref_name = 'agent'::text))), false) AS usr_agent,
    't'::text AS usr_active,
    COALESCE(( SELECT usrpref.usrpref_value
           FROM public.usrpref
          WHERE ((usrpref.usrpref_username = (pg_user.usename)::text) AND (usrpref.usrpref_name = 'email'::text))), ''::text) AS usr_email,
    COALESCE(( SELECT usrpref.usrpref_value
           FROM public.usrpref
          WHERE ((usrpref.usrpref_username = (pg_user.usename)::text) AND (usrpref.usrpref_name = 'window'::text))), ''::text) AS usr_window
   FROM pg_user;


ALTER TABLE public.usr OWNER TO admin;

--
-- Name: usr_usr_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.usr_usr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.usr_usr_id_seq OWNER TO admin;

--
-- Name: usrgrp; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.usrgrp (
    usrgrp_id integer NOT NULL,
    usrgrp_grp_id integer NOT NULL,
    usrgrp_username text NOT NULL
);


ALTER TABLE public.usrgrp OWNER TO admin;

--
-- Name: TABLE usrgrp; Type: COMMENT; Schema: public; Owner: admin
--

COMMENT ON TABLE public.usrgrp IS 'This is which group a user belongs to.';


--
-- Name: usrgrp_usrgrp_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.usrgrp_usrgrp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usrgrp_usrgrp_id_seq OWNER TO admin;

--
-- Name: usrgrp_usrgrp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.usrgrp_usrgrp_id_seq OWNED BY public.usrgrp.usrgrp_id;


--
-- Name: usrpref_usrpref_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.usrpref_usrpref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.usrpref_usrpref_id_seq OWNER TO admin;

--
-- Name: usrpriv; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.usrpriv (
    usrpriv_id integer DEFAULT nextval(('usrpriv_usrpriv_id_seq'::text)::regclass) NOT NULL,
    usrpriv_priv_id integer,
    usrpriv_username text
);


ALTER TABLE public.usrpriv OWNER TO admin;

--
-- Name: TABLE usrpriv; Type: COMMENT; Schema: public; Owner: admin
--

COMMENT ON TABLE public.usrpriv IS 'User Privileges information';


--
-- Name: usrpriv_usrpriv_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.usrpriv_usrpriv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE public.usrpriv_usrpriv_id_seq OWNER TO admin;


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: usrgrp usrgrp_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usrgrp
    ADD CONSTRAINT usrgrp_pkey PRIMARY KEY (usrgrp_id);


--
-- Name: usrpref usrpref_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usrpref
    ADD CONSTRAINT usrpref_pkey PRIMARY KEY (usrpref_id);


--
-- Name: usrpriv usrpriv_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usrpriv
    ADD CONSTRAINT usrpriv_pkey PRIMARY KEY (usrpriv_id);


--
-- Name: usrpref_userpref_name_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX usrpref_userpref_name_idx ON public.usrpref USING btree (usrpref_name);


--
-- Name: FUNCTION sp_dugovanja(date, date, character varying, character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.sp_dugovanja(date, date, character varying, character varying) TO xtrole;



--
-- Name: TABLE schema_migrations; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.schema_migrations TO xtrole;


--
-- Name: TABLE usrpref; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON TABLE public.usrpref TO xtrole;


--
-- Name: TABLE usr; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON TABLE public.usr TO xtrole;


--
-- Name: SEQUENCE usr_usr_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.usr_usr_id_seq TO xtrole;


--
-- Name: TABLE usrgrp; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON TABLE public.usrgrp TO xtrole;


--
-- Name: SEQUENCE usrgrp_usrgrp_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.usrgrp_usrgrp_id_seq TO xtrole;


--
-- Name: SEQUENCE usrpref_usrpref_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.usrpref_usrpref_id_seq TO xtrole;


--
-- Name: TABLE usrpriv; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON TABLE public.usrpriv TO xtrole;


--
-- Name: SEQUENCE usrpriv_usrpriv_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.usrpriv_usrpriv_id_seq TO xtrole;
