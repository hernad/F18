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
   FAKT delphirb labele koriste tabelu barkod
*/

FUNCTION cre_barkod( ver )

   LOCAL aDbf
   LOCAL _table_name, _alias
   LOCAL _created

   _alias := "BARKOD"
   _table_name := "barkod"

   aDBf := {}
   AAdd( aDBf, { 'ID', 'C',   10,  0 } )
   AAdd( aDBf, { 'BARKOD', 'C',   13,  0 } )
   AAdd( aDBf, { 'NAZIV', 'C',  250,  0 } )
   AAdd( aDBf, { 'L1', 'C',   40,   0 } )
   AAdd( aDBf, { 'L2', 'C',   40,   0 } )
   AAdd( aDBf, { 'L3', 'C',   40,  0 } )
   AAdd( aDBf, { 'VPC', 'N',   12,  2 } )
   AAdd( aDBf, { 'MPC', 'N',   12,  2 } )

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "barkod+id", _alias )
   CREATE_INDEX( "ID", "id+LEFT(naziv,40)", _alias )
   CREATE_INDEX( "Naziv", "LEFT(Naziv,40)+id", _alias )

   RETURN .T.

/*
FUNCTION cre_sif_roba( ver )

   LOCAL aDbf
   LOCAL _table_name, _alias
   LOCAL _created

   aDbf := {}
   AAdd( aDBf, { 'ID', 'C',  10,  0 } )
   AAdd( aDBf, { 'SIFRADOB', 'C',  20,  0 } )
   add_f_mcode( @aDbf )
   AAdd( aDBf, { 'NAZ', 'C', 250,  0 } )
   AAdd( aDBf, { 'STRINGS', 'N',  10,  0 } )  // izbaciti
   AAdd( aDBf, { 'JMJ', 'C',   3,  0 } )
   AAdd( aDBf, { 'IDTARIFA', 'C',   6,  0 } )
   AAdd( aDBf, { 'NC', 'N',  18,  8 } )
   AAdd( aDBf, { 'VPC', 'N',  18,  8 } )
   AAdd( aDBf, { 'VPC2', 'N',  18,  8 } )
   AAdd( aDBf, { 'PLC', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC2', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC3', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC4', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC5', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC6', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC7', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC8', 'N',  18,  8 } )
   AAdd( aDBf, { 'MPC9', 'N',  18,  8 } )
   AAdd( aDBf, { 'K1', 'C',   4,  0 } )
   AAdd( aDBf, { 'K2', 'C',   4,  0 } )
   AAdd( aDBf, { 'K7', 'C',   4,  0 } )
   AAdd( aDBf, { 'K8', 'C',   4,  0 } )
   AAdd( aDBf, { 'K9', 'C',   4,  0 } )
   AAdd( aDBf, { 'N1', 'N',  12,  2 } )
   AAdd( aDBf, { 'N2', 'N',  12,  2 } )
   AAdd( aDBf, { 'TIP', 'C',   1,  0 } )
   AAdd( aDBf, { 'MINK', 'N',  12,  2 } )
   AAdd( aDBf, { 'Opis', 'C', 500,  0 } )
   AAdd( aDBf, { 'BARKOD', 'C',  13,  0 } )
   AAdd( aDBf, { 'FISC_PLU', 'N',  10,  0 } )
   AAdd( aDBf, { 'ZANIVEL', 'N',  18,  8 } )
   AAdd( aDBf, { 'ZANIV2', 'N',  18,  8 } )
   AAdd( aDBf, { 'TROSK1', 'N',  15,  5 } )  // zavisni troskovi1-5
   AAdd( aDBf, { 'TROSK2', 'N',  15,  5 } )
   AAdd( aDBf, { 'TROSK3', 'N',  15,  5 } )
   AAdd( aDBf, { 'TROSK4', 'N',  15,  5 } )
   AAdd( aDBf, { 'TROSK5', 'N',  15,  5 } )
   AAdd( aDBf, { 'IDKONTO', 'C',   7,  5 } )

   RETURN .T.
*/

