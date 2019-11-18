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

// -----------------------------------
// pretraga po match_code polju
// -----------------------------------
FUNCTION m_code_src()

   LOCAL cSrch
   LOCAL cFilter

   IF !is_m_code()
      // ne postoji polje match_code
      RETURN 0
   ENDIF

   Box(, 7, 60 )
   PRIVATE GetList := {}
   cSrch := Space( 20 )
   set_cursor_on()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Match code:" GET cSrch VALID !Empty( cSrch )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Uslovi za pretragu:" COLOR f18_color_i()
   @ box_x_koord() + 4, box_y_koord() + 2 SAY " /ABC = m.code pocinje sa 'ABC'  ('ABC001')"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY " ABC/ = m.code zavrsava sa 'ABC' ('001ABC')"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY " #ABC = 'ABC' je unutar m.code  ('01ABC11')"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY " ABC  = m.code je striktno 'ABC'    ('ABC')"
   READ
   BoxC()

   // na esc 0
   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   cSrch := Trim( cSrch )
   // sredi filter
   g_mc_filter( @cFilter, cSrch )

   IF !Empty( cFilter )
      // set matchcode filter
      s_mc_filter( cFilter )
   ELSE
      SET FILTER TO
      GO TOP
   ENDIF

   RETURN 1


// ------------------------------------------
// provjerava da li postoji polje match_code
// ------------------------------------------
FUNCTION is_m_code()

   IF FieldPos( "MATCH_CODE" ) <> 0
      RETURN .T.
   ENDIF

   RETURN .F.


// ---------------------------------
// setuj match code filter
// ---------------------------------
STATIC FUNCTION s_mc_filter( cFilter )

   SET FILTER to &cFilter
   GO TOP

   RETURN

// -------------------------------------
// sredi filter po match_code za tabelu
// -------------------------------------
STATIC FUNCTION g_mc_filter( cFilt, cSrch )

   LOCAL cPom
   LOCAL nLeft

   cFilt := "TRIM(match_code)"
   cSrch := Trim( cSrch )

   DO CASE
   CASE Left( cSrch, 1 ) == "/"

      // match code pocinje
      cPom := StrTran( cSrch, "/", "" )
      cFilt += "=" + dbf_quote( cPom )

   CASE Left( cSrch, 1 ) == "#"

      // pretraga unutar match codea
      cPom := StrTran( cSrch, "#", "" )

      cFilt := dbf_quote( AllTrim( cPom ) )
      cFilt += "$ match_code"

   CASE Right( cSrch, 1 ) == "/"

      // match code zavrsava sa...
      cPom := StrTran( cSrch, "/", "" )
      nLeft := Len( AllTrim( cPom ) )

      cFilt := "RIGHT(ALLTRIM(match_code)," + AllTrim( Str( nLeft ) ) + ")"
      cFilt += "==" + dbf_quote( AllTrim( cPom ) )

   OTHERWISE

      // striktna pretraga
      cFilt += "==" + dbf_quote( cSrch )
   ENDCASE

   RETURN
