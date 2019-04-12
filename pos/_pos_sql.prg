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

FUNCTION seek_pos_pos_2( cIdRoba, dDatum )

   LOCAL hParams := hb_Hash()

   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   IF dDatum != NIL
      hParams[ "datum" ] := dDatum
   ENDIF
   hParams[ "tag" ] := "2"

   RETURN seek_pos_h( hParams )


FUNCTION seek_pos_pos_5( cIdPos, cIdRoba, dDatum )

   LOCAL hParams := hb_Hash()

   IF cIdPos != NIL
      hParams[ "idpos" ] := cIdPos
   ENDIF
   IF cIdRoba != NIL
      hParams[ "idroba" ] := cIdRoba
   ENDIF
   IF dDatum != NIL
      hParams[ "datum" ] := dDatum
   ENDIF
   hParams[ "tag" ] := "5"

   RETURN seek_pos_h( hParams )


FUNCTION seek_pos_pos( cIdPos, cIdVd, dDatum, cBrDok, cTag, cAlias )

   LOCAL hParams := hb_Hash()

   hParams[ "idpos" ] := cIdPos
   hParams[ "idvd" ] := cIdVd
   hParams[ "datum" ] := dDatum
   hParams[ "brdok" ] := cBrDok
   IF cTag == NIL
      hParams[ "tag" ] := 1
   ELSE
      hParams[ "tag" ] := cTag
   ENDIF
   IF cAlias != NIL
      hParams[ "alias" ] := cAlias
   ENDIF

   RETURN seek_pos_h( hParams )


FUNCTION seek_pos_h( hParams )

   LOCAL cIdPos, cIdVd, dDatum, cBrDok, cTag
   LOCAL dDatOd
   LOCAL cIdRoba
   LOCAL cSql
   LOCAL cTable := "pos_pos", cAlias := "POS"
   LOCAL hIndexes, cKey
   LOCAL lWhere := .F.

   IF hb_HHasKey( hParams, "alias" )
      cAlias := hParams[ "alias" ]
   ENDIF
   IF hb_HHasKey( hParams, "idpos" )
      cIdPos := hParams[ "idpos" ]
   ENDIF
   IF hb_HHasKey( hParams, "idvd" )
      cIdVd := hParams[ "idvd" ]
   ENDIF
   IF hb_HHasKey( hParams, "datum" )
      dDatum := hParams[ "datum" ]
   ENDIF
   IF hb_HHasKey( hParams, "brdok" )
      cBrDok := hParams[ "brdok" ]
   ENDIF
   IF hb_HHasKey( hParams, "idroba" )
      cIdRoba := hParams[ "idroba" ]
   ENDIF
   IF hb_HHasKey( hParams, "tag" )
      cTag := hParams[ "tag" ]
   ENDIF

   cSql := "SELECT * from " + f18_sql_schema( cTable )

   IF cIdPos != NIL .AND. !Empty( cIdPos )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idpos=" + sql_quote( cIdPos )
   ENDIF
   IF cIdVD != NIL .AND. !Empty( cIdVD )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idvd=" + sql_quote( cIdVd )
   ENDIF
   IF cIdRoba != NIL .AND. !Empty( cIdRoba )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idroba=" + sql_quote( cIdRoba )
   ENDIF
   IF dDatum != NIL .AND. !Empty( dDatum )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
      ENDIF
      cSql += "datum=" + sql_quote( dDatum )
   ENDIF
   IF hb_HHasKey( hParams, "dat_do" )
      IF !hb_HHasKey( hParams, "dat_od" )
         dDatOd := CToD( "" )
      ELSE
         dDatOd := hParams[ "dat_od" ]
      ENDIF
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
      ENDIF
      cSql +=  parsiraj_sql_date_interval( "datum", dDatOd, hParams[ "dat_do" ] )
   ENDIF

   IF cBrDok != NIL .AND. !Empty( cBrDok )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "brdok=" + sql_quote( cBrDok )
   ENDIF

   SELECT F_POS
   use_sql( cTable, cSql, cAlias )

   hIndexes := h_pos_pos_indexes()
   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( cAlias )
   NEXT
   IF cTag == NIL
      cTag := "1"
   ENDIF
   SET ORDER TO TAG ( cTag )
   GO TOP

   RETURN !Eof()


