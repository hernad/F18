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

FUNCTION sifk_sifv_test()

   LOCAL _ime_f := "tsifv_k"
   LOCAL _dbf_struct := {}
   LOCAL nI, _rec
   LOCAL cIdSifK, _karakteristika, _karakteristika_n
   LOCAL _header
   LOCAL _tmp

   CLOSE ALL


   AAdd( _dbf_struct,      { 'ID',  'C',    2,  0 } )
   AAdd( _dbf_struct,      { 'NAZ', 'C',   10,  0 } )
   AAdd( _dbf_struct,      { 'DEST', 'C',  60,  0 } )

   DBCREATE2( _ime_f, _dbf_struct )
   cre_index_tsifv_k( _ime_f )

   CLOSE ALL
   my_usex( "sifk" )
   delete_all_dbf_and_server( "sifk" )

   my_usex( "sifv" )
   SELECT sifv
   delete_all_dbf_and_server( "sifv" )

   CLOSE ALL

   // izbrisacu sada sifk
   TEST_LINE( ferase_dbf( "sifk" ), .T. )
   TEST_LINE( ferase_dbf( "sifv" ), .T. )

   TEST_LINE( File( f18_ime_dbf( "sifk" ) ), .F. )
   TEST_LINE( File( f18_ime_dbf( "sifv" ) ), .F. )
   cre_sifk_sifv()

   my_use( _ime_f )

   APPEND BLANK
   IF !RLock()
      RETURN .F.
   ENDIF

   REPLACE id WITH "01"
   REPLACE naz WITH "naz 01"
   REPLACE naz WITH "dest 01"

   REPLACE id WITH "02"
   REPLACE naz WITH "naz 02"
   REPLACE dest WITH "dest 02"

   cIdSifK := "tsifv_k"
   _karakteristika := "ka1"
   _karakteristika_n := "kaN"

   o_sifk()
   SET ORDER TO TAG "ID2"
   SEEK cIdSifK + _karakteristika

   TEST_LINE( Len( cIdSifK ) <= FIELD_LEN_SIFK_ID .AND. Len( _karakteristika ) < FIELD_LEN_SIFK_OZNAKA,  .T. )

   cIdSifK := PadR( cIdSifK, 8 )
   _karakteristika   := PadR( _karakteristika, 4 )
   _karakteristika_n := PadR( _karakteristika_n, 4 )

   o_sifv()

#define K1_LEN 9
#define KN_LEN 7

   TEST_LINE( sifk->( RecCount() ), 0 )
   TEST_LINE( sifv->( RecCount() ), 0 )
   append_sifk( cIdSifK, _karakteristika, "C", K1_LEN, "1" )
   append_sifk( cIdSifK, _karakteristika_n, "C", KN_LEN, "N" )

   // ,  {"id", "oznaka"} , { |x| "ID=" + sql_quote(x["id"]) + "and OZNAKA=" + sql_quote(x["oznaka"]) })


   SELECT F_SIFK
   USE

   my_use( "sifk" )
   SET ORDER TO TAG "ID2"
   SEEK cIdSifK + _karakteristika
   TEST_LINE( field->id + field->oznaka, cIdSifK + _karakteristika )

   SEEK cIdSifK + _karakteristika_n
   TEST_LINE( field->id + field->oznaka, cIdSifK + _karakteristika_n )

   // izbrisacu sada sifk
   TEST_LINE( ferase_dbf( "sifk" ), .T. )
   TEST_LINE( ferase_dbf( "sifv" ), .T. )

   cre_sifk_sifv()

   // tako da forsiram full import
   my_use( "sifk" )

   SET ORDER TO TAG "ID2"
   SEEK cIdSifK + _karakteristika
   _header := "NAKON FERASE: "
   TEST_LINE( _header + field->id + field->oznaka + sifk->tip + sifk->veza + Str( sifk->duzina, 2 ), _header + cIdSifK + _karakteristika + "C1" + Str( K1_LEN, 2 ) )

   SEEK cIdSifK + _karakteristika_n
   _header := "NAKON FERASE: "
   TEST_LINE( _header + field->id + field->oznaka + sifk->tip + sifk->veza + Str( sifk->duzina, 2 ), _header + cIdSifK + _karakteristika_n + "CN" + Str( KN_LEN, 2 ) )

   USE
   CLOSE ALL


   TEST_LINE( USifK( cIdSifK, _karakteristika, "01", "K1VAL1" ), .T. )
   TEST_LINE( USifK( cIdSifK, _karakteristika, "01", "K1VAL2" ), .T. )
   TEST_LINE( USifK( cIdSifK, _karakteristika, "01", "K1VAL3" ), .T. )



   TEST_LINE( USifK( cIdSifK, _karakteristika_n, "01", "K2VAL1,K2VAL3" ), .T. )
   TEST_LINE( USifK( cIdSifK, _karakteristika_n, "01", "K2VAL4,K2VAL1,K2VAL2" ), .T. )


   TEST_LINE( get_sifk_sifv( cIdSifK, _karakteristika, "01" ), PadR( "K1VAL3", K1_LEN ) )

   _tmp := PadR( "K2VAL1", KN_LEN ) + ","
   _tmp += PadR( "K2VAL2", KN_LEN ) + ","
   _tmp += PadR( "K2VAL4", KN_LEN )

   _tmp := PadR( _tmp, 190 )
   TEST_LINE( get_sifk_sifv( cIdSifK, _karakteristika_n, "01" ), _tmp )

   RETURN .t.
   

// -------------------------------------------
// -------------------------------------------
STATIC FUNCTION append_sifk( id_sif, karakteristika, tip, duzina, veza, fields, where_block )

   LOCAL _rec

   SELECT sifk
   SET ORDER TO TAG "ID2"
   SEEK PadR( id_sif, FIELD_LEN_SIFK_ID ) + PadR( karakteristika, FIELD_LEN_SIFK_OZNAKA )

   IF !Found()

      APPEND BLANK
      _rec := dbf_get_rec()
      _rec[ "id" ] := id_sif
      _rec[ "oznaka" ] := karakteristika
      _rec[ "naz" ] := karakteristika + " naziv "
      _rec[ "tip" ] := tip
      _rec[ "duzina" ] := duzina
      _rec[ "veza" ] := veza

      IF !update_rec_server_and_dbf( "sifk", _rec, fields, where_block )
         delete_with_rlock()
      ENDIF
   ENDIF

   RETURN


FUNCTION cre_index_tsifv_k( ime_f )

   CREATE_INDEX( "ID",  "id", ime_f )
   CREATE_INDEX( "NAZ", "naz", ime_f )

   RETURN
