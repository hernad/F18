/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


//STATIC LEN_VRIJEDNOST := 12
//STATIC PIC_VRIJEDNOST := ""
STATIC _template
STATIC _my_xml


FUNCTION fin_suban_specifikacija_sql()

   LOCAL _rpt_data := {}
   LOCAL _rpt_vars := hb_Hash()
   LOCAL lExported := .F.

   download_template( "fin_specif.odt", "b1435934623a308b0a3e2c39c018840e92a86a66ebd5f2e5daa24722c8eae0ba" )

   _my_xml := my_home() + "data.xml"
   _template := "fin_specif.odt"

   IF !uslovi_izvjestaja( @_rpt_vars )
      RETURN .F.
   ENDIF

   _rpt_data := _cre_rpt( _rpt_vars )

   IF _rpt_data == NIL
      Msgbeep( "Problem sa generisanjem izvještaja !" )
      RETURN .F.
   ENDIF

   IF _rpt_vars[ "export_dbf" ] == "D"
      IF export_podataka_u_dbf( _rpt_data, _rpt_vars )
         lExported := .T.
      ENDIF
   ENDIF

   IF _cre_xml( _rpt_data, _rpt_vars )
      IF generisi_odt_iz_xml( _template, _my_xml )
         prikazi_odt()
      ENDIF
   ENDIF

   IF lExported
      open_exported_xlsx()
   ENDIF

   RETURN .T.



STATIC FUNCTION uslovi_izvjestaja( rpt_vars )

   LOCAL _konto := fetch_metric( "fin_spec_rpt_konto", my_user(), "" )
   LOCAL _partner := fetch_metric( "fin_spec_rpt_partner", my_user(), "" )
   LOCAL _brdok := fetch_metric( "fin_spec_rpt_broj_dokumenta", my_user(), PadR( "", 200 ) )
   LOCAL _idvn := fetch_metric( "fin_spec_rpt_broj_dokumenta", my_user(), PadR( "", 200 ) )
   LOCAL _datum_od := fetch_metric( "fin_spec_rpt_datum_od", my_user(), CToD( "" ) )
   LOCAL _datum_do := fetch_metric( "fin_spec_rpt_datum_do", my_user(), CToD( "" ) )
   LOCAL _opcina := fetch_metric( "fin_spec_rpt_opcina", my_user(), PadR( "", 200 ) )
   LOCAL _tip_val := fetch_metric( "fin_spec_rpt_tip_valute", my_user(), 1 )
   LOCAL _export_dbf := fetch_metric( "fin_spec_rpt_export_dbf", my_user(), "N" )
   LOCAL _sintetika := fetch_metric( "fin_spec_rpt_sintetika", my_user(), "N" )
   LOCAL _nule := fetch_metric( "fin_spec_rpt_nule", my_user(), "N" )
   LOCAL lRasclanitiRj := fetch_metric( "fin_spec_rpt_rasclaniti_rj", my_user(), "N" )
   LOCAL _box_name := "SUBANALITICKA SPECIFIKACIJA"
   LOCAL _box_x := 21
   LOCAL _box_y := 65
   LOCAL _x := 1

   //o_sifk()
   //o_sifv()
   //o_konto()
   //o_partner()

   Box( "#" + _box_name, _box_x, _box_y )

   set_cursor_on()

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Firma "
   ?? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )

   ++ _x
   ++ _x

   _konto := PadR( _konto, 200 )
   _partner := PadR( _partner, 200 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Konto   " GET _konto PICT "@!S50"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Partner " GET _partner PICT "@!S50"

   ++ _x
   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Izvještaj za domaću/stranu valutu (1/2):" GET _tip_val PICT "9"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Datum dokumenta od:" GET _datum_od
   @ box_x_koord() + _x, Col() + 2 SAY "do" GET _datum_do VALID _datum_od <= _datum_do

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Uslov za vrstu naloga (prazno-sve):" GET _idvn PICT "@!S20"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Uslov za broj veze (prazno-svi):" GET _brdok PICT "@!S20"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Općina (prazno-sve):" GET _opcina PICT "@!S20"

   ++ _x
   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Prikaz stavki sa stanjem 0 (D/N)?" GET _nule PICT "@!" VALID _nule $ "DN"

   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Prikaz sintetike (D/N)?" GET _sintetika PICT "@!" VALID _sintetika $ "DN"
   @ box_x_koord() + _x, Col() + 1 SAY8 "Raščlaniti po RJ/FOND/FUNK (D/N)?" GET lRasclanitiRj PICT "@!" VALID lRasclanitiRj $ "DN"

   ++ _x
   ++ _x
   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Eksport izvjestaja u dbf (D/N)?" GET _export_dbf PICT "@!" VALID _export_dbf $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fin_spec_rpt_konto", my_user(), _konto )
   set_metric( "fin_spec_rpt_partner", my_user(), _partner )
   set_metric( "fin_spec_rpt_broj_dokumenta", my_user(), _brdok )
   set_metric( "fin_spec_rpt_broj_dokumenta", my_user(), _idvn )
   set_metric( "fin_spec_rpt_datum_od", my_user(), _datum_od )
   set_metric( "fin_spec_rpt_datum_do", my_user(), _datum_do )
   set_metric( "fin_spec_rpt_tip_valute", my_user(), _tip_val )
   set_metric( "fin_spec_rpt_export_dbf", my_user(), _export_dbf )
   set_metric( "fin_spec_rpt_sintetika", my_user(), _sintetika )
   set_metric( "fin_spec_rpt_nule", my_user(), _nule )
   set_metric( "fin_spec_rpt_rasclaniti_rj", my_user(), lRasclanitiRj )

   rpt_vars[ "konto" ] := _konto
   rpt_vars[ "partner" ] := _partner
   rpt_vars[ "brdok" ] := _brdok
   rpt_vars[ "idvn" ] := _idvn
   rpt_vars[ "datum_od" ] := _datum_od
   rpt_vars[ "datum_do" ] := _datum_do
   rpt_vars[ "opcina" ] := _opcina
   rpt_vars[ "valuta" ] := _tip_val
   rpt_vars[ "export_dbf" ] := _export_dbf
   rpt_vars[ "nule" ] := _nule
   rpt_vars[ "sintetika" ] := _sintetika
   rpt_vars[ "rasclaniti_rj" ] := lRasclanitiRj

   RETURN .T.


