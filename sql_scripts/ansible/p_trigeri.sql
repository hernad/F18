----------- TRIGERI na strani prodavnice POS_KNJIG -> POS ! -----------------------------------------------------

-- on {{ item_prodavnica }}.pos_doks_knjig -> {{ item_prodavnica }}.pos_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_pos_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'PROD {{ item_prodavnica }}: delete pos_knjig prodavnica %', OLD.idPos;
      EXECUTE 'DELETE FROM {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
         USING OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum;

      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_knjig prodavnica!? %', NEW.idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'PROD {{ item_prodavnica }}: insert pos_knjig prodavnica %', NEW.idPos;
      EXECUTE 'INSERT INTO {{ item_prodavnica }}.pos(dok_id,idpos,idvd,brdok,datum,brFaktP,dat_od,dat_do,opis,idpartner) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
        USING NEW.dok_id, NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.brFaktP, NEW.dat_od, NEW.dat_do, NEW.opis, NEW.idpartner;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on {{ item_prodavnica }}.pos_pos_knjig -> {{ item_prodavnica }}.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_pos_items_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    robaId varchar;
    robaCijena numeric;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_pos_knjig prodavnica % %', OLD.idPos, OLD.idvd;
      EXECUTE 'DELETE FROM {{ item_prodavnica }}.pos_items WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;

      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_pos_knjig prodavnica!? %', NEW.idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'FIRST insert/update roba u prodavnici';
      EXECUTE 'SELECT id from {{ item_prodavnica }}.roba WHERE id=$1'
         USING NEW.idroba
         INTO robaId;

      IF (NEW.idvd = '19') THEN
         robaCijena := NEW.ncijena;
      ELSE
         -- kada je '72' i radi se o novom artiklu, u sifarnik se stavi stara cijena sa ovog dokumenta
         -- to je dobro, jer kada se bude generisala '29'-ka ocekivace se ta cijena kao stara cijena
         robaCijena := NEW.cijena;
      END IF;

      IF NOT robaId IS NULL THEN -- roba postoji u sifarniku
         IF NOT NEW.idvd IN ('21', '79') THEN -- dokument 21 moze da sadrzi stare cijene, zato ne update-uj prodavnica.roba ; 79 radi sa postojecom robom
            EXECUTE 'UPDATE {{ item_prodavnica }}.roba SET barkod=$2, idtarifa=$3, naz=$4, mpc=$5, jmj=$6 WHERE id=$1'
               USING robaId, public.num_to_barkod_ean13(NEW.kol2, 3), NEW.idtarifa, NEW.robanaz, robaCijena, NEW.jmj;
         END IF;
      ELSE
         -- ako artikla uopste nema, onda i 21-ca moze setovati sifru u prodavnica.roba; ali ovo ne bi trebalo da se desava !
         IF NOT NEW.idvd = '79' THEN
           EXECUTE 'INSERT INTO {{ item_prodavnica }}.roba(id,barkod,mpc,idtarifa,naz,jmj) values($1,$2,$3,$4,$5,$6)'
              USING NEW.idroba, public.num_to_barkod_ean13(NEW.kol2, 3), robaCijena, NEW.idtarifa, NEW.robanaz, NEW.jmj;
         END IF;
      END IF;

      RAISE INFO 'insert pos_pos_knjig prodavnica % %', NEW.idPos, NEW.idvd;
      EXECUTE 'INSERT INTO {{ item_prodavnica }}.pos_items(dok_id,idpos,idvd,brdok,datum,rbr,idroba,idtarifa,kolicina,cijena,ncijena,kol2,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)'
        USING NEW.dok_id,NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr, NEW.idroba, NEW.idtarifa,NEW.kolicina, NEW.cijena, NEW.ncijena, NEW.kol2, NEW.robanaz, NEW.jmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- na strani kase dokumenti koji dolaze od knjigovodstva

-- {{ item_prodavnica }}.pos_doks_knjig -> {{ item_prodavnica }}.pos_doks
DROP TRIGGER IF EXISTS pos_knjig_crud on {{ item_prodavnica }}.pos_knjig;
CREATE TRIGGER pos_knjig_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON {{ item_prodavnica }}.pos_knjig
      FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_pos_knjig_crud();

ALTER TABLE {{ item_prodavnica }}.pos_knjig ENABLE ALWAYS TRIGGER pos_knjig_crud;

-- {{ item_prodavnica }}.pos_pos_knjig -> {{ item_prodavnica }}.pos_pos
DROP TRIGGER IF EXISTS pos_items_knjig_crud on {{ item_prodavnica }}.pos_items_knjig;
CREATE TRIGGER pos_items_knjig_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON {{ item_prodavnica }}.pos_items_knjig
   FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_pos_items_knjig_crud();

ALTER TABLE {{ item_prodavnica }}.pos_items_knjig ENABLE ALWAYS TRIGGER pos_items_knjig_crud;


----------- TRIGERI na strani kase radi pracenja stanja -----------------------------------------------------


CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_kasa_pos_crud() RETURNS trigger
LANGUAGE plpgsql
AS $$

DECLARE
   dokId uuid;
BEGIN

IF (TG_OP = 'INSERT') THEN
   IF (NEW.idvd <> '02') THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'INSERT') THEN
   IF ( NEW.idvd = '02') THEN
      EXECUTE 'DELETE FROM {{ item_prodavnica }}.pos_stanje';
      EXECUTE 'DELETE FROM {{ item_prodavnica }}.roba';
      RAISE INFO '02 - inicijalizacija {{ item_prodavnica }}.pos_stanje';
      RETURN NEW;
   END IF;
END IF;

IF (TG_OP = 'DELETE') THEN
  -- brisanje izgenerisanih storno 99, 79
  IF ( OLD.idvd = '72' ) THEN
      RAISE INFO 'brisem zahtjev 72 % %', OLD.brdok, OLD.dok_id;
      DELETE FROM {{ item_prodavnica }}.pos where idvd='29' AND ref=OLD.dok_id
        RETURNING dok_id
        INTO dokId;

      IF NOT dokId IS NULL THEN
         DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
      RAISE INFO '29-ref %', dokId;

      DELETE FROM {{ item_prodavnica }}.pos where idvd='29' AND ref_2=OLD.dok_id
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
           DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
      RAISE INFO '29-ref_2 %', dokId;

      -- izgenerisano pri start/end 79 nivelacija
      DELETE FROM {{ item_prodavnica }}.pos where idvd='79' AND ref=OLD.dok_id and datum=OLD.dat_od
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
          DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
      RAISE INFO '79 dat_od %', dokId;
      DELETE FROM {{ item_prodavnica }}.pos where idvd='79' AND ref=OLD.dok_id and datum=OLD.dat_do
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
         DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
      RAISE INFO '79 dat_do %', dokId;

      -- izgenerisano pri start/end 99 nivelacija
      DELETE FROM {{ item_prodavnica }}.pos where idvd='99' AND ref=OLD.dok_id and datum=OLD.dat_od
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
         DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;

      RAISE INFO '99 dat_od %', dokId;
      DELETE FROM {{ item_prodavnica }}.pos where idvd='99' AND ref=OLD.dok_id and datum=OLD.dat_do
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
          DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
      RAISE INFO '99 dat_do %', dokId;

  END IF;

  -- brisanje izgenerisanih 99 plus
  IF ( OLD.idvd = '99' ) THEN
      RAISE INFO 'brisem izgenerisane 99 % %', OLD.brdok, OLD.dok_id;
      DELETE FROM {{ item_prodavnica }}.pos where idvd='99' AND ref=OLD.dok_id and datum=OLD.datum
        RETURNING dok_id
        INTO dokId;
      IF NOT dokId IS NULL THEN
         DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
      END IF;
  END IF;
  -- brisanje izgenerisanih 79 plus
  IF ( OLD.idvd = '79' ) THEN
     RAISE INFO 'brisem izgenerisane 79 % %', OLD.brdok, OLD.dok_id;
     DELETE FROM {{ item_prodavnica }}.pos where idvd='79' AND ref=OLD.dok_id and datum=OLD.datum
       RETURNING dok_id
       INTO dokId;
     IF NOT dokId IS NULL THEN
        DELETE FROM {{ item_prodavnica }}.pos_items where dok_id=dokId;
     END IF;
  END IF;
  RETURN OLD;
END IF;

RETURN NULL;
END;
$$;

-- on {{ item_prodavnica }}.pos_items
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_kasa_pos_items_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
    idPos varchar := '1 ';
    lRet boolean;
    datOd date;
    datDo date;
    nVisak numeric;
    nManjak numeric;
    nKolicina numeric;
    nKolPromCijena numeric;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NOT NEW.idvd IN ('42','02','22','80','89','29','19','79','90','99') ) THEN   -- 42, 11, 80, 19, 79, 89
      RETURN NULL;
   END IF;
   IF ( NEW.idvd = '90' ) THEN
      IF ( NEW.kolicina - NEW.kol2 ) > 0 THEN  -- popisana - knjizna
         nVisak := NEW.kolicina - NEW.kol2;
         nManjak := 0;
         nKolicina := nVisak;
      ELSE
         nManjak := NEW.kol2 - NEW.kolicina;
         nVisak := 0;
         nKolicina := nManjak;
      END IF;
   ELSE
      nVisak := 0;
      nManjak := 0;
      nKolicina := NEW.kolicina;
   END IF;
