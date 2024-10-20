/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


STATIC FUNCTION kopiraj_operacije_sa_azuriranog_naloga( r_doc_no )

   LOCAL _count := 0, _rec

   SELECT ( F_DOC_OPS )
   IF !Used()
      O_DOC_OPS
   ENDIF

   SELECT ( F__DOC_OPST )
   IF !Used()
      O__DOC_OPST
   ENDIF

   SELECT _doc_opst
   IF RecCount() > 0
      my_dbf_zap()
   ENDIF

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( r_doc_no )

   IF !Found()
      MsgBeep( "Za ovaj nalog operacije ne postoje !#Prekidam operaciju." )
      RETURN _count
   ENDIF

   MsgO( "Kopiram operacije naloga u pomoćnu tabelu ..." )

   DO WHILE !Eof() .AND. field->doc_no == r_doc_no

      ++ _count

      _rec := dbf_get_rec()

      SELECT _doc_opst
      APPEND BLANK

      dbf_update_rec( _rec )

      SELECT doc_ops
      SKIP

   ENDDO

   MsgC()

   RETURN _count



FUNCTION rnal_azuriraj_statuse( doc_no )

   LOCAL _promjena := .F.
   LOCAL _promj_count := 0
   LOCAL lOk := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "rnal_doc_ops" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele!#Prekidam operaciju." )
      lOk := .F.
      RETURN lOk
   ENDIF

   SELECT _doc_opst
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      _rec := dbf_get_rec()

      SELECT doc_ops
      SET ORDER TO TAG "1"
      GO TOP
      SEEK docno_str( _rec[ "doc_no" ] ) + docit_str( _rec[ "doc_it_no" ] ) + Str( _rec[ "doc_op_no" ], 4 )

      IF !Found()
         SELECT _doc_opst
         SKIP
         LOOP
      ENDIF

      _rec_ops := dbf_get_rec()
      _promjena := .F.

      IF _rec_ops[ "op_status" ] <> _rec[ "op_status" ]
         _rec_ops[ "op_status" ] := _rec[ "op_status" ]
         _promjena := .T.
      ENDIF

      IF _rec_ops[ "op_notes" ] <> _rec[ "op_notes" ]
         _rec_ops[ "op_notes" ] := _rec[ "op_notes" ]
         _promjena := .T.
      ENDIF

      IF _promjena

         log_write( "F18_DOK_OPER: rnal, setovanje statusa operacije - dokument: " + ;
            AllTrim( Str( _rec[ "doc_no" ] ) ) + ;
            ", stavka: " + AllTrim( Str( _rec[ "doc_op_no" ] ) ) + ;
            ", status: " + AllTrim( _rec[ "op_status" ] ) + ;
            ", opis: " + AllTrim( _rec[ "op_notes" ] ), 2 )
         lOk := update_rec_server_and_dbf( "rnal_doc_ops", _rec, 1, "CONT" )

         IF !lOk
            EXIT
         ENDIF

         ++ _promj_count

      ENDIF

      SELECT _doc_opst
      SKIP

   ENDDO

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "rnal_doc_ops" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   IF lOk
      SELECT _doc_opst
      my_dbf_zap()
   ENDIF

   RETURN lOk




