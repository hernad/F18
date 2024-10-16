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

CREATE CLASS DokAttr

   VAR cModul
   VAR lGetAttrFromDbf
   VAR hAttrId
   VAR cAttr
   VAR nAttrWA
   VAR cTableNameServer
   VAR cTableNameDbf
   VAR cAliasAttribTable

   METHOD New( cProgramskiModul, nAttWA )
   METHOD get_attr( hId, cAttr )
   METHOD set_attr( cAttr, cValue )
   METHOD delete_attr_from_dbf()
   METHOD update_attr_rbr()
   METHOD create_dbf( lForceCreate )
   METHOD cleanup_attrs( nArrPriprema, aAttrIds )
   METHOD zap_attr_dbf()
   METHOD push_attr_from_dbf_to_server()
   METHOD get_attr_from_server_to_dbf()

   METHOD push_attr_from_mem_to_dbf( hAttribs )
   METHOD update_attr_on_server( hParams )
   METHOD delete_attr_from_server()
   METHOD open_attr_dbf()

   METHOD get_attr_from_dbf( cAttr )
   METHOD get_attr_from_server( cAttr )
   METHOD get_attrs_from_server_for_document()

   METHOD set_table_names()
   METHOD set_dbf_alias()
   METHOD attr_delete_duplicate( hParam )
   METHOD brisi_visak_atributa( nAreaPriprema )

ENDCLASS




METHOD New( cProgramskiModul, nAttWA ) CLASS DokAttr

   ::hAttrId := hb_Hash()

   IF cProgramskiModul <> NIL
      ::cModul := cProgramskiModul
   ENDIF

   IF nAttWA <> NIL
      ::nAttrWA := nAttWA  // F_FAKT_ATTR
   ENDIF

   ::set_table_names()
   ::set_dbf_alias()

   RETURN SELF



METHOD set_dbf_alias()  CLASS DokAttr

   ::cAliasAttribTable := AllTrim( Lower( ::cModul ) ) + "_attr" // fakt_attr, kalk_attr

   RETURN .T.




METHOD open_attr_dbf()  CLASS DokAttr

   SELECT ( ::nAttrWA )

   IF Select( ::cTableNameDbf ) == 0
      IF !my_use( ::cTableNameDbf )
         RETURN .F.
      ENDIF
   ENDIF

   my_dbSelectArea( ::cTableNameDbf )
   SET ORDER TO TAG "1"

   // #ifdef F18_DEBUG
   // IF is_in_main_thread()
   // browse_dbf( ::cTableNameDbf )
   // ENDIF
   // #endif
   GO TOP

   RETURN .T.




METHOD create_dbf( lForceCreate )  CLASS DokAttr

   LOCAL aDbf := {}
   LOCAL _ind_key := "idfirma + idtipdok + brdok + rbr + atribut"
   LOCAL _ind_uniq := ".t."

   IF lForceCreate == NIL
      lForceCreate := .F.
   ENDIF

   AAdd( aDbf, { 'IDFIRMA', 'C',   2,  0 } )
   AAdd( aDbf, { 'IDTIPDOK', 'C',   2,  0 } )
   AAdd( aDbf, { 'BRDOK', 'C',   8,  0 } )
   AAdd( aDbf, { 'RBR', 'C',   3,  0 } )
   AAdd( aDbf, { 'ATRIBUT', 'C',  50,  0 } )
   AAdd( aDbf, { 'VALUE', 'C', 250,  0 } )


   dbf_init( aDbf, ::cTableNameDbf, Upper( ::cTableNameDbf ) )

   // IF lForceCreate .OR. !File( my_home() + ::cTableNameDbf + ".dbf" )
   // dbCreate( my_home() + ::cTableNameDbf + ".dbf", _dbf )
   // ENDIF

   ::open_attr_dbf()

   // INDEX ON &cKljucIz  TAG (cTag)  TO (cImeCdx) FOR &cFilter UNIQUE
   INDEX ON &_ind_key TAG "1" FOR &_ind_uniq UNIQUE

   SELECT ( ::nAttrWA )
   USE

   RETURN SELF



