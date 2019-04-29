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
STATIC s_cLinija
STATIC s_nRobaSirina := 40

MEMVAR _IdFirma, _DatFaktP, _IdKonto, _IdKonto2, _kolicina, _idvd, _mkonto, _pkonto, _mpcsapp, _mpc, _nc, _fcj, _idroba, _idtarifa, _datdok
MEMVAR _MU_I, _PU_I, _VPC, _IdPartner
MEMVAR _TBankTr, _GKolicina, _GKolicin2, _Marza2, _TMarza2
MEMVAR cIdPar
MEMVAR cIdFirma, cIdVd, cBrDok, cPKonto
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

FUNCTION kalk_stampa_dok_19_79()

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt
   LOCAL nMpcSaPDVNovaCijena, nMpcSaPDVStaraCijena, nMpcBezPDVNovaCijena, nMpcBezPDVStaraCijena
   LOCAL nPDVNovaCijena, nPDVStaraCijena
   LOCAL nTot1, nTot2, nTot3, nTotPDV, nTotMPVsaPDV, nTot6, nTot7
   LOCAL nU3, nU4, nU5
   LOCAL nC0, nC1, nC2, nC3
   LOCAL dDatOd, dDatDo, cOpis

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   cIdFirma := kalk_pripr->IdFirma
   cIdVd := kalk_pripr->Idvd
   cBrDok := kalk_pripr->brdok
   cPKonto := kalk_pripr->pkonto

   IF cIdVd == POS_IDVD_ZAHTJEV_SNIZENJE
      cNaslov := "ZAHTJEV ZA SNIŽENJE"
   ELSEIF cIdVd == POS_IDVD_POS_NIVELACIJA
      cNaslov := "POS Nivelacija"
   ELSEIF cIdVd == POS_IDVD_ODOBRENO_SNIZENJE
      cNaslov := "ODOBRENO SNIŽENJE"
   ELSEIF cIdVd == POS_IDVD_AKCIJSKE_CIJENE
      cNaslov := "Zahtjev za nivelaciju"
   ELSE
      cNaslov := "NIVELACIJA"
   ENDIF

   IF FieldPos( "dat_od" ) == 0
      find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
      dDatOd := kalk_doks->dat_od
      dDatDo := kalk_doks->dat_do
      cOpis := kalk_doks->opis
   ELSE
      dDatOd := kalk_pripr->dat_od
      dDatDo := kalk_pripr->dat_do
      cOpis := kalk_pripr->opis
   ENDIF

   cNaslov += " " + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   select_o_konto( cPKonto )
   ?  _u( "KONTO zadužuje :" ), cPKonto, "-", konto->naz

   SELECT kalk_pripr

   s_cLinija := "--- ---------- " + Replicate( "-", 40 ) + " ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"

   bZagl := {|| zagl( dDatOd, dDatDo, cOpis ) }
   nTot1 := nTot2 := nTot3 := nTotPDV := nTotMPVsaPDV := nTot6 := nTot7 := 0

   Eval( bZagl )
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVd == kalk_pripr->IdVd

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_set_vars_troskovi_marzavp_marzamp()

      // nova cijena
      nMpcSaPDVNovaCijena := kalk_pripr->mpcSaPP + kalk_pripr->fcj
      nMpcBezPDVNovaCijena := mpc_bez_pdv_by_tarifa( kalk_pripr->idtarifa, nMpcSaPDVNovaCijena )

      // stara cijena
      nMpcSaPDVStaraCijena := field->fcj
      nMpcBezPDVStaraCijena := mpc_bez_pdv_by_tarifa( kalk_pripr->idtarifa, nMpcSaPDVStaraCijena )

      nTot3 +=  ( nU3 := kalk_pripr->MPC * kalk_pripr->Kolicina )
      nPDVNovaCijena := nMpcSaPDVNovaCijena - nMpcBezPDVNovaCijena
      nPDVStaraCijena := nMpcSaPDVStaraCijena - nMpcBezPDVStaraCijena

      nTotPDV +=  ( nU4 := ( nPDVNovaCijena - nPDVStaraCijena ) * kalk_pripr->Kolicina )
      nTotMPVsaPDV +=  ( nU5 := kalk_pripr->MPcSaPP * kalk_pripr->Kolicina )

      check_nova_strana( bZagl, s_oPDF )
      // 1. red
      @ PRow() + 1, 0 SAY  kalk_pripr->Rbr PICTURE "999"
      nC3 := PCol() + 1
      @ PRow(), PCol() + 1 SAY  kalk_pripr->idRoba
      nC2 := PCol() + 1
      @ PRow(), PCol() + 1 SAY  PadR( Trim( ROBA->naz ) + " (" + ROBA->jmj + ")", s_nRobaSirina )

      @ PRow(), PCol() + 1 SAY kalk_pripr->Kolicina             PICTURE pickol()
      @ PRow(), PCol() + 1 SAY kalk_pripr->FCJ                  PICTURE piccdem()
      nC0 := PCol() + 1
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPC                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) * 100   PICTURE picproc()
      nC1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY nPDVNovaCijena                         PICTURE picdem()
      @ PRow(), PCol() + 1 SAY nPDVNovaCijena * kalk_pripr->Kolicina     PICTURE picdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSAPP                       PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSAPP + kalk_pripr->FCJ     PICTURE piccdem()

      // 2. red
      @ PRow() + 1, nC3 SAY kalk_pripr->idtarifa
      @ PRow(), nC2 SAY roba->barkod
      @ PRow(), nC1        SAY nPDVStaraCijena   PICTURE picdem()
      @ PRow(), PCol() + 1 SAY nPDVStaraCijena * kalk_pripr->Kolicina  PICTURE picdem()

      IF Round( field->FCJ, 4 ) == 0
         @ PRow(), PCol() + 1 SAY 9999999  PICTURE picproc() // error fcj=0
      ELSE
         @ PRow(), PCol() + 1 SAY ( field->MPCSAPP / field->FCJ ) * 100  PICTURE picproc()
      ENDIF
      @ PRow(), PCol() + 1 SAY Space( Len( piccdem() ) )
      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 4 )
   ? s_cLinija
   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nC0          SAY  nTot3         PICTURE        picdem()
   @ PRow(), PCol() + 1   SAY  Space( Len( picdem() ) )
   @ PRow(), PCol() + 1   SAY  Space( Len( picdem() ) )
   @ PRow(), PCol() + 1   SAY  nTotPDV         PICTURE        picdem()
   @ PRow(), PCol() + 1   SAY  nTotMPVsaPDV         PICTURE        picdem()
   ? s_cLinija
   ?
   check_nova_strana( bZagl, s_oPDF, .F., 10 )
   kalk_pripr_rekap_tarife( {|| check_nova_strana( bZagl, s_oPDF, .F., 5 ) } )
   kalk_clanovi_komisije()

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl( dDatOd, dDatDo, cOpis )

   IF !Empty( cOpis )
      ? "Opis:", _u( Trim( cOpis ) )
   ENDIF
   ? _u( "Važeći period" ), dDatOd, "-", dDatDo
   ? s_cLinija
   ?U "*R * ROBA                                              * Količina *  STARA   * RAZLIKA  *   PDV%   * Izn.PDV  * Uk.PDV  * RAZLIKA  *  NOVA    *"
   ?U "*BR*                                                   *          * MPCsaPDV *   MPC    *          * N/Stara  * N/Stara * MPCsaPDV * MPCsaPDV *"
   ? s_cLinija

   RETURN .T.



