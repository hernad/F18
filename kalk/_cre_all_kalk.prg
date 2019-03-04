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

FUNCTION cre_all_kalk( ver )

   kreiraj_kalk_bazirane_tabele( ver )
   kreiraj_ostale_kalk_tabele( ver )


   RETURN .T.

/*
FUNCTION kalk_idzaduz2_se_koristi()

   LOCAL cQuery, oTable, oRow, nCount

   cQuery := "select count(*) as count from " + f18_sql_schema( "kalk_kalk" )
   cQuery += " where btrim(coalesce(idzaduz2,''))<>''"
   run_sql_query( cQuery )
   oTable := run_sql_query( cQuery )
   oRow := oTable:GetRow( 1 )
   nCount := oRow:FieldGet( oRow:FieldPos( "count" ) )

   RETURN nCount > 0
*/

STATIC FUNCTION kreiraj_ostale_kalk_tabele( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created
   LOCAL _tbl


   // objekti
   _alias := "OBJEKTI"
   _table_name := "objekti"

   aDbf := {}
   AAdd( aDbf, { "id", "C", 2, 0 } )
   AAdd( aDbf, { "naz", "C", 10, 0 } )
   AAdd( aDbf, { "IdObj", "C", 7, 0 } )
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID", _alias )
   CREATE_INDEX( "NAZ", "NAZ", _alias )
   CREATE_INDEX( "IdObj", "IdObj", _alias )
   AFTER_CREATE_INDEX

   _alias := "POBJEKTI"
   _table_name := "kalk_pobjekti"
   aDbf := {}
   AAdd( aDbf, { "id", "C", 2, 0 } )
   AAdd( aDbf, { "naz", "C", 10, 0 } )
   AAdd( aDbf, { "idobj", "C", 7, 0 } )
   AAdd( aDbf, { "zalt", "N", 18, 5 } )
   AAdd( aDbf, { "zaltu", "N", 18, 5 } )
   AAdd( aDbf, { "zalu", "N", 18, 5 } )
   AAdd( aDbf, { "zalg", "N", 18, 5 } )
   AAdd( aDbf, { "prodt", "N", 18, 5 } )
   AAdd( aDbf, { "prodtu", "N", 18, 5 } )
   AAdd( aDbf, { "prodg", "N", 18, 5 } )
   AAdd( aDbf, { "produ", "N", 18, 5 } )
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )

   _alias := "KALK_KARTICA"
   _table_name := "kalk_kartica"
   aDbf := {}
   AAdd( aDbf, { "ID", "C", 15, 0 } )
   AAdd( aDbf, { "stanje", "N", 15, 3 } )
   AAdd( aDbf, { "VPV", "N", 15, 3 } )
   AAdd( aDbf, { "NV", "N", 15, 3 } )
   AAdd( aDbf, { "VPC", "N", 15, 3 } )
   AAdd( aDbf, { "MPC", "N", 15, 3 } )
   AAdd( aDbf, { "MPV", "N", 15, 3 } )
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "id", _alias )

   RETURN .T.


STATIC FUNCTION kreiraj_kalk_bazirane_tabele( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created
   LOCAL _tbl

   aDbf := definicija_kalk_tabele()

   // KALK_PRIPR
   _alias := "KALK_PRIPR"
   _table_name := "kalk_pripr"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020106 // 2.1.5
      f18_delete_dbf( _table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idFirma+IdVD+BrDok+RBr", _alias )
   CREATE_INDEX( "2", "idFirma+idvd+brdok+IDTarifa", _alias )
   CREATE_INDEX( "3", "idFirma+idvd+brdok+idroba+rbr", _alias )
   CREATE_INDEX( "4", "idFirma+idvd+idroba", _alias )
   CREATE_INDEX( "5", "idFirma+idvd+idroba+STR(mpcsapp,12,2)", _alias )

   // KALK_PRIPR2

   _alias := "KALK_PRIPR2"
   _table_name := "kalk_pripr2"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020106 // 2.1.5
      f18_delete_dbf( _table_name )
   ENDIF

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idFirma+IdVD+BrDok+RBr", _alias )
   CREATE_INDEX( "2", "idFirma+idvd+brdok+IDTarifa", _alias )

   // KALK_PRIPR2

   _alias := "KALK_PRIPR9"
   _table_name := "kalk_pripr9"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020106 // 2.1.5
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "idFirma+IdVD+BrDok+RBr", _alias )
   CREATE_INDEX( "2", "idFirma+idvd+brdok+IDTarifa", _alias )
   CREATE_INDEX( "3", "dtos(datdok)+mu_i+pu_i", _alias )

   // _KALK
   _alias := "_KALK"
   _table_name := "_kalk"

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020106 // 2.1.5
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idFirma+IdVD+BrDok+RBr", _alias )
   _alias := "PRIPT"  // koristi kalk imp varazdin
   _table_name := "kalk_pript"
   AAdd( aDBf, { 'DATVAL', 'D',   8,  0 } ) // koristi kalk imp varazdin

   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 020106 // 2.1.5
      f18_delete_dbf( _table_name )
   ENDIF
   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "idfirma + idvd + brdok", _alias )
   CREATE_INDEX( "2", "idfirma + idvd + brdok + idroba", _alias )

   RETURN .T.


