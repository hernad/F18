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



FUNCTION fakt_uporedna_lista_fakt_kalk()

   LOCAL cIdFirma, qqRoba, nRezerv, nRevers
   LOCAL nul, nizl, nRbr, cRR, nCol1 := 0
   LOCAL m := ""
   LOCAL cDirFakt, cDirKalk
   LOCAL cViseKonta
   PRIVATE dDatOd, dDatDo

   // PRIVATE gDirKalk := ""
   PRIVATE cOpis1 := PadR( "F A K T", 12 )
   PRIVATE cOpis2 := "FAKT 2.FIRMA"

   // o_fakt_doks_dbf()
   // o_kalk() // uporedna lista fakt kalk
   // o_konto()
   // o_tarifa()
   // o_sifk()
   // o_sifv()
   // o_roba()
   // o_rj()
   // o_fakt_dbf()

   // SELECT fakt
   // SET ORDER TO TAG "3"
   // idroba

   cKalkFirma := self_organizacija_id()
   cIdfirma := self_organizacija_id()
   qqRoba := ""
   dDatOd := CToD( "" )
   dDatDo := Date()
   cRazlKol := "D"
   cRazlVr  := "D"
   cMP := "M"
   cIdKonto := PadR( "1320", 7 )


   cViseKonta := ""
   lViseKonta := .F.

   qqPartn := Space( 20 )
   PRIVATE qqTipdok := "  "

   Box(, 16, 66 )

   cIdFirma := fetch_metric( "fakt_uporedna_lista_id_firma", my_user(), cIdFirma )
   qqRoba := fetch_metric( "fakt_uporedna_lista_roba", my_user(), qqRoba )
   dDatOd := fetch_metric( "fakt_uporedna_lista_datum_od", my_user(), dDatOd )
   dDatDo := fetch_metric( "fakt_uporedna_lista_datum_do", my_user(), dDatDo )
   cRazlKol := fetch_metric( "fakt_uporedna_lista_razlika_kolicina", my_user(), cRazlKol )
   cRazlVr := fetch_metric( "fakt_uporedna_lista_razlika_vrijednosti", my_user(), cRazlVr )
   cMp := fetch_metric( "fakt_uporedna_lista_mp", my_user(), cMP )
   cIdKonto := fetch_metric( "fakt_uporedna_lista_konta", my_user(), cIdKonto )
   cKalk_firma := fetch_metric( "fakt_uporedna_lista_kalk_id_firma", my_user(), cKalkFirma )
   cOpis1 := fetch_metric( "fakt_uporedna_lista_opis_1", my_user(), cOpis1 )
   cOpis2 := fetch_metric( "fakt_uporedna_lista_opis_2", my_user(), cOpis2 )
   cIdKonto := fetch_metric( "fakt_uporedna_lista_konto", my_user(), cIdKonto )

   cIdKonto := cIdKonto

   qqRoba := PadR( qqRoba, 60 )
   cIdKonto := PadR( cIdKonto,  7 )
   qqPartn := PadR( qqPartn, 20 )
   qqTipDok := PadR( qqTipDok, 2 )

   cRR := "N"

   PRIVATE cTipVPC := "1"

   cK1 := cK2 := Space( 4 )

   DO WHILE .T.

      cIdFirma := Left( cIdFirma, 2 )

      fakt_getlist_rj_read( box_x_koord() + 1, box_y_koord() + 2, @GetList, @cIdFirma )

      // IF lViseKonta
      // @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto u KALK"  GET cIdKonto  WHEN  {|| cIdKonto := iif ( !Empty( cIdKonto ), cIdKonto + " ;", cIdKonto ), .T. } PICT "@!S20"
      // ELSE
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto u KALK"  GET cIdKonto     VALID P_Konto ( @cIdKonto )
      // ENDIF
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Oznaka firme u KALK"  GET cKalkFirma PICT "@!S40"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Roba   "  GET qqRoba   PICT "@!S40"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Od datuma"  GET dDatOd
      @ box_x_koord() + 5, Col() + 1 SAY "do datuma"  GET dDatDo
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Prikazi ako se razlikuju kolicine (D/N)" GET cRazlKol PICT "@!" VALID cRazlKol $ "DN"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikazi ako se razlikuju vrijednosti (D/N)" GET cRazlVr PICT "@!" VALID cRazlVr $ "DN"

      IF gVarC $ "12"
         @ box_x_koord() + 9, box_y_koord() + 2 SAY "Stanje u FAKT prikazati sa Cijenom 1/2 (1/2) "  GET cTipVpc PICT "@!" VALID cTipVPC $ "12"
      ENDIF

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "K1" GET  cK1 PICT "@!"
      @ box_x_koord() + 10, Col() + 1 SAY "K2" GET  cK2 PICT "@!"

      READ

      ESC_BCR

      aUsl1 := Parsiraj( qqRoba, "IdRoba" )

      // IF lViseKonta
      // aUsl2 := Parsiraj( cIdKonto, "MKONTO" )
      // IF aUsl1 <> NIL
      // EXIT
      // ENDIF
      // ELSE

      IF aUsl1 <> nil
         EXIT
      ENDIF
      // ENDIF
   ENDDO

   cSintetika := "N"

   qqRoba := Trim( qqRoba )

   // snimi parametre u sql/db
   set_metric( "fakt_uporedna_lista_id_firma", my_user(), cIdFirma )
   set_metric( "fakt_uporedna_lista_roba", my_user(), qqRoba )
   set_metric( "fakt_uporedna_lista_datum_od", my_user(), dDatOd )
   set_metric( "fakt_uporedna_lista_datum_do", my_user(), dDatDo )
   set_metric( "fakt_uporedna_lista_razlika_kolicina", my_user(), cRazlKol )
   set_metric( "fakt_uporedna_lista_razlika_vrijednosti", my_user(), cRazlVr )
   set_metric( "fakt_uporedna_lista_mp", my_user(), cMP )
   set_metric( "fakt_uporedna_lista_konta", my_user(), cIdKonto )
   set_metric( "fakt_uporedna_lista_kalk_id_firma", my_user(), cKalkFirma )
   set_metric( "fakt_uporedna_lista_opis_1", my_user(), cOpis1 )
   set_metric( "fakt_uporedna_lista_opis_2", my_user(), cOpis2 )
   set_metric( "fakt_uporedna_lista_konto", my_user(), cIdKonto )

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   // pobrisi pom tabele
   FErase( my_home() + my_dbf_prefix() + "pom.dbf" )
   FErase( my_home() + my_dbf_prefix() + "pom.cdx" )
   FErase( my_home() + my_dbf_prefix() + "pomi1.cdx" )

   aDbf := {}
   AAdd ( aDbf, { "IdRoba", "C", 10, 0 } )
   AAdd ( aDbf, { "FST",    "N", 15, 5 } )
   AAdd ( aDbf, { "FVR",    "N", 15, 5 } )
   AAdd ( aDbf, { "KST",    "N", 15, 5 } )
   AAdd ( aDbf, { "KVR",    "N", 15, 5 } )
   dbCreate( my_home() + my_dbf_prefix() + "pom", aDbf )

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + my_dbf_prefix() + "pom", .F., .T. )
   INDEX ON IdRoba TO ( my_home() + my_dbf_prefix() + "pomi1" )

   SET INDEX TO ( my_home() + my_dbf_prefix() + "pomi1" )

   BoxC()


   find_fakt_za_period( cIdFirma, dDatOd, dDatDo, NIL, NIL, "3" )

   PRIVATE cFilt1 := ""
   cFilt1 := aUsl1 + IF( Empty( dDatOd ), "", ".and.DATDOK>=" + dbf_quote( dDatOd ) ) + ;
      IF( Empty( dDatDo ), "", ".and.DATDOK<=" + dbf_quote( dDatDo ) )
   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ELSE
      SET FILTER TO
   ENDIF

   // veleprodajna cijena u FAKT, uzimam MKONTO u KALK
   cTipC := "V"
   IF select_o_rj( cIdFirma ) .AND. rj->tip == "M"
      cTipC := "M"
   ENDIF

   // SET ORDER TO TAG "3"
   // else
   // u suprotnom, uzimam PKONTO
   // cTipC := "M"


   // find_kalk_za_period( cIdFirma, NIL, NIL, NIL, dDatOd, dDatDo )

   PRIVATE cFilterKalk := ""

