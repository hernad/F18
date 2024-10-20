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


FUNCTION kalk_izvjestaji_magacina()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. kartica - magacin                                " )
   AAdd( _opcexe, {|| kalk_kartica_magacin() } )
   AAdd( _Opc, "2. lager lista - magacin" )
   AAdd( _opcexe, {|| kalk_lager_lista_magacin() } )
/*
   AAdd( _Opc, "3. lager lista - proizvoljni sort" )
   AAdd( _opcexe, {|| KaLagM() } )
*/

   AAdd( _Opc, "4. finansijsko stanje magacina" )
   AAdd( _opcexe, {|| finansijsko_stanje_magacin() } )
   AAdd( _Opc, "5. realizacija po partnerima" )
   AAdd( _opcexe, {|| kalk_real_partnera() } )

/*
   AAdd( _Opc, "6. promet grupe partnera" )
   AAdd( _opcexe, {|| kalk_mag_promet_grupe_partnera() } )
*/


   AAdd( _opc, "7. pregled robe za dobavljača" )
   AAdd( _opcexe, {|| kalk_magacin_pregled_robe_za_dobavljaca() } )

   AAdd( _Opc, "8. trgovačka knjiga na veliko" )
   AAdd( _opcexe, {|| kalk_tkv() } )

/*
   AAdd( _Opc, "P. porezi" )
   AAdd( _opcexe, {|| MPoreziMag() } )
  */

   // AAdd( _Opc, "K. kontrolni izvještaji" )
   // AAdd( _opcexe, {|| m_ctrl_rpt() } )

   AAdd( _opc, "R. rekapitulacija finansijskog stanja magacina" )
   AAdd( _opcexe, {|| rekap_finansijsko_stanje_magacin() } )

   // AAdd( _Opc, "T. lista trebovanja po sastavnicama" )
   // AAdd( _opcexe, {|| g_sast_list() } )

   // AAdd( _Opc, "U. specifikacija izlaza po sastavnicama" )
   // AAdd( _opcexe, {|| rpt_prspec() } )

   f18_menu( "imag", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .T.

/*
// ----------------------------------------------------
// kontrolni izvjestaji
// ----------------------------------------------------
FUNCTION m_ctrl_rpt()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _Opc, "1. kontrola sastavnica               " )
   AAdd( _opcexe, {|| r_ct_sast() } )

   f18_menu( "ctrl", .F., _izbor, _opc, _opcexe )

   RETURN .T.
*/

/*
FUNCTION MPoreziMag()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1


   //AAdd( _Opc, "3. rekapitulacija po tarifama" )
   //AAdd( _opcexe, {|| RekmagTar() } )

   f18_menu( "porm", .F., _izbor, _opc, _opcexe )

   my_close_all_dbf()

   RETURN .T.
*/
