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
STATIC s_nRobaNazivSirina := 39

MEMVAR nStr
MEMVAR cIdFirma, cIdVd, cBrDok, cIdPartner, cBrFaktP, cPKonto // dDatFaktp
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

/*
   input cIdFirma, cIdVd, cBrDok

   kalk_pripr->rabatv - popust u maloprodaji (bez uracunatog poreza)
*/

FUNCTION kalk_stampa_dok_41_42_49()

   LOCAL nCol0, nCol1, nCol2
   LOCAL cLine
   LOCAL nPDVCijena
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt

   LOCAL nTotPopustBezPDV, nTotNabVr, nTotMarzaMPBruto, nTotMPVbezPDV, nTotPDV, nTotMpvBezPDVNeto
   LOCAL nTotMPVSaPDVNeto, nTotMPvSaPDV

   LOCAL nUPopustBezPDV, nUMarzaMPBruto, nUMPVbezPDV, nUPDV, nUMpvBezPDVNeto
   LOCAL nUMPVSaPDVNeto, nUMPvSaPDV

   PRIVATE nKalkMarzaVP, nKalkMarzaMP

   nKalkMarzaVP := nKalkMarzaMP := 0
   nStr := 0
   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   cPKonto := kalk_pripr->pKonto

   IF cIdVd == "49"
      cNaslov := "POS PRENOS PRODAJE"
   ELSEIF cIdVd == "41"
      cNaslov := "PRODAVNICA PRODAJA - KUPAC"
   ELSE
      cNaslov := "PRODAVNICA PRODAJA"
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

   cLine := linija_za_podvlacenje()
   bZagl := {|| kalk_naslov_41_42() }

   SELECT kalk_pripr

   nTotNabVr := nTotMarzaMPBruto := nTotMPVbezPDV := nTotPDV := nTotMpvSaPDV := nTotMpvBezPDVNeto := nTotPopustBezPDV := 0
   nTotMPVSaPDVNeto := 0

   Eval( bZagl )
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cBrDok == kalk_pripr->brdok .AND. cIdVD == kalk_pripr->idvd

      Scatter()
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_marza_realizacija_prodavnica_41_42()
      kalk_set_vars_troskovi_marzavp_marzamp()

      nPDVCijena := kalk_pripr->mpc * pdv_procenat_by_tarifa( kalk_pripr->idtarifa )
      print_nova_strana( 125, @nStr, 2 )
      nTotNabVr += iif( roba->tip == "U", 0, kalk_pripr->nc ) * kalk_pripr->kolicina
      nTotMarzaMPBruto += ( nUMarzaMPBruto := ( nKalkMarzaMP + kalk_pripr->rabatv ) * kalk_pripr->kolicina )
      nTotMPVbezPDV += ( nUMPVbezPDV := ( kalk_pripr->mpc + kalk_pripr->rabatv ) * kalk_pripr->kolicina )
      nTotPDV += ( nUPdv := nPDVCijena * kalk_pripr->kolicina )
      nTotMpvBezPDVNeto += ( nUMpvBezPDVNeto := ( kalk_pripr->mpc * kalk_pripr->kolicina ) )
      nTotMpvSaPDV += ( nUMpvSaPDV := kalk_pripr->mpcsapp * kalk_pripr->kolicina )
      nTotPopustBezPDV += ( nUPopustBezPDV := kalk_pripr->rabatv * kalk_pripr->kolicina )
      nTotMPVSaPDVNeto += ( nUMpvSaPDVNeto := ( kalk_pripr->mpc + nPDVCijena ) * kalk_pripr->kolicina )

      check_nova_strana( bZagl, s_oPDF, .F., 0 )
      // prvi red
      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), PCol() + 1 SAY kalk_pripr->IdRoba
      @ PRow(), PCol() + 1 SAY ROBA->barkod
      @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
      @ PRow(), PCol() + 1 SAY kalk_pripr->kolicina PICT pickol()
      nCol0 := PCol()
      @ PRow(), nCol0 SAY ""

      IF roba->tip = "U"
         @ PRow(), PCol() + 1 SAY 0 PICT piccdem()
      ELSE
         @ PRow(), PCol() + 1 SAY kalk_pripr->nc PICT piccdem()
      ENDIF
      @ PRow(), nCol1 := PCol() + 1 SAY nKalkMarzaMP + kalk_pripr->rabatv PICT piccdem() // marza bruto
      @ PRow(), PCol() + 1 SAY kalk_pripr->mpc + kalk_pripr->rabatv PICT piccdem() // mpc ili prodajna cijena uvecana za rabat
      @ PRow(), nCol2 := PCol() + 1 SAY kalk_pripr->rabatv PICT piccdem() // popust bez pdv
      @ PRow(), PCol() + 1 SAY kalk_pripr->mpc PICT piccdem() // mpc neto
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) PICT picproc()
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->mpc + nPDVCijena ) PICT piccdem() // mpc sa pdv neto
      @ PRow(), PCol() + 1 SAY kalk_pripr->mpcsapp PICT piccdem() // mpc sa pdv bruto

      // drugi red
      @ PRow() + 1, 4 SAY kalk_pripr->idtarifa
      @ PRow(), nCol0 SAY ""
      IF roba->tip == "U"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem()
      ELSE
         @ PRow(), PCol() + 1 SAY ( kalk_pripr->nc * kalk_pripr->kolicina ) PICT picdem()
      ENDIF
      @ PRow(), PCol() + 1 SAY nUMarzaMPBruto PICT picdem()
      @ PRow(), PCol() + 1 SAY nUMPvBezPDV PICT picdem()
      @ PRow(), PCol() + 1 SAY nUPopustBezPDV PICT picdem()
      @ PRow(), PCol() + 1 SAY nUMpvBezPDVNeto PICT picdem()
      @ PRow(), PCol() + 1 SAY nUPdv PICT piccdem()
      @ PRow(), PCol() + 1 SAY nUMpvSaPDVNeto PICT piccdem()
      @ PRow(), PCol() + 1 SAY nUMpvSaPDV PICT picdem()

      // treći red
      IF Round( kalk_pripr->nc, 4 ) <> 0
         @ PRow() + 1, nCol1 SAY ( nKalkMarzaMP / kalk_pripr->nc ) * 100 PICT picproc()
      ELSE
         @ PRow() + 1, nCol1 SAY 0 PICT picproc()
      ENDIF
      @ PRow(), nCol2 SAY kalk_pripr->rabatv / ( kalk_pripr->mpc + kalk_pripr->rabatv ) * 100 PICT picproc() // procenat popusta u malaprodaji
      SKIP 1

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   ? cLine
   @ PRow() + 1, 0 SAY "Ukupno:"
   @ PRow(), nCol0 SAY ""
   @ PRow(), PCol() + 1 SAY nTotNabVr PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotMarzaMPBruto PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotMPVbezPDV PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotPopustBezPDV PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotMpvBezPDVNeto PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotPDV PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotMPVSaPDVNeto PICT picdem()
   @ PRow(), PCol() + 1 SAY nTotMpvSaPDV PICT picdem()
   ? cLine

   check_nova_strana( bZagl, s_oPDF, .F., 8 )
   PushWa()
   kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, bZagl )
   PopWa()
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


