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

STATIC s_hF18Dbfs := nil
STATIC s_mtxMutex

FUNCTION set_a_dbfs()

   LOCAL _dbf_fields, _sql_order
   LOCAL hAlgoritam
   LOCAL cDatabase := my_database()

   IF s_hF18Dbfs == NIL
      hb_mutexLock( s_mtxMutex )
      s_hF18Dbfs  := hb_Hash()
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   IF ! hb_HHasKey( s_hF18Dbfs, cDatabase )
      hb_mutexLock( s_mtxMutex )
      s_hF18Dbfs[ cDatabase ] := hb_Hash()
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   set_a_dbf_sif()
   set_a_dbf_params()
   set_a_dbf_sifk_sifv()
   set_a_dbf_temporary()

   IF f18_use_module( "fin" )
      set_a_dbf_fin()
   ENDIF

   IF f18_use_module( "kalk" )
      set_a_dbf_kalk()
   ENDIF

   IF f18_use_module( "fakt" )
      set_a_dbf_fakt()
   ENDIF

   IF f18_use_module( "ld" )
      set_a_dbf_ld()
      set_a_dbf_ld_sif()
   ENDIF

   IF f18_use_module( "epdv" )
      set_a_dbf_epdv()
   ENDIF

   IF f18_use_module( "os" )
      set_a_dbf_os()
   ENDIF

   IF f18_use_module( "virm" )
      set_a_dbf_virm()
   ENDIF

#ifdef F18_POS
   IF f18_use_module( "pos" )
      set_a_dbf_pos()
   ENDIF
#endif

#ifdef F18_RNAL
   IF f18_use_module( "rnal" )
      set_a_dbf_rnal()
   ENDIF
#endif

#ifdef F18_MAT
   IF f18_use_module( "mat" )
      set_a_dbf_mat()
   ENDIF
#endif

//#ifdef F18_KADEV
//   IF f18_use_module( "kadev" )
//      set_a_dbf_kadev()
//   ENDIF
//#endif

   RETURN .T.



FUNCTION set_a_dbfs_key_fields()

   LOCAL _key
   LOCAL cDatabase := my_server_params()[ "database" ]

   FOR EACH _key in s_hF18Dbfs[ cDatabase ]:Keys

      // nije zadano - na osnovu strukture dbf-a napraviti dbf_fields
      IF !hb_HHasKey( s_hF18Dbfs[ cDatabase ][ _key ], "dbf_fields" )  .OR.  s_hF18Dbfs[ cDatabase ][ _key ][ "dbf_fields" ] == NIL
         set_dbf_fields_from_struct( @s_hF18Dbfs[ cDatabase ][ _key ] )
      ENDIF

   NEXT

   RETURN .T.



FUNCTION f18_dbfs_add( cTable, hItem )

   LOCAL cItem
   LOCAL cDatabase := my_database()

   hb_mutexLock( s_mtxMutex )

   FOR EACH cItem IN s_hF18Dbfs[ cDatabase ]:Keys
      // ako vec postoje tabele sa istim nazivom tabele izbrisati
      IF s_hF18Dbfs[ cDatabase ][ cItem ][ "table" ] == hItem[ "table" ]
         hb_HDel( s_hF18Dbfs[ cDatabase ], cItem )
      ENDIF
   NEXT
   s_hF18Dbfs[ cDatabase ][ cTable ] := hItem

   hb_mutexUnlock( s_mtxMutex )

   RETURN .T.



FUNCTION f18_dbfs()

   LOCAL cDatabase := my_database()

   RETURN s_hF18Dbfs[ cDatabase ]



FUNCTION set_a_dbf_temp( cTabela, cAlias, nWorkarea )

   LOCAL hItem

   hItem := hb_Hash()

   hItem[ "alias" ] := cAlias
   hItem[ "table" ] := cTabela
   hItem[ "wa" ]    := nWorkarea
   hItem[ "temp" ]  := .T.
   hItem[ "chk0" ]  := .T.
   hItem[ "sql" ] := .F.
   hItem[ "sif" ]  := .F.

   f18_dbfs_add( cTabela, @hItem )

   RETURN .T.


FUNCTION set_a_sql_sifarnik( cTabela, cAlias, nWorkarea, hRec )

   set_a_dbf_sifarnik( cTabela, cAlias, nWorkarea, hRec, .T. )

   RETURN .T.


