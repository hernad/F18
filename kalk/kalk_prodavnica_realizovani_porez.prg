/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


FUNCTION kalk_realizovani_porez_prodavnice()

   LOCAL nT1 := nPDVTotal := nT5 := nT6 := nT7 := 0
   LOCAL nTT1 := nTT4 := nTT5 := nTT6 := nTT7 := 0
   LOCAL nMPVUkupno := nPDVUkupno := n5 := n6 := n7 := 0
   LOCAL nCol1 := 0
   LOCAL nMPC, nPDV
   LOCAL cPicProcenat := "99.99%"
   LOCAL cPicIznos := "9 999 999.99"
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL i := 0
   LOCAL aPorezi

   dDat1 := dDat2 := CToD( "" )
   cVDok := "99"
   qqKonto := PadR( "13;", 60 )


   Box(, 6, 70 )

   SET CURSOR ON

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto prodavnice/magacina:" GET qqKonto PICT "@!S30"

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Kalkulacije od datuma:" GET dDat1
      @ box_x_koord() + 3, Col() + 1 SAY "do" GET dDat2


      READ
      ESC_BCR

      cUslovPKonto := Parsiraj( qqKonto, "PKonto" )

      IF cUslovPKonto <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()


   IF cVDok == "99"
      cVDok := "41#42#43#47#82#IP"
   ENDIF

   find_kalk_za_period( cIdFirma, NIL, NIL, NIL, dDat1, dDat2, "idfirma,idtarifa,pkonto" )


   PRIVATE cFilt1 := ""


   cFilt1 := cUslovPKonto + ".and.(IDVD$" + dbf_quote( cVDOK ) + ")"

   // IF aUsl2 <> ".t."
   // cFilt1 += ".and." + aUsl2
   // ENDIF

   SET FILTER TO &cFilt1
   GO TOP

   EOF CRET

   aRRP := {}

   AAdd( aRRP, { 10, "PROD", " KTO" } )
   AAdd( aRRP, { 15, " TARIF", " BROJ" } )
   AAdd( aRRP, { Len( cPicIznos ), " MPV", "" } )
   AAdd( aRRP, { Len( cPicProcenat ), " PDV", " %" } )
   AAdd( aRRP, { Len( cPicIznos ), " PDV", "" } )
   AAdd( aRRP, { Len( cPicIznos ), " Popust", "" } )
   AAdd( aRRP, { Len( cPicIznos ), " MPV", " SA Por" } )

   cLine := SetRptLineAndText( aRRP, 0 )
   cText1 := SetRptLineAndText( aRRP, 1, "*" )
   cText2 := SetRptLineAndText( aRRP, 2, "*" )

   START PRINT CRET
   ?

   PRIVATE nKI, nPRUC
   nKI := nPRUC := 0

   nMPVUkupno := nPDVUkupno := n5 := n6 := n7 := nMPVSaPPUkupno := 0

   DO WHILE !Eof() .AND. IspitajPrekid()

      B := 0
      cIdFirma := KALK->IdFirma

      Preduzece()

      P_12CPI

      ? "KALK:  PREGLED REALIZOVANOG POREZA (PRODAVNICE)  ZA PERIOD OD", dDat1, "DO", dDat2, "   NA DAN:", Date()
      ?

      // ? "Objekti: ", qqKonto
      // ?

      P_COND

      ?
      ? cLine
      ? cText1
      ? cText2
      ? cLine


      nT1 := nPDVTotal := nT5 := nT6 := nT7 := nMPVSaPorezTotal := 0
      nTP := 0
      cLastTarifa := ""

      aPorezi := {}

      DO WHILE !Eof() .AND. cIdFirma == KALK->IdFirma .AND. IspitajPrekid()

         cIdKonto := PKonto
         cIdTarifa := IdTarifa
         select_o_roba( kalk->idroba )
         select_o_tarifa( cIdTarifa )
         SELECT kalk

         // VtPorezi()
         // cIdTarifa := Tarifa( pkonto, idroba, @aPorezi, cIdTarifa )

         nMPV := 0
         nNv := 0
         nPopust := 0
         nMPVSaPP := 0


         cPoDok := IDVD + BRDOK
         cLastTarifa := cIdTarifa
         nPRUC := 0
         DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdtarifa == kalk->IdTarifa .AND. cIdKonto == kalk->pkonto .AND. IspitajPrekid()

            select_o_roba( kalk->idroba )
            SELECT KALK

/*
               IF cTU == "2" .AND.  roba->tip $ "UT"
                  SKIP 1
                  LOOP
               ENDIF
               IF cTU == "1" .AND. idvd == "IP"
                  SKIP 1
                  LOOP
               ENDIF
*/
            IF pu_i == "I"
               nKolicina := gKolicin2
            ELSE
               nKolicina := kolicina
            ENDIF


            set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, NIL, @aPorezi, cIdTarifa )
            nPDV := kalk_porezi_maloprodaja( aPorezi, nMPC, field->mpcSaPP )
            nMpc := kalk_mpc_by_vrsta_dokumenta( field->idvd, aPorezi )

            nPor1 := nPDV * nKolicina

            nMPV += nMpc * nKolicina
            nMpvSaPP += field->mpcSaPP * nKolicina
            nNv += field->nc * nKolicina

            IF !pu_i == "I"
               nPopust += RabatV * nKolicina
            ENDIF

            SKIP 1

         ENDDO

         IF PRow() > ( RPT_PAGE_LEN + dodatni_redovi_po_stranici() )
            FF
         ENDIF

         set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, NIL, @aPorezi, cIdTarifa )
         nPDV := kalk_porezi_maloprodaja( aPorezi, nMPV, nMpvSaPP )


         @ PRow() + 1, 0 SAY Space( 3 ) + cIdKonto
         @ PRow(), PCol() + 1 SAY Space( 6 ) + cIdTarifa

         nCol1 := PCol() + 4
         @ PRow(), PCol() + 4 SAY nMPVUkupno := nMPV     PICT   cPicIznos

         @ PRow(), PCol() + 1 SAY aPorezi[ POR_PPP ] PICT   cPicProcenat

         @ PRow(), PCol() + 1 SAY nPDVUkupno := nPDV   PICT   cPicIznos

         @ PRow(), PCol() + 1 SAY nPopust := nPopust PICTURE   cPicIznos
         @ PRow(), PCol() + 1 SAY nMPVSaPPUkupno := nMPVSAPP PICTURE   cPicIznos

         nT1 += nMPVUkupno
         nPDVTotal += nPDVUkupno

         nTP += nPopust
         nMPVSaPorezTotal += nMPVSaPPUkupno


      ENDDO


      IF PRow() > ( RPT_PAGE_LEN + dodatni_redovi_po_stranici() )
         FF
      ENDIF

      ? cLine
      ? "UKUPNO:"
      @ PRow(), nCol1     SAY  nT1     PICT cPicIznos
      @ PRow(), PCol() + 1  SAY  0      PICT "@Z " + cPicProcenat

      @ PRow(), PCol() + 1  SAY  nPDVTotal     PICT cPicIznos

      @ PRow(), PCol() + 1  SAY  nTP     PICT cPicIznos
      @ PRow(), PCol() + 1  SAY  nMPVSaPorezTotal     PICT cPicIznos

      ? cLine

   ENDDO

   SET SOFTSEEK ON

   ?
   FF


   ENDPRINT

   RETURN .T.
