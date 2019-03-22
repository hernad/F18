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


FUNCTION pos_main_menu_upravnik()

   LOCAL aOpc := {}
   LOCAL aOpcexe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. izvještaji                        " )
   AAdd( aOpcexe, {|| pos_izvjestaji() } )
   AAdd( aOpc, "L. lista ažuriranih dokumenata" )
   AAdd( aOpcexe, {|| pos_lista_azuriranih_dokumenata() } )
   AAdd( aOpc, "D. unos dokumenata" )
   AAdd( aOpcexe, {|| pos_menu_dokumenti() } )
   AAdd( aOpc, "R. robno-materijalno poslovanje" )
   AAdd( aOpcexe, {|| pos_menu_dokumenti() } )

   AAdd( aOpc, "--------------" )
   AAdd( aOpcexe, NIL )
   AAdd( aOpc, "S. šifarnici" )
   AAdd( aOpcexe, {|| pos_sifarnici() } )
   AAdd( aOpc, "W. administracija pos-a" )
   AAdd( aOpcexe, {|| pos_admin_menu() } )
   // AAdd( opc, "P. promjena seta cijena" )
   // AAdd( opcexe, {|| PromIDCijena() } )

   f18_menu( "posu", .F., nIzbor, aOpc, aOpcExe )

   closeret

FUNCTION pos_menu_dokumenti()

   LOCAL nIzbor
   LOCAL aOpc := {}
   LOCAL aOpcexe := {}

   nIzbor := 1

   AAdd( aOpc, "1. prijem u prodavnicu iz magacina [21->22]    " )
   AAdd( aOpcexe, {|| pos_21_to_22_unos() } )

   AAdd( aOpc, "2. ulaz u prodavnicu direktno od dobavljača" )
   AAdd( aOpcexe, {|| pos_zaduzenje( POS_IDVD_DOBAVLJAC_PRODAVNICA ) } )

   AAdd( aOpc, "3. zahtjev za sniženje dijela zalihe     " )
   AAdd( aOpcexe, {|| pos_zaduzenje( POS_IDVD_ZAHTJEV_SNIZENJE ) } )

   AAdd( aOpc, "4. zahtjev za nabavku - narudžbe    " )
   AAdd( aOpcexe, {|| pos_zaduzenje( POS_IDVD_ZAHTJEV_NABAVKA ) } )
   /*
   AAdd( aOpc, "I. inventura" )
   AAdd( aOpcexe, {|| pos_inventura_nivelacija( .T. ) } )
   AAdd( aOpc, "N. nivelacija" )
   AAdd( aOpcexe, {|| pos_inventura_nivelacija( .F. ) } )
   */

   f18_menu( "pos6", .F., nIzbor, aOpc, aOpcexe )

   RETURN .T.
