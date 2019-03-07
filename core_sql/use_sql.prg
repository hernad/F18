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

FIELD ID, NAZ, IDJ, IDKAN, IDN0, IDPARTNER, GODINA, OBR
FIELD IDOPS, RACUN
FIELD BARKOD, fisc_plu

FUNCTION use_sql_sif( cTable, lMakeIndex, cAlias, cId )

   LOCAL pConn
   LOCAL nI, cMsg, cLogMsg := ""
   LOCAL cQuery, oError

   IF Used()
      USE
   ENDIF

   IF lMakeIndex == NIL
      lMakeIndex = .T.
   ENDIF

   IF cAlias == NIL
      cAlias := cTable
   ENDIF

   pConn := sql_data_conn():pDB

   IF HB_ISNIL( pConn )
      error_bar( "PSQL", "SQLMIX pDB NIL?! " + cTable )
      RETURN .F.
   ENDIF

   rddSetDefault( "SQLMIX" )

   IF rddInfo( 1001, { "POSTGRESQL", pConn } ) == 0  // #define RDDI_CONNECT          1001
      LOG_CALL_STACK cLogMsg
      ?E "Unable connect to the PSQLserver", cLogMsg
      error_bar( "PSQL", "SQLMIX connect " + cTable )
      RETURN .F.
   ENDIF

   cQuery := "SELECT * FROM " + f18_sql_schema( cTable )

   IF cId != NIL
      cQuery += " WHERE id=" + sql_quote( cId ) // select from fmk.partn where id='BRING01'
   ENDIF


   BEGIN SEQUENCE WITH {| err | Break( err ) }

      dbUseArea( .F., "SQLMIX", cQuery,  cAlias, NIL, NIL )

   RECOVER USING oError
      ?E cTable, cQuery, oError:description
      RaiseError( "use_sql_sif:" + cTable + " qry=" + cQuery )
      // MsgBeep( "SQL ERROR: " + cTable + "##" + Right( cQuery, f18_max_cols() - 10 ) + "##" + oError:description  )
      // QUIT_1
   END SEQUENCE


   IF lMakeIndex

      IF cTable == "os_os" .OR. cTable == "sii_sii"

         index_os_sii( cAlias )

         SET ORDER TO TAG "1"

      ELSEIF cTable == "os_promj" .OR. cTable == "sii_promj"

         INDEX ON id + tip + DToS( datum ) + opis  TAG "1" TO ( cAlias )
         SET ORDER TO TAG "1"

      ELSEIF cTable == "ld_radn" // RADN je izuzetak sa imenima tagova "1", "2"
         INDEX ON ID TAG "1" TO ( cAlias )
         IF FieldPos( "NAZ" ) > 0
            INDEX ON NAZ TAG "2" TO ( cAlias )
         ENDIF
         SET ORDER TO TAG "1"

      ELSEIF cTable == "ld_obracuni"

         INDEX ON rj + Str( godina, 4, 0 ) + Str( mjesec, 2, 0 ) + STATUS + obr TAG RJ  TO ( cAlias )
         SET ORDER TO TAG "RJ"

      ELSEIF cTable == "ld_parobr"

         INDEX ON id + godina + obr TAG ID TO ( cAlias ) // id sadrzi informaciju o mjesecu
         SET ORDER TO TAG "ID"

      ELSEIF cTable == "ops"

         INDEX ON ID TAG "ID" TO ( cAlias )
         INDEX ON NAZ TAG "NAZ" TO ( cAlias )
         INDEX ON IDJ TAG "IDJ" TO ( cAlias )
         INDEX ON IDKAN TAG "IDKAN" TO ( cAlias )
         INDEX ON IDN0 TAG "IDN0" TO ( cAlias )
         SET ORDER TO TAG "ID"

      ELSEIF cTable == "dest"

         INDEX ON field->IDPARTNER + field->ID TAG "ID" TO ( cAlias )
         INDEX ON ID TAG "IDDEST" TO ( cAlias )
         SET ORDER TO TAG "ID"

      ELSEIF cTable == "jprih"
         INDEX ON  id + IdOps + IdKan + IdN0 + Racun TAG "ID" TO  ( cAlias )
         INDEX ON  Naz + IdOps TAG "NAZ" TO  ( cAlias )
         SET ORDER TO TAG "ID"


      ELSEIF cTable == "roba"
         INDEX ON ID TAG "ID" TO ( cAlias )
         INDEX ON Left( NAZ, 40 ) TAG "NAZ" TO ( cAlias )
         INDEX ON barkod TAG "BARKOD" TO ( cAlias )
         // INDEX ON SIFRADOB TAG "SIFRADOB" TO ( cAlias )
         INDEX ON Str( fisc_plu, 10 ) TAG "PLU" TO ( cAlias )
         INDEX ON id + tip TAG "IDP" TO ( cAlias ) FOR tip = "P"
         SET ORDER TO TAG "ID"

      ELSEIF cTable == "sast"
         INDEX ON field->ID + field->ID2 TAG "ID" TO ( cAlias )
         INDEX ON field->ID + Str( field->R_BR, 4, 0 ) + field->ID2 TAG "IDRBR" TO ( cAlias )
         INDEX ON field->ID2 + field->ID TAG "NAZ" TO ( cAlias )
         SET ORDER TO TAG "ID"

      ELSEIF cTable == "pos_osob"
         INDEX ON KorSif TAG "ID" TO ( cAlias )
         INDEX ON NAZ TAG "NAZ" TO ( cAlias )

      ELSE
         INDEX ON ID TAG "ID" TO ( cAlias )
         IF FieldPos( "NAZ" ) > 0
            INDEX ON NAZ TAG "NAZ" TO ( cAlias )
         ENDIF
         SET ORDER TO TAG "ID"
      ENDIF

      GO TOP
   ENDIF

   rddSetDefault( "DBFCDX" )

   RETURN .T.


