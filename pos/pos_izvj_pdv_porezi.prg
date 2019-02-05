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

      AAdd ( aNiz, { "Prod.mjesto (prazno-svi)    ", "cIdPos", "cIdPos='X' .or. empty(cIdPos).or.p_pos_kase(cIdPos)", "@!", } )


      AAdd ( aNiz, { "Tarife (prazno sve)", "cTarife",, "@S10", } )
      AAdd ( aNiz, { "Izvjestaj se pravi od datuma", "dDatum0",,, } )
      AAdd ( aNiz, { "                   do datuma", "dDatum1",,, } )

      DO WHILE .T.
         IF !VarEdit( aNiz, 10, 5, 17, 74, 'USLOVI ZA IZVJESTAJ "POREZI PO TARIFAMA"', "B1" )
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
      // ZagFirma()

   ENDIF // fsolo


   DO WHILE .T.

      // petlja radi popusta
      aTarife := {}  // inicijalizuj matricu tarifa

      IF fSolo
         // ?? gP12cpi

         IF cNaplaceno == "3"
            ?U PadC( "**** OBRAČUN ZA NAPLAĆENI IZNOS ****", LEN_TRAKA )
         ENDIF

         ?U PadC( "POREZI PO TARIFAMA NA DAN " + FormDat1( danasnji_datum() ), LEN_TRAKA )
         ?U PadC( "-------------------------------------", LEN_TRAKA )
         ?
         ? "PROD.MJESTO: "

         ?? cIdPos + "-"
         IF ( Empty( cIdPos ) )
            ?? "SVA"
         ELSE
            ?? cIdPos + "-" + AllTrim ( find_pos_kasa_naz( cIdPos ) )
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

      // SELECT POS
      // SET ORDER TO TAG "1"
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
      // filuj za poreze, VD_PRR - realizacija iz predhodnih sezona
      aTarife := Porezi( POS_VD_RACUN, dDatum0, aTarife, cNaplaceno )
      aTarife := Porezi( VD_PRR, dDatum0, aTarife, cNaplaceno )

      ASort ( aTarife,,, {| x, y | x[ 1 ] < y[ 1 ] } )

      ? m
      ? "Tarifa (Stopa %)"
      ? PadL ( "MPV bez PDV", 12 ), PadL ( "PDV", 12 ), PadL( "MPV sa PDV", 12 )
      ? m

      FOR nCnt := 1 TO Len( aTarife )

         select_o_tarifa( aTarife[ nCnt ][ 1 ] )
         nPDV := tarifa->opp
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
