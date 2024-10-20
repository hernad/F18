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

FUNCTION cre_all_fakt( ver )

   LOCAL aDbf, _created
   LOCAL _alias, _table_name
   LOCAL _tbl

   // ---------------------------------------------------
   // FAKT_FAKT
   // ---------------------------------------------------

   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IdTIPDok', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C',   8,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( aDBf, { 'IDPARTNER', 'C',   6,  0 } )
   AAdd( aDBf, { 'DINDEM', 'C',   3,  0 } )
   AAdd( aDBf, { 'zaokr', 'N',   1,  0 } )
   AAdd( aDBf, { 'Rbr', 'C',   3,  0 } )
   AAdd( aDBf, { 'PodBr', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDROBA', 'C',  10,  0 } )
   AAdd( aDBf, { 'IDROBA_J', 'C',  10,  0 } )
   AAdd( aDBf, { 'SerBr', 'C',  15,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N',  14,  5 } )
   AAdd( aDBf, { 'Cijena', 'N',  14,  5 } )
   AAdd( aDBf, { 'Rabat', 'N',   8,  5 } )
   AAdd( aDBf, { 'Porez', 'N',   9,  5 } )
   AAdd( aDBf, { 'K1', 'C',   4,  0 } )
   AAdd( aDBf, { 'K2', 'C',   4,  0 } )
   AAdd( aDBf, { 'M1', 'C',   1,  0 } )
   AAdd( aDBf, { 'TXT', 'M',  10,  0 } )
   AAdd( aDBf, { 'IDVRSTEP', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDPM', 'C',  15,  0 } )
   AAdd( aDBf, { 'C1', 'C',  20,  0 } )
   AAdd( aDBf, { 'C2', 'C',  20,  0 } )
   AAdd( aDBf, { 'C3', 'C',  20,  0 } )
   AAdd( aDBf, { 'N1', 'N',  10,  3 } )
   AAdd( aDBf, { 'N2', 'N',  10,  3 } )
   AAdd( aDBf, { 'idrelac', 'C',   4,  0 } )
   AAdd( aDBf, { 'FISC_RN', 'N',   10,  0 } ) // dodaj polje fiskalnog racuna ali samo za pripremu

/*
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020101 // 2.1.1 - rbr numeric
     f18_delete_dbf( "fakt_pripr" )
   ENDIF
*/

/*
   // 0.8.3
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00803

      FOR EACH _tbl in { _table_name, "fakt_pripr" }
         modstru( { "*" + _tbl, ;
            "C FISC_RN N 10 0 FISC_RN I 4 0",  ;
            "D OPIS C 120 0", ;
            "D DOK_VEZA C 150 0" ;
            } )
      NEXT

   ENDIF

   // 0.9.2
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00902
      modstru( { "*" + "fakt_pripr", "C FISC_RN I 4 0 FISC_RN N 10 0" } )
   ENDIF
*/

   // ----------------------------------------------------------------------------
   // FAKT_PRIPR
   // ----------------------------------------------------------------------------

   _alias := "FAKT_PRIPR"
   _table_name := "fakt_pripr"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias )
   CREATE_INDEX( "2", "IdFirma+dtos(datdok)", _alias )
   CREATE_INDEX( "3", "IdFirma+idroba+rbr", _alias )


   // ----------------------------------------------------------------------------
   // FAKT_PRIPR9
   // opcija smece
   // ----------------------------------------------------------------------------

   _alias := "FAKT_PRIPR9"
   _table_name := "fakt_pripr9"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias )
   CREATE_INDEX( "2", "IdFirma+dtos(datdok)", _alias )
   CREATE_INDEX( "3", "IdFirma+idroba+rbr", _alias )


   // ----------------------------------------------------------------------------
   // FAKT__FAKT ( _FAKT )
   // ----------------------------------------------------------------------------
   _alias := "_FAKT"
   _table_name := "fakt__fakt"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+idtipdok+brdok+rbr+podbr", _alias )


   // ----------------------------------------------------------------------------
   // FAKT_DOKS
   // ----------------------------------------------------------------------------
   aDbf := {}
   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IdTIPDok', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C',   8,  0 } )
   AAdd( aDBf, { 'PARTNER', 'C', 100,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( aDBf, { 'DINDEM', 'C',   3,  0 } )
   AAdd( aDBf, { 'Iznos', 'N',  12,  3 } )
   AAdd( aDBf, { 'Rabat', 'N',  12,  3 } )
   AAdd( aDBf, { 'Rezerv', 'C',   1,  0 } )
   AAdd( aDBf, { 'M1', 'C',   1,  0 } )
   AAdd( aDBf, { 'IDPARTNER', 'C',   6,  0 } )
   AAdd( aDBf, { 'IDVRSTEP', 'C',   2,  0 } )
   AAdd( aDBf, { 'DATPL', 'D',   8,  0 } )
   AAdd( aDBf, { 'IDPM', 'C',  15,  0 } )
   AAdd( aDBf, { 'OPER_ID', 'N',  10,  0 } )
   AAdd( aDBf, { 'FISC_RN', 'N',  10,  0 } )
   AAdd( aDBf, { 'FISC_ST', 'N',  10,  0 } )
   AAdd( aDBf, { 'DAT_ISP', 'D',   8,  0 } )
   AAdd( aDBf, { 'DAT_VAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'DAT_OTPR', 'D',   8,  0 } )
   AAdd( aDBf, { 'FISC_TIME', 'C',  10,  0 } )
   AAdd( aDBf, { 'FISC_DATE', 'D',   8,  0 } )

/*
   _alias := "FAKT_DOKS"
   _table_name := "fakt_doks"

   IF_NOT_FILE_DBF_CREATE

   // 0.4.3
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0403
      modstru( { "*" + _table_name, "A FISC_ST N 10 0" } )
   ENDIF

   // 0.5.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0500
      modstru( { "*" + _table_name, "C PARTNER C 30 0 PARTNER C 100 0" } )
      modstru( { "*" + _table_name, "C OPER_ID N 3 0 OPER_ID N 10 0" } )
   ENDIF

   // 0.9.0
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 0900
      modstru( { "*" + _table_name, "A FISC_TIME C 10 0", "A FISC_DATE D 8 0" } )
   ENDIF

   // 0.9.3
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00903
      modstru( { "*" + _table_name, "D DOK_VEZA C 150 0" } )
   ENDIF


   CREATE_INDEX( "1", "IdFirma+idtipdok+brdok", _alias )
   CREATE_INDEX( "2", "IdFirma+idtipdok+partner", _alias )
   CREATE_INDEX( "3", "partner", _alias )
   CREATE_INDEX( "4", "idtipdok", _alias )
   CREATE_INDEX( "5", "datdok", _alias )
   CREATE_INDEX( "6", "IdFirma+idpartner+idtipdok", _alias )
   AFTER_CREATE_INDEX
*/


/*
   // ---------------------------------
   // FAKT_DOKS2
   // ---------------------------------

   aDbf := {}
   AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
   AAdd( aDBf, { "IDTIPDOK", "C",   2,  0 } )
   AAdd( aDBf, { "BRDOK", "C",   8,  0 } )
   AAdd( aDBf, { "K1", "C",  15,  0 } )
   AAdd( aDBf, { "K2", "C",  15,  0 } )
   AAdd( aDBf, { "K3", "C",  15,  0 } )
   AAdd( aDBf, { "K4", "C",  20,  0 } )
   AAdd( aDBf, { "K5", "C",  20,  0 } )
   AAdd( aDBf, { "N1", "N",  15,  2 } )
   AAdd( aDBf, { "N2", "N",  15,  2 } )

   _alias := "FAKT_DOKS2"
   _table_name := "fakt_doks2"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IdFirma+idtipdok+brdok", _alias )
   AFTER_CREATE_INDEX
*/

/*
   // ---------------------------------------------------
   // FAKT_UPL
   // ---------------------------------------------------

   aDBf := {}
   AAdd( aDBf, { 'DATUPL','D', 8, 0 } )
   AAdd( aDBf, { 'IDPARTNER','C', 6, 0 } )
   AAdd( aDBf, { 'OPIS','C', 30, 0 } )
   AAdd( aDBf, { 'IZNOS','N', 12, 2 } )

   _alias := "UPL"
   _table_name := "fakt_upl"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "IDPARTNER+DTOS(DATUPL)", _alias )
   CREATE_INDEX( "2", "IDPARTNER", _alias )
   AFTER_CREATE_INDEX
*/


   /*

   aDbf := {}
   AAdd( aDBf, { 'ID','C',  2,0 } )
   AAdd( aDBf, { 'NAZ','C', 340,0 } )

--   _alias := "FAKT_FTXT"
   _table_name := "fakt_ftxt"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "ID", _alias )
   AFTER_CREATE_INDEX
*/

   // ------------------------------------------------
   // FAKT_PRIPR_ATRIB
   // ---------------------------------------------------
   DokAttr():new( "fakt", F_FAKT_ATTR ):create_dbf()

   // kreiraj relacije : RELATION
   cre_relacije_fakt( ver )

   create_porezna_faktura_temp_dbfs()

   RETURN .T.