FUNCTION set_a_dbf_sifarnik( cTabela, cAlias, nWorkarea, hRec, lSql )

   LOCAL hAlgoritam, hItem

   IF lSql == NIL
      lSql := .F.
   ENDIF

   hItem := hb_Hash()

   hItem[ "alias" ] := cAlias
   hItem[ "table" ] := cTabela
   hItem[ "wa" ]    := nWorkarea

   hItem[ "temp" ]  := .F.
   hItem[ "sql" ]   :=  lSql
   hItem[ "chk0" ]   :=  .F.
   hItem[ "sif" ] := .T.
   hItem[ "algoritam" ] := {}

   hAlgoritam := hb_Hash()

   IF hRec == NIL
      hAlgoritam[ "dbf_key_fields" ] := { "id" }
      hAlgoritam[ "dbf_tag" ]        := "ID"
      hAlgoritam[ "sql_in" ]        := "id"
      hAlgoritam[ "dbf_key_block" ] := {|| field->id }

   ELSE
      hAlgoritam[ "dbf_key_fields" ] := hRec[ "dbf_key_fields" ]
      hAlgoritam[ "dbf_tag" ]        := hRec[ "dbf_tag" ]
      hAlgoritam[ "sql_in" ]        := hRec[ "sql_in" ]
      hAlgoritam[ "dbf_key_block" ] := hRec[ "dbf_key_block" ]
   ENDIF

   AAdd( hItem[ "algoritam" ], hAlgoritam )
   hItem[ "blacklisted" ] := { "match_code" } // match_code se vise ne koristi

   f18_dbfs_add( cTabela, @hItem )

   RETURN .T.


FUNCTION get_a_dbf_rec_by_wa( nWa )

   LOCAL cTable, cDatabase := my_database()

   FOR EACH cTable IN  s_hF18Dbfs[ cDatabase ]:Keys
      IF s_hF18Dbfs[ cDatabase ][ cTable ][ "wa" ] == nWa
         RETURN s_hF18Dbfs[ cDatabase ][ cTable ]
      ENDIF
   NEXT

   RETURN NIL


/*
  tbl - cTabela ili alias
  _only_basic_params - samo table, alias, wa
*/

