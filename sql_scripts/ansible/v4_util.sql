
CREATE OR REPLACE FUNCTION public.create_table_from_then_drop( cTableFrom varchar, cTable varchar) RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
   BEGIN
         EXECUTE 'CREATE TABLE IF NOT EXISTS ' || cTable || ' AS TABLE ' || cTableFrom;
         EXECUTE 'DROP TABLE IF EXISTS ' || cTableFrom;
   EXCEPTION WHEN OTHERS THEN
         RAISE NOTICE  '% garant not exists -> %', cTableFrom, cTable;
         RETURN FALSE;
   END;

   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION  public.drop_table_safely( cTable varchar) RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
   BEGIN
         EXECUTE 'DROP TABLE IF EXISTS ' || cTable;
   EXCEPTION WHEN OTHERS THEN
         RAISE NOTICE  '% garant je view', cTable;
         RETURN FALSE;
   END;

   RETURN TRUE;
END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_novi_brdok(cIdVd varchar) RETURNS varchar
   LANGUAGE plpgsql
AS $$
BEGIN
   -- RETURN lpad(btrim(to_char(nextval('f18.kalk_brdok_seq_' || cIdVd), '99999999')), 8, '0');
   RETURN public.kalk_novi_brdok_konto(cIdVd, '9999999');
END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_novi_brdok_konto(cIdVd varchar, cIdKonto varchar) RETURNS varchar
   LANGUAGE plpgsql
AS $$
DECLARE
   cSufix varchar;
   cBrDok varchar;
   nBrDok integer;
BEGIN
   cIdKonto := trim( cIdKonto );
   SELECT btrim(sufiks) from koncij where trim(id)=cIdKonto
       INTO cSufix;

   IF coalesce(cSufix,'') = '' THEN
    -- hb _o_kalk_sql.prg: FUNCTION find_kalk_doks_za_tip_zadnji_broj( cIdFirma, cIdvd )
     select coalesce(brdok,'') from kalk_doks where idvd=cIdVd AND not (left(brdok,1)='G' OR brdok similar to '%(-|/)%')
       order by brdok desc limit 1
        into cBrDok;
	   cBrDok := coalesce(cBrDok, '0');
     nBrDok := to_number(cBrDok, '09999999')::integer;
     cBrDok := lpad( btrim( to_char(nBrDok + 1, '09999999') ), 8, '0');
   ELSE
     -- hb _o_kalk_sql.prg: FUNCTION find_kalk_doks_za_tip_sufix_zadnji_broj( cIdFirma, cIdVd, cBrDokSfx )
     -- replace(brdok, cSufix, ''): 000010/T => 000010
     select replace(coalesce(brdok,''), cSufix, '') from kalk_doks where trim(pkonto)=cIdKonto and idvd=cIdVd
        order by replace(brdok, cSufix, '') desc limit 1
        into cBrDok;
	   cBrDok := coalesce(cBrDok, '0');
     nBrDok := to_number(cBrDok, '09999999')::integer;
     cBrDok := btrim( to_char(nBrDok + 1, '09999999') );
     cBrDok := cBrDok || cSufix;
   END IF;
   RETURN right(cBrDok, 8);
END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_novi_brdok_11(cPKonto varchar) RETURNS varchar
   LANGUAGE plpgsql
AS $$
DECLARE
   cSufix varchar;
   cBrDok varchar;
   nBrDok integer;
BEGIN
   RETURN public.kalk_novi_brdok_konto('11', cPKonto);
END;
$$;

-- hParams[ "order_by" ] := "idfirma,idvd,brdok"
-- hParams[ "indeks" ] := .F.  // ne trositi vrijeme na kreiranje indeksa
-- hParams[ "desc" ] := .T.
-- hParams[ "limit" ] := 1
-- hParams[ "where_ext" ] := " AND not (left(brdok,1)='G' OR brdok similar to '%(-|/)%')" // NOT: G00000001, 00020-BL, 00020/BL


-- POS 42 - racuni, zbirno u KALK
-- SELECT public.kalk_brdok_iz_pos(15, '49', '4', current_date); => 150214
-- POS 71 - dokument, zahtjev za snizenje - pojedinacno u KALK
-- SELECT public.kalk_brdok_iz_pos(15, '71', '    3', current_date); => 15021403

CREATE OR REPLACE FUNCTION public.kalk_brdok_iz_pos(prod integer, idvdKalk varchar, posBrdok varchar, datum date) RETURNS varchar

LANGUAGE plpgsql
AS $$
DECLARE
  brdok varchar;
BEGIN

IF ( idvdKalk = '49' ) THEN
    -- 01.02.2019, idpos=15 -> 150201
    SELECT TO_CHAR(datum, btrim(to_char(prod, '09')) || 'yymmdd' ) INTO brDok;
ELSIF ( idvdKalk = '22' ) THEN
    -- 22 - POS prijem iz magacin, uzima brdok od 21 koji se generise u KALK, tako da je to jedinstven broj
    brDok := posBrdok;
ELSIF ( idvdKalk IN ('29','61','71','89','90','99') ) THEN
   -- 61 - zahtjev za nabavku robe od strane pos-a
   -- 71 - zahtjev za snizenje se formira u pos
   -- 29 - nivelacija se generise u pos
   -- 89 - direktni prijem od dobavljaca
   -- 90 - pos inventura
   -- 99 - evidencija kalo
   -- 01.02.2019, brdok='      3' -> 15020103
   SELECT TO_CHAR(datum, btrim(to_char(prod, '09')) || 'mmdd' ) || lpad(btrim(posBrdok), 2, '0') INTO brDok;
ELSE
   RAISE EXCEPTION 'ERROR kalk_brdok_iz_pos % % % %', idPos, idvdKalk, posBrdok, datum;
END IF;

RETURN rpad(brDok, 8, '0');

END;
$$;


CREATE OR REPLACE FUNCTION public.barkod_ean13_to_num(barkod varchar, dec_mjesta integer) returns numeric
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    -- 1234567890123 => 1234567890.123
    IF (dec_mjesta = 3) THEN
      RETURN to_number(barkod, '0999999999999') / 1000;
    ELSE
      RETURN to_number(barkod, '0999999999999') / 1000000;
    END IF;
  EXCEPTION WHEN OTHERS THEN
       RETURN -1;
  END;
END;
$$;

