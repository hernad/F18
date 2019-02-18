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

FUNCTION kalk_finansijsko_stanje_prodavnice()

   LOCAL nKolUlaz
   LOCAL nKolIzlaz
   LOCAL hParams
   LOCAL dDatOd, dDatDo
   LOCAL cIdFirma
   LOCAL nPDV

   cPicIznos := kalk_prosiri_pic_iznos_za_2()
   cPicCijena := kalk_prosiri_pic_cjena_za_2()

   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "133", FIELD_LENGTH_IDKONTO )

   // o_koncij()
   // o_roba()
   // o_tarifa()
   // o_konto()

   dDatOd := CToD( "" )
   dDatDo := Date()
   qqRoba := Space( 200 )
   qqTarifa := qqidvd := Space( 60 )
   PRIVATE cPNab := "N"
   PRIVATE cNula := "D", cErr := "N"
   PRIVATE cTU := "2"

   Box(, 9, 60 )

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID P_Konto( @cIdKonto )
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tarife  " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Vrste dokumenata  " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Roba  " GET qqRoba PICT "@!S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 7, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 8, box_y_koord() + 2  SAY "Prikaz: roba tipa T / dokumenati IP (1/2)" GET cTU  VALID cTU $ "12"

      READ
      ESC_BCR

      PRIVATE aUsl2 := Parsiraj( qqTarifa, "idtarifa" )
      PRIVATE aUsl3 := Parsiraj( qqIDVD, "idvd" )
      PRIVATE aUsl4 := Parsiraj( qqRoba, "idroba" )

      IF aUsl2 <> NIL
         EXIT
      ENDIF

      IF aUsl3 <> NIL
         EXIT
      ENDIF

      IF aUsl4 <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   // ovo je napusteno ...
   // fSaberikol := ( my_get_from_ini( 'Svi', 'SaberiKol', 'N' ) == 'D' )

   hParams := hb_Hash()
   hParams[ "idfirma" ] := cIdFirma

   IF Len( Trim( cIdkonto ) ) == 3  // sinteticki konto
      cIdkonto := Trim( cIdkonto )
      hParams[ "pkonto_sint" ] := cIdKonto
   ELSE
      hParams[ "pkonto" ] := cIdKonto
   ENDIF

   IF !Empty( dDatOd )
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF !Empty( dDatDo )
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := "idFirma,datdok,idvd,brdok,rbr"

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_za_period( hParams )
   MsgC()

   cFilt1 := ".T."
   IF aUsl2 <> ".t."
      cFilt1 += ".and." + aUsl2
   ENDIF

   IF aUsl3 <> ".t."
      cFilt1 += ".and." + aUsl3
   ENDIF

   IF aUsl4 <> ".t."
      cFilt1 += ".and." + aUsl4
   ENDIF

   SET FILTER TO &cFilt1
   GO TOP

   EOF CRET

   select_o_koncij( cIdkonto )

   SELECT KALK

   nLen := 1

   aRFLLP := {}
   AAdd( aRFLLP, { 6, "Redni", " broj" } )
   AAdd( aRFLLP, { 8, "", " Datum" } )
   AAdd( aRFLLP, { 11, " Broj", "dokumenta" } )
   AAdd( aRFLLP, { Len( cPicIznos ), "  NV", " duguje" } )
   AAdd( aRFLLP, { Len( cPicIznos ), "  NV", " potraz." } )
   AAdd( aRFLLP, { Len( cPicIznos ), "  NV", " ukupno" } )

   AAdd( aRFLLP, { Len( cPicIznos ), "   PV", " duguje" } )
   AAdd( aRFLLP, { Len( cPicIznos ), "   PV", " potraz." } )
   AAdd( aRFLLP, { Len( cPicIznos ), "   PV", " ukupno" } )
   AAdd( aRFLLP, { Len( cPicIznos ), " PV sa PDV", " duguje" } )
   AAdd( aRFLLP, { Len( cPicIznos ), " PV sa PDV", " potraz." } )
   AAdd( aRFLLP, { Len( cPicIznos ), " Popust", "" } )
   AAdd( aRFLLP, { Len( cPicIznos ), " PV sa PDV", " - pop." } )
   AAdd( aRFLLP, { Len( cPicIznos ), " PV sa PDV", " ukupno" } )

   PRIVATE cLine := SetRptLineAndText( aRFLLP, 0 )
   PRIVATE cText1 := SetRptLineAndText( aRFLLP, 1, "*" )
   PRIVATE cText2 := SetRptLineAndText( aRFLLP, 2, "*" )

   start PRINT cret

   ?
   gpO_Land()

   PRIVATE nTStrana := 0
   PRIVATE bZagl := {|| kalk_zagl_fin_stanje_prodavnica( dDatOd, dDatDo ) }

   Eval( bZagl, dDatOd, dDatDo )
   nTUlaz := nTIzlaz := 0
   ntMPVBU := ntMPVBI := ntMPVU := ntMPVI := ntNVU := ntNVI := ntMPVIP := 0
   ntPopust := 0
   nCol1 := nCol0 := 10
   PRIVATE nRbr := 0

#define CMORE

