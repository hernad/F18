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

STATIC s_nKalkStaraCijena := 0

MEMVAR GetList
MEMVAR nKalkStrana, nKalkStaraCijena, nKalkNovaCijena, nKalkRbr
MEMVAR _IdFirma, _DatFaktP, _IdKonto, _IdKonto2, _kolicina, _idvd, _mkonto, _pkonto, _mpcsapp, _mpc, _nc, _fcj, _idroba, _idtarifa, _datdok
MEMVAR _MU_I, _PU_I, _VPC, _IdPartner
MEMVAR _TBankTr, _GKolicina, _GKolicin2, _Marza2, _TMarza2
MEMVAR _dat_od, _dat_do, _error
MEMVAR gStavitiUSifarnikNovuCijenuDefault

FUNCTION kalk_get_1_19_79()

   LOCAL nKolicinaNaStanju := 0

   _MKonto := ""
   _IdKonto := ""
   IF _IdVd == POS_IDVD_ODOBRENO_SNIZENJE
      _PU_I = KALK_TRANSAKCIJA_PRODAVNICA_SNIZENJE_PROCENAT
   ELSEIF _IdVd == POS_IDVD_ZAHTJEV_NIVELACIJA
      _PU_I = KALK_TRANSAKCIJA_PRODAVNICA_SNIZENJE_AKCIJA
   ELSE
      _PU_I := KALK_TRANSAKCIJA_PRODAVNICA_NIVELACIJA
   ENDIF
   _idpartner := ""

   IF nKalkRbr == 1 .AND. kalk_is_novi_dokument()
      _pkonto := _idkonto2
      _idkonto2 := Space( FIELD_LEN_KONTO_ID )
   ENDIF

   @ box_x_koord() + 8, box_y_koord() + 2   SAY8 "Konto koji zadužuje" GET _PKonto VALID  P_Konto( @_PKonto, 8, 30 ) PICT "@!"
   READ
   ESC_RETURN K_ESC
   set_prodavnica_by_pkonto( _pkonto )

   @ box_x_koord() + 10, box_y_koord() + 66 SAY "Tarif.br->"
   kalk_unos_get_roba_id( @GetList, @_idRoba, @_idTarifa, _idVd, kalk_is_novi_dokument(), box_x_koord() + 11, box_y_koord() + 2 )
   @ box_x_koord() + 11, box_y_koord() + 70 GET _IdTarifa VALID P_Tarifa( @_IdTarifa )
   READ
   ESC_RETURN K_ESC

   select_o_koncij( _pkonto )
   SELECT kalk_pripr
   IF kalk_is_novi_dokument()
      _Kolicina := 0
   ENDIF

   IF !Empty( kalk_metoda_nc() ) .AND. _TBankTr <> "X"
      MsgO( "Računam količinu u prodavnici" )
      kalk_get_nabavna_prod( _idfirma, _idroba, _pkonto, @nKolicinaNaStanju, NIL, NIL, @_nc )
      IF Round( _gkolicin2, 4 ) == 0 // ako je ispravka djelimične nivelacije, ne dirati količinu
         IF _IdVd <> POS_IDVD_ODOBRENO_SNIZENJE
            _kolicina := nKolicinaNaStanju
         ENDIF
      ENDIF
      MsgC()
   ENDIF

   @ box_x_koord() + 12, box_y_koord() + 23  SAY8 "knjig stanje: " + Transform( nKolicinaNaStanju, pickol() )
   @ box_x_koord() + 12, box_y_koord() + 2  SAY8 "Količina " GET _Kolicina PICTURE pickol() WHEN kalk_when_kolicina_19_72_79()

   IF _idvd == POS_IDVD_ODOBRENO_SNIZENJE .OR. _idvd == POS_IDVD_ZAHTJEV_NIVELACIJA
      @ box_x_koord() + 14, box_y_koord() + 2  SAY8 "Važi za period:" GET _dat_od WHEN {|| _dat_od := iif( Empty( _dat_od ), Date(), _dat_od ), .T. }
      @ Row(), Col() + 2  SAY8 "do" GET _dat_do ;
         WHEN {|| /*_dat_do := iif( Empty( _dat_do ), _dat_od + 7, _dat_do ),*/ .T. } ;
      VALID {|| ( Empty( _dat_do ) .AND. _idvd == POS_IDVD_ZAHTJEV_NIVELACIJA ) .OR. _dat_do >= _dat_od }
   ELSE
      _dat_od := _datdok
      _dat_do := CToD( "" )
   ENDIF
   READ

   nKalkStaraCijena := nKalkNovaCijena := 0
   IF kalk_is_novi_dokument()
      select_o_koncij( _pkonto )
      nKalkStaraCijena := Round( kalk_get_mpc_by_koncij_pravilo(), 3 )
   ELSE
      nKalkStaraCijena := _fcj
   ENDIF

   IF kalk_is_novi_dokument() .AND. dozvoljeno_azuriranje_sumnjivih_stavki()
      kalk_mpc_sa_pdv_sa_kartice( @nKalkStaraCijena, _idfirma, _pkonto, _idroba )
   ENDIF

   SELECT kalk_pripr
   nKalkNovaCijena := nKalkStaraCijena + _MPCSaPP
   @ box_x_koord() + 16, box_y_koord() + 2  SAY "STARA CIJENA (MPCSaPDV):"
   @ box_x_koord() + 16, box_y_koord() + 50 GET nKalkStaraCijena  PICT "999999.9999" ;
      WHEN kalk_when_stara_cijena_19_72_79( @nKalkStaraCijena ) ;
      VALID kalk_valid_start_cijena_19_72_78(  @nKalkStaraCijena )
   @ box_x_koord() + 17, box_y_koord() + 2  SAY "NOVA CIJENA  (MPCSaPDV):"
   @ box_x_koord() + 17, box_y_koord() + 50 GET nKalkNovaCijena  PICT "999999.9999" ;
      WHEN kalk_when_nova_cijena_79( GetList, _idroba, 12, 49, nKalkStaraCijena )

   kalk_say_pdv_a_porezi_var( 19 )
   READ
   ESC_RETURN K_ESC

   _MPCSaPP := nKalkNovaCijena - nKalkStaraCijena
   _MPC := 0
   _fcj := nKalkStaraCijena
   _mpc := mpc_bez_pdv_by_tarifa( _idtarifa, nKalkNovaCijena - nKalkStaraCijena )

   IF _idvd == POS_IDVD_KALK_NIVELACIJA
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
   ENDIF

   nKalkStrana := 3
   _VPC := 0
   _GKolicina := 0
   _Marza2 := 0
   _TMarza2 := "A"
   _MKonto := ""
   _MU_I := ""
   IF _idvd == POS_IDVD_ZAHTJEV_NIVELACIJA .OR. _idvd == POS_IDVD_ODOBRENO_SNIZENJE
      _error := "0"
   ENDIF

   RETURN LastKey()


