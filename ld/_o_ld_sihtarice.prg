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

FUNCTION o_tprsiht( cId )

   SELECT ( F_TPRSIHT )

   IF !use_sql_sif( "ld_tprsiht", .T., "TPRSIHT", cId )
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION o_norsiht( cId )

   SELECT ( F_NORSIHT )

   IF !use_sql_sif( "ld_norsiht", .T., "NORSIHT", cId )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN .T.


FUNCTION select_o_norsiht( cId )

   SELECT ( F_NORSIHT )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_norsiht( cId )



FUNCTION o_radsat( cId )

   LOCAL cAlias := "RADSAT"
   LOCAL cSql

   SELECT ( F_RADSAT )

   cSql := "select * from " + f18_sql_schema( "radsat" )

// my_use ( "radsat" )
   use_sql( "radsat", cSql, cAlias )

   INDEX ON IDRADN TAG IDRADN TO  ( cAlias )
   SET ORDER TO TAG "IDRADN"

   IF cId != NIL
      SEEK cId
   ELSE
      GO TOP
   ENDIF

   RETURN .T.


FUNCTION select_o_radsat( nGodina, nMjesec, cIdRadn )

   SELECT ( F_RADSAT )
   IF Used()
      IF RecCount() > 1 .AND. nGodina == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_radsat( nGodina, nMjesec, cIdRadn )



FUNCTION o_radsiht( nGodina, nMjesec, cIdRadn )

   LOCAL cAlias := "RADSIHT", cTable := "ld_radsiht"
   LOCAL cSql, lWhere := .F.

   SELECT ( F_RADSIHT )

   cSql := "select * from " + f18_sql_schema( cTable )

   IF nGodina != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "godina=" + Str( nGodina, 4, 0 )
   ENDIF


   IF nMjesec != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "mjesec=" + Str( nMjesec, 2, 0 )
   ENDIF


   IF cIdRadn != NIL .AND. !Empty( cIdRadn )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idradn=" + sql_quote( cIdRadn )
   ENDIF

   use_sql( cTable, cSql, cAlias )

   INDEX ON Str( godina, 4, 0 ) + Str( mjesec, 2, 0 ) + idradn + idrj + Str( dan ) + dandio + idtippr TAG "1" TO ( cAlias )
   INDEX ON idkonto + Str( godina, 4, 0 ) + Str( mjesec, 2, 0 ) + idradn TAG "2" TO ( cAlias )
   INDEX ON idnorsiht + Str( godina, 4, 0 ) + Str( mjesec, 2, 0 ) + idradn TAG "3" TO ( cAlias )
   INDEX ON idradn + Str( godina, 4, 0 ) + Str( mjesec, 2, 0 ) + idkonto TAG "4" TO ( cAlias )

   SET ORDER TO TAG "1"
   GO TOP


   RETURN .T.



FUNCTION select_o_radsiht( cId )

   SELECT ( F_RADSIHT )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE
      ENDIF
   ENDIF

   RETURN o_radsiht( cId )
