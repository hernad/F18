/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// ------------------------------
// aFields := { "id, "naz" }
// => "id, naz"
//
FUNCTION sql_fields( aFields )

   LOCAL  nI, _sql_fields := ""

   IF aFields == NIL
      RETURN NIL
   ENDIF

   FOR nI := 1 TO Len( aFields )
      _sql_fields += aFields[ nI ]
      IF nI < Len( aFields )
         _sql_fields +=  ","
      ENDIF
   NEXT

   RETURN _sql_fields



FUNCTION _sql_date_str( var )

   LOCAL _out

   _out := DToS( var )
   // 1234-56-78
   _out := SubStr( _out, 1, 4 ) + "-" + SubStr( _out, 5, 2 ) + "-" + SubStr( _out, 7, 2 )

   RETURN _out


FUNCTION sql_quote( xVar )

   LOCAL cOut

   IF ValType( xVar ) == "C"
      cOut := StrTran( xVar, "'", "''" )
      cOut := "'" + hb_StrToUTF8( cOut ) + "'"
   ELSEIF ValType( xVar ) == "D"
      IF xVar == CToD( "" )
         //cOut := "'1000-01-01'"
         cOut := "NULL"
      ELSE
         cOut := "'" + _sql_date_str( xVar ) + "'"
      ENDIF
   ELSEIF ValType( xVar ) == "N"
      cOut := AllTrim( Str( xVar ) )
   ELSE
      cOut := "NULL"
   ENDIF

   RETURN cOut


/*
// xVar je vec UTF-8 enkodiran
// ------------------------------
FUNCTION sql_quote_u( xVar )

   LOCAL cOut

   IF ValType( xVar ) == "C"
      cOut := StrTran( xVar, "'", "''" )
      cOut := "'" + cOut + "'"
   ELSE
      cOut := sql_quote( xVar )
   ENDIF

   RETURN cOut

*/


FUNCTION sql_where_from_dbf_key_fields( aDbfKeyFields, hRecord, lSqlTable )

   LOCAL _ret, _pos, _item, _key

   // npr aDbfKeyFields := {{"godina", 4}, "idrj", {"mjesec", 2}, "obr", "idradn" }
   _ret := ""
   FOR EACH _item in aDbfKeyFields

      IF !Empty( _ret )
         _ret += " AND "
      ENDIF

      IF ValType( _item ) == "A"
         // numeric
         _key := Lower( _item[ 1 ] )
         check_hash_key( hRecord, _key )
         _ret += _item[ 1 ] + "=" + Str( hRecord[ _key ], _item[ 2 ] )

      ELSEIF ValType( _item ) == "C"
         _key := Lower( _item )
         check_hash_key( hRecord, _key )
         //IF lSqlTable
          //  _ret += _item + "=" + sql_quote_u( hRecord[ _key ] )
         //ELSE
            _ret += _item + "=" + sql_quote( hRecord[ _key ] )
         //ENDIF

      ELSE
         MsgBeep( ProcName( 1 ) + "valtype _item ?!" )
         QUIT_1
      ENDIF

   NEXT

   RETURN _ret



// -----------------------------------------------------
// parsiranje datuma u sql izrazu
// -----------------------------------------------------
FUNCTION _sql_date_parse( cField, date1, date2 )

   LOCAL _ret := ""

   // datdok BETWEEN '2012-02-01' AND '2012-05-01'

   // dva su datuma
   IF PCount() > 2

      IF date1 == NIL
         date1 := CToD( "" )
      ENDIF
      IF date2 == NIL
         date2 := CToD( "" )
      ENDIF

      // oba su prazna
      IF DToC( date1 ) == DToC( CToD( "" ) ) .AND. DToC( date2 ) == DToC( CToD( "" ) )
         _ret := "TRUE"
         // samo prvi je prazan
      ELSEIF DToC( date1 ) == DToC( CToD( "" ) )
         _ret := cField + " <= " + sql_quote( date2 )
         // drugi je prazan
      ELSEIF DToC( date2 ) == DToC( CToD( "" ) )
         _ret := cField + " >= " + sql_quote( date1 )
         // imamo dva regularna datuma
      ELSE
         // ako su razliciti datumi
         IF DToC( date1 ) <> DToC( date2 )
            _ret := cField + " BETWEEN " + sql_quote( date1 ) + " AND " + sql_quote( date2 )
            // ako su identicni, samo nam jedan treba u LIKE klauzuli
         ELSE
            _ret := cField + "::char(20) LIKE " + sql_quote( _sql_date_str( date1 ) + "%" )
         ENDIF
      ENDIF

      // imamo samo jedan uslov, cField ili nista
   ELSEIF PCount() <= 1
      _ret := "TRUE"

      // samo jedan datumski uslov
   ELSE
      _ret := cField + "::char(20) LIKE " + sql_quote( _sql_date_str( date1 ) + "%" )
   ENDIF

   RETURN _ret


