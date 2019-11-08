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


FUNCTION pos_stampa_racuna( cIdPos, cBrDok, lPrepis, cIdVrsteP, dDatumRn, aVezani )

   LOCAL cDbf
   LOCAL cIdRadnik
   LOCAL aPom := {}
   LOCAL cPom
   PRIVATE nIznos
   PRIVATE nSumaPor := 0

   IF lPrepis == NIL
      lPrepis := .F.
   ENDIF

   IF cIdVrsteP == NIL
      cIdVrsteP := ""
   ENDIF

   IF dDatumRn == NIL
      dDatumRn := gDatum
   ENDIF

   SELECT ( F_ODJ )

   IF !Used()
      o_pos_odj()
   ENDIF

   IF lPrepis
      cPosDB := "POS"
   ELSE
      cPosDB := "_POS"
   ENDIF

   SELECT &cPosDB

   cCmnBrDok := cBrDok
   nIznos := 0
   nNeplaca := 0

   FOR i := 1 TO Len( aVezani )

      //
      dDatumRn := aVezani[ i, 4 ]
      cBrDok := aVezani[ i, 2 ]

      Seek2( cIdPos + POS_VD_RACUN + DToS( dDatumRn ) + cBrDok )

      IF !lPrepis
         cSto := &cPosDB->Sto
         cIdRadnik := &cPosDB->IdRadnik
         cSmjena := &cPosDB->Smjena
      ELSE
         SELECT pos_doks
         Seek2 ( cIdPos + POS_VD_RACUN + DToS( dDatumRn ) + cBrDok )
         cSto      := pos_doks->Sto
         cIdRadnik := pos_doks->IdRadnik
         cSmjena   := pos_doks->Smjena
      ENDIF

      SELECT &cPosDB

      IF VarPopPrekoOdrIzn()
         gIsPopust := .F.
      ENDIF

      DO WHILE !Eof() .AND. &cPosDB->( IdPos + IdVd + DToS( Datum ) + BrDok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatumRn ) + cBrDok )

         nIznos += Kolicina * Cijena

         select_o_pos_odj( &cPosDB->idodj )
         SELECT &cPosDB

         // IF Right( odj->naz, 5 ) == "#1#0#"
         // nNeplaca += Kolicina * Cijena - ncijena * Kolicina
         // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
         // nNeplaca += Kolicina * Cijena / 2 - ncijena
         // ENDIF

         // IF ( gPopVar == "P" )
         nNeplaca += kolicina * NCijena
         // ENDIF

         SKIP
      ENDDO

      //
   NEXT
   //


   ispisi_iznos_racuna_box( nIznos - nNeplaca )

   STARTPRINTPORT CRET gLocPort, Space( 5 )

   cBrDok := cCmnBrDok

   IF lPrepis
      cTime := RacHeder( cIdPos, DToS( dDatumRn ) + cBrDok, cSto, .T., aVezani )
   ELSE
      cTime := RacHeder( cIdPos, DToS( dDatumRn ) + cStalRac, cSto, .F., aVezani )
   ENDIF

   seek_pos_db( cPosDb, cIdPos, "42", dDatumRn, cBrDok )


   aPorezi := {}
   aRekPor := {}

   DO WHILE !Eof() .AND. ( IdPos + IdVd + DToS( datum ) ) == ( cIdPos + POS_VD_RACUN + DToS( dDatumRn ) )

      IF AScan( aVezani, {| aVal | aVal[ 2 ] == &cPosDB->brdok } ) == 0
         SKIP
         LOOP
      ELSE
         cBrDok := &cPosDB->brdok
      ENDIF

      cPom := " * "
      Scatter()
      _Kolicina := 0
      DO WHILE !Eof() .AND. &cPosDB->( IdPos + IdVd + DToS( datum ) + BrDok ) == ( cIdPos + "42" + DToS( dDatumRn ) + cBrDok ) .AND. &cPosDB->( IdRoba + IdCijena ) == ( _IdRoba + IdCijena ) .AND. &cPosDB->Cijena == _Cijena
         _Kolicina += &cPosDB->Kolicina
         SKIP
      ENDDO
      nIznosST := 0
      IF Round( _kolicina, 4 ) <> 0
         IF !lPrepis
            cPom += Trim( _IdRoba ) + " - " + Trim( _RobaNaz )
         ELSE
            select_o_roba( Trim( _idRoba ) )
            cPom += Trim( _idRoba ) + " - " + Trim( roba->naz )
            SELECT pos
         ENDIF
         aPom := SjeciStr( cPom, 38 )
         FOR i := 1 TO Len( aPom )
            ? aPom[ i ]
         NEXT
         SELECT &cPosDB

         nIznosSt := _Kolicina * ( _Cijena - _NCijena )

         IF gKolDec == N_ROUNDTO
            ? Space( 1 ) + PadR( "(T" + AllTrim( _IdTarifa ) + ")", 6 ) + Str( _Kolicina, 9, N_ROUNDTO ), if( !lPrepis, _Jmj, roba->jmj ), "x "
         ELSE
            ? Space( 1 ) + PadR( "(T" + AllTrim( _IdTarifa ) + ")", 6 ) + Str( _Kolicina, 9, gKolDec ), if( !lPrepis, _Jmj, roba->jmj ), "x "
         ENDIF
         IF gCijDec == N_ROUNDTO
            ?? PadR( AllTrim( Str( _Cijena, 8, N_ROUNDTO ) ), 8 ) + Str( nIznosSt, 8, N_ROUNDTO )
         ELSE
            ?? PadR( AllTrim( Str( _Cijena, 8, gCijDec ) ), 8 ) + Str( nIznosSt, 8, N_ROUNDTO )
         ENDIF
      ENDIF

      select_o_tarifa( _IdTarifa )

      IF glPorezNaSvakuStavku
         nPPP := tarifa->opp
         nPPU := tarifa->ppp
         nPP := tarifa->zpp
      ENDIF
      // Izracunaj MPC bez poreza
      nMPVBP := nIznosSt / ( 1 + zpp / 100 + ppp / 100 ) / ( 1 + opp / 100 )


      set_pdv_array( @aPorezi )
      aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, nMPVBP, nIznosSt, 0 )
      ? " PPP(" + Str( nPPP, 2, 0 ) + "%)" + AllTrim( Str( Round( aIPor[ 1 ], 2 ) ) )
      ?? " PPU(" + Str( nPPU, 2, 0 ) + "%)" + AllTrim( Str( Round( aIPor[ 2 ], 2 ) ) )
      ?? " PP(" + Str( nPP, 2, 0 ) + "%)" + AllTrim( Str( Round( aIPor[ 3 ], 2 ) ) )
      nSumaPor += aIPor[ 1 ] + aIPor[ 2 ] + aIPor[ 3 ]
      nPoz := AScan( aRekPor, {| x | x[ 1 ] == _IdTarifa } )
      IF nPoz == 0
         AAdd( aRekPor, { _idtarifa, aIPor[ 1 ], aIPor[ 2 ], aIPor[ 3 ], aIPor[ 1 ] + aIPor[ 2 ] + aIPor[ 3 ] } )
      ELSE
         aRekPor[ nPoz ][ 2 ] += aIPor[ 1 ]
         aRekPor[ nPoz ][ 3 ] += aIPor[ 2 ]
         aRekPor[ nPoz ][ 4 ] += aIPor[ 3 ]
      ENDIF


      SELECT &cPosDB
   ENDDO

   seek_pos_db( cPosDb, cIdPos, "42", dDatumRn, cBrDok )
   DO WHILE !Eof() .AND. &cPosDB->( IdPos + IdVd + DToS( datum ) + BrDok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatumRn ) + cBrDok )
      REPLACE m1 WITH "S" // odstampano
      SKIP
   ENDDO
   // iznos racuna
   ? " " + Replicate( "=", 38 )
   ? PadL( "UKUPNO (" + gDomValuta + ")", 30 ), iif( nIznos >= 0, Transform( nIznos, "****9.99" ), Transform( nIznos, "99999.99" ) )

   IF nNeplaca <> 0 // postoji oslobadjanje
      ?
      ? " " + Replicate ( "-", 38 )
      ? PadL ( "  POPUST: (" + gDomValuta + ")", 30 ), Transform ( nNeplaca, "99999.99" )
      ? " " + Replicate ( "=", 38 )
      ? PadL ( "NAPLATITI (" + gDomValuta + ")", 30 ), iif( nIznos - nNePlaca >= 0, Transform ( nIznos - nNeplaca, "****9.99" ), Transform( nIznos - nNePlaca, "99999.99" ) )
   ENDIF
   ? " " + Replicate ( "=", 38 )
   IF !Empty( gStrValuta )
      ?
      ? PadL ( "UKUPNO (" + gStrValuta + ")", 30 ), iif ( nIznos >= 0, Transform ( StrValuta( gStrValuta, pos_doks->datum ) * nIznos, "****9.99" ), Transform( StrValuta( gStrValuta, pos_doks->datum ) * nIznos, "99999.99" ) )
      ? " " + Replicate ( "=", 38 )
   ENDIF

   // porezi
   // stari obracun poreza


  // IF gPoreziRaster == "D"
  //    POSRekapTar( aRekPor )
  // ENDIF


   RacFuter( cIdRadnik, cSmjena )
   ENDPRN2 13
   SkloniIznRac()

   RETURN ( cTime )



