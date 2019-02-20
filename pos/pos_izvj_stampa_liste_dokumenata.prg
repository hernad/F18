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

FUNCTION pos_stampa_liste_dokumenata()

   LOCAL cIdVd
   LOCAL dDatOd := CToD( "" )
   LOCAL dDatDo := danasnji_datum()
   LOCAL cIdRadnik
   LOCAL nBH := 8
   LOCAL nR := 5
   LOCAL cIdPos := gIdPos
   LOCAL cLM := ""
   LOCAL nRW := 13
   LOCAL nSir
   LOCAL GetList := {}

   SET CURSOR ON

   cIdPos := gIdPos
   cIdRadnik := Space( FIELD_LEN_POS_IDRADNIK )
   cIdVd := Space( 2 )

   SET CURSOR ON
   Box(, 10, 77 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY " Prodajno mjesto (prazno-sva)" GET cIdPos PICT "@!" VALID Empty( cIdPos ) .OR. p_pos_kase( @cIdPos, 1, 37 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "          Radnik (prazno-svi)" GET cIdRadnik PICT "@!" VALID Empty( cIdRadnik ) .OR. P_Osob( @cIdRadnik, 2, 37 )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Vrste dokumenata (prazno-svi)" GET cIdVd PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "            Počevši od datuma" GET dDatOd PICT "@D" VALID dDatOd <= danasnji_datum() .AND. dDatOd <= dDatDo
   @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "                 zaključno sa" GET dDatDo PICT "@D" VALID dDatDo <= danasnji_datum() .AND. dDatOd <= dDatDo
   READ
   ESC_BCR

   BoxC()

   seek_pos_doks_za_period( cIdPos, cIdVd, dDatOd, dDatDo )

   EOF CRET

   START PRINT CRET
   ?
   ? PadC( "KASA " + gIdPos, 40 )
   ?U PadC( "ŠTAMPA LISTE DOKUMENATA", nSir )
   ? PadC( "NA DAN " + FormDat1 ( danasnji_datum() ), nSir )
   ? PadC( "-------------------------", nSir )
   ? PadC( "Za period od " + FormDat1( dDatOd ) + " do " + FormDat1( dDatDo ), nSir )
   ?

   ? cLM + "VD", PadR( "Broj", 9 )
   ?? " " + PadR( "Radnik", nRW ), "BrS", " Iznos"
   ? cLM + "--", REPL( "-", 9 )

   ?? " " + REPL( "-", nRW ), "---", REPL( "-", 10 )

   IF !Empty( cIdVd )
      nSuma := 0
   ENDIF

   DO WHILE !Eof()

      IF !Empty( cIdRadnik ) .AND. pos_doks->IdRadnik <> cIdRadnik
         SKIP
         LOOP
      ENDIF

      ? cLM
      ?? pos_doks->IdVd, PadR( AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), 9 )

      select_o_pos_osob( pos_doks->IdRadnik )
      ?? " " + Left( OSOB->Naz, nRW )
      nBrStav := 0
      nIznos := 0

      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )

      DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )
         nBrStav++
         nIznos += POS->kolicina * POS->cijena
         SKIP
      ENDDO

      ?? " " + Str( nBrStav, 3 ), Str( nIznos, 8, 2 )

      IF !Empty( cIdVd )
         nSuma += nIznos
      ENDIF

      SELECT pos_doks
      SKIP
   ENDDO

   IF !Empty( cIdVd )
      ? cLM + "--", REPL ( "-", 9 )
      ?? " " + REPL( "-", nRW ), "---", REPL( "-", 8 )
      ? cLM + PadL( "U K U P N O  (" + gDomValuta + ")", 3 + 9 + 0 + 1 + nRW ), Str( nSuma, 12, 2 )
   ENDIF

   ENDPRINT

   RETURN .T.
