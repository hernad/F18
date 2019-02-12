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

MEMVAR aPorezi
MEMVAR nStr
MEMVAR nPrevoz, nBankTr, nSpedTr, nMarza, nMarza2, nCarDaz, nZavTr

MEMVAR cIdFirma, cIdVd, cBrDok, cIdPartner, cBrFaktP, cPKonto //dDatFaktp

/*
   input cIdFirma, cIdVd, cBrDok

   kalk_pripr->rabatv - popust u maloprodaji (bez uracunatog poreza)
*/

FUNCTION kalk_stampa_dok_41_42()

   LOCAL nCol0
   LOCAL nCol1
   LOCAL cLine
   LOCAL nMPos
   LOCAL nTot3, nTot4, nTot5, nTotPorez, nTot7, nTot8, nTotPopust
   LOCAL nTot4a, nTotMPP
   LOCAL nU3, nU4, nU5, nU6, nU7, nU8, nU9, nUMPP
   LOCAL nPor1
   LOCAL aIPor
   LOCAL cNaslov
   LOCAL bZagl, xPrintOpt

   PRIVATE nMarza, nMarza2, aPorezi

   nMarza := nMarza2 := 0
   aPorezi := {}
   nStr := 0
   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   //dDatFaktP := kalk_pripr->DatFaktP
   cPKonto := kalk_pripr->pKonto

   IF cIdVd == "41"
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

   nTot3 := nTot4 := nTot5 := nTotPorez := nTot7 := nTot8 := nTotPopust := 0
   nTot4a := 0
   nTotMPP := 0

   Eval( bZagl )
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cBrDok == kalk_pripr->brdok .AND. cIdVD == kalk_pripr->idvd

      Scatter()
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_marza_realizacija_prodavnica()
      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idRoba, @aPorezi, kalk_pripr->idtarifa )

      // uracunaj i popust
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, kalk_pripr->mpc, kalk_pripr->mpcsapp, kalk_pripr->nc )
      nPor1 := aIPor[ 1 ]
      print_nova_strana( 125, @nStr, 2 )
      // nabavna vrijednost
      nTot3 += ( nU3 := iif( roba->tip = "U", 0, kalk_pripr->nc ) * kalk_pripr->kolicina )
      // marza
      nTot4 += ( nU4 := nMarza2 * kalk_pripr->kolicina )
      // maloprodajna vrijednost bez poreza (bez popusta)
      nTot5 += ( nU5 := ( kalk_pripr->mpc + kalk_pripr->rabatv ) * kalk_pripr->kolicina )
      // porez
      nTotPorez += ( nU6 := ( nPor1 ) * kalk_pripr->kolicina )
      // maloprodajna vrijednost sa porezom
      nTot7 += ( nU7 := kalk_pripr->mpcsapp * kalk_pripr->kolicina )
      // maloprodajna vrijednost sa popustom bez poreza
      nTot8 += ( nU8 := ( kalk_pripr->mpc * kalk_pripr->kolicina ) )
      // popust
      nTotPopust += ( nU9 := kalk_pripr->rabatv * kalk_pripr->kolicina )
      // mpv sa pdv - popust
      nTotMPP += ( nUMPP := ( kalk_pripr->mpc + nPor1 ) * kalk_pripr->kolicina )

      check_nova_strana( bZagl, s_oPDF, .F., 0 )
      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), PCol() + 1 SAY IdRoba
      @ PRow(), PCol() + 1 SAY ROBA->barkod
      @ PRow(), PCol() + 1 SAY PadR( ROBA->naz, s_nRobaNazivSirina ) + "(" + ROBA->jmj + ")"
      @ PRow(), PCol() + 1 SAY kalk_pripr->kolicina PICT pickol()
      nCol0 := PCol()
      @ PRow(), nCol0 SAY ""

      // nabavna cijena
      IF roba->tip = "U"
         @ PRow(), PCol() + 1 SAY 0 PICT piccdem()
      ELSE
         @ PRow(), PCol() + 1 SAY kalk_pripr->nc PICT piccdem()
      ENDIF
      // marza
      @ PRow(), nMPos := PCol() + 1 SAY nMarza2 PICT piccdem()
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->mpc + kalk_pripr->rabatv ) PICT piccdem()// mpc ili prodajna cijena uvecana za rabat
      nCol1 := PCol() + 1

      // popust
      @ PRow(), PCol() + 1 SAY kalk_pripr->rabatv PICT piccdem()
      // mpc sa pdv umanjen za popust
      @ PRow(), PCol() + 1 SAY kalk_pripr->mpc PICT piccdem()
      // pdv
      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PPP ] PICT picproc()
      // mpc sa porezom
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->mpc + nPor1 ) PICT piccdem()
      // mpc sa porezom
      @ PRow(), PCol() + 1 SAY kalk_pripr->mpcsapp PICT piccdem()

      // 3. red : totali stavke
      // tarifa
      @ PRow() + 1, 4 SAY kalk_pripr->idtarifa
      @ PRow(), nCol0 SAY ""

      IF roba->tip = "U"
         @ PRow(), PCol() + 1 SAY 0 PICT picdem()
      ELSE
         @ PRow(), PCol() + 1 SAY ( kalk_pripr->nc * kalk_pripr->kolicina ) PICT picdem()
      ENDIF

      // ukupna marza stavke
      @ PRow(), PCol() + 1 SAY ( nMarza2 * kalk_pripr->kolicina ) PICT picdem()
      // ukupna mpv bez poreza ili ukupna prodajna vrijednost
      @ PRow(), PCol() + 1 SAY ( ( kalk_pripr->mpc + kalk_pripr->rabatv ) * kalk_pripr->kolicina ) PICT picdem()
      // ukupne vrijednosti mpc sa porezom sa rabatom i sam rabat
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->rabatv * kalk_pripr->kolicina ) PICT picdem()
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->mpc * kalk_pripr->kolicina ) PICT picdem()
      // ukupni PDV stavke
      @ PRow(), PCol() + 1 SAY ( nPor1 * kalk_pripr->kolicina ) PICT piccdem()
      // ukupni PDV stavke
      @ PRow(), PCol() + 1 SAY ( ( nPor1 + kalk_pripr->mpc ) * kalk_pripr->kolicina ) PICT piccdem()
      // ukupna maloprodajna vrijednost (sa PDV-om)
      @ PRow(), PCol() + 1 SAY ( kalk_pripr->mpcsapp * kalk_pripr->kolicina ) PICT picdem()
      // marza iskazana u procentu
      IF Round( kalk_pripr->nc, 4 ) <> 0
         @ PRow() + 1, nMPos SAY ( nMarza2 / kalk_pripr->nc ) * 100 PICT picproc()
      ELSE
         @ PRow() + 1, nMPos SAY 0 PICT picproc()
      ENDIF
      SKIP 1

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   ? cLine
   @ PRow() + 1, 0 SAY "Ukupno:"
   @ PRow(), nCol0 SAY ""
   // nabavna vrijednost
   @ PRow(), PCol() + 1 SAY nTot3 PICT picdem()
   // marza
   @ PRow(), PCol() + 1 SAY nTot4 PICT picdem()
   // prodajna vrijednost
   @ PRow(), PCol() + 1 SAY nTot5 PICT picdem()
   // popust
   @ PRow(), PCol() + 1 SAY nTotPopust PICT picdem()
   // prodajna vrijednost - popust
   @ PRow(), PCol() + 1 SAY nTot8 PICT picdem()
   // porez
   @ PRow(), PCol() + 1 SAY nTotPorez PICT picdem()
   // maloprodajna vrijednost sa porezom - popust
   @ PRow(), PCol() + 1 SAY nTotMPP PICT picdem()
   // maloprodajna vrijednost sa porezom
   @ PRow(), PCol() + 1 SAY nTot7 PICT picdem()
   ? cLine

   check_nova_strana( bZagl, s_oPDF, .F., 8 )
   PushWa()
   kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, bZagl )
   PopWa()

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


