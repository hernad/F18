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

/*
   update hRecord na serveru
*/

FUNCTION sql_table_update( cTable, cSqlOperator, hRecord, cWhereStr, lSilent )

   LOCAL nI, cTmp, cTmp2, cMsg, lSqlTable
   LOCAL oQueryRet := NIL
   LOCAL _result
   LOCAL cQuery
   LOCAL _tbl
   LOCAL _where
   LOCAL _key
   LOCAL _pos
   LOCAL _dec
   LOCAL _len
   LOCAL hDbfRec, _alg
   LOCAL _dbf_fields, _sql_fields, _sql_order, _dbf_wa, _dbf_alias, cSqlTable

   // LOCAL lSqlDbf := .F. hRecord je uvijek 852 enkodiran!

   IF lSilent == NIL
      lSilent := .F.
   ENDIF

   IF cSqlOperator $ "ins#del"

      IF cTable == NIL
         cTable := Alias()
      ENDIF


      hDbfRec := get_a_dbf_rec( cTable )

      _dbf_fields := hDbfRec[ "dbf_fields" ]
      _sql_fields := sql_fields( _dbf_fields )

      _sql_order  := hDbfRec[ "sql_order" ]
      _dbf_wa    := hDbfRec[ "wa" ]
      _dbf_alias := hDbfRec[ "alias" ]
      lSqlTable := hDbfRec[ "sql" ]

      IF "." $ cTable
         cSqlTable := cTable
      ELSE
         cSqlTable := f18_sql_schema( cTable )
      ENDIF

      // uvijek je algoritam 1 nivo recorda
      _alg := hDbfRec[ "algoritam" ][ 1 ]

      IF cWhereStr == NIL
         IF hRecord <> NIL
            cWhereStr := sql_where_from_dbf_key_fields( _alg[ "dbf_key_fields" ], hRecord, lSqlTable )
         ENDIF
      ENDIF

   ENDIF

   // log_write( "sql table update, poceo", 9, lSilent )

   DO CASE

   CASE cSqlOperator == "BEGIN"
      cQuery := "BEGIN"

   CASE ( cSqlOperator == "END" ) .OR. ( cSqlOperator == "COMMIT" )
      cQuery := "COMMIT"

   CASE cSqlOperator == "ROLLBACK"
      cQuery := "ROLLBACK"

   CASE cSqlOperator == "del"

      IF ( cWhereStr == NIL ) .AND. ( hRecord == NIL .OR. ( hRecord[ "id" ] == NIL ) )
         cMsg := RECI_GDJE_SAM + " nedozvoljeno stanje, postavit eksplicitno where na 'true' !!"
         Alert( cMsg )
         log_write( cMsg, 2, lSilent )
         QUIT_1
      ENDIF
      cQuery := "DELETE FROM " + cSqlTable + " WHERE " + cWhereStr

   CASE cSqlOperator == "ins"

      cQuery := "INSERT INTO " + cSqlTable +  "("

      FOR nI := 1 TO Len( hDbfRec[ "dbf_fields" ] )

         IF field_in_blacklist( hDbfRec[ "dbf_fields" ][ nI ], hDbfRec[ "blacklisted" ] )
            LOOP
         ENDIF

         cQuery += hDbfRec[ "dbf_fields" ][ nI ]

         IF nI < Len( hDbfRec[ "dbf_fields" ] )
            cQuery += ","
         ENDIF

      NEXT

      IF Right( cQuery, 1 ) == "," //  ... polje1,polje2,) ==>  .. polje1,polje2)
         cQuery := Left( cQuery, Len( cQuery ) - 1 )
      ENDIF
      cQuery += ")  VALUES ("

      FOR nI := 1 TO Len( hDbfRec[ "dbf_fields" ] )

         cTmp := hDbfRec[ "dbf_fields" ][ nI ]
         IF field_in_blacklist( cTmp, hDbfRec[ "blacklisted" ] )
            LOOP
         ENDIF

         IF !(cTmp $ "match_code#korisnik#obradjeno") .AND.  !hb_HHasKey( hRecord, cTmp ) // match_code su nebitna polja
            cMsg := "record " + cSqlOperator + " ne sadrzi " + cTmp + " field !?## pogledaj log !"
            log_write( cMsg + " " + pp( hRecord ), 2 )
            MsgBeep( cMsg )
            RaiseError( cMsg + " " + pp( hRecord ) )
            RETURN .F.
         ENDIF

         IF !hb_HHasKey( hRecord, cTmp )
             log_write( "polje " + cTmp + " ne postoji ?!", 2 )
             LOOP
         ENDIF

         IF ValType( hRecord[ cTmp ] ) == "N"
            //IF  hDbfRec[ "dbf_fields_len" ][ cTmp ][ 1 ] == "I"
               //altd()
               //cTmp2 := Str( hRecord[ cTmp ], 5, 0 )
            //ELSE
               cTmp2 := Str( hRecord[ cTmp ], hDbfRec[ "dbf_fields_len" ][ cTmp ][ 2 ], hDbfRec[ "dbf_fields_len" ][ cTmp ][ 3 ] )
            //ENDIF

            IF Left( cTmp2, 1 ) == "*"
               cMsg := "err_num_width - field: " + cTmp + "  value:" + AllTrim( Str( hRecord[ cTmp ] ) ) + " / width: " +  AllTrim( Str( hDbfRec[ "dbf_fields_len" ][ cTmp ][ 2 ] ) ) + " : " +  AllTrim( Str( hDbfRec[ "dbf_fields_len" ][ cTmp ][ 3 ] ) )
               log_write( cMsg, 2 )
               RaiseError( cMsg )
            ELSE
               cQuery += cTmp2
            ENDIF
         ELSE
            // IF lSqlDbf
            // cQuery += sql_quote_u( hRecord[ cTmp ] ) // sql tabela sadrzi utf-8 enkodirane podatke
            // ELSE
            cQuery += sql_quote( hRecord[ cTmp ] )
            // ENDIF
         ENDIF

         IF nI < Len( hDbfRec[ "dbf_fields" ] )
            cQuery += ","
         ENDIF

      NEXT

      IF Right( cQuery, 1 ) == "," //  ... polje1,polje2,) ==>  .. polje1,polje2)
         cQuery := Left( cQuery, Len( cQuery ) - 1 )
      ENDIF
      cQuery += ")"


   END CASE

   // ?E "sql table update", cQuery
   oQueryRet := run_sql_query( cQuery )

   IF ValType(oQueryRet) == "O" .AND. oQueryRet:ErrorMsg() <> NIL .AND. Len(oQueryRet:ErrorMsg()) > 0
      Alert(oQueryRet:ErrorMsg())
      RETURN .F.
   ENDIF

   log_write( "sql table update, table: " + iif( cTable == NIL, "NIL", cTable ) + ", op: " + cSqlOperator + ", qry: " + cQuery, 8, lSilent )
   log_write( "sql table update, VALTYPE(oQueryRet): " + ValType( oQueryRet ), 9, lSilent )
   log_write( "sql table update, zavrsio", 9, lSilent )

   IF sql_error_in_query( oQueryRet, "INSERT" )
      RETURN .F.
   ENDIF

   RETURN .T.
