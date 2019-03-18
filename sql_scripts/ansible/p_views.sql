drop view if exists {{ ansible_nodename }}.pos_doks;
CREATE view {{ ansible_nodename }}.pos_doks AS SELECT
    idpos, idvd, brdok, datum, idpartner,
    idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do,
    obradjeno, korisnik
FROM
  {{ ansible_nodename }}.pos;

CREATE OR REPLACE RULE public_pos_doks_ins AS ON INSERT TO {{ ansible_nodename }}.pos_doks
      DO INSTEAD INSERT INTO {{ ansible_nodename }}.pos(
        idpos, idvd, brdok, datum, idpartner,
        idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idpartner,
        NEW.idradnik, NEW.idvrstep, NEW.vrijeme, NEW.ukupno, NEW.brfaktp, NEW.opis, NEW.dat_od, NEW.dat_do
      );

GRANT ALL ON {{ ansible_nodename }}.pos_doks TO xtrole;


drop view if exists {{ ansible_nodename }}.pos_pos;
CREATE view {{ ansible_nodename }}.pos_pos AS SELECT
    idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj
FROM
  {{ ansible_nodename }}.pos_items;

CREATE OR REPLACE RULE public_pos_pos_ins AS ON INSERT TO {{ ansible_nodename }}.pos_pos
      DO INSTEAD INSERT INTO {{ ansible_nodename }}.pos_items(
         idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj,
         dok_id
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.idtarifa, NEW.kolicina, NEW.kol2, NEW.cijena, NEW.ncijena, NEW.rbr, NEW.robanaz, NEW.jmj,
        {{ ansible_nodename }}.pos_dok_id(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum) );

GRANT ALL ON {{ ansible_nodename }}.pos_pos TO xtrole;
