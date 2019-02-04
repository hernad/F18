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


   // ----------------------------------------------------------
   // _POS, _PRIPR, PRIPRZ, PRIPRG, _POSP
   // ----------------------------------------------------------

   aDbf := g_pos_pripr_fields()
   _alias := "_POS"
   _table_name := "_pos"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX ( "1", "IdPos+IdVd+dtos(datum)+BrDok+IdRoba+STR(Cijena,10,3)", _alias )
   CREATE_INDEX ( "3", "IdVd+IdRadnik+IdRoba", _alias )

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
   CREATE_INDEX ( "1", "IdPos+IdRoba+DTOS(Datum)", _alias )
   CREATE_INDEX ( "2", "IdPos+DTOS (Datum)", _alias )
   CREATE_INDEX ( "3", "IdVd+IdPos+IdVrsteP+idPartner+Placen+IdRoba", _alias )
   CREATE_INDEX ( "4", "IdVd+IdPos+IdVrsteP+idPartner+DToS(datum)", _alias )

   aDbf := {}
   AAdd ( aDbf, { "KEYCODE", "N",  4, 0 } )
   AAdd ( aDbf, { "IDROBA",  "C", 10, 0 } )

   create_porezna_faktura_temp_dbfs()

   RETURN .T.


FUNCTION pos_check_brdok()

   LOCAL aTabele, nI, cFile

   o_pos_tables()
   SELECT _pos_pripr

   IF ( Len( _pos_pripr->brdok ) <> FIELD_LEN_POS_BRDOK ) .OR. ;
         ( FieldPos( "idpartner" ) == 0 )

      Alert( "Serviser F18 brdok[" + AllTrim( Str( Len( _pos_pripr->brdok ) ) ) + "] - pobrisati pos tabele pripreme!" )
      my_close_all_dbf()
      aTabele := { "_pos_pos", "_pos_posp", "pos_priprz", "pos_priprg", "_pos_pripr" }
      FOR nI := 1 TO Len( aTabele )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".dbf"
         info_bar( "pos_brdok", cFile )
         FErase( cFile )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".cdx"
         info_bar( "pos_brdok", cFile )
         FErase( cFile )
      NEXT

   ENDIF

   RETURN .T.


FUNCTION g_pos_pripr_fields()

   LOCAL aDbf

   // _POS, _PRIPR, PRIPRZ, PRIPRG, _POSP
   aDbf := {}
   AAdd ( aDbf, { "BRDOK",     "C",  FIELD_LEN_POS_BRDOK, 0 } )
   AAdd ( aDbf, { "CIJENA",    "N", 10, 3 } )
   AAdd ( aDbf, { "DATUM",     "D",  8, 0 } )
   AAdd ( aDbf, { "idPartner",    "C",  FIELD_LEN_PARTNER_ID, 0 } )
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
   AAdd ( aDbf, { "NCIJENA",   "N", 10, 3 } )
   AAdd ( aDbf, { "PLACEN",    "C",  1, 0 } )
   AAdd ( aDbf, { "ROBANAZ",   "C", 40, 0 } )
   AAdd ( aDbf, { "FISC_RN",   "N", 10, 0 } )
   AAdd ( aDbf, { "VRIJEME",   "C",  5, 0 } )

   AAdd( aDBf, { 'BARKOD', 'C',  13,  0 } )
   AAdd( aDBf, { 'brdokStorn', 'C',  FIELD_LEN_POS_BRDOK,  0 } )

   RETURN aDbf
