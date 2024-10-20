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


FUNCTION p_refer( cId, dx, dy )

   LOCAL xRet, hWorArea
   LOCAL _ret, nI

   PRIVATE ImeKol
   PRIVATE Kol

   hWorkArea := PushWA()

   IF !hWorkArea[ 'sql' ] .AND. F18_SQL_ENCODING == "UTF8" .AND. cId != NIL

      cId := hb_StrToUTF8( cId ) // ako je SQL tabela i SQL encoding UTF8 onda je cId UTF8 string
   ENDIF


   o_refer()

   ImeKol := {}
   Kol := {}

   AAdd( ImeKol, { PadR( "Id", 2 ), {|| id }, "id", {|| .T. }, {|| valid_sifarnik_id_postoji( wid ) } } )
   AAdd( ImeKol, { PadR( "idops", 5 ), {|| idops }, "idops", {|| .T. }, {|| p_ops( widops ) } } )
   AAdd( ImeKol, { PadR( "Naziv", 40 ), {|| naz }, "naz" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   xRet := p_sifra( F_REFER, 1, f18_max_rows() - 15, 60, "Lista referenata", @cId, dx, dy )

   hWorkArea := PopWA()

   IF !hWorkArea[ 'sql' ] .AND. F18_SQL_ENCODING == "UTF8"
      cId := hb_UTF8ToStr( cId ) // F18_SQL_ENCODING UTF8
   ENDIF

   RETURN xRet



// ------------------------------------------------
// vraca naziv referenta iz tabele REFER
// ------------------------------------------------
FUNCTION g_refer( cReferId )

   LOCAL cNaz := ""
   LOCAL nTarea := Select()

   o_refer()
   SEEK cReferId
   IF Found() .AND. refer->id == cReferId
      cNaz := AllTrim( refer->naz )
   ENDIF
   SELECT ( nTarea )

   RETURN cNaz