FUNCTION h_pos_pos_indexes()

   LOCAL hIndexes := hb_Hash()

   hIndexes[ "1" ] := "IdPos+IdVd+dtos(datum)+BrDok+TRANSFORM(Rbr,'99999')"
   hIndexes[ "2" ] := "idroba+DTOS(Datum)"
   hIndexes[ "4" ] := "dtos(datum)"
   hIndexes[ "5" ] := "IdPos+idroba+DTOS(Datum)"
   hIndexes[ "6" ] := "IdRoba"
   hIndexes[ "7" ] := "IdPos+IdVd+BrDok+DTOS(Datum)"

   RETURN hIndexes


FUNCTION seek_pos_doks_2( cIdVd, dDatum )
   RETURN seek_pos_doks( NIL, cIdVd, dDatum, NIL, "2" )


FUNCTION seek_pos_doks_2_za_period( cIdVd, dDatOd, dDatDo )
   RETURN seek_pos_doks( NIL, cIdVd, NIL, NIL, "2", dDatOd, dDatDo )


FUNCTION seek_pos_doks_za_period( cIdPos, cIdVd, dDatOd, dDatDo, cAlias )
   RETURN seek_pos_doks( cIdPos, cIdVd, NIL, NIL, "1", dDatOd, dDatDo, cAlias )


FUNCTION find_pos_doks_by_idvd_brfaktp( hParams )

   LOCAL lRet

   lRet := seek_pos_doks_h( hParams )
   IF lRet
      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "idvd" ] := pos_doks->idvd
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "brdok" ] := pos_doks->brdok
      hParams[ "idpartner" ] := pos_doks->idpartner
      hParams[ "opis" ] := pos_doks->opis
      hParams[ "dat_od" ] := pos_doks->dat_od
      hParams[ "dat_do" ] := pos_doks->dat_do
      hParams[ "idradnik" ] := pos_doks->idradnik
   ENDIF

   RETURN lRet


FUNCTION seek_pos_doks_h( hParams  )

   LOCAL cSql
   LOCAL cTable := "pos_doks"
   LOCAL hIndexes, cKey
   LOCAL lWhere := .F.
   LOCAL cFields

   LOCAL cIdPos, cIdVd, dDatum, cBrDok, cTag, dDatOd, dDatDo, cAlias

   IF hb_HHasKey( hParams, "idpos" )
      cIdPos := hParams[ "idpos" ]
   ENDIF
   IF hb_HHasKey( hParams, "idvd" )
      cIdVd := hParams[ "idvd" ]
   ENDIF
   IF hb_HHasKey( hParams, "datum" )
      dDatum := hParams[ "datum" ]
   ENDIF
   IF hb_HHasKey( hParams, "brdok" )
      cBrdok := hParams[ "brdok" ]
   ENDIF
   IF hb_HHasKey( hParams, "tag" )
      cTag := hParams[ "tag" ]
   ENDIF
   IF hb_HHasKey( hParams, "dat_od" )
      dDatOd := hParams[ "dat_od" ]
   ENDIF
   IF hb_HHasKey( hParams, "dat_do" )
      dDatDo := hParams[ "dat_do" ]
   ENDIF
   IF hb_HHasKey( hParams, "alias" )
      cAlias := hParams[ "alias" ]
   ENDIF

   cFields := "idpos, idvd, brdok, datum, idPartner, idradnik,"
   cFields += "idvrstep,vrijeme,ukupno,brFaktP,opis,dat_od,dat_do"

   cSql := "SELECT " + cFields + " from " + f18_sql_schema( cTable )
   IF cIdPos != NIL .AND. !Empty( cIdPos )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idpos=" + sql_quote( cIdPos )
   ENDIF
   IF cIdVD != NIL .AND. !Empty( cIdVD )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "idvd=" + sql_quote( cIdVd )
   ENDIF
   IF dDatum != NIL .AND. !Empty( dDatum )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
      ENDIF
      cSql += "datum=" + sql_quote( dDatum )
   ENDIF
   IF dDatDo != NIL
      IF dDatOd == NIL
         dDatOd := CToD( "" )
      ENDIF
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
      ENDIF
      cSql +=  parsiraj_sql_date_interval( "datum", dDatOd, dDatDo )
   ENDIF
   IF cBrDok != NIL .AND. !Empty( cBrDok )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "brdok=" + sql_quote( cBrDok )
   ENDIF

   IF cAlias == NIL
      cAlias := "POS_DOKS"
      SELECT F_POS_DOKS
   ELSE
      SELECT F_POS_DOKS_2
   ENDIF

   IF hb_HHasKey( hParams, "brfaktp" ) .AND. hParams[ "brfaktp" ] != NIL .AND. !Empty( hParams[ "brfaktp" ] )
      IF lWhere
         cSql += " AND "
      ELSE
         cSql += " WHERE "
         lWhere := .T.
      ENDIF
      cSql += "brfaktp=" + sql_quote( hParams[ "brfaktp" ] )
   ENDIF

   use_sql( cTable, cSql, cAlias )
   hIndexes := h_pos_doks_indexes()

   FOR EACH cKey IN hIndexes:Keys
      INDEX ON  &( hIndexes[ cKey ] )  TAG ( cKey ) TO ( cAlias )
   NEXT

   IF cTag == NIL
      cTag := "1"
   ENDIF
   SET ORDER TO TAG ( cTag )
   GO TOP

   RETURN !Eof()


