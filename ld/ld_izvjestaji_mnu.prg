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


FUNCTION ld_izvjestaji()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. kartice                                           " )
   AAdd( aOpcExe, {|| izvjestaji_kartice() } )
   AAdd( aOpc, "2. rekapitulacije" )
   AAdd( aOpcExe, {|| izvjestaji_rekapitulacije() } )
   AAdd( aOpc, "3. pregledi" )
   AAdd( aOpcExe, {|| ld_izvjestaji_pregledi() } )
   AAdd( aOpc, "4. specifikacije" )
   AAdd( aOpcExe, {|| izvjestaji_specifikacije() } )
   AAdd( aOpc, "5. ostali izvještaji" )
   AAdd( aOpcExe, {|| izvjestaji_ostali() } )
   AAdd( aOpc, "6. obrasci (MIP/GIP/OLP)" )
   AAdd( aOpcExe, {|| izvjestaji_obrasci() } )

   f18_menu( "izvj", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.


STATIC FUNCTION izvjestaji_kartice()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _Izbor := 1

   AAdd( aOpc, "1. kartica plate                  " )
   AAdd( aOpcExe, {|| ld_kartica_plate() } )
   AAdd( aOpc, "2. kartica plate za više mjeseci" )
   AAdd( aOpcExe, {|| ld_kartica_plate_za_vise_mjeseci() } )

   f18_menu( "krt", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION izvjestaji_obrasci()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _Izbor := 1

   AAdd( aOpc, "1. mjesečni obrazac MIP-1023                  " )
   AAdd( aOpcExe, {|| ld_mip_obrazac_1023() } )

   AAdd( aOpc, "2. obračunski listovi (obrasci OLP i GIP)" )
   AAdd( aOpcExe, {|| ld_olp_gip_obrazac() } )

   AAdd( aOpc, "3. akontacije poreza (obrasci ASD i AUG)" )
   AAdd( aOpcExe, {|| ld_asd_aug_obrazac() } )

   AAdd( aOpc, "4. prijave doprinosa (JS-3400)" )
   AAdd( aOpcExe, {|| ld_js3400_obrazac() } )

   f18_menu( "obr", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION izvjestaji_specifikacije()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. specifikacija uz isplatu plata 2001                            " )
   AAdd( aOpcExe, {|| ld_specifikacija_plate_obr_2001() } )

   AAdd( aOpc, "X. specifikacija uz isplatu plata 2001 (stari) " )
   AAdd( aOpcExe, {|| ld_specifikacija_plate_2001_stari() } )

   AAdd( aOpc, "2. specifikacija za samostalne poduzetnike obrazac 2002  " )
   AAdd( aOpcExe, {|| ld_specifikacija_plate_samostalni_obr_2002() } )

   AAdd( aOpc, "3. specifikacija ostale samostalne djelatnosti" )
   AAdd( aOpcExe, {|| ld_specifikacija_plate_ostali() } )
   AAdd( aOpc, "4. specifikacija primanja po mjesecima" )
   AAdd( aOpcExe, {|| ld_specifikacija_po_mjesecima() } )
   AAdd( aOpc, "5. specifikacija primanja po RJ" )
   AAdd( aOpcExe, {|| ld_specifikacija_po_rj() } )
   AAdd( aOpc, "6. specifikacija po rasponima primanja" )
   AAdd( aOpcExe, {|| ld_specifikacija_po_rasponima_primanja() } )
   AAdd( aOpc, "7. specifikacija neto primanja radnika po općinama stanovanja " )
   AAdd( aOpcExe, {|| ld_specifikacija_neto_primanja_po_opcinama() } )


   f18_menu( "spec", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION ld_izvjestaji_pregledi()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. pregled plata                                  " )
   AAdd( aOpcExe, {|| ld_pregled_plata() } )
   AAdd( aOpc, "2. pregled plata za više mjeseci  " )
   AAdd( aOpcExe, {|| ld_pregled_plata_za_period() } )
   AAdd( aOpc, "3. pregled određenog primanja" )
   AAdd( aOpcExe, {|| ld_pregled_odredjenog_primanja() } )
   AAdd( aOpc, "4. pregled primanja za period" )
   AAdd( aOpcExe, {|| ld_pregled_primanja_za_period() } )
   AAdd( aOpc, "5. platni spisak" )
   AAdd( aOpcExe, {|| ld_platni_spisak() } )
   AAdd( aOpc, "6. platni spisak tekući račun" )
   AAdd( aOpcExe, {|| ld_platni_spisak_tekuci_racun( "1" ) } )
   AAdd( aOpc, "8. isplata jednog tipa primanja na tekući račun" )
   AAdd( aOpcExe, {|| ld_pregled_isplate_za_tekuci_racun( "1" ) } )

   f18_menu( "preg", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION izvjestaji_ostali()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. pregled utroška po šihtaricama                        " )
   AAdd( aOpcExe, {|| ld_utrosak_po_sihtaricama() } )
   AAdd( aOpc, "2. lista radnika za isplatu toplog obroka" )
   AAdd( aOpcExe, {|| ld_lista_isplate_toplog_obroka() } )

   f18_menu( "ost", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.


STATIC FUNCTION izvjestaji_rekapitulacije()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. rekapitulacija plate za radnu jedinicu   " )
   AAdd( aOpcExe, {|| ld_rekapitulacija_sql( .F. ) } )
   AAdd( aOpc, "2. rekapitulacija za sve radne jedinice" )
   AAdd( aOpcExe, {|| ld_rekapitulacija_sql( .T. ) } )


   f18_menu( "rekap", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.
