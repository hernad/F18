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

FUNCTION kalk_stampa_dok_81()

   LOCAL nCol1 := nCol2 := 0, nPom := 0
   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   nKalkMarzaVP := nKalkMarzaMP := 0

   nStr := 0
   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   //dDatFaktP := DatFaktP
   cPKonto := kalk_pripr->pkonto
   //cIdKonto2 := IdKonto2

   P_10CPI
   ??U "ULAZ U PRODAVNICU DIREKTNO OD DOBAVLJAČA"
   P_COND
   ?
   ?? "KALK: KALKULACIJA BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   select_o_partner( cIdPartner )

   ?U  "DOBAVLJAČ:", cIdPartner, "-", PadR( naz, 20 ), Space( 5 ), "DOKUMENT Broj:", cBrFaktP //, "Datum:", dDatFaktP
   select_o_konto( cPKonto )

   ?U  "KONTO zadužuje :", cPKonto, "-", AllTrim( naz )

   m := "---- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- -----------"
   m += " ----------"

   ? m
   ? "*R * ROBA     *  FCJ     * RABAT    *  FCJ-RAB  * TROSKOVI *    NC    * MARZA.   *    PC    *  PDV(%)  *    PC    *"
   ? "*BR* TARIFA   *  KOLICINA* DOBAVLJ  *           *          *          *          *  BEZ PDV *  PDV     *  SA PDV  *"
   ? "*  *          *   sum    *  sum     *    sum    *          *          *   sum    *   sum    *   sum    *          *"
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

      nPDV := kalk_pripr->mpc * pdv_procenat_by_tarifa(kalk_pripr->idtarifa)
      IF PRow() > page_length()
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      kalk_set_vars_troskovi_marzavp_marzamp()
      //SKol := Kolicina
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
      @ PRow(), PCol() + 1 SAY ( nKalkPrevoz + nKalkBankTr + nKalkSpedTr + nKalkCarDaz + nKalkZavTr ) / kalk_pripr->FCJ2 * 100  PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->NC PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY nKalkMarzaMP / kalk_pripr->NC * 100 PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPC PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa(kalk_pripr->idtarifa)*100 PICTURE picproc()
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

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
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
   IF  Round( ntot3 + ntot4 + ntot5 + ntot6 + ntot7, 2 ) <> 0
      ?  m
      ?  "Troskovi (analiticki):"
      ?  c10T1, ":"
      @ PRow(), 30 SAY  ntot3 PICT picdem()
      ?  c10T2, ":"
      @ PRow(), 30 SAY  ntot4 PICT picdem()
      ?  c10T3, ":"
      @ PRow(), 30 SAY  ntot5 PICT picdem()
      ?  c10T4, ":"
      @ PRow(), 30 SAY  ntot6 PICT picdem()
      ?  c10T5, ":"
      @ PRow(), 30 SAY  ntot7 PICT picdem()
      ? m
      ? "Ukupno troskova:"
      @ PRow(), 30 SAY  ntot3 + ntot4 + ntot5 + ntot6 + ntot7 PICT picdem()
      ? m
   ENDIF

   nTot1 := nTot2 := nTot2b := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()
   ? "RUC:";  @ PRow(), PCol() + 1 SAY nTot6 PICT picdem()
   ? m

   RETURN .T.


