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


FUNCTION o_roba( cId )

   LOCAL cTabela := "roba"

   SELECT ( F_ROBA )
   IF !use_sql_sif( cTabela, .T., "ROBA", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION o_adres( cId )

   LOCAL cTabela := "adres", cAlias := "ADRES"

   SELECT ( F_ADRES )
   IF !use_sql_sif  ( cTabela, .T., cAlias, cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION find_roba_by_naz_or_id( cId )

   LOCAL cAlias := "ROBA"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( "roba" )
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql
   cSqlQuery += " OR sifradob ilike " + cIdSql

   IF roba_barkod_pri_unosu()
      cSqlQuery += " OR barkod ilike " + cIdSql
   ENDIF

   IF !use_sql( "roba", cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   INDEX ON SIFRADOB TAG SIFRADOB TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()


FUNCTION find_roba_p_by_naz_or_id( cId )

   LOCAL cAlias := "ROBA_P"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( "roba" )
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE tip='P' "
   cSqlQuery += " AND ("
   cSqlQuery += " id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql
   cSqlQuery += " OR sifradob ilike " + cIdSql
   cSqlQuery += ")"

   IF !use_sql( "roba_p", cSqlQuery, cAlias )
      RETURN .F.
   ENDIF
   INDEX ON ID TAG ID TO ( cAlias )
   INDEX ON NAZ TAG NAZ TO ( cAlias )
   SET ORDER TO TAG "ID"

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()


FUNCTION select_o_roba( cId )

   SELECT ( F_ROBA )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSEIF cId != NIL .AND. cId == roba->id
         RETURN .T. // vec pozicionirani na roba.id
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_roba( cId )


FUNCTION roba_update_vpc( cId, nVpc )

   LOCAL oQry, cSql := "update " + f18_sql_schema( "roba" ) + " set vpc=" + sql_quote( nVpc )

   cSql := " WHERE id=" + sql_quote( cId )

   oQry := run_sql_query( cSql  )

   IF sql_error_in_query( oQry, "UPDATE" )
      RETURN .F.
   ENDIF

   RETURN .T.



FUNCTION roba_max_fiskalni_plu()

   LOCAL nPlu := 0
   LOCAL cSql, oQuery

   cSql := "SELECT MAX( fisc_plu ) AS max_plu FROM " + f18_sql_schema( "roba" )
   oQuery := run_sql_query( cSql )

   nPlu := query_row( oQuery, "max_plu" )

   RETURN nPlu


/*
   roba je aktivna ako je u u tekucoj bazi bilo prometa
*/

FUNCTION is_roba_aktivna( cIdRoba )

   LOCAL nCnt
   LOCAL cSql, oQuery

   cSql := "SELECT count(idroba) AS cnt FROM " + f18_sql_schema( "kalk_kalk" )
   cSql += " WHERE idroba=" + sql_quote( cIdRoba )
   oQuery := run_sql_query( cSql )

   nCnt := query_row( oQuery, "cnt" )

   RETURN nCnt > 0


FUNCTION find_roba_id_by_barkod( cBarkodId )

   LOCAL nCnt
   LOCAL cSql, oQuery

   cSql := "SELECT id FROM " + f18_sql_schema( "roba" )
   cSql += " WHERE barkod=" + sql_quote( cBarkodId )
   cSql += " LIMIT 1"
   oQuery := run_sql_query( cSql )

   RETURN query_row( oQuery, "id" )


FUNCTION find_roba_by_sifradob( cIdSifraDob, cOrderBy, cWhere )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "id,naz" )

   IF Len( Trim( cIdSifraDob ) ) < 5 // https://redmine.bring.out.ba/issues/36373
      cIdSifraDob := PadL( Trim( cIdSifraDob ), 5, "0" ) // 7148 => 07148, 22 => 00022
   ENDIF

   IF cIdSifraDob <> NIL
      hParams[ "sifradob" ] := cIdSifraDob
   ENDIF
   hParams[ "order_by" ] := cOrderBy

   hParams[ "indeks" ] := .F.

   IF cWhere != NIL
      hParams[ "where" ] := cWhere
   ENDIF
   IF !use_sql_roba( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()


FUNCTION find_roba_by_id( cId, lCheckOnly, cWhere )

   LOCAL hParams := hb_Hash()

   hb_default( @lCheckOnly, .F. )

   IF lCheckOnly
      hParams[ "check_only" ] := .T.
   ENDIF

   IF cId <> NIL
      hParams[ "id" ] := cId
   ENDIF

   // hParams[ "order_by" ] := cOrderBy


   hParams[ "indeks" ] := .F.

   IF cWhere != NIL
      hParams[ "where" ] := cWhere
   ENDIF

   IF !use_sql_roba( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()



FUNCTION find_roba_by_id_sintetika( cId, lCheckOnly, cWhere )

   LOCAL hParams := hb_Hash()

   hb_default( @lCheckOnly, .F. )

   IF lCheckOnly
      hParams[ "check_only" ] := .T.
   ENDIF

   IF cId <> NIL
      hParams[ "id" ] := cId
   ENDIF

   hParams[ "sintetika" ] := .T.  // pretraga sa LIKE  idç%
   hParams[ "indeks" ] := .F.

   IF cWhere != NIL
      hParams[ "where" ] := cWhere
   ENDIF

   IF !use_sql_roba( hParams )
      RETURN .F.
   ENDIF

   GO TOP

   RETURN ! Eof()



FUNCTION find_roba_by_barkod( cBarkod, cOrderBy, cWhere )

   LOCAL hParams := hb_Hash()

   hb_default( @cOrderBy, "id,naz" )

   IF cBarkod <> NIL
      hParams[ "barkod" ] := cBarkod
   ENDIF
   hParams[ "order_by" ] := cOrderBy

   hParams[ "indeks" ] := .F.

   IF cWhere != NIL
      hParams[ "where" ] := cWhere
   ENDIF
   IF !use_sql_roba( hParams )
      RETURN .F.
   ENDIF
   GO TOP

   RETURN ! Eof()



FUNCTION kalk_aktivna_konta_magacin( cIdRoba )
   RETURN kalk_aktivna_konta( "mkonto", cIdRoba )

/*
   cKontoTip - mkonto ili pkonto
*/
FUNCTION kalk_aktivna_konta( cKontoTip, cIdRoba )

   LOCAL cSql, cKonto
   LOCAL oQry, oRow, aKonta := {}

   cSql :=  "SELECT distinct( " + cKontoTip + ") AS kto FROM "  + f18_sql_schema( "kalk_kalk " )
   cSql += " WHERE idroba=" + sql_quote( cIdRoba )
   cSql += " ORDER BY " + cKontoTip

   oQry := run_sql_query( cSql )
   DO WHILE !oQry:Eof()
      oRow := oQry:GetRow()
      AAdd( aKonta, oRow:FieldGet( oRow:FieldPos( "kto" ) ) )
      oQry:skip()
   ENDDO

   RETURN aKonta



FUNCTION kalk_kol_stanje_artikla_magacin( cIdKontoMagacin, cIdRoba, dDatumDo )

   LOCAL cSql, oQry
   LOCAL oRow
   LOCAL nStanje

   IF dDatumDo == NIL
      dDatumDo := Date()
   ENDIF

   cSql := "SELECT " + ;
      " SUM( " + ;
      " CASE " + ;
      " WHEN mu_i = '1' AND idvd NOT IN ('12', '22', '94') THEN kolicina " + ;
      " WHEN mu_i = '1' AND idvd IN ('12', '22', '94') THEN -kolicina " + ;
      " WHEN mu_i = '5' THEN -kolicina " + ;
      " WHEN mu_i = '8' THEN -kolicina " + ;
      " END ) as stanje_m " + ;
      " FROM " + f18_sql_schema( "kalk_kalk" ) + " " + ;
      " WHERE " + ;
      " idfirma = " + sql_quote( self_organizacija_id() ) + ;
      " AND mkonto = " + sql_quote( cIdKontoMagacin ) + ;
      " AND idroba = " + sql_quote( cIdRoba ) + ;
      " AND " + _sql_date_parse( "datdok", CToD( "" ), dDatumDo )

   oQry := run_sql_query( cSql )
   oRow := oQry:GetRow( 1 )
   nStanje := oRow:FieldGet( oRow:FieldPos( "stanje_m" ) )

   IF ValType( nStanje ) == "L"
      nStanje := 0
   ENDIF

   RETURN nStanje


FUNCTION kalk_kol_stanje_artikla_prodavnica( cIdKontoProdavnica, cIdRoba, dDatumDo )

   LOCAL cSql, oQry
   LOCAL oRow
   LOCAL nStanje

   IF dDatumDo == NIL
      dDatumDo := Date()
   ENDIF

   cSql := "SELECT SUM( CASE WHEN pu_i = '1' THEN kolicina-gkolicina-gkolicin2 " + ;
      " WHEN pu_i = '5' THEN -kolicina " + ;
      " WHEN pu_i = 'I' THEN -gkolicin2 ELSE 0 END ) as stanje_p " + ;
      " FROM " + f18_sql_schema( "kalk_kalk" ) + ;
      " WHERE " + ;
      " idfirma = " + sql_quote( self_organizacija_id() ) + ;
      " AND pkonto = " + sql_quote( cIdKontoProdavnica ) + ;
      " AND idroba = " + sql_quote( cIdRoba ) + ;
      " AND " + _sql_date_parse( "datdok", CToD( "" ), dDatumDo )

   oQry := run_sql_query( cSql )
   oRow := oQry:GetRow( 1 )
   nStanje := oRow:FieldGet( oRow:FieldPos( "stanje_p" ) )

   IF ValType( nStanje ) == "L"
      nStanje := 0
   ENDIF

   RETURN nStanje


/*


CREATE TABLE fmk.roba
(
  id character(10) NOT NULL,
  match_code character(10),
  sifradob character(20),
  naz character varying(250),
  jmj character(3),
  idtarifa character(6),
  nc numeric(18,8),
  vpc numeric(18,8),
  mpc numeric(18,8),
  tip character(1),
  carina numeric(5,2),
  opis text,
  vpc2 numeric(18,8),
  mpc2 numeric(18,8),
  mpc3 numeric(18,8),
  k1 character(4),
  k2 character(4),
  n1 numeric(12,2),
  n2 numeric(12,2),
  plc numeric(18,8),
  mink numeric(12,2),
  _m1_ character(1),
  barkod character(13),
  zanivel numeric(18,8),
  zaniv2 numeric(18,8),
  trosk1 numeric(15,5),
  trosk2 numeric(15,5),
  trosk3 numeric(15,5),
  trosk4 numeric(15,5),
  trosk5 numeric(15,5),
  fisc_plu numeric(10,0),
  k7 character(4),
  k8 character(4),
  k9 character(4),
  strings numeric(10,0),
  idkonto character(7),
  mpc4 numeric(18,8),
  mpc5 numeric(18,8),
  mpc6 numeric(18,8),
  mpc7 numeric(18,8),
  mpc8 numeric(18,8),
  mpc9 numeric(18,8)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fmk.roba
  OWNER TO admin;
GRANT ALL ON TABLE fmk.roba TO admin;
GRANT ALL ON TABLE fmk.roba TO xtrole;

*/
FUNCTION use_sql_roba( hParams )

   LOCAL cTable := "ROBA"
   LOCAL cWhere, cOrder
   LOCAL cSql, lCheckOnly := .F.

   default_if_nil( @hParams, hb_Hash() )

   IF hb_HHasKey( hParams, "check_only" ) .AND. hParams[ "check_only" ] == .T.
      lCheckOnly := .T.
   ENDIF

   cSql := "SELECT *"

/*
   IF lCheckOnly
      cSql += coalesce_char( "id", 10 )
   ELSE
      cSql += coalesce_char_zarez( "id", 10 )
      cSql += coalesce_char_zarez( "sifradob", 20 )
      cSql += coalesce_char_zarez( "naz", 250 )
      cSql += coalesce_char_zarez( "jmj", 3 )
      cSql += coalesce_char_zarez( "idtarifa", 6 )
      cSql += coalesce_char_zarez( "tip", 1 )
      cSql += coalesce_char_zarez( "opis", 200 )
      cSql += coalesce_char_zarez( "k1", 4 )
      cSql += coalesce_char_zarez( "k2", 4 )
      cSql += coalesce_char_zarez( "barkod", 13 )

      cSql += coalesce_num_num_zarez( "n1", 12, 2 )
      cSql += coalesce_num_num_zarez( "n2", 12, 2 )
      cSql += coalesce_num_num_zarez( "carina", 5, 2 )
      cSql += coalesce_num_num_zarez( "nc", 18, 8 )
      cSql += coalesce_num_num_zarez( "vpc", 18, 8 )
      cSql += coalesce_num_num_zarez( "vpc2", 18, 8 )
      cSql += coalesce_num_num_zarez( "mpc", 18, 8 )
      cSql += coalesce_num_num_zarez( "mpc2", 18, 8 )
      cSql += coalesce_num_num_zarez( "mpc3", 18, 8 )
      cSql += coalesce_num_num_zarez( "mpc4", 18, 8 )
      cSql += coalesce_num_num( "mpc5", 18, 8 )
   ENDIF
*/

   cSql += " FROM " + f18_sql_schema( "roba" )

   cWhere := use_sql_roba_where( hParams )
   cOrder := use_sql_roba_order( hParams )

   IF !Empty( cWhere )
      cSql += " WHERE " + cWhere
      IF !Empty( cOrder )
         cSql += cOrder
      ENDIF
   ELSE
      cSql += " OFFSET 0 LIMIT 1"
   ENDIF

   IF hb_HHasKey( hParams, "alias" )
      cTable := hParams[ "alias" ]
   ENDIF


   SELECT ( F_ROBA )
   IF !use_sql( cTable, cSql )
      RETURN .F.
   ENDIF

   IF is_sql_rdd_treba_indeks( hParams )
      INDEX ON id  TAG "ID" TO cTable
      INDEX ON naz  TAG "NAZ" TO cTable
      SET ORDER TO TAG "ID"
   ENDIF

   GO TOP

   RETURN .T.


STATIC FUNCTION use_sql_roba_order( hParams )

   LOCAL cOrder := ""

   IF hb_HHasKey( hParams, "order_by" )
      cOrder += " ORDER BY " + hParams[ "order_by" ]
   ELSE
      cOrder += " ORDER BY id,naz"
   ENDIF

   RETURN cOrder


STATIC FUNCTION use_sql_roba_where( hParams )

   LOCAL cWhere := ""
   LOCAL dDatOd

   IF hb_HHasKey( hParams, "id" )
      IF hb_HHasKey( hParams, "sintetika" ) .AND. hParams[ "sintetika" ]  // npr: id like '100%'
         cWhere := "id LIKE " + sql_quote( Trim( hParams[ "id" ] ) + "%" )
      ELSE
         cWhere := parsiraj_sql( "id", hParams[ "id" ] )
      ENDIF
   ENDIF

   IF hb_HHasKey( hParams, "sifradob" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "trim(sifradob)", hParams[ "sifradob" ] )
   ENDIF

   IF hb_HHasKey( hParams, "barkod" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "barkod", hParams[ "barkod" ] )
   ENDIF

   IF hb_HHasKey( hParams, "tip" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) + parsiraj_sql( "tip", hParams[ "tip" ] )
   ENDIF

   IF hb_HHasKey( hParams, "where" )
      cWhere += iif( Empty( cWhere ), "", " AND " ) +  hParams[ "where" ]
   ENDIF

   RETURN cWhere
