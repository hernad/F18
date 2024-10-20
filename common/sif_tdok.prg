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


MEMVAR ImeKol, Kol
MEMVAR wId

FUNCTION browse_tdok( cId, nDeltaX, nDeltaY )

   LOCAL nI, xRet
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   PushWA()
   o_tdok()

   AAdd( ImeKol, { "ID",    {|| PadR( field->id, 2 ) },  "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { "Naziv", {|| PadR(  field->naz, 35 ) }, "naz" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   xRet := p_sifra( F_TDOK, 1, Max( f18_max_rows() - 20, 10 ), Max( f18_max_cols() - 30, 35 ), "OsnPod: Vrste dokumenata", @cId, nDeltaX, nDeltaY )

   PopWa()

   RETURN xRet


FUNCTION P_TipDok( cId, nDeltaX, nDeltaY )

   RETURN browse_tdok( @cId, nDeltaX, nDeltaY )
