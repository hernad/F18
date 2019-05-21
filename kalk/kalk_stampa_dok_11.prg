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
STATIC s_nRobaNazivSirina := 34

MEMVAR cIdPartner, cBrFaktP, dDatFaktP
MEMVAR cIdFirma, cIdVd, cBrDok

FUNCTION kalk_stampa_dok_11()

   LOCAL nCol0 := 0
   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL lVPC := .F.
   LOCAL nVPC, nUVPV, nTVPV
   LOCAL bZagl, xPrintOpt, cNaslov
   LOCAL cLinija
   LOCAL nTot1, nTot1b, nTot2, nTotVPV, nTotMarzaVP, nTotMarzaMP, nTot5, nTot6, nTot7
   LOCAL nTot4c
   LOCAL cPKonto, cMKonto

   PRIVATE nKalkMarzaVP, nKalkMarzaMP

   SELECT kalk_pripr

   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP

   IF FieldPos( "DATFAKTP" ) == 0
      find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
      dDatFaktP := kalk_doks->datfaktp
      SELECT kalk_pripr
   ELSE
      dDatFaktP := kalk_pripr->DatFaktP
   ENDIF

   cPKonto := kalk_pripr->pkonto
   cMKonto := kalk_pripr->mkonto

   IF cIdVd == "21"
      cNaslov := "POS Zahtjev za prijem iz magacina"
   ELSEIF cIdVd == "22"
      cNaslov := "POS prijem iz magacina"
   ELSE
      cNaslov := "OTPREMNICA PRODAVNICA"
   ENDIF

   cNaslov += " " + cIdFirma + "-" + cIdVD + "-" + cBrDok  + ", Datum dokumenta:" + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "font_size" ] := 9
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF



   cLinija := "--- ---------- " + Replicate( "-", s_nRobaNazivSirina + 5 ) + " ---------- ---------- " + "---------- ---------- " +  "---------- ---------- "  + "---------- ---------- ---------- --------- -----------"

   select_o_koncij( kalk_pripr->mkonto )
   lVPC := is_magacin_evidencija_vpc( kalk_pripr->mkonto )

   SELECT kalk_pripr
   bZagl := {|| zagl_11( cPKonto, cMKonto, cBrFaktP, dDatFaktP, cLinija ) }
   Eval( bZagl )

   select_o_koncij( kalk_pripr->pkonto )
   SELECT kalk_pripr

   nTot1 := nTot1b := nTot2 := nTotVPV := nTotMarzaVP := nTotMarzaMP := nTot5 := nTot6 := nTot7 := 0
   nTot4c := 0

   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      Scatter()
      IF lVPC
         nVPC := vpc_magacin_rs( .T. )
         SELECT kalk_pripr
         _VPC := nVPC
      ENDIF

      kalk_proracun_marzamp_11_80( NIL, .F. ) // ne diraj _VPC
      nKalkMarzaVP := _marza
      nPDVCijena := kalk_pripr->mpc * pdv_procenat_by_tarifa( kalk_pripr->idtarifa )
      check_nova_strana( bZagl, s_oPDF )
      nTot1 +=  ( nU1 := kalk_pripr->FCJ * kalk_pripr->Kolicina   )
      nTot1b += ( nU1b := kalk_pripr->NC * kalk_pripr->Kolicina  )
      nTot2 +=  ( nU2 := kalk_pripr->Prevoz * kalk_pripr->Kolicina   )
      nTotVPV +=  ( nU3 := _VPC * kalk_pripr->kolicina )
      nTotMarzaVP +=  ( nU4 := nKalkMarzaVP * kalk_pripr->Kolicina )
      nTotMarzaMP +=  ( nU4b := nKalkMarzaMP * kalk_pripr->Kolicina )
      nTot5 +=  ( nU5 := kalk_pripr->MPC * kalk_pripr->Kolicina )
      nTot6 +=  ( nU6 := nPDVCijena * kalk_pripr->Kolicina )
      nTot7 +=  ( nU7 := kalk_pripr->MPcSaPP * kalk_pripr->Kolicina )

      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), PCol() + 1 SAY IdRoba
      @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
      @ PRow(), PCol() + 1  SAY kalk_pripr->Kolicina             PICTURE PicCDEM

      nCol0 := PCol() + 1
      @ PRow(), PCol() + 1 SAY kalk_pripr->FCJ                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->VPC                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY 0               PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY _VPC                   PICTURE piccdem() // _VPC
      @ PRow(), PCol() + 1 SAY nKalkMarzaVP               PICTURE piccdem()  // marza vp
      @ PRow(), PCol() + 1 SAY nKalkMarzaMP              PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPC                  PICTURE piccdem()
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) * 100  PICTURE picproc()
      @ PRow(), PCol() + 1 SAY nPDVCijena                PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSAPP              PICTURE piccdem()
      // =========  red 2 ===================
      @ PRow() + 1, 4 SAY IdTarifa + roba->tip
      @ PRow(), PCol() + 1 SAY "   " + ROBA->barkod
      @ PRow(), nCol0    SAY  kalk_pripr->fcj * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->nc * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->prevoz * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  _VPC * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  nKalkMarzaVP * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(), nMPos := PCol() + 1 SAY  nKalkMarzaMP * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(),  PCol() + 1 SAY  kalk_pripr->mpc * kalk_pripr->kolicina      PICTURE picdem()
      @ PRow(), nCol1    SAY pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) * 100   PICTURE picproc()
      @ PRow(),  PCol() + 1 SAY  nU6             PICTURE piccdem()
      @ PRow(),  PCol() + 1 SAY  nU7             PICTURE piccdem()

      // red 3
      IF Round( kalk_pripr->nc, 5 ) <> 0
         @ PRow() + 1, nMPos SAY ( nKalkMarzaMP / kalk_pripr->nc ) * 100  PICTURE picproc()
      ENDIF

      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF )
   ? cLinija
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nCol0      SAY  nTot1        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot1b       PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot2        PICTURE       picdem()

   nMarzaVP := nTotMarzaVP
   @ PRow(), PCol() + 1   SAY  nTotVPV        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTotMarzaVP        PICTURE       picdem()

   @ PRow(), PCol() + 1   SAY  nTotMarzaMP        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  nTot5        PICTURE       picdem()
   @ PRow(), PCol() + 1   SAY  Space( Len( picproc() ) )
   @ PRow(), PCol() + 1   SAY  nTot6        PICTURE        picdem()
   @ PRow(), PCol() + 1   SAY  nTot7        PICTURE        picdem()
   ? cLinija

   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl_11( cPKonto, cMKonto, cBrFaktP, dDatFaktP, cLine )

