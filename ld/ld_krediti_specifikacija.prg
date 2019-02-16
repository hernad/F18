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


FUNCTION ld_kred_specifikacija()

   LOCAL _params := hb_Hash()
   LOCAL _data

   IF !_get_vars( @_params )
      RETURN .F.
   ENDIF

   _data := _get_data( _params )

   IF _data:LastRec() == 0
      RETURN .F.
   ENDIF

   _print_data( _data, _params )

   RETURN .T.



STATIC FUNCTION _get_data( hParams )

   LOCAL _data := {}
   LOCAL cQuery
   LOCAL _where
   LOCAL _order

   _where := " lk.godina = " + AllTrim( Str( hParams[ "godina" ] ) )
   _where += " AND lk.mjesec = " + AllTrim( Str( hParams[ "mjesec" ] ) )

   IF !Empty( hParams[ "kreditor" ] )
      _where += " AND lk.idkred = " + sql_quote( hParams[ "kreditor" ] )
   ENDIF

   IF !Empty( hParams[ "radnik" ] )
      _where += " AND lk.idradn = " + sql_quote( hParams[ "radnik" ] )
   ENDIF

   IF !Empty( hParams[ "osnova" ] )
      _where += " AND " + _sql_cond_parse( "lk.naosnovu", hParams[ "osnova" ] )
   ENDIF

   IF !Empty( hParams[ "rj" ] )
      _where += " AND " + _sql_cond_parse( "ld.idrj", hParams[ "rj" ] )
   ENDIF

   _order := " lk.idkred, lk.idradn, lk.naosnovu "

   cQuery := "SELECT " + ;
      " lk.idradn, " + ;
      " rd.naz AS radn_prezime, " + ;
      " rd.ime AS radn_ime, " + ;
      " rd.imerod AS radn_imerod, " + ;
      " lk.idkred, " + ;
      " kr.naz AS kred_naz, " + ;
      " lk.naosnovu, " + ;
      " lk.placeno AS iznos_rate, " + ;
      " ld.idrj AS rj, " + ;
      " ( SELECT COUNT(iznos) FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr WHERE idradn = lk.idradn AND idkred = lk.idkred AND naosnovu = lk.naosnovu) AS kredit_rate_ukupno, " + ;
      " ( SELECT COUNT(placeno) FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr WHERE idradn = lk.idradn AND idkred = lk.idkred AND naosnovu = lk.naosnovu AND placeno <> 0 ) AS kredit_rate_uplaceno, " + ;
      " ( SELECT SUM(iznos) FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr WHERE idradn = lk.idradn AND idkred = lk.idkred AND naosnovu = lk.naosnovu) AS kredit_ukupno, " + ;
      " ( SELECT SUM(iznos) FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr WHERE idradn = lk.idradn AND idkred = lk.idkred AND naosnovu = lk.naosnovu AND placeno <> 0) AS kredit_uplaceno " + ;
      " FROM " + F18_PSQL_SCHEMA_DOT + "ld_radkr lk " + ;
      " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + " ld_ld ld ON lk.idradn = ld.idradn AND ld.mjesec = " + AllTrim( Str( hParams[ "mjesec" ] ) ) + " AND ld.godina = " + AllTrim( Str( hParams[ "godina" ] ) ) + ;
      " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + " ld_radn rd ON lk.idradn = rd.id " + ;
      " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + " kred kr ON lk.idkred = kr.id " + ;
      " WHERE " + _where + ;
      " ORDER BY " + _order

   MsgO( "formiranje sql upita u toku ..." )
   _data := run_sql_query( cQuery )
   MsgC()

   IF sql_error_in_query( _data )
      RETURN NIL
   ENDIF

   _data:GoTo( 1 )

   RETURN _data


