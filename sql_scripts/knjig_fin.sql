CREATE SCHEMA IF NOT EXISTS fmk;
ALTER SCHEMA fmk OWNER TO admin;


CREATE TABLE IF NOT EXISTS fmk.fin_suban
(
    idfirma character varying(2) COLLATE pg_catalog."default" NOT NULL,
    idvn character varying(2) COLLATE pg_catalog."default" NOT NULL,
    brnal character varying(8) COLLATE pg_catalog."default" NOT NULL,
    idkonto character varying(10) COLLATE pg_catalog."default",
    idpartner character varying(6) COLLATE pg_catalog."default",
    rbr integer NOT NULL,
    idtipdok character(2) COLLATE pg_catalog."default",
    brdok character varying(20) COLLATE pg_catalog."default",
    datdok date,
    datval date,
    otvst character(1) COLLATE pg_catalog."default",
    d_p character(1) COLLATE pg_catalog."default",
    iznosbhd numeric(17,2),
    iznosdem numeric(15,2),
    opis character varying(500) COLLATE pg_catalog."default",
    k1 character(1) COLLATE pg_catalog."default",
    k2 character(1) COLLATE pg_catalog."default",
    k3 character(2) COLLATE pg_catalog."default",
    k4 character(2) COLLATE pg_catalog."default",
    m1 character(1) COLLATE pg_catalog."default",
    m2 character(1) COLLATE pg_catalog."default",
    idrj character(6) COLLATE pg_catalog."default",
    funk character(5) COLLATE pg_catalog."default",
    fond character(4) COLLATE pg_catalog."default",
    CONSTRAINT fin_suban_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr)
);


ALTER TABLE fmk.fin_suban OWNER to admin;
GRANT ALL ON TABLE fmk.fin_suban TO admin;
GRANT ALL ON TABLE fmk.fin_suban TO xtrole;


CREATE INDEX IF NOT EXISTS fin_suban_brnal
    ON fmk.fin_suban USING btree
    (idfirma COLLATE pg_catalog."default", idvn COLLATE pg_catalog."default", brnal COLLATE pg_catalog."default", rbr)
    TABLESPACE pg_default;

CREATE INDEX fin_suban_datdok
    ON fmk.fin_suban USING btree
    (datdok)
    TABLESPACE pg_default;