/*
   _alias := "ROBA"
   _table_name := "roba"

   IF_NOT_FILE_DBF_CREATE

   // 0.2.1
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00201
      modstru( { "*" + _table_name, "A IDKONTO C 7 0" } )
   ENDIF

   // 0.4.8
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00408
      modstru( { "*" + _table_name, "A MPC4 N 18 8", "A MPC5 N 18 8", "A MPC6 N 18 8", "A MPC7 N 18 8", "A MPC8 N 18 8", "A MPC9 N 18 8" } )
   ENDIF

   // 0.8.9
   IF ver[ "current" ] > 0 .AND. ver[ "current" ] < 00809
      modstru( { "*" + _table_name, "C OPIS C 250 0 OPIS C 500 0" } )
   ENDIF


   CREATE_INDEX( "ID", "ID", _alias )
   index_mcode( my_home(), _alias )
   CREATE_INDEX( "NAZ", "LEFT(naz,40)", _alias )
   CREATE_INDEX( "BARKOD", "BARKOD", _alias )
   CREATE_INDEX( "SIFRADOB", "SIFRADOB", _alias )
   // CREATE_INDEX( "ID_VSD", "SIFRADOB",  _alias )
   CREATE_INDEX( "PLU", "str(fisc_plu, 10)",  _alias )
   CREATE_INDEX( "IDP", { "id+tip", 'tip=="P"' },  _alias )
   AFTER_CREATE_INDEX


   // -------------------------------------------------
   // cIdRoba
   // -------------------------------------------------

   _alias := "_roba"
   _table_name := "_fakt_roba"

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "ID", "ID", _alias )
*/

/*
   // -------------------------------------------------
   // SAST
   // -------------------------------------------------

   _alias := "SAST"
   _table_name := "sast"

   aDBf := {}
   AAdd( aDBf, { 'ID', 'C',   10,  0 } )
   AAdd( aDBf, { 'R_BR', 'N',    4,  0 } )
   AAdd( aDBf, { 'ID2', 'C',   10,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N',   20,  5 } )
   AAdd( aDBf, { 'K1', 'C',    1,  0 } )
   AAdd( aDBf, { 'K2', 'C',    1,  0 } )
   AAdd( aDBf, { 'N1', 'N',   20,  5 } )
   AAdd( aDBf, { 'N2', 'N',   20,  5 } )

   IF_NOT_FILE_DBF_CREATE
   CREATE_INDEX( "ID", "ID+ID2", _alias )
   CREATE_INDEX( "IDRBR", "ID+STR(R_BR,4,0)+ID2", _alias )
   CREATE_INDEX( "NAZ", "ID2+ID", _alias )
   AFTER_CREATE_INDEX
*/





   /*
   // STRINGS
   // --------------------------------------------------------

   -- _alias := "STRINGS"
   _table_name := "strings"

   aDBf := g_str_fields()

   IF_NOT_FILE_DBF_CREATE

   CREATE_INDEX( "1", "STR(ID,10,0)", _alias )
   CREATE_INDEX( "2", "OZNAKA+STR(ID,10,0)", _alias )
   CREATE_INDEX( "3", "OZNAKA+STR(VEZA_1,10,0)+STR(ID,10,0)", _alias )
   CREATE_INDEX( "4", "OZNAKA+STR(VEZA_1,10,0)+NAZ", _alias )
   CREATE_INDEX( "5", "OZNAKA+STR(VEZA_1,10,0)+STR(VEZA_2,10,0)", _alias )

*/


STATIC FUNCTION g_str_fields()

   LOCAL aDbf

   // aDbf =>
   // id   veza_1   veza_2   oznaka   aktivan   naz
   // -------------------------------------------------------------
   // (grupe)
   // 1                     R_GRUPE     D      obuca
   // 2                     R_GRUPE     D      kreme
   // (atributi)
   // 3                     R_D_ATRIB   D      proizvodjac
   // 4                     R_D_ATRIB   D      lice
   // 5                     R_D_ATRIB   D      sastav
   // (grupe - atributi)
   // 6       1         3   R_G_ATRIB   D      obuca / proizvodjac
   // 7       1         4   R_G_ATRIB   D      obuca / lice
   // 8       2         5   R_G_ATRIB   D      kreme / sastav
   // (dodatni atributi - dozvoljene vrijednosti)
   // 9       6             ATRIB_DOZ   D      proizvodjac 1
   // 10       6             ATRIB_DOZ   D      proizvodjac 2
   // 11       6             ATRIB_DOZ   D      proizvodjac 3
   // 12       6             ATRIB_DOZ   D      proizvodjac n...
   // 13       7             ATRIB_DOZ   D      lice 1
   // 14       7             ATRIB_DOZ   D      lice 2 ...
   // (vrijednosti za artikle)
   // 15      -1             01MCJ12002  D      9#13
   // 16      -1             01MCJ13221  D      10#14
   // itd....

   aDbf := {}
   AAdd( aDBf, { "ID", "N", 10, 0 } )
   AAdd( aDBf, { "VEZA_1", "N", 10, 0 } )
   AAdd( aDBf, { "VEZA_2", "N", 10, 0 } )
   AAdd( aDBf, { "OZNAKA", "C", 10, 0 } )
   AAdd( aDBf, { "AKTIVAN", "C",  1, 0 } )
   AAdd( aDBf, { "NAZ", "C", 200, 0 } )

   RETURN aDbf
