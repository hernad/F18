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

FUNCTION pdv_procenat_by_tarifa( cIdTarifa )

   PushWa()
   select_o_tarifa( cIdTarifa )
   PopWa()

   RETURN tarifa->pdv / 100


// formatiraj stopa pdv kao string
// " 17 %"
// "15.5%"

FUNCTION format_stopa_pdv_string( nPdv )

   IF nPdv == nil
      nPdv := tarifa->pdv
   ENDIF

   IF Round( nPdv, 1 ) == Round( nPdv, 0 )
      RETURN Str( nPdv, 3, 0 ) + " %"
   ENDIF

   RETURN Str( nPdv, 3, 1 ) + "%"


FUNCTION mpc_sa_pdv_by_tarifa( cIdTarifa, nMPCBp )

   LOCAL nPDV

   PushWa()
   select_o_tarifa( cIdTarifa )
   nPDV := tarifa->pdv / 100
   PopWa()

   RETURN nMpcBp * ( nPDV + 1 )


FUNCTION mpc_bez_pdv_by_tarifa( cIdTarifa, nMpcSaPP )

   LOCAL nPDV

   PushWa()
   select_o_tarifa( cIdTarifa )
   nPDV := tarifa->pdv / 100
   PopWa()

   RETURN nMpcSaPP / ( 1 + nPDV )
