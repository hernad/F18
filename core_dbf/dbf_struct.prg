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

/*  skrati matricu za polje D
*/
FUNCTION SkratiAZaD( struct )

   LOCAL nI, _len

   _len := Len( struct )

   FOR nI := 1 TO _len
      // sistemska polja
      IF ( "#" + STRUCT[ nI, 1 ] + "#" $ "#BRISANO#_SITE_#_OID_#_USER_#_COMMIT_#_DATAZ_#_TIMEAZ_#" )
         ADel ( struct, nI )
         _len--
         nI := nI - 1
      ENDIF
   NEXT

   ASize( struct, _len )

   RETURN NIL
