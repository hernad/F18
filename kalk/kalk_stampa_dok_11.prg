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

MEMVAR cPKonto, cMKonto, cIdPartner, cBrFakt, dDatFaktP

FUNCTION kalk_stampa_dok_11( fZaTops )

   LOCAL nCol0 := 0
   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL nBezNC11
   LOCAL lVPC := .F.
   LOCAL nVPC, nUVPV, nTVPV, nTotVPV

   PRIVATE aPorezi
   PRIVATE nMarza, nMarza2

   nStr := 0
   altd()
   cIdPartner := kalk_pripr->IdPartner
   cBrFaktP := kalk_pripr->BrFaktP
   dDatFaktP := kalk_pripr->DatFaktP
   cPKonto := kalk_pripr->pkonto
   cMKonto := kalk_pripr->mkonto

   IF fzaTops == NIL
      fzaTops := .F.
   ENDIF

   IF fzatops
      nBezNC11 := g11BezNC
      g11BezNc := "D"
   ENDIF

   P_COND
   B_ON

   IF cIdvd == "11"
      ??U "ZADUŽENJE PRODAVNICE IZ MAGACINA"
   ELSEIF CIDVD == "12"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN"
   ELSEIF CIDVD == "13"
      ??U "POVRAT IZ PRODAVNICE U MAGACIN RADI ZADUZENJA DRUGE PRODAVNICE"
   ENDIF

   B_OFF

   ? "KALK: KALKULACIJA BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, Space( 2 ), ", Datum:", DatDok

   @ PRow(), 123 SAY "Str:" + Str( ++nStr, 3 )

   select_o_partner( cIdPartner )

   ? "OTPREMNICA Broj:", cBrFaktP, "Datum:", dDatFaktP

   IF cIdvd == "11"
      select_o_konto( cPKonto )
      ?U  "Prodavnica zadužuje :", cPKonto, "-", AllTrim( naz )
      select_o_konto( cMKonto )
      ?U  "Magacin razdužuje   :", cMKonto, "-", AllTrim( naz )
   ELSE
      select_o_konto( cPKonto )
      ?  "Storno Prodavnica zadužuje :", cPKonto, "-", AllTrim( naz )
      select_o_konto( cMKonto )
      ?  "Storno Magacin razdužuje   :", cMKonto, "-", AllTrim( naz )
   ENDIF

   SELECT kalk_pripr

   m := "--- ---------- ---------- " +  "---------- " + "---------- ---------- " +  "---------- ---------- "  + "---------- ---------- ---------- --------- -----------"

   select_o_koncij( kalk_pripr->mkonto )

   lVPC := is_magacin_evidencija_vpc( kalk_pripr->mkonto )

   SELECT kalk_pripr

   head_11( lPrikPRUC, m )

   select_o_koncij( kalk_pripr->pkonto )
   SELECT kalk_pripr

   nTot1 := nTot1b := nTot2 := nTotVPV := nTotMarzaVP := nTotMarzaMP := nTot5 := nTot6 := nTot7 := 0
   nTot4c := 0


   aPorezi := {}

   PRIVATE cIdd := idpartner + brfaktp + idkonto + idkonto2

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD

      kalk_pozicioniraj_roba_tarifa_by_kalk_fields()

      Scatter()

      IF lVPC
         nVPC := vpc_magacin_rs( .T. )
         SELECT kalk_pripr
         _VPC := nVPC
      ENDIF

      kalk_Marza_11( NIL, .F. ) // ne diraj _VPC

      nMarza := _marza

      set_pdv_public_vars()

      set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idRoba, @aPorezi, field->idtarifa )
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcSaPP, field->nc )

      nPor1 := aIPor[ 1 ]

      IF lPrikPRUC
         nPRUC := aIPor[ 2 ]
         nPor2 := 0
         nMarza2 := nMarza2 - nPRUC
      ELSE
         nPor2 := aIPor[ 2 ]
      ENDIF

      print_nova_strana( 123, @nStr, 2 )

      nTot1 +=  ( nU1 := FCJ * Kolicina   )
      nTot1b += ( nU1b := NC * Kolicina  )
      nTot2 +=  ( nU2 := Prevoz * Kolicina   )
      nTotVPV +=  ( nU3 := _VPC * kolicina )
      nTotMarzaVP +=  ( nU4 := nMarza * Kolicina )
      nTotMarzaMP +=  ( nU4b := nMarza2 * Kolicina )


      IF lPrikPRUC
         nTot4c += ( nU4c := nPRUC * Kolicina )
      ENDIF

      nTot5 +=  ( nU5 := MPC * Kolicina )
      nTot6 +=  ( nU6 := ( nPor1 + nPor2 ) * Kolicina )
      nTot7 +=  ( nU7 := MPcSaPP * Kolicina )

      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""

      ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"

      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      @ PRow() + 1, 4 SAY IdRoba
      @ PRow(), PCol() + 1 SAY Kolicina             PICTURE PicKol

      nCol0 := PCol() + 1

      IF g11bezNC != "D"
         @ PRow(), PCol() + 1 SAY FCJ                  PICTURE PicCDEM
      ENDIF

      @ PRow(), PCol() + 1 SAY VPC                  PICTURE PicCDEM

      IF !lPrikPRUC
         @ PRow(), PCol() + 1 SAY Prevoz               PICTURE PicCDEM
      ENDIF


      @ PRow(), PCol() + 1 SAY _VPC                   PICTURE PicCDEM // _VPC
      @ PRow(), PCol() + 1 SAY nMarza               PICTURE PicCDEM  // marza vp


      @ PRow(), PCol() + 1 SAY nMarza2              PICTURE PicCDEM

      IF lPrikPRUC
         @ PRow(), PCol() + 1 SAY aPorezi[ POR_PRUCMP ] PICTURE PicProc
      ENDIF
      @ PRow(), PCol() + 1 SAY MPC                  PICTURE PicCDEM
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY aPorezi[ POR_PPP ]     PICTURE PicProc
      @ PRow(), PCol() + 1 SAY nPor1                PICTURE PiccDEM
      @ PRow(), PCol() + 1 SAY MPCSAPP              PICTURE PicCDEM

      // =========  red 2 ===================
      @ PRow() + 1, 4 SAY IdTarifa + roba->tip
      IF g11bezNC == "D"
         @ PRow(), nCol0 - 1    SAY  ""
      ELSE
         @ PRow(), nCol0    SAY  fcj * kolicina      PICTURE picdem
      ENDIF
      @ PRow(),  PCol() + 1 SAY  nc * kolicina      PICTURE picdem


      IF !lPrikPRUC
         @ PRow(),  PCol() + 1 SAY  prevoz * kolicina      PICTURE picdem
      ENDIF

      @ PRow(),  PCol() + 1 SAY  _VPC * kolicina      PICTURE picdem
      @ PRow(),  PCol() + 1 SAY  nMarza * kolicina      PICTURE picdem

      @ PRow(), nMPos := PCol() + 1 SAY  nMarza2 * kolicina      PICTURE picdem
      IF lPrikPRUC
         @ PRow(), PCol() + 1 SAY nU4c                PICTURE PicCDEM
      ENDIF
      @ PRow(),  PCol() + 1 SAY  mpc * kolicina      PICTURE picdem
      IF lPrikPRUC
         @ PRow(), nCol1    SAY aPorezi[ POR_PPU ]   PICTURE picproc
      ELSE

         @ PRow(), nCol1    SAY aPorezi[ POR_PPP ]   PICTURE picproc

      ENDIF

      @ PRow(),  PCol() + 1 SAY  nU6             PICTURE piccdem
      @ PRow(),  PCol() + 1 SAY  nU7             PICTURE piccdem


      // red 3
      IF Round( nc, 5 ) <> 0
         @ PRow() + 1, nMPos SAY ( nMarza2 / nc ) * 100  PICTURE picproc
      ENDIF

      SKIP

   ENDDO


   print_nova_strana( 123, @nStr, 3 )
   ? m
   @ PRow() + 1, 0        SAY "Ukupno:"
   IF g11bezNC == "D"
      @ PRow(), nCol0 - 1      SAY  ""
   ELSE
      @ PRow(), nCol0      SAY  nTot1        PICTURE       PicDEM
   ENDIF

   @ PRow(), PCol() + 1   SAY  nTot1b       PICTURE       PicDEM
   IF !lPrikPRUC
      @ PRow(), PCol() + 1   SAY  nTot2        PICTURE       PicDEM
   ENDIF

   nMarzaVP := nTotMarzaVP
   // IF g11bezNC != "D"
   @ PRow(), PCol() + 1   SAY  nTotVPV        PICTURE       PicDEM
   @ PRow(), PCol() + 1   SAY  nTotMarzaVP        PICTURE       PicDEM
   // ENDIF

   @ PRow(), PCol() + 1   SAY  nTotMarzaMP        PICTURE       PicDEM
   IF lPrikPRUC
      @ PRow(), PCol() + 1  SAY nTot4c        PICTURE         PICDEM
   ENDIF
   @ PRow(), PCol() + 1   SAY  nTot5        PICTURE       PicDEM
   @ PRow(), PCol() + 1   SAY  Space( Len( picproc ) )
   @ PRow(), PCol() + 1   SAY  nTot6        PICTURE        PicDEM
   @ PRow(), PCol() + 1   SAY  nTot7        PICTURE        PicDEM
   ? m

   nTot5 := nTot6 := nTot7 := 0
   kalk_pripr_rekap_tarife()

   IF fZaTops
      g11BezNC := nBezNC11
   ENDIF

   RETURN .T.



FUNCTION head_11( lPrikPRUC, cLine )

   LOCAL cHack0 := "*  NAB.CJ  "
   LOCAL cHack := "*   VP.CJ  "

   ? cLine
   IF koncij->naz == "P2"
      ? "*R * ROBA     * Kolicina " +  cHack0  + "* Plan.Cj. *  TROSAK  *" +  cHack + "*  MARZA   *"  + "  MARZA  * PROD.CJ  *   PDV %  *   PDV    * PROD.CJ  *"
   ELSE
      ? "*R * ROBA     * Kolicina " + cHack0 + "*   " +  " NC" + "    *  TROSAK  *" + cHack + "*  MARZA   *" + "  MARZA   * PROD.CJ  *   PDV %  *   PDV   * PROD.CJ  *"
   ENDIF
   ? "*BR*          *          " +  "*   U VP   " + "*          *   U MP   *" +  "          *   VP     *"  + "   MP     * BEZ PDV  *          *         *  SA PDV  *"
   ? "*  *          *          " +  "*          " + "*          *          *" +  "          *          *"  + "          *          *          *         *          *"


   ? cLine

   RETURN .T.
