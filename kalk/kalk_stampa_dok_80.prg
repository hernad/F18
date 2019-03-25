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
   LOCAL nPom := 0
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt
   LOCAL nProlaz, nProlaza, nRec
   LOCAL nTot1, nTot2, nTot3, nTot4, nTot5, nTot6, nTot7, nTotNV, nTotMarzaMP, nTotMPVBezPDV, nTotMPVSaPDV, nTot9a
   LOCAL nUTot, nUTot1, nUTot2, nUTot3, nUTot4, nUTot5, nUTot6, nUTot7, nUTot8, nUTot9, nUTotA, nUTotb, nUTot9a
   LOCAL nUNv
   LOCAL nUMarzaMP
   LOCAL nUMpvBezPDV
   LOCAL nUMpvSaPDV


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

   IF cIdVd == "02"
      cNaslov := "POS POČETNO STANJE"
   ELSEIF cIdVd == "61"
      cNaslov := "POS Zahtjev za narudžbu robe"
   ELSE
      cNaslov := "PRIJEM PRODAVNICA"
   ENDIF

   cNaslov += " " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( kalk_pripr->DatDok )
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

   IF !Empty( cPKonto2 ) // postoje stavka i protustavka
      nProlaza := 2
   ELSE
      nProlaza := 1
   ENDIF

   nUTot := nUTot1 := nUTot2 := nUTot3 := nUTot4 := nUTot5 := nUTot6 := nUTot7 := nUTot8 := nUTot9 := nUTotA := nUTotb := 0
   nUTot9a := 0

   Eval( bZagl )
   FOR nProlaz := 1 TO nProlaza
      nTot1 := nTot2 := nTot3 := nTot4 := nTot5 := nTot6 := nTot7 := nTotNV := nTotMarzaMP := nTotMPVBezPDV := nTotMPVSaPDV := 0
      nTot9a := 0
      GO nRec

      check_nova_strana( bZagl, s_oPDF )
      DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

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
         nTotNV += ( nUNv := kalk_pripr->NC * kalk_pripr->Kolicina )
         nTotMarzaMP += ( nUMarzaMP := nKalkMarzaMP * kalk_pripr->Kolicina )
         nTotMPVBezPDV += ( nUMpvBezPDV := kalk_pripr->MPC * kalk_pripr->Kolicina )
         nTotMPVSaPDV += ( nUMpvSaPDV := kalk_pripr->MPCSAPP * kalk_pripr->Kolicina )

         check_nova_strana( bZagl, s_oPDF )
         @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
         @ PRow(), PCol() + 1 SAY kalk_pripr->IdRoba
         @ PRow(), PCol() + 1 SAY ROBA->barkod
         @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
         @ PRow(), PCol() + 1  SAY kalk_pripr->Kolicina             PICTURE piccdem()

         nCol1 := PCol() + 1
         IF !lStampatiBezNabavneCijene  // bez nc
            @ PRow(), nCol1    SAY kalk_pripr->NC                    PICTURE piccdem()
            IF Round( kalk_pripr->nc, 5 ) <> 0
               @ PRow(), PCol() + 1 SAY nKalkMarzaMP / kalk_pripr->NC * 100        PICTURE picproc()
            ELSE
               @ PRow(), PCol() + 1 SAY 0  PICTURE picproc()
            ENDIF
         ENDIF
         @ PRow(), PCol() + 1 SAY kalk_pripr->MPC                   PICTURE piccdem()
         @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSaPP               PICTURE piccdem()

         // @ PRow() + 1, 4 SAY kalk_pripr->IdTarifa
         IF !lStampatiBezNabavneCijene
            @ PRow() + 1, nCol1   SAY nUNv         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nUMarzaMP         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nUMpvBezPDV         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nUMpvSaPDV         PICTURE         picdem()
         ELSE
            @ PRow() + 1, nCol1 SAY nUMpvBezPDV  PICTURE  picdem()
            @ PRow(), PCol() + 1  SAY nUMpvSaPDV PICTURE         picdem()
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
            @ PRow(), nCol1       SAY   nTotNV         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotMarzaMP         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotMPVBezPDV         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotMPVSaPDV         PICTURE         picdem()
         ELSE
            @ PRow(), nCol1  SAY nTotMPVBezPDV         PICTURE         picdem()
            @ PRow(), PCol() + 1  SAY nTotMPVSaPDV         PICTURE         picdem()
         ENDIF
         ? s_cLinija
      ENDIF
      nUTot8  += nTotNV
      nUTot9  += nTotMarzaMP
      nUTot9a += nTot9a
      nUTotA  += nTotMPVBezPDV
      nUTotB  += nTotMPVSaPDV
   NEXT

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? s_cLinija
   @ PRow() + 1, 0        SAY "Ukupno:"
   IF !lStampatiBezNabavneCijene
      @ PRow(), nCol1     SAY nUTot8         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nUTot9         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nUTotA         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nUTotB         PICTURE         picdem()
   ELSE
      @ PRow(), nCol1     SAY nUTotA         PICTURE         picdem()
      @ PRow(), PCol() + 1  SAY nUTotB         PICTURE         picdem()
   ENDIF
   ? s_cLinija

   nRec := RecNo()
   kalk_pripr_rekap_tarife( {|| check_nova_strana( bZagl, s_oPDF, .F., 9 ) }  )
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
