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

FUNCTION cre_all_pos( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created


   aDbf := g_pos_pripr_fields()

   _alias := "_POS_PRIPR"
   _table_name := "_pos_pripr"
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "1", "IdRoba+Transform(cijena,'99999.99')+Transform(ncijena,'99999.99')", _alias )
   CREATE_INDEX ( "2", "IdPos+IdVd+dtos(datum)+BrDok", _alias )

   _alias := "PRIPRZ"
   _table_name := "pos_priprz"
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX ( "1", "IdRoba+Transform(nCijena,'99999.99')+Transform(ncijena,'99999.99')", _alias )

   create_porezna_faktura_temp_dbfs()

   RETURN .T.


FUNCTION pos_check_dbf_fields()

   LOCAL aTabele, nI, cFile

   o_pos_tables()
   SELECT _pos_pripr

   IF ( Len( _pos_pripr->brdok ) <> FIELD_LEN_POS_BRDOK ) .OR. ;
         ( FieldPos( "idpartner" ) == 0 ) .OR. ;
         ( FieldPos( "dat_od" ) == 0 ) .OR. ;
         ( FIELDPOS( "fisk_rn") == 0 .OR. FIELDPOS( "fisk_id") == 0 )

      Alert( "Serviser F18 - promjena struktura, brisanje tabela pripreme!" )
      my_close_all_dbf()
      aTabele := { "pos_priprz", "_pos_pripr" }
      FOR nI := 1 TO Len( aTabele )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".dbf"
         info_bar( "pos_brdok", cFile )
         FErase( cFile )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".cdx"
         info_bar( "pos_brdok", cFile )
         FErase( cFile )
      NEXT
      Quit_1

   ENDIF

   RETURN .T.


FUNCTION g_pos_pripr_fields()

   LOCAL aDbf

   // _PRIPR, PRIPRZ
   aDbf := {}
   // pos_pos & pos_doks (id dokumenta)
   AAdd( aDbf, { "IDPOS",     "C",  2, 0 } )
   AAdd( aDbf, { "IDVD",      "C",  2, 0 } )
   AAdd( aDbf, { "BRDOK",     "C",  FIELD_LEN_POS_BRDOK, 0 } )
   AAdd( aDbf, { "DATUM",     "D",  8, 0 } )
   // END pos_pos & pos_doks (id dokumenta)

   // pos_pos
   AAdd( aDbf, { "CIJENA",    "N", 10, 3 } )
   AAdd( aDbf, { "NCIJENA",   "N", 10, 3 } )

   AAdd( aDbf, { "IDTARIFA",  "C",  6, 0 } )
   AAdd( aDbf, { "KOL2",      "N", 18, 3 } )
   AAdd( aDbf, { "KOLICINA",  "N", 18, 3 } )

   // pos_doks
   AAdd( aDbf, { "IDRADNIK",  "C",  4, 0 } )
   AAdd( aDBf, { 'BRFAKTP', 'C',  10,  0 } )
   AAdd( aDbf, { "VRIJEME",   "C",  5, 0 } )
   AAdd( aDbf, { "IDVRSTEP",  "C",  2, 0 } )
   AAdd( aDbf, { "idPartner",    "C",  FIELD_LEN_PARTNER_ID, 0 } )

   AAdd( aDBf, { 'OPIS', 'C',  100,  0 } )
   AAdd( aDBf, { 'DAT_OD', 'D',  8,  0 } )
   AAdd( aDBf, { 'DAT_DO', 'D',  8,  0 } )

   AAdd( aDBf, { 'fisk_rn', 'I',  4,  0 } )
   AAdd( aDBf, { 'fisk_id', 'C',  36,  0 } )

   // roba
   AAdd( aDbf, { "IDROBA",    "C", 10, 0 } )
   AAdd( aDbf, { "ROBANAZ",   "C", 40, 0 } )
   AAdd( aDBf, { 'BARKOD', 'C',  13,  0 } )
   AAdd ( aDbf, { "JMJ",       "C",  3, 0 } )

   RETURN aDbf
