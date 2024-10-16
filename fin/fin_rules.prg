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

FUNCTION get_rule_field_cols_fin()

   LOCAL aKols := {}

   // rule_c1 = 1
   // rule_c2 = 5
   // rule_c3 = 10
   // rule_c4 = 10
   // rule_c5 = 50
   // rule_c6 = 50
   // rule_c7 = 100

   AAdd( aKols, { "tip nal", {|| PadR( rule_c3, 10 ) }, "rule_c3", {|| .T. }, {|| .T. } } )
   AAdd( aKols, { "partner", {|| PadR( rule_c5, 20 ) }, "rule_c5", {|| .T. }, {|| .T. } } )
   AAdd( aKols, { "konto", {|| PadR( rule_c6, 20 ) }, "rule_c6", {|| .T. }, {|| .T. } } )
   AAdd( aKols, { "d_p", {|| rule_c1 }, "rule_c1", {|| .T. }, {|| .T. } } )

   RETURN aKols


FUNCTION get_rule_field_block_fin()

   LOCAL bBlock := {|| ed_rule_bl() }

   RETURN bBlock

STATIC FUNCTION ed_rule_bl()
   RETURN DE_CONT



STATIC FUNCTION error_validate( nLevel )

   LOCAL lRet := .F.

   IF nLevel <= 3

      lRet := .T.

   ELSEIF nLevel == 4

      IF Pitanje(, "Zanemariti ovo pravilo (D/N) ?", "N" ) == "D"

         lRet := .T.

      ENDIF

   ENDIF

   RETURN lRet




FUNCTION fin_pravilo_konto()

   LOCAL nErrLevel := 0

   nErrLevel := ispitaj_pravilo_konto()

   RETURN error_validate( nErrLevel )



FUNCTION ispitaj_pravilo_konto()

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "KNJIZ_KONTO"
   LOCAL cMod := programski_modul()

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "FINKNJ1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj )

      // B4 ili B* ili *
      cNalog := AllTrim( fmkrules->rule_c3 )
      // 132 ili 132;1333;2311;....
      cKtoList := AllTrim( fmkrules->rule_c6 )
      // nivo pravila
      nErrLevel := fmkrules->rule_level

      // ima li konta ???
      IF nErrLevel <> 0 .AND. ;
            uslov_nalog_zadovoljen( _idvn, cNalog ) .AND. ;
            uslov_konto_zadovoljen( _idkonto, cKtoList )

         nReturn := nErrLevel

         sh_rule_err( fmkrules->rule_ermsg, nErrLevel )

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn



STATIC FUNCTION uslov_nalog_zadovoljen( cFinNalog, cRuleNalog )

   LOCAL lRet := .F.

   IF cRuleNalog == "*"

      lRet := .T.

   ELSEIF Left( cRuleNalog, 1 ) <> "*" .AND. "*" $ cRuleNalog

      IF Left( cRuleNalog, 1 ) == Left( cFinNalog, 1 )
         lRet := .T.
      ENDIF

   ELSEIF cRuleNalog == cFinNalog

      lRet := .T.

   ENDIF

   RETURN lRet




FUNCTION fin_pravilo_partner()

   LOCAL nErrLevel := 0

   nErrLevel := ispitaj_pravilo_partner()

   RETURN error_validate( nErrLevel )



FUNCTION ispitaj_pravilo_partner()

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "KNJIZ_PARTNER_KONTO"
   LOCAL cMod := programski_modul()

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog
   LOCAL cPartn

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "FINKNJ1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj )

      cNalog := AllTrim( fmkrules->rule_c3 )

      cKtoList := AllTrim( fmkrules->rule_c6 )

      cPartn := AllTrim( fmkrules->rule_c5 )

      nErrLevel := fmkrules->rule_level

      IF nErrLevel <> 0 .AND. ;
            uslov_nalog_zadovoljen( _idvn, cNalog ) .AND. ;
            uslov_konto_zadovoljen( _idkonto, cKtoList ) .AND. ;
            uslov_partner_zadovoljen( _idpartner, cPartn ) == .F.

         nReturn := nErrLevel

         sh_rule_err( fmkrules->rule_ermsg, nErrLevel )

         EXIT

      ENDIF


      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn



FUNCTION fin_pravilo_dug_pot()

   LOCAL nErrLevel := 0

   nErrLevel := ispitaj_pravilo_dug_pot()

   RETURN error_validate( nErrLevel )



