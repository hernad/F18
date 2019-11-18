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


FUNCTION specifikacija_po_analitickim_kontima()

   LOCAL cSK := "N"
   PRIVATE nC := 66

   cIdFirma := self_organizacija_id()
   picBHD := FormPicL( "9 " + gPicBHD, 20 )

   // o_partner()

   dDatOd := dDatDo := CToD( "" )

   qqKonto := Space( 100 )

   cTip := "1"
   Box( "", 10, 65 )
   set_cursor_on()

   cNula := "N"

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 6 SAY "SPECIFIKACIJA ANALITICKIH KONTA"

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto " GET qqKonto  PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum od" GET dDatOd
      @ box_x_koord() + 5, Col() + 2 SAY "do" GET dDatDo
      IF fin_dvovalutno()
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Obracun za " + AllTrim( valuta_domaca_skraceni_naziv() ) + "/" + AllTrim( ValPomocna() ) + " (1/2):" GET cTip VALID ctip $ "12"
      ENDIF
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz sintetickih konta (D/N):" GET cSK PICT "@!" VALID cSK $ "DN"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prikaz stavki sa saldom 0 D/N" GET cNula PICT "@!" VALID cNula  $ "DN"
      cIdRJ := ""
      IF gFinRj == "D" .AND. gSAKrIz == "D"
         cIdRJ := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
         @ box_x_koord() + 10, box_y_koord() + 2 SAY "Radna jedinica (999999-sve): " GET cIdRj
      ENDIF
      READ
      ESC_BCR
      aUsl1 := Parsiraj( qqKonto, "IdKonto" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO

   BoxC()

   IF cIdRj == REPLICATE("9", FIELD_LEN_FIN_RJ_ID ); cIdrj := ""; ENDIF

   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. "." $ cidrj
      cidrj := Trim( StrTran( cidrj, ".", "" ) )
      // odsjeci ako je tacka. prakticno "01. " -> sve koje pocinju sa  "01"
   ENDIF

   cIdFirma := Left( cIdFirma, 2 )

   // o_konto()
   // IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
// otvori_sint_anal_kroz_temp( .F., "IDRJ='" + cIdRJ + "'" )
// ELSE
   // o_anal()
   // ENDIF

// SELECT ANAL
// SET ORDER TO TAG "1"
   find_anal_za_period( cIdFirma, dDatOd, dDatDo, "idfirma,idkonto,datnal" )

   cFilt1 := "IdFirma==" + dbf_quote( cIdFirma )
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      cFilt1 += ( ".and.DatNal>=" + dbf_quote( dDatOd ) + ".and.DatNal<=" + dbf_quote( dDatDo ) )
   ENDIF
   IF aUsl1 <> ".t."
      cFilt1 += ( ".and." + aUsl1 )
   ENDIF


   SET FILTER TO &cFilt1

   GO TOP

   EOF CRET

   Pic := PicBhd


   IF !start_print()
      RETURN .F.
   ENDIF

   m := "------ --------------------------------------------------------- --------------------- -------------------- --------------------"
   nStr := 0

   nud := nup := 0
   DO WHILE !Eof()

      cSin := Left( idkonto, 3 )
      nkd := nkp := 0
      DO WHILE !Eof() .AND.  cSin == Left( idkonto, 3 )

         cIdKonto := IdKonto
         nd := np := 0

         IF PRow() == 0; zagl_spec_anal(); ENDIF

         DO WHILE !Eof() .AND. cIdKonto == IdKonto
            IF cTip == "1"
               nD += dugbhd; nP += potbhd
            ELSE
               nD += dugdem; nP += potdem
            ENDIF
            SKIP
         ENDDO
         IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; zagl_spec_anal(); ENDIF

         select_o_konto( cIdKonto )

         SELECT ANAL

         IF cNula == "D" .OR. Round( nd - np, 3 ) <> 0
            ? cIdkonto, KONTO->naz
            nC := PCol() + 1
            @ PRow(), PCol() + 1 SAY nd PICT pic
            @ PRow(), PCol() + 1 SAY np PICT pic
            @ PRow(), PCol() + 1 SAY nd - np PICT pic
            nKd += nD; nKp += nP  // ukupno  za klasu
         ENDIF  // cnula

      ENDDO  // sintetika

      IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; zagl_spec_anal(); ENDIF
      IF cSK == "D" .AND. ( nkd != 0 .OR. nkp != 0 )
         ? m
         ?  "SINT.K.", cSin, ":"
         @ PRow(), nC       SAY nKd PICT pic
         @ PRow(), PCol() + 1 SAY nKp PICT pic
         @ PRow(), PCol() + 1 SAY nKd - nKp PICT pic
         ? m
      ENDIF
      nUd += nKd; nUp += nKp   // ukupno za sve
   ENDDO

   IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; zagl_spec_anal(); ENDIF
   ? m
   ? " UKUPNO:"
   @ PRow(), nC       SAY nUd PICT pic
   @ PRow(), PCol() + 1 SAY nUp PICT pic
   @ PRow(), PCol() + 1 SAY nUd - nUp PICT pic
   ? m
   FF
   end_print()
   closeret

   RETURN .T.





STATIC FUNCTION zagl_spec_anal()

   ?
   P_COND
   ?? "FIN.P:SPECIFIKACIJA ANALITICKIH KONTA  ZA", AllTrim( iif( cTip == "1", valuta_domaca_skraceni_naziv(), ValPomocna() ) )
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ?? "  ZA NALOGE U PERIODU ", dDatOd, "-", dDatDo
   ENDIF
   ?? " NA DAN: "; ?? Date()

   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )


   ? "Firma:", self_organizacija_id(), self_organizacija_naziv()


   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
      ? "Radna jedinica ='" + cIdRj + "'"
   ENDIF

   SELECT ANAL
   ? m
   ? "KONTO      N A Z I V                                                           duguje            potrazuje                saldo"
   ? m

   RETURN .T.
