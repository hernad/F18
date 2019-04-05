CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.pos_knjig_dok_id(cIdPos varchar, cIdVD varchar, cBrDok varchar, dDatum date) RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
   dok_id uuid;
BEGIN
   EXECUTE 'SELECT dok_id FROM {{ item_prodavnica }}.pos_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
     USING cIdPos, cIdVd, cBrDok, dDatum
     INTO dok_id;

   IF dok_id IS NULL THEN
      --RAISE EXCEPTION 'kalk_doks %-%-% od % NE postoji?!', cIdFirma, cIdVd, cBrDok, dDatDok;
      RAISE INFO 'pos_doks %-%-% od % NE postoji?!', cIdPos, cIdVd, cBrDok, dDatum;
   END IF;

   RETURN dok_id;
END;
$$;

drop view if exists {{ item_prodavnica }}.pos_doks_knjig;
CREATE view {{ item_prodavnica }}.pos_doks_knjig AS SELECT
    idpos, idvd, brdok, datum, idpartner,
    idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do,
    obradjeno, korisnik
FROM
  {{ item_prodavnica }}.pos_knjig;


drop rule IF EXISTS public_doks_pos_knjig_ins ON  {{ item_prodavnica }}.pos_doks_knjig;
CREATE OR REPLACE RULE {{ item_prodavnica }}_pos_doks_knjig_ins AS ON INSERT TO {{ item_prodavnica }}.pos_doks_knjig
      DO INSTEAD (
        INSERT INTO {{ item_prodavnica }}.pos_knjig(
        idpos, idvd, brdok, datum, idpartner,
        idradnik, idvrstep, vrijeme, ukupno, brfaktp, opis, dat_od, dat_do
       ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idpartner,
        NEW.idradnik, NEW.idvrstep, NEW.vrijeme, NEW.ukupno, NEW.brfaktp, NEW.opis, NEW.dat_od, NEW.dat_do
      );
      UPDATE {{ item_prodavnica }}.pos_items_knjig
         SET dok_id={{ item_prodavnica }}.pos_knjig_dok_id(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum)
         WHERE idpos=NEW.idpos AND idvd=NEW.idvd AND brdok=NEW.brdok AND  datum=NEW.datum
     );

GRANT ALL ON {{ item_prodavnica }}.pos_doks_knjig TO xtrole;

drop view if exists {{ item_prodavnica }}.pos_pos_knjig;
CREATE view {{ item_prodavnica }}.pos_pos_knjig AS SELECT
    idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj
FROM
  {{ item_prodavnica }}.pos_items_knjig;

drop rule IF EXISTS public_pos_pos_knjig_ins ON  {{ item_prodavnica }}.pos_pos_knjig;
CREATE OR REPLACE RULE {{ item_prodavnica }}_pos_pos_knjig_ins AS ON INSERT TO {{ item_prodavnica }}.pos_pos_knjig
      DO INSTEAD INSERT INTO {{ item_prodavnica }}.pos_items_knjig(
         idpos, idvd, brdok, datum, idroba, idtarifa, kolicina, kol2, cijena, ncijena, rbr, robanaz, jmj,
         dok_id
      ) VALUES (
        NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.idtarifa, NEW.kolicina, NEW.kol2, NEW.cijena, NEW.ncijena, NEW.rbr, NEW.robanaz, NEW.jmj,
        {{ item_prodavnica }}.pos_dok_id(NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum) );

GRANT ALL ON {{ item_prodavnica }}.pos_pos_knjig TO xtrole;
