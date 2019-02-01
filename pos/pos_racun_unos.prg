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

MEMVAR Kol, ImeKol, gIdPos
MEMVAR _idpos, _idroba, _cijena, _ncijena, _kolicina, _iznos, _popust, _idvd, _brdok, _datum, _sto, _smjena, _idradnik, _idcijena, _prebacen, _mu_ui
MEMVAR _robanaz, _jmj, _idtarifa, _idodj

FUNCTION pos_unos_racuna( cBrDok )

   LOCAL nMaxCols := f18_max_cols()
   LOCAL nMaxRows := f18_max_rows()
   LOCAL _read_barkod
   LOCAL nStanjeRobe := 0
   LOCAL cIdRobaStanje, cJmjStanje
   LOCAL i
   LOCAL aUnosMsg := {}
   LOCAL oBrowse
   LOCAL cRobaPosDuzinaSifre
   LOCAL GetList := {}

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}
   PRIVATE nRowPos

   PRIVATE nPopust := 0
   PRIVATE nIznNar := 0

   o_pos_tables()
   SELECT _pos_pripr


   aRabat := {}

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

   oBrowse := pos_form_browse( box_x_koord() + 7, box_y_koord() + 1, box_x_koord() + nMaxRows - 12, box_y_koord() + nMaxCols - 2, ;
      ImeKol, Kol, ;
      { hb_UTF8ToStrBox( BROWSE_PODVUCI_2 ), ;
      hb_UTF8ToStrBox( BROWSE_PODVUCI ), ;
      hb_UTF8ToStrBox( BROWSE_COL_SEP ) }, 0 )

   oBrowse:autolite := .F.

   SetKey( K_F6, {|| f7_pf_traka() } )

   SetKey( K_F7, {|| pos_storno_fisc_no(), _refresh_total() } )
   SetKey( K_F8, {|| pos_storno_rn(), _refresh_total() } )
   SetKey( K_F9, {|| fiskalni_izvjestaji_komande( .T., .T.  ) } )

   pos_set_key_handler_ispravka_racuna( oBrowse )

   @ box_x_koord() + 3, box_y_koord() + ( nMaxCols - 30 ) SAY "UKUPNO:"
   @ box_x_koord() + 4, box_y_koord() + ( nMaxCols - 30 ) SAY "POPUST:"
   @ box_x_koord() + 5, box_y_koord() + ( nMaxCols - 30 ) SAY " TOTAL:"

   ispisi_iznos_veliki_brojevi( 0, box_x_koord() + ( nMaxRows - 12 ), nMaxCols - 2 )

   nIznNar := 0
   nPopust := 0

   _calc_current_total( @nIznNar, @nPopust )

   SELECT _pos_pripr
   SET ORDER TO
   GO TOP

   scatter()
   _idpos := gIdPos
   _idvd  := POS_VD_RACUN
   _brdok := cBrDok
   _datum := danasnji_datum()
   _sto   := ""
   _smjena := gSmjena
   _idradnik := gIdRadnik
   _idcijena := gIdCijena
   _prebacen := OBR_NIJE
   _mu_i := R_I


   DO WHILE .T.

      SET CONFIRM ON
      pos_unos_show_total( nIznNar, nPopust, box_x_koord() + 2 )

      @ box_x_koord() + 3, box_y_koord() + 15 SAY Space( 10 )
      ispisi_iznos_veliki_brojevi( ( nIznNar - nPopust ), box_x_koord() + ( nMaxRows - 12 ), nMaxCols - 2 )

      DO WHILE !oBrowse:stable
         oBrowse:Stabilize()
      ENDDO

      DO WHILE !oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

      _idroba := Space( Len( _idroba ) )
      _kolicina := 0

      @ box_x_koord() + 2, box_y_koord() + 25 SAY Space ( 40 )
      SET CURSOR ON

      IF gRobaPosDuzinaSifre > 0
         cRobaPosDuzinaSifre := AllTrim( Str( gRobaPosDuzinaSifre ) )
      ELSE
         cRobaPosDuzinaSifre := "10"
      ENDIF

      @ box_x_koord() + 2, box_y_koord() + 5 SAY " Artikal:" GET _idroba PICT PICT_POS_ARTIKAL ;
         WHEN {|| _idroba := PadR( _idroba, Val( cRobaPosDuzinaSifre ) ), .T. } VALID valid_pos_racun_artikal( @_kolicina, GetList )

      @ box_x_koord() + 3, box_y_koord() + 5 SAY "  Cijena:" GET _Cijena PICT "99999.999"  WHEN ( roba->tip == "T" .OR. gPopZcj == "D" )
      @ box_x_koord() + 4, box_y_koord() + 5 SAY8 "Količina:" GET _kolicina PICT "999999.999" WHEN when_pos_kolicina( @_kolicina ) VALID valid_pos_kolicina( @_kolicina, _cijena )

      nRowPos := 5

      READ

      @ box_x_koord() + 4, box_y_koord() + 25 SAY Space ( 11 )

      IF LastKey() == K_ESC

         IF valid_dodaj_taksu_za_gorivo()
            EXIT
         ELSE
            _calc_current_total( @nIznNar, @nPopust )
            oBrowse:goBottom()
            oBrowse:refreshAll()
            oBrowse:dehilite()
            LOOP

         ENDIF

      ENDIF

      SELECT _pos_pripr
      APPEND BLANK

      _robanaz := roba->naz
      _jmj := roba->jmj
      _idtarifa := roba->idtarifa
      _idodj := Space( 2 )

      IF !( roba->tip == "T" )
         _cijena := pos_get_mpc()
      ENDIF

      Gather()

      nStanjeRobe := pos_stanje_artikla( field->idpos, field->idroba )

      cIdRobaStanje := field->idroba
      cJmjStanje := field->jmj

      nIznNar += field->cijena * field->kolicina
      nPopust += field->ncijena * field->kolicina
      oBrowse:goBottom()
      oBrowse:refreshAll()
      oBrowse:dehilite()

      _tmp := "STANJE ARTIKLA " + AllTrim( cIdRobaStanje ) + ": " + AllTrim( Str( nStanjeRobe, 12, 2 ) ) + " " + cJmjStanje
      ispisi_donji_dio_forme_unosa( _tmp, 1 )

   ENDDO

   SetKey( K_F6, NIL )
   SetKey( K_F7, NIL )
   SetKey( K_F8, NIL )
   SetKey( K_F9, NIL )

