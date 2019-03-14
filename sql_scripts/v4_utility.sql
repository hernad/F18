CREATE OR REPLACE FUNCTION public.kalk_novi_brdok(cIdVd varchar) RETURNS varchar
   LANGUAGE plpgsql
AS $$
BEGIN
  RETURN lpad(btrim(to_char(nextval('f18.kalk_brdok_seq_' || cIdVd), '99999999')), 8, '0');
END;
$$


-- POS 42 - racuni, zbirno u KALK
-- SELECT public.kalk_brdok_iz_pos('15', '49', '4', current_date); => 150214
-- POS 71 - dokument, zahtjev za snizenje - pojedinacno u KALK
-- SELECT public.kalk_brdok_iz_pos('15', '71', '    3', current_date); => 15021403

CREATE OR REPLACE FUNCTION public.kalk_brdok_iz_pos(
   idpos varchar,
   idvdKalk varchar,
   posBrdok varchar,
   datum date) RETURNS varchar

LANGUAGE plpgsql
AS $$
DECLARE
  brdok varchar;
BEGIN

IF ( idvdKalk = '49' ) THEN
  -- 01.02.2019, idpos=15 -> 150201
  SELECT TO_CHAR(datum, idpos || 'mmdd' ) INTO brDok;
ELSIF ( ( idvdKalk = '71' ) OR ( idvdKalk = '61' ) OR ( idvdKalk = '22' ) OR ( idvdKalk = '29' ) ) THEN
   -- 01.02.2019, brdok='      3' -> 15020103
   SELECT TO_CHAR(datum, idpos || 'mmdd' ) || lpad(btrim(posBrdok), 2, '0') INTO brDok;
ELSE
   RAISE EXCEPTION 'ERROR kalk_brdok_iz_pos % % % %', idPos, idvdKalk, posBrdok, datum;
END IF;

RETURN brDok;

END;
$$


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