STATIC FUNCTION _nalog()

   LOCAL _nalog := 0

   Box(, 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Pregledati za nalog:" GET _nalog PICT "9999999999" VALID _nalog > 0
   READ
   BoxC()

   IF LastKey() == K_ESC
      _nalog := NIL
   ENDIF

   RETURN _nalog



FUNCTION rnal_pregled_statusa_operacija( r_doc_no )

   LOCAL _ok := .T.
   LOCAL _footer
   LOCAL _header
   LOCAL _box_x := f18_max_rows() - 10
   LOCAL _box_y := f18_max_cols() - 10

   PRIVATE imekol
   PRIVATE kol

   IF r_doc_no == NIL
      r_doc_no := _nalog()
      IF r_doc_no == NIL
         RETURN _ok
      ENDIF
   ENDIF

   rnal_o_tables( .T. )

   IF kopiraj_operacije_sa_azuriranog_naloga( r_doc_no ) < 1
      MsgBeep( "Nalog ne sadrži niti jednu operaciju !#Prekidam operaciju." )
      RETURN _ok
   ENDIF

   _footer := "Pregled statusa naloga " + AllTrim( Str( r_doc_no, 10, 0 ) )
   _header := ""

   Box(, _box_x, _box_y )

   _set_box( _box_x, _box_y )
   _set_a_kol( @imekol, @kol )

   SELECT ( F__DOC_OPST )
   IF !Used()
      O__DOC_OPST
   ENDIF

   SELECT _doc_opst
   GO TOP

   my_browse( "nalst", _box_x, _box_y, {|| key_handler( r_doc_no ) }, _header, _footer, , , , , 5 )

   BoxC()

   IF LastKey() == K_ESC

      IF Pitanje(, "Ažurirati promjene na server (D/N) ?", "D" ) == "D"
         rnal_azuriraj_statuse( r_doc_no )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN _ok



STATIC FUNCTION key_handler( doc )

   DO CASE

   CASE Ch == K_F2

      _rec := dbf_get_rec()
      IF _setuj_status( @_rec )
         dbf_update_rec( _rec )
         RETURN DE_REFRESH
      ENDIF

   ENDCASE

   RETURN DE_CONT



STATIC FUNCTION _setuj_status( rec )

   LOCAL _ok := .F.
   LOCAL _x := 1
   LOCAL _op_status := _rec[ "op_status" ]
   LOCAL _op_notes := _rec[ "op_notes" ]

   Box(, 10, 70 )

   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "Postavi status tekuće stavke na "

   ++ _x
   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY8 "  - '1' - završeno "

   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "  - prazno - u izradi"

   ++ _x
   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "           -> odabrani status: " GET _op_status VALID _op_status $ " #1#2"

   ++ _x

   @ box_x_koord() + _x, box_y_koord() + 2 SAY "Napomena:" GET _op_notes PICT "@S50"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   _ok := .T.
   _rec[ "op_notes" ] := _op_notes
   _rec[ "op_status" ] := _op_status

   RETURN _ok



STATIC FUNCTION _set_box( box_x, box_y )

   LOCAL _line_1 := ""
   LOCAL _line_2 := ""

   _line_1 := "(F2) setuj status"
   _line_2 := "-- "

   @ box_x_koord() + ( box_x - 1 ), box_y_koord() + 2 SAY _line_1
   @ box_x_koord() + box_x, box_y_koord() + 2 SAY _line_2

   RETURN



STATIC FUNCTION _set_a_kol( a_ime_kol, a_kol )

   LOCAL nI

   a_ime_kol := {}
   a_kol := {}

   AAdd( a_ime_kol, { "Artikal", ;
      {|| PadR( g_art_desc( _get_doc_article( doc_no, doc_it_no ), .T., .F. ), 20 ) }, ;
      "doc_no", ;
      {|| .T. }, ;
      {|| .T. } } )


   AAdd( a_ime_kol, { "Element", ;
      {|| PadR( _get_doc_op_element( _get_doc_article( doc_no, doc_it_no ), doc_it_el_ ), 10 ) }, ;
      "doc_it_el_", ;
      {|| .T. }, ;
      {|| .T. } } )

   AAdd( a_ime_kol, { "Operacija", ;
      {|| PadR( AllTrim( g_aop_desc( aop_id ) ) + "/" + AllTrim( g_aop_att_desc( aop_att_id ) ), 30 )  }, ;
      "aop_id", ;
      {|| .T. }, ;
      {|| .T. } } )

   AAdd( a_ime_kol, { "Status", ;
      {|| PadR( _get_status( op_status ), 10 ) }, ;
      "aop_value", ;
      {|| .T. }, ;
      {|| .T. } } )

   AAdd( a_ime_kol, { "Napomene", ;
      {|| PadR( op_notes, 50 ) }, ;
      "aop_value", ;
      {|| .T. }, ;
      {|| .T. } } )


   FOR nI := 1 TO Len( a_ime_kol )
      AAdd( a_kol, nI )
   NEXT

   RETURN




STATIC FUNCTION _get_status( status )

   LOCAL _ret := ""

   DO CASE
   CASE status == " "
      _ret := "u izradi"
   CASE status == "1"
      _ret := "zavrseno"
   CASE status == "2"
      _ret := "odbaceno"
   ENDCASE

   RETURN _ret




// ----------------------------------------------------------------
// vraca oznaku elementa
// ----------------------------------------------------------------
STATIC FUNCTION _get_doc_op_element( art_id, el_no )

   LOCAL nDbfArea := Select()
   LOCAL _elem := {}
   LOCAL _art := {}
   LOCAL _art_id
   LOCAL _ret := ""
   LOCAL _scan := 0
   LOCAL _el_no

   rnal_matrica_artikla( art_id, @_art )

   _g_art_elements( @_elem, art_id )

   _scan := AScan( _elem, {|val| val[ 1 ] == el_no } )
   _el_no := _elem[ _scan, 3 ]

   _ret := g_el_descr( _art, _el_no )

   SELECT ( nDbfArea )

   RETURN _ret



// -----------------------------------------------------------------
// vraca artikal dokumenta
// -----------------------------------------------------------------
STATIC FUNCTION _get_doc_article( r_doc_no, r_doc_it_no )

   LOCAL _ret := 0
   LOCAL nDbfArea := Select()

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( r_doc_no )  + docit_str( r_doc_it_no )

   _ret := field->art_id

   SELECT ( nDbfArea )

   RETURN _ret
