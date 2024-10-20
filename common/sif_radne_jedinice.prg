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

MEMVAR gModul

FUNCTION P_RJ( cId, nDeltaX, nDeltaY )

   LOCAL nTArea, nI, lRet

   PRIVATE ImeKol, Kol

   ImeKol := {}
   Kol := {}

   nTArea := Select()

   IF gModul == "OS" .AND. ValType( cId ) == "C" // modul OS  - IdRj char(4)
      cId := PadR( cId, 7 )
   ENDIF

   PushWa()
   IF cId != NIL .AND. !Empty( cId )
      select_o_rj( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_rj()
   ENDIF


   AAdd( ImeKol, { PadR( "Id",  2 ),       {|| id },   "id",     {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadR( "Naziv", 35 ),    {|| PadR( naz, 35 ) },  "naz" } )
   AAdd( ImeKol, { PadR( "Tip cij.", 10 ), {|| tip },    "tip" } )
   AAdd( ImeKol, { PadR( "Konto", 10 ),    {|| konto },  "konto" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   SELECT ( nTArea )

   lRet := p_sifra( F_RJ, 1, f18_max_rows() - 15, f18_max_cols() - 30, "MatPod: Lista radnih jedinica", @cId, nDeltaX, nDeltaY )

   IF gModul == "OS" // modul OS  - IdRj char(4)
      cId := PadR( cId, 4 )
   ENDIF

   PopWA()

   RETURN lRet
