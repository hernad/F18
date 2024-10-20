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


CLASS TLdMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS

METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self


METHOD programski_modul_osnovni_meni

   LOCAL nIzbor := 1
   LOCAL aOpcije := {}
   LOCAL aOpcijeB := {}

   AAdd( aOpcije, "1. obračun (unos, ispravka, administracija)          " )
   AAdd( aOpcijeB, {|| ld_obracun() } )
   AAdd( aOpcije, "2. unos datuma isplate plaća" )
   AAdd( aOpcijeB, {|| unos_datuma_isplate_place() } )
   AAdd( aOpcije, "3. postavke obračuna (rj/mjesec/godina)" )
   AAdd( aOpcijeB, {|| ld_postavi_parametre_obracuna() } )

   AAdd( aOpcije, "------------------------------------" )
   AAdd( aOpcijeB, NIL )

   AAdd( aOpcije, "I. izvještaji" )
   AAdd( aOpcijeB, {|| ld_izvjestaji() } )

   AAdd( aOpcije, "A. rekapitulacija obračuna" )
   AAdd( aOpcijeB, {|| ld_rekapitulacija_sql( .T. ) } )
   AAdd( aOpcije, "B. kartica plate" )
   AAdd( aOpcijeB, {|| ld_kartica_plate() } )

   AAdd( aOpcije, "M. mjesečni obrazac MIP-1023" )
   AAdd( aOpcijeB, {|| ld_mip_obrazac_1023() } )

   AAdd( aOpcije, "P. specifikacija uz isplatu plata obrazac 2001" )
   AAdd( aOpcijeB, {|| ld_specifikacija_plate_obr_2001() } )

   AAdd( aOpcije, "------------------------------------" )
   AAdd( aOpcijeB, NIL )
   AAdd( aOpcije, "K. krediti" )
   AAdd( aOpcijeB, {|| ld_krediti_menu() } )

   AAdd( aOpcije, "T. export podataka" )
   AAdd( aOpcijeB, {|| ld_export() } )

   AAdd( aOpcije, "V. generisanje virmana " )
   AAdd( aOpcijeB, {|| ld_gen_virm() } )

   AAdd( aOpcije, "------------------------------------" )
   AAdd( aOpcijeB, NIL )
   AAdd( aOpcije, "S. šifarnici plate" )
   AAdd( aOpcijeB, {|| ld_sifarnici() } )

   AAdd( aOpcije, "X. parametri aplikacije" )
   AAdd( aOpcijeB, {|| ld_parametri() } )

   f18_menu( "gld", .T., nIzbor, aOpcije, aOpcijeB )

   RETURN .T.



METHOD mMenu()

   PRIVATE Izbor

   Izbor := 1

   my_close_all_dbf()

   ld_postavi_parametre_obracuna()

   ::programski_modul_osnovni_meni()

   RETURN NIL


METHOD set_module_gvars()

   PUBLIC cFormula := ""
   PUBLIC gLDRadnaJedinica := "10"
   PUBLIC gnHelpObr := 0

   PUBLIC gObracun := "1"

   // varijanta obracuna u skladu sa zak.promjenama
   PUBLIC gVarObracun := "2"
   PUBLIC gOsnLOdb := 300
   PUBLIC gRadnFilter := "D"
   PUBLIC gUgTrosk := 20
   PUBLIC gAhTrosk := 30
   PUBLIC gIzdanje := Space( 10 )
   PUBLIC gGodina := Year( Date() )
   PUBLIC gMjesec := 1

   PUBLIC gZaok := 2
   PUBLIC gZaok2 := 2
   PUBLIC gValuta := "KM "
   PUBLIC gPicI := "99999999.99"
   PUBLIC gPicS := "99999999"
   PUBLIC gTipObr := "1"
   PUBLIC gcLdSpec2001GrupePoslovaAutoRucno // automatski
   PUBLIC cVarPorOl := "1"
   PUBLIC gSihtarica := "N"
   PUBLIC gSihtGroup := "N"
   PUBLIC gFUPrim := PadR( "UNETO+I24+I25", 50 )
   PUBLIC gBFForm := PadR( "", 100 )
   PUBLIC gFURaz := PadR( "", 60 )
   PUBLIC gFUSati := PadR( "USATI", 50 )
   PUBLIC gFURSati := PadR( "", 50 )
   PUBLIC gFUGod := PadR( "I06", 40 )
   //PUBLIC gUNMjesec := "N"
   PUBLIC gMRM := 0.6
   PUBLIC gMRZ := 0.6
   PUBLIC gPDLimit := 0
   PUBLIC gSetForm := "1"
   PUBLIC gPrBruto := "D"
   PUBLIC gMinR := "%"
   PUBLIC gPotp := "D"
   PUBLIC gBodK := "1"
   PUBLIC gDaPorol := "N" // pri obracunu uzeti u obzir poreske olaksice
   PUBLIC gFSpec := PadR( "SPEC.TXT", 12 )
   PUBLIC gReKrOs := "X"
   PUBLIC gReKrKP := "2"
   PUBLIC gVarPP := "1"
   PUBLIC gKarSDop := "N"
   PUBLIC gPotpRpt := "N"
   PUBLIC gPotp1 := PadR( "PADL('Potpis:',70)", 150 )
   PUBLIC gPotp2 := PadR( "PADL('_________________',70)", 150 )
   PUBLIC _LK_ := 6

   PUBLIC lVOBrisiCDX := .F.
   PUBLIC cLdPolja := 40

   ld_get_params()

   LDPoljaINI()

   RETURN .T.


FUNCTION  ld_vise_obracuna()

   RETURN fetch_metric( "ld_vise_obracuna", NIL, .T. )


FUNCTION ld_tekuca_godina( nSet )

   IF nSet != NIL
      gGodina := nSet
   ENDIF

   RETURN gGodina


FUNCTION ld_tekuci_mjesec( nSet )

   IF nSet != NIL
      gMjesec := nSet
   ENDIF

   RETURN gMjesec


FUNCTION ld_broj_obracuna()

   PRIVATE cOznObracuna

   IF ld_vise_obracuna()
      cOznObracuna := gObracun
   ELSE
      cOznObracuna := ""
   ENDIF

   RETURN cOznObracuna
