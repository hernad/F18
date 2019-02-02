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

FUNCTION pos_racun_stampa_priprema( hParams )

// cIdPos, dDatBrDok, fEkran, lViseOdjednom, lOnlyFill )

   LOCAL cDbf
   LOCAL cIdRadnik
   LOCAL nCnt
   LOCAL aPom := {}
   LOCAL nIznos, nNePlaca

   //PRIVATE nSumaPor := 0
   PRIVATE aPorezi := {}

   cIdRadnik := pos_doks->IdRadnik
   //cSmjena := pos_doks->Smjena

   nIznos := 0
   nNeplaca := 0
   seek_pos_pos( hParams[ "idpos" ], POS_VD_RACUN, hParams[ "datum" ], hParams[ "brdok" ] )
   DO WHILE !Eof() .AND. ( pos->IdPos + pos->IdVd + DToS( pos->datum ) + pos->BrDok ) == ( hParams[ "idpos" ] + POS_VD_RACUN + DToS( hParams[ "datum" ] ) + hParams[ "brdok" ] )
      nIznos += pos->kolicina * pos->cijena
      //select_o_pos_odj( pos->idodj )
      //SELECT POS
      nNeplaca += pos->kolicina * pos->ncijena
      SKIP
   ENDDO

   //SELECT pos
   pos_stampa_racuna_pdv( hParams )
   // hParams["idpos"], hParams["brdok"], .T., pos_doks->idvrstep, pos_doks->datum, aVezani, lViseOdjednom, lOnlyFill )

   RETURN .T.