FUNCTION seek_pos_doks( cIdPos, cIdVd, dDatum, cBrDok, cTag, dDatOd, dDatDo, cAlias )

   LOCAL hParams := hb_Hash()

   hParams[ "idpos" ] := cIdPos
   hParams[ "idvd" ] := cIdVd
   hParams[ "datum" ] := dDatum
   hParams[ "brdok" ] := cBrDok
   hParams[ "tag" ] := cTag
   hParams[ "dat_od" ] := dDAtOd
   hParams[ "dat_do" ] := dDatDo
   hParams[ "alias" ] := cAlias

   RETURN seek_pos_doks_h( hParams )


FUNCTION h_pos_doks_indexes()

   LOCAL hIndexes := hb_Hash()

   hIndexes[ "1" ] := "IdPos+IdVd+dtos(datum)+BrDok"
   hIndexes[ "2" ] := "IdVd+DTOS(Datum)"
   hIndexes[ "3" ] := "idPartner+DTOS(Datum)"
   hIndexes[ "6" ] := "dtos(datum)"
   hIndexes[ "7" ] := "IdPos+IdVD+BrDok"
   hIndexes[ "TK" ] := "IdPos+DTOS(Datum)+IdVd"

   RETURN hIndexes


FUNCTION pos_stanje_artikal_str( cIdRoba, nStrLen )

   LOCAL nI, nCijena, nNCijena, aCijene := pos_dostupne_cijene_za_artikal( cIdRoba )
   LOCAL nStanje, nCijenaNeto, cSlikaStanja := ""
   LOCAL nLen := Len( aCijene )

   FOR nI := 1 TO nLen
      nCijena := aCijene[ nI, 1 ]
      nNCijena := aCijene[ nI, 2 ]
      IF nNCijena <> 0
         nCijenaNeto := nNCijena
      ELSE
         nCijenaNeto := nCijena
      ENDIF
      nStanje := pos_dostupno_artikal_za_cijenu( cIdRoba, nCijena, nNCijena )

      IF !Empty( cSlikaStanja )
         cSlikaStanja += " ; "
      ENDIF
      IF nLen == 1
         cSlikaStanja +=  "St:" + Transform( nStanje, "999999.99" )  + "- Cij:" + Transform( nCijenaNeto, "999999.99" )
      ELSE
         cSlikaStanja += "St: " + AllTrim( Transform( nStanje, "999999.99" ) ) + "- Cij:" + AllTrim( Transform( nCijenaNeto, "999999.99" ) )
      ENDIF
   NEXT

   RETURN PadR( cSlikaStanja, nStrLen )