ELSE
   IF ( NOT OLD.idvd IN ('42','02','22','80','89','29','19','79','90','99') ) THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'DELETE') AND ( OLD.idvd = '42' ) THEN
      RAISE INFO 'delete izlaz pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select {{ item_prodavnica }}.pos_izlaz_update_stanje('-', '15', '42', 'PROD91', '5', current_date, 'R01',  40, 2.5, 0);
      EXECUTE 'SELECT {{ item_prodavnica }}.pos_izlaz_update_stanje(''-'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
         USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum,  OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
         INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( OLD.idvd IN ('02','22','80','89','90') ) THEN
      RAISE INFO 'delete pos_prijem_update_stanje  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select {{ item_prodavnica }}.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '999', current_date, current_date, NULL, 'R01',  50, 2.5, 0);
      EXECUTE 'SELECT {{ item_prodavnica }}.pos_prijem_update_stanje(''-'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
               USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
               INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( OLD.idvd IN ('19','29','79' ) ) THEN
        RAISE INFO 'delete pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
        EXECUTE 'SELECT {{ item_prodavnica }}.pos_promjena_cijena_update_stanje(''-'', $1,$2,$3,$4,$5,$5,NULL,$6,$7,$8,$9)'
                   USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
                   INTO nKolPromCijena;
        -- RAISE INFO 'delete  ret=%', lRet;
        RETURN OLD;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd = '42' ) THEN
       RAISE INFO 'update 42 pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr ;
       RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd IN ('02','22','80','89','90') ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd IN ('19','29','79' ) ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' OR  NEW.idvd = '99' OR ( NEW.idvd = '90' AND nManjak > 0)  ) THEN
        -- 42 - prodaja
        -- 99 - kalo
        -- 90 nManjak - izlaz
        RAISE INFO 'insert 42 pos_pos  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- {{ item_prodavnica }}.pos_izlaz_update_stanje('+', '15', '42', 'PROD10', '999', current_date, 'R03', 10, 30, 0);
        EXECUTE 'SELECT {{ item_prodavnica }}.pos_izlaz_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
              USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum,  NEW.idroba, nKolicina, NEW.cijena, NEW.ncijena
              INTO lRet;
        RAISE INFO 'insert 42 ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd IN ('02','22','80','89') OR ( NEW.idvd = '90' AND nVisak > 0) ) THEN
        RAISE INFO 'insert pos_prijem_update_stanje % % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.rbr;
        -- select {{ item_prodavnica }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '999', current_date, current_date, NULL,'R01', 100, 2.5, 0);
        EXECUTE 'SELECT {{ item_prodavnica }}.pos_prijem_update_stanje(''+'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, NEW.idroba, nKolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
             RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd IN ('19','29','79') ) THEN
        RAISE INFO 'insert pos % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- u pos_doks se nalazi dat_od, dat_do
        EXECUTE 'SELECT dat_od, dat_do FROM {{ item_prodavnica }}.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
           USING idPos, NEW.idvd, NEW.brdok, NEW.datum
           INTO datOd, datDo;
        IF datOd IS NULL THEN
           RAISE EXCEPTION 'p_trigeri.sql pos % % % % NE postoji?!', idPos, NEW.idvd, NEW.brdok, NEW.datum;
           RETURN NULL;
        END IF;

        IF (NEW.idvd = '29' AND NEW.kolicina >= 0) THEN -- promjena cijene u sif roba
           UPDATE {{ item_prodavnica }}.roba SET mpc=NEW.ncijena
             WHERE id=NEW.idroba;
        END IF;

        IF (NEW.kolicina > 0) THEN
           EXECUTE 'SELECT {{ item_prodavnica }}.pos_promjena_cijena_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'
               USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, datOd, datDo, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
               INTO nKolPromCijena;
           IF NEW.idvd = '79' AND nKolPromCijena >= 0 THEN -- odobreno snizenje realizovano
               NEW.kol2 := nKolPromCijena;
           END IF;
        ELSIF (NEW.kolicina = 0) THEN
             RAISE INFO 'kolicina 0 nista se nema raditi';
        ELSE
           EXECUTE 'SELECT {{ item_prodavnica }}.pos_promjena_cijena_storno_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'
              USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, datOd, datDo, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
              INTO lRet;
        END IF;
        RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;

-- {{ item_prodavnica }}.pos na kasi
DROP TRIGGER IF EXISTS kasa_pos_crud on {{ item_prodavnica }}.pos;
    CREATE TRIGGER kasa_pos_crud
        AFTER INSERT OR DELETE OR UPDATE
        ON {{ item_prodavnica }}.pos
        FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_kasa_pos_crud();

-- on_kasa_pos_items_crud se desava BEFORE insert
-- {{ item_prodavnica }}.pos_items na kasi
DROP TRIGGER IF EXISTS kasa_pos_items_crud on {{ item_prodavnica }}.pos_items;
CREATE TRIGGER kasa_pos_items_crud
      BEFORE INSERT OR DELETE OR UPDATE
      ON {{ item_prodavnica }}.pos_items
      FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_kasa_pos_items_crud();

ALTER TABLE {{ item_prodavnica }}.pos ENABLE ALWAYS TRIGGER kasa_pos_crud;
ALTER TABLE {{ item_prodavnica }}.pos_items ENABLE ALWAYS TRIGGER kasa_pos_items_crud;
