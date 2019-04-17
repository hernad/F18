--- MSSQL FOREIGN TABLES ----------------------------------

CREATE EXTENSION IF NOT EXISTS tds_fdw;

DROP SERVER IF EXISTS mssql1 CASCADE;
CREATE SERVER mssql1 foreign data wrapper tds_fdw options (servername '{{ mssql.server_name }}', port '{{ mssql.server_port }}',
		database '{{ mssql.database }}', tds_version '7.1', character_set 'UTF-8');
CREATE USER MAPPING FOR {{ pg_admin }} SERVER mssql1 OPTIONS (username '{{ mssql.user }}', password '{{ mssql.password }}');

DROP FOREIGN TABLE IF EXISTS mssql1_kupac;
CREATE FOREIGN TABLE mssql1_kupac(nazpp varchar, mjesto varchar, ulica varchar, siff integer, prod integer) SERVER mssql1
   options (query 'SELECT nazpp,mjesto,ulica,siff,prod from [dbo].[kupac]', row_estimate_method 'showplan_all');

DROP SERVER IF EXISTS mssql2 CASCADE;
CREATE SERVER mssql2 foreign data wrapper tds_fdw options (servername '{{ mssql2.server_name }}', port '{{ mssql2.server_port }}',
		database '{{ mssql2.database }}', tds_version '7.1', character_set 'UTF-8');
CREATE USER MAPPING FOR {{ pg_admin }} SERVER mssql2 OPTIONS (username '{{ mssql2.user }}', password '{{ mssql2.password }}');

DROP SERVER IF EXISTS mssql3 CASCADE;
CREATE SERVER mssql3 foreign data wrapper tds_fdw options (servername '{{ mssql3.server_name }}', port '{{ mssql3.server_port }}',
		database '{{ mssql3.database }}', tds_version '7.1', character_set 'UTF-8');
CREATE USER MAPPING FOR {{ pg_admin }} SERVER mssql3 OPTIONS (username '{{ mssql3.user }}', password '{{ mssql3.password }}');


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
$$;

-- select * from public.sfak_by_brf('1', 2018232);

