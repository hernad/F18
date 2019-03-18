
CREATE TABLE IF NOT EXISTS fmk.adres (
    id character varying(50),
    rj character varying(30),
    kontakt character varying(30),
    naz character varying(15),
    tel2 character varying(15),
    tel3 character varying(15),
    mjesto character varying(15),
    ptt character(6),
    adresa character varying(50),
    drzava character varying(22),
    ziror character varying(30),
    zirod character varying(30),
    k7 character(1),
    k8 character(2),
    k9 character(3)
);

ALTER TABLE fmk.adres OWNER TO admin;
GRANT ALL ON TABLE fmk.adres TO xtrole;

CREATE TABLE IF NOT EXISTS fmk.banke
(
    id character(3) COLLATE pg_catalog."default",
    match_code character(10) COLLATE pg_catalog."default",
    naz character(45) COLLATE pg_catalog."default",
    mjesto character(30) COLLATE pg_catalog."default",
    adresa character(30) COLLATE pg_catalog."default"
);

ALTER TABLE fmk.banke OWNER to admin;
GRANT ALL ON TABLE fmk.banke TO admin;
GRANT ALL ON TABLE fmk.banke TO xtrole;

CREATE INDEX IF NOT EXISTS banke_id1
    ON fmk.banke USING btree
    (id COLLATE pg_catalog."default");


CREATE TABLE IF NOT EXISTS fmk.dest (
    id character(6),
    idpartner character(6),
    naziv character(60),
    naziv2 character(60),
    mjesto character(20),
    adresa character(40),
    ptt character(10),
    telefon character(20),
    mobitel character(20),
    fax character(20)
);

ALTER TABLE fmk.dest OWNER TO admin;
GRANT ALL ON TABLE fmk.dest TO xtrole;


CREATE TABLE IF NOT EXISTS  fmk.dopr (
    id character(2),
    match_code character(10),
    naz character(20),
    iznos numeric(5,2),
    idkbenef character(1),
    dlimit numeric(12,2),
    poopst character(1),
    dop_tip character(1),
    tiprada character(1)
);

ALTER TABLE fmk.dopr OWNER TO admin;
GRANT ALL ON TABLE fmk.dopr TO xtrole;



CREATE TABLE f18.koncij (
    koncij_id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    id character(7),
    match_code character(10),
    shema character(1),
    naz character(2),
    idprodmjes character(2),
    region character(2),
    sufiks character(3),
    kk1 character(7),
    kk2 character(7),
    kk3 character(7),
    kk4 character(7),
    kk5 character(7),
    kk6 character(7),
    kk7 character(7),
    kk8 character(7),
    kk9 character(7),
    kp1 character(7),
    kp2 character(7),
    kp3 character(7),
    kp4 character(7),
    kp5 character(7),
    kp6 character(7),
    kp7 character(7),
    kp8 character(7),
    kp9 character(7),
    kpa character(7),
    kpb character(7),
    kpc character(7),
    kpd character(7),
    ko1 character(7),
    ko2 character(7),
    ko3 character(7),
    ko4 character(7),
    ko5 character(7),
    ko6 character(7),
    ko7 character(7),
    ko8 character(7),
    ko9 character(7),
    koa character(7),
    kob character(7),
    koc character(7),
    kod character(7)
);

ALTER TABLE f18.koncij OWNER TO admin;


CREATE TABLE f18.konto (
    konto_id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    id character(7) NOT NULL,
    naz character(57)
);
ALTER TABLE f18.konto OWNER TO admin;


CREATE SEQUENCE f18.log_id_seq;
ALTER SEQUENCE f18.log_id_seq OWNER TO admin;
GRANT ALL ON SEQUENCE f18.log_id_seq TO admin;
GRANT ALL ON SEQUENCE f18.log_id_seq TO xtrole;

CREATE TABLE IF NOT EXISTS f18.log
(
    id bigint NOT NULL DEFAULT nextval('f18.log_id_seq'::regclass),
    user_code character varying(20) COLLATE pg_catalog."default" NOT NULL,
    l_time timestamp without time zone DEFAULT now(),
    msg text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT log_pkey PRIMARY KEY (id)
);

ALTER TABLE f18.log OWNER to admin;
GRANT ALL ON TABLE f18.log TO admin;
GRANT ALL ON TABLE f18.log TO xtrole;

CREATE INDEX IF NOT EXISTS log_l_time_idx
    ON f18.log USING btree(l_time);

