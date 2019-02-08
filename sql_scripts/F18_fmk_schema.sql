
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fmk; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA fmk;
ALTER SCHEMA fmk OWNER TO admin;

--
-- Name: SCHEMA fmk; Type: COMMENT; Schema: -; Owner: admin
--

COMMENT ON SCHEMA fmk IS 'fmk/F18';


--
-- Name: fetchbrojac(text); Type: FUNCTION; Schema: fmk; Owner: admin
--

CREATE FUNCTION fmk.fetchbrojac(text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
  _pBrojacName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT brojac_value::TEXT INTO _returnVal
    FROM brojac
   WHERE brojac_name = _pBrojacName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$_$;


ALTER FUNCTION fmk.fetchbrojac(text) OWNER TO admin;

--
-- Name: fetchmetrictext(text); Type: FUNCTION; Schema: fmk; Owner: admin
--

CREATE FUNCTION fmk.fetchmetrictext(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _pMetricName ALIAS FOR $1;
  _returnVal TEXT;
BEGIN
  SELECT metric_value::TEXT INTO _returnVal
    FROM fmk.metric WHERE metric_name = _pMetricName;

  IF (FOUND) THEN
     RETURN _returnVal;
  ELSE
     RETURN '!!notfound!!';
  END IF;

END;
$_$;


ALTER FUNCTION fmk.fetchmetrictext(text) OWNER TO admin;

--
-- Name: primary_keys_on_off(); Type: FUNCTION; Schema: fmk; Owner: xtrole
--

CREATE FUNCTION fmk.primary_keys_on_off() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE existsPK INTEGER;

BEGIN

IF exists(select 1 from pg_constraint where conname = 'fakt_fakt_pkey') THEN
  perform fmk.setmetric( 'primary_keys', '1' );
  existsPK = 1;
ELSE
  perform fmk.setmetric( 'primary_keys', '0' );
  existsPK = 0;
END IF;

return existsPK;

END;

$$;


ALTER FUNCTION fmk.primary_keys_on_off() OWNER TO xtrole;

--
-- Name: setbrojac(text, text); Type: FUNCTION; Schema: fmk; Owner: admin
--

CREATE FUNCTION fmk.setbrojac(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
  pBrojacName ALIAS FOR $1;
  pBrojacValue ALIAS FOR $2;
  _brojacid INTEGER;

BEGIN

  IF (pBrojacValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM brojac
     WHERE (brojac_name=pBrojacName);
     RETURN TRUE;
  END IF;

  SELECT brojac_id INTO _brojacid
  FROM brojac
  WHERE (brojac_name=pBrojacName);

  IF (FOUND) THEN
    UPDATE brojac
    SET brojac_value=pBrojacValue
    WHERE (brojac_id=_brojacid);

  ELSE
    INSERT INTO brojac
    (brojac_name, brojac_value)
    VALUES (pBrojacName, pBrojacValue);
  END IF;

  RETURN TRUE;

END;
$_$;


ALTER FUNCTION fmk.setbrojac(text, text) OWNER TO admin;

--
-- Name: setmetric(text, text); Type: FUNCTION; Schema: fmk; Owner: admin
--

CREATE FUNCTION fmk.setmetric(text, text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
  pMetricName ALIAS FOR $1;
  pMetricValue ALIAS FOR $2;
  _metricid INTEGER;

BEGIN

  IF (pMetricValue = '!!UNSET!!'::TEXT) THEN
     DELETE FROM fmk.metric WHERE (metric_name=pMetricName);
     RETURN TRUE;
  END IF;

  SELECT metric_id INTO _metricid FROM fmk.metric WHERE (metric_name=pMetricName);

  IF (FOUND) THEN
    UPDATE fmk.metric SET metric_value=pMetricValue WHERE (metric_id=_metricid);
  ELSE
    INSERT INTO fmk.metric(metric_name, metric_value)  VALUES (pMetricName, pMetricValue);
  END IF;

  RETURN TRUE;

END;
$_$;


ALTER FUNCTION fmk.setmetric(text, text) OWNER TO admin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: adres; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.adres (
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

--
-- Name: banke; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.banke (
    id character(3),
    match_code character(10),
    naz character(45),
    mjesto character(30),
    adresa character(30)
);

ALTER TABLE fmk.banke OWNER TO admin;

--
-- Name: brojac_brojac_id_seq; Type: SEQUENCE; Schema: fmk; Owner: admin
--

CREATE SEQUENCE fmk.brojac_brojac_id_seq
    START WITH 445
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;

ALTER TABLE fmk.brojac_brojac_id_seq OWNER TO admin;

--
-- Name: dest; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.dest (
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

--
-- Name: dopr; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.dopr (
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

--
-- Name: epdv_kif; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.epdv_kif (
    datum date,
    datum_2 date,
    src character(1),
    td_src character(2),
    src_2 character(1),
    id_tar character(6),
    id_part character(6),
    part_idbr character(13),
    part_kat character(1),
    part_kat_2 character(13),
    src_pm character(6),
    src_td character(12),
    src_br character(12),
    src_veza_b character(12),
    src_br_2 character(12),
    r_br numeric(6,0),
    br_dok numeric(6,0),
    g_r_br numeric(8,0),
    lock character(1),
    kat character(1),
    kat_2 character(1),
    opis character(160),
    i_b_pdv numeric(16,2),
    i_pdv numeric(16,2),
    i_v_b_pdv numeric(16,2),
    i_v_pdv numeric(16,2),
    status character(1),
    kat_p character(1),
    kat_p_2 character(1),
    p_kat character(1),
    p_kat_2 character(1)
);

ALTER TABLE fmk.epdv_kif OWNER TO admin;

--
-- Name: epdv_kuf; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.epdv_kuf (
    datum date,
    datum_2 date,
    src character(1),
    td_src character(2),
    src_2 character(1),
    id_tar character(6),
    id_part character(6),
    part_idbr character(13),
    part_kat character(1),
    src_td character(12),
    src_br character(12),
    src_veza_b character(12),
    src_br_2 character(12),
    r_br numeric(6,0),
    br_dok numeric(6,0),
    g_r_br numeric(8,0),
    lock character(1),
    kat character(1),
    kat_2 character(1),
    opis character(160),
    i_b_pdv numeric(16,2),
    i_pdv numeric(16,2),
    i_v_b_pdv numeric(16,2),
    i_v_pdv numeric(16,2),
    status character(1),
    kat_p character(1),
    kat_p_2 character(1),
    p_kat character(1),
    p_kat_2 character(1)
);

ALTER TABLE fmk.epdv_kuf OWNER TO admin;

--
-- Name: epdv_pdv; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.epdv_pdv (
    datum_1 date,
    datum_2 date,
    datum_3 date,
    id_br character(12),
    per_od date,
    per_do date,
    po_naziv character(60),
    po_adresa character(60),
    po_ptt character(10),
    po_mjesto character(40),
    isp_opor numeric(18,2),
    isp_izv numeric(18,2),
    isp_neopor numeric(18,2),
    isp_nep_sv numeric(18,2),
    nab_opor numeric(18,2),
    nab_uvoz numeric(18,2),
    nab_ne_opo numeric(18,2),
    nab_st_sr numeric(18,2),
    i_pdv_r numeric(18,2),
    i_pdv_nr1 numeric(18,2),
    i_pdv_nr2 numeric(18,2),
    i_pdv_nr3 numeric(18,2),
    i_pdv_nr4 numeric(18,2),
    u_pdv_r numeric(18,2),
    u_pdv_uv numeric(18,2),
    u_pdv_pp numeric(18,2),
    i_pdv_uk numeric(18,2),
    u_pdv_uk numeric(18,2),
    pdv_uplati numeric(18,2),
    pdv_prepla numeric(18,2),
    pdv_povrat character(1),
    pot_mjesto character(40),
    pot_datum date,
    pot_ob character(80),
    lock character(1),
    i_opor numeric(18,2),
    i_u_pdv_41 numeric(18,2),
    i_u_pdv_43 numeric(18,2),
    i_izvoz numeric(18,2),
    i_neop numeric(18,2),
    u_nab_21 numeric(18,2),
    u_nab_23 numeric(18,2),
    u_uvoz numeric(18,2),
    u_pdv_41 numeric(18,2),
    u_pdv_43 numeric(18,2)
);

ALTER TABLE fmk.epdv_pdv OWNER TO admin;

--
-- Name: epdv_sg_kif; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.epdv_sg_kif (
    id character(4),
    match_code character(10),
    naz character(60),
    src character(1),
    s_path character(60),
    s_path_s character(60),
    form_b_pdv character(160),
    form_pdv character(160),
    id_tar character(160),
    id_kto character(160),
    razb_tar character(1),
    razb_kto character(1),
    razb_dan character(1),
    kat_part character(1),
    td_src character(2),
    kat_p character(1),
    kat_p_2 character(1),
    s_id_tar character(6),
    zaok numeric(1,0),
    zaok2 numeric(1,0),
    s_id_part character(6),
    aktivan character(1),
    id_kto_naz character(10),
    s_br_dok character(12)
);

ALTER TABLE fmk.epdv_sg_kif OWNER TO admin;

--
-- Name: epdv_sg_kuf; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.epdv_sg_kuf (
    id character(4),
    match_code character(10),
    naz character(60),
    src character(1),
    s_path character(60),
    s_path_s character(60),
    form_b_pdv character(160),
    form_pdv character(160),
    id_tar character(160),
    id_kto character(160),
    razb_tar character(1),
    razb_kto character(1),
    razb_dan character(1),
    kat_part character(1),
    td_src character(2),
    kat_p character(1),
    kat_p_2 character(1),
    s_id_tar character(6),
    zaok numeric(1,0),
    zaok2 numeric(1,0),
    s_id_part character(6),
    aktivan character(1),
    id_kto_naz character(10),
    s_br_dok character(12)
);

ALTER TABLE fmk.epdv_sg_kuf OWNER TO admin;

--
-- Name: f18_rules; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.f18_rules (
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

--
-- Name: fakt_doks; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_doks (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    partner character varying(200),
    datdok date,
    dindem character(3),
    iznos numeric(12,3),
    rabat numeric(12,3),
    rezerv character(1),
    m1 character(1),
    idpartner character(6),
    sifra character(6),
    brisano character(1),
    idvrstep character(2),
    datpl date,
    idpm character(15),
    oper_id integer,
    fisc_rn numeric(10,0),
    dat_isp date,
    dat_otpr date,
    dat_val date,
    fisc_st numeric(10,0),
    fisc_time character(10),
    fisc_date date,
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);

ALTER TABLE fmk.fakt_doks OWNER TO admin;

--
-- Name: fakt_doks2; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_doks2 (
    idfirma character(2),
    idtipdok character(2),
    brdok character varying(12),
    k1 character(15),
    k2 character(15),
    k3 character(15),
    k4 character(20),
    k5 character(20),
    n1 numeric(15,2),
    n2 numeric(15,2)
);

ALTER TABLE fmk.fakt_doks2 OWNER TO admin;

CREATE TABLE fmk.fakt_fakt (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    idpartner character(6),
    dindem character(3),
    zaokr numeric(1,0),
    rbr character(3) NOT NULL,
    podbr character(2),
    idroba character(10),
    serbr character(15),
    kolicina numeric(14,5),
    cijena numeric(14,5),
    rabat numeric(8,5),
    porez numeric(9,5),
    txt text,
    k1 character(4),
    k2 character(4),
    m1 character(1),
    brisano character(1),
    idroba_j character(10),
    idvrstep character(2),
    idpm character(15),
    c1 character(20),
    c2 character(20),
    c3 character(20),
    n1 numeric(10,3),
    n2 numeric(10,3),
    idrelac character(4)
);

ALTER TABLE fmk.fakt_fakt OWNER TO admin;

CREATE TABLE fmk.fakt_fakt_atributi (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character(12) NOT NULL,
    rbr character(3) NOT NULL,
    atribut character(50) NOT NULL,
    value character varying
);

ALTER TABLE fmk.fakt_fakt_atributi OWNER TO admin;

--
-- Name: fakt_ftxt; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_ftxt (
    id character(2),
    match_code character(10),
    naz character varying
);

ALTER TABLE fmk.fakt_ftxt OWNER TO admin;

--
-- Name: fakt_gen_ug; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_gen_ug (
    dat_obr date,
    dat_gen date,
    dat_u_fin date,
    kto_kup character(7),
    kto_dob character(7),
    opis character(100),
    brdok_od character(8),
    brdok_do character(8),
    fakt_br numeric(5,0),
    saldo numeric(15,5),
    saldo_pdv numeric(15,5),
    brisano character(1),
    dat_val date
);

ALTER TABLE fmk.fakt_gen_ug OWNER TO admin;

--
-- Name: fakt_gen_ug_p; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_gen_ug_p (
    dat_obr date,
    idpartner character(6),
    id_ugov character(10),
    saldo_kup numeric(15,5),
    saldo_dob numeric(15,5),
    d_p_upl_ku date,
    d_p_prom_k date,
    d_p_prom_d date,
    f_iznos numeric(15,5),
    f_iznos_pd numeric(15,5)
);

ALTER TABLE fmk.fakt_gen_ug_p OWNER TO admin;

--
-- Name: fakt_objekti; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_objekti (
    id character(10),
    naz character varying(100)
);

ALTER TABLE fmk.fakt_objekti OWNER TO admin;

--
-- Name: fakt_rugov; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_rugov (
    id character(10),
    idroba character(10),
    kolicina numeric(15,4),
    rabat numeric(6,3),
    porez numeric(5,2),
    k1 character(1),
    k2 character(2),
    dest character(6),
    cijena numeric(15,3)
);


ALTER TABLE fmk.fakt_rugov OWNER TO admin;

--
-- Name: fakt_ugov; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_ugov (
    id character(10) NOT NULL,
    datod date,
    idpartner character(6),
    datdo date,
    vrsta character(1),
    idtipdok character(2),
    naz character(20),
    aktivan character(1),
    dindem character(3),
    idtxt character(2),
    zaokr numeric(1,0),
    lab_prn character(1),
    iddodtxt character(2),
    a1 numeric(12,2),
    a2 numeric(12,2),
    b1 numeric(12,2),
    b2 numeric(12,2),
    txt2 character(2),
    txt3 character(2),
    txt4 character(2),
    f_nivo character(1),
    f_p_d_nivo numeric(5,0),
    dat_l_fakt date,
    def_dest character(6)
);

ALTER TABLE fmk.fakt_ugov OWNER TO admin;

--
-- Name: fakt_upl; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fakt_upl (
    datupl date,
    idpartner character(6),
    opis character(100),
    iznos numeric(12,2)
);

ALTER TABLE fmk.fakt_upl OWNER TO admin;

--
-- Name: fin_anal; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_anal (
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

--
-- Name: fin_budzet; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_budzet (
    idrj character(6) NOT NULL,
    idkonto character(7) NOT NULL,
    iznos numeric(20,2),
    fond character(3) DEFAULT '   '::bpchar NOT NULL,
    funk character(5) DEFAULT '     '::bpchar NOT NULL,
    rebiznos numeric(20,2)
);

ALTER TABLE fmk.fin_budzet OWNER TO admin;

--
-- Name: fin_buiz; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_buiz (
    id character(7),
    naz character(10)
);

ALTER TABLE fmk.fin_buiz OWNER TO admin;

--
-- Name: fin_fin_atributi; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_fin_atributi (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character(8) NOT NULL,
    rbr character(3) NOT NULL,
    atribut character(50) NOT NULL,
    value character varying
);

ALTER TABLE fmk.fin_fin_atributi OWNER TO admin;

--
-- Name: fin_fond; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_fond (
    id character(4),
    naz character varying(35)
);

ALTER TABLE fmk.fin_fond OWNER TO admin;

--
-- Name: fin_funk; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_funk (
    id character(5),
    naz character varying(35)
);


ALTER TABLE fmk.fin_funk OWNER TO admin;

--
-- Name: fin_izvje; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_izvje (
    id character(2) NOT NULL,
    naz character(50),
    uslov character(80),
    kpolje character(50),
    imekp character(10),
    ksif character(50),
    kbaza character(50),
    kindeks character(80),
    tiptab character(1)
);

ALTER TABLE fmk.fin_izvje OWNER TO admin;

--
-- Name: fin_koliz; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_koliz (
    id character(2) NOT NULL,
    naz character(20) NOT NULL,
    rbr numeric(2,0) NOT NULL,
    formula character(150),
    tip character(2),
    sirina numeric(3,0),
    decimale numeric(1,0),
    sumirati character(1),
    k1 character(1),
    k2 character(2),
    n1 character(1),
    n2 character(2),
    kuslov character(100),
    sizraz character(100)
);

ALTER TABLE fmk.fin_koliz OWNER TO admin;

--
-- Name: fin_koniz; Type: TABLE; Schema: fmk; Owner: admin
--

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

--
-- Name: fin_nalog; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_nalog (
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

--
-- Name: fin_parek; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_parek (
    idpartija character(6),
    idkonto character(7)
);

ALTER TABLE fmk.fin_parek OWNER TO admin;

--
-- Name: fin_sint; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_sint (
    idfirma character(2) NOT NULL,
    idkonto character(3),
    idvn character(2) NOT NULL,
    brnal character varying(12) NOT NULL,
    rbr character varying(4) NOT NULL,
    datnal date,
    dugbhd numeric(17,2),
    potbhd numeric(17,2),
    dugdem numeric(15,2),
    potdem numeric(15,2)
);

ALTER TABLE fmk.fin_sint OWNER TO admin;

--
-- Name: fin_suban; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_suban (
    idfirma character varying(2) NOT NULL,
    idvn character varying(2) NOT NULL,
    brnal character varying(8) NOT NULL,
    idkonto character varying(7),
    idpartner character varying(6),
    rbr integer NOT NULL,
    idtipdok character(2),
    brdok character varying(20),
    datdok date,
    datval date,
    otvst character(1),
    d_p character(1),
    iznosbhd numeric(17,2),
    iznosdem numeric(15,2),
    opis character varying(500),
    k1 character(1),
    k2 character(1),
    k3 character(2),
    k4 character(2),
    m1 character(1),
    m2 character(1),
    idrj character(6),
    funk character(5),
    fond character(4)
);

ALTER TABLE fmk.fin_suban OWNER TO admin;

--
-- Name: fin_ulimit; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_ulimit (
    id character(3),
    idpartner character(6),
    f_limit numeric(15,2)
);

ALTER TABLE fmk.fin_ulimit OWNER TO admin;

--
-- Name: fin_zagli; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.fin_zagli (
    id character(2) NOT NULL,
    x1 numeric(3,0) NOT NULL,
    y1 numeric(3,0) NOT NULL,
    izraz character(100) NOT NULL
);

ALTER TABLE fmk.fin_zagli OWNER TO admin;

--
-- Name: jprih; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.jprih (
    id character(6),
    idn0 character(1),
    idkan character(2),
    idops character(3),
    naz character varying(40),
    racun character(16),
    budzorg character(7)
);

ALTER TABLE fmk.jprih OWNER TO admin;

--
-- Name: kalk_doks; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kalk_doks (
    idfirma character(2) NOT NULL,
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    idpartner character(6),
    idzaduz character(6),
    idzaduz2 character(6),
    pkonto character(7),
    mkonto character(7),
    nv numeric(12,2),
    vpv numeric(12,2),
    rabat numeric(12,2),
    mpv numeric(12,2),
    podbr character(2),
    sifra character(6),
    obradjeno timestamp without time zone DEFAULT now(),
    korisnik text DEFAULT "current_user"()
);

ALTER TABLE fmk.kalk_doks OWNER TO admin;

--
-- Name: kalk_doks2; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kalk_doks2 (
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

CREATE TABLE fmk.kalk_kalk (
    idfirma character(2) NOT NULL,
    idroba character(10),
    idkonto character(7),
    idkonto2 character(7),
    idzaduz character(6),
    idzaduz2 character(6),
    idvd character(2) NOT NULL,
    brdok character varying(12) NOT NULL,
    datdok date,
    brfaktp character(10),
    datfaktp date,
    idpartner character(6),
    datkurs date,
    rbr character(3) NOT NULL,
    kolicina numeric(12,3),
    gkolicina numeric(12,3),
    gkolicin2 numeric(12,3),
    fcj numeric(18,8),
    fcj2 numeric(18,8),
    fcj3 numeric(18,8),
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
    vpcsap numeric(18,8),
    tmarza2 character(1),
    marza2 numeric(18,8),
    mpc numeric(18,8),
    idtarifa character(6),
    mpcsapp numeric(18,8),
    mkonto character(7),
    pkonto character(7),
    roktr date,
    mu_i character(1),
    pu_i character(1),
    error character(1),
    podbr character(2)
);

ALTER TABLE fmk.kalk_kalk OWNER TO admin;

--
-- Name: kalk_kalk_atributi; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kalk_kalk_atributi (
    idfirma character(2) NOT NULL,
    idtipdok character(2) NOT NULL,
    brdok character(8) NOT NULL,
    rbr character(3) NOT NULL,
    atribut character(50) NOT NULL,
    value character varying
);

ALTER TABLE fmk.kalk_kalk_atributi OWNER TO admin;

--
-- Name: kalvir; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kalvir (
    id character(4),
    naz character varying(20),
    formula character varying(200),
    pnabr character(10)
);

ALTER TABLE fmk.kalvir OWNER TO admin;

--
-- Name: kbenef; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kbenef (
    id character(1),
    match_code character(10),
    naz character(8),
    iznos numeric(5,2)
);


ALTER TABLE fmk.kbenef OWNER TO admin;

--
-- Name: koncij; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.koncij (
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

ALTER TABLE fmk.koncij OWNER TO admin;

--
-- Name: konto; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.konto (
    id character(7) NOT NULL,
    match_code character(10),
    naz character(57),
    pozbilu character(3),
    pozbils character(3)
);

ALTER TABLE fmk.konto OWNER TO admin;

--
-- Name: kred; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.kred (
    id character(6) NOT NULL,
    match_code character(10),
    naz character(30),
    ziro character(20),
    zirod character(20),
    telefon character(20),
    adresa character(30),
    ptt character(5),
    fil character(30),
    mjesto character(20)
);

ALTER TABLE fmk.kred OWNER TO admin;

--
-- Name: ks; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ks (
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

--
-- Name: ld_ld; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_ld (
    godina numeric(4,0) NOT NULL,
    idrj character(2) NOT NULL,
    idradn character(6) NOT NULL,
    mjesec numeric(2,0) NOT NULL,
    brbod numeric(11,2),
    idstrspr character(3),
    idvposla character(2),
    kminrad numeric(5,2),
    s01 numeric(5,1),
    i01 numeric(12,2),
    s02 numeric(5,1),
    i02 numeric(12,2),
    s03 numeric(5,1),
    i03 numeric(12,2),
    s04 numeric(5,1),
    i04 numeric(12,2),
    s05 numeric(5,1),
    i05 numeric(12,2),
    s06 numeric(5,1),
    i06 numeric(12,2),
    s07 numeric(5,1),
    i07 numeric(12,2),
    s08 numeric(5,1),
    i08 numeric(12,2),
    s09 numeric(5,1),
    i09 numeric(12,2),
    s10 numeric(5,1),
    i10 numeric(12,2),
    s11 numeric(5,1),
    i11 numeric(12,2),
    s12 numeric(5,1),
    i12 numeric(12,2),
    s13 numeric(5,1),
    i13 numeric(12,2),
    s14 numeric(5,1),
    i14 numeric(12,2),
    s15 numeric(5,1),
    i15 numeric(12,2),
    s16 numeric(5,1),
    i16 numeric(12,2),
    s17 numeric(5,1),
    i17 numeric(12,2),
    s18 numeric(5,1),
    i18 numeric(12,2),
    s19 numeric(5,1),
    i19 numeric(12,2),
    s20 numeric(5,1),
    i20 numeric(12,2),
    s21 numeric(5,1),
    i21 numeric(12,2),
    s22 numeric(5,1),
    i22 numeric(12,2),
    s23 numeric(5,1),
    i23 numeric(12,2),
    s24 numeric(5,1),
    i24 numeric(12,2),
    s25 numeric(5,1),
    i25 numeric(12,2),
    s26 numeric(5,1),
    i26 numeric(12,2),
    s27 numeric(5,1),
    i27 numeric(12,2),
    s28 numeric(5,1),
    i28 numeric(12,2),
    s29 numeric(5,1),
    i29 numeric(12,2),
    s30 numeric(5,1),
    i30 numeric(12,2),
    usati numeric(8,1),
    uneto numeric(13,2),
    uodbici numeric(13,2),
    uiznos numeric(13,2),
    varobr character(1),
    ubruto numeric(13,2),
    uneto2 numeric(13,2),
    ulicodb numeric(13,2),
    trosk character(1),
    opor character(1),
    tiprada character(1),
    nakn_opor numeric(13,2),
    nakn_neop numeric(13,2),
    udopr numeric(13,2),
    udop_st numeric(10,2),
    uporez numeric(13,3),
    upor_st numeric(10,3),
    obr character(1) DEFAULT '1'::bpchar NOT NULL,
    v_ispl character(2),
    i31 numeric(12,2),
    s31 numeric(5,2),
    i32 numeric(12,2),
    s32 numeric(5,2),
    i33 numeric(12,2),
    s33 numeric(5,2),
    i34 numeric(12,2),
    s34 numeric(5,2),
    i35 numeric(12,2),
    s35 numeric(5,2),
    i36 numeric(12,2),
    s36 numeric(5,2),
    i37 numeric(12,2),
    s37 numeric(5,2),
    i38 numeric(12,2),
    s38 numeric(5,2),
    i39 numeric(12,2),
    s39 numeric(5,2),
    i40 numeric(12,2),
    s40 numeric(5,2),
    i41 numeric(12,2),
    s41 numeric(5,2),
    i42 numeric(12,2),
    s42 numeric(5,2),
    i43 numeric(12,2),
    s43 numeric(5,2),
    i44 numeric(12,2),
    s44 numeric(5,2),
    i45 numeric(12,2),
    s45 numeric(5,2),
    i46 numeric(12,2),
    s46 numeric(5,2),
    i47 numeric(12,2),
    s47 numeric(5,2),
    i48 numeric(12,2),
    s48 numeric(5,2),
    i49 numeric(12,2),
    s49 numeric(5,2),
    i50 numeric(12,2),
    s50 numeric(5,2),
    i51 numeric(12,2),
    s51 numeric(5,2),
    i52 numeric(12,2),
    s52 numeric(5,2),
    i53 numeric(12,2),
    s53 numeric(5,2),
    i54 numeric(12,2),
    s54 numeric(5,2),
    i55 numeric(12,2),
    s55 numeric(5,2),
    i56 numeric(12,2),
    s56 numeric(5,2),
    i57 numeric(12,2),
    s57 numeric(5,2),
    i58 numeric(12,2),
    s58 numeric(5,2),
    i59 numeric(12,2),
    s59 numeric(5,2),
    i60 numeric(12,2),
    s60 numeric(5,2),
    radsat numeric(10,0)
);

ALTER TABLE fmk.ld_ld OWNER TO admin;

--
-- Name: ld_norsiht; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_norsiht (
    id character(4),
    naz character(30),
    jmj character(3),
    iznos numeric(8,2),
    n1 numeric(6,2),
    k1 character(1),
    k2 character(2)
);


ALTER TABLE fmk.ld_norsiht OWNER TO admin;

--
-- Name: ld_obracuni; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_obracuni (
    rj character(2),
    godina numeric(4,0),
    mjesec numeric(2,0),
    status character(1),
    dat_ispl date,
    obr character(1),
    mj_ispl numeric(2,0),
    ispl_za character(50),
    vr_ispl character(50),
    k1 character(4),
    k2 character(10)
);


ALTER TABLE fmk.ld_obracuni OWNER TO admin;

--
-- Name: ld_parobr; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_parobr (
    id character(2),
    naz character(10),
    vrbod numeric(15,5),
    k1 numeric(11,6),
    k2 numeric(11,6),
    k3 numeric(9,5),
    k4 numeric(6,3),
    k5 numeric(12,6),
    k6 numeric(12,6),
    k7 numeric(12,6),
    k8 numeric(12,6),
    m_br_sat numeric(12,6),
    m_net_sat numeric(12,6),
    prosld numeric(12,2),
    idrj character(2),
    godina character(4),
    obr character(1) DEFAULT '1'::bpchar
);


ALTER TABLE fmk.ld_parobr OWNER TO admin;

--
-- Name: ld_pk_data; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_pk_data (
    idradn character(6),
    ident character(1),
    rbr numeric(2,0),
    ime_pr character(50),
    jmb character(13),
    sr_naz character(30),
    sr_kod numeric(2,0),
    prihod numeric(10,2),
    udio numeric(3,0),
    koef numeric(10,3)
);


ALTER TABLE fmk.ld_pk_data OWNER TO admin;

--
-- Name: ld_pk_radn; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_pk_radn (
    idradn character(6),
    zahtjev numeric(4,0),
    datum date,
    r_prez character(20),
    r_ime character(20),
    r_imeoca character(20),
    r_jmb character(13),
    r_adr character(30),
    r_opc character(30),
    r_opckod character(10),
    r_drodj date,
    r_tel numeric(12,0),
    p_naziv character(100),
    p_jib character(13),
    p_zap character(1),
    lo_osn numeric(10,3),
    lo_brdr numeric(10,3),
    lo_izdj numeric(10,3),
    lo_clp numeric(10,3),
    lo_clpi numeric(10,3),
    lo_ufakt numeric(10,3)
);


ALTER TABLE fmk.ld_pk_radn OWNER TO admin;

--
-- Name: ld_radkr; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_radkr (
    idradn character(6),
    mjesec numeric(2,0),
    godina numeric(4,0),
    idkred character(6),
    naosnovu character(20),
    iznos numeric(12,2),
    placeno numeric(12,2)
);


ALTER TABLE fmk.ld_radkr OWNER TO admin;

--
-- Name: ld_radn; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_radn (
    id character(6) NOT NULL,
    match_code character(10),
    naz character(20),
    imerod character(15),
    ime character(15),
    brbod numeric(11,2),
    kminrad numeric(7,2),
    idstrspr character(3),
    idvposla character(2),
    idopsst character(4),
    idopsrad character(4),
    pol character(1),
    matbr character(13),
    datod date,
    k1 character(1),
    k2 character(1),
    k3 character(2),
    k4 character(2),
    rmjesto character(30),
    brknjiz character(12),
    brtekr character(20),
    isplata character(2),
    idbanka character(6),
    porol numeric(5,2),
    n1 numeric(12,2),
    n2 numeric(12,2),
    n3 numeric(12,2),
    osnbol numeric(11,4),
    idrj character(2),
    streetname character(40),
    streetnum character(6),
    hiredfrom date,
    hiredto date,
    klo numeric(5,2),
    tiprada character(1),
    sp_koef numeric(5,2),
    opor character(1),
    trosk character(1),
    aktivan character(1),
    ben_srmj character(20),
    s1 character(10),
    s2 character(10),
    s3 character(10),
    s4 character(10),
    s5 character(10),
    s6 character(10),
    s7 character(10),
    s8 character(10),
    s9 character(10),
    st_invalid integer,
    vr_invalid integer
);


ALTER TABLE fmk.ld_radn OWNER TO admin;

--
-- Name: ld_radsat; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_radsat (
    idradn character(6),
    sati numeric(10,0),
    status character(2)
);


ALTER TABLE fmk.ld_radsat OWNER TO admin;

--
-- Name: ld_radsiht; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_radsiht (
    godina numeric(4,0),
    mjesec numeric(2,0),
    dan numeric(2,0),
    dandio character(1),
    idrj character(2),
    idradn character(6),
    idkonto character(7),
    opis character(50),
    idtippr character(2),
    brbod numeric(11,2),
    idnorsiht character(4),
    izvrseno numeric(14,3),
    bodova numeric(14,2)
);


ALTER TABLE fmk.ld_radsiht OWNER TO admin;

--
-- Name: ld_rj; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_rj (
    id character(2) NOT NULL,
    match_code character(10),
    naz character(100),
    tiprada character(1),
    opor character(1)
);


ALTER TABLE fmk.ld_rj OWNER TO admin;

--
-- Name: ld_tprsiht; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ld_tprsiht (
    id character(2),
    naz character(30),
    k1 character(1),
    k2 character(2),
    k3 character(3),
    ff character(30)
);


ALTER TABLE fmk.ld_tprsiht OWNER TO admin;

--
-- Name: ldvirm; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ldvirm (
    id character(4),
    naz character varying(50),
    formula character varying(200)
);


ALTER TABLE fmk.ldvirm OWNER TO admin;

--
-- Name: log; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.log (
    id bigint NOT NULL,
    user_code character varying(20) NOT NULL,
    l_time timestamp without time zone DEFAULT now(),
    msg text NOT NULL
);


ALTER TABLE fmk.log OWNER TO admin;

--
-- Name: log_id_seq; Type: SEQUENCE; Schema: fmk; Owner: admin
--

CREATE SEQUENCE fmk.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fmk.log_id_seq OWNER TO admin;

--
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: fmk; Owner: admin
--

ALTER SEQUENCE fmk.log_id_seq OWNED BY fmk.log.id;


--
-- Name: lokal; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.lokal (
    id character(2),
    match_code character(10),
    id_str numeric(6,0),
    naz character(200)
);


ALTER TABLE fmk.lokal OWNER TO admin;

--
-- Name: mat_anal; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.mat_anal (
    idfirma character(2) NOT NULL,
    idkonto character(7),
    idvn character(2) NOT NULL,
    brnal character(4) NOT NULL,
    datnal date,
    rbr character(3) NOT NULL,
    dug numeric(15,2),
    pot numeric(15,2),
    dug2 numeric(15,2),
    pot2 numeric(15,2)
);


ALTER TABLE fmk.mat_anal OWNER TO admin;

--
-- Name: mat_karkon; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.mat_karkon (
    id character(2),
    tip_nc character(1),
    tip_pc character(1)
);


ALTER TABLE fmk.mat_karkon OWNER TO admin;

--
-- Name: mat_nalog; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.mat_nalog (
    idfirma character(2) NOT NULL,
    idvn character(2) NOT NULL,
    brnal character(4) NOT NULL,
    datnal date,
    dug numeric(15,2),
    pot numeric(15,2),
    dug2 numeric(15,2),
    pot2 numeric(15,2)
);


ALTER TABLE fmk.mat_nalog OWNER TO admin;

--
-- Name: mat_sint; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.mat_sint (
    idfirma character(2) NOT NULL,
    idkonto character(3),
    idvn character(2) NOT NULL,
    brnal character(4) NOT NULL,
    datnal date,
    rbr character(3) NOT NULL,
    dug numeric(15,2),
    pot numeric(15,2),
    dug2 numeric(15,2),
    pot2 numeric(15,2)
);


ALTER TABLE fmk.mat_sint OWNER TO admin;

--
-- Name: mat_suban; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.mat_suban (
    idfirma character(2) NOT NULL,
    idroba character(10),
    idkonto character(7),
    idvn character(2) NOT NULL,
    brnal character(4) NOT NULL,
    rbr character(4) NOT NULL,
    idtipdok character(2),
    brdok character(8),
    datdok date,
    u_i character(1),
    kolicina numeric(10,3),
    d_p character(1),
    iznos numeric(15,2),
    idpartner character(6),
    idzaduz character(6),
    iznos2 numeric(15,2),
    datkurs date,
    k1 character(1),
    k2 character(1),
    k3 character(1),
    k4 character(1)
);


ALTER TABLE fmk.mat_suban OWNER TO admin;

--
-- Name: metric; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.metric (
    metric_id integer DEFAULT nextval(('metric_metric_id_seq'::text)::regclass) NOT NULL,
    metric_name text,
    metric_value text,
    metric_module text
);

ALTER TABLE fmk.metric OWNER TO admin;

--
-- Name: TABLE metric; Type: COMMENT; Schema: fmk; Owner: admin
--

COMMENT ON TABLE fmk.metric IS 'Application-wide settings information';


--
-- Name: metric_metric_id_seq; Type: SEQUENCE; Schema: fmk; Owner: admin
--

CREATE SEQUENCE fmk.metric_metric_id_seq
    START WITH 445
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;

ALTER TABLE fmk.metric_metric_id_seq OWNER TO admin;

--
-- Name: objekti; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.objekti (
    id character(2),
    naz character(10),
    idobj character(7)
);

ALTER TABLE fmk.objekti OWNER TO admin;

--
-- Name: ops; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.ops (
    id character(4),
    match_code character(10),
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

--
-- Name: os_amort; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.os_amort (
    id character(8),
    match_code character(10),
    naz character(25),
    iznos numeric(7,3)
);

ALTER TABLE fmk.os_amort OWNER TO admin;

--
-- Name: os_k1; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.os_k1 (
    id character(4),
    match_code character(10),
    naz character(25)
);

ALTER TABLE fmk.os_k1 OWNER TO admin;

--
-- Name: os_os; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.os_os (
    id character(10),
    match_code character(10),
    naz character(30),
    idrj character(4),
    datum date,
    datotp date,
    opisotp character(30),
    idkonto character(7),
    kolicina numeric(8,1),
    jmj character(3),
    idam character(8),
    idrev character(4),
    nabvr numeric(18,2),
    otpvr numeric(18,2),
    amd numeric(18,2),
    amp numeric(18,2),
    revd numeric(18,2),
    revp numeric(18,2),
    k1 character(4),
    k2 character(1),
    k3 character(2),
    opis character(25),
    brsoba character(6),
    idpartner character(6)
);

ALTER TABLE fmk.os_os OWNER TO admin;


--
-- Name: os_promj; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.os_promj (
    id character(10),
    match_code character(10),
    opis character(30),
    datum date,
    tip character(2),
    nabvr numeric(18,2),
    otpvr numeric(18,2),
    amd numeric(18,2),
    amp numeric(18,2),
    revd numeric(18,2),
    revp numeric(18,2)
);

ALTER TABLE fmk.os_promj OWNER TO admin;

--
-- Name: os_reval; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.os_reval (
    id character(4),
    match_code character(10),
    naz character(10),
    i1 numeric(7,3),
    i2 numeric(7,3),
    i3 numeric(7,3),
    i4 numeric(7,3),
    i5 numeric(7,3),
    i6 numeric(7,3),
    i7 numeric(7,3),
    i8 numeric(7,3),
    i9 numeric(7,3),
    i10 numeric(7,3),
    i11 numeric(7,3),
    i12 numeric(7,3)
);

ALTER TABLE fmk.os_reval OWNER TO admin;

--
-- Name: partn; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.partn (
    id character(6) NOT NULL,
    match_code character(10),
    naz character(250),
    naz2 character(250),
    ptt character(5),
    mjesto character(16),
    adresa character(24),
    ziror character(22),
    rejon character(4),
    telefon character(12),
    dziror character(22),
    fax character(12),
    mobtel character(20),
    idops character(4),
    _kup character(1),
    _dob character(1),
    _banka character(1),
    _radnik character(1),
    idrefer character(10)
);

ALTER TABLE fmk.partn OWNER TO admin;

--
-- Name: pkonto; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pkonto (
    id character(7),
    tip character(1)
);

ALTER TABLE fmk.pkonto OWNER TO admin;

--
-- Name: por; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.por (
    id character(2),
    match_code character(10),
    naz character(20),
    iznos numeric(5,2),
    dlimit numeric(12,2),
    poopst character(1),
    algoritam character(1),
    por_tip character(1),
    s_sto_1 numeric(5,2),
    s_izn_1 numeric(12,2),
    s_sto_2 numeric(5,2),
    s_izn_2 numeric(12,2),
    s_sto_3 numeric(5,2),
    s_izn_3 numeric(12,2),
    s_sto_4 numeric(5,2),
    s_izn_4 numeric(12,2),
    s_sto_5 numeric(5,2),
    s_izn_5 numeric(12,2)
);

ALTER TABLE fmk.por OWNER TO admin;

--
-- Name: pos_dokspf; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_dokspf (
    idpos character(2),
    idvd character(2),
    datum date,
    brdok character(6),
    knaz character varying(35),
    kadr character varying(35),
    kidbr character(13),
    datisp date
);

ALTER TABLE fmk.pos_dokspf OWNER TO admin;

--
-- Name: pos_kase; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_kase (
    id character varying(2),
    naz character varying(15),
    ppath character varying(50)
);


ALTER TABLE fmk.pos_kase OWNER TO admin;

--
-- Name: pos_odj; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_odj (
    id character varying(2),
    naz character varying(25),
    zaduzuje character(1),
    idkonto character varying(7)
);


ALTER TABLE fmk.pos_odj OWNER TO admin;

--
-- Name: pos_osob; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_osob (
    id character varying(4),
    korsif character varying(6),
    naz character varying(40),
    status character(2)
);


ALTER TABLE fmk.pos_osob OWNER TO admin;

--
-- Name: pos_promvp; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_promvp (
    datum date,
    polog01 numeric(10,2),
    polog02 numeric(10,2),
    polog03 numeric(10,2),
    polog04 numeric(10,2),
    polog05 numeric(10,2),
    polog06 numeric(10,2),
    polog07 numeric(10,2),
    polog08 numeric(10,2),
    polog09 numeric(10,2),
    polog10 numeric(10,2),
    polog11 numeric(10,2),
    polog12 numeric(10,2),
    ukupno numeric(10,3)
);


ALTER TABLE fmk.pos_promvp OWNER TO admin;

--
-- Name: pos_strad; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.pos_strad (
    id character varying(2),
    naz character varying(15),
    prioritet character(1)
);


ALTER TABLE fmk.pos_strad OWNER TO admin;

--
-- Name: refer; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.refer (
    id character(10),
    match_code character(10),
    idops character(4),
    naz character(40)
);

ALTER TABLE fmk.refer OWNER TO admin;

--
-- Name: relation; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.relation (
    tfrom character(10),
    tto character(10),
    tfromid character(10),
    ttoid character(10)
);


ALTER TABLE fmk.relation OWNER TO admin;

--
-- Name: rj; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.rj (
    id character(7) NOT NULL,
    match_code character(10),
    naz character(100),
    tip character(2),
    konto character(7)
);


ALTER TABLE fmk.rj OWNER TO admin;

--
-- Name: roba; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.roba (
    id character(10) NOT NULL,
    match_code character(10),
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

ALTER TABLE fmk.roba OWNER TO admin;

--
-- Name: sast; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.sast (
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

--
-- Name: sem_ver_banke; Type: SEQUENCE; Schema: fmk; Owner: admin
--


--
-- Name: sifk; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.sifk (
    id character(8),
    match_code character(10),
    sort character(2),
    naz character(25),
    oznaka character(4),
    veza character(1),
    f_unique character(1),
    izvor character(15),
    uslov character(200),
    duzina numeric(2,0),
    f_decimal numeric(1,0),
    tip character(1),
    kvalid character(100),
    kwhen character(100),
    ubrowsu character(1),
    edkolona numeric(2,0),
    k1 character(1),
    k2 character(2),
    k3 character(3),
    k4 character(4)
);


ALTER TABLE fmk.sifk OWNER TO admin;

--
-- Name: sifv; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.sifv (
    id character(8),
    idsif character(15),
    naz character(200),
    oznaka character(4)
);


ALTER TABLE fmk.sifv OWNER TO admin;

--
-- Name: sii_promj; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.sii_promj (
    id character(10),
    match_code character(10),
    opis character(30),
    datum date,
    tip character(2),
    nabvr numeric(18,2),
    otpvr numeric(18,2),
    amd numeric(18,2),
    amp numeric(18,2),
    revd numeric(18,2),
    revp numeric(18,2)
);

ALTER TABLE fmk.sii_promj OWNER TO admin;

--
-- Name: sii_sii; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.sii_sii (
    id character(10),
    match_code character(10),
    naz character(30),
    idrj character(4),
    datum date,
    datotp date,
    opisotp character(30),
    idkonto character(7),
    kolicina numeric(6,1),
    jmj character(3),
    idam character(8),
    idrev character(4),
    nabvr numeric(18,2),
    otpvr numeric(18,2),
    amd numeric(18,2),
    amp numeric(18,2),
    revd numeric(18,2),
    revp numeric(18,2),
    k1 character(4),
    k2 character(1),
    k3 character(2),
    opis character(25),
    brsoba character(6),
    idpartner character(6)
);

ALTER TABLE fmk.sii_sii OWNER TO admin;

--
-- Name: strspr; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.strspr (
    id character(3),
    naz character(20),
    naz2 character(6)
);


ALTER TABLE fmk.strspr OWNER TO admin;

--
-- Name: tarifa; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.tarifa (
    id character(6) NOT NULL,
    match_code character(10),
    naz character(50),
    opp numeric(6,2),
    ppp numeric(6,2),
    zpp numeric(6,2),
    vpp numeric(6,2),
    mpp numeric(6,2),
    dlruc numeric(6,2)
);

ALTER TABLE fmk.tarifa OWNER TO admin;

--
-- Name: tdok; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.tdok (
    id character(2),
    match_code character(10),
    naz character(30)
);

ALTER TABLE fmk.tdok OWNER TO admin;

--
-- Name: tippr; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.tippr (
    id character(2) NOT NULL,
    match_code character(10),
    naz character(20),
    aktivan character(1),
    fiksan character(1),
    ufs character(1),
    koef1 numeric(5,2),
    formula character(200),
    uneto character(1),
    opis character(8),
    tpr_tip character(1)
);

ALTER TABLE fmk.tippr OWNER TO admin;

--
-- Name: tippr2; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.tippr2 (
    id character(2) NOT NULL,
    match_code character(10),
    naz character(20),
    aktivan character(1),
    fiksan character(1),
    ufs character(1),
    koef1 numeric(5,2),
    formula character(200),
    uneto character(1),
    opis character(8),
    tpr_tip character(1)
);

ALTER TABLE fmk.tippr2 OWNER TO admin;

--
-- Name: tnal; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.tnal (
    id character(2),
    match_code character(10),
    naz character(30)
);

ALTER TABLE fmk.tnal OWNER TO admin;

--
-- Name: trfp; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.trfp (
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

ALTER TABLE fmk.trfp OWNER TO admin;

--
-- Name: trfp2; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.trfp2 (
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

--
-- Name: trfp3; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.trfp3 (
    id character(60),
    match_code character(10),
    shema character(1),
    naz character(20),
    idkonto character(7),
    d_p character(1),
    znak character(1),
    idvn character(2)
);

ALTER TABLE fmk.trfp3 OWNER TO admin;

--
-- Name: valute; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.valute (
    id character(4) NOT NULL,
    match_code character(10),
    naz character(30),
    naz2 character(4),
    datum date,
    kurs1 numeric(18,8),
    kurs2 numeric(18,8),
    kurs3 numeric(18,8),
    tip character(1)
);

ALTER TABLE fmk.valute OWNER TO admin;

--
-- Name: vposla; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.vposla (
    id character(2) NOT NULL,
    match_code character(10),
    naz character(20),
    idkbenef character(1)
);

ALTER TABLE fmk.vposla OWNER TO admin;

--
-- Name: vprih; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.vprih (
    id character(3),
    match_code character(10),
    naz character(20)
);

ALTER TABLE fmk.vprih OWNER TO admin;

--
-- Name: vrprim; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.vrprim (
    id character(4),
    naz character varying(55),
    pom_txt character varying(100),
    idkonto character(7),
    idpartner character(6),
    nacin_pl character(1),
    racun character(16),
    dobav character(1)
);

ALTER TABLE fmk.vrprim OWNER TO admin;

--
-- Name: vrstep; Type: TABLE; Schema: fmk; Owner: admin
--

CREATE TABLE fmk.vrstep (
    id character(2),
    naz character(20)
);

ALTER TABLE fmk.vrstep OWNER TO admin;

--
-- Name: log id; Type: DEFAULT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.log ALTER COLUMN id SET DEFAULT nextval('fmk.log_id_seq'::regclass);


--
-- Name: fakt_doks fakt_doks_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fakt_doks
    ADD CONSTRAINT fakt_doks_pkey PRIMARY KEY (idfirma, idtipdok, brdok);


--
-- Name: fakt_fakt_atributi fakt_fakt_atributi_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fakt_fakt_atributi
    ADD CONSTRAINT fakt_fakt_atributi_pkey PRIMARY KEY (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: fakt_fakt fakt_fakt_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fakt_fakt
    ADD CONSTRAINT fakt_fakt_pkey PRIMARY KEY (idfirma, idtipdok, brdok, rbr);


--
-- Name: fakt_ugov fakt_ugov_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fakt_ugov
    ADD CONSTRAINT fakt_ugov_pkey PRIMARY KEY (id);


--
-- Name: fin_anal fin_anal_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_anal
    ADD CONSTRAINT fin_anal_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: fin_budzet fin_budzet_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_budzet
    ADD CONSTRAINT fin_budzet_pkey PRIMARY KEY (idrj, idkonto, fond, funk);


--
-- Name: fin_fin_atributi fin_fin_atributi_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_fin_atributi
    ADD CONSTRAINT fin_fin_atributi_pkey PRIMARY KEY (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: fin_izvje fin_izvje_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_izvje
    ADD CONSTRAINT fin_izvje_pkey PRIMARY KEY (id);


--
-- Name: fin_koliz fin_koliz_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_koliz
    ADD CONSTRAINT fin_koliz_pkey PRIMARY KEY (id, rbr, naz);


--
-- Name: fin_koniz fin_koniz_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_koniz
    ADD CONSTRAINT fin_koniz_pkey PRIMARY KEY (id, izv, id2, opis);


--
-- Name: fin_nalog fin_nalog_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_nalog
    ADD CONSTRAINT fin_nalog_pkey PRIMARY KEY (idfirma, idvn, brnal);


--
-- Name: fin_sint fin_sint_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_sint
    ADD CONSTRAINT fin_sint_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: fin_suban fin_suban_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_suban
    ADD CONSTRAINT fin_suban_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: fin_zagli fin_zagli_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fin_zagli
    ADD CONSTRAINT fin_zagli_pkey PRIMARY KEY (id, x1, y1, izraz);


--
-- Name: kalk_doks kalk_doks_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.kalk_doks
    ADD CONSTRAINT kalk_doks_pkey PRIMARY KEY (idfirma, idvd, brdok);


--
-- Name: kalk_kalk_atributi kalk_kalk_atributi_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.kalk_kalk_atributi
    ADD CONSTRAINT kalk_kalk_atributi_pkey PRIMARY KEY (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: kalk_kalk kalk_kalk_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.kalk_kalk
    ADD CONSTRAINT kalk_kalk_pkey PRIMARY KEY (idfirma, idvd, brdok, rbr);


--
-- Name: konto konto_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.konto
    ADD CONSTRAINT konto_pkey PRIMARY KEY (id);


--
-- Name: kred kred_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.kred
    ADD CONSTRAINT kred_pkey PRIMARY KEY (id);


--
-- Name: ld_ld ld_ld_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.ld_ld
    ADD CONSTRAINT ld_ld_pkey PRIMARY KEY (idrj, godina, mjesec, obr, idradn);


--
-- Name: ld_radn ld_radn_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.ld_radn
    ADD CONSTRAINT ld_radn_pkey PRIMARY KEY (id);


--
-- Name: ld_rj ld_rj_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.ld_rj
    ADD CONSTRAINT ld_rj_pkey PRIMARY KEY (id);


--
-- Name: log log_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- Name: mat_anal mat_anal_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.mat_anal
    ADD CONSTRAINT mat_anal_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: mat_nalog mat_nalog_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.mat_nalog
    ADD CONSTRAINT mat_nalog_pkey PRIMARY KEY (idfirma, idvn, brnal);


--
-- Name: mat_sint mat_sint_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.mat_sint
    ADD CONSTRAINT mat_sint_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: mat_suban mat_suban_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.mat_suban
    ADD CONSTRAINT mat_suban_pkey PRIMARY KEY (idfirma, idvn, brnal, rbr);


--
-- Name: metric metric_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.metric
    ADD CONSTRAINT metric_pkey PRIMARY KEY (metric_id);


--
-- Name: partn partn_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.partn
    ADD CONSTRAINT partn_pkey PRIMARY KEY (id);



--
-- Name: rj rj_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.rj
    ADD CONSTRAINT rj_pkey PRIMARY KEY (id);


--
-- Name: roba roba_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.roba
    ADD CONSTRAINT roba_pkey PRIMARY KEY (id);


--
-- Name: tarifa tarifa_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.tarifa
    ADD CONSTRAINT tarifa_pkey PRIMARY KEY (id);


--
-- Name: tippr2 tippr2_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.tippr2
    ADD CONSTRAINT tippr2_pkey PRIMARY KEY (id);


--
-- Name: tippr tippr_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.tippr
    ADD CONSTRAINT tippr_pkey PRIMARY KEY (id);


--
-- Name: valute valute_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.valute
    ADD CONSTRAINT valute_pkey PRIMARY KEY (id);


--
-- Name: vposla vposla_pkey; Type: CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.vposla
    ADD CONSTRAINT vposla_pkey PRIMARY KEY (id);


--
-- Name: adres_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX adres_id1 ON fmk.adres USING btree (id, naz);


--
-- Name: banke_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX banke_id1 ON fmk.banke USING btree (id);


--
-- Name: dest_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX dest_id1 ON fmk.dest USING btree (id);


--
-- Name: dopr_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX dopr_id1 ON fmk.dopr USING btree (id, tiprada);


--
-- Name: epdv_kif_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX epdv_kif_id1 ON fmk.epdv_kif USING btree (datum, datum_2);


--
-- Name: epdv_kuf_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX epdv_kuf_id1 ON fmk.epdv_kuf USING btree (datum, datum_2);


--
-- Name: epdv_pdv_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX epdv_pdv_id1 ON fmk.epdv_pdv USING btree (datum_1, datum_2);


--
-- Name: epdv_sg_kif_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX epdv_sg_kif_id1 ON fmk.epdv_sg_kif USING btree (id);


--
-- Name: epdv_sg_kuf_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX epdv_sg_kuf_id1 ON fmk.epdv_sg_kuf USING btree (id);


--
-- Name: f18_rules_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX f18_rules_id1 ON fmk.f18_rules USING btree (rule_id);


--
-- Name: fakt_doks2_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_doks2_id1 ON fmk.fakt_doks2 USING btree (idfirma, idtipdok, brdok);


--
-- Name: fakt_doks_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_doks_datdok ON fmk.fakt_doks USING btree (datdok);


--
-- Name: fakt_doks_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_doks_id1 ON fmk.fakt_doks USING btree (idfirma, idtipdok, brdok, datdok, idpartner);


--
-- Name: fakt_fakt_atributi_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_fakt_atributi_id1 ON fmk.fakt_fakt_atributi USING btree (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: fakt_fakt_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_fakt_datdok ON fmk.fakt_fakt USING btree (datdok);


--
-- Name: fakt_fakt_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_fakt_id1 ON fmk.fakt_fakt USING btree (idfirma, idtipdok, brdok, rbr, idpartner);


--
-- Name: fakt_ftxt_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_ftxt_id1 ON fmk.fakt_ftxt USING btree (id);


--
-- Name: fakt_gen_ug_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_gen_ug_id1 ON fmk.fakt_gen_ug USING btree (dat_obr, dat_gen);


--
-- Name: fakt_gen_ug_p_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_gen_ug_p_id1 ON fmk.fakt_gen_ug_p USING btree (dat_obr, idpartner, id_ugov);


--
-- Name: fakt_objekti_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_objekti_id1 ON fmk.fakt_objekti USING btree (id);


--
-- Name: fakt_rugov_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_rugov_id1 ON fmk.fakt_rugov USING btree (id, idroba);


--
-- Name: fakt_ugov_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_ugov_id1 ON fmk.fakt_ugov USING btree (id, idpartner);


--
-- Name: fakt_upl_date; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fakt_upl_date ON fmk.fakt_upl USING btree (idpartner, datupl);


--
-- Name: fin_anal_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_anal_id1 ON fmk.fin_anal USING btree (idfirma, idvn, brnal, rbr);


--
-- Name: fin_budzet_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_budzet_id1 ON fmk.fin_budzet USING btree (idrj, idkonto);


--
-- Name: fin_buiz_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_buiz_id1 ON fmk.fin_buiz USING btree (id);


--
-- Name: fin_fin_atributi_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_fin_atributi_id1 ON fmk.fin_fin_atributi USING btree (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: fin_fond_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_fond_id1 ON fmk.fin_fond USING btree (id);


--
-- Name: fin_funk_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_funk_id1 ON fmk.fin_funk USING btree (id);


--
-- Name: fin_izvje_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_izvje_id1 ON fmk.fin_izvje USING btree (id);


--
-- Name: fin_koliz_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_koliz_id1 ON fmk.fin_koliz USING btree (id);


--
-- Name: fin_koniz_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_koniz_id1 ON fmk.fin_koniz USING btree (id);


--
-- Name: fin_nalog_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_nalog_id1 ON fmk.fin_nalog USING btree (idfirma, idvn, brnal);


--
-- Name: fin_parek_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_parek_id1 ON fmk.fin_parek USING btree (idpartija);


--
-- Name: fin_sint_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_sint_id1 ON fmk.fin_sint USING btree (idfirma, idvn, brnal, rbr);


--
-- Name: fin_suban_brnal; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_brnal ON fmk.fin_suban USING btree (idfirma, idvn, brnal, rbr);


--
-- Name: fin_suban_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_datdok ON fmk.fin_suban USING btree (datdok);


--
-- Name: fin_suban_datval_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_datval_datdok ON fmk.fin_suban USING btree (idfirma, idkonto, idpartner, COALESCE(datval, datdok), brdok);


--
-- Name: fin_suban_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_id1 ON fmk.fin_suban USING btree (idfirma, idvn, brnal, rbr);


--
-- Name: fin_suban_konto_partner; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_konto_partner ON fmk.fin_suban USING btree (idfirma, idkonto, idpartner, datdok);


--
-- Name: fin_suban_konto_partner_brdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_konto_partner_brdok ON fmk.fin_suban USING btree (idfirma, idkonto, idpartner, brdok, datdok);


--
-- Name: fin_suban_otvrst; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_suban_otvrst ON fmk.fin_suban USING btree (btrim((idkonto)::text), btrim((idpartner)::text), btrim((brdok)::text));


--
-- Name: fin_ulimit_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_ulimit_id1 ON fmk.fin_ulimit USING btree (id);


--
-- Name: fin_zagli_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX fin_zagli_id1 ON fmk.fin_zagli USING btree (id, x1, y1);


--
-- Name: jprih_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX jprih_id ON fmk.jprih USING btree (id, idops, idkan, idn0, racun);


--
-- Name: jprih_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX jprih_naz ON fmk.jprih USING btree (naz);


--
-- Name: kalk_doks2_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_doks2_id1 ON fmk.kalk_doks2 USING btree (idfirma, idvd, brdok);


--
-- Name: kalk_doks_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_doks_datdok ON fmk.kalk_doks USING btree (datdok);


--
-- Name: kalk_doks_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_doks_id1 ON fmk.kalk_doks USING btree (idfirma, idvd, brdok, mkonto, pkonto);


--
-- Name: kalk_kalk_atributi_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_kalk_atributi_id1 ON fmk.kalk_kalk_atributi USING btree (idfirma, idtipdok, brdok, rbr, atribut);


--
-- Name: kalk_kalk_datdok; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_kalk_datdok ON fmk.kalk_kalk USING btree (datdok);


--
-- Name: kalk_kalk_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_kalk_id1 ON fmk.kalk_kalk USING btree (idfirma, idvd, brdok, rbr, mkonto, pkonto);


--
-- Name: kalk_kalk_mkonto; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_kalk_mkonto ON fmk.kalk_kalk USING btree (idfirma, mkonto, idroba);


--
-- Name: kalk_kalk_pkonto; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalk_kalk_pkonto ON fmk.kalk_kalk USING btree (idfirma, pkonto, idroba);


--
-- Name: kalvir_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kalvir_id ON fmk.kalvir USING btree (id);


--
-- Name: kbenef_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kbenef_id1 ON fmk.kbenef USING btree (id);


--
-- Name: koncij_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX koncij_id1 ON fmk.koncij USING btree (id);


--
-- Name: konto_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX konto_id ON fmk.konto USING btree (id);


--
-- Name: konto_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX konto_naz ON fmk.konto USING btree (naz);


--
-- Name: kred_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX kred_id1 ON fmk.kred USING btree (id);


--
-- Name: ks_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ks_id1 ON fmk.ks USING btree (id);


--
-- Name: ld_ld_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_ld_id1 ON fmk.ld_ld USING btree (idrj, godina, mjesec, obr, idradn);


--
-- Name: ld_norsiht_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_norsiht_id1 ON fmk.ld_norsiht USING btree (id);


--
-- Name: ld_obracuni_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_obracuni_id1 ON fmk.ld_obracuni USING btree (rj, godina, mjesec, obr, dat_ispl);


--
-- Name: ld_parobr_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_parobr_id1 ON fmk.ld_parobr USING btree (id);


--
-- Name: ld_pk_data_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_pk_data_id1 ON fmk.ld_pk_data USING btree (idradn);


--
-- Name: ld_pk_radn_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_pk_radn_id1 ON fmk.ld_pk_radn USING btree (idradn);


--
-- Name: ld_radkr_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_radkr_id1 ON fmk.ld_radkr USING btree (idradn, idkred, mjesec, godina);


--
-- Name: ld_radn_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_radn_id1 ON fmk.ld_radn USING btree (id);


--
-- Name: ld_radsat_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_radsat_id1 ON fmk.ld_radsat USING btree (idradn);


--
-- Name: ld_radsiht_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_radsiht_id1 ON fmk.ld_radsiht USING btree (godina, mjesec, idradn);


--
-- Name: ld_rj_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_rj_id ON fmk.ld_rj USING btree (id);


--
-- Name: ld_rj_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_rj_naz ON fmk.ld_rj USING btree (naz);


--
-- Name: ld_tprsiht_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ld_tprsiht_id1 ON fmk.ld_tprsiht USING btree (id);


--
-- Name: ldvirm_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ldvirm_id ON fmk.ldvirm USING btree (id);


--
-- Name: log_l_time_idx; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX log_l_time_idx ON fmk.log USING btree (l_time);


--
-- Name: log_user_code_idx; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX log_user_code_idx ON fmk.log USING btree (user_code);


--
-- Name: lokal_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX lokal_id1 ON fmk.lokal USING btree (id);


--
-- Name: lokal_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX lokal_id2 ON fmk.lokal USING btree (id_str);


--
-- Name: mat_anal_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_anal_id1 ON fmk.mat_anal USING btree (idfirma, idkonto, datnal);


--
-- Name: mat_anal_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_anal_id2 ON fmk.mat_anal USING btree (idfirma, idvn, brnal, idkonto);


--
-- Name: mat_karkon_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_karkon_id1 ON fmk.mat_karkon USING btree (id);


--
-- Name: mat_nalog_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_nalog_id1 ON fmk.mat_nalog USING btree (idfirma, idvn, brnal);


--
-- Name: mat_sint_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_sint_id1 ON fmk.mat_sint USING btree (idfirma, idkonto, datnal);


--
-- Name: mat_sint_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_sint_id2 ON fmk.mat_sint USING btree (idfirma, idvn, brnal, idkonto);


--
-- Name: mat_suban_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_suban_id1 ON fmk.mat_suban USING btree (idfirma, idroba, datdok);


--
-- Name: mat_suban_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_suban_id2 ON fmk.mat_suban USING btree (idfirma, idpartner, idroba);


--
-- Name: mat_suban_id3; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_suban_id3 ON fmk.mat_suban USING btree (idfirma, idkonto, idroba, datdok);


--
-- Name: mat_suban_id4; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_suban_id4 ON fmk.mat_suban USING btree (idfirma, idvn, brnal, rbr);


--
-- Name: mat_suban_id5; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX mat_suban_id5 ON fmk.mat_suban USING btree (idfirma, idkonto, idpartner, idroba, datdok);


--
-- Name: metric_name_key; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX metric_name_key ON fmk.metric USING btree (metric_name);


--
-- Name: objekti_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX objekti_id1 ON fmk.objekti USING btree (id);


--
-- Name: ops_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ops_id1 ON fmk.ops USING btree (id);


--
-- Name: ops_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX ops_id2 ON fmk.ops USING btree (naz);


--
-- Name: os_amort_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX os_amort_id1 ON fmk.os_amort USING btree (id);


--
-- Name: os_k1_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX os_k1_id1 ON fmk.os_k1 USING btree (id);


--
-- Name: os_os_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX os_os_id1 ON fmk.os_os USING btree (id);


--
-- Name: os_promj_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX os_promj_id1 ON fmk.os_promj USING btree (id, datum);


--
-- Name: os_reval_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX os_reval_id1 ON fmk.os_reval USING btree (id);


--
-- Name: partn_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX partn_id ON fmk.partn USING btree (id);


--
-- Name: partn_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX partn_naz ON fmk.partn USING btree (naz);


--
-- Name: pkonto_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pkonto_id1 ON fmk.pkonto USING btree (id);


--
-- Name: pkonto_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pkonto_id2 ON fmk.pkonto USING btree (tip);


--
-- Name: por_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX por_id1 ON fmk.por USING btree (id);



--
-- Name: pos_dokspf_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_dokspf_id1 ON fmk.pos_dokspf USING btree (idpos, idvd, datum, brdok);


--
-- Name: pos_kase_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_kase_id1 ON fmk.pos_kase USING btree (id);


--
-- Name: pos_odj_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_odj_id1 ON fmk.pos_odj USING btree (id);


--
-- Name: pos_osob_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_osob_id1 ON fmk.pos_osob USING btree (korsif);


--
-- Name: pos_osob_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_osob_id2 ON fmk.pos_osob USING btree (id);



--
-- Name: pos_promvp_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_promvp_id1 ON fmk.pos_promvp USING btree (datum);


--
-- Name: pos_strad_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_strad_id1 ON fmk.pos_strad USING btree (id);


--
-- Name: pos_strad_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX pos_strad_id2 ON fmk.pos_strad USING btree (naz);


--
-- Name: refer_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX refer_id1 ON fmk.refer USING btree (id);


--
-- Name: relation_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX relation_id1 ON fmk.relation USING btree (tfrom, tto, tfromid);


--
-- Name: rj_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX rj_id ON fmk.rj USING btree (id);


--
-- Name: rj_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX rj_naz ON fmk.rj USING btree (naz);


--
-- Name: roba_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX roba_id ON fmk.roba USING btree (id);


--
-- Name: roba_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX roba_naz ON fmk.roba USING btree (naz);


--
-- Name: sast_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sast_id1 ON fmk.sast USING btree (id, id2);


--
-- Name: sifk_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifk_id ON fmk.sifk USING btree (id, sort, naz);


--
-- Name: sifk_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifk_id2 ON fmk.sifk USING btree (id, oznaka);


--
-- Name: sifk_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifk_naz ON fmk.sifk USING btree (naz);


--
-- Name: sifradob_idx; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifradob_idx ON fmk.roba USING btree (btrim((sifradob)::text));


--
-- Name: sifv_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifv_id1 ON fmk.sifv USING btree (id, oznaka, idsif, naz);


--
-- Name: sifv_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifv_id2 ON fmk.sifv USING btree (id, idsif);


--
-- Name: sifv_id3; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sifv_id3 ON fmk.sifv USING btree (id, oznaka, naz);


--
-- Name: sii_promj_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sii_promj_id1 ON fmk.sii_promj USING btree (id, datum);


--
-- Name: sii_sii_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX sii_sii_id1 ON fmk.sii_sii USING btree (id);


--
-- Name: strspr_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX strspr_id1 ON fmk.strspr USING btree (id);


--
-- Name: tarifa_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tarifa_id ON fmk.tarifa USING btree (id);


--
-- Name: tarifa_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tarifa_naz ON fmk.tarifa USING btree (naz);


--
-- Name: tdok_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tdok_id1 ON fmk.tdok USING btree (id);


--
-- Name: tdok_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tdok_id2 ON fmk.tdok USING btree (naz);


--
-- Name: tippr2_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tippr2_id1 ON fmk.tippr2 USING btree (id);


--
-- Name: tippr_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tippr_id1 ON fmk.tippr USING btree (id);


--
-- Name: tnal_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tnal_id1 ON fmk.tnal USING btree (id);


--
-- Name: tnal_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX tnal_id2 ON fmk.tnal USING btree (naz);


--
-- Name: trfp2_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX trfp2_id1 ON fmk.trfp2 USING btree (idvd, shema, idkonto);


--
-- Name: trfp3_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX trfp3_id1 ON fmk.trfp3 USING btree (shema, idkonto);


--
-- Name: trfp_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX trfp_id1 ON fmk.trfp USING btree (id);


--
-- Name: valute_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX valute_id ON fmk.valute USING btree (id);


--
-- Name: valute_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX valute_id2 ON fmk.valute USING btree (tip, id, datum);


--
-- Name: valute_id3; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX valute_id3 ON fmk.valute USING btree (id, datum);


--
-- Name: valute_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX valute_naz ON fmk.valute USING btree (naz);


--
-- Name: vposla_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vposla_id1 ON fmk.vposla USING btree (id);


--
-- Name: vprih_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vprih_id1 ON fmk.vprih USING btree (id);


--
-- Name: vrprim_id; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vrprim_id ON fmk.vrprim USING btree (id);


--
-- Name: vrprim_idkonto; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vrprim_idkonto ON fmk.vrprim USING btree (idkonto, idpartner);


--
-- Name: vrprim_naz; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vrprim_naz ON fmk.vrprim USING btree (naz);


--
-- Name: vrstep_id1; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vrstep_id1 ON fmk.vrstep USING btree (id);


--
-- Name: vrstep_id2; Type: INDEX; Schema: fmk; Owner: admin
--

CREATE INDEX vrstep_id2 ON fmk.vrstep USING btree (naz);


--
-- Name: fin_suban suban_insert_upate_delete; Type: TRIGGER; Schema: fmk; Owner: admin
--

CREATE TRIGGER suban_insert_upate_delete AFTER INSERT OR DELETE OR UPDATE ON fmk.fin_suban FOR EACH ROW EXECUTE PROCEDURE public.on_suban_insert_update_delete();


--
-- Name: kalk_kalk trig_cleanup_konto_roba_stanje; Type: TRIGGER; Schema: fmk; Owner: admin
--

CREATE TRIGGER trig_cleanup_konto_roba_stanje BEFORE INSERT OR DELETE OR UPDATE ON fmk.kalk_kalk
   FOR EACH ROW EXECUTE PROCEDURE public.cleanup_konto_roba_stanje();


--
-- Name: fakt_fakt_atributi brdok; Type: FK CONSTRAINT; Schema: fmk; Owner: admin
--

ALTER TABLE ONLY fmk.fakt_fakt_atributi
    ADD CONSTRAINT brdok FOREIGN KEY (idfirma, idtipdok, brdok, rbr) REFERENCES fmk.fakt_fakt(idfirma, idtipdok, brdok, rbr);


--
-- Name: SCHEMA fmk; Type: ACL; Schema: -; Owner: admin
--

GRANT ALL ON SCHEMA fmk TO xtrole;

--
-- Name: TABLE adres; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.adres TO xtrole;

--
-- Name: TABLE banke; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.banke TO xtrole;


--
-- Name: SEQUENCE brojac_brojac_id_seq; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON SEQUENCE fmk.brojac_brojac_id_seq TO xtrole;


--
-- Name: TABLE dest; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.dest TO xtrole;


--
-- Name: TABLE dopr; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.dopr TO xtrole;


--
-- Name: TABLE epdv_kif; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.epdv_kif TO xtrole;


--
-- Name: TABLE epdv_kuf; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.epdv_kuf TO xtrole;


--
-- Name: TABLE epdv_pdv; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.epdv_pdv TO xtrole;


--
-- Name: TABLE epdv_sg_kif; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.epdv_sg_kif TO xtrole;


--
-- Name: TABLE epdv_sg_kuf; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.epdv_sg_kuf TO xtrole;


--
-- Name: TABLE f18_rules; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.f18_rules TO xtrole;


--
-- Name: TABLE fakt_doks; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_doks TO xtrole;


--
-- Name: TABLE fakt_doks2; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_doks2 TO xtrole;


--
-- Name: TABLE fakt_fakt; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_fakt TO xtrole;


--
-- Name: TABLE fakt_fakt_atributi; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_fakt_atributi TO xtrole;


--
-- Name: TABLE fakt_ftxt; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_ftxt TO xtrole;


--
-- Name: TABLE fakt_gen_ug; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_gen_ug TO xtrole;


--
-- Name: TABLE fakt_gen_ug_p; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_gen_ug_p TO xtrole;


--
-- Name: TABLE fakt_objekti; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_objekti TO xtrole;


--
-- Name: TABLE fakt_rugov; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_rugov TO xtrole;

--
-- Name: TABLE fakt_ugov; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_ugov TO xtrole;

--
-- Name: TABLE fakt_upl; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fakt_upl TO xtrole;

--
-- Name: TABLE fin_anal; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_anal TO xtrole;

--
-- Name: TABLE fin_budzet; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_budzet TO xtrole;


--
-- Name: TABLE fin_buiz; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_buiz TO xtrole;


--
-- Name: TABLE fin_fin_atributi; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_fin_atributi TO xtrole;


--
-- Name: TABLE fin_fond; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_fond TO xtrole;


--
-- Name: TABLE fin_funk; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_funk TO xtrole;


--
-- Name: TABLE fin_izvje; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_izvje TO xtrole;


--
-- Name: TABLE fin_koliz; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_koliz TO xtrole;


--
-- Name: TABLE fin_koniz; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_koniz TO xtrole;


--
-- Name: TABLE fin_nalog; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_nalog TO xtrole;


--
-- Name: TABLE fin_parek; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_parek TO xtrole;


--
-- Name: TABLE fin_sint; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_sint TO xtrole;


--
-- Name: TABLE fin_suban; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_suban TO xtrole;


--
-- Name: TABLE fin_ulimit; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_ulimit TO xtrole;


--
-- Name: TABLE fin_zagli; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.fin_zagli TO xtrole;


--
-- Name: TABLE jprih; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.jprih TO xtrole;


--
-- Name: TABLE kalk_doks; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kalk_doks TO xtrole;


--
-- Name: TABLE kalk_doks2; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kalk_doks2 TO xtrole;

--
-- Name: TABLE kalk_kalk; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kalk_kalk TO xtrole;

--
-- Name: TABLE kalk_kalk_atributi; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kalk_kalk_atributi TO xtrole;


--
-- Name: TABLE kalvir; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kalvir TO xtrole;


--
-- Name: TABLE kbenef; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kbenef TO xtrole;


--
-- Name: TABLE koncij; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.koncij TO xtrole;


--
-- Name: TABLE konto; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.konto TO xtrole;


--
-- Name: TABLE kred; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.kred TO xtrole;


--
-- Name: TABLE ks; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ks TO xtrole;


--
-- Name: TABLE ld_ld; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_ld TO xtrole;

--
-- Name: TABLE ld_norsiht; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_norsiht TO xtrole;

--
-- Name: TABLE ld_obracuni; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_obracuni TO xtrole;


--
-- Name: TABLE ld_parobr; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_parobr TO xtrole;


--
-- Name: TABLE ld_pk_data; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_pk_data TO xtrole;


--
-- Name: TABLE ld_pk_radn; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_pk_radn TO xtrole;


--
-- Name: TABLE ld_radkr; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_radkr TO xtrole;


--
-- Name: TABLE ld_radn; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_radn TO xtrole;


--
-- Name: TABLE ld_radsat; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_radsat TO xtrole;


--
-- Name: TABLE ld_radsiht; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_radsiht TO xtrole;

--
-- Name: TABLE ld_rj; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_rj TO xtrole;


--
-- Name: TABLE ld_tprsiht; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ld_tprsiht TO xtrole;


--
-- Name: TABLE ldvirm; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ldvirm TO xtrole;


--
-- Name: TABLE log; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.log TO xtrole;


--
-- Name: SEQUENCE log_id_seq; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON SEQUENCE fmk.log_id_seq TO xtrole;


--
-- Name: TABLE lokal; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.lokal TO xtrole;


--
-- Name: TABLE mat_anal; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.mat_anal TO xtrole;


--
-- Name: TABLE mat_karkon; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.mat_karkon TO xtrole;


--
-- Name: TABLE mat_nalog; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.mat_nalog TO xtrole;


--
-- Name: TABLE mat_sint; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.mat_sint TO xtrole;


--
-- Name: TABLE mat_suban; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.mat_suban TO xtrole;


--
-- Name: TABLE metric; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.metric TO xtrole;


--
-- Name: SEQUENCE metric_metric_id_seq; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON SEQUENCE fmk.metric_metric_id_seq TO xtrole;


--
-- Name: TABLE objekti; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.objekti TO xtrole;


--
-- Name: TABLE ops; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.ops TO xtrole;


--
-- Name: TABLE os_amort; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.os_amort TO xtrole;


--
-- Name: TABLE os_k1; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.os_k1 TO xtrole;


--
-- Name: TABLE os_os; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.os_os TO xtrole;


--
-- Name: TABLE os_promj; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.os_promj TO xtrole;


--
-- Name: TABLE os_reval; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.os_reval TO xtrole;


--
-- Name: TABLE partn; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.partn TO xtrole;


--
-- Name: TABLE pkonto; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pkonto TO xtrole;


--
-- Name: TABLE por; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.por TO xtrole;


--
-- Name: TABLE pos_doks; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_doks TO xtrole;


--
-- Name: TABLE pos_dokspf; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_dokspf TO xtrole;


--
-- Name: TABLE pos_kase; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_kase TO xtrole;


--
-- Name: TABLE pos_odj; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_odj TO xtrole;


--
-- Name: TABLE pos_osob; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_osob TO xtrole;


--
-- Name: TABLE pos_promvp; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_promvp TO xtrole;


--
-- Name: TABLE pos_strad; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.pos_strad TO xtrole;


--
-- Name: TABLE refer; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.refer TO xtrole;


--
-- Name: TABLE relation; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.relation TO xtrole;


--
-- Name: TABLE rj; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.rj TO xtrole;


--
-- Name: TABLE roba; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.roba TO xtrole;


--
-- Name: TABLE sast; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.sast TO xtrole;



--
-- Name: TABLE sifk; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.sifk TO xtrole;


--
-- Name: TABLE sifv; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.sifv TO xtrole;


--
-- Name: TABLE sii_promj; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.sii_promj TO xtrole;


--
-- Name: TABLE sii_sii; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.sii_sii TO xtrole;


--
-- Name: TABLE strspr; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.strspr TO xtrole;


--
-- Name: TABLE tarifa; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.tarifa TO xtrole;


--
-- Name: TABLE tdok; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.tdok TO xtrole;


--
-- Name: TABLE tippr; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.tippr TO xtrole;


--
-- Name: TABLE tippr2; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.tippr2 TO xtrole;


--
-- Name: TABLE tnal; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.tnal TO xtrole;


--
-- Name: TABLE trfp; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.trfp TO xtrole;


--
-- Name: TABLE trfp2; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.trfp2 TO xtrole;


--
-- Name: TABLE trfp3; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.trfp3 TO xtrole;


--
-- Name: TABLE valute; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.valute TO xtrole;


--
-- Name: TABLE vposla; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.vposla TO xtrole;


--
-- Name: TABLE vprih; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.vprih TO xtrole;


--
-- Name: TABLE vrprim; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.vrprim TO xtrole;


--
-- Name: TABLE vrstep; Type: ACL; Schema: fmk; Owner: admin
--

GRANT ALL ON TABLE fmk.vrstep TO xtrole;