FUNCTION _sql_cond_parse( cField, aConditions, not )

   LOCAL _ret := ""
   LOCAL cond_arr := TokToNiz( aConditions, ";" )
   LOCAL nI, _cond

   IF not == NIL
      not := .F.
   ENDIF

   FOR EACH _cond in cond_arr

      IF Empty( _cond )
         LOOP
      ENDIF

      _ret += "  OR " + cField

      IF Len( cond_arr ) > 1
         IF not
            _ret += " NOT "
         ENDIF
         _ret += " LIKE " + sql_quote( AllTrim( _cond ) + "%" )
      ELSE
         IF not
            _ret += " <> "
         ELSE
            _ret += " = "
         ENDIF
         _ret += sql_quote( _cond )
      ENDIF

   NEXT

   _ret := Right( _ret, Len( _ret ) - 5 )

   IF " OR " $ _ret
      _ret := " ( " + _ret + " ) "
   ENDIF

   IF Empty( _ret )
      _ret := " TRUE "
   ENDIF

   RETURN _ret


/*
 vraca vrijednost polja po zadatom uslovu
 sql_get_field_za_uslov( "partn", "naz", { { "id", "1AL001" }, { ... } } )
*/

FUNCTION sql_get_field_za_uslov( cTableName, cField, aConditions )

   LOCAL xValue
   LOCAL cQuery := ""
   LOCAL oTable
   LOCAL _server := sql_data_conn()
   LOCAL _where := ""
   LOCAL _data := {}
   LOCAL nI, oRow

   IF aConditions == NIL
      aConditions := {}
   ENDIF

   IF ! ( "." $ cTableName )
      cTableName := F18_PSQL_SCHEMA + "." + cTableName
   ENDIF

   cQuery += "SELECT " + cField + " FROM " + cTableName

   FOR nI := 1 TO Len( aConditions )

      IF aConditions[ nI ] <> NIL

         IF !Empty( _where )
            _where += " AND "
         ENDIF

         IF ValType( aConditions[ nI, 2 ] ) == "N"
            _where += aConditions[ nI, 1 ] + " = " + Str( aConditions[ nI, 2 ] )
         ELSE
            _where += aConditions[ nI, 1 ] + " = " + sql_quote( aConditions[ nI, 2 ] )
         ENDIF

      ENDIF

   NEXT

   IF !Empty( _where )
      cQuery += " WHERE " + _where
   ENDIF

   oTable := run_sql_query( cQuery )
   IF  sql_error_in_query( oTable )
      RETURN NIL
   ENDIF

   oRow := oTable:GetRow( 1 )
   xValue := oRow:FieldGet( 1 )

   IF ValType( xValue ) == "L"
      xValue := NIL
   ENDIF

   IF ValType( xValue ) == "C"
      xValue := hb_UTF8ToStr( xValue )
   ENDIF

   RETURN xValue




// --------------------------------------------------------------------
// vraca sve zapise iz tabele po zadatom uslovu
// --------------------------------------------------------------------
FUNCTION select_all_records_from_table( cTable, aFields, where_cond, order_fields )

   LOCAL cQuery, _data, nI, _n, _o

   cQuery := "SELECT "

   IF aFields == NIL
      cQuery += " * "
   ELSE
      FOR nI := 1 TO Len( aFields )
         cQuery += aFields[ nI ]
         IF nI < Len( aFields )
            cQuery += ","
         ENDIF
      NEXT
   ENDIF

   cQuery += " FROM " + cTable

   IF where_cond <> NIL

      cQuery += " WHERE "

      FOR _n := 1 TO Len( where_cond )
         cQuery += where_cond[ _n ]
         IF _n < Len( where_cond )
            cQuery += " AND "
         ENDIF
      NEXT

   ENDIF

   IF order_fields <> NIL

      cQuery += " ORDER BY "

      FOR _o := 1 TO Len( order_fields )
         cQuery += order_fields[ _o ]
         IF _o < Len( order_fields )
            cQuery += ","
         ENDIF
      NEXT

   ENDIF

   RETURN run_sql_query( cQuery )





