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

FUNCTION m_rpt()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. lista naloga otvorenih na tekući dan          " )
   AAdd( _opcexe, {|| lst_tek_dan() } )

   AAdd( _opc, "2. nalozi prispjeli za realizaciju " )
   AAdd( _opcexe, {|| lst_real_tek_dan() } )

   AAdd( _opc, "3. nalozi van roka na tekuci dan " )
   AAdd( _opcexe, {|| lst_vrok_tek_dan() } )

   AAdd( _opc, "4. lista naloga >= od proizvoljnog datuma " )
   AAdd( _opcexe, {|| lst_ch_date() } )

   AAdd( _opc, "------------------------------------------- " )
   AAdd( _opcexe, {|| nil } )

   AAdd( _opc, "S. specifikacija naloga za poslovođe  " )
   AAdd( _opcexe, {|| rnal_specifikacija_poslovodja( 1 ) } )

   AAdd( _opc, "R. pregled utroška RAL sirovina  " )
   AAdd( _opcexe, {|| rpt_ral_calc() } )

   AAdd( _opc, "O. pregled učinka operatera  " )
   AAdd( _opcexe, {|| r_op_docs() } )

   AAdd( _opc, "P. pregled učinka proizvodnje  " )
   AAdd( _opcexe, {|| m_get_rpro() } )

   AAdd( _opc, "------------------------------------------- " )
   AAdd( _opcexe, {|| nil } )

   AAdd( _opc, "K. kontrola prebačenih dokumenata  " )
   AAdd( _opcexe, {|| m_rpt_check() } )
   AAdd( _opc, "L. popuni veze RNAL <> FAKT (dok.11) " )
   AAdd( _opcexe, {|| chk_dok_11() } )

   AAdd( _opc, "------------------------------------------- " )
   AAdd( _opcexe, {|| nil } )

   AAdd( _opc, "Y. send email " )
   AAdd( _opcexe, {|| f18_email_test() } )

   f18_menu( "rpt_rnal", .F., _izbor, _opc, _opcexe )

   RETURN
