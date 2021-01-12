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

FUNCTION cre_all_fin( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

   // -----------------------------------------------------------
   // FIN_SUBAN
   // -----------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
   AAdd( aDBf, { "IDVN", "C",   2,  0 } )
   AAdd( aDBf, { "BRNAL", "C",   8,  0 } )
   AAdd( aDBf, { "RBR", "I", 4,  0 } )
   AAdd( aDBf, { "IDTIPDOK", "C",   2,  0 } )
   AAdd( aDBf, { "BRDOK", "C",   10,  0 } )
   AAdd( aDBf, { "DATDOK", "D",   8,  0 } )
   AAdd( aDBf, { "DatVal", "D",   8,  0 } )
   AAdd( aDBf, { "OTVST", "C",   1,  0 } )
   AAdd( aDBf, { "D_P", "C",   1,  0 } )
   AAdd( aDBf, { "IZNOSBHD", "B",  8,  6 } )
   AAdd( aDBf, { "IZNOSDEM", "B",  8,  6 } )
   AAdd( aDBf, { "OPIS", "C",  80,  0 } )
   AAdd( aDBf, { "K1", "C",   1,  0 } )
   AAdd( aDBf, { "K2", "C",   1,  0 } )
   AAdd( aDBf, { "K3", "C",   2,  0 } )
   AAdd( aDBf, { "K4", "C",   2,  0 } )
   AAdd( aDBf, { "M1", "C",   1,  0 } )
   AAdd( aDBf, { "M2", "C",   1,  0 } )
   AAdd( aDBf, { "IDRJ", "C",   6,  0 } )
   AAdd( aDBf, { "FUNK", "C",   5,  0 } )
   AAdd( aDBf, { "FOND", "C",   4,  0 } )

/*
   _alias := "SUBAN"
   _table_name := "fin_suban"


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020000 // 2.0.0 - rbr numeric
      f18_delete_dbf( _table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   // 0.3.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00300
      modstru( { "*" + _table_name, "A IDRJ C 6 0", "A FUNK C 5 0", "A FOND C 4 0" } )
   ENDIF


   CREATE_INDEX( "1", "IdFirma+IdKonto+IdPartner+dtos(DatDok)+BrNal+Str(RBr,5)", _alias )
   CREATE_INDEX( "2", "IdFirma+IdPartner+IdKonto", _alias )
   CREATE_INDEX( "3", "IdFirma+IdKonto+IdPartner+BrDok+dtos(DatDok)", _alias )
   CREATE_INDEX( "4", "idFirma+IdVN+BrNal+Str(Rbr,5)", _alias )
   CREATE_INDEX( "5", "idFirma+IdKonto+dtos(DatDok)+idpartner", _alias )
   CREATE_INDEX( "6", "IdKonto", _alias )
   CREATE_INDEX( "7", "Idpartner", _alias )
   CREATE_INDEX( "8", "Datdok", _alias )
   CREATE_INDEX( "9", "idfirma+idkonto+idrj+idpartner+DTOS(datdok)+brnal+Str(rbr,5)", _alias )
   CREATE_INDEX( "10", "idFirma+IdVN+BrNal+idkonto+DTOS(datdok)", _alias )
   AFTER_CREATE_INDEX
*/


   // ----------------------------------------------------------------------------
   // PSUBAN
   // ----------------------------------------------------------------------------

   _alias := "PSUBAN"
   _table_name := "fin_psuban"


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020000 // 2.0.0 - rbr numeric
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   // 0.4.1
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00401
      modstru( { "*" + _table_name, "A IDRJ C 6 0", "A FUNK C 5 0", "A FOND C 4 0" } )
   ENDIF

   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+IdKonto", _alias )


   // ----------------------------------------------------------------------------
   // FIN_PRIPR
   // ----------------------------------------------------------------------------
   _alias := "FIN_PRIPR"
   _table_name := "fin_pripr"


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020000 // 2.0.0 - rbr numeric
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   // 0.4.1
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00401
      modstru( { "*" + _table_name, "A IDRJ C 6 0", "A FUNK C 5 0", "A FOND C 4 0" } )
   ENDIF

   CREATE_INDEX( "1", "idFirma+IdVN+BrNal+Str(Rbr,5)", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+IdKonto", _alias )

   // -----------------------------------------------------------
   // FIN_ANAL
   // -----------------------------------------------------------


   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "IDVN", "C",   2,  0 } )
   AAdd( aDBf, { "BRNAL", "C",   8,  0 } )
   AAdd( aDBf, { "RBR",   "C",   3,  0 } )
   AAdd( aDBf, { "DATNAL", "D",   8,  0 } )
   AAdd( aDBf, { "DUGBHD", "B",  8,  2 } )
   AAdd( aDBf, { "POTBHD", "B",  8,  2 } )
   AAdd( aDBf, { "DUGDEM", "B",  8,  2 } )
   AAdd( aDBf, { "POTDEM", "B",  8,  2 } )


