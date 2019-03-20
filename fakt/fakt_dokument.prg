/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"



CLASS FaktDokument

   ACCESS     idfirma         METHOD get_idfirma()
   ASSIGN     idfirma         METHOD set_idfirma()
   ACCESS     idtipdok        INLINE ::p_idtipdok
   ASSIGN     idtipdok        METHOD set_idtipdok()
   ACCESS     brdok           INLINE ::p_brdok
   ASSIGN     brdok           METHOD set_brdok()

   ACCESS     broj            INLINE ::p_idfirma + "/" + ::p_idtipdok + "/" + ::p_brdok

   ACCESS     error_message   INLINE ::err_msg

   // info vraca hash matricu:
   // neto_vrijednost, broj_stavki, distinct_roba, datdok, idpartner
   ACCESS     info            METHOD get_info()
   METHOD     refresh_info()

   METHOD     change_idtipdok( new_idtipdok )
   METHOD     refresh_dbfs()

   METHOD     New()
   METHOD     exists()

   // markiran
   ACCESS     mark     INLINE  ::p_marked
   ASSIGN     mark     METHOD   set_mark()

   PROTECTED:

   // access assign metodi dodaju "_" prefix
   DATA       p_idfirma
   DATA       p_idtipdok
   DATA       p_brdok
   DATA       p_h_info

   DATA       p_marked      INIT  .F.

   DATA       err_msg        INIT ""
   DATA       p_server
   DATA       p_sql_where
   METHOD     set_sql_where()

ENDCLASS


METHOD FaktDokument:New( idfirma, idtipdok, brdok, server )

   ::p_idfirma := idfirma
   ::p_idtipdok := idtipdok
   ::p_brdok := brdok

/*
   if server == NIL
      ::_server := sql_data_conn()
   else
      ::_server := server
   endif
*/


   ::set_sql_where()

   RETURN SELF

METHOD FaktDokument:get_idfirma()
   return ::p_idfirma

METHOD FaktDokument:set_idfirma( val )

   ::p_idfirma := val
   ::set_sql_where()

   RETURN .T.

METHOD FaktDokument:set_idtipdok( val )

   ::p_idtipdok := val
   ::set_sql_where()

   RETURN .T.


METHOD FaktDokument:set_brdok( val )

   ::p_brdok := val
   ::set_sql_where()

   RETURN .T.


METHOD FaktDokument:set_sql_where()

   ::p_sql_where := "idfirma=" + sql_quote( ::p_idfirma )
   ::p_sql_where += " AND idtipdok=" + sql_quote( ::p_idtipdok )
   ::p_sql_where += " AND brdok=" + sql_quote( ::p_brdok )

   RETURN .T.


METHOD FaktDokument:exists()

   LOCAL _ret
   LOCAL cQuery := "SELECT count(*)  FROM " + f18_sql_schema( "fakt_doks" ) + " WHERE " + ::p_sql_where

   _ret := cQuery:FieldGet( 1 )

   IF _ret > 1
      ::err_msg := "Dokument dupliran !?  cnt=" + to_str( _ret )
      log_write( ::err_msg, 2 )
      MsgBeep( ::err_msg )
      RETURN .F.
   ENDIF

   _ret := cQuery:FieldGet( 1 )

   RETURN _ret


METHOD FaktDokument:refresh_info()

   ::p_h_info := NIL

   return ::info


METHOD FaktDokument:get_info()

   LOCAL _ret := hb_Hash()
   LOCAL cQuery
   LOCAL _qry_str

   if ::p_h_info != NIL
      return ::p_h_info
   ENDIF

   _qry_str := "SELECT sum(kolicina * cijena * (1-Rabat/100)) from " + f18_sql_schema( "fakt_fakt" ) + " WHERE " + ::p_sql_where
   cQuery := run_sql_query( _qry_str )
   _ret[ "neto_vrijednost" ] := cQuery:FieldGet( 1 )

   _qry_str := "SELECT count(*) from " + f18_sql_schema( "fakt_fakt" ) + " WHERE " + ::p_sql_where
   cQuery := run_sql_query( _qry_str )
   _ret[ "broj_stavki" ] := cQuery:FieldGet( 1 )

   _qry_str := "SELECT DISTINCT(idroba) from " + f18_sql_schema( "fakt_fakt" ) + " WHERE " + ::p_sql_where
   cQuery := run_sql_query( _qry_str )

   _ret[ "distinct_idroba" ] := {}
   DO WHILE !cQuery:Eof()
      AAdd( _ret[ "distinct_idroba" ], cQuery:FieldGet( 1 ) )
      cQuery:skip()
   ENDDO

   _qry_str := "SELECT datdok, idpartner from " + f18_sql_schema( "fakt_doks" ) + " WHERE " + ::p_sql_where
   cQuery := run_sql_query( _qry_str )
   _ret[ "datdok" ] := cQuery:FieldGet( 1 )
   _ret[ "idpartner" ] := cQuery:FieldGet( 2 )

   ::p_h_info := _ret

   RETURN _ret


