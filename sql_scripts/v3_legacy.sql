-- ovo trazi F18 v3 klijenti

CREATE OR REPLACE FUNCTION fmk.fetchmetrictext(text) RETURNS text
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

CREATE OR REPLACE FUNCTION fmk.setmetric(text, text) RETURNS boolean
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

ALTER FUNCTION fmk.fetchmetrictext(text) OWNER TO admin;
GRANT ALL ON FUNCTION fmk.fetchmetrictext TO xtrole;

ALTER FUNCTION fmk.setmetric(text, text) OWNER TO admin;
GRANT ALL ON FUNCTION fmk.setmetric TO xtrole;


--------------------------------------------------------------------------------
-- F18 v3 legacy fmk.kalk_kalk, kalk_doks updatable views
-------------------------------------------------------------------------------

drop view if exists fmk.kalk_kalk;
CREATE view fmk.kalk_kalk  AS SELECT
     idfirma, idroba, idkonto, idkonto2, idvd, brdok, datdok,
     brfaktp, idpartner,
     lpad(btrim(to_char(rbr,'999')), 3) as rbr,
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
     date '1990-01-01' as datfaktp,
     current_date as datkurs,
     current_date as roktr,
     NULL as idzaduz,
     NULL as idzaduz2,
     0.0 AS fcj3,
     0.0 AS vpcsap,
     NULL as podbr
FROM
  f18.kalk_kalk;

CREATE OR REPLACE RULE fmk_kalk_kalk_ins AS ON INSERT TO fmk.kalk_kalk
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
        to_number(NEW.rbr,'999'),
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
        public.kalk_dok_id(NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok) );

GRANT ALL ON fmk.kalk_kalk TO xtrole;

----------------------  fmk.kalk_doks ----------------------------------
DROP VIEW if exists fmk.kalk_doks;
CREATE view fmk.kalk_doks  AS SELECT
idfirma, idvd, brdok, datdok,
brfaktp, datfaktp, idpartner, datval,
dat_od, dat_do,
opis,
pkonto,mkonto,
nv,vpv,rabat,mpv,
obradjeno,
korisnik,
NULL as idzaduz,
NULL as idzaduz2,
NULL as sifra,
NULL as podbr
FROM
  f18.kalk_doks;

CREATE OR REPLACE RULE fmk_kalk_doks_ins AS ON INSERT TO fmk.kalk_doks
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

GRANT ALL ON fmk.kalk_doks TO xtrole;

-- fmk.tarifa

drop view if exists fmk.tarifa;
CREATE view fmk.tarifa  AS SELECT
  id, naz,
  NULL AS match_code,
  0.0::numeric(10,2) AS ppp,
  0.0::numeric(10,2) AS vpp,
  0.0::numeric(10,2) AS mpp,
  0.0::numeric(10,2) AS dlruc,
  0.0::numeric(10,2) AS zpp,
  pdv AS opp
FROM
  f18.tarifa;


CREATE OR REPLACE RULE fmk_tarifa_ins AS ON INSERT TO fmk.tarifa
        DO INSTEAD INSERT INTO f18.tarifa(
           id, naz,
           pdv
        ) VALUES (
          NEW.id, NEW.NAZ, NEW.opp );

GRANT ALL ON fmk.tarifa TO xtrole;


-- fmk.koncij
drop view if exists fmk.koncij;
CREATE view fmk.koncij  AS
  SELECT id, shema,
         naz, idprodmjes, region, sufiks,
         kk1, kk2, kk3, kk4, kk5, kk6, kk7, kk8, kk9,
         kp1, kp2, kp3, kp4, kp5, kp6, kp7, kp8, kp9, kpa, kpb, kpc, kpd,
         ko1, ko2, ko3, ko4, ko5, ko6, ko7, ko8, ko9, koa, kob, koc, kod
	  FROM f18.koncij;

GRANT ALL ON fmk.koncij TO xtrole;