/* kalk_obrazac_promjene_cijena_19()
 *     Stampa dokumenta tipa 19 - obrazac nivelacije
 */

FUNCTION kalk_obrazac_promjene_cijena_19()

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL xPrintOpt, bZagl
   LOCAL GetList := {}
   LOCAL cNaslov

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   cPKonto := kalk_pripr->pkonto

   cProred := "D"
   cPodvuceno := "N"
   Box(, 2, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Prikazati sa proredom:" GET cProred VALID cprored $ "DN" PICT "@!"

   READ
   ESC_BCR
   BoxC()

   cNaslov := "OBRAZAC PROMJENE CIJENA"

   // START PRINT CRET
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF

   ?
   Preduzece()
   ? PadL( "Prodavnica __________________________", 74 )
   ?
   ?
   ? PadC( "PROMJENA CIJENA U PRODAVNICI ___________________, Datum _________", 80 )
   ?


   SELECT kalk_pripr

   cIdFirma := kalk_pripr->IdFirma
   cIdVd := kalk_pripr->Idvd
   cBrDok := kalk_pripr->brdok

   nTot1 := nTot2 := nTot3 := nTotPDV := nTotMPVsaPDV := nTot6 := nTot7 := 0

   s_cLinija := "--- --------------------------------------------------- ---------- ---------- ---------- ------------- -------------"

   bZagl := {|| zagl_obrazac() }
   Eval( bZagl )
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND. cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr

      check_nova_strana( bZagl, s_oPDF, .F., 2 )
      IF cProred == "D"
         ?
      ENDIF
      ?
      ?? Transform( kalk_pripr->rbr, '999' ) + " " + kalk_pripr->idroba + " " + PadR( Trim( Left( ROBA->naz, 40 ) ) + " (" + ROBA->jmj + ")", 40 )
      @ PRow(), PCol() + 1 SAY kalk_pripr->FCJ                  PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSAPP + kalk_pripr->FCJ          PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY kalk_pripr->MPCSAPP              PICTURE piccdem()
      @ PRow(), PCol() + 1 SAY "_____________"
      @ PRow(), PCol() + 1 SAY "_____________"

      SKIP

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   ? s_cLinija
   ? " UKUPNO "
   ? s_cLinija
   ?
   ?
   ?

   kalk_clanovi_komisije()
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl_obrazac()

   ?U s_cLinija
   ?U "*R *  Sifra   *        Naziv                           *  STARA   *   NOVA   * promjena *  zaliha     *  ukupno    *"
   ?U "*BR*          *                                        *  cijena  *  cijena  *  cijene  * (količina)  * promjena   *"
   ?U s_cLinija

   RETURN .T.
