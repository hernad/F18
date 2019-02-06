/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"



FUNCTION kalk_stampa_dok_rn()

   LOCAL nCol1 := nCol2 := 0, npom := 0

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nMarza, nMarza2

   // iznosi troskova i marzi koji se izracunavaju u kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

   nStr := 0
   cIdPartner := IdPartner; cBrFaktP := BrFaktP; dDatFaktP := DatFaktP
   cIdKonto := IdKonto; cIdKonto2 := IdKonto2

   P_COND
   ?? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   select_o_partner( cIdPartner )

   ? "RADNI NALOG:", kalk_pripr->IDZADUZ2

   m := "--- ------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"
   ? m
   IF koncij->naz == "P2"
      ? "*R *Konto  * ROBA     *          *  NCJ     * " + cRNT1 + " * " + cRNT2 + " * " + cRNT3 + " * " + cRNT4 + " * " + cRNT5 + " * Cij.Kost *  Marza   * Plan.Cj * "
   ELSE
      ? "*R *Konto  * ROBA     *          *  NCJ     * " + cRNT1 + " * " + cRNT2 + " * " + cRNT3 + " * " + cRNT4 + " * " + cRNT5 + " * Cij.Kost *  Marza   * Prod.Cj * "
   ENDIF
   ? "*BR*       * TARIFA   * KOLICINA *          *          *          *          *          *          *          *          *         *"
   ? "*  *       *          *          *   sum    *   sum    *   sum    *    sum   *   sum    *   sum    *   sum    *   sum    *  sum    *"
   ? m
   nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := 0

   SELECT kalk_pripr

   PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

      nT := nT1 := nT2 := nT3 := nT4 := nT5 := nT6 := nT7 := nT8 := nT9 := nTA := 0
      cBrFaktP := brfaktp; dDatFaktP := datfaktp; cIdpartner := idpartner
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD .AND. idpartner + brfaktp + DToS( datfaktp ) == cidpartner + cbrfaktp + DToS( ddatfaktp )

/*
   if gmagacin<>"1"
    if idpartner+brfaktp+idkonto+idkonto2<>cidd
     set device to screen
     Beep(2)
     Msg("Unutar kalkulacije se pojavilo vise dokumenata !",6)
     set device to printer
    endif
   endif
*/
         kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

         select_o_roba( kalk_pripr->IdRoba )
         select_o_tarifa( kalk_pripr->IdTarifa )
         SELECT kalk_pripr

         IF PRow() > page_length()
            FF
            @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
         ENDIF

         //IF gKalo == "1"
        //    SKol := Kolicina - GKolicina - GKolicin2
         //ELSE
            SKol := Kolicina
         //ENDIF

         nU := FCj * Kolicina
         //IF gKalo == "1"
          //  nU1 := FCj2 * ( GKolicina + GKolicin2 )
         //ELSE
            nU1 := NC * ( GKolicina + GKolicin2 )
         //ENDIF

         nU3 := nPrevoz * SKol
         nU4 := nBankTr * SKol
         nU5 := nSpedTr * SKol
         nU6 := nCarDaz * SKol
         nU7 := nZavTr * SKol
         nU8 := NC *    ( Kolicina - Gkolicina - GKolicin2 )
         nU9 := nMarza * ( Kolicina - Gkolicina - GKolicin2 )
         nUA := VPC   * ( Kolicina - Gkolicina - GKolicin2 )

         IF Val( Rbr ) > 900
            nT += nU
            nT3 += nU3; nT4 += nU4; nT5 += nU5; nT6 += nU6
            nT7 += nU7
         ELSE
            nT1 += nU
            nT8 += nU8; nT9 += nU9; nTA += nUA
         ENDIF

         IF rbr == "901"
            ? m
            @ PRow() + 1, 0        SAY "Ukupno:"
            @ PRow(), nCol1     SAY nT1        PICTURE         picdem
            @ PRow(), PCol() + 1  SAY 0          PICTURE         Space( Len( PICDEM ) )
            @ PRow(), PCol() + 1  SAY 0          PICTURE         Space( Len( PICDEM ) )
            @ PRow(), PCol() + 1  SAY 0          PICTURE         Space( Len( PICDEM ) )
            @ PRow(), PCol() + 1  SAY 0          PICTURE         Space( Len( PICDEM ) )
            @ PRow(), PCol() + 1  SAY 0          PICTURE         Space( Len( PICDEM ) )
            @ PRow(), PCol() + 1  SAY nT8        PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nT9        PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nTA        PICTURE         PICDEM
            ? m
            ?
            ?
            ? m
            ? "Rekapitulacija troskova - razduzenje konta:", idkonto2
            ? m

         ENDIF
         @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
         IF Val( rbr ) < 900
            @  PRow(), PCol() + 1 SAY  idkonto
         ELSE
            @  PRow(), PCol() + 1 SAY  Space( 7 )
         ENDIF
         @ PRow(), 11 SAY  "";?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"
         @ PRow() + 1, 11 SAY IdRoba
         @ PRow(), PCol() + 1 SAY Kolicina             PICTURE PicKol
         nCol1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY fcj                   PICTURE PicCDEM
         IF Val( rbr ) < 900
            @ PRow(), PCol() + 1 SAY nPrevoz / FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nBankTr / FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nSpedTr / FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nCarDaz / FCJ2 * 100      PICTURE PicProc
            @ PRow(), PCol() + 1 SAY nZavTr / FCJ2 * 100       PICTURE PicProc
            @ PRow(), PCol() + 1 SAY NC                    PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nMarza / NC * 100         PICTURE PicProc
            @ PRow(), PCol() + 1 SAY VPC                   PICTURE PicCDEM
         ENDIF

         IF Val( rbr ) < 900
            @ PRow() + 1, 11 SAY IdTarifa
            @ PRow(), nCol1    SAY Space( Len( PicCDEM ) )
            @ PRow(), PCol() + 1 SAY nPrevoz              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nBankTr              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nSpedTr              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nCarDaz              PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY nZavTr               PICTURE PicCDEM
            @ PRow(), PCol() + 1 SAY 0                    PICTURE PicDEM
            @ PRow(), PCol() + 1 SAY nMarza               PICTURE PicDEM
         ENDIF

         @ PRow() + 1, nCol1   SAY nU          PICTURE         PICDEM
         // @ prow(),pcol()+1  SAY nU1         picture         PICDEM
         IF Val( rbr ) < 900
            @ PRow(), PCol() + 1  SAY nU3         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU4         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU5         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU6         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU7         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU8         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU9         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nUA         PICTURE         PICDEM
         ENDIF
         SKIP
      ENDDO

      nTot += nT; nTot1 += nT1; nTot2 += nT2; nTot3 += nT3; nTot4 += nT4
      nTot5 += nT5; nTot6 += nT6; nTot7 += nT7; nTot8 += nT8; nTot9 += nT9; nTotA += nTA

   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol1     SAY nTot          PICTURE         PICDEM

   ? m

   RETURN ( NIL )
// }
