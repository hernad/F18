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



FUNCTION os_izvjestaji()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   cTip := IF( gDrugaVal == "D", valuta_domaca_skraceni_naziv(), "" )
   cBBV := cTip
   nBBK := 1

   AAdd( _opc, "1. pregled sredstava za rj                          " )
   AAdd( _opcexe, {|| os_pregled_po_rj() } )
   AAdd( _opc, "2. pregled sredstava po kontima" )
   AAdd( _opcexe, {|| os_pregled_po_kontima() } )
   AAdd( _opc, "3. amortizacija po kontima" )
   AAdd( _opcexe, {|| os_pregled_amortizacije() } )
   AAdd( _opc, "4. revalorizacija po kontima" )
   AAdd( _opcexe, {|| os_pregled_revalorizacije() } )
   AAdd( _opc, "5. rekapitulacija količina po grupacijama - k1" )
   AAdd( _opcexe, {|| os_rekapitulacija_po_k1() } )
   AAdd( _opc, "6. amortizacija po grupama amortizacionih stopa" )
   AAdd( _opcexe, {|| os_amortizacija_po_stopama() } )
   AAdd( _opc, "7. amortizacija po kontima i po grupama amort.stopa" )
   AAdd( _opcexe, {|| os_amortizacija_po_kontima() } )

   AAdd( _opc, "8. popisna lista" )
   AAdd( _opcexe, {|| os_popisna_lista() } )

   f18_menu( "izv", .F., _izbor, _opc, _opcexe )

   RETURN .T.
