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

CLASS TOsMod FROM TAppMod

   METHOD NEW
   METHOD set_module_gvars
   METHOD mMenu
   METHOD programski_modul_osnovni_meni

ENDCLASS



METHOD new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   ::super:new( p1, p2, p3, p4, p5, p6, p7, p8, p9 )

   RETURN self



METHOD mMenu()

   LOCAL _tmp

   _tmp := fetch_metric( "os_set_epoch", NIL, 0 )
   // nPom := VAL( my_get_from_ini( "SET", "Epoch", "1945", KUMPATH ) )

   IF _tmp > 0
      SET EPOCH TO ( _tmp )
   ENDIF

   PUBLIC gCentOn := fetch_metric( "os_set_century_on", NIL, "N" )
   // my_get_from_ini( "SET", "CenturyOn", "N", KUMPATH )

   IF gCentOn == "D"
      SET CENTURY ON
   ELSE
      SET CENTURY OFF
   ENDIF

   os_set_datum_obrade()
   set_os_info()


   ::programski_modul_osnovni_meni()

   RETURN NIL



METHOD programski_modul_osnovni_meni

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. unos promjena na postojećem sredstvu               " )
   AAdd( _opcexe, {|| unos_osnovnih_sredstava() } )
   AAdd( _opc, "2. obračuni" )
   AAdd( _opcexe, {|| os_obracuni() } )
   AAdd( _opc, "3. izvještaji" )
   AAdd( _opcexe, {|| os_izvjestaji() } )
   AAdd( _opc, "----------------------------------------------- ------" )
   AAdd( _opcexe, {|| nil } )
   AAdd( _opc, "5. šifarnici" )
   AAdd( _opcexe, {|| os_sifarnici() } )
   AAdd( _opc, "6. parametri" )
   AAdd( _opcexe, {|| os_parametri() } )
   AAdd( _opc, "------------------------------------------------------" )
   AAdd( _opcexe, {|| nil } )
   AAdd( _opc, "8. prenos početnog stanja " )
   AAdd( _opcexe, {|| os_generacija_pocetnog_stanja() } )

   f18_menu( "gos", .F., _izbor, _opc, _opcexe )

   RETURN .T.


METHOD set_module_gvars()

   os_datum_obracuna( Date() )
   PUBLIC gOSRj := "00"
   PUBLIC gValuta := "KM "
   PUBLIC gPicI := "99999999.99"

   PUBLIC gVObracun := "2"
   //PUBLIC gIBJ := "D"
   PUBLIC gDrugaVal := "N"
   PUBLIC gVarDio := "N"
   PUBLIC gDatDio := CToD( "01.01.1999" )
   PUBLIC gMetodObr := "1"
   PUBLIC gOsSii := "O"


   gOSRj := fetch_metric( "os_radna_jedinica", nil, gOSRj )
   gOsSii := fetch_metric( "os_sii_modul", my_user(), gOsSii )
   os_datum_obracuna( fetch_metric( "os_datum_obrade", my_user(), Date() ) )
   gPicI := fetch_metric( "os_prikaz_iznosa", nil, gPicI )
   gMetodObr := fetch_metric( "os_metoda_obracuna", nil, gMetodObr )
   //gIBJ := fetch_metric( "os_id_broj_je_unikatan", nil, gIBJ )
   gDrugaVal := fetch_metric( "os_prikaz_u_dvije_valute", nil, gDrugaVal )
   gVObracun := fetch_metric( "os_varijanta_obracuna", nil, gVObracun )
   gVarDio := fetch_metric( "os_pocetak_obracuna", nil, gVarDio )
   gDatDio := fetch_metric( "os_pocetak_obracuna_datum", nil, gDatDio )

   RETURN .T.
