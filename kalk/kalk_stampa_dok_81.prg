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

FUNCTION kalk_stampa_dok_81()

   LOCAL nCol1 := nCol2 := 0, npom := 0
   PRIVATE aPorezi

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nKalkMarzaVP, nKalkMarzaMP

   nKalkMarzaVP := nKalkMarzaMP := 0
   // iznosi troskova i marzi koji se izracunavaju u kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

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
   aPorezi := {}

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idRoba, @aPorezi )

      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr

      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcSaPP, field->nc )
      nPDV := aIPor[ 1 ]
      IF PRow() > page_length()
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      SKol := Kolicina
      nTot +=  ( nU := FCj * Kolicina )
      nTot1 += ( nU1 := NC * ( GKolicina + GKolicin2 ) )
      nTot2 += ( nU2 := -Rabat / 100 * FCJ * Kolicina )
      nTot3 += ( nU3 := nPrevoz * SKol )
      nTot4 += ( nU4 := nBankTr * SKol )
      nTot5 += ( nU5 := nSpedTr * SKol )
      nTot6 += ( nU6 := nCarDaz * SKol )
      nTot7 += ( nU7 := nZavTr * SKol )
      nTot8 += ( nU8 := NC *    ( Kolicina - Gkolicina - GKolicin2 ) )
      nTot9 += ( nU9 := nKalkMarzaMP * ( Kolicina - Gkolicina - GKolicin2 ) )

      nTotA += ( nUA := MPC   * ( Kolicina - Gkolicina - GKolicin2 ) )
      nTotB += ( nUB := MPCSAPP * ( Kolicina - Gkolicina - GKolicin2 ) )
      nTotC += ( nUC := nPDV * ( Kolicina - Gkolicina - GKolicin2 ) )

      // prvi red
      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""; ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      @ PRow() + 1, 4 SAY IdRoba
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY FCJ                   PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY -Rabat                PICTURE PicProc
      @ PRow(), PCol() + 1 SAY fcj * ( 1 - Rabat / 100 )     PICTURE piccdem
      @ PRow(), PCol() + 1 SAY ( nPrevoz + nBankTr + nSpedtr + nCarDaz + nZavTr ) / FCJ2 * 100       PICTURE PicProc
      @ PRow(), PCol() + 1 SAY NC                    PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY nKalkMarzaMP / NC * 100        PICTURE PicProc

      @ PRow(), PCol() + 1 SAY MPC                   PICTURE PicCDEM

      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PDV ] PICTURE PicProc

      @ PRow(), PCol() + 1 SAY MPCSaPP               PICTURE PicCDEM

      // drugi red
      @ PRow() + 1, 4 SAY IdTarifa
      @ PRow(), nCol1    SAY Kolicina             PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY -Rabat / 100 * FCJ       PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY Space( Len( piccdem ) )
      @ PRow(), PCol() + 1 SAY ( nPrevoz + nBankTr + nSpedtr + nCarDaz + nZavTr )   PICTURE Piccdem
      @ PRow(), PCol() + 1 SAY Space( Len( picdem ) )
      @ PRow(), PCol() + 1 SAY nKalkMarzaMP              PICTURE PicCDEM


      @ PRow(), PCol() + 1 SAY Space( Len( picdem ) )
      @ PRow(), PCol() + 1 SAY nPDV  PICTURE PicCDEM

      // treci red
      @ PRow() + 1, nCol1   SAY nU          PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU2         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nu + nU2         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nu3 + nu4 + nu5 + nu6 + nU7         PICTURE  PICDEM
      @ PRow(), PCol() + 1  SAY nU8         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nU9         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nUA         PICTURE         PICDEM
      @ PRow(), PCol() + 1 SAY nUC  PICTURE  PICDEM
      @ PRow(), PCol() + 1  SAY nUB         PICTURE         PICDEM

      SKIP
   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol1     SAY nTot          PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot2         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot + nTot2         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY ntot3 + ntot4 + ntot5 + ntot6 + nTot7         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot8         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTot9         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTotA         PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTotC  PICTURE         PICDEM
   @ PRow(), PCol() + 1  SAY nTotB         PICTURE         PICDEM

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
      @ PRow(), 30 SAY  ntot3 PICT picdem
      ?  c10T2, ":"
      @ PRow(), 30 SAY  ntot4 PICT picdem
      ?  c10T3, ":"
      @ PRow(), 30 SAY  ntot5 PICT picdem
      ?  c10T4, ":"
      @ PRow(), 30 SAY  ntot6 PICT picdem
      ?  c10T5, ":"
      @ PRow(), 30 SAY  ntot7 PICT picdem
      ? m
      ? "Ukupno troskova:"
      @ PRow(), 30 SAY  ntot3 + ntot4 + ntot5 + ntot6 + ntot7 PICT picdem
      ? m
   ENDIF

   nTot1 := nTot2 := nTot2b := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()

   ? "RUC:";  @ PRow(), PCol() + 1 SAY nTot6 PICT picdem
   ? m

   RETURN .T.


