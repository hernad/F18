/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/* \file fmk/fin/specif/ramaglas/rpt/1g/mnu_rpt.prg
 *     Meni izvjestaja za rama glas - "pogonsko knjigovodstvo"
 */

/* Izvjestaji()
 *     Glavni menij za izbor izvjestaja
 *   param:
 */

FUNCTION IzvjPogonK()

   PRIVATE Izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   AAdd( opc, "1. specifikacija troskova po radnim nalozima" )
   AAdd( opcexe, {|| SpecTrosRN() } )

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "izPK" )

   RETURN .F.
