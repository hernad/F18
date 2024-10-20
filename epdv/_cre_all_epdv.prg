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

FUNCTION cre_all_epdv( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

   // KUF, KIF, PDV
   // ----------------------------------

   aDbf := get_kuf_fields()

/*
   _alias := "KUF"
   _table_name := "epdv_kuf"
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "datum", "dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "l_datum", "lock+dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "g_r_br", "STR(g_r_br,6,0)+dtos(datum)", _alias )
   CREATE_INDEX( "BR_DOK", "STR(BR_DOK,6,0)+STR(r_br,6,0)", _alias )
   CREATE_INDEX( "BR_DOK2", "STR(BR_DOK,6,0)+dtos(datum)", _alias )
   AFTER_CREATE_INDEX
*/

   aDbf := get_kif_fields()

/*
   _alias := "KIF"
   _table_name := "epdv_kif"
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "datum", "dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "l_datum", "lock+dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "g_r_br", "STR(g_r_br,6,0)+dtos(datum)", _alias )
   CREATE_INDEX( "BR_DOK", "STR(BR_DOK,6,0)+STR(r_br,6,0)", _alias )
   CREATE_INDEX( "BR_DOK2", "STR(BR_DOK,6,0)+dtos(datum)", _alias )
   AFTER_CREATE_INDEX
*/

   aDbf := epdv_get_pdv_fields()

/*
   _alias := "PDV"
   _table_name := "epdv_pdv"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "period", "DTOS(per_od)+DTOS(per_do)", _alias )
   AFTER_CREATE_INDEX
*/

   // P_KIF, P_KUF
   // ------------------------------
   //  polja za p_kuf
   aDbf := get_kuf_fields()

   _alias := "P_KUF"
   _table_name := "epdv_p_kuf"
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "datum", "dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "l_datum", "lock+dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "br_dok", "STR(br_dok,6,0)+STR(r_br,6,0)", _alias )


   aDbf := get_kif_fields()
   _alias := "P_KIF"
   _table_name := "epdv_p_kif"
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "datum", "dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "l_datum", "lock+dtos(datum)+src_br_2", _alias )
   CREATE_INDEX( "br_dok", "STR(br_dok,6,0)+STR(r_br,6,0)", _alias )


/*
   // SG_KIF, SG_KUF
   // --------------------------------------

   aDbf := get_sg_fields() //  polja za sg_kuf
   _alias := "SG_KUF"
   _table_name := "epdv_sg_kuf"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "id", "id", _alias )
   CREATE_INDEX( "naz", "id", _alias )
   AFTER_CREATE_INDEX


   aDbf := get_sg_fields()
   _alias := "SG_KIF"
   _table_name := "epdv_sg_kif"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "id", "id", _alias )
   CREATE_INDEX( "naz", "id", _alias )
   AFTER_CREATE_INDEX
*/

   RETURN .T.



