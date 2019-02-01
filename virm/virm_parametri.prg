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



FUNCTION virm_parametri()

   LOCAL _firma := PadR( fetch_metric( "virm_org_id", nil, "" ), 6 )
   LOCAL _firma_naziv := fetch_metric( "virm_org_naz", nil, PadR( self_organizacija_naziv(), 100 ) )
   LOCAL _pict := fetch_metric( "virm_iznos_pict", nil, PadR( "999999999.99", 12 ) )
   LOCAL _nule := fetch_metric( "virm_stampati_nule", nil, "N" )
   LOCAL _sys_datum := fetch_metric( "virm_sys_datum_uplate", nil, "D" )
   LOCAL _org_jed := fetch_metric( "virm_org_jedinica", nil, gOrgJed )
   LOCAL _mjesto := fetch_metric( "virm_mjesto_uplate", nil, gMjesto )
   LOCAL _datum := fetch_metric( "virm_init_datum_uplate", nil, danasnji_datum() )
   LOCAL _konverzija := fetch_metric( "virm_konverzija_delphirb", nil, "5" )

   Box(, 10, 70 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma (nalogodavac) id:" GET _firma
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "   Naziv:" GET _firma_naziv PICT "@S45"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Inicijalni datum uplate:" GET _datum
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Mjesto uplate:" GET _mjesto PICT "@S45"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Broj poreznog obveznika:" GET _org_jed PICT "@S17"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Format iznosa:" GET _pict
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Ako je iznos = 0, treba ga stampati (D/N)?" GET _nule
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Datum uplate = sistemski datum (D/N)?" GET _sys_datum
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Konverzija za stampu delphirb (1 - 5)" GET _konverzija

   READ

   BoxC()

   IF LastKey() <> K_ESC

      set_metric( "virm_org_id", nil, _firma )
      set_metric( "virm_org_naz", nil, _firma_naziv )
      set_metric( "virm_iznos_pict", nil, _pict )
      set_metric( "virm_stampati_nule", nil, _nule )
      set_metric( "virm_sys_datum_uplate", nil, _sys_datum )
      set_metric( "virm_mjesto_uplate", nil, _mjesto )
      set_metric( "virm_init_datum_uplate", nil, _datum )
      set_metric( "virm_org_jedinica", nil, _org_jed )
      set_metric( "virm_konverzija_delphirb", nil, _konverzija )

      gVirmFirma := _firma

   ENDIF

   RETURN
