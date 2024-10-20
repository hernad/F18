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


#ifdef __PLATFORM__LINUX

FUNCTION is_linux()

   RETURN .T.

FUNCTION is_windows()

   RETURN .F.

FUNCTION is_mac()

   RETURN .F.
#endif


#ifdef __PLATFORM__DARWIN

FUNCTION is_linux()

   RETURN .F.

FUNCTION is_windows()

   RETURN .F.

FUNCTION is_mac()

   RETURN .T.

#endif



#ifdef __PLATFORM__WINDOWS


FUNCTION is_windows()

   RETURN .T.

FUNCTION is_mac()

   RETURN .F.

FUNCTION is_linux()

   RETURN .F.

#endif




#ifdef GT_DEFAULT_CONSOLE
FUNCTION is_terminal()
   RETURN .T.

#else
FUNCTION is_terminal()
   RETURN .F.
#endif