CREATE INDEX IF NOT EXISTS fin_suban_datval_datdok
    ON fmk.fin_suban USING btree
    (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", COALESCE(datval, datdok), brdok COLLATE pg_catalog."default")
    TABLESPACE pg_default;


CREATE INDEX IF NOT EXISTS fin_suban_id1
    ON fmk.fin_suban USING btree
    (idfirma COLLATE pg_catalog."default", idvn COLLATE pg_catalog."default", brnal COLLATE pg_catalog."default", rbr)
    TABLESPACE pg_default;


CREATE INDEX IF NOT EXISTS fin_suban_konto_partner
    ON fmk.fin_suban USING btree
    (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", datdok)
    TABLESPACE pg_default;


CREATE INDEX IF NOT EXISTS  fin_suban_konto_partner_brdok
    ON fmk.fin_suban USING btree
    (idfirma COLLATE pg_catalog."default", idkonto COLLATE pg_catalog."default", idpartner COLLATE pg_catalog."default", brdok COLLATE pg_catalog."default", datdok)
    TABLESPACE pg_default;


CREATE INDEX IF NOT EXISTS fin_suban_otvrst
    ON fmk.fin_suban USING btree
    (btrim(idkonto::text) COLLATE pg_catalog."default", btrim(idpartner::text) COLLATE pg_catalog."default", btrim(brdok::text) COLLATE pg_catalog."default")
    TABLESPACE pg_default;


CREATE TRIGGER IF NOT EXISTS suban_insert_upate_delete
    AFTER INSERT OR DELETE OR UPDATE 
    ON fmk.fin_suban
    FOR EACH ROW
    EXECUTE PROCEDURE public.on_suban_insert_update_delete();


CREATE TABLE IF NOT EXISTS fmk.fin_sint
(
    idfirma character(2) COLLATE pg_catalog."default" NOT NULL,
    idkonto character(3) COLLATE pg_catalog."default",
    idvn character(2) COLLATE pg_catalog."default" NOT NULL,
    brnal character(8) COLLATE pg_catalog."default" NOT NULL,
    rbr character varying(4) COLLATE pg_catalog."default" NOT NULL,
    datnal date,
    dugbhd numeric(17,2),
    potbhd numeric(17,2),
    dugdem numeric(15,2),
    potdem numeric(15,2)
);


ALTER TABLE fmk.fin_sint OWNER to admin;
GRANT ALL ON TABLE fmk.fin_sint TO admin;
GRANT ALL ON TABLE fmk.fin_sint TO xtrole;

CREATE INDEX IF NOT EXISTS fin_sint_id1
    ON fmk.fin_sint USING btree
    (idfirma COLLATE pg_catalog."default", idvn COLLATE pg_catalog."default", brnal COLLATE pg_catalog."default", rbr COLLATE pg_catalog."default")
    TABLESPACE pg_default;




CREATE TABLE IF NOT EXISTS fmk.fin_anal (
    idfirma character(2) NOT NULL,
    idkonto character(7),
    idvn character(2) NOT NULL,
    brnal character varying(12) NOT NULL,
    rbr character varying(4) NOT NULL,
    datnal date,
    dugbhd numeric(17,2),
    potbhd numeric(17,2),
    dugdem numeric(15,2),
    potdem numeric(15,2)
);

ALTER TABLE fmk.fin_anal OWNER TO admin;
GRANT ALL ON TABLE fmk.fin_anal TO xtrole;



-- CREATE TABLE fmk.fin_fin_atributi (
--     idfirma character(2) NOT NULL,
--     idtipdok character(2) NOT NULL,
--     brdok character(8) NOT NULL,
--     rbr character(3) NOT NULL,
--     atribut character(50) NOT NULL,
--     value character varying
-- );
-- 
-- ALTER TABLE fmk.fin_fin_atributi OWNER TO admin;



CREATE TABLE IF NOT EXISTS fmk.fin_fond (
    id character(4),
    naz character varying(35)
);

ALTER TABLE fmk.fin_fond OWNER TO admin;
CREATE TABLE IF NOT EXISTS fmk.fin_funk (
    id character(5),
    naz character varying(35)
);

ALTER TABLE fmk.fin_funk OWNER TO admin;


-- CREATE TABLE fmk.fin_izvje (
--     id character(2) NOT NULL,
--     naz character(50),
--     uslov character(80),
--     kpolje character(50),
--     imekp character(10),
--     ksif character(50),
--     kbaza character(50),
--     kindeks character(80),
--     tiptab character(1)
-- );
-- 
-- ALTER TABLE fmk.fin_izvje OWNER TO admin;


-- CREATE TABLE fmk.fin_koliz (
--     id character(2) NOT NULL,
--     naz character(20) NOT NULL,
--     rbr numeric(2,0) NOT NULL,
--     formula character(150),
--     tip character(2),
--     sirina numeric(3,0),
--     decimale numeric(1,0),
--     sumirati character(1),
--     k1 character(1),
--     k2 character(2),
--     n1 character(1),
--     n2 character(2),
--     kuslov character(100),
--     sizraz character(100)
-- );
-- ALTER TABLE fmk.fin_koliz OWNER TO admin;



CREATE TABLE fmk.fin_koniz (
    id character(20) NOT NULL,
    izv character(2) NOT NULL,
    id2 character(20) NOT NULL,
    opis character(57) NOT NULL,
    ri numeric(4,0),
    fi character(80),
    fi2 character(80),
    k character(2),
    k2 character(2),
    predzn numeric(2,0),
    predzn2 numeric(2,0),
    podvuci character(1),
    k1 character(1),
    u1 character(3)
);

ALTER TABLE fmk.fin_koniz OWNER TO admin;



CREATE TABLE IF NOT EXISTS fmk.fin_nalog (
    idfirma character(2) NOT NULL,
    idvn character(2) NOT NULL,
    brnal character varying(12) NOT NULL,
    datnal date,
    dugbhd numeric(17,2),
    potbhd numeric(17,2),
    dugdem numeric(15,2),
    potdem numeric(15,2),
    sifra character(6),
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);
ALTER TABLE fmk.fin_nalog OWNER TO admin;
GRANT ALL ON TABLE fmk.fin_nalog TO xtrole;