#ifdef F18_POS
   pos_unset_key_handler_ispravka_racuna()
#endif

   BoxC()

   RETURN ( .T. )



FUNCTION pos_max_kolicina_kod_unosa( nMaxKolicina )

   IF nMaxKolicina != NIL
      s_nMaxKolicinaPosRacun := fetch_metric( "pos_maksimalna_kolicina_na_unosu", my_user(), 0 )
   ENDIF

   RETURN s_nMaxKolicinaPosRacun


STATIC FUNCTION Popust( nx, ny )

   LOCAL nC1 := 0
   LOCAL nC2 := 0

   pos_get_popust_sve_varijante( aRabat, _cijena )
   ShowRabatOnForm( nx, ny )

   RETURN .T.


STATIC FUNCTION valid_pos_racun_artikal( nKolicina, aGetList )

   LOCAL lOk, cBarkodProcitati

   lOk := pos_postoji_roba( @_idroba, 2, 27, @cBarkodProcitati, aGetList ) .AND. NarProvDuple( _idroba )

   IF gOcitBarCod
      hb_keyPut( K_ENTER )
   ENDIF

   RETURN lOk


STATIC FUNCTION when_pos_kolicina( kolicina )

   Popust( box_x_koord() + 4, box_y_koord() + 28 )

   IF gOcitBarCod
      IF param_tezinski_barkod() == "D" .AND. kolicina <> 0
      ELSE
         kolicina := 1
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION valid_pos_kolicina( kolicina, cijena )
   RETURN KolicinaOK( kolicina ) .AND. pos_check_qtty( @kolicina ) .AND. cijena_ok( cijena )



