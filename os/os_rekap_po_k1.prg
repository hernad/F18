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



FUNCTION os_rekapitulacija_po_k1()

  // o_k1()
   //o_rj()

   o_os_sii()

   cIdRj := Space( 4 )
   cON := "N"
   cKolP := "N"
   cPocinju := "N"
   cDNOS := "D"

   Box(, 4, 77 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno svi):" GET cIdRj VALID Empty( cIdRj ) .OR. p_rj( @cIdRj )
   @ box_x_koord() + 1, Col() + 2 SAY "sve koje pocinju " GET cPocinju VALID cPocinju $ "DN" PICT "@!"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prikaz svih neotpisanih/otpisanih/samo novonabavljenih (N/O/B) sredstava:" GET cON PICT "@!" VALID con $ "ONB"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prikaz sredstava D/N:" GET cDNOs PICT "@!" VALID cDNOs $ "DN"
   READ
   ESC_BCR
   BoxC()

   IF cPocinju == "D" .OR. Empty( cIdRj )
      cIdRj := Trim( cIdRj )
   ENDIF

   m := "----- ---------- ------------------------- -------------"

   select_o_os_or_sii()
   SET ORDER TO TAG "2"
   // idrj+id+dtos(datum)

   cFilt1 := "idrj=cIdRj"
   cSort1 := "k1+idrj"

   Box(, 1, 30 )
   INDEX on &cSort1 TO "TMPSP2" for &cFilt1 Eval( TekRec() ) every 10
   BoxC()

   START PRINT CRET

   nCol1 := 48

   ZglK1()

   GO TOP

   DO WHILE !Eof()

      select_o_os_or_sii()
      nKol := 0
      cK1 := field->k1
      DO WHILE !Eof() .AND. cK1 = field->k1

         select_o_os_or_sii()
         nKolRJ := 0
         nRbr := 0
         cTRj := field->idrj
         DO WHILE !Eof() .AND. cK1 == field->k1 .AND. cTRj == field->idrj
            select_o_os_or_sii()
            IF ( cON = "B" .AND. Year( os_datum_obracuna() ) <> Year( field->datum ) )
               // nije novonabavljeno
               SKIP
               LOOP
               // prikazi samo novonabavlj.
            ENDIF

            IF ( !Empty( field->datotp ) .AND. Year( field->datotp ) = Year( os_datum_obracuna() ) ) .AND. cON $ "NB"
               // otpisano sredstvo , a zelim prikaz neotpisanih
               SKIP
               LOOP
            ENDIF

            IF ( Empty( field->datotp ) .OR. Year( field->datotp ) < Year( os_datum_obracuna() ) ) .AND. cON == "O"
               // neotpisano, a zelim prikaz otpisanih
               SKIP
               LOOP
            ENDIF

            nKolRJ += field->kolicina
            IF cDNOS == "D"
               ? Str( ++nrbr, 4 ) + ".", field->id, field->naz
               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY field->kolicina PICT os_pic_kolicina()
            ENDIF

            SKIP
            select_o_os_or_sii()

         ENDDO

         IF PRow() > 62
            FF
            ZglK1()
         ENDIF

         ? m
         ? "UKUPNO ZA RJ", cTRJ, "-", cK1
         @ PRow(), nCol1 SAY nKolRJ   PICT os_pic_kolicina()
         ? m
         nKol += nKolRJ
      ENDDO

      IF PRow() > 62
         FF
         ZglK1()
      ENDIF

      ? StrTran( m, "-", "=" )
      SELECT k1
      HSEEK cK1

      select_o_os_or_sii()

      ? "UKUPNO ZA GRUPU", cK1, k1->naz
      @ PRow(), nCol1 SAY nKol PICT os_pic_kolicina()
      ? StrTran( m, "-", "=" )

   ENDDO

   ENDPRINT

   my_close_all_dbf()

   RETURN


STATIC FUNCTION TekRec()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY RecNo()

   RETURN NIL



STATIC FUNCTION ZglK1()

   LOCAL _mod_name := "OS"

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   ?

   P_12CPI

   ?? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?
   ? _mod_name + ": Rekapitulacija po grupama - k1 "

   IF cON == "N"
      ?? "sredstava u upotrebi"
   ELSE
      ?? "sredstava otpisanih u toku godine"
   ENDIF

   ?? "     Datum:", os_datum_obracuna()

   select_o_rj( cIdRj )
   select_o_os_or_sii()

   ? "Radna jedinica:", cIdRj, rj->naz

   IF cPocinju == "D"
      ?? "(SVEUKUPNO)"
   ENDIF

   ? m
   ? "Rbr                                           Kolicina"
   ? m

   RETURN .T.
