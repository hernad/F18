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


// -----------------------------------------------
// definisanje sihtarice
// -----------------------------------------------
FUNCTION def_siht( lNew )

   LOCAL nBoxX := 10
   LOCAL nBoxY := 65
   LOCAL nX := 1
   LOCAL cIdRadn := Space( 6 )
   LOCAL nGodina := ld_tekuca_godina()
   LOCAL nMjesec := ld_tekuci_mjesec()
   LOCAL cGroup := Space( 7 )
   LOCAL cOpis := Space( 50 )

   o_radsiht()


   SELECT radsiht
   SET ORDER TO TAG "2"

   Box(, nBoxX, nBoxY )

   DO WHILE .T.

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** Unos / obrada sihtarica po grupama"

      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "godina" GET nGodina PICT "9999"
      @ box_x_koord() + nX, Col() + 2 SAY "mjesec" GET nMjesec PICT "99"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "grupa:" GET cGroup ;
         VALID {|| p_konto( @cGroup ), ;
         _show_get_item_value( g_gr_naz( cGroup ), 40 ) }

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "opis:" GET cOpis PICT "@S40"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "radnik:" GET cIdRadn ;
         VALID {|| p_radn( @cIdRadn ), ;
         _show_get_item_value( _rad_ime( cIdRadn ), 30 ) }

      READ

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      // pronadji ovaj zapis u RADSIHT
      SELECT radsiht
      GO TOP
      SEEK cGroup + Str( nGodina ) + Str( nMjesec ) + cIdRadn

      IF !Found()

         APPEND BLANK
         set_global_memvars_from_dbf()

         _godina := nGodina
         _mjesec := nMjesec
         _idkonto := cGroup
         _opis := cOpis
         _idradn := cIdRadn
         _dandio := "G"
         _izvrseno := 0
         _bodova := 0

      ELSE

         set_global_memvars_from_dbf()

      ENDIF

      ++nX
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "broj odradjenih sati:" GET _izvrseno PICT "99999.99"

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "od toga nocni rad:" GET _bodova PICT "99999.99"

      READ

      IF LastKey() == K_ESC
         EXIT
      ENDIF

      _vals := get_hash_record_from_global_vars()

      update_rec_server_and_dbf( "ld_radsiht", _vals, 1, "FULL" )

      // resetuj varijable
      cIdRadn := Space( 6 )

      nX := 1

   ENDDO

   BoxC()

   RETURN .T.


