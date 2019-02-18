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


FUNCTION kalk_ukalkulisani_porez_prodavnice()

   LOCAL  i := 0
   LOCAL nT1 := 0
   LOCAL nT4 := 0
   LOCAL nT5 := 0
   LOCAL nT5a := 0
   LOCAL nT6 := 0
   LOCAL nT7 := 0
   LOCAL nTT1 := 0
   LOCAL nTT4 := 0
   LOCAL nTT5 := 0
   LOCAL nTT5a := 0
   LOCAL nTT6 := 0
   LOCAL nTT7 := 0
   LOCAL n1 := 0
   LOCAL nPDVUkupno
   LOCAL cIdTarifa
   LOCAL n5 := 0
   LOCAL n5a := 0
   LOCAL n6 := 0
   LOCAL n7 := 0
   LOCAL nCol1 := 0
   LOCAL cPicProcenat := "99.99%"
   LOCAL cPicIznos := "9 999 999.99"
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cLine, cText1, cText2
   LOCAL GetList := {}

   dDat1 := dDat2 := CToD( "" )
   cVDok := "99"
   // cStope := "N"

   qqKonto := PadR( "13;", 60 )
   Box(, 5, 75 )
   SET CURSOR ON
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto prodavnice:" GET qqKonto PICT "@!S50"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Tip dokumenta (11/12/13/15/19/80/81/99):" GET cVDok  VALID cVDOK $ "11/12/13/15/19/16/22/80/81/99"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Kalkulacije od datuma:" GET dDat1
      @ box_x_koord() + 3, Col() + 1 SAY "do" GET dDat2
      // @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prikaz stopa ucesca pojedinih tarifa:" GET cStope VALID cstope $ "DN" PICT "@!"
      READ
      ESC_BCR

      cUslovPKonto := Parsiraj( qqKonto, "Pkonto" )
      IF cUslovPKonto <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()


   IF cVDOK == "99"
      cVDOK := "11#80#81#12#13#15#19"
      // IF cStope == "D"
      // cVDOK += "#42#43"
      // ENDIF
   ENDIF

   find_kalk_za_period( cIdFirma, NIL, NIL, NIL, dDat1, dDat2, "idfirma,idtarifa,pkonto" )

   PRIVATE cFilt1 := ""

   cFilt1 := cUslovPKonto + ".and.(IDVD$" + dbf_quote( cVDOK ) + ")"

   SET FILTER TO &cFilt1

   GO TOP   // samo  zaduz prod. i povrat iz prod.
   EOF CRET

   aRUP := {}
   AAdd( aRUP, { 10, "PROD", " KTO" } )
   AAdd( aRUP, { 15, " TARIF", " BROJ" } )
   AAdd( aRUP, { Len( cPicIznos ), " MPV", "" } )
   AAdd( aRUP, { Len( cPicProcenat ), " PDV", " %" } )
   AAdd( aRUP, { Len( cPicIznos ), " PDV", "" } )
   AAdd( aRUP, { Len( cPicIznos ), " MPV", " SA Por" } )


   cLine := SetRptLineAndText( aRUP, 0 )
   cText1 := SetRptLineAndText( aRUP, 1, "*" )
   cText2 := SetRptLineAndText( aRUP, 2, "*" )

   START PRINT CRET
   ?

   n1 := 0
   nPDVUkupno := 0
   n5 := 0
   n5a := 0
   n6 := 0
   n7 := 0

   DO WHILE !Eof() .AND. IspitajPrekid()
      B := 0
      cIdFirma := KALK->IdFirma
      Preduzece()

      // IF Val( gFcPicIznos ) > 0
      // P_COND2
      // ELSE
      // P_COND
      // ENDIF

      ? "KALK: PREGLED UKALKULISANI PDV " + Trim( qqKonto ) + " ZA PERIOD OD", dDat1, "DO", dDAt2, "  NA DAN:", Date()
      ? "      Tipovi dokumenta: ", cVDOK

      ?
      ? cLine
      ? cText1
      ? cText2
      ? cLine

      nT1 := 0
      nT4 := 0
      nT5 := 0
      nT5a := 0
      nT6 := 0
      nT7 := 0
      // PRIVATE aTarife := {}, nReal := 0

      SELECT KALK
      DO WHILE !Eof() .AND. cIdFirma == KALK->IdFirma .AND. IspitajPrekid()

         cIdKonto := kalk->PKonto
         cIdTarifa := kalk->IdTarifa
         select_o_tarifa( cIdtarifa )
         SELECT kalk
         nMPV := 0
         nMPVSaPDV := 0
         nNV := 0
         DO WHILE !Eof() .AND. cIdFirma == kalk->IdFirma .AND. cIdKonto == kalk->pkonto .AND.  cIdtarifa == kalk->IdTarifa .AND. IspitajPrekid()

            SELECT KALK
            // IF  idvd == "42" .OR. idvd == "43"
            // nReal += mpcsapp * kolicina
            IF IdVD $ "12#13" // povrat robe se uzima negativno
               nMPV -= MPC * ( Kolicina )
               nMPVSaPDV -= MPCSaPP * ( Kolicina )
               nNV -= nc * kolicina
            ELSE
               nMPV += MPC * ( Kolicina )
               nMPVSaPDV += MPCSaPP * ( Kolicina )
               nNV += nc * kolicina
            ENDIF

            SKIP
         ENDDO


         IF PRow() > ( RPT_PAGE_LEN + + dodatni_redovi_po_stranici() )
            FF
         ENDIF


         nPDVUkupno :=  nMPV * pdv_procenat_by_tarifa(cIdTarifa)
         @ PRow() + 1, 0 SAY Space( 3 ) + cIdKonto
         @ PRow(), PCol() + 1 SAY Space( 6 ) + cIdTarifa

         nCol1 := PCol() + 4
         @ PRow(), PCol() + 4 SAY nMPV PICT cPicIznos
         @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa(cIdTarifa)*100 PICT cPicProcenat

         @ PRow(), PCol() + 1 SAY nPDVUkupno PICT cPicIznos

         @ PRow(), PCol() + 1 SAY nMPVSaPDV PICTURE cPicIznos
         nT1 += nMPV
         nT4 += nPDVUkupno
         nT7 += nMPVSaPDV
      ENDDO


      IF PRow() > ( RPT_PAGE_LEN + + dodatni_redovi_po_stranici() )
         FF
      ENDIF
      ? cLine
      ? "UKUPNO:"
      @ PRow(), nCol1     SAY  nT1     PICT cPicIznos
      @ PRow(), PCol() + 1  SAY  0       PICT "@Z " + cPicProcenat

      @ PRow(), PCol() + 1  SAY  nT4     PICT cPicIznos
      @ PRow(), PCol() + 1  SAY  nT7     PICT cPicIznos
      ? cLine

   ENDDO

   ?
   FF
   ENDPRINT
   SET SOFTSEEK ON

   closeret

   RETURN .T.