STATIC FUNCTION _cre_rpt( rpt_vars )

   LOCAL lRasclanitiRj, _nule, _sintetika, _konto, _partner, _brdok, _idvn
   LOCAL _datum_od, _datum_do, _tip_valute
   LOCAL cQuery, _table
   LOCAL _where, _opcina
   LOCAL _fld_iznos
   LOCAL _rj_fond_funk := ""
   LOCAL _where_cond := ""
   LOCAL _order_cond := ""
   LOCAL _group_cond := ""

   _konto := rpt_vars[ "konto" ]
   _partner := rpt_vars[ "partner" ]
   _brdok := rpt_vars[ "brdok" ]
   _idvn := rpt_vars[ "idvn" ]
   _datum_od := rpt_vars[ "datum_od" ]
   _datum_do := rpt_vars[ "datum_do" ]
   _opcina := rpt_vars[ "opcina" ]
   _tip_valute := rpt_vars[ "valuta" ]
   _nule := rpt_vars[ "nule" ] == "D"
   _sintetika := rpt_vars[ "sintetika" ] == "D"
   lRasclanitiRj := rpt_vars[ "rasclaniti_rj" ] == "D"
   _fld_iznos := "sub.iznosbhd"

   IF _tip_valute == 2
      _fld_iznos := "sub.iznosdem"
   ENDIF

   IF lRasclanitiRj
      _rj_fond_funk := " sub.idrj, sub.fond, sub.funk, "
   ENDIF

   _where_cond := "WHERE sub.idfirma = " + sql_quote( self_organizacija_id() )
   _where_cond += " AND " + _sql_date_parse( "sub.datdok", _datum_od, _datum_do )
   IF !Empty( _konto )
      _where_cond += " AND " + _sql_cond_parse( "sub.idkonto", _konto )
   ENDIF
   IF !Empty( _partner )
      _where_cond += " AND " + _sql_cond_parse( "sub.idpartner", _partner )
   ENDIF
   IF !Empty( _brdok )
      _where_cond += " AND " + _sql_cond_parse( "sub.brdok", _brdok )
   ENDIF
   IF !Empty( _idvn )
      _where_cond += " AND " + _sql_cond_parse( "sub.idvn", _idvn )
   ENDIF
   IF !Empty( _opcina )
      _where_cond += " AND " + _sql_cond_parse( "part.idops", _opcina )
   ENDIF

   _group_cond := " GROUP BY sub.idkonto, kto.naz, sub.idpartner, part.naz"

   IF lRasclanitiRj
      _group_cond += ", sub.idrj, sub.fond, sub.funk "
   ENDIF

   _order_cond := " ORDER BY sub.idkonto, kto.naz, sub.idpartner, part.naz"

   IF lRasclanitiRj
      _order_cond += ", sub.idrj, sub.fond, sub.funk "
   ENDIF

   cQuery := "SELECT " + ;
      " sub.idkonto as konto_id, " + ;
      " kto.naz as konto_naz, " + ;
      " sub.idpartner as partner_id, " + ;
      " part.naz as partner_naz, " + ;
      _rj_fond_funk + ;
      " SUM( CASE WHEN sub.d_p = '1' THEN " + _fld_iznos + " ELSE 0 END ) AS duguje, " + ;
      " SUM( CASE WHEN sub.d_p = '2' THEN " + _fld_iznos + " ELSE 0 END ) AS potrazuje " + ;
      "FROM " + F18_PSQL_SCHEMA_DOT + "fin_suban sub " + ;
      "LEFT JOIN " + F18_PSQL_SCHEMA_DOT + "partn part ON sub.idpartner = part.id " + ;
      "LEFT JOIN " + F18_PSQL_SCHEMA_DOT + "konto kto ON sub.idkonto = kto.id "
   cQuery += _where_cond
   cQuery += _group_cond
   cQuery += _order_cond

   MsgO( "formiranje sql upita u toku ..." )
   _table := run_sql_query( cQuery )
   MsgC()

   IF !is_var_objekat_tpqquery( _table )
      RETURN NIL
   ENDIF

   RETURN _table



