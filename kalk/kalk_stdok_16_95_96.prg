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
STATIC s_nLijevaMargina := 4

MEMVAR nKalkMarzaVP
MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR cIdFirma, cIdVd, cBrDok

FUNCTION kalk_stampa_dok_16_95_96()

   LOCAL cPom
   LOCAL _page_len := RPT_PAGE_LEN
   LOCAL lVPC := .F.
   LOCAL nVPC, nUVPV, nTVPV, nTotVPV
   LOCAL nTotNv, nTot6, nTot7, nTot8, nTot9, nTota, nTotb, nTotc, nTotd
   LOCAL nUNv, nTNv
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt
   LOCAL cMKonto, cIdKonto2
   LOCAL cIdKontoGlavni
   LOCAL nC1, nC2, nC3
   LOCAL cIdPartner, cBrFaktP
   LOCAL nMarzaVPStopa, nTMarzaVP, nTotMarzaVP

   SELECT kalk_pripr
   cIdFirma := kalk_pripr->idfirma
   cIdVd := kalk_pripr->idvd
   cBrDok := kalk_pripr->brdok

   cIdPartner := field->IdPartner
   cBrFaktP := field->BrFaktP
   // dDatFaktP := field->DatFaktP
   cMKonto := field->mkonto
   cIdKonto2 := field->IdKonto2
   // cIdZaduz2 := field->IdZaduz2

   cNaslov := _get_naslov_dokumenta( cIdVd ) + ": " + cIdFirma + "-" + cIdVD + "-" + AllTrim( cBrDok ) + "  Datum:" +  DToC( field->datdok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF


   bZagl := {|| zagl( cIdVd, cMKonto, cIdKonto2, @lVpc ) }
   // IF !Empty( cIdZaduz2 )
   // select_o_fakt_objekti( cIdZaduz2 )
   // ? PadL( "Rad.nalog:", 14 ), AllTrim( cIdZaduz2 ) + " - " + AllTrim( fakt_objekti->naz )
   // ENDIF

   Eval( bZagl )
   nTot6 := nTot7 := nTot8 := nTot9 := nTota := nTotb := nTotc := nTotd := 0
   nTotNv := 0
   nTotMarzaVP := 0
   nTotVPV := 0

   DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cBrDok == field->BrDok .AND. cIdVD == field->IdVD

      nTNv := 0
      nTVPV := 0
      nTMarzaVP := 0
      cBrFaktP := field->brfaktp
      // dDatFaktP := field->datfaktp
      cIdpartner := field->idpartner
      select_o_partner( cIdPartner )
      SELECT kalk_pripr

      DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cBrDok == field->BrDok .AND. cIdVD == field->IdVD ;
            .AND. field->idpartner + field->brfaktp == cIdpartner + cBrfaktp

         // IF field->tbanktr == "X" // izgenerisani dokument
         // SKIP 1
         // LOOP
         // ENDIF

         select_o_roba( kalk_pripr->idroba )
         select_o_tarifa( kalk_pripr->idtarifa )
         SELECT kalk_pripr
         kalk_set_vars_troskovi_marzavp_marzamp()

         check_nova_strana( bZagl, s_oPDF )
         nTNv += ( nUNv := Round( field->nc * field->kolicina, 2 ) )

         @ PRow() + 1, s_nLijevaMargina SAY field->rbr PICT "99999"
         IF field->idvd == "16"
            cIdKontoGlavni := field->idkonto
         ELSE
            cIdKontoGlavni := field->idkonto2
         ENDIF
         ?? "  ", PadR( cIdKontoGlavni, 7 ), PadR( AllTrim( field->idroba ) + "-" + AllTrim( roba->naz ) + " (" + AllTrim( roba->jmj ) + ")", 60 )
         @ PRow(), PCol() + 1 SAY field->kolicina PICT pickol()
         @ PRow(), PCol() + 1 SAY field->nc PICT piccdem()
         @ PRow(), nC1 := PCol() + 1 SAY nUNv PICT picdem()
         IF lVPC
            nVPC := vpc_magacin_rs_priprema
            SELECT kalk_pripr
            nUVPV := nVPC * field->kolicina
            // nv * (marzavp% + 1) = vpv =>  marzavp% = vpv/nv - 1 x 100%
            IF Round( nUNV, 4 ) == 0
               nMarzaVPStopa :=  0
            ELSE
               nMarzaVPStopa := ( nUVPV / nUNV - 1 ) * 100
            ENDIF
            @ PRow(), PCol() + 1 SAY nVPC PICT piccdem()
            @ PRow(), PCol() + 1 SAY nMarzaVPStopa PICT picproc()
            @ PRow(), nC2 := PCol() + 1 SAY nUVPV - nUNV PICT picdem()
            @ PRow(), nC3 := PCol() + 1 SAY nUVPV PICT picdem()
            nTMarzaVP += Round( nUVPV - nUNV, 2 )
            nTVPV += Round( nUVPV, 2 )

         ENDIF
         SKIP

      ENDDO

      nTotNv += nTNv
      IF lVPC
         nTotMarzaVP += nTMarzaVP
         nTotVPV += nTVPV
      ENDIF
      ? s_cLinija

      check_nova_strana( bZagl, s_oPDF, .F., 3 )

      // ukupno za dokument
      // @ PRow() + 1, 0 SAY "Ukupno za: "
      // ?? AllTrim( cIdpartner ) +  " - " + AllTrim( partn->naz )
      ? Space( s_nLijevaMargina ) + "Broj fakture:", AllTrim( cBrFaktP )
      @ PRow(), nC1 SAY nTNv PICT picdem()
      IF lVPC
         @ PRow(), nC2 SAY nTMarzaVP PICT picdem()
         @ PRow(), nC3 SAY nTVPV PICT picdem()
      ENDIF
      ? s_cLinija

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 3 )
   ? s_cLinija
   @ PRow() + 1, s_nLijevaMargina SAY "Ukupno za sve dokumente:"
   @ PRow(), nC1 SAY nTotNv PICT picdem()
   IF lVPC
      @ PRow(), nC2 SAY nTotMarzaVP PICT picdem()
      @ PRow(), nC3 SAY nTotVPV PICT picdem()
   ENDIF
   ? s_cLinija

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