FUNCTION f18_sql_schema( cTable )

   LOCAL aF18Tables := { "tarifa", "kalk_kalk", "kalk_doks", "roba", "koncij", "partn", "valute", "konto", "tnal", "tdok", "sifk", "sifv", "trfp" }
   IF "." $ cTable
      RETURN cTable
   ENDIF

if cTable == "tarifa"
altd()
endif
   IF AScan( aF18Tables, cTable ) > 0
      RETURN "public." + cTable
   ENDIF


   RETURN sql_primarna_schema() + "." + cTable


FUNCTION use_sql( cTable, cSqlQuery, cAlias )

   LOCAL pConn, oError
   LOCAL nI, cMsg, cLogMsg := ""
   LOCAL nWa
   LOCAL lError := .F.
   LOCAL lOpenInNewArea := .F.

   IF ValType( sql_data_conn() ) != "O"
      RETURN .F.
   ENDIF

   pConn := sql_data_conn():pDB
   IF HB_ISNIL( pConn )
      error_bar( "SQL", "SQLMIX pDB NIL?!" + cTable )
      RETURN .F.
   ENDIF

   rddSetDefault( "SQLMIX" )
   IF rddInfo( 1001, { "POSTGRESQL", pConn } ) == 0  // #define RDDI_CONNECT          1001
      LOG_CALL_STACK cLogMsg
      ?E "Unable connect to the PSQLserver", cLogMsg
      error_bar( "SQL", "SQLMIX connect " + cTable )
      lError := .T.
   ENDIF

   IF cAlias == NIL
      cAlias := cTable
      nWa := Select( cTable )
      IF nWa > 0
         SELECT ( nWa )
         USE
         dbSelectArea( nWa )
      ENDIF
   ELSE
      IF cAlias == "_NEW_WA_"
         lOpenInNewArea := .T.
         cAlias := cTable
      ENDIF
      nWa := Select( cAlias )
      IF nWa > 0
         SELECT ( nWa )
         USE
         dbSelectArea( nWa )
      ENDIF
   ENDIF

   BEGIN SEQUENCE WITH {| err | Break( err ) }
      dbUseArea( lOpenInNewArea, "SQLMIX", cSqlQuery, cAlias )
      IF Used() .AND. my_rddName() == "SQLMIX" .AND. Select( cAlias ) > 0
         lError := .F.
      ELSE
         ?E "ERROR dbUseArea SQLMIX:", cSqlQuery, "Alias:", cAlias
         error_bar( "SQLMIX", "ERR: use_sql" + cSqlQuery )
         lError := .T.
      ENDIF

   RECOVER USING oError
      ?E "SQL ERR:", oError:description, cSqlQuery
      error_bar( "SQL", "ERR: use_sql" + oError:description + " " + cSqlQuery )
      lError := .T.
   END SEQUENCE

   rddSetDefault( "DBFCDX" )

   RETURN !lError



