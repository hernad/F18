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


FUNCTION kalk_stampa_dok_14_txt_legacy()

   LOCAL nCol1 := nCol2 := 0, npom := 0

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nMarza, nMarza2

   // iznosi troskova i marzi koji se izracunavaju u kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

   nStr := 0
   cIdPartner := IdPartner; cBrFaktP := BrFaktP; dDatFaktP := DatFaktP

   cIdKonto := IdKonto; cIdKonto2 := IdKonto2

   P_10CPI
   B_ON

   IF cIdvd == "14" .OR. cIdvd == "74"
      ?? "IZLAZ KUPCU PO VELEPRODAJI"
   ELSEIF cidvd == "15"
      ?? "OBRACUN VELEPRODAJE"
   ELSE
      ?? "STORNO IZLAZA KUPCU PO VELEPRODAJI"
   ENDIF

   ?
   B_OFF
   P_COND
   ??

   ? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, ", Datum:", DatDok

   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )

   select_o_partner( cIdPartner )

   ?  "KUPAC:", cIdPartner, "-", PadR( naz, 20 ), " FAKT br.:", cBrFaktP, "Datum:", dDatFaktP
   SELECT kalk_pripr
   find_kalk_doks2_by_broj_dokumenta( kalk_pripr->idfirma, kalk_pripr->idvd, kalk_pripr->brdok )
   ?? "  DatVal:", kalk_doks2->datval

   IF cIdvd == "94"
      select_o_konto( cIdkonto2 )
      ?  "Storno razduzenja KONTA:", cIdKonto, "-", AllTrim( naz )
   ELSE
      select_o_konto( cIdkonto2 )
      ?  "KONTO razduzuje:", kalk_pripr->mkonto, "-", AllTrim( naz )
      IF !Empty( kalk_pripr->Idzaduz2 )
         ?? " Rad.nalog:", kalk_pripr->Idzaduz2
      ENDIF
   ENDIF

   SELECT kalk_pripr
   select_o_koncij( kalk_pripr->mkonto )
   SELECT kalk_pripr

   m := "--- ---------- ---------- ----------  ---------- ---------- ---------- ----------- --------- ----------"

   ? m

   ? "*R * ROBA     * Kolicina *  NABAV.  *  MARZA   * PROD.CIJ *  RABAT    * PROD.CIJ*   PDV    * PROD.CIJ *"
   ? "*BR*          *          *  CJENA   *          *          *           * -RABAT  *          * SA PDV   *"

   ? m
   nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTota := ntotb := ntotc := nTotd := 0

   fNafta := .F.

   PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD


      SELECT kalk_pripr
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

      IF PRow() > page_length()
         FF
         @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      IF kalk_pripr->idvd = "15"
         SKol := - Kolicina
      ELSE
         SKol := Kolicina
      ENDIF

      nVPCIzbij := 0

      IF roba->tip == "X"
         nVPCIzbij := ( MPCSAPP / ( 1 + tarifa->opp / 100 ) * tarifa->opp / 100 )
      ENDIF

      nTot4 +=  ( nU4 := Round( NC * Kolicina * iif( idvd = "15", - 1, 1 ), gZaokr )     )  // nv


      IF ( roba->tip $ "UTY" )
         nU5 := 0
      ELSE
         nTot5 +=  ( Round( nU5 := nMarza * Kolicina * iif( idvd = "15", - 1, 1 ), gZaokr )  ) // ruc
      ENDIF
      nTot6 +=  ( nU6 := Round( TARIFA->VPP / 100 * iif( nMarza < 0, 0, nMarza ) * Kolicina * iif( idvd = "15", - 1, 1 ), gZaokr ) )  // pruc
      nTot7 +=  ( nU7 := nU5 - nU6  )    // ruc-pruc


      nTot8 +=  ( nU8 := Round( ( VPC - nVPCIzbij ) * Kolicina * iif( idvd = "15", - 1, 1 ), gZaokr ) )
      nTot9 +=  ( nU9 := Round( RABATV / 100 * VPC * Kolicina * iif( idvd = "15", - 1, 1 ), gZaokr ) )

      IF roba->tip == "X"
         // kod nafte prikazi bez poreza
         nTota +=  ( nUa := Round( nU8 - nU9, gZaokr ) )
         fnafta := .T.
      ELSE
         nTota +=  ( nUa := Round( nU8 - nU9, gZaokr ) )     // vpv sa ukalk rabatom
      ENDIF
      IF roba->tip == "X"
         nTotb := nUb := 0
         nTotc +=  ( nUc := Round( VPC * kolicina * iif( idvd = "15", - 1, 1 ), gzaokr ) )   // vpv+ppp
      ELSE
         IF idvd == "15" // kod 15-ke nema poreza na promet
            nUb := 0
         ELSE
            nUb := Round( nUa * mpc / 100, gZaokr ) // ppp
         ENDIF
         nTotb +=  nUb
         nTotc +=  ( nUc := nUa + nUb )   // vpv+ppp
      ENDIF

      IF koncij->naz = "P"
         nTotd +=  ( nUd := Round( fcj * kolicina * iif( idvd = "15", - 1, 1 ), gZaokr ) )  // trpa se planska cijena
      ELSE
         nTotd +=  ( nUd := nua + nub + nu6 )   // vpc+pornapr+pornaruc
      ENDIF

      // 1. PRVI RED
      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""
      ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF
      @ PRow() + 1, 4 SAY IdRoba
      @ PRow(), PCol() + 1 SAY Kolicina * iif( idvd = "15", - 1, 1 )  PICTURE PicKol
      nC1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY NC                          PICTURE PicCDEM
      PRIVATE nNc := 0
      IF nc <> 0
         nNC := nc
      ELSE
         nNC := 99999999
      ENDIF

      @ PRow(), PCol() + 1 SAY ( VPC - nNC ) / nNC * 100               PICTURE PicProc

      @ PRow(), PCol() + 1 SAY VPC - nVPCIzbij       PICTURE PiccDEM
      @ PRow(), PCol() + 1 SAY RABATV              PICTURE PicProc
      @ PRow(), PCol() + 1 SAY VPC * ( 1 - RABATV / 100 ) - nVPCIzbij  PICTURE PiccDEM

      IF roba->tip $ "VKX"
         @ PRow(), PCol() + 1 SAY PadL( "VT-" + Str( tarifa->opp, 5, 2 ) + "%", Len( picproc ) )
      ELSE
         IF idvd = "15"
            @ PRow(), PCol() + 1 SAY 0          PICTURE PicProc
         ELSE
            @ PRow(), PCol() + 1 SAY MPC        PICTURE PicProc
         ENDIF
      ENDIF

      IF roba->tip = "X"  // nafta , kolona VPC SA PP
         @ PRow(), PCol() + 1 SAY VPC PICTURE PicCDEM
      ELSE
         @ PRow(), PCol() + 1 SAY VPC * ( 1 - RabatV / 100 ) * ( 1 + mpc / 100 ) PICTURE PicCDEM
      ENDIF

      // 2. DRUGI RED
      @ PRow() + 1, 4 SAY IdTarifa + roba->tip
      @ PRow(), nC1    SAY nU4  PICT picdem
      @ PRow(), PCol() + 1 SAY nu8 - nU4  PICT picdem
      @ PRow(), PCol() + 1 SAY nu8  PICT picdem
      @ PRow(), PCol() + 1 SAY nU9  PICT picdem
      @ PRow(), PCol() + 1 SAY nUA  PICT picdem
      @ PRow(), PCol() + 1 SAY nub  PICT picdem
      @ PRow(), PCol() + 1 SAY nUC  PICT picdem

      SKIP

   ENDDO

   IF PRow() > page_length()
      FF
      @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   ENDIF

   ? m

   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nc1      SAY nTot4  PICT picdem
   @ PRow(), PCol() + 1 SAY ntot8 - nTot4  PICT picdem
   @ PRow(), PCol() + 1 SAY ntot8  PICT picdem
   @ PRow(), PCol() + 1 SAY ntot9  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotA  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotB  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotC  PICT picdem

   ? m

   RETURN
// }
