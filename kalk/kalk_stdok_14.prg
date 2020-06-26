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
MEMVAR nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP
MEMVAR nStr, cIdFirma, cIdVd, cBrDok, cIdPartner, cBrFaktP, cIdKonto, cIdKonto2  // dDatFaktP

FIELD IdPartner, BrFaktP, DatFaktP, IdKonto, IdKonto2, Kolicina, DatDok
FIELD naz, pkonto, mkonto

FUNCTION kalk_stampa_dok_14(lViseDokumenata)

   LOCAL nCol1 := 0
   LOCAL nCol2 := 0
   LOCAL nPom := 0
   LOCAL oPDF, xPrintOpt, bZagl
   LOCAL nPDVStopa, nPDV, nNetoVPC
   LOCAL cFileName
      
   PRIVATE nKalkPrevoz, nKalkCarDaz, nKalkZavTr, nKalkBankTr, nKalkSpedTr, nKalkMarzaVP, nKalkMarzaMP

   m := "--- ---------- ---------- ----------  ---------- ---------- ---------- ----------- --------- ----------"

   cIdPartner := IdPartner
   cBrFaktP := BrFaktP
   // dDatFaktP := DatFaktP
   cIdKonto := IdKonto
   cIdKonto2 := IdKonto2

   oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := oPDF
   xPrintOpt[ "left_space" ] := 0
   IF lViseDokumenata <> NIL .AND. lViseDokumenata
      xPrintOpt["vise_dokumenata" ] := .T.
   ENDIF 
   cFileName := kalk_print_file_name_txt(cIdFirma, cIdVd, cBrDok)

   IF f18_start_print( cFileName, xPrintOpt,  "KALK Br:" + cIdFirma + "-" + cIdVD + "-" + cBrDok + " / " + AllTrim( P_TipDok( cIdVD, - 2 ) ) + " , Datum:" + DToC( DatDok ) ) == "X"
      RETURN .F.
   ENDIF

   bZagl := {|| zagl() }

   Eval( bZagl )

   nTotNV := nTotVPV := nTotRabat := nTotNetoVPV := nTotPDV := nTotVPVsaPDV := 0

   fNafta := .F.

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND.  cBrDok == BrDok .AND. cIdVD == IdVD


      select_o_roba( kalk_pripr->IdRoba )
      select_o_tarifa( kalk_pripr->IdTarifa )
      SELECT kalk_pripr

      kalk_set_vars_troskovi_marzavp_marzamp()
      check_nova_strana( bZagl, oPdf )

      
      //SKol := Kolicina
      
      nNetoVPC := VPC * ( 1 - RABATV / 100 )
      nPDVStopa := pdv_procenat_by_tarifa( kalk_pripr->IdTarifa )
      
      nTotNV +=  ( nUkNV := Round( NC * Kolicina, gZaokr )     )  // nv

         
      //nTot5 +=  ( Round( nU5 := nKalkMarzaVP * Kolicina, gZaokr )  ) // ruc
  
    
      nTotVPV += ( nUkVPV := Round( VPC * Kolicina, gZaokr ) )
      nTotRabat += ( nUkRabat := Round( RABATV / 100 * VPC * Kolicina, gZaokr ) )
      nTotNetoVPV +=  ( nUkNetoVPC := Round( nNetoVPC * kolicina, gZaokr ) )   

      nUkPDV := Round( nUkNetoVPC * nPDVStopa, gZaokr ) // PDV
      
      nTotPDV +=  nUkPDV
      nTotVPVsaPDV +=  ( nUkVPVsaPDV := nUkNetoVPC + nUkPDV )   // vpv+ppp

      //IF koncij->naz = "P"
       //  nTotd +=  ( nUd := Round( fcj * kolicina, gZaokr ) )  // trpa se planska cijena
      //ELSE
        // nTotd +=  ( nUd := nUkNetoVPC + nUkPDV + nu6 )   // vpc+pornapr+pornaruc
      //ENDIF

      // 1. PRVI RED
      @ PRow() + 1, 0 SAY  Rbr PICTURE "999"
      @ PRow(), 4 SAY  ""
      ?? Trim( Left( ROBA->naz, 40 ) ), "(", ROBA->jmj, ")"
      IF roba_barkod_pri_unosu() .AND. !Empty( roba->barkod )
         ?? ", BK: " + roba->barkod
      ENDIF

      @ PRow() + 1, 4 SAY IdRoba
      @ PRow(), PCol() + 1 SAY Kolicina PICTURE PicKol
      nC1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY NC                          PICTURE PicCDEM
      PRIVATE nNc := 0
      IF nc <> 0
         nNC := nc
      ELSE
         nNC := 99999999
      ENDIF

      @ PRow(), PCol() + 1 SAY ( VPC - nNC ) / nNC * 100               PICTURE PicProc

      @ PRow(), PCol() + 1 SAY VPC PICTURE PiccDEM
      @ PRow(), PCol() + 1 SAY RABATV PICTURE PicProc


   
      @ PRow(), PCol() + 1 SAY nNetoVPC PICTURE PiccDEM

      @ PRow(), PCol() + 1 SAY nPDVStopa * 100 PICTURE PicProc
      

      @ PRow(), PCol() + 1 SAY nNetoVPC * ( 1 + nPDVStopa ) PICTURE PicCDEM


      // 2. DRUGI RED
      @ PRow() + 1, 4 SAY IdTarifa + roba->tip
      @ PRow(), nC1    SAY nUkNV  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkVPV - nUkNV  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkVPV  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkRabat  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkNetoVPC  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkPDV  PICT picdem
      @ PRow(), PCol() + 1 SAY nUkVPVsaPDV  PICT picdem

      SKIP

   ENDDO

   check_nova_strana( bZagl, oPdf )

   ? m

   @ PRow() + 1, 0        SAY "Ukupno:"
   @ PRow(), nc1      SAY nTotNV  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotVPV - nTotNV  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotVPV  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotRabat  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotNetoVPV  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotPDV  PICT picdem
   @ PRow(), PCol() + 1 SAY nTotVPVsaPDV  PICT picdem

   ? m

   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl()

   LOCAL dDatVal

   IF cIdvd == "14"
      ?U "IZLAZ KUPCU PO VELEPRODAJI"
   ELSE
      ?U "STORNO IZLAZA KUPCU PO VELEPRODAJI"
   ENDIF

   ? "KALK BR:",  cIdFirma + "-" + cIdVD + "-" + cBrDok, ", Datum:", DatDok
   select_o_partner( cIdPartner )
   ? "KUPAC:", cIdPartner, "-", PadR( naz, 20 ), " FAKT br.:", cBrFaktP  // , "Datum:", dDatFaktP

   SELECT kalk_pripr
   IF FieldPos( "datval" ) > 0
      dDatVal := kalk_pripr->datval
   ELSE
      find_kalk_doks_by_broj_dokumenta( kalk_pripr->idfirma, kalk_pripr->idvd, kalk_pripr->brdok )
      dDatVal := kalk_doks->datval
   ENDIF
   ?? "  DatVal:", dDatVal

   IF cIdvd == "94"
      select_o_partner( cIdkonto2 )
      ?  "Storno razduzenja KONTA:", cIdKonto, "-", AllTrim( naz )
   ELSE
      select_o_partner( cIdkonto2 )
      ?  "KONTO razduzuje:", kalk_pripr->mkonto, "-", AllTrim( naz )
      // IF !Empty( kalk_pripr->Idzaduz2 )
      // ?? " Rad.nalog:", kalk_pripr->Idzaduz2
      // ENDIF
   ENDIF

   SELECT kalk_pripr
   select_o_koncij( kalk_pripr->mkonto )
   SELECT kalk_pripr

   ? m
   ? "*R * ROBA     * Kolicina *  NABAV.  *  MARZA   * PROD.CIJ *  RABAT    * PROD.CIJ*   PDV    * PROD.CIJ *"
   ? "*BR*          *          *  CJENA   *          *          *           * -RABAT  *          * SA PDV   *"
   ? m

   RETURN .T.
