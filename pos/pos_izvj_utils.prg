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



/*
FUNCTION RealNaDan( dDatum )

   LOCAL nUkupno
   LOCAL lOpened

   Select( F_POS )
   lOpened := .T.
   IF !Used()
      o_pos_pos()
      lOpened := .F.
   ENDIF

   // "4", "dtos(datum)", KUMPATH+"POS"
   SET ORDER TO TAG "4"
   SEEK DToS( dDatum )

   nUkupno := 0
   cPopust := Pitanje(, "Uzeti u obzir popust", "D" )
   DO WHILE !Eof() .AND. dDatum == field->datum
      IF field->idVd == "42"
         IF cPopust == "D"
            nUkupno += field->kolicina * ( field->cijena - field->ncijena )
         ELSE
            nUkupno += field->kolicina * field->cijena
         ENDIF
      ENDIF
      SKIP
   ENDDO

   IF !lOpened
      USE
   ENDIF

   RETURN nUkupno

*/


FUNCTION pos_kasa_pripremi_pom_za_izvjestaj( cIdVd, cDobId )

   // cIdVD - Id vrsta dokumenta
   // Opis: priprema pomoce baze POM.DBF za realizaciju

   IF ( cDobId == NIL )
      cDobId := ""
   ENDIF

   MsgO( "formiram pomocnu tabelu izvjestaja..." )

   // SEEK cIdVd + DToS( dDatum0 )
   seek_pos_doks_2( cIdVd, dDatum0 )

   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatum1

      IF ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos ) .OR. ( !Empty( cSmjena ) .AND. pos_doks->Smjena <> cSmjena )
         SKIP
         LOOP
      ENDIF

      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

         IF ( !Empty( cIdOdj ) .AND. pos->IdOdj <> cIdOdj )
            SKIP
            LOOP
         ENDIF

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

         IF roba->( FieldPos( "idodj" ) ) <> 0
            select_o_pos_odj( roba->IdOdj )
         ENDIF

         nNeplaca := 0

         // IF Right( odj->naz, 5 ) == "#1#0#"  // proba!!!
         // nNeplaca := pos->( Kolicina * Cijena )
         // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
         // nNeplaca := pos->( Kolicina * Cijena ) / 2
         // ENDIF

         // IF gPopVar = "P"
         nNeplaca += pos->( kolicina * nCijena )
         // ENDIF

         SELECT pom
         GO TOP
         SEEK pos_doks->IdPos + pos_doks->IdRadnik + pos_doks->IdVrsteP + pos->IdOdj + pos->IdRoba + pos->IdCijena // POM

         IF !Found()

            APPEND BLANK
            REPLACE IdPos WITH pos_doks->IdPos
            REPLACE IdRadnik WITH pos_doks->IdRadnik
            REPLACE IdVrsteP WITH pos_doks->IdVrsteP
            REPLACE IdOdj WITH pos->IdOdj
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

            // IF gPopVar == "A"
            // REPLACE Iznos2 WITH Iznos2 + pos->nCijena
            // ENDIF

         ENDIF

         SELECT pos
         SKIP

      ENDDO

      SELECT pos_doks
      SKIP

   ENDDO

   MsgC()

   RETURN .T.
