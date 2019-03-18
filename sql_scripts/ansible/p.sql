CREATE SCHEMA IF NOT EXISTS {{ ansible_nodename }};
ALTER SCHEMA {{ ansible_nodename }} OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos_fisk_doks (
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
ALTER TABLE {{ ansible_nodename }}.pos_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_fisk_doks TO xtrole;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos (
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

comment on column {{ ansible_nodename }}.pos.ref_fisk_dok is 'za 42 referenca na pos_fisk_doks.dok_id';
comment on column {{ ansible_nodename }}.pos.ref is 'za 72 referenca na pos dokument 29-start nivelacija';
comment on column {{ ansible_nodename }}.pos.ref_2 is 'za 72 referenca na pos dokument 29-end nivelacija';

ALTER TABLE {{ ansible_nodename }}.pos OWNER TO admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos TO xtrole;

CREATE INDEX IF NOT EXISTS pos_id1 ON {{ ansible_nodename }}.pos USING btree (idpos, idvd, datum, brdok);
CREATE INDEX IF NOT EXISTS pos_id2 ON {{ ansible_nodename }}.pos USING btree (idvd, datum);
CREATE INDEX IF NOT EXISTS pos_id3 ON {{ ansible_nodename }}.pos USING btree (idPartner, datum);
CREATE INDEX IF NOT EXISTS pos_id6 ON {{ ansible_nodename }}.pos USING btree (datum);
CREATE INDEX IF NOT EXISTS pos_dok_id ON {{ ansible_nodename }}.pos USING btree( dok_id );
CREATE INDEX IF NOT EXISTS pos_ref_fisk_dok ON {{ ansible_nodename }}.pos USING btree( ref_fisk_dok );

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
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
ALTER TABLE {{ ansible_nodename }}.pos_items OWNER TO admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_items TO xtrole;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.roba (
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
ALTER TABLE {{ ansible_nodename }}.roba OWNER TO admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.roba TO xtrole;

CREATE TABLE IF NOT EXISTS  {{ ansible_nodename }}.pos_kase (
    id character varying(2),
    naz character varying(15),
    ppath character varying(50)
);
ALTER TABLE {{ ansible_nodename }}.pos_kase OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos_osob (
    id character varying(4),
    korsif character varying(6),
    naz character varying(40),
    status character(2)
);
ALTER TABLE {{ ansible_nodename }}.pos_osob OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos_strad (
    id character varying(2),
    naz character varying(15),
    prioritet character(1)
);
ALTER TABLE {{ ansible_nodename }}.pos_strad OWNER TO admin;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.vrstep (
    id character(2),
    naz character(20)
);
ALTER TABLE {{ ansible_nodename }}.vrstep OWNER TO admin;

GRANT ALL ON SCHEMA {{ ansible_nodename }} TO xtrole;
GRANT ALL ON TABLE {{ ansible_nodename }}.roba TO xtrole;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_strad TO xtrole;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_osob TO xtrole;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_kase TO xtrole;
GRANT ALL ON TABLE {{ ansible_nodename }}.vrstep TO xtrole;

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.metric
(
    metric_id integer,
    metric_name text COLLATE pg_catalog."default",
    metric_value text COLLATE pg_catalog."default",
    metric_module text COLLATE pg_catalog."default"
);

CREATE SEQUENCE IF NOT EXISTS {{ ansible_nodename }}.metric_metric_id_seq;
ALTER SEQUENCE {{ ansible_nodename }}.metric_metric_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE {{ ansible_nodename }}.metric_metric_id_seq TO admin;
GRANT ALL ON SEQUENCE {{ ansible_nodename }}.metric_metric_id_seq TO xtrole;
ALTER TABLE {{ ansible_nodename }}.metric OWNER to admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.metric TO xtrole;

delete from {{ ansible_nodename }}.metric where metric_id IS null;
ALTER TABLE {{ ansible_nodename }}.metric ALTER COLUMN metric_id SET NOT NULL;
ALTER TABLE {{ ansible_nodename }}.metric ALTER COLUMN metric_id SET DEFAULT nextval(('{{ ansible_nodename }}.metric_metric_id_seq'::text)::regclass);

-- select setval('{{ ansible_nodename }}.metric_metric_id_seq'::text, 2);
-- select currval('{{ ansible_nodename }}.metric_metric_id_seq'::text);

ALTER TABLE {{ ansible_nodename }}.metric  DROP CONSTRAINT IF EXISTS metric_id_unique;
ALTER TABLE {{ ansible_nodename }}.metric  ADD CONSTRAINT metric_id_unique UNIQUE (metric_id);

CREATE TABLE IF NOT EXISTS {{ ansible_nodename }}.pos_fisk_doks (
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
ALTER TABLE {{ ansible_nodename }}.pos_fisk_doks OWNER TO admin;
GRANT ALL ON TABLE {{ ansible_nodename }}.pos_fisk_doks TO xtrole;

-- https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
CREATE UNIQUE INDEX IF NOT EXISTS pos_fisk_doks_broj_rn ON {{ ansible_nodename }}.pos_fisk_doks (broj_rn)
    WHERE broj_rn IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ref_storno_fisk_dok ON {{ ansible_nodename }}.pos_fisk_doks (ref_storno_fisk_dok)
        WHERE ref_storno_fisk_dok IS NOT NULL;


-- test

-- step 1
-- insert into public.kalk_doks(idfirma, idvd, brdok, datdok, brfaktP, pkonto) values('10', '11', 'BRDOK01', current_date, 'FAKTP01', '13322');
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 1, '13322', 'R01', 10,  2);
-- insert into public.kalk_kalk(idfirma, idvd, brdok, datdok, rbr, pkonto, idroba, mpcsapp, kolicina) values('10', '11', 'BRDOK01', current_date, 2, '13322', 'R02', 20,  3);

-- step 2
-- select * from {{ ansible_nodename }}.pos_doks_knjig;
-- step 3
-- select * from {{ ansible_nodename }}.pos_pos_knjig;

-- step 4
-- delete from public.kalk_kalk where brdok='BRDOK01';
-- delete from public.kalk_doks where brdok='BRDOK01';

-- step 5
-- select * from {{ ansible_nodename }}.pos_doks_knjig;
-- step 6
-- select * from {{ ansible_nodename }}.pos_pos_knjig;



-- test pos->knjig

-- step 1
-- delete from {{ ansible_nodename }}.pos_doks where brdok='BRDOK01' and idvd='42';
-- insert into {{ ansible_nodename }}.pos_doks(idpos, idvd, brdok, datum) values('15', '42', 'BRDOK01', current_date);
-- insert into {{ ansible_nodename }}.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '42', 'BRDOK01', current_date, '  1', 'R01', 5, 2.5, 0, 'PDV17');

-- step 3
-- select * from {{ ansible_nodename }}.pos_doks where datum=current_date and idvd='42';

-- step 4
-- select * from f18.kalk_doks where brdok=TO_CHAR(current_date, 'ddmm/15') and idvd='42';

-- delete from {{ ansible_nodename }}.pos_pos where brdok='BRDOK01';

-- insert into {{ ansible_nodename }}.pos_pos(idpos, idvd, brdok, datum, rbr, idroba, kolicina, cijena, ncijena, idtarifa)
--		values('15', '89', '       4', current_date, '  1', 'R01', 5, 2.5, 0.5, 'PDV17');


-- TARIFE CLEANUP --
