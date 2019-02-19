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

MEMVAR cIdFirma, cIdPartner, cBrFaktP, cIdVd, cBrDok, cPKonto, cPKonto2 // dDatFaktP
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

STATIC s_oPDF
STATIC s_cLinija
STATIC s_nRobaNazivSirina := 39

FUNCTION kalk_stampa_dok_80( lStampatiBezNabavneCijene )

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   IF lStampatiBezNabavneCijene == NIL
      lStampatiBezNabavneCijene := .F.
   ENDIF

   cIdFirma := kalk_pripr->IdFirma
   cIdVd := kalk_pripr->Idvd
   cBrDok := kalk_pripr->brdok

   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   // dDatFaktP := kalk_pripr->DatFaktP

   cPKonto := kalk_pripr->pkonto
   cPKonto2 := kalk_pripr->IdKonto2

   cNaslov := "PRIJEM PRODAVNICA " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   select_o_partner( cIdPartner )
   ?  "DOKUMENT Broj:", cBrFaktP // , "Datum:", dDatFaktP
   select_o_konto( cPKonto )
   ?  _u( "KONTO zadužuje :" ), cPKonto, "-", AllTrim( konto->naz )

   s_cLinija := "--- " + Replicate( "-", 10 ) + " " + Replicate( "-", 13 )
   s_cLinija += " " + Replicate( "-", s_nRobaNazivSirina + 5 ) + " ----------" + ;
      iif( lStampatiBezNabavneCijene, "", " ---------- ----------" ) + ;
      " ---------- ----------"

   bZagl := {|| zagl( lStampatiBezNabavneCijene ) }

   SELECT kalk_pripr
   nRec := RecNo()
   PRIVATE cIdd := kalk_pripr->idpartner + kalk_pripr->brfaktp + kalk_pripr->idkonto + kalk_pripr->idkonto2
   IF !Empty( cPKonto2 ) // postoje stavka i protustavka
      nProlaza := 2
   ELSE
      nProlaza := 1
   ENDIF

   unTot := unTot1 := unTot2 := unTot3 := unTot4 := unTot5 := unTot6 := unTot7 := unTot8 := unTot9 := unTotA := unTotb := 0
   unTot9a := 0

   Eval( bZagl )
   FOR nProlaz := 1 TO nProlaza
      nTot := nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTotA := nTotb := 0
      nTot9a := 0
      GO nRec

      check_nova_strana( bZagl, s_oPDF )
      DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

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
         kalk_set_vars_troskovi_marzavp_marzamp()
         kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
         nTot8 += ( nU8 := NC * kalk_pripr->Kolicina )
         nTot9 += ( nU9 := nKalkMarzaMP * kalk_pripr->Kolicina )
         nTotA += ( nUA := kalk_pripr->MPC * kalk_pripr->Kolicina )
         nTotB += ( nUB := kalk_pripr->MPCSAPP * kalk_pripr->Kolicina )

         check_nova_strana( bZagl, s_oPDF )
         @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
         @ PRow(), PCol() + 1 SAY kalk_pripr->IdRoba
         @ PRow(), PCol() + 1 SAY ROBA->barkod
         @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
         @ PRow(), PCol() + 1  SAY kalk_pripr->Kolicina             PICTURE piccdem()

         nCol1 := PCol() + 1
         IF !lStampatiBezNabavneCijene  // bez nc
            @ PRow(), nCol1    SAY kalk_pripr->NC                    PICTURE piccdem()
            IF Round( nc, 5 ) <> 0
               @ PRow(), PCol() + 1 SAY nKalkMarzaMP / kalk_pripr->NC * 100        PICTURE picproc()
            ELSE
               @ PRow(), PCol() + 1 SAY 0  PICTURE picproc()
            ENDIF
         ENDIF
         @ PRow(), PCol() + 1 SAY kalk_pripr->MPC                   PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSaPP               PICTURE piccdem()

         // @ PRow() + 1, 4 SAY kalk_pripr->IdTarifa
         IF !lStampatiBezNabavneCijene
            @ PRow(), nCol1     SAY nU8         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nU9         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nUA         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nUB         PICTURE         picdem()
         ELSE
            @ PRow(), nCol1 SAY nUA  PICTURE  picdem()
            @ PRow(), PCol() + 1  SAY nUB PICTURE         picdem()
         ENDIF

         SKIP
      ENDDO

      IF nProlaza == 2

         check_nova_strana( bZagl, s_oPDF, .F., 3 )
         ? s_cLinija
         ? "Konto "
         IF nProlaz == 1
            ?? cPKonto
         ELSE
            ?? cPKonto2
         ENDIF
         IF !lStampatiBezNabavneCijene
            @ PRow(), nCol1       SAY   nTot8         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTot9         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotA         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotB         PICTURE         picdem()
         ELSE
            @ PRow(), nCol1  SAY nTotA         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotB         PICTURE         picdem()
         ENDIF
         ? s_cLinija
      ENDIF
      unTot8  += nTot8
      unTot9  += nTot9
      unTot9a += nTot9a
      unTotA  += nTotA
      unTotB  += nTotB
   NEXT

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? s_cLinija
   @ PRow() + 1, 0        SAY "Ukupno:"
   IF !lStampatiBezNabavneCijene
      @ PRow(), nCol1     SAY unTot8         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY unTot9         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY unTotA         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY unTotB         PICTURE         picdem()
   ELSE
      @ PRow(), nCol1     SAY unTotA         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY unTotB         PICTURE         picdem()
   ENDIF
   ? s_cLinija

   nRec := RecNo()
   kalk_pripr_rekap_tarife( {|| check_nova_strana( bZagl, s_oPDF, .F., 5 ) }  )
   dok_potpis( 90, "L", NIL, NIL )
   f18_end_print( NIL, xPrintOpt )

   RETURN .F.



STATIC FUNCTION zagl( lStampatiBezNabavneCijene )

   ? s_cLinija
   ?U "*R.*  Roba        Barkod                  Naziv                          * količina *" + ;
      iif( lStampatiBezNabavneCijene, "", "  Nab.cj  * marža    *" ) + ;
      "   MPC    *  MPC    *"
   ?U "*br*                                                                     *          *" + ;
      iif( lStampatiBezNabavneCijene, "", "          *          *" ) + ;
      "  bez PDV * sa PDV  *"
   ? s_cLinija

   RETURN .T.