FUNCTION is_magacin_evidencija_vpc( cMKonto )

   LOCAL lVPC := .F.

altd()
   select_o_koncij( cMKonto )
   IF koncij->region == "RS"
      lVPC := .T.
   ENDIF

   RETURN lVpc


STATIC FUNCTION zagl( cIdVd, cMKonto, cIdkonto2, lVpc )

   LOCAL cPom

   ?
   PushWa()
   IF cIdVd $ "95#96"
      lVPC := is_magacin_evidencija_vpc( cMKonto )
      cPom := "Razdužuje:"
      select_o_konto( cMKonto )
      ? Space( s_nLijevaMargina ) + PadR( _u( cPom ), 14 ), AllTrim( cMKonto ) + " - " + PadR( konto->naz, 60 )

      IF !Empty( cIdKonto2 )
         cPom := "Zadužuje:"
         select_o_konto( cIdKonto2 )
         ? Space( s_nLijevaMargina ) + PadR( _u( cPom ), 14 ), AllTrim( cIdKonto2 ) + " - " + PadR( konto->naz, 60 )
      ENDIF

   ELSE // 16
      lVPC := is_magacin_evidencija_vpc( cMKonto )
      cPom := "Zadužuje:"
      select_o_konto( cMKonto )
      ? Space( s_nLijevaMargina ) + PadR( _u( cPom ), 14 ), AllTrim( cMKonto ) + " - " + PadR( konto->naz, 60 )

      IF !Empty( cIdKonto2 )
         cPom := "Razdužuje:"
         select_o_konto( cIdKonto2 )
         ? Space( s_nLijevaMargina ) + PadR( _u( cPom ), 14 ), AllTrim( cIdKonto2 ) + " - " + PadR( konto->naz, 60 )
      ENDIF
   ENDIF
   ?

   s_cLinija := get_linija( lVPC )
   ? s_cLinija
   ?U Space( s_nLijevaMargina ) + "*Rbr.* Konto * ARTIKAL  (šifra-naziv-jmj)                                 * Količina *   NC     *    NV     *"
   IF lVPC
      ??U "   VPC   *  Marža % *   Marža  *   VPV   *"
   ENDIF
   ? s_cLinija

   PopWa()

   RETURN .T.


STATIC FUNCTION get_linija( lVPC )

   LOCAL cLine := Space( s_nLijevaMargina )

   hb_default( @lVPC, .F. )
   cLine += Replicate( "-", 5 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 7 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 60 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 10 )
   IF lVPC
      cLine += Space( 1 )
      cLine += Replicate( "-", 10 )
      cLine += Space( 1 )
      cLine += Replicate( "-", 10 )
      cLine += Space( 1 )
      cLine += Replicate( "-", 10 )
      cLine += Space( 1 )
      cLine += Replicate( "-", 10 )
   ENDIF

   RETURN cLine


STATIC FUNCTION _get_naslov_dokumenta( cIdVd )

   LOCAL cRet := ""

   IF cIdVd == "16"
      cRet := "PRIJEM U MAGACIN (INTERNI DOKUMENT)"
   ELSEIF cIdVd == "96"
      cRet := "OTPREMA IZ MAGACINA (INTERNI DOKUMENT)"
   ELSEIF cIdVd == "95"
      cRet := "OTPIS MAGACIN"
   ENDIF

   RETURN cRet
