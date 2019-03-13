CREATE OR REPLACE FUNCTION public.kalk_novi_brdok(cIdVd varchar) RETURNS varchar
   LANGUAGE plpgsql
AS $$
BEGIN
  RETURN lpad(btrim(to_char(nextval('f18.kalk_brdok_seq_' || cIdVd), '99999999')), 8, '0');
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
