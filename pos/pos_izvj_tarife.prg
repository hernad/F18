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

FUNCTION pos_rekapitulacija_tarifa( aTarife )

   LOCAL nArr
   LOCAL cLine

   ?
   ? "REKAPITULACIJA POREZA PO TARIFAMA"

   nTotOsn := 0
   nTotPPP := 0
   nTotPPU := 0
   nTotPP := 0
   nPDV := 0

   cLine := Replicate( "-", 12 )
   cLine += " "
   cLine += Replicate( "-", 12 )
   cLine += " "
   cLine += Replicate( "-", 12 )

   ASort ( aTarife,,, {| x, y| x[ 1 ] < y[ 1 ] } )

   ? cLine

   ? "Tarifa (Stopa %)"
   ? PadC( "PV bez PDV", 12 ), PadC( "PDV", 12 ), PadC( "PV sa PDV", 12 )

   ? cLine

   nArr := Select()

   FOR nCnt := 1 TO Len( aTarife )

      select_o_tarifa( aTarife[ nCnt ][ 1 ] )
      nPDV := tarifa->opp

      ? aTarife[ nCnt ][ 1 ], "(" + Str( nPDV ) + "%)"
      ? Str( aTarife[ nCnt ][ 2 ], 12, 2 ), Str ( aTarife[ nCnt ][ 3 ], 12, 2 ), Str( Round( aTarife[ nCnt ][ 2 ], 2 ) + Round( aTarife[ nCnt ][ 3 ], 2 ), 12, 2 )
      nTotOsn += Round( aTarife[ nCnt ][ 2 ], 2 )
      nTotPPP += Round( aTarife[ nCnt ][ 3 ], 2 )
   NEXT

   SELECT ( nArr )

   ? cLine
   ? "UKUPNO"
   ? Str( nTotOsn, 12, 2 ), Str( nTotPPP, 12, 2 ), Str( nTotOsn + nTotPPP, 12, 2 )
   ? cLine
   ?

   RETURN NIL



FUNCTION pos_setuj_tarife( cIdRoba, nIzn, aTarife, nPPP, nPPU, nOsn, nPP )

   nArr := Select()

   //o_roba()
   //o_tarifa()

   select_o_roba( cIdRoba )
   select_o_tarifa( roba->idtarifa )

   SELECT ( nArr )

   nOsn := nIzn / ( tarifa->zpp / 100 + ( 1 + tarifa->opp / 100 ) * ( 1 + tarifa->ppp / 100 ) )
   nPPP := nOsn * tarifa->opp / 100
   nPP := nOsn * tarifa->zpp / 100

   nPPU := ( nOsn + nPPP ) * tarifa->ppp / 100

   nPoz := AScan ( aTarife, {| x| x[ 1 ] == roba->IdTarifa } )

   IF nPoz == 0
      AAdd ( aTarife, { roba->IdTarifa, nOsn, nPPP, nPPU, nPP } )
   ELSE
      aTarife[nPoz ][ 2 ] += nOsn
      aTarife[nPoz ][ 3 ] += nPPP
      aTarife[nPoz ][ 4 ] += nPPU
      aTarife[nPoz ][ 5 ] += nPP
   ENDIF

   RETURN NIL
