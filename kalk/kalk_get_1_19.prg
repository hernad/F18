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

MEMVAR GetList
MEMVAR nKalkStrana, nKalkStaraCijena, nKalkNovaCijena
MEMVAR _IdFirma, _DatFaktP, _IdKonto, _IdKonto2, _kolicina, _idvd, _mkonto, _pkonto, _mpcsapp, _mpc, _nc, _fcj, _idroba, _idtarifa, _datdok
MEMVAR _MU_I, _PU_I, _VPC, _IdPartner
MEMVAR _TBankTr, _GKolicina, _GKolicin2, _Marza2, _TMarza2
MEMVAR gStavitiUSifarnikNovuCijenuDefault
MEMVAR aPorezi

FUNCTION kalk_get_1_19()

   LOCAL nKolicinaNaStanju

   _DatFaktP := _datdok
   _MKonto := ""
   _IdKonto := ""
   _PKonto := _Idkonto2
   _PU_I := "3"

   PRIVATE aPorezi := {}

   @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Konto koji zadužuje" GET _PKonto VALID  P_Konto( @_PKonto, 8, 30 ) PICT "@!"
   READ
   ESC_RETURN K_ESC

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_pripr_form_get_roba( @GetList, @_idRoba, @_idTarifa, _idVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2, @aPorezi )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )

   READ
   ESC_RETURN K_ESC

   IF roba_barkod_pri_unosu()
      _idRoba := Left( _idRoba, 10 )
   ENDIF

   select_o_koncij( _pkonto )
   SELECT kalk_pripr

   IF kalk_is_novi_dokument()
      _Kolicina := 0
   ENDIF

   IF !Empty( kalk_metoda_nc() ) .AND. _TBankTr <> "X"
      MsgO( "Računam količinu u prodavnici" )
      kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, NIL, NIL, @_nc )
      IF ROUND(_gkolicin2, 4) == 0 // ako je ispravka djelimične nivelacije, ne dirati količinu
         _kolicina := nKolicinaNaStanju
      ENDIF
      MsgC()
   ENDIF

   @ box_x_koord() + 12, box_y_koord() + 23  SAY8 "stanje: " + Transform( nKolicinaNaStanju, pickol() )
   @ box_x_koord() + 12, box_y_koord() + 2  SAY8 "Količina " GET _Kolicina PICTURE pickol() // VALID _kolicina >= 0
   _idpartner := ""
   READ

   nKalkStaraCijena := nKalkNovaCijena := 0
   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      nKalkStaraCijena := Round( kalk_get_mpc_by_koncij_pravilo(), 3 )
   ELSE
      nKalkStaraCijena := _fcj
   ENDIF

   IF kalk_is_novi_dokument() .AND.  dozvoljeno_azuriranje_sumnjivih_stavki()
      kalk_fakticka_mpc( @nKalkStaraCijena, _idfirma, _pkonto, _idroba )
   ENDIF

   set_pdv_public_vars()
   SELECT kalk_pripr

   nKalkNovaCijena := nKalkStaraCijena + _MPCSaPP
   @ box_x_koord() + 16, box_y_koord() + 2  SAY "STARA CIJENA (MPCSAPDV):"
   @ box_x_koord() + 16, box_y_koord() + 50 GET nKalkStaraCijena    PICT "999999.9999"
   @ box_x_koord() + 17, box_y_koord() + 2  SAY "NOVA CIJENA  (MPCSAPDV):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET nKalkNovaCijena     PICT "999999.9999"

   kalk_say_pdv_a_porezi_var( 19 )

   READ
   ESC_RETURN K_ESC

   _MPCSaPP := nKalkNovaCijena - nKalkStaraCijena
   _MPC := 0
   _fcj := nKalkStaraCijena
   _mpc := MpcBezPor( nKalkNovaCijena, aPorezi, , _nc ) - MpcBezPor( nKalkStaraCijena, aPorezi, , _nc )

   IF Round( nKolicinaNaStanju - _kolicina, 4 ) == 0
      IF Pitanje(, "Staviti u šifarnik novu cijenu", gStavitiUSifarnikNovuCijenuDefault ) == "D"
         select_o_koncij( _pkonto )
         roba_set_mcsapp_na_osnovu_koncij_pozicije( _fcj + _mpcsapp )
         SELECT kalk_pripr
      ENDIF
      _gkolicin2 := 0
   ELSE
      // zapamtiti količinu na stanju u slučaju djelimične nivelacije
      _gkolicin2 := nKolicinaNaStanju
      info_bar( "kalk_19", _idroba + " djelimična nivelacija" )
   ENDIF

   nKalkStrana := 3
   _VPC := 0
   _GKolicina := 0
   _Marza2 := 0
   _TMarza2 := "A"
   _MKonto := ""
   _MU_I := ""

   RETURN LastKey()
