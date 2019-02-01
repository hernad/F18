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


FUNCTION pos_racun_stampa_priprema( cIdPos, dDatBrDok, fEkran, lViseOdjednom, lOnlyFill )

   LOCAL cDbf
   LOCAL cIdRadnik
   LOCAL nCnt
   LOCAL aPom := {}
   LOCAL cPomaVezani
   LOCAL aVezani := { { pos_doks->IdPos, pos_doks->BrDok, pos_doks->IdVd, pos_doks->datum } }

   //
   // 1            2               3              4
   // aVezani : {pos_doks->IdPos, pos_doks->(BrDok), pos_doks->IdVrsteP, pos_doks->Datum})
   //
   // Napomena: dDatBrDok sadrzi DTOS(DATUM)+BRDOK  !!

   PRIVATE nIznos := 0
   PRIVATE nSumaPor := 0
   PRIVATE aPorezi := {}

   IF fEkran == NIL
      fEkran := .F.
   ELSE
      fEkran := .T.
   ENDIF

   IF lOnlyFill == nil
      lOnlyFill := .F.
   ENDIF

   IF lViseOdjednom == nil
      lViseOdjednom := .F.
   ENDIF

   cSto := pos_doks->Sto
   cIdRadnik := pos_doks->IdRadnik
   cSmjena := pos_doks->Smjena

   nIznos := 0
   nNeplaca := 0

   FOR nCnt := 1 TO Len( aVezani )
      seek_pos_pos( aVezani[ nCnt ][ 1 ], POS_VD_RACUN, aVezani[ nCnt ][ 4 ],  aVezani[ nCnt ][ 2 ] )
      DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == ( aVezani[ nCnt ][ 1 ] + POS_VD_RACUN + DToS( aVezani[ nCnt ][ 4 ] ) + aVezani[ nCnt ][ 2 ] )

         nIznos += pos->( kolicina * cijena )
         select_o_pos_odj( pos->idodj )
         SELECT POS
         nNeplaca += pos->( kolicina * ncijena )
         SKIP
      ENDDO
   NEXT

   SELECT pos
   pos_stampa_racuna_pdv( cIdPos, pos_doks->brdok, .T., pos_doks->idvrstep, pos_doks->datum, aVezani, lViseOdjednom, lOnlyFill )

   RETURN .T.