#xcommand CMINIT => ncmSlogova:=100; ncmRec:=1
   // #DEFINE CMNEOF  !eof() .and. ncmRec<=ncmSLOGOVA
   // #XCOMMAND CMSKIP => ++ncmRec; if ncmrec>ncmslogova;exit;end; skip


   CMINIT
   // showkorner( ncmslogova, 1, 16 )
   // showkorner( 0, 100 )


   PRIVATE nKU := nKI := 0 // kolicine ulaz/izlaz

   nKolUlaz := 0
   nKolIzlaz := 0

   DO WHILE !Eof() .AND. cIdfirma == idfirma .AND.  IspitajPrekid()

      nUlaz := nIzlaz := 0
      nMPVBU := nMPVBI := nMPVU := nMPVI := nNVU := nNVI := nMPVIP := 0
      nPopust := 0

      // nRabat:=0

      dDatDok := datdok
      cBroj := idvd + "-" + brdok

      DO WHILE !Eof()  .AND. cIdfirma + DToS( ddatdok ) + cBroj == idFirma + DToS( datdok ) + idvd + "-" + brdok .AND.  IspitajPrekid()

         select_o_roba( KALK->idroba )
         SELECT KALK

         // showkorner( 1, 100 )
         IF cTU == "2" .AND.  roba->tip $ "UT"
            // prikaz dokumenata IP, a ne robe tipa "T"
            SKIP
            LOOP
         ENDIF
         IF cTU == "1" .AND. idvd == "IP"
            SKIP
            LOOP
         ENDIF

         select_o_roba( KALK->idroba )
         select_o_tarifa( KALK->idtarifa )
         SELECT KALK

         IF field->pu_i == "1"
            nMPVBU += kalk->mpc * kalk->kolicina
            nMPVU += kalk->mpcsapp * kalk->kolicina
            nNVU += kalk->nc * kalk->kolicina

         ELSEIF field->pu_i == "5"

            nPDV := field->mpc * pdv_procenat_by_tarifa( kalk->idtarifa )

            IF field->idvd $ "12#13"
               nMPVBU -= kalk->mpc * kalk->kolicina
               nMPVU -= kalk->mpcsapp * kalk->kolicina
               nNVU -= kalk->nc * kalk->kolicina
               nPopust -= kalk->rabatv * kalk->kolicina
               nMPVIP -= ( kalk->mpc + nPDV ) * kalk->kolicina
            ELSE
               nMPVBI += kalk->mpc * kalk->kolicina
               nMPVI += kalk->mpcsapp * kalk->kolicina
               nNVI += kalk->nc * kalk->kolicina
               nPopust += kalk->rabatv * kalk->kolicina
               nMPVIP += ( kalk->mpc + nPDV ) * kalk->kolicina
            ENDIF

         ELSEIF kalk->pu_i == "3" // nivelacija
            nMPVBU += kalk->mpc * kalk->kolicina
            nMPVU += kalk->mpcsapp * kalk->kolicina

         ELSEIF kalk->pu_i == "I"
            nMPVBI += field->mpc * field->gkolicin2
            nMPVI += mpcsapp * gkolicin2
            nNVI += nc * gkolicin2
         ENDIF
         SKIP

      ENDDO

      IF Round( nNVU - nNVI, 4 ) == 0 .AND. Round( nMPVU - nMPVI, 4 ) == 0
         LOOP
      ENDIF

      IF PRow() > page_length_landscape()
         FF
         Eval( bZagl )
      ENDIF

      ? Str( ++nRbr, 5 ) + ".", dDatDok, cBroj
      nCol1 := PCol() + 1

      ntNVU += nNVU
      ntNVI += nNVI
      ntMPVBU += nMPVBU
      ntMPVBI += nMPVBI
      ntMPVU += nMPVU
      ntMPVI += nMPVI
      ntPopust += nPopust
      ntMPVIP += nMPVIP

      @ PRow(), PCol() + 1 SAY nNVU PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nNVI PICT cPicIznos
      @ PRow(), PCol() + 1 SAY ntNVU - ntNVI PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nMPVBU PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nMPVBI PICT cPicIznos
      @ PRow(), PCol() + 1 SAY ntMPVBU - ntMPVBI PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nMPVU PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nMPVI PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nPopust PICT cPicIznos
      @ PRow(), PCol() + 1 SAY nMPVIP PICT cPicIznos
      @ PRow(), PCol() + 1 SAY ntMPVU - ntMPVI PICT cPicIznos

   ENDDO

   ? cLine
   ? "UKUPNO:"

   @ PRow(), nCol1    SAY ntNVU PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntNVI PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntNVU - ntNVI PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVBU PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVBI PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVBU - ntMPVBI PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVU PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVI PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntPopust PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVIP PICT cPicIznos
   @ PRow(), PCol() + 1 SAY ntMPVU - ntMPVI PICT cPicIznos

   ? cLine


   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_zagl_fin_stanje_prodavnica( dDatOd, dDatDo )

   select_o_konto( cIdKonto )
   Preduzece()

   // IF Val( gFPicDem ) > 0
   // P_COND2
   // ELSE
   P_COND
   // ENDIF

   ?? "KALK:PROD Finansijsko stanje za period", dDatOd, "-", dDatDo, " NA DAN "
   ?? Date(), Space( 10 ), "Str:", Str( ++nTStrana, 3 )
   ? "Prodavnica:", cIdKonto, "-", konto->naz

   SELECT KALK

   ? cLine
   ? cText1
   ? cText2
   ? cLine

   RETURN .T.