FUNCTION my_dbSelectArea( xArea )

   RETURN dbSelectArea( xArea )





/*
   use_sql_valute() => otvori šifarnik valuta sa prilagođenim poljima
*/
FUNCTION use_sql_valute( cId )

   LOCAL cSql
   LOCAL cTable := "valute"

   cSql := "SELECT "
   cSql += "id, "
   cSql += "match_code::char(10),"
   cSql += "naz::char(30),"
   cSql += "naz2::char(4),"
   cSql += "(CASE WHEN datum IS NULL THEN '1960-01-01'::date ELSE datum END) AS datum,"
   cSql += "COALESCE(kurs1,0)::numeric(18,8) AS kurs1,"
   cSql += "COALESCE(kurs2,0)::numeric(18,8) AS kurs2,"
   cSql += "COALESCE(kurs3,0)::numeric(18,8) AS kurs3,"
   cSql += "tip::char(1) "
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + "valute ORDER BY id"

   IF cId != NIL
      cSql += " WHERE id=" + sql_quote( cId )
   ENDIF

   SELECT F_VALUTE
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   INDEX ON ID TAG ID TO ( cTable )
   INDEX ON TIP + ID + DToS( DATUM ) TAG NAZ TO ( cTable )
   INDEX ON ID + DToS( DATUM ) TAG ID2 TO ( cTable )

   SET ORDER TO TAG ID
   GO TOP

   RETURN !Eof()


/*
   use_sql_ks() => otvori šifarnik kamatnih stopa sa prilagođenim poljima
*/

FUNCTION use_sql_ks()

   LOCAL cSql
   LOCAL cTable := "ks"

   cSql := "SELECT "
   cSql += "  id, "
   cSql += "  naz, "
   cSql += "  datod, "
   cSql += "  datdo, "
   cSql += "  COALESCE(strev,0)::numeric(8,4) AS strev, "
   cSql += "  COALESCE(stkam,0)::numeric(8,4) AS stkam, "
   cSql += "  COALESCE(den,0)::numeric(15,6) AS den, "
   cSql += "  tip::char(1), "
   cSql += "  COALESCE(duz,0)::numeric(4,0) AS duz "
   cSql += "FROM " + F18_PSQL_SCHEMA_DOT + "ks "
   cSQL += "ORDER BY id"


   SELECT ( F_KS )
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   INDEX ON ID TAG ID TO ( cTable )
   INDEX ON DToS( DATOD ) TAG "2" TO ( cTable )

   SET ORDER TO TAG ID

   RETURN .T.



/*
   use_sql_pkonto() => otvori šifarnik pkonto sa prilagođenim poljima
*/

FUNCTION use_sql_pkonto()

   LOCAL cSql
   LOCAL cTable := "pkonto"

   cSql := "SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "pkonto ORDER BY id"

   SELECT F_PKONTO
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   INDEX ON ID TAG ID TO ( cTable )
   INDEX ON TIP TAG NAZ TO ( cTable )

   SET ORDER TO TAG ID

   RETURN .T.






/*
   use_sql_tarifa() => otvori šifarnik tarifa sa prilagođenim poljima
*/