/* RacHeder(cIdPos,dDatBrDok,cSto,fPrepis, aVezani)
 */

FUNCTION RacHeder( cIdPos, dDatBrDok, cSto, fPrepis, aVezani )

   //
   // 1            2               3              4
   // aVezani : {pos_doks->IdPos, pos_doks->(BrDok), pos_doks->IdVrsteP, pos_doks->Datum})
   // fprepis - .t. - vrsi se prepis racuna

   LOCAL cStr
   LOCAL cTime
   LOCAL nCnt
   LOCAL cJedan
   LOCAL dDat

   cStr := MemoRead( my_home() + AllTrim( gRnHeder ) )

   IF ! Empty ( cStr )
      QQOut ( cStr )
      ?
   ENDIF

   ?? PadC ( "RACUN br. " + AllTrim ( cIdPos ) + "-" + AllTrim ( SubStr( dDatBrDok, 9 ) ), 40 )

   IF fPrepis
      IF !glRetroakt
         ? PadC ( "PREPIS", 40 )
      ENDIF
      IF Len( aVezani ) > 1
         ? PadC( "ZBIRNI", 40 )
      ENDIF
      cStr := Space( 16 )
      FOR nCnt := 2 TO Len ( aVezani )
         cJedan := AllTrim ( aVezani[ nCnt ][ 1 ] ) + "-" + AllTrim ( aVezani[ nCnt ][ 2 ] )
         IF Len ( cStr ) + Len ( cJedan ) < 38
            cStr += cJedan + ", "
         ELSE
            cStr += Chr ( 13 ) + Chr( 10 ) + Space ( 16 ) + cJedan
         ENDIF
      NEXT
      IF !Empty ( cStr )
         ? " Vezani racuni: " + LTrim ( cStr )
      ENDIF
      nPrev := SELECT ()
      // SELECT poßs_doks
      // HSEEK (cIdPos+POS_VD_RACUN+dDatBrDok)
      seek_pos_doks( cIdPos, POS_VD_RACUN, dDatBrDok )
      cTime := pos_doks->Vrijeme
      cDat  := DToC ( pos_doks->Datum )
      SELECT ( nPrev )
   ELSE
      cTime := Left ( Time(), 5 )
      cDat := DToC ( gDatum )
   ENDIF


   cStoStr := Space ( 8 )

   ? " " + cDat + "." + Space ( 8 ) + cStoStr + Space ( 8 ) + cTime
   ? " " + Replicate ( "-", 38 )

   RETURN ( cTime )


