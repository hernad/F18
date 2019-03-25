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

MEMVAR m
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP
MEMVAR gKalkUlazTrosak1, gKalkUlazTrosak2, gKalkUlazTrosak3, gKalkUlazTrosak4, gKalkUlazTrosak5

MEMVAR cIdPartner, cBrFaktp

STATIC s_oPDF

FUNCTION kalk_stampa_dok_81()

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom
   LOCAL cNaslov
   LOCAL xPrintOpt, bZagl
   LOCAL nTot1, nTo2, nTot3, nTot4, nTot5, nTot6, nTot7
   LOCAL nPdv


   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   nKalkMarzaVP := nKalkMarzaMP := 0

   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   // dDatFaktP := DatFaktP
   cPKonto := kalk_pripr->pkonto
   // cIdKonto2 := IdKonto2

   IF cIdVd == "89"
      cNaslov := "POS Prijem robe od dobavljača"
   ELSE
      cNaslov := "Ulaz u prodavnicu od dobavljača"
   ENDIF

   cNaslov += " " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9

   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   select_o_partner( cIdPartner )
   ?U  "DOBAVLJAČ:", cIdPartner, "-", PadR( naz, 20 ), Space( 5 ), "DOKUMENT Broj:", cBrFaktP // , "Datum:", dDatFaktP
   select_o_konto( cPKonto )

   ?U  "KONTO zadužuje :", cPKonto, "-", AllTrim( naz )

   m := "---- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------"
   m += " ----------"

   ? m
   ? "*R * ROBA     *  FCJ     * RABAT    *  FCJ-RAB  * TROSKOVI *    NC    * MARZA.   *    PC    *  PDV(%)  *    PC    *"
   ? "*BR* TARIFA   *  KOLICINA* DOBAVLJ  *           *          *          *          *  BEZ PDV *  PDV     *  SA PDV  *"
   ? m
   nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := nTotb := 0
   nTot9a := 0
   nTotC := nUC := 0
   nPDV := 0

   SELECT kalk_pripr
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr
      nPDV := kalk_pripr->mpc * pdv_procenat_by_tarifa( kalk_pripr->idtarifa )
      check_nova_strana( bZagl, s_oPDF )
      kalk_set_vars_troskovi_marzavp_marzamp()
      // SKol := Kolicina
      nTot +=  ( nU := FCj * kalk_pripr->Kolicina )
      nTot1 += ( nU1 := NC * ( GKolicina + GKolicin2 ) )
      nTot2 += ( nU2 := -Rabat / 100 * FCJ * Kolicina )
      nTot3 += ( nU3 := nKalkPrevoz * kalk_pripr->kolicina )
      nTot4 += ( nU4 := nKalkBankTr * kalk_pripr->kolicina )
      nTot5 += ( nU5 := nKalkSpedTr * kalk_pripr->kolicina )
      nTot6 += ( nU6 := nKalkCarDaz * kalk_pripr->kolicina )
      nTot7 += ( nU7 := nKalkZavTr * kalk_pripr->kolicina )
      nTot8 += ( nU8 := kalk_pripr->NC * kalk_pripr->kolicina )
      nTot9 += ( nU9 := nKalkMarzaMP * kalk_pripr->kolicina )
      nTotA += ( nUA := kalk_pripr->MPC   * kalk_pripr->kolicina )
      nTotB += ( nUB := kalk_pripr->MPCSAPP * kalk_pripr->kolicina )
      nTotC += ( nUC := nPDV * kalk_pripr->kolicina )

      // prvi red
      @ PRow() + 1, 0 SAY  kalk_pripr->Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""; ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF
      @ PRow() + 1, 4 SAY kalk_pripr->IdRoba
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY kalk_pripr->FCJ  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY - kalk_pripr->Rabat PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->fcj * ( 1 - kalk_pripr->Rabat / 100 )     PICTURE piccdem()
      IF kalk_pripr->fcj2 == 0
         nPom := -9999
      ELSE
         nPom := ( nKalkPrevoz + nKalkBankTr + nKalkSpedTr + nKalkCarDaz + nKalkZavTr ) / kalk_pripr->FCJ2 * 100
      ENDIF
      @ PRow(), PCol() + 1 SAY nPom  PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->NC PICTURE piccdem()
      IF kalk_pripr->nc == 0
         nPom := -9999
      ELSE
         nPom := nKalkMarzaMP / kalk_pripr->NC * 100
      ENDIF
      @ PRow(), PCol() + 1 SAY nPom PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPC PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) * 100 PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSaPP PICTURE piccdem()

      // drugi red
      @ PRow() + 1, 4 SAY kalk_pripr->IdTarifa
      @ PRow(), nCol1    SAY kalk_pripr->Kolicina PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY -kalk_pripr->Rabat / 100 * kalk_pripr->FCJ PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY Space( Len( piccdem() ) )
      @ PRow(), PCol() + 1 SAY nKalkPrevoz + nKalkBankTr + nKalkSpedTr + nKalkCarDaz + nKalkZavTr PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY Space( Len( picdem() ) )
      @ PRow(), PCol() + 1 SAY nKalkMarzaMP PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY Space( Len( picdem() ) )
      @ PRow(), PCol() + 1 SAY nPDV PICTURE piccdem()

      // treci red
      @ PRow() + 1, nCol1   SAY nU   PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nU2  PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nU + nU2  PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nU3 + nU4 + nU5 + nU6 + nU7         PICTURE  picdem()
      @ PRow(), PCol() + 1  SAY nU8 PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nU9 PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nUA PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nUC PICTURE  picdem()
      @ PRow(), PCol() + 1  SAY nUB PICTURE picdem()

      SKIP
   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 7 )

   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol1     SAY nTot          PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTot2         PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTot + nTot2         PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTot3 + nTot4 + nTot5 + nTot6 + nTot7 PICTURE picdem()
   @ PRow(), PCol() + 1  SAY nTot8         PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTot9         PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTotA         PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTotC  PICTURE         picdem()
   @ PRow(), PCol() + 1  SAY nTotB         PICTURE         picdem()
   ? m

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ?
   IF  Round( nTot3 + nTot4 + nTot5 + nTot6 + nTot7, 2 ) <> 0
      ?  m
      ?  "Troskovi (analiticki):"
      ?  gKalkUlazTrosak1, ":"
      @ PRow(), 30 SAY  nTot3 PICT picdem()
      ?  gKalkUlazTrosak2, ":"
      @ PRow(), 30 SAY  nTot4 PICT picdem()
      ?  gKalkUlazTrosak3, ":"
      @ PRow(), 30 SAY  nTot5 PICT picdem()
      ?  gKalkUlazTrosak4, ":"
      @ PRow(), 30 SAY  nTot6 PICT picdem()
      ?  gKalkUlazTrosak5, ":"
      @ PRow(), 30 SAY  nTot7 PICT picdem()
      ? m
      ?U "Ukupno troškovi:"
      @ PRow(), 30 SAY  nTot3 + nTot4 + nTot5 + nTot6 + nTot7 PICT picdem()
      ? m
   ENDIF

   nTot1 := nTot2 := nTot2b := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()
   ? "RUC:"
   @ PRow(), PCol() + 1 SAY nTot6 PICT picdem()
   ? m

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.
