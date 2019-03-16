-----------------------------------------------------
-- pos_pos_knjig, pos_doks_knjig
----------------------------------------------------

CREATE TABLE IF NOT EXISTS p16.pos_knjig (
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
  ref uuid,
  ref_2 uuid,
  ukupno numeric(16,5),
  brFaktP varchar(10),
  opis varchar(100),
  dat_od date,
  dat_do date,
  obradjeno timestamp with time zone DEFAULT now(),
  korisnik text DEFAULT current_user
);

ALTER TABLE p16.pos_knjig OWNER TO admin;
CREATE INDEX IF NOT EXISTS pos_id1_knjig ON p16.pos_knjig USING btree (idpos, idvd, datum, brdok);
CREATE INDEX IF NOT EXISTS pos_id2_knjig ON p16.pos_knjig USING btree (idvd, datum);
CREATE INDEX IF NOT EXISTS pos_id3_knjig ON p16.pos_knjig USING btree (idPartner, datum);
CREATE INDEX IF NOT EXISTS pos_id6_knjig ON p16.pos_knjig USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_knjig_dok_id ON p16.pos_knjig USING btree( dok_id );
GRANT ALL ON TABLE p16.pos_knjig TO xtrole;

CREATE TABLE IF NOT EXISTS p16.pos_items_knjig (
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
ALTER TABLE p16.pos_items_knjig OWNER TO admin;
CREATE INDEX IF NOT EXISTS pos_items_id1_knjig ON p16.pos_items_knjig USING btree (idpos, idvd, datum, brdok, idroba);
CREATE INDEX IF NOT EXISTS pos_items_id2_knjig ON p16.pos_items_knjig USING btree (idroba, datum);
CREATE INDEX IF NOT EXISTS pos_items_id4_knjig ON p16.pos_items_knjig USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_items_id5_knjig ON p16.pos_items_knjig USING btree (idpos, idroba, datum);
CREATE INDEX IF NOT EXISTS pos_items_id6_knjig ON p16.pos_items_knjig USING btree (idroba);
GRANT ALL ON TABLE p16.pos_items_knjig TO xtrole;


CREATE TABLE IF NOT EXISTS  p16.roba (
    id character(10) NOT NULL,
    sifradob character(20),
    naz character varying(250),
    jmj character(3),
    idtarifa character(6),
    mpc numeric(18,8),
    tip character(1),
    opis text,
    barkod character(13),
    fisc_plu numeric(10,0)
);
ALTER TABLE p16.roba OWNER TO admin;





CREATE TABLE IF NOT EXISTS p16.pos (
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
    ref uuid,
    ref_2 uuid,
    ukupno numeric(16,5),
    brFaktP varchar(10),
    opis varchar(100),
    dat_od date,
    dat_do date,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);

comment on column p16.pos.ref_fisk_dok is 'za 42 referenca na pos_fisk_doks.dok_id';
comment on column p16.pos.ref is 'za 72 referenca na pos dokument 29-start nivelacija';
comment on column p16.pos.ref_2 is 'za 72 referenca na pos dokument 29-end nivelacija';

ALTER TABLE p16.pos OWNER TO admin;
GRANT ALL ON TABLE p16.pos TO xtrole;

CREATE INDEX IF NOT EXISTS pos_id1 ON p16.pos USING btree (idpos, idvd, datum, brdok);
CREATE INDEX IF NOT EXISTS pos_id2 ON p16.pos USING btree (idvd, datum);
CREATE INDEX IF NOT EXISTS pos_id3 ON p16.pos USING btree (idPartner, datum);
CREATE INDEX IF NOT EXISTS pos_id6 ON p16.pos USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_dok_id ON p16.pos USING btree( dok_id );
CREATE INDEX IF NOT EXISTS pos_ref_fisk_dok ON p16.pos USING btree( ref_fisk_dok );




CREATE TABLE IF NOT EXISTS p16.pos_items (
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
ALTER TABLE p16.pos_items OWNER TO admin;
GRANT ALL ON TABLE p16.pos_items TO xtrole;
