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

STATIC __cust_id

// -------------------------------------
// otvara tabelu objekata
// -------------------------------------
FUNCTION s_objects( cId, nCust_id, cObjDesc, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   LOCAL cTag := "4"
   PRIVATE ImeKol
   PRIVATE Kol

   IF nCust_id == nil
      nCust_id := -1
   ENDIF

   IF cObjDesc == nil
      cObjDesc := ""
   ENDIF

   __cust_id := nCust_id

   nTArea := Select()

   cHeader := "Objekti /"

   O_OBJECTS

   SELECT objects

   IF cID == nil
      // obj_desc
      cTag := "4"
   ELSE
      // cust_id + obj_desc
      cTag := "3"
   ENDIF

   set_a_kol( @ImeKol, @Kol, nCust_id )

   IF ValType( cId ) == "C"
      // try to validate
      IF Val( cId ) <> 0

         cId := Val( cId )
         nCust_id := -1
         cObjDesc := ""
         cTag := "1"
      ENDIF
   ENDIF

   SET ORDER TO TAG cTag

   SET FILTER TO
   obj_filter( nCust_id, cObjDesc )

   cRet := p_sifra( F_OBJECTS, cTag, f18_max_rows() -15, f18_max_cols() -5, cHeader, @cId, dx, dy, {|| key_handler( Ch ) } )

   IF LastKey() == K_ESC
      cId := 0
   ENDIF

   SELECT ( nTArea )

   RETURN cRet


// --------------------------------------
// obrada tipki u sifrarniku
// --------------------------------------
STATIC FUNCTION key_handler()

   LOCAL nRet := DE_CONT

   DO CASE
   CASE Ch == K_F3
      nRet := rnal_wid_edit( "OBJ_ID" )
   ENDCASE

   RETURN nRet

// -----------------------------------------
// setovanje kolona tabele
// -----------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol, nCust_id )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( obj_id ) }, "obj_id", {|| rnal_uvecaj_id( @wObj_id, "OBJ_ID" ), .F. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "Narucioc", 10 ), {|| g_cust_desc( cust_id ) }, "cust_id", {|| set_cust_id( @wCust_id ) }, {|| s_customers( @wCust_id ), show_it( g_cust_desc( wcust_id ) ) } } )
   AAdd( aImeKol, { PadC( "Naziv objekta", 20 ), {|| PadR( obj_desc, 30 ) }, "obj_desc", {|| .T. }, {|| rnal_chk_id( @wObj_id, "OBJ_ID" ) } } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// ----------------------------------------------
// setuje cust_id pri unosu automatski
// ----------------------------------------------
STATIC FUNCTION set_cust_id( nCust_id )

   IF __cust_id > 0
      nCust_id := __cust_id
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF

   RETURN


// -------------------------------------------
// filter po cust_id
// nCust_id - id customer
// -------------------------------------------
STATIC FUNCTION obj_filter( nCust_id, cObjDesc )

   LOCAL cFilter := ""

   IF nCust_id > 0
      cFilter += "cust_id == " + custid_str( nCust_id )
   ENDIF

   IF !Empty( cObjDesc )

      IF !Empty( cFilter )
         cFilter += " .and. "
      ENDIF

      cObjDesc := AllTrim( cObjDesc )
      cFilter += " ALLTRIM(UPPER(obj_desc)) = " + dbf_quote( Upper( cObjDesc ) )

   ENDIF

   IF !Empty( cFilter )
      SET FILTER to &cFilter
      GO TOP
   ENDIF

   RETURN



// -------------------------------
// convert obj_id to string
// -------------------------------
FUNCTION objid_str( nId )
   RETURN Str( nId, 10 )


// -------------------------------
// get obj_id_desc by obj_id
// -------------------------------
FUNCTION g_obj_desc( nObj_id, lEmpty )

   LOCAL cObjDesc := "?????"

   PushWA()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cObjDesc := ""
   ENDIF

   O_OBJECTS
   SELECT objects
   SET ORDER TO TAG "1"
   GO TOP
   SEEK objid_str( nObj_id )

   IF Found()
      IF !Empty( field->obj_desc )
         cObjDesc := AllTrim( field->obj_desc )
      ENDIF
   ENDIF

   PopWa()

   RETURN cObjDesc
