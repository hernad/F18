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
MEMVAR cMpcFieldName
MEMVAR nKalkMarzaMP
MEMVAR _kolicina, _pkonto, _TBankTr, _idroba, _error, _idvd, _fcj, _vpc, _mpc, _mpcsapp
MEMVAR _TMarza2, _Marza2, _idtarifa, _nc

FUNCTION kalk_proracun_marzamp_11_80( cProracunMarzeUnaprijed, lSvediVPCNaNC )

   hb_default( @lSvediVPCNaNC, .T. )
   IF cProracunMarzeUnaprijed == nil
      cProracunMarzeUnaprijed := " "
   ENDIF
   IF lSvediVPCNaNC // izjednačiti vpc sa nc
      _VPC := _FCJ
   ENDIF

   // ako je prevoz u MP rasporedjen uzmi ga u obzir
   // IF _TPrevoz == "A"
   // nPrevMP := _Prevoz
   // ELSE
   // nPrevMP := 0
   // ENDIF

   IF _FCj == 0
      _FCj := _mpc
   ENDIF

   IF  _Marza2 == 0 .AND. Empty( cProracunMarzeUnaprijed )
      nKalkMarzaMP := _MPC - _VPC // - nPrevMP
      IF _TMarza2 == "%"
         IF Round( _vpc, 5 ) <> 0
            _Marza2 := 100 * ( _MPC / _VPC  - 1 )
         ELSE
            _Marza2 := 0
         ENDIF
      ELSEIF _TMarza2 == "A"
         _Marza2 := nKalkMarzaMP

      ELSEIF _TMarza2 == "U"
         _Marza2 := nKalkMarzaMP * _Kolicina
      ENDIF

   ELSEIF _MPC == 0 .OR. !Empty( cProracunMarzeUnaprijed )

      IF _TMarza2 == "%"
         nKalkMarzaMP := _Marza2 / 100 * _VPC
      ELSEIF _TMarza2 == "A"
         nKalkMarzaMP := _Marza2
      ELSEIF _TMarza2 == "U"
         nKalkMarzaMP := _Marza2 / _Kolicina
      ENDIF
      _MPC := Round( nKalkMarzaMP + _VPC, 2 )
      IF !Empty( cProracunMarzeUnaprijed )
         _MpcSaPP := Round( mpc_sa_pdv_by_tarifa( _idtarifa, _mpc ), 2 )
      ENDIF
   ELSE
      nKalkMarzaMP := _MPC - _VPC
   ENDIF
   AEval( GetList, {| o | o:display() } )

   RETURN .T.



FUNCTION kalk_marza_realizacija_prodavnica_41_42()

   LOCAL nPDV, nMpcBezPDVNeto

   nPDV := 1 / ( 1 + tarifa->pdv / 100 )
   IF _nc == 0
      _nc := _mpc
   ENDIF
   nMpcBezPDVNeto := _MPC

   IF  ( _Marza2 == 0 )
      nKalkMarzaMP := nMpcBezPDVNeto - _NC
      IF _TMarza2 == "%"
         IF Round( _nc - 1, 4 ) != 0
            _Marza2 := 100 * ( nMpcBezPDVNeto / _NC - 1 )
         ELSE
            _Marza2 := 999
            error_bar( "kalk", "dijeljenje sa 0: nc - 1" )
         ENDIF
      ELSEIF _TMarza2 == "A"
         _Marza2 := nKalkMarzaMP
      ELSEIF _TMarza2 == "U"
         _Marza2 := nKalkMarzaMP * _Kolicina
      ENDIF
   ELSEIF ( _MPC == 0 )
      IF _TMarza2 == "%"
         nKalkMarzaMP := _Marza2 / 100 * _NC
      ELSEIF _TMarza2 == "A"
         nKalkMarzaMP := _Marza2
      ELSEIF _TMarza2 == "U"
         IF Round( _kolicina, 4 ) != 0
            nKalkMarzaMP := _Marza2 / _Kolicina
         ELSE
            error_bar( "kalk", "dijeljenje sa 0: kolicina" )
            nKalkMarzaMP := 999
         ENDIF
      ENDIF
      _MPC := nKalkMarzaMP + _NC

   ELSE
      nKalkMarzaMP := nMpcBezPDVNeto - _NC
   ENDIF
   AEval( GetList, {| o | o:display() } )

   RETURN .T.



FUNCTION kalk_mpc_sa_pdv_sa_kartice( nMPC, cIdFirma, cPKonto, cIdRoba, dDatum )

   LOCAL nOrder

   nMPC := kalk_get_mpc_by_koncij_pravilo()

   PushWA()

   find_kalk_by_pkonto_idroba( cIdFirma, cPKonto, cIdRoba )
   GO BOTTOM
   // uzeti cijenu sa zadnje stavke na kartici
   DO WHILE !Bof() .AND. kalk->idfirma + kalk->pkonto + kalk->idroba == cIdFirma + cPKonto + cIdRoba

      IF dDatum <> NIL .AND. dDatum < kalk->datdok
         SKIP -1
         LOOP
      ENDIF

      IF kalk->idvd $ "11#80#81"
         nMPC := kalk->mpcsapp
         EXIT
      ELSEIF kalk->idvd == "19"
         nMPC := kalk->fcj + kalk->mpcsapp
         EXIT
      ENDIF

      SKIP -1
   ENDDO
   PopWa()

   RETURN .T.



