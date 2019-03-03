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

STATIC s_cKonverzijaValuteDN := "N"

MEMVAR nKalkRBr
MEMVAR GetList
MEMVAR _idroba, _kolicina, _pkonto, _idkonto2, _brfaktp, _datfaktp

FUNCTION kalk_unos_dok_81( hParams )

   LOCAL nX := 5
   LOCAL nKoordX := 0
   LOCAL nY := 40

   // LOCAL _use_opis := .F.
   // LOCAL _opis := Space( 300 )
   LOCAL _krabat := NIL

   IF hb_HHasKey( hParams, "opis" )
      _use_opis := .T.
   ENDIF

   // IF _use_opis
   // IF !kalk_is_novi_dokument()
   // _opis := PadR( hParams[ "opis" ], 300 )
   // ENDIF
   // ENDIF

   IF Empty( _pkonto )
      _pkonto := _idkonto2
      _idkonto2 := ""
   ENDIF

   s_cKonverzijaValuteDN := "N"

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _datfaktp := _datdok
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()

      ++nX
      nKoordX := box_x_koord() + nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "DOBAVLJAČ:" GET _IdPartner PICT "@!" ;
         VALID {|| Empty( _IdPartner ) .OR. p_partner( @_IdPartner ), ispisi_naziv_partner( nKoordX - 1, 22, 20 ) }
      @ box_x_koord() + nX, 50 SAY "Broj fakture:" GET _brfaktp
      @ box_x_koord() + nX, Col() + 1 SAY "Datum:" GET _datfaktp

      ++nX
      nKoordX := box_x_koord() + nX

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto zadužuje:" GET _pkonto VALID {|| P_Konto( @_pkonto ), ispisi_naziv_konto( nKoordX, 40, 30 ) } PICT "@!"
      READ

      ESC_RETURN K_ESC

   ELSE

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "DOBAVLJAČ: "
      ?? _idpartner
      @  box_x_koord() + nX, Col() + 1 SAY "Faktura broj: "
      ?? _brfaktp
      @  box_x_koord() + nX, Col() + 1 SAY "Datum: "
      ?? _datfaktp

      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto zadužuje: "
      ?? _pkonto

      READ
      ESC_RETURN K_ESC

   ENDIF

   nX += 2
   nKoordX := box_x_koord() + nX

   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), nKoordX, box_y_koord() + 2, _idPartner )
   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _idtarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idroba := Left( _idroba, 10 )
   ENDIF

   select_o_tarifa( roba->idtarifa )
   select_o_koncij( _pkonto )
   SELECT kalk_pripr

   // ++nX
   // IF _use_opis
   // @ box_x_koord() + nX, box_y_koord() + 30 SAY8 "Opis:" GET _opis PICT "@S40"
   // ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina " GET _kolicina PICT PicKol VALID _kolicina <> 0

   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      select_o_roba(  _idroba )
      _mpcsapp := kalk_get_mpc_by_koncij_pravilo()
      _TMarza2 := "%"
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Fakturna cijena:"

   IF is_kalk_konverzija_valute_na_unosu()
      @ box_x_koord() + nX, Col() + 1 SAY "EUR->" GET s_cKonverzijaValuteDN VALID kalk_ulaz_preracun_fakturne_cijene( s_cKonverzijaValuteDN ) PICT "@!"
   ENDIF

   @ box_x_koord() + nX, box_y_koord() + nY GET _fcj PICT PicDEM VALID {|| SetKey( K_ALT_T, {|| NIL } ), _fcj > 0 } WHEN valid_kolicina()
   @ box_x_koord() + nX, Col() + 1 SAY "*** <ALT+T> unos ukupne FV"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2   SAY "Rabat (%):"
   @ box_x_koord() + nX, box_y_koord() + nY GET _rabat PICT PicDEM
   READ

   ESC_RETURN K_ESC

   _fcj2 := _fcj * ( 1 - _rabat / 100 )

   obracun_kalkulacija_tip_81_pdv( nX )

   RETURN LastKey()



// ---------------------------------------------
// unos ukupne fakturne vrijednosti
// ---------------------------------------------
STATIC FUNCTION _fv_ukupno()

   LOCAL _uk_fv := 0
   LOCAL _ok := .T.
   PRIVATE GetList := {}

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ukupna FV:" GET _uk_fv PICT PicDem
   READ
   BoxC()

   IF LastKey() == K_ESC .OR. Round( _uk_fv, 2 ) == 0
      RETURN _ok
   ENDIF
   _fcj := ( _uk_fv / _kolicina )

   RETURN _ok


