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


/* fn UBrojDok(nBroj,nNumDio,cOstatak)
 * brief Pretvara Broj podbroj u string format "Broj dokumenta"

 * UBrojDok ( 123,  5, "/99" )   =>   00123/99
 */

FUNCTION UBrojDok( nBroj, nNumdio, cOstatak )

   RETURN PadL( AllTrim( Str( nBroj ) ), nNumDio, "0" ) + cOstatak
