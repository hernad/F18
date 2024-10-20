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


FUNCTION PrintParovno( nKolUlaz, nKolIzlaz )

   ?
   ?
   ? Replicate( "=", 80 )
   ? "PAROVNO:"
   @ PRow(), PCol() + 1  SAY  "Ulaz:"
   @ PRow(), PCol() + 1  SAY  nKolUlaz  PICT "9,999,999"
   @ PRow(), PCol() + 1  SAY  "Izlaz:"
   @ PRow(), PCol() + 1  SAY  nKolIzlaz PICT "9,999,999"
   @ PRow(), PCol() + 1  SAY  "Stanje:"
   @ PRow(), PCol() + 1  SAY  nKolUlaz - nKolIzlaz PICT "9,999,999"
   ? Replicate( "=", 80 )

   RETURN .T.

/*   
// -------------------------------------------
// vraca naziv prodavnice iz tabele OBJEKTI
// -------------------------------------------
FUNCTION get_prod_naz( cIdKonto )

   LOCAL nTArea := Select()
   LOCAL cNaz := "???"

   kalk_o_objekti()
   SELECT objekti
   SET ORDER TO TAG "idobj"
   GO TOP
   SEEK cIdKonto // objekti

   IF Found()
      cNaz := AllTrim( field->naz )
   ENDIF

   SELECT ( nTArea )

   RETURN cNaz
*/