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


FUNCTION MainVirm( cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oVirm
   LOCAL cModul


   cModul := "VIRM"
   PUBLIC goModul

   oVirm := TVirmMod():new( NIL, cModul, f18_ver(), f18_ver_date(), cKorisn, cSifra, p3, p4, p5, p6, p7 )
   goModul := oVirm

   oVirm:run()

   RETURN .T.