STATIC FUNCTION _refresh_total()

   LOCAL _iznos := 0
   LOCAL _popust := 0

   _calc_current_total( @_iznos, @_popust )

   nIznNar := _iznos
   nPopust := _popust

   ispisi_iznos_veliki_brojevi( ( _iznos - _popust ), box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )
   pos_unos_show_total( _iznos, _popust, box_x_koord() + 2 )

   SELECT _pos_pripr
   GO TOP

   RETURN .T.


STATIC FUNCTION _calc_current_total( iznos, nPopust )

   LOCAL nDbfArea := Select()
   LOCAL _iznos := 0
   LOCAL _popust := 0

   SELECT _pos_pripr
   GO TOP

   DO WHILE !Eof()
      _iznos += _pos_pripr->( kolicina * cijena )
      _popust += _pos_pripr->( kolicina * nCijena )
      SKIP
   ENDDO

   GO TOP

   iznos := _iznos
   nPopust := _popust

   SELECT ( nDbfArea )

   RETURN .T.


FUNCTION pos_check_qtty( nKolicina )

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


FUNCTION pos_set_key_handler_ispravka_racuna( oBrowse )

   SetKey( Asc( "*" ), {|| pos_ispravi_racun( oBrowse ) } )

   RETURN .T.


FUNCTION pos_unset_key_handler_ispravka_racuna()

   SetKey( Asc ( "*" ), NIL )

   RETURN .F.


STATIC FUNCTION cijena_ok( cijena )

   LOCAL _ret := .T.

   IF LastKey() == K_UP
      RETURN _ret
   ENDIF

   IF cijena == 0
      MsgBeep( "Nepravilan unos cijene, cijena mora biti <> 0 !?" )
      _ret := .F.
   ENDIF

   RETURN _ret


STATIC FUNCTION KolicinaOK( nKolicina )

   LOCAL lOk := .F.
   LOCAL _msg
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

      _msg := "Artikal: " + _idroba + " Trenutno na stanju: " + Str( nStanjeRobe, 12, 2 )

      IF gPratiStanje = "!"
         _msg += "#Unos artikla onemogućen !?"
         lOk := .F.
      ENDIF

      MsgBeep( _msg )

   ENDIF

   RETURN lOk



STATIC FUNCTION NarProvDuple()

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



FUNCTION pos_ispravi_racun( oBrowse )

   LOCAL cGetId
   LOCAL nGetKol
   LOCAL aConds
   LOCAL aProcs

   pos_unset_key_handler_ispravka_racuna()

   prikaz_dostupnih_opcija( { "<Enter>-Ispravi stavku", hb_UTF8ToStr( "<B>-Briši stavku" ), hb_UTF8ToStr( "<Esc>-Završi" ) } )

   oBrowse:autolite := .T.
   oBrowse:configure()

   cGetId := _idroba
   nGetKol := _Kolicina

   aConds := { {| Ch | Upper( Chr( Ch ) ) == "B" }, {| Ch | Ch == K_ENTER } }
   aProcs := { {|| pos_brisi_stavku_racuna( oBrowse ) }, {|| pos_ispravi_stavku_racuna( oBrowse ) } }

   ShowBrowse( oBrowse, aConds, aProcs )

   oBrowse:autolite := .F.
   oBrowse:dehilite()
   oBrowse:stabilize()

   Prozor0()

   _idroba := cGetId
   _kolicina := nGetKol

   pos_set_key_handler_ispravka_racuna( oBrowse )

   RETURN .T.


