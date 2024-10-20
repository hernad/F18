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



FUNCTION os_popisna_lista()

   LOCAL _pars

   _o_tables()

   IF !_get_vars( @_pars )
      RETURN .F.
   ENDIF

   IF !_gen_xml( _pars )
      RETURN .F.
   ENDIF

   IF generisi_odt_iz_xml( "mat_invent.odt", my_home() + "data.xml" )
      prikazi_odt()
   ENDIF

   RETURN .T.


STATIC FUNCTION _o_tables()

   //o_rj()
   o_os_sii()

   RETURN


// uslovi izvjestaja
STATIC FUNCTION _get_vars( params )

   LOCAL _ok := .F.
   LOCAL _idrj := PadR( fetch_metric( "os_popis_idrj", my_user(), "" ), Len( field->idrj ) )
   LOCAL _on := "N"
   LOCAL _filt_k1 := Space( 100 )
   LOCAL _filt_dob := Space( 100 )
   LOCAL _filt_jmj := PadR( fetch_metric( "os_popis_jmj", my_user(), "" ), 100 )
   LOCAL _cijena := "N"

   Box(, 10, 77 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica:" GET _idrj ;
      VALID {|| P_RJ( @_idrj ), IF( !Empty( _idrj ), _idrj := PadR( _idrj, 4 ), .T. ), .T. }

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prikaz svih neotpisanih (N) / otpisanih(O) /"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "samo novonabavljenih (B)    / iz proteklih godina (G)" GET _on PICT "@!" ;
      VALID _on $ "ONBG"

   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET _filt_k1 PICT "@!S20"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Filter po dobavljacima:" GET _filt_dob PICT "@!S20"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Filter po jedin. mjere:" GET _filt_jmj PICT "@!S20"

   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikaz nab.cijene (D/N) ?" GET _cijena PICT "@!" VALID _cijena $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   _ok := .T.

   set_metric( "os_popis_idrj", my_user(), AllTrim( _idrj ) )
   set_metric( "os_popis_jmj", my_user(), AllTrim( _filt_jmj ) )

   params := hb_Hash()
   params[ "idrj" ] := _idrj
   params[ "prikaz" ] := _on
   params[ "filter_k1" ] := _filt_k1
   params[ "filter_dob" ] := _filt_dob
   params[ "filter_jmj" ] := _filt_jmj
   params[ "cijena" ] := ( _cijena == "D" )

   RETURN _ok


// generisanje podataka...
STATIC FUNCTION _gen_xml( params )

   LOCAL _idrj := PadR( params[ "idrj" ], 4 )
   LOCAL _prikaz := params[ "prikaz" ]
   LOCAL _filt_jmj := params[ "filter_jmj" ]
   LOCAL _filt_k1 := params[ "filter_k1" ]
   LOCAL _filt_dob := params[ "filter_dob" ]
   LOCAL _filter := ""
   LOCAL _rbr := 0
   LOCAL _ok := .F.

   select_o_os_or_sii()
   SET ORDER TO TAG "2"

   IF !Empty( _idrj )
      _filter += "idrj=" + _filter_quote( _idrj )
   ENDIF

   IF !Empty( _filt_jmj )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      _filter += Parsiraj( Upper( _filt_jmj ), "UPPER(jmj)" )
   ENDIF

   IF !Empty( _filt_k1 )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      _filter += Parsiraj( _filt_k1, "k1" )
   ENDIF

   IF !Empty( _filt_dob )
      IF !Empty( _filter )
         _filter += " .AND. "
      ENDIF
      _filter += Parsiraj( _filt_dob, "idpartner" )
   ENDIF

   IF !Empty( _filter )
      SET FILTER to &_filter
   ENDIF

   GO TOP

   create_xml( my_home() + "data.xml" )
   xml_head()

   xml_subnode( "inv", .F. )

   // header
   xml_node( "fid", to_xml_encoding( self_organizacija_id() ) )
   xml_node( "fnaz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "datum", DToC( os_datum_obracuna() ) )
   xml_node( "kid", to_xml_encoding( _idrj ) )
   xml_node( "knaz", "" )
   xml_node( "pid", "" )
   xml_node( "pnaz", "" )
   xml_node( "modul", "OS" )

   DO WHILE !Eof()

      IF ( _prikaz == "B" .AND. Year( os_datum_obracuna() ) <> Year( field->datum ) )
         SKIP
         LOOP
      ENDIF

      IF ( _prikaz == "G" .AND. Year( os_datum_obracuna() ) = Year( field->datum ) )
         SKIP
         LOOP
      ENDIF

      IF ( !Empty( datotp ) .AND. Year( datotp ) <= Year( os_datum_obracuna() ) ) .AND. _prikaz $ "NB"
         SKIP
         LOOP
      ENDIF

      IF ( Empty( datotp ) .AND. Year( datotp ) < Year( os_datum_obracuna() ) ) .AND. _prikaz == "O"
         SKIP
         LOOP
      ENDIF

      xml_subnode( "items", .F. )

      xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
      xml_node( "rid", to_xml_encoding( field->id ) )
      xml_node( "naz", to_xml_encoding( field->naz ) )
      xml_node( "jmj", to_xml_encoding( field->jmj ) )
      xml_node( "stanje", Str( field->kolicina, 12, 2 ) )

      IF params[ "cijena" ]
         xml_node( "cijena", Str( field->nabvr, 12, 2 ) )
      ELSE
         xml_node( "cijena", "" )
      ENDIF

      xml_subnode( "items", .T. )

      SKIP

   ENDDO

   xml_subnode( "inv", .T. )

   close_xml()

   my_close_all_dbf()

   IF _rbr > 0
      _ok := .T.
   ENDIF

   RETURN _ok
