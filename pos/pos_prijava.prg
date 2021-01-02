/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION pos_prijava( nX, nY )

   LOCAL nChar
   LOCAL cKorSif
   LOCAL nSifLen
   LOCAL nPom
   LOCAL cLevel
   LOCAL cBrojac
   LOCAL nPrevKorRec

   CLOSE ALL
   nSifLen := 6

   DO WHILE .T.

      SetPos ( nX + 4, nY + 15 )
      cKorSif := Upper( pos_get_lozinka( nSifLen ) )
#ifdef F18_DEBUG
      ?E "pos_prijava", cKorSif
#endif
      IF Empty( cKorSif )
         MsgBeep( "ERR unijeti lozinku" )
         LOOP
      ENDIF

      IF ( AllTrim( cKorSif ) == "ADMIN" )
         gIdRadnik := "XXXX"
         gKorIme   := "bring.out servis / ADMIN mode"
         gSTRAD  := "A"
         cLevel := L_SYSTEM
         EXIT
      ENDIF

      pos_spec_sifre( cKorSif ) // obradi specijalne sifre
      IF ( goModul:lTerminate )
         RETURN "X"
      ENDIF

      set_cursor_off()
      SetColor ( f18_color_normal() )
      IF pos_set_user( cKorSif, nSifLen, @cLevel ) == 0
         LOOP
      ELSE
         EXIT
      ENDIF

   ENDDO

   pos_21_neobradjeni_lista_stariji()
   
   pos_status_traka()
   CLOSE ALL

   RETURN cLevel



// obrada specijalnih sifara...
FUNCTION pos_spec_sifre( cSifra )

   IF Trim( Upper( cSifra ) ) $ "X"
      goModul:lTerminate := .T.
   ELSEIF Trim( Upper( cSifra ) ) = "M"
      goModul:quit()
   ENDIF

   RETURN .T.


FUNCTION pos_status_traka()

   LOCAL nX := f18_max_rows() - 1
   LOCAL nY := 0

   @ 1, nY + 1 SAY8 "RADI:" + PadR( LTrim( gKorIme ), 31 ) +  " DATUM:" + DToC( danasnji_datum() ) + " PROD-PM:" + pos_prodavnica_str() + "/" + pos_pm()
   @ nX - 1, nY + 1 SAY PadC ( Razrijedi ( gKorIme ), f18_max_cols() - 2 ) COLOR f18_color_invert()


   RETURN .T.


FUNCTION pos_set_user( cKorSif, nSifLen, cLevel )

   cKorSif := CryptSC( PadR( Upper( Trim( cKorSif ) ), nSifLen ) )

   IF find_pos_osob_by_korsif( cKorSif )
      gIdRadnik := field->ID
      gKorIme   := field->Naz
      gSTRAD  := AllTrim ( field->STATUS )
      IF select_o_pos_strad( OSOB->STATUS )
         cLevel := field->prioritet
      ELSE
         cLevel := L_PRODAVAC
         gSTRAD := "K"
      ENDIF
      RETURN 1
   ELSE
      MsgBeep ( "Unijeta je nepostojeća lozinka !" )
      RETURN 0
   ENDIF

   RETURN 0


FUNCTION pos_popust_prikaz()

   // RETURN iif( gPopVar = "A", "NENAPLACENO:", "     POPUST:" )

   RETURN  "     POPUST:"
