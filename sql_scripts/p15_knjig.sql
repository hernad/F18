-----------------------------------------------------
-- pos_pos_knjig, pos_doks_knjig
----------------------------------------------------

CREATE TABLE IF NOT EXISTS p15.pos_doks_knjig (
  dok_id uuid DEFAULT gen_random_uuid(),
  idpos character varying(2) NOT NULL,
  idvd character varying(2) NOT NULL,
  brdok character varying(8) NOT NULL,
  datum date,
  idPartner character varying(6),
  idradnik character varying(4),
  idvrstep character(2),
  vrijeme character varying(5),
  ref_fisk_dok uuid,
  --brdokStorn character varying(8),
  --fisc_rn numeric(10,0),
  ukupno numeric(15,5),
  brFaktP varchar(10),
  opis varchar(100),
  dat_od date,
  dat_do date,
  obradjeno timestamp with time zone DEFAULT now(),
  korisnik text DEFAULT current_user
);

ALTER TABLE p15.pos_doks_knjig OWNER TO admin;
CREATE INDEX pos_doks_id1_knjig ON p15.pos_doks_knjig USING btree (idpos, idvd, datum, brdok);
CREATE INDEX pos_doks_id2_knjig ON p15.pos_doks_knjig USING btree (idvd, datum);
CREATE INDEX pos_doks_id3_knjig ON p15.pos_doks_knjig USING btree (idPartner, datum);
CREATE INDEX pos_doks_id6_knjig ON p15.pos_doks_knjig USING btree (datum);
GRANT ALL ON TABLE p15.pos_doks_knjig TO xtrole;

CREATE TABLE IF NOT EXISTS p15.pos_pos_knjig (
  dok_id uuid,
  idpos character varying(2),
  idvd character varying(2),
  brdok character varying(8),
  datum date,
  idroba character(10),
  idtarifa character(6),
  kolicina numeric(18,3),
  kol2 numeric(18,3),
  cijena numeric(10,3),
  ncijena numeric(10,3),
  rbr integer NOT NULL,
  robanaz varchar,
  jmj varchar
);
ALTER TABLE p15.pos_pos_knjig OWNER TO admin;
CREATE INDEX pos_pos_id1_knjig ON p15.pos_pos_knjig USING btree (idpos, idvd, datum, brdok, idroba);
CREATE INDEX pos_pos_id2_knjig ON p15.pos_pos_knjig USING btree (idroba, datum);
CREATE INDEX pos_pos_id4_knjig ON p15.pos_pos_knjig USING btree (datum);
CREATE INDEX pos_pos_id5_knjig ON p15.pos_pos_knjig USING btree (idpos, idroba, datum);
CREATE INDEX pos_pos_id6_knjig ON p15.pos_pos_knjig USING btree (idroba);
GRANT ALL ON TABLE p15.pos_pos_knjig TO xtrole;
--
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS funk;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS sto;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS sto_br;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS zak_br;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS idgost;
-- ALTER TABLE p15.pos_doks ALTER COLUMN brdok TYPE varchar(8);
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS idpartner varchar(6);
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS brdokStorn varchar(8);
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_1;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_2;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS c_3;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS m1;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS idodj;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS smjena;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS rabat;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS prebacen;
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS brFaktP varchar(10);
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS opis varchar(100);
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS dat_od date;
-- ALTER TABLE p15.pos_doks ADD COLUMN IF NOT EXISTS dat_do date;
-- ALTER TABLE p15.pos_doks DROP COLUMN IF EXISTS placen;
--
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS funk;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS sto;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS sto_br;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS zak_br;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS idgost;
-- ALTER TABLE p15.pos_doks_knjig ALTER COLUMN brdok TYPE varchar(8);
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS idpartner varchar(6);
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS brdokStorn varchar(8);
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_1;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_2;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS c_3;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS m1;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS idodj;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS smjena;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS rabat;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS prebacen;
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS brFaktP varchar(10);
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS opis varchar(100);
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS dat_od date;
-- ALTER TABLE p15.pos_doks_knjig ADD COLUMN IF NOT EXISTS dat_do date;
-- ALTER TABLE p15.pos_doks_knjig DROP COLUMN IF EXISTS placen;
--
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS iddio;
-- ALTER TABLE p15.pos_pos ALTER COLUMN brdok TYPE varchar(8);
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_1;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_2;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS c_3;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS m1;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idodj;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS smjena;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS prebacen;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS mu_i;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idcijena;
-- ALTER TABLE p15.pos_pos DROP COLUMN IF EXISTS idradnik;
-- --update p15.pos_pos set rbr = lpad(ltrim(rbr),3);
--ALTER TABLE p15.pos_pos ALTER COLUMN rbr TYPE character(3);
--ALTER TABLE p15.pos_pos ALTER COLUMN rbr TYPE integer;