// ---------------------------------------------------
// uslovi izvjestaja
// ---------------------------------------------------
STATIC FUNCTION g_vars( nGod, nMj, cRadn, cGroup )

   LOCAL nRet := 1
   PRIVATE GetList := {}

   Box(, 2, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Godina" GET nGod PICT "9999"
   @ box_x_koord() + 1, Col() + 2 SAY "Godina" GET nMj PICT "99"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Grupa" GET cGroup ;
      VALID Empty( cGroup ) .OR. p_konto( @cGroup )
   @ box_x_koord() + 2, Col() + 2 SAY "Radnik" GET cRadn ;
      VALID Empty( cRadn ) .OR. p_radn( @cRadn )
   READ
   BoxC()

   IF LastKey() == K_ESC
      nRet := 0
   ENDIF

   RETURN nRet



// --------------------------------------------
// daj mi obradjene sihtarice
//
// lInfo - za prikaz na kartici .t.
// vraca ukupne sate radnika
// --------------------------------------------
FUNCTION get_siht( lInfo, nGodina, nMjesec, cIdRadn, cGroup )

   LOCAL nTArea := Select()
   LOCAL cFilter := ""
   LOCAL nLineLen := 100
   LOCAL nVar := 1

   IF PCount() <= 1

      // nema parametara unesenih
      nMjesec := ld_tekuci_mjesec()
      nGodina := ld_tekuca_godina()
      cGroup := Space( 7 )
      cIdRadn := Space( 6 )

      IF g_vars( @nGodina, @nMjesec, @cIdRadn, @cGroup ) == 0
         RETURN .F.
      ENDIF

   ENDIF

   IF PCount() == 0
      lInfo := .F.
   ENDIF

   IF !Empty( cIdRadn )
      nLineLen := 80
   ENDIF

   IF lInfo == .T.
      nVar := 0
   ENDIF

   open_sort_siht( nGodina, nMjesec, cIdRadn, cGroup, nVar )

   // HACK: 2i index ld_rasiht ne valja
   // IF nVar > 0
   SET ORDER TO TAG "2"
   // ELSE
   // SET ORDER TO TAG "2i"
   // ENDIF

   GO TOP

   IF lInfo == .F.
      START PRINT CRET
      ?
   ENDIF

   ? "Lista satnica po sihtarici: ", Str( nMjesec ) + "/" + Str( nGodina )
   ? Replicate( "-", nLineLen )
   ? PadR( "rbr", 4 ), ;
      PadR( "objekat", 30 ), ;
      if( Empty( cIdRadn ), PadR( "radnik", 20 ), "" ), ;
      PadR( "sati", 15 ), PadR( "nocni", 15 ), PadR( "redovni", 15 )

   ? Replicate( "-", nLineLen )

   nT_sati := 0
   nT_nsati := 0
   nT_razl := 0

   nTCol := 30

   nCnt := 0

   DO WHILE !Eof()

      ? PadL( AllTrim( Str( ++nCnt ) ) + ".", 4 )
      @ PRow(), PCol() + 1 SAY PadR( g_gr_naz( field->idkonto ), 30 )

      IF Empty( cIdRadn )
         @ PRow(), PCol() + 1 SAY PadR( _rad_ime( field->idradn ), 20 )
      ENDIF

      @ PRow(), nTCol := PCol() + 1 SAY Str( field->izvrseno, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->bodova, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( field->izvrseno - field->bodova, 12, 2 )

      nT_sati += field->izvrseno
      nT_nsati += field->bodova
      nT_razl += field->izvrseno - field->bodova

      SKIP
   ENDDO

   ? Replicate( "-", nLineLen )
   ? "UKUPNO SATI:"
   @ PRow(), nTCOL SAY Str( nT_sati, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_nsati, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nT_razl, 12, 2 )
   ? Replicate( "-", nLineLen )

   IF lInfo == .F.
      FF
      ENDPRINT
   ENDIF



   o_radsiht()
   GO TOP
   SET FILTER TO

   SELECT ( nTArea )

   RETURN nT_sati



// --------------------------------------------
// lista sihtarice
//
// --------------------------------------------
FUNCTION get_siht2()

   LOCAL nTArea := Select()
   LOCAL cFilter := ""
   LOCAL nLineLen := 70
   LOCAL nMjesec
   LOCAL nGodina
   LOCAL cGroup
   LOCAL cIdRadn
   LOCAL nCol := 12
   LOCAL aSiht
   LOCAL i

   // nema parametara unesenih
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cGroup := Space( 7 )
   cIdRadn := Space( 6 )

   SELECT F_RADN
   IF !Used()
      o_ld_radn()
   ENDIF

   IF g_vars( @nGodina, @nMjesec, @cIdRadn, @cGroup ) == 0
      RETURN .F.
   ENDIF

   open_sort_siht( nGodina, nMjesec, cIdRadn, cGroup )
   SET ORDER TO TAG "4"
   // "4","idradn+str(godina)+str(mjesec)+idkonto"
   GO TOP

   START PRINT CRET
   ?

   ? "Lista satnica po sihtarici: ", Str( nMjesec ) + "/" + Str( nGodina )
   ? Replicate( "-", nLineLen )
   ? PadR( "rbr", 5 ), PadR( "radnik", 20 ), PadR( "sati", 15 ), PadR( "nocni", 15 ), ;
      PadR( "redovni", 15 )
   ? Replicate( "-", nLineLen )

   nT_sati := 0
   nT_nsati := 0

   nT_tsati := 0
   nT_tnsati := 0

   nT_razl := 0
   nT_trazl := 0

   nCnt := 0

   aSiht := {}

   // zavrti se po radnicima...
   DO WHILE !Eof()

      cId_radn := field->idradn
      nT_sati := 0
      nT_nsati := 0
      nT_razl := 0

      DO WHILE !Eof() .AND. field->idradn == cId_radn

         nT_sati += field->izvrseno
         nT_nsati += field->bodova
         nT_razl += field->izvrseno - field->bodova

         nT_tsati += field->izvrseno
         nT_tnsati += field->bodova
         nT_trazl += field->izvrseno - field->bodova

         SKIP

      ENDDO

      AAdd( aSiht, { PadR( _rad_ime( cId_radn ), 20 ), Str( nT_sati, 12, 2 ), ;
         Str( nT_nsati, 12, 2 ), Str( nT_razl, 12, 2 ) } )

   ENDDO

   IF Len( aSiht ) > 0

      // napravi sortiranje
      ASort( aSiht,,, {| x, y | x[ 1 ] < y[ 1 ] } )

      // sada ispisi
      FOR i := 1 TO Len( aSiht )

         // ispisi ukupno
         ? PadL( AllTrim( Str( ++nCnt, 4 ) ) + ".", 5 )
         @ PRow(), PCol() + 1 SAY aSiht[ i, 1 ]
         @ PRow(), nCol := PCol() + 1 SAY aSiht[ i, 2 ]
         @ PRow(), PCol() + 1 SAY aSiht[ i, 3 ]
         @ PRow(), PCol() + 1 SAY aSiht[ i, 4 ]

      NEXT

      ? Replicate( "-", nLineLen )
      ? "UKUPNO SATI: "
      @ PRow(), nCol SAY Str( nT_tsati, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nT_tnsati, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nT_trazl, 12, 2 )
      ? Replicate( "-", nLineLen )

   ENDIF

   FF
   ENDPRINT

   o_radsiht()
   GO TOP
   SET FILTER TO

   SELECT ( nTArea )

   RETURN .T.



FUNCTION open_sort_siht( nGodina, nMjesec, cIdRadn, cGroup, nVar )

   LOCAL cFilter

   IF nVar == nil
      nVar := 0
   ENDIF


   o_radsiht( nGodina, nMjesec, cIdRadn )

   //cFilter := "godina =" + Str( nGodina )
   //cFilter += " .and. mjesec = " + Str( nMjesec )
   cFilter := "dandio == 'G' "

   IF !Empty( cIdRadn )
      cFilter += " .and. idradn == " + dbf_quote( cIdRadn )
   ENDIF

   IF !Empty( cGroup )
      cFilter += " .and. idkonto == " + dbf_quote( cGroup )
   ENDIF


   SET FILTER TO &cFilter
   SET ORDER TO TAG "2"
   GO TOP

   // HACK: 2i ld_radsiht ne valja
   // IF nVar == 1
   // SET ORDER TO TAG "2i"
   // GO TOP
   // ENDIF

   RETURN .T.

// ------------------------------------------
// brisanje sihtarice
// ------------------------------------------
FUNCTION del_siht()

   LOCAL nMjesec := ld_tekuci_mjesec()
   LOCAL nGodina := ld_tekuca_godina()
   LOCAL cGroup := Space( 7 )
   LOCAL cIdRadn := Space( 6 )
   LOCAL nTArea := Select()
   LOCAL cFilter := ""
   LOCAL _rec, nTrec

   IF g_vars( @nGodina, @nMjesec, @cIdRadn, @cGroup ) == 0
      RETURN .F.
   ENDIF

   open_sort_siht( nGodina, nMjesec, cIdRadn, cGroup )

   IF Pitanje(, "Pobrisati zapise sa ovim kriterijem (D/N)", "N" ) == "N"
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "2"
   GO TOP

   nCnt := 0
   DO WHILE !Eof()

      ++nCnt

      SKIP 1
      nTrec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      delete_rec_server_and_dbf( "ld_radsiht", _rec )

      GO ( nTrec )

   ENDDO

   GO TOP
   SET FILTER TO

   MsgBeep( "pobrisao " + AllTrim( Str( nCnt ) ) + " zapisa..." )

   RETURN .T.



// ------------------------------------------------
// prikazuje cItem u istom redu gdje je get
// cItem - string za prikazati
// nPadR - n vrijednost pad-a
// ------------------------------------------------
FUNCTION _show_get_item_value( cItem, nPadR )

   IF nPadR <> nil
      cItem := PadR( cItem, nPadR )
   ENDIF
   @ Row(), Col() + 3 SAY cItem

   RETURN .T.


// ------------------------------------------------
// vraca ime i prezime radnika
// ------------------------------------------------
FUNCTION _rad_ime( cId, lImeOca )

   LOCAL xRet := ""
   LOCAL nTArea := Select()

   IF lImeOca == nil
      lImeOca := .F.
   ENDIF

   select_o_radn( cId )

   xRet := AllTrim( field->ime )
   xRet += " "
   IF lImeOca == .T.
      xRet += "(" + AllTrim( field->imerod ) + ") "
   ENDIF
   xRet += AllTrim( field->naz )

   SELECT ( nTArea )

   RETURN xRet
