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


FUNCTION fakt_print_narudzbenica( cIdFirma, cIdTipDok, cBrDok )

   PushWA()

   close_open_fakt_tabele()

   // izgenerisi rn.dbf i drn.dbf, ali nemoj stampati poreznu fakturu
   fakt_stamp_txt_dokumenta( cIdfirma, cIdTipdok, cBrDok, .T. )

   print_narudzbenica()

   //o_partner()
   SELECT ( F_FAKT_DOKS )
   USE
   //o_fakt_doks_dbf()
   PopWa()

   RETURN NIL


FUNCTION fakt_print_narudzbenica_priprema()

      fakt_stdok_pdv( nil, nil, nil, .T. )
      select_fakt_pripr()

      print_narudzbenica()
      close_open_fakt_tabele()
      select_fakt_pripr()

    RETURN NIL
