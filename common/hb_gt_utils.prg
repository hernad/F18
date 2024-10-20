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

FUNCTION f18_gt()

#ifdef __PLATFORM__WINDOWS
#ifdef GT_DEFAULT_CONSOLE
      RETURN "WIN"
#endif
    
    RETURN "WVT"

#else

#ifdef GT_DEFAULT_CONSOLE
   RETURN "TRM"
#else

    RETURN "XWC"
#endif





/*
#ifdef __PLATFORM__WINDOWS

#ifdef GT_DEFAULT_CONSOLE
   RETURN "NUL"

#else

   RETURN "NUL"
#endif

#else

#ifdef GT_DEFAULT_CONSOLE

   RETURN "NUL"
#else

#ifdef GT_DEFAULT_QT

   RETURN "NUL"
#else

   RETURN "NUL"
#endif

#endif
*/
