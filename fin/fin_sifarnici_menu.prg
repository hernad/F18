/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2011 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION MnuSifrarnik()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. opšti šifarnici                  " )
   AAdd( _opcexe, {|| opci_sifarnici() } )

   AAdd( _opc, "2. finansijsko poslovanje " )
   AAdd( _opcexe, {|| _menu_specif() } )


   IF ( gFinRj == "D" .OR. gTroskovi == "D" )
      AAdd( _opc, "3. budžet" )
      AAdd( _opcexe, {|| _menu_budzet() } )
   ENDIF

   f18_menu( "sif", .F., _izbor, _opc, _opcexe )

   RETURN .T.


STATIC FUNCTION _menu_specif()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   O_KONTO
   O_KS
   O_TRFP2
   //O_TRFP3
   O_PKONTO
   //O_ULIMIT

   AAdd( _opc, "1. kontni plan                          " )
   AAdd( _opcexe, {|| P_KontoFin() } )
   AAdd( _opc, "2. sheme kontiranja                     " )
   AAdd( _opcexe, {|| P_Trfp2() } )
   AAdd( _opc, "3. prenos konta u ng" )
   AAdd( _opcexe, {|| P_PKonto() } )

  // AAdd( _opc, "4. limiti po ugovorima" )
  // AAdd( _opcexe, {|| P_ULimit() } )

  // AAdd( _opc, "5. sheme kontiranja obracuna LD" )
  // AAdd( _opcexe, {|| P_TRFP3() } )
   AAdd( _opc, "6. kamatne stope" )
   AAdd( _opcexe, {|| P_KS() } )

   f18_menu( "sopc", .F., _izbor, _opc, _opcexe )

   RETURN .T.



STATIC FUNCTION _menu_budzet()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _Izbor := 1

   OSifBudzet()

   AAdd( _opc, "1. radne jedinice              " )
   AAdd( _opcexe, {|| P_Rj() } )
   AAdd( _opc, "2. funkc.kval       " )
   AAdd( _opcexe, {|| P_FunK() } )
   AAdd( _opc, "3. plan budzeta" )
   AAdd( _opcexe, {|| P_Budzet() } )
   AAdd( _opc, "4. partije->konta " )
   AAdd( _opcexe, {|| P_ParEK() } )
   AAdd( _opc, "5. fond   " )
   AAdd( _opcexe, {|| P_Fond() } )
   
  // AAdd( _opc, "6. konta-izuzeci" )
  // AAdd( _opcexe, {|| P_BuIZ() } )

   f18_menu( "sbdz", .F., _izbor, _opc, _opcexe )

   RETURN


FUNCTION OSifBudzet()

   O_RJ
   O_FUNK
   O_FOND
   O_BUDZET
   O_PAREK
   O_BUIZ
   O_KONTO
   O_TRFP2

   RETURN