FUNCTION get_a_dbf_rec( cTable, _only_basic_params )

   LOCAL _msg, hDbfRecord, _keys, cDbfTable, _key
   LOCAL nI, cMsg, cDatabase := my_database(), hServerParams := my_server_params()

   cDbfTable := "x"

   IF _only_basic_params == NIL
      _only_basic_params = .F.
   ENDIF

   IF !hb_HHasKey( hServerParams, "database" ) .OR. ValType( s_hF18Dbfs[ hServerParams[ "database" ] ] ) <> "H"
      _msg := ""
      LOG_CALL_STACK _msg
      ?E  "get_a_dbf_rec: " + cTable + " s_hF18Dbfs nije inicijalizirana " + _msg
   ENDIF

   IF hb_HHasKey( s_hF18Dbfs[ cDatabase ], cTable )
      cDbfTable := cTable
   ELSE

      FOR EACH _key IN s_hF18Dbfs[ cDatabase ]:Keys // probaj preko aliasa
         IF ValType( cTable ) == "N"  // zadana je workarea
            IF s_hF18Dbfs[ cDatabase ][ _key ][ "wa" ] == cTable
               cDbfTable := _key
               EXIT
            ENDIF
         ELSE
            IF s_hF18Dbfs[ cDatabase ][ _key ][ "alias" ] == Upper( cTable )
               cDbfTable := _key
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF


   IF cDbfTable == "x"
      _msg := "ERROR: x dbf alias " + cTable + " ne postoji u a_dbf_rec ?!"

      hDbfRecord := hb_Hash()
      hDbfRecord[ "temp" ] := .T.
      hDbfRecord[ "table" ] := cTable
      hDbfRecord[ "alias" ] := cTable
      hDbfRecord[ "sql" ] := .F.
      hDbfRecord[ "sif" ] := .F.
      hDbfRecord[ "wa" ] := 6000

      LOG_CALL_STACK _msg
      ?E _msg
      RETURN hDbfRecord

   ENDIF

   IF hb_HHasKey( s_hF18Dbfs[ cDatabase ], cDbfTable )
      hDbfRecord := s_hF18Dbfs[ cDatabase ][ cDbfTable ] // preferirani set parametara
   ELSE
      hDbfRecord := hb_Hash()
      hDbfRecord[ "table" ] := cDbfTable
      hDbfRecord[ "alias" ] := Alias()
      hDbfRecord[ "wa" ] := Select()
      hDbfRecord[ "temp" ] := .T.
      hDbfRecord[ "chk0" ] := .F.
      hDbfRecord[ "sql" ] := .F.
      hDbfRecord[ "sif" ] := .F.
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "table" ) .OR. hDbfRecord[ "table" ] == NIL
      _msg := RECI_GDJE_SAM + " set_a_dbf nije definisan za table= " + cTable
      Alert( _msg )
      log_write( _msg, 2 )
      RaiseError( _msg )
      QUIT_1
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "blacklisted" ) // ako nema definisane blackliste, setuj je ali kao NIL
      hDbfRecord[ "blacklisted" ] := NIL
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "sql" )
      hDbfRecord[ "sql" ] := .F.
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "chk0" )
      hDbfRecord[ "chk0" ] := .F.
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "sif" )
      hDbfRecord[ "sif" ] := .F.
   ENDIF

   IF _only_basic_params
      RETURN hDbfRecord
   ENDIF


   IF !hb_HHasKey( hDbfRecord, "dbf_fields" ) .OR. hDbfRecord[ "dbf_fields" ] == NIL  // nije zadano - na osnovu strukture dbf-a
      set_dbf_fields_from_struct( @hDbfRecord )
   ENDIF

   IF !hb_HHasKey( hDbfRecord, "sql_order" )
      IF hb_HHasKey( hDbfRecord, "algoritam" )
         // dbf_key_fields stavke su "C" za datumska i char polja, "A" za numericka polja
         // npr: { {"godina", 4, 0}, "datum", "id" }
         hDbfRecord[ "sql_order" ] := sql_order_from_key_fields( hDbfRecord[ "algoritam" ][ 1 ][ "dbf_key_fields" ] )
      ENDIF
   ENDIF

   RETURN hDbfRecord


FUNCTION set_a_dbf_rec_chk0( cTable )

   LOCAL lSet := .F.
   LOCAL cDatabase := my_database()

   IF cDatabase == "?undefined?"
      error_bar( "chk0", "set" + cTable )
      RETURN .F.
   ENDIF

   DO WHILE !lSet
      IF hb_mutexLock( s_mtxMutex )
         s_hF18Dbfs[ cDatabase ][ cTable ][ "chk0" ] := .T.
         lSet := .T.
         hb_mutexUnlock( s_mtxMutex )
      ENDIF
   ENDDO

   RETURN .T.


FUNCTION unset_a_dbf_rec_chk0( cTable )

   LOCAL lSet := .F.
   LOCAL cDatabase := my_database()

   IF cDatabase == "?undefined?"
      error_bar( "chk0", "unset" + cTable )
      RETURN .F.
   ENDIF

   DO WHILE !lSet
      IF hb_mutexLock( s_mtxMutex )
         lSet := .T.
         s_hF18Dbfs[ cDatabase ][ cTable ][ "chk0" ] := .F.
         hb_mutexUnlock( s_mtxMutex )
      ENDIF
   ENDDO

   RETURN .T.


FUNCTION is_chk0( cTable )

   LOCAL cDatabase := my_database()

   IF cDatabase == "?undefined?"
      RETURN .F.
   ENDIF

   RETURN s_hF18Dbfs[ cDatabase ][ cTable ][ "chk0" ]


FUNCTION is_sifarnik( cTable )

   LOCAL cDatabase := my_database()

   IF cDatabase == "?undefined?"
      RETURN .F.
   ENDIF

   RETURN s_hF18Dbfs[ cDatabase ][ cTable ][ "sif" ]


