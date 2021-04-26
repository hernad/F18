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

/*
SEEK Str( nGodina, 4 ) + cIdRj + Str( nMjesec, 2 ) + ld_broj_obracuna() + cIdRadn

seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn )
*/

FUNCTION seek_ld( cIdRj, xGodina, nMjesec, cObracun, cIdRadn, cTag, cAlias )

   LOCAL cSql
   LOCAL cTable := "ld_ld"
   LOCAL hIndexes, cKey
   LOCAL lWhere := .F.
   LOCAL nGodinaOd, nGodinaDo
   LOCAL nArea

   IF cAlias == NIL
      cAlias := "LD"
      nArea := F_LD
   ELSE
      nArea := F_LD_2
   ENDIF

   cSql := "SELECT * from " + F18_PSQL_SCHEMA_DOT + cTable

   IF xGodina != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      IF ValType( xGodina ) == "N"
         cSql += "godina=" + Str( xGodina, 4, 0 )
      ELSE // array
         nGodinaOd := xGodina[ 1 ]
         nGodinaDo := xGodina[ 2 ]
         cSql += "(godina>=" + Str( nGodinaOd, 4, 0 ) + " AND godina<=" + Str( nGodinaDo, 4, 0 ) + ")"
      ENDIF
   ENDIF

   IF cIdRj != NIL .AND. !Empty( cIdRj )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idrj=" + sql_quote( cIdRj )
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

   IF cObracun != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "obr=" + sql_quote( cObracun )
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

   SELECT ( nArea )
   use_sql( cTable, cSql, cAlias )

   hIndexes := h_ld_ld_indexes()

   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( "LD" )
   NEXT
   IF cTag == NIL
      cTag := "1"
   ENDIF
   SET ORDER TO TAG ( cTag )
   GO TOP

   RETURN .T.


FUNCTION seek_ld_2( cIdRj, nGodina, nMjesec, cObracun, cIdRadn )

   // TAG=2 => hIndexes[ "2" ] := "str(godina,4,0)+str(mjesec,2,0)+obr+idradn+idrj"
   seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn, "2" )

   RETURN .T.


FUNCTION ld_max_godina()

   LOCAL cSql

   cSql := "select max(godina) as godina from fmk.ld_ld"
   use_sql( "ld_ld", cSql, "LD" )

   RETURN .T.


FUNCTION ld_min_godina()

   LOCAL cSql

   cSql := "select min(godina) as godina from fmk.ld_ld"
   use_sql( "ld_ld", cSql, "LD" )

   RETURN .T.

/*
   SELECT radkr
   SET ORDER TO 1
   SEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + _idradn
*/
FUNCTION seek_radkr( nGodina, nMjesec, cIdRadn, cIdKred, cNaOsnovu, cTag, aWorkarea )

   LOCAL cSql
   LOCAL cTable := "ld_radkr"
   LOCAL hIndexes, cKey, lWhere := .F.
   LOCAL cAlias := "RADKR"
   LOCAL nWa := F_RADKR

   cSql := "SELECT * from " + F18_PSQL_SCHEMA_DOT + cTable

   IF aWorkarea != NIL
        nWa := aWorkarea[ 1 ]
        cAlias := aWorkarea[ 2 ]
   ENDIF

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


   IF cIdKred != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idkred=" + sql_quote( cIdKred )
   ENDIF


   IF cNaOsnovu != NIL
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
      ENDIF
      cSql += "naosnovu=" + sql_quote( cNaOsnovu )
   ENDIF


   my_dbSelectArea( nWa )
   IF !use_sql( cTable, cSql, cAlias )
      Alert( cSql )
      QUIT
   ENDIF

   hIndexes := h_ld_radkr_indexes()

   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] ) TAG ( cKey )
   NEXT

   IF cTag == NIL
      IF cNaOsnovu != NIL
         cTag := "2"
      ELSE
         cTag := "1"
      ENDIF
   ENDIF

   SET ORDER TO TAG ( cTag )
   GO TOP

   RETURN .T.


FUNCTION seek_radkr_2( cIdRadn, cIdkred, cNaOsnovu, nGodina, nMjesec, cTag, aWorkarea )

   RETURN seek_radkr( nGodina, nMjesec, cIdRadn, cIdKred, cNaOsnovu, cTag, aWorkarea )



FUNCTION o_radkr_1rec()
   RETURN o_radkr( .T. )


FUNCTION o_radkr_all_rec()
   RETURN o_radkr( .F. )

FUNCTION o_radkr_otvoreni_krediti()
   RETURN o_radkr( .F., .T. )