FUNCTION epdv_get_pdv_fields()

   LOCAL aDbf

   aDbf := {}
   // datum kreiranja
   AAdd( aDBf, { "datum_1", "D",   8,  0 } )

   // datum posljednje ispravke
   AAdd( aDBf, { "datum_2", "D",   8,  0 } )

   // datum zakljucavanja
   AAdd( aDBf, { "datum_3", "D",   8,  0 } )

   // identifikacijski broj
   AAdd( aDBf, { "id_br", "C",   12,  0 } )

   // period od
   AAdd( aDBf, { "per_od", "D",   8,  0 } )
   // do
   AAdd( aDBf, { "per_do", "D",   8,  0 } )

   // naziv poreskog obveznika
   AAdd( aDBf, { "po_naziv", "C",   60,  0 } )

   // adresa
   AAdd( aDBf, { "po_adresa", "C",   60,  0 } )

   // ptt broj
   AAdd( aDBf, { "po_ptt", "C",   10,  0 } )
   // mjesto
   AAdd( aDBf, { "po_mjesto", "C",   40,  0 } )

   // 11 - oporezive isporuke
   AAdd( aDBf, { "i_opor", "N",   18,  2 } )
   // 12 - isporuke izvoz
   AAdd( aDBf, { "i_izvoz", "N",   18,  2 } )
   // 13 - ostale neoporezive isporuke
   AAdd( aDBf, { "i_neop", "N",   18,  2 } )


   // 21 - sve nabavke osim uvoza i poljoprivrede
   AAdd( aDBf, { "u_nab_21", "N",   18,  2 } )

   // 22  - uvoz
   AAdd( aDBf, { "u_uvoz", "N",   18,  2 } )

   // 21 - nabavke od poljoprivrednika
   AAdd( aDBf, { "u_nab_23", "N",   18,  2 } )


   // 31 - pdv za registrovane pdv obveznike
   AAdd( aDBf, { "i_pdv_r", "N",   18,  2 } )

   // 32 - pdv za neregistovane, federacija
   AAdd( aDBf, { "i_pdv_nr1", "N",   18,  2 } )
   // 33 - rs
   AAdd( aDBf, { "i_pdv_nr2", "N",   18,  2 } )
   // 34 - bdistrikt
   AAdd( aDBf, { "i_pdv_nr3", "N",   18,  2 } )
   // ne koristi se
   AAdd( aDBf, { "i_pdv_nr4", "N",   18,  2 } )


   // 41 - ulazni pdv, sve osim uvoza i poljoprivrednika
   AAdd( aDBf, { "u_pdv_41", "N",   18,  2 } )

   // 42 - uvoz
   AAdd( aDBf, { "u_pdv_uv", "N",   18,  2 } )

   // 43 -  pausalna naknada za poljoprivrednike, oporezivi dio pdv
   AAdd( aDBf, { "u_pdv_43", "N",   18,  2 } )


   // preneseno iz predhodnog perioda
   AAdd( aDBf, { "u_pdv_pp", "N",   18,  2 } )

   // 51 izlazni pdv ukupno
   AAdd( aDBf, { "i_pdv_uk", "N",   18,  2 } )

   // 61 = u_pdv_pp + u_pdv_41 + u_pdv_uv + u_pdv_43
   AAdd( aDBf, { "u_pdv_uk", "N",   18,  2 } )


   // 71 obaveza za uplatu, ako ima
   // moze biti + (uplatiti) ili - (povrat)
   AAdd( aDBf, { "pdv_uplati", "N",   18,  2 } )

   // 80 zahtjev za povrat
   // D - da
   // N - ne
   AAdd( aDBf, { "pdv_povrat", "C",   1,  0 } )


   // potpis mjesto
   AAdd( aDBf, { "pot_mjesto", "C",   40,  0 } )
   // potpis datum
   AAdd( aDBf, { "pot_datum",  "D",   8,  0 } )
   // potpis obveznik pdv-a
   AAdd( aDBf, { "pot_ob",  "C",   80,  0 } )


   AAdd( aDBf, { "lock",  "C",   1,  0 } )  // zakljucan obracun

   RETURN aDbf


// ------------------------------------------------------
// kif struktura
// ------------------------------------------------------
FUNCTION get_kif_fields()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "datum", "D",   8,  0 } )

   // ne koristi se
   AAdd( aDBf, { "datum_2", "D",   8,  0 } )

   // 1 - FIN
   // 2 - KALK
   // 3 - FAKT
   // 4 - OS
   // 5 - SII
   AAdd( aDBf, { "src", "C",   1,  0 } )

   // tip dokumenta
   //
   AAdd( aDBf, { "td_src", "C",   2,  0 } )

   // podnivo src-a
   // ako nam je to potrebno, ako nije empty
   AAdd( aDBf, { "src_2", "C",   1,  0 } )

   AAdd( aDBf, { "id_tar", "C",   6,  0 } )
   AAdd( aDBf, { "id_part", "C",   6,  0 } )

   // id partner, id broj
   AAdd( aDBf, { "part_idbr", "C",   13,  0 } )

   // kategorija partnera
   // 1-pdv obveznik
   // 2-ne pdv obvezink
   AAdd( aDBf, { "p_kat", "C",   1,  0 } )

   // za ne-pdv obveznike
   // 1-federacija
   // 2-rs
   // 3-distrikt brcko
   AAdd( aDBf, { "p_kat_2", "C",   1,  0 } )


   // source dokument prodajno mjesto
   AAdd( aDBf, { "src_pm", "C",  6,  0 } )

   AAdd( aDBf, { "src_td", "C",  12,  0 } )

   // source dokument broj
   AAdd( aDBf, { "src_br", "C",  12,  0 } )

   // source dokument broj - veza
   // ako slucaj avansne fakture:
   // 05.01 - src_br = 00005,  i_b_pdv = 500 KM  opis=avans 50%
   // nakon toga desi se placanje
   // 12.02 - src_br = 00033 (broj fakture),   src_veza_br = 00005
   // i_b_pdv = 500 KM (placeno po avansnoj fakturi)
   // i_v_b_pdv = 1000 KM (placeno po fakturi)
   // kako vidimo veza broj je broj avansne fakture
   AAdd( aDBf, { "src_veza_br", "C",  12,  0 } )


   // source dokument eksterni broj
   // (br dobavljaca ako je razlicit od brdokumenta)
   AAdd( aDBf, { "src_br_2", "C",  12,  0 } )


   // redni broj stavke unutar dokumenta
   AAdd( aDBf, { "r_br", "N",   6,  0 } )

   // broj kif dokumenta kod knjizenja
   AAdd( aDBf, { "br_dok", "N",   6,  0 } )

   // globalni redni broj kif-a
   AAdd( aDBf, { "g_r_br", "N",   8,  0 } )

   // lock = D - zakljucano i ne moze se renumerisati i mjenjati
   // (osim stavki kao sto je opis itd)
   AAdd( aDBf, { "lock", "C",   1,  0 } )

   // kategorija stavke
   // 1  - dnevni bezgotovinski promet
   // 2  - dnevni gotovinski promet
   // 3  - gotovinski promet bez racuna iz clana 120 pravilnika ZPDV
   // 4  - racun za isporuke bez naknade ili uz licni popust
   // 5  - naknadne ispravke racuna
   AAdd( aDBf, { "kat", "C",   1,  0 } )

   // kategorija 2 stavke
   // 1  - izlazne fakture PDV obveznicima
   // 2  - izlazne fakture ne-PDV obveznicima
   // 3  - izlazne fakture izvoz, oslobodjen od pdv-a
   // 4  - izlazne fakture oslobodjene od PDV-a po ostalim osnovama
   // 5  - primljeni avansi - avansne fakture
   // 6  -  izvanposlovne svrhe
   AAdd( aDBf, { "kat_2", "C",   1,  0 } )

   // opis stavke
   AAdd( aDBf, { "opis", "C",   160,  0 } )

   // iznos bez pdv-a - osnovica
   AAdd( aDBf, { "i_b_pdv", "N",   16,  2 } )
   // pdv
   AAdd( aDBf, { "i_pdv", "N",   16,  2 } )


   // vezna stavka, iznos bez pdv-a - ako imamo veznu stavku
   // (pogledati gore primjer avansne fakture)
   AAdd( aDBf, { "i_v_b_pdv", "N",   16,  2 } )
   AAdd( aDBf, { "i_v_pdv", "N",   16,  2 } )


   // status stavke
   // " " - nepoznato
   // 1 - nije placeno
   // 2 - placeno
   AAdd( aDBf, { "status", "C",   1,  0 } )

   AAdd( aDBf, { "part_kat", "C",   1,  0 } )

   // kategorija partnera
   // shema se primjenjuje samo za odredjenu kategoriju partnera
   AAdd( aDBf, { "kat_p", "C",   1,  0 } )
   AAdd( aDBf, { "kat_p_2", "C",   1,  0 } )

   RETURN aDbf


