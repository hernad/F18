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


FUNCTION ld_obracun()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. unos                              " )
   AAdd( _opcexe, {|| ld_unos_obracuna() } )
   AAdd( _opc, "2. administracija obračuna           " )
   AAdd( _opcexe, {|| ld_obracun_mnu_admin() } )

   f18_menu( "obr", .F., _izbor, _opc, _opcexe )

   RETURN .T.


FUNCTION ld_obracun_mnu_admin()

   LOCAL _radni_sati := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. brisanje obračuna                                            " )
   AAdd( _opcexe, {|| ld_brisanje_obr() } )


   AAdd( _opc, "3. radnici obrađeni više puta za isti mjesec" )
   AAdd( _opcexe, {|| ld_obracun_napravljen_vise_puta() } )

   IF gSihtGroup == "D"
      AAdd( _opc, "S. obrada šihtarica" )
      AAdd( _opcexe, {|| siht_obr() } )
   ENDIF

   IF _radni_sati == "D"
      AAdd( _opc, "R. pregled/ispravka radnih sati radnika" )
      AAdd( _opcexe, {|| edRadniSati() } )
   ENDIF


   AAdd( _opc, "X. rekalkulacija nakon promjene vrijednosti boda" )
   AAdd( _opcexe, {|| ld_rekalkulacija_primanja() } ) 

   f18_menu( "ao", .F., _izbor, _opc, _opcexe )

   RETURN .T.


STATIC FUNCTION siht_obr()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. unos/ispravka                " )
   AAdd( _opcexe, {|| def_siht() } )
   AAdd( _opc, "2. pregled unesenih sihtarica" )
   AAdd( _opcexe, {|| get_siht() } )
   AAdd( _opc, "3. pregled ukupnih sati po siht." )
   AAdd( _opcexe, {|| get_siht2() } )
   AAdd( _opc, "4. brisanje sihtarice " )
   AAdd( _opcexe, {|| del_siht() } )

   f18_menu( "sobr", .F., _izbor, _opc, _opcexe )

   RETURN
