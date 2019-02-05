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


FUNCTION kalk_get_1_19()

   _DatFaktP := _datdok
   PRIVATE aPorezi := {}

   @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Konto koji zadužuje" GET _IdKonto VALID  P_Konto( @_IdKonto, 21, 5 ) PICT "@!"

   // IF gNW <> "X"
   // @ box_x_koord() + 8, box_y_koord() + 35  SAY "Zaduzuje: "   GET _IdZaduz  PICT "@!" VALID Empty( _idZaduz ) .OR. p_partner( @_IdZaduz, 21, 5 )
   // ENDIF
   READ

   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _idVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )
/*
   IF roba_barkod_pri_unosu()
    --  @ box_x_koord() + 11, box_y_koord() + 2   SAY "Artikal  " GET _IdRoba PICT "@!S10" when {|| _IdRoba := PadR( _idroba, Val( --gDuzSifIni ) ), .T. } VALID VRoba()
   ELSE
    --  @ box_x_koord() + 11, box_y_koord() + 2   SAY "Artikal  " GET _IdRoba PICT "@!" VALID VRoba()
   ENDIF
*/
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC
   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF


   _MKonto := _Idkonto
   //kalk_dat_poslj_promjene_prod()

   select_o_koncij( _idkonto )
   SELECT kalk_pripr  // napuni tarifu

   //kalk_dat_poslj_promjene_prod()
   //DuplRoba()

   dDatNab := CToD( "" )
   IF kalk_is_novi_dokument()
      _Kolicina := 0
   ENDIF

   lGenStavke := .F.
   IF !Empty( kalk_metoda_nc() ) .AND. _TBankTr <> "X"
      MsgO( "Racunam kolicinu u prodavnici" )
      kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, @_kolicina, NIL, NIL, @_nc, @dDatNab )
      MsgC()
   ENDIF

   @ box_x_koord() + 12, box_y_koord() + 2   SAY "Kolicina " GET _Kolicina PICTURE PicKol VALID _kolicina >= 0

   _idpartner := ""

   READ

   nStCj := nNCJ := 0

   IF kalk_is_novi_dokument()
      select_o_koncij( _idkonto )
      nStCj := Round( kalk_get_mpc_by_koncij_pravilo(), 3 )
   ELSE
      nStCj := _fcj
   ENDIF

   _PKonto := _Idkonto
   _PU_I := "3"

   IF kalk_is_novi_dokument() .AND.  dozvoljeno_azuriranje_sumnjivih_stavki()
      kalk_fakticka_mpc( @nStCj, _idfirma, _pkonto, _idroba )
   ENDIF

   set_pdv_public_vars()
   SELECT kalk_pripr

   nNCJ := nStCj + _MPCSaPP

   @ box_x_koord() + 16, box_y_koord() + 2  SAY "STARA CIJENA " + "(MPCSAPDV):"
   @ box_x_koord() + 16, box_y_koord() + 50 GET nStCj    PICT "999999.9999"
   @ box_x_koord() + 17, box_y_koord() + 2  SAY "NOVA CIJENA  " +  "(MPCSAPDV):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET nNCj     PICT "999999.9999"

   kalk_say_pdv_a_porezi_var( 19 )

   READ
   ESC_RETURN K_ESC

   _MPCSaPP := nNCj - nStCj
   _MPC := 0
   _fcj := nStCj

   _mpc := MpcBezPor( nNCj, aPorezi, , _nc ) -MpcBezPor( nStCj, aPorezi, , _nc )

   IF Pitanje(, "Staviti u šifrarnik novu cijenu", gDefNiv ) == "D"
      select_o_koncij( _idkonto )
    //  SELECT roba
      roba_set_mcsapp_na_osnovu_koncij_pozicije( _fcj + _mpcsapp )
      SELECT kalk_pripr
   ENDIF

   nKalkStrana := 3
   _VPC := 0
   _GKolicina := _GKolicin2 := 0
   _Marza2 := 0
   _TMarza2 := "A"

   _MKonto := ""
   _MU_I := ""

   RETURN LastKey()
