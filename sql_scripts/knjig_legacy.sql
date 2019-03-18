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