/* RacFuter(cIdRadnik,cSmjena)
 */

FUNCTION RacFuter( cIdRadnik, cSmjena )

   LOCAL cStr

   ? " " + Replicate ( "-", 38 )
   // SELECT OSOB
   // SET ORDER TO TAG "NAZ"
   // HSEEK cIdRadnik
   find_pos_osob_by_naz( cIdRadnik )
   ? " " + PadR ( AllTrim ( OSOB->Naz ), 29 ), "Smjena " + cSmjena
   cStr := MemoRead ( my_home() + AllTrim ( gRnFuter ) )
   IF !Empty( cStr )
      QOut( cStr )
   ENDIF
   PaperFeed ()
   gOtvorStr()

   RETURN .T.



FUNCTION seek_pos_db( cPosDb, cIdPos, cIdVD, dDatumRn, cBrDok )

   IF cPosDB == "_POS"
      SELECT &cPosDB

      SEEK cIdPos + cIdVd + DToS( dDatumRn ) + cBrDok // _POS
      RETURN Found()
   ENDIF

   // POS

   RETURN seek_pos_pos( cIdPos, cIdVD, dDatumRn, cBrDok )



FUNCTION pos_stampa_priprema( cIdPos, dDatBrDok, fEkran, lViseOdjednom, lOnlyFill )

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

   // SELECT pos_doks
   // SET ORDER TO TAG "1"
   // seek_pos_doks( cIdPos, POS_VD_RACUN, dDatBrDok )

   // nTRk := RecNo()

   cSto := pos_doks->Sto
   cIdRadnik := pos_doks->IdRadnik
   cSmjena := pos_doks->Smjena


   // SELECT pos

   nIznos := 0
   nNeplaca := 0

   FOR nCnt := 1 TO Len( aVezani )
      // SELECT pos_doks
      // SEEK ( aVezani[ nCnt ][ 1 ] + POS_VD_RACUN + DToS( aVezani[ nCnt ][ 4 ] ) + aVezani[ nCnt ][ 2 ] )
      // seek_pos_doks ( aVezani[ nCnt ][ 1 ], POS_VD_RACUN, aVezani[ nCnt ][ 4 ],  aVezani[ nCnt ][ 2 ] )

      // SELECT pos
      // SEEK ( aVezani[ nCnt ][ 1 ] + POS_VD_RACUN + DToS( aVezani[ nCnt ][ 4 ] ) + aVezani[ nCnt ][ 2 ] )
      seek_pos_pos( aVezani[ nCnt ][ 1 ], POS_VD_RACUN, aVezani[ nCnt ][ 4 ],  aVezani[ nCnt ][ 2 ] )
      DO WHILE !Eof() .AND. pos->( IdPos + IdVd + DToS( datum ) + BrDok ) == ( aVezani[ nCnt ][ 1 ] + POS_VD_RACUN + DToS( aVezani[ nCnt ][ 4 ] ) + aVezani[ nCnt ][ 2 ] )


         // select pom
         // seek POS->IdRoba+POS->IdCijena+STR (POS->Cijena, 10, 3)
         // if Found()
         // replace Kolicina WITH Kolicina+POS->Kolicina
         // else
         // Append Blank
         // replace IdRoba WITH POS->IdRoba
         // replace IdCijena WITH POS->IdCijena
         // replace Cijena WITH POS->Cijena
         // replace Kolicina WITH POS->Kolicina
         // replace NCijena WITH pos->ncijena
         // replace datum WITH pos->datum
         // endif
         // select pos

         nIznos += pos->( kolicina * cijena )
         select_o_pos_odj( pos->idodj )
         SELECT POS
         // IF Right( odj->naz, 5 ) == "#1#0#"
         // nNeplaca += pos->( Kolicina * Cijena - ncijena * Kolicina )
         // ELSEIF Right( odj->naz, 6 ) == "#1#50#"
         // nNeplaca += pos->( Kolicina * Cijena / 2 - ncijena )
         // ENDIF
         // IF gPopVar = "P"
         nNeplaca += pos->( kolicina * ncijena )
         // ENDIF
         SKIP
      ENDDO
   NEXT

   // SELECT pos_doks
   // GO nTrk
   SELECT pos


   pos_stampa_racuna_pdv( cIdPos, pos_doks->brdok, .T., pos_doks->idvrstep, pos_doks->datum, aVezani, lViseOdjednom, lOnlyFill )

   RETURN .T.


