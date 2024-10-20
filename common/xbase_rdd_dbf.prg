/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cDbfPrefix := ""


FUNCTION f18_ime_dbf( xTableRec )

   LOCAL _pos
   LOCAL hRecDbf
   LOCAL cRet

   SWITCH ValType( xTableRec )

   CASE "H"
      hRecDbf := xTableRec
      EXIT
   CASE "C"
      hRecDbf := get_a_dbf_rec( FILEBASE( xTableRec, .T. ), .T. )
      EXIT
   OTHERWISE
      ?E  "f18_ime_dbf arg ?! " + hb_ValToStr( xTableRec )
   ENDSWITCH

   IF hRecDbf[ "table" ] == "x"
      Alert( "f18_ime_dbf alias :" + ToStr( xTableRec ) )
   ENDIF

   IF ValType( hRecDbf[ "table" ] ) != "C" .OR. ValType( my_home() ) != "C"
      cRet := "xyz"
      ?E "ERROR_f18_ime_dbf", my_home(), hRecDbf[ "table" ]
   ELSE
      cRet := my_home() + my_dbf_prefix( @hRecDbf ) + hRecDbf[ "table" ] + "." + DBFEXT
   ENDIF

   RETURN cRet


FUNCTION dbf_prefix( cPrefix )

   IF cPrefix != NIL
      s_cDbfPrefix := cPrefix
   ENDIF

   RETURN  s_cDbfPrefix


FUNCTION my_dbf_prefix( aDbfRec )

   LOCAL cPath, lTemp

   IF aDbfRec == NIL
      lTemp := .T.
   ELSE
      lTemp := aDbfRec[ "temp" ]
      // lTemp := lTemp .AND. !( "params" $ aDbfRec[ "table" ] )
   ENDIF


   IF Empty( dbf_prefix() )
      RETURN ""
   ENDIF

   IF lTemp

      // .f18/bringout_2016
      // /1/kalk_pripr
      // /2/kalk_pripr
      cPath := my_home() + dbf_prefix()

      IF DirChange( cPath ) != 0
         MakeDir( cPath )
      ENDIF

      RETURN  dbf_prefix() + SLASH

   ENDIF

   RETURN ""

/*
   uzima sva polja iz tekuceg dbf zapisa
   kada je sql dbf konvertuje u 852 encoding

*/

FUNCTION dbf_get_rec( lConvertToUtf )

   LOCAL cImeDbfPolja, nI, aDbfStruct
   LOCAL cRet := hb_Hash()
   LOCAL lSql := ( my_rddName() ==  "SQLMIX" )

   hb_default( @lConvertToUtf, .F. )

   aDbfStruct := dbStruct()
   FOR nI := 1 TO Len( aDbfStruct )

      cImeDbfPolja := Lower( aDbfStruct[ nI, 1 ] )

      IF !( "#" + cImeDbfPolja + "#" $ "#BRISANO#_OID_#_COMMIT_#" )

         cRet[ cImeDbfPolja ] := Eval( FieldBlock( cImeDbfPolja ) )

         IF aDbfStruct[ nI, 2 ] == "C"
            IF cRet[ cImeDbfPolja ] == NIL
               cRet[ cImeDbfPolja ] := Space( aDbfStruct[ nI, 3 ] )
            ENDIF
            IF lSql .AND. F18_SQL_ENCODING == "UTF8" // sql tabela utf->str
               cRet[ cImeDbfPolja ] := hb_UTF8ToStr( cRet[ cImeDbfPolja ] ) // F18_SQL_ENCODING UTF8
            ENDIF
            IF lConvertToUtf // str->utf
               cRet[ cImeDbfPolja ] := hb_StrToUTF8( cRet[ cImeDbfPolja ] )
            ENDIF

         ENDIF
         IF  aDbfStruct[ nI, 2 ] == "D"
            cRet[ cImeDbfPolja ]  := fix_dat_var( cRet[ cImeDbfPolja ] )
         ENDIF
      ENDIF

   NEXT

   RETURN cRet


/*
     is_dbf_struktura_polja_identicna( "racun", "BRDOK", 8, 0)

    => .T. ako je racun, brdok C(8, 0)

    => .F.  ako je racun.brdok npr. C(6,0)
    => .F.  ako je racun.brdok polje ne postoji
*/
FUNCTION is_dbf_struktura_polja_identicna( cTable, cPolje, nLen, nWidth )

   my_use( cTable )

   IF FieldPos( cPolje ) == 0
      USE
      RETURN .F.
   ENDIF

   SWITCH ValType( cPolje )

   CASE "C"
      IF Len( Eval( FieldBlock( cPolje ) ) ) != nLen
         USE
         RETURN .F.
      ENDIF
      EXIT
   OTHERWISE
      USE
      RaiseError( "implementirano samo za C polja" )

   ENDSWITCH

   USE

   RETURN .T.