FUNCTION pos_dostupno_artikal_za_cijenu( cIdRoba, nCijena, nNCijena )

   LOCAL cQuery, oTable
   LOCAL nI, oRow
   LOCAL nStanje

   cQuery := "SELECT kol_ulaz-kol_izlaz as stanje FROM " + f18_sql_schema( "pos_stanje" )
   cQuery += " WHERE rtrim(idroba)=" + sql_quote( Trim( cIdRoba ) )
   cQuery += " AND cijena=" + sql_quote( nCijena )
   cQuery += " AND ncijena=" + sql_quote( nNCijena )
   cQuery += " AND current_date>=dat_od AND current_date<=dat_do"
   cQuery += " AND kol_ulaz-kol_izlaz <> 0"

   oTable := run_sql_query( cQuery )
   oRow := oTable:GetRow( 1 )
   nStanje := oRow:FieldGet( oRow:FieldPos( "stanje" ) )

   IF ValType( nStanje ) == "L"
      nStanje := 0
   ENDIF

   RETURN nStanje


FUNCTION pos_dostupno_artikal( cIdRoba )

   LOCAL cQuery, oRet, oError, nRet := 0

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_dostupno_artikal(" + ;
      sql_quote( cIdRoba ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "pos_dostupno artikal error ?!" ) )
   END SEQUENCE

   RETURN nRet



FUNCTION pos_dostupna_osnovna_cijena_za_artikal( cIdRoba )

   LOCAL cQuery, oRet, oError, nRet := 0

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_dostupna_osnovna_cijena_za_artikal(" + ;
      sql_quote( cIdRoba ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "pos_dostupna_osnovna_cijena_za_artikal error ?!" ) )
   END SEQUENCE

   RETURN nRet



FUNCTION pos_kalo( cIdRoba )

   LOCAL cQuery, oRet, oError, nRet := 0

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_kalo(" + ;
      sql_quote( cIdRoba ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "pos_kalo artikal error ?!" ) )
   END SEQUENCE

   RETURN nRet