METHOD set_table_names()  CLASS DokAttr

   IF !Empty( ::cModul )
      ::cTableNameDbf := AllTrim( Lower( ::cModul ) ) + "_attr"
      ::cTableNameServer := F18_PSQL_SCHEMA + "." + AllTrim( Lower( ::cModul ) ) + "_" + ;
         AllTrim( Lower( ::cModul ) ) + "_atributi"
   ELSE
      MsgBeep( "DATA:cModul nije setovano !" )
   ENDIF

   RETURN .T.



METHOD get_attr( hId, cAttr )  CLASS DokAttr

   LOCAL cRet

   IF PCount() > 0

      IF hId <> NIL
         ::hAttrId := hId
      ENDIF
      IF cAttr <> NIL
         ::cAttr := cAttr
      ENDIF
   ENDIF

   IF !::lGetAttrFromDbf
      cRet := ::get_attr_from_server()
   ELSE
      cRet := ::get_attr_from_dbf()
   ENDIF

   RETURN cRet



METHOD get_attr_from_dbf( cAttr ) CLASS DokAttr

   LOCAL cRet := ""

   hb_default( @cAttr, ::cAttr )
   PushWa()

   ::open_attr_dbf()

   SET ORDER TO TAG "1"
   dbSeek( ::hAttrId[ "idfirma" ] + ::hAttrId[ "idtipdok" ] + ::hAttrId[ "brdok" ] +  ::hAttrId[ "rbr" ] + cAttr, .T. )

   IF Found()
      cRet := AllTrim( field->value )
   ENDIF

   PopWa()

   RETURN cRet



METHOD get_attr_from_server( cAttr )  CLASS DokAttr

   LOCAL cVal := ""
   LOCAL aAttribs

   IF cAttr != NIL
      ::cAttr := cAttr
   ENDIF

   aAttribs := ::get_attrs_from_server_for_document()

   IF aAttribs != NIL .AND. Len( aAttribs ) <> 0
      cVal := aAttribs[ 1, 3 ] // { "rbr", "value", "atribut" }
   ENDIF

   RETURN cVal


METHOD get_attr_from_server_to_dbf() CLASS DokAttr

   LOCAL aAttribs
   LOCAL nI, hRec

   aAttribs := ::get_attrs_from_server_for_document()

   IF aAttribs == NIL
      RETURN .F.
   ENDIF

   PushWa()
   ::open_attr_dbf()
   GO TOP

   FOR nI := 1 TO Len( aAttribs )

      APPEND BLANK

      hRec := dbf_get_rec()
      hRec[ "idfirma" ] := ::hAttrId[ "idfirma" ]
      hRec[ "idtipdok" ] := ::hAttrId[ "idtipdok" ]
      hRec[ "brdok" ] := ::hAttrId[ "brdok" ]
      hRec[ "rbr" ] := aAttribs[ nI, 1 ]
      hRec[ "atribut" ] := aAttribs[ nI, 2 ]
      hRec[ "value" ] := aAttribs[ nI, 3 ]

      dbf_update_rec( hRec )

   NEXT

   PopWa()

   RETURN .T.

// ----------------------------------------------------------------------------
// vraca listu atributa sa servera za pojedini dokument
//
// ako zadamo id_firma + tip_dok + br_dok -> dobijamo sve za taj dokument
// ako zadamo id_firma + tip_dok + br_dok + r_br -> dobijamo za tu stavku
// ako zadamo id_firma + tip_dok + br_dok + r_br + atribut -> dobijamo
// samo trazeni atribut
//
// vraca se matrica { "rbr", "value", "atribut" }
// ----------------------------------------------------------------------------
METHOD get_attrs_from_server_for_document() CLASS DokAttr

   LOCAL aAttr := {}
   LOCAL _table, oItem
   LOCAL _idfirma, _idtipdok, _brdok, _rbr, cAttr
   LOCAL _where

   _idfirma := ::hAttrId[ "idfirma" ]
   _idtipdok := ::hAttrId[ "idtipdok" ]
   _brdok := ::hAttrId[ "brdok" ]

   IF ::cAttr == NIL
      cAttr := ""  // svi atributi
   ELSE
      cAttr := ::cAttr
   ENDIF

   IF hb_HHasKey( ::hAttrId, "rbr" )
      if ::hAttrId[ "rbr" ] == NIL
         _rbr := ""
      ELSE
         _rbr := ::hAttrId[ "rbr" ]
      ENDIF
   ELSE
      _rbr := ""
   ENDIF

   _where := "idfirma = " + sql_quote( _idfirma )
   _where += " AND "
   _where += "brdok = " + sql_quote( _brdok )
   _where += " AND "
   _where += "idtipdok = " + sql_quote( _idtipdok )

   IF !Empty( _rbr )
      _where += " AND rbr = " + sql_quote( _rbr )
   ENDIF

   IF !Empty( cAttr )
      _where += " AND atribut = " + sql_quote( cAttr )
   ENDIF

   _table := select_all_records_from_table( ::cTableNameServer, NIL, { _where }, { "atribut" } )

   IF sql_error_in_query( _table )
      RETURN NIL
   ENDIF

   _table:GoTo( 1 )

   DO WHILE !_table:Eof()
      oItem := _table:GetRow()
      AAdd( aAttr, { oItem:FieldGet( oItem:FieldPos( "rbr" ) ), ;
         oItem:FieldGet( oItem:FieldPos( "atribut" ) ), ;
         hb_UTF8ToStr( oItem:FieldGet( oItem:FieldPos( "value" ) ) ) } )
      _table:Skip()
   ENDDO

   RETURN aAttr



