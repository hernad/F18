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


FUNCTION PorPoTar

   PARAMETERS dDatum0, dDatum1, cIdPos, cNaplaceno, cIdOdj

   LOCAL aNiz := {}
   LOCAL fSolo
   LOCAL aTarife := {}

   PRIVATE cTarife := Space ( 30 )
   PRIVATE aUsl := ".t."

   IF cNaplaceno == nil
      cNaplaceno := "1"
   ENDIF

   IF ( PCount() == 0 )
      fSolo := .T.
   ELSE
      fSolo := .F.
   ENDIF

   IF fSolo
      PRIVATE dDatum0 := gDatum
      PRIVATE dDatum1 := gDatum
      PRIVATE cIdPos := Space( 2 )
      PRIVATE cNaplaceno := "1"
   ENDIF

   IF ( cIdOdj == NIL )
      cIdOdj := Space( 2 )
   ENDIF

   // otvaranje potrebnih baza
   // o_tarifa()

   IF fSolo
      // o_sifk()
      // o_sifv()
      // o_pos_kase()
      // o_roba()
      o_pos_odj()
      o_pos_kumulativne_tabele()
   ENDIF

   cIdPos := gIdPos

   IF fSolo

      AAdd ( aNiz, { "Prod.mjesto (prazno-svi)    ", "cIdPos", "cIdPos='X' .or. empty(cIdPos).or.p_pos_kase(cIdPos)", "@!", } )

    //  IF gVodiOdj == "D"
      //   AAdd ( aNiz, { "Odjeljenje (prazno-sva)", "cIdOdj", ".t.", "@!", } )
      //ENDIF

      AAdd ( aNiz, { "Tarife (prazno sve)", "cTarife",, "@S10", } )
      AAdd ( aNiz, { "Izvjestaj se pravi od datuma", "dDatum0",,, } )
      AAdd ( aNiz, { "                   do datuma", "dDatum1",,, } )

      DO WHILE .T.

         IF !VarEdit( aNiz, 10, 5, 17, 74, 'USLOVI ZA IZVJESTAJ "POREZI PO TARIFAMA"', "B1" )
            CLOSERET
         ENDIF
         aUsl := Parsiraj( cTarife, "IdTarifa" )
         IF aUsl <> NIL .AND. dDatum0 <= dDatum1
            EXIT
         ELSEIF aUsl == nil
            MsgBeep ( "Kriterij za tarife nije korektno postavljen!" )
         ELSE
            Msg( "'Datum do' ne smije biti stariji nego 'datum od'!" )
         ENDIF
      ENDDO

      // pravljenje izvjestaja
      START PRINT CRET
      // ZagFirma()

   ENDIF // fsolo


   DO WHILE .T.

      // petlja radi popusta
      aTarife := {}  // inicijalizuj matricu tarifa

      IF fSolo
         ?? gP12cpi

         IF cNaplaceno == "3"
            ? PadC( "**** OBRACUN ZA NAPLACENI IZNOS ****", 40 )
         ENDIF

         ? PadC( "POREZI PO TARIFAMA NA DAN " + FormDat1( gDatum ), 40 )
         ? PadC( "-------------------------------------", 40 )
         ?
         ? "PROD.MJESTO: "


         ?? cIdPos + "-"
         IF ( Empty( cIdPos ) )
            ?? "SVA"
         ELSE
            ?? cIdPos + "-" + AllTrim ( find_pos_kasa_naz( cIdPos ) )
         ENDIF

         IF !Empty( cIdOdj )
            ? "  Odjeljenje:", cIdOdj
         ENDIF

         ? "      Tarife:", iif ( Empty ( cTarife ), "SVE", cTarife )
         ? "PERIOD: " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )
         ?

      ELSE // fsolo
         ?
         IF cNaplaceno == "3"
            ? PadC( "**** OBRACUN ZA NAPLACENI IZNOS ****", 40 )
         ENDIF
         ? PadC ( "REKAPITULACIJA POREZA PO TARIFAMA", 40 )
         ? PadC ( "---------------------------------", 40 )
         ?
      ENDIF // fsolo

      SELECT POS
      SET ORDER TO TAG "1"

      PRIVATE cFilter := ".t."

      IF !( aUsl == ".t." )
         cFilter += ".and." + aUsl
      ENDIF

      IF !Empty( cIdOdj )
         cFilter += ".and. IdOdj=" + dbf_quote( cIdOdj )
      ENDIF

      IF !( cFilter == ".t." )
         SET FILTER TO &cFilter
      ENDIF

      SELECT pos_doks
      SET ORDER TO TAG "2"

      nTotOsn := 0
      nTotPPP := 0
      nTotPPU := 0
      nTotPP := 0

      m := Replicate( "-", 6 ) + " " + Replicate( "-", 10 ) + " " + Replicate( "-", 8 ) + " " + Replicate( "-", 8 )

      nTotOsn := 0
      nTotPPP := 0
      nTotPPU := 0

      // matrica je lok var : aTarife:={}
      // filuj za poreze, VD_PRR - realizacija iz predhodnih sezona
      aTarife := Porezi( POS_VD_RACUN, dDatum0, aTarife, cNaplaceno )
      aTarife := Porezi( VD_PRR, dDatum0, aTarife, cNaplaceno )

      ASort ( aTarife,,, {| x, y | x[ 1 ] < y[ 1 ] } )
      fPP := .F.

      FOR nCnt := 1 TO Len( aTarife )
         IF Round( aTarife[ nCnt ][ 5 ], 4 ) <> 0
            fPP := .T.
         ENDIF
      NEXT

      ? m
      ? "Tarifa", PadC ( "MPV B.P.", 10 ), PadC ( "P P P", 8 ), PadC ( "P P U", 8 )
      ? "      ", PadC ( "- MPV -", 10 ), PadC( "", 9 )

      IF fPP
         ?? PadC ( " P P  ", 8 )
      ENDIF

      ? m
      FOR nCnt := 1 TO Len( aTarife )
         select_o_tarifa( aTarife[ nCnt ][ 1 ] )
         nPPP := tarifa->opp
         nPPU := tarifa->ppp
         SELECT pos_doks

         // ispisi opis i na realizaciji kao na racunu
         ? aTarife[ nCnt ][ 1 ], "(PPP:" + Str( nPPP ) + "%, ", "PPU:" + Str( nPPU ) + "%)"

         ? aTarife[ nCnt ][ 1 ], Str( aTarife[ nCnt ][ 2 ], 10, 2 ), Str( aTarife[ nCnt ][ 3 ], 8, 2 ), Str( aTarife[ nCnt ][ 4 ], 8, 2 )

         // ? space(6), STR( round(aTarife[nCnt][2],2)+;
         // round(aTarife[nCnt][3],2)+;
         // round(aTarife[nCnt][4],2)+;
         // round(aTarife[nCnt][5],2), 10,2),;
         // space(9)

         ? Space( 6 ), Str( Round( aTarife[ nCnt ][ 6 ], 2 ), 10, 2 ), Space( 9 )

         IF fPP
            ?? Str( aTarife[ nCnt ][ 5 ], 8, 2 )
         ENDIF

         // nTotOsn += round(aTarife [nCnt][2],2)
         nTotOsn += Round( aTarife[ nCnt ][ 6 ], 2 ) - Round( aTarife[ nCnt ][ 3 ], 2 ) - Round( aTarife[ nCnt ][ 4 ], 2 ) - Round( aTarife[ nCnt ][ 5 ], 2 )
         nTotPPP += Round( aTarife[ nCnt ][ 3 ], 2 )
         nTotPPU += Round( aTarife[ nCnt ][ 4 ], 2 )
         nTotPP += Round( aTarife[ nCnt ][ 5 ], 2 )
      NEXT

      ? m
      ? "UKUPNO", Str ( nTotOsn, 10, 2 ), Str ( nTotPPP, 8, 2 ), Str ( nTotPPU, 8, 2 )
      ? Space( 6 ), Str( nTotOsn + nTotPPP + nTotPPU + nTotPP, 10, 2 ), Space( 9 )

      IF fPP
         ?? Str( nTotPP, 8, 2 )
      ENDIF

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

   PaperFeed ()


   IF fSolo
      ENDPRINT
   ENDIF

   SET FILTER TO
   CLOSERET



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

            IF roba->( FieldPos( "idodj" ) ) <> 0
               select_o_pos_odj( roba->idodj )
            ENDIF

            nNeplaca := 0

            // IF Right( odj->naz, 5 ) == "#1#0#"  // proba!!!
            // nNeplaca := pos->( Kolicina * Cijena )
            // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
            // nNeplaca := pos->( Kolicina * Cijena ) / 2
            // ENDIF

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