STATIC FUNCTION export_podataka_u_dbf( table, rpt_vars )

   LOCAL oRow, aExportStruct
   LOCAL lRasclanitiRj := rpt_vars[ "rasclaniti_rj" ] == "D"
   LOCAL _nule := rpt_vars[ "nule" ] == "D"
   LOCAL hRec, cKontoId, cPartnerId

   IF table:LastRec() == 0
      RETURN .F.
   ENDIF

   aExportStruct := fin_specifikacija_dbf_struct()
   xlsx_export_init( aExportStruct )

   o_r_export_legacy()

   FOR nI := 1 TO table:LastRec()

      oRow := table:GetRow( nI )

      cKontoId := query_row( oRow, "konto_id" )
      cPartnerId := query_row( oRow, "partner_id" )

      SELECT r_export
      APPEND BLANK

      hRec := dbf_get_rec()
      hRec[ "id_konto" ] := cKontoId
      hRec[ "id_partn" ] := cPartnerId

      IF !Empty ( cPartnerId )
         hRec[ "naziv" ] := query_row( oRow, "partner_naz" )
      ELSE
         hRec[ "naziv" ] := query_row( oRow, "konto_naz" )
      ENDIF

      IF lRasclanitiRj
         hRec[ "rj" ] := query_row( oRow, "idrj" )
         hRec[ "fond" ] := query_row( oRow, "fond" )
         hRec[ "funk" ] := query_row( oRow, "funk" )
      ENDIF

      hRec[ "duguje" ] := query_row( oRow, "duguje" )
      hRec[ "potrazuje" ] := query_row( oRow, "potrazuje" )
      hRec[ "saldo" ] := hRec[ "duguje" ] - hRec[ "potrazuje" ]

      IF Round( hRec[ "saldo" ], 2 ) == 0 .AND. !_nule
         LOOP
      ENDIF

      dbf_update_rec( hRec )

   NEXT

   SELECT r_export
   USE

   RETURN .T.


FUNCTION fin_specifikacija_dbf_struct()

   LOCAL aDbf := {}

   AAdd( aDbf, { "id_konto", "C", 7, 0 }  )
   AAdd( aDbf, { "id_partn", "C", 6, 0 }  )
   AAdd( aDbf, { "rj", "C", 6, 0 }  )
   AAdd( aDbf, { "fond", "C", 6, 0 }  )
   AAdd( aDbf, { "funk", "C", 6, 0 }  )
   AAdd( aDbf, { "naziv", "C", 200, 0 }  )
   AAdd( aDbf, { "duguje", "N", 15, 5 }  )
   AAdd( aDbf, { "potrazuje", "N", 15, 5 }  )
   AAdd( aDbf, { "saldo", "N", 15, 5 }  )

   RETURN aDbf



