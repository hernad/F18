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
STATIC s_oBrowse, s_nIznosRacuna, s_nPopust, s_cRobaPosDuzinaSifre

MEMVAR Kol, ImeKol, gIdPos, gOcitBarKod
MEMVAR _idpos, _idroba, _cijena, _ncijena, _kolicina, _iznos, _popust, _idvd, _brdok, _datum, _idradnik
MEMVAR _robanaz, _jmj, _idtarifa

FUNCTION pos_racun_unos_browse( cBrDok )

   LOCAL nMaxCols := f18_max_cols()
   LOCAL nMaxRows := f18_max_rows()

   LOCAL nStanjeRobe := 0
   LOCAL cIdRobaStanje, cJmjStanje
   LOCAL i
   LOCAL aUnosMsg := {}
   LOCAL GetList := {}
   LOCAL cTmp

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}
   PRIVATE nRowPos

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

   pos_set_key_handler_ispravka_racuna()

   @ box_x_koord() + 3, box_y_koord() + ( nMaxCols - 30 ) SAY "UKUPNO:"
   @ box_x_koord() + 4, box_y_koord() + ( nMaxCols - 30 ) SAY "POPUST:"
   @ box_x_koord() + 5, box_y_koord() + ( nMaxCols - 30 ) SAY " TOTAL:"

   // aRet := pos_tekuci_saldo_racuna()
   // s_nIznosRacuna := aRet[ 1 ]
   // s_nPopust := aRet[ 2 ]
   // ispisi_iznos_veliki_brojevi( s_nIznosRacuna - s_nPopust, box_x_koord() + ( nMaxRows - 13 ), nMaxCols - 2 )
   pos_osvjezi_ukupno( .T. )

   SELECT _pos_pripr
   SET ORDER TO
   GO TOP

   scatter()
   _idpos := gIdPos
   _idvd  := POS_VD_RACUN
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
         WHEN {|| _idroba := PadR( _idroba, Val( s_cRobaPosDuzinaSifre ) ), .T. } VALID valid_pos_racun_artikal( GetList, 2, 27 )

      @ box_x_koord() + 3, box_y_koord() + 5 SAY "  Cijena:" GET _Cijena PICT "99999.999"  WHEN ( roba->tip == "T" .OR. gPopZcj == "D" )
      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _kolicina PICT "999999.999" WHEN when_pos_kolicina( @_kolicina ) VALID valid_pos_kolicina( @_kolicina, _cijena )

      nRowPos := 5
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

      nStanjeRobe := pos_stanje_artikla( field->idpos, field->idroba )
      cIdRobaStanje := field->idroba
      cJmjStanje := field->jmj

      s_nIznosRacuna += field->cijena * field->kolicina
      s_nPopust += field->ncijena * field->kolicina
      s_oBrowse:goBottom()
      s_oBrowse:refreshAll()
      s_oBrowse:dehilite()

      cTmp := "STANJE ARTIKLA " + AllTrim( cIdRobaStanje ) + ": " + AllTrim( Str( nStanjeRobe, 12, 2 ) ) + " " + cJmjStanje
      ispisi_donji_dio_forme_unosa( cTmp, 1 )

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



STATIC FUNCTION valid_pos_racun_artikal( aGetList, nRow, nCol )

   LOCAL lOk, cBarkodProcitati

   lOk := pos_postoji_roba( @_idroba, nRow, nCol, @cBarkodProcitati, aGetList ) .AND. pos_racun_provjera_dupli_artikli( _idroba )

   IF gOcitBarKod
      hb_keyPut( K_ENTER )
   ENDIF

   RETURN lOk


STATIC FUNCTION when_pos_kolicina( kolicina )

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
      s_nIznosRacuna := aRet[ 1 ]
      s_nPopust := aRet[ 2 ]
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 15 SAY Space( 10 )
   pos_unos_show_total( box_x_koord() + 2 )
   ispisi_iznos_veliki_brojevi( s_nIznosRacuna - s_nPopust, box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )

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

   IF gPratiStanje == "N" .OR. roba->tip $ "TU"
      lOk := .T.
      RETURN lOk
   ENDIF

   nStanjeRobe := pos_stanje_artikla( _idpos, _idroba )

   lOk := .T.

   IF ( nKolicina > nStanjeRobe )

      cMsg := "Artikal: " + _idroba + " Trenutno na stanju: " + Str( nStanjeRobe, 12, 2 )
      IF gPratiStanje = "!"
         cMsg += "#Unos artikla onemogućen !?"
         lOk := .F.
      ENDIF

      MsgBeep( cMsg )

   ENDIF

   RETURN lOk


