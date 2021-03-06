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

STATIC __LEV_MIN
STATIC __LEV_MAX

// ------------------------------------------------
// vraca vrijednost za seek polja rule_obj
// ------------------------------------------------
FUNCTION get_rule_field_obj( cSeek )
   RETURN PadR( cSeek, 30 )



FUNCTION get_rule_field_mod( cSeek )
   RETURN PadR( cSeek, 10 )


FUNCTION get_rule_field_c1( cSeek )
   RETURN PadR( cSeek, 1 )


FUNCTION get_rule_field_c2( cSeek )
   RETURN PadR( cSeek, 5 )


FUNCTION get_rule_field_c3( cSeek )
   RETURN PadR( cSeek, 10 )


FUNCTION get_rule_field_c4( cSeek )
   RETURN PadR( cSeek, 10 )


FUNCTION get_rule_field_c5( cSeek )
   RETURN PadR( cSeek, 50 )



FUNCTION get_rule_field_c6( cSeek )
   RETURN PadR( cSeek, 50 )



FUNCTION get_rule_field_c7( cSeek )
   RETURN PadR( cSeek, 100 )



// -----------------------------------------------
// otvaranje sifrarnika pravila "RULES"
// cID - id
// dx - koordinata x
// dy - koordinata y
// aSpecKol - specificne kolone // modul defined
// bRules - rules block for object browse
// -----------------------------------------------
FUNCTION p_rules( cId, dx, dy, aSpecKol, bRBlock )

   LOCAL cModName
   LOCAL nSelect := Select()
   LOCAL nRet
   LOCAL cHeader := ""
   PRIVATE Kol
   PRIVATE ImeKol

   __LEV_MIN := 0
   __LEV_MAX := 5

   O_RULES
   SET ORDER TO TAG "2"

   IF aSpecKol == nil
      aSpecKol := {}
   ENDIF

   cHeader += " "
   cHeader += AllTrim( programski_modul() )
   cHeader += " "
   cHeader += "pravila : RULES "

   cModName := programski_modul()
   cModName := PadR( cModName, 10 )

   // sredi kolone
   set_a_kol( @ImeKol, @Kol, aSpecKol )
   // postavi filter za modul
   set_mod_filt()

   GO TOP

   nRet := p_sifra( F_RULES, 1, 16, 70, cHeader, @cId, dx, dy, bRBlock )

   SELECT ( nSelect )

   RETURN nRet


// ---------------------------------------
// postavlja filter za modul
// ---------------------------------------
STATIC FUNCTION set_mod_filt()

   LOCAL cFilt := ""

   cFilt := "modul_name = " + dbf_quote( PadR( programski_modul(), 10 ) )

   SET FILTER to &cFilt

   RETURN .T.

// --------------------------------------------------------
// setovanje kolona tabele "FMKRULES"
// --------------------------------------------------------
STATIC FUNCTION set_a_kol( aImeKol, aKol, aSpecKol )

   LOCAL i
   LOCAL nSpec

   aImeKol := {}
   aKol := {}

   // standardne kolone tabele

   AAdd( aImeKol, { "ID", {|| rule_id }, "rule_id", ;
      {|| i_rule_id( @wrule_id ), .F. }, {|| .T. } } )
   AAdd( aImeKol, { "Modul", {|| modul_name }, "modul_name", {|| _w_mod_name( @wmodul_name ), .F. }  } )
   AAdd( aImeKol, { "Objekat", {|| rule_obj }, "rule_obj"  } )
   AAdd( aImeKol, { "Podbr.", {|| rule_no }, "rule_no", ;
      {|| i_rule_no( @wrule_no, wrule_obj ), .F. }, {|| .T. }, , "99999" } )
   AAdd( aImeKol, { "Naziv", {|| PadR( rule_name, 20 ) + ".." }, ;
      "rule_name" } )
   AAdd( aImeKol, { "Err.msg", {|| PadR( rule_ermsg, 30 ) + ".." }, ;
      "rule_ermsg" } )
   AAdd( aImeKol, { "Nivo", {|| rule_level }, ;
      "rule_level", {|| .T. }, {|| _w_level( wrule_level ) } } )

   IF Len( aSpecKol ) == 0

      // dodajem po defaultu specificne kolone

      // karakterne
      AAdd( aImeKol, { "pr.k1", {|| rule_c1 }, "rule_c1" } )
      AAdd( aImeKol, { "pr.k2", {|| rule_c2 }, "rule_c2" } )
      AAdd( aImeKol, { "pr.k3", {|| rule_c3 }, "rule_c3" } )
      AAdd( aImeKol, { "pr.k4", {|| rule_c4 }, "rule_c4" } )
      AAdd( aImeKol, { "pr.k5", {|| rule_c5 }, "rule_c5" } )
      AAdd( aImeKol, { "pr.k6", {|| rule_c6 }, "rule_c6" } )
      AAdd( aImeKol, { "pr.k7", {|| rule_c7 }, "rule_c7" } )

      // numericke
      AAdd( aImeKol, { "pr.n1", {|| rule_n1 }, "rule_n1" } )
      AAdd( aImeKol, { "pr.n2", {|| rule_n2 }, "rule_n2" } )

      // date
      AAdd( aImeKol, { "pr.d1", {|| rule_d1 }, "rule_d1" } )
      AAdd( aImeKol, { "pr.d2", {|| rule_d2 }, "rule_d2" } )


   ELSE

      // dodajem na osnovu matrice aSpecKol
      FOR nSpec := 1 TO Len( aSpecKol )

         AAdd( aImeKol, { aSpecKol[ nSpec, 1 ], aSpecKol[ nSpec, 2 ], ;
            aSpecKol[ nSpec, 3 ], aSpecKol[ nSpec, 4 ], ;
            aSpecKol[ nSpec, 5 ] } )

      NEXT

   ENDIF

   FOR i := 1 TO Len( aImeKol )
      AAdd( aKol, i )
   NEXT

   RETURN .T.