FUNCTION my_reccount()

   RETURN RecCount2()


FUNCTION RecCount2()

   LOCAL nCnt, nDel

   PushWa()
   count_deleted( @nCnt, @nDel )
   SET DELETED ON
   PopWa()

   RETURN nCnt - nDel

FUNCTION my_delete()

   RETURN delete_with_rlock()



FUNCTION my_delete_with_pack()

   my_delete()

   RETURN my_dbf_pack()


FUNCTION delete_with_rlock()

   IF my_rlock()
      DELETE
      my_unlock()
      RETURN .T.
   ENDIF

   RETURN .F.



/*
   ferase_dbf( "konto", .T. ) => izbriši tabelu "konto.dbf"
                                 (kao i pripadajuće indekse)

   - lSilent (default .T.)
     .F. => pitaj korisnika da li želi izbrisati tabelu
     .T. => briši bez pitanja
*/

FUNCTION f18_delete_dbf( cTableName )

   RETURN ferase_dbf( cTableName, .T. )


FUNCTION ferase_dbf( cTableName, lSilent )

   LOCAL _tmp, _odg

   IF lSilent == NIL
      lSilent := .T.
   ENDIF

   IF !lSilent

      _odg := Pitanje(, "Izbrisati dbf tabelu " + cTableName + " (L-quit) ?!", "N" )

      IF _odg == "L"
         log_write( "ferase_dbf quit: " + cTableName, 3 )
         QUIT_1
      ENDIF

      IF _odg == "N"
         RETURN .F.
      ENDIF

   ENDIF

   log_write( "ferase_dbf : " + cTableName, 3 )
   cTableName := f18_ime_dbf( cTableName )

   IF File( cTableName )
      IF FErase( cTableName ) != 0
         log_write( "ferase_dbf : " + cTableName + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   _tmp := StrTran( cTableName, DBFEXT, INDEXEXT )
   IF File( _tmp )
      log_write( "ferase_dbf, brisem: " + _tmp, 3 )
      IF FErase( _tmp ) != 0
         log_write( "ferase_dbf : " + _tmp + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   _tmp := StrTran( cTableName, DBFEXT, MEMOEXT )
   IF File( _tmp )
      log_write( "ferase, brisem: " + _tmp, 3 )
      IF FErase( _tmp ) != 0
         log_write( "ferase_dbf : " + _tmp + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION ferase_cdx( cTableName )

   LOCAL _tmp

   cTableName := f18_ime_dbf( cTableName )

   _tmp := StrTran( cTableName, DBFEXT, INDEXEXT )
   IF File( _tmp )
      log_write( "ferase_cdx, brisem: " + _tmp, 3 )
      IF FErase( _tmp ) != 0
         log_write( "ferase_cdx : " + _tmp + "neuspjesno !", 3 )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.


// ------------------------------------------------------
// open exclusive, lOpenIndex - otvoriti index
// ------------------------------------------------------
/*
// FUNCTION reopen_shared( dbf_table, lOpenIndex )

   RETURN reopen_dbf( .F., dbf_table, lOpenIndex )
*/


FUNCTION reopen_exclusive( xArg1, lOpenIndex )

   RETURN reopen_dbf( .T., xArg1, lOpenIndex )



FUNCTION reopen_dbf( lExclusive, xArg1, lOpenIndex, lSilent )

   LOCAL hRecDbf, oError
   LOCAL cDbfIme
   LOCAL lRet
   LOCAL cMsg

   IF lOpenIndex == NIL
      lOpenIndex := .T.
   ENDIF

   IF lSilent == NIL
      lSilent := .T. // koristi se za pokušaj ekslkuzivnog otvaranja DBF-a pa fizičkog zapovanja
                     // u većini neuspješno, nepotrebno informisati korisnika - lSilent TRUE
   ENDIF

   IF ValType( xArg1 ) == "H"
      hRecDbf := xArg1
   ELSE
      hRecDbf  := get_a_dbf_rec( xArg1, .T. )
   ENDIF

   IF hRecDbf[ "sql" ]
      RETURN .F.
   ENDIF


   SELECT ( hRecDbf[ "wa" ] )
   USE

   cDbfIme := my_home() + my_dbf_prefix( @hRecDbf ) + hRecDbf[ "table" ]

   BEGIN SEQUENCE WITH {| err| Break( err ) }

      dbUseArea( .F., DBFENGINE, cDbfIme, hRecDbf[ "alias" ], iif( lExclusive, .F., .T. ), .F. )
      IF lOpenIndex
         IF File( ImeDbfCdx( cDbfIme ) )
            dbSetIndex( ImeDbfCDX( cDbfIme ) )
         ENDIF
         lRet := .T.
      ENDIF

   RECOVER USING oError

      IF !lSilent
         cMsg := "tbl:" + hRecDbf[ "table" ] + " : " + oError:description +  " excl:" + ToStr( lExclusive )
         info_bar( "reop_dbf:" + hRecDbf[ "table" ], cMsg )
         ?E "ERR-reopen_dbf " + cMsg
      ENDIF

      lRet := .F.

   END SEQUENCE

   RETURN lRet


/*
 zap, then open shared, lOpenIndex - otvori index
*/

FUNCTION reopen_exclusive_and_zap( cDbfTable, lOpenIndex )

   LOCAL oError

   IF lOpenIndex == NIL
      lOpenIndex := .T.
   ENDIF


   BEGIN SEQUENCE WITH {| err | Break( err ) }

      reopen_dbf( .T., cDbfTable, lOpenIndex )
      ZAP
      reopen_dbf( .F., cDbfTable, lOpenIndex )

   RECOVER USING oError

      ?E "ERROR-REXCL-ZAP ", oError:Description
      // info_bar( "reop_dbf_zap:" + cDbfTable, cDbfTable + " / " + oError:Description )
      reopen_dbf( .F., cDbfTable, lOpenIndex )
      zapp()

   END SEQUENCE

   RETURN .T.


FUNCTION open_exclusive_zap_close( xArg1, lOpenIndex )

   LOCAL cDbfTable
   LOCAL oError
   LOCAL nRecCount := 999
   LOCAL nCounter := 0

   IF ValType( xArg1 ) == "H"
      cDbfTable := xArg1[ "table" ]
   ELSE
      cDbfTable := xArg1
   ENDIF


   IF lOpenIndex == NIL
      lOpenIndex := .T.
   ENDIF

   DO WHILE nRecCount != 0

      BEGIN SEQUENCE WITH {| err | Break( err ) }
         IF ValType( xArg1 ) == "H"
            reopen_dbf( .T., xArg1, lOpenIndex )
         ELSE
            reopen_dbf( .T., cDbfTable, lOpenIndex )
         ENDIF

         ZAP
         nRecCount := RecCount2()

         USE

      RECOVER USING oError

         ?E "ERR-OXCL-ZAP ", cDbfTable, oError:Description, nCounter
         // info_bar( "op_zap_clo:" + cDbfTable, cDbfTable + " / " + oError:Description )
         IF ValType( xArg1 ) == "H"
            reopen_dbf( .F., xArg1, lOpenIndex )
         ELSE
            reopen_dbf( .F., cDbfTable, lOpenIndex )
         ENDIF
         zapp()

         IF Used()
            nRecCount := RecCount2()
         ENDIF

         USE

      END SEQUENCE

      nCounter++

      IF nCounter > 10
         RETURN .F.
      ELSE
         hb_idleSleep( 1 )
      ENDIF
   ENDDO

   RETURN .T.


FUNCTION my_dbf_zap( cTabelaOrAlias )

   LOCAL cAlias
   LOCAL lRet

   IF cTabelaOrAlias  != NIL
      cAlias := get_a_dbf_rec( cTabelaOrAlias )[ "alias" ]
   ELSE
      cAlias := Alias()
   ENDIF

   PushWA()
   lRet := reopen_exclusive_and_zap( cAlias, .T. )
   PopWa()

   RETURN lRet


FUNCTION my_dbf_pack( lOpenUSharedRezimu )

   LOCAL lRet
   LOCAL cAlias
   LOCAL cMsg

   cAlias := Alias()

   IF lOpenUSharedRezimu == NIL
      lOpenUSharedRezimu := .T.
   ENDIF

   PushWA()

   lRet := reopen_dbf( .T., cAlias, .T. )
   IF lRet
      __dbPack()
   ENDIF

   IF !lRet .OR. lOpenUSharedRezimu
      lRet := reopen_dbf( .F., cAlias, .T. ) // ako je neuspjesan bio reopen u ekskluzivnom režimu obavezno otvoriti ponovo
   ENDIF

   IF Alias() <> cAlias
      PopWa()
      cMsg := "my_dbf_pack :" + Alias() + " <> " + cAlias
      RaiseError( cMsg )
   ENDIF
   PopWa()

   RETURN lRet



FUNCTION pakuj_dbf( hDbfRec, lSilent )

   LOCAL oError

   log_write( "PACK table " + hDbfRec[ "alias" ], 2 )

   BEGIN SEQUENCE WITH {| err| Break( err ) }

      SELECT ( hDbfRec[ "wa" ] )
      my_use_temp( hDbfRec[ "alias" ], my_home() + my_dbf_prefix( @hDbfRec ) + hDbfRec[ "table" ], .F., .T. )

      ?E "PACK-TABELA", hDbfRec[ "table" ]

      PACK

      DO WHILE .T.
         USE
         IF Used()
            hb_idleSleep( 2 )
         ELSE
            EXIT
         ENDIF
      ENDDO


   RECOVER using oError
      log_write( "NOTIFY: PACK neuspjesan dbf: " + hDbfRec[ "table" ] + "  " + oError:Description, 3 )

   END SEQUENCE

   RETURN .T.




STATIC FUNCTION zatvori_dbf( hDbfRec )

   Select( hDbfRec[ 'wa' ] )

   IF Used()
      // ostalo je još otvorenih DBF-ova
      USE
      RETURN .F.
   ENDIF

   RETURN .T.




FUNCTION dbf_open_temp_and_count( aDbfRec, nCntSql, nCnt, nDel )

   LOCAL cAliasTemp := "TEMP__" + aDbfRec[ "alias" ]
   LOCAL cFullDbf := f18_ime_dbf( aDbfRec )
   LOCAL cFullIdx
   LOCAL bKeyBlock, cEmptyRec, nDel0, nCnt2
   LOCAL oError
   LOCAL nI, cMsg, cLogMsg := ""

   IF !File( cFullDbf )
      nCnt := -999
      nDel := -7777
      RETURN .F.
   ENDIF

   cFullIdx := ImeDbfCdx( cFullDbf )

   BEGIN SEQUENCE WITH {| err| Break( err ) }
      SELECT ( aDbfRec[ "wa" ] + 2000 )
      USE  ( cFullDbf ) Alias ( cAliasTemp )  SHARED
      IF File( cFullIdx )
         dbSetIndex( ImeDbfCdx( cFullDbf ) )
      ENDIF
   RECOVER USING  oError
      LOG_CALL_STACK cLogMsg
      ?E "dbf_open_temp_and_count use dbf:", cFullDbf, "alias:", cAliasTemp, oError:Description
      error_bar( "dbf_open_tmp_cnt", cAliasTemp + " / " + oError:Description )
      nCnt := -888
      nDel := -8888
      RETURN .F.
   END SEQUENCE

   count_deleted( @nCnt, @nDel )

   IF Abs( nCntSql - nCnt + nDel ) > 0

      bKeyBlock := aDbfRec[ "algoritam" ][ 1 ][ "dbf_key_block" ]
      IF hb_HHasKey( aDbfRec[ "algoritam" ][ 1 ], "dbf_key_empty_rec" )

         nDel0 := nDel
         SET ORDER TO
         SET DELETED ON
         cEmptyRec := aDbfRec[ "algoritam" ][ 1 ][ "dbf_key_empty_rec" ]

         nCnt2 := 0
         dbEval( {|| delete_empty_records( bKeyBlock, cEmptyRec, @nCnt2 ) } )
         count_deleted( @nCnt, @nDel )
         log_write( "DELETING (nDel0:" + ;
            AllTrim( Str( nDel0 ) ) + ") empty records for dbf: " + ;
            aDbfRec[ "table" ] + " nDel:" + AllTrim( Str( nDel ) ) + ;
            " nCnt2= " + AllTrim( Str ( nCnt2 ) ), 1 )
      ELSE
         ?E "WARNING-dbf_open_temp_and_count_NOT_defined_dbf_key_empty_rec: " + aDbfRec[ "table" ]
      ENDIF

   ENDIF

   USE
   SET DELETED ON

   RETURN .T.


FUNCTION count_deleted( nCnt, nDel )

   LOCAL oError

   SET DELETED OFF
   SET ORDER TO TAG "DEL"
   IF Empty( ordKey() )
      SET DELETED ON
      COUNT TO nCnt
      nDel := 0
   ELSE
      COUNT TO nDel
      nCnt := RecCount()
   ENDIF

   RETURN .T.


STATIC FUNCTION delete_empty_records( bKeyBlock, cEmptyRec, nCnt2 )

   IF Eval( bKeyBlock ) == cEmptyRec
      RLock()
      dbDelete()
      dbUnlock()
      nCnt2++
      RETURN .T.
   ENDIF

   RETURN .F.
