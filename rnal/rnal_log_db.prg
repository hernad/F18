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
   use_sql_doc_log => otvori šifarnik rnal_doc_log
*/
FUNCTION use_sql_doc_log( nDoc_no, cDoc_type )

   LOCAL cSql
   LOCAL cTable := "doc_log"
   LOCAL cWhere := ""

   IF nDoc_no <> NIL
       cWhere := " WHERE doc_no = " + ALLTRIM( STR ( nDoc_no ) )
       IF cDoc_type <> NIL
           cWhere += " AND doc_log_ty = " + sql_quote( cDoc_type )
       ENDIF
   ENDIF

   cSql := "SELECT "
   cSql += "doc_no, "
   cSql += "doc_log_no,"
   cSql += "(CASE WHEN doc_log_da IS NULL THEN '1960-01-01'::date ELSE doc_log_da END) AS doc_log_da,"
   cSql += "doc_log_ti::char(8),"
   cSql += "operater_i,"
   cSql += "doc_log_ty::char(3),"
   cSql += "doc_log_de::char(250) "
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_log "
   cSql += cWhere
   cSql += " ORDER BY doc_no, doc_log_no "

   SELECT ( F_DOC_LOG )
   use_sql( cTable, cSql )

   INDEX ON STR(DOC_NO,10) + STR(DOC_LOG_NO,10) + DTOS(DOC_LOG_DA) + DOC_LOG_TI TAG "1" TO ( cTable )
   INDEX ON STR(DOC_NO,10) + DOC_LOG_TY + STR(DOC_LOG_NO,10) TAG "2" TO ( cTable )

   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.



/*
   use_sql_doc_lit() => otvori šifarnik rnal_doc_lit
*/

FUNCTION use_sql_doc_lit( nDoc_no, nDoc_log_no )

   LOCAL cSql
   LOCAL cTable := "doc_lit"
   LOCAL cWhere := ""

   IF nDoc_no <> NIL
       cWhere := " WHERE doc_no = " + ALLTRIM( STR ( nDoc_no ) )
       IF nDoc_log_no <> NIL
           cWhere += " AND doc_log_no = " + ALLTRIM( STR ( nDoc_log_no ) )
       ENDIF
   ENDIF

   cSql := "SELECT "
   cSql += "doc_no, "
   cSql += "doc_log_no,"
   cSql += "doc_lit_no,"
   cSql += "doc_lit_ac::char(1),"
   cSql += "art_id,"
   cSql += "char_1::char(250),"
   cSql += "char_2::char(250),"
   cSql += "char_3::char(250),"
   cSql += "num_1,"
   cSql += "num_2,"
   cSql += "num_3,"
   cSql += "int_1,"
   cSql += "int_2,"
   cSql += "int_3,"
   cSql += "int_4,"
   cSql += "int_5,"
   cSql += "(CASE WHEN date_1 IS NULL THEN '1960-01-01'::date ELSE date_1 END) AS date_1,"
   cSql += "(CASE WHEN date_2 IS NULL THEN '1960-01-01'::date ELSE date_2 END) AS date_2 "
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_lit "
   cSql += cWhere
   cSql += " ORDER BY doc_no, doc_log_no, doc_lit_no "

   SELECT ( F_DOC_LIT )
   use_sql( cTable, cSql )

   INDEX ON STR(DOC_NO,10) + STR(DOC_LOG_NO,10) + STR(DOC_LIT_NO,10) TAG "1" TO ( cTable )

   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.



FUNCTION rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )

   LOCAL nOperId, _rec
   LOCAL nTArea := Select()
   LOCAL lRet

   nOperId := f18_get_user_id( f18_user() )

   use_sql_doc_log( 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_log_da" ] := danasnji_datum()
   _rec[ "doc_log_ti" ] := PadR( Time(), 5 )
   _rec[ "doc_log_ty" ] := cDoc_log_type
   _rec[ "operater_i" ] := nOperId
   _rec[ "doc_log_de" ] := hb_StrToUtf8( cDesc )

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   SELECT ( nTArea )

   RETURN lRet


FUNCTION rnal_log_tip_10_insert( cAction, nDoc_no, nDoc_log_no, aArr )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "int_1" ] := aArr[ 1, 1 ]
   _rec[ "int_2" ] := aArr[ 1, 2 ]
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet



FUNCTION rnal_log_tip_11_insert( cAction, nDoc_no, nDoc_log_no, aArr )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "date_1" ] := aArr[ 1, 2 ]
   _rec[ "int_1" ] := aArr[ 1, 1 ]
   _rec[ "char_1" ] := hb_StrToUtf8( aArr[ 1, 3 ] )
   _rec[ "char_2" ] := hb_StrToUtf8( aArr[ 1, 4 ] )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet



FUNCTION rnal_log_tip_12_insert( cAction, nDoc_no, nDoc_log_no, aArr )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "int_1" ] := aArr[ 1, 1 ]
   _rec[ "char_1" ] := hb_StrToUtf8( aArr[ 1, 2 ] )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet



FUNCTION rnal_log_tip_13_insert( cAction, nDoc_no, nDoc_log_no, aArr )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "int_1" ] := aArr[ 1, 1 ]
   _rec[ "char_1" ] := hb_StrToUtf8( aArr[ 1, 2 ] )
   _rec[ "char_2" ] := hb_StrToUtf8( aArr[ 1, 3 ] )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet


FUNCTION rnal_log_tip_20_insert( cAction, nDoc_no, nDoc_log_no, ;
      nArt_id, cDoc_desc, cDoc_sch, ;
      nArt_qtty, nArt_heigh, nArt_width )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "art_id" ] := nArt_id
   _rec[ "num_1" ] := nArt_qtty
   _rec[ "num_2" ] := nArt_heigh
   _rec[ "num_3" ] := nArt_width
   _rec[ "char_1" ] := hb_StrToUtf8( cDoc_desc )
   _rec[ "char_2" ] := hb_StrToUtf8( cDoc_sch )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet


FUNCTION rnal_log_tip_21_insert( cAction, nDoc_no, nDoc_log_no, ;
      nArt_id, cArt_desc, nGlass_no, nDoc_it_no, ;
      nQty, nDamage )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "art_id" ] := nArt_id
   _rec[ "num_1" ] := nQty
   _rec[ "num_2" ] := nDamage
   _rec[ "int_1" ] := nDoc_it_no
   _rec[ "int_2" ] := nGlass_no
   _rec[ "char_1" ] := hb_StrToUtf8( cArt_desc )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet




FUNCTION rnal_log_tip_30_insert( cAction, nDoc_no, nDoc_log_no, ;
      nAop_id, nAop_att_id, cDoc_op_desc )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "int_1" ] := nAop_id
   _rec[ "int_2" ] := nAop_att_id
   _rec[ "char_1" ] := hb_StrToUtf8( cDoc_op_desc )
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet



FUNCTION rnal_log_tip_99_insert( cAction, nDoc_no, nDoc_log_no, nDoc_status )

   LOCAL nDoc_lit_no
   LOCAL lRet

   nDoc_lit_no := rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   use_sql_doc_lit( 0, 0 )

   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   _rec[ "doc_log_no" ] := nDoc_log_no
   _rec[ "doc_lit_no" ] := nDoc_lit_no
   _rec[ "int_1" ] := nDoc_status
   _rec[ "doc_lit_ac" ] := cAction

   lRet := update_rec_server_and_dbf( Alias(), _rec, 1, "CONT" )

   RETURN lRet



/*
   Opis: vraća zadnji broj polja doc_log_no tabele rnal_doc_log
*/

STATIC FUNCTION zadnji_broj_loga( nDoc_no )

   LOCAL cSql := ""
   LOCAL xRes
   LOCAL nLast := 0

   cSql := "SELECT MAX( doc_log_no ) FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_log WHERE doc_no = " + ALLTRIM( STR( nDoc_no ) )
   xRes := run_sql_query( cSql )

   IF is_var_objekat_tpqquery( xRes ) .AND. xRes:FieldGet(1) <> NIL
      nLast := xRes:FieldGet(1)
   ENDIF

   RETURN nLast



/*
   Opis: vraća sljedeći increment broj za polje doc_log_no tabele rnal_doc_log

   Usage: rnal_novi_broj_loga( nDoc_no )

   Params:
     - nDoc_no - broj radnog naloga

   Return:
     vraća sljedeći broj
*/

FUNCTION rnal_novi_broj_loga( nDoc_no )

   LOCAL nLastNo

   nLastNo := zadnji_broj_loga( nDoc_no )

   RETURN nLastNo + 1




FUNCTION doclog_str( nId )
   RETURN Str( nId, 10 )



/*
   Opis: vraća zadnji broj polja doc_lit_no iz tabele rnal_doc_lit

   Usage: rnal_novi_broj_stavke_naloga( nDoc_no, nDoc_log_no )

   Params:
    - nDoc_no - broj radnog naloga
    - nDoc_log_no - broj loga

   Returns:
    - vraća novi broj za tabelu
*/

STATIC FUNCTION rnal_novi_broj_stavke_loga( nDoc_no, nDoc_log_no )

   LOCAL nLastNo := 0
   LOCAL cSql := ""
   LOCAL xRes
   LOCAL nLast := 0

   cSql := "SELECT MAX( doc_lit_no ) FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_lit "
   cSql += "WHERE doc_no = " + ALLTRIM( STR( nDoc_no ) )
   cSql += "  AND doc_log_no = " + ALLTRIM( STR( nDoc_log_no ) )

   xRes := run_sql_query( cSql )

   IF is_var_objekat_tpqquery( xRes ) .AND. xRes:FieldGet(1) <> NIL
      nLast := xRes:FieldGet(1)
   ENDIF

   RETURN nLastNo + 1