CREATE INDEX IF NOT EXISTS log_user_code_idx
    ON f18.log USING btree(user_code COLLATE pg_catalog."default");



CREATE TABLE IF NOT EXISTS fmk.ops (
    id character(4),
    idj character(3),
    idn0 character(1),
    idkan character(2),
    naz character(20),
    zipcode character(5),
    puccanton character(2),
    puccity character(5),
    reg character(1)
);

ALTER TABLE fmk.ops OWNER TO admin;



CREATE TABLE IF NOT EXISTS fmk.rj (
    id character(7) NOT NULL,
    naz character(100),
    tip character(2),
    konto character(7)
);



CREATE TABLE IF NOT EXISTS fmk.pkonto (
    id character(7),
    tip character(1)
);
ALTER TABLE fmk.pkonto OWNER TO admin;


CREATE TABLE IF NOT EXISTS f18.roba (
    roba_id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    id character(10) NOT NULL,
    sifradob character(20),
    naz character varying(250),
    jmj character(3),
    idtarifa character(6),
    nc numeric(18,8),
    vpc numeric(18,8),
    mpc numeric(18,8),
    tip character(1),
    carina numeric(5,2),
    opis text,
    vpc2 numeric(18,8),
    mpc2 numeric(18,8),
    mpc3 numeric(18,8),
    k1 character(4),
    k2 character(4),
    n1 numeric(12,2),
    n2 numeric(12,2),
    plc numeric(18,8),
    mink numeric(12,2),
    _m1_ character(1),
    barkod character(13),
    zanivel numeric(18,8),
    zaniv2 numeric(18,8),
    trosk1 numeric(15,5),
    trosk2 numeric(15,5),
    trosk3 numeric(15,5),
    trosk4 numeric(15,5),
    trosk5 numeric(15,5),
    fisc_plu numeric(10,0),
    k7 character(4),
    k8 character(4),
    k9 character(4),
    strings numeric(10,0),
    idkonto character(7),
    mpc4 numeric(18,8),
    mpc5 numeric(18,8),
    mpc6 numeric(18,8),
    mpc7 numeric(18,8),
    mpc8 numeric(18,8),
    mpc9 numeric(18,8)
);

ALTER TABLE f18.roba OWNER TO admin;


CREATE TABLE IF NOT EXISTS public.schema_migrations
(
    version integer NOT NULL,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY (version)
);

ALTER TABLE public.schema_migrations OWNER to admin;

GRANT ALL ON TABLE public.schema_migrations TO admin;
GRANT SELECT ON TABLE public.schema_migrations TO xtrole;




CREATE TABLE IF NOT EXISTS f18.partn
(
    partner_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    id character(6) COLLATE pg_catalog."default",
    naz character(250) COLLATE pg_catalog."default",
    naz2 character(250) COLLATE pg_catalog."default",
    ptt character(5) COLLATE pg_catalog."default",
    mjesto character(16) COLLATE pg_catalog."default",
    adresa character(24) COLLATE pg_catalog."default",
    ziror character(22) COLLATE pg_catalog."default",
    rejon character(4) COLLATE pg_catalog."default",
    telefon character(12) COLLATE pg_catalog."default",
    dziror character(22) COLLATE pg_catalog."default",
    fax character(12) COLLATE pg_catalog."default",
    mobtel character(20) COLLATE pg_catalog."default",
    idops character(4) COLLATE pg_catalog."default",
    _kup character(1) COLLATE pg_catalog."default",
    _dob character(1) COLLATE pg_catalog."default",
    _banka character(1) COLLATE pg_catalog."default",
    _radnik character(1) COLLATE pg_catalog."default",
    idrefer character(10) COLLATE pg_catalog."default"

);
ALTER TABLE f18.partn OWNER to admin;
GRANT ALL ON TABLE f18.partn TO xtrole;


CREATE TABLE IF NOT EXISTS f18.valute
(
    valuta_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    id character(4) COLLATE pg_catalog."default",
    naz character(30) COLLATE pg_catalog."default",
    naz2 character(4) COLLATE pg_catalog."default",
    datum date,
    kurs1 numeric(18,8),
    kurs2 numeric(18,8),
    kurs3 numeric(18,8),
    tip character(1) COLLATE pg_catalog."default"
);

ALTER TABLE f18.valute OWNER to admin;
GRANT ALL ON TABLE f18.valute TO admin;
GRANT ALL ON TABLE f18.valute TO xtrole;