METHOD FaktDokument:set_mark( val )

   ::p_marked := val

   RETURN .T.


METHOD FaktDokument:refresh_dbfs()

   LOCAL _ids_fakt := {}, _ids_doks := {}
   LOCAL _tmp_id

   _tmp_id := ::p_idfirma + ::p_idtipdok + ::p_brdok
   AAdd( _ids_fakt, "#2" + _tmp_id )
   AAdd( _ids_doks,  _tmp_id )

   // i na moj semafor stavi ovaj id da bih
   // pokupio stanje sa servera
   push_ids_to_semaphore( "fakt_fakt",  _ids_fakt, .T. )
   push_ids_to_semaphore( "fakt_doks",  _ids_doks, .T. )
   push_ids_to_semaphore( "fakt_doks2", _ids_doks, .T. )

   RETURN .T.


METHOD FaktDokument:change_idtipdok( new_idtipdok )

   LOCAL _sql, cQuery
   LOCAL cSqlTempTable := f18_user() + "_tmp_fakt_atributi"

   cSqlTempTable := StrTran( cSqlTempTable, "-", "_")  // ernad.husremovic_tmp_fakt_atributi - ernad_husremovic_tmp_fakt_atributi
   cSqlTempTable := StrTran( cSqlTempTable, "@", "_")  // ernad@husremovic_tmp_fakt_atributi - ernad_husremovic_tmp_fakt_atributi
   cSqlTempTable := StrTran( cSqlTempTable, ".", "_")  // ernad-husremovic_tmp_fakt_atributi - ernad_husremovic_tmp_fakt_atributi

   // prvo sve u temp tabeli uraditi
   _sql := "DROP TABLE IF EXISTS " + cSqlTempTable
   _sql += ";"
   _sql += "CREATE TEMP TABLE " + cSqlTempTable + " AS "
   _sql += "SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt_atributi WHERE " + ::p_sql_where
   _sql += ";"
   _sql += "UPDATE " + cSqlTempTable + " SET idtipdok=" + sql_quote( new_idtipdok )
   _sql += ";"
   _sql += "DELETE FROM " + F18_PSQL_SCHEMA_DOT + "fakt_fakt_atributi "
   _sql += " WHERE " + ::p_sql_where
   _sql += ";"


   _sql += "UPDATE " + F18_PSQL_SCHEMA_DOT + "fakt_fakt set idtipdok=" + sql_quote( new_idtipdok )
   _sql += " WHERE " + ::p_sql_where
   _sql += ";"

   _sql += "UPDATE " + F18_PSQL_SCHEMA_DOT + "fakt_doks set idtipdok=" + sql_quote( new_idtipdok )
   _sql += " WHERE " + ::p_sql_where
   _sql += ";"

   _sql += "UPDATE " + F18_PSQL_SCHEMA_DOT + "fakt_doks2 set idtipdok=" + sql_quote( new_idtipdok )
   _sql += " WHERE " + ::p_sql_where
   _sql += ";"

   _sql += "INSERT INTO " + F18_PSQL_SCHEMA_DOT + "fakt_fakt_atributi (SELECT * from " + cSqlTempTable + ")"

   cQuery := run_sql_query( _sql )

   IF !sql_error_in_query( cQuery )
      ::refresh_dbfs()
      ::p_idtipdok := new_idtipdok
      ::refresh_dbfs()
      RETURN .T.
   ENDIF

   RETURN .F.