-- ALTER TABLE p15.pos_pos ALTER COLUMN rbr SET NOT NULL;
-- ALTER TABLE p15.pos_pos ADD COLUMN IF NOT EXISTS robanaz varchar;


-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS iddio;
-- ALTER TABLE p15.pos_pos_knjig ALTER COLUMN brdok TYPE varchar(8);
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_1;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_2;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS c_3;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS m1;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idodj;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS smjena;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS prebacen;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS mu_i;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idcijena;
-- ALTER TABLE p15.pos_pos_knjig DROP COLUMN IF EXISTS idradnik;
--update p15.pos_pos_knjig set rbr = lpad(ltrim(rbr),3);
--ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr TYPE character(3);
-- ALTER TABLE p15.pos_pos_knjig ALTER COLUMN rbr SET NOT NULL;
-- ALTER TABLE p15.pos_pos_knjig ADD COLUMN IF NOT EXISTS robanaz varchar;


---------------------------------------------------------------------------------------
-- TRIGER na strani prodavnice !
-- on p15.pos_pos_knjig -> p15.pos_pos
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_pos_knjig_crud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

DECLARE
    robaId varchar;
    robaCijena numeric;
BEGIN

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete pos_pos_knjig prodavnica % %', OLD.idPos, OLD.idvd;
      EXECUTE 'DELETE FROM p15.pos_pos WHERE idpos=$1 AND idvd=$2 AND brdok=$3 AND datum=$4 AND rbr=$5'
         USING OLD.idpos, OLD.idvd, OLD.brdok, OLD.datum, OLD.rbr;
      RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
      RAISE INFO 'update pos_pos_knjig prodavnica!? %', NEW.idPos;
      RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
      RAISE INFO 'FIRST insert/update roba u prodavnici';
      EXECUTE 'SELECT id from p15.roba WHERE id=$1'
         USING NEW.idroba
         INTO robaId;

      IF (NEW.idvd = '19') THEN
         robaCijena := NEW.ncijena;
      ELSE
         robaCijena := NEW.cijena;
      END IF;

      IF NOT robaId IS NULL THEN -- roba postoji u sifarniku
         EXECUTE 'UPDATE p15.roba SET barkod=$2, idtarifa=$3, naz=$4, mpc=$5, jmj=$6 WHERE id=$1'
           USING robaId, public.num_to_barkod_ean13(NEW.kol2, 3), NEW.idtarifa, NEW.robanaz, robaCijena, NEW.jmj;
      ELSE
         EXECUTE 'INSERT INTO p15.roba(id,barkod,mpc,idtarifa,naz,jmj) values($1,$2,$3,$4,$5,$6)'
           USING NEW.idroba, public.num_to_barkod_ean13(NEW.kol2, 3), robaCijena, NEW.idtarifa, NEW.robanaz, NEW.jmj;
      END IF;

      RAISE INFO 'insert pos_pos_knjig prodavnica % %', NEW.idPos, NEW.idvd;
      EXECUTE 'INSERT INTO p15.pos_pos(idpos,idvd,brdok,datum,rbr,idroba,idtarifa,kolicina,cijena,ncijena,kol2,robanaz,jmj) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)'
        USING NEW.idpos, NEW.idvd, NEW.brdok, NEW.datum, NEW.rbr, NEW.idroba, NEW.idtarifa,NEW.kolicina, NEW.cijena, NEW.ncijena, NEW.kol2, NEW.robanaz, NEW.jmj;
      RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos_doks_knjig -> p15.pos_doks
DROP TRIGGER IF EXISTS pos_doks_knjig_crud on p15.pos_doks_knjig;
CREATE TRIGGER pos_doks_knjig_icrud
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_doks_knjig
      FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_doks_knjig_crud();

-- p15.pos_pos_knjig -> p15.pos_pos
DROP TRIGGER IF EXISTS pos_pos_knjig_crud on p15.pos_pos_knjig;
CREATE TRIGGER pos_pos_knjig_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos_pos_knjig
   FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_pos_knjig_crud();
