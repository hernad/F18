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

FUNCTION is_key_alt_a( nCh )

   RETURN ( nCh == K_ALT_A ) .OR. ( is_mac_osx() .AND. Chr( nCh ) == 'A' )


FUNCTION is_key_alt_p( nCh )

   RETURN ( nCh == K_ALT_P ) .OR. ( is_mac_osx() .AND. Chr( nCh ) == 'P' )


FUNCTION is_key_alt_x( nCh )

  RETURN ( nCh == K_ALT_X ) .OR. ( is_mac_osx() .AND. Chr( nCh ) == 'X' )
