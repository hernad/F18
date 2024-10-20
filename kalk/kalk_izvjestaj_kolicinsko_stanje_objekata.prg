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

STATIC nCol1 := 0
STATIC cPicCDem
STATIC cPicProc
STATIC cPicDem
STATIC cPicKol
STATIC cStrRedova2 := 62
STATIC cPrikProd := "N"
STATIC s_cUslovIdKonto
STATIC s_cUslovIdRoba
STATIC s_cUslovPKonto
STATIC s_cUslovMKonto
STATIC s_cUslovIdObj
STATIC cUslovRoba
STATIC cK9
STATIC cNObjekat
STATIC cLinija

#define ROBAN_LEN 40
#define KOLICINA_LEN 10

/*

FUNCTION kalk_izvj_stanje_po_objektima()

   LOCAL i
   LOCAL nT1
   LOCAL nT4
   LOCAL nT5
   LOCAL nT6
   LOCAL nT7
   LOCAL nTT1
   LOCAL nTT4
   LOCAL nTT5
   LOCAL nTT6
   LOCAL nTT7
   LOCAL n1
   LOCAL n4
   LOCAL n5
   LOCAL n6
   LOCAL n7
   LOCAL nRecno, hRec
   LOCAL cPodvuci
   PRIVATE dDatOd
   PRIVATE dDatDo
   PRIVATE aUTar := {}
   PRIVATE nUkObj := 0
   PRIVATE nITar := 0
   PRIVATE aUGArt := {}
   PRIVATE cPrSort := "SUBSTR(cIdRoba,3,3)"

   cPodvuci := "N"

   o_k1()
   kalk_o_objekti()

   cPicCDem := "999999.999"
   cPicProc := "999999.99%"
   cPicDem := "9999999.99"
   cPicKol := kalk_pic_kolicina_bilo_gpickol()
   s_cUslovIdKonto := PadR( "13;", 100 )
   s_cUslovIdRoba := Space( 100 )

   IF uslovi_izvjestaja( @cNObjekat ) == 0
      RETURN .F.
   ENDIF

   brisi_tabelu_pobjekti()
   napuni_tabelu_pobjekti_iz_objekti()
   kalk_cre_tabela_kalk_rekap1( "1" )
   otvori_tabele()
   kalk_gen_rekap1( s_cUslovPKonto, s_cUslovMKonto, s_cUslovIdRoba, "N", "1", "N", NIL, cK9 )

   set_linije_razdvajanja()

   SELECT rekap1
   SET ORDER TO TAG "2"
   GO TOP

   START PRINT CRET
   ?

   IF ( gPrinter = "R" )
      cStrRedova2 := 40
      ?? "#%LANDS#"
   ENDIF

   nStr := 0

   zaglavlje_izvjestaja( @nStr )

   nCol1 := 43

   resetuj_vrijednosti_tabele_pobjekti()

   SELECT rekap1
   nRbr := 0
   nRecno := 0
   fFilovo := .F.

   DO WHILE !Eof()

      cG1 := rekap1->g1

      SELECT pobjekti

      GO TOP
      DO WHILE !Eof()
         hRec := dbf_get_rec()
         hRec[ "prodg" ] := 0
         hRec[ "zalg" ] := 0
         dbf_update_rec( hRec )
         SKIP
      ENDDO

      SELECT rekap1
      fFilGr := .F.
      fFilovo := .F.

      DO WHILE ( !Eof() .AND. cG1 == field->g1 )
         ++nRecno

         cIdroba := rekap1->idRoba

         select_o_roba( cIdRoba )
         cIdTarifa := roba->idTarifa

         SELECT rekap1

         nK2 := nK1 := 0
         get_k1_k2_rekap1_za_grupa_tarifa_roba_idobj( cG1, cIdTarifa, cIdRoba, @nK1, @nK2 )

         IF ( ( Round( nK2, 3 ) == 0 .AND. Round( nK1, 2 ) == 0 ) )
            SELECT rekap1
            SEEK cG1 + cIdTarifa + cIdroba + Chr( 254 )
            LOOP
         ENDIF

         fFilovo := .T.
         fFilGr := .T.

         aStrRoba := SjeciStr( Trim( roba->naz ), ROBAN_LEN )

         IF ( PRow() > cStrRedova2 )
            FF
            zaglavlje_izvjestaja( @nStr )
         ENDIF

         ++nRBr
         ? Str( nRBr, 4 ) + "." + PadR( cIdRoba, 10 )
         nColR := PCol() + 1
         @ PRow(), nColR  SAY PadR( aStrRoba[ 1 ], ROBAN_LEN )
         nCol1 := PCol()

         ispisi_zalihe( cG1, cIdTarifa, cIdRoba, s_cUslovIdObj )

         nK1 := 0
         IF ( ( cPrikProd == "D" ) .OR. Len( aStrRoba ) > 1 )
            ?
            IF Len( aStrRoba ) > 1
               @ PRow(), nColR SAY PadR( aStrRoba[ 2 ], ROBAN_LEN )
            ENDIF
            @ PRow(), nCol1 SAY ""
            IF ( cPrikProd == "D" )
               ispisi_prodaju( cG1, cIdTarifa, cIdRoba, s_cUslovIdObj )
            ENDIF
         ENDIF

         IF cPodvuci == "D"
            ? cLinija
         ENDIF

         SELECT rekap1
         SEEK cG1 + cIdTarifa + cIdroba + Chr( 255 )
      ENDDO

      IF !fFilGr
         LOOP
      ENDIF

      IF ( PRow() > cStrRedova2 )
         FF
         zaglavlje_izvjestaja( @nStr )
      ENDIF

      ? StrTran( cLinija, "-", "=" )

      // SELECT k1
      // HSEEK cG1
      SELECT rekap1
      StrTran( cLinija, "-", "=" )
   ENDDO

   IF ( PRow() > cStrRedova2 )
      FF
      zaglavlje_izvjestaja( @nStr )
   ENDIF

   FF
   endprint

   my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_o_pobjekti()

   Select( F_POBJEKTI )
   my_use ( "pobjekti" )
   SET ORDER TO TAG "1"

   RETURN .T.


FUNCTION o_k1( cId )

   LOCAL cTabela := "os_k1"

   IF ! f18_use_module( "os" )
      MsgBeep( "k1 tabela trazi aktiviran modul OS" )
      RETURN .F.
   ENDIF

   SELECT ( F_K1 )

   IF !use_sql_sif  ( cTabela, .T., "K1", cId  )
      error_bar( "o_sql", "open sql " + cTabela )
      RETURN .F.
   ENDIF
   SET ORDER TO TAG "ID"
   IF cId != NIL
      SEEK cId
   ENDIF

   RETURN !Eof()


FUNCTION select_o_k1( cId )

   SELECT ( F_K1 )
   IF Used()
      IF RecCount() > 1 .AND. cId == NIL
         RETURN .T.
      ELSE
         USE // samo zatvoriti postojecu tabelu, pa ponovo otvoriti sa cId
      ENDIF
   ENDIF

   RETURN o_k1( cId )


FUNCTION kalk_gen_rekap1( aUsl1, aUsl2, s_cUslovIdRoba, cKartica, cVarijanta, cKesiraj,  cK1, cK7, cK9, cIdKPovrata, aUslSez )

   LOCAL nSec

   IF ( cKesiraj = NIL )
      cKesiraj := "N"
   ENDIF

   IF ( cK1 == NIL )
      cK1 := "9999"
   ENDIF

   IF ( cK7 == NIL )
      cK7 := "N"
   ENDIF

   IF ( cK9 == NIL )
      cK9 := "999"
   ENDIF

   IF ( cIdKPovrata == NIL )
      cIdKPovrata := "XXXXXXXX"
   ENDIF

   IF ( aUslSez == NIL )
      aUslSez := ".t."
   ENDIF


   nSec := Seconds()

   find_kalk_by_mkonto_idroba_idvd( self_organizacija_id(), NIL, NIL, s_cUslovIdRoba, "idkonto,idroba" )

   PRIVATE cFilt1 := ""

   cFilt1 := "DatDok<=" + dbf_quote( dDatDo ) + ".and.(" + aUsl1 + ".or." + aUsl2 + ")"

   // IF aUslr <> ".t."
   // cFilt1 += ".and." + aUslR
   // ENDIF

   IF aUslSez <> ".t."
      cFilt1 += ".and." + aUslSez
   ENDIF

   SELECT kalk
   SET FILTER TO &cFilt1


   GO TOP
   nStavki := 0
   Box(, 2, 70 )
   DO WHILE !Eof()

      select_o_roba(  kalk->idroba )
      IF cK7 == "D" .AND. Empty( roba->k7 )
         SELECT kalk
         SKIP
         LOOP
      ENDIF

      IF ( cK1 <> "9999" .AND. !Empty( cK1 ) .AND. roba->k1 <> cK1 )
         SELECT kalk
         SKIP
         LOOP
      ENDIF

      IF ( cK9 <> "999" .AND. !Empty( cK9 ) .AND. roba->k9 <> cK9 )
         SELECT kalk
         SKIP
         LOOP
      ENDIF


      kalk_scan_magacinski_konto( dDatOd, dDatDo, cIdKPovrata, cKartica, cVarijanta, cKesiraj )


      kalk_scan_prodavnicki_konto( dDatOd, dDatDo, cIdKPovrata, cKartica, cVarijanta, cKesiraj )

      IF ( ( ++nStavki % 100 ) == 0 )
         @ box_x_koord() + 1, box_y_koord() + 2 SAY nStavki PICT "99999999999999"
      ENDIF

      SELECT kalk
      SKIP
   ENDDO

   nStavki := 0

   o_roba()
   GO TOP
   DO WHILE !Eof()
      IF roba->tip == "N"
         // nova roba
         SELECT pobjekti
         GO TOP
         // za sve objekte
         DO WHILE !Eof()
            SELECT rekap1
            HSEEK pobjekti->idobj + roba->id
            IF !Found()
               APPEND BLANK
               REPLACE objekat WITH pobjekti->idobj
               REPLACE idroba WITH roba->id
               REPLACE idtarifa WITH roba->idtarifa
               REPLACE g1 WITH roba->k1
               field->mpc := roba->mpc
            ENDIF
            SELECT pobjekti
            SKIP
         ENDDO
      ENDIF
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "***********************"
      @ box_x_koord() + 1, Col() + 2 SAY ++nStavki PICT "99999999999999"
      SELECT roba
      SKIP
   ENDDO

   BoxC()

   nSec := Seconds() - nSec
   IF ( nSec > 1 )
      @ 23, 75 SAY nSec PICT "9999"
   ENDIF

   RETURN .T.



FUNCTION kalk_scan_magacinski_konto( dDatOd, dDatDo, cIdKPovrata, cKartica, cVarijanta, cKesiraj )

   LOCAL nGGOrd
   LOCAL nGGo
   LOCAL nMpc
   LOCAL cSeek
   LOCAL hRec

   IF Empty( kalk->mKonto ) // nije stavka magacin
      RETURN 0
   ENDIF

   SELECT rekap1
   HSEEK kalk->( mKonto + idroba )

   IF !Found()

      APPEND BLANK

      hRec := dbf_get_rec()

      // radi promjene tarifa promjenio sam kalk->idtarifa u roba->idtarifa
      // replace objekat with kalk->mKonto, idroba with kalk->idroba, idtarifa with kalk->idtarifa, g1 with roba->k1

      hRec[ "objekat" ] := kalk->mkonto
      hRec[ "idroba" ] := kalk->idroba
      hRec[ "idtarifa" ] := roba->idtarifa
      hRec[ "g1" ] := roba->k1

      IF ( cKartica == "D" )
         // ocitaj_izbaci sa kartica
         nMpc := 0
         IF ( cVarijanta <> "1" )
            // varijanta="1" - pregled kretanja zaliha
            cSeek := kalk->( idfirma + mKonto + idroba )
            SELECT kalk
            nGGOrd := IndexOrd()
            nGGo := RecNo()
            select_o_koncij( kalk->mKonto )
            SELECT kalk
            // dan prije inventure !!!
            kalk_vpc_po_kartici( @nmpc, cSeek, dDatDo - 1 )
            dbSetOrder( nGGOrd )
            GO nGGo

            SELECT rekap1
            hRec[ "mpc" ] := nMpc

         ENDIF
      ELSE
         hRec[ "mpc" ] := roba->mpc

      ENDIF

   ELSE
      hRec := dbf_get_rec()
   ENDIF

   IF kalk->mu_i == "1"

      IF kalk->datdok <= dDatDo
         // stanje zalihe
         hRec[ "k2" ] := hRec[ "k2" ] + kalk->kolicina
      ENDIF

      IF cVarijanta <> "1"
         // u pregledu kretanja zaliha ovo nam ne treba
         IF ( kalk->datdok < dDatOd )
            // predhodno stanje
            hRec[ "k0" ] := hRec[ "k0" ] + kalk->kolicina
         ENDIF
         IF DInRange( kalk->datdok, dDatOd, dDatDo )
            // tekuci prijem
            hRec[ "k4" ] := hRec[ "k4" ] + kalk->kolicina
         ENDIF
      ENDIF

   ELSEIF kalk->mu_i == "5"
      // izlaz iz magacina
      IF cVarijanta <> "1"
         // u pregledu kretanja zaliha ovo nam ne treba
         IF ( kalk->datdok < dDatOd )
            // predhodno stanje
            hRec[ "k0" ] := hRec[ "k0" ] - kalk->kolicina
         ENDIF
      ENDIF
      IF kalk->datdok <= dDatDo
         // stanje trenutne zalihe
         hRec[ "k2" ] := hRec[ "k2" ] - kalk->kolicina
      ENDIF

      IF kalk->idvd $ "14#94"
         IF ( cVarijanta <> "1" )
            // u pregledu kretanja zaliha ovo nam ne treba
            IF ( kalk->datdok <= dDatDo )
               // kumulativna prodaja
               hRec[ "k3" ] := hRec[ "k3" ] + kalk->kolicina
            ENDIF
         ENDIF
         IF DInRange( kalk->datDok, dDatOd, dDatDo )
            // stanje trenutne prodaje
            hRec[ "k1" ] := hRec[ "k1" ] + kalk->kolicina
         ENDIF
      ENDIF

   ELSEIF ( kalk->mu_i == "3" )
      // nivelacija
      IF ( kalk->datDok = dDatDo )
         // dokument nivelacije na dan inventure
         IF ( cVarijanta <> "1" )
            hRec[ "novampc" ] := kalk->mpcsapp + kalk->vpc
         ENDIF
         hRec[ "mpc" ] := kalk->mpcsapp
      ENDIF
   ENDIF

   dbf_update_rec( hRec )

   RETURN 1



FUNCTION kalk_scan_prodavnicki_konto( dDatOd, dDatDo, cIdKPovrata, cKartica, cVarijanta, cKesiraj )

   LOCAL nGGOrd
   LOCAL nGGo
   LOCAL nMpc
   LOCAL cSeek
   LOCAL hRec

   IF Empty( kalk->pkonto )
      RETURN 0
   ENDIF

   SELECT rekap1
   HSEEK kalk->( pkonto + idroba )

   IF !Found()

      APPEND BLANK

      hRec := dbf_get_rec()

      hRec[ "objekat" ] := kalk->pkonto
      hRec[ "idroba" ] := kalk->idroba
      hRec[ "idtarifa" ] := roba->idtarifa
      hRec[ "g1" ] := roba->k1

      IF ( cKartica == "D" )
         // ocitaj_izbaci sa kartica
         nMpc := 0
         // cSeek := kalk->( idfirma + pkonto + idroba )
         SELECT kalk
         nGGo := RecNo()
         nGGOrd := IndexOrd()
         select_o_koncij( kalk->pkonto )
         SELECT kalk


         kalk_mpc_sa_pdv_sa_kartice( @nMpc, kalk->idfirma, kalk->pkonto, kalk->idroba, dDatDo - 1 ) // dan prije inventure !
         dbSetOrder( nGGOrd )
         GO nGGo
         SELECT rekap1
         hRec[ "mpc" ] := nMpc
      ELSE
         hRec[ "mpc" ] := roba->mpc
      ENDIF

   ELSE

      hRec := dbf_get_rec()

   ENDIF

   IF ( kalk->pu_i == "1" .AND. kalk->kolicina > 0 )

      // ulaz moze biti po osnovu prijema, 80 - preknjizenja
      // odnosno internog dokumenta

      IF kalk->datdok <= dDatDo  // kumulativno stanje
         hRec[ "k2" ] += kalk->kolicina  // zalihe
      ENDIF
      IF ( cVarijanta <> "1" )
         IF kalk->datdok < dDatOd
            // predhodno stanje
            hRec[ "k0" ] += kalk->kolicina
         ENDIF
         IF DInRange( kalk->datdok, dDatOd, dDatDo )
            // tekuci prijem
            hRec[ "k4" ] += kalk->kolicina
         ENDIF
      ELSE
         IF DInRange( kalk->datdok, dDatOd, dDatDo )
            // tekuci prijem
            IF kalk->idvd == "80" .AND. !Empty( kalk->idkonto2 )
               // bilo je promjena po osnovu predispozicije
               hRec[ "k4pp" ] += kalk->kolicina
            ENDIF
         ENDIF
      ENDIF

   ELSEIF ( kalk->pu_i == "3" )

      // nivelacija
      IF kalk->datdok = dDatDo
         // dokument nivelacije na dan inventure
         IF cVarijanta <> "1"
            hRec[ "novampc" ] := kalk->( fcj + mpcsapp )
         ENDIF
         // stara cijena
         hRec[ "mpc" ] := kalk->fcj

      ENDIF

   ELSEIF kalk->pu_i == "5" .OR. ( kalk->pu_i == "1" .AND. kalk->kolicina < 0 )

      // izlaz iz prodavnice moze biti 42,41,11,12,13
      // f1 - tekuca prodaja, f2 zaliha, f3 - kumulativna prodaja
      // f4 - prijem u toku mjeseca
      // f6 - izlaz iz prodavnice po ostalim osnovama
      // f5 - reklamacije u toku mjeseca, f7 - reklamacije u toku godine

      IF ( cVarijanta <> "1" )
         IF kalk->datdok < dDatOd
            IF kalk->pu_i == "5"
               // predhodno stanje
               hRec[ "k0" ] -= kalk->kolicina
            ELSE
               hRec[ "k0" ] -= Abs( kalk->kolicina )
            ENDIF
         ENDIF
      ENDIF

      IF ( kalk->datdok <= dDatDo )
         IF kalk->pu_i == "5"
            // zaliha
            hRec[ "k2" ] -= kalk->kolicina
         ELSE
            hRec[ "k2" ] -= Abs( kalk->kolicina )
         ENDIF
      ENDIF

      IF ( kalk->idvd $ "41#42#43" )
         // prodaja
         IF DInRange( kalk->datdok, dDatOd, dDatDo )
            // tekuca prodaja
            hRec[ "k1" ] += kalk->kolicina
         ENDIF
         IF ( cVarijanta <> "1" )
            IF kalk->datdok <= dDatDo
               // kumulativna prodaja
               hRec[ "k3" ] += kalk->kolicina
            ENDIF
         ENDIF

      ELSE

         // izlazi iz prodavnice po ostalim osnovima

         IF ( cVarijanta <> "1" )
            IF ( kalk->idvd $ "11#12#13" .AND. kalk->mKonto == cIdKPovrata )
               // reklamacija
               IF DInRange( kalk->datdok, dDatOd, dDatDo )
                  // tekuce reklamacije
                  // reklamacije u mjesecu
                  hRec[ "k5" ] += Abs( kalk->kolicina )
               ENDIF
               IF kalk->datdok <= dDatDo
                  // kumulativno reklamacije
                  hRec[ "k7" ] += Abs( kalk->kolicina )
               ENDIF
            ELSE
               IF DInRange( kalk->datdok, dDatOd, dDatDo )
                  // izlaz-otprema po ostalim osnovama
                  hRec[ "k6" ] += Abs( kalk->kolicina )
               ENDIF
            ENDIF
         ELSE
            IF DInRange( kalk->datdok, dDatOd, dDatDo )
               IF kalk->idvd == "80" .AND. !Empty( kalk->idkonto2 )
                  // bilo je promjena po osnovu predispozicije
                  hRec[ "k4pp" ] += kalk->kolicina
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   dbf_update_rec( hRec )

   RETURN 1




STATIC FUNCTION otvori_tabele()

   kalk_o_pobjekti()
   o_koncij()
   // o_roba()
   // o_konto()
   // o_tarifa()
   // o_k1()
   kalk_o_objekti()
   // o_kalk()
   o_rekap1()

   RETURN .T.


FUNCTION o_rekap1()

   Select( F_REKAP1 )
   my_use  ( "rekap1" )
   SET ORDER TO TAG "1"

   RETURN .T.




FUNCTION get_k1_k2_rekap1_za_grupa_tarifa_roba_idobj( cG1, cIdTarifa, cIdRoba, nK1, nK2 )

   nK2 := 0
   nK1 := 0
   SELECT pobjekti // kalk_pobjekti.dbf
   GO TOP
   DO WHILE ( !Eof()  .AND. field->id < "99" )
      SELECT rekap1
      HSEEK  cG1 + cIdtarifa + cIdroba + pobjekti->idobj
      nK2 += field->k2
      nK1 += field->k1
      SELECT pobjekti
      SKIP
   ENDDO

   RETURN .T.


STATIC FUNCTION set_linije_razdvajanja()

   LOCAL nObjekata

   cLinija := Replicate( "-", 4 ) + " " + Replicate( "-", 10 ) + " " + Replicate( "-", ROBAN_LEN )

   SELECT pobjekti
   GO TOP

   nObjekata := 0

   DO WHILE !Eof()

      IF !( "SVE" $ Upper( field->naz ) ) .AND. ( field->id <> "99" .AND. !Empty( s_cUslovIdObj ) .AND. !( &s_cUslovIdObj ) )
         SKIP
         LOOP
      ENDIF

      cLinija := cLinija + " " + Replicate( "-", KOLICINA_LEN )

      ++nObjekata

      SKIP

   ENDDO

   RETURN .T.




STATIC FUNCTION zaglavlje_izvjestaja( nStr )

   LOCAL nObjekata

   ? tip_organizacije() + ":", self_organizacija_naziv(), Space( 40 ), "Strana:" + Str( ++nStr, 3 )
   ?
   ?U  "Količinsko stanje " + iif( cPrikProd == "D", "zaliha i prodaje", "zaliha" ) + " artikala po objektima za period:"
   ?? dDatOd, "-", dDatDo
   ?

   IF ( s_cUslovIdRoba == NIL )
      s_cUslovIdRoba := ""
   ENDIF

   ? "Kriterij za objekat:", Trim( s_cUslovIdKonto ), "Robu:", Trim( s_cUslovIdRoba )
   ?

   P_COND

   ? cLinija

   ?U PadC( "Rbr", 4 ) + " " + PadC( "Šifra", 10 ) + " " + PadC( "Naziv  artikla", ROBAN_LEN )

   SELECT objekti
   GO BOTTOM

   ?? " " + PadC( AllTrim( objekti->naz ), KOLICINA_LEN )

   GO TOP

   DO WHILE ( !Eof() .AND. objekti->id < "99" )

      IF !Empty( s_cUslovIdObj ) .AND. !( &s_cUslovIdObj )
         SKIP
         LOOP
      ENDIF
      ?? " " + PadC( AllTrim( objekti->naz ), KOLICINA_LEN )
      SKIP

   ENDDO

   ? PadC( " ", 4 ) + " " + PadC( " ", 10 ) + " " + PadC( " ", ROBAN_LEN )

   ?? " " + PadC( iif( cPrikProd == "D", "zal/pr", "zaliha" ), KOLICINA_LEN )

   SELECT pobjekti
   GO TOP
   DO WHILE ( !Eof() .AND. field->id < "99" )

      IF !Empty( s_cUslovIdObj ) .AND. !( &s_cUslovIdObj )
         SKIP
         LOOP
      ENDIF

      ?? " " + PadC( iif( cPrikProd == "D", "zal/pr", "zaliha" ), KOLICINA_LEN )

      SKIP

   ENDDO

   ? cLinija

   RETURN NIL


STATIC FUNCTION uslovi_izvjestaja( cNObjekat )

   s_cUslovPKonto := ""
   s_cUslovMKonto := ""
   s_cUslovIdObj := ""
   cUslovR := ""
   dDatOd := Date()
   dDatDo := Date()

   o_params()
   PRIVATE cSection := "F", cHistory := " ", aHistory := {}

   Params1()
   RPar( "c2", @s_cUslovIdKonto )
   RPar( "c3", @cPrSort )
   RPar( "d1", @dDatOd )
   RPar( "d2", @dDatDo )
   RPar( "cR", @s_cUslovIdRoba )

   s_cUslovIdRoba := PadR( s_cUslovIdRoba, 100 ) // sql parsiraj funkcije traze Len( cUslovString ) > 99
   s_cUslovIdKonto := PadR( s_cUslovIdKonto, 100 )
   cKartica := "N"
   cNObjekat := Space( 20 )

   cPrikProd := "N"

   Box(, 10, 70 )
   set_cursor_on()

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konta objekata:" GET s_cUslovIdKonto PICT "@!S50"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "tekući promet je period:" GET dDatOd
      @ box_x_koord() + 3, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Kriterij za robu :" GET s_cUslovIdRoba PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Prikaz prodaje (D/N)" GET cPrikProd PICT "@!" VALID cPrikProd $ "DN"
      READ

      IF ( LastKey() == K_ESC )
         BoxC()
         RETURN 0
      ENDIF
      s_cUslovPKonto := Parsiraj( s_cUslovIdKonto, "PKonto" )
      s_cUslovMKonto := Parsiraj( s_cUslovIdKonto, "MKonto" )
      s_cUslovIdObj := Parsiraj( s_cUslovIdKonto, "IDOBJ" )
      cUslovRoba := Parsiraj( s_cUslovIdRoba, "IdRoba" )

      IF ( s_cUslovPKonto <> NIL .AND. cUslovRoba <> NIL )
         EXIT
      ENDIF
   ENDDO
   BoxC()

   // SELECT roba
   // USE

   SELECT params

   WPar( "c2", s_cUslovIdKonto )
   WPar( "c3", cPrSort )
   WPar( "d1", dDatOd )
   WPar( "d2", dDatDo )
   WPar( "cR", @s_cUslovIdRoba )
   SELECT params
   USE

   RETURN 1



STATIC FUNCTION ispisi_zalihe( cG1, cIdTarifa, cIdRoba, cDUslov )

   LOCAL nK2

   nK2 := 0
   SELECT pobjekti
   GO TOP
   DO WHILE ( !Eof() .AND. field->id < "99" )
      SELECT rekap1
      HSEEK cG1 + cIdTarifa + cIdRoba + pobjekti->idobj
      nK2 += field->k2
      SELECT pobjekti
      SKIP
   ENDDO

   @ PRow(), PCol() + 1 SAY nK2 PICT cPicKol

   SELECT pobjekti
   GO TOP
   DO WHILE ( !Eof() .AND. pobjekti->id < "99" )

      SELECT pobjekti

      IF !Empty( cDUslov ) .AND. !( &cDUslov )
         SKIP
         LOOP
      ENDIF

      SELECT rekap1
      HSEEK cG1 + cIdTarifa + cIdRoba + pobjekti->idobj
      IF k4pp <> 0
         @ PRow(), PCol() + 1 SAY StrTran( TRANS( k2, cPicKol ), " ", "*" )
      ELSE
         @ PRow(), PCol() + 1 SAY k2 PICT cPicKol
      ENDIF
      SELECT pobjekti
      IF roba->k2 <> "X"
         hRec := dbf_get_rec()
         hRec[ "zalt" ] := hRec[ "zalt" ] + rekap1->k2
         hRec[ "zalu" ] := hRec[ "zalu" ] + rekap1->k2
         hRec[ "zalg" ] := hRec[ "zalg" ] + rekap1->k2
         dbf_update_rec( hRec )
      ENDIF
      SKIP
   ENDDO

   IF ( roba->k2 <> "X" )
      hRec := dbf_get_rec()
      hRec[ "zalt" ] := hRec[ "zalt" ] + nK2
      hRec[ "zalu" ] := hRec[ "zalu" ] + nK2
      hRec[ "zalg" ] := hRec[ "zalg" ] + nK2
      dbf_update_rec( hRec )
   ENDIF

   RETURN .T.


STATIC FUNCTION ispisi_prodaju( cG1, cIdTarifa, cIdRoba, cDUslov )

   LOCAL nK1

   SELECT pobjekti
   nK1 := 0
   GO TOP
   DO WHILE ( !Eof() .AND. pobjekti->id < "99" )
      SELECT rekap1
      HSEEK cG1 + cIdTarifa + cIdRoba + pobjekti->idobj
      nK1 += field->k1
      SELECT pobjekti
      SKIP
   ENDDO

   @ PRow(), PCol() + 1 SAY nK1 PICT cPicKol

   SELECT pobjekti
   GO TOP
   lIzaProc := .T.
   i := 0
   DO WHILE ( !Eof() .AND. pobjekti->id < "99" )

      SELECT pobjekti
      IF !Empty( cDUslov ) .AND. !( &cDUslov )
         SKIP
         LOOP
      ENDIF

      SELECT rekap1
      HSEEK cG1 + cIdTarifa + cIdRoba + pobjekti->idobj
      IF k4pp <> 0
         @ PRow(), PCol() + 1 SAY StrTran( TRANS( k1, cPicKol ), " ", "*" )
      ELSE
         @ PRow(), PCol() + 1 SAY k1 PICT cPicKol
      ENDIF
      ++i

      SELECT pobjekti
      IF ( roba->k2 <> "X" )

         hRec := dbf_get_rec()
         hRec[ "prodt" ] := hRec[ "prodt" ] + rekap1->k1
         hRec[ "produ" ] := hRec[ "produ" ] + rekap1->k1
         hRec[ "prodg" ] := hRec[ "prodg" ] + rekap1->k1
         dbf_update_rec( hRec )

      ENDIF
      SKIP
   ENDDO

   IF roba->k2 <> "X"

      hRec := dbf_get_rec()
      hRec[ "prodt" ] := hRec[ "prodt" ] + nK1
      hRec[ "produ" ] := hRec[ "produ" ] + nK1
      hRec[ "prodg" ] := hRec[ "prodg" ] + nK1
      dbf_update_rec( hRec )

   ENDIF

   RETURN .T.

STATIC FUNCTION PrintZalGr()

   LOCAL i

   SELECT pobjekti
   GO BOTTOM
   @ PRow(), nCol1 + 1 SAY zalg PICT cPicKol
   SELECT pobjekti
   GO TOP
   i := 0
   DO WHILE ( !Eof() .AND. pobjekti->id < "99" )
      @ PRow(), PCol() + 1 SAY zalg PICT cPicKol
      ++i
      SKIP
   ENDDO

   RETURN .T.


STATIC FUNCTION PrintProdGr()

   SELECT pobjekti
   GO BOTTOM
   @ PRow() + 1, nCol1 + 1 SAY prodg PICT cPicKol
   SELECT pobjekti
   GO TOP
   i := 0
   DO WHILE ( !Eof()  .AND. field->id < "99" )
      @ PRow(), PCol() + 1 SAY prodg PICT cPicKol
      ++i
      SKIP
   ENDDO

FUNCTION brisi_tabelu_pobjekti()

   kalk_o_pobjekti()

   my_dbf_zap()

   RETURN .T.



FUNCTION napuni_tabelu_pobjekti_iz_objekti()

   LOCAL hRec

   kalk_o_pobjekti()
   kalk_o_objekti()

   MsgO( "objekti -> pobjekti" )

   SELECT objekti
   GO TOP

   DO WHILE !Eof()
      hRec := dbf_get_rec()
      SELECT pobjekti
      APPEND BLANK
      dbf_update_rec( hRec )
      SELECT objekti
      SKIP
   ENDDO

   MsgC()

   SELECT POBJEKTI
   INDEX ON field->id TAG "1"

   RETURN .T.



FUNCTION resetuj_vrijednosti_tabele_pobjekti()

   LOCAL hRec

   SELECT pobjekti
   GO TOP

   DO WHILE !Eof()

      hRec := dbf_get_rec()
      hRec[ "prodtu" ] := 0
      hRec[ "produ" ] := 0
      hRec[ "zaltu" ] := 0
      hRec[ "zalu" ] := 0
      dbf_update_rec( hRec )

      SKIP

   ENDDO

   RETURN

*/   