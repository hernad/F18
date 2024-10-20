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

MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

FUNCTION kalk_stampa_dok_18()

   LOCAL nCol1 := nCol2 := 0, npom := 0, nCR := 0

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   nStr := 1

   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   cIdKonto := IdKonto
   cIdKonto2 := IdKonto2

   P_10CPI
   B_ON
   ?? "PROMJENA CIJENA U MAGACINU"
   B_OFF
   ?
   P_COND
   ? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), ", Datum:", DatDok
   @ PRow(), 122 SAY "Str:" + Str( nStr, 3 )

   select_o_konto( cIdkonto )
   ?  "KONTO zaduzuje :", cIdKonto, "-", naz
   SELECT kalk_pripr

   m := "--- ------------------------------------------------ ----------- ---------- ---------- ---------- ---------- ---------- ----------"

   ? m

   ? "*RB*       ROBA                                     * Kolicina  * STARA PC *  RAZLIKA *  NOVA  PC*  IZNOS   *   PDV%  *  IZNOS   *"
   ? "*  *                                                *           *  BEZ PDV *PC BEZ PDV*  BEZ PDV *  RAZLIKE *         *   PDV    *"

   ? m
   nTotA := nTotB := nTotC := 0


   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

      select_o_roba(  kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr

      kalk_set_vars_troskovi_marzavp_marzamp()

      IF PRow() > page_length()
         FF
         @ PRow(), 122 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      nTotA += VPC * Kolicina
      nTotB += 0
      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), PCol() + 1 SAY IdRoba
      aNaz := SjeciStr( Trim( ROBA->naz ) + " ( " + ROBA->jmj + " )", 37 )
      @ PRow(), ( nCR := PCol() + 1 ) SAY  ""; ?? aNaz[ 1 ]
      @ PRow(), 52 SAY Kolicina
      @ PRow(), PCol() + 1 SAY MPCSAPP  PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY VPC      PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY MPCSAPP + VPC  PICTURE PicCDEM
      nC1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY VPC * Kolicina  PICTURE PicDEM
      @ PRow(), PCol() + 1 SAY 0    PICTURE Picproc
      @ PRow(), PCol() + 1 SAY 0   PICTURE Picdem

      // novi red
      IF Len( aNaz ) > 1
         @ PRow() + 1, 0 SAY ""
         @ PRow(), nCR  SAY ""; ?? aNaz[ 2 ]
      ENDIF

      SKIP

   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"

   @ PRow(), nC1  SAY nTota         PICTURE PicDEM
   @ PRow(), PCol() + 1  SAY 0             PICTURE PicDEM
   @ PRow(), PCol() + 1  SAY nTotB         PICTURE PicDEM

   ? m

   ?
   P_10CPI
   ? PadL( "Clanovi komisije: 1. ___________________", 75 )
   ? PadL( "2. ___________________", 75 )
   ? PadL( "3. ___________________", 75 )
   ?

   RETURN .T.
