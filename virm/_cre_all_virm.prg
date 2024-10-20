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



FUNCTION cre_all_virm_sif( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

/*
   // VRPRIM
   // -------------------

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   4,   0 } )
   AAdd( aDBf, { 'NAZ', 'C',  55,   0 } )
   AAdd( aDBf, { 'POM_TXT', 'C',  65,   0 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,   0 } )
   AAdd( aDBf, { 'IDPartner', 'C',   6,   0 } )
   AAdd( aDBf, { 'NACIN_PL', 'C',   1,   0 } )
   AAdd( aDBf, { 'RACUN', 'C',  16,   0 } )
   AAdd( aDBf, { 'DOBAV', 'C',   1,   0 } )

   _alias := "VRPRIM"
   _table_name := "vrprim"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "id", _alias )
   CREATE_INDEX( "NAZ", "naz", _alias )
   CREATE_INDEX( "IDKONTO", "idkonto+idpartner", _alias )
   AFTER_CREATE_INDEX
*/

   /* -------------------

   _table_name := "vrprim2"
   _alias := "VRPRIM2"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "id", _alias )
   CREATE_INDEX( "NAZ", "naz", _alias )
   CREATE_INDEX( "IDKONTO", "idkonto+idpartner", _alias )
   */

   // -------------------
   // LDVIRM
   // -------------------

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   4,   0 } )
   AAdd( aDBf, { 'NAZ', 'C',  50,   0 } )
   AAdd( aDBf, { 'FORMULA', 'C',  70,   0 } )

   _table_name := "ldvirm"
   _alias := "LDVIRM"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "ID", "id", _alias )
   AFTER_CREATE_INDEX
*/

   /*
   // KALVIR
   // -------------------

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   4,   0 } )
   AAdd( aDBf, { 'NAZ', 'C',  20,   0 } )
   AAdd( aDBf, { 'FORMULA', 'C',  70,   0 } )
   AAdd( aDBf, { 'PNABR', 'C',  10,   0 } )

   -- _table_name := "kalvir"
   -- _alias := "KALVIR"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "id", _alias )
   AFTER_CREATE_INDEX
   */


/*
   // JPRIH
   // -------------------

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',   6,  0 } )
   AAdd( aDBf, { 'IdN0', 'C',   1,  0 } )
   AAdd( aDBf, { 'IdKan', 'C',   2,  0 } )
   AAdd( aDBf, { 'IdOps', 'C',   3,  0 } )
   AAdd( aDBf, { 'Naz', 'C',  40,  0 } )
   AAdd( aDBf, { 'Racun', 'C',  16,  0 } )
   AAdd( aDBf, { 'BudzOrg', 'C',  7,  0 } )

   _table_name := "jprih"
   _alias := "JPRIH"

   IF_NOT_FILE_DBF_CREATE


   CREATE_INDEX( "Id", "id+IdOps+IdKan+IdN0+Racun", _alias )
   CREATE_INDEX( "Naz", "Naz+IdOps", _alias )
   AFTER_CREATE_INDEX
*/

   RETURN .T.



