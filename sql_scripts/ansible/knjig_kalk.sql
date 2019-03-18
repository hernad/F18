



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



CREATE TABLE f18.kalk_kalk (
    idfirma character(2) NOT NULL,
    idroba character(10),
    idkonto character(7),
    idkonto2 character(7),
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    idpartner character(6),
    rbr character(3) NOT NULL,
    kolicina numeric(12,3),
    gkolicina numeric(12,3),
    gkolicin2 numeric(12,3),
    fcj numeric(18,8),
    fcj2 numeric(18,8),
    trabat character(1),
    rabat numeric(18,8),
    tprevoz character(1),
    prevoz numeric(18,8),
    tprevoz2 character(1),
    prevoz2 numeric(18,8),
    tbanktr character(1),
    banktr numeric(18,8),
    tspedtr character(1),
    spedtr numeric(18,8),
    tcardaz character(1),
    cardaz numeric(18,8),
    tzavtr character(1),
    zavtr numeric(18,8),
    nc numeric(18,8),
    tmarza character(1),
    marza numeric(18,8),
    vpc numeric(18,8),
    rabatv numeric(18,8),
    tmarza2 character(1),
    marza2 numeric(18,8),
    mpc numeric(18,8),
    idtarifa character(6),
    mpcsapp numeric(18,8),
    mkonto character(7),
    pkonto character(7),
    mu_i character(1),
    pu_i character(1),
    error character(1)
);

ALTER TABLE f18.kalk_kalk OWNER TO admin;

ALTER TABLE ONLY f18.kalk_kalk
    ADD CONSTRAINT kalk_kalk_pkey PRIMARY KEY (idfirma, idvd, brdok, rbr);


CREATE TABLE f18.kalk_doks (
    idfirma character(2) NOT NULL,
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    idpartner character(6),
    pkonto character(7),
    mkonto character(7),
    nv numeric(12,2),
    vpv numeric(12,2),
    rabat numeric(12,2),
    mpv numeric(12,2),
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);

ALTER TABLE f18.kalk_doks OWNER TO admin;


CREATE INDEX IF NOT EXISTS kalk_doks_datdok ON f18.kalk_doks USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_doks_id1 ON f18.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);


ALTER TABLE ONLY f18.kalk_doks
    ADD CONSTRAINT kalk_doks_pkey PRIMARY KEY (idfirma, idvd, brdok);


CREATE TABLE IF NOT EXISTS fmk.sast (
    id character(10),
    match_code character(10),
    r_br numeric(4,0),
    id2 character(10),
    kolicina numeric(20,5),
    k1 character(1),
    k2 character(1),
    n1 numeric(20,5),
    n2 numeric(20,5)
);

ALTER TABLE fmk.sast OWNER TO admin;