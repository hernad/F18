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
