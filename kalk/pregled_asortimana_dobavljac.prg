/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


FUNCTION asortiman_dobavljac_mp()

   LOCAL hVars

   IF !frm_vars( @hVars )
      RETURN
   ENDIF

   _cre_tmp()

   gen_rpt( hVars )

   IF hVars[ "narudzba" ] == "D"
      print_frm_asort_nar( hVars )
   ELSE
      print_report( hVars )
   ENDIF

   RETURN


STATIC FUNCTION _cre_tmp()

   LOCAL _dbf := {}

   AAdd( _dbf, { "IDKONTO", "C", 7, 0 } )
   AAdd( _dbf, { "IDPARTNER", "C", 6, 0 } )
   AAdd( _dbf, { "IDROBA", "C", 10, 0 } )
   AAdd( _dbf, { "BARKOD", "C", 13, 0 } )
   AAdd( _dbf, { "NAZIV", "C", 40, 0 } )
   AAdd( _dbf, { "TARIFA", "C", 6, 0 } )
   AAdd( _dbf, { "JMJ", "C", 3, 0 } )
   AAdd( _dbf, { "ULAZ", "N", 15, 5 } )
   AAdd( _dbf, { "IZLAZ", "N", 15, 5 } )
   AAdd( _dbf, { "STANJE", "N", 15, 5 } )
   AAdd( _dbf, { "PC", "N", 15, 5 } )

   xlsx_export_init( _dbf )

   o_r_export()
   INDEX ON idroba TAG "roba"

   RETURN


