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


FUNCTION fin_spec_prebijeno_konto_konto2( lOtvSt )

   LOCAL fK1 := "N"
   LOCAL fk2 := "N"
   LOCAL fk3 := "N"
   LOCAL fk4 := "N"
   LOCAL nC1 := 35
   LOCAL cUslovKonta
   LOCAL cIdFirma
   LOCAL cUslovPartneri := PadR( "", 100 )
   LOCAL cIdKonto :=  PadR( "2110", 7 )
   LOCAL cIdKonto2 := PadR( "4310", 7 )

   cIdFirma := self_organizacija_id()

   PRIVATE picBHD := FormPicL( "9 " + gPicBHD, 16 )
   PRIVATE picDEM := FormPicL( "9 " + pic_iznos_eur(), 14 ), cPG := "D"
   PRIVATE lOtvoreneStavke := lOtvSt

   // o_konto()


   cDinDem := "1"
   dDatOd := dDatDo := CToD( "" )
   cKumul := cPredh := "1"


   cIdFirma := self_organizacija_id()

   cK1 := cK2 := "9"; cK3 := cK4 := "99"

   // IF my_get_from_ini( "FIN", "LimitiPoUgovoru_PoljeK3", "N", SIFPATH ) == "D"
   // cK3 := "999"
   // ENDIF

   cNula := "D"

   Box( "", 17, 65 )
   set_cursor_on()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "SPECIFIKACIJA SUBANALITIKE KONTO/KONTO2"
   READ
   // DO WHILE .T.


   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

   cIdKonto := PadR( cIdKonto, 7 )
   cIdKonto2 := PadR( cIdKonto2, 7 )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Konto   " GET cIdKonto  VALID p_konto( @cIdKonto )
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Konto 2 " GET cIdKonto2  VALID p_konto( @cIdKonto2 ) .AND. cIdKonto2 > cIdKonto
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Partner " GET cUslovPartneri PICT "@!S50"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Datum dokumenta od:" GET dDatod
   @ box_x_koord() + 8, Col() + 2 SAY "do" GET dDatDo   VALID dDatOd <= dDatDo
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikazi mjesto partnera (D/N)" GET cPG PICT "@!" VALID cPG $ "DN"
   IF fin_dvovalutno()
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Prikaz " + AllTrim( valuta_domaca_skraceni_naziv() ) + "/" + AllTrim( ValPomocna() ) + " (1/2)" GET cDinDem PICT "@!" VALID cDinDem $ "12"
   ENDIF
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Prikaz stavki sa saldom 0 D/N/2/4" GET cNula PICT "@!" VALID cNula  $ "DN24"

   IF fk1 == "D"; @ box_x_koord() + 14, box_y_koord() + 2 SAY "K1 (9 svi) :" GET cK1; ENDIF
   IF fk2 == "D"; @ box_x_koord() + 15, box_y_koord() + 2 SAY "K2 (9 svi) :" GET cK2; ENDIF
   IF fk3 == "D"; @ box_x_koord() + 16, box_y_koord() + 2 SAY "K3 (" + ck3 + " svi):" GET cK3; ENDIF
   IF fk4 == "D"; @ box_x_koord() + 17, box_y_koord() + 2 SAY "K4 (99 svi):" GET cK4; ENDIF

   READ

   ESC_BCR

   // aUsl1 := Parsiraj( cUslovPartneri, "IdPartner", "C" )

   // IF aUsl1 <> NIL; exit; ENDIF // ako je NIL - sintaksna greska

   // ENDDO

   BoxC()

   IF cPG == "N"
      PRIVATE m := Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ------------------------- ---------------- ---------------- ----------------"
   ELSE
      PRIVATE m := Replicate( "-", FIELD_LEN_PARTNER_ID ) + " ------------------------- ---------------- ---------------- ---------------- ----------------"
   ENDIF

   cUslovKonta := PadR( cIdKonto + ";" + cIdKonto2 + ";", 100 )
   find_suban_by_konto_partner( cIdFirma, cUslovKonta, cUslovPartneri, NIL, "IdFirma,IdPartner,IdKonto,brdok", .T. )

   cIdRj := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )  // samo da program ne ispada u f-ji fin_cisti_polja_k4k4_funk_fond()
   cFunk := "99999"
   cFond := "9999"
 
   fin_cisti_polja_k4k4_funk_fond( .T., @cIdRj, @cK1, @cK2, @cK3, @cK4, @cFunk, @cFond )

   cFilt1 := ".t."

   IF  fk1 == "N" .AND. fk2 == "N" .AND. fk3 == "N" .AND. fk4 == "N"

      IF Empty( dDatOd ) .AND. Empty( dDatDo )
         // IF Len( aUsl1 ) == 0
         cFilt1 := ".t."
         // ELSE
         // cFilt1 := aUsl1
         // ENDIF
      ELSE
         cFilt1 := "DATDOK>=" + dbf_quote( dDatOd ) + ".and.DATDOK<=" + dbf_quote( dDatDo ) // + ".and." + aUsl1
      ENDIF

   ELSE  // odigraj sa ck4
      IF Empty( dDatOd ) .AND. Empty( dDatDo )
         cFilt1 := "k1=" + dbf_quote( ck1 ) + ".and.k2=" + dbf_quote( ck2 ) + ;
            ".and.k3=ck3.and.k4=" + dbf_quote( ck4 )
      ELSE
         cFilt1 := "DATDOK>=" + dbf_quote( dDatOd ) + ".and.DATDOK<=" + dbf_quote( dDatDo ) + ".and." + ;
            " k1=" + dbf_quote( cK1 ) + ".and.k2=" + dbf_quote( cK2 ) + ;
            ".and.k3=cK3.and.k4=" + dbf_quote( cK4 )
      ENDIF
   ENDIF

   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF

   SET ORDER TO TAG 2
   GO TOP

   EOF CRET

   nStr := 0

   IF !start_print()
      RETURN .F.
   ENDIF



   IF nStr == 0; zagl_prebijeno_konto_konto2( cIdKonto, cIdKonto2 ); ENDIF


   nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0
   DO WHILE !Eof() .AND. IdFirma == cIdFirma



      cIdPartner := IdPartner

      nDBHD := nPBHD := nDDEM := nPDEM := 0
      SEEK cIdfirma + cIdpartner + cIdKonto
      IF !Found()
         SEEK cidfirma + cidpartner + cIdKonto2
         IF !Found()
            SEEK cidfirma + cidpartner + "!"
         ENDIF
      ENDIF

      DO WHILE !Eof() .AND. IdFirma == cIdFirma .AND. cIdpartner == idpartner
         IF idkonto == cIdKonto
            IF D_P == "1"
               nDBHD += iznosbhd
               nDDEM += iznosdem
            ELSE
               nDBHD -= iznosbhd
               nDDEM -= iznosdem
            ENDIF
         ELSEIF idkonto == cIdKonto2
            IF D_P == "1"
               nPBHD -= iznosbhd
               nPDEM -= iznosdem
            ELSE
               nPBHD += iznosbhd
               nPDEM += iznosdem
            ENDIF
         ENDIF
         SKIP
      ENDDO

      fuslov := .F.
      IF  cNula == "D"
         IF ( ndbhd <> 0 .OR. npbhd <> 0 )
            fuslov := .T.
         ENDIF
      ELSEIF cnula == "N"
         IF Round( nDBHD - nPBHD, 3 ) <> 0
            fuslov := .T.
         ENDIF
      ELSEIF cnula == "2"
         IF Round( nDBHD - nPBHD, 3 ) <> 0   .AND.  Round( ndbhd, 3 ) <> 0  .AND. Round( npbhd, 3 ) <> 0
            fuslov := .T.
            // i saldo 1 i saldo2 su zivi ,   i ukupan saldo <>0
         ENDIF

      ELSEIF cnula == "4"
         IF Round( ndbhd, 3 ) <> 0  .AND. Round( npbhd, 3 ) <> 0
            fuslov := .T.
            // bitno je sa su saldo 1 i saldo2 su zivi
         ENDIF
      ENDIF

      IF fUslov
         IF PRow() > 56 + dodatni_redovi_po_stranici()
            FF
            zagl_prebijeno_konto_konto2()
         ENDIF

         @ PRow() + 1, 0 SAY cidpartner

         select_o_partner( cIdPartner )
         SELECT suban

         @ PRow(), PCol() + 1 SAY PadR( partn->naz, 25 )

         IF cPG == "D"
            @ PRow(), PCol() + 1 SAY PARTN->Mjesto
         ENDIF

         nC1 := PCol() + 1

         IF cDinDem == "1"
            @ PRow(), PCol() + 1 SAY nDBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nPBHD PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nDBHD - nPBHD PICTURE picBHD
            nDugBHD += nDBHD
            nPotBHD += nPBHD
         ELSEIF cDinDem == "2"   // devize
            @ PRow(), PCol() + 1 SAY nDDEM PICTURE picbhd
            @ PRow(), PCol() + 1 SAY nPDEM PICTURE picbhd
            @ PRow(), PCol() + 1 SAY nDDEM - nPDEM PICTURE picbhd
            nDugDEM += nDDEM
            nPotDEM += nPDEM
         ENDIF
      ENDIF


   ENDDO
   ? M
   ? "UKUPNO:"

   IF cDinDem == "1"
      @ PRow(), nC1      SAY nDugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICT picbhd
   ELSEIF cDinDem == "2"
      @ PRow(), nC1      SAY nDugDEM PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nDugDEM - nPotDEM PICT picbhd
   ENDIF
   ? m

   FF
   end_print()
   closeret

   RETURN .T.



STATIC FUNCTION zagl_prebijeno_konto_konto2( cIdKonto, cIdKonto2 )

   ?
   P_COND
   ?? "FIN: SPECIFIKACIJA SUBANALITIKE ", cIdKonto, "-", cIdKonto2, " ZA "
   IF cDinDem == "1"
      ?? valuta_domaca_skraceni_naziv()
   ELSEIF cDinDem == "2"
      ?? ValPomocna()
   ENDIF
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ?? "  ZA DOKUMENTE U PERIODU ", dDatOd, "-", dDatDo
   ENDIF
   ?? " NA DAN: "; ?? Date()
   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )


   ? "Firma:", self_organizacija_id(), self_organizacija_naziv()


   SELECT SUBAN

   ? m
   IF cPG = "D"
      ? PadR( "PARTN.", FIELD_LEN_PARTNER_ID ) + " PARTNER                       MJESTO           saldo1         saldo2           saldo"
   ELSE
      ? PadR( "PARTN.", FIELD_LEN_PARTNER_ID ) + "  PARTNER                       saldo1           saldo2           saldo"
   ENDIF
   ? m

   RETURN .T.