METHOD set_attr( cAttr, cValue ) CLASS DokAttr

   LOCAL _ok := .T.
   LOCAL hRec

   PushWA()

   ::open_attr_dbf()

   SET ORDER TO TAG "1"
   dbSeek( ::hAttrId[ "idfirma" ] + ::hAttrId[ "idtipdok" ] + ::hAttrId[ "brdok" ] + ::hAttrId[ "rbr" ] + cAttr )

   IF !Found()

      IF Empty( cValue )
         USE
         PopWa()
         RETURN _ok
      ENDIF

      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "idfirma" ] := ::hAttrId[ "idfirma" ]
      hRec[ "idtipdok" ] := ::hAttrId[ "idtipdok" ]
      hRec[ "brdok" ] := ::hAttrId[ "brdok" ]
      hRec[ "rbr" ] := ::hAttrId[ "rbr" ]
      hRec[ "atribut" ] := cAttr
      hRec[ "value" ] := cValue

      dbf_update_rec( hRec )

   ELSE

      hRec := dbf_get_rec()
      hRec[ "value" ] := cValue
      dbf_update_rec( hRec )

   ENDIF

   PopWa()

   RETURN _ok




METHOD push_attr_from_mem_to_dbf( hAttribs ) CLASS DokAttr

   LOCAL cKey

   FOR EACH cKey in hAttribs:keys() // prodji kroz atribute i napuni dbf
      ::set_attr( cKey, hAttribs[ cKey ] )
   NEXT

   RETURN .T.




METHOD zap_attr_dbf() CLASS DokAttr

   PushWA()

   open_exclusive_zap_close( ::cTableNameDbf )

   PopWa()

   RETURN .T.


METHOD delete_attr_from_dbf()  CLASS DokAttr

   LOCAL _idfirma, _idtipdok, _brdok, _rbr, cAttr

   _idfirma := ::hAttrId[ "idfirma" ]
   _idtipdok := ::hAttrId[ "idtipdok" ]
   _brdok := ::hAttrId[ "brdok" ]

   IF hb_HHasKey( ::hAttrId, "rbr" )
      _rbr := ::hAttrId[ "rbr" ]
   ENDIF

   IF hb_HHasKey( ::hAttrId, "atribut" )
      cAttr := ::hAttrId[ "atribut" ]
   ELSE
      cAttr := NIL
   ENDIF

   IF _rbr == NIL
      _rbr := ""
   ENDIF

   IF cAttr == NIL
      cAttr := ""
   ENDIF

   PushWA()
   ::open_attr_dbf()

   my_flock()


   dbSeek( _idfirma + _idtipdok + _brdok + _rbr + cAttr, .T. )

   DO WHILE !Eof() .AND. field->idfirma == _idfirma .AND. field->idtipdok == _idtipdok ;
         .AND. field->brdok == _brdok ;
         .AND. IF( !Empty( _rbr ), field->rbr == _rbr, .T. ) ;
         .AND. IF( !Empty( cAttr ), field->atribut == cAttr, .T. )
      DELETE
      SKIP
   ENDDO

   my_unlock()


   PopWa()

   RETURN .T.



