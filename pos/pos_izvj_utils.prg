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

FUNCTION pos_kasa_pripremi_pom_za_izvjestaj( cIdVd, cDobId )

   // cIdVD - Id vrsta dokumenta
   // Opis: priprema pomoce baze POM.DBF za realizaciju

   IF ( cDobId == NIL )
      cDobId := ""
   ENDIF

   MsgO( "formiranje pomoćne tabele za izvještaj..." )

   // SEEK cIdVd + DToS( dDatum0 )
   seek_pos_doks_2( cIdVd, dDatum0 )

   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatum1

      IF ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos )
         SKIP
         LOOP
      ENDIF
      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

         select_o_roba( pos->IdRoba )
         IF roba->( FieldPos( "sifdob" ) ) <> 0
            IF !Empty( cDobId )
               IF roba->sifdob <> cDobId
                  SELECT pos
                  SKIP
                  LOOP
               ENDIF
            ENDIF
         ENDIF

         nNeplaca := 0
         nNeplaca += pos->( kolicina * nCijena )


         SELECT pom
         GO TOP
         SEEK pos_doks->IdPos + pos_doks->IdRadnik + pos_doks->IdVrsteP + pos->IdRoba + pos->IdCijena // POM

         IF !Found()
            APPEND BLANK
            REPLACE IdPos WITH pos_doks->IdPos
            REPLACE IdRadnik WITH pos_doks->IdRadnik
            REPLACE IdVrsteP WITH pos_doks->IdVrsteP
            REPLACE IdRoba WITH pos->IdRoba
            REPLACE IdCijena WITH pos->IdCijena
            REPLACE Kolicina WITH pos->Kolicina
            REPLACE Iznos WITH pos->Kolicina * POS->Cijena
            REPLACE Iznos3 WITH nNeplaca

            // IF gPopVar == "A"
            REPLACE Iznos2 WITH pos->nCijena
            // ENDIF
            IF roba->( FieldPos( "K1" ) ) <> 0
               REPLACE K2 WITH roba->K2, K1 WITH roba->K1
            ENDIF

         ELSE
            REPLACE Kolicina WITH Kolicina + POS->Kolicina
            REPLACE Iznos WITH Iznos + POS->Kolicina * POS->Cijena
            REPLACE Iznos3 WITH Iznos3 + nNeplaca

         ENDIF

         SELECT pos
         SKIP

      ENDDO

      SELECT pos_doks
      SKIP

   ENDDO

   MsgC()

   RETURN .T.
