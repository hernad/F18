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


FUNCTION kalk_sumiraj_kolicinu( nUlaz, nIzlaz, nTotalUlaz, nTotalIzlaz, lPocStanje, lPrikazK2 )

   IF lPocStanje == nil
      lPocStanje := .F.
   ENDIF

   IF lPrikazK2 == nil
      lPrikazK2 := .F.
   ENDIF

   nTotalUlaz += nUlaz
   nTotalIzlaz += nIzlaz

   RETURN .T.



FUNCTION kalk_cre_tabela_kalk_rekap1( cVarijanta )

   LOCAL _table := "kalk_rekap1"

   aDbf := { { "idroba","C", 10, 0 }, ;
      { "objekat","C", 7,0 }, ;
      { "G1","C", 4,0 }, ;
      { "idtarifa", "C", 6,0 }, ;
      { "mpc",    "N", 10,2 }, ;
      { "k1", "N", 9 + gDecKol, gDecKol }, ;
      { "k2", "N", 9 + gDecKol, gDecKol }, ;
      { "k4pp", "N", 9 + gDecKol, gDecKol } ;
      }

   IF ( cVarijanta == "2" )
      // nisu samo kolicine interesantne
      AAdd( adbf, { "novampc", "N", 10,2 } )
      AAdd( adbf, { "k0", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k3", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k4", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k5", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k6", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k7", "N", 9 + gdeckol, gDecKol } )
      AAdd( adbf, { "k8", "N", 9 + gdeckol, gDecKol } )

      AAdd( adbf, { "f0", "N", 18, 3 }  )
      AAdd( adbf,  { "f1", "N", 18, 3 } )
      AAdd( adbf,  { "f2", "N", 18, 3 } )
      AAdd( adbf,  { "f3", "N", 18, 3 } )
      AAdd( adbf,  { "f4", "N", 18, 3 } )
      AAdd( adbf,  { "f5", "N", 18, 3 } )
      AAdd( adbf,  { "f6", "N", 18, 3 } )
      AAdd( adbf,  { "f7", "N", 18, 3 } )
      AAdd( adbf,  { "f8", "N", 18, 3 } )
   ENDIF

   // novampc - ako nadjes 19-ku na dDatDo onda je nova cijena
   // F0 - pocetno stanje zaliha
   // f1 - tekuca prodaja, f2 trenutna zaliha, f3 - kumulativna prodaja
   // f4 - prijem u toku mjeseca
   // f6 - izlaz iz prodavnice po ostalim osnovama
   // f5 - reklamacije u toku mjeseca, f7 - reklamacije u toku godine
   // f8 -

   my_close_all_dbf()

   FErase( my_home() + _table + ".dbf" )
   FErase( my_home() + _table + ".cdx" )

   dbCreate( my_home() + _table + ".dbf", aDbf )

   SELECT ( F_REKAP1 )
   my_use_temp( "REKAP1", my_home() + _table, .F., .T. )

   INDEX ON objekat + idroba TAG "1"
   INDEX ON g1 + idtarifa + idroba + objekat TAG "2"
   SET ORDER TO TAG "1"

   my_close_all_dbf()

   RETURN .T.



FUNCTION CreTblRek2()

   LOCAL aDbf
   LOCAL _table := "kalk_rekap2"

   aDbf := { { "objekat","C", 7,0 }, ;
      { "G1","C", 4,0 }, ;
      { "idtarifa", "C", 6,0 }, ;
      { "MJESEC",  "N", 2,0 }, ;
      { "GODINA", "N", 4,0 }, ;
      { "ZALIHAK", "N", 16, 2 }, ;
      { "ZALIHAF", "N", 16, 2 }, ;
      { "NABAVK", "N", 16, 2 }, ;
      { "NABAVF", "N", 16, 2 }, ;
      { "PNABAVK", "N", 16, 2 }, ;
      { "PNABAVF", "N", 16, 2 }, ;
      { "STANJEK", "N", 16, 2 }, ;
      { "STANJEF", "N", 16, 2 }, ;
      { "STANJRK", "N", 16, 2 }, ;
      { "STANJRF", "N", 16, 2 }, ;
      { "PRODAJAK", "N", 16, 2 }, ;
      { "PRODAJAF", "N", 16, 2 }, ;
      { "PROSZALK", "N", 16, 2 }, ;
      { "PROSZALF", "N", 16, 2 }, ;
      { "ORUCF", "N", 16, 2 }, ;
      { "OMPRUCF", "N", 16, 2 }, ;
      { "POVECANJE", "N", 16, 2 }, ;
      { "SNIZENJE", "N", 16, 2 } ;
      }

   my_close_all_dbf()

   FErase( my_home() + _table + ".dbf" )
   FErase( my_home() + _table + ".cdx" )

   dbCreate( my_home() + _table + ".dbf", aDbf )

   SELECT( F_REKAP2 )
   my_use_temp( "REKAP2", my_home() + _table + ".dbf", .F., .T. )

   INDEX ON Str( godina ) + Str( mjesec ) + objekat TAG "1"
   INDEX ON Str( godina ) + Str( mjesec ) + g1 + objekat TAG "2"
   INDEX ON g1 + Str( godina ) + Str( mjesec ) TAG "3"
   SET ORDER TO TAG "2"


   aDbf := { { "G1","C", 4,0 }, ;
      { "idtarifa", "C", 6,0 }, ;
      { "ZALIHAK", "N", 16, 2 }, ;
      { "ZALIHAF", "N", 16, 2 }, ;
      { "NABAVK", "N", 16, 2 }, ;
      { "NABAVF", "N", 16, 2 }, ;
      { "PNABAVK", "N", 16, 2 }, ;
      { "PNABAVF", "N", 16, 2 }, ;
      { "STANJEK", "N", 16, 2 }, ;
      { "STANJEF", "N", 16, 2 }, ;
      { "STANJRF", "N", 16, 2 }, ;
      { "STANJRK", "N", 16, 2 }, ;
      { "PRODAJAK", "N", 16, 2 }, ;
      { "PRODAJAF", "N", 16, 2 }, ;
      { "PROSZALK", "N", 16, 2 }, ;
      { "PROSZALF", "N", 16, 2 }, ;
      { "PRODKUMK", "N", 16, 2 }, ;
      { "PRODKUMF", "N", 16, 2 }, ;
      { "ORUCF", "N", 16, 2 }, ;
      { "OMPRUCF", "N", 16, 2 }, ;
      { "POVECANJE", "N", 16, 2 }, ;
      { "SNIZENJE", "N", 16, 2 }, ;
      { "KOBRDAN", "N", 16, 9 }, ;
      { "GKOBR", "N", 18, 9 } ;
      }

   _table := "kalk_reka22"

   FErase( my_home() + _table + ".dbf" )
   FErase( my_home() + _table + ".cdx" )

   dbCreate( my_home() + _table + ".dbf", aDbf )

   SELECT( F_REKA22 )
   my_use_temp( "REKA22", my_home() + _table + ".dbf", .F., .T. )

   INDEX ON g1 TAG "1"
   SET ORDER TO TAG "1"

   my_close_all_dbf()

   RETURN .T.



/* CrePPProd()
 *     Kreiraj tabelu kalk_ppprod
 *  sa tbl_kalk_ppprod
 *


FUNCTION CrePPProd()

   LOCAL cTblName
   LOCAL aTblCols

   cTblName := "kalk_ppprod"

   aTblCols := {}

   AAdd( aTblCols, { "idKonto", "C", 7, 0 } )
   AAdd( aTblCols, { "pari1", "N", 10, 0 } )
   AAdd( aTblCols, { "pari2", "N", 10, 0 } )
   AAdd( aTblCols, { "pari", "N", 10, 0 } )
   AAdd( aTblCols, { "bruto1", "N", 12, 2 } )
   AAdd( aTblCols, { "bruto2", "N", 12, 2 } )
   AAdd( aTblCols, { "bruto", "N", 14, 2 } )
   AAdd( aTblCols, { "neto1", "N", 12, 2 } )
   AAdd( aTblCols, { "neto2", "N", 12, 2 } )
   AAdd( aTblCols, { "neto", "N", 14, 2 } )
   AAdd( aTblCols, { "polog01", "N", 12, 2 } )
   AAdd( aTblCols, { "polog02", "N", 12, 2 } )
   AAdd( aTblCols, { "polog03", "N", 12, 2 } )
   AAdd( aTblCols, { "polog04", "N", 12, 2 } )
   AAdd( aTblCols, { "polog05", "N", 12, 2 } )
   AAdd( aTblCols, { "polog06", "N", 12, 2 } )
   AAdd( aTblCols, { "polog07", "N", 12, 2 } )
   AAdd( aTblCols, { "polog08", "N", 12, 2 } )
   AAdd( aTblCols, { "polog09", "N", 12, 2 } )
   AAdd( aTblCols, { "polog10", "N", 12, 2 } )
   AAdd( aTblCols, { "polog11", "N", 12, 2 } )
   AAdd( aTblCols, { "polog12", "N", 12, 2 } )

   my_close_all_dbf()

   FErase( my_home() + cTblName + ".dbf" )
   FErase( my_home() + cTblName + ".cdx" )

   dbCreate( my_home() + cTblName + ".dbf", aTblCols )

   SELECT ( F_PPPROD )
   my_use_temp( "PPPROD", my_home() + cTblName + ".dbf", .F., .T. )

   INDEX ON idkonto TO "konto"

   RETURN
*/



FUNCTION kalk_gen_rekap_2( lK2X, cC, lPrDatOd, lVpRab )

   LOCAL lMagacin
   LOCAL lProdavnica

   IF ( lK2X == nil )
      lK2X := .F.
   ENDIF

   IF ( cC == nil )
      cC := "P"
   ENDIF

   IF ( lVpRab == nil )
      lVpRab := .T.
   ENDIF

   find_kalk_by_mkonto_idroba_idvd( self_organizacija_id(), NIL, NIL, qqRoba, "idkonto,idroba" )

   PRIVATE cFilt3 := ""

   cFilt3 := "(" + aUsl1 + ".or." + aUsl2 + ") .and.DATDOK<=" + dbf_quote( dDatDo )

   IF aUslR <> ".t."
      cFilt3 += ".and." + aUslR
   ENDIF

   SET FILTER to &cFilt3

   GO TOP

   nStavki := 0
   Box(, 2, 70 )
   DO WHILE !Eof()

      SELECT roba
      HSEEK kalk->idRoba

      lMagacin := .T.
      SELECT rekap2

      Sca2MKonto( dDatOd, dDatDo, aUsl1, aUsl2, cIdKPovrata, cC, lK2X, @lMagacin, lVpRab, lPrDatOd )
      Sca2PKonto( dDatOd, dDatDo, aUsl1, aUsl2, cIdKPovrata, cC, lK2X, @lProdavnica, lPrDatOd )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY ++nStavki PICT "999999999999"

      SELECT kalk
      SKIP
   ENDDO

   GRekap22()

   BoxC()

   RETURN


FUNCTION Sca2MKonto( dDatOd, dDatDo, aUsl1, aUsl2, cIdKPovrata, cC, lK2X, lMagacin, lVpRabat, lPrDatOd )

   LOCAL nPomKolicina
   LOCAL nTC

   IF lPrDatOd == nil
      lPrDatOd := .F.
   ENDIF

   IF !Empty( kalk->mKonto ) .AND. ( KALK->( &aUsl2 ) .OR. kalk->mKonto == cIdKPovrata )
      cGodina := Str( Year( kalk->datDok ), 4 )
      cMjesec := Str( Month( kalk->datDok ), 2 )
      HSEEK cGodina + cMjesec + roba->k1 + kalk->mKonto
      IF !Found()
         APPEND BLANK
         REPLACE objekat WITH kalk->mKonto
         REPLACE godina WITH Val( cGodina )
         REPLACE mjesec WITH Val( cMjesec )
         REPLACE g1 WITH roba->k1
      ENDIF
   ELSE
      lMagacin := .F.
   ENDIF

   IF cC == "P"
      nTC := KALK->vpc
   ELSE
      nTC := KALK->nc
   ENDIF

   // biljezi magacin - radi zaliha
   IF !lMagacin

   ELSEIF ( kalk->mu_i == "1" .OR. ( kalk->mu_i == "5" .AND. kalk->idvd == "97" ) )

      // mu_i=="5" jeste izlaz iz magacina, ali ga ovdje treba prikazivati
      // kao storno ulaza
      IF ( kalk->mu_i == "5" .AND. kalk->idvd == "97" )
         nPomKolicina := -1 * kalk->kolicina
      ELSE
         nPomKolicina := kalk->kolicina
      ENDIF
      IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
         field->stanjek += nPomKolicina
      ENDIF
      field->stanjef += nPomKolicina * nTC

      IF ( kalk->datDok <= dDatOd )

         IF !lK2X .OR. !( Left( roba->K2, 1 ) == 'X' )
            field->zalihak += nPomKolicina
         ENDIF
         field->zalihaf += nPomKolicina * nTC
         IF ( kalk->mKonto == cIdKPovrata )
            IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
               field->stanjrk += nPomKolicina
            ENDIF
            field->stanjrf += nPomKolicina * nTC
         ENDIF
      ELSE
         IF ( kalk->mKonto == cIdKPovrata )
            // magacin rekl. robe
            IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
               field->stanjrk += nPomKolicina
            ENDIF
            field->stanjrf += nPomKolicina * nTC
         ELSEIF ( kalk->idvd == "10" )
            IF ( !lK2X .OR. !( Left( roba->K2, 1 ) == 'X' ) )
               field->nabavk += nPomKolicina
            ENDIF
            field->nabavf += nPomKolicina * nTC
         ENDIF
      ENDIF

   ELSEIF ( kalk->mu_i == "5" )

      // izlaz iz magacina
      IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
         field->stanjek -= kalk->kolicina
      ENDIF
      field->stanjef -= kalk->kolicina * nTC
      IF kalk->datdok <= dDatOd
         IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
            field->zalihak -= kalk->kolicina
         ENDIF
         field->zalihaf -= kalk->kolicina * nTC
         IF ( kalk->mKonto == cIdKPovrata )
            IF !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' )
               field->stanjrk -= kalk->kolicina
            ENDIF
            field->stanjrf -= kalk->kolicina * nTC
         ENDIF
      ELSE
         IF ( kalk->mKonto == cIdKPovrata )
            IF ( !lK2X .OR. !( Left( roba->k2, 1 ) == 'X' ) )
               field->stanjrk -= kalk->kolicina
            ENDIF
            field->stanjrf -= kalk->kolicina * nTC
         ELSEIF kalk->idvd == "14"
            // izlaz velepr.
            IF ( !lK2X .OR. !( roba->K2 = 'X' ) )
               field->prodajak += kalk->kolicina
            ENDIF
            IF ( cC == "P" )
               IF lVpRabat
                  field->prodajaf += kalk->( kolicina * nTC * ( 1 -RabatV / 100 ) )
                  field->orucf += kalk->( kolicina * ( nTC * ( 1 -RabatV / 100 ) -nc ) )
               ELSE
                  field->prodajaf += kalk->( kolicina * nTC )
                  field->orucf += kalk->( kolicina * ( nTC - nc ) )
               ENDIF
            ELSE
               field->prodajaf += kalk->( kolicina * nTC )
            ENDIF
         ENDIF
      ENDIF

   ELSEIF ( kalk->mu_i == "3" .AND. cC == "P" )
      // nivelacija - samo za prod.cijenu
      IF kalk->datdok <= dDatOd
         field->zalihaf += kalk->kolicina * nTC
      ENDIF

      IF ( nTC > 0 )
         field->povecanje += kalk->( kolicina * nTC )
      ELSE
         // apsolutno
         field->snizenje += Abs( kalk->( kolicina * nTC ) )
      ENDIF

      IF ( kalk->mKonto == cIdKPovrata )
         field->stanjrf += kalk->kolicina * nTC
      ELSE
         field->stanjef += kalk->kolicina * nTC
      ENDIF

   ENDIF

   RETURN .T.


FUNCTION Sca2PKonto( dDatOd, dDatDo, aUsl1, aUsl2, cIdKPovrata, cC, lK2X, lMagacin, lPrDatOd )

   LOCAL nTC

   IF lPrDatOd == nil
      lPrDatOd := .F.
   ENDIF

   lProdavnica := .T.
   SELECT rekap2

   IF !Empty( kalk->pkonto ) .AND. kalk->( &aUsl1 )
      cGodina := Str( Year( kalk->datDOK ), 4 )
      cMjesec := Str( Month( kalk->datDOK ), 2 )
      HSEEK cGodina + cMjesec + roba->k1 + kalk->pkonto
      IF !Found()
         APPEND BLANK
         REPLACE objekat WITH kalk->pkonto, ;
            godina WITH Val( cGodina ), ;
            mjesec WITH Val( cMjesec ), ;
            g1 WITH roba->k1
      ENDIF
   ELSE
      lProdavnica := .F.
   ENDIF

   IF cC == "P"
      nTC := KALK->mpc
   ELSE
      nTC := KALK->nc
   ENDIF

   IF !lProdavnica

   ELSEIF ( kalk->pu_i == "1" )

      // ulaz moze biti po osnovu prijema, 80 - preknjizenja
      // odnosno internog dokumenta

      IF !lK2X .OR. !( roba->K2 = 'X' )
         field->stanjek += kalk->kolicina
      ENDIF
      field->stanjef += kalk->( kolicina * nTC )

      IF kalk->datdok <= dDatOd
         IF !lK2X .OR. !( roba->K2 = 'X' )
            field->zalihak += kalk->kolicina
         ENDIF
         field->zalihaf += kalk->( kolicina * nTC )
      ELSE
         IF kalk->idvd $ "11#12#13#81"
            IF !lK2X .OR. !( roba->K2 = 'X' )
               field->pnabavk += KALK->kolicina
            ENDIF
            field->pnabavf += KALK->kolicina * nTC
         ENDIF
         field->omprucf += kalk->( kolicina * ( nTC - nc ) )
      ENDIF


   ELSEIF kalk->Pu_i == "3" .AND. cC == "P"

      // nivelacija - samo za prod.cijenu

      field->stanjef += kalk->( kolicina * nTC )

      IF kalk->datdok <= dDatOd
         field->zalihaf += kalk->( kolicina * nTC )
      ENDIF

      IF KALK->mpcsapp > 0
         field->povecanje += kalk->( kolicina * nTC )
      ELSE
         field->snizenje += Abs( kalk->( kolicina * nTC ) ) // apsolutno
      ENDIF


   ELSEIF kalk->pu_i == "5"

      // izlaz iz prodavnice moze biti 42,41,11,12,13

      IF !lK2X .OR. !( roba->K2 = 'X' )
         field->stanjek -= kalk->kolicina
      ENDIF
      field->stanjef -= kalk->kolicina * nTC

      IF kalk->datdok <= dDatOd
         IF !lK2X .OR. !( roba->K2 = 'X' )
            field->zalihak -= kalk->kolicina
         ENDIF
         field->zalihaf -= kalk->( kolicina * nTC )

      ENDIF

      IF lPrDatOd == .T.
         // prodaja 01.01
         IF kalk->datdok >= dDatOd
            IF kalk->idvd $ "41#42#43" // maloprodaja
               IF !lK2X .OR. !( roba->K2 = 'X' )
                  field->prodajak += kalk->kolicina
               ENDIF
               field->prodajaf += kalk->( kolicina * nTC )
               field->orucf += kalk->( kolicina * ( nTC - nc ) )
            ENDIF
         ENDIF
      ELSE
         // prodaja 02.01
         IF kalk->datdok > dDatOd
            IF kalk->idvd $ "41#42#43" // maloprodaja
               IF !lK2X .OR. !( roba->K2 = 'X' )
                  field->prodajak += kalk->kolicina
               ENDIF
               field->prodajaf += kalk->( kolicina * nTC )
               field->orucf += kalk->( kolicina * ( nTC - nc ) )
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN


STATIC FUNCTION GRekap22()

   nStavki := 0
   SELECT rekap2
   SET ORDER TO TAG "3" // rekap2

   GO TOP
   DO WHILE !Eof()

      cG1 := g1
      nZalihaF := 0
      nZalihaK := 0
      nNabavF := 0
      nNabavK := 0
      nPNabavF := 0
      nPNabavK := 0
      nProdajaF := 0
      nProdajaK := 0

      aZalihe := {}
      nProdKumF := 0
      nProdKumK := 0
      nPovecanje := 0
      nSnizenje := 0
      nStanjRF := 0
      nStanjRK := 0
      nORucF := 0
      nOMPRucF := 0
      nStanjeF := 0
      nStanjeK := 0

      SELECT rekap2

      DO WHILE ( !Eof() .AND. rekap2->g1 == cG1 )

         SELECT rekap2
         nMjesec := rekap2->mjesec
         nGodina := rekap2->godina

         DO WHILE ( ( !Eof() .AND. rekap2->g1 == cG1  .AND. nMjesec == rekap2->mjesec .AND. nGodina == rekap2->godina ) )

            IF ( Year( dDatOd ) == Godina .AND. Month( dDatOd ) == mjesec )
               // samo je 01.98 mjesec poc zalihe
               nZalihaf += zalihaf
               nZalihak += zalihak
            ENDIF

            nNabavF += nabavf
            nNabavK += nabavk
            nPNabavF += pnabavf
            nPNabavK += pnabavk
            nProdajaF += prodajaf
            nProdajaK += prodajak
            nProdKumF += ProdajaF
            nProdKumK += Prodajak
            nStanjeF += StanjeF
            nStanjeK += StanjeK
            nStanjRF += StanjRF
            nStanjRK += StanjRK
            nPovecanje += povecanje
            nSnizenje += snizenje
            nORucF += orucf
            nOMPRucF += omprucf

            SELECT rekap2
            SKIP

         ENDDO

         IF ( Year( dDatOd ) == rekap2->godina .AND. Month( dDatOd ) == rekap2->mjesec )
            IF ( Round( nZalihaF, 4 ) <> 0 .AND. my_get_from_ini( "Planika", "ProsZalihaBezPocZalihe", "D", KUMPATH ) == "N" )
               AAdd( AZalihe, { nZalihaF, nZalihaK } )  // poc zaliha
            ENDIF
         ENDIF
         IF Round( nStanjef, 4 ) <> 0
            AAdd( AZalihe, { nStanjeF, nStanjeK } )
         ENDIF

         // 01.01 - 30.09
         // znaci imamo 10 uzoraka: 01.01, 31.01, 31.02, ..., 30.09

      ENDDO

      SELECT reka22
      APPEND BLANK
      nProszalf := 0
      nProszalk := 0
      nKObrDan := 0
      nGKObr := 0

      IF Len( aZalihe ) <> 0
         FOR i := 1 TO Len( aZalihe )
            nProsZalf += aZalihe[ i, 1 ]
            nProsZalk += aZalihe[ i, 2 ]
         NEXT
         nProsZalF := nProsZalf / Len( aZalihe )
         nProsZalk := nProsZalk / Len( aZalihe )
         IF nProsZalF <> 0
            nKobrDan := nProdKumf / nProsZalf
            nGKObr   := nKObrDan * 12 / Len( aZalihe )
         ENDIF
      ENDIF

      REPLACE  g1 WITH cG1
      REPLACE zalihaf   WITH nZalihaF
      REPLACE nabavF   WITH nNabavF
      REPLACE pnabavF   WITH nPNabavF
      REPLACE prodajaF  WITH nProdajaF
      REPLACE stanjeF  WITH nStanjeF
      REPLACE stanjrF   WITH nStanjRF
      REPLACE orucf    WITH nORucf
      REPLACE omprucf   WITH nOMPRucf
      REPLACE proszalF  WITH nProsZalF
      REPLACE prodKumF WITH nProdKumF
      REPLACE povecanje WITH nPovecanje
      REPLACE snizenje WITH nSnizenje
      REPLACE KObrDan   WITH nKObrDan
      IF ( Abs( nGKObr ) > 99999 )
         MsgBeep( "G. Koef obracuna za " + cG1 + " " + Str( nGKOBr ) + " ???" )
         REPLACE GKObr  WITH 0
      ELSE
         REPLACE GKObr    WITH nGKObr
      ENDIF
      REPLACE zalihak   WITH nZalihak
      REPLACE nabavk   WITH nNabavk
      REPLACE pnabavk   WITH nPNabavk
      REPLACE prodajak  WITH nProdajak
      REPLACE stanjek  WITH nStanjek
      REPLACE stanjrk   WITH nStanjRk
      REPLACE prodKumk WITH nProdKumk
      REPLACE proszalk  WITH nProsZalK

      SELECT rekap2
   ENDDO

   RETURN



FUNCTION kalk_prod_generacija_dokumenataNc()

   LOCAL cPKonto
   LOCAL cIdRoba

   LOCAL nNc
   LOCAL cBrDok
   LOCAL cIdVd
   LOCAL dDatDok

   O_PRODNC
  // o_roba()
   o_kalk()
   o_kalk_pripr()
   o_koncij()
   GO TOP

   Box(, 3, 60 )

   DO WHILE !Eof()

      SELECT koncij
      IF !Empty( koncij->IdProdMjes )
         cPKonto = koncij->Id
      ELSE
         SKIP
         LOOP
      ENDIF

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prodavnica: " + cPKonto
      SELECT roba
      GO TOP
      DO WHILE !Eof()

         cIdRoba := roba->id
         IF IsRobaInProdavnica( cPKonto, cIdRoba )
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "Roba " + cIdRoba
            nNc := GetNcForProdavnica( cPKonto, cIdRoba )
            cBrDok := "00000000"
            cIdVd := "00"
            dDatDok := Date()
            SetProdNc( cPKonto, cIdRoba, cIdVd, cBrDok, dDatDok, nNc )
         ELSE
            @ box_x_koord() + 2, box_y_koord() + 2 SAY "!Roba " + cIdRoba
         ENDIF

         SELECT roba
         SKIP
      ENDDO

      SELECT koncij
      SKIP
   ENDDO

   BoxC()

   RETURN

FUNCTION IsRobaInProdavnica( cPKonto, cIdRoba )

   SELECT kalk
   SET ORDER TO TAG "4"
   SEEK self_organizacija_id() + cPKonto + cIdRoba

   IF Found()
      RETURN .T.
   ELSE
      RETURN .F.
   ENDIF


FUNCTION GetNcForProdavnica( cPKonto, cIdRoba )

   LOCAL nKolicinaNaStanju
   LOCAL nKolZn
   LOCAL nNc1
   LOCAL nSredNc
   LOCAL dDatNab

   PRIVATE _DatDok

   SELECT ( F_PRIPR )
   IF !Used()
      o_kalk_pripr()
   ENDIF

   _DatDok = Date()
   kalk_get_nabavna_prod( self_organizacija_id(), cIdRoba, cPKonto, @nKolicinaNaStanju, @nKolZN, @nNc1, @nSredNc, @dDatNab )

   RETURN nSredNc




FUNCTION SetProdNc( cPKonto, cIdRoba, cIdVd, cBrDok, dDatDok, nNc )

   LOCAL nArr
   nArr := Select()

   SELECT ( F_PRODNC )
   IF !Used()
      O_PRODNC
   ENDIF

   SEEK cPKonto + cIdRoba

   my_flock()

   IF !Found()
      APPEND BLANK
      REPLACE PKonto WITH cPKonto
      REPLACE IdRoba WITH cIdRoba
   ENDIF

   REPLACE IdVd WITH cIdVd
   REPLACE BrDok WITH cBrDok
   REPLACE DatDok WITH dDatDok
   REPLACE Nc WITH nNc

   my_unlock()

   SELECT ( nArr )

   RETURN



FUNCTION SetIdPartnerRoba()

   LOCAL cPKonto
   LOCAL cIdRoba

   LOCAL nNc
   LOCAL cBrDok
   LOCAL cIdVd
   LOCAL dDatDok


//   o_roba()
   o_partner()
   GO TOP

   Box(, 3, 60 )


   FOR i = 1 TO 7

      IF ( i == 1 )
         cGodina = ""
      ELSEIF ( i == 2 )
         cGodina = "2002"
      ELSEIF ( i == 3 )
         cGodina = "2001"
      ELSEIF ( i == 4 )
         cGodina = "2000"
      ELSEIF ( i == 5 )
         cGodina = "1999"
      ELSEIF ( i == 6 )
         cGodina = "1998"
      ELSEIF ( i == 7 )
         cGodina = "1997"
      ENDIF


      SELECT ( F_KALK )
      USE  ( KUMPATH + cGodina + "\kalk" )
      SET ORDER TO TAG "1"


      @ box_x_koord() + 1, box_y_koord() + 2 SAY iif( cGodina == "", "2003", cGodina )

      SEEK self_organizacija_id() + "10"
      DO WHILE !Eof() .AND. ( IdVd == "10" )

         @ box_x_koord() + 2, box_y_koord() + 2 SAY kalk->IdRoba

         SELECT ROBA
         cIdPartner = kalk->IdPartner
         SEEK kalk->IdRoba
         IF Found()
            IF Empty( IdPartner )
               REPLACE IdPartner WITH cIdPartner
            ENDIF
         ENDIF

         SELECT KALK
         SKIP
      ENDDO

      SELECT kalk
      USE

   NEXT

   BoxC()

   RETURN