METHOD update_attr_rbr()  CLASS DokAttr

   LOCAL _idfirma, _idtipdok, _brdok, _rbr, _update_rbr
   LOCAL hRec, _thRec

   IF !hb_HHasKey( ::hAttrId, "update_rbr" )
      RETURN .F.
   ENDIF

   _idfirma := ::hAttrId[ "idfirma" ]
   _idtipdok := ::hAttrId[ "idtipdok" ]
   _brdok := ::hAttrId[ "brdok" ]
   _rbr := ::hAttrId[ "rbr" ]
   _update_rbr := ::hAttrId[ "update_rbr" ]

   PushWA()
   ::open_attr_dbf()
   dbSeek( _idfirma + _idtipdok + _brdok + _update_rbr, .T. )

   DO WHILE !Eof() .AND. field->idfirma == _idfirma .AND. field->idtipdok == _idtipdok ;
         .AND. field->brdok == _brdok ;
         .AND. field->rbr == _update_rbr

      SKIP 1
      _thRec := RecNo()
      SKIP -1

      hRec := dbf_get_rec()
      hRec[ "rbr" ] := _rbr
      dbf_update_rec( hRec )

      GO ( _thRec )

   ENDDO

   PopWA()

   RETURN .T.



METHOD update_attr_on_server( hParams )

   LOCAL oRet
   LOCAL cQuery
   LOCAL _old_firma := hParams[ "old_firma" ]
   LOCAL _old_tipdok := hParams[ "old_tipdok" ]
   LOCAL _old_brdok := hParams[ "old_brdok" ]
   LOCAL _new_firma := hParams[ "new_firma" ]
   LOCAL _new_tipdok := hParams[ "new_tipdok" ]
   LOCAL _new_brdok := hParams[ "new_brdok" ]

   // prvo pobrisi sa servera
   cQuery := "UPDATE " + ::cTableNameServer + " "
   cQuery += "SET "
   cQuery += "idfirma = " + sql_quote( _new_firma )
   cQuery += ", idtipdok = " + sql_quote( _new_tipdok )
   cQuery += ", brdok = " + sql_quote( _new_brdok )
   cQuery += " WHERE "
   cQuery += " idfirma = " + sql_quote( _old_firma )
   cQuery += " AND idtipdok = " + sql_quote( _old_tipdok )
   cQuery += " AND brdok = " + sql_quote( _old_brdok )

   oRet := run_sql_query( cQuery )
   IF sql_error_in_query( oRet, "UPDATE" )
      RETURN .F.
   ENDIF

   RETURN .T.




METHOD delete_attr_from_server()  CLASS DokAttr

   LOCAL cQuery, _ret

   cQuery := "DELETE FROM " + ::cTableNameServer
   cQuery += " WHERE "
   cQuery += "idfirma = " + sql_quote( ::hAttrId[ "idfirma" ] )
   cQuery += " AND idtipdok = " + sql_quote( ::hAttrId[ "idtipdok" ] )
   cQuery += " AND brdok = " + sql_quote( ::hAttrId[ "brdok" ] )

   _ret := run_sql_query( cQuery )

   IF sql_error_in_query( _ret )
      RETURN .F.
   ENDIF

   RETURN .T.




METHOD push_attr_from_dbf_to_server()  CLASS DokAttr

   LOCAL _ok := .T.
   LOCAL cQuery
   LOCAL _res

   PushWA()
   ::open_attr_dbf()

   IF RecCount2() == 0
      USE
      PopWa()
      RETURN .T.
   ENDIF

   IF !::delete_attr_from_server()
      USE
      PopWa()
      RETURN .F.
   ENDIF

   SELECT ( ::nAttrWA )
   SET ORDER TO TAG "1"

   DO WHILE !Eof()

      IF Empty( field->value )
         SKIP
         LOOP
      ENDIF

      IF ( ::hAttrId[ "idfirma" ] != field->idfirma ) .OR. ;
            ( ::hAttrId[ "idtipdok" ] != field->idtipdok ) .OR. ;
            ( ::hAttrId[ "brdok" ] != field->brdok )
         SKIP
         LOOP
      ENDIF

      cQuery := "INSERT INTO " + ::cTableNameServer + " "
      cQuery += "( idfirma, idtipdok, brdok, rbr, atribut, value ) "
      cQuery += "VALUES ("
      cQuery += sql_quote( ::hAttrId[ "idfirma" ] ) + ", "
      cQuery += sql_quote( ::hAttrId[ "idtipdok" ] ) + ", "
      cQuery += sql_quote( ::hAttrId[ "brdok" ] ) + ", "
      cQuery += sql_quote( field->rbr ) + ", "
      cQuery += sql_quote( field->atribut ) + ", "
      cQuery += sql_quote( field->value )
      cQuery += ")"

      _res := run_sql_query( cQuery )
      IF sql_error_in_query( _res, "INSERT" )
         _ok := .F.
         EXIT
      ENDIF

      SKIP

   ENDDO

   PopWa()

   RETURN _ok




