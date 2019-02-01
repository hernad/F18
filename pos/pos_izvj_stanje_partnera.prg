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

FUNCTION pos_rpt_stanje_partnera()

   LOCAL nPom
   LOCAL nDuguje
   LOCAL nPotrazuje
   PRIVATE cGost := Space( 8 )
   PRIVATE cNula := "D"
   PRIVATE dDat := danasnji_datum()
   PRIVATE dDatOd := danasnji_datum() - 30
   PRIVATE cSpec := "D"
   PRIVATE cVrstP := Space( 2 )
   PRIVATE cGotZir := Space( 1 )
   PRIVATE cSifraDob := Space( 8 )

   // o_partner()

   DO WHILE .T.
      IF !VarEdit( { ;
            { "Sifra partnera (prazno-svi)", "cGost", "IF(!EMPTY(cGost),p_partner(@cGost),.t.)", "@!", }, ;
            { "Prikaz partnera sa stanjem 0 (D/N)", "cNula", "cNula$'DN'", "@!", }, ;
            { "Prikazati stanje od dana ", "dDatOd", ".t.",, }, ;
            { "Prikazati stanje do dana ", "dDat", ".t.",, }, ;
            { "Prikaz G/Z/sve ", "cGotZir", "cGotZir$'GZ '", "@!", }, ;
            { "Vrsta placanja (prazno-sve) ", "cVrstP", ".t.",, }, ;
            { "Dobavljac ", "cSifraDob", ".t.",, }, ;
            { "Prikazati specifikaciju", "cSpec", "cSpec$'DN'", "@!", } }, 8, 5, 19, 74, 'USLOVI ZA IZVJESTAJ "STANJE PARTNERA"', "B1" )
         CLOSERET
      ELSE
         EXIT
      ENDIF
   ENDDO

   // o_roba()
   o_pos_kumulativne_tabele()
   // o_partner()

   START PRINT CRET
   ?? gP12cpi

   // ZagFirma()

   ? PadC( "STANJE RACUNA PARTNERA NA DAN " + FormDat1( dDat ), 80 )
   ? PadC( "----------------------------------------", 80 )
   ?
   ? PadR( "Partner", 39 ) + " "

   // IF gVrstaRS == "K"
   // ? Space( 4 )
   // ENDIF

   ?? PadR( "Dugovanje", 12 ), PadR( "Placeno", 12 ), "   STANJE    "
   ? Replicate( "-", 39 ) + " "

   // IF gVrstaRS == "K"
   // ? Space( 4 )
   // ENDIF

   ?? REPL( "-", 12 ), REPL( "-", 12 ), REPL( "-", 14 )

   nSumaSt := 0
   nSumaNije := 0
   nSumaJest := 0
   nBrojacPartnera := 1
   nBrojacStavki := 1

   SELECT pos_doks

   // "IdGost+Placen+DTOS (Datum)"
   SET ORDER TO 3
   SEEK cGost

   DO WHILE !Eof()

      IF ( pos_doks->datum < dDatOd .OR. pos_doks->datum > dDat )
         SKIP
         LOOP
      ENDIF

      IF Empty( pos_doks->IdGost )
         SKIP
         LOOP
      ENDIF

      // G-gotovina Z-ziral
      IF !Empty( cGotZir )
         DO CASE
         CASE cGotZir == "G"
            IF pos_doks->placen <> " "
               SKIP
               LOOP
            ENDIF
         CASE cGotZir == "Z"
            IF pos_doks->placen <> cGotZir
               SKIP
               LOOP
            ENDIF
         ENDCASE
      ENDIF

      nPrviRec := RecNo()
      fPisi := .F.
      nPlacJest := 0
      nPlacNije := 0
      cIdGost := pos_doks->IdGost

      DO WHILE !Eof() .AND. pos_doks->IdGost == cIdGost

         IF ( pos_doks->datum < dDatOd .OR. pos_doks->datum > dDat )
            SKIP
            LOOP
         ENDIF

         IF !Empty( cVrstP )
            IF ( pos_doks->IdVrsteP <> cVrstP )
               SKIP
               LOOP
            ENDIF
         ENDIF

         seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
         nIznos := 0
         nDuguje := 0
         nPotrazuje := 0
         DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

            // pretraga po sifri dobavljaca
            select_o_roba( pos->idroba )
            IF roba->( FieldPos( "sifdob" ) ) <> 0
               IF roba->id == pos->idroba
                  IF !Empty( cSifraDob )
                     IF ( roba->sifdob <> cSifraDob )
                        SELECT pos
                        SKIP
                        LOOP
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF

            SELECT pos
            IF pos_doks->IdVrsteP == "01"
               nPom := pos->kolicina * pos->cijena * iif( pos->idvd == "00", - 1, 1 )
               // placanje gotovinom povecava promet na obje strane
               nPlacJest += nPom
               nPlacNije += nPom
            ELSEIF ( Left( idroba, 5 ) == 'PLDUG' )
               nPlacJest += POS->Kolicina * POS->Cijena * iif( pos->idvd = '00', - 1, 1 )
            ELSE
               nIznos += POS->Kolicina * POS->Cijena * iif( pos->idvd = '00', - 1, 1 )
               nPlacNije += POS->Kolicina * POS->Cijena * iif( pos->idvd = '00', - 1, 1 )
            ENDIF
            SKIP
         ENDDO
         SELECT pos_doks
         SKIP
      ENDDO

      nStanje := nPlacNije - nPlacJest

      IF Round( nStanje, 4 ) <> 0 .OR. cNula == "D"

         select_o_partner( cIdGost )
         ? REPL( "-", 80 )
         ? AllTrim( Str( nBrojacPartnera ) ) + ") " + PadR( AllTrim( cIdGost ) + " " + partn->Naz, 35 ) + " "
         // IF gVrstaRS == "K"
         // ? Space( 4 )
         // ENDIF
         ?? Str( nPlacNije, 12, 2 ), Str( nPlacJest, 12, 2 ) + " "
         ?? Str( nStanje, 12, 2 )
         nSumaSt += nStanje
         fPisi := .T.
         ? REPL( "-", 80 )
         ++nBrojacPartnera
      ENDIF
      nSumaNije += nPlacNije
      nSumaJest += nPlacJest
      SELECT pos_doks
      IF cSpec == "D" .AND. fPisi
         GO nPrviRec
         nBrojacStavki := 1
         DO WHILE !Eof() .AND. pos_doks->IdGost == cIdGost

            IF ( pos_doks->datum < dDatOd .OR. pos_doks->datum > dDat )
               SKIP
               LOOP
            ENDIF

            IF !Empty( cVrstP )
               IF ( pos_doks->IdVrsteP <> cVrstP )
                  SKIP
                  LOOP
               ENDIF
            ENDIF

            // SELECT POS
            // SEEK pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )
            seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )
            nDuguje := 0
            nPotrazuje := 0
            DO WHILE !Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

               IF pos_doks->IdVrsteP == "01"

                  nPom := pos->kolicina * pos->cijena * iif( pos->idvd == "00", - 1, 1 )
                  // placanje gotovinom povecava promet na obje strane
                  nDuguje += nPom
                  nPotrazuje += nPom
               ELSEIF ( Left( idroba, 5 ) == 'PLDUG' )
                  // ako je placanje, dug je negativan
                  // za poc stanje promjeni znak ????
                  nPotrazuje += POS->Kolicina * POS->Cijena * iif( pos->idvd = '00', - 1, 1 )

               ELSE
                  // veresija
                  nDuguje += POS->Kolicina * POS->Cijena * iif( pos->idvd = '00', - 1, 1 )
               ENDIF
               SKIP
            ENDDO

            SELECT pos_doks
            ? AllTrim( Str( nBrojacStavki ) ) + " " + PadL( pos_doks->idvd, 4 ) + " " + PadR( AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), 9 ), FormDat1( pos_doks->Datum )
            ++nBrojacStavki
            ?? " " + pos_doks->IdVrsteP + "       "
            ?? Str( nDuguje, 12, 2 ), Str( nPotrazuje, 12, 2 )
            SKIP
         ENDDO
         ?
      ENDIF
      IF !Empty( cGost )
         EXIT
      ENDIF
   ENDDO

   IF Empty( cGost )
      // IF gVrstaRS == "K"
      // nDuz := 25
      // ELSE
      nDuz := 35 + 1 + 10 + 1 + 10
      // ENDIF
      ? REPL( "=", nDuz ), REPL( "=", 14 )
      ? PadL( "Ukupno placeno:", nDuz ), Str( nSumaJest, 14, 2 )
      ? PadL( "UKUPNO NEPLACENO:", nDuz ), Str( nSumaNije, 14, 2 )
      ? PadL( "STANJE UKUPNO:", nDuz ), Str( nSumaSt, 14, 2 )
      ? REPL( "=", nDuz ), REPL( "=", 14 )
   ENDIF

   // IF gVrstaRS <> "S"
   //PaperFeed()
   // ENDIF

   ENDPRINT

   CLOSERET
