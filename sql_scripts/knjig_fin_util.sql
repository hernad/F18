CREATE OR REPLACE FUNCTION public.zatvori_otvst(
	cidkonto text,
	cidpartner text,
	cbrdok text)
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