/*
   IF lViseKonta
      IF ! RJ->( Found() ) .OR. Empty ( RJ->Tip ) .OR. RJ->Tip = "V"
         // veleprodajna cijena u FAKT, uzimam MKONTO u KALK
         cTipC := "V"
      ELSE
         // u suprotnom, uzimam PKONTO
         aUsl2 := Parsiraj( cIdKonto, "PKONTO" )
         cTipC := "M"
      ENDIF
   ENDIF
*/

   cFilterKalk := aUsl1 + iif( Empty( dDatOd ), "", ".and.DATDOK>=" + dbf_quote( dDatOd ) ) + iif( Empty( dDatDo ), "", ".and.DATDOK<=" + dbf_quote( dDatDo ) )

/*
   IF lViseKonta
      cFilterKalk += ".and." + aUsl2 + ".and.IDFIRMA==" + dbf_quote( cKalkFirma )
      SET ORDER TO TAG "7"
   ENDIF
*/

   cFilterKalk := StrTran( cFilterKalk, ".t..and.", "" )

   // IF !( cFilterKalk == ".t." )
   // SET FILTER TO &cFilterKalk
   // ELSE
   // SET FILTER TO
   // ENDIF

   SELECT FAKT
   GO TOP
   FaktEof := Eof()

   //SELECT KALK
   //GO TOP
   //KalkEof := Eof()

   IF FaktEof  //.AND. KalkEof
      Beep ( 3 )
      Msg ( "FAKT.UP.L: Ne postoje traženi podaci" )
      CLOSERET
   ENDIF

   START PRINT CRET

   SELECT FAKT

   DO WHILE !Eof()

      cIdRoba := IdRoba
      nSt := 0
      nVr := 0

      WHILE !Eof() .AND. cIdRoba == field->IdRoba

         IF field->idfirma <> cIdfirma
            SKIP
            LOOP
         ENDIF

         // atributi
         IF !Empty( AllTrim( cK1 ) )
            IF ck1 <> K1
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( AllTrim( cK2 ) )
            IF ck2 <> K2
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( cIdRoba )
            IF idtipdok = "0"
               // ulaz
               nSt += kolicina
               nVr += Kolicina * Cijena
            ELSEIF idtipdok = "1"
               // izlaz faktura
               IF !( serbr = "*" .AND. idtipdok == "10" )
                  // za fakture na osnovu optpremince ne ra~unaj izlaz
                  nSt -= kolicina
                  nVr -= Kolicina * Cijena
               ENDIF
            ENDIF
         ENDIF
         SKIP
      ENDDO

      IF !Empty( cIdRoba )

         fakt_set_pozicija_sif_roba( cIdRoba, cSintetika == "D" )
         IF cTipVPC == "2" .AND.  roba->( FieldPos( "vpc2" ) <> 0 )
            _cijena := roba->vpc2
         ELSE
            _cijena := IF ( !Empty( cIdFirma ), fakt_mpc_iz_sifrarnika(), roba->vpc )
         ENDIF
         SELECT POM
         APPEND BLANK
         REPLACE IdRoba WITH cIdRoba, FST WITH nSt, FVR WITH nSt * _cijena
         SELECT FAKT
      ENDIF

   ENDDO

   // zatim prodjem KALK (jer nesto moze biti samo u jednom)
   // SELECT KALK


   IF cTipC == "M"
      find_kalk_by_pkonto_idroba( cKalkFirma, cIdKonto )
   ELSE
      find_kalk_by_mkonto_idroba( cKalkFirma, cIdKonto )
   ENDIF
   IF !( cFilterKalk == ".t." )
      SET FILTER TO &cFilterKalk
   ELSE
      SET FILTER TO
   ENDIF
   GO TOP

   DO WHILE !Eof() .AND.  KALK->( IdFirma + iif ( cTipC == "V", MKonto, PKonto ) ) == cKalkFirma + cIdKonto
      cIdRoba := KALK->IdRoba
      nSt := 0
      nVr := 0
      DO WHILE !Eof() .AND. KALK->IdRoba == cIdRoba .AND. IF( lViseKonta, .T., KALK->( IdFirma + iif ( cTipC == "V", MKonto, PKonto ) ) == cKalkFirma + cIdKonto )


         IF cTipC == "V"
            // magacin
            IF mu_i == "1" .AND. !( idvd $ "12#22#94" )    // ulaz
               nSt += kolicina - gkolicina - gkolicin2
               nVr += vpc * ( kolicina - gkolicina - gkolicin2 )
            ELSEIF mu_i == "5"                           // izlaz
               nSt -= kolicina
               nVr -= vpc * ( kolicina )
            ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
               nSt += kolicina
               nVr += vpc * ( kolicina )
            ELSEIF mu_i == "3"    // nivelacija
               nVr += vpc * ( kolicina )
            ENDIF
         ELSE
            // cTipC=="M"
            // prodavnica
            IF pu_i == "1"
               nSt += kolicina - GKolicina - GKolicin2
               nVr += Round( mpcsapp * kolicina, fakt_zaokruzenje() )
            ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
               nSt -= kolicina
               nVr -= Round( mpcsapp * kolicina, fakt_zaokruzenje() )

            ELSEIF pu_i == "I"
               nSt += gkolicin2
               nVr -= mpcsapp * gkolicin2

            ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
               nSt -= kolicina
               nVr -= Round( mpcsapp * kolicina, fakt_zaokruzenje() )
            ELSEIF pu_i == "3"    // nivelacija
               nVr += Round( mpcsapp * kolicina, fakt_zaokruzenje() )
            ENDIF
         ENDIF // cTipC=="V"
         SKIP

      ENDDO

      SELECT POM
      HSEEK cIdRoba // pom
      IF ! Found()
         APPEND BLANK
         REPLACE IdRoba WITH cIdRoba
      ENDIF
      RREPLACE KST WITH nSt, KVR WITH nVr
      SELECT KALK

   ENDDO


   // --------------------------------------------------
   // pocetak ispisa
   ?
   P_COND
   ?? Space( gnLMarg ); IspisFirme( cidfirma )
   ? Space( gnLMarg ); ?? "FAKT: uporedna lager lista u FAKT i KALK na dan", Date(), "   za period od", dDatOd, "-", dDatDo
   IF !Empty( qqRoba )
      ?
      ? Space( gnLMarg )
      ?? "Roba:", qqRoba
   ENDIF

   IF !Empty( cK1 )
      ?
      ? Space( gnlmarg ), "- Roba sa osobinom K1:", ck1
   ENDIF
   IF !Empty( cK2 )
      ?
      ? Space( gnlmarg ), "- Roba sa osobinom K2:", ck2
   ENDIF

   ?
   IF cTipVPC == "2" .AND.  roba->( FieldPos( "vpc2" ) <> 0 )
      ? Space( gnlmarg ); ?? "U IZVJEŠTAJU SU PRIKAZANE CIJENE: " + cTipVPC
   ENDIF
   ?
   m := "----------------------------------------- --- ------------ ------------ ------------ ------------ ------------ ------------"

   ? Space( gnLMarg ); ?? m
   ? Space( gnLMarg )
   ?? "                                         *   *      F   A   K   T      *      K   A   L   K      *      R A Z L I K A"
   ? Space( gnLMarg )
   ??U "Šifra i naziv artikla                    *JMJ*   STANJE   * VRIJEDNOST *   STANJE   * VRIJEDNOST *  KOLIČINA  * VRIJEDNOST"
   ? Space( gnLMarg ); ?? m

   SELECT POM
   GO TOP
   WHILE !Eof()
      IF ( cRazlKol == "D" .AND. Round ( FST, 4 ) <> Round ( KST, 4 ) ) .OR. ( cRazlVr == "D" .AND. Round ( FVR, 4 ) <> Round ( KVR, 4 ) )
         select_o_roba( POM->IdRoba )
         SELECT POM
         ? Space ( gnLMarg )
         ?? ROBA->Id, Left ( ROBA->Naz, 30 ), ROBA->Jmj, ;
            Str ( FST, 12, 3 ), Str ( FVR, 12, 2 ), ;
            Str ( KST, 12, 3 ), Str ( KVR, 12, 2 ), ;
            Str ( FST - KST, 12, 3 ), Str ( FVR - KVR, 12, 2 )
      ENDIF
      SKIP
   ENDDO
   ? Space( gnLMarg ); ?? m

   my_close_all_dbf()

   FF
   ENDPRINT

   RETURN .T.