FUNCTION kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, bZagl )

   LOCAL nTotMpvNeto
   LOCAL nTotPDV
   LOCAL nTotRealizovanaRuc
   LOCAL nTotPopustBezPDV
   LOCAL cLine
   LOCAL cIdTarifa
   LOCAL nUMpvNeto
   LOCAL nUPdv
   LOCAL nUMPvSaPDV
   LOCAL nTotMPvSaPDV
   LOCAL nUPopustBezPDV
   LOCAL nCol1

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   SEEK cIdfirma + cIdvd + cBrdok

   cLine := linija_za_podvlacenje_pdv()
   ? cLine
   ?  "* Tar *  PDV%    *   MPV    *  Popust  * MPV NETO *   PDV   * MPV NETO *  MPV    *"
   ?  "*     *          *  b.PDV   *  b.PDV   *  b.PDV   *   PDV   *  sa PDV  * sa PDV  *"
   ? cLine

   nTotMpvNeto := 0
   nTotPDV := 0
   nTotMPVSaPDV := 0
   nTotRealizovanaRuc := 0
   nTotPopustBezPDV := 0

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   DO WHILE !Eof() .AND. cIdfirma + cIdvd + cBrDok == kalk_pripr->idfirma + kalk_pripr->idvd + kalk_pripr->brdok
      cIdTarifa := kalk_pripr->idtarifa
      nUMpvNeto := 0
      nUPdv := 0
      nUMPvSaPDV := 0
      nUPopustBezPDV := 0
      select_o_tarifa( cIdtarifa )
      SELECT kalk_pripr
      DO WHILE !Eof() .AND. cIdfirma + cIdVd + cBrDok == kalk_pripr->idFirma + kalk_pripr->idVd + kalk_pripr->brDok ;
            .AND. kalk_pripr->idTarifa == cIdTarifa
         select_o_roba( kalk_pripr->idroba )
         SELECT kalk_pripr
         nUMpvNeto += kalk_pripr->mpc * kalk_pripr->kolicina
         nUPdv += kalk_pripr->mpc * pdv_procenat_by_tarifa( kalk_pripr->idtarifa ) * kalk_pripr->kolicina
         nUMPvSaPDV += kalk_pripr->mpcsapp * kalk_pripr->kolicina
         nUPopustBezPDV += kalk_pripr->rabatv * kalk_pripr->kolicina
         nTotRealizovanaRuc += ( kalk_pripr->mpc - kalk_pripr->nc ) * kalk_pripr->kolicina
         SKIP
      ENDDO
      nTotMpvNeto += nUMpvNeto
      nTotPDV += nUPdv
      nTotMPVSaPDV += nUMPvSaPDV
      nTotPopustBezPDV += nUPopustBezPDV

      check_nova_strana( bZagl, s_oPDF, .F., 3 )
      ? cIdtarifa
      @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( cIdTarifa ) PICT picproc()
      nCol1 := PCol()
      @ PRow(), nCol1 + 1 SAY nUMpvNeto + nUPopustBezPDV PICT picdem()
      @ PRow(), PCol() + 1 SAY nUPopustBezPDV PICT picdem()
      @ PRow(), PCol() + 1 SAY nUMpvNeto PICT picdem()
      @ PRow(), PCol() + 1 SAY nUPdv PICT picdem()
      @ PRow(), PCol() + 1 SAY ( nUMpvNeto + nUPdv ) PICT picdem()
      @ PRow(), PCol() + 1 SAY nTotMPvSaPDV PICT picdem()

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   ? cLine
   ? "UKUPNO"
   @ PRow(), nCol1 + 1 SAY ( nTotMpvNeto + nTotPopustBezPDV ) PICT picdem() // MPV bruto
   @ PRow(), PCol() + 1 SAY nTotPopustBezPDV PICT picdem()  // popust
   @ PRow(), PCol() + 1 SAY nTotMpvNeto PICT picdem() // MPV neto
   @ PRow(), PCol() + 1 SAY nTotPDV PICT picdem() // pdv
   @ PRow(), PCol() + 1 SAY ( nTotMpvNeto + nTotPDV ) PICT picdem() // mpv neto + pdv = mpv neto sa pdv
   @ PRow(), PCol() + 1 SAY nTotMPVSaPDV PICT picdem() // mpv sa pdv bruto

   ? cLine
   ? "        REALIZOVANI (NETO) RUC:"
   @ PRow(), PCol() + 1 SAY nTotRealizovanaRuc PICT picdem()
   ? "    UKUPNO POPUST bez PDV U MP:"
   @ PRow(), PCol() + 1 SAY nTotPopustBezPDV PICT picdem()
   ? cLine

   RETURN .T.


