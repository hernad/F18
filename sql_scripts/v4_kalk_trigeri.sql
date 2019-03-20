
---------------------------------------------------------------------------------------
-- on kalk_kalk update p15.pos_pos_knjig,
-- idvd = 19 - nivelacija prodavnica,
--        02 - pocetno stanje prodavnica
--        21 - zahtjev za prijem robe iz magacina
--        80 - prijem prodavnica
--        79 - odobreno snizenje
--        72 - akcijske cijene
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION f18.on_kalk_kalk_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar DEFAULT '1 ';
    cijena decimal;
    ncijena decimal;
    barkodRoba varchar DEFAULT '';
    robaNaz varchar;
    robaJmj varchar;
    cProdShema varchar;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '19' ) AND ( NEW.idvd <> '02' ) AND ( NEW.idvd <> '21' ) AND ( NEW.idvd <> '80' ) AND ( NEW.idvd <> '79' ) AND ( NEW.idvd <> '72' ) THEN
     RETURN NULL;
   END IF;
   cProdShema := 'p' || btrim(to_char(public.pos_prodavnica_by_pkonto( NEW.pkonto ), '999'));
   SELECT barkod, naz, jmj INTO barkodRoba, robaNaz, robaJmj
          from public.roba where id=NEW.idroba;
ELSE
   IF ( OLD.idvd <> '19' ) AND ( OLD.idvd <> '02' ) AND ( OLD.idvd <> '21' ) AND ( OLD.idvd <> '80' ) AND ( OLD.idvd <> '79' ) AND ( OLD.idvd <> '72' ) THEN
      RETURN NULL;
   END IF;
   cProdShema := 'p' || btrim(to_char(public.pos_prodavnica_by_pkonto( OLD.pkonto ), '999'));
END IF;

-- u koncij nije dodijeljena prodavnica za ovaj konto - STOP!
IF ( cProdShema IS NULL ) OR ( cProdShema = 'p0' ) THEN
    RETURN NULL;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete % prodavnica %', OLD.idvd, cProdShema;
      EXECUTE 'DELETE FROM '  || cProdShema || '.pos_pos_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING idpos, OLD.idvd, OLD.brdok, OLD.datdok, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update % prodavnica!? %', NEW.idvd, cProdShema;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert % prodavnica % % %', NEW.idvd, cProdShema, NEW.idroba, public.barkod_ean13_to_num(barkodRoba,3);
      IF ( NEW.idvd = '19' ) OR ( NEW.idvd = '79' ) OR ( NEW.idvd = '72' ) THEN
        cijena := NEW.fcj;  -- stara cijena
        ncijena := NEW.mpcsapp + NEW.fcj; -- nova cijena
      ELSE
        cijena := NEW.mpcsapp;
        ncijena := 0;
      END IF;
      EXECUTE 'INSERT INTO ' || cProdShema || '.pos_items_knjig(idpos,idvd,brdok,datum,rbr,idroba,kolicina,cijena,ncijena,kol2,idtarifa,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
        USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.rbr, NEW.idroba, NEW.kolicina, cijena, ncijena, public.barkod_ean13_to_num(barkodRoba,3), NEW.idtarifa, robaNaz,robaJmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


---------------------------------------------------------------------------------------
-- on kalk_doks update p15.pos_doks_knjig
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION f18.on_kalk_doks_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    idPos varchar DEFAULT '1 ';
    cProdShema varchar;
BEGIN


IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
      IF ( NEW.idvd <> '19' ) AND ( NEW.idvd <> '02' ) AND ( NEW.idvd <> '21' ) AND ( NEW.idvd <> '80' ) AND ( NEW.idvd <> '79' ) AND ( NEW.idvd <> '72' ) THEN
         RETURN NULL;
      END IF;
      cProdShema := 'p' || btrim(to_char(public.pos_prodavnica_by_pkonto( NEW.pkonto ), '999'));
ELSE
     IF ( OLD.idvd <> '19' ) AND ( OLD.idvd <> '02' ) AND ( OLD.idvd <> '21' ) AND ( OLD.idvd <> '80' ) AND ( OLD.idvd <> '79' ) AND ( OLD.idvd <> '72' ) THEN
        RETURN NULL;
     END IF;
     cProdShema := 'p' || btrim(to_char(public.pos_prodavnica_by_pkonto( OLD.pkonto ), '999'));
END IF;

IF ( cProdShema IS NULL ) OR ( cProdShema = 'p0' ) THEN
    RETURN NULL;
END IF;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete doks prodavnica %', idPos;
      EXECUTE 'DELETE FROM ' || cProdShema || '.pos_doks_knjig WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4'
             USING idpos, OLD.idvd, OLD.brdok, OLD.datdok;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update doks prodavnica!? %', cProdShema;
          RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'insert doks prodavnica %', cProdShema;
      EXECUTE 'INSERT INTO ' || cProdShema || '.pos_doks_knjig(idpos,idvd,brdok,datum,brFaktP,dat_od,dat_do,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8)'
            USING idpos, NEW.idvd, NEW.brdok, NEW.datdok, NEW.brFaktP, NEW.dat_od, NEW.dat_do, NEW.opis;

      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- f18.kalk_kalk -> p15.pos_pos_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_crud on f18.kalk_kalk;
CREATE TRIGGER t_kalk_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON f18.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE f18.on_kalk_kalk_crud();

-- f18.kalk_doks -> p15.pos_doks_knjig -> ...

DROP TRIGGER IF EXISTS t_kalk_doks_crud on f18.kalk_doks;
CREATE TRIGGER t_kalk_doks_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON f18.kalk_doks
      FOR EACH ROW EXECUTE PROCEDURE f18.on_kalk_doks_crud();
