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


FUNCTION epdv_update_sif_tarifa()

   LOCAL cPom


   run_sql_query( "BEGIN" )

   cPom := PadR( "PDV17", 6 )
   epdv_dodati_tarifu( cPom, "PDV 17%", 17 )

   cPom := PadR( "PDV17Z", 6 )
   epdv_dodati_tarifu( cPom, "PDV 17% ZASTICENA CIJENA", 17 )

   cPom := PadR( "PDV0", 6 )
   epdv_dodati_tarifu( cPom, "PDV 0%", 0 )

   cPom := PadR ( "PDV7PO", 6 )
   epdv_dodati_tarifu( cPom, "POLJOPR., OPOR. DIO PDV 17%", 17 )

   cPom := PadR( "PDV0PO", 6 )
   epdv_dodati_tarifu( cPom, "POLJOPR., NEOPOR. DIO PDV 0%", 0 )

   cPom := PadR( "PDV7UV", 6 )
   epdv_dodati_tarifu( cPom, "UVOZ OPOREZIVO, PDV 17%", 17 )

   cPom := PadR( "PDV0UV", 6 )
   epdv_dodati_tarifu( cPom, "UVOZ NEOPOREZIVO, PDV 0%", 0 )

   cPom := PadR( "PDV7NP", 6 )
   epdv_dodati_tarifu( cPom, "NEPOSLOVNE SVRHE, NAB/ISP", 17 )

   cPom := PadR( "PDV7AV", 6 )
   epdv_dodati_tarifu( cPom, "AVANSNE FAKTURE, PDV 17%", 17 )

   cPom := PadR( "PDV0AV", 6 )
   epdv_dodati_tarifu( cPom, "AVANSNE FAKTURE, PDV 0%", 0 )

   cPom := PadR( "PDV0IZ", 6 )
   epdv_dodati_tarifu( cPom, "IZVOZ, PDV 0%", 0 )

   run_sql_query( "COMMIT" )

   RETURN .T.



STATIC FUNCTION epdv_dodati_tarifu( cTarifaId, cNaziv, nIznos )

   LOCAL hRec

   IF !select_o_tarifa( cTarifaId )

      APPEND BLANK
      hRec := dbf_get_rec()
      hRec[ "id" ] := cTarifaId
      hRec[ "naz" ] := cNaziv
      hRec[ "pdv" ] := nIznos
      update_rec_server_and_dbf( "tarifa", hRec, 1, "CONT" )

   ENDIF

   RETURN .T.
