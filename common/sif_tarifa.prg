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

MEMVAR cPolje

MEMVAR wId
MEMVAR ImeKol, Kol

FUNCTION P_Tarifa( cId, dx, dy )

   LOCAL i
   LOCAL lRet

   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   PushWA()
   IF cId != NIL .AND. !Empty( cId )
      select_o_tarifa( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_tarifa()
   ENDIF

   AAdd( ImeKol, { "ID", {|| tarifa->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) }  } )
   AAdd( ImeKol, { PadC( "Naziv", 35 ), {|| PadR( ToStrU( tarifa->naz ), 35 ) }, "naz" } )
   AAdd( ImeKol,  { "PDV ", {|| tarifa->pdv },  "pdv", NIL, NIL, NIL, "999.99" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( F_TARIFA, 1, f18_max_rows() - 15, f18_max_cols() - 25, "Tarifne grupe", @cid, dx, dy )

   PopWa()

   RETURN lRet
