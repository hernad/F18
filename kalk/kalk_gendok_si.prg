/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"



FUNCTION Otpis16SI()

   //o_koncij()
   o_kalk_pripr()
   o_kalk_pripr2()
   //o_kalk()
  // o_sifk()
//   o_sifv()
//   o_roba()

   SELECT kalk_pripr
   GO TOP
   PRIVATE cIdFirma := idfirma, cIdVD := idvd, cBrDok := brdok
   IF !( cidvd $ "16" ) .OR. "-X" $ cBrDok .OR. Pitanje(, "Formirati dokument radi evidentiranja otpisanog dijela? (D/N)", "N" ) == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   cBrUlaz := PadR( Trim( kalk_pripr->brdok ) + "-X", 8 )

   SELECT kalk_pripr
   GO TOP
   PRIVATE nRBr := 0
   DO WHILE !Eof() .AND. cidfirma == idfirma .AND. cidvd == idvd .AND. cbrdok == brdok
      scatter()
      SELECT kalk_pripr2
      APPEND BLANK
      _brdok := cBrUlaz
      _idkonto := "X-" + Trim( kalk_pripr->idkonto )
      _MKonto := _idkonto
      _TBankTr := "X"    // izgenerisani dokument
      gather()
      SELECT kalk_pripr
      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN .T.