/*

   IF fEkran
      IF !lViseOdjednom
         START PRINT CRET
      ENDIF
   ELSE
      ispisi_iznos_racuna_box( nIznos - nNeplaca )
      STARTPRINTPORT CRET gLocPort, Space ( 5 )
   ENDIF

   RacHeder ( cIdPos, dDatBrDok, cSto, .T., aVezani )

   SELECT POM
   GO TOP
   DO WHILE ! Eof()
      cPom := " * "
      select_o_roba( POM->IdRoba )

      cPom += Trim( POM->IdRoba ) + " - " + Trim( roba->Naz )
      aPom := SjeciStr( cPom, 38 )
      FOR i := 1 TO Len( aPom )
         ? aPom[ i ]
      NEXT

      _idTarifa := roba->IdTarifa
      cJmj := roba->JMJ

      SELECT POM
      nIznosSt := POM->( Kolicina * ( Cijena - NCijena ) )
      // uzeti u obzir popust !!!!

      IF gKolDec == N_ROUNDTO
         ? Space ( 1 ) + PadR ( "(T" + AllTrim ( _IdTarifa ) + ")", 6 ) + Str ( POM->Kolicina, 9, N_ROUNDTO ), cJmj, "x "
      ELSE
         ? Space ( 1 ) + PadR ( "(T" + AllTrim ( _IdTarifa ) + ")", 6 ) + Str ( POM->Kolicina, 9, gKolDec ), cJmj, "x "
      ENDIF

      IF gCijDec == N_ROUNDTO
         ?? PadR ( AllTrim ( Str ( POM->Cijena, 8, N_ROUNDTO ) ), 8 ) + Str ( nIznosSt, 8, N_ROUNDTO )
      ELSE
         ?? PadR ( AllTrim ( Str ( POM->Cijena, 8, gCijDec ) ), 8 ) + Str ( nIznosSt, 8, N_ROUNDTO )
      ENDIF

      select_o_tarifa( _IdTarifa )

      IF glPorezNaSvakuStavku
         nPPP := tarifa->opp
         nPPU := tarifa->ppp
      ENDIF

      IF my_get_from_ini( "POREZI", "PPUgostKaoPPU", "N" ) == "D"
         nMpVBP := nIznosSt / ( 1 + zpp / 100 + ppp / 100 ) / ( 1 + opp / 100 )
         nPPPIznos := nMPVBP * opp / 100
         nPPIznos := ( nMPVBP + nPPPIznos ) * zpp / 100
      ELSE
         nMpVBP := nIznosSt / ( zpp / 100 + ( 1 + opp / 100 ) * ( 1 + ppp / 100 ) )
         nPPPIznos := nMPVBP * opp / 100
         nPPIznos := nMPVBP * zpp / 100
      ENDIF

      IF glPorezNaSvakuStavku
         ? Space( 1 ) + "PPP(" + AllTrim( Str( nPPP ) ) + "%) " + AllTrim( Str( nPPPIznos ) )
      ENDIF

      nPPUIznos := ( nMPVBP + nPPPIznos ) * ppp / 100

      IF glPorezNaSvakuStavku
         ?? " PPU(" + AllTrim( Str( nPPU ) ) + "%) " + AllTrim( Str( nPPUIznos ) )
      ENDIF

      nSumaPor += nPPPiznos + nPPUiznos + nPPIznos

      nPoz := AScan ( aPorezi, {| x | x[ 1 ] == _IdTarifa } )
      IF nPoz == 0
         AAdd( aPorezi, { _IdTarifa, nPPPiznos, nPPUiznos, nPPIznos, { opp, ppp, zpp } } )
      ELSE
         aPorezi[ nPoz ][ 2 ] += nPPPiznos
         aPorezi[ nPoz ][ 3 ] += nPPUiznos
         aPorezi[ nPoz ][ 4 ] += nPPiznos
      ENDIF

      SELECT POM
      SKIP
   ENDDO

   // iznos racuna
   ? " " + Replicate ( "=", 38 )
   ? PadL ( "UKUPNO (" + gDomValuta + ")", 30 ), ;
      iif ( nIznos >= 0, Transform ( nIznos, "****9.99" ), ;
      Transform ( nIznos, "99999.99" ) )


   IF nNeplaca <> 0 // postoji oslobadjanje
      ?
      ? " " + Replicate ( "-", 38 )
      ? PadL ( "  POPUST: (" + gDomValuta + ")", 30 ), Transform ( nNeplaca, "99999.99" )
      ? " " + Replicate ( "=", 38 )
      ? PadL ( "NAPLATITI (" + gDomValuta + ")", 30 ), ;
         iif ( nIznos - nNePlaca >= 0, Transform ( nIznos - nNeplaca, "****9.99" ), ;
         Transform ( nIznos - nNePlaca, "99999.99" ) )
   ENDIF

   ? " " + Replicate ( "=", 38 )
   IF !Empty( gStrValuta )
      ?
      ? PadL ( "UKUPNO (" + gStrValuta + ")", 30 ), ;
         iif ( nIznos >= 0, Transform ( StrValuta( gStrValuta, pos_doks->datum ) * nIznos, "****9.99" ), ;
         Transform ( StrValuta( gStrValuta, pos_doks->datum ) * nIznos, "99999.99" ) )
      ? " " + Replicate ( "=", 38 )
   ENDIF

   // porezi
--   IF gPoreziRaster == "D"
      ASort ( aPorezi,,, {| x, y | x[ 1 ] < y[ 1 ] } )
      fPP := .F. // ima posebnog poreza
      FOR i := 1 TO Len ( aPorezi )
         IF Round( aPorezi[ i, 4 ], 4 ) <> 0
            fPP := .T.
            EXIT
         ENDIF
      NEXT
      ? " T.br.        PPP       PPU      Iznos"
      IF fPP
         ? "               PP"
      ENDIF
      nPPP := nPPU := 0
      nPP := 0
      FOR nCnt := 1 TO Len ( aPorezi )

         ? " T" + PadR( aPorezi[ nCnt ][ 1 ], 4 )
         ?? " (PPP " + Str( aPorezi[ nCnt ][ 5 ][ 1 ], 2, 0 ) + "%, PPU " + Str( aPorezi[ nCnt ][ 5 ][ 2 ], 2, 0 ) + IF( !fPP, "%)   ", "%, PP " + Str( aPorezi[ nCnt ][ 5 ][ 3 ], 2, 0 ) + "%)" )
         ? Space( 10 )

         ?? Str ( aPorezi[ nCnt ][ 2 ], 7, N_ROUNDTO ) + "   " + ;
            Str ( aPorezi[ nCnt ][ 3 ], 7, N_ROUNDTO ) + "    " + ;
            Str ( Round( aPorezi[ nCnt ][ 2 ], N_ROUNDTO ) + ;
            Round( aPorezi[ nCnt ][ 3 ], N_ROUNDTO ) + ;
            Round( aPorezi[ nCnt ][ 4 ], N_ROUNDTO ), 7, N_ROUNDTO )
         IF Round( aPorezi[ nCnt ][ 4 ], 4 ) <> 0
            ? Space( 10 ) + Str ( aPorezi[ nCnt ][ 4 ], 7, N_ROUNDTO )
         ENDIF
         nPPP += Round( aPorezi[ nCnt ][ 2 ], N_ROUNDTO )
         nPPU += Round( aPorezi[ nCnt ][ 3 ], N_ROUNDTO )
         nPP += Round( aPorezi[ nCnt ][ 4 ], N_ROUNDTO )
      NEXT
      ? " " + Replicate ( "-", 38 )
      ? " UKUPNO   " + ;
         Str ( nPPP, 7, N_ROUNDTO ) + "   " + ;
         Str ( nPPU, 7, N_ROUNDTO ) + "    " + ;
         Str ( nPPP + nPPU + nPP, 7, N_ROUNDTO )
      IF fPP
         ? "          " + ;
            Str ( nPP, 7, N_ROUNDTO )
      ENDIF
   ELSE
      ?? LTrim ( Str ( nSumaPor, 8, N_ROUNDTO ) ), gDomValuta
   ENDIF


   RacFuter( cIdRadnik, cSmjena )

   IF fEkran
      IF !lViseOdjednom
         ENDPRINT
      ENDIF
   ELSE
      ENDPRN2 13
      SkloniIznRac()
   ENDIF

   */

