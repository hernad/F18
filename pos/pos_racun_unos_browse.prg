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

STATIC s_oBrowse

MEMVAR Ch // browse privatna var
MEMVAR Kol, ImeKol, gPosProdajnoMjesto, gOcitBarKod, gIdRadnik
MEMVAR gPosPratiStanjePriProdaji
MEMVAR _idpos, _idroba, _cijena, _ncijena, _kolicina, _iznos, _popust, _idvd, _brdok, _datum, _idradnik
MEMVAR _robanaz, _jmj, _idtarifa

FUNCTION pos_racun_unos_browse( cBrDok )

   LOCAL nMaxCols := f18_max_cols()
   LOCAL nMaxRows := f18_max_rows()
   LOCAL i
   LOCAL nCijenaSaPopustom, nPopust
   LOCAL aUnosMsg := {}
   LOCAL GetList := {}
   LOCAL cTmp

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   o_pos_tables()
   SELECT _pos_pripr

   IF ( cBrDok == NIL )
      cBrDok := ""
   ENDIF

   AAdd( ImeKol, { PadR( "Artikal", 10 ), {|| _pos_pripr->idroba } } )
   AAdd( ImeKol, { PadC( "Naziv", 50 ), {|| PadR( _pos_pripr->robanaz, 50 ) } } )
   AAdd( ImeKol, { "JMJ", {|| _pos_pripr->jmj } } )
   AAdd( ImeKol, { _u( "Količina" ), {|| Str( _pos_pripr->kolicina, 8, 3 ) } } )
   AAdd( ImeKol, { "Cijena", {|| Str( _pos_pripr->cijena, 8, 2 ) } } )
   AAdd( ImeKol, { "Ukupno", {|| Str( _pos_pripr->kolicina * _pos_pripr->cijena, 10, 2 ) } } )
   AAdd( ImeKol, { "Popust", {|| Str( pos_popust( _pos_pripr->cijena, _pos_pripr->ncijena ), 8, 2 ) } } )
   AAdd( ImeKol, { "Ukupno NETO", {|| Str( _pos_pripr->kolicina * pos_pripr_neto_cijena(), 10, 2 ) } } )
   AAdd( ImeKol, { "Tarifa", {|| _pos_pripr->idtarifa } } )
   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   AAdd( aUnosMsg, "<*> - Ispravka stavke" )
   AAdd( aUnosMsg, "<F8> storno" )
   AAdd( aUnosMsg, "<F9> fiskalne funkcije" )

   Box(, nMaxRows - 3, nMaxCols - 3, , aUnosMsg )
   @ box_x_koord(), box_y_koord() + 23 SAY8 PadC ( "RAČUN BR: " + AllTrim( cBrDok ), 40 ) COLOR f18_color_invert()
   s_oBrowse := pos_form_browse( box_x_koord() + 7, box_y_koord() + 1, box_x_koord() + nMaxRows - 12, box_y_koord() + nMaxCols - 2, ;
      ImeKol, Kol, ;
      { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), ;
      hb_UTF8ToStrBox( BROWSE_PODVUCI ), ;
      hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )

   s_oBrowse:autolite := .F.

   SetKey( K_F8, {|| pos_storno_racuna_f8( s_oBrowse ) } )
   SetKey( K_F9, {|| fiskalni_izvjestaji_komande( .T., .T.  ) } )

   @ box_x_koord() + 3, box_y_koord() + ( nMaxCols - 30 ) SAY "UKUPNO:"
   @ box_x_koord() + 4, box_y_koord() + ( nMaxCols - 30 ) SAY "POPUST:"
   @ box_x_koord() + 5, box_y_koord() + ( nMaxCols - 30 ) SAY "  NETO:"
   pos_racun_prikazi_ukupno()

   SELECT _pos_pripr
   SET ORDER TO
   GO TOP
   IF _pos_pripr->idvd = POS_IDVD_RACUN .AND. !Empty( _pos_pripr->opis )
      Alert( _u( "Predhodno ažuriranje nije bilo uspješno, da li je fiskalni račun izdan?" ) )
      MsgBeep("Ako je fiskalni račun izdan, zaključite račun")
   ENDIF

   Scatter()
   _idpos := gPosProdajnoMjesto
   _idvd  := POS_IDVD_RACUN
   _brdok := cBrDok
   _datum := danasnji_datum()
   _idradnik := gIdRadnik

   DO WHILE .T.

      SET CONFIRM ON
      pos_racun_prikazi_ukupno()
      DO WHILE !s_oBrowse:stable
         s_oBrowse:Stabilize()
      ENDDO

      DO WHILE !s_oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO
      _idroba := Space( Len( _idroba ) )
      _kolicina := 0
      nPopust := 0
      nCijenaSaPopustom := 0

      @ box_x_koord() + 2, box_y_koord() + 25 SAY Space ( 40 )
      SET CURSOR ON

      @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
         WHEN pos_when_racun_artikal( @_idroba ) ;
         VALID pos_valid_racun_artikal( @_idroba, GetList, 2, 27 )
      @ box_x_koord() + 3, box_y_koord() + 5 SAY "  Cijena:" GET _Cijena PICT "99999.999"  ;
         WHEN pos_when_racun_cijena_ncijena( _idroba, _cijena, _ncijena )

      @ box_x_koord() + 3, Col() + 2 SAY "Popust" GET nPopust PICT "999999.99" ;
         WHEN {|| nPopust := pos_popust( _cijena, _ncijena ), .F. }
      @ box_x_koord() + 3, Col() + 2 SAY "Sa popustom:" GET nCijenaSaPopustom PICT "999999.99" ;
         WHEN {|| nCijenaSaPopustom := _cijena - nPopust, .F. }

      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _kolicina PICT "999999.999" ;
         WHEN pos_when_racun_kolicina( @_kolicina ) ;
         VALID pos_valid_racun_kolicina( _idroba, @_kolicina, _cijena, _ncijena )

      READ

      @ box_x_koord() + 4, box_y_koord() + 25 SAY Space ( 11 )
      IF LastKey() == K_ESC
         IF valid_dodaj_taksu_za_gorivo()
            EXIT
         ELSE
            pos_racun_tekuci_saldo()
            s_oBrowse:goBottom()
            s_oBrowse:refreshAll()
            s_oBrowse:dehilite()
            LOOP
         ENDIF
      ENDIF

      SELECT _pos_pripr
      APPEND BLANK

      _robanaz := roba->naz
      _jmj := roba->jmj
      _idtarifa := roba->idtarifa
      Gather()

      // pos_racun_iznos( pos_racun_iznos() + _pos_pripr->cijena * _pos_pripr->kolicina )
      // pos_racun_popust( pos_racun_popust() + _pos_pripr->ncijena * _pos_pripr->kolicina )

      s_oBrowse:goBottom()
      s_oBrowse:refreshAll()
      s_oBrowse:dehilite()

   ENDDO

   SetKey( K_F8, NIL )
   SetKey( K_F9, NIL )

