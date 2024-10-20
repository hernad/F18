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


FUNCTION ld_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   o_ld_sif_tables()

   AAdd( aOpc, "1. opći šifarnici                     " )
   AAdd( aOpcExe, {|| ld_opci_sifarnici() } )
   AAdd( aOpc, "2. ostali šifarnici" )
   AAdd( aOpcExe, {|| ld_specificni_sifarnici() } )

   f18_menu( "sif", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



FUNCTION ld_opci_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. radnici                            " )
   AAdd( aOpcExe, {|| P_Radn() } )
   AAdd( aOpc,  "5. radne jedinice" )
   AAdd( aOpcExe, {|| P_LD_RJ() } )
   AAdd( aOpc, "6. općine" )
   AAdd( aOpcExe, {|| P_Ops() } )
   AAdd( aOpc, "9. vrste posla" )
   AAdd( aOpcExe, {|| P_VPosla() } )
   AAdd( aOpc, "B. stručne spreme" )
   AAdd( aOpcExe, {|| P_StrSpr() } )
   AAdd( aOpc, "C. kreditori" )
   AAdd( aOpcExe, {|| P_Kred() } )
   AAdd( aOpc, "F. banke" )
   AAdd( aOpcExe, {|| P_Banke() } )
   AAdd( aOpc, "G. sifk" )
   AAdd( aOpcExe, {|| P_SifK() } )

   IF ( IsRamaGlas() )
      AAdd( aOpc,  "H. objekti"  )
      AAdd( aOpcExe, {|| P_fakt_objekti() } )
   ENDIF


   f18_menu( "op", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



FUNCTION ld_specificni_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. parametri obračuna                  " )
   AAdd( aOpcExe, {|| P_ParObr() } )
   AAdd( aOpc, "2. tipovi primanja" )
   AAdd( aOpcExe, {|| P_TipPr() } )
   AAdd( aOpc, "3. tipovi primanja / ostali obračuni" )
   AAdd( aOpcExe, {|| P_TipPr2() } )
   AAdd( aOpc, "4. porezne stope " )
   AAdd( aOpcExe, {|| p_ld_por() } )
   AAdd( aOpc, "5. doprinosi " )
   AAdd( aOpcExe, {|| p_ld_dopr() } )
   AAdd( aOpc, "6. koef.benef.rst" )
   AAdd( aOpcExe, {|| P_KBenef() } )

   IF gSihtarica == "D"
      AAdd( aOpc, "7. tipovi primanja u šihtarici" )
      AAdd( aOpcExe, {|| P_TprSiht() } )

      AAdd( aOpc, "8. norme radova u šihtarici   " )
      AAdd( aOpcExe, {|| P_NorSiht() } )
   ENDIF

   //IF gSihtGroup == "D"
    //  AAdd( aOpc, "8. lista konta   " )
    //  AAdd( aOpcExe, {|| p_konto() } )
   //ENDIF

   f18_menu( "spc", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION o_ld_sif_tables()

  // o_sifk()
  // o_sifv()
  // o_banke()
   o_tprsiht()
  // o_norsiht()
   //o_ld_radn()
   o_ld_parametri_obracuna()
   //o_tippr()
   //o_ld_rj()
   //o_por()
   //o_dopr()
   //o_str_spr()
   //o_koef_beneficiranog_radnog_staza()
   //o_ld_vrste_posla()
   //o_ops()
   //o_kred()
   //o_tippr2()

   //IF ( IsRamaGlas() )
      //select_o_fakt_objekti()
   //ENDIF

   RETURN .T.
