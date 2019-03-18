----------- TRIGERI na strani prodavnice POS_KNJIG -> POS ! -----------------------------------------------------

-- on {{ ansible_nodename }}.pos_doks_knjig -> {{ ansible_nodename }}.pos_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ ansible_nodename }}.on_pos_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'PROD 15: delete pos_knjig prodavnica %', OLD.idPos;
      EXECUTE 'DELETE FROM {{ ansible_nodename }}.pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
         USING OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_knjig prodavnica!? %', NEW.idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'PROD {{ ansible_nodename }}: insert pos_knjig prodavnica %', NEW.idPos;
      EXECUTE 'INSERT INTO {{ ansible_nodename }}.pos(dok_id,idpos,idvd,brdok,datum,brFaktP,dat_od,dat_do,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)'
        USING NEW.dok_id, NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.brFaktP, NEW.dat_od, NEW.dat_do, NEW.opis;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on {{ ansible_nodename }}.pos_pos_knjig -> {{ ansible_nodename }}.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ ansible_nodename }}.on_pos_items_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    robaId varchar;
    robaCijena numeric;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_pos_knjig prodavnica % %', OLD.idPos, OLD.idvd;
      EXECUTE 'DELETE FROM {{ ansible_nodename }}.pos_pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_pos_knjig prodavnica!? %', NEW.idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'FIRST insert/update roba u prodavnici';
      EXECUTE 'SELECT id from {{ ansible_nodename }}.roba WHERE id=$1'
         USING NEW.idroba
         INTO robaId;

      IF (NEW.idvd = '19') THEN
         robaCijena := NEW.ncijena;
      ELSE
         robaCijena := NEW.cijena;
      END IF;

      IF NOT robaId IS NULL THEN -- roba postoji u sifarniku
         EXECUTE 'UPDATE {{ ansible_nodename }}.roba SET barkod=$2, idtarifa=$3, naz=$4, mpc=$5, jmj=$6 WHERE id=$1'
           USING robaId, public.num_to_barkod_ean13(NEW.kol2, 3), NEW.idtarifa, NEW.robanaz, robaCijena, NEW.jmj;
      ELSE
         EXECUTE 'INSERT INTO {{ ansible_nodename }}.roba(id,barkod,mpc,idtarifa,naz,jmj) values($1,$2,$3,$4,$5,$6)'
           USING NEW.idroba, public.num_to_barkod_ean13(NEW.kol2, 3), robaCijena, NEW.idtarifa, NEW.robanaz, NEW.jmj;
      END IF;

      RAISE INFO 'insert pos_pos_knjig prodavnica % %', NEW.idPos, NEW.idvd;
      EXECUTE 'INSERT INTO {{ ansible_nodename }}.pos_items(dok_id,idpos,idvd,brdok,datum,rbr,idroba,idtarifa,kolicina,cijena,ncijena,kol2,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)'
        USING NEW.dok_id,NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr, NEW.idroba, NEW.idtarifa,NEW.kolicina, NEW.cijena, NEW.ncijena, NEW.kol2, NEW.robanaz, NEW.jmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- na strani kase dokumenti koji dolaze od knjigovodstva

-- {{ ansible_nodename }}.pos_doks_knjig -> {{ ansible_nodename }}.pos_doks
DROP TRIGGER IF EXISTS pos_knjig_crud on {{ ansible_nodename }}.pos_knjig;
CREATE TRIGGER pos_knjig_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON {{ ansible_nodename }}.pos_knjig
      FOR EACH ROW EXECUTE PROCEDURE {{ ansible_nodename }}.on_pos_knjig_crud();

ALTER TABLE {{ ansible_nodename }}.pos_knjig ENABLE ALWAYS TRIGGER pos_knjig_crud;

-- {{ ansible_nodename }}.pos_pos_knjig -> {{ ansible_nodename }}.pos_pos
DROP TRIGGER IF EXISTS pos_items_knjig_crud on {{ ansible_nodename }}.pos_items_knjig;
CREATE TRIGGER pos_items_knjig_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON {{ ansible_nodename }}.pos_items_knjig
   FOR EACH ROW EXECUTE PROCEDURE {{ ansible_nodename }}.on_pos_items_knjig_crud();

ALTER TABLE {{ ansible_nodename }}.pos_items_knjig ENABLE ALWAYS TRIGGER pos_items_knjig_crud;


----------- TRIGERI na strani kase radi pracenja stanja -----------------------------------------------------


CREATE OR REPLACE FUNCTION {{ ansible_nodename }}.on_kasa_pos_crud() RETURNS trigger
LANGUAGE plpgsql
AS $$

BEGIN

IF (TG_OP = 'INSERT') THEN
   IF (NEW.idvd <> '02') THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'INSERT') THEN
   IF ( NEW.idvd = '02') THEN
      EXECUTE 'DELETE FROM {{ ansible_nodename }}.pos_stanje';
      EXECUTE 'DELETE FROM {{ ansible_nodename }}.roba';
      RAISE INFO '02 - inicijalizacija {{ ansible_nodename }}.pos_stanje';
      RETURN NEW;
   END IF;
END IF;

RETURN NULL;
END;
$$;

-- on {{ ansible_nodename }}.pos_items
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ ansible_nodename }}.on_kasa_pos_items_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
    idPos varchar := '15';
    lRet boolean;
    datOd date;
    datDo date;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF (NEW.idvd <> '42') AND (NEW.idvd <> '02') AND (NEW.idvd <> '22') AND (NEW.idvd <> '80') AND (NEW.idvd <> '29') AND (NEW.idvd <> '19') AND (NEW.idvd <> '79') AND (NEW.idvd <> '89')  THEN   -- 42, 11, 80, 19, 79, 89
      RETURN NULL;
   END IF;
