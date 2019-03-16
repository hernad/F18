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


FUNCTION pos_dokument( hParams )

   RETURN AllTrim( hParams[ "idpos" ] ) + "-" + AllTrim( hParams[ "idvd" ] ) + "-" + AllTrim( hParams[ "brdok" ] )


FUNCTION pos_dokument_sa_vrijeme( hParams )
   RETURN pos_dokument( hParams ) + " " + DToC( hParams[ "datum" ] )

FUNCTION pos_stampa_dokumenta( hParams )

   IF hParams[ "idvd" ] $ POS_IDVD_NIVELACIJE_SNIZENJA
      pos_stampa_nivelacija( hParams )
   ELSE
      pos_stampa_zaduzenja( hParams )
   ENDIF

   RETURN .T.


FUNCTION pos_racun_sadrzi_artikal( cIdPos, cIdVd, dDatum, cBroj, cIdRoba )

   LOCAL lRet := .F.
   LOCAL cWhere

   cWhere := " idpos " + sql_quote( cIdPos )
   cWhere += " AND idvd = " + sql_quote( cIdVd )
   cWhere += " AND datum = " + sql_quote( dDatum )
   cWhere += " AND brdok = " + sql_quote( cBroj )
   cWhere += " AND idroba = " + sql_quote( cIdRoba )

   IF table_count( f18_sql_schema( "pos_pos" ), cWhere ) > 0
      lRet := .T.
   ENDIF

   RETURN lRet
