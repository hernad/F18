DO $$
DECLARE
  nCount numeric;
BEGIN
    BEGIN
      SELECT count(*) as count from f18.kalk_kalk where btrim(coalesce(idzaduz2,''))<>''
        INTO nCount;
      IF (nCount > 1) THEN
         RAISE EXCEPTION 'kalk idzaduz2 se koristi % !?', nCount
            USING HINT = 'Vjerovatno ima veze sa pracenjem proizvodnje';
      END IF;
      ALTER TABLE f18.kalk_doks DROP COLUMN idzaduz;
      ALTER TABLE f18.kalk_doks DROP COLUMN idzaduz2;
      ALTER TABLE f18.kalk_doks DROP COLUMN sifra;

      ALTER TABLE f18.kalk_kalk DROP COLUMN idzaduz;
      ALTER TABLE f18.kalk_kalk DROP COLUMN idzaduz2;
      ALTER TABLE f18.kalk_kalk DROP COLUMN fcj3;
      ALTER TABLE f18.kalk_kalk DROP COLUMN vpcsap;

	EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'idzaduz2 garant ne postoji';
	END;
END;
$$;
