
CREATE OR REPLACE FUNCTION p2.pos_postoji_dokument_by_brfaktp( cIdVd varchar, cBrFaktP varchar) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  rec_dok RECORD;
BEGIN
   select * from p2.pos where brfaktp=cBrFaktP and idvd=cIdVd
     INTO rec_dok;

   IF rec_dok.dok_id is null THEN
       RAISE INFO 'NE POSTOJI idvd % sa brfaktp: % ?', cIdVd, cBrFaktP;
       RETURN False;
   END IF;

   RETURN True;
END;
$$;

-- 1) radnik 00010 odbija prijem:
-- select p2.pos_21_to_22( '20567431', '0010', false );
-- generise se samo p2.pos stavka 22, sa opisom: ODBIJENO: 0010

-- 2) radnik 00010 potvrdjuje prijem:
-- select p2.pos_21_to_22( '20567431', '0010', true );
-- generise se samo p2.pos stavka 22, sa opisom: PRIJEM: 0010

CREATE OR REPLACE FUNCTION p2.pos_21_to_22( cBrFaktP varchar, cIdRadnik varchar, lPreuzimaSe boolean) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE

    rec_dok RECORD;
    rec RECORD;
    cOpis varchar;

BEGIN

     select * from p2.pos where brfaktp=cBrFaktP and idvd='21'
        INTO rec_dok;

     IF rec_dok.dok_id is NULL  THEN
         RAISE INFO 'NE POSTOJI 21 sa brfaktp: % ?', cBrFaktP;
         RETURN -1;
     END IF;

     IF p2.pos_postoji_dokument_by_brfaktp( '22', cBrFaktP )  THEN
         RAISE INFO 'VEC POSTOJI 22 sa brfaktp: % ?', cBrFaktP;
         RETURN -2;
     END IF;

     IF lPreuzimaSe THEN
        cOpis := 'PRIJEM: ' || cIdRadnik;
     ELSE
        cOpis := 'ODBIJENO: ' || cIdRadnik;
     END IF;


     INSERT INTO p2.pos(ref, idpos, idvd, brdok, datum, brfaktp, opis, dat_od, dat_do)
         VALUES(rec_dok.dok_id, rec_dok.idpos, '22', rec_dok.brdok, rec_dok.datum, rec_dok.brfaktp, cOpis, rec_dok.dat_od, rec_dok.dat_do);

     IF lPreuzimaSe THEN
        -- ako se roba preuzima stavke se pune
        FOR rec IN
            SELECT * from p2.pos_items
            WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum
        LOOP
            INSERT INTO p2.pos_items(idpos, idvd, brdok, datum, rbr, kolicina, idroba, idtarifa, cijena, ncijena, kol2, robanaz, jmj)
              VALUES(rec.idpos, '22', rec.brdok, rec.datum, rec.rbr, rec.kolicina, rec.idroba, rec.idtarifa, rec.cijena, rec.ncijena, rec.kol2, rec.robanaz, rec.jmj);

        END LOOP;
     ELSE
        --ako se ne prihvata items se ne pune
        RAISE INFO 'Prijem otkazan % !', cBrFaktP;
        RETURN 10;
     END IF;

     RETURN 0;
END;
$$;


-- servisna funkcija prvenstveno
-- select p2.pos_delete_by_idvd_brfakt( '22', '20567431');

CREATE OR REPLACE FUNCTION p2.pos_delete_by_idvd_brfakt( cIdVd varchar, cBrFaktP varchar) RETURNS integer
       LANGUAGE plpgsql
       AS $$
DECLARE

    rec_dok RECORD;

BEGIN

     IF btrim(cBrFaktP) = '' THEN
        RETURN -100;
     END IF;

     IF NOT p2.pos_postoji_dokument_by_brfaktp( cIdVd, cBrFaktP )  THEN
         RAISE INFO 'NE POSTOJI % sa brfaktp: % ?', cIdVd, cBrFaktP;
         RETURN -1;
     END IF;

     SELECT * from p2.pos where idvd=cIdVd and brfaktp=cBrFaktP
        INTO rec_dok;

     DELETE from p2.pos WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum;
     DELETE from p2.pos_items WHERE idpos=rec_dok.idpos and idvd=rec_dok.idvd and brdok=rec_dok.brdok and datum=rec_dok.datum;

     RETURN 0;
END;
$$;
