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

MEMVAR cPKonto, cPKonto2

FUNCTION kalk_stampa_dok_80( lStampatiBezNabavneCijene )

   LOCAL nCol1 := nCol2 := 0, nPom := 0

   PRIVATE nPrevoz, nCarDaz, nZavTr, nBankTr, nSpedTr, nMarza, nMarza2

   IF lStampatiBezNabavneCijene == NIL
      lStampatiBezNabavneCijene := .F.
   ENDIF

   nStr := 0
   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   dDatFaktP := DatFaktP

   cPKonto := kalk_pripr->pkonto
   cPKonto2 := kalk_pripr->IdKonto2

   P_10CPI
   ?
   ? "PRIJEM U PRODAVNICU (INTERNI DOKUMENT)"
   ?
   P_COND
   ? "KALK. DOKUMENT BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   select_o_partner( cIdPartner )

   ?  "DOKUMENT Broj:", cBrFaktP, "Datum:", dDatFaktP

   select_o_konto( cPKonto )

   ?U  "KONTO zadužuje :", cPKonto, "-", AllTrim( naz )


   m := "--- -------------------------------------------- ----------" + ;
      iif( lStampatiBezNabavneCijene, "", " ---------- ----------" ) + ;
      " ---------- ----------"


   ? m

   // 1. red
   ? "*R.* Roba                                       * kolicina *" + ;
      iif( lStampatiBezNabavneCijene, "", "  Nab.cj  * marza    *" ) + ;
      "   MPC    *  MPC    *"
   // 2.red
   ? "*br* Tarifa                                     *          *" + ;
      iif( lStampatiBezNabavneCijene, "", "          *          *" ) + ;
      "  bez PDV * sa PDV  *"


   ? m

   SELECT kalk_pripr
   nRec := RecNo()
   PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   IF !Empty( cPKonto2 ) // postoje stavka i protustavka
      nProlaza := 2
   ELSE
      nProlaza := 1
   ENDIF

   unTot := unTot1 := unTot2 := unTot3 := unTot4 := unTot5 := unTot6 := unTot7 := unTot8 := unTot9 := unTotA := unTotb := 0
   unTot9a := 0

   PRIVATE aPorezi
   aPorezi := {}

   FOR nProlaz := 1 TO nProlaza
      nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := nTotb := 0
      nTot9a := 0
      GO nRec
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD


         kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()

         IF ( nProlaza == 2 .AND. nProlaz == 1 .AND. Left( kalk_pripr->idkonto2, 3 ) == "XXX" )
            // prvi prolaz ignorisati idkonto==XXX
            SKIP
            LOOP
         ENDIF

         IF ( nProlaza == 2 .AND. nProlaz == 2 .AND. Left( kalk_pripr->idkonto2, 3 ) != "XXX" )
            // drugi prolaz ignorisati ako idkonto2 NIJE XXX
            SKIP
            LOOP
         ENDIF

         kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
         kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
         set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idroba, @aPorezi )

         aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcSaPP, field->nc )

         print_nova_strana( 125, @nStr, 2 )

         SKol := kalk_pripr->Kolicina

         nTot8 += ( nU8 := NC *    ( Kolicina ) )
         nTot9 += ( nU9 := nMarza2 * ( Kolicina ) )
         nTotA += ( nUA := MPC   * ( Kolicina ) )
         nTotB += ( nUB := MPCSAPP * ( Kolicina  ) )

         @ PRow() + 1, 0 SAY rbr PICT "999"
         @ PRow(), 4 SAY ""
         ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

         IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
            ?? ", BK: " + ROBA->barkod
         ENDIF

         @ PRow() + 1, 4 SAY IdRoba
         @ PRow(), PCol() + 35  SAY Kolicina             PICTURE PicCDEM
         nCol1 := PCol() + 1
         IF !lStampatiBezNabavneCijene  // bez nc
            @ PRow(), nCol1    SAY NC                    PICTURE PicCDEM
            IF Round( nc, 5 ) <> 0
               @ PRow(), PCol() + 1 SAY nMarza2 / NC * 100        PICTURE PicProc
            ELSE
               @ PRow(), PCol() + 1 SAY 0        PICTURE PicProc
            ENDIF
         ENDIF
         @ PRow(), PCol() + 1 SAY MPC                   PICTURE PicCDEM
         @ PRow(), PCol() + 1 SAY MPCSaPP               PICTURE PicCDEM

         @ PRow() + 1, 4 SAY IdTarifa
         IF !lStampatiBezNabavneCijene
            @ PRow(), nCol1     SAY nU8         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nU9         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nUA         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nUB         PICTURE         PICDEM
         ELSE
            @ PRow(), nCol1     SAY nUA         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nUB         PICTURE         PICDEM
         ENDIF

         SKIP
      ENDDO

      IF nProlaza == 2
         ? m
         ? "Konto "
         IF nProlaz == 1
            ?? cPKonto
         ELSE
            ?? cPKonto2
         ENDIF
         IF !lStampatiBezNabavneCijene
            @ PRow(), nCol1     SAY   nTot8         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nTot9         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nTotA         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nTotB         PICTURE         PICDEM
         ELSE
            @ PRow(), nCol1     SAY nTotA         PICTURE         PICDEM
            @ PRow(), PCol() + 1  SAY nTotB         PICTURE         PICDEM
         ENDIF
         ? m
      ENDIF
      unTot8  += nTot8
      unTot9  += nTot9
      unTot9a += nTot9a
      unTotA  += nTotA
      unTotB  += nTotB
   NEXT

   print_nova_strana( 125, @nStr, 3 )
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   IF !lStampatiBezNabavneCijene
      @ PRow(), nCol1     SAY unTot8         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY unTot9         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY unTotA         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY unTotB         PICTURE         PICDEM
   ELSE
      @ PRow(), nCol1     SAY unTotA         PICTURE         PICDEM
      @ PRow(), PCol() + 1  SAY unTotB         PICTURE         PICDEM
   ENDIF
   ? m

   print_nova_strana( 125, @nStr, 8 )
   nRec := RecNo()
   kalk_pripr_rekap_tarife()


   dok_potpis( 90, "L", NIL, NIL ) // potpis na dokumentu

   RETURN .F.
