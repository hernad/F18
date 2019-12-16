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

#ifndef F18_REQUEST

REQUEST SDDPG, SQLMIX

REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_SL852
REQUEST HB_CODEPAGE_SLISO
REQUEST HB_CODEPAGE_SLWIN

#ifdef NTX_INDICES
  REQUEST DBFNTX
  REQUEST DBFFPT
#else
  REQUEST DBFCDX
  REQUEST DBFFPT
#endif

#ifdef __PLATFORM__WINDOWS

#ifdef GT_DEFAULT_CONSOLE
   REQUEST HB_GT_WIN_DEFAULT
#else
   //REQUEST HB_GT_NUL
   REQUEST HB_GT_WVT_DEFAULT
#endif

#else

#ifdef GT_DEFAULT_CONSOLE
   //REQUEST HB_GT_NUL
   REQUEST HB_GT_TRM_DEFAULT
#else

#ifdef GT_DEFAULT_QT
     //REQUEST HB_GT_NUL
     REQUEST HB_GT_QTC_DEFAULT
#else
     //REQUEST HB_GT_NUL
     REQUEST HB_GT_XWC_DEFAULT
#endif

#endif

#endif

#endif

#define F18_REQUEST