FUNCTION ispitaj_pravilo_dug_pot()

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "KNJIZ_DP_PARTNER_KONTO"
   LOCAL cMod := programski_modul()

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cDugPot
   LOCAL cPartn
   LOCAL cNalog

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "FINKNJ1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj )

      // B4 ili B* ili *
      cNalog := AllTrim( fmkrules->rule_c3 )

      // 132 ili 132;1333;2311;....
      cKtoList := AllTrim( fmkrules->rule_c6 )

      // SC_SV1 - sifra partnera
      cPartn := AllTrim( fmkrules->rule_c5 )

      // duguje ili potrazuje (1 ili 2)
      cDugPot := AllTrim( fmkrules->rule_c1 )

      // nivo pravila
      nErrLevel := fmkrules->rule_level

      // ima li konta ???
      IF nErrLevel <> 0 .AND. ;
            uslov_nalog_zadovoljen( _idvn, cNalog ) .AND. ;
            uslov_konto_zadovoljen( _idkonto, cKtoList ) .AND. ;
            ( uslov_partner_zadovoljen( _idpartner, cPartn ) == .F. .OR. ;
               uslov_dug_pot_zadovoljen( _d_p, cDugPot ) == .F. )

         nReturn := nErrLevel

         sh_rule_err( fmkrules->rule_ermsg, nErrLevel )

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn



STATIC FUNCTION uslov_partner_zadovoljen( cNalPartn, cRulePartn, lEmpty )

   LOCAL lRet := .F.

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   cNalPartn := AllTrim( cNalPartn )

   IF lEmpty == .T. .AND. Empty( cRulePartn )

      lRet := .T.

   ELSEIF cRulePartn == "*"

      lRet := .T.

   ELSEIF cRulePartn == "#KUPAC#"

      lRet := is_kupac( cNalPartn )

   ELSEIF cRulePartn == "#DOBAVLJAC#"

      lRet := is_dobavljac( cNalPartn )

   ELSEIF cRulePartn == "#BANKA#"

      lRet := is_banka( cNalPartn )

   ELSEIF cRulePartn == "#RADNIK#"

      lRet := is_radnik( cNalPartn )

   ELSEIF cRulePartn == cNalPartn

      lRet := .T.

   ENDIF

   RETURN lRet



STATIC FUNCTION uslov_konto_zadovoljen( cNalKonto, cRuleKtoList, lEmpty )

   LOCAL lRet := .F.

   cNalKonto := AllTrim( cNalKonto )

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T. .AND. Empty( cRuleKtoList )

      lRet := .T.

   ELSEIF cRuleKtoList == "*"

      lRet := .T.

   ELSEIF cNalKonto $ cRuleKtoList

      lRet := .T.

   ENDIF

   RETURN lRet



STATIC FUNCTION uslov_dug_pot_zadovoljen( cNalDP, cRuleDP, lEmpty )

   LOCAL lRet := .F.

   cNalDP := AllTrim( cNalDP )

   IF lEmpty == nil
      lEmpty := .F.
   ENDIF

   IF lEmpty == .T. .AND. Empty( cRuleDP )

      lRet := .T.

   ELSEIF cNalDP == cRuleDP

      lRet := .T.

   ENDIF

   RETURN lRet



FUNCTION fin_pravilo_broj_veze()

   LOCAL nErrLevel := 0

   nErrLevel := ispitaj_pravilo_broj_veze()

   RETURN error_validate( nErrLevel )



FUNCTION ispitaj_pravilo_broj_veze()

   LOCAL nReturn := 0
   LOCAL nTArea := Select()

   LOCAL cObj := "KNJIZ_BROJ_VEZE"
   LOCAL cMod := programski_modul()

   LOCAL nErrLevel
   LOCAL cKtoList
   LOCAL cNalog
   LOCAL cPartn
   LOCAL cDugPot

   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "FINKNJ1"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj )

      // B4 ili B* ili *
      cNalog := AllTrim( fmkrules->rule_c3 )

      // 132 ili 132;1333;2311;....
      cKtoList := AllTrim( fmkrules->rule_c6 )

      // partner
      cPartn := AllTrim( fmkrules->rule_c5 )

      // duguje / potrazuje
      cDugPot := AllTrim( fmkrules->rule_c1 )

      // nivo pravila
      nErrLevel := fmkrules->rule_level

      // ima li konto/nalog/opis ???
      IF nErrLevel <> 0 .AND. ;
            uslov_nalog_zadovoljen( _idvn, cNalog ) .AND. ;
            uslov_konto_zadovoljen( _idkonto, cKtoList, .T. ) .AND. ;
            uslov_partner_zadovoljen( _idpartner, cPartn, .T. ) .AND. ;
            uslov_dug_pot_zadovoljen( _d_p, cDugPot, .T. ) .AND. ;
            Empty( _brdok )

         nReturn := nErrLevel

         sh_rule_err( fmkrules->rule_ermsg, nErrLevel )

         EXIT

      ENDIF

      SKIP

   ENDDO

   SELECT ( nTArea )

   RETURN nReturn
