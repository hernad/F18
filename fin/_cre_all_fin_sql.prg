/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*

CREATE TABLE fmk.fin_nalog
(
  idfirma character(2) NOT NULL,
  idvn character(2) NOT NULL,
  brnal character(8) NOT NULL,
  datnal date,
  dugbhd numeric(17,2),
  potbhd numeric(17,2),
  dugdem numeric(15,2),
  potdem numeric(15,2),
  sifra character(6),
  CONSTRAINT fin_nalog_pkey PRIMARY KEY (idfirma, idvn, brnal)
)

*/


/*
-- DROP TABLE fmk.fin_suban;

CREATE TABLE fmk.fin_suban
(
  idfirma character varying(2) NOT NULL,
  idvn character varying(2) NOT NULL,
  brnal character varying(10) NOT NULL,
  idkonto character varying(7),
  idpartner character varying(6),
  rbr character integer NOT NULL,
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
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.fin_suban
  OWNER TO admin;
GRANT ALL ON TABLE fmk.fin_suban TO admin;
GRANT ALL ON TABLE fmk.fin_suban TO xtrole;

*/
