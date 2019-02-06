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


FUNCTION rekap_finansijsko_stanje_magacin()

   LOCAL nKolUlaz
   LOCAL nKolIzlaz

   cIdFirma := self_organizacija_id()
   cidKonto := PadR( "132", FIELD_LENGTH_IDKONTO )
   o_kalk_tabele_izvj()

   dDatOd := CToD( "" )
   dDatDo := Date()
   qqRoba := Space( 60 )
   qqKonto := Space( 120 )
   qqTarifa := qqidvd := Space( 60 )
   PRIVATE cPNab := "N"
   PRIVATE cNula := "D", cErr := "N"
   Box(, 10, 60 )
   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID "." $ cIdkonto .OR. P_Konto( @cIdKonto )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konta   " GET qqKonto  PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Tarife  " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Artikli " GET qqRoba   PICT "@!S50"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Vrste dokumenata  " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 8, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikazati i ako je saldo=0 ? (D/N)" GET cNula  VALID cNula $ "DN" PICT "@!"
      read; ESC_BCR
      PRIVATE aUsl1 := Parsiraj( qqKonto, "MKonto" )
      PRIVATE aUsl2 := Parsiraj( qqTarifa, "IdTarifa" )
      PRIVATE aUsl3 := Parsiraj( qqIDVD, "idvd" )
      PRIVATE aUslR := Parsiraj( qqRoba, "idroba" )
      IF aUsl2 <> NIL; exit; ENDIF
      IF aUsl3 <> NIL; exit; ENDIF
      IF aUsl4 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   hParams := hb_Hash()

   hParams[ "idfirma" ] := cIdFirma

   IF Len( Trim( cIdkonto ) ) == 3  // sinteticki konto
      cIdkonto := Trim( cIdkonto )
      hParams[ "mkonto_sint" ] := cIdKonto
   ELSE
      hParams[ "mkonto" ] := cIdKonto
   ENDIF

   IF !Empty( dDatOd )
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF !Empty( dDatDo )
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := "idFirma,mkonto,idroba,datdok,mu_i,idvd"

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_za_period( hParams )
   MsgC()

   select_o_koncij( cIdkonto )

   SELECT kalk
   EOF CRET

   nLen := 1

   aRFLLM := {}
   AAdd( aRFLLM, { 5, " R.br" } )
   AAdd( aRFLLM, { 11, " Konto" } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " NV.Dug." } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " NV.Pot." } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " NV" } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " VPV Dug." } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " VPV Pot." } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " VPV" } )
   AAdd( aRFLLM, { Len( pict_iznos() ), " Rabat" } )
   PRIVATE cLine := SetRptLineAndText( aRFLLM, 0 )
   PRIVATE cText1 := SetRptLineAndText( aRFLLM, 1, "*" )

   start PRINT cret
   ?

   PRIVATE nTStrana := 0
   PRIVATE bZagl := {|| Zaglrekap_finansijsko_stanje_magacin() }

   Eval( bZagl )
   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   nCol1 := nCol0 := 50
   PRIVATE nRbr := 0

   nKolUlaz := 0
   nKolIzlaz := 0

   DO WHILE !Eof() .AND. cIdfirma == idfirma .AND.  IspitajPrekid()

      nUlaz := nIzlaz := 0
      nVPVU := nVPVI := nNVU := nNVI := 0
      nRabat := 0

      IF field->mKonto <> cIdKonto
         SKIP
         LOOP
      ENDIF

      dDatDok := datdok
      cBroj := mkonto

      DO WHILE !Eof() .AND. cIdfirma + cBroj == idFirma + mkonto .AND. IspitajPrekid()

         IF aUsl1 <> '.t.'
            IF ! &aUsl1
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF ( datdok < dDatOd .OR. datdok > dDatDo .OR. mkonto <> cIdKonto )
            SKIP
            LOOP
         ENDIF
         IF aUsl2 <> '.t.'
            IF !  &aUsl2
               SKIP
               LOOP
            ENDIF
         ENDIF
         IF aUsl3 <> '.t.'
            IF ! &aUsl3
               SKIP
               LOOP
            ENDIF
         ENDIF
         IF aUslR <> '.t.'
            // roba
            IF !  &aUslR
               SKIP
               LOOP
            ENDIF
         ENDIF
         IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
            nCol1 := PCol() + 1
            nVPVU += Round( vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            nNVU += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
         ELSEIF mu_i == "5"
            nVPVI += Round( vpc * kolicina, gZaokr )
            nRabat += Round( rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI += Round( nc * kolicina, gZaokr )
         ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )
            // povrat
            nVPVI -= Round( vpc * kolicina, gZaokr )
            nRabat -= Round( rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI -= Round( nc * kolicina, gZaokr )
         ELSEIF mu_i == "3"
            // nivelacija
            nVPVU += Round( vpc * kolicina, gZaokr )
         ENDIF

         SKIP
      ENDDO

      IF ( cNula <> "D" .AND. Round( nNVU - nNVI, 4 ) == 0 .AND. Round( nVPVU - nVPVI, 4 ) == 0 )
         LOOP
      ENDIF

      NovaStrana( bZagl )

      select_o_konto( cBroj )
      cNaz := KONTO->naz
      SELECT kalk


      ? Str( ++nrbr, 4 ) + ".", PadR( cBroj, 11 )
      nCol1 = PCol() + 1

      nTVPVU += nVPVU; nTVPVI += nVPVI
      nTNVU += nNVU; nTNVI += nNVI
      nTRabat += nRabat

      @ PRow(), PCol() + 1 SAY nNVU PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nNVI PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nNVU - nNVI PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nVPVU PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nVPVI PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nVPVU - NVPVI PICT pict_iznos()
      @ PRow(), PCol() + 1 SAY nRabat PICT pict_iznos()
      @ PRow() + 1, 6 SAY cNaz

   ENDDO

   ? cLine
   ? "UKUPNO:"

   @ PRow(), nCol1    SAY ntNVU PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntNVI PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntNVU - NtNVI PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntVPVU PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntVPVI PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntVPVU - NtVPVI PICT pict_iznos()
   @ PRow(), PCol() + 1 SAY ntRabat PICT pict_iznos()

   ? cLine

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// zaglavlje izvjestaja rekap.fin.stanja
FUNCTION Zaglrekap_finansijsko_stanje_magacin()

   Preduzece()
   P_12CPI
   select_o_konto( cIdkonto )
   ?? Space( 60 ), " DATUM "
   ?? Date(), Space( 5 ), "Str:", Str( ++nTStrana, 3 )
   ?
   ?
   ? "KALK: Rekapitulacija fin. stanja po magacinima za period", dDatOd, "-", dDatDo
   ?
   ?
   ? "Magacin:", cIdKonto, "-", konto->naz
   ?
   IF aUsl1 <> '.t.'
      ? "Kriterij za konta  :", Trim( qqKonto )
   ENDIF
   IF aUslR <> '.t.'
      ? "Kriterij za artikle:", qqRoba
   ENDIF
   SELECT kalk
   P_COND
   ?
   ? cLine
   ? cText1
   ? cLine

   RETURN .T.


FUNCTION pict_iznos()
   RETURN "99,999,999.99"
