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


FUNCTION p_fin_vrsta_naloga( cId, dx, dy )

   LOCAL xRet

   PRIVATE ImeKol
   PRIVATE Kol


   ImeKol := {}
   Kol := {}

   PushWa()

   IF cId != NIL .AND. !Empty( cId )
      select_o_tnal( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_tnal()
   ENDIF

   //o_tnal()

   AAdd( ImeKol, { "ID", {|| field->id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { "Naziv", {|| PadR( field->naz , 30 ) }, "naz" } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT


   xRet := p_sifra( F_TNAL, 1, Max( f18_max_rows() - 20, 10 ), Max( f18_max_cols() - 30, 50 ), "OsnPod: Vrste naloga", @cId, dx, dy )

   PopWa()

   
   RETURN xRet



FUNCTION P_VN( cId, dx, dy )

   RETURN p_fin_vrsta_naloga( @cId, dx, dy )