// -----------------------------------------------------
// vraca strukturu tabele sa servera
// ... klasicno vraca matricu kao ASTRUCT()
// -----------------------------------------------------
FUNCTION _sql_table_struct( cTable )

   LOCAL _struct := {}
   LOCAL cQuery
   LOCAL nI
   LOCAL _data
   LOCAL _cField, _field_type, _field_len, _field_dec
   LOCAL _field_type_short
   LOCAL oRow

   cQuery := "SELECT column_name, data_type, character_maximum_length, numeric_precision, numeric_scale " + ;
      " FROM information_schema.columns " + ;
      " WHERE ( table_schema || '.' || cTableName ) = " + sql_quote( cTable ) + ;
      " ORDER BY ordinal_position;"

   _data := run_sql_query( cQuery )
   _data:goto( 1 )

   DO WHILE !_data:Eof()

      oRow := _data:GetRow()

      _cField := oRow:FieldGet( 1 )
      _field_type := oRow:FieldGet( 2 )

      DO CASE

      CASE "character" $ _field_type

         _field_type_short := "C"
         _field_len := oRow:FieldGet( 3 )
         _field_dec := 0

      CASE _field_type == "numeric"

         _field_type_short := "N"
         _field_len := oRow:FieldGet( 4 )
         _field_dec := oRow:FieldGet( 5 )

      CASE _field_type == "text"

         _field_type_short := "M"
         _field_len := 1000
         _field_dec := 0

      CASE _field_type == "date"

         _field_type_short := "D"
         _field_len := 8
         _field_dec := 0

      ENDCASE

      AAdd( _struct, { _cField, _field_type_short, _field_len, _field_dec } )

      _data:Skip()

   ENDDO

   RETURN _struct



// --------------------------------------------------------------------
// sql update
// --------------------------------------------------------------------
FUNCTION sql_update_table_from_hash( cTable, op, hash, where_fields )

   LOCAL cQuery
   LOCAL _result

   DO CASE
   CASE op == "ins"
      cQuery := _create_insertcQuery_from_hash( cTable, hash )
   CASE op == "upd"
      cQuery := _create_updatecQuery_from_hash( cTable, hash, where_fields )
   ENDCASE

   run_sql_query( "BEGIN;" )

   _result := run_sql_query( cQuery )

   IF _result:Eof()
      run_sql_query( "ROLLBACK;" )
   ELSE
      run_sql_query( "COMMIT;" )
   ENDIF

   RETURN _result



// --------------------------------------------------------------------
// kreira insert qry iz hash tabele
// --------------------------------------------------------------------
STATIC FUNCTION _create_insertcQuery_from_hash( cTable, hash )

   LOCAL cQuery, _key

   cQuery := "WITH tmp AS ( "
   cQuery += "INSERT INTO " + cTable
   cQuery += " ( "

   FOR EACH _key in hash:keys
      cQuery += _key + ","
   NEXT

   cQuery := PadR( cQuery, Len( cQuery ) - 1 )

   cQuery += " ) VALUES ( "

   FOR EACH _key in hash:keys

      IF ValType( hash[ _key ] ) == "N"
         cQuery += Str( hash[ _key ] )
      ELSE
         cQuery += sql_quote( hash[ _key ] )
      ENDIF

      cQuery += ","

   NEXT

   cQuery := PadR( cQuery, Len( cQuery ) - 1 )

   cQuery += " ) "

   cQuery += " RETURNING "

   FOR EACH _key in hash:keys
      cQuery += _key + ","
   NEXT

   cQuery := PadR( cQuery, Len( cQuery ) - 1 )

   cQuery += " ) "
   cQuery += " SELECT * FROM tmp;"

   RETURN cQuery


