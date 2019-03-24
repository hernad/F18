--- MSSQL FOREIGN TABLES ----------------------------------

CREATE EXTENSION tds_fdw;

DROP SERVER IF EXISTS mssql1 CASCADE;
CREATE SERVER mssql1 foreign data wrapper tds_fdw options (servername '192.168.124.1', port '1433',
		database 'Sarajevo', tds_version '7.1', character_set 'UTF-8');
CREATE USER MAPPING FOR postgres SERVER mssql1 OPTIONS (username 'sa', password 'test01Pwd');

DROP FOREIGN TABLE IF EXISTS mssql1_kupac;
CREATE FOREIGN TABLE mssql1_kupac(nazpp varchar, mjesto varchar, ulica varchar, siff integer, prod integer) SERVER mssql1
   options (query 'SELECT nazpp,mjesto,ulica,siff,prod from [dbo].[kupac]', row_estimate_method 'showplan_all');


CREATE OR REPLACE FUNCTION public.mssql_int_to_date(iDat integer) RETURNS date
   LANGUAGE plpgsql
   AS $$
   DECLARE
     nYear integer;
     nMonth integer;
     nDay integer;
   BEGIN
       nYear := iDat / 10^4;
       nMonth := (iDat - nYear * 10^4) / 10^2;
       nDay := iDat - nYear * 10^4 - nMonth * 10^2;
       nYear := 2000 + nYear;
       RETURN (to_char(nYear,'0999') || to_char(nMonth, '09') || to_char(nDay,'09'))::date;

END;
$$

-- select * from public.sfak_by_brf(2018232);

