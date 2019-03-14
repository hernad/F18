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