FUNCTION dbf_alias_has_semaphore( cAlias )

   LOCAL _ret := .F.
   LOCAL hDbfRecord, cDbfTable, _key
   LOCAL cDatabase := my_database()

   // ako nema parametra uzmi tekuci alias na kome se nalazimo
   IF ( cAlias == NIL )
      cAlias := Alias()
   ENDIF

   IF cDatabase == "?undefined?"
      error_bar( "a_dbfs", "dbf_alias_has_semaphore: " + cAlias )
      RETURN .F.
   ENDIF

   cDbfTable := "x"

   FOR EACH _key IN s_hF18Dbfs[ cDatabase ]:Keys
      IF ValType( cAlias ) == "N"
         IF s_hF18Dbfs[ cDatabase ][ _key ][ "wa" ] == cAlias // zadana je workarea
            cDbfTable := _key
            EXIT
         ENDIF
      ELSE
         IF s_hF18Dbfs[ cDatabase ][ _key ][ "alias" ] == Upper( cAlias )
            cDbfTable := _key
            EXIT
         ENDIF
      ENDIF
   NEXT

   IF hb_HHasKey( s_hF18Dbfs[ cDatabase ], cDbfTable )

      hDbfRecord := s_hF18Dbfs[ cDatabase ][ cDbfTable ]
      IF hDbfRecord[ "temp" ] == .F.
         _ret := .T. // tabela ima semafor
      ENDIF

   ENDIF

   RETURN _ret


FUNCTION imaju_nesinhronizovani_sifarnici()

   LOCAL cKey, lSql, lSif, lChk0
   LOCAL cDatabase := my_database()

   FOR EACH cKey IN s_hF18Dbfs[ cDatabase ]:Keys

      lSql := .F.
      IF hb_HHasKey( s_hF18Dbfs[ cDatabase ][ cKey ], "sql" )
         IF hb_mutexLock( s_mtxMutex )
            lSql := s_hF18Dbfs[ cDatabase ][ cKey ][ "sql" ]
            hb_mutexUnlock( s_mtxMutex )
         ENDIF
      ENDIF

      lSif := .F.
      IF hb_HHasKey( s_hF18Dbfs[ cDatabase ][ cKey ], "sif" )
         IF hb_mutexLock( s_mtxMutex )
            lSif := s_hF18Dbfs[ cDatabase ][ cKey ][ "sif" ]
            hb_mutexUnlock( s_mtxMutex )
         ENDIF
      ENDIF

      lChk0 := .F.
      IF hb_HHasKey( s_hF18Dbfs[ cDatabase ][ cKey ], "chk0" )
         IF hb_mutexLock( s_mtxMutex )
            lChk0 := s_hF18Dbfs[ cDatabase ][ cKey ][ "chk0" ]
            hb_mutexUnlock( s_mtxMutex )
         ENDIF
      ENDIF

      IF !lSQl .AND. !lChk0 .AND. lSif
// #ifdef F18_DEBUG_SYNC
         ?E "U unchecked sif", cDatabase, cKey, "chk0", lChk0, "sif", lSif, "sql", lSql
// #endif
         info_bar( "sync", "nesinhroniziran šifarnik:" + cDatabase + " / " + cKey )
         RETURN .T.
      ENDIF
   NEXT


#ifdef F18_DEBUG_SYNC
   ?E "OOO nema unchecked sif"
#endif

   RETURN .F.


FUNCTION print_a_dbfs()

   LOCAL nCount := 0, cKey
   LOCAL cDatabase := my_database()
   LOCAL nCnt, nDel, nCntSql

   ?E Replicate( "A", 60 )
   FOR EACH cKey IN s_hF18Dbfs[ cDatabase ]:Keys
      ?E ++nCount, s_hF18Dbfs[ cDatabase ][ cKey ][ "table" ]
      IF hb_HHasKey( s_hF18Dbfs[ cDatabase ][ cKey ], "chk0" )
         ??E " chk0", s_hF18Dbfs[ cDatabase ][ cKey ][ "chk0" ]
      ELSE
         ??E " chk0 undefined"
      ENDIF
      IF hb_HHasKey( s_hF18Dbfs[ cDatabase ][ cKey ], "sif" )
         ??E " sif", s_hF18Dbfs[ cDatabase ][ cKey ][ "sif" ]
      ELSE
         ??E " sif undefined!"
      ENDIF
      IF !s_hF18Dbfs[ cDatabase ][ cKey ][ "temp" ]
         nCntSql := table_count( s_hF18Dbfs[ cDatabase ][ cKey ][ "table" ] )
         nCnt := 0
         nDel := 0
         ??E " count: sql", nCntSql
         IF !s_hF18Dbfs[ cDatabase ][ cKey ][ "sql" ]
            IF ! dbf_open_temp_and_count( s_hF18Dbfs[ cDatabase ][ cKey ], @nCntSql, @nCnt, @nDel )
               ??E " dbf open ERROR ! "
            ENDIF
            ??E " dbf cnt/del: ", nCnt, "/", nDel, "dbf cnt-del:", nCnt - nDel
            IF ( nCntSql - nCnt + nDel ) != 0
               ?? " ERR DIFF SQL-DBF: ", ( nCntSql - nCnt + nDel )
            ENDIF
         ENDIF


      ENDIF

   NEXT
   ?E Replicate( "a", 70 )

   RETURN .T.




