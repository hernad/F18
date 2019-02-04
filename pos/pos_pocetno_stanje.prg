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


STATIC __stanje
STATIC __vrijednost
STATIC __dok_br



FUNCTION pos_pocetno_stanje()

   LOCAL _params := hb_Hash()
   LOCAL _cnt := 0
   LOCAL _padr := 80

   __stanje := 0
   __vrijednost := 0
   __dok_br := ""


   IF _get_vars( @_params ) == 0
      RETURN .F.
   ENDIF


   _cnt := pocetno_stanje_sql( _params )

   IF _cnt > 0
      _txt := "Izvrsen prenos pocetnog stanja, dokument 16-1 !"
   ELSE
      _txt := "Nema dokumenata za prenos !!!"
   ENDIF

   MsgBeep( _txt )

   RETURN .F.


// --------------------------------------------
// parametri prenosa
// --------------------------------------------
STATIC FUNCTION _get_vars( params )

   LOCAL _x := 1
   LOCAL _box_x := 8
   LOCAL _box_y := 60
   LOCAL _dat_od, _dat_do, _id_pos, _dat_ps
   PRIVATE GetList := {}

   _dat_od := CToD( "01.01." + AllTrim( Str( Year( Date() ) -1 ) ) )
   _dat_do := CToD( "31.12." + AllTrim( Str( Year( Date() ) -1 ) ) )
   _dat_ps := CToD( "01.01." + AllTrim( Str( Year( Date() ) ) ) )
   _id_pos := gIdPos

   Box(, _box_x, _box_y )

   SET CURSOR ON

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Parametri prenosa u novu godinu" COLOR "BG+/B"

   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "pos ID" GET _id_pos VALID !Empty( _id_pos )

   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Datum prenosa od:" GET _dat_od VALID !Empty( _dat_od )
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET _dat_do VALID !Empty( _dat_do )

   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Datum dokumenta pocetnog stanja:" GET _dat_ps VALID !Empty( _dat_ps )

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   // snimi parametre
   params[ "datum_od" ] := _dat_od
   params[ "datum_do" ] := _dat_do
   params[ "id_pos" ] := _id_pos
   params[ "datum_ps" ] := _dat_ps

   RETURN 1


// ----------------------------------------------------------
// prebaci se na rad sa sezonskim podrucjem
// ----------------------------------------------------------
STATIC FUNCTION prebaci_se_u_bazu( db_params, database, year )

   IF year == NIL
      year := Year( Date() )
   ENDIF

   // 1) odjavi mi se iz tekuce sezone
   my_server_logout()

   IF year <> Year( Date() )
      // 2) xxxx_2013 => xxxx_2012
      db_params[ "database" ] := Left( database, Len( database ) - 4 ) + AllTrim( Str( year ) )
   ELSE
      db_params[ "database" ] := database
   ENDIF

   // 3) setuj parametre
   my_server_params( db_params )
   // 4) napravi login
   my_server_login( db_params )
   set_sql_search_path()

   RETURN .T.




STATIC FUNCTION pocetno_stanje_sql( hParams )

   LOCAL _db_params := my_server_params()
   LOCAL _tek_database := my_server_params()[ "database" ]
   LOCAL _date_from := hParams[ "datum_od" ]
   LOCAL _date_to := hParams[ "datum_do" ]
   LOCAL dDatDok := hParams[ "datum_ps" ]
   LOCAL _year_sez := Year( _date_to )
   LOCAL _year_tek := Year( dDatDok )
   LOCAL _id_pos := hParams[ "id_pos" ]
   LOCAL _qry, oDataset, oRow
   LOCAL nCount := 0
   LOCAL hRec, cIdRoba, nKolicina, nVrijednost
   LOCAL cBrDok
   LOCAL lOk := .T.


   prebaci_se_u_bazu( _db_params, _tek_database, _year_sez )


   _qry := "SELECT " + ;
      "idroba, " + ;
      "SUM( CASE " + ;
      "WHEN idvd IN ('16', '00') THEN kolicina " + ;
      "WHEN idvd IN ('IN') THEN -(kolicina - kol2) " + ;
      "WHEN idvd IN ('42') THEN -kolicina " + ;
      "END ) as kolicina, " + ;
      "SUM( CASE  " + ;
      "WHEN idvd IN ('16', '00') THEN kolicina * cijena " + ;
      "WHEN idvd IN ('IN') THEN -(kolicina - kol2) * cijena " + ;
      "WHEN idvd IN ('42') THEN -kolicina * cijena " + ;
      "END ) as vrijednost " + ;
      "FROM " + f18_sql_schema( "pos_pos " )

   _qry += " WHERE "
   _qry += _sql_cond_parse( "idpos", _id_pos )
   _qry += " AND " + _sql_date_parse( "datum", _date_from, _date_to )
   _qry += " GROUP BY idroba "
   _qry += " ORDER BY idroba "

   MsgO( "pocetno stanje sql query u toku..." )
   oDataset := run_sql_query( _qry )
   MsgC()

   prebaci_se_u_bazu( _db_params, _tek_database, _year_tek )

   o_pos_kumulativne_tabele()

   o_roba()

   cBrDok := pos_novi_broj_dokumenta( _id_pos, "16", dDatDok )

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "pos_pos", "pos_doks" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
      RETURN .F.
   ENDIF

   MsgO( "Formiranje dokumenta početnog stanja u toku ..." )

   DO WHILE !oDataset:Eof()

      oRow := oDataset:GetRow()

      cIdRoba := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idroba" ) ) )

      nKolicina := oRow:FieldGet( oRow:FieldPos( "kolicina" ) )
      __stanje += nKolicina

      nVrijednost := oRow:FieldGet( oRow:FieldPos( "vrijednost" ) )
      __vrijednost += nVrijednost

      select_o_roba( cIdRoba )

      IF Round( nKolicina, 2 ) <> 0

         SELECT pos
         APPEND BLANK

         hRec := dbf_get_rec()

         hRec[ "idpos" ] := _id_pos
         hRec[ "idvd" ] := "16"
         hRec[ "brdok" ] := cBrDok
         hRec[ "rbr" ] := PadL( AllTrim( Str( ++nCount ) ), 5 )
         hRec[ "idroba" ] := cIdRoba
         hRec[ "kolicina" ] := nKolicina
         hRec[ "cijena" ] := pos_get_mpc()
         hRec[ "datum" ] := dDatDok
         hRec[ "idradnik" ] := "XXXX"
         hRec[ "idtarifa" ] := roba->idtarifa

         lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )

      ENDIF

      IF !lOk
         EXIT
      ENDIF

      oDataset:Skip()

   ENDDO

   IF lOk .AND. nCount > 0

      SELECT pos_doks
      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idpos" ] := _id_pos
      hRec[ "idvd" ] := "16"
      hRec[ "brdok" ] := cBrDok
      hRec[ "datum" ] := dDatDok
      hRec[ "idradnik" ] := "XXXX"

      lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )

   ENDIF

   MsgC()

   IF lOk
      hParams := hb_hash()
      hParams[ "unlock" ] := { "pos_doks", "pos_pos" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   SELECT ( F_ROBA )
   USE
   SELECT ( F_POS_DOKS )
   USE
   SELECT ( F_POS )
   USE

   RETURN nCount
