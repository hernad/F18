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


FUNCTION fin_spec_otv_stavke_preko_dana()

   LOCAL nCol1 := 0

   picBHD := FormPicL( "9 " + gPicBHD, 16 )
   picDEM := FormPicL( "9 " + pic_iznos_eur(), 16 )

   cIdFirma := self_organizacija_id(); nIznosBHD := 0; nDana := 30; cIdKonto := Space( 7 )

   o_konto()
   //o_partner()
   dDatumOd := CToD( "" )
   dDatum := Date()
   cUkupnoPartner := "D"
   cPojed := "D"
   cD_P := "1"
   qqBrDok := Space( 40 )

   M := "----- " + Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ----------------------------------- ------ ---------------- -------- -------- --------- -----------------"
   IF fin_dvovalutno()
      M += " ----------------"
   ENDIF


   // Markeri otvorenih stavki
   // D - uzeti u obzir markere
   // N - izvjestaj saldirati bez obzira na markere, sabirajuci prema broju veze
   cMarkeri := "N"
   IF my_get_from_ini( "FIN", "Ostav_Markeri", "N", KUMPATH ) == "D"
      cMarkeri := "D"
   ENDIF

   // uzeti u obzir datum valutiranja
   PRIVATE cObzirDatVal := "D"



   Box( "skpoi", 14, 70, .F. )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "OTVORENE STAVKE PREKO/DO ODREDJENOG BROJA DANA"

    @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "
    ?? self_organizacija_id(), "-", self_organizacija_naziv()

   PRIVATE cViseManje := ">"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "KONTO  " GET cIdKonto VALID p_konto( @cIdKonto )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Broj dana ?" GET cViseManje VALID cViseManje $ "><"
   @ box_x_koord() + 5, Col() + 2 GET nDana PICTURE "9999"

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "obracun od " GET dDatumOd
   @ box_x_koord() + 6, Col() + 2 SAY  "do datuma:" GET dDatum
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "duguje/potrazuje (1/2):" GET cD_P
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Uzeti u obzir datum valutiranja :" GET cObzirDatVal PICT "@!" VALID cObzirDatVal $ "DN" when {|| cObzirDatVal := iif( cViseManje = ">", "D", "N" ), .T. }
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Uzeti u obzir markere           :" GET cMarkeri     PICT "@!" VALID cObzirDatVal $ "DN"

   @ box_x_koord() + 12, box_y_koord() + 2 SAY "prikaz pojedinacnog racuna:" GET cPojed VALID cPojed $ "DN" PICT "@!"
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "prikaz ukupno za partnera :" GET cUkupnoPartner VALID cUkupnoPartner $ "DN" PICT "@!"
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "Uslov za broj veze (prazno-svi)" GET qqBrDok PICT "@S20"
   READ
   ESC_BCR

   BoxC()

   B := 0

   cIdFirma := Left( cIdFirma, 2 )

   nStr := 0

   IF my_get_from_ini( "FAKT", "VrstePlacanja", "N", SIFPATH ) == "D"
      o_vrstep()
   ENDIF

   // o_suban() ; SET ORDER TO TAG "3"
   // "IdFirma+IdKonto+IdPartner+BrDok+dtos(DatDok)"
   // HSEEK cIdFirma + cIdKonto

   find_suban_by_konto_partner( cIdFirma, cIdKonto )


   EOF CRET


   IF !start_print()
      RETURN .F.
   ENDIF

   cIdKonto := IdKonto

   IF PRow() <> 0
      FF
      ZaglSpBrDana()
   ENDIF

   IF !Empty( qqBrDok )
      aUslBrDok := {}
      aUslBrDok := TOKuNIZ( AllTrim( qqBrDok ), ";" )
   ENDIF


   KDIN := KDEM := 0   // ukupno za konto BHD,DEM
   DO WHILE !Eof() .AND. cIdKonto == IdKonto

      cIdPartner := Idpartner
      nDinP := nDemP := 0
      DO WHILE !Eof() .AND. cIdKonto == IdKonto .AND. idpartner == cidpartner

         dDatDok := CToD( "" )
         cBrdok := field->brdok

         IF !Empty( qqBrDok ) .AND. Len( aUslBrDok ) <> 0
            lFound := .F.
            FOR i := 1 TO Len( aUslBrDok )
               nOdsjeci := Len( aUslBrDok[ i, 1 ] )
               IF Right( AllTrim( cBrdok ), nOdsjeci ) == aUslBrDok[ i, 1 ]
                  lFound := .T.
                  EXIT
               ENDIF
            NEXT
            IF !lFound
               SKIP
               LOOP
            ENDIF
         ENDIF


         nDin := nDEM := 0
         DO WHILE !Eof() .AND. idkonto == cidkonto .AND. idpartner == cidpartner .AND. ;
               brdok == cBrdok

            IF ( cMarkeri == "N" .OR. OtvSt = " " )

               IF  DatDok <= dDatum  .AND. ;// stavke samo do zadanog datuma !!
                  ( Empty( dDatumOd ) .OR. DatDok >= dDatumOd )
                  IF cD_P == "1" // kupci
                     IF d_P == "1"
                        nDin += IznosBHD  ; nDEM += IznosDEM
                     ELSE
                        nDin -= IznosBHD  ; nDEM -= IznosDEM
                     ENDIF
                  ELSE  // dobalja�i
                     IF d_P == "2"
                        nDin += IznosBHD  ; nDEM += IznosDEM
                     ELSE
                        nDin -= IznosBHD  ; nDEM -= IznosDEM
                     ENDIF
                  ENDIF

               ENDIF

               IF ( cD_P == "1" .AND. D_P == "1"  .AND. iznosbhd > 0 ) .OR. ;
                     ( cD_P == "2" .AND. D_P == "2"  .AND. iznosbhd > 0 )
                  // dDatDok:=datdok
                  IF cObzirDatVal == "D"
                     // uzima se u obzir datum valutiranja
                     dDatDok := iif( datval_prazan(), DATDOK, DATVAL )
                  ELSE
                     dDatDok := DatDok
                  ENDIF

               ENDIF

            ENDIF // otvst =" "

            SKIP
         ENDDO

         IF !Empty( dDatDok ) .AND. iif( cViseManje = ">", dDatum - dDatDok > nDana, ( dDatum - dDatDok > 0 .AND. dDatum - dDatDok <= nDana ) ) .AND. ;
               Abs( Round( nDin, 4 ) ) > 0

            KDIN += nDin; KDEM += nDEM
            nDINP += nDin; nDEMP += nDEM
            IF cPojed == "D"

               IF PRow() == 0
                  ZaglSpBrDana()
               ENDIF
               IF PRow() > 60 + dodatni_redovi_po_stranici()
                  FF
                  ZaglSpBrDana()
               ENDIF

               @ PRow() + 1, 1 SAY ++B PICTURE '9999'
               @ PRow(), PCol() + 1 SAY cIdPartner
               select_o_partner( cIdPartner )
               @ PRow(), PCol() + 1 SAY PadR( naz, 25 )
               @ PRow(), PCol() + 1 SAY naz2 PICTURE 'XXXXXXXXXX'
               @ PRow(), PCol() + 1 SAY PTT
               @ PRow(), PCol() + 1 SAY Mjesto

               SELECT SUBAN

               @ PRow(), PCol() + 1 SAY cBrDok
               @ PRow(), PCol() + 1 SAY dDatDok
               @ PRow(), PCol() + 1 SAY k1 + "-" + k2 + "-" + k3iz256( k3 ) + k4
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY nDin PICTURE picBHD
               IF fin_dvovalutno()
                  @ PRow(), PCol() + 1 SAY nDEM PICTURE picDEM
               ENDIF
            ENDIF // cpojed=="D"

         ENDIF  // dana

      ENDDO // partner

      IF cUkupnoPartner == "D"  .AND. Abs( Round( nDinP, 4 ) ) > 0

         IF cpojed == "D"
            ? m
         ENDIF

         IF PRow() == 0; ZaglSpBrDana(); ENDIF
         IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglSpBrDana(); ENDIF

         IF cPojed == "N"
            @ PRow() + 1, 1 SAY ++B PICTURE '9999'
         ELSE
            @ PRow() + 1, 1 SAY Space( 4 )
         ENDIF
         @ PRow(), PCol() + 1 SAY cIdPartner
         select_o_partner( cIdPartner )
         @ PRow(), PCol() + 1 SAY PadR( naz, 25 )
         @ PRow(), PCol() + 1 SAY naz2 PICT 'XXXXXXXXXX'
         @ PRow(), PCol() + 1 SAY PTT
         @ PRow(), PCol() + 1 SAY Mjesto
         SELECT SUBAN

         @ PRow(), PCol() + 1 SAY Space( Len( cBrDok ) )
         @ PRow(), PCol() + 1 SAY Space( 8 )  // dDatDok
         @ PRow(), PCol() + 1 SAY k1 + "-" + k2 + "-" + k3iz256( k3 ) + k4
         nCol1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY nDinP PICTURE picBHD
         IF fin_dvovalutno()
            @ PRow(), PCol() + 1 SAY nDEMP PICTURE picDEM
         ENDIF

         IF cpojed == "D"
            ? m
         ENDIF
      ENDIF

   ENDDO  // konto
   IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglSpBrDana(); ENDIF
   ? M
   ? "UKUPNO ZA KONTO:"
   @ PRow(), nCol1    SAY KDIN PICTURE picBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY KDEM PICTURE picDEM
   ENDIF
   ? M


   FF
   end_print()

   closeret

   RETURN



