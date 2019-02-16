/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


CLASS RNALDamageDocument

   METHOD New()
   METHOD get_damage_data()
   METHOD get_damage_items()
   METHOD has_damage_data()
   METHOD has_multiglass()
   METHOD generate_rnal_document()
   METHOD multiglass_configurator()

   DATA damage_items
   DATA damage_data
   DATA doc_no
   DATA multiglass

   PROTECTED:

   METHOD open_tables()
   METHOD get_damage_items_cond()
   METHOD get_damage_items_qtty()
   METHOD get_damage_article()
   METHOD get_rnal_header_data()
   METHOD get_rnal_items_data()
   METHOD get_rnal_opers_data()
   METHOD config_tbl_struct()
   METHOD configurator_box()
   METHOD configurator_box_key_handler()
   METHOD set_configurator_box_columns()
   METHOD fill_config_tbl()
   METHOD configurator_edit_data()
   METHOD fix_items()

ENDCLASS



METHOD RNALDamageDocument:New()

   ::damage_data := NIL
   ::damage_items := NIL
   ::doc_no := NIL
   ::multiglass := NIL

   RETURN SELF


// vraca podatke o ostecenju za nalog broj
METHOD RNALDamageDocument:get_damage_data()

   LOCAL _ok := .F.
   LOCAL cQuery, _table
   LOCAL _log_type := "21"

   cQuery := "SELECT " + ;
      "  lit.doc_no, " + ;
      "  lit.doc_log_no, " + ;
      "  lit.doc_lit_no, " + ;
      "  lit.doc_lit_ac, " + ;
      "  lit.art_id, " + ;
      "  lit.char_1, " + ;
      "  lit.num_1, " + ;
      "  lit.num_2, " + ;
      "  lit.int_1, " + ;
      "  lit.int_2, " + ;
      "  dlog.doc_log_da, " + ;
      "  dlog.doc_log_ti " + ;
      "FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_lit lit " + ;
      "LEFT JOIN " + F18_PSQL_SCHEMA_DOT + " rnal_doc_log dlog ON lit.doc_no = dlog.doc_no " + ;
      "   AND dlog.doc_log_no = lit.doc_log_no " + ;
      "WHERE dlog.doc_log_ty = " + sql_quote( _log_type ) + ;
      "   AND dlog.doc_no = " + AllTrim( Str( ::doc_no ) ) + " " + ;
      "ORDER BY lit.doc_no, lit.doc_log_no, lit.doc_lit_no"

   MsgO( "formiranje sql upita u toku ..." )
   _table := run_sql_query( cQuery )
   MsgC()

   IF _table == NIL
      RETURN NIL
   ENDIF

   ::damage_data := _table

   RETURN


METHOD RNALDamageDocument:get_damage_items()

   LOCAL oRow
   LOCAL _item, _scan

   ::damage_items := {}
   ::damage_data:GoTo( 1 )

   DO WHILE !::damage_data:Eof()

      oRow := ::damage_data:GetRow()

      _item := oRow:FieldGet( oRow:FieldPos( "int_1" ) )
      _scan := AScan( ::damage_items, {| var | VAR[ 1 ] == _item } )

      IF _scan == 0
         AAdd( ::damage_items, { _item } )
      ENDIF

      ::damage_data:skip()

   ENDDO

   ::damage_data:GoTo( 1 )

   RETURN


// -------------------------------------------------------------
// vrati uslov za sql izraz na osnovu ovoga
// -------------------------------------------------------------
METHOD RNALDamageDocument:get_damage_items_cond( field_name )

   LOCAL _cond := ""
   LOCAL nI

   if ::damage_items == NIL .OR. Len( ::damage_items ) == 0
      RETURN _cond
   ENDIF

   _cond := " AND " +  field_name + " IN ( "

   FOR nI := 1 TO Len( ::damage_items )
      _cond += AllTrim( Str( ::damage_items[ nI, 1 ] ) )
      IF nI < Len( ::damage_items )
         _cond += ", "
      ENDIF
   NEXT

   _cond += " ) "

   RETURN _cond


// -------------------------------------------------------------
// vraca podatke o ostecenju za nalog broj
// -------------------------------------------------------------
METHOD RNALDamageDocument:has_damage_data()

   LOCAL _res
   LOCAL _where

   _where := "WHERE doc_log_ty = " + sql_quote( _log_type ) + ;
      "   AND doc_no = " + AllTrim( Str( ::doc_no ) );

      _res := table_count( F18_PSQL_SCHEMA_DOT + "rnal_doc_log", _where )

   RETURN _res