FUNCTION cre_all_virm( ver )

   LOCAL aDbf
   LOCAL _alias, _table_name
   LOCAL _created

   aDbf := {}
   AAdd( aDBf, { 'RBR', 'N',   3,   0 } )
   AAdd( aDBf, { 'MJESTO', 'C',  16,   0 } )
   AAdd( aDBf, { 'DAT_UPL', 'D',   8,   0 } )
   AAdd( aDBf, { 'SVRHA_PL', 'C',   4,   0 } )
   AAdd( aDBf, { 'NA_TERET', 'C',   6,   0 } ) // ko  placa - sifra
   AAdd( aDBf, { 'U_KORIST', 'C',   6,   0 } ) // kome se placa - sifra
   AAdd( aDBf, { 'KO_TXT', 'C',  55,   0 } )
   AAdd( aDBf, { 'KO_ZR', 'C',  16,   0 } )
   AAdd( aDBf, { 'KOME_TXT', 'C',  55,   0 } )
   AAdd( aDBf, { 'KOME_ZR', 'C',  16,   0 } )
   AAdd( aDBf, { 'KO_SJ', 'C',  16,   0 } )
   AAdd( aDBf, { 'KOME_SJ', 'C',  16,   0 } )
   AAdd( aDBf, { 'SVRHA_DOZ', 'C',  92,   0 } )
   AAdd( aDBf, { 'PNABR', 'C',  10,   0 } )
   AAdd( aDBf, { 'Hitno', 'C',   1,   0 } )
   AAdd( aDBf, { 'Vupl', 'C',   1,   0 } )
   AAdd( aDBF, { 'IdOps', 'C',   3,   0 } )
   AAdd( aDBF, { 'POd', 'D',   8,   0 } )
   AAdd( aDBF, { 'PDo', 'D',   8,   0 } )
   AAdd( aDBF, { 'BPO', 'C',  13,   0 } )
   AAdd( aDBF, { 'BudzOrg', 'C',   7,   0 } )
   AAdd( aDBF, { 'IdJPrih', 'C',   6,   0 } )
   AAdd( aDBf, { 'IZNOS', 'N',  20,   2 } )
   AAdd( aDBf, { 'IZNOSSTR', 'C',  20,   0 } )
   AAdd( aDBf, { '_ST_',     'C',   1,   0 } )

   _alias := "VIRM_PRIPR"
   _table_name := "virm_pripr"

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "1", "STR(rbr,3)", _alias )
   CREATE_INDEX( "2", "DTOS(dat_upl)+STR(rbr,3)", _alias )


   aDbf := {}
   AAdd( aDBf, { 'RBR', 'N',   3,   0 } )
   AAdd( aDBf, { 'MJESTO', 'C',  16,   0 } )
   AAdd( aDBf, { 'DAT_UPL', 'C',  15,   0 } )
   AAdd( aDBf, { 'SVRHA_PL', 'C',   4,   0 } )
   AAdd( aDBf, { 'NA_TERET', 'C',   6,   0 } ) // ko  placa - sifra
   AAdd( aDBf, { 'U_KORIST', 'C',   6,   0 } ) // kome se placa - sifra
   AAdd( aDBf, { 'KO_TXT', 'C',  55,   0 } )
   AAdd( aDBf, { 'KO_ZR', 'C',  31,   0 } )
   AAdd( aDBf, { 'KOME_TXT', 'C',  55,   0 } )
   AAdd( aDBf, { 'KOME_ZR', 'C',  31,   0 } )
   AAdd( aDBf, { 'KO_SJ', 'C',  16,   0 } )
   AAdd( aDBf, { 'KOME_SJ', 'C',  16,   0 } )
   AAdd( aDBf, { 'SVRHA_DOZ', 'C',  92,   0 } )
   AAdd( aDBf, { 'PNABR', 'C',  19,   0 } )
   AAdd( aDBf, { 'Hitno', 'C',   1,   0 } )
   AAdd( aDBf, { 'Vupl', 'C',   1,   0 } )
   AAdd( aDBF, { 'IdOps', 'C',   5,   0 } )
   AAdd( aDBF, { 'POd', 'C',  15,   0 } )
   AAdd( aDBF, { 'PDo', 'C',  15,   0 } )
   AAdd( aDBF, { 'BPO', 'C',  25,   0 } )
   AAdd( aDBF, { 'BudzOrg', 'C',  13,   0 } )
   AAdd( aDBF, { 'IdJPrih', 'C',  11,   0 } )
   AAdd( aDBf, { 'IZNOS', 'N',  20,   2 } )
   AAdd( aDBf, { 'IZNOSSTR', 'C',  20,   0 } )
   AAdd( aDBf, { '_ST_',     'C',   1,   0 } )

   _alias := "IZLAZ"
   _table_name := "izlaz"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(rbr,3)", _alias )

   RETURN .T.
