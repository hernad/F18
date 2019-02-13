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

STATIC s_nMaxKolicinaPosRacun := NIL
STATIC s_oBrowse, s_cRobaPosDuzinaSifre

MEMVAR Ch // browse privatna var
MEMVAR Kol, ImeKol, gIdPos, gOcitBarKod, gIdRadnik
MEMVAR gPosPratiStanjePriProdaji
MEMVAR _idpos, _idroba, _cijena, _ncijena, _kolicina, _iznos, _popust, _idvd, _brdok, _datum, _idradnik
MEMVAR _robanaz, _jmj, _idtarifa

FUNCTION pos_racun_unos_browse( cBrDok )

   LOCAL nMaxCols := f18_max_cols()
   LOCAL nMaxRows := f18_max_rows()

   LOCAL i
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

   SetKey( K_F8, {|| pos_storno_racuna( s_oBrowse ), pos_osvjezi_ukupno( .T. ) } )
   SetKey( K_F9, {|| fiskalni_izvjestaji_komande( .T., .T.  ) } )

   @ box_x_koord() + 3, box_y_koord() + ( nMaxCols - 30 ) SAY "UKUPNO:"
   @ box_x_koord() + 4, box_y_koord() + ( nMaxCols - 30 ) SAY "POPUST:"
   @ box_x_koord() + 5, box_y_koord() + ( nMaxCols - 30 ) SAY " TOTAL:"

   pos_osvjezi_ukupno( .T. )

   SELECT _pos_pripr
   SET ORDER TO
   GO TOP

   Scatter()
   _idpos := gIdPos
   _idvd  := POS_IDVD_RACUN
   _brdok := cBrDok
   _datum := danasnji_datum()
   _idradnik := gIdRadnik

   DO WHILE .T.

      SET CONFIRM ON
      pos_osvjezi_ukupno( .F. )
      DO WHILE !s_oBrowse:stable
         s_oBrowse:Stabilize()
      ENDDO

      DO WHILE !s_oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

      _idroba := Space( Len( _idroba ) )
      _kolicina := 0

      @ box_x_koord() + 2, box_y_koord() + 25 SAY Space ( 40 )
      SET CURSOR ON

      s_cRobaPosDuzinaSifre := "13"

      @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
         WHEN when_pos_racun_artikal(@_idroba) ;
         VALID valid_pos_racun_artikal( @_idroba, GetList, 2, 27 )
      @ box_x_koord() + 3, box_y_koord() + 5 SAY "  Cijena:" GET _Cijena PICT "99999.999"  WHEN pos_when_cijena()
      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _kolicina PICT "999999.999" WHEN pos_when_kolicina( @_kolicina ) VALID valid_pos_kolicina( @_kolicina, _cijena )

      // nRowPos := 5
      READ

      @ box_x_koord() + 4, box_y_koord() + 25 SAY Space ( 11 )

      IF LastKey() == K_ESC
         IF valid_dodaj_taksu_za_gorivo()
            EXIT
         ELSE
            pos_tekuci_saldo_racuna()
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

      IF !( roba->tip == "T" )
         _cijena := pos_get_mpc()
      ENDIF
      Gather()

      pos_racun_iznos( pos_racun_iznos() + _pos_pripr->cijena * _pos_pripr->kolicina )
      pos_racun_popust( pos_racun_popust() + _pos_pripr->ncijena * _pos_pripr->kolicina )

      s_oBrowse:goBottom()
      s_oBrowse:refreshAll()
      s_oBrowse:dehilite()

      // cTmp := "STANJE ARTIKLA " + AllTrim( cIdRobaStanje ) + ": " + AllTrim( Str( nStanjeRobe, 12, 2 ) ) + " " + cJmjStanje

   ENDDO

   SetKey( K_F6, NIL )
   SetKey( K_F7, NIL )
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



FUNCTION pos_max_kolicina_kod_unosa( nMaxKolicina )

   IF nMaxKolicina != NIL
      s_nMaxKolicinaPosRacun := fetch_metric( "pos_maksimalna_kolicina_na_unosu", my_user(), 0 )
   ENDIF

   RETURN s_nMaxKolicinaPosRacun



STATIC FUNCTION when_pos_racun_artikal( cIdRoba )

   pos_set_key_handler_ispravka_racuna()
   cIdroba := PadR( cIdroba, Val( s_cRobaPosDuzinaSifre ) )

   pos_racun_artikal_info( 0, "XCLEARX" )

   RETURN .T.

