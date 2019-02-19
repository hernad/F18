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

MEMVAR m

MEMVAR nKalkPrevoz
MEMVAR nKalkBankTr
MEMVAR nKalkSpedTr
MEMVAR nKalkCarDaz
MEMVAR nKalkZavTr
MEMVAR nKalkMarzaVP, nKalkMarzaMP

FUNCTION kalk_stampa_dok_16_95_96()

   LOCAL cKto1
   LOCAL cKto2

   // LOCAL cIdZaduz2
   LOCAL cPom
   LOCAL cNaslov
   LOCAL nCol1 := nCol2 := 0, nPom := 0
   LOCAL _page_len := RPT_PAGE_LEN
   LOCAL lVPC := .F.
   LOCAL nVPC, nUVPV, nTVPV, nTotVPV

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP

   nStr := 0
   cIdPartner := field->IdPartner
   cBrFaktP := field->BrFaktP
   // dDatFaktP := field->DatFaktP
   cIdKonto := field->IdKonto
   cIdKonto2 := field->IdKonto2
   // cIdZaduz2 := field->IdZaduz2

   P_12CPI
   ?? "KALK BR:", cIdFirma + "-" + cIdVD + "-" + AllTrim( cBrDok ), "  Datum:", field->datdok

   @ PRow(), 76 SAY "Str:" + Str( ++nStr, 3 )
   cNaslov := _get_naslov_dokumenta( cIdVd )

   ?
   ? cNaslov
   ?
   IF cIdVd $ "95#96"
      cPom := "Razduzuje:"
      cKto1 := cIdKonto2
      cKto2 := cIdKonto
   ELSE
      cPom := "Zaduzuje:"
      cKto1 := cIdKonto
      cKto2 := cIdKonto2
   ENDIF

   lVPC := is_magacin_evidencija_vpc( cKto1 )
   select_o_konto( cKto1 )
   ? PadL( cPom, 14 ), AllTrim( cKto1 ) + " - " + PadR( konto->naz, 60 )

   IF !Empty( cKto2 )
      IF cIdVd $ "95#96"
         cPom := "Zaduzuje:"
      ELSE
         cPom := "Razduzuje:"
      ENDIF
      select_o_konto( cKto2 )
      ? PadL( cPom, 14 ), AllTrim( cKto2 ) + " - " + PadR( konto->naz, 60 )
   ENDIF

   // IF !Empty( cIdZaduz2 )
   // select_o_fakt_objekti( cIdZaduz2 )
   // ? PadL( "Rad.nalog:", 14 ), AllTrim( cIdZaduz2 ) + " - " + AllTrim( fakt_objekti->naz )
   // ENDIF

   ?
   SELECT kalk_pripr
   P_10CPI
   P_COND
   m := _get_line( lVPC )
   ? m
   ?U "*Rbr.* Konto * ARTIKAL  (šifra-naziv-jmj)                                 * Količina *   NC     *    NV     *"
   IF lVPC
      ??U "   PC    *    PV     *"
   ENDIF
   ? m

   nTot4 := nTot5 := nTot6 := nTot7 := nTot8 := nTot9 := nTota := nTotb := nTotc := nTotd := 0
   nTotVPV := 0

   // PRIVATE cIdd := field->idpartner + field->brfaktp + field->idkonto + field->idkonto2
   DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cBrDok == field->BrDok .AND. cIdVD == field->IdVD

      nT4 := nT5 := nT8 := nTVPV := 0
      cBrFaktP := field->brfaktp
      // dDatFaktP := field->datfaktp
      cIdpartner := field->idpartner
      select_o_partner( cIdPartner )
      SELECT kalk_pripr

      DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cBrDok == field->BrDok .AND. cIdVD == field->IdVD ;
            .AND. field->idpartner + field->brfaktp == cIdpartner + cBrfaktp

         IF cIdVd $ "97" .AND. field->tbanktr == "X"
            SKIP 1
            LOOP
         ENDIF

         select_o_roba( kalk_pripr->idroba )
         select_o_tarifa( kalk_pripr->idtarifa )
         SELECT kalk_pripr
         kalk_set_vars_troskovi_marzavp_marzamp()
         print_nova_strana( 125, @nStr, 5 )

         // sKol := field->kolicina
         // NV
         nT4 += ( nU4 := field->nc * field->kolicina )

         @ PRow() + 1, 0 SAY field->rbr PICT "99999"
         IF field->idvd == "16"
            cNKonto := field->idkonto
         ELSE
            cNKonto := field->idkonto2
         ENDIF

         @ PRow(), 6 SAY ""
         ?? PadR( cNKonto, 7 ), PadR( AllTrim( field->idroba ) + "-" + AllTrim( roba->naz ) + " (" + AllTrim( roba->jmj ) + ")", 60 )
         @ PRow(), nC1 := PCol() + 1 SAY field->kolicina PICT pickol()
         @ PRow(), PCol() + 1 SAY field->nc PICT piccdem
         @ PRow(), PCol() + 1 SAY nU4 PICT picdem()
         IF lVPC
            nVPC := vpc_magacin_rs( .T. )
            SELECT kalk_pripr
            nTVPV += ( nUVPV := nVPC * field->kolicina )
            @ PRow(), PCol() + 1 SAY nVPC PICT piccdem
            @ PRow(), PCol() + 1 SAY nUVPV PICT picdem()
         ENDIF
         SKIP

      ENDDO

      nTot4 += nT4
      // nTot5 += nT5
      // nTot8 += nT8
      IF lVPC
         nTotVPV += nTVPV
      ENDIF
      ? m

      print_nova_strana( 125, @nStr, 5 )
      @ PRow() + 1, 0 SAY "Ukupno za: "
      ?? AllTrim( cIdpartner ) +  " - " + AllTrim( partn->naz )
      print_nova_strana( 125, @nStr, 5 )
      ? "Broj fakture:", AllTrim( cBrFaktP )  // , "/", dDatFaktp
      @ PRow(), nC1 SAY 0 PICT "@Z " + piccdem
      @ PRow(), PCol() + 1 SAY nT4 PICT picdem()
      IF lVPC
         @ PRow(), PCol() + 1 SAY 0 PICT "@Z " + piccdem
         @ PRow(), PCol() + 1 SAY nTotVPV PICT picdem()
      ENDIF
      ? m

   ENDDO

   print_nova_strana( 125, @nStr, 5 )

   ? m
   @ PRow() + 1, 0 SAY "Ukupno:"
   @ PRow(), nC1 SAY 0 PICT "@Z " + piccdem()
   @ PRow(), PCol() + 1 SAY nTot4 PICT picdem()
   IF lVPC
      @ PRow(), PCol() + 1 SAY 0 PICT "@Z " + piccdem()
      @ PRow(), PCol() + 1 SAY nTotVPV PICT picdem()
   ENDIF
   ? m

   RETURN .T.


FUNCTION is_magacin_evidencija_vpc( cIdKonto )

   LOCAL lVPC := .F.

   select_o_koncij( cIdKonto )
   IF koncij->region == "RS"
      lVPC := .T.
   ENDIF

   RETURN lVpc


STATIC FUNCTION _get_naslov_dokumenta( cIdVd )

   LOCAL cRet := "????"

   IF cIdVd == "16"
      cRet := "PRIJEM U MAGACIN (INTERNI DOKUMENT):"
   ELSEIF cIdVd == "96"
      cRet := "OTPREMA IZ MAGACINA (INTERNI DOKUMENT):"
      // ELSEIF cIdVd == "97"
      // cRet := "PREBACIVANJE IZ MAGACINA U MAGACIN (INTERNI DOKUMENT):"
   ELSEIF cIdVd == "95"
      cRet := "OTPIS MAGACIN:"
   ENDIF

   RETURN cRet


STATIC FUNCTION _get_line( lVPC )

   LOCAL cLine := ""

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
   cLine += Replicate( "-", 11 )
   IF lVPC
      cLine += Space( 1 )
      cLine += Replicate( "-", 10 )
      cLine += Space( 1 )
      cLine += Replicate( "-", 11 )
   ENDIF

   RETURN cLine
