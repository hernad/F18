/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION cre_all_pos( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

/*
   // --------------- strad - statusi radnika -----------
   aDbf := {}
   AAdd( aDbf, { "ID",        "C",  2, 0 } )
   AAdd( aDbf, { "NAZ",       "C", 15, 0 } )
   AAdd( aDbf, { "PRIORITET", "C",  1, 0 } )


   _alias := "STRAD"
   _table_name := "pos_strad"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID",  _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   AFTER_CREATE_INDEX
*/

/*

   // ------------ osob - osoblje ------------------------
   aDbf := {}
   AAdd( aDbf, { "ID",        "C",  4, 0 } )
   AAdd( aDbf, { "KORSIF",    "C",  6, 0 } )
   AAdd( aDbf, { "NAZ",       "C", 40, 0 } )
   AAdd( aDbf, { "STATUS",    "C",  2, 0 } )

   _alias := "OSOB"
   _table_name := "pos_osob"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "KorSif", _alias )
   CREATE_INDEX( "NAZ", "ID", _alias )
   AFTER_CREATE_INDEX
*/

   /* --------- kase ------------------------

   aDbf := {}
   AAdd( aDbf, { "ID",     "C",  2, 0 } )
   AAdd( aDbf, { "NAZ",     "C", 15, 0 } )
   AAdd( aDbf, { "PPATH",   "C", 50, 0 } )

   _alias := "KASE"
   _table_name := "pos_kase"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID", _alias )
   AFTER_CREATE_INDEX

   */

   /* ----------- pos_odj

   aDbf := {}
   AAdd( aDbf, { "ID",      "C",  2, 0 } )
   AAdd( aDbf, { "NAZ",      "C", 25, 0 } )
   AAdd( aDbf, { "ZADUZUJE", "C",  1, 0 } )
   AAdd( aDbf, { "IDKONTO",  "C",  7, 0 } )

   _alias := "ODJ"
   _table_name := "pos_odj"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID", _alias )
   AFTER_CREATE_INDEX
*/

/*
   aDbf := {}
   AAdd ( aDbf, { "ID",      "C",  2, 0 } )
   AAdd ( aDbf, { "NAZ",      "C", 25, 0 } )

   _alias := "DIO"
   _table_name := "dio"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX ( "ID", "ID", _alias )
*/


   // --------------------- uredj -------
   aDbf := {}
   AAdd ( aDbf, { "ID", "C",  2, 0 } )
   AAdd ( aDbf, { "NAZ", "C", 30, 0 } )
   AAdd ( aDbf, { "PORT", "C", 10, 0 } )

   _alias := "UREDJ"
   _table_name := "uredj"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX ( "ID", "ID", _alias )
   CREATE_INDEX ( "NAZ", "NAZ", _alias )

   aDbf := {}
   AAdd ( aDbf, { "ID",        "C",  8, 0 } )
   AAdd ( aDbf, { "ID2",       "C",  8, 0 } )
   AAdd ( aDbf, { "KM",        "N",  6, 1 } )

   _alias := "MARS"
   _table_name := "mars"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "ID", "ID", _alias )
   CREATE_INDEX ( "2", "ID+ID2", _alias )


   aDbf := {}
   AAdd ( aDbf, { "DATUM",     "D",  8, 0 } )
   AAdd ( aDbf, { "IDPOS",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDVD",      "C",  2, 0 } )
   AAdd ( aDbf, { "BRDOK",     "C",  FIELD_LEN_POS_BRDOK, 0 } )

   AAdd ( aDbf, { "IDGOST",    "C",  8, 0 } )
   AAdd ( aDbf, { "IDRADNIK",  "C",  4, 0 } )
   AAdd ( aDbf, { "IDVRSTEP",  "C",  2, 0 } )
   AAdd ( aDbf, { "M1",        "C",  1, 0 } )
   AAdd ( aDbf, { "PLACEN",    "C",  1, 0 } )
   AAdd ( aDbf, { "PREBACEN",  "C",  1, 0 } )
   AAdd ( aDbf, { "SMJENA",    "C",  1, 0 } )
   AAdd ( aDbf, { "STO",       "C",  3, 0 } )
   AAdd ( aDbf, { "VRIJEME",   "C",  5, 0 } )

   AAdd ( aDbf, { "C_1",       "C",  6, 0 } )
   AAdd ( aDbf, { "C_2",       "C", 10, 0 } )
   AAdd ( aDbf, { "C_3",       "C", 50, 0 } )

   AAdd ( aDbf, { "FISC_RN",   "N", 10, 0 } )
   // AAdd ( aDbf, { "ZAK_BR",    "N",  6, 0 } )
   // AAdd ( aDbf, { "STO_BR",    "N",  3, 0 } )

   _alias := "POS_DOKS"
   _table_name := "pos_doks"



   // ----------------- pos items ---------------

   aDbf := {}

   AAdd ( aDbf, { "DATUM",     "D",  8, 0 } )
   AAdd ( aDbf, { "IDPOS",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDVD",      "C",  2, 0 } )
   AAdd ( aDbf, { "BRDOK",     "C",  FIELD_LEN_POS_BRDOK, 0 } )
   AAdd ( aDbf, { "RBR",       "C",  FIELD_LEN_POS_RBR, 0 } )
   AAdd ( aDbf, { "IDCIJENA",  "C",  1, 0 } )
   AAdd ( aDbf, { "CIJENA",    "N", 10, 3 } )
   // AAdd ( aDbf, { "IDDIO",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDODJ",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDRADNIK",  "C",  4, 0 } )
   AAdd ( aDbf, { "IDROBA",    "C", 10, 0 } )
   AAdd ( aDbf, { "IDTARIFA",  "C",  6, 0 } )
   AAdd ( aDbf, { "KOL2",      "N", 18, 3 } )  // za dokument IN - inventuru
   AAdd ( aDbf, { "KOLICINA",  "N", 18, 3 } )
   AAdd ( aDbf, { "M1",        "C",  1, 0 } )
   AAdd ( aDbf, { "MU_I",      "C",  1, 0 } )
   AAdd ( aDbf, { "NCIJENA",   "N", 10, 3 } )
   AAdd ( aDbf, { "PREBACEN",  "C",  1, 0 } )
   AAdd ( aDbf, { "SMJENA",    "C",  1, 0 } )
   AAdd ( aDbf, { "C_1",        "C",  6, 0 } )
   AAdd ( aDbf, { "C_2",        "C", 10, 0 } )
   AAdd ( aDbf, { "C_3",        "C", 50, 0 } )



   // --- promvp - promet po vrstama placanja --
   aDbf := {}
   AAdd ( aDbf, { "DATUM",     "D",  8, 0 } )
   AAdd ( aDbf, { "POLOG01",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG02",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG03",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG04",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG05",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG06",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG07",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG08",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG09",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG10",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG11",   "N", 10, 2 } )
   AAdd ( aDbf, { "POLOG12",   "N", 10, 2 } )
   AAdd ( aDbf, { "UKUPNO",    "N", 10, 3 } )
/*
   _alias := "PROMVP"
   _table_name := "pos_promvp"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "1", "DATUM", _alias )
   AFTER_CREATE_INDEX
*/




   // ----------------------------------------------------------
   // _POS, _PRIPR, PRIPRZ, PRIPRG, _POSP
   // ----------------------------------------------------------

   aDbf := g_pos_pripr_fields()

   _alias := "_POS"
   _table_name := "_pos"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX ( "1", "IdPos+IdVd+dtos(datum)+BrDok+IdRoba+IdCijena+STR(Cijena,10,3)", _alias )
   CREATE_INDEX ( "2", "IdVd+IdOdj", _alias )
   CREATE_INDEX ( "3", "IdVd+IdRadnik+GT+IdOdj+IdRoba", _alias )

   _alias := "_POSP"
   _table_name := "_posp"

   IF_NOT_FILE_DBF_CREATE

   _alias := "_POS_PRIPR"
   _table_name := "_pos_pripr"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX ( "1", "IdRoba", _alias )
   CREATE_INDEX ( "2", "IdPos+IdVd+dtos(datum)+BrDok", _alias )

   _alias := "PRIPRZ"
   _table_name := "priprz"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "1", "IdRoba", _alias )

   _alias := "PRIPRG"
   _table_name := "priprg"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "1", "IdPos+IdOdj+IdRoba+DTOS(Datum)+Smjena", _alias )
   CREATE_INDEX ( "2", "IdPos+DTOS (Datum)+Smjena", _alias )
   CREATE_INDEX ( "3", "IdVd+IdPos+IdVrsteP+IdGost+Placen+IdOdj+IdRoba", _alias )
   CREATE_INDEX ( "4", "IdVd+IdPos+IdVrsteP+IdGost+DToS(datum)", _alias )


   aDbf := {}
   AAdd ( aDbf, { "KEYCODE", "N",  4, 0 } )
   AAdd ( aDbf, { "IDROBA",  "C", 10, 0 } )

   create_porezna_faktura_temp_dbfs()

   RETURN .T.


FUNCTION g_pos_pripr_fields()

   LOCAL aDbf

   // _POS, _PRIPR, PRIPRZ, PRIPRG, _POSP
   aDbf := {}
   AAdd ( aDbf, { "BRDOK",     "C",  FIELD_LEN_POS_BRDOK, 0 } )
   AAdd ( aDbf, { "CIJENA",    "N", 10, 3 } )
   AAdd ( aDbf, { "DATUM",     "D",  8, 0 } )
   AAdd ( aDbf, { "GT",        "C",  1, 0 } )
   AAdd ( aDbf, { "IDCIJENA",  "C",  1, 0 } )
   AAdd ( aDbf, { "IDGOST",    "C",  8, 0 } )
   AAdd ( aDbf, { "IDODJ",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDPOS",     "C",  2, 0 } )
   AAdd ( aDbf, { "IDRADNIK",  "C",  4, 0 } )
   AAdd ( aDbf, { "IDROBA",    "C", 10, 0 } )

   AAdd ( aDbf, { "IDTARIFA",  "C",  6, 0 } )
   AAdd ( aDbf, { "IDVD",      "C",  2, 0 } )
   AAdd ( aDbf, { "IDVRSTEP",  "C",  2, 0 } )
   AAdd ( aDbf, { "JMJ",       "C",  3, 0 } )

   // za inventuru, nivelaciju
   AAdd ( aDbf, { "KOL2",      "N", 18, 3 } )
   AAdd ( aDbf, { "KOLICINA",  "N", 18, 3 } )
   AAdd ( aDbf, { "M1",        "C",  1, 0 } )
   AAdd ( aDbf, { "MU_I",      "C",  1, 0 } )
   AAdd ( aDbf, { "NCIJENA",   "N", 10, 3 } )
   AAdd ( aDbf, { "PLACEN",    "C",  1, 0 } )
   AAdd ( aDbf, { "PREBACEN",  "C",  1, 0 } )
   AAdd ( aDbf, { "ROBANAZ",   "C", 40, 0 } )
   AAdd ( aDbf, { "SMJENA",    "C",  1, 0 } )
   AAdd ( aDbf, { "FISC_RN",   "N", 10, 0 } )

   AAdd ( aDbf, { "VRIJEME",   "C",  5, 0 } )

   AAdd( aDBf, { 'K1', 'C',   4,  0 } )
   // planika: dobavljac   - grupe artikala
   AAdd( aDBf, { 'K2', 'C',   4,  0 } )
   // planika: stavljaju se oznake za velicinu obuce
   // X - ne broji se parovno

   AAdd( aDBf, { 'K7', 'C',   1,  0 } )
   AAdd( aDBf, { 'K8', 'C',   2,  0 } )
   AAdd( aDBf, { 'K9', 'C',   3,  0 } )
   // planika: stavljaju se oznake za velicinu obuce
   // X - ne broji se parovno

   AAdd( aDBf, { 'N1', 'N',  12,  2 } )
   AAdd( aDBf, { 'N2', 'N',  12,  2 } )
   AAdd( aDBf, { 'BARKOD', 'C',  13,  0 } )
   AAdd( aDBf, { 'C_1', 'C',   6,  0 } )
   AAdd( aDBf, { 'C_2', 'C',  10,  0 } )
   AAdd( aDBf, { 'C_3', 'C',  50,  0 } )

   RETURN aDbf