/*
   _alias := "ANAL"
   _table_name := "fin_anal"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+IdKonto+dtos(DatNal)", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+Rbr", _alias )
   CREATE_INDEX( "3", "idFirma+dtos(DatNal)", _alias )
   CREATE_INDEX( "4", "Idkonto", _alias )
   CREATE_INDEX( "5", "DatNal", _alias )
   AFTER_CREATE_INDEX
*/

   // ----------------------------------------------------------------------------
   // PANAL
   // ----------------------------------------------------------------------------

   _alias := "PANAL"
   _table_name := "fin_panal"


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal+idkonto", _alias )


   // ----------------------------------------------------------------------------
   // FIN_SINT
   // ----------------------------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   3,  0 } )
   AAdd( aDBf, { "IDVN", "C",   2,  0 } )
   AAdd( aDBf, { "BRNAL", "C",   8,  0 } )
   AAdd( aDBf, { "RBR", "C",   3,  0 } )
   AAdd( aDBf, { "DATNAL", "D",   8,  0 } )
   AAdd( aDBf, { "DUGBHD", "B",  8,  2 } )
   AAdd( aDBf, { "POTBHD", "B",  8,  2 } )
   AAdd( aDBf, { "DUGDEM", "B",  8,  2 } )
   AAdd( aDBf, { "POTDEM", "B",  8,  2 } )

/*
   _alias := "SINT"
   _table_name := "fin_sint"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+IdKonto+dtos(DatNal)", _alias )
   CREATE_INDEX( "2", "idFirma+IdVN+BrNal+Rbr", _alias )
   CREATE_INDEX( "3", "datnal", _alias )
   AFTER_CREATE_INDEX
*/

   // ----------------------------------------------------------------------------
   // PSINT
   // ----------------------------------------------------------------------------

   _alias := "PSINT"
   _table_name := "fin_psint"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal+idkonto", _alias )


   // ----------------------------------------------------------------------------
   // FIN_NALOG
   // ----------------------------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDVN", "C",   2,  0 } )
   AAdd( aDBf, { "BRNAL", "C",   8,  0 } )
   AAdd( aDBf, { "DATNAL", "D",   8,  0 } )
   AAdd( aDBf, { "DUGBHD", "B",   8,  2 } )
   AAdd( aDBf, { "POTBHD", "B",   8,  2 } )
   AAdd( aDBf, { "DUGDEM", "B",   8,  2 } )
   AAdd( aDBf, { "POTDEM", "B",   8,  2 } )
   AAdd( aDBf, { "SIFRA", "C",   6,  0 } )


   /*
   _alias := "NALOG"
   _table_name := "fin_nalog"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020001 // sifra
       f18_delete_dbf( _table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal", _alias )
   CREATE_INDEX( "2", "IdFirma+str(val(BrNal),8)+idvn", _alias )
   CREATE_INDEX( "3", "dtos(datnal)+IdFirma+idvn+brnal", _alias )
   CREATE_INDEX( "4", "datnal", _alias )
   AFTER_CREATE_INDEX
*/


   // -----------------------------------------------------------
   // PNALOG
   // -----------------------------------------------------------

   _alias := "PNALOG"
   _table_name := "fin_pnalog"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020001 // sifra
      f18_delete_dbf( _table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "IdFirma+IdVn+BrNal", _alias )



   /*
   // FIN_FUNK
   // -----------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { "ID", "C",   5,  0 } )
   AAdd( aDBf, { "NAZ", "C",  35,  0 } )

   _alias := "FUNK"
   _table_name := "fin_funk"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   AFTER_CREATE_INDEX

   // -----------------------------------------------------------
   // FIN_FOND
   // -----------------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { "ID", "C",   4,  0 } )
   AAdd( aDBf, { "NAZ", "C",  35,  0 } )

   _alias := "FOND"
   _table_name := "fin_fond"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "ID", "id", _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   AFTER_CREATE_INDEX


   // -----------------------------------------------------------
   // FIN_BUDZET
   // -----------------------------------------------------------

   aDBf := {}
   AAdd( aDBf, { "IDRJ", "C",   6,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "IZNOS", "N",  20,  2 } )
   AAdd( aDBf, { "FOND", "C",   3,  0 } )
   AAdd( aDBf, { "FUNK", "C",   5,  0 } )
   AAdd( aDBf, { "REBIZNOS", "N",  20,  2 } )

   _alias := "BUDZET"
   _table_name := "fin_budzet"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "IdRj+Idkonto", _alias )
   CREATE_INDEX( "2", "Idkonto",      _alias )
   AFTER_CREATE_INDEX


   // -----------------------------------------------------------
   // FIN_PAREK
   // -----------------------------------------------------------

   --_alias := "PAREK"
   _table_name := "fin_parek"

   aDBf := {}
   AAdd( aDBf, { "IDPARTIJA", "C",   6,  0 } )
   AAdd( aDBf, { "Idkonto", "C",   7,  0 } )

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdPartija", _alias )

   AFTER_CREATE_INDEX

*/

