/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

STATIC aPorezi := {}



FUNCTION kalk_unos_dok_81( hParams )

   LOCAL nX := 5
   LOCAL _kord_x := 0
   LOCAL _unos_left := 40
   LOCAL _use_opis := .F.
   LOCAL _use_rok := .F.
   LOCAL _opis := Space( 300 )
   LOCAL _rok := CToD( "" )
   LOCAL _krabat := NIL

   IF hb_HHasKey( hParams, "opis" )
      _use_opis := .T.
   ENDIF

   IF hb_HHasKey( hParams, "rok" )
      _use_rok := .T.
   ENDIF

   IF _use_opis
      IF !kalk_is_novi_dokument()
         _opis := PadR( hParams[ "opis" ], 300 )
      ENDIF
   ENDIF

   IF _use_rok
      IF !kalk_is_novi_dokument()
         _rok := CToD( AllTrim( hParams[ "rok" ] ) )
      ENDIF
   ENDIF

   __k_val := "N"

   IF nRbr == 1 .AND. kalk_is_novi_dokument()
      _datfaktp := _datdok
   ENDIF

   IF nRbr == 1 .OR. !kalk_is_novi_dokument()

      ++nX
      _kord_x := box_x_koord() + nX

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "DOBAVLJAČ:" GET _IdPartner PICT "@!" ;
         VALID {|| Empty( _IdPartner ) .OR. p_partner( @_IdPartner ), ispisi_naziv_partner( _kord_x - 1, 22, 20 ) }
      @ box_x_koord() + nX, 50 SAY "Broj fakture:" GET _brfaktp
      @ box_x_koord() + nX, Col() + 1 SAY "Datum:" GET _datfaktp

      ++nX
      _kord_x := box_x_koord() + nX

      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto zadužuje:" GET _idkonto VALID {|| P_Konto( @_IdKonto ), ispisi_naziv_konto( _kord_x, 40, 30 ) } PICT "@!"

      // IF gNW <> "X"
      // @ box_x_koord() + nX, box_y_koord() + 42 SAY8 "Zadužuje: " GET _idzaduz PICT "@!" VALID Empty( _idzaduz ) .OR. p_partner( @_idzaduz )
      // ENDIF

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

      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Konto zaduzuje: "
      ?? _idkonto

      // IF gNW <> "X"
      // @  box_x_koord() + nX, box_y_koord() + 42 SAY "Zaduzuje: "
      // ?? _idzaduz
      // ENDIF
      READ
      ESC_RETURN K_ESC

   ENDIF

   nX += 2
   _kord_x := box_x_koord() + nX

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), _kord_x, box_y_koord() + 2, @aPorezi, _idPartner )



   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _idtarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idroba := Left( _idroba, 10 )
   ENDIF

   select_o_tarifa( roba->idtarifa )
   select_o_koncij( _idkonto )
   SELECT kalk_pripr

   _pkonto := _idkonto
   // kalk_dat_poslj_promjene_prod()

   ++nX
   // IF _use_rok
   // @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Datum isteka roka:" GET _rok
   // ENDIF

   IF _use_opis
      @ box_x_koord() + nX, box_y_koord() + 30 SAY8 "Opis:" GET _opis PICT "@S40"
   ENDIF

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina " GET _kolicina PICT PicKol VALID _kolicina <> 0

   IF kalk_is_novi_dokument()
      select_o_koncij( _idkonto )
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
      @ box_x_koord() + nX, Col() + 1 SAY "EUR->" GET __k_val VALID kalk_ulaz_preracun_fakturne_cijene( __k_val ) PICT "@!"
   ENDIF

   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _fcj ;
      PICT PicDEM ;
      VALID {|| SetKey( K_ALT_T, {|| NIL } ), _fcj > 0 } ;
      WHEN VKol()
   @ box_x_koord() + nX, Col() + 1 SAY "*** <ALT+T> unos ukupne FV"


   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2   SAY "Rabat (%):"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _rabat PICT PicDEM ;
      WHEN {|| SetKey( K_ALT_T, {|| _kaskadni_rabat( @_krabat ) } ), .T. } ;
      VALID {|| SetKey( K_ALT_T, {|| NIL } ), .T. }
   @ box_x_koord() + nX, Col() + 1 SAY "*** <ALT+T> unos kaskadnog rabata"

/*
   IF gNW <> "X"
      ++ nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Transport. kalo:"
      @ box_x_koord() + nX, box_y_koord() + _unos_left GET _gkolicina PICT PicKol
      ++ nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "    Ostalo kalo:"
      @ box_x_koord() + nX, box_y_koord() + _unos_left GET _gkolicin2 PICT PicKol
   ENDIF
*/
   READ

   ESC_RETURN K_ESC

   _fcj2 := _fcj * ( 1 - _rabat / 100 )

   // setuj hParamsute
   IF _use_opis
      hParams[ "opis" ] := _opis
   ENDIF

   IF _use_rok
      hParams[ "rok" ] := DToC( _rok )
   ENDIF

   obracun_kalkulacija_tip_81_pdv( nX )

   RETURN LastKey()



