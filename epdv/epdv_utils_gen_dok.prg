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


FUNCTION g_src_modul( cSrc, lShow )

   LOCAL cPom := ""

   // 1 - FIN
   // 2 - KALK
   // 3 - FAKT
   // 4 - OS
   // 5 - SII
   // 6 - TOPS

   IF lShow == nil
      lShow := .F.
   ENDIF

   DO CASE
   CASE cSrc == "1"
      cPom := "FIN"
   CASE cSrc == "2"
      cPom := "KALK"
   CASE cSrc == "3"
      cPom := "FAKT"
   CASE cSrc == "4"
      cPom := "OS"
   CASE cSrc == "5"
      cPom := "SII"
   CASE cSrc == "6"
      cPom := "TOPS"

   OTHERWISE
      IF lShow
         MsgBeep( "odaberite: 1-FIN, 2-KALK,#3-FAKT, 4-OS, 5-SII, 6-TOPS" )
      ENDIF
   ENDCASE

   IF lShow
      MsgBeep( "Source = " + cPom )
   ENDIF

   RETURN cPom


FUNCTION epdv_get_kateg_partner( cKat, lShow )

   LOCAL cPom := ""

   IF lShow == nil
      lShow := .F.
   ENDIF

   // kategorija partnera
   // 1-pdv obveznik
   // 2-ne pdv obvezink
   // 3-ino partner

   DO CASE
   CASE cKat == "1"
      cPom := "PDV Obveznik"
   CASE cKat == "2"
      cPom := "Ne-PDV obvezik"
   CASE cKat == "3"
      cPom := "Ino partner"
   CASE cKat == "4"
      cPom := "Oslobodjen po clanu"
   CASE cKat == "0"
      cPom := "PDV=0 Ino ili oslobodjen po clanu"
   CASE cKat == "9"
      cPom := "PDV obracunati"
   OTHERWISE
      cPom := "Sve kategorije"
   ENDCASE
   IF lShow
      MsgBeep( "Partner kat. = " + cPom )
   ENDIF

   RETURN cPom



FUNCTION g_kat_p_2( cKat, lShow )

   LOCAL cPom

   cPom := ""

   IF lShow == nil
      lShow := .F.
   ENDIF

   DO CASE
   CASE cKat == "1"
      cPom := "Federacija"
   CASE cKat == "2"
      cPom := "Republika Srpska"
   CASE cKat == "3"
      cPom := "Distrikt Brcko"
   OTHERWISE
      cPom := "Svi BiH subjekti"

   ENDCASE

   IF lShow
      MsgBeep( "Partner kat.2 = " + cPom )
   ENDIF

   RETURN cPom



FUNCTION close_open_kuf_kif_sif()

   //o_partner()
   //o_roba()
   //o_tarifa()
   //o_sifk()
   //o_sifv()

   RETURN .T.