SELECT pos_doks

   RETURN .T.


FUNCTION pos_racun_info( cBrRn )

   info_bar( "pos", "POS račun broj: " + cBrRN )

   RETURN .T.



/* StampaRekap(cIdRadnik, cBrojStola)
 *     Stampa rekapitulacije racuna


--FUNCTION StampaRekap( cIdRadnik, cBrojStola, dDatumOd, dDatumDo )

   LOCAL nRecNoTrenutni
   LOCAL nRecNoNext
   PRIVATE aGrupni

   cZakljucen := "N"

   SELECT pos_doks
   SET ORDER TO TAG "8"
   GO TOP
   SEEK gIdPos + cIdRadnik + cZakljucen

   aGrupni := {}

   nTek := 0
   nCnt := 0

   DO WHILE !Eof() .AND. field->idpos == gIdPos .AND. field->idradnik == cIdRadnik .AND. field->datum <= dDatumDo .AND. field->datum >= dDatumOd

      IF field->zakljucen <> "N"
         SKIP
         LOOP
      ENDIF

      IF ( field->sto <> cBrojStola )
         SKIP
         LOOP
      ENDIF
      // markiraj ga kao zakljucen sa Z
      IF ( field->zakljucen == "N" )

         ++nCnt

         IF nTek == 0
            nTek := RecNo()
         ENDIF

         AAdd( aGrupni, { pos_doks->idpos, pos_doks->brdok, pos_doks->idvrstep, pos_doks->datum } )

         nTRec := RecNo()
         SKIP
         nNNRec := RecNo()
         SKIP -1
         REPLACE field->zakljucen WITH "Z"

         GO nNNRec
      ENDIF
   ENDDO

   GO nTek

   IF nCnt == 0
      MsgBeep( "Ne postoje otvoreni racuni za stol br." + cBrojStola )
      RETURN .F.
   ENDIF

--   pos_stampa_priprema( gIdPos, DToS( aGrupni[ 1, 4 ] ) + aGrupni[ 1, 2 ], aGrupni, .F., .F. )

   RETURN .T.


FUNCTION StampaNezakljRN( cIdRadnik, dDatumOd, dDatumDo )

   START PRINT CRET

   cZaklj := "N"

   SELECT pos_doks
   SET ORDER TO TAG "8"
   GO TOP

   SEEK gIdPos + cIdRadnik + cZaklj

   ? Space( 2 ),  Date()
   ? Space( 2 ) + "Nezakljuceni racuni:"
   ? Space( 2 ) + "----------------------"
   ?
   ? Space( 2 ) + "Rn.Br.       Sto"
   ? Space( 2 ) + "----------------"


   DO WHILE !Eof() .AND. field->idpos == gIdPos .AND. field->idradnik == cIdRadnik .AND. field->datum <= dDatumDo .AND. field->datum >= dDatumOd
      IF field->zakljucen <> "N"
         SKIP
         LOOP
      ENDIF
      cBrDok := pos_doks->brdok
      cIdPos := pos_doks->idpos
      cBrojStola := pos_doks->sto

      ? Space( 2 ) + AllTrim( cIdPos ) + "-" + AllTrim( cBrDok ) + "  -> " + AllTrim( cBrojStola )
      SKIP
   ENDDO

   FF
   ENDPRINT

   SELECT pos_doks
   SET ORDER TO TAG "1"

   RETURN



FUNCTION SetujZakljuceno()

   // {
   LOCAL nCounter

   IF !spec_funkcije_sifra( "RNZAK" )
      MsgBeep( "Nemate ovlastenja za koristenje opcije!!!" )
      RETURN
   ENDIF

   IF Pitanje(, "Setovati sve racune na zakljuceno (D/N) ?", "N" ) == "N"
      RETURN
   ENDIF

   IF Pitanje(, "Sto posto sigurni da zelite (D/N) ?", "N" ) == "N"
      RETURN
   ENDIF

   SELECT pos_doks
   SET ORDER TO TAG 0
   GO TOP

   nCounter := 0

   DO WHILE !Eof()
      REPLACE field->zakljucen WITH "Z"
      ++nCounter
      SKIP
   ENDDO

   MsgBeep( "Setovano ukupno " + AllTrim( Str( nCounter ) ) + " racuna!!!" )

   RETURN

*/