STATIC FUNCTION _cre_xml( table, rpt_vars )

   LOCAL nI, oRow, oItem
   //LOCAL PIC_VRIJEDNOST := PadL( AllTrim( Right( pic_iznos_eur(), LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )
   LOCAL _dug := 0
   LOCAL _pot := 0
   LOCAL _saldo := 0
   LOCAL _u_dug1 := 0
   LOCAL _u_dug2 := 0
   LOCAL _u_pot1 := 0
   LOCAL _u_pot2 := 0
   LOCAL _u_saldo1 := 0
   LOCAL _u_saldo2 := 0
   LOCAL _u_sint_dug := 0
   LOCAL _u_sint_pot := 0
   LOCAL _u_sint_saldo := 0
   LOCAL _val, _sint_kto
   LOCAL _id_konto, _id_partner
   LOCAL _sintetika := rpt_vars[ "sintetika" ] == "D"
   LOCAL _nule := rpt_vars[ "nule" ] == "D"
   LOCAL lRasclanitiRj := rpt_vars[ "rasclaniti_rj" ] == "D"

   IF table:LastRec() == 0
      RETURN .F.
   ENDIF

   create_xml( _my_xml )

   xml_head()

   xml_subnode( "specif", .F. )

   xml_node( "f_id", self_organizacija_id() )
   xml_node( "f_naz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "f_mj", to_xml_encoding( gMjStr ) )

   xml_node( "datum", DToC( Date() ) )
   xml_node( "datum_od", DToC( rpt_vars[ "datum_od" ] ) )
   xml_node( "datum_do", DToC( rpt_vars[ "datum_do" ] ) )

   IF rpt_vars[ "valuta" ] == 1
      xml_node( "val", "KM" )
   ELSE
      xml_node( "val", "EUR" )
   ENDIF

   _u_pot1 := 0
   _u_dug1 := 0
   _u_saldo1 := 0

   _sint_kto := "X"

   table:GoTo( 1 )

   DO WHILE !table:Eof()

      oItem := table:GetRow()

      _id_konto := oItem:FieldGet( oItem:FieldPos( "konto_id" ) )
      _naz_konto := oItem:FieldGet( oItem:FieldPos( "konto_naz" ) )

      _id_partner := oItem:FieldGet( oItem:FieldPos( "partner_id" ) )
      _naz_partner := oItem:FieldGet( oItem:FieldPos( "partner_naz" ) )

      _sint_kto := PadR( _id_konto, 3 )

      IF lRasclanitiRj
         _rj := oItem:FieldGet( oItem:FieldPos( "idrj" ) )
         _fond := oItem:FieldGet( oItem:FieldPos( "fond" ) )
         _funk := oItem:FieldGet( oItem:FieldPos( "funk" ) )
      ENDIF

      _dug := oItem:FieldGet( oItem:FieldPos( "duguje" ) )
      _pot := oItem:FieldGet( oItem:FieldPos( "potrazuje" ) )
      _saldo := oItem:FieldGet( oItem:FieldPos( "duguje" ) ) - oItem:FieldGet( oItem:FieldPos( "potrazuje" ) )

      IF Round( _saldo, 2 ) == 0 .AND. !_nule
         table:Skip()
         LOOP
      ENDIF

      xml_subnode( "specif_item", .F. )

      xml_node( "konto", to_xml_encoding( hb_UTF8ToStr( _id_konto ) ) )
      xml_node( "partner", to_xml_encoding( hb_UTF8ToStr( _id_partner ) ) )

      IF !Empty( _id_partner )
         xml_node( "naziv", to_xml_encoding( hb_UTF8ToStr( _naz_partner ) ) )
      ELSE
         xml_node( "naziv", to_xml_encoding( hb_UTF8ToStr( _naz_konto ) ) )
      ENDIF

      IF lRasclanitiRj
         xml_node( "rj", to_xml_encoding( hb_UTF8ToStr( _rj ) ) )
         xml_node( "fond", to_xml_encoding( hb_UTF8ToStr( _fond ) ) )
         xml_node( "funk", to_xml_encoding( hb_UTF8ToStr( _funk ) ) )
      ENDIF

      xml_node( "dug", show_number( _dug, pic_iznos_eur() ) )
      _u_dug1 += _dug

      xml_node( "pot", show_number( _pot, pic_iznos_eur() ) )
      _u_pot1 += _pot

      xml_node( "saldo", show_number( _saldo, pic_iznos_eur() ) )
      _u_saldo1 += _saldo

      xml_subnode( "specif_item", .T. )

      table:Skip()

   ENDDO

   xml_node( "dug", show_number( _u_dug1, pic_iznos_eur() ) )
   xml_node( "pot", show_number( _u_pot1, pic_iznos_eur() ) )
   xml_node( "saldo", show_number( _u_saldo1, pic_iznos_eur() ) )

   xml_subnode( "specif", .T. )

   close_xml()

   RETURN .T.
