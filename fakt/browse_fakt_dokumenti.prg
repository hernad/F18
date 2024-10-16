/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


CREATE CLASS BrowseFaktDokumenti INHERIT TBrowse

   DATA     fakt_dokumenti
   DATA     tekuci_item
   DATA     tekuci_red   INIT 1

   METHOD   New( top, left, bottom, right, fakt_dokumenti )
   METHOD   set_kolone_markiraj_otpremnice()

   METHOD   Browse()

   METHOD   default_keyboard_hook( key )
   METHOD   keyboard_hook( key )

   PROTECTED:
   METHOD   skipper( s )

ENDCLASS


METHOD BrowseFaktDokumenti:New( top, left, bottom, right, fakt_dokumenti )

   LOCAL nI, _item, _col

   ::super:New( top, left, bottom, right )

   ::fakt_dokumenti := fakt_dokumenti

   ::SkipBlock     := {| n| ::tekuci_item := ::skipper( @n ), n }
   ::GoBottomBlock := {||  ::tekuci_item := iif( ::fakt_dokumenti:count == 0, NIL, ::fakt_dokumenti:aItems[ ::fakt_dokumenti:count ] ), 1 }
   ::GoTopBlock    := {||  ::tekuci_item := iif( ::fakt_dokumenti:count == 0, NIL, ::fakt_dokumenti:aItems[ 1 ] ), 1 }

   ::headSep := hb_UTF8ToStrBox( BROWSE_HEAD_SEP )
   ::colsep :=  hb_UTF8ToStrBox( BROWSE_COL_SEP )

   RETURN Self


METHOD BrowseFaktDokumenti:set_kolone_markiraj_otpremnice()

   LOCAL _col

   _col := FaktColumn():New( "datdok", self, NIL )
   ::AddColumn( _col )

   _col := FaktColumn():New( "broj", self, NIL )
   ::AddColumn( _col )

   _col := FaktColumn():New( "neto", self, NIL )
   ::AddColumn( _col )

   _col := FaktColumn():New( "mark", self, NIL )
   ::AddColumn( _col )

   RETURN .T.

METHOD BrowseFaktDokumenti:skipper( s )

   ::tekuci_red += s

   if ::tekuci_red > ::fakt_dokumenti:count
      s -= ::tekuci_red - ::fakt_dokumenti:count
      ::tekuci_red := ::fakt_dokumenti:count
   ENDIF

   if ::tekuci_red < 1
      s +=  1 - ::tekuci_red
      ::tekuci_red := 1
   ENDIF

   RETURN iif( ::fakt_dokumenti:count == 0, NIL, ::fakt_dokumenti:aItems[ ::tekuci_red ] )


METHOD BrowseFaktDokumenti:Browse()

   LOCAL exit_keys, _vrti := .T., _k

   IF ! ISARRAY( exit_keys )
      exit_keys := { K_ESC }
   ENDIF

   DO WHILE _vrti

      DO WHILE !::Stabilize() .AND. NextKey() == 0
      ENDDO

      _k := Inkey( 0 )
      IF AScan( exit_keys, _k ) > 0
         _vrti := .F.
         LOOP
      ENDIF

      ::default_keyboard_hook( _k )
   ENDDO

   RETURN self


METHOD BrowseFaktDokumenti:default_keyboard_hook( key )

   SWITCH ( key )
   CASE K_DOWN
      ::down()
      EXIT
   CASE K_PGDN
      ::pageDown()
      EXIT
   CASE K_CTRL_PGDN
      ::goBottom()
      EXIT
   CASE K_UP
      ::up()
      EXIT
   CASE K_PGUP
      ::pageUp()
      EXIT
   CASE K_CTRL_PGUP
      ::goTop()
      EXIT
   CASE K_RIGHT
      ::Right()
      EXIT
   CASE K_LEFT
      ::Left()
      EXIT
   CASE  K_HOME
      ::home()
      EXIT
   CASE K_END
      ::end()
      EXIT
   CASE K_CTRL_LEFT
      ::panLeft()
      EXIT
   CASE K_CTRL_RIGHT
      ::panRight()
      EXIT
   CASE K_CTRL_HOME
      ::panHome()
      EXIT
   CASE K_CTRL_END
      ::panEnd()
      EXIT
   OTHERWISE
      ::keyboard_hook( key )
   END

   RETURN self


METHOD BrowseFaktDokumenti:keyboard_hook( key )

   IF Chr( key ) == " "
      Beep( 1 )
      if ::tekuci_item == NIL
         RETURN self
      ENDIF

      if ::tekuci_item:mark
         ::tekuci_item:mark := .F.
      ELSE
         ::tekuci_item:mark := .T.
      ENDIF
      ::RefreshAll()
   ENDIF

   RETURN self