FUNCTION gvars_fill()

   // prikaz cijene sa pdv, bez pdv
   add_drntext( "P20", AllTrim( Str( grbCjen ) ) )
   // stampa id robe na racunu
   add_drntext( "P21", grbStId )
   // redukcija trake
   add_drntext( "P22", AllTrim( Str( grbReduk ) ) )

   RETURN .T.


FUNCTION firma_params_fill()

   add_drntext( "I01", gFirNaziv )
   add_drntext( "I02", gFirAdres )
   add_drntext( "I03", gFirIdBroj )
   add_drntext( "I04", gFirPM )
   add_drntext( "I05", gFirTel )

   RETURN .T.



FUNCTION fill_rb_traka( cIdPos, cBrDok, dDatRn, lPrepis, aRacuni, cTime )

   LOCAL cPosDB
   LOCAL dDatumRn
   LOCAL cSto
   LOCAL cIdRadnik
   LOCAL cSmjena
   LOCAL cIdRoba
   LOCAL cIdTarifa
   LOCAL cRobaNaz
   LOCAL nRbr

   // rn vars
   LOCAL nCjenBPDV
   LOCAL nCjenPDV
   LOCAL nKolicina
   LOCAL nPopust
   LOCAL nCjen2BPDV
   LOCAL nCjen2PDV
   LOCAL nVPDV
   LOCAL nPPDV
   LOCAL nUkupno
   LOCAL cJmj
   // drn vars
   LOCAL nUBPDV
   LOCAL nUPDV
   LOCAL nUPopust
   LOCAL nUBPDVPopust
   LOCAL nUTotal
   LOCAL nCSum
   LOCAL cRdnkNaz := ""
   LOCAL aPPs
   LOCAL cBrStola
   LOCAL nZakBr := 0
   LOCAL nFZaokr := 0

   // o_pos_tables()
   close_open_racun_tbl()
   zap_racun_tbl()

   firma_params_fill()

   gvars_fill()

   IF lPrepis == .T.
      SELECT pos
   ELSE
      SELECT _pos_pripr
   ENDIF

   // checksum
   nCSum := 0

   // matrica aRacuni moze da sadrzi vise racuna, u svakom slucaju sadrzi 1 racun
   // aRacuni : {pos_doks->IdPos, pos_doks->(BrDok), pos_doks->IdVrsteP, pos_doks->Datum})

   nUkupno := 0
   nUkStavka := 0
   nUBPDV := 0
   nUPDV := 0
   nUPopust := 0
   nUBPDVPopust := 0
   nUTotal := 0

   FOR i := 1 TO Len( aRacuni )

      dDatRn := aRacuni[ i, 4 ]
      cBrDok := aRacuni[ i, 2 ]

      IF lPrepis == .T.
         cStalRac := cBrDok
      ENDIF

      IF lPrepis == .T.
         seek_pos_pos( cIdPos, POS_VD_RACUN, dDatRn, cBrDok )
      ELSE
         SELECT _pos_pripr
         SET ORDER TO TAG "1"
         GO TOP
         SEEK cIdPos + POS_VD_RACUN + DToS( dDatRn ) + cBrDok
      ENDIF


      // MsgBeep( _pos->brdok + "," + cIdPos + "," + POS_VD_RACUN + "," + cBrDok + "," + DTOS( dDatRn ) )

      IF !lPrepis
         cSto := _pos->sto
         cIdRadnik := _pos->idradnik
         cSmjena := _pos->smjena
         cTime := Left( Time(), 5 )
         cVrstaP := _pos->idvrstep

      ELSE

         seek_pos_dokspf( cIdPos, POS_VD_RACUN, cBrDok, dDatRn )    // nadji parametre kupca

         SELECT pos_doks
         // seek_Seek2( cIdPos + POS_VD_RACUN + DToS( dDatRn ) + cBrDok )

         cSto := pos_doks->sto
         cIdRadnik := pos_doks->idRadnik
         cSmjena := pos_doks->smjena
         cTime := pos_doks->vrijeme
         cVrstaP := pos_doks->idvrstep

      ENDIF

      // SELECT osob
      // SET ORDER TO TAG "NAZ"
      // HSEEK cIdRadnik
      find_pos_osob_by_naz( cIdRadnik )
      cRdnkNaz := osob->naz


      IF !select_o_vrstep( cVrstaP )

         // IF !Found()
         cNazVrstaP := "GOTOVINA"
      ELSE
         cNazVrstaP := AllTrim( vrstep->naz )
      ENDIF

      IF lPrepis == .T.
         SELECT pos
      ELSE
         SELECT _pos_pripr
      ENDIF

      DO WHILE !Eof() .AND. iif( lPrepis == .T., pos->( idpos + idvd + DToS( datum ) + brdok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatRn ) + cBrDok ), ;
            _pos->( idpos + idvd + DToS( datum ) + brdok ) == ( cIdPos + POS_VD_RACUN + DToS( dDatRn ) + cBrDok ) )

         nCjenBPDV := 0
         nCjenPDV := 0
         nKolicina := 0
         nPopust := 0
         nCjen2BPDV := 0
         nCjen2PDV := 0
         nPDV := 0
         nIznPop := 0

         cIdRoba := field->idroba
         cIdTarifa := field->idtarifa

         select_o_roba( cIdRoba )
         cJmj := roba->jmj
         cRobaNaz := AllTrim( roba->naz )

         select_o_tarifa( cIdTarifa )
         nPPDV := tarifa->opp

         nStPP := 0

         IF lPrepis == .T.
            SELECT pos
         ELSE
            SELECT _pos_pripr
         ENDIF

         nKolicina := kolicina
         nCjenPDV :=  cijena
         nCjenBPDV := nCjenPDV / ( 1 + ( nPPDV + nStPP ) / 100 )

         // popust - ovo treba jos dobro pregledati
         // DO CASE
         // CASE gPopVar = "P"
         nIznPop := field->ncijena
         // ENDCASE

         nPopust := 0

         IF Round( nIznPop, 4 ) <> 0

            // cjena 2 : cjena sa pdv - iznos popusta
            nCjen2PDV := nCjenPDV - nIznPop

            // cjena 2 : cjena bez pdv - iznos popusta bez pdv
            nCjen2BPDV := nCjenBPDV - ( nIznPop / ( 1 + nPPDV / 100 ) )

            // procenat popusta
            nPopust := ( ( nIznPop / ( 1 + nPPDV / 100 ) ) / nCjenBPDV ) * 100

         ENDIF

         // izracunaj ukupno za stavku
         nUkupno := ( nKolicina * nCjenPDV ) - ( nKolicina * nIznPop )

         // izracunaj ukupnu vrijednost pdv-a
         nVPDV := ( ( nKolicina * nCjenBPDV ) - ( nKolicina * ( nIznPop / ( 1 + nPPDV / 100 ) ) ) ) * ( nPPDV / 100 )

         // ukupno bez pdv-a
         nUBPDV += nKolicina * nCjenBPDV
         // ukupno pdv
         nUPDV += nVPDV
         // total racuna
         nUTotal += nUkupno

         IF Round( nCjen2BPDV, 2 ) <> 0
            // ukupno popust
            nUPopust += ( nCjenBPDV - nCjen2BPDV ) * nKolicina
         ENDIF

         // ukupno bez pdv-a - popust
         nUBPDVPopust := nUBPDV - nUPopust

         IF grbCjen == 2
            nUkStavka := nUkupno
         ELSE
            nUkStavka := nUBPDVPopust
         ENDIF

         ++nCSum

         dodaj_stavku_racuna( cStalRac, Str( nCSum, 3 ), "", cIdRoba, cRobaNaz, cJmj, nKolicina, Round( nCjenPDV, 3 ), Round( nCjenBPDV, 3 ), Round( nCjen2PDV, 3 ), Round( nCjen2BPDV, 3 ), Round( nPopust, 2 ), Round( nPPDV, 2 ), Round( nVPDV, 3 ), Round( nUkStavka, 3 ), 0, 0 )

         IF lPrepis == .T.
            SELECT pos
         ELSE
            SELECT _pos_pripr
         ENDIF

         SKIP

      ENDDO

   NEXT

   aPPs := nil

   // dodaj zapis u drn.dbf
   add_drn( cStalRac, dDatRn, NIL, NIL, cTime, Round( nUBPDV, 2 ), Round( nUPopust, 2 ), Round( nUBPDVPopust, 2 ), Round( nUPDV, 2 ), Round( nUTotal - nFZaokr, 2 ), nCSum, 0, nFZaokr, 0 )

   // mjesto nastanka racuna
   add_drntext( "R01", gRnMjesto )
   // dodaj naziv radnika
   add_drntext( "R02", cRdnkNaz )
   // dodaj podatak o smjeni
   add_drntext( "R03", cSmjena )
   // vrsta placanja
   add_drntext( "R05", cNazVrstaP )
   // dodatni text na racunu 3 linije
   add_drntext( "R06", gRnPTxt1 )
   add_drntext( "R07", gRnPTxt2 )
   add_drntext( "R08", gRnPTxt3 )
   // Broj linija potrebnih da se ocjepi traka
   add_drntext( "P12", AllTrim( Str( nFeedLines ) ) )
   // sekv.za otvaranje ladice
   add_drntext( "P13", gOtvorStr )
   // sekv.za cjepanje trake
   add_drntext( "P14", gSjeciStr )



   // ako je prepis
   IF lPrepis == .T.
      // podaci o kupcu
      add_drntext( "K01", dokspf->knaz )
      add_drntext( "K02", dokspf->kadr )
      add_drntext( "K03", dokspf->kidbr )
      add_drntext( "D01", "A" )
   ELSE
      // dodaj D01 - P - priprema
      add_drntext( "D01", "P" )
   ENDIF

   RETURN .T.




FUNCTION pos_stampa_racuna_pdv( cIdPos, cBrDok, lPrepis, cIdVrsteP, dDatumRn, aRacuni, lViseOdjednom, lOnlyFill )

   LOCAL cTime

   IF ( lOnlyFill == NIL )
      lOnlyFill := .F.
   ENDIF

   IF ( lPrepis == NIL )
      lPrepis := .F.
   ENDIF

   IF ( cIdVrsteP == NIL )
      cIdVrsteP := ""
   ENDIF

   IF ( dDatumRn == NIL )
      dDatumRn := gDatum
   ENDIF

   // napuni tabele podacima
   fill_rb_traka( cIdPos, cBrDok, dDatumRn, lPrepis, aRacuni, @cTime )

   lStartPrint := .T.
   IF lViseOdjednom == .T.
      lStartPrint := .F.
   ENDIF


   IF lOnlyFill  // ako je samo punjenje tabela - ovdje se zaustavi
      RETURN .T.
   ENDIF

   IF !fiscal_opt_active() // fiskalni racun - ne stampati !
      pos_racun_print( lStartPrint )
   ENDIF

   RETURN cTime
