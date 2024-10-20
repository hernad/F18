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

MEMVAR gModul, goModul


FUNCTION programski_modul()

   LOCAL cRunParam := get_f18_param( "run" )

   IF cRunParam <> "<undefined>"
      RETURN Upper( cRunParam )
   ENDIF

   RETURN gModul


FUNCTION start_f18_program_module( oApp, lSezone )

   LOCAL cImeDbf
   LOCAL nI

   gModul   := oApp:cName
   goModul  := oApp

   IF oApp:lTerminate
      RETURN .T.
   ENDIF

   oApp:set_module_gvars()
   open_main_window()
   pripremi_naslovni_ekran( oApp )
   crtaj_naslovni_ekran()

   RETURN .T.



FUNCTION mpar37( x, oApp )

   // proslijedjeni su parametri
   lp3 := oApp:cP3
   lp4 := oApp:cP4
   lp5 := oApp:cP5
   lp6 := oApp:cP6
   lp7 := oApp:cP7

   RETURN ( ( lp3 <> NIL .AND. Upper( lp3 ) == x ) .OR. ( lp4 <> NIL .AND. Upper( lp4 ) == x ) .OR. ;
      ( lp5 <> NIL .AND. Upper( lp5 ) == x ) .OR. ( lp6 <> NIL .AND. Upper( lp6 ) == x ) .OR. ;
      ( lp7 <> NIL .AND. Upper( lp7 ) == x ) )



FUNCTION mpar37cnt( oApp )

   LOCAL nCnt := 0

   IF oApp:cP3 <> nil
      ++nCnt
   ENDIF
   IF oApp:cP4 <> nil
      ++nCnt
   ENDIF
   IF oApp:cP5 <> nil
      ++nCnt
   ENDIF
   IF oApp:cP6 <> nil
      ++nCnt
   ENDIF
   IF oApp:cP7 <> nil
      ++nCnt
   ENDIF

   RETURN nCnt


FUNCTION mparstring( oApp )

   LOCAL cPars

   cPars := ""

   IF oApp:cP3 <> NIL
      cPars += "'" + oApp:cP3 + "'"
   ENDIF
   IF oApp:cP4 <> NIL
      IF !Empty( cPars ); cPars += ", ";ENDIF
      cPars += "'" + oApp:cP4 + "'"
   ENDIF
   IF oApp:cP5 <> NIL
      IF !Empty( cPars ); cPars += ", ";ENDIF
      cPars += "'" + oApp:cP5 + "'"
   ENDIF
   IF oApp:cP6 <> NIL
      IF !Empty( cPars ); cPars += ", ";ENDIF
      cPars += "'" + oApp:cP6 + "'"
   ENDIF
   IF oApp:cP7 <> NIL
      IF !Empty( cPars ); cPars += ", ";ENDIF
      cPars += "'" + oApp:cP7 + "'"
   ENDIF

   RETURN cPars