// ---------------------------------------------------------------
// prebacuje record iz query-ja u hash matricu
// ---------------------------------------------------------------
FUNCTION _sql_query_record_to_hash( query, rec_no )

   LOCAL _hash := hb_Hash()
   LOCAL nI, _field, _value, _type
   LOCAL _row

   IF query == NIL
      RETURN query
   ENDIF

   IF rec_no == NIL
      // default
      rec_no := 1
   ENDIF

   _row := query:GetRow( rec_no )

   FOR nI := 1 TO _row:FCount()
      _field := _row:FieldName( nI )
      _value := _row:FieldGet( nI )
      IF ValType( _value ) $ "C#M"
         _value := hb_UTF8ToStr( _value )
      ENDIF
      _hash[ Lower( _field ) ] := _value
   NEXT

   RETURN _hash




// ----------------------------------------------------------------
// iz query-ja ce sve prebaciti u hash matricu...
// ----------------------------------------------------------------
FUNCTION _sql_query_to_table( alias, qry )

   LOCAL _row
   LOCAL nI
   LOCAL _hash
   LOCAL _field, _value
   LOCAL _count := 0

   SELECT ( alias )
   GO TOP

   qry:Goto( 1 )

   DO WHILE !qry:Eof()

      APPEND BLANK
      _hash := dbf_get_rec()

      _row := qry:GetRow()
      nI := 1

      FOR nI := 1 TO _row:FCount()
         _field := _row:FieldName( nI )
         IF hb_HHasKey( _hash, Lower( _field ) )
            _value := _row:FieldGet( _row:FieldPos( Lower( _field ) ) )
            IF ValType( _value ) == "C"
               _value := hb_UTF8ToStr( _value )
            ENDIF
            _hash[ Lower( _field ) ] := _value
         ENDIF
      NEXT

      dbf_update_rec( _hash )

      ++ _count

      qry:Skip()

   ENDDO

   RETURN _count



// ------------------------------------------------------------
// vraca hash strukturu iz strukture sql tabele
// ------------------------------------------------------------
FUNCTION _get_hash_from_sql_table( cTable )

   LOCAL _hash := hb_Hash()
   LOCAL _struct := _sql_table_struct( cTable )
   LOCAL nI, _value, _type

   FOR nI := 1 TO Len( _struct )

      _type := _struct[ nI, 2 ]

      IF _type $ "CM"
         _value := ""
      ELSEIF _type == "D"
         _value := CToD( "" )
      ELSEIF _type == "N"
         _value := 0
      ENDIF

      _hash[ Lower( _struct[ nI, 1 ] ) ] := _value

   NEXT

   RETURN _hash


// --------------------------------------------------------------------
// kreira update qry iz hash tabele
// --------------------------------------------------------------------
STATIC FUNCTION _create_updatecQuery_from_hash( cTable, hash, where_key_fields )

   LOCAL cQuery, _key
   LOCAL nI

   cQuery := "WITH tmp AS ( "

   cQuery += "UPDATE " + cTable
   cQuery += " SET "

   FOR EACH _key in hash:keys
      IF ValType( hash[ _key ] ) == "N"
         cQuery += _key + " = " + Str( hash[ _key ] )
      ELSE
         cQuery += _key + " = " + sql_quote( hash[ _key ] )
      ENDIF

      cQuery += ","
   NEXT

   // ukini zarez
   cQuery := PadR( cQuery, Len( cQuery ) - 1 )

   cQuery += " WHERE "

   FOR nI := 1 TO Len( where_key_fields )
      IF nI > 1
         cQuery += " AND "
      ENDIF

      IF ValType( hash[ where_key_fields[ nI ] ] ) == "N"
         cQuery += where_key_fields[ nI ] + " = " + Str( hash[ where_key_fields[ nI ] ] )
      ELSE
         cQuery += where_key_fields[ nI ] + " = " + sql_quote( hash[ where_key_fields[ nI ] ] )
      ENDIF

   NEXT

   cQuery += " RETURNING "

   FOR EACH _key in hash:keys
      cQuery += _key + ","
   NEXT

   cQuery := PadR( cQuery, Len( cQuery ) - 1 )

   cQuery += " ) "
   cQuery += " SELECT * FROM tmp;"

   RETURN cQuery


FUNCTION _set_sql_record_to_hash( cTable, id )

   LOCAL _hash

   IF ValType( id ) == "N"
      _hash := _sql_query_record_to_hash( select_all_records_from_table( cTable, NIL, { "id = " + AllTrim( Str( id ) ) } ) )
   ELSE
      _hash := _sql_query_record_to_hash( select_all_records_from_table( cTable, NIL, { "id = " + sql_quote( id ) } ) )
   ENDIF

   RETURN _hash