// ---------------------------------------------
// unos kaskadnog rabata
// ---------------------------------------------
STATIC FUNCTION _kaskadni_rabat( krabat )

   LOCAL _r_1 := 0
   LOCAL _r_2 := 0
   LOCAL _r_3 := 0
   LOCAL _r_4 := 0
   LOCAL _ok := .T.
   PRIVATE GetList := {}

   Box(, 8, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unos kaskadnog rabata:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Rabat 1 (%):" GET _r_1 PICT PicDem
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Rabat 2 (%):" GET _r_2 PICT PicDem
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Rabat 3 (%):" GET _r_3 PICT PicDem
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Rabat 4 (%):" GET _r_4 PICT PicDem
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN _ok
   ENDIF

   _rabat := ( 100 - 100 * ( 1 - _r_1 / 100 ) * ;
      IF( _r_2 > 0, ( 1 - _r_2 / 100 ), 1 ) * ;
      IF( _r_3 > 0, ( 1 - _r_3 / 100 ), 1 ) * ;
      IF( _r_4 > 0, ( 1 - _r_4 / 100 ), 1 ) ;
      )

   RETURN _ok



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


STATIC FUNCTION VKol()

   SetKey( K_ALT_T, {|| _fv_ukupno() } )

   IF _kolicina < 0

      // storno

      nKolS := 0
      nKolZN := 0
      nc1 := nc2 := 0
      dDatNab := CToD( "" )

      IF !Empty( kalk_metoda_nc() )
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, @nKolS, @nKolZN, @nc1, @nc2, @dDatNab )
         @ box_x_koord() + 12, box_y_koord() + 30 SAY "Ukupno na stanju "
         @ box_x_koord() + 12, Col() + 2 SAY nKols PICT pickol
      ENDIF

      IF dDatNab > _DatDok
         Beep( 1 )
         Msg( "Datum nabavke je " + DToC( dDatNab ), 4 )
      ENDIF

      IF nKols < Abs( _kolicina )
         sumnjive_stavke_error()
         error_bar( "KA_" + _idroba + "/" + _idkonto, _idroba + "/" + _idkonto + " kolicina nedovoljna:" + AllTrim( Str( nKols, 12, 3 ) ) )
      ENDIF
      SELECT kalk_pripr
   ENDIF

   RETURN .T.


// --------------------------------------------------------
// 81 - dokument, obracun kalkulacije
// --------------------------------------------------------
STATIC FUNCTION obracun_kalkulacija_tip_81_pdv( x_kord )

   LOCAL cSPom := " (%,A,U,R) "
   LOCAL nX := x_kord + 2
   LOCAL _unos_left := 40
   LOCAL _kord_x
   LOCAL lSaTroskovima := .T.
   PRIVATE getlist := {}
   PRIVATE cProracunMarzeUnaprijed := " "

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
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Raspored troskova kalkulacije ->"
      @ box_x_koord() + nX, box_y_koord() + _unos_left SAY c10T1 + cSPom GET _TPrevoz VALID _TPrevoz $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _Prevoz PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + _unos_left SAY c10T2 + cSPom GET _TBankTr VALID _TBankTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _BankTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + _unos_left SAY c10T3 + cSPom GET _TSpedTr VALID _TSpedTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _SpedTr PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + _unos_left SAY c10T4 + cSPom GET _TCarDaz VALID _TCarDaz $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _CarDaz PICT PicDEM

      ++nX
      @ box_x_koord() + nX, box_y_koord() + _unos_left SAY c10T5 + cSPom GET _TZavTr VALID _TZavTr $ "%AUR" PICT "@!"
      @ box_x_koord() + nX, Col() + 2 GET _ZavTr PICT PicDEM ;
         VALID {|| kalk_when_valid_nc_ulaz(), .T. }

      nX += 2

   ENDIF

   // NC
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CIJENA:"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _nc PICT PicDEM

   // MARZA
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MARZA:" GET _TMarza2 VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _marza2 PICT PicDEM VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"

   // PRODAJNA CIJENA
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PC BEZ PDV:"

   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _mpc PICT PicDEM WHEN W_MPC_( "81", ( cProracunMarzeUnaprijed == "F" ), @aPorezi ) ;
      VALID V_Mpc_( "81", ( cProracunMarzeUnaprijed == "F" ), @aPorezi )

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PDV (%):"
   @ box_x_koord() + nX, Col() + 2 SAY aPorezi[ POR_PPP ] PICTURE "99.99"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PC SA PDV:"

   @ box_x_koord() + nX, box_y_koord() + _unos_left GET _mpcsapp PICT PicDEM ;
      WHEN {|| cProracunMarzeUnaprijed := " ", _Marza2 := 0, .T. } VALID kalk_valid_mpcsapdv( "81", .F., @aPorezi, .T. )

   READ

   ESC_RETURN K_ESC

   select_o_koncij( _idkonto )

   roba_set_mcsapp_na_osnovu_koncij_pozicije( _mpcsapp, .T. )

   SELECT kalk_pripr

   _pkonto := _idkonto
   _mkonto := ""
   _pu_i := "1"
   _mu_i := ""

   nStrana := 3

   RETURN LastKey()
