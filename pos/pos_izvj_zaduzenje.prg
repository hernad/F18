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


FUNCTION pos_stampa_zaduzenja( cIdVd, cBrDok )

   LOCAL nPrevRec
   LOCAL cKoje
   LOCAL nFinZad
   LOCAL fPred := .F.
   LOCAL aTarife := {}
   LOCAL nPPP
   LOCAL nPPU
   LOCAL nOsn
   LOCAL nPP

   nPPP := 0
   nPPU := 0
   nOsn := 0
   nPP := 0

   SELECT PRIPRZ

   IF RecCount2() > 0

      nPrevRec := RecNo()

      GO TOP

      START PRINT CRET
      ?

      cPom := ""

      NaslovDok( cIdVd )

      IF cIdVD == "16"
         IF !Empty( IdDio )
            cPom += "PREDISPOZICIJA "
            fPred := .T.
         ELSE
            cPom += "ZADUŽENJE "
         ENDIF
      ENDIF

      IF cIdvd == "PD"
         cPom += "PREDISPOZICIJA "
         fpred := .T.
      ENDIF

      IF cIdVd == "98"
         cPom += "REKLAMACIJA "
      ENDIF

      cPom += AllTrim( PRIPRZ->IdPos ) + "-" + AllTrim ( cBrDok )

      IF fpred
         ? PadC( "PRENOS IZ ODJ: " + idodj + "  U ODJ:" + idvrstep, 38 )
      ENDIF

      ? PadC( cPom, 40 )
      ? PadL ( FormDat1 ( PRIPRZ->Datum ), 39 )
      ?

      IF gZadCij == "D"
         ? " Sifra      Naziv            JMJ Kolicina"
         ? "---------- ----------------- --- --------"
         ? "           Nabav.vr.*   PPP   *    MPC   "
         ? "           --------- --------- ----------"
         ? "           MPV-porez*   PPU   *    MPV   "
         ? "-----------------------------------------"
      ELSE
         ? " Sifra      Naziv            JMJ Kolicina"
         ? "---------- ----------------- --- --------"
      ENDIF

      nFinZad := 0
      SELECT PRIPRZ
      GoTop2()
      DO WHILE ! Eof()

         nIzn := cijena * kolicina
         pos_setuj_tarife( IdRoba, nIzn, @aTarife, @nPPP, @nPPU, @nOsn, @nPP )
         IF fpred .AND. !Empty( IdDio )
            // ne stampaj nista
         ELSE
            ? idroba, PadR ( RobaNaz, 17 ), JMJ, ;
               Transform ( Kolicina, "99999.99" )
            IF gZadCij == "D"
               ? Space( 10 ), Transform( ncijena * kolicina, "999999.99" ), Transform ( nPPP, "999999.99" ), Transform ( cijena, "9999999.99" )
               ? Space( 10 ), Transform( nOsn, "999999.99" ),             Transform ( nPPU, "999999.99" ), Transform ( cijena * kolicina, "9999999.99" )
               ? "-----------------------------------------"
            ENDIF
         ENDIF
         nFinZad += PRIPRZ->( Kolicina * Cijena )

         SKIP 1

      ENDDO

      ? "-------- ----------------- --- --------"
      ?U PadL ( "UKUPNO ZADUŽENJE (" + Trim ( gDomValuta ) + ")", 29 ), ;
         TRANS ( nFinZad, "999,999.99" )
      ? "-------- ----------------- --- --------"

      pos_rekapitulacija_tarifa( aTarife )

      ? " Primio " + PadL ( "Predao", 31 )
      ?
      ? PadL ( AllTrim ( gKorIme ), 39 )

      ENDPRINT

      o_pos_priprz()
      GO nPrevRec

   ELSE
      MsgBeep ( "Zaduženje nema nijedne stavke!", 20 )
   ENDIF

   RETURN