FUNCTION query_row( row, cField )

   LOCAL _ret := NIL
   LOCAL _type

   _type := row:FieldType( cField )
   _ret := row:FieldGet( row:FieldPos( cField ) )

   IF _type $ "C"
      _ret := hb_UTF8ToStr( _ret )
   ENDIF

   RETURN _ret


/*
/ sql_table_empty("tnal") => .t. ako je sql tabela prazna
*/

FUNCTION sql_table_empty( alias )

   LOCAL hRec := get_a_dbf_rec( alias, .T. )

   IF hRec[ "temp" ]
      RETURN .T.
   ENDIF

   RETURN table_count( f18_sql_schema(hRec[ "cTable" ]) ) == 0

/*
FUNCTION sql_from_adbf( aDbf, cTable )

   LOCAL i
   LOCAL cRet := ""
   LOCAL cField, cFieldPrefix := ""

   IF cTable != NIL
      cFieldPrefix := cTable + "."
   ENDIF


   FOR i := 1 TO Len( aDbf )

      cField := cFieldPrefix + aDbf[ i, 1 ]

      DO CASE
      CASE aDbf[ i, 2 ] == "C"
         // naz2::char(4)
         cRet += cField + "::char(" + AllTrim( Str( aDbf[ i, 3 ] ) ) + ")"

      CASE aDbf[ i, 2 ] == "N"
         // COALESCE(kurs1,0)::numeric(18,8) AS kurs1
         cRet += "COALESCE(" + cField + ",0)::numeric(" + ;
            AllTrim( Str( aDbf[ i, 3 ] ) ) + "," + AllTrim( Str( aDbf[ i, 4 ] ) ) + ")"

      CASE aDbf[ i, 2 ] == "I"
         cRet += "COALESCE(" + cField + ",0)::integer"


      CASE aDbf[ i, 2 ] == "D"
         // (CASE WHEN datum IS NULL THEN '1960-01-01'::date ELSE datum END) AS datum
         cRet += "(CASE WHEN " + cField + "IS NULL THEN '1960-01-01'::date ELSE " + cField + ;
            " END)"

      OTHERWISE
         MsgBeep( "ERROR sql_from_adbf field type !" )
         RETURN NIL
      ENDCASE
      cRet += " AS " + aDbf[ i, 1 ]

      IF i < Len( aDbf )
         cRet += ","
      ENDIF

   NEXT

   RETURN cRet
*/


FUNCTION sql_from_adbf( aDbf, cTable )

   LOCAL i
   LOCAL cRet := ""
   LOCAL cField, cFieldPrefix := ""

   IF cTable != NIL
      cFieldPrefix := cTable + "."
   ENDIF


   FOR i := 1 TO Len( aDbf )

      cField := cFieldPrefix + aDbf[ i, 1 ]

      DO CASE
      //CASE aDbf[ i, 2 ] == "C"
         // naz2::char(4)
      //   cRet += cField + "::char(" + AllTrim( Str( aDbf[ i, 3 ] ) ) + ")"

      //CASE aDbf[ i, 2 ] == "N"
      //   // COALESCE(kurs1,0)::numeric(18,8) AS kurs1
      //   cRet += "COALESCE(" + cField + ",0)::numeric(" + ;
      //      AllTrim( Str( aDbf[ i, 3 ] ) ) + "," + AllTrim( Str( aDbf[ i, 4 ] ) ) + ")"

      //CASE aDbf[ i, 2 ] == "I"
      //   cRet += "COALESCE(" + cField + ",0)::integer"


      CASE aDbf[ i, 2 ] == "D"
         // (CASE WHEN datum IS NULL THEN '1960-01-01'::date ELSE datum END) AS datum
         cRet += "(CASE WHEN " + cField + "IS NULL THEN '1960-01-01'::date ELSE " + cField + ;
            " END)"

      OTHERWISE
         //MsgBeep( "ERROR sql_from_adbf field type !" )
         //RETURN NIL
          cRet += cField
      ENDCASE
      cRet += " AS " + aDbf[ i, 1 ]

      IF i < Len( aDbf )
         cRet += ","
      ENDIF

   NEXT

   RETURN cRet
