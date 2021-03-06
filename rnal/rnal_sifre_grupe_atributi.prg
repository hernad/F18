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


STATIC _e_gr_id
STATIC __wo_id

// -------------------------------------------------------
// otvara sifrarnik atributa grupa
// -------------------------------------------------------
FUNCTION s_e_gr_att( cId, nGr_id, cE_gr_at_desc, lwoID, dx, dy )

   LOCAL nTArea
   LOCAL cHeader
   PRIVATE ImeKol
   PRIVATE Kol
   PRIVATE GetList := {}

   IF lwoID == nil
      lwoID := .F.
   ENDIF

   __wo_id := lwoID

   nTArea := Select()

   O_E_GR_ATT

   cHeader := "Elementi - grupe atributi /  'V' - pr.vrijednosti / required '*'"

   IF nGr_id == nil
      nGr_id := -1
   ENDIF

   IF cE_gr_at_desc == nil
      cE_gr_at_desc := ""
   ENDIF

   _e_gr_id := nGr_id

   SELECT e_gr_att
   SET ORDER TO TAG "1"

   set_a_kol( @ImeKol, @Kol )
   gr_filter( nGr_id, cE_gr_at_desc )

   SELECT e_gr_att
   GO TOP

   cRet := p_sifra( F_E_GR_ATT, 1, f18_max_rows() -10, f18_max_cols() -5, cHeader, @cId, dx, dy, {|| key_handler() } )

   IF ValType( cE_gr_at_desc ) == "N"
      cE_gr_at_desc := Str( cE_gr_at_desc, 10 )
   ENDIF

   IF nGr_id > 0 .OR. cE_gr_at_desc <> ""
      SET FILTER TO
   ENDIF

   SELECT ( nTArea )

   IF LastKey() == K_ESC
      cRet := 0
   ENDIF

   RETURN cRet



// ---------------------------------------------------
// gr_id filter na e_gr_att sifrarniku
// nE_gr_id - grupa id
// ---------------------------------------------------
STATIC FUNCTION gr_filter( nE_gr_id, cE_gr_at_desc )

   LOCAL cFilter := ""

   IF nE_gr_id > 0
      cFilter += 'e_gr_id == ' + e_gr_id_str( nE_gr_id )
   ENDIF

   IF !Empty( cE_gr_at_desc )

      IF !Empty( cFilter )
         cFilter += ' .and. '
      ENDIF

      cFilter += 'UPPER(e_gr_at_de) = ' + dbf_quote( Upper( AllTrim( cE_gr_at_desc ) ) )
   ENDIF

   IF !Empty( cFilter )
      SET FILTER to &cFilter
      GO TOP
   ENDIF

   RETURN


// -----------------------------------------
// setovanje kolona tabele
// -----------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol )

   aKol := {}
   aImeKol := {}

   IF __wo_id == .F.
      AAdd( aImeKol, { PadC( "ID/MC", 10 ), {|| sif_idmc( e_gr_at_id ) }, "e_gr_at_id", {|| rnal_uvecaj_id( @wE_gr_at_id, "E_GR_AT_ID" ), .F. }, {|| .T. } } )
   ENDIF

   AAdd( aImeKol, { PadC( "Elem.grupa", 10 ), {|| PadR( g_e_gr_desc( e_gr_id ), 10 ) }, "e_gr_id", {|| set_gr_id( @wE_gr_id ) }, {|| s_e_groups( @we_gr_id ), show_it( g_e_gr_desc( we_gr_id ) ) } } )

   AAdd( aImeKol, { PadC( "Opis", 20 ), {|| PadR( e_gr_at_de, 20 ) }, "e_gr_at_de" } )

   AAdd( aImeKol, { PadC( "Joker", 20 ), {|| PadR( e_gr_at_jo, 20 ) }, "e_gr_at_jo" } )

   AAdd( aImeKol, { PadC( "Neoph", 5 ), {|| e_gr_at_re }, "e_gr_at_re", {|| .T. }, {|| .T. } } )

   AAdd( aImeKol, { PadC( "u art.naz ( /*)", 15 ), {|| PadR( in_art_des, 15 ) }, "in_art_des" } )

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN


// ---------------------------------------------------
// setuje polje e_gr_id pri unosu automatski
// ---------------------------------------------------
STATIC FUNCTION set_gr_id( nE_gr_id )

   IF _e_gr_id > 0
      nE_gr_id := _e_gr_id
      RETURN .F.
   ELSE
      RETURN .T.
   ENDIF

   RETURN