METHOD RNALDamageDocument:has_multiglass()

   LOCAL _ok := .F.
   LOCAL oRow, _art_id, _a_art

   ::damage_data:GoTo( 1 )

   DO WHILE !::damage_data:Eof()

      oRow := ::damage_data:GetRow()

      _art_id := oRow:FieldGet( oRow:FieldPos( "art_id" ) )
      _a_art := {}

      rnal_matrica_artikla( _art_id, @_a_art )

      IF is_izo( _a_art ) .OR. is_lami( _a_art ) .OR. is_lamig( _a_art )
         _ok := .T.
         EXIT
      ENDIF

      ::damage_data:Skip()

   ENDDO

   ::damage_data:GoTo( 1 )

   ::multiglass := _ok

   RETURN _ok



// --------------------------------------------------------
// pokreni konfiguraciju, tj. odaberi zamjenska stakla
// --------------------------------------------------------
METHOD RNALDamageDocument:multiglass_configurator()

   LOCAL _ok := .F.

   ::fill_config_tbl()
   ::configurator_box()

   _ok := .T.

   RETURN _ok



METHOD RNALDamageDocument:configurator_box()

   LOCAL _x_pos := f18_max_rows() - 15
   LOCAL _y_pos := f18_max_cols() - 10
   LOCAL _opts := "<ENTER> definisi novi artikal  <ESC> izlaz/snimanje"
   LOCAL _head, _foot
   PRIVATE Kol, ImeKol

   _head := "Konfiguracija artikala za novi nalog..."
   _foot := ""

   Box(, _x_pos, _y_pos, .T. )

   SELECT _tmp1
   GO TOP

   // setuj kolone konfiguratora
   ::set_configurator_box_columns( @ImeKol, @Kol )

   @ box_x_koord() + ( _x_pos - 1 ), box_y_koord() + 1 SAY _opts

   my_browse( "_tmp1", _x_pos, _y_pos, {|| ::configurator_box_key_handler() }, _head, _foot,,,,, 2 )

   BoxC()

   SELECT _tmp1
   GO TOP

   RETURN



// ----------------------------------------------------------------------
//
// ----------------------------------------------------------------------
METHOD RNALDamageDocument:configurator_box_key_handler()

   DO CASE
   CASE Ch == K_ENTER
      if ::configurator_edit_data()
         RETURN DE_REFRESH
      ENDIF

   ENDCASE

   RETURN DE_CONT




