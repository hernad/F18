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