FUNCTION o_radkr( lRec1, lSamoOtvoreni )

   LOCAL cSql, lRet, hIndexes, cKey

   hb_default( @lRec1, .T. )
   hb_default( @lSamoOtvoreni, .F. )

   cSql := "select * from fmk.ld_radkr"

   IF lSamoOtvoreni
      cSql += " WHERE round(iznos-placeno,2)<>0"
   ENDIF

   IF lRec1
      cSql += " LIMIT 1"
   ENDIF

   IF !lRec1
      MsgO( "Preuzimanje tabele RADKR sa servera ..." )
   ENDIF
   lRet := use_sql( "ld_radkr", cSql, "RADKR" )

   hIndexes := h_ld_radkr_indexes()

   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( "RADKR" )
   NEXT

   IF !lRec1
      Msgc()
   ENDIF

   RETURN lRet


FUNCTION use_sql_ld_ld( nGodina, nMjesec, nMjesecDo, nVrInvalid, nStInvalid, hParams )

   LOCAL cSql
   LOCAL aDbf := a_dbf_ld_ld()
   LOCAL cTable := "ld_ld"
   LOCAL cAlias := "LD"
   LOCAL hIndexes, cKey
   LOCAL cFilter

   cSql := "SELECT "
   cSql += sql_from_adbf( @aDbf, cTable )

   cSql += ", ld_radn.vr_invalid, ld_radn.st_invalid "
   cSql += " FROM " + F18_PSQL_SCHEMA_DOT + cTable
   cSql += " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + "ld_radn ON ld_ld.idradn = ld_radn.id"

   cSql += " WHERE godina =" + Str( nGodina, 4 ) + ;
      " AND mjesec>=" + Str( nMjesec, 2, 0 ) + " AND mjesec<=" + Str( nMjesecDo, 2, 0 )

   IF hParams != NIL
      IF !Empty( hParams[ "str_sprema" ] )
         cSql += " AND ld_ld.idStrSpr = " + sql_quote( hParams[ "str_sprema" ] )
      ENDIF
      IF !Empty( hParams[ "obracun" ] )
         cSql += " AND ld_ld.obr = " + sql_quote( hParams[ "obracun" ] )
      ENDIF

      cFilter := get_ld_rekap_filter( hParams )
   ENDIF

   IF nVrInvalid > 0
      cSql += " AND ld_radn.vr_invalid = " + sql_quote( nVrInvalid )
   ENDIF

   IF nStInvalid > 0
      cSql += " AND ld_radn.st_invalid >= " + sql_quote( nStInvalid )
   ENDIF

   SELECT F_LD
   IF !use_sql( cTable, cSql, "LD" )
      Alert( cSql )
      QUIT
   ENDIF
   hIndexes := h_ld_ld_indexes()

   FOR EACH cKey IN hIndexes:Keys
      IF cFilter != NIL .AND. cFilter != ".t."
         INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( cAlias ) FOR &cFilter
      ELSE
         INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( cAlias )
      ENDIF
   NEXT
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.



FUNCTION get_ld_rekap_filter( hParams )

   LOCAL cFilt1
   LOCAL lSvi := hParams[ "svi" ]

   // LOCAL cStrSpr := hParams[ "str_sprema" ]
   LOCAL qqRj := hParams[ "q_rj" ]
   LOCAL aUsl1 := hParams[ "usl1" ]
   // LOCAL cObracun := hParams[ "obracun" ]
   LOCAL nGodina := hParams[ "godina" ]
   LOCAL nMjesec := hParams[ "mjesec" ]
   LOCAL nMjesecDo := hParams[ "mjesec_do" ]

   IF lSvi

      cFilt1 := ".t."
      // cFilt1 += iif( Empty( cStrSpr ), "", ".and.IDSTRSPR == " + dbf_quote( cStrSpr ) )
      cFilt1 += iif( Empty( qqRJ ), "", ".and." + aUsl1 )

      IF nMjesec != nMjesecDo
         cFilt1 := cFilt1 + ".and. mjesec >= " + dbf_quote( nMjesec ) + ;
            ".and. mjesec <= " + dbf_quote( nMjesecDo ) + ".and. godina = " + dbf_quote( nGodina )
      ENDIF

   ELSE

      cFilt1 := ".t."
      // cFilt1 +=  iif( Empty( cStrSpr ), "", ".and. IDSTRSPR == " + dbf_quote( cStrSpr ) )

      IF nMjesec != nMjesecDo
         cFilt1 := cFilt1 + ".and. mjesec >= " + dbf_quote( nMjesec ) + ;
            ".and. mjesec <= " + dbf_quote( nMjesecDo ) + ".and. godina = " + dbf_quote( nGodina )
      ENDIF

   ENDIF

   // cFilt1 += ".and. obr = " + dbf_quote( cObracun )
   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   RETURN cFilt1