STATIC FUNCTION pos_unos_show_total( iznos, popust, row )

   @ box_x_koord() + row + 0, box_y_koord() + ( f18_max_cols() - 12 ) SAY iznos PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + row + 1, box_y_koord() + ( f18_max_cols() - 12 ) SAY popust PICT "99999.99" COLOR f18_color_invert()
   @ box_x_koord() + row + 2, box_y_koord() + ( f18_max_cols() - 12 ) SAY iznos - popust PICT "99999.99" COLOR f18_color_invert()

   RETURN .T.



FUNCTION pos_brisi_stavku_racuna( oBrowse )

   SELECT _pos_pripr

   IF RecCount2() == 0
      MsgBeep ( "Priprema računa je prazna !#Brisanje nije moguće !", 20 )
      RETURN ( DE_REFRESH )
   ENDIF

   Beep ( 2 )

   nIznNar -= _pos_pripr->kolicina * _pos_pripr->cijena
   nPopust -= _pos_pripr->kolicina * _pos_pripr->ncijena

   pos_unos_show_total( nIznNar, nPopust, box_x_koord() + 2 )
   ispisi_iznos_veliki_brojevi( ( nIznNar - nPopust ), box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )

   my_delete()

   oBrowse:refreshAll()

   DO WHILE !oBrowse:stable
      oBrowse:Stabilize()
   ENDDO

   RETURN ( DE_REFRESH )



FUNCTION pos_ispravi_stavku_racuna(oBrowse)

   LOCAL GetList := {}

   SELECT _pos_pripr

   IF RecCount2() == 0
      MsgBeep ( "Račun ne sadrži niti jednu stavku!#Ispravka nije moguća!", 20 )
      RETURN ( DE_CONT )
   ENDIF

   Scatter()

   SET CURSOR ON

   BOX (, 3, 75 )

   @ box_x_koord() + 1, box_y_koord() + 4 SAY8 "    Artikal:" GET _idroba PICTURE PICT_POS_ARTIKAL VALID pos_postoji_roba( @_idroba, 1, 27 ) .AND. ( _IdRoba == _pos_pripr->IdRoba .OR. NarProvDuple () )
   @ box_x_koord() + 2, box_y_koord() + 3 SAY8 "     Cijena:" GET _Cijena  PICTURE "99999.999" WHEN roba->tip == "T"
   @ box_x_koord() + 3, box_y_koord() + 3 SAY8 "   količina:" GET _Kolicina VALID KolicinaOK ( _Kolicina )

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
         _idodj := Space( 2 )

         nIznNar += ( _cijena * _kolicina ) - cijena * kolicina
         nPopust += ( _ncijena * _kolicina )  - ncijena * kolicina

         my_rlock()
         Gather()
         my_unlock()

      ENDIF

      IF ( _pos_pripr->Kolicina <> _Kolicina )
         nIznNar += ( _cijena * _kolicina ) - cijena * kolicina
         nPopust += ( _ncijena * _kolicina ) - ncijena * kolicina
         RREPLACE Kolicina WITH _Kolicina
      ENDIF

   ENDIF

   BoxC()

   pos_unos_show_total( nIznNar, nPopust, box_x_koord() + 2 )
   ispisi_iznos_veliki_brojevi( ( nIznNar - nPopust ), box_x_koord() + ( f18_max_rows() - 12 ), f18_max_cols() - 2 )

   oBrowse:refreshCurrent()

   DO WHILE !oBrowse:stable
      oBrowse:Stabilize()
   ENDDO

   RETURN ( DE_CONT )



FUNCTION GetReader2( oGet, GetList, oMenu, aMsg )

   LOCAL nKey
   LOCAL nRow
   LOCAL nCol

   IF ( GetPreValSC( oGet, aMsg ) )
      oGet:setFocus()
      DO WHILE ( oGet:exitState == GE_NOEXIT )
         IF ( gOcitBarcod .AND. gEntBarCod == "D" )
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
