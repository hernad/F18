/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION MainKalk( cKorisn, cSifra, p3, p4, p5, p6, p7 )

   LOCAL oKalk
   LOCAL cModul


   cModul := "KALK"
   PUBLIC goModul

   oKalk := TKalkMod():new( NIL, cModul, f18_ver(), f18_ver_date(), cKorisn, cSifra, p3, p4, p5, p6, p7 )
   goModul := oKalk

   oKalk:run()

   RETURN .T.