FUNCTION kalk_stampa_dok_81_tops( lZaTops )

   LOCAL nCol1 := nCol2 := 0, nPom := 0
   LOCAL nPDV

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP
   nKalkMarzaVP := nKalkMarzaMP := 0


   nStr := 0
   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   // dDatFaktP := DatFaktP
   cPKonto := kalk_pripr->Konto
   cIdKonto2 := IdKonto2

   IF lZaTops == NIL
      lZaTops := .F.
   ENDIF

   P_COND2
   ?? "KALK: KALKULACIJA BR:", cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", DatDok

   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   select_o_partner( cIdPartner )
   ?U "DOBAVLJAČ:", cIdPartner, "-", PadR( naz, 20 ), Space( 5 ), "DOKUMENT Broj:", AllTrim( cBrFaktP ) //, "Datum:", dDatFaktP
   select_o_konto( cPKonto )
   ?U  "KONTO zadužuje :", cPKonto, "-", AllTrim( naz )

   IF !lZaTops
      m := "--- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"
      m += " -----------"
      ? m
      ? "*R * ROBA     *  FCJ     * TRKALO   * KASA-    * " + c10T1 + " * " + c10T2 + " * " + c10T3 + " * " + c10T4 + " * " + c10T5 + " *   NC     * MARZA.   *   MPC    * MPCSaPP *"
      ? "*BR* TARIFA   *  KOLICINA* OST.KALO * SKONTO   *          *          *          *          *          *          *          *          *         *"
      ? "*  *          *          *          *          *          *          *          *          *          *          *          *          *         *"
      ? m

   ELSE
      m := "--- ---------- --------- ---------- ----------- ----------"
      ? m
      ?U "*R * ROBA     * Količina *   PDV   *    PC    * PC sa PDV *"
      ?U "*BR* TARIFA   *          *         *          *           *"
      ?U "*  *          *          *         *          *           *"
      ? m

   ENDIF

   nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := nTotb := nTotC := 0
   nTot9a := 0
   nUC := 0

   SELECT kalk_pripr
   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr
      kalk_set_vars_troskovi_marzavp_marzamp()
      nPDV := field->mpc * pdv_procenat_by_tarifa(kalk_pripr->idtarifa)
      IF PRow() > page_length() - 4
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      nTot +=  ( nU := kalk_pripr->FCj * kalk_pripr->kolicina )
      nTot1 += ( nU1 := NC * ( GKolicina + GKolicin2 ) )
      nTot2 += ( nU2 := -kalk_pripr->Rabat / 100 * kalk_pripr->FCJ * kalk_pripr->kolicin )
      nTot3 += ( nU3 := nKalkPrevoz * kalk_pripr->kolicina )
      nTot4 += ( nU4 := nKalkBankTr * kalk_pripr->kolicina )
      nTot5 += ( nU5 := nKalkSpedTr * kalk_pripr->kolicina )
      nTot6 += ( nU6 := nKalkCarDaz * kalk_pripr->kolicina )
      nTot7 += ( nU7 := nKalkZavTr * kalk_pripr->kolicina )
      nTot8 += ( nU8 := kalk_pripr->NC * kalk_pripr->kolicina )
      nTot9 += ( nU9 := nKalkMarzaMP * kalk_pripr->kolicina )
      nTotA += ( nUA := MPC * kalk_pripr->kolicina )
      nTotB += ( nUB := MPCSAPP * kalk_pripr->kolicina )
      nTotC += ( nUC := nPDV * kalk_pripr->kolicina )

      // prvi red
      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), 4 SAY ""
      ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + ROBA->barkod
      ENDIF
      @ PRow() + 1, 4 SAY kalk_pripr->IdRoba
      nCol1 := PCol() + 1

      IF !lZaTops
         @ PRow(), PCol() + 1 SAY kalk_pripr->FCJ                   PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY kalk_pripr->GKolicina             PICTURE PicKol
         @ PRow(), PCol() + 1 SAY -kalk_pripr->Rabat                PICTURE picproc()
         @ PRow(), PCol() + 1 SAY nKalkPrevoz / kalk_pripr->FCJ2 * 100      PICTURE picproc()
         @ PRow(), PCol() + 1 SAY nKalkBankTr / kalk_pripr->FCJ2 * 100      PICTURE picproc()
         @ PRow(), PCol() + 1 SAY nKalkSpedTr / kalk_pripr->FCJ2 * 100      PICTURE picproc()
         @ PRow(), PCol() + 1 SAY nKalkCarDaz / kalk_pripr->FCJ2 * 100      PICTURE picproc()
         @ PRow(), PCol() + 1 SAY nKalkZavTr / kalk_pripr->FCJ2 * 100       PICTURE picproc()
         @ PRow(), PCol() + 1 SAY kalk_pripr->NC                    PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkMarzaMP / kalk_pripr->NC * 100        PICTURE picproc()

      ELSE
         @ PRow(), PCol() + 1 SAY kalk_pripr->Kolicina             PICTURE piccdem()
      ENDIF
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPC                   PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa(kalk_pripr->idtarifa)*100 PICTURE picproc()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSaPP               PICTURE piccdem()

      // drugi red
      @ PRow() + 1, 4 SAY kalk_pripr->IdTarifa
      IF !lZaTops
         @ PRow(), nCol1    SAY kalk_pripr->Kolicina             PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY GKolicin2            PICTURE PicKol
         @ PRow(), PCol() + 1 SAY -kalk_pripr->Rabat / 100 * kalk_pripr->FCJ       PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkPrevoz              PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkBankTr              PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkSpedTr              PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkCarDaz              PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY nKalkZavTr               PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY Space( Len( picdem() ) )
         @ PRow(), PCol() + 1 SAY nKalkMarzaMP              PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY Space( Len( piccdem() ) )
         @ PRow(), PCol() + 1 SAY nPDV PICTURE piccdem()

      ENDIF

      // treci red
      IF !lZaTops
         @ PRow() + 1, nCol1   SAY nU          PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU1         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU2         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU3         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU4         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU5         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU6         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU7         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU8         PICTURE         picdem()
         @ PRow(), PCol() + 1  SAY nU9         PICTURE         picdem()

      ELSE
         @ PRow() + 1, nCol1 - 1   SAY Space( Len( picdem() ) )
      ENDIF
      @ PRow(), PCol() + 1  SAY nUA         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nUC  PICTURE picdem()
      @ PRow(), PCol() + 1  SAY nUB         PICTURE         picdem()
      SKIP
   ENDDO

   IF PRow() > page_length() - 3
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF

   ? m

   @ PRow() + 1, 0        SAY "Ukupno:"
   // ************************** magacin *****************************
   IF !lZaTops
      @ PRow(), nCol1     SAY nTot          PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot1         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot2         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot3         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot4         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot5         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot6         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot7         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot8         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nTot9         PICTURE         picdem()
   ELSE
      @ PRow() + 1, nCol1 - 1   SAY Space( Len( picdem() ) )
   ENDIF
   @ PRow(), PCol() + 1  SAY nTotA         PICTURE         picdem()

   @ PRow(), PCol() + 1 SAY nTotC PICTURE picdem()

   @ PRow(), PCol() + 1  SAY nTotB         PICTURE         picdem()

   ? m

   nTot1 := nTot2 := nTot2b := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0

   kalk_pripr_rekap_tarife()

   IF !lZaTops
      ? "RUC:";  @ PRow(), PCol() + 1 SAY nTot6 PICT picdem()
   ENDIF

   ? m

   dok_potpis( 90, "L", NIL, NIL )

   RETURN .T.