FUNCTION pos_dostupno_artikal_sa_kalo( cIdRoba )

   LOCAL cQuery, oRet, oError, nRet := 0

   cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_dostupno_artikal_sa_kalo(" + ;
      sql_quote( cIdRoba ) + ")"

   BEGIN SEQUENCE WITH {| err | Break( err ) }

      oRet := run_sql_query( cQuery )
      IF is_var_objekat_tpqquery( oRet )
         nRet := oRet:FieldGet( 1 )
      ENDIF

   RECOVER USING oError
      Alert( _u( "pos_dostupno_artikal_sa_kalo error ?!" ) )
   END SEQUENCE

   RETURN nRet



/*
   => aCijene
      aCijenaItem [1] - cijena, [2] - ncijena, [3] - dat_od, [4] - dat_do, [5] - stanje
*/
FUNCTION pos_dostupne_cijene_za_artikal( cIdRoba )

   LOCAL cQuery
   LOCAL aCijene := {}

   cQuery := "SELECT cijena, ncijena, dat_od, dat_do, kol_ulaz-kol_izlaz as stanje FROM " + f18_sql_schema( "pos_stanje" )
   cQuery += " WHERE rtrim(idroba)=" + sql_quote( Trim( cIdRoba ) )
   cQuery += " AND kol_ulaz-kol_izlaz>0"
   cQuery += " AND dat_od<=current_date AND dat_do>=current_date"

   PushWa()
   SELECT F_POM
   use_sql( "POM", cQuery, "POM" )
   run_sql_query( cQuery )
   DO WHILE !Eof()
      AAdd( aCijene, { pom->cijena, pom->ncijena, pom->dat_od, pom->dat_do, pom->stanje } )
      SKIP
   ENDDO
   USE
   PopWa()

   RETURN aCijene


FUNCTION pos_iznos_racuna( cIdPos, cIdVD, dDatum, cBrDok )

   LOCAL cSql, oData, oRow
   LOCAL nTotal := 0

   PushWA()
   IF PCount() == 0
      cIdPos := pos_doks->IdPos
      cIdVD := pos_doks->IdVD
      dDatum := pos_doks->Datum
      cBrDok := pos_doks->BrDok
   ENDIF

   cSql := "SELECT "
   cSql += " SUM( ( kolicina * cijena ) - ( kolicina * (CASE WHEN (ncijena <>0) THEN cijena-ncijena ELSE 0.00 END) ) ) AS total "
   cSql += "FROM " + f18_sql_schema( "pos_pos" )
   cSql += " WHERE "
   cSql += " idpos = " + sql_quote( cIdPos )
   cSql += " AND idvd = " + sql_quote( cIdVd )
   cSql += " AND brdok = " + sql_quote( cBrDok )
   cSql += " AND datum = " + sql_quote( dDatum )

   oData := run_sql_query( cSql )
   PopWa()
   IF !is_var_objekat_tpqquery( oData )
      RETURN nTotal
   ENDIF
   nTotal := oData:FieldGet( 1 )

   RETURN nTotal


FUNCTION pos_get_mpc( cIdRoba )

   LOCAL nCijena := 0
   LOCAL cField
   LOCAL oData, cQry

   cQry := "SELECT mpc FROM " + f18_sql_schema( "roba" )
   cQry += " WHERE id=" + sql_quote( cIdRoba )

   oData := run_sql_query( cQry )
   IF !is_var_objekat_tpqquery( oData )
      MsgBeep( "Problem sa SQL upitom !" )
   ELSE
      IF oData:LastRec() > 0 .AND. ValType( oData:FieldGet( 1 ) ) == "N"
         nCijena := oData:FieldGet( 1 )
      ENDIF
   ENDIF

   RETURN nCijena


FUNCTION o_vrstep( cId )

   SELECT ( F_VRSTEP )
   use_sql_vrstep( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_vrstep( cId )

   SELECT ( F_VRSTEP )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_vrstep( cId )


FUNCTION use_sql_vrstep( cId )

   LOCAL cSql
   LOCAL cTable := f18_sql_schema( "vrstep" )

   SELECT ( F_VRSTEP )
   IF !use_sql_sif( cTable, .T., "VRSTEP", cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


// set_a_sql_sifarnik( "pos_strad", "STRAD", F_STRAD   )

FUNCTION o_pos_strad( cId )

   SELECT ( F_STRAD )
   use_sql_pos_strad( cId )
   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_pos_strad( cId )

   SELECT ( F_STRAD )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_pos_strad( cId )


FUNCTION use_sql_pos_strad( cId )

   LOCAL cTable := f18_sql_schema(  "pos_strad" )
   LOCAL cAlias := "STRAD"

   SELECT ( F_STRAD )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION find_pos_osob_by_naz( cNaz )

   LOCAL cTable := f18_sql_schema( "pos_osob" ), cAlias := "OSOB"
   LOCAL cSqlQuery := "select * from " + cTable

   cSqlQuery += " WHERE naz=" + sql_quote( cNaz )
   SELECT ( F_OSOB )
   use_sql( cTable, cSqlQuery, cAlias )

   RETURN !Eof()


FUNCTION find_pos_osob_by_korsif( cKorSif )

   LOCAL cTable := f18_sql_schema( "pos_osob" ), cAlias := "OSOB"
   LOCAL cSqlQuery := "select * from " +  cTable

   cSqlQuery += " WHERE korsif=" + sql_quote( cKorSif )
   SELECT ( F_OSOB )
   use_sql( cTable, cSqlQuery, cAlias )

   RETURN !Eof()


// set_a_sql_sifarnik( "pos_osob", "OSOB", F_OSOB   )

FUNCTION o_pos_osob( cId )

   SELECT ( F_OSOB )
   use_sql_pos_osob( cId )

   SET ORDER TO TAG "ID"

   RETURN !Eof()


FUNCTION select_o_pos_osob( cId )

   SELECT ( F_OSOB )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_pos_osob( cId )


FUNCTION use_sql_pos_osob( cId )

   LOCAL cSql
   LOCAL cTable := f18_sql_schema( "pos_osob" )
   LOCAL cAlias := "OSOB"

   SELECT ( F_OSOB )
   IF !use_sql_sif( cTable, .T., cAlias, cId )
      RETURN .F.
   ENDIF

   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION find_pos_osob_naziv( cId )

   LOCAL cRet, nSelect := Select()

   SELECT F_OSOB
   cRet := find_field_by_id( "pos_osob", cId, "naz" )
   SELECT ( nSelect )

   RETURN cRet