DROP FUNCTION IF EXISTS public.sfak_by_brf(bigint);
CREATE OR REPLACE FUNCTION public.sfak_by_brf(brfIn bigint) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd date, rel integer)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT rb,prod,ident,kold,cijena,brf,datd,rel from [dbo].[SFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_sfak_' || cBrF || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd integer, rel integer) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena, brf, public.mssql_int_to_date(datd), rel from mssql1_sfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cBrF;
END;
$$



-- select * from public.gfak_by_brf(2018232);

DROP FUNCTION IF EXISTS public.gfak_by_brf(bigint);

CREATE OR REPLACE FUNCTION public.gfak_by_brf(brfIn bigint) RETURNS TABLE (vcij integer, siff integer, datfk date, dvo date, datk date, valdat date, brf bigint, ts timestamp)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT vcij,siff,datfk,dvo,datk,valdat,brf,ts from [dbo].[GFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_gfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_gfak_' || cBrF || '(vcij integer, siff integer, datfk integer, dvo integer, datk integer, valdat integer, brf bigint,ts timestamp) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT vcij,siff,public.mssql_int_to_date(datfk),public.mssql_int_to_date(dvo),public.mssql_int_to_date(datk),public.mssql_int_to_date(valdat),brf,ts from mssql1_gfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_gfak_' || cBrF;
END;
$$


-- select * from public.sfak_by_brf(2018232) as sfak
--  LEFT JOIN public.gfak_by_brf(2018232) as gfak
--  ON sfak.brf=gfak.brf;


-- select * from public.sfak_prodavnice_by_datum('2018-10-16');

DROP FUNCTION IF EXISTS public.sfak_prodavnice_by_datum(datum date);
CREATE OR REPLACE FUNCTION public.sfak_prodavnice_by_datum(datum date) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, vcij integer, datd date, rel integer, siff integer, kp integer)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cDatum text;
BEGIN

cDatum := to_char(datum, 'yymmdd');
-- gfak.KP - magacin SA (40), BL (598), Bihac (942)
-- prod < 199 => prodavnica
-- select count(*) FROM [Sarajevo].[dbo].[SFAK] LEFT JOIN [Sarajevo].[dbo].[GFAK] ON sfak.brf=gfak.brf  where datd=181016
-- siff=2000 => neka od prodavnica
cQuery := 'SELECT rb,prod,ident,kold,cijena,sfak.brf,gfak.vcij,datd,rel,siff,kp from [dbo].[SFAK]' ||
          ' LEFT JOIN [dbo].[GFAK] ON sfak.brf=gfak.brf' ||
          ' WHERE prod>0 AND prod<199 AND siff=20000 AND datd=' || cDatum;

-- select count(*) FROM [Sarajevo].[dbo].[SFAK] LEFT JOIN [Sarajevo].[dbo].[GFAK] ON sfak.brf=gfak.brf  where datd=181016

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cDatum;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql1_sfak_' || cDatum || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, vcij integer, datd integer, rel integer, siff integer, kp integer) SERVER mssql1' ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena, brf, vcij, public.mssql_int_to_date(datd),rel,siff,kp from mssql1_sfak_' || cDatum;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql1_sfak_' || cDatum;
END;
$$;


CREATE OR REPLACE FUNCTION public.magacin_konto(nMagacin integer) RETURNS varchar
   LANGUAGE plpgsql
AS $$
BEGIN

RETURN CASE WHEN nMagacin=40 THEN '1320'
     WHEN nMagacin=598 THEN '13202'
     WHEN nMagacin=942 THEN '13203'
     ELSE '13299'
END;

END;
$$;



--IF ( NOT nProdavnica IN (15) ) THEN
--    RETURN '99999';
--END IF;
--
--RETURN CASE WHEN nProdavnica=1 THEN '13311'
--     WHEN nProdavnica=2 THEN '13312'
--     WHEN nProdavnica=4 THEN '13314'
--     WHEN nProdavnica=5 THEN '13315'
--     WHEN nProdavnica=6 THEN '13316'
--     WHEN nProdavnica=7 THEN '13317'
--     WHEN nProdavnica=8 THEN '13318'
--     WHEN nProdavnica=9 THEN '13319'
--     WHEN nProdavnica=10 THEN '13320'
--     WHEN nProdavnica=11 THEN '13321'
--     WHEN nProdavnica=12 THEN '13322'
--     WHEN nProdavnica=13 THEN '13323'
--     WHEN nProdavnica=14 THEN '13324'
--     WHEN nProdavnica=15 THEN '13325'
--     WHEN nProdavnica=16 THEN '13326'
--     WHEN nProdavnica=17 THEN '13327'
--     WHEN nProdavnica=18 THEN '13328'
--     WHEN nProdavnica=19 THEN '13329'
--     WHEN nProdavnica=20 THEN '13330'
--     WHEN nProdavnica=21 THEN '13331'
--     WHEN nProdavnica=22 THEN '13332'
--     ELSE '13399'
--END;

END;
$$

CREATE OR REPLACE FUNCTION public.prodavnica_zahtjev_prijem_magacin_create(nMagacin integer, dDatum date) RETURNS void
       LANGUAGE plpgsql
       AS $$
DECLARE
   nRbr integer;
   nProdavnica integer;
   nRobaId integer;
   nBrojFakture integer;
   nVrstaCijena integer;
   nKolicina numeric;
   cBrojFaktureT text;
   cIdFirma varchar DEFAULT '10';
   cIdVd varchar DEFAULT '21';
   cBrDok varchar;

BEGIN
     RAISE INFO '==== Magacin % ======', public.magacin_konto(nMagacin);

     cBrojFaktureT := 'XX';
     FOR nBrojFakture, nVrstaCijena, nProdavnica, nRbr, nRobaId, nKolicina IN
          SELECT brf, vcij, prod, rb, ident, kold from public.sfak_prodavnice_by_datum(dDatum)
          WHERE kp=nMagacin
          ORDER BY brf, rb
     LOOP
         IF public.prodavnica_konto(nProdavnica) = '99999' THEN
           RAISE INFO 'Preskacemo prodavnicu %', nProdavnica;
           CONTINUE;
         ELSE
           RAISE INFO 'Obrada prodavnica %', nProdavnica;
         END IF;

          IF ( cBrojFaktureT = 'XX' ) OR ( cBrojFaktureT <> (btrim(to_char(nBrojFakture, '9999999999')) || btrim(to_char(nVrstaCijena, '9'))) ) THEN
             cBrojFaktureT := btrim(to_char(nBrojFakture, '9999999999')) || btrim(to_char(nVrstaCijena, '9'));
             cBrDok := public.kalk_novi_brdok(cIdVd);
             RAISE INFO '---- Otpremnica % prodavnica: % ----', cBrojFaktureT, public.prodavnica_konto(nProdavnica);
             INSERT INTO public.kalk_doks(idfirma,idvd,brdok,datdok,mkonto,pkonto,brfaktp)
                 values(
                   cIdFirma, cIdVd, cBrDok, dDatum,
                   public.magacin_konto(nMagacin), public.prodavnica_konto(nProdavnica),
                   cBrojFaktureT
                 );
          END IF;

          RAISE INFO ' stavke:  % % %',  nRbr, public.roba_id_by_sifradob(nRobaId), nKolicina;
          INSERT INTO public.kalk_kalk(idfirma,idvd,brdok,datdok,mkonto,pkonto,brfaktp,mu_i,pu_i,rbr,idroba,kolicina)
          values(
            cIdFirma, cIdVd, cBrDok, dDatum,
            public.magacin_konto(nMagacin), public.prodavnica_konto(nProdavnica),
            cBrojFaktureT,
            '6', '2',
            nRbr, public.roba_id_by_sifradob(nRobaId),
            nKolicina
          );

            -- PERFORM p15.nivelacija_start_create( uuidPos );
     END LOOP;

     RETURN;
END;
$$