/*
   cIdRoba - parametar po referenci
*/
STATIC FUNCTION valid_pos_racun_artikal( cIdroba, aGetList, nRow, nCol )

   LOCAL lOk, cBarkodProcitati

   lOk := pos_postoji_roba( @cIdroba, nRow, nCol, @cBarkodProcitati, aGetList ) ;
          .AND. pos_racun_provjera_dupli_artikal( cIdroba )

   pos_racun_artikal_info( 1, cIdRoba, "Stanje: " + AllTrim( Str( pos_stanje_artikla( _idpos, cIdRoba ), 12, 2 ) ) )

   IF gOcitBarKod
      hb_keyPut( K_ENTER )
   ENDIF

   RETURN lOk

STATIC FUNCTION pos_racun_provjera_dupli_artikal( cIdroba )

   SELECT _pos_pripr
   PushWa()
   SET ORDER TO TAG "1"
   HSEEK cIdRoba
   IF Found()
      pos_racun_artikal_info( 2, _idRoba, "Na računu se već nalazi ista roba!" )
   ENDIF
   PopWa()

   RETURN .T.


STATIC FUNCTION pos_when_cijena()

   RETURN roba->tip == "T" // .OR. gPopZcj == "D"


STATIC FUNCTION pos_when_kolicina( kolicina )

   IF gOcitBarKod
      IF param_tezinski_barkod() == "D" .AND. kolicina <> 0
      ELSE
         kolicina := 1
      ENDIF
   ENDIF

   RETURN .T.


STATIC FUNCTION valid_pos_kolicina( nKolicina, nCijena )
   RETURN pos_valid_kolicina( nKolicina ) .AND. pos_provjera_max_kolicine( @nKolicina ) .AND. pos_cijena_nije_nula( nCijena )


STATIC FUNCTION pos_osvjezi_ukupno( lRekalkulisati )

   LOCAL aRet

   IF lRekalkulisati == NIL
      lRekalkulisati := .F.
   ENDIF

   IF lRekalkulisati
      aRet := pos_tekuci_saldo_racuna()
      pos_racun_iznos( aRet[ 1 ] )
      pos_racun_popust( aRet[ 2 ] )
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 15 SAY Space( 10 )
   pos_racun_prikaz_ukupno( box_x_koord() + 2 )
   ispis_veliki_brojevi_iznos( pos_racun_iznos_neto(), box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )

   SELECT _pos_pripr
   GO TOP

   RETURN .T.


STATIC FUNCTION pos_tekuci_saldo_racuna()

   LOCAL nIznos := 0
   LOCAL nPopust := 0

   PushWa()
   SELECT _pos_pripr
   GO TOP

   DO WHILE !Eof()
      nIznos += _pos_pripr->kolicina *  _pos_pripr->cijena
      nPopust += _pos_pripr->kolicina * _pos_pripr->ncijena
      SKIP
   ENDDO
   PopWa()

   RETURN { nIznos, nPopust }


FUNCTION pos_provjera_max_kolicine( nKolicina )

   LOCAL nPosUnosMaxKolicina

   nPosUnosMaxKolicina := pos_max_kolicina_kod_unosa()

   IF nPosUnosMaxKolicina == 0
      nPosUnosMaxKolicina := 99999
   ENDIF

   IF nPosUnosMaxKolicina == 0
      RETURN .T.
   ENDIF

   IF nKolicina > nPosUnosMaxKolicina
      IF Pitanje(, "Da li je ovo ispravna količina (D/N) ?: " + AllTrim( Str( nKolicina ) ), "N" ) == "D"
         RETURN .T.
      ELSE
         nKolicina := 0
         RETURN .F.
      ENDIF
   ELSE
      RETURN .T.
   ENDIF

   RETURN .T.


FUNCTION pos_set_key_handler_ispravka_racuna()

   SetKey( Asc ( "*" ), NIL )
   SetKey( Asc( "*" ), {|| pos_ispravi_racun() } )

   RETURN .T.


FUNCTION pos_unset_key_handler_ispravka_racuna()

   SetKey( Asc ( "*" ), NIL )

   RETURN .F.


STATIC FUNCTION pos_cijena_nije_nula( nCijena )

   IF LastKey() == K_UP
      RETURN .T.
   ENDIF

   IF nCijena == 0
      MsgBeep( "Nepravilan unos cijene, cijena mora biti <> 0 !?" )
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_valid_kolicina( nKolicina )

   LOCAL lOk := .F.
   LOCAL cMsg
   LOCAL nStanjeRobe

   IF LastKey() == K_UP
      lOk := .T.
      RETURN lOk
   ENDIF

   IF ( nKolicina == 0 )
      MsgBeep( "Nepravilan unos količine! Ponovite unos!", 15 )
      RETURN lOk
   ENDIF

   IF gPosPratiStanjePriProdaji == "N" .OR. roba->tip $ "TU"
      lOk := .T.
      RETURN lOk
   ENDIF
   nStanjeRobe := pos_stanje_artikla( _idpos, _idroba )

   lOk := .T.
   IF ( nKolicina > nStanjeRobe )

      cMsg := "Artikal: " + _idroba + " Trenutno na stanju: " + Str( nStanjeRobe, 12, 2 )
      IF gPosPratiStanjePriProdaji = "!"
         cMsg += "#Unos artikla onemogućen !?"
         lOk := .F.
      ENDIF
      MsgBeep( cMsg )

   ENDIF

   RETURN lOk