/*
   // -----------------------------------------------------------
   // FIN_BUIZ
   // -----------------------------------------------------------
   _alias := "BUIZ"
  -- _table_name := "fin_buiz"

   aDBf := {}
   AAdd( aDBf, { "ID", "C",   7,  0 } )
   AAdd( aDBf, { "NAZ", "C",  10,  0 } )

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "ID", _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   AFTER_CREATE_INDEX
*/

   /*
   // FIN_ULIMIT
   // -----------------------------------------------------------

   _alias := "ULIMIT"
   _table_name := "fin_ulimit"

   aDBf := {}
   AAdd( aDBf, { "ID", "C",   3,  0 } )
   AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
   AAdd( aDBf, { "F_LIMIT", "N",  15,  2 } )

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "Id", _alias )
   CREATE_INDEX( "2", "Id+idpartner", _alias )
   AFTER_CREATE_INDEX

*/

   // -----------------------------------------------------------
   // FIN_KONTO
   // -----------------------------------------------------------

   _alias := "_KONTO"
   _table_name := "fin_konto"

   aDbf := {}
   AAdd( aDBf, { "ID", "C",   7,  0 } )
   AAdd( aDBf, { "NAZ", "C",  57,  0 } )
   
   IF_NOT_FILE_DBF_CREATE



   // -----------------------------------------------------------
   // FIN_BBKLAS
   // -----------------------------------------------------------

   _alias := "BBKLAS"
   _table_name := "fin_bbklas"

   aDbf := {}
   AAdd( aDBf, { "IDKLASA", "C",   1,  0 } )
   AAdd( aDBf, { "POCDUG", "B",   8,  2 } )
   AAdd( aDBf, { "POCPOT", "B",   8,  2 } )
   AAdd( aDBf, { "TEKPDUG", "B",  8,  2 } )
   AAdd( aDBf, { "TEKPPOT", "B",  8,  2 } )
   AAdd( aDBf, { "KUMPDUG", "B",  8,  2 } )
   AAdd( aDBf, { "KUMPPOT", "B",  8,  2 } )
   AAdd( aDBf, { "SALPDUG", "B",  8,  2 } )
   AAdd( aDBf, { "SALPPOT", "B",  8,  2 } )

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdKlasa", _alias )


   // -----------------------------------------------------------
   // FIN_IOS
   // -----------------------------------------------------------

   _alias := "IOS"
   _table_name := "fin_ios"

   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
   AAdd( aDBf, { "IZNOSBHD", "B",  8,  2 } )
   AAdd( aDBf, { "IZNOSDEM", "B",  8,  2 } )

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "IdFirma+IdKonto+IdPartner", _alias )
   CREATE_INDEX( "IZNOS", "IdFirma+IdKonto+STR(IZNOSBHD,8,2)+IdPartner", _alias )

   // -----------------------------------------------------------
   // KAM_PRIPR
   // -----------------------------------------------------------

   _alias := "kam_pripr"
   _table_name := "kam_pripr"

   aDbf := {}
   AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
   AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
   AAdd( aDBf, { "BRDOK", "C",  10,  0 } )
   AAdd( aDBf, { "DATOD", "D",   8,  0 } )
   AAdd( aDBf, { "DATDO", "D",   8,  0 } )
   AAdd( aDBf, { "OSNOVICA", "B",  8,  2 } )
   AAdd( aDBf, { "OSNDUG", "B",    8,  2 } )
   AAdd( aDBf, { "M1", "C",   1,  0 } )


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "idpartner+brdok+dtos(datod)", _alias )


   // -----------------------------------------------------------
   // KAM_KAMAT
   // -----------------------------------------------------------

   _alias := "kam_kamat"
   _table_name := "kam_kamat"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idpartner+brdok+dtos(datod)", _alias )


   // ----------------------------------------------------------
   // KOMP_DUG / KOMP_POT
   // ----------------------------------------------------------

   aDbf := {}
   AAdd( aDbf, { "BRDOK", "C", 50, 0 } )
   AAdd( aDbf, { "IZNOSBHD", "B", 8, 2 } )
   AAdd( aDbf, { "MARKER", "C",  1, 0 } )

   _alias := "komp_dug"
   _table_name := "fin_komp_dug"


   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   _alias := "komp_pot"
   _table_name := "fin_komp_pot"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 010004 // 1.0.4 - currency polja iznosi
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   RETURN .T.