#ifdef F18_POS
   pos_unset_key_handler_ispravka_racuna()
#endif

   BoxC()

   SELECT _pos_pripr
   my_dbf_pack()
   IF RecCount() == 0
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION pos_storno_racuna_f8( oBrowse )

   LOCAL hParams := hb_Hash()
   LOCAL nCh

   pos_storno_racuna( hParams )
   pos_racun_prikazi_ukupno()
   oBrowse:goBottom()
   oBrowse:refreshAll()
   oBrowse:dehilite()
   DO WHILE !oBrowse:Stabilize() .AND. ( ( nCh := Inkey() ) == 0 )
   ENDDO

   RETURN .T.

FUNCTION pos_set_key_handler_ispravka_racuna()

   SetKey( Asc ( "*" ), NIL )
   SetKey( Asc( "*" ), {|| pos_racun_ispravka() } )

   RETURN .T.


FUNCTION pos_unset_key_handler_ispravka_racuna()

   SetKey( Asc ( "*" ), NIL )

   RETURN .F.


FUNCTION ShowBrowse( oBrowse, aConds, aProcs )

   LOCAL nCnt
   LOCAL lFlag
   LOCAL nArrLen
   LOCAL nRez := DE_CONT
   LOCAL nCh

   nArrLen := Len ( aConds )
   DO WHILE nRez <> DE_ABORT

      IF nRez == DE_REFRESH     // obnovi
         oBrowse:Refreshall()
      ENDIF

      IF oBrowse:colPos <= oBrowse:freeze
         oBrowse:colPos := oBrowse:freeze + 1
      ENDIF

      nCh := 0
      DO WHILE ! oBrowse:stable .AND. ( nCh = 0 )
         oBrowse:Stabilize()
         nCh := Inkey ()
      ENDDO

      IF oBrowse:stable
         IF oBrowse:hitTop .OR. oBrowse:hitBottom
            Beep ( 1 )
         ENDIF
         nCh := Inkey ( 0 )
      ENDIF

      lFlag := .T.
      FOR nCnt := 1 TO nArrLen
         IF Eval ( aConds[ nCnt ], nCh )
            nRez := Eval ( aProcs[ nCnt ] )
            lFlag := .F.
            EXIT
         ENDIF
      NEXT

      IF ! lFlag;  LOOP; ENDIF

      DO CASE
      CASE nCh = K_ESC
         EXIT
      CASE nCh == K_DOWN
         oBrowse:down()
      CASE nCh == K_PGDN
         oBrowse:pageDown()
      CASE nCh == K_CTRL_PGDN
         oBrowse:goBottom()
      CASE nCh == K_UP
         oBrowse:up()
      CASE nCh == K_PGUP
         oBrowse:pageUp()
      CASE nCh == K_CTRL_PGUP
         oBrowse:goTop()
      CASE nCh == K_RIGHT
         oBrowse:Right()
      CASE nCh == K_LEFT
         oBrowse:Left()
      CASE nCh == K_HOME
         oBrowse:home()
      CASE nCh == K_END
         oBrowse:end()
      CASE nCh == K_CTRL_LEFT
         oBrowse:panLeft()
      CASE nCh == K_CTRL_RIGHT
         oBrowse:panRight()
      CASE nCh == K_CTRL_HOME
         oBrowse:panHome()
      CASE nCh == K_CTRL_END
         oBrowse:panEnd()
      ENDCASE
   ENDDO

   RETURN .T.


FUNCTION pos_racun_browse_objekat()
   RETURN s_oBrowse