CREATE OR REPLACE FUNCTION public.num_to_barkod_ean13(barkod numeric, dec_mjesta integer) returns text
LANGUAGE plpgsql
AS $$
BEGIN
   IF (barkod < 0) THEN
      RETURN '';
   ELSE
      ---  1234567890.123 => 1234567890123
      IF (dec_mjesta = 3) THEN
         RETURN replace(btrim(to_char(barkod , '0999999999.990')), '.','');
      ELSE
         RETURN replace(btrim(to_char(barkod , '0999999.999990')), '.','');
      END IF;
   END IF;
END;
$$;


-- select kalk_dok_id('10','11','00000100', '2018-01-09');
CREATE OR REPLACE FUNCTION public.kalk_dok_id(cIdFirma varchar, cIdVD varchar, cBrDok varchar, dDatDok date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM f18.kalk_doks WHERE idfirma=$1 AND idvd=$2 AND brdok=$3 AND datdok=$4'
     USING cIdFirma, cIdVd, cBrDok, dDatDok
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
   END IF;

   RETURN dok_id;
END;
$$;


-- select * from kalk_prod_stanje_sa_kartice('13325', '003189');

CREATE OR REPLACE FUNCTION public.kalk_prod_stanje_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS table( count integer, nv_dug numeric, nv_pot numeric, mpv_dug numeric, mpv_pot numeric, kol_dug numeric, kol_pot numeric, mpc_sa_pdv numeric )
   LANGUAGE plpgsql
AS $$
DECLARE
   cIdVd varchar;
   nKolicina numeric;
   nKolicina2 numeric;
   nKolicinaUlaz numeric DEFAULT 0.0;
   nKolicinaIzlaz numeric DEFAULT 0.0;
   nNVUlaz numeric DEFAULT 0.0;
   nNVIzlaz numeric DEFAULT 0.0;
   nMPVUlaz numeric DEFAULT 0.0;
   nMPVIzlaz numeric DEFAULT 0.0;
   nNC numeric;
   nMpc numeric;
   nMpcStara numeric;
   cPUI varchar;
   nCount integer DEFAULT 0;

BEGIN
  FOR cIdVd, nKolicina, nKolicina2, nNc, nMpc, nMpcStara, cPUI IN SELECT idvd, coalesce(kolicina,0),
      coalesce(gkolicin2,0), coalesce(nc,0), coalesce(mpcsapp,0), coalesce(fcj,0), pu_i from kalk_kalk
     WHERE pkonto=cPKonto AND idroba=cIdRoba
  LOOP

    CASE cPUI
     WHEN '1' THEN
         nKolicinaUlaz := nKolicinaUlaz + nKolicina;
         nNvUlaz := nNvUlaz + nKolicina * nNc;
         nMpvUlaz := nMpvUlaz + nKolicina * nMpc;
     WHEN '5' THEN
         nKolicinaIzlaz := nKolicinaIzlaz + nKolicina;
         nNvIzlaz := nNvIzlaz + nKolicina * nNc;
         nMpvIzlaz := nMpvIzlaz + nKolicina * nMpc;
     WHEN '3' THEN
         nMpvUlaz := nMpvUlaz + nKolicina * nMpc ;
     WHEN 'I' THEN
         nKolicinaIzlaz := nKolicinaIzlaz + nKolicina2;
         nMpvIzlaz := nMpvIzlaz + nKolicina2 * nMpc;
         nNvIzlaz := nNvIzlaz + nKolicina2 * nNc;
     ELSE
    END CASE;
    nCount := nCount + 1;

  END LOOP;

  IF ( nKolicinaUlaz - nKolicinaIzlaz ) <> 0 THEN
     nMpc := ROUND( ( nMpvUlaz - nMpvIzlaz ) / ( nKolicinaUlaz - nKolicinaIzlaz), 2);
  ELSE
     nMpc := 0;
  END IF;

  RETURN QUERY SELECT nCount, round(nNvUlaz,4), round(nNvIzlaz,4), round(nMpvUlaz,4), round(nMpvIzlaz,4),
        round(nKolicinaUlaz,4), round(nKolicinaIzlaz,4), round(nMpc,4);
END;
$$;


-- select kalk_prod_mpc_sa_kartice('13325', '003189');

CREATE OR REPLACE FUNCTION public.kalk_prod_mpc_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS numeric
   LANGUAGE plpgsql
AS $$
DECLARE
   nMpc numeric;
BEGIN
  select CASE WHEN (kol_dug - kol_pot) <> 0 THEN ROUND((mpv_dug-mpv_pot) / (kol_dug-kol_pot), 2) ELSE 0 END from public.kalk_prod_stanje_sa_kartice( cPKonto, cIdRoba )
     INTO nMpc;
  RETURN nMpc;
END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_prod_kolicina_sa_kartice( cPKonto varchar, cIdRoba varchar ) RETURNS numeric
   LANGUAGE plpgsql
AS $$
DECLARE
   nKolicina numeric;
BEGIN
  select ROUND(kol_dug - kol_pot, 4) from public.kalk_prod_stanje_sa_kartice( cPKonto, cIdRoba )
     INTO nKolicina;
  RETURN nKolicina;
END;
$$;


CREATE OR REPLACE FUNCTION public.logiraj( cUser varchar, cPrefix varchar, cMsg text) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN

   insert into public.log(user_code, msg) values(cUser, cPrefix || ': ' || cMsg);
   RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.roba_id_by_sifradob(nRobaId integer) RETURNS varchar
   LANGUAGE plpgsql
AS $$
DECLARE
  cIdRoba varchar;
  cMsg varchar;
  cSifraDob varchar;
BEGIN

SELECT id from public.roba where lpad(btrim(sifradob),5,'0')=lpad(btrim(to_char(nRobaId,'99999')),5,'0')
  INTO cIdRoba;

IF cIdRoba IS NULL THEN
   cSifraDob := lpad(btrim(to_char(nRobaId,'99999')),5,'0');
   cMsg := format('sifradob = %s', cSifraDob) ;
   PERFORM public.logiraj( current_user::varchar, 'ERROR_SIFRADOB', cMsg);
   RAISE INFO 'sifradob =? %', cSifraDob;
END IF;

RETURN COALESCE(cIdRoba, '<<UNDEF>>');

END;
$$;


CREATE OR REPLACE FUNCTION public.pos_prodavnica_by_pkonto(cPKonto varchar) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  nProdavnica integer;
BEGIN
   SELECT prod INTO nProdavnica
       from public.koncij where id=cPKonto;
   RETURN COALESCE( nProdavnica );
END;
$$;

CREATE OR REPLACE FUNCTION public.pos_popust( nCijena numeric, nNCijena numeric) RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  nProdavnica integer;
BEGIN
   IF round( nNCijena, 4) = 0 THEN
      RETURN 0;
   END IF;

   RETURN nCijena - nNCijena;
END;
$$;

CREATE OR REPLACE FUNCTION public.pos_neto_cijena( nCijena numeric, nNCijena numeric) RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  nProdavnica integer;
BEGIN
   IF round( nNCijena, 4) = 0 THEN
      RETURN nCijena;
   END IF;

   RETURN nNCijena;
END;
$$;

CREATE OR REPLACE FUNCTION public.prodavnica_konto(nProdavnica integer) RETURNS varchar
   LANGUAGE plpgsql
AS $$
DECLARE
   pKonto varchar;
BEGIN

SELECT id INTO pKonto
	 from public.koncij where prod=nProdavnica;

IF coalesce( btrim( pKonto), '' ) = '' THEN
    RETURN '99999';
END IF;

RETURN rpad(pKonto, 7);

END;
$$;


CREATE OR REPLACE FUNCTION public.idtarifa_by_idroba( cIdRoba varchar ) RETURNS varchar
LANGUAGE plpgsql
AS $$
DECLARE
  cIdTarifa varchar;
BEGIN
   SELECT idtarifa FROM public.roba
   WHERE id=cIdRoba
	   INTO cIdTarifa;

   RETURN coalesce( btrim( cIdTarifa), '' );

END
$$;

CREATE OR REPLACE FUNCTION public.mpc_by_koncij(cPKonto varchar, cIdRoba varchar) RETURNS numeric
   LANGUAGE plpgsql
AS $$
DECLARE
   cTip varchar;
	 nMpc numeric;
	 nMpc2 numeric;
	 nMpc3 numeric;
	 nMpc4 numeric;
	 nMpc5 numeric;
	 nMpc6 numeric;
	 nMpc7 numeric;
	 nMpc8 numeric;
	 nMpc9 numeric;
	 cIdFound varchar;
BEGIN

-- tip cijene je pohranjen u naz polje
SELECT naz INTO cTip
	 from public.koncij where trim(id)=trim(cPKonto);

-- nije definisan tip, treba da bude 'M1', 'M2' itd
IF coalesce( btrim( cTip), '' ) = '' THEN
    RETURN 0;
END IF;

SELECT Id, mpc, mpc2, mpc3, mpc4, mpc5, mpc6, mpc7, mpc8, mpc9 FROM public.roba
   WHERE id=cIdRoba
	 INTO cIdFound, nMpc, nMpc2, nMpc3, nMpc4, nMpc5, nMpc6, nMpc7, nMpc8, nMpc9;

RAISE INFO '[%] % % %', cTip, cIdFound, nMpc, nMpc2;

IF coalesce( btrim(cIdFound), '' ) = '' THEN
     RAISE INFO 'artikla % nema ?!', cIdRoba;
	   RETURN -1;
END IF;

RETURN CASE WHEN cTip='M1' THEN nMpc
       WHEN cTip='M2' THEN nMpc2
			 WHEN cTip='M3' THEN nMpc3
			 WHEN cTip='M4' THEN nMpc4
			 WHEN cTip='M5' THEN nMpc5
			 WHEN cTip='M6' THEN nMpc6
			 WHEN cTip='M7' THEN nMpc7
			 WHEN cTip='M8' THEN nMpc8
			 WHEN cTip='M9' THEN nMpc9
      ELSE -3
END;

END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_pkonto_idvd_brfaktp_kalk_exists( cIdVd varchar, cPKonto varchar,  cBrFaktP varchar) RETURNS boolean
   LANGUAGE plpgsql
AS $$
DECLARE
   dokId uuid;
   lExist boolean;
BEGIN
   select dok_id FROM f18.kalk_doks where pkonto=cPKonto AND brfaktp=cBrFaktP AND idvd=cIdVd
      INTO dokId;
   IF (dokId IS NULL) THEN
      RETURN False;
   END IF;
   RETURN True;

END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_pkonto_brfaktp_kalk_21_exists( cPKonto varchar,  cBrFaktP varchar) RETURNS boolean
   LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
    RETURN public.kalk_pkonto_idvd_brfaktp_kalk_exists( '21', cPKonto,  cBrFaktP);
END;
$$;


-- select public.kalk_from_idvd_to_idvd('10', '49', '42', '00000015');
-- na osnovu 10-49-0000015 formira se 10-42-0000015

DROP FUNCTION IF EXISTS public.kalk_from_idvd_to_idvd( cIdFirma varchar, cIdVdFrom varchar, cIdVdTo varchar, cBrDok varchar );

CREATE OR REPLACE FUNCTION public.kalk_from_idvd_to_idvd( cIdFirma varchar, cIdVdFrom varchar, cIdVdTo varchar, cBrDok varchar, cBrDokNew varchar) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE

    rec_dok RECORD;
    dokId uuid;
    rec RECORD;

BEGIN
     select * from f18.kalk_doks where cIdFirma=idfirma and cIdVdFrom=idvd and cBrDok=brdok
        INTO rec_dok;

     IF rec_dok.dok_id is NULL  THEN
         RAISE INFO 'NE POSTOJI dokument: % % % !?', cIdFirma, cIdVdFrom, cBrDok;
         RETURN -1;
     END IF;

     select dok_id from f18.kalk_doks where cIdFirma=idfirma and cIdVdTo=idvd and cBrDokNew=brdok
        INTO dokId;
     IF NOT dokId IS NULL THEN
         RAISE INFO 'VEC POSTOJI: % % % ?', cIdFirma, cIdVdTo, cBrDokNew;
         RETURN -2;
     END IF;

     -- ref sadrzi referencu na dok_id izvornog dokumenta
     INSERT INTO f18.kalk_doks(
              idfirma, idvd, brdok, datdok, dat_od, dat_do,
              brfaktp, datfaktp, idpartner, pkonto, mkonto,
              nv, vpv, rabat, mpv, datval, ref )
         VALUES(rec_dok.idfirma, cIdVdTo, cBrDokNew, rec_dok.datdok, rec_dok.dat_od, rec_dok.dat_do,
             rec_dok.brfaktp, rec_dok.datfaktp, rec_dok.idpartner, rec_dok.pkonto, rec_dok.mkonto,
             rec_dok.nv, rec_dok.vpv, rec_dok.rabat, rec_dok.mpv, rec_dok.datval, rec_dok.dok_id );

     FOR rec IN
        SELECT * from public.kalk_kalk
        WHERE cIdFirma=idfirma and cIdVdFrom=idvd and cBrDok=brdok
     LOOP
        INSERT INTO public.kalk_kalk(idfirma, idvd, brdok, datdok,
          idroba, idkonto, idkonto2, brfaktp, idpartner,
          rbr, kolicina, gkolicina, gkolicin2,
          trabat, rabat, tprevoz, prevoz, tprevoz2, prevoz2, tbanktr, banktr, tspedtr, spedtr, tcardaz, cardaz, tzavtr, zavtr,
          fcj, fcj2, nc, tmarza, marza, vpc, rabatv,
          tmarza2, marza2, mpc, idtarifa, mpcsapp,
          mkonto, pkonto, mu_i, pu_i, error
        )
        VALUES(rec.idfirma, cIdVdTo, cBrDokNew, rec.datdok,
          rec.idroba, rec.idkonto, rec.idkonto2, rec.brfaktp, rec.idpartner,
          rec.rbr, rec.kolicina, rec.gkolicina, rec.gkolicin2,
          rec.trabat, rec.rabat, rec.tprevoz, rec.prevoz, rec.tprevoz2, rec.prevoz2, rec.tbanktr, rec.banktr, rec.tspedtr, rec.spedtr, rec.tcardaz, rec.cardaz, rec.tzavtr, rec.zavtr,
          rec.fcj, rec.fcj2, rec.nc, rec.tmarza, rec.marza, rec.vpc, rec.rabatv,
          rec.tmarza2, rec.marza2, rec.mpc, rec.idtarifa, rec.mpcsapp,
          rec.mkonto, rec.pkonto, rec.mu_i, rec.pu_i, rec.error
        );
     END LOOP;

     RETURN 0;
END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_49_to_42( nProdavnica integer, dDatum date) RETURNS varchar
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   cBrDok varchar;
   nRet integer;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
    SELECT public.kalk_brdok_iz_pos(nProdavnica, '49', lpad('1',8), dDatum)
       INTO cBrDok;
    SELECT public.kalk_from_idvd_to_idvd( cIdFirma, '49', '42', cBrDok, cBrDok )
       INTO nRet;
    IF ( nRet = 0 ) THEN
       RETURN cBrDok;
    END IF;
    RETURN btrim(to_char(nRet,'9999'));
END;
$$;

DROP FUNCTION IF EXISTS public.kalk_22_neobradjeni_dokumenti;

CREATE OR REPLACE FUNCTION public.kalk_22_neobradjeni_dokumenti() RETURNS TABLE( pkonto varchar, brdok varchar, datdok date, brfaktp varchar )
LANGUAGE plpgsql
AS $$
DECLARE
  cIdFirma varchar;
  nRet integer;
BEGIN

    -- k22.dok_id <-> k11.ref znaci da postoji obradjen dokument 11
    RETURN QUERY select k22.pkonto::varchar, k22.brdok::varchar, k22.datdok::date, k22.brfaktp::varchar from f18.kalk_doks k22
        left join f18.kalk_doks k11
        on k11.ref=k22.dok_id
        where k22.idvd='22' and k11.pkonto IS null and k22.opis not like '%ODBIJENO%';

END;
$$;

DROP FUNCTION IF EXISTS public.kalk_22_to_11( cPKonto varchar, cBrDok varchar );

CREATE OR REPLACE FUNCTION public.kalk_22_to_11( cPKonto varchar, cBrDok varchar ) RETURNS varchar
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   nRet integer;
   cBrDokNew varchar;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
    cBrDokNew := public.kalk_novi_brdok_11( cPKonto );
    SELECT public.kalk_from_idvd_to_idvd( cIdFirma, '22', '11', cBrDok, cBrDokNew )
       INTO nRet;

    IF ( nRet = 0 ) THEN
       RETURN cBrDokNew;
    ELSE
       RETURN btrim(to_char(nRet, '9999'));
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_kalk_ref_by_brfaktp( cIdFirma varchar, cIdVd varchar, cBrdok varchar, cBrFaktP varchar)
   RETURNS integer
   LANGUAGE plpgsql
AS $$
DECLARE
  uuidDokId uuid;
BEGIN
  IF cIdVd <> '11' THEN
     RETURN -1;
  END IF;

  -- trazimo 22 dokument na koji se referenciramo
  SELECT dok_id FROM f18.kalk_doks where idvd='22' and brfaktp=cBrFaktP
    INTO uuidDokId;

  IF uuidDokId IS NULL THEN
     RETURN -2;
  END IF;

  UPDATE f18.kalk_doks SET ref=uuidDokId
      WHERE idfirma=cIdFirma and idvd=cIdVd and brdok=cBrDok;
  RETURN 0;

END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_71_to_79_dokumenti( nProdavnica integer, dDatum date )
       RETURNS TABLE (brdok varchar, prod text, mjesec text, dan text, broj text )
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   cBrDok varchar;
   nRet integer;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;

    -- kalk_doks 71 koje nemaju svoje 79-ke
    -- brdok 02032301 -> prodavnica 02, mjesec 03, dan 23, dokument 01
    RETURN QUERY SELECT doks71.brdok::varchar, substr(doks71.brdok,1,2) as prod,
        substr(doks71.brdok,3,2) as mjesec, substr(doks71.brdok,5,2) as dan, substr(doks71.brdok,7,2) as broj
        FROM public.kalk_doks doks71
        LEFT JOIN public.kalk_doks doks79
        ON doks71.idfirma=doks79.idfirma AND doks71.brdok=doks79.brdok AND doks71.idvd='71' AND doks79.idvd='79'
        WHERE doks71.idfirma=cIdFirma AND doks71.idvd='71' AND doks71.datdok=dDatum
              AND doks79.brdok IS NULL
        ORDER BY doks71.brdok;

END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_71_to_79( cBrDok varchar ) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   nRet integer;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
    SELECT public.kalk_from_idvd_to_idvd( cIdFirma, '71', '79', cBrDok, cBrDok )
       INTO nRet;
    RETURN nRet;
END;
$$;



CREATE OR REPLACE FUNCTION public.kalk_89_to_81_dokumenti( nProdavnica integer, dDatum date )
       RETURNS TABLE (brdok varchar, prod text, mjesec text, dan text, broj text )
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   cBrDok varchar;
   nRet integer;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;

    -- kalk_doks 89 koje nemaju svoje 81-ke
    -- brdok 02032301 -> prodavnica 02, mjesec 03, dan 23, dokument 01
    RETURN QUERY SELECT doks89.brdok::varchar, substr(doks89.brdok,1,2) as prod,
        substr(doks89.brdok,3,2) as mjesec, substr(doks89.brdok,5,2) as dan, substr(doks89.brdok,7,2) as broj
        FROM public.kalk_doks doks89
        LEFT JOIN public.kalk_doks doks81
        ON doks89.idfirma=doks81.idfirma AND doks89.brdok=doks81.brdok AND doks89.idvd='89' AND doks81.idvd='81'
        WHERE doks89.idfirma=cIdFirma AND doks89.idvd='89' AND doks89.datdok=dDatum
              AND doks81.brdok IS NULL
        ORDER BY doks89.brdok;

END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_89_to_81( cBrDok varchar ) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
   cIdFirma varchar;
   nRet integer;
BEGIN
    SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
    SELECT public.kalk_from_idvd_to_idvd( cIdFirma, '89', '81', cBrDok, cBrDok )
       INTO nRet;
    RETURN nRet;
END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_idpartner_by_brdok( cIdFirma varchar, cIdVd varchar, cBrDok varchar ) RETURNS varchar
LANGUAGE plpgsql
AS $$
DECLARE
   cIdPartner varchar;
BEGIN
    SELECT idpartner from public.kalk_doks WHERE cIdFirma=idfirma and cIdVd=idvd and cBrDok=brDok
       INTO cIdPartner;

    RETURN coalesce(cIdPartner, '');
END;
$$;


CREATE OR REPLACE FUNCTION public.run_cron() RETURNS void
  LANGUAGE plpgsql
  AS $$
DECLARE
  cJSon text;
BEGIN
   PERFORM public.setmetric('run_cron_time', now()::text);

   SET SESSION AUTHORIZATION admin;

   BEGIN
      -- 40 sarajevo
      select json_agg(t)::text from
      (
       select * from (
         select * from  public.prodavnica_zahtjev_prijem_magacin_create( '1', 40, current_date)
         ) s1
       ) t INTO cJSon;
      cJSON := coalesce(cJSON, '?ERROR?');
      insert into public.log(user_code, msg) values(current_user, 'CRON_ZPROPMAG: Srv[SA] ' || cJson);

   EXCEPTION WHEN OTHERS THEN
      RAISE INFO 'Srv[SA] - 40 ERROR?!';
   END;

   BEGIN
      -- 942 Bihac
      select json_agg(t)::text from
      (
         select * from (
            select * from  public.prodavnica_zahtjev_prijem_magacin_create( '2', 942, current_date)
          ) s1
      ) t INTO cJSon;
      cJSON := coalesce(cJSON, '?ERROR?');
      insert into public.log(user_code, msg) values(current_user, 'CRON_ZPROPMAG: Srv[BIH] ' || cJson);

   EXCEPTION WHEN OTHERS THEN
      RAISE INFO 'Srv[BIH] - 942 error?!';
   END;

   BEGIN
       -- 598 BL
       select json_agg(t)::text from
       (
           select * from (
              select * from  public.prodavnica_zahtjev_prijem_magacin_create( '3', 598, current_date)
            ) s1
       ) t INTO cJSon;
       cJSON := coalesce(cJSON, '?ERROR?');
       insert into public.log(user_code, msg) values(current_user, 'CRON_ZPROPMAG: Srv[BL] ' || cJson);

   EXCEPTION WHEN OTHERS THEN
      RAISE INFO 'Srv[BL] - 598 error?!';
   END;

   PERFORM public.cron_kontiranje_29_zadnja_sedmica();

   -- brisanje logova od prije tri dana
   delete from log where ( date(l_time) <= (current_date-3) ) and msg like 'CRON_ZPROPMAG:%';

   RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_glavni_konto( cIdVd varchar, cPKonto varchar, cMKonto varchar) RETURNS varchar
LANGUAGE plpgsql
AS $$
BEGIN
  IF cIdvd IN ('29','19','42') THEN
      RETURN cPKonto;
  ELSE
      RETURN cMKonto;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.km_to_euro( nKM numeric ) RETURNS numeric
LANGUAGE plpgsql
AS $$
BEGIN
   return nKM / 1.95583;
END;
$$;


CREATE OR REPLACE FUNCTION public.kalk_kontiranje_stavka(
  cIdVd varchar, cBrDok varchar, cPKonto varchar, cMKonto varchar,
  cIdRoba varchar, cIdTarifa varchar,
  nRbr integer, nKolicina numeric, nNC numeric, nMPC numeric, nMPCSAPDV numeric,
  dDatDok date, cBrFaktP varchar
) RETURNS integer
   LANGUAGE plpgsql
AS $$
DECLARE
   cIdFirma varchar;
   rec_koncij RECORD;
   rec_trfp RECORD;
   rec_suban RECORD;
   rec_nalog RECORD;
   cBrNal varchar;
   cIdVn varchar;
   cDP varchar;
   cShema varchar;
   cIdKonto varchar;
   nNV numeric;
   nMPVSaPDV numeric;
   nMPV numeric;
   nPDV numeric;
   nRUCMp numeric;
   nIznos numeric;
   nMaxRbr numeric;
   aArray text[];
   nRows integer;
   cMsg varchar;
BEGIN

   SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
   cIdFirma := trim( cIdFirma );
   cBrNal := cBrDok;
   cBrFaktP := coalesce(cBrFaktP, '');
   cPKonto := coalesce(cPKonto, '');
   cMKonto := coalesce(cMKonto, '');

   SELECT * from koncij where trim(id)=public.kalk_glavni_konto( cIdVd, cPKonto, cMKonto )
       INTO rec_koncij;

   -- pos -> kalk_doks opis: ROWS: [25] => 25 redova
   SELECT regexp_matches( trim(opis), 'ROWS:\s*\[(\d+)\]' ) FROM public.kalk_doks
      where idfirma=cIdFirma AND idvd=cIdVd AND brdok=cBrdok
      INTO aArray;

   IF aArray IS NOT NULL AND array_length( aArray, 1 ) = 1 THEN
      nRows := to_number( aArray[1], '99999' );
   ELSE
      nRows := -1;
   END IF;

   IF rec_koncij IS NULL THEN
      RAISE EXCEPTION '% konto % shema ne postoji?!', cIdVd, public.kalk_glavni_konto( cIdVd, cPKonto, cMKonto );
   END IF;

   cShema := rec_koncij.shema;

   SELECT idvn FROM public.trfp WHERE shema=cShema AND idvd=cIdVd
     INTO cIdVn;

   IF (nRbr = 1) THEN -- prva stavka kalk dokumenta
      RAISE INFO 'KALK RBR=1 => fin_suban, fin_nalog, fin_sint, fin_anal delete %-%-%', cIdFirma, cIdVn, cBrNal;
      DELETE FROM fmk.fin_nalog
         WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;
      DELETE FROM fmk.fin_suban
         WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;
      DELETE FROM fmk.fin_anal
         WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;
      DELETE FROM fmk.fin_sint
         WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;
   END IF;

   cMsg := format('%s / %s : roba: %s kol: %s mpc: %s mpcsapp: %s ; ROWS %s', cBrNal, cPKonto, cIdRoba, nKolicina, nMPC, nMPCSAPDV, nRows);
   PERFORM public.logiraj( current_user::varchar, 'KALK_TRIG_29', cMsg);

   FOR rec_trfp IN SELECT * FROM public.trfp WHERE shema=cShema AND idvd=cIdVd
       AND btrim(id)<>'ZAOKRUZENJE'
   LOOP

      cDP := rec_trfp.d_p;
      IF rec_trfp.idkonto='PKONTO' THEN
         cIdKonto := cPKonto;
      ELSE
         cIdKonto := cMKonto;
      END IF;
      nMPVSaPDV := nMpcSaPDV * nKolicina;
      nMPV := nMPC * nKolicina;
      nPDV := (nMpcSaPDV - nMPC) * nKolicina;
      nNV := nNC * nKolicina;
      nRUCMP := nMPV - nNV;
      IF rec_trfp.idkonto='PKONTO' THEN
         cIdKonto := cPKonto;
      ELSIF rec_trfp.idkonto='MKONTO' THEN
         cIdKonto := cMKonto;
      ELSE
         cIdKonto := rec_trfp.idkonto;
         cIdKonto := replace( cIdKonto, 'A1', right(trim(cPKonto),1) );
         cIdKonto := replace( cIdKonto, 'A2', right(trim(cPKonto),2) );
         cIdKonto := replace( cIdKonto, 'B1', right(trim(cMKonto),1) );
         cIdKonto := replace( cIdKonto, 'B2', right(trim(cMKonto),2) );
      END IF;

      cIdKonto := rpad(trim(cIdKonto),7);
      CASE trim(rec_trfp.id)
       WHEN 'MPVSAPDV' THEN
           nIznos := nMPVSaPDV;
           RAISE INFO '% Kontiranje: MPVSAPDV %', cIdKonto, nIznos;
       WHEN 'MPV' THEN
           nIznos := nMPV;
           RAISE INFO '% Kontiranje: MPV %', cIdKonto, nIznos;
       WHEN 'PDV' THEN
           nIznos := nPDV;
           RAISE INFO '% Kontiranje: PDV %', cIdkonto, nIznos;
       WHEN 'NV' THEN
          nIznos := nNV;
          RAISE INFO '% Kontiranje: NV %', cIdKonto, nIznos;
       ELSE
          nIznos := 0;
      END CASE;

      nIznos := coalesce( nIznos, 0);
      IF (rec_trfp.znak = '-') THEN
         nIznos := -nIznos;
      END IF;

      SELECT * from fmk.fin_nalog
          where idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
          INTO rec_nalog;
      IF rec_nalog IS NULL THEN
        INSERT INTO fmk.fin_nalog(idfirma, idvn, brnal, korisnik, datnal)
                  values(cIdFirma, cIdVn, cBrNal, current_user::text, dDatDok);
      ELSE
        UPDATE fmk.fin_nalog set datnal=dDatDok, obradjeno=now(), korisnik=current_user::text
          where idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal;
      END IF;

      RAISE INFO 'fin_suban seek %-%-% [%]', cIdFirma, cIdVn, cBrNal, cIdKonto;

      SELECT * from fmk.fin_suban
          WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and trim(idkonto)=trim(cIdKonto)
          INTO rec_suban;

      IF rec_suban IS NULL THEN
           SELECT max(rbr) FROM fmk.fin_suban
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
              INTO nMaxRbr;
           nMaxRbr := coalesce( nMaxRbr, 0);
           INSERT INTO fmk.fin_suban(idfirma,idvn,brnal,idkonto,opis,d_p,iznosbhd,iznosdem,idpartner,datdok,brdok,rbr,k1,k2,k3,k4,m1,m2,idrj,funk,fond,otvst,idtipdok)
              values(cIdFirma, cIdVn, cBrNal, cIdKonto, rec_trfp.naz, cDP, nIznos, public.km_to_euro(nIznos),rpad('',6),dDatDok, cBrFaktP, nMaxRbr+1,'','','','','','','','','', ' ',cIdVn);
           RAISE INFO 'Kontiranje INSERT %-%-% [%] %', cIdFirma, cIdVn, cBrNal, cIdKonto, nIznos;
      ELSE
           UPDATE fmk.fin_suban
             SET iznosbhd=rec_suban.iznosbhd+nIznos, iznosdem=rec_suban.iznosdem+public.km_to_euro(nIznos)
             WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal AND trim(idkonto)=trim(cIdKonto);
           RAISE INFO 'Kontiranje UPDATE [%] % + % = %', cIdKonto, rec_suban.iznosbhd, nIznos, rec_suban.iznosbhd + nIznos;
      END IF;

   END LOOP;

   IF (nRbr >= nRows) THEN
      -- ako je potrebno prvo zatvoriti zaokruzenje
      PERFORM public.kalk_kontiranje_stavka_zaokruzenje( cIdVd, cBrDok, cPKonto, cMKonto );

      cMsg := format('ZADNJI RED %s / %s / ROWS %s', cBrNal, cIdKonto, nRows);
      PERFORM public.logiraj( current_user::varchar, 'KALK_TRIG_29_END', cMsg);

      RAISE INFO 'ZADNJI RED % - gen_anal_sint % !', nRows, public.fin_gen_anal_sint(cIdFirma, cIdVn, cBrNal);
   END IF;

   RETURN 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.kalk_kontiranje_stavka_zaokruzenje(
  cIdVd varchar, cBrDok varchar, cPKonto varchar, cMKonto varchar
) RETURNS integer
   LANGUAGE plpgsql
AS $$
DECLARE
   cIdFirma varchar;
   cBrNal varchar;
   cIdVn varchar;
   cDP varchar;
   cShema varchar;
   rec_trfp RECORD;
   cIdKonto varchar;
   nIznos numeric;
   nSaldo numeric;
   rec_koncij RECORD;
   rec_suban RECORD;
   nMaxRbr integer;
   dDatDok date;
BEGIN

   SELECT public.fetchmetrictext('org_id') INTO cIdFirma;
   cIdFirma := trim( cIdFirma );
   cBrNal := cBrDok;

   SELECT * from koncij where trim(id)=public.kalk_glavni_konto( cIdVd, cPKonto, cMKonto )
       INTO rec_koncij;

   IF rec_koncij IS NULL THEN
      RAISE EXCEPTION '% konto % shema ne postoji?!', cIdVd, public.kalk_glavni_konto( cIdVd, cPKonto, cMKonto );
   END IF;

   cShema := rec_koncij.shema;
   SELECT idvn FROM public.trfp WHERE shema=cShema AND idvd=cIdVd
     INTO cIdVn;

   SELECT * FROM public.trfp
       WHERE shema=cShema AND idvd=cIdVd AND btrim(id)='ZAOKRUZENJE'
       LIMIT 1
       INTO rec_trfp;

   SELECT max(datdok) from fmk.fin_suban
      WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
       INTO dDatDok;
      dDatdok := coalesce( dDatDok, current_date );

   IF rec_trfp IS NULL THEN
       RAISE EXCEPTION 'trfp ZAOKRUZENJE nije definisano za % %', cShema, cIdVd;
   END IF;

   IF rec_trfp.idkonto='PKONTO' THEN
        cIdKonto := cPKonto;
   ELSE
         cIdKonto := cMKonto;
   END IF;

   IF rec_trfp.idkonto='PKONTO' THEN
        cIdKonto := cPKonto;
   ELSIF rec_trfp.idkonto='MKONTO' THEN
         cIdKonto := cMKonto;
   ELSE
         cIdKonto := rec_trfp.idkonto;
         cIdKonto := replace( cIdKonto, 'A1', right(trim(cPKonto),1) );
         cIdKonto := replace( cIdKonto, 'A2', right(trim(cPKonto),2) );
         cIdKonto := replace( cIdKonto, 'B1', right(trim(cMKonto),1) );
         cIdKonto := replace( cIdKonto, 'B2', right(trim(cMKonto),2) );
    END IF;

    cIdKonto := rpad(trim(cIdKonto),7);
    nSaldo := public.fin_saldo(cIdFirma, cIdVn, cBrNal);
    cDP := rec_trfp.d_p;
    nIznos := coalesce( nIznos, 0);

    IF cDP = '1' THEN
        nIznos := -nSaldo;
    ELSE
        nIznos := nSaldo;
    END IF;
    IF (rec_trfp.znak = '-') THEN
         nIznos := -nIznos;
    END IF;

    IF nIznos = 0 THEN
         RETURN 0;
    END IF;

    RAISE INFO 'fin_suban seek %-%-% [%]', cIdFirma, cIdVn, cBrNal, cIdKonto;
    SELECT * from fmk.fin_suban
          WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and trim(idkonto)=trim(cIdKonto)
          INTO rec_suban;

    IF rec_suban IS NULL THEN
       SELECT max(rbr) FROM fmk.fin_suban
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
              INTO nMaxRbr;
        nMaxRbr := coalesce( nMaxRbr, 0);
        INSERT INTO fmk.fin_suban(idfirma,idvn,brnal,idkonto,opis,d_p,iznosbhd,iznosdem,datdok,idpartner,brdok,rbr)
              values(cIdFirma, cIdVn, cBrNal, cIdKonto, rec_trfp.naz, cDP, nIznos, public.km_to_euro(nIznos), dDatDok, '', 'ZAOKR', nMaxRbr+1);
        RAISE INFO 'Kontiranje INSERT %-%-% [%] %', cIdFirma, cIdVn, cBrNal, cIdKonto, nIznos;
    ELSE
        UPDATE fmk.fin_suban
             SET iznosbhd=rec_suban.iznosbhd+nIznos, iznosdem=rec_suban.iznosdem+public.km_to_euro(nIznos)
             WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal AND trim(idkonto)=trim(cIdKonto);
        RAISE INFO 'Kontiranje UPDATE [%] % + % = %', cIdKonto, rec_suban.iznosbhd, nIznos, rec_suban.iznosbhd + nIznos;
    END IF;

    RETURN 1;
END;
$$;


CREATE OR REPLACE FUNCTION public.fin_gen_anal_sint( cIdFirma varchar, cIdVN varchar, cBrNal varchar) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    rec_suban RECORD;
    rec_anal RECORD;
    rec_sint RECORD;
    nMaxRBR integer;
    dDatNal date;
    nIznosDug numeric;
    nIznosPot numeric;
    cRbr varchar;
    nCount integer;
    nIznosDugNalog numeric;
    nIznosPotNalog numeric;
BEGIN
    nCount := 0;
    nIznosDugNalog := 0;
    nIznosPotNalog := 0;

    DELETE FROM fmk.fin_anal
       WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;
    DELETE FROM fmk.fin_sint
       WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrnal;

    FOR rec_suban IN SELECT * FROM fmk.fin_suban
        where idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
        ORDER BY rbr
    LOOP

        SELECT max(datdok) from fmk.fin_suban
           WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and trim(idkonto)=trim(rec_suban.idkonto)
        INTO dDatNal;
        dDatNal := coalesce( dDatNal, current_date );
        IF rec_suban.d_p = '1' THEN
          nIznosDug := rec_suban.iznosbhd;
          nIznosPot := 0;
        ELSE
          nIznosDug := 0;
          nIznosPot := rec_suban.iznosbhd;
        END IF;

        nIznosDugNalog := nIznosDugNalog + nIznosDug;
        nIznosPotNalog := nIznosPotNalog + nIznosPot;

        -- analitika
        SELECT * from fmk.fin_anal
           WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and trim(idkonto)=trim(rec_suban.idkonto)
        INTO rec_anal;
        IF rec_anal IS NULL THEN
            SELECT max(to_number(rbr, '9999')) FROM fmk.fin_anal
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
            INTO nMaxRbr;
            nMaxRbr := coalesce( nMaxRbr, 0);
            cRbr := lpad(btrim(to_char(nMaxRbr+1,'9999')), 4, ' ');
            RAISE INFO 'anal INSERT % % dug=% pot=%', cRbr, trim(rec_suban.idkonto), nIznosDug, nIznosPot;
            INSERT INTO fmk.fin_anal(idfirma,idvn,brnal,idkonto,dugbhd,potbhd,dugdem,potdem,datnal,rbr)
               values(cIdFirma, cIdVn, cBrNal, trim(rec_suban.idkonto), nIznosDug, nIznosPot, public.km_to_euro(nIznosDug),public.km_to_euro(nIznosPot), dDatNal, cRbr);
        ELSE
           RAISE INFO 'anal UPDATE % dug=% pot=%', trim(rec_suban.idkonto), nIznosDug, nIznosPot;
           UPDATE fmk.fin_anal
              SET dugbhd=rec_anal.dugbhd + nIznosDug, potbhd=rec_anal.potbhd + nIznosPot, dugdem=rec_anal.dugdem + public.km_to_euro(nIznosDug), potdem=rec_anal.potdem + public.km_to_euro(nIznosPot)
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal AND trim(idkonto)=trim(rec_suban.idkonto);

        END IF;

        -- sitnetika
        SELECT max(datdok) from fmk.fin_suban
           WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and left(idkonto,3)=left(rec_suban.idkonto,3)
        INTO dDatNal;
        SELECT * from fmk.fin_sint
           WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal and left(idkonto,3)=left(rec_suban.idkonto,3)
        INTO rec_sint;
        IF rec_sint IS NULL THEN
            SELECT max(to_number(rbr, '9999')) FROM fmk.fin_sint
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
            INTO nMaxRbr;
            nMaxRbr := coalesce( nMaxRbr, 0);
            cRbr := lpad(btrim(to_char(nMaxRbr+1,'9999')), 4, ' ');
            RAISE INFO 'sint INSERT % % dug=% pot=%', cRbr, left(rec_suban.idkonto,3), nIznosDug, nIznosPot;
            INSERT INTO fmk.fin_sint(idfirma,idvn,brnal,idkonto,dugbhd,potbhd,dugdem,potdem,datnal,rbr)
               values(cIdFirma, cIdVn, cBrNal, left(rec_suban.idkonto,3), nIznosDug, nIznosPot, public.km_to_euro(nIznosDug),public.km_to_euro(nIznosPot), dDatNal, cRbr);
        ELSE
           RAISE INFO 'sint UPDATE % dug=% pot=%', left(rec_suban.idkonto,3), nIznosDug, nIznosPot;
           UPDATE fmk.fin_sint
              SET dugbhd=rec_sint.dugbhd + nIznosDug, potbhd=rec_sint.potbhd + nIznosPot, dugdem=rec_sint.dugdem + public.km_to_euro(nIznosDug), potdem=rec_sint.potdem + public.km_to_euro(nIznosPot)
              WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal AND left(idkonto,3)=left(rec_suban.idkonto,3);

        END IF;

        nCount := nCount + 1;
    END LOOP;

    UPDATE fmk.fin_nalog set dugbhd=nIznosDugNalog, potbhd=nIznosPotNalog, dugdem=public.km_to_euro(nIznosDugNalog), potdem=public.km_to_euro(nIznosPotNalog)
        WHERE idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal;

    RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION public.fin_saldo( cIdFirma varchar, cIdVN varchar, cBrNal varchar) RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
    rec_suban RECORD;
    nSaldo numeric;
BEGIN
    nSaldo := 0;
    FOR rec_suban IN SELECT * FROM fmk.fin_suban
        where idfirma=cIdFirma and idvn=cIdVn and brnal=cBrNal
    LOOP
        IF rec_suban.d_p = '1' THEN
           nSaldo := nSaldo + rec_suban.iznosbhd;
        ELSE
           nSaldo := nSaldo - rec_suban.iznosbhd;
        END IF;
    END LOOP;

    RETURN nSaldo;
END;
$$;

-- DROP FUNCTION IF EXISTS public.kalk_kontiranje(character varying,character varying,character varying);

CREATE OR REPLACE FUNCTION public.kalk_kontiranje( cIdFirma varchar, cIdVD varchar, cBrDok varchar) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    rec_kalk RECORD;
    nCount integer;
BEGIN
   nCount := 0;
   FOR rec_kalk IN select * from kalk_kalk
      WHERE idfirma=cIdFirma AND idvd=cIdVD AND brdok=cBrDok
      ORDER BY rbr
   LOOP
       PERFORM public.kalk_kontiranje_stavka(
         rec_kalk.idvd, rec_kalk.brdok, rec_kalk.pkonto, rec_kalk.mkonto,
         rec_kalk.idroba, rec_kalk.idtarifa,
         rec_kalk.rbr, rec_kalk.kolicina, rec_kalk.nc, rec_kalk.mpc, rec_kalk.mpcsapp,
         rec_kalk.datdok, rec_kalk.brfaktp
       );
       nCount := nCount + 1;
  END LOOP;
  RETURN nCount;
END;
$$;


CREATE OR REPLACE FUNCTION public.cron_kontiranje_29_zadnja_sedmica() RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE
       rec_kalk record;
       nCount integer;
BEGIN
     nCount := 0;

     FOR rec_kalk IN SELECT kalk_doks.idfirma,kalk_doks.idvd,kalk_doks.brdok from kalk_doks
       LEFT JOIN fmk.fin_nalog on kalk_doks.idfirma=fin_nalog.idfirma and kalk_doks.idvd=fin_nalog.idvn and kalk_doks.brdok=fin_nalog.brnal
       WHERE idvd='29' and datdok>current_date-7 and datdok<=current_date and dugbhd is null
       ORDER BY datdok
     LOOP
          PERFORM public.kalk_kontiranje( rec_kalk.idfirma, rec_kalk.idvd, rec_kalk.brdok );
          nCount := nCount + 1;
     END LOOP;

     RETURN nCount;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_sifk(param_id character varying, param_oznaka character varying, param_sif character varying, OUT vrijednost text) RETURNS text
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


CREATE OR REPLACE FUNCTION public.convert_to_integer(v_input text) RETURNS integer
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
