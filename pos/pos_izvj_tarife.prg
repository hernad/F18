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
   LOCAL nCnt
   LOCAL nTotOsn
   LOCAL nTotPDV

   LOCAL nPDV := 0

   ?
   ? "REKAPITULACIJA PDV PO TARIFAMA"

   nTotOsn := 0
   nTotPDV := 0
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
      nPDV := tarifa->pdv

      ? aTarife[ nCnt ][ 1 ], "(" + Str( nPDV ) + "%)"
      ? Str( aTarife[ nCnt ][ 2 ], 12, 2 ), Str ( aTarife[ nCnt ][ 3 ], 12, 2 ), Str( Round( aTarife[ nCnt ][ 2 ], 2 ) + Round( aTarife[ nCnt ][ 3 ], 2 ), 12, 2 )
      nTotOsn += Round( aTarife[ nCnt ][ 2 ], 2 )
      nTotPDV += Round( aTarife[ nCnt ][ 3 ], 2 )
   NEXT

   SELECT ( nArr )

   ? cLine
   ? "UKUPNO"
   ? Str( nTotOsn, 12, 2 ), Str( nTotPDV, 12, 2 ), Str( nTotOsn + nTotPDV, 12, 2 )
   ? cLine
   ?

   RETURN NIL



FUNCTION pos_setuj_tarife( cIdRoba, nIzn, aTarife, nPDV, nPPU, nOsn, nPP )

   nArr := Select()

   select_o_roba( cIdRoba )
   select_o_tarifa( roba->idtarifa )

   SELECT ( nArr )

   nOsn := nIzn / ( 1 + tarifa->pdv / 100 )
   nPDV := nOsn * tarifa->pdv / 100
   nPoz := AScan ( aTarife, {| x| x[ 1 ] == roba->IdTarifa } )

   IF nPoz == 0
      AAdd ( aTarife, { roba->IdTarifa, nOsn, nPDV } )
   ELSE
      aTarife[nPoz ][ 2 ] += nOsn
      aTarife[nPoz ][ 3 ] += nPDV
   ENDIF

   RETURN NIL
