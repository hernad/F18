/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION rnal_mnu_admin()

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL izbor := 1

   AAdd( opc, "1. administracija db-a            " )
   AAdd( opcexe, {|| m_adm() } )

   f18_menu( "administracija", .F., izbor, opc, opcexe )

   RETURN .T.