ELSE
   IF (OLD.idvd <> '42') AND ( OLD.idvd <> '02') AND ( OLD.idvd <> '22') AND (OLD.idvd <> '80') AND (OLD.idvd <> '29') AND (OLD.idvd <> '19') AND (OLD.idvd <> '79') AND (OLD.idvd <> '89')  THEN
      RETURN NULL;
   END IF;
END IF;

IF (TG_OP = 'DELETE') AND ( OLD.idvd = '42' ) THEN
      RAISE INFO 'delete izlaz pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select {{ ansible_nodename }}.pos_izlaz_update_stanje('-', '15', '42', 'PROD91', '5', current_date, 'R01',  40, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''-'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
         USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum,  OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
         INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( (OLD.idvd='02') OR (OLD.idvd='22') OR (OLD.idvd='80') OR (OLD.idvd='89') ) THEN
      RAISE INFO 'delete pos_prijem_update_stanje  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      -- select {{ ansible_nodename }}.pos_prijem_update_stanje('-','15', '11', 'BRDOK02', '999', current_date, current_date, NULL, 'R01',  50, 2.5, 0);
      EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''-'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
               USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
               INTO lRet;
      RAISE INFO 'delete % ret=%', OLD.idvd, lRet;
      RETURN OLD;

ELSIF (TG_OP = 'DELETE') AND ( (OLD.idvd = '19') OR (OLD.idvd = '29') OR (OLD.idvd='79') ) THEN
        RAISE INFO 'delete pos_pos  % % % %', OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
        EXECUTE 'SELECT p' || idPos || '.pos_promjena_cijena_update_stanje(''-'', $1,$2,$3,$4,$5,$5,NULL,$6,$7,$8,$9)'
                   USING idPos, OLD.idvd, OLD.brdok, OLD.rbr, OLD.datum, OLD.idroba, OLD.kolicina, OLD.cijena, OLD.ncijena
                   INTO lRet;
        -- RAISE INFO 'delete  ret=%', lRet;
        RETURN OLD;

ELSIF (TG_OP = 'UPDATE') AND ( NEW.idvd = '42' ) THEN
       RAISE INFO 'update 42 pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr ;
       RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( (NEW.idvd = '02') OR (NEW.idvd = '22') OR (NEW.idvd = '80') OR (NEW.idvd = '89') ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'UPDATE') AND ( (NEW.idvd = '19') OR (NEW.idvd = '29') OR (NEW.idvd = '79') ) THEN
        RAISE INFO 'update pos_pos?!  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN
        RAISE INFO 'insert 42 pos_pos  % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- {{ ansible_nodename }}.pos_izlaz_update_stanje('+', '15', '42', 'PROD10', '999', current_date, 'R03', 10, 30, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_izlaz_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9)'
              USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum,  NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
              INTO lRet;
        RAISE INFO 'insert 42 ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( (NEW.idvd = '02') OR (NEW.idvd = '22') OR ( NEW.idvd = '80') OR ( NEW.idvd = '89') ) THEN
        RAISE INFO 'insert pos_prijem_update_stanje % % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.idroba, NEW.rbr;
        -- select {{ ansible_nodename }}.pos_prijem_update_stanje('+','15', '11', 'BRDOK01', '999', current_date, current_date, NULL,'R01', 100, 2.5, 0);
        EXECUTE 'SELECT p' || idPos || '.pos_prijem_update_stanje(''+'', $1, $2, $3, $4, $5, $5, NULL, $6, $7, $8, $9)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
             RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

ELSIF (TG_OP = 'INSERT') AND ( (NEW.idvd = '19') OR (NEW.idvd = '29') OR (NEW.idvd = '79') ) THEN
        RAISE INFO 'insert pos_pos % % % %', NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr;
        -- u pos_doks se nalazi dat_od, dat_do
        EXECUTE 'SELECT dat_od, dat_do FROM p' || idPos || '.pos_doks WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
           USING idPos, NEW.idvd, NEW.brdok, NEW.datum
           INTO datOd, datDo;
        IF datOd IS NULL THEN
           RAISE EXCEPTION 'pos_doks % % % % NE postoji?!', idPos, NEW.idvd, NEW.brdok, NEW.datum;
        END IF;

        EXECUTE 'SELECT p' || idPos || '.pos_promjena_cijena_update_stanje(''+'', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'
             USING idPos, NEW.idvd, NEW.brdok, NEW.rbr, NEW.datum, datOd, datDo, NEW.idroba, NEW.kolicina, NEW.cijena, NEW.ncijena
             INTO lRet;
        RAISE INFO 'insert ret=%', lRet;
        RETURN NEW;

END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;

-- {{ ansible_nodename }}.pos na kasi
DROP TRIGGER IF EXISTS kasa_pos_crud on {{ ansible_nodename }}.pos;
    CREATE TRIGGER kasa_pos_crud
        AFTER INSERT OR DELETE OR UPDATE
        ON {{ ansible_nodename }}.pos
        FOR EACH ROW EXECUTE PROCEDURE {{ ansible_nodename }}.on_kasa_pos_crud();

-- {{ ansible_nodename }}.pos_items na kasi
DROP TRIGGER IF EXISTS kasa_pos_items_crud on {{ ansible_nodename }}.pos_items;
CREATE TRIGGER kasa_pos_items_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON {{ ansible_nodename }}.pos_items
      FOR EACH ROW EXECUTE PROCEDURE {{ ansible_nodename }}.on_kasa_pos_items_crud();