DROP FUNCTION IF EXISTS public.sfak_by_brf;
CREATE OR REPLACE FUNCTION public.sfak_by_brf(cServer character(1), brfIn bigint) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd date, rel integer, vs integer)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT rb,prod,ident,kold,cijena,brf,datd,rel,vs from [dbo].[SFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_sfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql_sfak_' || cBrF || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, datd integer, rel integer, vs integer) SERVER mssql' || cServer ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena,brf,public.mssql_int_to_date(datd),rel,vs from mssql_sfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_sfak_' || cBrF;
END;
$$;



-- select * from public.gfak_by_brf(2018232);

DROP FUNCTION IF EXISTS public.gfak_by_brf(bigint);

CREATE OR REPLACE FUNCTION public.gfak_by_brf(cServer character(1), brfIn bigint) RETURNS TABLE (vcij integer, siff integer, datfk date, dvo date, datk date, valdat date, brf bigint, ts timestamp)

LANGUAGE plpgsql
AS $$
DECLARE
  cQuery text;
  cBrf text;
BEGIN

cBrF := btrim(to_char(brfIn, '999999999'));
cQuery := 'SELECT vcij,siff,datfk,dvo,datk,valdat,brf,ts from [dbo].[GFAK] WHERE brf=' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_gfak_' || cBrF;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql_gfak_' || cBrF || '(vcij integer, siff integer, datfk integer, dvo integer, datk integer, valdat integer, brf bigint,ts timestamp) SERVER mssql' || cServer ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT vcij,siff,public.mssql_int_to_date(datfk),public.mssql_int_to_date(dvo),public.mssql_int_to_date(datk),public.mssql_int_to_date(valdat),brf,ts from mssql_gfak_' || cBrF;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_gfak_' || cBrF;
END;
$$;


-- select * from public.sfak_by_brf(2018232) as sfak
--  LEFT JOIN public.gfak_by_brf(2018232) as gfak
--  ON sfak.brf=gfak.brf;


-- select * from public.sfak_prodavnice_by_datum('1', '2018-10-16');

DROP FUNCTION IF EXISTS public.sfak_prodavnice_by_datum;
CREATE OR REPLACE FUNCTION public.sfak_prodavnice_by_datum(cServer character(1), datum date) RETURNS TABLE (rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, vcij integer, datd date, rel integer, siff integer, kp integer, vs integer, datfk date)

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
cQuery := 'SELECT rb,prod,ident,kold,cijena,sfak.brf,gfak.vcij,datd,rel,siff,kp,vs,datfk from [dbo].[SFAK]' ||
          ' LEFT JOIN [dbo].[GFAK] ON sfak.brf=gfak.brf' ||
          ' WHERE prod>0 AND prod<199 AND siff=20000 AND datfk=' || cDatum;

-- select count(*) FROM [Sarajevo].[dbo].[SFAK] LEFT JOIN [Sarajevo].[dbo].[GFAK] ON sfak.brf=gfak.brf  where datd=181016

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_sfak_' || cDatum;
RAISE INFO 'query: %', cQuery;
EXECUTE 'CREATE FOREIGN TABLE mssql_sfak_' || cDatum || '(rb integer, prod integer, ident integer, kold numeric, cijena numeric, brf bigint, vcij integer, datd integer, rel integer, siff integer, kp integer, vs integer, datfk integer) SERVER mssql' || cServer ||
        ' options (query '''|| cQuery ||''', row_estimate_method ''execute'')';

RETURN QUERY EXECUTE 'SELECT rb,prod,ident,kold,cijena, brf, vcij, public.mssql_int_to_date(datd),rel,siff,kp,vs,public.mssql_int_to_date(datfk) from mssql_sfak_' || cDatum;

EXECUTE 'DROP FOREIGN TABLE IF EXISTS mssql_sfak_' || cDatum;
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


-- select * from  public.prodavnica_zahtjev_prijem_magacin_create('1', 40, current_date);

DROP TYPE IF EXISTS prod_magacin_type CASCADE;
CREATE TYPE prod_magacin_type AS
(
	  insert character(1),
    prod integer,
		mkonto varchar,
		pkonto varchar,
		brfaktp varchar,
		brdok varchar,
		datum date
);

DROP FUNCTION IF EXISTS public.prodavnica_zahtjev_prijem_magacin_create;

CREATE OR REPLACE FUNCTION public.prodavnica_zahtjev_prijem_magacin_create(cServer character(1), nMagacin integer, dDatum date)
    RETURNS table( insert character(1), prod integer, mkonto varchar, pkonto varchar, brfaktp varchar, brdok varchar, datum date )
    LANGUAGE plpgsql
AS $$
DECLARE
   nRbr integer;
   nProdavnica integer;
	 nPredhodnaProd integer;
   nRobaId integer;
   nBrojFakture integer;
   nVrstaCijena integer;
   nKolicina numeric;
   cBrojFaktureT text;
   cIdFirma varchar DEFAULT '10';
   cIdVd varchar DEFAULT '21';
   cBrDok varchar;
	 cPKonto varchar;
	 cIdRoba varchar;
	 cIdTarifa varchar;
	 lFakturaPostoji boolean;
	 nVS integer;

	 rptItem prod_magacin_type;
	 aRpt prod_magacin_type[] DEFAULT '{}';
BEGIN
     RAISE INFO '==== Magacin % ======', public.magacin_konto(nMagacin);

     cBrojFaktureT := 'XX';
		 lFakturaPostoji := False;
		 nProdavnica := -1;
		 nPredhodnaProd := -1;
     FOR nBrojFakture, nVrstaCijena, nProdavnica, nRbr, nRobaId, nKolicina, nVS IN
          SELECT sfak.brf, sfak.vcij, sfak.prod, sfak.rb, sfak.ident, sfak.kold, sfak.vs from public.sfak_prodavnice_by_datum(cServer, dDatum) sfak
          WHERE kp=nMagacin
          ORDER BY brf, rb
     LOOP
		     cPKonto := public.prodavnica_konto(nProdavnica);
		     cIdRoba := public.roba_id_by_sifradob(nRobaId);
		     cIdTarifa := public.idtarifa_by_idroba(cIdRoba);
          IF ( public.prodavnica_konto(nProdavnica) = '99999' ) THEN
					   IF nPredhodnaProd <> nProdavnica THEN
					     rptItem := (
						     'S',
						     nProdavnica,
						     public.magacin_konto(nMagacin),
						     '',
						      btrim(to_char(nBrojFakture, '9999999999')) || btrim(to_char(nVrstaCijena, '9')),
						     '',
						     dDatum
					      );
					      aRpt := array_append(aRpt, rptItem);
								nPredhodnaProd := nProdavnica;
								RAISE INFO 'Preskacemo prodavnicu: %', nProdavnica;
						 END IF;
             CONTINUE;
          ELSE
             RAISE INFO 'Obrada prodavnica %', nProdavnica;
          END IF;

					IF ( cBrojFaktureT = 'XX' ) OR ( cBrojFaktureT <> (btrim(to_char(nBrojFakture, '9999999999')) || btrim(to_char(nVrstaCijena, '9'))) ) THEN
             cBrojFaktureT := btrim(to_char(nBrojFakture, '9999999999')) || btrim(to_char(nVrstaCijena, '9'));
						 lFakturaPostoji := public.kalk_pkonto_brfaktp_kalk_21_exists( cPKonto, cBrojFaktureT);
						 IF lFakturaPostoji THEN
		           RAISE INFO 'Preskacemo prodavnicu: % jer postoji faktura %', nProdavnica, cBrojFaktureT;
							 rptItem := (
								  '0',
							    nProdavnica,
							 		public.magacin_konto(nMagacin),
							 		public.prodavnica_konto(nProdavnica),
							 		cBrojFaktureT || '-' || to_char(nVS, '9999'),
							 		'',
							 		dDatum
							 );
							 aRpt := array_append(aRpt, rptItem);
		           CONTINUE;
		         END IF;
             cBrDok := public.kalk_novi_brdok(cIdVd);
             RAISE INFO '---- Otpremnica % prodavnica: % ----', cBrojFaktureT, public.prodavnica_konto(nProdavnica);
						 rptItem := (
							  '1',
						    nProdavnica,
						 		public.magacin_konto(nMagacin),
						 		public.prodavnica_konto(nProdavnica),
						 		cBrojFaktureT || '-' || to_char(nVS, '9999'),
						 		cBrDok,
						 		dDatum
						 );
						 aRpt := array_append(aRpt, rptItem);
             INSERT INTO public.kalk_doks(idfirma,idvd,brdok,datdok,mkonto,pkonto,brfaktp,opis)
                 values(
                   cIdFirma, cIdVd, cBrDok, dDatum,
                   public.magacin_konto(nMagacin),
									 public.prodavnica_konto(nProdavnica),
                   cBrojFaktureT,
									 btrim(to_char(nVS, '9999'))
                 );
          END IF;

          IF lFakturaPostoji THEN
					   CONTINUE;
					END IF;
          RAISE INFO ' stavke: % % [%] %  mpc_koncij_sif: %',  cPKonto, nRbr, cIdRoba, nKolicina, public.mpc_by_koncij(cPKonto, cIdRoba);
          INSERT INTO public.kalk_kalk(idfirma,idvd,brdok,datdok,mkonto,pkonto,brfaktp,mu_i,pu_i,rbr,idroba,idtarifa,kolicina,mpcsapp)
          values(
            cIdFirma, cIdVd, cBrDok, dDatum,
            public.magacin_konto(nMagacin), cPKonto,
            cBrojFaktureT,
            '6', '2',
            nRbr, cIdRoba, cIdTarifa,
            nKolicina,
						public.mpc_by_koncij(cPKonto, cIdRoba)
          );

     END LOOP;

     RETURN QUERY SELECT * FROM unnest( aRpt );
END;
$$;


--
-- CREATE OR REPLACE FUNCTION p2.test_array_to_table_3()
--   RETURNS table(brdok varchar, cnt integer)
--   LANGUAGE plpgsql
--    AS
--   $$
--  DECLARE
--    aItem  test_type;
--    aBrDoks test_type[] DEFAULT '{}';
--    BEGIN
--    aItem := ('hello', 1);
--    aBrDoks := array_append(aBrDoks, aItem);
--    aItem := ('world', '2');
--    aBrDoks := array_append(aBrDoks, aItem);
--
--    RETURN QUERY SELECT * FROM unnest( aBrDoks );
-- END;
-- $$;
