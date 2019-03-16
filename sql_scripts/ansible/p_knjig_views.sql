drop view if exists {{ item.name }}.pos_doks_knjig;
CREATE view {{ item.name }}.pos_doks_knjig AS SELECT
    idpos, idvd, brdok, datum, idpartner,
    idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do,
    obradjeno, korisnik
FROM
  {{ item.name }}.pos_knjig;

CREATE OR REPLACE RULE public_pos_doks_knjig_ins AS ON INSERT TO {{ item.name }}.pos_doks_knjig
      DO INSTEAD INSERT INTO {{ item.name }}.pos_knjig(
        idpos, idvd, brdok, datum, idpartner,
        idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idpartner,
        NEW.idradnik, NEW.idvrstep, NEW.vrijeme, NEW.ukupno, NEW.brfaktp, NEW.opis, NEW.dat_od, NEW.dat_do
      );

GRANT ALL ON {{ item.name }}.pos_doks_knjig TO xtrole;

drop view if exists {{ item.name }}.pos_pos_knjig;
CREATE view {{ item.name }}.pos_pos_knjig AS SELECT
    idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj
FROM
  {{ item.name }}.pos_items_knjig;

CREATE OR REPLACE RULE public_pos_pos_knjig_ins AS ON INSERT TO {{ item.name }}.pos_pos_knjig
      DO INSTEAD INSERT INTO {{ item.name }}.pos_items_knjig(
         idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj,
         dok_id
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.idtarifa, NEW.kolicina, NEW.kol2, NEW.cijena, NEW.ncijena, NEW.rbr, NEW.robanaz, NEW.jmj,
        {{ item.name }}.pos_dok_id(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum) );

GRANT ALL ON {{ item.name }}.pos_pos_knjig TO xtrole;
