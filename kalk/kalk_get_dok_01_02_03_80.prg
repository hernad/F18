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

MEMVAR nKalkStrana
MEMVAR nKalkMpvSaPDV80PredhodnaStavka, nKalkNVPredhodnaStavka
MEMVAR nKalkRBr
MEMVAR GetList
MEMVAR _idfirma, _kolicina, _nc, _idroba, _pkonto, _pu_i, _mkonto, _mu_i, _datfaktp, _datdok
MEMVAR _idtarifa, _idvd, _idkonto2, _brfaktp, _mpcsapp
MEMVAR _Vpc, _Mpc, _TMarza2, _Marza2, _TCarDaz, _CarDaz, _dat_od, _dat_do

FUNCTION kalk_get1_01_02_03_80()

   LOCAL nX := 5
   LOCAL nXCurrent := 0
   LOCAL nYCurrent := 40
   PRIVATE cProracunMarzeUnaprijed := " "

   _dat_od := CToD( "" )
   _dat_do := CToD( "" )

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _DatFaktP := _datdok
      _pkonto := _idkonto2
      _idkonto2 := Space( FIELD_LEN_KONTO_ID )
   ENDIF

   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()
      nXCurrent := box_x_koord() + nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Temeljnica:" GET _BrFaktP
      @ box_x_koord() + nX, Col() + 1 SAY "Datum:" GET _DatFaktP
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prodavnički konto: " GET _pkonto VALID {|| P_Konto( @_pkonto ), ispisi_naziv_konto( nXCurrent - 1, 35, 30 ) } PICT "@!"
      ++nX
      IF _IdVd <> POS_IDVD_POCETNO_STANJE_PRODAVNICA
         nXCurrent := box_x_koord() + nX
         @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  Prenos na konto: " GET _IdKonto2 VALID {|| Empty( _idkonto2 ) .OR. P_Konto( @_IdKonto2 ), ispisi_naziv_konto( nXCurrent, 35, 30 )  } PICT "@!"
      ENDIF
      READ
      ESC_RETURN K_ESC

   ELSE
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Temeljnica: "
      ?? _BrFaktP
      @ box_x_koord() + nX, Col() + 2 SAY "Datum: "
      ?? _DatFaktP
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto zadužuje: "
      ?? _pkonto
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prenos na konto: "
      ?? _IdKonto2
      READ
      ESC_RETURN K_ESC
   ENDIF

   SELECT kalk_pripr

   nX += 2
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + nX, box_y_koord() + 2 )
   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _IdTarifa  VALID P_Tarifa( @_IdTarifa )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Količina " GET _Kolicina PICT pickol()
   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF
   select_o_roba( _idroba )
   select_o_tarifa( roba->idtarifa )
   select_o_koncij( _pkonto )
   SELECT kalk_pripr

   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      select_o_roba( _idroba )
      _mpcsapp := kalk_get_mpc_by_koncij_pravilo()
      _TMarza2 := "%"
      _TCarDaz := "%"
      _CarDaz := 0
   ENDIF

   SELECT kalk_pripr
   nX += 2 // NC
   nXCurrent := box_x_koord() + nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CJENA:"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _nc WHEN kalk_valid_nc_80( nXCurrent - 2 ) PICT picdem()
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "MARŽA:" GET _TMarza2 VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _Marza2 PICT picdem() VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MALOPROD. CIJENA (MPC):"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _mpc PICT picdem();
      WHEN kalk_when_mpc_bez_pdv_80_81_41_42( _idvd, ( cProracunMarzeUnaprijed == "F" ) ) ;
      VALID kalk_valid_mpc_bez_pdv_80_81_41_42( _idvd, ( cProracunMarzeUnaprijed == "F" ) )
   ++nX
   say_pdv_procenat( nX, _idtarifa )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MPC saPDV:"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _MPCSaPP PICT picdem() VALID kalk_valid_mpc_sa_pdv_41_42_81( _idvd, .F., .T. )

   READ
   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _MpcSapp, .T. )
   SELECT kalk_pripr
   IF _IdVd == POS_IDVD_POCETNO_STANJE_PRODAVNICA .OR. _IdVd == POS_IDVD_KOL_PORAVNANJE_PRODAVNICA
      _PU_I := "0"
   ELSE
      _PU_I := "1"
   ENDIF
   _MKonto := ""
   _MU_I := ""
   nKalkStrana := 3

   RETURN LastKey()


