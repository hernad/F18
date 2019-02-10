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

MEMVAR aPorezi
MEMVAR nStr
MEMVAR nPrevoz, nBankTr, nSpedTr, nMarza, nMarza2, nCarDaz, nZavTr

MEMVAR cIdFirma, cIdVd, cBrDok, cIdPartner, cBrFaktP, dDatFaktp, cPKonto

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

   PRIVATE nMarza, nMarza2, aPorezi

   nMarza := nMarza2 := 0
   aPorezi := {}
   nStr := 0
   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   dDatFaktP := kalk_pripr->DatFaktP
   cPKonto := kalk_pripr->pKonto

   P_10CPI

   kalk_naslov_41_42()

   SELECT kalk_pripr
   cLine := _get_line( cIdVd )
   ? cLine
   _print_report_header( cIdvd )
   ? cLine

   nTot3 := nTot4 := nTot5 := nTotPorez := nTot7 := nTot8 := nTotPopust := 0
   nTot4a := 0
   nTotMPP := 0

   //PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->idfirma .AND. cBrDok == kalk_pripr->brdok .AND. cIdVD == kalk_pripr->idvd

      Scatter()
      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()
      kalk_marza_realizacija_prodavnica()
      kalk_set_troskovi_priv_vars_ntrosakx_nmarzax()
      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idRoba, @aPorezi, kalk_pripr->idtarifa )

      // uracunaj i popust
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, kalk_pripr->mpc, kalk_pripr->mpcsapp, kalk_pripr->nc )
      nPor1 := aIPor[ 1 ]

      set_pdv_public_vars()
      print_nova_strana( 125, @nStr, 2 )

      // nabavna vrijednost
      nTot3 += ( nU3 := IIF( roba->tip = "U", 0, kalk_pripr->nc ) * kalk_pripr->kolicina )
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

      // 1. red
      @ PRow() + 1, 0 SAY kalk_pripr->rbr PICT "999"
      @ PRow(), 4 SAY  ""

      ?? Trim( Left( roba->naz, 40 ) ), "(", roba->jmj, ")"
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      // 2. red
      @ PRow() + 1, 4 SAY kalk_pripr->idroba
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

   print_nova_strana( 125, @nStr, 3 )
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
   print_nova_strana( 125, @nStr, 10 )

   //nRec := RecNo()
   PushWa()
   // rekapitulacija tarifa PDV
   kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, @nStr )
   //SET ORDER TO TAG "1"
   //GO nRec
   PopWa()

   RETURN .T.


STATIC FUNCTION _get_line()

   LOCAL cLine

   cLine := "--- ---------- ---------- ---------- ---------- ---------- ---------- ----------"
   cLine += " ---------- ---------- ----------"

   RETURN cLine


STATIC FUNCTION _print_report_header()

   ? "*R * ROBA     * Kolicina *  NAB.CJ  *  MARZA  * MPC bPDV *  Popust  * PC-pop.  *   PDV %  *   MPC    * MPC     *"
   ? "*BR*          *          *   U MP   *         * MPV bPDV * (bez PDV)* PV-pop.  *   PDV    *  SA PDV  * SA PDV  *"
   ? "*  *          *          *   sum    *         *    sum   *          *          *    sum   * - popust *  sum    *"

   RETURN .T.


STATIC FUNCTION _get_rekap_line()

   LOCAL cLine
   LOCAL nI

   cLine := "------ "
   FOR nI := 1 TO 7
      cLine += Replicate( "-", 10 ) + " "
   NEXT

   RETURN cLine


STATIC FUNCTION _print_rekap_header()

   ?  "* Tar *  PDV%    *   MPV    *  Popust  * MPV-Pop  *   PDV   * MPV-Pop. *  MPV    *"
   ?  "*     *          *  b.PDV   *  b.PDV   *  b.PDV   *   PDV   *  sa PDV  * sa PDV  *"

   RETURN .T.


FUNCTION kalk_stdok_41_rekap_pdv( cIdFirma, cIdVd, cBrDok, nStr )

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

   cLine := _get_rekap_line()
   ? cLine
   _print_rekap_header()
   ? cLine

   nTot1 := 0
   nTot2 := 0
   nTot5 := 0
   nTotRuc := 0
   // popust
   nTotP := 0
   aPorezi := {}

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
         set_pdv_public_vars()
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

   print_nova_strana( 125, @nStr, 4 )
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


FUNCTION kalk_naslov_41_42()

   B_ON
   IF cIdVd == "41"
      ?? "IZLAZ IZ PRODAVNICE - KUPAC"
   ELSE
      ?? "IZLAZ IZ PRODAVNICE - PARAGON BLOK"
   ENDIF
   B_OFF
   P_COND
   ?

   ?? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), P_TipDok( cIdVD, - 2 ), Space( 2 ), "Datum:", kalk_pripr->DatDok
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )

   select_o_partner( cIdPartner )
   IF cIdVd == "41"
      ?  "KUPAC:", cIdPartner, "-", PadR( partn->naz, 20 ), Space( 5 ), "DOKUMENT Broj:", cBrFaktP, "Datum:", dDatFaktP
   ENDIF

   select_o_konto( cPKonto )
   ?  "Prodavnicki konto razduzuje:", cPKonto, "-", PadR( konto->naz, 60 )

   RETURN NIL
