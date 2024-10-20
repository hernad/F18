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


CLASS RnalCsvImport

   DATA params

   VAR doc_no

   METHOD new()
   METHOD import()

   PROTECTED:

   METHOD get_article()
   METHOD get_shape_type()
   METHOD get_vars()
   METHOD csv_browse()
   METHOD csv_browse_key_handler()
   METHOD string_to_number()

ENDCLASS




METHOD RnalCsvImport:New( _doc_no )

   ::params := NIL
   ::doc_no := _doc_no

   RETURN self




METHOD RnalCsvImport:import()

   LOCAL _ok := .F.
   LOCAL oCsv
   LOCAL _struct := {}
   LOCAL _rec, _art_id, _qtty, _height, _width
   LOCAL _count := 0
   LOCAL nDbfArea := Select()

   if ::params == NIL .AND. !::get_vars()
      RETURN _ok
   ENDIF

   // sada ja ovo rucno zadajem...
   // prakticno obicna struktura kao za DBF tabelu
   AAdd( _struct, { "POSITION", "C", 20, 0 } )
   AAdd( _struct, { "WIDTH", "C", 15, 0 } )
   AAdd( _struct, { "HEIGHT", "C", 15, 0 } )
   AAdd( _struct, { "QTTY", "C", 10, 0 } )
   AAdd( _struct, { "SHAPE", "C", 10, 0 } )
   AAdd( _struct, { "M2",   "C", 15, 0 } )
   AAdd( _struct, { "UM2",   "C", 15, 0 } )
   AAdd( _struct, { "MARKER", "C", 1, 0 } )

   // otvori CSV fajl
   oCsv := CsvReader():new()
   oCsv:struct := _struct
   oCsv:csvname := ::params[ "import_path" ] + ::params[ "csv_file" ]
   oCsv:read()

   IF RecCount() == 0
      oCsv:close()
      RETURN _ok
   ENDIF

   SELECT csvimp
   GO TOP

   // markiraj sve stavke za prenos, osim headera
   DO WHILE !Eof()
      IF Upper( AllTrim( field->position ) ) <> "POZICIJA"
         REPLACE field->marker WITH "*"
      ENDIF
      SKIP
   ENDDO

   GO TOP

   // daj mi pregled csvimp tabele
   if ::csv_browse() == 0
      oCsv:close()
      RETURN _ok
   ENDIF

   _art_id := ::get_article()

   IF _art_id == NIL
      oCsv:close()
      RETURN _ok
   ENDIF

   GO TOP

   DO WHILE !Eof()

      // preskacemo sve što nije markirano za prenos
      IF field->marker <> "*"
         SKIP 1
         LOOP
      ENDIF

      IF Val( field->height ) == 0 .OR. Val( field->width ) == 0 .OR. Val( field->qtty ) == 0
         SKIP 1
         LOOP
      ENDIF

      ++ _count

      _qtty := ::string_to_number( field->qtty, "BA" )
      _height := ::string_to_number( field->height, "BA" )
      _width := ::string_to_number( field->width, "BA" )

      SELECT _doc_it
      APPEND BLANK

      _rec := dbf_get_rec()

      // standardna polja bitna za unos
      _rec[ "doc_no" ] := ::doc_no
      _rec[ "doc_it_no" ] := inc_docit( ::doc_no )
      _rec[ "doc_it_typ" ] := " "
      _rec[ "it_lab_pos" ] := "I"
      _rec[ "doc_it_alt" ] := gDefNVM
      _rec[ "doc_acity" ] := PadR( gDefCity, 50 )
      _rec[ "doc_it_sch" ] := "N"
      _rec[ "doc_it_typ" ] := ::get_shape_type( csvimp->shape )
      _rec[ "doc_it_pos" ] := AllTrim( csvimp->position )

      // sada podaci artikla i kolicina...
      _rec[ "art_id" ] := _art_id
      _rec[ "doc_it_wid" ] := _width
      _rec[ "doc_it_hei" ] := _height
      _rec[ "doc_it_qtt" ] := _qtty

      dbf_update_rec( _rec )

      SELECT csvimp
      SKIP

   ENDDO

   oCsv:close()

   IF _count > 0
      Msgbeep( "Uspjesno importovano " + AllTrim( Str( _count ) ) + " zapisa." )
      _ok := .T.
   ENDIF

   RETURN _ok




