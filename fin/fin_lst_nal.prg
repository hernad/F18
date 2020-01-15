/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*

FUNCTION st_sv_nal()

   aFields := get_exp_fields()
   xlsx_export_init( aFields )

   o_suban()
   o_konto()
   //o_partner()

   SELECT suban
   SET ORDER TO TAG "4" // "4", "idFirma+IdVN+BrNal+Rbr"
   GO TOP


   Box(, 4, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Exportujem naloge......"

   DO WHILE !Eof() .AND. self_organizacija_id() == idfirma

      select_o_partner( suban->idpartner )

      cPartNaz := partn->naz

      IF Empty( suban->idpartner )
         cPartNaz := ""
      ENDIF

      SELECT suban

      fill_export( field->idfirma, field->idvn, field->brnal, ;
         field->rbr, field->idkonto, field->idpartner, cPartNaz, ;
         field->d_p, field->iznosbhd, field->datdok, ;
         field->datval, field->brdok, field->opis )

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "nalog-> " + idvn + "-" + brnal

      SKIP
   ENDDO

   BoxC()

   open_exported_xlsx()

   RETURN .T.


// ---------------------------------------------
// vraca definiciju polja tabele exporta
// ---------------------------------------------
STATIC FUNCTION get_exp_fields()

   LOCAL aDBF := {}

   AAdd( aDBF, { "IDVN", "C", 2, 0 } )
   AAdd( aDBF, { "BRNAL", "C", 4, 0 } )
   AAdd( aDBF, { "RBR", "C", 4, 0 } )
   AAdd( aDBF, { "IDKONTO", "C", 7, 0 } )
   AAdd( aDBF, { "IDPARTN", "C", 6, 0 } )
   AAdd( aDBF, { "NAZPART", "C", 40, 0 } )
   AAdd( aDBF, { "DUG", "N", 18, 8 } )
   AAdd( aDBF, { "POT", "N", 18, 8 } )
   AAdd( aDBF, { "DATUM", "D", 8, 0 } )
   AAdd( aDBF, { "DATVAL", "D", 8, 0 } )
   AAdd( aDBF, { "VEZA", "C", 10, 0 } )
   AAdd( aDBF, { "OPIS",  "C", 40, 0 } )

   RETURN aDBF



// ----------------------------------------------------------------
// napuni tabelu exporta
// ----------------------------------------------------------------
STATIC FUNCTION fill_export( cIdF, cIdVn, cBrNal, cRbr, cIdKto, ;
      cIdPart, cPartNaz, cD_P, nIznos, dDatum, ;
      dValuta, cVeza, cOpis )

   LOCAL nArr := Select()

   o_r_export()

   APPEND BLANK
   REPLACE idvn WITH cIdVn
   REPLACE brnal WITH cBrNal
   REPLACE rbr WITH cRbr
   REPLACE idkonto WITH cIdKto
   REPLACE idpartn WITH cIdPart
   REPLACE nazpart WITH cPartNaz

   IF cD_P == "1"
      REPLACE dug WITH nIznos
      REPLACE pot WITH 0
   ELSE
      REPLACE dug WITH 0
      REPLACE pot WITH nIznos
   ENDIF

   REPLACE datum WITH dDatum
   REPLACE datval WITH dValuta
   REPLACE veza WITH cVeza
   REPLACE opis WITH cOpis


   SELECT ( nArr )

   RETURN

*/