STATIC FUNCTION pos_racun_provjera_dupli_artikli()

   LOCAL nPrevRec
   LOCAL lFlag := .T.

   IF gDupliArt == "D" .AND. gDupliUpoz == "N"
      RETURN .T.
   ENDIF

   SELECT _pos_pripr
   nPrevRec := RecNo()

   IF _idroba = PadR( "PLDUG", 7 ) .AND. reccount2() <> 0
      RETURN .F.
   ENDIF

   SET ORDER TO TAG "1"
   SEEK PadR( "PLDUG", 7 )

   IF Found()
      MsgBeep( 'PLDUG mora biti jedina stavka !' )
      SET ORDER TO
      GO ( nPrevRec )
      RETURN .F.
   ELSE
      SET ORDER TO TAG "1"
      HSEEK _IdRoba
   ENDIF

   IF Found()
      IF _IdRoba = 'PLDUG'
         MsgBeep( 'Pri plaćanju duga ne možete navoditi artikal' )
      ENDIF
      IF gDupliArt == "N"
         MsgBeep ( "Na računu se već nalazi ista roba!#" + "U slucaju potrebe ispravite stavku računa!", 20 )
         lFlag := .F.
      ELSEIF gDupliUpoz == "D"
         MsgBeep ( "Na računu se već nalazi ista roba!" )
      ENDIF
   ENDIF
   SET ORDER TO
   GO ( nPrevRec )

   RETURN ( lFlag )


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

   // cGetId := _idroba
   // nGetKol := _Kolicina

   aConds := { {| nCh | Upper( Chr( nCh ) ) == "B" }, {| nCh | nCh == K_ENTER } }
   aProcs := { {|| pos_brisi_stavku_racuna() }, {|| pos_ispravi_stavku_racuna() } }

   ShowBrowse( s_oBrowse, aConds, aProcs )

   s_oBrowse:autolite := .F.
   s_oBrowse:dehilite()
   s_oBrowse:stabilize()

   // box_crno_na_zuto_end()

   // _idroba := cGetId
   // _kolicina := nGetKol

   pos_set_key_handler_ispravka_racuna()

   RETURN .T.


STATIC FUNCTION pos_unos_show_total( nRow )

   @ box_x_koord() + nRow + 0, box_y_koord() + ( f18_max_cols() - 12 ) SAY s_nIznosRacuna PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + nRow + 1, box_y_koord() + ( f18_max_cols() - 12 ) SAY s_nPopust PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + nRow + 2, box_y_koord() + ( f18_max_cols() - 12 ) SAY s_nIznosRacuna - s_nPopust PICT "99999.99" COLOR f18_color_invert()

   RETURN .T.


FUNCTION pos_brisi_stavku_racuna()

   SELECT _pos_pripr

   IF RecCount2() == 0
      MsgBeep ( "Priprema računa je prazna !#Brisanje nije moguće !", 20 )
      RETURN ( DE_REFRESH )
   ENDIF

   Beep ( 2 )

   s_nIznosRacuna -= _pos_pripr->kolicina * _pos_pripr->cijena
   s_nPopust -= _pos_pripr->kolicina * _pos_pripr->ncijena
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

   BOX (, 3, 80 )

   @ box_x_koord() + 1, box_y_koord() + 3 SAY8 "    Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
      WHEN {|| _idroba := PadR( _idroba, Val( s_cRobaPosDuzinaSifre ) ), .T. } VALID valid_pos_racun_artikal( GetList, 1, 28 )

   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "     Cijena:" GET _Cijena  PICTURE "99999.999" WHEN roba->tip == "T"
   @ box_x_koord() + 3, box_y_koord() + 3 SAY8 "   količina:" GET _Kolicina VALID pos_valid_kolicina ( _Kolicina )

   READ

   SELECT _pos_pripr
   @ box_x_koord() + 3, box_y_koord() + 25 SAY Space( 11 )

   IF LastKey() <> K_ESC

      IF ( _pos_pripr->IdRoba <> _IdRoba ) .OR. roba->tip == "T"

         _robanaz := roba->naz
         _jmj := roba->jmj

         IF !( roba->tip == "T" )
            _cijena := pos_get_mpc()
         ENDIF

         _idtarifa := roba->idtarifa
         // _idodj := Space( 2 )

         s_nIznosRacuna += ( _cijena * _kolicina ) - _pos_pripr->cijena * _pos_pripr->kolicina
         s_nPopust += ( _ncijena * _kolicina )  - _pos_pripr->ncijena * _pos_pripr->kolicina

         my_rlock()
         Gather()
         my_unlock()

      ENDIF

      IF ( _pos_pripr->Kolicina <> _Kolicina )
         s_nIznosRacuna += ( _cijena * _kolicina ) - _pos_pripr->cijena * _pos_pripr->kolicina
         s_nPopust += ( _ncijena * _kolicina ) - _pos_pripr->ncijena * _pos_pripr->kolicina
         RREPLACE Kolicina WITH _Kolicina
      ENDIF

   ENDIF

   BoxC()

   pos_osvjezi_ukupno( .F. )

   s_oBrowse:refreshCurrent()

   DO WHILE !s_oBrowse:stable
      s_oBrowse:Stabilize()
   ENDDO

   RETURN ( DE_CONT )



FUNCTION GetReader2( oGet, GetList, oMenu, aMsg )

   LOCAL nKey
   LOCAL nRow
   LOCAL nCol

   IF ( GetPreValSC( oGet, aMsg ) )
      oGet:setFocus()
      DO WHILE ( oGet:exitState == GE_NOEXIT )
         IF ( gOcitBarKod .AND. gEntBarCod == "D" )
            oGet:exitState := GE_ENTER
            EXIT
         ENDIF
         IF ( oGet:typeOut )
            oGet:exitState := GE_ENTER
         ENDIF

         DO WHILE ( oGet:exitState == GE_NOEXIT )
            nKey := Inkey( 0 )
            GetApplyKey( oGet, nKey, GetList, oMenu, aMsg )
            nRow := Row()
            nCol := Col()
            DevPos( nRow, nCol )
         ENDDO

         IF ( !GetPstValSC( oGet, aMsg ) )
            oGet:exitState := GE_NOEXIT
         ENDIF
      ENDDO
      oGet:killFocus()
   ENDIF

   RETURN .T.


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