FUNCTION use_sql_tarifa( lMakeIndex )

   LOCAL cSql
   LOCAL cTable := f18_sql_schema( "tarifa" )

   IF lMakeIndex == NIL
      lMakeIndex := .T.
   ENDIF

   cSql := "SELECT "
   cSql += "  id, "
   cSql += "  naz, "
   cSql += "  COALESCE(pdv,0)::numeric(6,2) AS pdv, "
   cSql += "  match_code::char(10) "
   cSql += "FROM " + f18_sql_schema("tarifa")
   cSQL += " ORDER BY id"

   SELECT F_TARIFA
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   IF lMakeIndex
      INDEX ON ID TAG ID TO ( cTable )
      INDEX ON NAZ TAG NAZ TO ( cTable )
   ENDIF

   SET ORDER TO TAG ID
   GO TOP

   RETURN .T.


/*
   use_sql_trfp() => otvori šifarnik šema kontiranja kalk->fin sa uslovima
*/
FUNCTION use_sql_trfp( cShema, cDok )
   RETURN _use_sql_trfp( "trfp", F_TRFP, cShema, cDok )


/*
   use_sql_trfp2() => otvori šifarnik šema kontiranja fakt->fin sa uslovima
*/
FUNCTION use_sql_trfp2( cShema, cDok )
   RETURN _use_sql_trfp( "trfp2", F_TRFP2, cShema, cDok )



/*
   use_sql_trfp() => otvori šifarnik šema kontiranja sa uslovima
*/

STATIC FUNCTION _use_sql_trfp( cTable, nWa, cShema, cDok )

   LOCAL cSql
   LOCAL cWhere := ""

   cSql := "SELECT * FROM " + f18_sql_schema( cTable )

   IF cShema <> NIL
      cWhere += " shema = " + sql_quote( cShema )
   ENDIF

   IF cDok <> NIL .AND. !Empty( cDok )
      IF !Empty( cWhere )
         cWhere += " AND "
      ENDIF
      cWhere += " idvd = " + sql_quote( cDok )
   ENDIF

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
   ENDIF

   cSql += " ORDER BY idvd, shema, idkonto, id, idtarifa, idvn, naz"

   SELECT ( nWa )
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   INDEX ON ( field->idvd + field->shema + field->idkonto + field->id + field->idtarifa + field->idvn + field->naz )  TAG ID TO ( cTable )

   SET ORDER TO TAG "ID"

   RETURN .T.




FUNCTION o_sifk( cDbf )

   Select( F_SIFK )
   USE

   RETURN use_sql_sifk( cDbf )

/*
   use_sql_sifk() => otvori citavu tabelu
   use_sql_sifk( "ROBA", "GR1  " ) =>  filter na ROBA/GR1
*/

FUNCTION use_sql_sifk( cDbf, cOznaka )

   LOCAL cSql
   LOCAL cTable := "sifk"


#ifdef F18_DEBUG_THREAD

   ?E "USE SQL SIFK in main thread:", is_in_main_thread()
#endif

   cSql := "SELECT * from " + F18_PSQL_SCHEMA_DOT + "sifk"
   IF cDbf != NIL
      cSql += " WHERE id=" + sql_quote( cDbf )
   ENDIF
   IF cOznaka != NIL
      cSql += " AND oznaka=" + sql_quote( cOznaka )
   ENDIF

   cSQL += " ORDER BY id,oznaka,sort"
   SELECT ( F_SIFK )
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   // IF cDbf == NIL .AND. cOznaka == NIL
   INDEX ON field->ID + field->SORT + field->NAZ TAG ID  TO ( cTable )
   INDEX ON field->ID + field->OZNAKA TAG ID2  TO ( cTable )
   INDEX ON field->NAZ  TAG NAZ TO ( cTable )
   SET ORDER TO TAG ID
   // ENDIF

   GO TOP  // ovo obavezno inace ostane na eof() poziciji?!

   RETURN !Eof()



FUNCTION o_sifv( cDbf )

   Select( F_SIFV )
   USE

   RETURN use_sql_sifv( cDbf )

FUNCTION o_sifk_sifv_empty( cDbf )

   o_sifk( "XXXX" )
   o_sifv( "XXXX" )

   RETURN .T.

