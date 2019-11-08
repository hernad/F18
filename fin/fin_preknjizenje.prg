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

MEMVAR gFinRj, cSection, cHistory, aHistory


FUNCTION fin_preknjizenje_konta()

   LOCAL fK1 := "N"
   LOCAL fk2 := "N"
   LOCAL fk3 := "N"
   LOCAL fk4 := "N"
   LOCAL cSK := "N"
   LOCAL GetList := {}
   LOCAL bCond
   LOCAL cPreknjizi
   LOCAL nD, nP, nD2, nP2
   LOCAL nC, nRbr
   LOCAL cK1, cK2, cK3, cK4
   LOCAL dDatOd, dDatDo, cIdKonto, cIdPartner
   LOCAL cIdFirma, cTip, cIdRj, dDatDok
   LOCAL cUslovKonto, cUslovPartner, cUslovRj
   LOCAL cFilterKonto, cFilterPartner, cFilterRj
   LOCAL cRascanitilPoRj, lRasclanitiPoRj

   nC := 50

   o_params()

   PRIVATE cSection := "1"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   RPar( "k1", @fk1 )
   RPar( "k2", @fk2 )
   RPar( "k3", @fk3 )
   RPar( "k4", @fk4 )

   SELECT params
   USE

   cIdFirma := self_organizacija_id()
   picBHD := FormPicL( "9 " + gPicBHD, 20 )

   // o_partner()

   dDatOd := CToD( "" )
   dDatDo := CToD( "" )

   cUslovKonto := Space( 100 )
   cUslovPartner := Space( 100 )
   IF gFinRj == "D"
      cUslovRj := Space( 100 )
   ENDIF

   cTip := "1"

   Box( "", 14, 65 )
   SET CURSOR ON

   cK1 := "9"
   cK2 := "9"
   cK3 := "99"
   cK4 := "99"
   cPreknjizi := "P"
   cStrana := "D"
   cIDVN := "88"
   cBrNal := "00000001"
   dDatDok := Date()
   cRascanitilPoRj := "D"
   

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 6 SAY8 "PREKNJIŽENJE SUBANALITICKIH KONTA"

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto   " GET cUslovKonto  PICT "@!S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Partner " GET cUslovPartner PICT "@!S50"
      IF gFinRj == "D"
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Rad.jed." GET cUslovRj PICT "@!S50"
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Rasclaniti po RJ" GET cRascanitilPoRj PICT "@!" VALID cRascanitilPoRj $ "DN"
      ENDIF
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Datum dokumenta od" GET dDatOd
      @ box_x_koord() + 7, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Protustav/Storno/Saldo (P/S/T) " GET cPreknjizi VALID cPreknjizi $ "PST" PICT "@!"
      READ

      IF cPreknjizi == "T"
         @ box_x_koord() + 9, box_y_koord() + 38 SAY8 "Duguje/Potražuje (D/P)" GET cStrana VALID cStrana $ "DP" PICT "@!"
      ENDIF

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Sifra naloga koji se generise" GET cIDVN
      @ box_x_koord() + 10, Col() + 2 SAY "Broj" GET cBrNal
      @ box_x_koord() + 10, Col() + 2 SAY "datum" GET dDatDok
      IF fk1 == "D"
         @ box_x_koord() + 11, box_y_koord() + 2 SAY "K1 (9 svi) :" GET cK1
      ENDIF
      IF fk2 == "D"
         @ box_x_koord() + 12, box_y_koord() + 2 SAY "K2 (9 svi) :" GET cK2
      ENDIF
      IF fk3 == "D"
         @ box_x_koord() + 13, box_y_koord() + 2 SAY "K3 (" + cK3 + " svi):" GET cK3
      ENDIF
      IF fk4 == "D"
         @ box_x_koord() + 14, box_y_koord() + 2 SAY "K4 (99 svi):" GET cK4
      ENDIF

      READ
      ESC_BCR

      cFilterKonto := Parsiraj( cUslovKonto, "IdKonto" )
      cFilterPartner := Parsiraj( cUslovPartner, "IdPartner" )

      IF gFinRj == "D"
         IF cRascanitilPoRj == "D"
            lRasclanitiPoRj := .T.
         ENDIF
      ENDIF

      IF gFinRj == "D"
         cFilterRj := Parsiraj( cUslovRj, "IdRj" )
      ENDIF

      IF cFilterKonto <> NIL .AND. cFilterPartner <> NIL
         EXIT
      ENDIF

      IF gFinRj == "D" .AND. cFilterRj <> NIL
         EXIT
      ENDIF

   ENDDO
   BoxC()

   cIdFirma := Left( cIdFirma, 2 )

   o_fin_pripr()
   select_o_konto()
   //o_suban()
   find_suban_za_period( cIdFirma, dDatOd, dDatDo, "idkonto,idpartner" )

   IF cK1 == "9"
      cK1 := ""
   ENDIF
   IF cK2 == "9"
      cK2 := ""
   ENDIF
   IF cK3 == REPL( "9", Len( ck3 ) )
      cK3 := ""
   ELSE
      cK3 := K3U256( cK3 )
   ENDIF
   IF cK4 == "99"
      cK4 := ""
   ENDIF

   SELECT SUBAN