CREATE OR REPLACE RULE fmk_koncij_ins AS ON INSERT TO fmk.koncij
      DO INSTEAD INSERT INTO f18.koncij(
        id, shema,
        naz, idprodmjes, region, sufiks,
        kk1, kk2, kk3, kk4, kk5, kk6, kk7, kk8, kk9,
        kp1, kp2, kp3, kp4, kp5, kp6, kp7, kp8, kp9, kpa, kpb, kpc, kpd,
        ko1, ko2, ko3, ko4, ko5, ko6, ko7, ko8, ko9, koa, kob, koc, kod
      ) VALUES (
        NEW.id, NEW.shema,
        NEW.naz, NEW.idprodmjes, NEW.region, NEW.sufiks,
        NEW.kk1, NEW.kk2, NEW.kk3, NEW.kk4, NEW.kk5, NEW.kk6, NEW.kk7, NEW.kk8, NEW.kk9,
        NEW.kp1, NEW.kp2, NEW.kp3, NEW.kp4, NEW.kp5, NEW.kp6, NEW.kp7, NEW.kp8, NEW.kp9, NEW.kpa, NEW.kpb, NEW.kpc, NEW.kpd,
        NEW.ko1, NEW.ko2, NEW.ko3, NEW.ko4, NEW.ko5, NEW.ko6, NEW.ko7, NEW.ko8, NEW.ko9, NEW.koa, NEW.kob, NEW.koc, NEW.kod
      );

GRANT ALL ON fmk.koncij TO xtrole;

-- fmk.roba
drop view if exists fmk.roba;
CREATE view fmk.roba  AS SELECT
   id, sifradob, naz, jmj, idtarifa, nc, vpc, mpc, tip, carina, opis, vpc2, mpc2, mpc3, k1, k2, n1, n2, plc,
   mink, _m1_, barkod, zanivel, zaniv2, trosk1, trosk2, trosk3, trosk4, trosk5, fisc_plu, k7, k8, k9,
   strings, idkonto, mpc4, mpc5, mpc6, mpc7, mpc8, mpc9
FROM
  f18.roba;

CREATE OR REPLACE RULE fmk_roba_ins AS ON INSERT TO fmk.roba
        DO INSTEAD INSERT INTO f18.roba(
          id, sifradob, naz, jmj, idtarifa, nc, vpc, mpc, tip, carina, opis, vpc2, mpc2, mpc3, k1, k2, n1, n2, plc,
          mink, _m1_, barkod, zanivel, zaniv2, trosk1, trosk2, trosk3, trosk4, trosk5, fisc_plu, k7, k8, k9,
          strings, idkonto, mpc4, mpc5, mpc6, mpc7, mpc8, mpc9
        ) VALUES (
          NEW.id, NEW.sifradob, NEW.naz, NEW.jmj, NEW.idtarifa, NEW.nc, NEW.vpc, NEW.mpc, NEW.tip, NEW.carina, NEW.opis, NEW.vpc2, NEW.mpc2, NEW.mpc3, NEW.k1, NEW.k2, NEW.n1, NEW.n2, NEW.plc,
          NEW.mink, NEW._m1_, NEW.barkod, NEW.zanivel, NEW.zaniv2, NEW.trosk1, NEW.trosk2, NEW.trosk3, NEW.trosk4, NEW.trosk5, NEW.fisc_plu, NEW.k7, NEW.k8, NEW.k9,
          NEW.strings, NEW.idkonto, NEW.mpc4, NEW.mpc5, NEW.mpc6, NEW.mpc7, NEW.mpc8, NEW.mpc9
        );

GRANT ALL ON fmk.roba TO xtrole;

-- fmk.partn
drop view if exists fmk.partn;
CREATE view fmk.partn  AS
  SELECT id, naz, naz2, ptt, mjesto, adresa, ziror, rejon, telefon, dziror, fax, mobtel,
         idops, _kup, _dob, _banka, _radnik, idrefer
FROM
  f18.partn;