/*
   mora biti pozicioniran na zapis u roba
*/

FUNCTION kalk_get_mpc_by_koncij_pravilo( cIdKonto )

   LOCAL nMPCSifarnik := 0, cTipCijene

   IF cIdKonto != NIL
      PushWa()
      select_o_koncij( cIdKonto )
      cTipCijene := koncij->naz
      PopWa()
   ELSE
      cTipCijene := koncij->naz
   ENDIF

   IF cTipCijene == "M2"
      nMPCSifarnik := roba->mpc2
   ELSEIF cTipCijene == "M3"
      nMPCSifarnik := roba->mpc3
   ELSEIF cTipCijene == "M4"
      nMPCSifarnik := roba->mpc4
   ELSEIF cTipCijene == "M5"
      nMPCSifarnik := roba->mpc5
   ELSEIF cTipCijene == "M6"
      nMPCSifarnik := roba->mpc6
   ELSEIF cTipCijene == "M7"
      nMPCSifarnik := roba->mpc7
   ELSEIF cTipCijene == "M8"
      nMPCSifarnik := roba->mpc8
   ELSEIF cTipCijene == "M9"
      nMPCSifarnik := roba->mpc9
   ELSE
      nMPCSifarnik := roba->mpc
   ENDIF

   RETURN nMPCSifarnik


FUNCTION roba_set_mcsapp_na_osnovu_koncij_pozicije( nCijena, lUpit )

   LOCAL lAzurirajCijenu
   LOCAL lRet := .F.
   LOCAL lIsteCijene
   LOCAL hRec

   IF lUpit == nil
      lUpit := .F.
   ENDIF

   PRIVATE cMpcFieldName := ""

   DO CASE
   CASE koncij->naz == "M2"
      cMpcFieldName := "mpc2"
   CASE koncij->naz == "M3"
      cMpcFieldName := "mpc3"
   CASE koncij->naz == "M4"
      cMpcFieldName := "mpc4"

   OTHERWISE
      cMpcFieldName := "mpc"
   ENDCASE

   lIsteCijene := ( Round( roba->( &cMpcFieldName ), 4 ) == Round( nCijena, 4 ) )
   IF lIsteCijene
      RETURN .F.
   ENDIF

   IF lUpit
      IF gAutoCjen == "D" .AND. Pitanje(, "Staviti " + cMpcFieldName + " u šifarnik ?", gStavitiUSifarnikNovuCijenuDefault ) == "D"
         lAzurirajCijenu := .T.
      ELSE
         lAzurirajCijenu := .F.
      ENDIF
   ELSE
      lAzurirajCijenu := .T.
      IF gAutoCjen == "N"
         lAzurirajCijenu := .F.
      ENDIF
   ENDIF

   IF lAzurirajCijenu
      PushWA()
      SELECT ROBA
      hRec := dbf_get_rec()
      hRec[ cMpcFieldName ] := nCijena
      update_rec_server_and_dbf( Alias(), hRec, 1, "FULL" )
      PopWa()
      lRet := .T.
   ENDIF

   RETURN lRet


FUNCTION kalk_valid_kolicina_prod( nKolicinaNaStanju )

   LOCAL nKol

   IF Empty( kalk_metoda_nc() ) .OR. _TBankTr == "X"
      RETURN .T.
   ENDIF

   IF roba->tip $ "UT"
      RETURN .T.
   ENDIF

   nKol := _Kolicina
   IF _idvd == "11"
      nKol := Abs( _Kolicina )
   ENDIF

   IF _fcj <= 0
      MsgBeep( _idroba + "NC <= 0 ! STOP !" )
      error_bar( "prod", _pkonto + " " + _idroba + " nc <= 0" )
      _ERROR := "1"
      automatska_obrada_error( .T. )
      RETURN .F.
   ENDIF

   IF nKolicinaNaStanju < nKol
      sumnjive_stavke_error()
      error_bar( "KA_" + _pkonto + "/" + _idroba, ;
         _pkonto + " / " + _idroba + "na stanju: " + AllTrim( Str( nKolicinaNaStanju, 10, 4 ) ) + " treba " +  AllTrim( Str( _kolicina, 10, 4 ) ) )
   ENDIF

   RETURN .T.


FUNCTION kalk_marza_maloprodaja()

   IF TMarza2 == "%" .OR. Empty( Tmarza2 )
      nKalkMarzaMP := kolicina * Marza2 / 100 * VPC
   ELSEIF TMarza2 == "A"
      nKalkMarzaMP := Marza2 * kolicina
   ELSEIF TMarza2 == "U"
      nKalkMarzaMP := Marza2
   ENDIF

   RETURN nKalkMarzaMP
