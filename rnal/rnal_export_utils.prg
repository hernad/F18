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

// -------------------------------------------
// get exp.fajl
// -------------------------------------------
FUNCTION g_exp_location( cLocation )

   LOCAL nRet := 1

   cLocation := AllTrim( gExpOutDir )

   IF Empty( cLocation )
      MsgBeep( "Nije podesen export direktorij!#Parametri -> 4. parametri exporta" )
      nRet := 0
   ENDIF

   // dodaj bs ako ne postoji
   AddBS( @cLocation )

   RETURN nRet



// -------------------------------------------
// vraca naziv fajla
// -------------------------------------------
STATIC FUNCTION g_exp_file( nDoc_no, cLocat )

   LOCAL aDir
   LOCAL cFExt := "TRF"
   LOCAL cFileName := ""

   cFileName := "E"
   cFileName += PadL( AllTrim( Str( nDoc_no ) ), 7, "0" )
   cFileName += "."
   cFileName += cFExt

   RETURN cFileName


// -------------------------------------------
// kreiraj fajl za export....
// -------------------------------------------
FUNCTION cre_exp_file( nDoc_no, cLocation, cFileName, nH )

   // daj naziv fajla
   cFileName := g_exp_file( nDoc_no, cLocation )

   // gExpAlwOvWrite - export file uvijek overwrite
   IF gExpAlwOvWrite == "N" .AND. File( cLocation + cFileName )

      IF pitanje( , "Fajl " + cFileName + " vec postoji, pobrisati ga ?", "D" ) == "N"
         RETURN 0
      ENDIF

   ENDIF

   FErase( cLocation + cFileName )

   nH := FCreate( cLocation + cFileName )

   IF nH == -1
      MsgBeep( "greska pri kreiranju fajla" )
   ENDIF

   RETURN 1



// ----------------------------------------------------
// zatvori fajl
// ----------------------------------------------------
FUNCTION close_exp_file( nH )

   FClose( nH )

   RETURN