STATIC FUNCTION _get_vars( hParams )

   LOCAL _ok := .F.
   LOCAL nX := 1
   LOCAL _godina, _mjesec
   LOCAL cIdRadnik, cIdKreditor, _sort, _rj
   LOCAL _osnova := Space( 200 )

   _godina := fetch_metric( "ld_kred_spec_godina", my_user(), 2013 )
   _mjesec := fetch_metric( "ld_kred_spec_mjesec", my_user(), 1 )
   cIdRadnik := fetch_metric( "ld_kred_spec_radnik", my_user(), Space( 6 ) )
   cIdKreditor := fetch_metric( "ld_kred_spec_kreditor", my_user(), Space( 6 ) )
   _sort := fetch_metric( "ld_kred_spec_sort", my_user(), 2 )
   _rj := fetch_metric( "ld_kred_spec_rj", my_user(), Space( 200 ) )

   Box(, 15, 60 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Godina" GET _godina PICT "9999"
   @ box_x_koord() + nX, Col() + 1 SAY "mjesec" GET _mjesec PICT "99"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Radnik (prazno-svi):" GET cIdRadnik VALID Empty( cIdRadnik ) .OR. P_Radn( @cIdRadnik )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Kreditor (prazno-svi):" GET cIdKreditor VALID Empty( cIdKreditor ) .OR. P_Kred( @cIdKreditor )

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "   Filter po osnovi kredita:" GET _osnova PICT "@S30"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Filter po radnim jedinicama:" GET _rj PICT "@S30"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   set_metric( "ld_kred_spec_godina", my_user(), _godina )
   set_metric( "ld_kred_spec_mjesec", my_user(), _mjesec )
   set_metric( "ld_kred_spec_radnik", my_user(), cIdRadnik )
   set_metric( "ld_kred_spec_kreditor", my_user(), cIdKreditor )
   set_metric( "ld_kred_spec_sort", my_user(), _sort )
   set_metric( "ld_kred_spec_rj", my_user(), _rj )

   IF !Empty( _osnova )
      _osnova := AllTrim( _osnova ) + " "
   ENDIF

   IF !Empty( _rj )
      _rj := AllTrim( _rj ) + " "
   ENDIF

   hParams[ "godina" ] := _godina
   hParams[ "mjesec" ] := _mjesec
   hParams[ "kreditor" ] := cIdKreditor
   hParams[ "radnik" ] := cIdRadnik
   hParams[ "tip_sorta" ] := _sort
   hParams[ "osnova" ] := _osnova
   hParams[ "rj" ] := _rj

   _ok := .T.

   RETURN _ok


STATIC FUNCTION _print_data( oDataset, hParams )

   LOCAL _template := "kred_spec.odt"

   download_template( "kred_spec.odt", "8e996b671e63960c9466f5326cd78d00f2aefced0537104cda8b196763ccc55c" )

   _cre_xml( oDataset, hParams )

   IF generisi_odt_iz_xml( _template )
      prikazi_odt()
   ENDIF

   RETURN .T.



STATIC FUNCTION _cre_xml( oDataset, hParams )

   LOCAL oRow
   LOCAL _xml_file := my_home() + "oDataset.xml"
   LOCAL cIdKreditor
   LOCAL _sort := hParams[ "tip_sorta" ]
   LOCAL _t_rata_iznos := 0
   LOCAL _t_rata_ukupno := 0
   LOCAL _t_rata_uplaceno := 0
   LOCAL _t_kred_ukupno := 0
   LOCAL _t_kred_uplaceno := 0
   LOCAL _t_ostatak := 0

   create_xml( _xml_file )
   xml_head()

   xml_subnode( "spec", .F. )

   xml_node( "firma", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "godina", Str( hParams[ "godina" ] ) )
   xml_node( "mjesec", Str( hParams[ "mjesec" ] ) )
   xml_node( "kreditor", to_xml_encoding( hParams[ "kreditor" ] ) )
   xml_node( "radnik", to_xml_encoding( hParams[ "radnik" ] ) )

   oDataset:GoTo( 1 )

   DO WHILE !oDataset:Eof()

      oRow := oDataset:GetRow()

      cIdKreditor := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idkred" ) ) )
      cIdRadnik := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "idradn" ) ) )

      xml_subnode( "kred", .F. )

      xml_node( "k_naz", to_xml_encoding( hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "kred_naz" ) ) ) ) )
      xml_node( "k_id", to_xml_encoding( cIdKreditor ) )

      _t_rata_iznos := 0
      _t_rata_ukupno := 0
      _t_rata_uplaceno := 0
      _t_kred_ukupno := 0
      _t_kred_uplaceno := 0
      _t_ostatak := 0

      DO WHILE !oDataset:Eof() .AND. cIdKreditor == hb_UTF8ToStr( oDataset:FieldGet( oDataset:FieldPos( "idkred" ) ) )

         oRow2 := oDataset:GetRow()

         xml_subnode( "oDataset", .F. )

         xml_node( "r_id", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "idradn" ) ) ) ) )
         xml_node( "r_prez", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "radn_prezime" ) ) ) ) )
         xml_node( "r_ime", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "radn_ime" ) ) ) ) )
         xml_node( "r_imerod", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "radn_imerod" ) ) ) ) )
         xml_node( "k_id", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "idkred" ) ) ) ) )
         xml_node( "k_naz", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "kred_naz" ) ) ) ) )
         xml_node( "osn", to_xml_encoding( hb_UTF8ToStr( oRow2:FieldGet( oRow2:FieldPos( "naosnovu" ) ) ) ) )
         xml_node( "rata_i", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "iznos_rate" ) ), 12, 2 ) ) )
         xml_node( "rata_uk", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "kredit_rate_ukupno" ) ), 12, 0 ) ) )
         xml_node( "rata_up", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "kredit_rate_uplaceno" ) ), 12, 0 ) ) )
         xml_node( "kred_uk", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "kredit_ukupno" ) ), 12, 2 ) ) )
         xml_node( "kred_up", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "kredit_uplaceno" ) ), 12, 2 ) ) )
         xml_node( "ostatak", AllTrim( Str( oRow2:FieldGet( oRow2:FieldPos( "kredit_ukupno" ) ) - ;
            oRow2:FieldGet( oRow:FieldPos( "kredit_uplaceno" ) ), 12, 2 ) ) )

         _t_rata_iznos += oRow2:FieldGet( oRow2:FieldPos( "iznos_rate" ) )
         _t_rata_ukupno += oRow2:FieldGet( oRow2:FieldPos( "kredit_rate_ukupno" ) )
         _t_rata_uplaceno += oRow2:FieldGet( oRow2:FieldPos( "kredit_rate_uplaceno" ) )
         _t_kred_ukupno += oRow2:FieldGet( oRow2:FieldPos( "kredit_ukupno" ) )
         _t_kred_uplaceno += oRow2:FieldGet( oRow2:FieldPos( "kredit_uplaceno" ) )
         _t_ostatak += oRow2:FieldGet( oRow2:FieldPos( "kredit_ukupno" ) ) - ;
            oRow2:FieldGet( oRow2:FieldPos( "kredit_uplaceno" ) )

         xml_subnode( "oDataset", .T. )

         oDataset:Skip()

      ENDDO

      xml_node( "rata_i", AllTrim( Str( _t_rata_iznos, 12, 2 ) ) )
      xml_node( "rata_uk", AllTrim( Str( _t_rata_ukupno, 12, 2 ) ) )
      xml_node( "rata_up", AllTrim( Str( _t_rata_uplaceno, 12, 2 ) ) )
      xml_node( "kred_uk", AllTrim( Str( _t_kred_ukupno, 12, 2 ) ) )
      xml_node( "kred_up", AllTrim( Str( _t_kred_uplaceno, 12, 2 ) ) )
      xml_node( "ostatak", AllTrim( Str( _t_ostatak, 12, 2 ) ) )

      xml_subnode( "kred", .T. )

   ENDDO

   xml_subnode( "spec", .T. )

   close_xml()

   RETURN
