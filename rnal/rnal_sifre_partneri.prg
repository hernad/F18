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

// -----------------------------------------
// otvara sifrarnik narucioca
// -----------------------------------------
FUNCTION s_customers( cId, cCustDesc, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   LOCAL cTag := "1"
   PRIVATE ImeKol
   PRIVATE Kol

   nTArea := Select()

   O_CUSTOMS

   cHeader := "Naručioci"
   cHeader += Space( 5 )
   cHeader += "/ 'K' - pr.kontakata  / 'O' - pr.objekata"

   SELECT customs
   SET ORDER TO TAG cTag

   IF cCustDesc == nil
      cCustDesc := ""
   ENDIF

   set_a_kol( @ImeKol, @Kol )

   rnal_sifra_bez_tacke( @cCustDesc )

   IF ValType( cId ) == "C"
      rnal_sifra_bez_tacke( @cId )
      IF Val( cId ) <> 0
         cId := Val( cId )
         cCustDesc := ""
      ENDIF
   ENDIF

   set_f_kol( cCustDesc, @cId )

   cRet := p_sifra( F_CUSTOMS, cTag, f18_max_rows() - 15, f18_max_cols() - 5, _u( cHeader ), @cId, dx, dy, {|| key_handler( Ch ) } )

   IF !Empty( cCustDesc )
      SET FILTER TO
      GO TOP
   ENDIF

   IF LastKey() == K_ESC
      cId := 0
   ENDIF

   SELECT ( nTArea )

   RETURN cRet


// --------------------------------------------------
// setovanje filtera nad tabelom customers
// --------------------------------------------------
STATIC FUNCTION set_f_kol( cCustDesc, cId )

   LOCAL cFilter := ""

   IF !Empty( cCustDesc )

      cCustDesc := AllTrim( cCustDesc )

      IF Right( cCustDesc ) == "$"

         // vrati uslov u normalno stanje
         cCustDesc := Left( cCustDesc, Len( cCustDesc ) - 1 )
         // vrati i id u normalno stanje
         cId := cCustDesc

         // pretrazi po dijelu naziva
         cFilter += _filter_quote( Upper( cCustDesc ) ) + " $ ALLTRIM(UPPER(cust_desc))"
      ELSE
         cFilter += "ALLTRIM(UPPER(cust_desc)) = " + _filter_quote( Upper( cCustDesc ) )
      ENDIF

   ENDIF

   IF !Empty( cFilter )
      SET FILTER to &cFilter
      GO TOP
   ENDIF

   RETURN .T.




STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   AAdd( aImeKol, { PadC( "ID/MC", 20 ), {|| sif_idmc( cust_id, .F., 20 ) }, "cust_id", {|| rnal_uvecaj_id( @wCust_id, "CUST_ID" ), .F. }, {|| .T. } } )
   AAdd( aImeKol, { PadC( "Naziv", 40 ), {|| PadR( cust_desc, 40 ) }, "cust_desc" } )
   AAdd( aImeKol, { PadC( "Adresa", 20 ), {|| PadR( cust_addr, 20 ) }, "cust_addr" } )
   AAdd( aImeKol, { PadC( "Telefon", 20 ), {|| PadR( cust_tel, 20 ) }, "cust_tel" } )
   AAdd( aImeKol, { "ID broj", {|| cust_ident }, "cust_ident", {|| set_cust_mc( @wMatch_code, @wCust_desc ) }, {|| rnal_chk_id( @wCust_id, "CUST_ID" ) } } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// --------------------------------------------------
// generisi match code za contakt...
// --------------------------------------------------
STATIC FUNCTION set_cust_mc( m_code, cust_desc )

   IF !Empty( m_code )
      RETURN .T.
   ENDIF

   m_code := Upper( PadR( cust_desc, 5 ) )
   m_code := PadR( m_code, 10 )

   RETURN .T.


// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION key_handler( Ch )

   LOCAL cTblFilter := dbFilter()
   LOCAL nRec := RecNo()
   LOCAL nRet := DE_CONT

   DO CASE
   CASE Upper( Chr( Ch ) ) == "K"

      // pregled kontakata
      s_contacts( nil, field->cust_id )
      nRet := DE_CONT

   CASE Upper( Chr( Ch ) ) == "O"

      // pregled objekata
      s_objects( nil, field->cust_id )
      nRet := DE_CONT

   CASE CH == K_F3

      // ispravka sifre
      nRet := rnal_wid_edit( "CUST_ID" )
   ENDCASE

   SELECT customs
   // set filter to cTblFilter
   GO ( nRec )

   RETURN nRet


// -------------------------------
// convert cust_id to string
// -------------------------------
FUNCTION custid_str( nId )
   RETURN Str( nId, 10 )



// -------------------------------
// get cust_id_desc by cust_id
// -------------------------------
FUNCTION g_cust_desc( nCust_id, lEmpty )

   LOCAL cCustDesc := "?????"
   LOCAL nTArea := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cCustDesc := ""
   ENDIF

   O_CUSTOMS
   SELECT customs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK custid_str( nCust_id )

   IF Found()
      IF !Empty( field->cust_desc )
         cCustDesc := AllTrim( field->cust_desc )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cCustDesc


// ----------------------------------------------------
// vraca ime kupca, ako je NN onda kontakt
// ----------------------------------------------------
FUNCTION _cust_cont( nCust_id, nCont_id )

   LOCAL xRet := ""
   LOCAL nTArea := Select()
   LOCAL cTmp := ""

   SELECT customs
   SEEK custid_str( nCust_id )

   IF Found()
      cTmp := AllTrim( field->cust_desc )
   ENDIF

   // ako je NN onda potrazi kontakt
   IF cTmp == "NN"

      SELECT contacts
      SEEK contid_str( nCont_id )

      IF Found()
         cTmp := AllTrim( field->cont_desc )
      ENDIF

   ENDIF

   xRet := cTmp

   SELECT ( nTArea )

   RETURN xRet
