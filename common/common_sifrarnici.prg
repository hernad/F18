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


FUNCTION opci_sifarnici()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. partneri                          " )

   AAdd( aOpcExe, {|| p_partner() } )

   IF ( programski_modul() <> "FIN" )
      AAdd( aOpc, "2. konta" )
      AAdd( aOpcExe, {|| P_Konto() } )

   ELSE
      AAdd( aOpc, "2. ----------------- " )
      AAdd( aOpcExe, {|| NotImp() } )
   ENDIF

   AAdd( aOpc, "3. tipovi naloga" )
   AAdd( aOpcExe, {|| p_fin_vrsta_naloga() } )


   AAdd( aOpc, "4. tipovi dokumenata" )
   AAdd( aOpcExe, {|| browse_tdok() } )


   AAdd( aOpc, "5. valute" )
   AAdd( aOpcExe, {|| P_Valute() } )


   AAdd( aOpc, "6. radne jedinice" )
   AAdd( aOpcExe, {|| P_RJ() } )


   AAdd( aOpc, "7. općine" )
   AAdd( aOpcExe, {|| P_Ops() } )


   AAdd( aOpc, "8. banke" )
   AAdd( aOpcExe, {|| P_Banke() } )


   AAdd( aOpc, "9. sifk - karakteristike" )
   AAdd( aOpcExe, {|| P_SifK() } )


   AAdd( aOpc, "A. vrste plaćanja" )
   AAdd( aOpcExe, {|| P_VrsteP() } )


   AAdd( aOpc, "R. pravila" )
   AAdd( aOpcExe, {|| p_rules() } )

   IF ( IsRamaGlas() .OR.  gModul == "FAKT" .AND. glRadNal )
      AAdd( aOpc, "O. objekti" )
      AAdd( aOpcExe, {|| P_fakt_objekti() } )
   ENDIF

   open_sif_tables_1()

   gPregledSifriIzMenija := .T.

   f18_menu( "ssvi", .F., nIzbor, aOpc, aOpcExe )

   gPregledSifriIzMenija := .F.

   my_close_all_dbf()

   RETURN .T.




// -------------------------------------------------------------------------
// profili
// primjer: Profil partnera = "KUP,KMS"
// KUP - kupac
// DOB - dobavljac
// KMS - komisionar
// KMT - komintent u konsignacionoj prodaji
// INO - ino partner
// UIO - radi se o specificnom partneru - uprava za indirektno
// oporezivanje
// SPE - partner koji obavlja poslove spediciji kod uvoza robe
// TRA - obavlja transport
//
// Napomena: partner moze biti i kupac i dobavljac - stavlja se KUP,DOB
// znaci moze imati vise funkcija
//
// profil partnera = SVI atributi koji odgovaraju ovom partneru
// ------------------------------------------------------------------------
FUNCTION IsProfil( cIdPartner, cProfId )

   LOCAL cProfili

   cProfili := get_partn_sifk_sifv( "PROF", cIdPartner, .F. )

   IF cProfId $ Upper( cProfili )
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF


/*
   partner je komisionar
*/

FUNCTION IsKomision( cIdPartner )

   RETURN IsProfil( cIdPartner, "KMS" )