FUNCTION kalk_stampa_dok_81_tops( lZaTops )

   LOCAL nCol1 := nCol2 := 0, nPom := 0
   LOCAL nPDV

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nKalkMarzaVP, nKalkMarzaMP, aPorezi

   nKalkMarzaVP := nKalkMarzaMP := 0
   aPorezi := {}

   // iznosi troskova i marzi koji se izracunavaju u kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
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

      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )

      SELECT kalk_pripr

      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idRoba, @aPorezi )
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcSaPP, field->nc )

      nPDV := aIPor[ 1 ]

      IF PRow() > page_length() - 4
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      SKol := Kolicina

      nTot +=  ( nU := FCj * Kolicina )
      nTot1 += ( nU1 := NC * ( GKolicina + GKolicin2 ) )
      nTot2 += ( nU2 := -Rabat / 100 * FCJ * Kolicina )
      nTot3 += ( nU3 := nPrevoz * SKol )
      nTot4 += ( nU4 := nBankTr * SKol )
      nTot5 += ( nU5 := nSpedTr * SKol )
      nTot6 += ( nU6 := nCarDaz * SKol )
      nTot7 += ( nU7 := nZavTr * SKol )
      nTot8 += ( nU8 := NC *    ( Kolicina - Gkolicina - GKolicin2 ) )
      nTot9 += ( nU9 := nKalkMarzaMP * ( Kolicina - Gkolicina - GKolicin2 ) )

      nTotA += ( nUA := MPC   * ( Kolicina - Gkolicina - GKolicin2 ) )
      nTotB += ( nUB := MPCSAPP * ( Kolicina - Gkolicina - GKolicin2 ) )
      nTotC += ( nUC := nPDV * ( Kolicina - Gkolicina - GKolicin2 ) )

      // prvi red
      @ PRow() + 1, 0 SAY rbr PICT "999"
      @ PRow(), 4 SAY ""
      ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + ROBA->barkod
      ENDIF

      @ PRow() + 1, 4 SAY IdRoba
      nCol1 := PCol() + 1

      IF !lZaTops
         @ PRow(), PCol() + 1 SAY FCJ                   PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY GKolicina             PICTURE PicKol
         @ PRow(), PCol() + 1 SAY -Rabat                PICTURE PicProc
         @ PRow(), PCol() + 1 SAY nPrevoz / FCJ2 * 100      PICTURE PicProc
         @ PRow(), PCol() + 1 SAY nBankTr / FCJ2 * 100      PICTURE PicProc
         @ PRow(), PCol() + 1 SAY nSpedTr / FCJ2 * 100      PICTURE PicProc
         @ PRow(), PCol() + 1 SAY nCarDaz / FCJ2 * 100      PICTURE PicProc
         @ PRow(), PCol() + 1 SAY nZavTr / FCJ2 * 100       PICTURE PicProc
         @ PRow(), PCol() + 1 SAY NC                    PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nKalkMarzaMP / NC * 100        PICTURE PicProc

      ELSE
         @ PRow(), PCol() + 1 SAY Kolicina             PICTURE PicCDEM
      ENDIF
      @ PRow(), PCol() + 1 SAY MPC                   PICTURE PicCDEM

      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PDV ] PICTURE PicProc

      @ PRow(), PCol() + 1 SAY MPCSaPP               PICTURE PicCDEM

      // drugi red
      @ PRow() + 1, 4 SAY IdTarifa
      IF !lZaTops
         @ PRow(), nCol1    SAY Kolicina             PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY GKolicin2            PICTURE PicKol
         @ PRow(), PCol() + 1 SAY -Rabat / 100 * FCJ       PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nPrevoz              PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nBankTr              PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nSpedTr              PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nCarDaz              PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY nZavTr               PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY Space( Len( picdem ) )
         @ PRow(), PCol() + 1 SAY nKalkMarzaMP              PICTURE PicCDEM

         @ PRow(), PCol() + 1 SAY Space( Len( PicCDEM ) )

         @ PRow(), PCol() + 1 SAY nPDV PICTURE PicCDEM

      ENDIF

      // treci red
      IF !lZaTops
         @ PRow() + 1, nCol1   SAY nU          PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU1         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU2         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU3         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU4         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU5         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU6         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU7         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU8         PICTURE         PICDEM
         @ PRow(), PCol() + 1  SAY nU9         PICTURE         PICDEM

      ELSE
         @ PRow() + 1, nCol1 - 1   SAY Space( Len( picdem ) )
      ENDIF
      @ PRow(), PCol() + 1  SAY nUA         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nUC  PICTURE PICDEM
      @ PRow(), PCol() + 1  SAY nUB         PICTURE         PICDEM
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
      @ PRow(), nCol1     SAY nTot          PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot1         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot2         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot3         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot4         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot5         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot6         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot7         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot8         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY nTot9         PICTURE         PICDEM
   ELSE
      @ PRow() + 1, nCol1 - 1   SAY Space( Len( picdem ) )
   ENDIF
   @ PRow(), PCol() + 1  SAY nTotA         PICTURE         PICDEM

   @ PRow(), PCol() + 1 SAY nTotC PICTURE PICDEM

   @ PRow(), PCol() + 1  SAY nTotB         PICTURE         PICDEM

   ? m

   nTot1 := nTot2 := nTot2b := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0

   kalk_pripr_rekap_tarife()

   IF !lZaTops
      ? "RUC:";  @ PRow(), PCol() + 1 SAY nTot6 PICT picdem
   ENDIF

   ? m

   dok_potpis( 90, "L", NIL, NIL )

   RETURN .T.
