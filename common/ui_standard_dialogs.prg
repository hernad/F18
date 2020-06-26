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


THREAD STATIC cLDirekt := "0"

/*
 *  brief Otvara box sa zadatim pitanjem na koje treba odgovoriti sa D,N,..
 *  param cId
 *  param cPitanje       - Pitanje
 *  param cOdgDefault    - Odgovor koji ce biti ponudjen na boxu
 *  cMogOdg              - Moguci odgovori
 */

FUNCTION Pitanje( cId, cPitanje, cOdgDefault, cMogOdg, cHeader )

   LOCAL cPom
   LOCAL cOdgovor
   LOCAL lConfirmEnter := Set( _SET_CONFIRM )
   LOCAL GetList := {}

   IF cMogOdg == NIL
      cMogOdg := "YDNL"
   ENDIF


   cPom := Set( _SET_DEVICE )
   SET DEVICE TO SCREEN

   IF cOdgDefault == NIL .OR. !( cOdgDefault $ cMogOdg )
      cOdgovor := " "
   ELSE
      cOdgovor := cOdgDefault
   ENDIF

   SET ESCAPE OFF
#ifdef TEST
   push_test_tag( cId )
#else
   Set( _SET_CONFIRM, .F. )
#endif

   Box( "<CENTAR>", 3, Len( cPitanje ) + 6, .F. )

   IF ValType( cId ) == "C"
      @ box_x_koord() + 0, box_y_koord() + 2 SAY cId
   ENDIF

   set_cursor_on()
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 cPitanje GET cOdgovor PICTURE "@!"  VALID ValidSamo( cOdgovor, cMogOdg )

   READ

   BoxC()

   SET ESCAPE ON
#ifdef TEST
   pop_test_tag()
#else
   Set( _SET_CONFIRM, lConfirmEnter )
#endif

   Set( _SET_DEVICE, cPom )

   RETURN cOdgovor



STATIC FUNCTION ValidSamo( cOdg, cMogOdg )

   IF cOdg $ cMogOdg
      RETURN .T.
   ELSE

#ifndef TEST
      MsgBeep( "Unešeno: " + cOdg + "#Morate unijeti nešto od :" + cMogOdg )
#endif

      RETURN .F.
   ENDIF

   RETURN .F.



/*  Pitanje2(cId,cPitanje,cOdgDefault)
 *
 *  param: cId
 *   param: cPitanje       - Pitanje
 *  param: cOdgDefault          - Ponudjeni odgovor
 */

FUNCTION Pitanje2( cId, cPitanje, cOdgDefault )

   LOCAL cOdg
   LOCAL nDuz := Len( cPitanje ) + 4
   LOCAL cPom := Set( _SET_DEVICE )
   LOCAL GetList := {}

   SET DEVICE TO SCREEN
   IF nDuz < 54; nDuz := 54; ENDIF

   IF cOdgDefault == NIL .OR. !( cOdgDefault $ 'DNAO' )
      cOdg := ' '
   ELSE
      cOdg := cOdgDefault
   ENDIF

#ifndef TEST
   SET ESCAPE OFF
   SET CONFIRM OFF
#endif

   Box( "", 5, nDuz + 4, .F. )
   set_cursor_on()
   @ box_x_koord() + 2, box_y_koord() + 3 SAY PadR( cPitanje, nDuz ) GET cOdg PICTURE "@!" VALID cOdg $ 'DNAO'
   @ box_x_koord() + 4, box_y_koord() + 3 SAY8 PadC( "Mogući odgovori:  D - DA  ,  A - DA sve do kraja", nDuz )
   @ box_x_koord() + 5, box_y_koord() + 3 SAY8 PadC( "                  N - NE  ,  O - NE sve do kraja", nDuz )
   READ
   BoxC()

#ifndef TEST
   SET ESCAPE ON
   SET CONFIRM ON
#endif

   Set( _SET_DEVICE, cPom )

   RETURN cOdg




FUNCTION print_dialog_box( cDirekt )

   SET CONFIRM OFF
   set_cursor_on()

   cDirekt := select_print_mode( @cDirekt )

   SET CONFIRM ON

   RETURN cDirekt



FUNCTION select_print_mode( cDirekt )

   LOCAL nWidth
   LOCAL GetList := {}

   nWidth := 40

   ?E "trace-print-dialog-2"
   f18_tone( 350, 2 )
   ?E "trace-print-dialog-3"

   box_x_koord(  8 )
   box_y_koord( 38 - Round( nWidth / 2, 0 ) )

   @ box_x_koord(), box_y_koord() SAY ""


   IF gcDirekt <> "B"

      Box(, 7, nWidth )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "   Izlaz direktno na printer:" GET cDirekt  PICT "@!" VALID cDirekt $ "DEFGRVPX0"

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "-------------------------------------"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "E - direktna štampa na LPT1 (F,G)"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "V - prikaz izvještaja u editoru"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "P - pošalji na email podrške"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "R - ptxt štampa, 0 - interni editor"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "-----------------( X izlaz )---------"

      READ

      BoxC()

      IF LastKey() == K_ESC
         cDirekt := "X" // exit
      ENDIF
      RETURN cDirekt

   ELSE

      Box (, 3, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Batch printer režim ..."
      Sleep( 14 )
      BoxC()
      RETURN "D"

   ENDIF

   RETURN .T.
