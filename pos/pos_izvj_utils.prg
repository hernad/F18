/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

FUNCTION pos_kasa_pripremi_pom_za_realkase( cIdPos, cIdVd, dDatOd, dDatDo )

   // cIdVD - Id vrsta dokumenta
   // Opis: priprema pomoce baze POM.DBF za realizaciju


   MsgO( "formiranje pomoćne tabele za izvještaj..." )

   //seek_pos_doks_2( cIdVd, dDatOd )
   seek_pos_doks_2_za_period( cIdVd, dDatOd, dDatDo )
   DO WHILE !Eof() .AND. pos_doks->IdVd == cIdVd .AND. pos_doks->Datum <= dDatDo

      IF ( !Empty( cIdPos ) .AND. pos_doks->IdPos <> cIdPos )
         SKIP
         LOOP
      ENDIF
      seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
      DO WHILE !Eof() .AND. pos->IdPos + pos->IdVd + DToS( pos->datum ) + pos->BrDok  == pos_doks->IdPos + pos_doks->IdVd + DToS( pos_doks->datum ) + pos_doks->BrDok

         select_o_roba( pos->IdRoba )
         SELECT pom
         GO TOP
         SEEK pos_doks->IdPos + pos_doks->IdRadnik + pos_doks->IdVrsteP + pos->IdRoba

         IF !Found()
            APPEND BLANK
            REPLACE IdPos WITH pos_doks->IdPos
            REPLACE IdRadnik WITH pos_doks->IdRadnik
            REPLACE IdVrsteP WITH pos_doks->IdVrsteP
            REPLACE IdRoba WITH pos->IdRoba
            REPLACE Kolicina WITH pos->Kolicina
            REPLACE Iznos WITH pos->Kolicina * POS->Cijena
            REPLACE popust with pos->kolicina * pos_popust( pos->cijena, pos->ncijena )

         ELSE
            REPLACE Kolicina WITH Kolicina + POS->Kolicina
            REPLACE Iznos WITH Iznos + POS->Kolicina * POS->Cijena
            REPLACE popust WITH popust + POS->Kolicina * pos_popust( POS->Cijena, pos->ncijena )
         ENDIF

         SELECT pos
         SKIP

      ENDDO

      SELECT pos_doks
      SKIP

   ENDDO

   MsgC()

   RETURN .T.
