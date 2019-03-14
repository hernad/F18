drop view if exists p15.pos_doks_knjig;
CREATE view p15.pos_doks_knjig AS SELECT
    dok_id, idpos, idvd, brdok, datum, idpartner,
    idradnik, idvrstep, vrijeme, ref_fisk_dok, ref, ref_2, ukupno, brfaktp, opis, dat_od, dat_do,
    obradjeno, korisnik
FROM
  p15.pos_knjig;

CREATE OR REPLACE RULE public_pos_doks_knjig_ins AS ON INSERT TO p15.pos_doks_knjig
      DO INSTEAD INSERT INTO p15.pos_knjig(
        idpos, idvd, brdok, datum, idpartner,
        idradnik, idvrstep, vrijeme, ref_fisk_dok, ref, ref_2, ukupno, brfaktp, opis, dat_od, dat_do
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idpartner,
        NEW.idradnik, NEW.idvrstep, NEW.vrijeme, NEW.ref_fisk_dok, NEW.ref, NEW.ref_2, NEW.ukupno, NEW.brfaktp, NEW.opis, NEW.dat_od, NEW.dat_do
      );

GRANT ALL ON p15.pos_doks_knjig TO xtrole;

drop view if exists p15.pos_pos_knjig;
CREATE view p15.pos_pos_knjig AS SELECT
    dok_id, idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj
FROM
  p15.pos_items_knjig;

CREATE OR REPLACE RULE public_pos_pos_knjig_ins AS ON INSERT TO p15.pos_pos_knjig
      DO INSTEAD INSERT INTO p15.pos_items_knjig(
         idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj,
         dok_id
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.idtarifa, NEW.kolicina, NEW.kol2, NEW.cijena, NEW.ncijena, NEW.rbr, NEW.robanaz, NEW.jmj,
        p15.pos_dok_id(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum) );

GRANT ALL ON p15.pos_pos_knjig TO xtrole;