// PROTUSTAVKA 80-ka, druga strana
// _odlval nalazi se u knjiz, filuje staru vrijenost
// _odlvalb nalazi se u knjiz, filuje staru vrijenost nabavke
FUNCTION kalk_get_1_80_protustavka()

   LOCAL cSvediCijenaKolicina := fetch_metric( "kalk_dok_80_predispozicija_set_cijena", my_user(), " " )
   LOCAL nX := 2
   LOCAL nXCurrent := 0
   LOCAL nYCurrent := 40
   PRIVATE picdem := "9999999.99999999"

   kalk_is_novi_dokument( .T. )
   pickol( "999999.999" )
   Beep( 1 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "PROTUSTAVKA   ( S - svedi M - mpc sifr i ' ' - ne diraj ):"
   @ box_x_koord() + nX, Col() + 2 GET cSvediCijenaKolicina VALID cSvediCijenaKolicina $ " SM" PICT "@!"
   READ

   set_metric( "kalk_dok_80_predispozicija_set_cijena", my_user(), cSvediCijenaKolicina ) // zapamti zadnji unos
   nX := 12
   nXCurrent := box_x_koord() + nX
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + nX, box_y_koord() + 2 )
   @ box_x_koord() + nX, box_y_koord() + ( f18_max_cols() - 20 ) SAY "Tarifa:" GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   READ
   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   SELECT kalk_pripr
   _pkonto := _pkonto
   PRIVATE cProracunMarzeUnaprijed := " "
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Kolicina " GET _Kolicina PICT pickol() VALID _Kolicina <> 0
   select_o_koncij( _pkonto )
   select_o_roba( _idroba )
   _mpcsapp := kalk_get_mpc_by_koncij_pravilo()
   _TMarza2 := "%"
   _TCarDaz := "%"
   _CarDaz := 0

   SELECT kalk_pripr

   ++nX
   nXCurrent := box_x_koord() + nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "NABAVNA CIJENA:"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _NC PICT picdem() WHEN kalk_valid_nc_80( nXCurrent )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MARZA:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICT "@!"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent  GET _Marza2 PICT picdem() VALID {|| _vpc := _nc, .T. }
   @ box_x_koord() + nX, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2  SAY "MPC BEZ PDV:"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _mpc PICT picdem() WHEN kalk_when_mpc_bez_pdv_80() VALID kalk_valid_mpc_bez_pdv_80()

   ++nX
   say_pdv_procenat( nX, _idtarifa )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "MPC SA PDV:"
   @ box_x_koord() + nX, box_y_koord() + nYCurrent GET _mpcsapp PICT picdem() VALID kalk_valid_mpc_sa_pdv_80_protustavka( cSvediCijenaKolicina )
   READ

   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _mpcsapp, .T. )
   SELECT kalk_pripr
   _PU_I := "1"
   _MKonto := ""
   _MU_I := ""
   nKalkStrana := 3

   RETURN LastKey()


FUNCTION kalk_valid_mpc_sa_pdv_80_protustavka( cSvediCijenaKolicina )

   IF cSvediCijenaKolicina == "M"
      select_o_koncij( _pkonto )
      select_o_roba( _idroba )
      _mpcsapp := kalk_get_mpc_by_koncij_pravilo()

   ELSEIF cSvediCijenaKolicina == "S"
      IF _mpcsapp <> 0
         _kolicina := -Round( nKalkMpvSaPDV80PredhodnaStavka / _mpcsapp, 4 )
      ELSE
         _kolicina := 99999999
      ENDIF

      IF _kolicina <> 0
         _nc := Abs( nKalkNVPredhodnaStavka / _kolicina )
      ELSE
         _nc := 0
      ENDIF
   ENDIF


   IF _mpcsapp <> 0 // .AND. Empty( cProracunMarzeUnaprijed )
      _mpc := mpc_bez_pdv_by_tarifa ( _idtarifa, _mpcsapp )
      _marza2 := 0
      // IF fRealizacija
      // Marza2R()
      // ELSE
      kalk_proracun_marzamp_11_80()
      // ENDIF
      // IF lShowGets
      ShowGets()
      // ENDIF
   ENDIF

   // cProracunMarzeUnaprijed := " "

   RETURN .T.





STATIC FUNCTION kalk_when_mpc_bez_pdv_80()

   IF _MpcSapp <> 0
      _marza2 := 0
      _Mpc := mpc_bez_pdv_by_tarifa( _idtarifa, _MpcSaPP )
   ENDIF

   RETURN .T.



FUNCTION kalk_valid_mpc_bez_pdv_80()

   LOCAL cProracunMarzeUnaprijed := " "

   kalk_proracun_marzamp_11_80( cProracunMarzeUnaprijed )
   IF ( _mpcsapp == 0 )
      _MPCSaPP := Round( mpc_sa_pdv_by_tarifa( _idtarifa, _mpc ), 2 )
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_valid_nc_80( nX )

   LOCAL nNcjSrednja, nNcjZadnjaNabavka
   LOCAL nKolicinaNaStanju, nKolicinaZadnjaNabavka

   IF _kolicina < 0
      nKolicinaNaStanju := 0
      nKolicinaZadnjaNabavka := 0
      nNcjZadnjaNabavka := 0
      nNcjSrednja := 0
      kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, @nKolicinaZadnjaNabavka, @nNcjZadnjaNabavka, @nNcjSrednja )

      @ nX, box_y_koord() + 30 SAY "Ukupno na stanju "
      @ nX, Col() + 2 SAY nKolicinaNaStanju PICT pickol()
      IF _nc == 0
         _nc := nNcjSrednja
      ENDIF
      IF nKolicinaNaStanju < Abs( _kolicina )
         sumnjive_stavke_error()
         error_bar( "KA_" + _pkonto + " / " + _idroba, _pkonto + " / " + _idroba + " kolicina:" + ;
            AllTrim( Str( nKolicinaNaStanju, 12, 3 ) ) +  " treba: " + AllTrim( Str( _kolicina, 12, 3 ) ) )
      ENDIF
      SELECT kalk_pripr
   ENDIF

   RETURN .T.


FUNCTION say_pdv_procenat( nRow, cIdTarifa )

   PushWa()
   select_o_tarifa( cIdTarifa )
   @ box_x_koord() + nRow, box_y_koord() + 2  SAY "PDV (%):"
   @ Row(), Col() + 2 SAY  tarifa->pdv PICTURE "99.99"
   PopWa()

   RETURN .T.