/*
   use_sql_sifv( "ROBA", "GR1", NIL, "G000000001" ) =>  filter na ROBA/GR1/grupa1=G0000000001
   use_sql_isfv( "ROBA", "GR1", "ROBA99", NIL )        =>  filter na ROBA/GR1/idroba=ROBA99
*/

FUNCTION use_sql_sifv( cDbf, cOznaka, xIdSif, xVrijednost )

   LOCAL cSql
   LOCAL cTable := "sifv"
   LOCAL uIdSif, uVrijednost

   IF cDbf == NIL
      SELECT F_SIFK
      IF !Used()
         Alert( "USE_SQL Prije SIFV mora se otvoriti SIFK !" )
         QUIT_1
      ENDIF
      cDbf := field->id
      cOznaka := field->oznaka
   ENDIF

   cSql := "SELECT * from " + F18_PSQL_SCHEMA_DOT + "sifv"
   cSql += " WHERE id=" + sql_quote( cDbf )

   IF cOznaka != "*" // * - sve oznake
      cSql += " AND oznaka=" + sql_quote( cOznaka )
   ENDIF

   IF xIdSif == NIL
      IF Empty( cDbf )
         uIdSif := "MLFJUSXX" // navodi se namjerno nepostojeca sifra da bi se otvorila tabela sa 0 zapisa, slucajevi kada trebamo samo sif otvoreno radno podrucje - strukturu tabele
      ELSEIF xVrijednost == NIL  // samo ako je i xVrijednost NIL onda definisi uslov idsif

         IF ( cDbf )->( Used() )
            xIdSif := ( cDbf )->id
         ELSE
            xIdSif := Space( 6 )
         ENDIF
         cSql += " AND idsif=" + sql_quote( xIdSif )
      ENDIF
   ELSE
      cSql += " AND idsif=" + sql_quote( xIdSif )
   ENDIF

   IF xVrijednost != NIL
      cSql += " AND naz=" + sql_quote( xVrijednost )
   ENDIF

   cSQL += " ORDER BY id,oznaka,idsif,naz"
   SELECT F_SIFV
   IF !use_sql( "sifv", cSql )
      ?E "use_sql sifv ERROR", cSql
      RETURN .F.
   ENDIF

   GO TOP

/*
   INDEX ON ID + OZNAKA + IDSIF + NAZ TAG ID  TO ( cTable )
   INDEX ON ID + IDSIF TAG IDIDSIF  TO ( cTable )
   SET ORDER TO TAG "ID"
   GO TOP
*/

   RETURN !Eof()


/*
  kreiranje tabela "rules"
*/

FUNCTION use_sql_rules()

   LOCAL _table_name, _alias
   LOCAL cSql

   _alias := "FMKRULES"
   _table_name := "f18_rules"

   cSql := "SELECT * FROM " + F18_PSQL_SCHEMA_DOT + _table_name

   SELECT F_RULES
   IF !use_sql( _alias, cSql )
      RETURN .F.
   ENDIF

   INDEX ON Str( RULE_ID, 10 )   TAG 1 TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + Str( RULE_NO, 10 )  TAG 2 TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + Str( RULE_LEVEL, 2 ) + Str( RULE_NO, 10 ) TAG 3 TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + RULE_C1 + RULE_C2  TAG 4 TO ( _table_name )
   // kreiranje rules index-a specificnih za rnal
   INDEX ON MODUL_NAME + RULE_OBJ + RULE_C3 + RULE_C4   TAG ELCODE TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + RULE_C3 + Str( RULE_NO, 5 ) TAG RNART1 TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + RULE_C5 + Str( RULE_NO, 5 ) TAG ITEM1  TO ( _table_name )
   // kreiranje rules index-a specificnih za fin
   INDEX ON MODUL_NAME + RULE_OBJ + Str( RULE_NO, 5 ) TAG FINKNJ1 TO ( _table_name )
   INDEX ON MODUL_NAME + RULE_OBJ + RULE_C3  TAG OBJC3 TO ( _table_name )

   RETURN .T.
