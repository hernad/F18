-- v3 trazi
CREATE TABLE IF NOT EXISTS fmk.kalk_kalk_atributi (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character(8) NOT NULL,
    rbr character(3) NOT NULL,
    atribut character(50) NOT NULL,
    value character varying
);

ALTER TABLE fmk.kalk_kalk_atributi OWNER TO admin;
CREATE INDEX IF NOT EXISTS kalk_kalk_atributi_id1 ON fmk.kalk_kalk_atributi USING btree (idfirma, idtipdok, brdok, rbr, atribut);


-- v3 trazi
CREATE TABLE IF NOT EXISTS fmk.kalk_doks2 (
    idfirma character(2),
    idvd character(2),
    brdok character varying(12),
    datval date,
    opis character varying(20),
    k1 character(1),
    k2 character(2),
    k3 character(3)
);

ALTER TABLE fmk.kalk_doks2 OWNER TO admin;
CREATE INDEX IF NOT EXISTS kalk_doks2_id1 ON fmk.kalk_doks2 USING btree (idfirma, idvd, brdok);


CREATE TABLE IF NOT EXISTS fmk.pos_doks (
    idpos character varying(2) NOT NULL,
    idvd character varying(2) NOT NULL,
    brdok character varying(6) NOT NULL,
    datum date NOT NULL,
    idPartner character varying(8),
    idradnik character varying(4),
    idvrstep character(2),
    m1 character varying(1),
    placen character(1),
    prebacen character(1),
    smjena character varying(1),
    sto character varying(3),
    vrijeme character varying(5),
    c_1 character varying(6),
    c_2 character varying(10),
    c_3 character varying(50),
    fisc_rn numeric(10,0),
    zak_br numeric(6,0),
    sto_br numeric(3,0),
    funk numeric(3,0)
);


CREATE TABLE IF NOT EXISTS fmk.f18_rules (
    rule_id numeric(10,0),
    modul_name character(10),
    rule_obj character(30),
    rule_no numeric(5,0),
    rule_name character(100),
    rule_ermsg character(200),
    rule_level numeric(2,0),
    rule_c1 character(1),
    rule_c2 character(5),
    rule_c3 character(10),
    rule_c4 character(10),
    rule_c5 character(50),
    rule_c6 character(50),
    rule_c7 character(100),
    rule_n1 numeric(15,5),
    rule_n2 numeric(15,5),
    rule_n3 numeric(15,5),
    rule_d1 date,
    rule_d2 date
);

ALTER TABLE fmk.f18_rules OWNER TO admin;

CREATE TABLE IF NOT EXISTS fmk.ks (
    id character(3),
    naz character(10),
    datod date,
    datdo date,
    strev numeric(8,4),
    stkam numeric(8,4),
    den numeric(15,6),
    tip character(1),
    duz numeric(4,0)
);

ALTER TABLE fmk.ks OWNER TO admin;


CREATE TABLE IF NOT EXISTS fmk.trfp2 (
    id character(60),
    match_code character(10),
    shema character(1),
    naz character(20),
    idkonto character(7),
    dokument character(1),
    partner character(1),
    d_p character(1),
    znak character(1),
    idvd character(2),
    idvn character(2),
    idtarifa character(6)
);
ALTER TABLE fmk.trfp2 OWNER TO admin;

CREATE TABLE IF NOT EXISTS public.schema_migrations
(
    version integer NOT NULL,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY (version)
);

ALTER TABLE public.schema_migrations OWNER to admin;

GRANT ALL ON TABLE public.schema_migrations TO admin;
GRANT SELECT ON TABLE public.schema_migrations TO xtrole;

CREATE TABLE fmk.refer (
    id character(10),
    match_code character(10),
    idops character(4),
    naz character(40)
);
ALTER TABLE fmk.refer OWNER TO admin;
CREATE INDEX refer_id1 ON fmk.refer USING btree (id);
