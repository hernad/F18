/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"



FUNCTION RptInv()

   LOCAL nTota := 0
   LOCAL nTotb := 0
   LOCAL nTotc := 0
   LOCAL nTotd := 0
   LOCAL nRecNo
   LOCAL nRazlika := 0
   LOCAL nVisak := 0
   LOCAL nManjak := 0
   LOCAL cPict
   PRIVATE nStr := 0

   cLin := "--- --------------------------------------- ---------- ---------- ----------- ----------- ----------- ----------- ----------- -----------"

   cIdFirma := idFirma
   cIdTipDok := idTipDok
   cBrDok := brDok

   nRecNo := RecNo()

   START PRINT CRET

   fakt_zagl_inventura( cLin )

   GO TOP
   DO WHILE !Eof()
      select_o_roba( fakt_pripr->idRoba )
      SELECT fakt_pripr

      print_nova_strana( 125, @nStr, 1 )

      @ PRow() + 1, 0 SAY field->rbr PICTURE "XXX"
      @ PRow(), 4 SAY ""

      ?? PadR( field->idRoba + " " + Trim( Left( roba->naz, 40 ) ) + " (" + roba->jmj + ")", 36 )

      // popisana kolicina
      @ PRow(), PCol() + 1 SAY field->kolicina PICTURE fakt_pic_kolicina()

      // knjizena kolicina
      @ PRow(), PCol() + 1 SAY Val( field->serbr ) PICTURE fakt_pic_kolicina()

      nC1 := PCol() + 1

      // knjizna vrijednost
      @ PRow(), PCol() + 1 SAY ( Val( field->serbr ) ) * ( field->cijena ) PICTURE fakt_pic_iznos()

      // popisana vrijednost
      @ PRow(), PCol() + 1 SAY ( field->kolicina ) * ( field->cijena ) PICTURE fakt_pic_iznos()

      // razlika
      nRazlika := ( Val( field->serbr ) ) -( field->kolicina )
      @ PRow(), PCol() + 1 SAY nRazlika PICTURE fakt_pic_kolicina()

      // VP cijena
      @ PRow(), PCol() + 1 SAY field->cijena PICTURE fakt_pic_cijena()

      IF ( nRazlika > 0 )
         nVisak := nRazlika * ( field->cijena )
         nManjak := 0
      ELSEIF ( nRazlika < 0 )
         nVisak := 0
         nManjak := nRazlika * ( field->cijena )
      ELSE
         nVisak := 0
         nManjak := 0
      ENDIF

      // VPV visak
      @ PRow(), PCol() + 1 SAY nVisak PICTURE fakt_pic_iznos()
      nTotc += nVisak

      // VPV manjak
      @ PRow(), PCol() + 1 SAY -nManjak PICTURE fakt_pic_iznos()
      nTotd += -nManjak

      // sumiraj knjizne vrijednosti
      nTota += ( Val( field->serbr ) ) * ( field->cijena )

      // sumiraj popisane vrijednosti
      nTotb += ( field->kolicina ) * ( field->cijena )

      SKIP
   ENDDO

   print_nova_strana( 125, @nStr, 3 )

   // UKUPNO:
   // nTota - suma knj.vrijednosti
   // nTotb - suma pop.vrijednosti
   // nTotc - suma VPV visak
   // nTotd - suma VPV manjak

   ? cLin
   @ PRow() + 1, 0 SAY "Ukupno:"
   @ PRow(), nC1 SAY nTota PICTURE fakt_pic_iznos()
   @ PRow(), PCol() + 1 SAY nTotb PICTURE fakt_pic_iznos()
   @ PRow(), PCol() + 1 SAY Replicate( " ", Len( fakt_pic_iznos() ) )
   @ PRow(), PCol() + 1 SAY Replicate( " ", Len( fakt_pic_iznos() ) )
   @ PRow(), PCol() + 1 SAY nTotc PICTURE fakt_pic_iznos()
   @ PRow(), PCol() + 1 SAY nTotd PICTURE fakt_pic_iznos()
   ? cLin

   ENDPRINT

   o_fakt_pripr()
   SELECT fakt_pripr
   GO nRecNo

   RETURN



FUNCTION fakt_zagl_inventura( cLinija )

   ?
   P_10CPI
   ?? "INVENTURA VP :"
   P_COND
   ?
   ? "DOKUMENT BR. :", cIdFirma + "-" + cIdTipDok + "-" + cBrDok, Space( 2 ), "Datum:", datDok
   ?
   print_nova_strana( 125, @nStr, -1 )
   ? cLinija
   ?  "*R * ROBA                                  * Popisana * Knjizna  *  Knjizna  * Popisana  *  Razlika  *  Cijena   *   Visak   *  Manjak  *"
   ?  "*BR*                                       * Kolicina * Kolicina *vrijednost *vrijednost *  (kol)    *    VP     *    VPV    *   VPV    *"
   ? cLinija

   RETURN
