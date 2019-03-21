
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
  RETURN lpad(btrim(to_char(nextval('f18.kalk_brdok_seq_' || cIdVd), '99999999')), 8, '0');
END;
$$;

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
ELSIF ( ( idvdKalk = '71' ) OR ( idvdKalk = '61' ) OR ( idvdKalk = '22' ) OR ( idvdKalk = '29' ) ) THEN
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


CREATE OR REPLACE FUNCTION public.roba_id_by_sifradob(nRobaId integer) RETURNS varchar
   LANGUAGE plpgsql
AS $$
DECLARE
  cIdRoba varchar;
BEGIN

SELECT id from public.roba where lpad(btrim(sifradob),5,'0')=lpad(btrim(to_char(nRobaId,'99999')),5,'0')
  INTO cIdRoba;

RETURN COALESCE(cIdRoba, '<UNDEFINED>');

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


CREATE OR REPLACE FUNCTION public.kalk_pkonto_brfaktp_exists( cPKonto varchar,  cBrFaktP varchar) RETURNS boolean
   LANGUAGE plpgsql
AS $$
DECLARE
   dokId uuid;
   lExist boolean;
BEGIN
   select dok_id FROM f18.kalk_doks where pkonto=cPKonto AND brfaktp=cBrFaktP
      INTO dokId;
   IF (dokId IS NULL) THEN
      RETURN False;
   END IF;
   RETURN True;

END;
$$;