STATIC FUNCTION kalk_naslov_41_42()

   LOCAL cLine

   PushWa()
   select_o_partner( cIdPartner )
   IF cIdVd == "41"
      ?  "KUPAC:", cIdPartner, "-", PadR( partn->naz, 20 ), Space( 5 ), "DOKUMENT Broj:", cBrFaktP
   ENDIF

   select_o_konto( cPKonto )
   ?  _u( "Prodavnički konto razdužuje:" ), cPKonto, "-", PadR( konto->naz, 60 )

   cLine := linija_za_podvlacenje( cIdVd )
   ? cLine

   ?U "*R * ROBA     *" + PadC( "Barkod", 13 ) + "*" + PadC( "Naziv", s_nRobaNazivSirina + 5 ) + ;
      "* Količina *  NAB.CJ  *  MARZA  * MPC bPDV *  Popust   * MPV NETO *   PDV %  *  MPC/MPV * MPC/MPV *"

   ?U "*BR*          *" + PadC( "      ", 13 ) + "*" + PadC( "     ", s_nRobaNazivSirina + 5 ) + ;
      "*          *   U MP    * (bruto) * MPV bPDV * (bez PDV) *(bez PDV)*   PDV    *   NETO   * SA PDV  *"

   ? cLine
   PopWa()

   RETURN NIL


STATIC FUNCTION linija_za_podvlacenje()

   LOCAL cLine

   cLine := "--- ---------- " + Replicate( "-", 13 ) + " " + Replicate( "-", s_nRobaNazivSirina + 5 ) + ;
      " ---------- ---------- ---------- ---------- ---------- ----------"
   cLine += " ---------- ---------- ----------"

   RETURN cLine


STATIC FUNCTION linija_za_podvlacenje_pdv()

   LOCAL cLine
   LOCAL nI

   cLine := "------ "
   FOR nI := 1 TO 7
      cLine += Replicate( "-", 10 ) + " "
   NEXT

   RETURN cLine
