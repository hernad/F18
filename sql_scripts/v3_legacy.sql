

------------------------------------------------------------------------
-- kalk_kalk, kalk_doks cleanup datumska polja
-----------------------------------------------------------------------
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datfaktp;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS datkurs;
ALTER TABLE f18.kalk_kalk DROP COLUMN IF EXISTS roktr;

--------------------------------------------------------------------------------
-- F18 v3 legacy public.kalk_kalk, kalk_doks updatable views
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
     current_date as roktr
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
         error
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
        NEW.error );

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
korisnik
FROM
  f18.kalk_doks;

CREATE OR REPLACE RULE fmk_kalk_doks_ins AS ON INSERT TO f18.kalk_doks
      DO INSTEAD INSERT INTO f18.kalk_doks(
        idfirma, idvd, brdok, datdok,
        brfaktp, datfaktp, idpartner, datval,
        dat_od, dat_do,
        opis,
        pkonto,mkonto,
        nv,vpv,rabat,mpv,
        obradjeno,
        korisnik
      ) VALUES (
        NEW.idfirma, NEW.idvd, NEW.brdok, NEW.datdok,
        NEW.brfaktp, NEW.datfaktp, NEW.idpartner, NEW.datval,
        NEW.dat_od, NEW.dat_do,
        NEW.opis,
        NEW.pkonto, NEW.mkonto,
        NEW.nv, NEW.vpv, NEW.rabat, NEW.mpv,
        NEW.obradjeno,
        NEW.korisnik   );

GRANT ALL ON fmk.kalk_doks TO xtrole;
