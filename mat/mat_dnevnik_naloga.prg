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

STATIC _pict := "@Z 999999999.99"

// --------------------------------------------
// stampa liste naloga
// --------------------------------------------
FUNCTION mat_dnevnik_naloga()

   LOCAL _line
   LOCAL _dug
   LOCAL _pot
   LOCAL _dug2
   LOCAL _pot2
   LOCAL _rbr
   LOCAL _row_pos

   O_MAT_NALOG
   SELECT mat_nalog
   SET ORDER TO TAG "1"
   GO TOP

   START PRINT CRET

   _line := _get_line()
   _rbr := 0
   _row_pos := 0

   _dug := 0
   _pot := 0
   _dug2 := 0
   _pot2 := 0

   DO WHILE !Eof()

      IF PRow() == 0
         _zaglavlje( _line )
      ENDIF

      DO WHILE !Eof() .AND. PRow() < 66
         @ PRow() + 1, 0 SAY ++_rbr PICTURE "9999"
         @ PRow(), PCol() + 2 SAY field->IdFirma
         @ PRow(), PCol() + 2 SAY field->IdVN
         @ PRow(), PCol() + 2 SAY field->BrNal
         @ PRow(), PCol() + 1 SAY field->DatNal
         _row_pos := PCol()
         @ PRow(), PCol() + 1 SAY field->Dug  PICTURE _pict
         @ PRow(), PCol() + 1 SAY field->Pot  PICTURE _pict
         @ PRow(), PCol() + 1 SAY field->Dug2 PICTURE _pict
         @ PRow(), PCol() + 1 SAY field->Pot2 PICTURE _pict

         _dug += field->Dug
         _pot += field->Pot
         _dug2 += field->Dug2
         _pot2 += field->Pot2

         SKIP
      ENDDO
      IF PRow() > 65
         FF
      ENDIF
   ENDDO

   ? _line
   ? "UKUPNO:"
   @ PRow(), _row_pos + 1 SAY _dug        PICTURE _pict
   @ PRow(), PCol() + 1 SAY _pot  PICTURE _pict
   @ PRow(), PCol() + 1 SAY _dug2 PICTURE _pict
   @ PRow(), PCol() + 1 SAY _pot2 PICTURE _pict
   ? _line

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


// -------------------------------------------
// zaglavlje izvjestaja
// -------------------------------------------
STATIC FUNCTION _zaglavlje( line )

   LOCAL _r_line_1
   LOCAL _r_line_2

   P_COND

   ?? "DNEVNIK NALOGA NA DAN:"
   @ PRow(), PCol() + 2 SAY Date()

   ? line

   _r_line_1 := PadR( "*RED", 4 )
   _r_line_2 := PadR( "*BRD", 4 )

   _r_line_1 += PadR( "*FIR", 4 )
   _r_line_2 += PadR( "*MA", 4 )

   _r_line_1 += PadR( "* V", 4 )
   _r_line_2 += PadR( "* N", 4 )

   _r_line_1 += PadR( "* BR", 6 )
   _r_line_2 += PadR( "* NAL", 6 )

   _r_line_1 += PadR( "* DAT", 9 )
   _r_line_2 += PadR( "* NAL", 9 )

   _r_line_1 += PadR( "*   DUGUJE", 13 )
   _r_line_2 += PadR( "*   " + valuta_domaca_skraceni_naziv(), 13 )

   _r_line_1 += PadR( "* POTRAZUJE", 13 )
   _r_line_2 += PadR( "*   " + valuta_domaca_skraceni_naziv(), 13 )

   _r_line_1 += PadR( "*   DUGUJE", 13 )
   _r_line_2 += PadR( "*   " + ValPomocna(), 13 )

   _r_line_1 += PadR( "* POTRAZUJE", 13 )
   _r_line_2 += PadR( "*   " + ValPomocna(), 13 )

   ? _r_line_1
   ? _r_line_2

   ? line

   RETURN


// vraca liniju za report
STATIC FUNCTION _get_line()

   LOCAL _line := ""

   _line := Replicate( "-", 4 )
   _line += Space( 1 )
   _line += Replicate( "-", 3 )
   _line += Space( 1 )
   _line += Replicate( "-", 3 )
   _line += Space( 1 )
   _line += Replicate( "-", 5 )
   _line += Space( 1 )
   _line += Replicate( "-", 8 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )
   _line += Space( 1 )
   _line += Replicate( "-", 12 )

   RETURN _line
