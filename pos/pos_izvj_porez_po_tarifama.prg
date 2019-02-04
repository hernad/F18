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

   // cIdvd - tip dokumenta za koji se obracun poreza vrsi
   // dDatum0 - pocetni datum
   // aTarife - puni se matrica aTarife
   //
   // private: dDatum1 - krajnji datum
   //

/* Porezi(cIdVd,dDatum0,aTarife,cNaplaceno)
 *     Pravi matricu sa izracunatim porezima za zadani period
 *  return aTarife - matrica izracunatih poreza po tarifama
 */

FUNCTION Porezi( cIdVd, dDatum0, aTarife, cNaplaceno )

   IF cNaplaceno == nil
      cNaplaceno := "1"
   ENDIF

   // SELECT pos_doks
   // SEEK cIdVd + DToS( dDatum0 )   // realizaciju skidam sa racuna
   seek_pos_doks_2( cIdVd, dDatum0 )


   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatum1

      IF ( !pos_admin() .AND. pos_doks->idpos = "X" ) .OR. ( pos_doks->IdPos = "X" .AND. AllTrim( cIdPos ) <> "X" ) .OR. ( !Empty( cIdPos ) .AND. cIdPos <> pos_doks->IdPos )
         SKIP
         LOOP
      ENDIF


      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

         select_o_tarifa( POS->IdTarifa )

         IF cNaplaceno == "1"

            nIzn := pos->( Cijena * Kolicina )

         ELSE  // cnaplaceno="3"

            select_o_roba( pos->idroba )

            nNeplaca := 0

            // IF gPopVar = "P"
            nNeplaca += pos->( kolicina * NCijena )
            // ENDIF

            // IF gPopVar == "A"
            // nIzn := pos->( Cijena * kolicina ) - nNeplaca + pos->ncijena
            // ELSE
            nIzn := pos->( Cijena * kolicina ) - nNeplaca
            // ENDIF

         ENDIF

         SELECT POS

         nOsn := nIzn / ( tarifa->zpp / 100 + ( 1 + tarifa->opp / 100 ) * ( 1 + tarifa->ppp / 100 ) )
         nPPP := nOsn * tarifa->opp / 100
         nPP := nOsn * tarifa->zpp / 100

         nPPU := ( nOsn + nPPP ) * tarifa->ppp / 100


         aPorezi := {}
         set_pdv_array( @aPorezi )
         aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, nOsn, nIzn, 0 )
         nPoz := AScan( aTarife, {| x | x[ 1 ] == POS->IdTarifa } )
         IF nPoz == 0
            AAdd( aTarife, { POS->IdTarifa, nOsn, aIPor[ 1 ], aIPor[ 2 ], aIPor[ 3 ], nIzn } )
         ELSE
            aTarife[ nPoz ][ 2 ] += nOsn
            aTarife[ nPoz ][ 3 ] += aIPor[ 1 ]
            aTarife[ nPoz ][ 4 ] += aIPor[ 2 ]
            aTarife[ nPoz ][ 5 ] += aIPor[ 3 ]
            aTarife[ nPoz ][ 6 ] += nIzn
         ENDIF


         SKIP
      ENDDO

      SELECT pos_doks
      SKIP
   ENDDO

   RETURN aTarife
