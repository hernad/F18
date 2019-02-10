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


FUNCTION kalk_stampa_dok_82()

   LOCAL nCol0 := nCol1 := nCol2 := 0, npom := 0
   LOCAL nPdvProc

   PRIVATE nMarza, nMarza2

   nStr := 0
   cIdPartner := IdPartner; cBrFaktP := BrFaktP; dDatFaktP := DatFaktP

   cIdKonto := IdKonto; cIdKonto2 := IdKonto2

   P_COND
   ?? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   select_o_partner( cIdPartner )

   select_o_konto( cIdKonto )
   ?  "Magacin razduzuje:", cIdKonto, "-", AllTrim( naz )

   SELECT kalk_pripr

   m := "--- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"
   ? m
   ? "*R * ROBA     * Kolicina *   NC     *  VPC    *    MPC   *   PPP %  *   PPP    *  MPC     *"
   ? "*BR*          *          *          *         *          *   PPU %  *   PPU    *  SA Por  *"
   ? "*  *          *          *   sum    *         *    sum   *    sum   *   sum    *   sum    *"
   ? m
   nTot1 := nTot1b := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := 0

   PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD


      scatter()  // formiraj varijable _....
      Marza2R()   // izracunaj nMarza2
      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr
      nPDVProc := tarifa->opp / 100

      IF PRow() > page_length()
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      nTot3 +=  ( nU3 := NC * kolicina )
      nTot4 +=  ( nU4 := vpc * ( 1 - rabatv / 100 ) * Kolicina )
      nTot5 +=  ( nU5 := MPC * Kolicina )
      nPor1 :=  MPC * nPdvProc
      nPor2 := 0
      nTot6 +=  ( nU6 := ( nPor1 + nPor2 ) * Kolicina )
      nTot7 +=  ( nU7 := MPcSaPP * Kolicina )

      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""; ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      @ PRow() + 1, 4 SAY IdRoba
      @ PRow(), PCol() + 1 SAY Kolicina             PICTURE PicKol

      nCol0 := PCol() + 1
      @ PRow(), PCol() + 1 SAY NC                   PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY vpc * ( 1 - rabatv / 100 )   PICTURE PicCDEM
      @ PRow(), PCol() + 1 SAY MPC                  PICTURE PicCDEM
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY TARIFA->OPP          PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nPor1                PICTURE PiccDEM
      @ PRow(), PCol() + 1 SAY MPCSAPP              PICTURE PicCDEM

      @ PRow() + 1, nCol0     SAY  nc * kolicina      PICTURE picdem
      @ PRow(),   PCol() + 1  SAY  vpc * ( 1 - rabatv / 100 ) * kolicina  PICTURE picdem
      @ PRow(),   PCol() + 1  SAY  mpc * kolicina      PICTURE picdem

      @ PRow(), nCol1    SAY    0       PICTURE picproc
      @ PRow(),  PCol() + 1 SAY  nPor2             PICTURE piccdem

      SKIP

   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol0      SAY  nTot3        PICTURE       PicDEM
   @ PRow(), PCol() + 1   SAY  nTot4        PICTURE       PicDEM
   @ PRow(), PCol() + 1   SAY  nTot5        PICTURE       PicDEM
   @ PRow(), PCol() + 1   SAY  Space( Len( picproc ) )
   @ PRow(), PCol() + 1   SAY  nTot6        PICTURE        PicDEM
   @ PRow(), PCol() + 1   SAY  nTot7        PICTURE        PicDEM
   ? m

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   nRec := RecNo()

   SELECT kalk_pripr
   SET ORDER TO TAG "2"
   SEEK cidfirma + cidvd + cbrdok
   m := "------ ---------- ---------- ---------- ---------- ---------- ----------"
   ? m
   ? "* Tar *  PPP%    *   PPU%   *    MPV   *    PPP   *   PPU    * MPVSAPP *"
   ? m
   nTot1 := nTot2 := nTot3 := nTot4 := 0
   nTot5 := nTot6 := nTot7 := 0
   DO WHILE !Eof() .AND. cidfirma + cidvd + cbrdok == idfirma + idvd + brdok
      cidtarifa := idtarifa
      nU1 := nU2 := nU3 := nU4 := 0
      select_o_tarifa( cIdtarifa )
      SELECT kalk_pripr
      DO WHILE !Eof() .AND. cIdfirma + cIdvd + cBrdok == idfirma + idvd + brdok .AND. idtarifa == cidtarifa
         select_o_roba( kalk_pripr->idroba )
         SELECT kalk_pripr
         nU1 += mpc * kolicina
         nU2 += mpc * nPDVProc * kolicina
         nU3 += 0
         nU4 += mpcsapp * kolicina
         nTot5 += ( mpc - nc ) * kolicina
         SKIP
      ENDDO
      nTot1 += nu1; nTot2 += nU2; nTot3 += nU3
      nTot4 += nU4
      ? cidtarifa
      @ PRow(), PCol() + 1   SAY nPdvProc * 100 PICT picproc
      @ PRow(), PCol() + 1   SAY 0 PICT picproc
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1   SAY nu1 PICT picdem
      @ PRow(), PCol() + 1   SAY nu2 PICT picdem
      @ PRow(), PCol() + 1   SAY nu3 PICT picdem
      @ PRow(), PCol() + 1   SAY nu4 PICT picdem
   ENDDO
   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF
   ? m
   ? "UKUPNO"
   @ PRow(), nCol1      SAY nTot1 PICT picdem
   @ PRow(), PCol() + 1   SAY nTot2 PICT picdem
   @ PRow(), PCol() + 1   SAY nTot3 PICT picdem
   @ PRow(), PCol() + 1   SAY nTot4 PICT picdem
   ? m
   ? "RUC:";  @ PRow(), PCol() + 1 SAY nTot5 PICT picdem
   ? m

   SET ORDER TO TAG "1"
   GO nRec

   RETURN