// ------------------------------------------------------
// kuf struktura
// ------------------------------------------------------
FUNCTION get_kuf_fields()

   LOCAL aDbf

   aDbf := {}
   AAdd( aDBf, { "datum", "D",   8,  0 } )

   // ne koristi se
   AAdd( aDBf, { "datum_2", "D",   8,  0 } )

   // 1 - FIN
   // 4 - OS
   // 5 - SII
   AAdd( aDBf, { "src", "C",   1,  0 } )

   // tip dokumenta
   //
   AAdd( aDBf, { "td_src", "C",   2,  0 } )

   // podnivo source-a
   // ako nam je to potrebno, ako nije empty
   AAdd( aDBf, { "src_2", "C",   1,  0 } )

   AAdd( aDBf, { "id_tar", "C",   6,  0 } )
   AAdd( aDBf, { "id_part", "C",   6,  0 } )

   // id partner, id broj
   AAdd( aDBf, { "part_idbr", "C",   13,  0 } )

   // kategorija partnera
   // 1-pdv obveznik
   // 2-ne pdv obvezink
   AAdd( aDBf, { "p_kat", "C",   1,  0 } )

   // ne koristi se trenutno
   AAdd( aDBf, { "p_kat_2", "C",   1,  0 } )


   AAdd( aDBf, { "src_td", "C",  12,  0 } )

   // source dokument broj
   AAdd( aDBf, { "src_br", "C",  12,  0 } )

   // source dokument broj - veza
   // ako slucaj avansne fakture:
   // 05.01 - src_br = 00005,  i_b_pdv = 500 KM  opis=avans 50%
   // nakon toga desi se placanje
   // 12.02 - src_br = 00033 (broj fakture),   src_veza_br = 00005
   // i_b_pdv = 500 KM (placeno po avansnoj fakturi)
   // i_v_b_pdv = 1000 KM (placeno po fakturi)
   // kako vidimo veza broj je broj avansne fakture
   AAdd( aDBf, { "src_veza_br", "C",  12,  0 } )


   // source dokument eksterni broj
   // (br dobavljaca ako je razlicit od brdokumenta)
   AAdd( aDBf, { "src_br_2", "C",  12,  0 } )


   // redni broj stavke
   AAdd( aDBf, { "r_br", "N",   6,  0 } )

   // broj kuf dokumenta kod knjizenja
   AAdd( aDBf, { "br_dok", "N",   6,  0 } )


   // globalni redni broj kuf-a
   AAdd( aDBf, { "g_r_br", "N",   8,  0 } )

   // lock = D - zakljucano i ne moze se renumerisati i mjenjati
   // (osim stavki kao sto je opis itd)
   AAdd( aDBf, { "lock", "C",   1,  0 } )

   // kategorija stavke
   // 1  - ima pravo na odbitak pdv-a
   // 2  - nema pravo na odbitak
   AAdd( aDBf, { "kat", "C",   1,  0 } )

   // kategorija 2 stavke
   // trenutno se ne koristi
   AAdd( aDBf, { "kat_2", "C",   1,  0 } )

   // opis stavke
   AAdd( aDBf, { "opis", "C",   160,  0 } )

   // iznos bez pdv-a - osnovica
   AAdd( aDBf, { "i_b_pdv", "N",   16,  2 } )
   // pdv
   AAdd( aDBf, { "i_pdv", "N",   16,  2 } )


   // vezna stavka, iznos bez pdv-a - ako imamo veznu stavku
   // (pogledati gore primjer avansne fakture)
   AAdd( aDBf, { "i_v_b_pdv", "N",   16,  2 } )
   AAdd( aDBf, { "i_v_pdv", "N",   16,  2 } )


   // status stavke
   // " " - nepoznato
   // 1 - nije placeno
   // 2 - placeno
   AAdd( aDBf, { "status", "C",   1,  0 } )

   AAdd( aDBf, { "part_kat", "C",   1,  0 } )

   // kategorija partnera
   // shema se primjenjuje samo za odredjenu kategoriju partnera
   AAdd( aDBf, { "kat_p", "C",   1,  0 } )
   AAdd( aDBf, { "kat_p_2", "C",   1,  0 } )

   RETURN aDbf