// ------------------------------------
// setuje polje required
// ------------------------------------
STATIC FUNCTION set_required()

   LOCAL _rec

   _rec := dbf_get_rec()

   IF _rec[ "e_gr_at_re" ] == "*"
      _rec[ "e_gr_at_re" ] := " "
   ELSE
      _rec[ "e_gr_at_re" ] := "*"
   ENDIF

   dbf_update_rec( _rec )

   RETURN



// -----------------------------------------
// key handler funkcija
// -----------------------------------------
STATIC FUNCTION key_handler()

   LOCAL nE_gr_at_id := field->e_gr_at_id
   LOCAL nTRec := RecNo()

   DO CASE

   CASE Upper( Chr( Ch ) ) == "V"

      s_e_gr_val( nil, nE_gr_at_id )
      GO ( nTRec )
      RETURN DE_CONT

   CASE Upper( Chr( Ch ) ) == "R"

      Beep( 1 )
      set_required()

      RETURN DE_REFRESH

   CASE Ch == K_CTRL_N .OR. Ch == K_F4

      __wo_id := .F.
      set_a_kol( @ImeKol, @Kol )

      RETURN DE_CONT
   ENDCASE

   RETURN DE_CONT


// -------------------------------
// convert e_gr_at_id to string
// -------------------------------
FUNCTION e_gr_at_str( nId )
   RETURN Str( nId, 10 )


// --------------------------------------------
// vraca djoker za pojedini atribut
// --------------------------------------------
FUNCTION g_gr_att_joker( nE_gr_att )

   LOCAL cEGrAttJoker := ""
   LOCAL nTArea := Select()

   O_E_GR_ATT
   SELECT e_gr_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK e_gr_at_str( nE_gr_att )

   IF Found()
      IF !Empty( field->e_gr_at_jo )
         cEGrAttJoker := AllTrim( field->e_gr_at_jo )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cEGrAttJoker


// --------------------------------------------------
// get e_gr_at_desc by e_gr_att_id
// --------------------------------------------------
FUNCTION g_gr_at_desc( nE_gr_att_id, lShowRequired, lEmpty )

   LOCAL cEGrAttDesc := "?????"
   LOCAL nTArea := Select()

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T.
      cEGrAttDesc := ""
   ENDIF

   IF lShowRequired == nil
      lShowRequired := .F.
   ENDIF

   O_E_GR_ATT
   SELECT e_gr_att
   SET ORDER TO TAG "1"
   GO TOP
   SEEK e_gr_at_str( nE_gr_att_id )

   IF Found()
      IF !Empty( field->e_gr_at_de )

         cEGrAttDesc := ""

         IF lShowRequired == .T.

            IF !Empty( field->e_gr_at_re )

               cEGrAttDesc += "("
               cEGrAttDesc += AllTrim( field->e_gr_at_re )
               cEGrAttDesc += ")"

            ENDIF

         ENDIF

         cEGrAttDesc += " "
         cEGrAttDesc += AllTrim( field->e_gr_at_de )
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN cEGrAttDesc


// ------------------------------------------
// gr_att in art_desc ???
// ------------------------------------------
FUNCTION gr_att_in_desc( nE_gr_att )

   LOCAL lRet := .F.
   LOCAL nTArea := Select()

   SELECT e_gr_att
   SET ORDER TO TAG "1"
   SEEK e_gr_at_str( nE_gr_att )

   IF Found()
      IF field->in_art_des == "*"
         lRet := .T.
      ENDIF
   ENDIF

   SELECT ( nTArea )

   RETURN lRet



// ------------------------------------------------------
// napuni matricu aAtt sa atributima grupa
// ------------------------------------------------------
FUNCTION a_gr_attibs( aAtt, nE_Gr_id )

   LOCAL nTArea := Select()

   SELECT e_gr_att
   SET FILTER TO "e_gr_id == " + e_gr_id_str( nE_gr_id )
   GO TOP

   DO WHILE !Eof() .AND. field->e_gr_id == nE_gr_id
      AAdd( aAtt, { field->e_gr_at_id, AllTrim( field->e_gr_at_de ), 0, 0, 0 } )
      SKIP
   ENDDO

   SET FILTER TO

   SELECT ( nTArea )

   RETURN
