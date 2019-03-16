----------- TRIGERI na strani knjigovodstva POS_DOKS - KALK_DOKS ! -----------------------------------------------------

-- on p15.pos -> f18.kalk_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
       knjigShema varchar := 'public';
       pKonto varchar;
       brDok varchar;
       idFirma varchar;
       idvdKalk varchar;
       nProdavnica integer DEFAULT 15;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   --  42 - prodaja, 71-zahtjev snizenje, 61-zahtjev narudzba, 22 -pos potvrda prijema magacin, 29 - pos nivelacija
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '71' ) AND ( NEW.idvd <> '61' ) AND ( NEW.idvd <> '22' ) AND ( NEW.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from public.koncij where prod=15;
  IF ( NEW.idvd = '42') THEN
       idvdKalk := '49';
   ELSE
       idvdKalk := NEW.idvd;
   END IF;
   SELECT public.kalk_brdok_iz_pos(nProdavnica, idvdKalk, NEW.brdok, NEW.datum)
          INTO brDok;
ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '71' ) AND ( OLD.idvd <> '61' ) AND ( OLD.idvd <> '22' ) AND ( OLD.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
      from public.koncij where prod=15;
   IF ( OLD.idvd = '42') THEN
        idvdKalk := '49';
    ELSE
        idvdKalk := OLD.idvd;
    END IF;
    SELECT public.kalk_brdok_iz_pos(nProdavnica, idvdKalk, OLD.brdok, OLD.datum)
         INTO brDok;
END IF;

SELECT public.fetchmetrictext('org_id') INTO idFirma;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_doks % % % % %', idFirma, pKonto, OLD.idvd, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE idfirma=$1 AND pkonto=$2 AND idvd=$3 AND datdok=$4 AND brdok=$5'
            USING idFirma, pKonto, idvdKalk, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_doks !? % % %', pKonto, brDok, idvdKalk;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
         RAISE INFO 'FIRST delete kalk_doks % % % %', idFirma, pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_doks WHERE idFirma=$1 AND pkonto=$2 AND idvd=$3 AND datdok=$4 AND brDok=$5'
                USING idFirma, pKonto, idvdKalk, NEW.datum, brDok;
         RAISE INFO 'THEN insert kalk_doks % % % %', idFirma, pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_doks(idfirma,idvd,brdok,datdok,pkonto,dat_od,dat_do,idPartner,brFaktP,opis) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)'
                     USING idFirma, idvdKalk, brDok, NEW.datum, pKonto, NEW.dat_od, NEW.dat_do, NEW.idPartner, NEW.brFaktP, NEW.opis;
         RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


----------- TRIGERI na strani knjigovodstva POS - KALK_KALK ! -----------------------------------------------------

-- on p15.pos_items -> f18.kalk_kalk
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION p15.on_pos_items_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'public';
       pKonto varchar;
       brDok varchar;
       pdvStopa numeric;
       idFirma varchar;
       idvdKalk varchar;
       pUI varchar;
       nProdavnica integer DEFAULT 15;