/*
FUNCTION POSRekapTar( aRekPor )

   LOCAL lPP
   LOCAL nPPP
   LOCAL nPPU
   LOCAL nPP
   LOCAL nCnt
   LOCAL nArr

   nArr := Select()


   ASort( aRekPor,,, {| x, y | x[ 1 ] < y[ 1 ] } )
   lPP := .F. // ima posebnog poreza

   FOR i := 1 TO Len( aRekPor )
      IF Round( aRekPor[ i, 4 ], 4 ) <> 0
         lPP := .T.
         EXIT
      ENDIF
   NEXT

   ? " U iznos uracunati porezi "
   ? " T.br.    PPP     PPU     PP     Iznos"

   nPPP := 0
   nPPU := 0
   nPP := 0

   FOR nCnt := 1 TO Len( aRekPor )
      ? " T" + PadR( aRekPor[ nCnt ][ 1 ], 4 )
      select_o_tarifa( aRekPor[ nCnt, 1 ] )
      ?? " (PPP " + Str( tarifa->opp, 2, 0 ) + "%,PPU " + Str( tarifa->ppp, 2, 0 ) + "%,PP " + Str( tarifa->zpp, 2, 0 ) + "%)"
      SELECT ( nArr )
      ? Space( 6 )
      ?? " " + Str( aRekPor[ nCnt ][ 2 ], 7, N_ROUNDTO ) + " " + Str( aRekPor[ nCnt ][ 3 ], 7, N_ROUNDTO ) + " " + Str( aRekPor[ nCnt ][ 4 ], 7, N_ROUNDTO ) + " "
      ?? Str( Round( aRekPor[ nCnt ][ 2 ], N_ROUNDTO ) + Round( aRekPor[ nCnt ][ 3 ], N_ROUNDTO ) + Round( aRekPor[ nCnt ][ 4 ], N_ROUNDTO ), 7, N_ROUNDTO )
      nPPP += Round( aRekPor[ nCnt ][ 2 ], N_ROUNDTO )
      nPPU += Round( aRekPor[ nCnt ][ 3 ], N_ROUNDTO )
      nPP += Round( aRekPor[ nCnt ][ 4 ], N_ROUNDTO )
   NEXT

   // stampaj ukupno
   ? " " + Replicate ( "-", 38 )
   ? " UKUPNO" + Str( nPPP, 7, N_ROUNDTO ) + " " + Str( nPPU, 7, N_ROUNDTO ) + " " + Str( nPP, 7, N_ROUNDTO ) + " " + Str( nPPP + nPPU + nPP, 7, N_ROUNDTO )

   RETURN .T.
*/
