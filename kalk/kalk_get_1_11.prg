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

MEMVAR nKalkRBr
MEMVAR nKalkStrana, nKalkStaraCijena, nKalkNovaCijena
MEMVAR _IdFirma, _DatFaktP, _IdKonto, _IdKonto2, _kolicina, _idvd, _mkonto, _pkonto, _mpcsapp, _mpc, _nc, _fcj, _idroba, _idtarifa, _datdok
MEMVAR _MU_I, _PU_I, _VPC, _IdPartner
MEMVAR _TBankTr, _Marza2, _TMarza2, _Prevoz, _TPrevoz, _TMarza, _Marza
MEMVAR _BrFaktP

FUNCTION kalk_get_1_11()

   LOCAL lRet
   LOCAL GetList := {}
   LOCAL cProracunMarzeUnaprijed := " "

   // LOCAL lKalkIzgenerisaneStavke
   LOCAL nKolicinaNaStanju
   LOCAL nKolZN
   LOCAL nNcPosljednjegUlaza
   LOCAL nNcSrednja

   IF Empty( _mkonto )
      _MKonto := _Idkonto
   ENDIF
   IF Empty( _pkonto )
      _PKonto := _Idkonto2
   ENDIF
   IF Empty( _datfaktp )
      _datfaktp := _datdok
   ENDIF
   IF Empty( _tmarza2 )
     _tmarza2 := "A"
   ENDIF

   //IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
  //    _DatFaktP := _datdok
   //ENDIF

   IF nKalkRbr == 1  .OR. !kalk_is_novi_dokument()
      _IdPartner := ""
      @  box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj:" GET _BrFaktP
      @  box_x_koord() + 6, Col() + 2 SAY "Datum:" GET _DatFaktP
      @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Prodavnički Konto zadužuje" GET _pkonto VALID  P_Konto( @_pkonto, 8, 40 ) PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto razdužuje"  GET _mkonto VALID Empty( _mkonto ) .OR. P_Konto( @_mkonto, 9, 40 )
      READ
      ESC_RETURN K_ESC
   ELSE
      @  box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj: "; ?? _BrFaktP
      @  box_x_koord() + 6, Col() + 2 SAY "Datum: "; ?? _DatFaktP
      @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Prodavnički Konto zadužuje "; ?? _pkonto
      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto razdužuje "; ?? _mkonto
   ENDIF

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarifa ->"
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2 )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   @ box_x_koord() + 12, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE pickol() VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   SELECT kalk_pripr
   IF kalk_is_novi_dokument()
      _MPCSaPP := kalk_get_mpc_by_koncij_pravilo( _pkonto )
      _FCJ := roba->NC
      _VPC := roba->NC
      SELECT kalk_pripr
      _Marza2 := 0
      _TMarza2 := "A"
   ENDIF

   IF nije_dozvoljeno_azuriranje_sumnjivih_stavki() .OR. Round( _VPC, 3 ) == 0
      select_o_koncij( _mkonto )
      SELECT kalk_pripr
      kalk_vpc_po_kartici( @_VPC, _idfirma, _mkonto, _idroba )
      select_o_koncij( _pkonto )
      SELECT kalk_pripr
   ENDIF

   nKolicinaNaStanju := 0
   nKolZN := 0
   nNcPosljednjegUlaza := 0
   nNcSrednja := 0
   IF _TBankTr <> "X"
      IF !Empty( kalk_metoda_nc() )
         nNcPosljednjegUlaza := nNcSrednja := 0
         IF _kolicina > 0
            kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _mkonto, @nKolicinaNaStanju, @nKolZN, @nNcPosljednjegUlaza, @nNcSrednja )
         ELSE
            kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, @nKolZN, @nNcPosljednjegUlaza, @nNcSrednja )
         ENDIF
         // IF kalk_metoda_nc() $ "13"
         // _fcj := nNcPosljednjegUlaza
         IF kalk_metoda_nc() == "2"
            _fcj := nNcSrednja
         ENDIF
      ENDIF
   ENDIF

   IF _kolicina > 0
      @ box_x_koord() + 12, box_y_koord() + 30   SAY "Na stanju magacin "
      @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol()
   ELSE
      @ box_x_koord() + 12, box_y_koord() + 30   SAY "Na stanju prodavn "
      @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol()
   ENDIF

   select_o_koncij( _mkonto )
   SELECT kalk_pripr

   _vpc := _fcj
   @ box_x_koord() + 14, box_y_koord() + 2  SAY8 "       NABAVNA CIJENA (NC):"
   IF _kolicina > 0
      @ box_x_koord() + 14, box_y_koord() + 50  GET _FCj   PICTURE picnc() VALID {|| lRet := kalk_valid_kolicina_mag( nKolicinaNaStanju ), _vpc := _fcj, lRet }
   ELSE
      @ box_x_koord() + 14, box_y_koord() + 50  GET _FCJ   PICTURE picdem() VALID {|| lRet := kalk_valid_kolicina_prod( nKolicinaNaStanju ), _vpc := _fcj, lRet }
   ENDIF

   select_o_koncij( _pkonto )
   SELECT kalk_pripr
   IF kalk_is_novi_dokument()
      _TPrevoz := "R"
   ENDIF

   @ box_x_koord() + 16, box_y_koord() + 2 SAY8 "MP marza:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICTURE "@!"
   @ box_x_koord() + 16, Col() + 1  GET _Marza2 PICTURE  picdem() ;
      VALID {|| _nc := _fcj + iif( _TPrevoz == "A", _Prevoz, 0 ), _Tmarza := "A", _marza := _vpc - _fcj, .T. }
   @ box_x_koord() + 16, Col() + 1 GET cProracunMarzeUnaprijed PICT "@!"   VALID {|| kalk_proracun_marzamp_11_80( cProracunMarzeUnaprijed ), cProracunMarzeUnaprijed := " ", .T. }

   @ box_x_koord() + 18, box_y_koord() + 2 SAY8 "                MP BEZ PDV:"
   @ box_x_koord() + 18, box_y_koord() + 50 GET _MPC PICTURE picdem() ;
      WHEN kalk_when_mpc_bez_pdv_11_12() ;
      VALID kalk_valid_mpc_bez_pdv_11_12( cProracunMarzeUnaprijed )
   kalk_say_pdv_a_porezi_var( 19 )
   @ box_x_koord() + 20, box_y_koord() + 2 SAY8 "Maloprodajna cijena SA PDV:"
   @ box_x_koord() + 20, box_y_koord() + 50 GET _MPCSaPP  PICTURE picdem() ;
      VALID kalk_valid_mpc_sa_pdv_11( cProracunMarzeUnaprijed, _idTarifa )
   READ

   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   roba_set_mcsapp_na_osnovu_koncij_pozicije( _mpcsapp, .T. )       // .t. znaci sa upitom
   SELECT kalk_pripr

   _IdKonto := _MKonto // izlaz iz magacina
   _MU_I := "5"
   _IdKonto2 := _PKonto  // ulaz u prodavnicu
   _PU_I := "1"

   nKalkStrana := 2
   // kalk_puni_polja_za_izgenerisane_stavke( lKalkIzgenerisaneStavke )

   RETURN LastKey()
