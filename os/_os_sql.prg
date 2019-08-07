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

MEMVAR gOssii

FUNCTION datotp_prazan()

   IF field->datotp < SToD( "10010101" ) // 1000-01-01
      RETURN .T.
   ENDIF

   RETURN .F.


FUNCTION get_datotp()

   IF field->datotp < SToD( "10010101" )
      RETURN CToD( "" )
   ENDIF

   RETURN field->datotp



FUNCTION find_os_sii_by_naz_or_id( cId )

   LOCAL cAlias := "OS", cTable := "os_os"
   LOCAL cSqlQuery
   LOCAL cIdSql

   IF gOsSii != "O"
      cAlias := "SII"
      cTable := "sii_sii"
   ENDIF

   cSqlQuery := "select * from " + f18_sql_schema( cTable )

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql
   cSqlQuery += " OR naz ilike " + cIdSql

   IF !use_sql( cTable, cSqlQuery, cAlias )
      RETURN .F.
   ENDIF

   index_os_sii( cAlias )

   SEEK cId
   IF !Found()
      GO TOP
   ENDIF

   RETURN !Eof()



FUNCTION index_os_sii( cAlias )

   INDEX ON field->id + field->idam + DToS( field->datum ) TAG "1" TO ( cAlias )
   INDEX ON field->idrj + field->id + DToS( field->datum ) TAG "2" TO ( cAlias )
   INDEX ON field->idrj + field->idkonto + field->id TAG "3" TO ( cAlias )
   INDEX ON field->idkonto + field->idrj + field->id TAG "4" TO ( cAlias )
   INDEX ON field->idam + field->idrj + field->id TAG "5" TO ( cAlias )

   SET ORDER TO TAG "1"
   RETURN .T.



FUNCTION o_amort( cId )

   LOCAL cTable := "os_amort"
   LOCAL cAlias := "AMORT"

   SELECT ( F_AMORT )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_amort( cId )

   SELECT ( F_AMORT )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_amort( cId )


FUNCTION find_amort_by_id( cId )

   LOCAL cAlias := "AMORT"
   LOCAL cTable := "os_amort"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( cTable )
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql

   IF !use_sql( cTable, cSqlQuery, cAlias )
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



FUNCTION o_reval( cId )

   LOCAL cTable := "os_reval"
   LOCAL cAlias := "REVAL"

   SELECT ( F_REVAL )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION find_reval_by_id( cId )

   LOCAL cAlias := "REVAL"
   LOCAL cTable := "os_reval"
   LOCAL cSqlQuery := "select * from " + f18_sql_schema( cTable )
   LOCAL cIdSql

   cIdSql := sql_quote( "%" + Upper( AllTrim( cId ) ) + "%" )
   cSqlQuery += " WHERE id ilike " + cIdSql

   IF !use_sql( cTable, cSqlQuery, cAlias )
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


FUNCTION select_o_reval( cId )

   SELECT ( F_REVAL )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_reval( cId )



FUNCTION o_os( cId )

   LOCAL cTable := "os_os", cAlias := "OS"

   SELECT ( F_OS )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_os( cId )

   SELECT ( F_OS )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_os( cId )


FUNCTION o_sii( cId )

   LOCAL cTable := "sii_sii", cAlias := "sii"

   SELECT ( F_SII )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_sii( cId )

   SELECT ( F_SII )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_sii( cId )


FUNCTION o_os_promj( cId )

   LOCAL cTable := "os_promj", cAlias := "OS_PROMJ"

   SELECT ( F_OS_PROMJ )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_os_promj( cId )

   SELECT ( F_OS_PROMJ )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_os_promj( cId )


FUNCTION o_sii_promj( cId )

   LOCAL cTable := "sii_promj", cAlias := "SII_PROMJ"

   SELECT ( F_SII_PROMJ )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_sii_promj( cId )

   SELECT ( F_SII_PROMJ )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_os_sii_promj( cId )




FUNCTION select_o_os_or_sii( cId )

   IF gOsSii == "O"
      RETURN select_o_os( cId )
   ENDIF

   RETURN select_o_sii( cId )


FUNCTION select_o_os_or_sii_area()

  IF gOsSii == "O"
     SELECT( F_OS )
     RETURN .T.
  ENDIF

  SELECT( F_SII )
  RETURN .T.


FUNCTION os_select_promj( cId )

   IF gOsSii == "O"
      RETURN select_o_os_promj( cId )
   ENDIF

   RETURN select_o_sii_promj( cId )


FUNCTION os_select_promj_area()

   IF gOsSII == "O"
      SELECT ( F_OS_PROMJ )
      RETURN .T.
   ENDIF

   SELECT( F_SII_PROMJ )
   RETURN .F.


FUNCTION o_os_sii( cId )

   IF gOsSii == "O"
      RETURN o_os( cId )
   ENDIF

   RETURN o_sii( cId )




FUNCTION o_os_sii_promj( cId )

   IF gOsSii == "O"
      RETURN o_os_promj( cId )
   ENDIF

   RETURN o_sii_promj( cId )
