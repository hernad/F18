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

FUNCTION kalk_stampa_dok_pr()

   LOCAL nCol1 := nCol2 := 0, nProc, nPom := 0
   LOCAL bProizvod

   IF is_legacy_kalk_pr()
      RETURN leg_StKalkPR()
   ENDIF

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   nStr := 0
   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   //dDatFaktP := DatFaktP
   cIdKonto := IdKonto
   cIdKonto2 := IdKonto2

   P_COND
   ?? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), "PROZVODNJA PO SASTAVNICAMA ", Space( 2 ), "Datum:", DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )

   select_o_partner( cIdPartner )

   m := "--- ------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"
   ? m
   ?U "*R *Konto  * ROBA     *          *  NCJ     * " + cRNT1 + " * " + cRNT2 + " * " + cRNT3 + " * " + cRNT4 + " * " + cRNT5 + " * Cij.Kost *  Marza   * Prod.Cj * "
   ?U "*BR*       * TARIFA   * KOLIČINA *          *          *          *          *          *          *          *          *         *"
   ?U "*  *       *          *          *   sum    *   sum    *   sum    *    sum   *   sum    *   sum    *   sum    *   sum    *  sum    *"
   ? m

   nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := 0

   SELECT kalk_pripr

   bProizvod := {|| AllTrim( Str( Round( field->rBr / 100, 0 ) ) ) }

   DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND.  cBrDok == field->BrDok .AND. cIdVD == field->IdVD

      nTnabavna := nT1 := nT2 := nT3 := nT4 := nT5 := nT6 := nT7 := nT8 := nT9 := nTA := 0

      cBrFaktP := field->brfaktp
      //dDatFaktP := field->datfaktp
      cIdpartner := field->idpartner

      cProizvod := "0"
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD ;
            .AND. field->idpartner + field->brfaktp == cIdpartner + cBrFaktp

         kalk_set_vars_troskovi_marzavp_marzamp()
         select_o_roba( kalk_pripr->IdRoba )
         select_o_tarifa( kalk_pripr->IdTarifa )

         SELECT kalk_pripr

         IF PRow() > page_length()
            FF
            @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
         ENDIF

         //IF gKalo == "1"
          //  SKol := field->Kolicina - field->GKolicina - field->GKolicin2
        // ELSE
            SKol := field->Kolicina
        // ENDIF

         nUnabavna := field->FCj * field->Kolicina
         IF field->rbr > 99
            nUnabavna := field->NC * field->Kolicina
         ENDIF

         //IF gKalo == "1"
        //    nU1 := field->FCj2 * ( field->GKolicina + field->GKolicin2 )
         //ELSE
            nU1 := field->NC * ( field->GKolicina + field->GKolicin2 )
         //ENDIF

         nU3 := nKalkPrevoz * SKol
         nU4 := nKalkBankTr * SKol
         nU5 := nKalkSpedTr * SKol
         nU6 := nKalkCarDaz * SKol
         nU7 := nKalkZavTr * SKol
         nU8 := field->NC * ( field->Kolicina - field->Gkolicina - field->GKolicin2 )
         nU9 := nKalkMarzaVP * ( field->Kolicina - field->Gkolicina - field->GKolicin2 )
         nUA := field->VPC * ( field->Kolicina - field->Gkolicina - field->GKolicin2 )

         IF field->Rbr > 99
            nTNabavna += nUnabavna; nT1 += nU1
            nT3 += nU3; nT4 += nU4; nT5 += nU5; nT6 += nU6
            nT7 += nU7; nT8 += nU8; nT9 += nU9; nTA += nUA

         ENDIF


         IF field->rbr > 100 .AND. cProizvod != Eval( bProizvod )

            cProizvod := Eval( bProizvod )
            ?
            ? m
            ?U "Rekapitulacija troškova - razduženje konta:", field->idkonto2, ;
               "za stavku proizvoda: ", cProizvod
            ? m

         ENDIF

         @ PRow() + 1, 0 SAY  kalk_pripr->Rbr PICTURE "999"
         IF kalk_pripr->rbr < 10
            @  PRow(), PCol() + 1 SAY  field->idkonto
         ELSE
            @  PRow(), PCol() + 1 SAY  Space( 7 )
         ENDIF
         @ PRow(), 11 SAY  "";?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"
         @ PRow() + 1, 11 SAY IdRoba
         @ PRow(), PCol() + 1 SAY field->Kolicina             PICTURE PicKol
         nCol1 := PCol() + 1

         IF kalk_pripr->rbr > 10
            @ PRow(), PCol() + 1 SAY field->nc                   PICTURE PicCDEM
         ENDIF

         IF kalk_pripr->rbr < 10
            @ PRow(), PCol() + 1 SAY field->fcj                   PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nKalkPrevoz / field->FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nKalkBankTr / field->FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nKalkSpedTr / field->FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nKalkCarDaz / field->FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nKalkZavTr / field->FCJ2 * 100       PICTURE PicProc
            @ PRow(), PCol() + 1 SAY field->NC                    PICTURE PicCDEM

            IF Round( field->nc, 4 ) != 0
               nProc := nKalkMarzaVP / field->NC * 100
            ELSE
               nProc := -1
            ENDIF
            @ PRow(), PCol() + 1 SAY nProc        PICTURE PicProc

            @ PRow(), PCol() + 1 SAY field->VPC                   PICTURE PicCDEM
         ENDIF

         IF kalk_pripr->rbr < 10
            @ PRow() + 1, 11 SAY IdTarifa
            @ PRow(), nCol1    SAY Space( Len( PicCDEM ) )
            @ PRow(), PCol() + 1 SAY nKalkPrevoz              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nKalkBankTr              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nKalkSpedTr              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nKalkCarDaz              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nKalkZavTr               PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY 0                    PICTURE pic_vrijednost()
            @ PRow(), PCol() + 1 SAY nKalkMarzaVP               PICTURE pic_vrijednost()
         ENDIF

         @ PRow() + 1, nCol1   SAY nUnabavna       PICTURE         pic_vrijednost()
         IF kalk_pripr->rbr < 10
            @ PRow(), PCol() + 1  SAY nU3         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU4         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU5         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU6         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU7         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU8         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nU9         PICTURE         pic_vrijednost()
            @ PRow(), PCol() + 1  SAY nUA         PICTURE         pic_vrijednost()
         ENDIF
         SKIP
      ENDDO

      nTot += nTnabavna; nTot1 += nT1; nTot2 += nT2; nTot3 += nT3; nTot4 += nT4
      nTot5 += nT5; nTot6 += nT6; nTot7 += nT7; nTot8 += nT8; nTot9 += nT9; nTotA += nTA

   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF

   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol1     SAY nTot          PICTURE         pic_vrijednost()
   ? m

   RETURN .T.


STATIC FUNCTION pic_vrijednost()

   RETURN "999999.999"
