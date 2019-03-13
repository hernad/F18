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

MEMVAR gPopustMaloprodajaPrekoProcentaIliCijene
MEMVAR nKalkStrana
MEMVAR _pkonto, _idkonto2
MEMVAR GetList
MEMVAR _idfirma, _fcj, _datdok, _idvd, _idpartner, _brfaktp, _datfaktp, _idtarifa, _idroba, _pu_i, _kolicina, _tbanktr, _mpcsapp, _mpc
MEMVAR _TMarza2, _Marza2
MEMVAR _rabatv  // popust u maloprodaji
MEMVAR _TPrevoz, _Prevoz, _nc

FUNCTION kalk_get_1_41_42_49()

   LOCAL lRet
   LOCAL nKolicinaNaStanju
   LOCAL nKolicinaPriZadnjojNabavci
   LOCAL nNabCjenaPriZadnjojNabavci
   LOCAL nNabCjSrednja
   LOCAL nMpcBezPDVBruto
   LOCAL cPopustPrekoProcentaIliCijene := gPopustMaloprodajaPrekoProcentaIliCijene

   IF Empty( _pkonto )
      _pkonto := _idkonto2
   ENDIF

   IF kalk_is_novi_dokument()
      _DatFaktP := _datdok
   ENDIF
   IF _idvd == "41"
      @  box_x_koord() + 6,  box_y_koord() + 2 SAY "KUPAC:" GET _IdPartner PICT "@!" VALID Empty( _IdPartner ) .OR. p_partner( @_IdPartner, 5, 30 )
      @  box_x_koord() + 7,  box_y_koord() + 2 SAY "Faktura Broj:" GET _BrFaktP
      @  box_x_koord() + 7, Col() + 2 SAY "Datum:" GET _DatFaktP
   ELSE
      _idpartner := ""
      _brfaktP := ""
   ENDIF

   @ box_x_koord() + 8, box_y_koord() + 2  SAY8 "Prodavnički Konto razdužuje" GET _pkonto VALID  P_Konto( @_pkonto, 8, 38 ) PICT "@!"
   READ

   SELECT kalk_pripr
   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _idVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2 )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   @ box_x_koord() + 12, box_y_koord() + 2  SAY8 "Količina " GET _Kolicina PICTURE pickol() VALID _Kolicina <> 0

   READ
   ESC_RETURN K_ESC

   // IF roba_barkod_pri_unosu()
   // _idRoba := Left( _idRoba, 10 )
   // ENDIF

   select_o_tarifa( _IdTarifa )
   select_o_koncij( _pkonto )
   SELECT kalk_pripr  // napuni tarifu

   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      select_o_roba( _IdRoba )
      _MPCSaPP := kalk_get_mpc_by_koncij_pravilo()
      _FCJ := kalk_pripr->NC
      SELECT kalk_pripr
      _Marza2 := 0
      _TMarza2 := "A"
   ENDIF

   IF ( dozvoljeno_azuriranje_sumnjivih_stavki() .AND. ( _MpcSAPP == 0 .OR. kalk_is_novi_dokument() ) )
      kalk_mpc_sa_pdv_sa_kartice( @_MPCSAPP, _idfirma, _pkonto, _idroba )
   ENDIF

   IF ( roba->tip != "T" )
      nKolicinaNaStanju := 0
      nKolicinaPriZadnjojNabavci := 0
      nNabCjenaPriZadnjojNabavci := 0
      nNabCjSrednja := 0
      // ako je X onda su stavke vec izgenerisane
      IF _TBankTr <> "X"
         IF !Empty( kalk_metoda_nc() )
            nNabCjenaPriZadnjojNabavci := 0
            nNabCjSrednja := 0
            kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, @nKolicinaPriZadnjojNabavci, @nNabCjenaPriZadnjojNabavci, @nNabCjSrednja )
            // IF kalk_metoda_nc() $ "13"
            // _fcj := nNabCjenaPriZadnjojNabavci
            IF kalk_metoda_nc() == "2"
               _fcj := nNabCjSrednja
            ENDIF
         ENDIF
      ENDIF

      @ box_x_koord() + 12, box_y_koord() + 30 SAY "Ukupno na stanju "
      @ box_x_koord() + 12, Col() + 2 SAY nKolicinaNaStanju PICT pickol()

      @ box_x_koord() + 14, box_y_koord() + 2 SAY "NC  :" GET _fcj PICT picdem() ;
         VALID {|| lRet := kalk_valid_kolicina_prod( nKolicinaNaStanju ), _tprevoz := "A", _prevoz := 0, _nc := _fcj, lRet }

      @ box_x_koord() + 14, box_y_koord() + 35 SAY8 "MP marža:" GET _TMarza2  VALID _TMarza2 $ "%AU" PICTURE "@!"
      @ box_x_koord() + 14, Col() + 1 GET _Marza2 PICTURE  picdem()

   ENDIF

   @ box_x_koord() + 16, box_y_koord() + 2 SAY "MPC bez PDV (bruto) :"
   @ box_x_koord() + 16, box_y_koord() + 50 GET nMpcBezPDVBruto PICT picdem() ;
      WHEN { || nMpcBezPDVBruto := _mpc + _rabatv, .F. }

   @ box_x_koord() + 17, box_y_koord() + 2 SAY "POPUST (C-CIJENA,P-%):" GET cPopustPrekoProcentaIliCijene VALID cPopustPrekoProcentaIliCijene $ "CP" PICT "@!"
   @ box_x_koord() + 17, box_y_koord() + 50 GET _Rabatv PICT picdem() VALID kalk_42_rabat_procenat_to_cijena( @cPopustPrekoProcentaIliCijene, nMpcBezPDVBruto )

   @ box_x_koord() + 18, box_y_koord() + 2 SAY "MPC bez PDV (neto)  :"
   @ box_x_koord() + 18, box_y_koord() + 50 GET _mpc PICT picdem() ;
      WHEN kalk_when_mpc_bez_pdv_80_81_41_42( IdVd, .F. ) ;
      VALID kalk_valid_mpc_bez_pdv_80_81_41_42( _IdVd, .F. )

   kalk_say_pdv_a_porezi_var( 19 )
   @ box_x_koord() + 20, box_y_koord() + 2 SAY "MPC SA PDV (bruto) :"
   @ box_x_koord() + 20, box_y_koord() + 50 GET _mpcsapp PICT picdem() VALID kalk_valid_mpc_sa_pdv_41_42_81( _IdVd, .F., .T. )

   READ
   ESC_RETURN K_ESC

   _PU_I := "5"
   nKalkStrana := 2

   RETURN LastKey()


STATIC FUNCTION kalk_42_rabat_procenat_to_cijena( cPopustPrekoProcentaIliCijene, nMpcBezPDVBruto )

   IF cPopustPrekoProcentaIliCijene == "P"
      _rabatv := nMpcBezPDVBruto * _rabatv / 100
      cPopustPrekoProcentaIliCijene := "C"
      ShowGets()
   ENDIF

   RETURN .T.