/* ZaglSpBrDana()
 *     Zaglavlje za otvorene stavke preko odredjenog broja dana
 */

FUNCTION ZaglSpBrDana()

   LOCAL cPom

   ?
   P_COND
   ?? "FIN: SPECIFIKACIJA PARTNERA SA NEPLA�ENIM RA�UNIMA " + iif( cViseManje = ">", "PREKO ", "DO " ) + Str( nDana, 3 ) + " DANA  NA DAN "; ?? dDatum
   IF !Empty( dDatumOd )
      ? "     obuhva�en je period:", dDatumOd, "-", dDatum
   ENDIF

   IF !Empty( qqBrDok )
      ? "Izvjestaj pravljen po uslovu za broj veze/racuna: '" + AllTrim( qqBrDok ) + "'"
   ENDIF

   @ PRow(), 123 SAY "Str:" + Str( ++nStr, 3 )

   //IF gNW == "D"
      ? "Firma:", self_organizacija_id(), self_organizacija_naziv()
   //ELSE
  //    SELECT PARTN; HSEEK cIdFirma
  //    ? "Firma:", cidfirma, PadR( partn->naz, 25 ), partn->naz2
   //ENDIF

   ? "KONTO:", cIdkonto

   SELECT SUBAN

   ? "----- " + Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ----------------------------------- ------ ---------------- -------- -------- -------- "
   ?? Replicate( "-", 17 )
   IF fin_dvovalutno() // dvovalutno
      ?? " " + Replicate( "-", 17 )
   ENDIF
   ? "*RED *" + PadC( "PART-", FIELD_LEN_PARTNER_ID ) + "*      NAZIV POSLOVNOG PARTNERA      PTT     MJESTO         *  BROJ  * DATUM  * K1-K4  *"
   IF fin_dvovalutno()
      ?? PadC( "NEPLA�ENO", 35 )
   ELSE
      ?? PadC( "NEPLA�ENO", 17 )
   ENDIF

   ? " BR. " + PadC( "NER", FIELD_LEN_PARTNER_ID ) + "                                                                                         "

   ?? Replicate( "-", 17 )
   IF fin_dvovalutno() // dvovalutno
      ?? " " + Replicate( "-", 17 )
   ENDIF

   ? "*    *" + Replicate( " ", FIELD_LEN_PARTNER_ID ) + "*                                                           * RA�UNA *" + iif( cObzirDatVal == "D", " VALUTE ", " RA�UNA " ) + "*        *"

   cPom := ""
   IF cD_P = "1"
      cPom += "    DUGUJE "
   ELSE
      cPom += "   POTRA�. "
   ENDIF
   cPom += valuta_domaca_skraceni_naziv() + "  * "

   IF fin_dvovalutno() // dvovalutno
      IF cD_P = "1"
         cPom += "  DUGUJE "
      ELSE
         cPom += " POTRA�. "
      ENDIF
      cPom += ValPomocna() + "  *"
   ENDIF
   ?? cPom

   ? m

   RETURN .T.
