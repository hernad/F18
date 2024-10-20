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



FUNCTION fin_menu_specifikacije()

   LOCAL _izbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   AAdd( aOpc, "1. finansijske specifikacije        " )
   AAdd( aOpcExe, {|| fin_specifikacije_meni() } )

   AAdd( aOpc, "2. kupci" )
   AAdd( aOpcExe, {|| fin_specif_kupci() } )

   f18_menu( "spec", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION fin_specif_kupci()

   LOCAL _izbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}

   AAdd( aOpc, "1. kupci pregled dugovanja                                  " )
   AAdd( aOpcExe, {|| fin_kupci_pregled_dugovanja() } )

   AAdd( aOpc, "2. partnera na kontu" )
   AAdd( aOpcExe, {|| fin_spec_partnera_na_kontu() } )
   AAdd( aOpc, "3. otvorene stavke preko-do odredjenog broja dana za konto" )
   AAdd( aOpcExe, {|| fin_spec_otv_stavke_preko_dana() } )


   AAdd( aOpc, "4. konta za partnera" )
   AAdd( aOpcExe, {|| fin_specifikacija_konta_za_partnera() } )
   AAdd( aOpc, "5. pregled novih dugovanja/potraživanja" )
   AAdd( aOpcExe, {|| PregNDP() } )
   AAdd( aOpc, "6. pregled partnera bez prometa" )
   AAdd( aOpcExe, {|| PartVanProm() } )

   f18_menu( "fsp2", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.




STATIC FUNCTION fin_specifikacije_meni()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1


   AAdd( aOpc, "1. specifkacija po subanalitičkim kontima                " )
   AAdd( aOpcExe, {|| fin_specifikacija_suban() } )

   AAdd( aOpc, "2. specifikacija po subanalitičkim kontima / sql" )
   AAdd( aOpcExe, {|| fin_suban_specifikacija_sql() } )


   AAdd( aOpc, "3. prebijeno stanje konto/konto2" )
   AAdd( aOpcExe, {|| fin_spec_prebijeno_konto_konto2() } )


   AAdd( aOpc, "A. po analitičkim kontima" )
   AAdd( aOpcExe, {|| specifikacija_po_analitickim_kontima() } )


   AAdd( aOpc, "P. subanalitička specifikacija proizvoljno sortiranje" )
   AAdd( aOpcExe, {|| fin_specif_suban_proizv_sort() } )

   //IF gFinRj == "D" .OR. gFinFunkFond == "D"
      // AAdd( aOpc, "A. izvrsenje budzeta/pregled rashoda" )
      // AAdd( aOpcExe, {|| IzvrsBudz() } )

      // AAdd( aOpc, "B. pregled prihoda" )
      // AAdd( aOpcExe, {|| Prihodi() } )
   //ENDIF


   //AAdd( aOpc, "S. specifikacija troskova po gradilištima " )
   //AAdd( aOpcExe, {|| r_spec_tr() } )

   f18_menu( "spfin", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.
