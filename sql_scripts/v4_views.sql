
CREATE OR REPLACE FUNCTION public.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM f18.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$$;

CREATE OR REPLACE FUNCTION public.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM f18.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM f18.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE f18.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO f18.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$$;

ALTER FUNCTION public.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION public.fetchmetrictext TO xtrole;

ALTER FUNCTION public.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION public.setmetric TO xtrole;


--------------------------------------------------------------------------------
-- F18 v4 public kalk_kalk, kalk_doks updatable views
-------------------------------------------------------------------------------
drop view if exists public.kalk_kalk;
CREATE view public.kalk_kalk AS SELECT
     idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
     brfaktp, idpartner,
     rbr,
     kolicina, gkolicina, gkolicin2,
     fcj, fcj2,
     trabat,rabat,
     tprevoz,prevoz,
     tprevoz2,prevoz2,
     tbanktr,banktr,
     tspedtr,spedtr,
     tcardaz,cardaz,
     tzavtr,zavtr,
     tmarza,marza,
     nc, vpc,
     rabatv,
     tmarza2, marza2,
     mpc, idtarifa,
     mpcsapp,
     mkonto,pkonto,mu_i,pu_i,
     error,
     dok_id
FROM
  f18.kalk_kalk;

CREATE OR REPLACE RULE public_kalk_kalk_ins AS ON INSERT TO public.kalk_kalk
      DO INSTEAD INSERT INTO f18.kalk_kalk(
         idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
         brfaktp, idpartner,
         rbr,
         kolicina, gkolicina, gkolicin2,
         fcj, fcj2,
         trabat,rabat,
         tprevoz,prevoz,
         tprevoz2,prevoz2,
         tbanktr,banktr,
         tspedtr,spedtr,
         tcardaz,cardaz,
         tzavtr,zavtr,
         tmarza,marza,
         nc, vpc,
         rabatv,
         tmarza2, marza2,
         mpc, idtarifa,
         mpcsapp,
         mkonto,pkonto,mu_i,pu_i,
         error,
         dok_id
      ) VALUES (
        NEW.idfirma, NEW.idroba, NEW.idkonto, NEW.idkonto2, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.idpartner,
        NEW.rbr,
        NEW.kolicina, NEW.gkolicina, NEW.gkolicin2,
        NEW.fcj, NEW.fcj2,
        NEW.trabat, NEW.rabat,
        NEW.tprevoz, NEW.prevoz,
        NEW.tprevoz2, NEW.prevoz2,
        NEW.tbanktr, NEW.banktr,
        NEW.tspedtr, NEW.spedtr,
        NEW.tcardaz, NEW.cardaz,
        NEW.tzavtr, NEW.zavtr,
        NEW.tmarza, NEW.marza,
        NEW.nc, NEW.vpc,
        NEW.rabatv,
        NEW.tmarza2, NEW.marza2,
        NEW.mpc, NEW.idtarifa,
        NEW.mpcsapp,
        NEW.mkonto, NEW.pkonto, NEW.mu_i,NEW.pu_i,
        NEW.error,
        kalk_dok_id(NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok) );

GRANT ALL ON public.kalk_kalk TO xtrole;

----------------------  public.kalk_doks ----------------------------------
DROP VIEW if exists public.kalk_doks;
CREATE view public.kalk_doks  AS SELECT
idfirma, idvd, brdok, datdok,
brfaktp, datfaktp, idpartner, datval,
dat_od, dat_do,
opis,
pkonto,mkonto,
nv,vpv,rabat,mpv,
obradjeno,
korisnik
FROM
  f18.kalk_doks;

CREATE OR REPLACE RULE public_kalk_doks_ins AS ON INSERT TO public.kalk_doks
      DO INSTEAD INSERT INTO f18.kalk_doks(
        idfirma, idvd, brdok, datdok,
        brfaktp, datfaktp, idpartner, datval,
        dat_od, dat_do,
        opis,
        pkonto,mkonto,
        nv,vpv,rabat,mpv
      ) VALUES (
        NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.datfaktp, NEW.idpartner, NEW.datval,
        NEW.dat_od, NEW.dat_do,
        NEW.opis,
        NEW.pkonto, NEW.mkonto,
        NEW.nv, NEW.vpv, NEW.rabat, NEW.mpv
      );


GRANT ALL ON public.kalk_doks TO xtrole;

----  public.tarifa
drop view if exists public.tarifa;
CREATE view public.tarifa  AS SELECT *
FROM
  f18.tarifa;

GRANT ALL ON public.tarifa TO xtrole;

