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

PROCEDURE thread_create_dbfs()

   LOCAL _ver

#ifdef F18_DEBUG_SYNC

   ?E "SSSSTART thread create dbfs"
#endif
   DO WHILE !open_thread( "create_dbfs" )
      ?E "ERRO open_thread create_dbfs"
   ENDDO

   ErrorBlock( {| objError, lShowreport, lQuit | GlobalErrorHandler( objError, lShowReport, lQuit ) } )

   _ver := read_dbf_version_from_config()

   IF !cre_all_dbfs( _ver )
      ?E "ERROR cre_all_dbfs thread_create_dbfs !"
      RETURN
   ENDIF

   kreiraj_pa_napuni_partn_idbr_pdvb() // upgrade SIFK PARTN REGB -> IDBR, PDVB

   // idle_add_for_eval( "kreiraj_pa_napuni_partn_idbr_pdvb", {||  kreiraj_pa_napuni_partn_idbr_pdvb () } )

   set_a_dbfs_key_fields() // inicijaliziraj "dbf_key_fields" u __f18_dbf hash matrici
   write_dbf_version_to_ini_conf()
   f18_log_delete() // brisanje loga nakon logiranja...

   close_thread( "create_dbfs" )

#ifdef F18_DEBUG_SYNC
   ?E "EEEEND thread create dbfs"
#endif

   RETURN
