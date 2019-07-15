CREATE SCHEMA IF NOT EXISTS {{ item_prodavnica }};
ALTER SCHEMA {{ item_prodavnica }} OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_fisk_doks (
    dok_id uuid DEFAULT gen_random_uuid(),
    ref_pos_dok uuid,
    broj_rn integer,
    ref_storno_fisk_dok uuid,
    partner_id uuid,
    ukupno real,
    popust real,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);
ALTER TABLE {{ item_prodavnica }}.pos_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_fisk_doks TO xtrole;


DO $$
BEGIN
   ALTER TABLE {{ item_prodavnica }}.pos_fisk_doks ADD PRIMARY KEY (dok_id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'pos_fisk_doks primary key garant postoji';
END;
$$;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos (
    dok_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
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
    ukupno numeric(15,5),
    brFaktP varchar(10),
    opis varchar(100),
    dat_od date,
    dat_do date,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);

comment on column {{ item_prodavnica }}.pos.ref_fisk_dok is 'za 42 referenca na pos_fisk_doks.dok_id';
comment on column {{ item_prodavnica }}.pos.ref is 'za 72 referenca na pos dokument 29-start nivelacija';
comment on column {{ item_prodavnica }}.pos.ref_2 is 'za 72 referenca na pos dokument 29-end nivelacija';

ALTER TABLE {{ item_prodavnica }}.pos OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos TO xtrole;

CREATE INDEX IF NOT EXISTS pos_id1 ON {{ item_prodavnica }}.pos USING btree (idpos, idvd, datum, brdok);
CREATE INDEX IF NOT EXISTS pos_id2 ON {{ item_prodavnica }}.pos USING btree (idvd, datum);
CREATE INDEX IF NOT EXISTS pos_id3 ON {{ item_prodavnica }}.pos USING btree (idPartner, datum);
CREATE INDEX IF NOT EXISTS pos_id6 ON {{ item_prodavnica }}.pos USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_dok_id ON {{ item_prodavnica }}.pos USING btree( dok_id );
CREATE INDEX IF NOT EXISTS pos_ref_fisk_dok ON {{ item_prodavnica }}.pos USING btree( ref_fisk_dok );

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_items (
    item_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
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
ALTER TABLE {{ item_prodavnica }}.pos_items OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_items TO xtrole;
CREATE INDEX IF NOT EXISTS pos_items_id1 ON {{ item_prodavnica }}.pos_items USING btree (idpos, idvd, datum, brdok, idroba);
CREATE INDEX IF NOT EXISTS pos_items_id2 ON {{ item_prodavnica }}.pos_items USING btree (idroba, datum);
CREATE INDEX IF NOT EXISTS pos_items_id4 ON {{ item_prodavnica }}.pos_items USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_items_id5 ON {{ item_prodavnica }}.pos_items USING btree (idpos, idroba, datum);
CREATE INDEX IF NOT EXISTS pos_items_id6 ON {{ item_prodavnica }}.pos_items USING btree (idroba);
CREATE UNIQUE INDEX IF NOT EXISTS pos_items_rbr ON {{ item_prodavnica }}.pos_items USING btree (idpos, idvd, brdok, datum, rbr);

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.roba (
    roba_id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
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
ALTER TABLE {{ item_prodavnica }}.roba OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.roba TO xtrole;

CREATE TABLE IF NOT EXISTS  {{ item_prodavnica }}.pos_kase (
    id character varying(2),
    naz character varying(15),
    ppath character varying(50)
);
ALTER TABLE {{ item_prodavnica }}.pos_kase OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_osob (
    id character varying(4),
    korsif character varying(6),
    naz character varying(40),
    status character(2)
);
ALTER TABLE {{ item_prodavnica }}.pos_osob OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_strad (
    id character varying(2),
    naz character varying(15),
    prioritet character(1)
);
ALTER TABLE {{ item_prodavnica }}.pos_strad OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.vrstep (
    id character(2),
    naz character(20)
);
ALTER TABLE {{ item_prodavnica }}.vrstep OWNER TO admin;

GRANT ALL ON SCHEMA {{ item_prodavnica }} TO xtrole;
GRANT ALL ON TABLE {{ item_prodavnica }}.roba TO xtrole;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_strad TO xtrole;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_osob TO xtrole;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_kase TO xtrole;
GRANT ALL ON TABLE {{ item_prodavnica }}.vrstep TO xtrole;

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.metric
(
    metric_id integer,
    metric_name text COLLATE pg_catalog."default",
    metric_value text COLLATE pg_catalog."default",
    metric_module text COLLATE pg_catalog."default"
);

CREATE SEQUENCE IF NOT EXISTS {{ item_prodavnica }}.metric_metric_id_seq;
ALTER SEQUENCE {{ item_prodavnica }}.metric_metric_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE {{ item_prodavnica }}.metric_metric_id_seq TO admin;
GRANT ALL ON SEQUENCE {{ item_prodavnica }}.metric_metric_id_seq TO xtrole;
ALTER TABLE {{ item_prodavnica }}.metric OWNER to admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.metric TO xtrole;

delete from {{ item_prodavnica }}.metric where metric_id IS null;
ALTER TABLE {{ item_prodavnica }}.metric ALTER COLUMN metric_id SET NOT NULL;
ALTER TABLE {{ item_prodavnica }}.metric ALTER COLUMN metric_id SET DEFAULT nextval(('{{ item_prodavnica }}.metric_metric_id_seq'::text)::regclass);

-- select setval('{{ item_prodavnica }}.metric_metric_id_seq'::text, 2);
-- select currval('{{ item_prodavnica }}.metric_metric_id_seq'::text);

ALTER TABLE {{ item_prodavnica }}.metric  DROP CONSTRAINT IF EXISTS metric_id_unique;
ALTER TABLE {{ item_prodavnica }}.metric  ADD CONSTRAINT metric_id_unique UNIQUE (metric_id);

CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_fisk_doks (
    dok_id uuid NOT NULL DEFAULT gen_random_uuid(),
    ref_pos_dok uuid,
    broj_rn integer,
    ref_storno_fisk_dok uuid,
    partner_id uuid,
    ukupno real,
    popust real,
    obradjeno timestamp with time zone DEFAULT now(),
    korisnik text DEFAULT current_user
);
ALTER TABLE {{ item_prodavnica }}.pos_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_fisk_doks TO xtrole;

-- https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
CREATE UNIQUE INDEX IF NOT EXISTS pos_fisk_doks_broj_rn ON {{ item_prodavnica }}.pos_fisk_doks (broj_rn)
    WHERE broj_rn IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ref_storno_fisk_dok ON {{ item_prodavnica }}.pos_fisk_doks (ref_storno_fisk_dok)
        WHERE ref_storno_fisk_dok IS NOT NULL;


-- test

-- step 1
-- insert into public.kalk_doks(idfirma, idvd, brdok, datdok, brfaktP, pkonto) values('10', '11', 'BRDOK01', current_date, 'FAKTP01', '13322');
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 1, '13322', 'R01', 10,  2);
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 2, '13322', 'R02', 20,  3);

-- step 2
-- select * from {{ item_prodavnica }}.pos_doks_knjig;
-- step 3
-- select * from {{ item_prodavnica }}.pos_pos_knjig;

-- step 4
-- delete from public.kalk_kalk where brdok='BRDOK01';
-- delete from public.kalk_doks where brdok='BRDOK01';

-- step 5
-- select * from {{ item_prodavnica }}.pos_doks_knjig;
-- step 6
-- select * from {{ item_prodavnica }}.pos_pos_knjig;



-- test pos->knjig

-- step 1
-- delete from {{ item_prodavnica }}.pos_doks where brdok='BRDOK01' and idvd='42';
-- insert into {{ item_prodavnica }}.pos_doks(idpos, idvd, brdok, datum) values('15', '42', 'BRDOK01', current_date);
-- insert into {{ item_prodavnica }}.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '42', 'BRDOK01', current_date, '  1', 'R01', 5, 2.5, 0, 'PDV17');

