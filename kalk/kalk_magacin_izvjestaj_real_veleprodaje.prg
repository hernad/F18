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

STATIC s_nStrana := 0

FUNCTION kalk_real_partnera()

   LOCAL GetList := {}
   LOCAL nT0 := nT1 := nT2 := nT3 := nT4 := 0
   LOCAL nCol1 := 0
   LOCAL nPom
   LOCAL PicCDEM := kalk_pic_cijena_bilo_gpiccdem()       // "999999.999"
   LOCAL PicProc := gPicProc       // "999999.99%"
   LOCAL PicDEM := kalk_pic_iznos_bilo_gpicdem()         // "9999999.99"
   LOCAL Pickol := kalk_pic_kolicina_bilo_gpickol()         // "999999.999"

   PRIVATE dDat1 := dDat2 := CToD( "" )
   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "1320", 7 )
   cOpcine := Space( 50 )

   qqPartn := Space( 60 )

   cPRUC := "N"
   Box(, 8, 70 )
   DO WHILE .T.
      set_cursor_on()

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Magacinski konto:" GET cIdKonto PICT "@!" VALID P_Konto( @cIdKonto )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Period:" GET dDat1
      @ box_x_koord() + 4, Col() + 1 SAY "do" GET dDat2

      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Partneri:" GET qqPartn PICT "@!S40"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Općine:" GET cOpcine PICT "@!S40"
      READ

      ESC_BCR

      cUslovPartner := Parsiraj( qqPartn, "Idpartner" )
      IF cUslovPartner <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto, NIL , "idfirma,mkonto,idpartner", .F., NIL )


   PRIVATE cFilt1 := ""

   cFilt1 := ".t." + IIF( Empty( dDat1 ), "", ".and.DATDOK>=" + dbf_quote( dDat1 ) ) + ;
      IIF( Empty( dDat2 ), "", ".and.DATDOK<=" + dbf_quote( dDat2 ) )

   cFilt1 := StrTran( cFilt1, ".t..and.", "" )


   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF


   GO TOP
   EOF CRET

   PRIVATE M := "   -------------------------------- ---------- ---------- ---------- ---------- ---------- ---------- ----------" + ""

   START PRINT CRET
   ?

   B := 0

   PRIVATE s_nStrana := 0
   kalk_zagl_real_partnera()

   nVPV := nNV := nVPVBP := nPP := nZarada := nRabat := 0
   nRuc := 0
   nNivP := nNivS := 0
   // nivelacija povecanje, snizenje
   nUlazD := nUlazND := 0
   nUlazO := nUlazNO := 0
   // ostali ulazi
   nUlazPS := nUlazNPS := 0
   // pocetno stanje
   nIzlazP := nIzlazNP := 0
   // izlazi prodavnica
   nIzlazO := nIzlazNO := 0
   // ostali izlazi

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdkonto = mkonto .AND. ispitaj_prekid()

      nPaNV := nPaVPV := nPaRuc := nPaPP := nPaZarada := nPaRabat := 0
      cIdPartner := idpartner


      IF !Empty( cOpcine )
         select_o_partner( cIdPartner )
         IF At( AllTrim( partn->idops ), cOpcine ) == 0
            SELECT kalk
            SKIP
            LOOP
         ENDIF
         SELECT kalk
      ENDIF

      DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. idpartner == cIdpartner  .AND. cIdkonto = mkonto .AND. ispitaj_prekid()

         select_o_roba( kalk->idroba )
         select_o_tarifa( kalk->idtarifa )
         SELECT kalk

         IF idvd == "14"
            IF cUslovPartner <> ".t." .AND. ! &cUslovPartner
               SKIP
               LOOP
            ENDIF
            nVPVBP := nVPV
            nPaNV += Round( NC * kolicina, gZaokr )
            nPaVPV += Round( VPC * ( Kolicina ), gZaokr )
            nPaPP += Round( MPC / 100 * VPC * ( 1 - RabatV / 100 ) * Kolicina, gZaokr )

            nPaRabat += Round( RabatV / 100 * VPC * Kolicina, gZaokr )
            nPom := VPC * ( 1 - RabatV / 100 ) - NC
            nPaRuc += Round( nPom * Kolicina, gZaokr )


         ELSEIF idvd == "18"
            // nivelacija
            IF vpc > 0
               nNivP += vpc * kolicina
            ELSE
               nNivS += vpc * kolicina
            ENDIF

         ELSEIF idvd $ "11#12#13"
            // prodavnica
            nIzlazNP += Round( NC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
            nIzlazP += Round( VPC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
         ELSEIF mu_i == "2"
            // ostali izlazi
            nIzlazNO += Round( NC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
            nIzlazO += Round( VPC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
         ELSEIF idvd == "10"
            nUlazND += Round( NC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
            nUlazD += Round( VPC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )

         ELSEIF mu_i == "1"
            // ostali ulazi
            IF Day( datdok ) = 1 .AND. Month( datdok ) = 1
               // datum 01.01
               nUlazNPS += Round( NC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
               nUlazPS += Round( VPC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
            ELSE
               nUlazNO += Round( NC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
               nUlazO += Round( VPC * ( Kolicina - GKolicina - GKolicin2 ), gZaokr )
            ENDIF

         ENDIF
         SKIP
      ENDDO


      nPaZarada := nPaVPV - nPaNV

      // zarada

      IF nPaNV = 0 .AND. nPAVPV = 0 .AND. nPaRabat = 0 .AND. nPaPP = 0 .AND. nPaZarada = 0
         LOOP
      ENDIF

      IF PRow() > RPT_PAGE_LEN
         FF
         kalk_zagl_real_partnera()
      ENDIF
      select_o_partner( cIdPartner )
      SELECT kalk

      ? Space( 2 ), cIdPartner, PadR( partn->naz, 25 )

      nCol1 := PCol() + 1

      @ PRow(), nCol1    SAY nPaNV   PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nPaRUC  PICT kalk_pic_iznos_bilo_gpicdem()


      @ PRow(), PCol() + 1 SAY nPaZarada PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nPaVPV  PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nPaRabat PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nPaPP  PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nPaVPV - nPaRabat + nPaPP  PICT kalk_pic_iznos_bilo_gpicdem()

      nNV += nPaNV
      nVPV += nPaVPV
      nZarada += nPaZarada
      nRuc += nPaRuc
      nPP += nPaPP
      nRabat += nPaRabat

   ENDDO

   IF PRow() > RPT_PAGE_LEN
      FF
      kalk_zagl_real_partnera()
   ENDIF

   ? m
   ? "   Ukupno:"
   @ PRow(), nCol1    SAY nNV   PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nRUC  PICT kalk_pic_iznos_bilo_gpicdem()

   @ PRow(), PCol() + 1 SAY nZarada PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nVPV  PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nRabat PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1  SAY nPP  PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nVPV - nRabat + nPP  PICT kalk_pic_iznos_bilo_gpicdem()

   ? m

   IF PRow() > 50
      FF
      kalk_zagl_real_partnera( .F. )
   ENDIF

   P_12CPI
   ?
   ? Replicate( "=", 45 )
   ? "Rekapitulacija  prometa za period :"
   ? Replicate( "=", 45 )
   ?
   ? "--------------------------------- ---------- --------"

   ? "                        Nab.vr.    Prod.vr     Ruc%"

   ? "--------------------------------- ---------- --------"
   ?

   ? "**** ULAZI: ********"
   IF nUlazPS <> 0
      ? "-    pocetno stanje:  "
      @ PRow(), PCol() + 1 SAY nUlazNPS PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nUlazPS PICT kalk_pic_iznos_bilo_gpicdem()
      IF nulazPS <> 0
         @ PRow(), PCol() + 1 SAY ( nUlazPS - nUlazNPS ) / nUlazPS * 100 PICT "999.99%"
      ENDIF

   ENDIF
   IF nUlazd <> 0
      ? "-       Dobavljaci :  "
      @ PRow(), PCol() + 1 SAY nUlazND PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nUlazD PICT kalk_pic_iznos_bilo_gpicdem()
      IF nulazD <> 0
         @ PRow(), PCol() + 1 SAY ( nUlazD - nUlazND ) / nUlazD * 100 PICT "999.99%"
      ENDIF
   ENDIF

   IF nUlazo <> 0
      ? "-           ostalo :  "
      @ PRow(), PCol() + 1 SAY nUlazNO PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nUlazO PICT kalk_pic_iznos_bilo_gpicdem()
      IF nulazO <> 0
         @ PRow(), PCol() + 1 SAY ( nUlazO - nUlazNO ) / nUlazO * 100 PICT "999.99%"
      ENDIF
   ENDIF

   IF nNivP <> 0 .OR. nNivS <> 0
      ?
      ? "**** Nivelacije ****"
      IF nNivP <> 0
         ? "-        povecanje :  "
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
         @ PRow(), PCol() + 1 SAY nNivP PICT kalk_pic_iznos_bilo_gpicdem()
      ENDIF
      IF nNivS <> 0
         ? "-        snizenje  :  "
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
         @ PRow(), PCol() + 1 SAY nNivS PICT kalk_pic_iznos_bilo_gpicdem()
      ENDIF
   ENDIF

   ?

   ? "**** IZLAZI (Prod.vr.-Rabat) **"

   ? "-      realizacija :  "
   @ PRow(), PCol() + 1 SAY nNV PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nVPV - nRabat PICT kalk_pic_iznos_bilo_gpicdem()
   IF ( nVPV - nRabat ) <> 0
      @ PRow(), PCol() + 1 SAY nZarada / ( nVPV - nRabat ) * 100 PICT "999.99%"
   ENDIF

   IF nIzlazP <> 0
      ? "-       prodavnice :  "
      @ PRow(), PCol() + 1 SAY nIzlazNP PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nIzlazP PICT kalk_pic_iznos_bilo_gpicdem()
      IF nIzlazP <> 0
         @ PRow(), PCol() + 1 SAY ( nIzlazP - nIzlazNP ) / nIzlazP * 100 PICT "999.99%"
      ENDIF
   ENDIF

   IF nIzlazO <> 0
      ? "-           ostalo :  "
      @ PRow(), PCol() + 1 SAY nIzlazNo PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nIzlazo PICT kalk_pic_iznos_bilo_gpicdem()
      IF nIzlazO <> 0
         @ PRow(), PCol() + 1 SAY ( nIzlazO - nIzlazNO ) / nIzlazO * 100 PICT "999.99%"
      ENDIF
   ENDIF

   FF

   ENDPRINT
   closeret

   RETURN .T.



/* kalk_zagl_real_partnera(fTabela)
 *     Zaglavlje izvjestaja "realizacija veleprodaje po partnerima"
 */

FUNCTION kalk_zagl_real_partnera( fTabela )

   IF ftabela = NIL
      ftabela := .T.
   ENDIF

   Preduzece()
   P_12CPI

   SET CENTURY ON
   ? "  KALK: REALIZACIJA VELEPRODAJE PO PARTNERIMA    na dan:", Date()
   ?? Space( 6 ), "Strana:", Str( ++s_nStrana, 3 )
   ? "        Magacin:", cIdkonto, "   period:", dDat1, "DO", dDat2
   SET CENTURY OFF

   P_COND

   IF ftabela
      ?
      ? m
      ? "   *           Partner            *    NV     *  ZARADA  *   RUC    * Prod.vr  *  Rabat   *   PDV    *  Ukupno *"
      ? "   *                              *           *(RUC-RAB.)* (PV - NV) *         *          *          *          *" +  ""
      ? m
   ENDIF

   RETURN .T.