/*
   IF ( gFinRj == "D" .AND. lRasclanitiPoRj )
      SET ORDER TO TAG "9" // idfirma+idkonto+idrj+idpartner+...
   ELSE
      SET ORDER TO TAG "1"
   ENDIF
*/

   cFilt1 := "IDFIRMA=" + dbf_quote( cIdFirma ) + ".and." + cFilterKonto + ".and." + cFilterPartner + IF( gFinRj == "D", ".and." + cFilterRj, "" ) + ;
      IIF( Empty( dDatOd ), "", ".and.DATDOK>=" + dbf_quote( dDatOd ) ) + ;
      IIF( Empty( dDatDo ), "", ".and.DATDOK<=" + dbf_quote( dDatDo ) ) + ;
      IIF( fk1 == "N", "", ".and.k1=" + dbf_quote( ck1 ) ) + ;
      IIF( fk2 == "N", "", ".and.k2=" + dbf_quote( ck2 ) ) + ;
      IIF( fk3 == "N", "", ".and.k3=ck3" ) + ;
      IIF( fk4 == "N", "", ".and.k4=" + dbf_quote( ck4 ) )

   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF

   GO TOP
   EOF CRET

   Pic := PicBhd

   nStr := 0
   nUd := 0
   nUp := 0      // DIN
   nUd2 := 0
   nUp2 := 0    // DEM
   nRbr := 0

   SELECT fin_pripr
   GO BOTTOM
   nRbr := field->rbr
   SELECT suban

   DO WHILE !Eof()
      cSin := Left( suban->idkonto, 3 )
      nKd := 0
      nKp := 0
      nKd2 := 0
      nKp2 := 0
      DO WHILE !Eof() .AND.  cSin == Left( suban->idkonto, 3 )
         cIdKonto := suban->IdKonto
         cIdPartner := suban->IdPartner
         IF gFinRj == "D"
            cIdRj := suban->idRj
         ENDIF
         nD := 0
         nP := 0
         nD2 := 0
         nP2 := 0

         IF ( gFinRj == "D" .AND. lRasclanitiPoRj )
            bCond := {|| cIdKonto == suban->IdKonto .AND. suban->IdRj == cIdRj .AND. suban->IdPartner == cIdPartner }
         ELSE
            bCond := {|| cIdKonto == suban->IdKonto .AND. cIdPartner == suban->IdPartner }
         ENDIF

         DO WHILE !Eof() .AND. Eval( bCond )
            IF suban->d_P == "1"
               nD += suban->iznosbhd
               nD2 += suban->iznosdem
            ELSE
               nP += suban->iznosbhd
               nP2 += suban->iznosdem
            ENDIF
            SKIP
         ENDDO    // partner

         SELECT fin_pripr

         // dodata opcija za preknjizenje saldo T
         IF cPreknjizi == "T"
            IF Round( nD - nP, 2 ) <> 0
               APPEND BLANK
               REPLACE idfirma WITH cIdFirma, idpartner WITH cIdPartner, idkonto WITH cIdKonto, idvn WITH cIdVn, brnal WITH cBrNal, datdok WITH dDatDok, field->rbr WITH ++nRbr
               REPLACE d_p WITH iif( cStrana == "D", "1", "2" ), iznosbhd with ( nD - nP ), iznosdem with ( nD2 - nP2 )
               IF gFinRj == "D"
                  REPLACE idrj WITH cIdRj
               ENDIF
            ENDIF
         ENDIF

         IF cPreknjizi == "P"
            IF Round( nD - nP, 2 ) <> 0
               APPEND BLANK
               REPLACE idfirma WITH cIdFirma, idpartner WITH cIdPartner, idkonto WITH cIdKonto, idvn WITH cIdVn, brnal WITH cBrNal, datdok WITH dDatDok, field->rbr WITH ++nRbr
               REPLACE  d_p WITH iif( nD - nP > 0, "2", "1" ), iznosbhd WITH Abs( nD - nP ), iznosdem WITH Abs( nD2 - nP2 )
               IF gFinRj == "D"
                  REPLACE idrj WITH cIdRj
               ENDIF
            ENDIF
         ENDIF

         IF cPreknjizi == "S"
            IF Round( nD, 3 ) <> 0
               APPEND BLANK
               REPLACE idfirma WITH cIdFirma, idpartner WITH cIdPartner, idkonto WITH cIdKonto, idvn WITH cIdVn, brnal WITH cBrNal, datdok WITH dDatDok, field->rbr WITH ++nRbr
               REPLACE  d_p WITH "1", iznosbhd WITH -nd, iznosdem WITH -nd2
               IF gFinRj == "D"
                  REPLACE idrj WITH cIdRj
               ENDIF
            ENDIF
            IF Round( nP, 3 ) <> 0
               APPEND BLANK
               REPLACE idfirma WITH cIdFirma, idpartner WITH cIdPartner, idkonto WITH cIdKonto, idvn WITH cIdVn, brnal WITH cBrNal, datdok WITH dDatDok, rbr WITH  ++nRbr
               REPLACE  d_p WITH "2", iznosbhd WITH -nP, iznosdem WITH -nP2
               IF gFinRj == "D"
                  REPLACE idrj WITH cIdRj
               ENDIF
            ENDIF
         ENDIF
         SELECT suban
         nKd += nD
         nKp += nP  // ukupno  za klasu
         nKd2 += nD2
         nKp2 += nP2  // ukupno  za klasu
      ENDDO  // sintetika

      nUd += nKd
      nUp += nKp   // ukupno za sve
      nUd2 += nKd2
      nUp2 += nKp2   // ukupno za sve
   ENDDO // eof

   my_close_all_dbf()

   RETURN .T.
