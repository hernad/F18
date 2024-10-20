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


FUNCTION P_Ops( cId, dx, dy )

   LOCAL nI, hWorkArea, xRet
   PRIVATE ImeKol
   PRIVATE Kol


   hWorkArea := PushWA()

   IF !hWorkArea[ 'sql' ] .AND. F18_SQL_ENCODING == "UTF8" .AND. cId != NIL
      cId := hb_StrToUTF8( cId ) // ako je SQL tabela onda je cId UTF8 string, SAMO ako je F18_SQL_ENCODING UTF8
   ENDIF

   o_ops()

   ImeKol := {}
   Kol := {}

   AAdd( ImeKol, { PadR( "Id", 4 ),  {|| Padr( field->id, 4 ) }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wid ) } } )
   AAdd( ImeKol, { PadR( "IDJ", 3 ), {|| field->idj }, "idj" } )
   AAdd( ImeKol, { PadR( "Kan", 3 ), {|| field->idkan }, "idkan" } )
   AAdd( ImeKol, { PadR( "N0", 3 ),  {|| field->idN0 }, "idN0" } )
   AAdd( ImeKol, { PadR( "Naziv", 25 ), {|| PadR( field->naz , 25 ) }, "naz" } )
   AAdd( ImeKol, { PadR( "Reg", 3 ), {|| field->reg }, "reg" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   xRet := p_sifra( F_OPS, 1, f18_max_rows() - 15, f18_max_cols() - 10, "MP: Lista općina", @cId, dx, dy )

   hWorkArea := PopWA()

   IF !hWorkArea[ 'sql' ] .AND. F18_SQL_ENCODING == "UTF8"
      cId := hb_UTF8ToStr( cId )   // ako smo na pocetku uradili konverziju moramo napraviti novu obrnutu konverziju
   ENDIF

   RETURN xRet



FUNCTION P_Banke( cId, dx, dy )

   LOCAL _arr, nI
   PRIVATE ImeKol
   PRIVATE Kol

   _arr := Select()
   o_banke()

   ImeKol := {}
   AAdd( ImeKol, { PadR( "Id", 2 ), {|| id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wId ) } } )
   AAdd( ImeKol, { PadR( "Naziv", 35 ), {|| PadR( ToStrU( naz ), 35 ) }, "naz" } )
   AAdd( ImeKol, { "Mjesto", {|| mjesto }, "mjesto" } )
   AAdd( ImeKol, { "Adresa", {|| adresa }, "adresa" } )

   Kol := {}
   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   SELECT ( _arr )

   RETURN p_sifra( F_BANKE, 1, f18_max_rows() -15, f18_max_cols() -10, "MatPod: Lista banaka", @cId, dx, dy )