STATIC FUNCTION kalk_when_kolicina_19_72_79()

   IF _idvd == POS_IDVD_ZAHTJEV_NIVELACIJA
      _kolicina := 0
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_when_stara_cijena_19_72_79( nKalkStaraCijena )

   s_nKalkStaraCijena := nKalkStaraCijena

   RETURN .T.

STATIC FUNCTION kalk_valid_start_cijena_19_72_78(  nKalkStaraCijena )

   IF !kalk_is_novi_dokument() .AND. nKalkStaraCijena <> s_nKalkStaraCijena
      IF Pitanje(, "Želite promjenu stare cijene ?! Sigurno ?", "N" ) == "D"
         RETURN .T.
      ELSE
         nKalkStaraCijena := s_nKalkStaraCijena
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION kalk_when_nova_cijena_79( GetList, cIdRoba, nShowXPosStanje, nShowYPosStanje, nKalkStaraCijena )

   LOCAL nStanje, nKalo

   nStanje := pos_dostupno_artikal_za_cijenu( cIdroba, nKalkStaraCijena, 0 )
   nKalo := pos_kalo( cIdroba )

   @ box_x_koord() + nShowXPosStanje, box_y_koord() + nShowYPosStanje  SAY8 "; POS st-kalo Cij(" + AllTrim( Transform( nKalkStaraCijena,  piccdem() ) ) + ") = "
   @ Row(), Col() + 1  SAY AllTrim( Transform( nStanje, pickol() ) ) + " - " + AllTrim( Transform( nKalo, pickol() ) ) + " = " + AllTrim( Transform( nStanje - nKalo, pickol() ) )

   RETURN .T.
