
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

FUNCTION dbf_init( aDbf, cTableName, cAlias )

   LOCAL hRec

   insert_semaphore_if_not_exists( cTableName, .T. )

   IF !File( f18_ime_dbf( cAlias ) )
      DBCREATE2( cAlias, aDbf )
      reset_semaphore_version( cTableName )
      set_dbf_fields_from_struct( cTableName )
   ENDIF

   RETURN .T.