// -------------------------------------------------------------
// stampa dokumenta zaduzenja
// -------------------------------------------------------------
FUNCTION PrepisZad( cNazDok )

   LOCAL fPred := .F.
   LOCAL nSir := 80
   LOCAL nRobaSir := 40
   LOCAL cLm := Space ( 5 )
   LOCAL cPicKol := "999999.999"
   LOCAL aTarife := {}
   LOCAL cRobaNaStanju := "N"
   LOCAL cLine
   LOCAL cLine2
   LOCAL nDbfArea := Select()

   START PRINT CRET


   nSir := 40
   nRobaSir := 18
   cLM := ""
   cPicKol := "9999.999"

   seek_pos_pos( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->BrDok )

   IF !Empty( pos_doks->idvrstep )
      // predispozicija
      fPred := .T.
      cNazDok := "PREDISPOZICIJA "
   ENDIF

   cNazDok := cNazDok + " "

   ? PadC( cNazDok + iif( Empty( pos_doks->IdPos ), "", AllTrim( pos_doks->IdPos ) + "-" ) + ;
      AllTrim( pos_doks->BrDok ), nSir )

   select_o_pos_odj( POS->IdOdj )

   // IF !Empty( POS->IdDio )
   // SELECT DIO
   // --  HSEEK POS->IdDio
   // ENDIF

   SELECT POS
   IF fpred
      ? PadC( "PRENOS IZ ODJ: " + pos->idodj + "  U ODJ:" + pos_doks->idvrstep, nSir )
   ELSE
      ? PadC ( iif ( !Empty ( POS->IdDio ), "-" + AllTrim ( DIO->Naz ), "" );
         , nSir )
   ENDIF

   ? PadC ( FormDat1 ( pos_doks->Datum ), nSir )
   ?

   // setuj linije...
   // cLine = artikal, kolicina ....
   // cLine2 = ------- --------- ...
   _get_line( @cLine, @cLine2 )

   ? cLM + cLine
   ? cLM + cLine2

   nFinZad := 0
   SELECT POS
   DO WHILE ! Eof() .AND. POS->( IdPos + IdVd + DToS( datum ) + BrDok ) == pos_doks->( IdPos + IdVd + DToS( datum ) + BrDok )

      IF fPred  // predispozicija
         IF !Empty( IdDio )
            SKIP
            LOOP
         ENDIF
      ENDIF

      ? cLM
      IF Len( Trim( idroba ) ) > 8
         ?? IdRoba, ""
      ELSE
         ?? PadR( IdRoba, 8 ), ""
      ENDIF

      select_o_roba( POS->IdRoba )
      ?? PadR ( _field->Naz, nRobaSir ), _field->Jmj, ""
      SELECT POS

      ?? TRANS ( POS->Kolicina, cPicKol )
      nFinZad += POS->( Kolicina * Cijena )

      pos_setuj_tarife( pos->IdRoba, POS->( Kolicina * Cijena ), @aTarife )
      SKIP
   ENDDO

   ? cLine2
   ? cLM


   ?? PadL( "IZNOS DOKUMENTA ", 11  + nRobaSir ), TRANS ( nFinZad, "9,999,999.99" )
   ? cLine2
   ?

   pos_rekapitulacija_tarifa( aTarife )

   ?? " Primio", PadL ( "Predao", nSir - 9 )

   select_o_pos_osob( pos_doks->IdRadnik )

   ? PadL ( AllTrim ( OSOB->Naz ), nSir - 9 )

   //PaperFeed()

   ENDPRINT

   SELECT ( nDbfArea )

   RETURN .T.


// ----------------------------------------------
// setovanje linije za podvlacenje
// ----------------------------------------------
STATIC FUNCTION _get_line( cLine, cLine2 )

   cLine := PadR( "Sifra", 10 ) + " "
   cLine2 := Replicate( "-", 10 ) + " "

   cLine += PadR( "Naziv", 18 ) + " "
   cLine2 += Replicate( "-", 18 ) + " "

   cLine += PadR( "JMJ", 3 ) + " "
   cLine2 += Replicate( "-", 3 ) + " "

   cLine += PadR( "Kolicina", 8 )
   cLine2 += Replicate( "-", 8 )

   RETURN .T.
