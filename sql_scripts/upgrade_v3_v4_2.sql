DELETE from f18.kalk_kalk where brdok is null or btrim(brdok)='';
DELETE from f18.kalk_doks where brdok is null or btrim(brdok)='';

ALTER TABLE f18.kalk_doks ADD COLUMN IF NOT EXISTS datfaktp date;

CREATE OR REPLACE FUNCTION datfaktp_from_kalk_kalk(cIdFirma varchar, cIdVd varchar, cBrDok varchar ) RETURNS date
LANGUAGE plpgsql
AS $$
DECLARE
   dDatFaktP date;
BEGIN
   SELECT datfaktp from f18.kalk_kalk where idfirma=cIdFirma and idvd=cIdVd and brdok=cBrDok LIMIT 1
      INTO dDatFaktP;

  RETURN dDatFaktP;
END;
$$;


DO $$
DECLARE
   nRbr numeric;
BEGIN

    -- check if rbr is char, ako nije STOP => exception
   select to_number(rbr, '999') from f18.kalk_kalk LIMIT 1
      INTO nRbr;

   update f18.kalk_doks set datfaktp=datfaktp_from_kalk_kalk(idfirma, idvd, brdok);

   alter table f18.kalk_kalk rename column rbr to c_rbr;
   alter table f18.kalk_kalk add column rbr integer;
   update f18.kalk_kalk set rbr = to_number(c_rbr, '999') WHERE rbr is NULL;
   alter table f18.kalk_kalk drop column c_rbr;

EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'rbr is not char';

END;
$$;