// ----------------------------------------------
// when naziv
// ----------------------------------------------
STATIC FUNCTION _w_mod_name( cName )

   cName := PadR( programski_modul(), 10 )

   RETURN .T.


// ----------------------------------------
// when levela
// ----------------------------------------
STATIC FUNCTION _w_level( nLev )

   LOCAL lRet := .F.

   IF nLev >= __LEV_MIN .AND. nLev <= __LEV_MAX
      lRet := .T.
   ENDIF

   IF lRet == .F.
      MsgBeep( "Nivo greske mora biti u rangu od " + ;
         AllTrim( Str( __LEV_MIN ) ) + " do " + ;
         AllTrim( Str( __LEV_MAX ) ) )
   ENDIF

   RETURN lRet


// -----------------------------------------------
// uvecaj automatski broj pravila
// -----------------------------------------------
FUNCTION i_rule_no( nNo, cRuleObj )

   LOCAL lRet := .T.

   IF ( ( Ch == K_CTRL_N ) .OR. ( Ch == K_F4 ) )

      IF ( LastKey() == K_ESC )
         RETURN lRet := .F.
      ENDIF

      nNo := _last_no( cRuleObj )

      AEval( GetList, {| o| o:display() } )

   ENDIF

   RETURN lRet



// -----------------------------------------------
// uvecaj automatski id broj pravila
// -----------------------------------------------
FUNCTION i_rule_id( nID )

   LOCAL lRet := .T.

   IF ( ( Ch == K_CTRL_N ) .OR. ( Ch == K_F4 ) )

      IF ( LastKey() == K_ESC )
         RETURN lRet := .F.
      ENDIF

      nID := _last_id()

      AEval( GetList, {| o| o:display() } )

   ENDIF

   RETURN lRet




// --------------------------------------------
// vraca posljednji zapis iz tabele
// --------------------------------------------
FUNCTION _last_no( cRuleObj )

   LOCAL nNo := 0
   LOCAL nSelect := Select()
   LOCAL nRec := RecNo()
   LOCAL cModul := PadR( programski_modul(), 10 )

   cRuleObj := PadR( cRuleObj, 30 )

   SELECT fmkrules
   SET ORDER TO TAG "2"
   GO TOP
   SEEK cModul + cRuleObj

   DO WHILE !Eof() .AND. field->modul_name == cModul ;
         .AND. field->rule_obj == cRuleObj

      nNo := field->rule_no

      SKIP
   ENDDO

   nNo += 1

   SELECT ( nSelect )
   GO ( nRec )

   RETURN nNo



// --------------------------------------------
// vraca posljednji id iz tabele
// --------------------------------------------
FUNCTION _last_id()

   LOCAL nNo := 0
   LOCAL nSelect := Select()
   LOCAL nRec := RecNo()
   LOCAL cTbFilter

   SELECT fmkrules
   cTbFilter := dbFilter()
   SET FILTER TO

   SET ORDER TO TAG "1"
   GO BOTTOM

   nNo := field->rule_id + 1

   SET ORDER TO TAG "2"
   SET FILTER to &cTbFilter

   SELECT ( nSelect )
   GO ( nRec )

   RETURN nNo



// -----------------------------------------------------
// prikazuje poruku o gresci
// -----------------------------------------------------
FUNCTION sh_rule_err( cMsg, nLevel )

   LOCAL aMsg
   LOCAL cTxt := ""
   LOCAL i

   IF nLevel == nil
      nLevel := 0
   ENDIF

   aMsg := SjeciStr( AllTrim( cMsg ), 70 )

   cTxt := ""

   FOR i := 1 TO Len( aMsg )

      cTxt += aMsg[ i ] + "#"

   NEXT

   cTxt := _info_level( nLevel ) + cTxt

   MsgBeep( cTxt )

   RETURN


// -----------------------------------------
// informacija o nivou
// -----------------------------------------
STATIC FUNCTION _info_level( nLev )

   cRet := ""

   DO CASE
   CASE nLev == 1 .OR. nLev == 2 .OR. nLev == 3
      cRet := "! OBAVJESTENJE !##"
   CASE nLev == 4
      cRet := "! UPOZORENJE !##"
   CASE nLev == 5
      cRet := "!!! VAZNO UPOZORENJE !!!##"

   ENDCASE

   RETURN cRet