// -----------------------------
// gen shema kuf, kif fields
// -----------------------------
FUNCTION get_sg_fields()

   LOCAL aDbf

   aDbf := {}

   // 0001 - stavka 1, 0002 - stavka 2 itd ...
   AAdd( aDBf, { "id", "C",   4,  0 } )

   // npr: "got. promet prodavnica Tuzla 1"
   AAdd( aDBf, { "naz", "C",   60,  0 } )

   // src - pogledaj g_src_modul(cSrc)
   AAdd( aDBf, { "src", "C",   1,  0 } )

   // tip dokumenta source-a
   AAdd( aDBf, { "td_src", "C",   2,  0 } )

   // source path kumulativ
   AAdd( aDBf, { "s_path", "C",   60,  0 } )
   // ako je potreban i sifrarnik
   AAdd( aDBf, { "s_path_s", "C",   60,  0 } )

   // formula za izracunavanje osnovice - iznos b. pdv
   AAdd( aDBf, { "form_b_pdv", "C",   160,  0 } )

   // formula za izracunavanje PDV-a
   AAdd( aDBf, { "form_pdv", "C",   160,  0 } )

   // tarifa dobra, moze se navesti vise tarifa sa ";"
   AAdd( aDBf, { "id_tar", "C",   160,  0 } )
   // ako se podaci uzimaju iz fin-a, onda nam je konto najbitniji
   // moze se uzeti vise konta iz fin-a
   AAdd( aDBf, { "id_kto", "C",   160,  0 } )

   // "PKONTO", "MKONTO" , "IDKONTO"
   AAdd( aDBf, { "id_kto_naz", "C",   10,  0 } )

   // svaki konto posebno
   // razbij za svaku tarifu posebno, ako ih ima vise
   // D - da
   // N - ne
   AAdd( aDBf, { "razb_tar", "C",   1,  0 } )

   // razbij za svaki konto posebno, ako ih vise ima
   // D - da
   // N - ne
   AAdd( aDBf, { "razb_kto", "C",   1,  0 } )

   // razbij po danima
   // D - da
   // N - ne
   AAdd( aDBf, { "razb_dan", "C",   1,  0 } )

   // kategorija partnera
   // shema se primjenjuje samo za odredjenu kategoriju partnera
   AAdd( aDBf, { "kat_p", "C",   1,  0 } )
   AAdd( aDBf, { "kat_p_2", "C",   1,  0 } )

   // set id tarifa kod kuf/kif stavke
   AAdd( aDBf, { "s_id_tar", "C",   6,  0 } )

   // setuj id partnera
   AAdd( aDBf, { "s_id_part", "C",   6,  0 } )

   // setuj broj dokuumenta
   AAdd( aDBf, { "s_br_dok", "C",   12,  0 } )

   // zaokruzenja
   AAdd( aDBf, { "zaok", "N",   1,  0 } )
   AAdd( aDBf, { "zaok2", "N",   1,  0 } )

   AAdd( aDBf, { "kat_part", "C",   1,  0 } )

   // aktivan
   // D - da
   // N - ne
   AAdd( aDBf, { "aktivan", "C",   1,  0 } )

   RETURN aDbf
