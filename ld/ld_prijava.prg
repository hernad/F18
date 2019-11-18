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


FUNCTION ld_postavi_parametre_obracuna()

   LOCAL nX := 1
   LOCAL _pad_l := 20
   LOCAL _v_obr_unos := fetch_metric( "ld_vise_obracuna_na_unosu", my_user(), "N" ) == "D"
   LOCAL nMjesec := ld_tekuci_mjesec(), nGodina := ld_tekuca_godina()
   LOCAL GetList := {}

  // o_ld_rj()

   Box(, 6 + iif( _v_obr_unos, 1, 0 ), 50 )

   set_cursor_on()

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadC( "*** PRISTUPNI PODACI ZA OBRAČUN ***", 50 )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Radna jedinica", _pad_l ) GET gLDRadnaJedinica VALID P_LD_Rj( @gLDRadnaJedinica ) PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Mjesec", _pad_l ) GET nMjesec PICT "99"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Godina", _pad_l ) GET nGodina PICT "9999"

   IF _v_obr_unos
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Obračun broj", _pad_l ) GET gObracun WHEN ld_help_broj_obracuna( .F., gObracun ) VALID ld_valid_obracun( .F., gObracun )

   ENDIF

   READ

   ClvBox()

   BoxC()


   IF LastKey() <> K_ESC

      set_metric( "ld_godina", my_user(), ld_tekuca_godina( nGodina ) )
      set_metric( "ld_mjesec", my_user(), ld_tekuci_mjesec( nMjesec ) )
      set_metric( "ld_rj", my_user(), gLDRadnaJedinica )
      set_metric( "ld_obracun", my_user(), gObracun )
      set_metric( "ld_varijanta_obracuna", NIL, gVarObracun )

   ENDIF

   RETURN .T.