STATIC FUNCTION frm_vars( hVars )

   LOCAL _dat_od, _dat_do, _p_konto, _artikli, _dob, _prik_nule
   LOCAL _narudzba
   LOCAL _x := 1

   _dat_od := fetch_metric( "kalk_spec_mp_dob_dat_od", my_user(), CToD( "" ) )
   _dat_do := fetch_metric( "kalk_spec_mp_dob_dat_do", my_user(), Date() )
   _p_konto := fetch_metric( "kalk_spec_mp_dob_p_konto", my_user(), PadR( "1330", 7 ) )
   _artikli := PadR( fetch_metric( "kalk_spec_mp_dob_artikli", my_user(), "" ), 200 )
   _dob := fetch_metric( "kalk_spec_mp_dob_dobavljac", my_user(), PadR( "", 6 ) )
   _prik_nule := fetch_metric( "kalk_spec_mp_dob_nule", my_user(), "N" )
   _narudzba := fetch_metric( "kalk_spec_mp_dob_narudzba", my_user(), "N" )

   Box(, 10, 70 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Datum od:" GET _dat_od
   @ box_x_koord() + _x, Col() + 1 SAY "do:" GET _dat_do

   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Prodavnički konto:" GET _p_konto VALID P_Konto( @_p_konto )
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Dobavljač:" GET _dob VALID p_partner( @_dob )
   _x += 2
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Artikli (prazno-svi):" GET _artikli PICT "@S35"
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Prikaz stavki kojima je ulaz = 0 (D/N) ?" GET _prik_nule VALID _prik_nule $ "DN" PICT "@!"
   ++_x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Štampati formu narudžbe (D/N) ?" GET _narudzba VALID _narudzba $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // snimi parametre i hash matricu
   set_metric( "kalk_spec_mp_dob_dat_od", my_user(), _dat_od )
   set_metric( "kalk_spec_mp_dob_dat_do", my_user(), _dat_do )
   set_metric( "kalk_spec_mp_dob_p_konto", my_user(), _p_konto )
   set_metric( "kalk_spec_mp_dob_artikli", my_user(), _artikli )
   set_metric( "kalk_spec_mp_dob_dobavljac", my_user(), _dob )
   set_metric( "kalk_spec_mp_dob_nule", my_user(), _prik_nule )
   set_metric( "kalk_spec_mp_dob_narudzba", my_user(), _narudzba )

   hVars := hb_Hash()
   hVars[ "datum_od" ] := _dat_od
   hVars[ "datum_do" ] := _dat_do
   hVars[ "p_konto" ] := _p_konto
   hVars[ "artikli" ] := _artikli
   hVars[ "dobavljac" ] := _dob
   hVars[ "nule" ] := _prik_nule
   hVars[ "narudzba" ] := _narudzba

   RETURN .T.


STATIC FUNCTION gen_rpt( hVars )

   IF _izdvoji_ulaze( hVars ) == 0
      RETURN .F.
   ENDIF
   IF hVars[ "narudzba" ] == "N"
      _izdvoji_prodaju( hVars )
   ENDIF

   RETURN .T.

STATIC FUNCTION _izdvoji_ulaze( hVars )

   LOCAL cQuery := ""
   LOCAL _date := ""
   LOCAL _dat_od, _dat_do, _dob, _artikli, _p_konto, _id_firma
   LOCAL _table
   LOCAL _data := {}
   LOCAL nI, oRow
   LOCAL _cnt := 0

   _p_konto := hVars[ "p_konto" ]
   _dat_od := hVars[ "datum_od" ]
   _dat_do := hVars[ "datum_do" ]
   _artikli := hVars[ "artikli" ]
   _dob := hVars[ "dobavljac" ]
   _id_firma := self_organizacija_id()

   IF _dat_od <> CToD( "" )
      _date += "kalk.datdok >= " + sql_quote( _dat_od )
   ENDIF

   IF _dat_do <> CToD( "" )
      IF !Empty( _date )
         _date += " AND "
      ENDIF
      _date += "kalk.datdok <= " + sql_quote( _dat_do )

   ENDIF

   IF !Empty( _date )
      _date := " AND (" + _date + ")"
   ENDIF

   cQuery := "SELECT " + ;
      "kalk.pkonto pkonto, " + ;
      "kalk.idroba idroba, " + ;
      "roba.barkod barkod, " + ;
      "roba.naz robanaz, " + ;
      "roba.idtarifa idtarifa, " + ;
      "roba.jmj jmj, " + ;
      "SUM( " + ;
      "CASE " + ;
      "WHEN kalk.pu_i = '1' THEN kalk.kolicina " + ;
      "WHEN kalk.pu_i = 'I' THEN kalk.gkolicin2 " + ;
      "ELSE 0 " + ;
      "END " + ;
      ") as ulaz " + ;
      "FROM " + f18_sql_schema( "kalk_kalk" ) + " kalk " + ;
      "LEFT JOIN " + f18_sql_schema("roba") + " roba ON kalk.idroba = roba.id " + ;
      "WHERE " + ;
      "kalk.idfirma = " + sql_quote( _id_firma ) + ;
      " AND kalk.pkonto = " + sql_quote( _p_konto ) + ;
      " AND kalk.idpartner = " + sql_quote( _dob ) + ;
      _date + ;
      " AND roba.tip NOT IN ( " + sql_quote( "T" ) + ", " + sql_quote( "U" ) + " ) " + ;
      "GROUP BY kalk.pkonto, kalk.idroba, roba.barkod, roba.naz, roba.idtarifa, roba.jmj " + ;
      "ORDER BY kalk.idroba"

   _table := run_sql_query( cQuery )

   IF !is_var_objekat_tpqquery( _table )
      RETURN 0
   ENDIF

   MsgO( "Prikupljanje podataka ulaza u maloprodaji... sačekajte !" )

   _table:GoTo( 1 )

   FOR nI := 1 TO _table:LastRec()

      ++_cnt
      oRow := _table:GetRow( nI )

      SELECT r_export
      APPEND BLANK

      hRec := dbf_get_rec()
      hRec[ "idpartner" ] := _dob
      hRec[ "idkonto" ] := oRow:FieldGet( oRow:FieldPos( "pkonto" ) )
      hRec[ "idroba" ] := PadR( oRow:FieldGet( oRow:FieldPos( "idroba" ) ), 10 )
      hRec[ "barkod" ] := PadR( oRow:FieldGet( oRow:FieldPos( "barkod" ) ), 13 )
      hRec[ "naziv" ] := oRow:FieldGet( oRow:FieldPos( "robanaz" ) )
      hRec[ "tarifa" ] := oRow:FieldGet( oRow:FieldPos( "idtarifa" ) )
      hRec[ "jmj" ] := oRow:FieldGet( oRow:FieldPos( "jmj" ) )
      hRec[ "ulaz" ] := oRow:FieldGet( oRow:FieldPos( "ulaz" ) )
      hRec[ "stanje" ] := ( hRec[ "ulaz" ] - hRec[ "izlaz" ] )
      dbf_update_rec( hRec )

   NEXT

   MsgC()

   RETURN _cnt


STATIC FUNCTION _izdvoji_prodaju( hVars )

   LOCAL cQuery := ""
   LOCAL _date := ""
   LOCAL _dat_od, _dat_do, _dob, _artikli, _p_konto, _id_firma
   LOCAL _table
   LOCAL _data := {}
   LOCAL nI, oRow
   LOCAL _cnt := 0
   LOCAL cIdRoba
   LOCAL hRec

   _p_konto := hVars[ "p_konto" ]
   _dat_od := hVars[ "datum_od" ]
   _dat_do := hVars[ "datum_do" ]
   _artikli := hVars[ "artikli" ]
   _dob := hVars[ "dobavljac" ]
   _id_firma := self_organizacija_id()

   IF _dat_od <> CToD( "" )
      _date += "kalk.datdok >= " + sql_quote( _dat_od ) + " "
   ENDIF

   IF _dat_do <> CToD( "" )
      IF !Empty( _date )
         _date += " AND "
      ENDIF
      _date += " kalk.datdok <= " + sql_quote( _dat_do ) + " "
   ENDIF

   IF !Empty( _date )
      _date := " AND (" + _date + ")"
   ENDIF

   cQuery := "SELECT " + ;
      "kalk.pkonto pkonto, " + ;
      "kalk.idroba idroba, " + ;
      "SUM( " + ;
      "CASE " + ;
      "WHEN kalk.pu_i = '5' AND kalk.idvd IN ( " + sql_quote( "12" ) + "," + sql_quote( "13" ) + " ) THEN -kalk.kolicina " + ;
      "WHEN kalk.pu_i = '5' AND kalk.idvd NOT IN ( " + sql_quote( "12" ) + "," + sql_quote( "13" ) + " ) THEN kalk.kolicina " + ;
      "WHEN kalk.idvd = '80' AND kalk.kolicina < 0  THEN -kalk.kolicina " + ;
      "ELSE 0 " + ;
      "END " + ;
      ") as izlaz " + ;
      "FROM " + f18_sql_schema("kalk_kalk") + " kalk " + ;
      "LEFT JOIN " + f18_sql_schema("roba") + " roba ON kalk.idroba = roba.id " + ;
      "WHERE " + ;
      "kalk.idfirma = " + sql_quote( _id_firma ) + ;
      " AND kalk.pkonto = " + sql_quote( _p_konto ) + ;
      _date + ;
      " AND roba.tip NOT IN ( " + sql_quote( "T" ) + ", " + sql_quote( "U" ) + " ) " + ;
      "GROUP BY kalk.pkonto, kalk.idroba " + ;
      "ORDER BY kalk.idroba"

   MsgO( "Prikupljanje podataka o izlazima robe... sačekajte !" )
   _table := run_sql_query( cQuery )
   _table:GoTo( 1 )

   FOR nI := 1 TO _table:LastRec()
      ++_cnt
      oRow := _table:GetRow( nI )
      cIdRoba := oRow:FieldGet( oRow:FieldPos( "idroba" ) )
      SELECT r_export
      SET ORDER TO TAG "roba"
      GO TOP
      SEEK PadR( cIdRoba, 10 )
      IF Found()
         ++_cnt
         hRec := dbf_get_rec()
         hRec[ "izlaz" ] := oRow:FieldGet( oRow:FieldPos( "izlaz" ) )
         hRec[ "stanje" ] := ( hRec[ "ulaz" ] - hRec[ "izlaz" ]  )
         dbf_update_rec( hRec )
      ENDIF

   NEXT
   MsgC()

   RETURN _cnt



// ---------------------------------------------------------
// printanje obrasca narudzbe na osnovu podataka
// ---------------------------------------------------------

STATIC FUNCTION print_frm_asort_nar( hVars )

   LOCAL _my_xml := my_home() + "data.xml"
   LOCAL _template := "kalk_asort_nar.odt"
   LOCAL _count := 0

   download_template( "kalk_asort_nar.odt", "b1124faac9f8e579bdc03e4bdfb39f1d002e7e6c190bf8aa79aaddc981c3f588" )

   create_xml( _my_xml )
   xml_head()

   SELECT r_export
   SET ORDER TO TAG "roba"
   GO TOP

   select_o_partner(  r_export->idpartner )

   SELECT r_export

   xml_subnode( "nar", .F. )

   // podaci matične firme
   xml_node( "firma", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "f_adr", to_xml_encoding( fetch_metric( "org_adresa", NIL, "" ) ) )
   xml_node( "f_mj", to_xml_encoding( gMjStr ) )
   xml_node( "f_tel", to_xml_encoding( fetch_metric( "fakt_zagl_telefon", NIL, "" ) ) )

   // podaci partnera
   xml_node( "part_id", to_xml_encoding( field->idpartner ) )
   xml_node( "part_naz", to_xml_encoding( partn->naz ) )
   xml_node( "part_adr", to_xml_encoding( partn->adresa ) )
   xml_node( "part_mj", to_xml_encoding( partn->mjesto ) )
   xml_node( "part_ptt", to_xml_encoding( partn->ptt ) )
   xml_node( "part_tel", to_xml_encoding( partn->telefon ) )
   xml_node( "datum", DToC( Date() ) )

   DO WHILE !Eof()

      ++_count

      xml_subnode( "item", .F. )

      xml_node( "rbr", AllTrim( Str( _count ) ) )
      xml_node( "idroba", to_xml_encoding( field->idroba ) )
      xml_node( "barkod", to_xml_encoding( field->barkod ) )
      xml_node( "naziv", to_xml_encoding( field->naziv ) )
      xml_node( "jmj", to_xml_encoding( field->jmj ) )

      xml_subnode( "item", .T. )

      SKIP

   ENDDO

   xml_subnode( "nar", .T. )
   close_xml()

   IF _count > 0
      IF generisi_odt_iz_xml( _template, _my_xml )
         prikazi_odt()
      ENDIF
   ENDIF

   RETURN




STATIC FUNCTION print_report( hVars )

   LOCAL _cnt := 0
   LOCAL _head, _line
   LOCAL _t_ulaz := 0
   LOCAL _t_izlaz := 0
   LOCAL _n_pos := 50
   LOCAL _nule := hVars[ "nule" ]

   IF RecCount() == 0
      MsgBeep( "Ne postoje traženi podaci !" )
      RETURN
   ENDIF

   _head := _get_head()
   _line := _get_line()

   START PRINT CRET
   ?

   ?U "SPECIFIKACIJA ASORTIMANA PO DOBAVLJAČIMA NA DAN", DToC( Date() )
   ?U "Za period od", DToC( hVars[ "datum_od" ] ), "do", DToC( hVars[ "datum_do" ] )
   ?U "Prodavnički konto:", hVars[ "p_konto" ]

   o_konto()
   SEEK hVars[ "p_konto" ]
   ?? AllTrim( konto->naz )

   ?U "Dobavljač:", hVars[ "dobavljac" ]

   o_partner()
   SEEK hVars[ "dobavljac" ]
   ?? AllTrim( partn->naz )

   P_COND

   ? _line
   ? _head
   ? _line

   SELECT r_export
   SET ORDER TO TAG "roba"
   GO TOP

   DO WHILE !Eof()

      IF _nule == "N" .AND. Round( field->ulaz, 2 ) == 0
         SKIP
         LOOP
      ENDIF

      ? PadL( AllTrim( Str( ++_cnt ) ), 5 ) + "."

      @ PRow(), PCol() + 1 SAY field->idroba
      @ PRow(), PCol() + 1 SAY field->barkod
      @ PRow(), PCol() + 1 SAY PadR( field->naziv, 40 )
      @ PRow(), PCol() + 1 SAY field->tarifa
      @ PRow(), _n_pos := PCol() + 1 SAY Str( field->ulaz, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->izlaz, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->stanje, 12, 2 )

      _t_ulaz += field->ulaz
      _t_izlaz += field->izlaz

      SKIP

   ENDDO

   ? _line

   ? "UKUPNO:"

   @ PRow(), _n_pos SAY Str( _t_ulaz, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( _t_izlaz, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( _t_ulaz - _t_izlaz, 12, 2 )

   ? _line

   FF
   ENDPRINT

   RETURN


STATIC FUNCTION _get_head()

   LOCAL _head := ""

   _head += PadR( "R.br", 6 )
   _head += Space( 1 )
   _head += PadR( "Artikal", 10 )
   _head += Space( 1 )
   _head += PadR( "Barkod", 13 )
   _head += Space( 1 )
   _head += PadR( "Naziv", 40 )
   _head += Space( 1 )
   _head += PadR( "Tarifa", 7 )
   _head += Space( 1 )
   _head += PadR( "Ulazi", 12 )
   _head += Space( 1 )
   _head += PadR( "Izlazi", 12 )
   _head += Space( 1 )
   _head += PadR( "Razlika", 12 )

   RETURN _head

STATIC FUNCTION _get_line()

   LOCAL _line := ""

   _line += Replicate( "-", 6 )
   _line += Space( 1 )
   _line += Replicate( "-", 10 )
   _line += Space( 1 )
   _line += Replicate( "-", 13 )
   _line += Space( 1 )
   _line += Replicate( "-", 40 )
   _line += Space( 1 )
   _line += Replicate( "-", 7 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )

   RETURN _line
