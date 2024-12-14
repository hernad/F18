-- fakt_ofs v1.0.0

ALTER TABLE fmk.fakt_doks add column dok_id uuid default gen_random_uuid();


CREATE TABLE IF NOT EXISTS public.fakt_fisk_doks_ofs (
    dok_id uuid DEFAULT gen_random_uuid(),
    ref_fakt_dok uuid,
    invoice_number text,
    sdc_date_time text,
    ref_storno_fisk_dok uuid,
    partner_id uuid,
    ukupno real,
    popust real,
    json_response jsonb,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);

ALTER TABLE public.fakt_fisk_doks_ofs OWNER TO admin;

GRANT ALL ON TABLE public.fakt_fisk_doks_ofs TO xtrole;


DO $$
BEGIN
   ALTER TABLE public.fakt_fisk_doks_ofs ADD PRIMARY KEY (dok_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'fakt_fisk_doks_ofs primary key garant postoji';
END;
$$;

DO $$
BEGIN
   CREATE UNIQUE INDEX IF NOT EXISTS fakt_fisk_doks_ofs_unique ON public.fakt_fisk_doks_ofs USING btree (invoice_number, sdc_date_time);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'fakt_fisk_doks_ofs_unique garant postoji';
END;
$$;

-- vraca dok_id iz tabele fiskalnih racuna ofs za zadani FAKT dokument

CREATE OR REPLACE FUNCTION public.fisk_dok_ofs_id( cIdFirma varchar, cIdTipdok varchar, cBrDok varchar) RETURNS text
 LANGUAGE plpgsql
 AS $$
DECLARE
   fiskUUID uuid;
BEGIN

 SELECT fakt_fisk_doks_ofs.dok_id FROM fmk.fakt_doks
    LEFT JOIN public.fakt_fisk_doks_ofs
    ON public.fakt_fisk_doks_ofs.ref_fakt_dok = fmk.fakt_doks.dok_id
    WHERE fakt_doks.idFirma=cIdFirma AND fakt_doks.idtipdok=cIdTipdok  AND fakt_doks.brDok=cBrDok
    INTO fiskUUID;
 
 IF fiskUUID IS NULL THEN
      RAISE INFO 'fakt_doks % % % ne postoji ?!', cIdFirma, cIdTipdok, cBrDok;
      RETURN '';
 END IF;
 
 RETURN fiskUUID::text;
 
END;
$$;


CREATE OR REPLACE FUNCTION public.set_ref_storno_fisk_dok_ofs( cIdFirma varchar, cIdTipDok varchar, cBrDok varchar, uuidFiskStorniran text ) RETURNS void
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidFiskNovi uuid;
BEGIN

  uuidFiskNovi := public.fisk_dok_ofs_id( cIdFirma, cIdTipdok, cBrDok);
  UPDATE public.fakt_fisk_doks_ofs SET ref_storno_fisk_dok = uuidFiskStorniran::uuid
      WHERE dok_id = uuidFiskNovi;

END;
$$;


-- F18 FUNCTION fakt_set_broj_fiskalnog_racuna_ofs( cIdFirma, cIdTipDok, cBrDok, cBrojFRacuna, cDatFRacuna, cJson )
-- TEST:
-- insert into public.fakt_doks(idfirma, idtipdok, brdok, datum) values('1 ', '42', 'XX', current_date );

-- SET
-- select public.broj_fiskalnog_racuna( '1 ', '42', current_date, lpad('2',8), "101-102-103", "20240101", "{jsonfiskalnog racuna}" );
-- GET
-- select public.broj_fiskalnog_racuna( '1 ', '42', current_date, 'XX', NULL );

-- select * from public.fakt_doks;
-- select * from public.fakt_fisk_doks;

CREATE OR REPLACE FUNCTION public.broj_fiskalnog_racuna_ofs( cIdFirma varchar, cIdTipDok varchar, cBrDok varchar, cBrojFRacuna varchar, cDatFRacuna varchar, cJson varchar) RETURNS varchar
 LANGUAGE plpgsql
 AS $$
DECLARE
   faktUUID uuid;
   fiskUUID uuid;
BEGIN

SELECT dok_id FROM fmk.fakt_doks
   WHERE idFirma=cIdFirma AND idTipDok=cIdTipDok AND brDok=cBrDok
   INTO faktUUID;

IF faktUUID IS NULL THEN
     RAISE INFO 'fakt % % % ne postoji ?!', cIdFirma, cIdTipDok, cBrDok;
     RETURN '';
END IF;

-- get broj racuna
IF cBrojFRacuna IS NULL THEN
    SELECT invoice_number || '-'  sdc_date_time FROM public.fakt_fisk_doks_ofs where ref_fakt_dok=faktUUID
      INTO cBrojFRacuna;
    RETURN COALESCE( cBrojFRacuna, '-');
END IF;

IF ( cBrojFRacuna = '-' ) THEN -- insert null vrijednost za broj fiskalnog racuna
    cBrojFRacuna := NULL;
    cDatFRacuna := NULL;
END IF;

SELECT dok_id FROM public.fakt_fisk_doks_ofs
   WHERE ref_fakt_dok = faktUUID
   INTO fiskUUID;

IF fiskUUID IS NULL THEN
    INSERT INTO public.fakt_fisk_doks_ofs(ref_fakt_dok, invoice_number, sdc_date_time, json_response) VALUES(faktUUID, cBrojFRacuna, cDatFRacuna, cJson::jsonb);
ELSE
    UPDATE public.fakt_fisk_doks_ofs set invoice_number=cBrojFRacuna, sdc_date_time=cDatFRacuna, json_response=cJson::jsonb, obradjeno=now() WHERE ref_fakt_dok=faktUUID;
END IF;

RETURN COALESCE( cBrojFRacuna, '');

END;
$$;


CREATE OR REPLACE FUNCTION public.get_broj_dat_fiskalnog_racuna_ofs( cIdFirma varchar, cIdTipDok varchar, cBrDok varchar) RETURNS varchar
 LANGUAGE plpgsql
 AS $$
DECLARE
   cBrojFRacuna varchar;
   faktUUID uuid;
   fiskUUID uuid;
BEGIN

SELECT dok_id FROM fmk.fakt_doks
   WHERE idfirma=cIdFirma AND idtipdok=cIdTipDok AND brDok=cBrDok
   INTO faktUUID;

IF faktUUID IS NULL THEN
     RAISE INFO 'fakt % % % ne postoji ?!', cIdFirma, cIdTipDok, cBrDok;
     RETURN '_';
END IF;

SELECT invoice_number || '_' || sdc_date_time FROM public.fakt_fisk_doks_ofs where ref_fakt_dok=faktUUID
    INTO cBrojFRacuna;


RETURN COALESCE( cBrojFRacuna, '');

END;
$$;



CREATE OR REPLACE FUNCTION public.fisk_broj_rn_by_storno_ref_ofs( uuidFiskStorniran text ) RETURNS varchar
 LANGUAGE plpgsql
 AS $$
DECLARE
   cBrojRacuna varchar;
   nCount integer;
BEGIN

SELECT count(*) FROM public.fakt_fisk_doks_ofs
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO nCount;

IF (nCount = 0) THEN
      RETURN '_'; -- uopste nema fakt_fisk_doks_ofs zapisa
END IF;

SELECT invoice_number || '_' || sdc_date_time FROM public.fakt_fisk_doks_ofs
   WHERE ref_storno_fisk_dok = uuidFiskStorniran::uuid
   INTO cBrojRacuna;

RETURN COALESCE(cBrojRacuna, '_');

END;
$$;



CREATE OR REPLACE FUNCTION public.fakt_storno_broj_rn_ofs( cIdFirma varchar, cIdTipDok varchar, dDatDok date, cBrDok varchar) RETURNS varchar
 LANGUAGE plpgsql
 AS $$
DECLARE
   cStornoBrojRn varchar;
BEGIN

SELECT fisk2.invoice_number || '_' || fisk2.sdc_date_time FROM fmk.fakt_doks
   LEFT JOIN public.fakt_fisk_doks_ofs as fisk1
   ON fisk1.ref_fakt_dok = fmk.fakt_doks.dok_id
   LEFT JOIN public.fakt_fisk_doks_ofs as fisk2
   ON fisk1.ref_storno_fisk_dok = fisk2.dok_id
   WHERE fmk.fakt_doks.idfirma=cIdFirma AND fmk.fakt_doks.idtipdok=cIdTipDok AND fmk.fakt_doks.datdok=dDatDok AND fmk.fakt_doks.brdok=cBrDok
   INTO cStornoBrojRn;

IF cStornoBrojRn IS NULL THEN
     RETURN '_';
END IF;

RETURN cStornoBrojRn;

END;
$$;


CREATE OR REPLACE FUNCTION public.fakt_is_storno_ofs(cIdFirma varchar, cIdTipDok varchar, cBrDok varchar) RETURNS boolean
 LANGUAGE plpgsql
 AS $$
DECLARE
   uuidStorno uuid;
BEGIN

SELECT fakt_fisk_doks_ofs.ref_storno_fisk_dok FROM fmk.fakt_doks
   LEFT JOIN public.fakt_fisk_doks_ofs
   ON public.fakt_fisk_doks_ofs.ref_fakt_dok = fmk.fakt_doks.dok_id
   WHERE fmk.fakt_doks.idfirma=cIdFirma AND fmk.fakt_doks.idtipdok=cIdTipDok AND fmk.fakt_doks.brdok=cBrDok
   INTO uuidStorno;

IF uuidStorno IS NULL THEN
     RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;