STATIC FUNCTION valid_kolicina()

   SetKey( K_ALT_T, {|| _fv_ukupno() } )

   IF _kolicina < 0

      nKolicinaNaStanju := 0
      nKolZN := 0
      nC1 := nC2 := 0
      IF !Empty( kalk_metoda_nc() )
         kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, @nKolZN, @nc1, @nc2 )
         @ box_x_koord() + 12, box_y_koord() + 30 SAY "Ukupno na stanju "
         @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol
      ENDIF

      IF nKolicinaNaStanju < Abs( _kolicina )
         sumnjive_stavke_error()
         error_bar( "KA_" + _idroba + "/" + _pkonto, _idroba + "/" + _pkonto + " kolicina nedovoljna:" + AllTrim( Str( nKolicinaNaStanju, 12, 3 ) ) )
      ENDIF
      SELECT kalk_pripr
   ENDIF

   RETURN .T.


STATIC FUNCTION obracun_kalkulacija_tip_81_pdv( nX )

   LOCAL cSPom := " (%,A,U,R) "
   LOCAL nY := 40
   LOCAL nKoordX
   LOCAL lSaTroskovima := .T.
   PRIVATE getlist := {}
   PRIVATE cProracunMarzeUnaprijed := " "

   nX += 2
   IF Empty( _TPrevoz )
      _TPrevoz := "%"
   ENDIF
   IF Empty( _TCarDaz ); _TCarDaz := "%"; ENDIF
   IF Empty( _TBankTr ); _TBankTr := "%"; ENDIF
   IF Empty( _TSpedTr ); _TSpedtr := "%"; ENDIF
   IF Empty( _TZavTr );  _TZavTr := "%" ; ENDIF
   IF Empty( _TMarza );  _TMarza := "%" ; ENDIF

   IF lSaTroskovima == .T.
      // TROSKOVNIK
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Raspored troškova kalkulacije ->"
      @ box_x_koord() + nX, box_y_koord() + nY SAY c10T1 + cSPom GET _TPrevoz VALID _TPrevoz $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _Prevoz PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nY SAY c10T2 + cSPom GET _TBankTr VALID _TBankTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _BankTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nY SAY c10T3 + cSPom GET _TSpedTr VALID _TSpedTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _SpedTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nY SAY c10T4 + cSPom GET _TCarDaz VALID _TCarDaz $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _CarDaz PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + nY SAY c10T5 + cSPom GET _TZavTr VALID _TZavTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _ZavTr PICT PicDEM ;
         VALID {|| kalk_when_valid_nc_ulaz(), .T. }
      nX += 2

   ENDIF

   // NC
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CIJENA:"
   @ box_x_koord() + nX, box_y_koord() + nY GET _nc PICT PicDEM

   // MARZA
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MARZA:" GET _TMarza2 VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + nY GET _marza2 PICT PicDEM VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"

   // PRODAJNA CIJENA
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PC BEZ PDV:"
   @ box_x_koord() + nX, box_y_koord() + nY GET _mpc PICT PicDEM WHEN kalk_when_mpc_bez_pdv_80_81_41_42( "81", ( cProracunMarzeUnaprijed == "F" ) ) ;
      VALID kalk_valid_mpc_bez_pdv_80_81_41_42( "81", ( cProracunMarzeUnaprijed == "F" ) )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PDV (%):"
   @ box_x_koord() + nX, Col() + 2 SAY pdv_procenat_by_tarifa( _idtarifa ) * 100 PICTURE "99.99"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PC SA PDV:"
   @ box_x_koord() + nX, box_y_koord() + nY GET _mpcsapp PICT PicDEM ;
      WHEN {|| cProracunMarzeUnaprijed := " ", _Marza2 := 0, .T. } VALID kalk_valid_mpc_sa_pdv_41_42_81( _idvd, .F., .T. )

   READ

   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _mpcsapp, .T. )

   SELECT kalk_pripr

   _mkonto := ""
   // _idkonto := ""
   _pu_i := "1"
   _mu_i := ""

   nKalkStrana := 3

   RETURN LastKey()
