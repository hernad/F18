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

MEMVAR m
MEMVAR PicKol, PicDem, PicCdem

FUNCTION kalk_stampa_dok_ip()

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nC1
   LOCAL nPom := 0
   LOCAL cSamoObraz
   LOCAL cIdFirma, cIdVd, cBrDok
   LOCAL cNaslov
   LOCAL xPrintOpt, bZagl
   LOCAL cPKonto
   LOCAL nTotVisakManjak
   LOCAL nTot5
   LOCAL nTot6
   LOCAL nTot7
   LOCAL nTot8
   LOCAL nTot9
   LOCAL nTota
   LOCAL nTotKnjiznaVrijednost
   LOCAL nTotPopisanaVrijednost
   LOCAL nTotd
   LOCAL nTotPopisanaKolicina
   LOCAL nTotKnjiznaKolicina
   LOCAL nTotVisak
   LOCAL nTotManjak
   LOCAL nPosKol
   LOCAL nUVisakManjak
   LOCAL nKnjiznaVrijednost

   // LOCAL cIdPartner, cBrFaktp

   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   // nStr := 0
   // cIdPartner := kalk_pripr->IdPartner
   // cBrFaktP := kalk_pripr->BrFaktP
   // dDatFaktP := DatFaktP
   cPKonto := kalk_pripr->pkonto
   // cIdKonto2 := IdKonto2

   cIdFirma := kalk_pripr->idfirma
   cIdVd := kalk_pripr->idvd
   cBrDok := kalk_pripr->brdok

   IF cIdVd == "90"
      cNaslov := "POS inventura prodavnica"
   ELSE
      cNaslov := "KALK inventura prodavnica"
   ENDIF

   cSamoObraz := Pitanje(, "Prikaz samo obrasca inventure (D-da, N-ne) ?",, "DN" )

   cNaslov += " " + cPKonto  + " " + cIdFirma + "-" + cIdVD + "-" + cBrDok  + " Dat.dok: " + DToC( kalk_pripr->DatDok )
   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "landscape"
   xPrintOpt[ "font_size" ] := 9
   xPrintOpt[ "opdf" ] := s_oPDF
   IF f18_start_print( NIL, xPrintOpt,  cNaslov ) == "X"
      RETURN .F.
   ENDIF


   select_o_konto( cPKonto )
   SELECT kalk_pripr

   ? "PRODAVNICA:", cPKonto, "-", AllTrim( konto->naz )

   SELECT kalk_pripr

   m := "--- --------------------------------------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ----------"

   bZagl := {|| zagl_ip() }
   nTotVisakManjak := 0
   nTot5 := 0
   nTot6 := 0
   nTot7 := 0
   nTot8 := 0
   nTot9 := 0
   nTota := 0
   nTotKnjiznaVrijednost := 0
   nTotPopisanaVrijednost := 0
   nTotd := 0
   nTotPopisanaKolicina := 0
   nTotKnjiznaKolicina := 0
   nTotVisak := 0
   nTotManjak := 0

   Eval( bZagl )
   // PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2
   DO WHILE !Eof() .AND. cIdFirma == kalk_pripr->IdFirma .AND.  cBrDok == kalk_pripr->BrDok .AND. cIdVD == kalk_pripr->IdVD

      kalk_set_vars_troskovi_marzavp_marzamp()
      select_o_roba(  kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )

      SELECT kalk_pripr
      check_nova_strana( bZagl, s_oPDF )

      @ PRow() + 1, 0 SAY field->rbr PICT "999"
      @ PRow(), 4 SAY  ""

      ?? field->idroba, Trim( Left( roba->naz, 40 ) ), "(", roba->jmj, ")"
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      nPosKol := 30
      @ PRow() + 1, 4 SAY field->idtarifa + Space( 4 )

      IF cSamoObraz == "D"
         @ PRow(), PCol() + nPosKol SAY field->kolicina PICT Replicate( "_", Len( PicKol ) )
         @ PRow(), PCol() + 1 SAY field->gkolicina PICT Replicate( " ", Len( PicKol ) )
      ELSE
         @ PRow(), PCol() + nPosKol SAY field->kolicina PICT PicKol
         @ PRow(), PCol() + 1 SAY field->gkolicina PICT PicKol
      ENDIF

      nC1 := PCol()

      //nTotKnjiznaVrijednost += field->fcj
      nKnjiznaVrijednost := kalk_pripr->gkolicina * kalk_pripr->mpcsapp

      IF cSamoObraz == "D"
         @ PRow(), PCol() + 1 SAY nKnjiznaVrijednost PICT Replicate( " ", Len( PicDEM ) )
         @ PRow(), PCol() + 1 SAY field->kolicina * field->mpcsapp PICT Replicate( "_", Len( PicDEM ) )
         @ PRow(), PCol() + 1 SAY field->Kolicina - field->gkolicina PICT Replicate( " ", Len( PicKol ) )
      ELSE
         @ PRow(), PCol() + 1 SAY nKnjiznaVrijednost PICT Picdem // knjizna vrijednost
         @ PRow(), PCol() + 1 SAY field->kolicina * field->mpcsapp PICT Picdem
         @ PRow(), PCol() + 1 SAY field->kolicina - field->gkolicina PICT PicKol
      ENDIF

      @ PRow(), PCol() + 1 SAY field->mpcsapp PICT PicCDEM

      nTotKnjiznaVrijednost += nKnjiznaVrijednost
      nTotPopisanaVrijednost += field->kolicina * field->mpcsapp
      nTotVisakManjak += ( nUVisakManjak := kalk_pripr->MPCSAPP * kalk_pripr->Kolicina - nKnjiznaVrijednost )
      nTotPopisanaKolicina += field->kolicina
      nTotKnjiznaKolicina += field->gkolicina

      IF cSamoObraz == "D"
         @ PRow(), PCol() + 1 SAY nUVisakManjak PICT Replicate( " ", Len( PicDEM ) )
      ELSE
         IF ( nUVisakManjak < 0 )
            // manjak
            @ PRow(), PCol() + 1 SAY 0 PICT picdem
            @ PRow(), PCol() + 1 SAY nUVisakManjak PICT picdem
            nTotManjak += nUVisakManjak
         ELSE
            // visak
            @ PRow(), PCol() + 1 SAY nUVisakManjak PICT picdem
            @ PRow(), PCol() + 1 SAY 0 PICT picdem
            nTotVisak += nUVisakManjak

         ENDIF
      ENDIF

      SKIP 1

   ENDDO


   // IF PRow() - dodatni_redovi_po_stranici() > 58
   // FF
   // @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
   // ENDIF


   IF cSamoObraz == "D"
      check_nova_strana( bZagl, s_oPDF, .F., 5 )
      ? m
      ?
      ?
      ?U Space( 80 ), "Članovi komisije: 1. ___________________"
      ? Space( 80 ), "                  2. ___________________"
      ? Space( 80 ), "                  3. ___________________"

      f18_end_print( NIL, xPrintOpt )
      RETURN .T.
   ENDIF

   check_nova_strana( bZagl, s_oPDF, .F., 13 )

   ? m
   @ PRow() + 1, 0 SAY PadR( "Ukupno:", 43 )
   @ PRow(), PCol() + 1 SAY nTotPopisanaKolicina PICT pickol
   @ PRow(), PCol() + 1 SAY nTotKnjiznaKolicina PICT pickol
   @ PRow(), PCol() + 1 SAY nTotKnjiznaVrijednost PICT picdem
   @ PRow(), PCol() + 1 SAY nTotPopisanaVrijednost PICT picdem
   @ PRow(), PCol() + 1 SAY 0 PICT picdem
   @ PRow(), PCol() + 1 SAY 0 PICT picdem
   @ PRow(), PCol() + 1 SAY nTotVisak PICT picdem
   @ PRow(), PCol() + 1 SAY nTotManjak PICT picdem
   ? m
   ? "Rekapitulacija:"
   ? "---------------"
   ?U "  popisana količina:", Str( nTotPopisanaKolicina, 18, 2 )
   ?U "popisana vrijednost:", Str( nTotPopisanaVrijednost, 18, 2 )
   ?U "   knjižna količina:", Str( nTotKnjiznaKolicina, 18, 2 )
   ?U " knjižna vrijednost:", Str( nTotKnjiznaVrijednost, 18, 2 )
   ?U "          + (višak):", Str( nTotVisak, 18, 2 )
   ?U "         - (manjak):", Str( nTotManjak, 18, 2 )
   ? m

   // Visak
   kalk_pripr_rekap_tarife( {|| check_nova_strana( bZagl, s_oPDF, .F., 9 ) }  )

   // IF !lKalkZaPOS
   ?
   ?
   ?U "Napomena: Ovaj dokument ima sljedeći efekat na karticama:"
   ?U "     1 - izlaz za količinu manjka"
   ?U "     2 - storno izlaza za količinu viška"
   ?
   // ENDIF

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.




STATIC FUNCTION zagl_ip()

   ? m
   ?U "*R * ROBA                                  *  Popisana*  Knjižna *  Knjižna * Popisana *  Razlika * Cijena  *  +VIŠAK  * -MANJAK  *"
   ?U "*BR* TARIFA                                *  količina*  količina*vrijednost*vrijednost*  (kol)   *         *          *          *"
   ? m

   RETURN .T.