// ----------------------------------------------------------------------
//
// ----------------------------------------------------------------------
METHOD RNALDamageDocument:configurator_edit_data()

   LOCAL _ok := .F.
   LOCAL _art_id := 0

   Box(, 3, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Postavi novi artikal:" GET _art_id ;
      VALID {|| s_articles( @_art_id, .F., .T.  ), ;
      check_article_valid( _art_id ) } ;
      PICT "9999999999"
   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   _rec := dbf_get_rec()

   _rec[ "art_id_2" ] := _art_id

   dbf_update_rec( _rec )

   _ok := .T.

   RETURN _ok




// ----------------------------------------------------------------------
// setovanje kolona konfiguratora
// ----------------------------------------------------------------------
METHOD RNALDamageDocument:set_configurator_box_columns( ime_kol, kol )

   LOCAL nI

   ime_kol := {}
   kol := {}

   // definisanje kolona
   AAdd( ime_kol, { "rbr", {|| docit_str( doc_it_no ) }, ;
      "doc_it_no", {|| .T. }, {|| .T. } } )

   AAdd( ime_kol, { "Artikal/Kol.", {|| sh_article( art_id, doc_it_qtt, 0, 0 ) }, ;
      "art_id", {|| .T. }, {|| .T. } } )

   AAdd( ime_kol, { "Br.stakla", {|| glass_no }, ;
      "glass_no", {|| .T. }, {|| .T. } } )

   AAdd( ime_kol, { "Novi artikal", {|| if( art_id_2 <> 0, sh_article( art_id_2, doc_it_qtt, 0, 0 ), "ostaje isti" ) }, ;
      "art_id_2", {|| .T. }, {|| .T. } } )

   FOR nI := 1 TO Len( ime_kol )
      AAdd( kol, nI )
   NEXT

   RETURN


// -----------------------------------------------------------------
// sredjuje redne brojeve u pripremi...
// -----------------------------------------------------------------
METHOD RNALDamageDocument:fix_items()
   RETURN


// ------------------------------------------------------------------
// vraca artikal za novi nalog, originalni ili iz konfiguratora
// ------------------------------------------------------------------
METHOD RNALDamageDocument:get_damage_article( doc_no, item_no, art_orig )

   LOCAL nDbfArea := Select()
   LOCAL _ret := art_orig

   IF !::multiglass
      RETURN _ret
   ENDIF

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( doc_no ) + docit_str( item_no ) + Str( art_orig, 10, 0 )

   IF !Found()
      SELECT ( nDbfArea )
      RETURN _ret
   ENDIF

   IF field->art_id_2 <> 0
      _ret := field->art_id_2
   ENDIF

   SELECT ( nDbfArea )

   RETURN _ret




// ------------------------------------------------------------
// filuje tabelu konfiguratora sa podacima
// ------------------------------------------------------------
METHOD RNALDamageDocument:fill_config_tbl()

   LOCAL _db_struct := ::config_tbl_struct()
   LOCAL oRow
   LOCAL _count := 0

   // 1) napravi pomocnu tabelu
   cre_tmp1( _db_struct )
   o_tmp1()
   INDEX on ( Str( doc_no, 10, 0 ) + Str( doc_it_no, 4, 0 ) + Str( art_id, 10, 0 ) ) TAG "1"

   SELECT _tmp1
   SET ORDER TO TAG "1"
   GO TOP

   // 2) napuni mi podatke iz tabele ostecenih stavki
   ::damage_data:GoTo( 1 )

   // daj mi podatke stavki
   // _items_tbl := ::get_rnal_items_data()
   // _items_tbl:GoTo(1)

   DO WHILE !::damage_data:Eof()

      oRow := ::damage_data:GetRow()

      SELECT _tmp1
      APPEND BLANK

      _rec := dbf_get_rec()

      _rec[ "doc_no" ] := oRow:FieldGet( oRow:FieldPos( "doc_no" ) )
      _rec[ "doc_it_no" ] := oRow:FieldGet( oRow:FieldPos( "int_1" ) )
      _rec[ "art_id" ] := oRow:FieldGet( oRow:FieldPos( "art_id" ) )
      _rec[ "glass_no" ] := oRow:FieldGet( oRow:FieldPos( "int_2" ) )
      _rec[ "doc_it_qtt" ] := oRow:FieldGet( oRow:FieldPos( "num_2" ) )
      // ovo je zamjenski artikal
      _rec[ "art_id_2" ] := 0

      dbf_update_rec( _rec )

      ++ _count

      ::damage_data:Skip()

   ENDDO

   ::damage_data:GoTo( 1 )

   RETURN _count




// --------------------------------------------------------
// vraca strukturu config tabele
// --------------------------------------------------------
METHOD RNALDamageDocument:config_tbl_struct()

   LOCAL _dbf := {}

   AAdd( _dbf, { "doc_no", "N", 10, 0 } )
   AAdd( _dbf, { "doc_it_no", "N", 4, 0 } )
   AAdd( _dbf, { "art_id", "N", 10, 0 } )
   AAdd( _dbf, { "glass_no", "N", 3, 0 } )
   AAdd( _dbf, { "doc_it_qtt", "N", 12, 2 } )
   AAdd( _dbf, { "art_id_2", "N", 10, 2 } )

   RETURN _dbf



// ------------------------------------------------------
// vraca header podatke dokumenta
// ------------------------------------------------------
METHOD RNALDamageDocument:get_rnal_header_data()

   LOCAL cQuery, _table

   cQuery := "SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "rnal_docs " + ;
      " WHERE doc_no = " + docno_str( ::doc_no ) + ;
      " ORDER BY doc_no"

   _table := run_sql_query( cQuery )
   IF sql_error_in_query( _table )
      RETURN NIL
   ENDIF

   RETURN _table


// ------------------------------------------------------
// vraca item podatke dokumenta
// ------------------------------------------------------
METHOD RNALDamageDocument:get_rnal_items_data()

   LOCAL cQuery, _table
   LOCAL _items_cond := ::get_damage_items_cond( "doc_it_no" )
   LOCAL nI

   cQuery := " SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_it " + ;
      " WHERE doc_no = " + AllTrim( Str( ::doc_no ) ) + _items_cond + ;
      " ORDER BY doc_no, doc_it_no "

   _table := run_sql_query( cQuery )

   IF sql_error_in_query( _table ) == NIL
      RETURN NIL
   ENDIF

   RETURN _table


// ------------------------------------------------------
// vraca oper podatke dokumenta
// ------------------------------------------------------
METHOD RNALDamageDocument:get_rnal_opers_data()

   LOCAL cQuery, _table
   LOCAL _items_cond := ::get_damage_items_cond( "doc_it_no" )

   cQuery := " SELECT * FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_ops " + ;
      " WHERE doc_no = " + AllTrim( Str( ::doc_no ) ) + _items_cond + ;
      " ORDER BY doc_no, doc_it_no, doc_op_no"

   _table := run_sql_query( cQuery )
   IF sql_error_in_query( _table )
      RETURN NIL
   ENDIF

   RETURN _table



// -----------------------------------------------------
// generisanje novog dokumenta...
// -----------------------------------------------------
METHOD RNALDamageDocument:generate_rnal_document()

   LOCAL _ok := .F.
   LOCAL _rec
   LOCAL _header_tbl, _items_tbl, _opers_tbl
   LOCAL _damage_doc_no := 0
   LOCAL _fix_items := {}
   LOCAL oRow, _scan
   LOCAL _count := 0

   // otvori mi sve tabele potrebne za rad !
   ::open_tables()

   IF _docs->( RecCount() ) <> 0
      MsgBeep( "Priprema nije prazna !!!" )
      RETURN _ok
   ENDIF

   // daj mi podatke header-a
   _header_tbl := ::get_rnal_header_data()
   _header_tbl:GoTo( 1 )

   // daj mi podatke stavki
   _items_tbl := ::get_rnal_items_data()
   _items_tbl:GoTo( 1 )

   // daj mi podatke operacija
   _opers_tbl := ::get_rnal_opers_data()
   _opers_tbl:GoTo( 1 )

   // 1) ubaci podatke header-a

   oRow := _header_tbl:GetRow()

   SELECT _docs
   APPEND BLANK

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := _damage_doc_no
   _rec[ "doc_date" ] := danasnji_datum()
   _rec[ "doc_dvr_da" ] := danasnji_datum() + 2
   _rec[ "doc_dvr_ti" ] := PadR( PadR( Time(), 5 ), 8 )
   _rec[ "doc_ship_p" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_ship_p" ) ) )
   _rec[ "doc_priori" ] := oRow:FieldGet( oRow:FieldPos( "doc_priori" ) )
   _rec[ "doc_pay_id" ] := oRow:FieldGet( oRow:FieldPos( "doc_pay_id" ) )
   _rec[ "doc_paid" ] := oRow:FieldGet( oRow:FieldPos( "doc_paid" ) )
   _rec[ "doc_pay_de" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_pay_de" ) ) )
   _rec[ "doc_status" ] := 10
   _rec[ "doc_sh_des" ] := "NP na osnovu: " + AllTrim( docno_str( oRow:FieldGet( oRow:FieldPos( "doc_no" ) ) ) ) ;
      + ", " + hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_sh_des" ) ) )
   _rec[ "doc_desc" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_desc" ) ) )
   _rec[ "operater_i" ] := f18_get_user_id( f18_user() )
   _rec[ "cust_id" ] := oRow:FieldGet( oRow:FieldPos( "cust_id" ) )
   _rec[ "cont_add_d" ] := oRow:FieldGet( oRow:FieldPos( "cont_add_d" ) )
   _rec[ "cont_id" ] := oRow:FieldGet( oRow:FieldPos( "cont_id" ) )
   _rec[ "obj_id" ] := oRow:FieldGet( oRow:FieldPos( "obj_id" ) )
   _rec[ "doc_type" ] := "NP"

   dbf_update_rec( _rec )

   // 2) ubaci podatke u items...

   DO WHILE !_items_tbl:Eof()

      oRow := _items_tbl:GetRow()

      _item := oRow:FieldGet( oRow:FieldPos( "doc_it_no" ) )

      SELECT _doc_it
      APPEND BLANK

      _rec := dbf_get_rec()

      _rec[ "doc_no" ] := _damage_doc_no
      _rec[ "doc_it_no" ] := inc_docit( _damage_doc_no )

      // dodaj u matricu fix_items, stari/novi redni broj
      AAdd( _fix_items, { _item, _rec[ "doc_it_no" ] } )

      _rec[ "doc_it_typ" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_typ" ) )
      _rec[ "it_lab_pos" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "it_lab_pos" ) ) )
      _rec[ "doc_it_alt" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_alt" ) )
      _rec[ "doc_it_des" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_it_des" ) ) )
      _rec[ "doc_acity" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_acity" ) ) )
      _rec[ "doc_it_sch" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_it_sch" ) ) )
      _rec[ "doc_it_wid" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_wid" ) )
      _rec[ "doc_it_w2" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_w2" ) )
      _rec[ "doc_it_hei" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_hei" ) )
      _rec[ "doc_it_h2" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_h2" ) )

      // artikal ces mozda uzeti i iz konfiguratora....
      _rec[ "art_id" ] := ::get_damage_article( oRow:FieldGet( oRow:FieldPos( "doc_no" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "doc_it_no" ) ), ;
         oRow:FieldGet( oRow:FieldPos( "art_id" ) ) )

      // broj komada ostecenog stakla
      _rec[ "doc_it_qtt" ] := ::get_damage_items_qtty( _item )

      dbf_update_rec( _rec )

      ++ _count

      _items_tbl:Skip()

   ENDDO


   // 3) ubaci podatke u operacije

   DO WHILE !_opers_tbl:Eof()

      oRow := _opers_tbl:GetRow()

      _item := oRow:FieldGet( oRow:FieldPos( "doc_it_no" ) )

      SELECT _doc_ops
      APPEND BLANK

      _rec := dbf_get_rec()

      _rec[ "doc_no" ] := _damage_doc_no

      // pronadji i redni broj na osnovu kontrolne matrice
      _scan := AScan( _fix_items, {|var| VAR[ 1 ] == _item } )
      _item_no := _fix_items[ _scan, 2 ]

      _rec[ "doc_it_no" ] := _item_no
      _rec[ "doc_op_no" ] := inc_docop( _damage_doc_no )
      _rec[ "doc_it_el_" ] := oRow:FieldGet( oRow:FieldPos( "doc_it_el_" ) )
      _rec[ "aop_id" ] := oRow:FieldGet( oRow:FieldPos( "aop_id" ) )
      _rec[ "aop_att_id" ] := oRow:FieldGet( oRow:FieldPos( "aop_att_id" ) )
      _rec[ "doc_op_des" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "doc_op_des" ) ) )
      _rec[ "aop_value" ] := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "aop_value" ) ) )

      dbf_update_rec( _rec )

      _opers_tbl:Skip()

   ENDDO


   IF _count > 0
      MsgBeep( "Kreiran nalog tip-a NEUSKLADJENI PROIZVOD#Nalazi se u pripremi!#PREGLEDATI GA PRIJE AZURIRANJA" )
   ENDIF

   _ok := .T.

   RETURN _ok




// -----------------------------------------------------
// koliko je osteceno stakala za stavku
// -----------------------------------------------------
METHOD RNALDamageDocument:get_damage_items_qtty( item_no )

   LOCAL _qtty := 0
   LOCAL _item, oRow

   ::damage_data:GoTo( 1 )

   DO WHILE !::damage_data:Eof()

      oRow := ::damage_data:GetRow()
      _item := oRow:FieldGet( oRow:FieldPos( "int_1" ) )

      IF _item == item_no
         _qtty := oRow:FieldGet( oRow:FieldPos( "num_2" ) )
         EXIT
      ENDIF

      ::damage_data:Skip()

   ENDDO

   ::damage_data:GoTo( 1 )

   RETURN _qtty





// -----------------------------------------------------
// otvaranje potrebnih tabela
// -----------------------------------------------------
METHOD RNALDamageDocument:open_tables()

   rnal_o_tables( .T. )

   RETURN



// ---------------------------------------------
// generisi neuskladjeni nalog
// ---------------------------------------------
FUNCTION rnal_damage_doc_generate( doc_no )

   LOCAL oDamage := RNALDamageDocument():New()

   // setuj broj dokumenta za koji cemo ovo sve raditi
   oDamage:doc_no := doc_no
   // daj mi podatke loma za ovaj nalog
   oDamage:get_damage_data()

   // ima li podataka ?
   IF oDamage:damage_data == NIL
      MsgBeep( "Ovaj dokument nema evidencije loma !" )
      RETURN
   ENDIF

   // daj mi matricu stavki koje su sporne sa naloga
   oDamage:get_damage_items()

   // konfigurator ako su visestruka stakla
   IF oDamage:has_multiglass()
      MsgBeep( "Ovaj nalog sadrzi visestruka stakla !#Napravite odgovarajucu zamjenu u tabeli" )
      oDamage:multiglass_configurator()
   ENDIF

   oDamage:generate_rnal_document()

   RETURN
