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

STATIC s_oPDF

MEMVAR gZaokr, gcMpcKalk10
MEMVAR gKalkUlazTrosak1, gKalkUlazTrosak2, gKalkUlazTrosak3, gKalkUlazTrosak4, gKalkUlazTrosak5
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

#define PRINT_LEFT_SPACE 4

MEMVAR m
MEMVAR PicDEM, PicKOL, PicPROC
MEMVAR cIdFirma, cIdVD, cBrDok, cIdPartner, cBrFaktP, cIdKonto, cIdKonto2  //dDatFaktP

FIELD IdFirma, BrDok, IdVD, IdTarifa, rbr, DatDok, idpartner, brfaktp, idkonto, idkonto2, GKolicina, GKolicin2

FUNCTION kalk_stampa_dok_10()

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL bZagl, xPrintOpt
   LOCAL nTot, nTot1, nTot2, nTot3, nTot4, nTot5, nTot6, nTot7, nTot8, nTot9, nTotA, nTotB, nTotP, nTotM
   LOCAL nU, nU1, nU2, nU3, nU4, nU5, nU6, nU7, nU8, nU9, nUA, nUP, nUM
   LOCAL nKolicina
   LOCAL nPDV, nPDVStopa
   LOCAL hParams := hb_hash()


   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   cIdPartner := field->IdPartner
   cBrFaktP := field->BrFaktP


   cIdKonto := field->IdKonto
   cIdKonto2 := field->IdKonto2

   IF FIELDPOS("datfaktp") <> 0
      hParams["datfaktp"] := kalk_pripr->datfaktp
   ELSE
      find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdvd, cBrDok )
      hParams["datfaktp"] := kalk_doks->datfaktp
      select kalk_pripr
   ENDIF

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  "KALK Br:" + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( DatDok ) ) == "X"
      RETURN .F.
   ENDIF

   PRIVATE m

   bZagl := {|| zagl(hParams) }

   Eval( bZagl )
   nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := 0
   nTotB := nTotP := nTotM := 0

   SELECT kalk_pripr

   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD


      check_nova_strana( bZagl, s_oPDF )

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_set_vars_troskovi_marzavp_marzamp()
      nKolicina := kalk_pripr->Kolicina
      nPDVStopa := tarifa->pdv
      nPDV := kalk_pripr->MPCsaPP / ( 1 + ( tarifa->pdv / 100 ) ) * ( tarifa->pdv / 100 )
      nTot +=  ( nU := Round( kalk_pripr->FCj * kalk_pripr->Kolicina, gZaokr ) )
      nTot1 += ( nU1 := Round( kalk_pripr->FCj2 * ( kalk_pripr->GKolicina + kalk_pripr->GKolicin2 ), gZaokr ) )
      nTot2 += ( nU2 := Round( - kalk_pripr->Rabat / 100 * kalk_pripr->FCJ * kalk_pripr->Kolicina, gZaokr ) )
      nTot3 += ( nU3 := Round( nKalkPrevoz * nKolicina, gZaokr ) )
      nTot4 += ( nU4 := Round( nKalkBankTr * nKolicina, gZaokr ) )
      nTot5 += ( nU5 := Round( nKalkSpedTr * nKolicina, gZaokr ) )
      nTot6 += ( nU6 := Round( nKalkCarDaz * nKolicina, gZaokr ) )
      nTot7 += ( nU7 := Round( nKalkZavTr * nKolicina, gZaokr ) )
      nTot8 += ( nU8 := Round( NC *    ( Kolicina - Gkolicina - GKolicin2 ), gZaokr ) )
      nTot9 += ( nU9 := Round( nKalkMarzaVP * ( Kolicina - Gkolicina - GKolicin2 ), gZaokr ) )
      nTotA += ( nUA := Round( VPC   * ( Kolicina - Gkolicina - GKolicin2 ), gZaokr ) )

      nTotP += ( nUP := nPDV * kolicina ) // total porez
      nTotM += ( nUM := MPCsaPP * kolicina ) // total mpcsapp


      @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE ) // PRVI RED podaci o artiklu
      @ PRow(), PCol() SAY field->rBr PICTURE "999"
      ?? " " + Trim( Left( ROBA->naz, 60 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )  // drugi red
      @ PRow(), PCol() + 4 SAY IdRoba
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY FCJ                   PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY GKolicina             PICTURE PicKol
      @ PRow(), PCol() + 1 SAY -Rabat                PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nKalkPrevoz / FCJ2 * 100      PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nKalkBankTr / FCJ2 * 100      PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nKalkSpedTr / FCJ2 * 100      PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nKalkCarDaz / FCJ2 * 100      PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nKalkZavTr / FCJ2 * 100       PICTURE PicProc
      @ PRow(), PCol() + 1 SAY NC                    PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkMarzaVP / NC * 100         PICTURE PicProc
      @ PRow(), PCol() + 1 SAY VPC                   PICTURE PicCDEM

      IF gcMpcKalk10 == "D"
         @ PRow(), PCol() + 1 SAY nPDVStopa         PICTURE PicProc
         @ PRow(), PCol() + 1 SAY MPCsaPP           PICTURE PicCDEM
      ENDIF

      @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )  // treci red
      @ PRow(), PCol() + 4 SAY IdTarifa
      @ PRow(), nCol1      SAY Kolicina             PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY GKolicin2            PICTURE PicKol
      @ PRow(), PCol() + 1 SAY -Rabat / 100 * FCJ   PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkPrevoz              PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkBankTr              PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkSpedTr              PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkCarDaz              PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkZavTr               PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY 0                    PICTURE PicDEM
      @ PRow(), PCol() + 1 SAY nKalkMarzaVP               PICTURE PicCDEM
      IF gcMpcKalk10 == "D"
         @ PRow(), PCol() + 1 SAY 0              PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nPDV           PICTURE PicCDEM
      ENDIF

      @ PRow() + 1, nCol1   SAY nU          PICTURE         PICDEM  // cetvrti red
      @ PRow(), PCol() + 1  SAY nU1         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU2         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU3         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU4         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU5         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU6         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU7         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU8         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU9         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nUA         PICTURE         PICDEM

      IF gcMpcKalk10 == "D"
         @ PRow(), PCol() + 1  SAY nUP         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nUM         PICTURE         PICDEM
      ENDIF

      SKIP
   ENDDO

   check_nova_strana( bZagl, s_oPDF )

   ? m

   @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
   @ PRow(), PCol() SAY "Ukupno:"
   @ PRow(), nCol1     SAY nTot            PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot1         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot2         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot3         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot4         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot5         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot6         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot7         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot8         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot9         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTotA         PICTURE         PICDEM
   IF ( gcMpcKalk10 == "D" )
      @ PRow(), PCol() + 1  SAY nTotP         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTotM         PICTURE         PICDEM
   ENDIF

   check_nova_strana( bZagl, s_oPDF )

   ? m
   ? Space( PRINT_LEFT_SPACE ) + "Magacin se zadužuje po nabavnoj vrijednosti " + AllTrim( Transform( nTot8, picdem ) )
   ? m

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl( hParams )

   zagl_organizacija( PRINT_LEFT_SPACE )

   select_o_partner( cIdPartner )
   ?U  Space( PRINT_LEFT_SPACE ) + "DOBAVLJAČ:", cIdPartner, "-", Trim( field->naz ), Space( 5 ), "Faktura Br:", cBrFaktP, "-", hParams[ "datfaktp" ]

   SELECT kalk_pripr

   select_o_konto( cIdKonto )
   ?U  Space( PRINT_LEFT_SPACE )  + "MAGACINSKI KONTO zadužuje :", cIdKonto, "-", field->naz

   M := Space( PRINT_LEFT_SPACE )  + "--- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"

   IF ( gcMpcKalk10 == "D" )
      m += " ---------- ----------"
   ENDIF

   ? m

   IF gcMpcKalk10 == "D" // prikazi mpc
      ?U Space( PRINT_LEFT_SPACE )  + "*R * ROBA     *  FCJ     * NOR.KALO * KASA-    * " + gKalkUlazTrosak1 + " * " + gKalkUlazTrosak2 + " * " + gKalkUlazTrosak3 + " * " + gKalkUlazTrosak4 + " * " + gKalkUlazTrosak5 + " *   NC     *  MARZA   * PROD.CIJ.*   PDV%   * PROD.CIJ.*"
      ?U Space( PRINT_LEFT_SPACE )  + "*BR* TARIFA   *  KOLIČINA* PRE.KALO * SKONTO   *          *          *          *          *          *          *          * BEZ.PDV  *   PDV    * SA PDV   *"
      ?U Space( PRINT_LEFT_SPACE )  + "*  *          *   sum    *   sum    *  sum     *   sum    *   sum    *    sum   *   sum    *   sum    *   sum    *   sum    *   sum    *   sum    *    sum   *"
   ELSE
      // prikazi samo do neto cijene - bez pdv-a
      ?U Space( PRINT_LEFT_SPACE )  + "*R * ROBA     *  FCJ     * NOR.KALO * KASA-    * " + gKalkUlazTrosak1 + " * " + gKalkUlazTrosak2 + " * " + gKalkUlazTrosak3 + " * " + gKalkUlazTrosak4 + " * " + gKalkUlazTrosak5 + " *   NC     *  MARZA   * PROD.CIJ.*"
      ?U Space( PRINT_LEFT_SPACE )  + "*BR* TARIFA   *  KOLIČINA* PRE.KALO * SKONTO   *          *          *          *          *          *          *          * BEZ.PDV  *"
      ?U Space( PRINT_LEFT_SPACE )  + "*  *          *   sum    *   sum    *  sum     *   sum    *   sum    *    sum   *   sum    *   sum    *   sum    *   sum    *   sum    *"

   ENDIF

   ? m

   RETURN .T.
