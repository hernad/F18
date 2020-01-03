CREATE OR REPLACE FUNCTION public.zatvori_otvst(
	cIdkonto text,
	cIdpartner text,
	cBrdok text)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$

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
$BODY$;

ALTER FUNCTION public.zatvori_otvst(text, text, text) OWNER TO admin;


DO $$ BEGIN
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

EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


ALTER TYPE public.t_dugovanje OWNER TO admin;


CREATE OR REPLACE FUNCTION public.sp_duguje_stanje_2(param_konto character varying, param_partner character varying, param_dat_od date, param_dat_do date, OUT pocstanje double precision, OUT dospjelo double precision, OUT nedospjelo double precision, OUT valuta date) RETURNS record
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
-- Name: sp_dugovanja(date, date, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--
-- CREATE OR REPLACE FUNCTION public.sp_dugovanja(date, date, character varying, character varying) RETURNS SETOF public.t_dugovanje
--     LANGUAGE sql
--     AS $_$
-- SELECT idkonto::varchar as konto_id, partn.naz::varchar as partner_naz, refer.naz::varchar as referent_naz, idpartner::varchar as partner_id,
-- pocstanje::numeric(16,2) as i_pocstanje, dospjelo::numeric(16,2) as i_dospjelo,
-- nedospjelo::numeric(16,2) as i_nedospjelo,
-- (dospjelo+nedospjelo+pocstanje)::numeric(16,2) as i_ukupno, valuta,
--  convert_to_integer(get_sifk( 'PARTN', 'ROKP', idpartner  )) AS rok_pl  from
-- (
-- select idkonto, idpartner, (dug_0.sp_duguje_stanje_2).*  from
-- (
--    SELECT  idkonto, idpartner, sp_duguje_stanje_2( kto_partner.idkonto, kto_partner.idpartner, $1, $2)  FROM
--      (select  distinct on (idkonto, idpartner) idkonto, idpartner
--       from fmk.fin_suban where  trim(idpartner)<>'' and trim(idkonto) LIKE $3 and trim(idpartner) LIKE $4
--       order by idkonto, idpartner) as kto_partner
-- ) as dug_0
-- ) as dugovanja
-- LEFT JOIN fmk.partn ON partn.id=dugovanja.idpartner
-- LEFT OUTER JOIN fmk.refer ON (partn.idrefer = refer.id);
-- $_$;
-- 
-- ALTER FUNCTION public.sp_dugovanja(date, date, character varying, character varying) OWNER TO admin;