FUNCTION kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, bZagl )

   LOCAL nTot1
   LOCAL nTot2
   LOCAL nTot5, nTotRuc
   LOCAL nTotP
   LOCAL aPorezi
   LOCAL cLine
   LOCAL cIdTarifa
   LOCAL nU1
   LOCAL nU2
   LOCAL nU5
   LOCAL nUp
   LOCAL aIPor
   LOCAL nCol1

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   SEEK cIdfirma + cIdvd + cBrdok

   cLine := linija_za_podvlacenje_pdv()
   ? cLine
   ?  "* Tar *  PDV%    *   MPV    *  Popust  * MPV-Pop  *   PDV   * MPV-Pop. *  MPV    *"
   ?  "*     *          *  b.PDV   *  b.PDV   *  b.PDV   *   PDV   *  sa PDV  * sa PDV  *"
   ? cLine

   nTot1 := 0
   nTot2 := 0
   nTot5 := 0
   nTotRuc := 0
   // popust
   nTotP := 0
   aPorezi := {}

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   DO WHILE !Eof() .AND. cIdfirma + cIdvd + cBrDok == kalk_pripr->idfirma + kalk_pripr->idvd + kalk_pripr->brdok

      cIdTarifa := kalk_pripr->idtarifa
      nU1 := 0
      nU2 := 0
      nU5 := 0
      nUp := 0
      select_o_tarifa( cIdtarifa )
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idroba, @aPorezi, kalk_pripr->idtarifa )

      SELECT kalk_pripr
      DO WHILE !Eof() .AND. cIdfirma + cIdVd + cBrDok == kalk_pripr->idFirma + kalk_pripr->idVd + kalk_pripr->brDok .AND. kalk_pripr->idTarifa == cIdTarifa

         select_o_roba( kalk_pripr->idroba )
         SELECT kalk_pripr
         set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idRoba, @aPorezi, kalk_pripr->idtarifa )
         // mpc bez poreza sa uracunatim popustom
         nU1 += kalk_pripr->mpc * kalk_pripr->kolicina
         aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, kalk_pripr->mpc, kalk_pripr->mpcsapp, kalk_pripr->nc )
         // PDV
         nU2 += aIPor[ 1 ] * kalk_pripr->kolicina
         nU5 += kalk_pripr->mpcsapp * kalk_pripr->kolicina
         nUP += kalk_pripr->rabatv * kalk_pripr->kolicina
         nTotRuc += ( kalk_pripr->mpc - kalk_pripr->nc ) * kalk_pripr->kolicina
         SKIP
      ENDDO

      nTot1 += nU1
      nTot2 += nU2
      nTot5 += nU5
      nTotP += nUP

      check_nova_strana( bZagl, s_oPDF, .F., 3 )
      ? cIdtarifa
      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PPP ] PICT picproc()

      nCol1 := PCol()
      // mpv bez pdv
      @ PRow(), nCol1 + 1 SAY nU1 + nUP PICT picdem()
      // popust
      @ PRow(), PCol() + 1 SAY nUp PICT picdem()
      // mpv - popust
      @ PRow(), PCol() + 1 SAY nU1 PICT picdem()
      // PDV
      @ PRow(), PCol() + 1 SAY nU2 PICT picdem()
      // mpv
      @ PRow(), PCol() + 1 SAY ( nU1 + nU2 ) PICT picdem()
      // mpv sa originalnom cijemo
      @ PRow(), PCol() + 1 SAY nU5 PICT picdem()

   ENDDO

   check_nova_strana( bZagl, s_oPDF, .F., 5 )
   ? cLine
   ? "UKUPNO"
   // prodajna vrijednost bez popusta
   @ PRow(), nCol1 + 1 SAY ( nTot1 + nTotP ) PICT picdem()
   // popust
   @ PRow(), PCol() + 1 SAY nTotP PICT picdem()
   // prodajna vrijednost - popust
   @ PRow(), PCol() + 1 SAY nTot1 PICT picdem()
   // pdv
   @ PRow(), PCol() + 1 SAY nTot2 PICT picdem()
   // mpv sa uracunatim popustom
   @ PRow(), PCol() + 1 SAY ( nTot1 + nTot2 ) PICT picdem()
   // mpv
   @ PRow(), PCol() + 1 SAY nTot5 PICT picdem()

   ? cLine
   ? "        UKUPNA RUC:"
   @ PRow(), PCol() + 1 SAY nTotRuc PICT picdem()
   ? "UKUPNO POPUST U MP:"
   @ PRow(), PCol() + 1 SAY nTot5 - ( nTot1 + nTot2 ) PICT picdem()
   ? cLine

   RETURN .T.


STATIC FUNCTION kalk_naslov_41_42()

   LOCAL cLine

   PushWa()
   select_o_partner( cIdPartner )
   IF cIdVd == "41"
      ?  "KUPAC:", cIdPartner, "-", PadR( partn->naz, 20 ), Space( 5 ), "DOKUMENT Broj:", cBrFaktP  //, "Datum:", dDatFaktP
   ENDIF

   select_o_konto( cPKonto )
   ?  _u( "Prodavnički konto razdužuje:" ), cPKonto, "-", PadR( konto->naz, 60 )

   cLine := linija_za_podvlacenje( cIdVd )
   ? cLine

   ?U "*R * ROBA     *" + PadC( "Barkod", 13 ) + "*" + PadC( "Naziv", s_nRobaNazivSirina + 5 ) +;
      "* Količina *  NAB.CJ  *  MARZA  * MPC bPDV *  Popust   * MPV-pop. *   PDV %  *   MPC    * MPC/MPV *"

   ?U "*BR*          *" + PadC( "      ", 13 ) + "*" + PadC( "     ", s_nRobaNazivSirina + 5 ) +;
      "*          *   U MP    *         * MPV bPDV * (bez PDV) * (bez PDV)*   PDV    *  SA PDV  * SA PDV  *"

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
