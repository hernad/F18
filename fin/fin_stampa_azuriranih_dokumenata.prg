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


#include "f18.ch"



FUNCTION fin_stampa_azur_naloga_menu()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AADD( _opc, "1. subanalitika                 ")
   AADD( _opcexe, {|| fin_nalog_suban_stampa_azurirani_dokument() } )
   AADD( _opc, "2. sintetika  ")
   AADD( _opcexe, {|| fin_sinteticki_nalog_stampa() } )

   f18_menu( "fst", .f., _izbor, _opc, _opcexe  )

   RETURN .T.