FUNCTION sql_order_from_key_fields( hTabelaKeyFields ) // "sql_order" hash na osnovu hRec["dbf_fields"]

   LOCAL nI, _len
   LOCAL _sql_order

   // primjer: hTabelaKeyFields = {{"godina", 4}, "idrj", {"mjesec", 2}

   _len := Len( hTabelaKeyFields )

   _sql_order := ""
   FOR nI := 1 TO _len

      IF ValType( hTabelaKeyFields[ nI ] ) == "A"
         _sql_order += hTabelaKeyFields[ nI, 1 ]
      ELSE
         _sql_order += hTabelaKeyFields[ nI ]
      ENDIF

      IF nI < _len
         _sql_order += ","
      ENDIF
   NEXT

   RETURN _sql_order


// ----------------------------------------------
// setujem "dbf_fields" hash na osnovu stukture
// dbf-a
// hRec["dbf_fields"]
// ----------------------------------------------
FUNCTION set_dbf_fields_from_struct( xRec )

   LOCAL lTabelaOtvorenaOvdje := .F.
   LOCAL _dbf
   LOCAL _err
   LOCAL cLogMsg

   LOCAL lSql
   LOCAL nI, cMsg
   LOCAL hRec

   IF ValType( xRec ) == "C"
#ifdef F18_DEBUG
      ?E "set_dbf_fields xRec=", xRec
#endif
      IF hb_HHasKey( s_hF18Dbfs[ my_server_params()[ "database" ] ], xRec )
         hRec := s_hF18Dbfs[ my_server_params()[ "database" ] ][ xRec ]
      ELSE
         ?E "set_dbf_fields tabela ", xRec, "nije u a_dbf_rec"
         RETURN .F.
      ENDIF
   ELSE
      hRec := xRec
   ENDIF

   lSql := hb_HHasKey( hRec, "sql" ) .AND. ValType( hRec[ "sql" ] ) == "L"  .AND. hRec[ "sql" ]

   IF hRec[ "temp" ]  // ovi podaci ne trebaju za temp tabele
      RETURN .F.
   ENDIF

   PushWA()
   SELECT ( hRec[ "wa" ] )

   IF !Used() .AND. !lSql

      _dbf := my_home() + my_dbf_prefix( @hRec ) + hRec[ "table" ]
      IF !File( f18_ime_dbf( hRec ) )
#ifdef F18_DEBUG
         cLogMsg := "NO-DBF : tbl:" + my_home() + my_dbf_prefix( @hRec ) +  hRec[ "table" ] + " alias:" + hRec[ "alias" ] + " ne postoji"
         LOG_CALL_STACK cLogMsg
#endif
         RETURN .F.
      ENDIF

      BEGIN SEQUENCE WITH {| err | err:cargo :=  Break( err ) }

         dbUseArea( .F., DBFENGINE, _dbf, hRec[ "alias" ], .T., .F. )

      RECOVER using _err

         // tabele ocigledno nema, tako da se struktura ne moze utvrditi
         hRec[ "dbf_fields" ]     := NIL
         hRec[ "dbf_fields_len" ] := NIL

         cLogMsg := "ERR-DBF: " + _err:description + ": tbl:" + my_home() + hRec[ "table" ] + " alias:" + hRec[ "alias" ] + " se ne moze otvoriti ?!"
         LOG_CALL_STACK cLogMsg

         log_write( cLogMsg, 5 )
         RETURN .F.

      END SEQUENCE
      lTabelaOtvorenaOvdje := .T.
   ENDIF


   IF !Used() .AND. lSql
      hRec[ "dbf_fields" ]     := NIL
      hRec[ "dbf_fields_len" ] := NIL
   ELSE
      hRec[ "dbf_fields" ] := NIL
      set_rec_from_dbstruct( @hRec )
   ENDIF

   IF lTabelaOtvorenaOvdje
      USE
   ENDIF

   PopWa()

   RETURN .T.



