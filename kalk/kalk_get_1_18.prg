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

STATIC aPorezi := {}

FUNCTION kalk_get_1_18()

   _DatFaktP := _datdok

   @ box_x_koord() + 8, box_y_koord() + 2   SAY "Konto koji zaduzuje" GET _IdKonto VALID  P_Konto( @_IdKonto, 21, 5 ) PICT "@!"
   // IF gNW <> "X"
   // @ box_x_koord() + 8, box_y_koord() + 35  SAY "Zaduzuje: "   GET _IdZaduz  PICT "@!" VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz, 21, 5 )
   // ENDIF
   read
   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"

   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _IdVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )

   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   READ
   ESC_RETURN K_ESC
   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_tarifa( _IdTarifa )
   select_o_koncij( _idkonto )
   SELECT kalk_pripr  // napuni tarifu

   _MKonto := _Idkonto

   IF kalk_is_novi_dokument()
      _Kolicina := 0
   ENDIF

   IF !Empty( kalk_metoda_nc() ) .AND. _TBankTr <> "X"
      IF gKolicFakt == "D"
         KalkNaF( _idroba, @_kolicina )
      ELSE
         kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _idkonto, @_kolicina, NIL, NIL, NIL )
      ENDIF

   ENDIF
   @ box_x_koord() + 12, box_y_koord() + 2   SAY8 "Količina " GET _Kolicina PICTURE PicKol VALID _kolicina > 0

   IF kalk_is_novi_dokument() .AND. gMagacin == "2" .AND. _TBankTr <> "X"
      nKalkStaraCijena := KoncijVPC()
   ELSE
      nKalkStaraCijena := _MPCSAPP
   ENDIF

   IF kalk_is_novi_dokument()
      nKalkNovaCijena := 0
   ELSE
      nKalkNovaCijena := _VPC + nKalkStaraCijena
   ENDIF

   IF roba->tip = "X"
      MsgBeep( "Za robu tipa X ne rade se nivelacije" )
   ENDIF


  cNaziv := "VPC"

   IF gmagacin == "1"
      cNaziv := "NC"
   ENDIF
   @ box_x_koord() + 17, box_y_koord() + 2    SAY "STARA CIJENA  (" + cNaziv + ") :"  GET nKalkStaraCijena  PICTURE PicDEM
   @ box_x_koord() + 18, box_y_koord() + 2    SAY "NOVA CIJENA   (" + cNaziv + ") :"  GET nKalkNovaCijena   PICTURE PicDEM

   IF gcMpcKalk10 == "D"
      PRIVATE _MPCPom := 0
      @ box_x_koord() + 18, box_y_koord() + 42    SAY "NOVA CIJENA  MPC :"  GET _mpcpom   PICTURE PicDEM ;
         valid {|| nKalkNovaCijena := iif( nKalkNovaCijena = 0, Round( _mpcpom / ( 1 + TARIFA->opp / 100 ) / ( 1 + TARIFA->PPP / 100 ), 2 ), nKalkNovaCijena ), .T. }
   ENDIF

   READ
   ESC_RETURN K_ESC

   IF _TBankTr <> "X"

      //SELECT roba
      kalk_set_vpc_sifarnik( nKalkNovaCijena )

      SELECT kalk_pripr
   ENDIF


   IF gcMpcKalk10 == "D"
      IF ( roba->mpc == 0 .OR. roba->mpc <> Round( _mpcpom, 2 ) ) .AND. Round( _mpcpom, 2 ) <> 0 .AND. Pitanje(, "Staviti MPC u šifarnik" ) == "D"
         SELECT roba
         hRec := dbf_get_rec()
         hRec[ "mpc" ] := _mpcpom
         update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
         SELECT kalk_pripr
      ENDIF
   ENDIF

   IF roba->tip $ "VK"
      _VPC := ( nKalkNovaCijena - nKalkStaraCijena )
      _MPCSAPP := nKalkStaraCijena
   ELSE
      _VPC := nKalkNovaCijena - nKalkStaraCijena
      _MPCSAPP := nKalkStaraCijena
   ENDIF

   _idpartner := ""
   _rabat := prevoz := prevoz2 := _banktr := _spedtr := _zavtr := _nc := _marza := _marza2 := _mpc := 0
   _gkolicina := _gkolicin2 := _mpc := 0

   _MKonto := _Idkonto
   _MU_I := "3"
   _PKonto := ""
   _PU_I := ""

   nKalkStrana := 3

   RETURN LastKey()