/*
 ova funkcija treba da uradi:
 - provjeri ima li viska atributa
 - provjeri ima li duplih atributa
cleanup_attrs( F_FAKT_PRIPR, _a_fakt_doks )

*/
METHOD cleanup_attrs( nArrPriprema, aAttrIds )  CLASS DokAttr

   LOCAL _dok_params
   LOCAL nI

   FOR nI := 1 TO Len( aAttrIds )

      _dok_params := hb_Hash()
      _dok_params[ "idfirma" ] := aAttrIds[ nI, 1 ]
      _dok_params[ "idtipdok" ] := aAttrIds[ nI, 2 ]
      _dok_params[ "brdok" ] := aAttrIds[ nI, 3 ]
      ::attr_delete_duplicate( _dok_params )

   NEXT

   ::brisi_visak_atributa( nArrPriprema )

   RETURN .T.


/*
  brisi_visak_atributa( F_FAKT_PRIPR )
*/
METHOD brisi_visak_atributa( nAreaPriprema )  CLASS DokAttr

   LOCAL _ok := .T.
   LOCAL _deleted := .F.
   LOCAL _thRec
   LOCAL cSeek
   LOCAL lStavkaInPriprema

   PushWa()

   SELECT ( nAreaPriprema )
   SET ORDER TO TAG "1"

   ::open_attr_dbf()

   my_flock()

   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      SKIP 1
      _thRec := RecNo()
      SKIP -1


      IF SELECT ( ::cAliasAttribTable ) > 0
         my_dbSelectArea( ::cAliasAttribTable )
         cSeek := field->idfirma + field->idtipdok + field->brdok + field->rbr
      ELSE
         error_bar( "bug", log_stack( 1 ) )
         cSeek := "XXX"
      ENDIF

      SELECT ( nAreaPriprema ) // F_FAKT_PRIPR
      dbSeek( cSeek, .T. )
      lStavkaInPriprema := Found()

      my_dbSelectArea( ::cAliasAttribTable )

      IF !lStavkaInPriprema // u fakt_pripr nema ove stavke vise, brisi atribut u dbf tabeli atributa
         DELETE
         _deleted := .T.
      ENDIF

      GO ( _thRec )

   ENDDO
   my_unlock()

   IF _deleted
      // my_dbf_pack()
   ENDIF

   PopWa()

   RETURN _ok



METHOD attr_delete_duplicate( hParam )  CLASS DokAttr

   LOCAL _id_firma, _tip_dok, _br_dok, _b1
   LOCAL _ok := .T.
   LOCAL _r_br, cAttr, _r_br_2, cAttr_2
   LOCAL _deleted := .F.
   LOCAL _thRec

   _id_firma := hParam[ "idfirma" ]
   _tip_dok := hParam[ "idtipdok" ]
   _br_dok := hParam[ "brdok" ]

   PushWa()
   ::open_attr_dbf()

   my_flock()

   SET ORDER TO TAG "1"
   dbSeek( _id_firma + _tip_dok + _br_dok, .T. )

   _b1 := {|| field->idfirma == _id_firma .AND. field->idtipdok == _tip_dok .AND. field->brdok == _br_dok }

   DO WHILE !Eof() .AND. Eval( _b1 )

      _r_br := field->rbr
      cAttr := field->atribut
      SKIP 1
      _thRec := RecNo()
      _r_br_2 := field->rbr
      cAttr_2 := field->atribut
      SKIP -1

      IF Eval( _b1 ) .AND. ( _r_br_2 == _r_br ) .AND. ( cAttr_2 == cAttr )
         DELETE
         _deleted := .T.
      ENDIF

      GO _thRec
   ENDDO

   my_unlock()

   IF _deleted
      // my_dbf_pack( .F. )
   ENDIF

   PopWa()

   RETURN _ok