FUNCTION rnal_log_tip_20_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "artikal: " + PadR( hb_StrToUtf8( g_art_desc( field->art_id ) ), 10 )
      cRet += "#"
      cRet += "kol.=" + AllTrim( Str( field->num_1, 8, 2 ) )
      cRet += ","
      cRet += "vis.=" + AllTrim( Str( field->num_2, 8, 2 ) )
      cRet += ","
      cRet += "sir.=" + AllTrim( Str( field->num_3, 8, 2 ) )
      cRet += "#"

      IF !Empty( field->char_1 )
         cRet += "opis.=" + AllTrim( field->char_1 )
         cRet += "#"
      ENDIF

      IF !Empty( field->char_2 )
         cRet += "shema.=" + AllTrim( field->char_2 )
         cRet += "#"
      ENDIF

      SELECT doc_lit

      SKIP
   ENDDO

   RETURN cRet



FUNCTION rnal_log_tip_21_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no


      cRet += "stavka: " + AllTrim( Str( field->int_1 ) )
      cRet += "#"
      cRet += AllTrim( "artikal: " + PadR( hb_StrToUtf8( g_art_desc( field->art_id ) ), 30 ) )
      cRet += "#"
      cRet += "staklo br: " + AllTrim( Str( field->int_2 ) )
      cRet += "#"
      cRet += "lom komada: " + AllTrim( Str( field->num_2 ) )
      cRet += "#"
      cRet += "opis: " + AllTrim( field->char_1 )

      SELECT doc_lit

      SKIP
   ENDDO

   RETURN cRet


FUNCTION rnal_log_tip_30_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "d.oper.: " + hb_StrToUtf8( g_aop_desc( field->int_1 ) )
      cRet += "#"
      cRet += "atr.d.oper.:" + hb_StrToUtf8( g_aop_att_desc( field->int_2 ) )
      cRet += ","
      cRet += "d.opis:" + AllTrim( field->char_1 )
      cRet += "#"

      SELECT doc_lit

      SKIP
   ENDDO

   RETURN cRet




FUNCTION rnal_log_tip_01_get( nDoc_no, nDoc_log_no )
   RETURN "Otvaranje naloga...#"


FUNCTION rnal_log_tip_99_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   nStat := field->int_1

   DO CASE
   CASE nStat == 1
      cRet := "zatvoren nalog...#"
   CASE nStat == 2
      cRet := "poništen nalog...#"
   CASE nStat == 4
      cRet := "djelimično zatvoren nalog...#"
   CASE nStat == 5
      cRet := "zatvoren, ali nije isporučen...#"
   ENDCASE

   RETURN cRet


FUNCTION rnal_log_tip_10_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "naručilac: " + PadR( g_cust_desc( field->int_1 ), 20 )
      cRet += "#"
      cRet += "prioritet: " + AllTrim( Str( field->int_2 ) )
      cRet += "#"

      SELECT doc_lit
      SKIP
   ENDDO

   RETURN cRet


FUNCTION rnal_log_tip_11_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "objekat: " + AllTrim( hb_StrToUtf8( g_obj_desc( field->int_1 ) ) )
      cRet += "#"
      cRet += "datum isp.: " + DToC( field->date_1 )
      cRet += "#"
      cRet += "vrij.isp.: " + AllTrim( field->char_1 )
      cRet += "#"
      cRet += "mjesto isp.: " + AllTrim( field->char_2 )
      cRet += "#"

      SELECT doc_lit
      SKIP
   ENDDO

   RETURN cRet



FUNCTION rnal_log_tip_12_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "kontakt.: " + hb_StrToUtf8( g_cont_desc( field->int_1 ) )
      cRet += "#"
      cRet += "kont.d.opis.: " + AllTrim( field->char_1 )
      cRet += "#"

      SELECT doc_lit
      SKIP
   ENDDO

   RETURN cRet



FUNCTION rnal_log_tip_13_get( nDoc_no, nDoc_log_no )

   LOCAL cRet := ""

   use_sql_doc_lit( nDoc_no, nDoc_log_no )

   SEEK docno_str( nDoc_no ) + doclog_str( nDoc_log_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_log_no == nDoc_log_no

      cRet += "vr.plać: " + s_pay_id( field->int_1 )
      cRet += "#"
      cRet += "plaćeno: " + AllTrim( field->char_1 )
      cRet += "#"
      cRet += "opis: " + AllTrim( field->char_2 )
      cRet += "#"

      SELECT doc_lit
      SKIP
   ENDDO

   RETURN cRet
