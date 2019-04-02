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

MEMVAR nKalkMarzaMP
MEMVAR _mpc, _mpcsapp, _tmarza2, _marza2, _idtarifa, _rabatv, _vpc, _kolicina, _fcj, _nc
MEMVAR GetList

FUNCTION kalk_when_mpc_bez_pdv_11_12()

   IF _mpcsapp <> 0
      _marza2 := 0
      _mpc := mpc_bez_pdv_by_tarifa( _idtarifa, _mpcsapp )
   ENDIF

   RETURN .T.


FUNCTION kalk_valid_mpc_bez_pdv_11_12( cProracunMarzeUnaprijed )

   IF cProracunMarzeUnaprijed == NIL
      cProracunMarzeUnaprijed := " "
   ENDIF

   kalk_proracun_marzamp_11_80( cProracunMarzeUnaprijed )
   IF _mpcsapp == 0
      _MPCSaPP := Round( mpc_sa_pdv_by_tarifa( _idtarifa, _mpc ), 2 )
   ENDIF

   RETURN .T.


FUNCTION kalk_valid_mpc_sa_pdv_11( cProracunMarzeUnaprijed, cIdTarifa )

   IF cProracunMarzeUnaprijed == NIL
      cProracunMarzeUnaprijed := " "
   ENDIF
   IF _mpcsapp <> 0 .AND. Empty( cProracunMarzeUnaprijed )
      _mpc := mpc_bez_pdv_by_tarifa( cIdTarifa, _mpcsapp )
      _marza2 := 0
      kalk_proracun_marzamp_11_80()
      ShowGets()
   ENDIF

   cProracunMarzeUnaprijed := " "

   RETURN .T.


FUNCTION kalk_say_pdv_a_porezi_var( nRow )

   @ box_x_koord() + nRow, box_y_koord() + 2  SAY "PDV (%):"
   @ Row(), Col() + 2 SAY pdv_procenat_by_tarifa( _idtarifa ) * 100 PICTURE "99.99"

   RETURN .T.


FUNCTION kalk_when_mpc_bez_pdv_80_81_41_42( cIdVd, lNaprijed )

   LOCAL nMpcSaPDVBruto
   LOCAL nPopustMaloprodaja

   IF lNaprijed
      kalk_set_vars_marza_maloprodaja_80_81_41_42( cIdVd, .T. )
   ENDIF

   nMpcSaPDVBruto := _MpcSaPP
   IF cIdVd $ "41#42"
      nPopustMaloprodaja := _rabatv // ne sadrzi pdv
   ELSE
      nPopustMaloprodaja := 0
   ENDIF

   IF !lNaprijed .AND. _MpcSapp <> 0
      _Marza2 := 0
      // mpc_bruto - popust (field rabatv) = mpc_neto (field mpc)
      // mpc_neto = mpc_sa_pdv_neto
      // mpc_bruto = mpc_sa_pdv_bruto bez pdv
      _Mpc := mpc_bez_pdv_by_tarifa( _idtarifa, nMpcSaPDVBruto ) - nPopustMaloprodaja
   ENDIF

   RETURN .T.


FUNCTION kalk_valid_mpc_bez_pdv_80_81_41_42( cIdVd, lNaprijed )

   LOCAL nMpcBezPDVNeto, nPopustMaloprodaja

   nMpcBezPDVNeto := _mpc
   IF cIdVd $ "41#42"
      nPopustMaloprodaja := _RabatV
   ELSE
      nPopustMaloprodaja := 0
   ENDIF

   kalk_set_vars_marza_maloprodaja_80_81_41_42( cIdVd, lNaprijed )
   IF ( _Mpcsapp == 0 )
      // mpc_sa_pdv_bruto = mpc_bruto = (mpc_neto + popust) sa pdv
      _mpcsapp := Round( mpc_sa_pdv_by_tarifa( _idtarifa, nMpcBezPDVNeto + nPopustMaloprodaja ), 2 )
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_set_vars_marza_maloprodaja_80_81_41_42( cIdVd, lNaprijed )

   IF cIdVd <> "81"
      _fcj := _nc
      _vpc := _nc
   ENDIF

   IF  ( _Marza2 == 0 ) .AND. !lNaprijed
      nKalkMarzaMP := _MPC - _VPC
      IF _TMarza2 == "%"
         IF Round( _VPC, 5 ) <> 0
            _Marza2 := 100 * ( _MPC / _VPC - 1 )
         ELSE
            _Marza2 := 0
         ENDIF
      ELSEIF _TMarza2 == "A"
         _Marza2 := nKalkMarzaMP

      ELSEIF _TMarza2 == "U"
         _Marza2 := nKalkMarzaMP * ( _Kolicina )
      ENDIF

   ELSEIF ( _MPC == 0 ) .OR. lNaprijed

      IF _TMarza2 == "%"
         nKalkMarzaMP := _VPC * _Marza2 / 100
      ELSEIF _TMarza2 == "A"
         nKalkMarzaMP := _Marza2
      ELSEIF _TMarza2 == "U"
         nKalkMarzaMP := _Marza2 / _Kolicina
      ENDIF
      _MPC := Round( nKalkMarzaMP + _VPC, 2 )
      _MpcSaPP := Round( mpc_sa_pdv_by_tarifa( _idtarifa, _mpc ), 2 )

   ELSE
      nKalkMarzaMP := _MPC - _VPC
   ENDIF

   AEval( GetList, {| o | o:display() } )

   RETURN .T.


FUNCTION kalk_valid_mpc_sa_pdv_41_42_81( cIdVd, lNaprijed, lShowGets )

   IF lShowGets == nil
      lShowGets := .T.
   ENDIF

   IF _Mpcsapp <> 0 .AND. !lNaprijed
      // mpc ce biti umanjena mpc sa pp - porez - rabat (ako postoji)
      _mpc := mpc_bez_pdv_by_tarifa( _idtarifa, _mpcsapp ) - _rabatv
      _marza2 := 0
      kalk_set_vars_marza_maloprodaja_80_81_41_42( cIdVd, lNaprijed )
      IF lShowGets
         ShowGets()
      ENDIF
   ENDIF

   RETURN .T.