STATIC FUNCTION definicija_kalk_tabele()

   LOCAL aDbf := {}

   AAdd( aDBf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDBf, { 'IDROBA', 'C',  10,  0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'IDKONTO2', 'C',   7,  0 } )
   AAdd( aDBf, { 'IDVD', 'C',   2,  0 } )
   AAdd( aDBf, { 'BRDOK', 'C',   FIELD_LEN_KALK_BRDOK,  0 } )
   AAdd( aDBf, { 'DATDOK', 'D',   8,  0 } )
   AAdd( aDBf, { 'BRFAKTP', 'C',  10,  0 } )
   AAdd( aDBf, { 'DATFAKTP', 'D',   8,  0 } )
   AAdd( aDBf, { 'IDPARTNER', 'C',   6,  0 } )
   AAdd( aDBf, { 'RBR', 'C',   FIELD_LEN_KALK_RBR,  0 } )
   AAdd( aDBf, { 'TPREVOZ', 'C',   1,  0 } )
   AAdd( aDBf, { 'TPREVOZ2', 'C',   1,  0 } )
   AAdd( aDBf, { 'TBANKTR', 'C',   1,  0 } )
   AAdd( aDBf, { 'TSPEDTR', 'C',   1,  0 } )
   AAdd( aDBf, { 'TCARDAZ', 'C',   1,  0 } )
   AAdd( aDBf, { 'TZAVTR', 'C',   1,  0 } )
   AAdd( aDBf, { 'TRABAT', 'C',   1,  0 } )
   AAdd( aDBf, { 'TMARZA', 'C',   1,  0 } )
   AAdd( aDBf, { 'TMARZA2', 'C',   1,  0 } )
   AAdd( aDBf, { 'NC', 'N', 18, 8 } )
   AAdd( aDBf, { 'MPC', 'N', 18, 8 } )
   AAdd( aDBf, { 'VPC', 'N', 18, 8 } )
   AAdd( aDBf, { 'MPCSAPP', 'N', 18, 8 } )
   AAdd( aDBf, { 'IDTARIFA', 'C',   6,  0 } )
   AAdd( aDBf, { 'MKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'PKONTO', 'C',   7,  0 } )
   AAdd( aDBf, { 'MU_I', 'C',   1,  0 } )
   AAdd( aDBf, { 'PU_I', 'C',   1,  0 } )
   AAdd( aDBf, { 'ERROR', 'C',   1,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N', 18, 8 } )
   AAdd( aDBf, { 'GKOLICINA', 'N', 18, 8 } )
   AAdd( aDBf, { 'GKOLICIN2', 'N', 18, 8 } )
   AAdd( aDBf, { 'FCJ', 'N', 18, 8 } )
   AAdd( aDBf, { 'FCJ2', 'N', 18, 8 } )
   AAdd( aDBf, { 'RABAT', 'N', 18, 8 } )
   AAdd( aDBf, { 'PREVOZ', 'N', 18, 8 } )
   AAdd( aDBf, { 'BANKTR', 'N', 18, 8 } )
   AAdd( aDBf, { 'SPEDTR', 'N', 18, 8 } )
   AAdd( aDBf, { 'PREVOZ2', 'N', 18, 8 } )
   AAdd( aDBf, { 'CARDAZ', 'N', 18, 8 } )
   AAdd( aDBf, { 'ZAVTR', 'N', 18, 8 } )
   AAdd( aDBf, { 'MARZA', 'N', 18, 8 } )
   AAdd( aDBf, { 'MARZA2', 'N', 18, 8 } )
   AAdd( aDBf, { 'RABATV', 'N', 18, 8 } )
   AAdd( aDBf, { 'DATVAL', 'D',   8,  0 } )
   AAdd( aDBf, { 'DAT_OD', 'D',   8,  0 } )
   AAdd( aDBf, { 'DAT_DO', 'D',   8,  0 } )
   AAdd( aDBf, { 'opis', 'C',   150,  0 } )

   RETURN aDbf


/*
   vec otvorena dbf tabela: kalk_pripr
*/
FUNCTION kalk_check_idzaduz2()

   LOCAL aTabele, nI, cFile

   IF ( FieldPos( "idzaduz2" ) != 0 .OR. FieldPos( "datval" ) == 0 )
      Alert( "Serviser F18 - kalk fix idzaduz2, datval, brisanje, restart!" )
      my_close_all_dbf()
      aTabele := { "finmat", "kalk_pripr", "kalk_priprt", "kalk_pripr2", "kalk_pripr9" }
      FOR nI := 1 TO Len( aTabele )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".dbf"
         info_bar( "kalk", cFile )
         FErase( cFile )
         cFile := my_home() + my_dbf_prefix() + aTabele[ nI ] + ".cdx"
         info_bar( "kalk", cFile )
         FErase( cFile )
      NEXT
      Quit_1
   ENDIF

   RETURN .T.
