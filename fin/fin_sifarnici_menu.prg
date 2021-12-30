/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION MnuSifrarnik()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   AAdd( aOpc, "1. opći matični podaci (šifarnici)                " )
   AAdd( aOpcExe, {|| opci_sifarnici() } )

   AAdd( aOpc, "2. matični podaci finansijsko poslovanje " )
   AAdd( aOpcExe, {|| _menu_specif() } )


   IF ( gFinRj == "D" .OR. gFinFunkFond == "D" )
      AAdd( aOpc, "3. budžet" )
      AAdd( aOpcExe, {|| _menu_budzet() } )
   ENDIF

   f18_menu( "sif", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.


STATIC FUNCTION _menu_specif()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _izbor := 1

   o_konto()
   O_KS
   o_trfp2()
   //O_TRFP3
   O_PKONTO
   //O_ULIMIT

   AAdd( aOpc, "1. kontni plan                             " )
   AAdd( aOpcExe, {|| p_konto() } )
   AAdd( aOpc, "2. sheme kontiranja fakt->fin (trfp2)  " )
   AAdd( aOpcExe, {|| P_Trfp2() } )
   AAdd( aOpc, "3. prenos konta u ng" )
   AAdd( aOpcExe, {|| P_PKonto() } )

   
   IF konto_2022()
      AADD(aOpc, "4. kontni plan 2022")
      AAdd( aOpcExe, {|| fin_kontni_plan_2022() } )
   ENDIF

  // AAdd( aOpc, "4. limiti po ugovorima" )
  // AAdd( aOpcExe, {|| P_ULimit() } )

  // AAdd( aOpc, "5. sheme kontiranja obracuna LD" )
  // AAdd( aOpcExe, {|| P_TRFP3() } )
   AAdd( aOpc, "6. kamatne stope" )
   AAdd( aOpcExe, {|| P_KS() } )

   f18_menu( "sopc", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION _menu_budzet()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _Izbor := 1

   OSifBudzet()

   AAdd( aOpc, "1. radne jedinice              " )
   AAdd( aOpcExe, {|| P_Rj() } )

   AAdd( aOpc, "2. funkc.kval       " )
   AAdd( aOpcExe, {|| P_FunK() } )

   //AAdd( aOpc, "3. plan budzeta" )
   //AAdd( aOpcExe, {|| P_Budzet() } )
   //AAdd( aOpc, "4. partije->konta " )
   //AAdd( aOpcExe, {|| P_ParEK() } )
   AAdd( aOpc, "5. fond   " )
   AAdd( aOpcExe, {|| P_Fond() } )

  // AAdd( aOpc, "6. konta-izuzeci" )
  // AAdd( aOpcExe, {|| P_BuIZ() } )

   f18_menu( "sbdz", .F., _izbor, aOpc, aOpcExe )

   RETURN .T.


FUNCTION OSifBudzet()

// o_rj()
   //o_funk()
   //o_fond()
   //O_BUDZET
   //O_PAREK
   //o_buiz()
  // o_konto()
   o_trfp2()

   RETURN .T.
