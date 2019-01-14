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
#include "f18_color.ch"

// nOldCursor koriste browse funkcije
MEMVAR gNaslov, h, nOldCursor

FUNCTION pripremi_naslovni_ekran( oApp )

   set_global_screen_vars()

   PUBLIC gNaslov  := "F18: " + oApp:cName + " (" + f18_dev_period() + ")  Ver: " + f18_ver() + "-" + f18_varijanta_builtin() + " " + f18_ver_date()

   AFill( h, "" )
   nOldCursor := iif( ReadInsert(), 2, 1 )


#ifdef __PLATFORM__DARWIN
   SET KEY K_F12 TO  swap_insert_over_stanje()
#else
   SET KEY K_INS TO  swap_insert_over_stanje()
#endif

   RETURN NIL



FUNCTION crtaj_naslovni_ekran()

   LOCAL cColorNormal
   LOCAL nMaxCols := f18_max_cols()
   LOCAL nMaxRows := f18_max_rows()

   cColorNormal := f18_color_normal( .T. )
   SetColor( cColorNormal )


   CLEAR

   // start zaglavlje
   @ 0, 2 SAY '<ESC> Izlaz' COLOR f18_color_invert()
   @ 0, Col() + 2 SAY Date() COLOR f18_color_invert()

   @ nMaxRows - 1, nMaxCols - 16  SAY f18_harbour()

   DispBox( 2, 0, 4, nMaxCols - 1, B_DOUBLE + BOX_CHAR_BACKGROUND_HEAD, cColorNormal )

   @ 3, 1 SAY PadC( gNaslov, nMaxCols - 8 ) COLOR cColorNormal

   show_podaci_organizacija()

   @ 4, 5 SAY ""
   show_dbf_prefix()
   show_insert_over_stanje()

   @ 0, f18_max_cols() - 14 SAY "bring.out" COLOR cColorNormal

   cColorNormal := f18_color_normal( .F. )
   SetColor( cColorNormal )

   // povrsina iza menija
   DispBox( 5, 0, nMaxRows - 1, nMaxCols - 1, B_DOUBLE + BOX_CHAR_BACKGROUND, f18_color_invert()  )

   IF !in_tekuca_godina()
      ispisi_velikim_slovima( AllTrim( Str( tekuca_sezona() ) ), f18_max_rows() - 12, f18_max_cols() - 5, ;
         iif( in_tekuca_godina(), F18_COLOR_NAGLASENO, F18_COLOR_NAGLASENO_STARA_SEZONA ) )
   ENDIF

   RETURN .T.


STATIC FUNCTION show_podaci_organizacija()

   @ 0, 15 SAY AllTrim( tip_organizacije() ) + " :"
   @ Row(), Col() + 1  SAY AllTrim( self_organizacija_naziv() ) + ", " + f18_baza_server_host() ;
      COLOR iif( in_tekuca_godina(), F18_COLOR_NAGLASENO, F18_COLOR_NAGLASENO_STARA_SEZONA )

   RETURN .T.


FUNCTION swap_insert_over_stanje()
   RETURN show_insert_over_stanje( .T. )


FUNCTION show_dbf_prefix()

   LOCAL cPrefix

   IF !Empty( my_dbf_prefix() )
      cPrefix := "[" + StrTran( my_dbf_prefix(), "/", "" ) + "]"
      @ 0, f18_max_cols() - 4 SAY cPrefix COLOR F18_COLOR_NAGLASENO
   ENDIF

   RETURN .T.


FUNCTION show_insert_over_stanje( lSWap )

   LOCAL nX
   LOCAL nY
   LOCAL lNewState := ReadInsert()
   LOCAL cState

   hb_default( @lSwap, .F. )
   nX := Row()
   nY := Col()

   IF lSwap
      lNewState := !ReadInsert()
      ReadInsert( lNewState )
   ENDIF

   IF ReadInsert()
      cState := '< INS  >'
   ELSE
      cState := '< OVER >'
   ENDIF

   @ 0, f18_max_cols() - 23 SAY cState COLOR f18_color_invert( .T. )

   SetPos( nX, nY )

   RETURN .T.



FUNCTION set_global_screen_vars()

   //PUBLIC box_x_koord() := 0
   //PUBLIC box_y_koord() := 0
   PUBLIC m_x := 0
   PUBLIC m_y := 0

   RETURN .T.


FUNCTION f18_ispisi_status_log_levela()

   @ f18_max_rows(), 1 SAY "log level: " + AllTrim( Str( log_level() ) )

   RETURN .T.


FUNCTION f18_ispisi_status_podrucja( nPosX )

   LOCAL _database := my_server_params()[ "database" ]
   LOCAL cColor := F18_COLOR_STATUS
   LOCAL cTxt := ""
   LOCAL cTekucaGodina := AllTrim( Str( Year( Date() ) ) )
   LOCAL lShow := .F.

   IF !( cTekucaGodina $ _database )
      lShow := .T.
      cTxt := "! SEZONSKO PODRUČJE: " + Right( AllTrim( _database ), 4 ) + " !"
      cColor := F18_COLOR_POSEBAN_STATUS
   ENDIF

   IF lShow
      @ nPosX, f18_max_cols() - 35 SAY8 PadC( cTxt, 30 ) COLOR cColor
   ENDIF

   RETURN .T.



FUNCTION f18_ispisi_status_modula()

   LOCAL _module := Lower( goModul:cName )
   LOCAL _in_use := f18_use_module( iif( _module == "pos", "pos", _module ) )
   LOCAL cColor := F18_COLOR_STATUS

   IF !_in_use
      cColor := F18_COLOR_POSEBAN_STATUS
      @ f18_max_rows() -1, 25 SAY "!" COLOR cColor
   ELSE
      @ f18_max_rows() -1, 25 SAY " " COLOR cColor
   ENDIF

   RETURN .T.