-- step 3
-- select * from {{ item_prodavnica }}.pos_doks where datum=current_date and idvd='42';

-- step 4
-- select * from f18.kalk_doks where brdok=TO_CHAR(current_date, 'ddmm/15') and idvd='42';

-- delete from {{ item_prodavnica }}.pos_pos where brdok='BRDOK01';

-- insert into {{ item_prodavnica }}.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '89', '       4', current_date, '  1', 'R01', 5, 2.5, 0.5, 'PDV17');


-- TARIFE CLEANUP --


CREATE TABLE IF NOT EXISTS {{ item_prodavnica }}.pos_stanje (
   id SERIAL,
   dat_od date,
   dat_do date,
   idroba varchar(10),
   roba_id uuid,
   ulazi text[],
   izlazi text[],
   kol_ulaz numeric(18,3),
   kol_izlaz numeric(18,3),
   cijena numeric(10,3),
   ncijena numeric(10,3)
);
ALTER TABLE {{ item_prodavnica }}.pos_stanje OWNER TO admin;
GRANT ALL ON TABLE {{ item_prodavnica }}.pos_stanje TO xtrole;
GRANT ALL ON SEQUENCE {{ item_prodavnica }}.pos_stanje_id_seq TO xtrole;

ALTER TABLE {{ item_prodavnica }}.pos_stanje ALTER COLUMN dat_od SET NOT NULL;
ALTER TABLE {{ item_prodavnica }}.pos_items ALTER COLUMN idroba SET NOT NULL;
ALTER TABLE {{ item_prodavnica }}.pos_items ALTER COLUMN cijena SET NOT NULL;

CREATE INDEX IF NOT EXISTS pos_stanje_idroba ON {{ item_prodavnica }}.pos_stanje USING btree (idroba, cijena, ncijena);


DO $$
BEGIN
   ALTER TABLE {{ item_prodavnica }}.pos_stanje ADD PRIMARY KEY (id);
EXCEPTION WHEN OTHERS THEN
   RAISE INFO 'pos_stanje primary key garant postoji';
END;
$$;
