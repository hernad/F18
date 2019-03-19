CREATE TABLE IF NOT EXISTS f18.kalk_kalk (
    dok_id uuid,
    item_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    idfirma character(2) NOT NULL,
    idroba character(10),
    idkonto character(7),
    idkonto2 character(7),
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    idpartner character(6),
    rbr integer NOT NULL,
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

CREATE TABLE IF NOT EXISTS f18.kalk_doks (
    dok_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    idfirma character(2) NOT NULL,
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    datfaktp date,
    idpartner character(6),
    pkonto character(7),
    mkonto character(7),
    nv numeric(12,2),
    vpv numeric(12,2),
    rabat numeric(12,2),
    mpv numeric(12,2),
    datval date,
    dat_od date,
    dat_do date,
    opis text,
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);

ALTER TABLE f18.kalk_doks OWNER TO admin;


CREATE INDEX IF NOT EXISTS kalk_kalk_datdok ON f18.kalk_kalk USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_kalk_id1 ON f18.kalk_kalk USING btree (idfirma, idvd, brdok, rbr, mkonto, pkonto);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto ON f18.kalk_kalk USING btree (idfirma, mkonto, idroba);
CREATE INDEX IF NOT EXISTS kalk_kalk_mkonto_roba ON f18.kalk_kalk USING btree (mkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto ON f18.kalk_kalk USING btree (idfirma, pkonto, idroba);
CREATE INDEX  IF NOT EXISTS kalk_kalk_pkonto_roba ON f18.kalk_kalk USING btree (pkonto, idroba);

CREATE INDEX IF NOT EXISTS kalk_doks_datdok ON f18.kalk_doks USING btree (datdok);
CREATE INDEX IF NOT EXISTS kalk_doks_id1 ON f18.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);

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
