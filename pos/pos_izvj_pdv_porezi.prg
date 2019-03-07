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

MEMVAR m

STATIC LEN_TRAKA := 40

FUNCTION pos_pdv_po_tarifama

   PARAMETERS dDatum0, dDatum1, cIdPos, cNaplaceno

   LOCAL aNiz := {}
   LOCAL fSolo
   LOCAL aTarife := {}

   PRIVATE cTarife := Space ( 30 )
   PRIVATE cFilterTarifa := ".t."

   IF cNaplaceno == nil
      cNaplaceno := "1"
   ENDIF

   IF ( PCount() == 0 )
      fSolo := .T.
   ELSE
      fSolo := .F.
   ENDIF

   IF fSolo
      PRIVATE dDatum0 := danasnji_datum()
      PRIVATE dDatum1 := danasnji_datum()
      PRIVATE cIdPos := Space( 2 )
      PRIVATE cNaplaceno := "1"
   ENDIF

   cIdPos := gIdPos

   IF fSolo

      AAdd ( aNiz, { "Tarife (prazno sve)", "cTarife",, "@S10", } )
      AAdd ( aNiz, { "Izvještaj se pravi od datuma", "dDatum0",,, } )
      AAdd ( aNiz, { "                   do datuma", "dDatum1",,, } )

      DO WHILE .T.
         IF !VarEdit( aNiz, 10, 5, 17, 74, 'USLOVI ZA IZVJEŠTAJ "Prikaz PDV"', "B1" )
            CLOSERET
         ENDIF
         cFilterTarifa := Parsiraj( cTarife, "IdTarifa" )
         IF cFilterTarifa <> NIL .AND. dDatum0 <= dDatum1
            EXIT
         ELSEIF cFilterTarifa == nil
            MsgBeep ( "Kriterij za tarife nije korektno postavljen!" )
         ELSE
            Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
         ENDIF
      ENDDO

      START PRINT CRET


   ENDIF // fsolo


   DO WHILE .T.

      // petlja radi popusta
      aTarife := {}  // inicijalizuj matricu tarifa

      IF fSolo
         // ?? gP12cpi

         IF cNaplaceno == "3"
            ?U PadC( "**** OBRAČUN ZA NAPLAĆENI IZNOS ****", LEN_TRAKA )
         ENDIF

         ?U PadC( "PDV PO TARIFAMA NA DAN " + FormDat1( danasnji_datum() ), LEN_TRAKA )
         ?U PadC( "-------------------------------------", LEN_TRAKA )
         ?
         ? "PROD.MJESTO: "

         ?? cIdPos + "-"
         IF ( Empty( cIdPos ) )
            ?? "SVA"
         ELSE
            ?? cIdPos
         ENDIF


         ? "     Tarife:", iif ( Empty ( cTarife ), "SVE", cTarife )
         ? "PERIOD: " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )
         ?

      ELSE // fsolo
         ?
         IF cNaplaceno == "3"
            ?U PadC( "**** OBRAČUN ZA NAPLAĆENI IZNOS ****", LEN_TRAKA )
         ENDIF
         ? PadC ( "REKAPITULACIJA POREZA PO TARIFAMA", LEN_TRAKA )

      ENDIF // fsolo


      seek_pos_pos( cIdPos )

      PRIVATE cFilter := ".t."

      IF !( cFilterTarifa == ".t." )
         cFilter += ".and." + cFilterTarifa
      ENDIF

      IF !( cFilter == ".t." )
         SET FILTER TO &cFilter
      ENDIF


      m := Replicate( "-", 12 ) + " " + Replicate( "-", 12 ) + " " + Replicate( "-", 12 )

      nTotOsn := 0
      nTotPDV := 0

      // matrica je lok var : aTarife:={}
      aTarife := pos_pdv_napuni_pom( POS_IDVD_RACUN, dDatum0, aTarife, cNaplaceno )

      ASort ( aTarife,,, {| x, y | x[ 1 ] < y[ 1 ] } )

      ? m
      ? "Tarifa (Stopa %)"
      ? PadL ( "MPV bez PDV", 12 ), PadL ( "PDV", 12 ), PadL( "MPV sa PDV", 12 )
      ? m

      FOR nCnt := 1 TO Len( aTarife )

         select_o_tarifa( aTarife[ nCnt ][ 1 ] )
         nPDV := tarifa->pdv
         // SELECT pos_doks

         // ispisi opis i na realizaciji kao na racunu
         ? aTarife[ nCnt ][ 1 ], "(" + Str( nPDV ) + "%)"

         ? Str( aTarife[ nCnt ][ 2 ], 12, 2 ), Str( aTarife[ nCnt ][ 3 ], 12, 2 ), Str( Round( aTarife[ nCnt ][ 6 ], 2 ), 12, 2 )
         nTotOsn += Round( aTarife[ nCnt ][ 6 ], 2 ) - Round( aTarife[ nCnt ][ 3 ], 2 )
         nTotPDV += Round( aTarife[ nCnt ][ 3 ], 2 )
      NEXT

      ? m
      ? "UKUPNO:"
      ? Str ( nTotOsn, 12, 2 ), Str ( nTotPDV, 12, 2 ), Str( nTotOsn + nTotPDV, 12, 2 )
      ? m
      ?
      ?

      IF !fsolo
         EXIT
      ENDIF

      IF cNaplaceno == "1"  // prvi krug u dowhile petlji
         cNaplaceno := "3"
      ELSE
         // vec odradjen drugi krug
         EXIT
      ENDIF

   ENDDO // petlja radi popusta

   SELECT pos
   SET FILTER TO

   IF fSolo
      ENDPRINT
   ENDIF

   CLOSE ALL

   RETURN .T.




STATIC FUNCTION pos_pdv_napuni_pom( cIdVd, dDatum0, aTarife, cNaplaceno )

   IF cNaplaceno == nil
      cNaplaceno := "1"
   ENDIF


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
            nIzn := pos->( Cijena * kolicina )


         ENDIF

         SELECT POS

         nOsn := nIzn / ( 1 + tarifa->pdv / 100 )
         nPDV := nOsn * tarifa->pdv / 100
         nPoz := AScan( aTarife, {| x | x[ 1 ] == POS->IdTarifa } )

         IF nPoz == 0
            AAdd( aTarife, { POS->IdTarifa, nOsn, nPDV, nIzn } )
         ELSE
            aTarife[ nPoz ][ 2 ] += nOsn
            aTarife[ nPoz ][ 3 ] += nPDV
            aTarife[ nPoz ][ 4 ] += nIzn
         ENDIF

         SKIP
      ENDDO

      SELECT pos_doks
      SKIP
   ENDDO

   RETURN aTarife
