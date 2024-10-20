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


// -------------------------------------------
// otvori potrebne tabele
// -------------------------------------------
STATIC FUNCTION o_kzb_tables()

   O_MAT_NALOG
   O_MAT_SUBAN
   O_MAT_ANAL
   O_MAT_SINT

   RETURN



// -----------------------------------------------
// kontrola zbira datoteka
// -----------------------------------------------
FUNCTION mat_kzb()

   LOCAL _pict := "999999999.99"
   LOCAL _header

   _header := PadR( "* NAZIV", 13 )
   _header += PadR( "* DUGUJE " + valuta_domaca_skraceni_naziv(), 13 )
   _header += PadR( "* POTRAZ." + valuta_domaca_skraceni_naziv(), 13 )
   _header += PadR( "* DUGUJE " + ValPomocna(), 13 )
   _header += PadR( "* POTRAZ." + ValPomocna(), 13 )

   o_kzb_tables()

   Box( "KZB", 10, 77, .F. )

   set_cursor_off()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY _header

   SELECT mat_nalog

   GO TOP

   nDug := nPot := nDug2 := nPot2 := 0

   DO WHILE !Eof() .AND. Inkey() != 27
      nDug += Dug
      nPot += Pot
      nDug2 += Dug2
      nPot2 += Pot2
      SKIP
   ENDDO

   ESC_BCR

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "NALOZI", 13 )
   @ Row(), Col() + 1 SAY nDug PICT _pict
   @ Row(), Col() + 1 SAY nPot PICT _pict
   @ Row(), Col() + 1 SAY nDug2 PICT _pict
   @ Row(), Col() + 1 SAY nPot2 PICT _pict

   SELECT mat_sint
   nDug := nPot := nDug2 := nPot2 := 0
   GO TOP
   DO WHILE !Eof() .AND. Inkey() != 27
      nDug += Dug; nPot += Pot
      nDug2 += Dug2; nPot2 += Pot2
      SKIP
   ENDDO
   ESC_BCR
   @ box_x_koord() + 5, box_y_koord() + 2 SAY PadL( "SINTETIKA", 13 )
   @ Row(), Col() + 1 SAY nDug PICTURE _pict
   @ Row(), Col() + 1 SAY nPot PICTURE _pict
   @ Row(), Col() + 1 SAY nDug2 PICTURE _pict
   @ Row(), Col() + 1 SAY nPot2 PICTURE _pict


   SELECT mat_anal
   nDug := nPot := nDug2 := nPot2 := 0
   GO TOP
   DO WHILE !Eof() .AND. Inkey() != 27
      nDug += Dug; nPot += Pot
      nDug2 += Dug2; nPot2 += Pot2
      SKIP
   ENDDO
   ESC_BCR
   @ box_x_koord() + 7, box_y_koord() + 2 SAY PadL( "ANALITIKA", 13 )
   @ Row(), Col() + 1 SAY nDug PICTURE _pict
   @ Row(), Col() + 1 SAY nPot PICTURE _pict
   @ Row(), Col() + 1 SAY nDug2 PICTURE _pict
   @ Row(), Col() + 1 SAY nPot2 PICTURE _pict

   SELECT mat_suban
   nDug := nPot := nDug2 := nPot2 := 0
   GO TOP
   DO WHILE !Eof() .AND. Inkey() != 27
      IF D_P == "1"
         nDug += Iznos; nDug2 += Iznos2
      ELSE
         nPot += Iznos; nPot2 += Iznos2
      ENDIF
      SKIP
   ENDDO
   ESC_BCR
   @ box_x_koord() + 9, box_y_koord() + 2 SAY PadL( "SUBANALITIKA", 13 )
   @ Row(), Col() + 1 SAY nDug PICTURE _pict
   @ Row(), Col() + 1 SAY nPot PICTURE _pict
   @ Row(), Col() + 1 SAY nDug2 PICTURE _pict
   @ Row(), Col() + 1 SAY nPot2 PICTURE _pict

   Inkey( 0 )
   BoxC()

   my_close_all_dbf()

   RETURN