CREATE OR REPLACE RULE fmk_partn_ins AS ON INSERT TO fmk.partn
        DO INSTEAD INSERT INTO f18.partn(
           id, naz, naz2, ptt, mjesto, adresa, ziror, rejon, telefon, dziror, fax, mobtel,
                 idops, _kup, _dob, _banka, _radnik, idrefer
        ) VALUES (
           NEW.id, NEW.naz, NEW.naz2, NEW.ptt, NEW.mjesto, NEW.adresa, NEW.ziror, NEW.rejon, NEW.telefon, NEW.dziror, NEW.fax, NEW.mobtel,
                NEW.idops, NEW._kup, NEW._dob, NEW._banka, NEW._radnik, NEW.idrefer
        );

GRANT ALL ON fmk.partn TO xtrole;

-- fmk.valute
drop view if exists fmk.valute;
CREATE view fmk.valute  AS
SELECT id, naz, naz2, datum, kurs1, kurs2, kurs3, tip, NULL as match_code
	FROM f18.valute;


CREATE OR REPLACE RULE fmk_valute_ins AS ON INSERT TO fmk.valute
     DO INSTEAD INSERT INTO f18.valute(
             id, naz, naz2, datum, kurs1, kurs2, kurs3, tip
    ) VALUES (
           NEW.id, NEW.naz, NEW.naz2, NEW.datum, NEW.kurs1, NEW.kurs2, NEW.kurs3, NEW.tip );

GRANT ALL ON fmk.valute TO xtrole;


-- fmk.konto
drop view if exists fmk.konto;
CREATE view fmk.konto  AS SELECT
  id, naz
FROM
  f18.konto;

CREATE OR REPLACE RULE fmk_konto_ins AS ON INSERT TO fmk.konto
         DO INSTEAD INSERT INTO f18.konto(
            id, naz
         ) VALUES (
          NEW.id, NEW.naz );
GRANT ALL ON fmk.konto TO xtrole;

-- fmk.tnal
drop view if exists fmk.tnal;
CREATE view fmk.tnal  AS SELECT
  id, naz
FROM
  f18.tnal;

CREATE OR REPLACE RULE fmk_tnal_ins AS ON INSERT TO fmk.tnal
        DO INSTEAD INSERT INTO f18.tnal(
           id, naz
        ) VALUES (
            NEW.id, NEW.NAZ );

GRANT ALL ON fmk.tnal TO xtrole;

-- fmk.tdok
drop view if exists fmk.tdok;
CREATE view fmk.tdok  AS SELECT
  id, naz
FROM
  f18.tdok;

CREATE OR REPLACE RULE fmk_tdok_ins AS ON INSERT TO fmk.tdok
        DO INSTEAD INSERT INTO f18.tdok(
           id, naz
        ) VALUES (
          NEW.id, NEW.NAZ );

GRANT ALL ON fmk.tdok TO xtrole;

-- fmk.sifk
drop view if exists fmk.sifk;
CREATE view fmk.sifk  AS SELECT
  *
FROM
  f18.sifk;


--- CREATE OR REPLACE RULE fmk_sifk_ins AS ON INSERT TO fmk.sifk
---         DO INSTEAD INSERT INTO f18.sifk(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON fmk.sifk TO xtrole;

-- fmk.sifv
drop view if exists fmk.sifv;
CREATE view fmk.sifv  AS SELECT
  *
FROM
  f18.sifv;


--- CREATE OR REPLACE RULE fmk_sifv_ins AS ON INSERT TO fmk.sifv
---         DO INSTEAD INSERT INTO f18.sifv(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON fmk.sifv TO xtrole;


-- fmk.trfp
drop view if exists fmk.trfp;
CREATE view fmk.trfp  AS SELECT
  *
FROM
  f18.trfp;


--- CREATE OR REPLACE RULE fmk_trfp_ins AS ON INSERT TO fmk.trfp
---         DO INSTEAD INSERT INTO f18.trfp(
---            id, naz,
---            ??
---         ) VALUES (
---           NEW.id, NEW.NAZ, ?? );
---

GRANT ALL ON fmk.trfp TO xtrole;