/*
   IF cIdvd == "11"
      ??U "ZADUŽENJE PRODAVNICE IZ MAGACINA"
   ELSEIF cIdVd == "12"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN"
   ELSEIF cIdVd == "13"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN RADI ZADUZENJA DRUGE PRODAVNICE"
   ENDIF
*/

   select_o_partner( cIdPartner )
   ? "OTPREMNICA Broj:", cBrFaktP, "Datum:", dDatFaktP

   // IF cIdvd == "11"
   select_o_konto( cPKonto )
   ?  _u( "Prodavnica zadužuje :" ), cPKonto, "-", AllTrim( konto->naz )
   select_o_konto( cMKonto )
   ?  _u( "Magacin razdužuje   :" ), cMKonto, "-", AllTrim( konto->naz )
   // ELSE
   // select_o_konto( cPKonto )
   // ?  "Storno Prodavnica zadužuje :", cPKonto, "-", AllTrim( konto->naz )
   // select_o_konto( cMKonto )
   // ?  "Storno Magacin razdužuje   :", cMKonto, "-", AllTrim( konto->naz )
   // ENDIF

   ? cLine
   ?U "*R *          *                ROBA                   * Količina *  NAB.CJ  *    NC    *  TROSAK  *   VP.CJ  *  MARŽA   *  MARŽA   * PROD.CJ  *   PDV %  *   PDV   * PROD.CJ  *"
   ?U "*BR*          *                                       *          *   U VP   *          *   U MP   *          *   VP     *   MP     * BEZ PDV  *          *         *  SA PDV  *"
   ?U "*  *          *                                       *          *          *          *          *          *          *          *          *          *         *          *"
   ? cLine

   RETURN .T.
