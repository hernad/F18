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
// kreiranje tabela ugovora
// -------------------------------
FUNCTION db_cre_ugov( ver )

   cre_tbl( "UGOV", ver )
   cre_tbl( "RUGOV", ver )
   cre_tbl( "GEN_UG", ver )
   cre_tbl( "GEN_UG_P", ver )
   //cre_tbl( "DEST", ver )

   RETURN .T.



// ------------------------------------------
// interna funkcija za kreiranje tabela
// ------------------------------------------
STATIC FUNCTION cre_tbl( table_name, ver )

   LOCAL aDbf
   LOCAL _alias, _table_name

   // struktura
   DO CASE
   CASE table_name == "UGOV"
      aDbf := a_ugov()
   CASE table_name == "RUGOV"
      aDbf := a_rugov()
   CASE table_name == "GEN_UG"
      aDbf := a_genug()
   CASE table_name == "GEN_UG_P"
      aDbf := a_gug_p()
   CASE table_name == "DEST"
      aDbf := a_dest()
   ENDCASE

   _alias := table_name
   _table_name := Lower( table_name )

   IF !( table_name == "DEST" )
      _table_name := "fakt_" + Lower( table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   // indexi
   DO CASE
   CASE table_name == "UGOV"
      CREATE_INDEX( "ID","Id+idpartner", "UGOV" )
      CREATE_INDEX( "NAZ","idpartner+Id", "UGOV" )
      CREATE_INDEX( "NAZ2","naz", "UGOV" )
      CREATE_INDEX( "PARTNER","IDPARTNER", "UGOV" )
      CREATE_INDEX( "AKTIVAN","AKTIVAN",  "UGOV" )
   CASE table_name == "RUGOV"
      CREATE_INDEX( "ID", "id+idroba+dest", "RUGOV" )
      CREATE_INDEX( "IDROBA", "IdRoba", "RUGOV" )
   CASE table_name == "GEN_UG"
      CREATE_INDEX( "DAT_OBR", "DTOS(DAT_OBR)", "GEN_UG" )
      CREATE_INDEX( "DAT_GEN", "DTOS(DAT_GEN)", "GEN_UG" )
   CASE table_name == "GEN_UG_P"
      CREATE_INDEX( "DAT_OBR", "DTOS(DAT_OBR)+ID_UGOV+IDPARTNER", "GEN_UG_P" )
   CASE table_name == "DEST"
      CREATE_INDEX( "ID", "IDPARTNER + ID", "DEST" )
      CREATE_INDEX( "IDDEST", "ID", "DEST" )
   ENDCASE
   AFTER_CREATE_INDEX

   RETURN .T.


// ---------------------------------------------
// vraca matricu sa tabelom DEST
// ---------------------------------------------
STATIC FUNCTION a_dest()

   LOCAL aDbf := {}

   AAdd( aDBF, { "ID", "C",  6,  0 } )
   AAdd( aDBF, { "IDPartner", "C",  6,  0 } )
   AAdd( aDBF, { "Naziv", "C", 60,  0 } )
   AAdd( aDBF, { "Naziv2", "C", 60,  0 } )
   AAdd( aDBF, { "Mjesto", "C", 20,  0 } )
   AAdd( aDBF, { "Adresa", "C", 40,  0 } )
   AAdd( aDBF, { "Ptt", "C", 10,  0 } )
   AAdd( aDBF, { "Telefon", "C", 20,  0 } )
   AAdd( aDBf, { "Mobitel", "C", 20,  0 } )
   AAdd( aDBf, { "Fax", "C", 20,  0 } )

   RETURN aDbf


// -----------------------------------------
// vraca matricu sa strukturom tabele UGOV
// -----------------------------------------
STATIC FUNCTION a_ugov()

   LOCAL aDbf := {}

   AAdd( aDBF, { "ID", "C", 10,  0 } )
   AAdd( aDBF, { "DatOd", "D",  8,  0 } )
   AAdd( aDBF, { "IDPartner", "C",  6,  0 } )
   AAdd( aDBF, { "DatDo", "D",  8,  0 } )
   AAdd( aDBF, { "Naz", "C", 20,  0 } )
   AAdd( aDBF, { "Vrsta", "C",  1,  0 } )
   AAdd( aDBF, { "IdTipdok", "C",  2,  0 } )
   AAdd( aDBF, { "Aktivan", "C",  1,  0 } )
   AAdd( aDBF, { "LAB_PRN", "C",  1,  0 } )
   AAdd( aDBf, { 'DINDEM', 'C',  3,  0 } )
   AAdd( aDBf, { 'IDTXT', 'C',  2,  0 } )
   AAdd( aDBf, { 'ZAOKR', 'N',  1,  0 } )
   AAdd( aDBf, { 'IDDODTXT', 'C',  2,  0 } )

   AAdd( aDBf, { 'A1', 'N', 12,  2 } )
   AAdd( aDBf, { 'A2', 'N', 12,  2 } )

   AAdd( aDBf, { 'B1', 'N', 12,  2 } )
   AAdd( aDBf, { 'B2', 'N', 12,  2 } )

   AAdd( aDBf, { 'TXT2', 'C',  2,  0 } )
   AAdd( aDBf, { 'TXT3', 'C',  2,  0 } )
   AAdd( aDBf, { 'TXT4', 'C',  2,  0 } )

   // nivo fakturisanja
   AAdd( aDBf, { 'F_NIVO', 'C',  1,  0 } )
   // proizvoljni nivo
   AAdd( aDBf, { 'F_P_D_NIVO', 'N',  5,  0 } )
   // datum zadnjeg obracuna
   AAdd( aDBf, { 'DAT_L_FAKT', 'D',  8,  0 } )
   // destinacija
   AAdd( aDBf, { 'DEF_DEST',   'C',  6,  0 } )

   RETURN aDbf


// ----------------------------------------
// vraca strukturu polja tabele RUGOV
// ----------------------------------------
STATIC FUNCTION a_rugov()

   aDbf := {}

   AAdd( aDBF, { "ID", "C",  10,  0 } )
   AAdd( aDBF, { "IDROBA", "C",  10,  0 } )
   AAdd( aDBF, { "Kolicina", "N",  15,  4 } )
   AAdd( aDBF, { "Cijena", "N",  15,  3 } )
   AAdd( aDBf, { 'Rabat', 'N',   6,  3 } )
   AAdd( aDBf, { 'Porez', 'N',   5,  2 } )
   AAdd( aDBf, { 'K1', 'C',   1,  0 } )
   AAdd( aDBf, { 'K2', 'C',   2,  0 } )
   AAdd( aDBf, { 'DEST', 'C',   6,  0 } )

   RETURN aDbf


// ----------------------------------------
// vraca strukturu polja tabele GEN_UG
// ----------------------------------------
STATIC FUNCTION a_genug()

   aDbf := {}

   // / datum obracuna je kljucni datum -
   // on nam govori na koji se mjesec generacija
   // odnosi
   AAdd( aDBF, { "DAT_OBR", "D",   8,  0 } )

   // datum generacije govori kada je
   // obracun napravljen
   AAdd( aDBF, { "DAT_GEN", "D",   8,  0 } )

   // datum valute za izgenerisane dokumente
   AAdd( aDBF, { "DAT_VAL", "D",   8,  0 } )

   // datum posljednje uplate
   AAdd( aDBF, { "DAT_U_FIN", "D",   8,  0 } )
   // konto kupac
   AAdd( aDBF, { "KTO_KUP", "C",   7,  0 } )
   // konto dobavljac
   AAdd( aDBF, { "KTO_DOB", "C",   7,  0 } )
   // opis
   AAdd( aDBF, { "OPIS", "C", 100,  0 } )
   // broj fakture od
   AAdd( aDBf, { 'BRDOK_OD', 'C',   8,  0 } )
   // broj fakture do
   AAdd( aDBf, { 'BRDOK_DO', 'C',   8,  0 } )
   // broj faktura
   AAdd( aDBf, { 'FAKT_BR', 'N',   5,  0 } )
   // saldo fakturisanja
   AAdd( aDBf, { 'SALDO', 'N',  15,  5 } )
   // saldo pdv-a
   AAdd( aDBf, { 'SALDO_PDV', 'N',  15,  5 } )

   RETURN aDbf


// ----------------------------------------
// vraca strukturu polja tabele GEN_UG_P
// ----------------------------------------
STATIC FUNCTION a_gug_p()

   aDbf := {}

   // datum obracuna
   AAdd( aDBF, { "DAT_OBR", "D",   8,  0 } )

   // partner
   AAdd( aDBF, { "IDPARTNER", "C",   6,  0 } )
   // id ugovora
   AAdd( aDBF, { "ID_UGOV", "C",  10,  0 } )
   // saldo kupca
   AAdd( aDBF, { "SALDO_KUP", "N",  15,  5 } )
   // saldo dobavljaci
   AAdd( aDBF, { "SALDO_DOB", "N",  15,  5 } )
   // datum posljednje uplate kupca
   AAdd( aDBf, { 'D_P_UPL_KUP', 'D',   8,  0 } )
   // datum posljednje promjene kupca
   AAdd( aDBf, { 'D_P_PROM_KUP', 'D',   8,  0 } )
   // datum posljednje promjene dobavljac
   AAdd( aDBf, { 'D_P_PROM_DOB', 'D',   8,  0 } )
   // fakturisanje iznos
   AAdd( aDBF, { "F_IZNOS", "N",  15,  5 } )
   // fakturisanje iznos pdv-a
   AAdd( aDBF, { "F_IZNOS_PDV", "N",  15,  5 } )

   RETURN aDbf

*/

FUNCTION o_ugov_tabele()

   // o_fakt_txt()
   // o_sifk()
   // o_sifv()
   // o_fakt_dbf()
   // o_fakt_doks_dbf()
   // o_roba()
   // o_tarifa()
   // o_partner()
   //o_dest()
  // o_ugov()
   //o_rugov()
   // o_gen_ug()
   // o_gen_ug_p()
   // o_konto()

   RETURN .T.