BEGIN

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
   IF ( NEW.idvd <> '42' ) AND ( NEW.idvd <> '71' ) AND ( NEW.idvd <> '61' ) AND ( NEW.idvd <> '22' ) AND ( NEW.idvd <> '29' ) THEN -- samo 42-prodaja, 71-zahtjev za snizenje, 61-zahtjev narudzba, 22-pos potvrda prijema magacin
      RETURN NULL;
   END IF;
   IF ( NEW.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := NEW.idvd;
   END IF;
   SELECT id INTO pKonto
          from public.koncij where prod=15;
   brDok := public.kalk_brdok_iz_pos( nProdavnica, idvdKalk, NEW.brdok, NEW.datum);

ELSE
   IF ( OLD.idvd <> '42' ) AND ( OLD.idvd <> '71' ) AND ( OLD.idvd <> '61' ) AND ( OLD.idvd <> '22' ) AND ( OLD.idvd <> '29' ) THEN
      RETURN NULL;
   END IF;
   IF ( OLD.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := OLD.idvd;
   END IF;
   SELECT id INTO pKonto
       from public.koncij where prod=15;
   brDok := public.kalk_brdok_iz_pos(nProdavnica, idvdKalk, OLD.brdok, OLD.datum);
END IF;

SELECT public.fetchmetrictext('org_id') INTO idFirma;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_kalk % % % %', pKonto, idVdKalk, OLD.datum, brDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING pKonto, idvdKalk, OLD.datum, brDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_kalk !? % % %', pKonto, brDok, idvdKalk;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN -- 42 POS => 49 KALK
         RAISE INFO 'FIRST delete kalk_kalk % % % %', idvdKalk, pKonto, NEW.datum, brDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING pKonto, idvdKalk, NEW.datum, brDok;
         RAISE INFO 'THEN insert POS 42 => kalk_kalk % % % % %', NEW.idpos, idvdKalk, brDok, NEW.datum, pKonto;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj) ' ||
                 '(SELECT $1 as idfirma, $2 as idvd,' ||
                 ' (row_number() over (order by idroba))::integer as rbr,' ||
                 ' $3 as brdok, $4 as datdok,$6 as pkonto, idroba, idtarifa, cijena as mpcsapp, sum(kolicina) as kolicina, ' ||
                 ' cijena/(1 + tarifa.pdv/100) as mpc, 0.00000001 as nc, 0.00000001 as fcj' ||
                 ' FROM p15.pos_pos ' ||
                 ' LEFT JOIN public.tarifa on pos_pos.idtarifa = tarifa.id' ||
                 ' WHERE idvd=''42'' AND datum=$4 AND idpos=$5' ||
                 ' GROUP BY idroba,idtarifa,cijena,ncijena,tarifa.pdv' ||
                 ' ORDER BY idroba)'
              USING idFirma, idvdKalk, brDok, NEW.datum, NEW.idpos, pKonto;
         RETURN NEW;

  ELSIF (TG_OP = 'INSERT') AND  (( NEW.idvd = '61' ) OR ( NEW.idvd = '22' )) THEN

                EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                       USING NEW.idtarifa
                       INTO pdvStopa;
                RAISE INFO 'THEN insert kalk_kalk % % % % %', NEW.idpos, idvdKalk, pKonto, brDok, NEW.datum;
                -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
                -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
                EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc) ' ||
                         'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $12/100), $11)'
                        USING idFirma, idvdKalk, NEW.rbr, brDok, NEW.datum, pKonto, NEW.idroba, NEW.idtarifa,
                        NEW.cijena, NEW.kolicina, 0, pdvStopa;
                 RETURN NEW;

  -- 71 - zahtjev snizenje, 29 - pos nivelacija generisana na osnovu akcijskih cijena
  ELSIF (TG_OP = 'INSERT') AND (( NEW.idvd = '71' ) OR ( NEW.idvd = '29' )) THEN

         IF (NEW.idvd = '29') THEN
             pUI := '3';
         ELSE
             pUI := '%';
         END IF;
         EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                USING NEW.idtarifa
                INTO pdvStopa;
         RAISE INFO 'THEN insert kalk_kalk % % % % %', NEW.idpos, idvdKalk, pKonto, brDok, NEW.datum;
         -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
         -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj, pu_i) ' ||
                  'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $13/100), $11, $12, $13)'
                 USING idFirma, idvdKalk, NEW.rbr, brDok, NEW.datum, pKonto, NEW.idroba, NEW.idtarifa,
                 NEW.ncijena-NEW.cijena, NEW.kolicina, 0, NEW.cijena, pdvStopa, pUI;
          RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- p15.pos -> f18.kalk_doks
DROP TRIGGER IF EXISTS knjig_pos_crud on p15.pos;
CREATE TRIGGER knjig_pos_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON p15.pos
   FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_crud();

-- p15.pos_items -> f18.kalk_kalk
DROP TRIGGER IF EXISTS knjig_pos_items_crud on p15.pos_items;
CREATE TRIGGER knjig_pos_items_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON p15.pos_items
      FOR EACH ROW EXECUTE PROCEDURE p15.on_pos_items_crud();