FUNCTION pos_ispravi_racun()

   LOCAL aConds
   LOCAL aProcs
   LOCAL cColor

   pos_unset_key_handler_ispravka_racuna()

   cColor := SetColor()
   prikaz_dostupnih_opcija_crno_na_zuto( { ;
      " <Enter>-Ispravi stavku", ;
      _u( " <B>-Briši stavku" ), ;
      _u( " <Esc>-Završi" ) } )

   SetColor( cColor )

   s_oBrowse:autolite := .T.
   s_oBrowse:configure()
   aConds := { {| nCh | Upper( Chr( nCh ) ) == "B" }, {| nCh | nCh == K_ENTER } }
   aProcs := { {|| pos_brisi_stavku_racuna() }, {|| pos_ispravi_stavku_racuna() } }

   ShowBrowse( s_oBrowse, aConds, aProcs )
   s_oBrowse:autolite := .F.
   s_oBrowse:dehilite()
   s_oBrowse:stabilize()

   pos_set_key_handler_ispravka_racuna()

   RETURN .T.


FUNCTION pos_brisi_stavku_racuna()

   SELECT _pos_pripr

   IF RecCount2() == 0
      MsgBeep ( "Priprema računa je prazna !#Brisanje nije moguće !", 20 )
      RETURN ( DE_REFRESH )
   ENDIF

   Beep ( 2 )
   pos_racun_iznos( pos_racun_iznos() - _pos_pripr->cijena * _pos_pripr->kolicina )
   pos_racun_popust( pos_racun_popust() - _pos_pripr->ncijena * _pos_pripr->kolicina )

   my_delete()

   pos_osvjezi_ukupno( .F. )

   s_oBrowse:refreshAll()
   DO WHILE !s_oBrowse:stable
      s_oBrowse:Stabilize()
   ENDDO

   RETURN ( DE_REFRESH )


FUNCTION pos_ispravi_stavku_racuna()

   LOCAL GetList := {}

   SELECT _pos_pripr
   IF RecCount2() == 0
      MsgBeep ( "Račun ne sadrži niti jednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   Scatter()

   SET CURSOR ON
   Box(, 3, 80 )
   @ box_x_koord() + 1, box_y_koord() + 3 SAY8 "    Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
      WHEN {|| _idroba := PadR( _idroba, Val( s_cRobaPosDuzinaSifre ) ), .T. } VALID valid_pos_racun_artikal( @_idroba, GetList, 1, 28 )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "     Cijena:" GET _Cijena  PICTURE "99999.999" WHEN roba->tip == "T"
   @ box_x_koord() + 3, box_y_koord() + 3 SAY8 "   količina:" GET _Kolicina VALID pos_valid_kolicina ( _Kolicina )

   READ

   SELECT _pos_pripr
   @ box_x_koord() + 3, box_y_koord() + 25 SAY Space( 11 )

   IF LastKey() <> K_ESC
      IF ( _pos_pripr->IdRoba <> _IdRoba  .OR. roba->tip == "T" ) .OR. _pos_pripr->Kolicina <> _Kolicina
         _robanaz := roba->naz
         _jmj := roba->jmj
         IF !( roba->tip == "T" )
            _cijena := pos_get_mpc()
         ENDIF
         _idtarifa := roba->idtarifa
         pos_racun_iznos( pos_racun_iznos() + _cijena * _kolicina - _pos_pripr->cijena * _pos_pripr->kolicina )
         pos_racun_popust( pos_racun_popust() + _ncijena * _kolicina - _pos_pripr->ncijena * _pos_pripr->kolicina )

         my_rlock()
         Gather()
         my_unlock()

         // ELSEIF ( _pos_pripr->Kolicina <> _Kolicina )
         // pos_racun_iznos( pos_racun_iznos() + _cijena * _kolicina - _pos_pripr->cijena * _pos_pripr->kolicina)
         // pos_racun_popust( pos_racun_popust() + _ncijena * _kolicina - _pos_pripr->ncijena * _pos_pripr->kolicina)
         //
         // RREPLACE Kolicina WITH _Kolicina
      ENDIF

   ENDIF

   BoxC()

   pos_osvjezi_ukupno( .F. )
   s_oBrowse:refreshCurrent()

   DO WHILE !s_oBrowse:stable
      s_oBrowse:Stabilize()
   ENDDO

   RETURN ( DE_CONT )


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
