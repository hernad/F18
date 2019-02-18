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

FUNCTION kalk_get_1_12()

   LOCAL lRet
   LOCAL nKolicinaNaStanju
   LOCAL nKolicinaZadnjeNabavke
   LOCAL nNcjZadnjaNabavka
   LOCAL nNcjSrednja

   _GKolicina := _GKolicin2 := 0
   _IdPartner := ""
   IF nKalkRbr == 1 .OR. !kalk_is_novi_dokument()
      @ box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj:" GET _BrFaktP
      @ box_x_koord() + 6, Col() + 2 SAY "Datum:" GET _DatFaktP
      _DatFaktP := _datdok

      @ box_x_koord() + 8, box_y_koord() + 2   SAY "Prodavnicki konto razduzuje " GET _IdKonto VALID P_Konto( @_IdKonto, 21, 5 ) PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto zadužuje   "  GET _IdKonto2 VALID Empty( _IdKonto2 ) .OR. P_Konto( @_IdKonto2, 24 )
      READ
      ESC_RETURN K_ESC
   ELSE
      @ box_x_koord() + 6, box_y_koord() + 2   SAY "Otpremnica - Broj: "; ?? _BrFaktP
      @ box_x_koord() + 6, Col() + 2 SAY "Datum: "; ??  _DatFaktP
      @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Prodavnicki konto razdužuje "; ?? _IdKonto
      @ box_x_koord() + 9, box_y_koord() + 2   SAY8 "Magacinski konto zadužuje   "; ?? _IdKonto2
   ENDIF
   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"

   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2 )
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

   nKolicinaNaStanju := 0
   nKolicinaZadnjeNabavke := 0
   nNcjZadnjaNabavka := nNcjSrednja := 0

   IF _TBankTr <> "X"
      IF !Empty( kalk_metoda_nc() )
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, @nKolicinaNaStanju, @nKolicinaZadnjeNabavke, @nNcjZadnjaNabavka, @nNcjSrednja )
         //IF kalk_metoda_nc() $ "13"; _fcj := nNcjZadnjaNabavka; ELSE
         IF kalk_metoda_nc() == "2"
           _fcj := nNcjSrednja
         ENDIF
      ENDIF
   ENDIF

   @ box_x_koord() + 12, box_y_koord() + 30   SAY "Ukupno na stanju "; @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol
   @ box_x_koord() + 14, box_y_koord() + 2    SAY "NABAVNA CIJENA (NC)         :"
   @ box_x_koord() + 14, box_y_koord() + 50   GET _FCJ    PICTURE PicDEM VALID {|| lRet := kalk_valid_kolicina_prod(nKolicinaNaStanju), _vpc := _fcj, lRet }

   _TPrevoz := "R"
   @ box_x_koord() + 16, box_y_koord() + 2  SAY8 "MP marža:" GET _TMarza2  VALID _Tmarza2 $ "%AU" PICTURE "@!"
   @ box_x_koord() + 16, Col() + 1  GET _Marza2 PICTURE  PicDEM ;
      VALID {|| _nc := _fcj + iif( _TPrevoz == "A", _Prevoz, 0 ), _Tmarza := "A", _marza := _vpc - _fcj, .T. }
   @ box_x_koord() + 17, box_y_koord() + 2  SAY "MALOPROD. CJENA (MPC):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET _MPC PICT PicDEM ;
      WHEN kalk_when_mpc_bez_pdv_11_12() VALID kalk_valid_mpc_bez_pdv_11_12()

   kalk_say_pdv_a_porezi_var( 19 )

   @ box_x_koord() + 19, box_y_koord() + 2 SAY "MPC SA PDV    :"
   @ box_x_koord() + 19, box_y_koord() + 50 GET _MPCSaPP PICT PicDEM VALID kalk_valid_mpc_sa_pdv_11( NIL, _IdTarifa)

   READ

   ESC_RETURN K_ESC

   nKalkStrana := 2

   _MKonto := _Idkonto2
   _MU_I := "1"
   _PKonto := _Idkonto
   _PU_I := "5"

   //kalk_puni_polja_za_izgenerisane_stavke( lKalkIzgenerisaneStavke )

   RETURN LastKey()
