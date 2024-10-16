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

FUNCTION cre_all_os( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',  10,  0 } )
   AAdd( aDBf, { 'NAZ', 'C',  30,  0 } )
   AAdd( aDBf, { 'IDRJ', 'C',   4,  0 } )
   AAdd( aDBf, { 'Datum', 'D',   8,  0 } )
   AAdd( aDBf, { 'DatOtp', 'D',   8,  0 } )
   AAdd( aDBf, { 'OpisOtp', 'C',  30,  0 } )
   AAdd( aDBf, { 'IdKonto', 'C',   7,  0 } )
   AAdd( aDBf, { 'kolicina', 'N',   8,  1 } )
   AAdd( aDBf, { 'jmj', 'C',   3,  0 } )
   AAdd( aDBf, { 'IdAm', 'C',   8,  0 } )
   AAdd( aDBf, { 'IdRev', 'C',   4,  0 } )
   AAdd( aDBf, { 'NabVr', 'N',  18,  2 } )
   AAdd( aDBf, { 'OtpVr', 'N',  18,  2 } )
   AAdd( aDBf, { 'AmD', 'N',  18,  2 } )
   AAdd( aDBf, { 'AmP', 'N',  18,  2 } )
   AAdd( aDBf, { 'RevD', 'N',  18,  2 } )
   AAdd( aDBf, { 'RevP', 'N',  18,  2 } )
   AAdd( aDBf, { 'K1', 'C',   4,  0 } )
   AAdd( aDBf, { 'K2', 'C',   1,  0 } )
   AAdd( aDBf, { 'K3', 'C',   2,  0 } )
   AAdd( aDBf, { 'Opis', 'C',  25,  0 } )
   AAdd( aDBf, { 'BrSoba', 'C',   6,  0 } )
   AAdd( aDBf, { 'IdPartner', 'C',   6,  0 } )

   // kreiraj tabelu OS

   _alias := "os"
   _table_name := "os_os"

/*
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "id+idam+dtos(datum)", _alias )
   CREATE_INDEX( "2", "idrj+id+dtos(datum)", _alias )
   CREATE_INDEX( "3", "idrj+idkonto+id",  _alias )
   CREATE_INDEX( "4", "idkonto+idrj+id", _alias )
   CREATE_INDEX( "5", "idam+idrj+id", _alias )
   AFTER_CREATE_INDEX
*/

   // kreiraj tabelu SII

/*
   _alias := "sii"
   _table_name := "sii_sii"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "id+idam+dtos(datum)", _alias )
   CREATE_INDEX( "2", "idrj+id+dtos(datum)", _alias )
   CREATE_INDEX( "3", "idrj+idkonto+id",  _alias )
   CREATE_INDEX( "4", "idkonto+idrj+id", _alias )
   CREATE_INDEX( "5", "idam+idrj+id", _alias )
   AFTER_CREATE_INDEX
*/

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',  10,  0 } )
   AAdd( aDBf, { 'Opis', 'C',  30,  0 } )
   AAdd( aDBf, { 'Datum', 'D',   8,  0 } )
   AAdd( aDBf, { 'Tip', 'C',   2,  0 } )
   AAdd( aDBf, { 'NabVr', 'N',  18,  2 } )
   AAdd( aDBf, { 'OtpVr', 'N',  18,  2 } )
   AAdd( aDBf, { 'AmD', 'N',  18,  2 } )
   AAdd( aDBf, { 'AmP', 'N',  18,  2 } )
   AAdd( aDBf, { 'RevD', 'N',  18,  2 } )
   AAdd( aDBf, { 'RevP', 'N',  18,  2 } )


   _alias := "OS_PROMJ"
   _table_name := "os_promj"

/*
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "id+tip+dtos(datum)+opis", _alias )
   AFTER_CREATE_INDEX
*/

   _alias := "sii_promj"
   _table_name := "sii_promj"


/*
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "id+tip+dtos(datum)+opis", _alias )
   AFTER_CREATE_INDEX
*/

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   8,  0 } )
   AAdd( aDBf, { 'NAZ', 'C',  25,  0 } )
   AAdd( aDBf, { 'IZNOS', 'N',   7,  3 } )

   _alias := "amort"
   _table_name := "os_amort"

/*
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )
   AFTER_CREATE_INDEX
*/

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   4,  0 } )
   AAdd( aDBf, { 'NAZ', 'C',  10,  0 } )
   AAdd( aDBf, { 'I1', 'N',   7,  3 } )
   AAdd( aDBf, { 'I2', 'N',   7,  3 } )
   AAdd( aDBf, { 'I3', 'N',   7,  3 } )
   AAdd( aDBf, { 'I4', 'N',   7,  3 } )
   AAdd( aDBf, { 'I5', 'N',   7,  3 } )
   AAdd( aDBf, { 'I6', 'N',   7,  3 } )
   AAdd( aDBf, { 'I7', 'N',   7,  3 } )
   AAdd( aDBf, { 'I8', 'N',   7,  3 } )
   AAdd( aDBf, { 'I9', 'N',   7,  3 } )
   AAdd( aDBf, { 'I10', 'N',   7,  3 } )
   AAdd( aDBf, { 'I11', 'N',   7,  3 } )
   AAdd( aDBf, { 'I12', 'N',   7,  3 } )

/*
   _alias := "reval"
   _table_name := "os_reval"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )
   AFTER_CREATE_INDEX
*/

   aDBf := {}
   AAdd( aDBf, { 'ID', 'C',   4,  0 } )
   AAdd( aDBf, { 'NAZ', 'C',  25,  0 } )

/*
   _alias := "k1"
   _table_name := "os_k1"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   AFTER_CREATE_INDEX
*/

/*
   IF !File( f18_ime_dbf( "invent" ) )
      aDbf := {}
      AAdd( aDBf, { 'ID', 'C',  10,  0 } )
      AAdd( aDBf, { 'RBR', 'C',   4,  0 } )
      AAdd( aDBf, { 'KOLICINA', 'N',   6,  1 } )
      AAdd( aDBf, { 'IZNOS', 'N',  14,  2 } )
      DBCREATE2( my_home() + 'INVENT.DBF', aDbf )

   ENDIF
   CREATE_INDEX( "ID", "Id", "INVENT" ) // Inventura
*/

   RETURN .T.