-- public.koncij
drop view if exists public.koncij;
CREATE view public.koncij  AS
SELECT id, shema,
       naz, idprodmjes, region, sufiks,
       kk1, kk2, kk3, kk4, kk5, kk6, kk7, kk8, kk9,
       kp1, kp2, kp3, kp4, kp5, kp6, kp7, kp8, kp9, kpa, kpb, kpc, kpd,
       ko1, ko2, ko3, ko4, ko5, ko6, ko7, ko8, ko9, koa, kob, koc, kod,
       prod
  FROM f18.koncij;

GRANT ALL ON public.koncij TO xtrole;

CREATE OR REPLACE RULE public_koncij_ins AS ON INSERT TO public.koncij
  DO INSTEAD INSERT INTO f18.koncij(
    id, shema,
    naz, idprodmjes, region, sufiks,
    kk1, kk2, kk3, kk4, kk5, kk6, kk7, kk8, kk9,
    kp1, kp2, kp3, kp4, kp5, kp6, kp7, kp8, kp9, kpa, kpb, kpc, kpd,
    ko1, ko2, ko3, ko4, ko5, ko6, ko7, ko8, ko9, koa, kob, koc, kod,
    prod
  ) VALUES (
    NEW.id, NEW.shema,
    NEW.naz, NEW.idprodmjes, NEW.region, NEW.sufiks,
    NEW.kk1, NEW.kk2, NEW.kk3, NEW.kk4, NEW.kk5, NEW.kk6, NEW.kk7, NEW.kk8, NEW.kk9,
    NEW.kp1, NEW.kp2, NEW.kp3, NEW.kp4, NEW.kp5, NEW.kp6, NEW.kp7, NEW.kp8, NEW.kp9, NEW.kpa, NEW.kpb, NEW.kpc, NEW.kpd,
    NEW.ko1, NEW.ko2, NEW.ko3, NEW.ko4, NEW.ko5, NEW.ko6, NEW.ko7, NEW.ko8, NEW.ko9, NEW.koa, NEW.kob, NEW.koc, NEW.kod,
    NEW.prod
  );


GRANT ALL ON public.koncij TO xtrole;

-- public.roba

drop view if exists public.roba;
CREATE view public.roba  AS SELECT
  *
FROM
  f18.roba;

--- CREATE OR REPLACE RULE public_roba_ins AS ON INSERT TO public.roba
---         DO INSTEAD INSERT INTO f18.roba(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.roba TO xtrole;

-- public.partn

drop view if exists public.partn;
CREATE view public.partn  AS SELECT
  *
FROM
  f18.partn;

--- CREATE OR REPLACE RULE public_partn_ins AS ON INSERT TO public.partn
---         DO INSTEAD INSERT INTO f18.partn(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.partn TO xtrole;

-- public.valute
drop view if exists public.valute;
CREATE view public.valute  AS SELECT
  *
FROM
  f18.valute;

--- CREATE OR REPLACE RULE public_valute_ins AS ON INSERT TO public.valute
---         DO INSTEAD INSERT INTO f18.valute(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.valute TO xtrole;

-- public.konto
drop view if exists public.konto;
CREATE view public.konto  AS SELECT
  *
FROM
  f18.konto;

--- CREATE OR REPLACE RULE public_konto_ins AS ON INSERT TO public.konto
---         DO INSTEAD INSERT INTO f18.konto(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.konto TO xtrole;

-- public.tnal
drop view if exists public.tnal;
CREATE view public.tnal  AS SELECT
  *
FROM
  f18.tnal;

--- CREATE OR REPLACE RULE public_tnal_ins AS ON INSERT TO public.tnal
---         DO INSTEAD INSERT INTO f18.tnal(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.tnal TO xtrole;

-- public.tdok
drop view if exists public.tdok;
CREATE view public.tdok  AS SELECT
  *
FROM
  f18.tdok;

--- CREATE OR REPLACE RULE public_tdok_ins AS ON INSERT TO public.tdok
---         DO INSTEAD INSERT INTO f18.tdok(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.tdok TO xtrole;

-- public.sifk
drop view if exists public.sifk;
CREATE view public.sifk  AS SELECT
  *
FROM
  f18.sifk;

--- CREATE OR REPLACE RULE public_sifk_ins AS ON INSERT TO public.sifk
---         DO INSTEAD INSERT INTO f18.sifk(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.sifk TO xtrole;

-- public.sifv
drop view if exists public.sifv;
CREATE view public.sifv  AS SELECT
  *
FROM
  f18.sifv;

--- CREATE OR REPLACE RULE public_sifv_ins AS ON INSERT TO public.sifv
---         DO INSTEAD INSERT INTO f18.sifv(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.sifv TO xtrole;

-- public.trfp
drop view if exists public.trfp;
CREATE view public.trfp  AS SELECT
  *
FROM
  f18.trfp;

--- CREATE OR REPLACE RULE public_trfp_ins AS ON INSERT TO public.trfp
---         DO INSTEAD INSERT INTO f18.trfp(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON public.trfp TO xtrole;