METHOD RnalCsvImport:get_article()
   RETURN get_items_article()



METHOD RnalCsvImport:get_shape_type( shape )

   LOCAL _type := " "

   IF Lower( AllTrim( shape ) ) == "nepravilni"
      _type := "S"
   ENDIF

   RETURN _type






METHOD RnalCsvImport:csv_browse()

   LOCAL _box_x := f18_max_rows() - 10
   LOCAL _box_y := f18_max_cols() - 10
   LOCAL nDbfArea := Select()
   LOCAL _ret := 0
   LOCAL _header := "Pregled importovanih podataka CSV fajla..."
   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL nI
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}
   PRIVATE GetList := {}

   // kolone browse-a
   AAdd( ImeKol, { PadC( "Pozicija", 20 ), {|| position }, "position" } )
   AAdd( ImeKol, { PadC( "Sirina", 15 ), {|| width }, "width" } )
   AAdd( ImeKol, { PadC( "Visina", 15 ), {|| height }, "height" } )
   AAdd( ImeKol, { PadC( "Kolicina", 15 ), {|| qtty }, "qtty" } )
   AAdd( ImeKol, { PadC( "Oblik", 10 ), {|| shape }, "shape" } )
   AAdd( ImeKol, { PadC( "Marker", 6 ), {|| marker }, "marker" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   SELECT csvimp
   GO TOP

   // otvori box
   Box(, _box_x, _box_y )

   @ box_x_koord() + _box_x, box_x_koord() + 2 SAY "<SPACE> markiranje stavki za prenos  <ESC> izlaz"

   my_browse( "csvimp", _box_x, _box_y, {|| ::csv_browse_key_handler() }, _header, "foot",,,,, 1 )

   IF LastKey() == K_ESC .AND. Pitanje(, "Importovati sadržaj fajla (D/N) ?", "D" ) == "D"
      _ret := 1
   ENDIF

   BoxC()

   box_x_koord( nX )
   box_y_koord( nY )

   SELECT ( nDbfArea )

   RETURN _ret



METHOD RnalCsvImport:csv_browse_key_handler()

   DO CASE

   CASE Ch == K_SPACE
      IF field->marker == "*"
         REPLACE field->marker WITH ""
      ELSE
         REPLACE field->marker WITH "*"
      ENDIF
      RETURN DE_REFRESH

   ENDCASE

   RETURN DE_CONT




METHOD RnalCsvImport:get_vars()

   LOCAL _ok := .F.
   LOCAL nX := 1
   LOCAL _import_path := PadR( fetch_metric( "rnal_csv_import_path", my_user(), "" ), 200 )
   LOCAL _imp_ok := "D"
   LOCAL _csv_file := ""
   LOCAL _csv_filter := "*.csv"
   LOCAL _delimiter := ","

   Box(, 5, 60 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** import CSV fajla"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Lokacija fajla:" GET _import_path PICT "@S35"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Izvršiti import fajla (D/N) ?" GET _imp_ok VALID _imp_ok $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC .OR. _imp_ok == "N"
      RETURN _ok
   ENDIF

   _import_path := AllTrim( _import_path )
   IF Right( _import_path, 1 ) <> SLASH
      _import_path += SLASH
   ENDIF

   // zabiljezi za ubuduce
   set_metric( "rnal_csv_import_path", my_user(), _import_path )

   // idemo na izbor fajla
   IF get_file_list_array( _import_path, _csv_filter, @_csv_file ) == 0
      RETURN _ok
   ENDIF

   IF Pitanje(, "Import fajla " + _csv_file + " (D/N) ?", "D" ) == "N"
      RETURN _ok
   ENDIF

   _ok := .T.

   ::params := hb_Hash()
   ::params[ "import_path" ] := AllTrim( _import_path )
   ::params[ "csv_file" ] := _csv_file
   ::params[ "delimiter" ] := _delimiter

   RETURN _ok


METHOD RnalCsvImport:string_to_number( val, countryCode )

   LOCAL sepDec := ","
   LOCAL sep1000 := "."
   LOCAL cTmp

   IF countryCode == NIL
      countryCode = "BA"
   ENDIF

   IF countryCode == "EN"
      RETURN Val( val )
   ENDIF

   cTmp := StrTran( val, sep1000, "" )
   cTmp := StrTran( val, sepDec, "." )

   RETURN Val( cTmp )
