----------- TRIGERI na strani knjigovodstva POS - KALK_DOKS ! -----------------------------------------------------

-- on {{ item_prodavnica }}.pos -> f18.kalk_doks
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_pos_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$
DECLARE
       knjigShema varchar := 'public';
       pKonto varchar;
       brDok varchar;
       idFirma varchar;
       idvdKalk varchar;
       nProdavnica integer;
       cMKonto varchar;
BEGIN

-- select to_number(substring('p16',2),'9999')::integer
-- =>  16
nProdavnica := to_number(substring('{{ item_prodavnica }}',2),'9999')::integer;

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN -- POS -> KALK
   -- 42 - prodaja
   -- 71 - zahtjev snizenje
   -- 61 - zahtjev narudzba
   -- 22 -pos potvrda prijema magacin
   -- 29 - pos nivelacija
   -- 89 - direktni prijem u prodavnicu od dobavljaca
   IF ( NOT NEW.idvd IN ('42','71','61','22','29','89','90','99') ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
          from public.koncij where prod=nProdavnica;
  IF ( NEW.idvd = '42') THEN
       idvdKalk := '49';
   ELSE
       idvdKalk := NEW.idvd;
   END IF;
   SELECT public.kalk_brdok_iz_pos(nProdavnica, idvdKalk, NEW.brdok, NEW.datum)
          INTO brDok;
ELSE
   IF ( NOT OLD.idvd IN ('42','71','61','22','29','89','90','99') ) THEN
      RETURN NULL;
   END IF;
   SELECT id INTO pKonto
      from public.koncij where prod=nProdavnica;
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
         IF ( NEW.idvd = '22' ) THEN
            -- pos prijem u magacin
            cMKonto := rpad( NEW.idpartner, 7);
         ELSE
            cMKonto := '';
         END IF;
         RAISE INFO 'THEN insert kalk_doks % % % %', idFirma, pKonto, brDok, NEW.datum;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_doks(idfirma,idvd,brdok,datdok,pkonto,dat_od,dat_do,idPartner,brFaktP,opis,mkonto) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)'
                     USING idFirma, idvdKalk, brDok, NEW.datum, pKonto, NEW.dat_od, NEW.dat_do, NEW.idPartner, NEW.brFaktP, NEW.opis, cMKonto;
         RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


----------- TRIGERI na strani knjigovodstva POS - KALK_KALK ! -----------------------------------------------------

-- on {{ item_prodavnica }}.pos_items -> f18.kalk_kalk
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION {{ item_prodavnica }}.on_pos_items_crud() RETURNS trigger
       LANGUAGE plpgsql
       AS $$

DECLARE
       knjigShema varchar := 'public';
       cPKonto varchar;
       cMKonto varchar;
       cBrDok varchar;
       pdvStopa numeric;
       idFirma varchar;
       idvdKalk varchar;
       pUI varchar;
       nProdavnica integer;
       nKolicina numeric;
       nKnjiznaKolicina numeric;

BEGIN

-- select to_number(substring('p16',2),'9999')::integer
-- =>  16
nProdavnica := to_number(substring('{{ item_prodavnica }}',2),'9999')::integer;

IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN  -- POS -> KALK
   IF ( NOT NEW.idvd IN ('42','71','61','22','29','89','90','99') ) THEN
      RETURN NULL;
   END IF;
   IF ( NEW.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := NEW.idvd;
   END IF;
   SELECT id INTO cPKonto
        from public.koncij where prod=nProdavnica LIMIT 1;
   cBrDok := public.kalk_brdok_iz_pos( nProdavnica, idvdKalk, NEW.brdok, NEW.datum);
   SELECT mkonto INTO cMKonto
        FROM public.kalk_doks where idvd=idvdKalk and brdok=cBrDok and datdok=NEW.datum LIMIT 1;

ELSE
   IF ( NOT OLD.idvd IN ('42','71','61','22','29','89','90','99') ) THEN
      RETURN NULL;
   END IF;
   IF ( OLD.idvd = '42') THEN
      idvdKalk := '49';
   ELSE
      idvdKalk := OLD.idvd;
   END IF;
   SELECT id INTO cPKonto
       from public.koncij where prod=nProdavnica;
   cBrDok := public.kalk_brdok_iz_pos(nProdavnica, idvdKalk, OLD.brdok, OLD.datum);
END IF;

SELECT public.fetchmetrictext('org_id') INTO idFirma;

IF (TG_OP = 'DELETE') THEN
      RAISE INFO 'delete kalk_kalk % % % %', cPKonto, idVdKalk, OLD.datum, cBrDok;
      EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brdok=$4'
            USING cPKonto, idvdKalk, OLD.datum, cBrDok;
         RETURN OLD;
ELSIF (TG_OP = 'UPDATE') THEN
         RAISE INFO 'update kalk_kalk !? % % %', cPKonto, cBrDok, idvdKalk;
         RETURN NEW;
ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd = '42' ) THEN -- 42 POS => 49 KALK
         RAISE INFO 'FIRST delete kalk_kalk % % % %', idvdKalk, cPKonto, NEW.datum, cBrDok;
         EXECUTE 'DELETE FROM ' || knjigShema || '.kalk_kalk WHERE pkonto=$1 AND idvd=$2 AND datdok=$3 AND brDok=$4'
                USING cPKonto, idvdKalk, NEW.datum, cBrDok;
         RAISE INFO 'THEN insert POS 42 => kalk_kalk % % % % %', NEW.idpos, idvdKalk, cBrDok, NEW.datum, cPKonto;
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj, pu_i, mu_i, tmarza2, rabatv) ' ||
                 '(SELECT $1 as idfirma, $2 as idvd,' ||
                 ' (row_number() over (order by idroba))::integer as rbr,' ||
                 ' $3 as brdok, $4 as datdok,$6 as pkonto, idroba, idtarifa, cijena as mpcsapp, sum(kolicina) as kolicina, ' ||
                 ' public.pos_neto_cijena(cijena, ncijena)/(1 + tarifa.pdv/100) as mpc, 0.00000001 as nc, 0.00000001 as fcj,''9'','''',''A'', public.pos_popust(cijena, ncijena)/(1 + tarifa.pdv/100) ' ||
                 ' FROM {{ item_prodavnica }}.pos_items ' ||
                 ' LEFT JOIN public.tarifa on pos_items.idtarifa = tarifa.id' ||
                 ' WHERE idvd=''42'' AND datum=$4 AND idpos=$5' ||
                 ' GROUP BY idroba,idtarifa,cijena,ncijena,tarifa.pdv' ||
                 ' ORDER BY idroba)'
              USING idFirma, idvdKalk, cBrDok, NEW.datum, NEW.idpos, cPKonto;
         RETURN NEW;

  ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd IN ('61','22','89','90','99') ) THEN

          pUI := 'P';
          IF ( NEW.idvd = '90' ) THEN
             pUI := 'I';
             nKolicina := NEW.kolicina;
             nKnjiznaKolicina := NEW.kol2;
          ELSE
             nKolicina := NEW.kolicina;
             nKnjiznaKolicina := 0;
          END IF;
          EXECUTE 'SELECT pdv from public.tarifa where id=$1'
               USING NEW.idtarifa
               INTO pdvStopa;
          RAISE INFO 'THEN insert kalk_kalk % % % % % %', NEW.idpos, idvdKalk, cPKonto, cMKonto, cBrDok, NEW.datum;

          IF NEW.idvd='90' THEN -- popis u prodavnici
            -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
             -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
             -- kalk 90: fcj = knjizna vrijednost = nKnjiznaKolicina * NEW.cijena = $15 * $9
             EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, mkonto, pu_i, gkolicina, gkolicin2, fcj ) ' ||
                 'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $12/100), $11, $13, $14, $15, $15-$10, $15 * $9)'
                  USING idFirma, idvdKalk, NEW.rbr, cBrDok, NEW.datum, cPKonto, NEW.idroba, NEW.idtarifa,
                  NEW.cijena, nKolicina, 0, pdvStopa, cMKonto, pUI, nKnjiznaKolicina;
             RETURN NEW;
           ELSE
             EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, mkonto, pu_i, gkolicina, gkolicin2, fcj ) ' ||
                'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $12/100), $11, $13, $14, 0, 0, 0)'
                USING idFirma, idvdKalk, NEW.rbr, cBrDok, NEW.datum, cPKonto, NEW.idroba, NEW.idtarifa,
                NEW.cijena, nKolicina, 0, pdvStopa, cMKonto, pUI;
             RETURN NEW;
           END IF;

  -- 71 - zahtjev snizenje, 29 - pos nivelacija generisana na osnovu akcijskih cijena
  ELSIF (TG_OP = 'INSERT') AND ( NEW.idvd IN ('71', '29') ) THEN

         IF (NEW.idvd = '29') THEN
             pUI := '3';
         ELSE
             pUI := '%';
         END IF;
         EXECUTE 'SELECT pdv from public.tarifa where id=$1'
                USING NEW.idtarifa
                INTO pdvStopa;
         RAISE INFO 'THEN insert kalk_kalk % % % % %', NEW.idpos, idvdKalk, cPKonto, cBrDok, NEW.datum;
         -- pos.cijena = 10, pos.ncijena = 1 => neto_cijena = 10-1 = 9
         -- kalk: fcj = stara cijena = 10 = pos.cijena, mpcsapp - razlika u cijeni = 9 - 10 = -1 = - pos.ncijena
         EXECUTE 'INSERT INTO ' || knjigShema || '.kalk_kalk(idfirma, idvd, rbr, brdok, datdok, pkonto, idroba, idtarifa, mpcsapp, kolicina, mpc, nc, fcj, pu_i) ' ||
                  'values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $9/(1 + $13/100), $11, $12, $14)'
                 USING idFirma, idvdKalk, NEW.rbr, cBrDok, NEW.datum, cPKonto, NEW.idroba, NEW.idtarifa,
                 NEW.ncijena-NEW.cijena, NEW.kolicina, 0, NEW.cijena, pdvStopa, pUI;
          RETURN NEW;
END IF;

RETURN NULL; -- result is ignored since this is an AFTER trigger

END;
$$;


-- {{ item_prodavnica }}.pos -> f18.kalk_doks
DROP TRIGGER IF EXISTS knjig_pos_crud on {{ item_prodavnica }}.pos;
CREATE TRIGGER knjig_pos_crud
   AFTER INSERT OR DELETE OR UPDATE
   ON {{ item_prodavnica }}.pos
   FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_pos_crud();

-- {{ item_prodavnica }}.pos_items -> f18.kalk_kalk
DROP TRIGGER IF EXISTS knjig_pos_items_crud on {{ item_prodavnica }}.pos_items;
CREATE TRIGGER knjig_pos_items_crud
      AFTER INSERT OR DELETE OR UPDATE
      ON {{ item_prodavnica }}.pos_items
      FOR EACH ROW EXECUTE PROCEDURE {{ item_prodavnica }}.on_pos_items_crud();


ALTER TABLE {{ item_prodavnica }}.pos ENABLE ALWAYS TRIGGER knjig_pos_crud;
ALTER TABLE {{ item_prodavnica }}.pos_items ENABLE ALWAYS TRIGGER knjig_pos_items_crud;