FUNCTION set_rec_from_dbstruct( hRec )

   LOCAL aDbfStruct, nI
   LOCAL hDbfFields := {}, hDbfFieldsLen

   IF hRec[ "dbf_fields" ] != NIL
      RETURN NIL // dbf_fields, dbf_fields_len su vec popunjena
   ENDIF

   hb_mutexLock( s_mtxMutex )

   aDbfStruct := dbStruct()

   hDbfFieldsLen := hb_Hash()
   FOR nI := 1 TO Len( aDbfStruct )
      AAdd( hDbfFields, Lower( aDbfStruct[ nI, 1 ] ) ) // char(10), num(12,2) => {{"C", 10, 0}, {"N", 12, 2}}

// IF aDbfStruct[ nI, 2 ] == "B"

// hDbfFieldsLen[ Lower( aDbfStruct[ nI, 1 ] ) ] := { aDbfStruct[ nI, 2 ], 18, 8 }   // double

      IF aDbfStruct[ nI, 2 ] == "Y" .OR. ( aDbfStruct[ nI, 2 ] == "I" .AND. aDbfStruct[ nI, 4 ] > 0 )

         // za currency polje stoji I 8 4 - sto znaci currency sa cetiri decimale
         // mislim da se ovdje radi o tome da se u 4 bajta stavlja integer dio, a u ostala 4 decimalni dio
         hDbfFieldsLen[ Lower( aDbfStruct[ nI, 1 ] ) ] := { aDbfStruct[ nI, 2 ], 18, aDbfStruct[ nI, 4 ] }

      ELSE
         hDbfFieldsLen[ Lower( aDbfStruct[ nI, 1 ] ) ] := { aDbfStruct[ nI, 2 ], aDbfStruct[ nI, 3 ], aDbfStruct[ nI, 4 ] }

      ENDIF
   NEXT

   hRec[ "dbf_fields" ]     := hDbfFields
   hRec[ "dbf_fields_len" ] := hDbfFieldsLen

   hb_mutexUnlock( s_mtxMutex )

   RETURN NIL





FUNCTION my_close_all_dbf()

   LOCAL nPos := 100
   LOCAL hServerParams := my_server_params()

   CLOSE ALL

   IF !hb_HHasKey( hServerParams, "database" )
      RETURN .F.
   ENDIF

   IF s_hF18Dbfs == NIL .OR. !hb_HHasKey( s_hF18Dbfs, hServerParams[ "database" ] )
      RETURN .F.
   ENDIF

   DO WHILE nPos > 0

      // ako je neki dbf ostao otvoren nPos ce vratiti poziciju tog a_dbf_recorda
      nPos := hb_HScan( s_hF18Dbfs[ hServerParams[ "database" ] ], {| KEY, hRec | zatvori_dbf( hRec ) == .F.  } )
      IF nPos > 0
         hb_idleSleep( 0.1 )
      ELSE
         // svi dbf-ovi su zatvoreni
         EXIT
      ENDIF

   ENDDO

   RETURN .T.



FUNCTION is_sql_table( cDbf )

   LOCAL lSql

   IF cDbf == NIL
      cDbf := Alias()
   ENDIF

   IF Empty( cDbf )
      lSql := .F.
   ELSE
      lSql := get_a_dbf_rec( AllTrim( cDbf ) )[ 'sql' ]
   ENDIF

   RETURN lSql




STATIC FUNCTION zatvori_dbf( hValue )

   Select( hValue[ 'wa' ] )

   IF Used()
      // ostalo je još otvorenih DBF-ova
      USE
      RETURN .F.
   ENDIF

   RETURN .T.


INIT PROCEDURE  init_a_dbfs()

   IF s_mtxMutex == NIL
      s_mtxMutex := hb_mutexCreate()
   ENDIF

   RETURN
