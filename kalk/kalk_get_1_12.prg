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

FUNCTION kalk_get_1_12()

   LOCAL lRet

   pIzgSt := .F.   // izgenerisane stavke jos ne postoje
   PRIVATE aPorezi := {}

   _GKolicina := _GKolicin2 := 0
   _IdPartner := ""
   IF nRbr == 1 .OR. !kalk_is_novi_dokument()
      @ box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj:" GET _BrFaktP
      @ box_x_koord() + 6, Col() + 2 SAY "Datum:" GET _DatFaktP
      _DatFaktP := _datdok

      @ box_x_koord() + 8, box_y_koord() + 2   SAY "Prodavnicki konto razduzuje " GET _IdKonto VALID P_Konto( @_IdKonto, 21, 5 ) PICT "@!"

      // IF gNW <> "X"
      // @ box_x_koord() + 8, box_y_koord() + 40  SAY "Razduzuje "   GET _IdZaduz  PICT "@!" VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz, 21, 5 )
      // ENDIF

      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto zadužuje   "  GET _IdKonto2 VALID Empty( _IdKonto2 ) .OR. P_Konto( @_IdKonto2, 24 )
      // IF gNW <> "X"
      // @ box_x_koord() + 9, box_y_koord() + 40  SAY "Zaduzuje  " GET _IdZaduz2   PICT "@!"  VALID Empty( _idZaduz2 ) .OR. p_partner( @_IdZaduz2, 21, 5 )
      // ENDIF
      READ
      ESC_RETURN K_ESC
   ELSE
      @ box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj: "; ?? _BrFaktP
      @ box_x_koord() + 6, Col() + 2 SAY "Datum: "; ??  _DatFaktP
      @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Prodavnicki konto razdužuje "; ?? _IdKonto
      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto zadužuje   "; ?? _IdKonto2
   ENDIF
   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )
   /*
   IF roba_barkod_pri_unosu()
    --  @ box_x_koord() + 11, box_y_koord() + 2   SAY "Artikal  " GET _IdRoba PICT "@!S10" when {|| _IdRoba := PadR( _idroba, Val( --gDuzSifIni ) ), .T. } VALID VRoba()
   ELSE
    --  @ box_x_koord() + 11, box_y_koord() + 2   SAY "Artikal  " GET _IdRoba PICT "@!" VALID VRoba()
   ENDIF
   */

   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   @ box_x_koord() + 12, box_y_koord() + 2   SAY "Kolicina " GET _Kolicina PICTURE PicKol VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_koncij( _idkonto )
   SELECT kalk_pripr

   _PKonto := _Idkonto
   _MKonto := _Idkonto2
   // kalk_dat_poslj_promjene_prod()
   // check_datum_posljednje_kalkulacije()
   // DuplRoba()

   _GKolicina := 0

   IF kalk_is_novi_dokument()
      select_o_koncij( _idkonto )
      select_o_roba( _IdRoba )

      _MPCSaPP := kalk_get_mpc_by_koncij_pravilo()

      _FCJ := NC
      _VPC := NC

      SELECT kalk_pripr
      _Marza2 := 0
      _TMarza2 := "A"
   ENDIF

   IF nije_dozvoljeno_azuriranje_sumnjivih_stavki()
      kalk_fakticka_mpc( @_Mpcsapp, _idfirma, _pkonto, _idroba )
      kalk_vpc_po_kartici( @_VPC, _idfirma, _mkonto, _idroba )
   ENDIF

   set_pdv_public_vars()
   nKolS := 0
   nKolZN := 0
   nc1 := nc2 := 0
   dDatNab := CToD( "" )
   lGenStavke := .F.

   IF _TBankTr <> "X"
      IF !Empty( kalk_metoda_nc() )
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, @nKolS, @nKolZN, @nc1, @nc2, dDatNab )
         IF dDatNab > _DatDok
            Beep( 1 )
            Msg( "Datum nabavke je " + DToC( dDatNab ), 4 )
         ENDIF
         IF kalk_metoda_nc() $ "13"; _fcj := nc1; ELSEIF kalk_metoda_nc() == "2"; _fcj := nc2; ENDIF
      ENDIF
   ENDIF

   @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "; @ box_x_koord() + 12, Col() + 2 SAY nkols PICT pickol
   @ box_x_koord() + 14, box_y_koord() + 2    SAY "NABAVNA CIJENA (NC)         :"
   @ box_x_koord() + 14, box_y_koord() + 50   GET _FCJ    PICTURE PicDEM VALID {|| lRet := kalk_valid_kolicina_prod(), _vpc := _fcj, lRet }


   _TPrevoz := "R"

   @ box_x_koord() + 16, box_y_koord() + 2  SAY8 "MP marža:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICTURE "@!"
   @ box_x_koord() + 16, Col() + 1  GET _Marza2 PICTURE  PicDEM ;
      VALID {|| _nc := _fcj + iif( _TPrevoz == "A", _Prevoz, 0 ), _Tmarza := "A", _marza := _vpc / ( 1 + _PORVT ) - _fcj, .T. }
   @ box_x_koord() + 17, box_y_koord() + 2  SAY "MALOPROD. CJENA (MPC):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET _MPC PICT PicDEM WHEN WMpc() VALID VMpc()

   kalk_say_pdv_a_porezi_var( 19 )

   @ box_x_koord() + 19, box_y_koord() + 2 SAY "MPC SA PDV    :"
   @ box_x_koord() + 19, box_y_koord() + 50 GET _MPCSaPP PICT PicDEM VALID VMpcSaPP()

   READ

   ESC_RETURN K_ESC

   nStrana := 2

   _MKonto := _Idkonto2
   _MU_I := "1"
   _PKonto := _Idkonto
   _PU_I := "5"

   kalk_puni_polja_za_izgenerisane_stavke( pIzgSt )

   RETURN LastKey()
