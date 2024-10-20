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


FUNCTION ld_asd_aug_obrazac()

   // LOCAL cRj := Space( 65 )
   // LOCAL cIdRj
   LOCAL cIdRj := gLDRadnaJedinica
   LOCAL nMjesec
   LOCAL nGodina
   LOCAL cDopr1X := "1X"
   LOCAL cDopr2X := "2X"
   LOCAL cTipRada := "1"
   LOCAL cVarPrn := "2"
   LOCAL cObracun := gObracun
   LOCAL cIdRadn := Space( 6 )

   ld_aug_cre_dbf_r_export()

   // cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()

   cPredNaz := Space( 50 )
   cPredAdr := Space( 50 )
   cPredJMB := Space( 13 )

   o_tables()

   cPredNaz := fetch_metric( "org_naziv", NIL, cPredNaz )
   cPredNaz := PadR( cPredNaz, 35 )

   cPredAdr := fetch_metric( "ld_firma_adresa", NIL, cPredAdr )
   cPredAdr := PadR( cPredAdr, 35 )

   cPredJMB := fetch_metric( "ld_specifikacija_maticni_broj", NIL, cPredJMB )
   cPredJMB := PadR( cPredJMB, 13 )

   Box( "#RPT: AKONTACIJA POREZA PO ODBITKU", 13, 75 )

   // @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radne jedinice: " GET cRj PICT "@S25"
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica: " GET cIdRj
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Za mjesec:" GET nMjesec PICT "99"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: " GET nGodina PICT "9999"
   @ box_x_koord() + 3, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "   Radnik (prazno-svi):" GET cIdRadn VALID Empty( cIdRadn ) .OR. P_Radn( @cIdRadn )

   @ box_x_koord() + 5, box_y_koord() + 2 SAY "   Doprinos zdr: " GET cDopr1X
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "   Doprinos pio: " GET cDopr2X
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Naziv preduzeca: " GET cPredNaz PICT "@S30"
   @ box_x_koord() + 8, Col() + 1 SAY "JID: " GET cPredJMB
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Adresa: " GET cPredAdr PICT "@S30"

   @ box_x_koord() + 11, box_y_koord() + 2 SAY "(1) AUG-1031 (2) ASD-1032 (3) PDN-1033" ;
      GET cTipRada ;
      VALID cTipRada $ "1#2#3"

   @ box_x_koord() + 12, box_y_koord() + 2 SAY "Varijanta stampe (txt/drb):" GET cVarPrn PICT "@!" VALID cVarPrn $ "12"

   READ

   clvbox()

   ESC_BCR

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "org_naziv", NIL, AllTrim( cPredNaz ) )
   set_metric( "ld_firma_adresa", NIL, AllTrim( cPredAdr ) )
   set_metric( "ld_specifikacija_maticni_broj", NIL, AllTrim( cPredJMB ) )

   // sortiraj tabelu i postavi filter
   // ld_sort( cRj, nGodina, nMjesec, cObracun )

   seek_ld( cIdRj, nGodina, nMjesec, cObracun )
   fill_data( nGodina, nMjesec, cDopr1X, cDopr2X, cTipRada, cObracun, cIdRadn )


   dDatIspl := Date()
   // IF obracuni->( FieldPos( "DAT_ISPL" ) ) <> 0
   cObr := " "
   dDatIspl := ld_get_datum_isplate_plate( "  ", nGodina, nMjesec, cObr )
   // ENDIF

   cPeriod := AllTrim( Str( nMjesec, 2, 0 ) ) + "/" + AllTrim( Str( nGodina, 4, 0 ) )

   IF cVarPrn == "1"
      ak_print( dDatIspl, cPeriod, cTipRada )   // printaj obracunski list
   ENDIF

   IF cVarPrn == "2"
      ld_akontacija_delphirb_print( dDatIspl, cPeriod, cTipRada )
   ENDIF

   RETURN .T.



STATIC FUNCTION fill_data( nGodina, nMjesec, cDopr1X, cDopr2X, cVRada, cObr, cRadnik )

   LOCAL cPom, cIdRadnikTekuci

   SELECT ld

   DO WHILE !Eof() .AND. field->godina == nGodina .AND. field->mjesec == nMjesec

      cIdRadnikTekuci := field->idradn

      IF !Empty( cRadnik )
         IF cIdRadnikTekuci <> cRadnik
            SKIP
            LOOP
         ENDIF
      ENDIF

      cT_tiprada := get_ld_rj_tip_rada( field->idradn, field->idrj )

      select_o_radn( cIdRadnikTekuci )

      lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad ) .AND. cT_tipRada $ "A#U"

      IF ( cVRada $ "1#3" .AND. !( cT_tiprada $ "A#U" ) )  // uzmi samo odgovarajuce tipove rada
         SELECT ld
         SKIP
         LOOP
      ENDIF

      IF ( cVRada == "2" .AND. !( cT_tiprada $ "P" ) )
         SELECT ld
         SKIP
         LOOP
      ENDIF

      IF ( lInRS == .T. .AND. cVRada <> "3" ) .OR. ( lInRS == .F. .AND. cVRada == "3" )  // da li je u rs-u, koji obrazac ?
         SELECT ld
         SKIP
         LOOP
      ENDIF

      cR_jmb := radn->matbr
      cR_naziv := AllTrim( radn->naz ) + " " + AllTrim( radn->ime )

      ld_pozicija_parobr( nMjesec, nGodina, iif( ld_vise_obracuna(), ld->obr, NIL ), ld->idrj )

      SELECT ld

      nRashod := 0
      nPrihod := 0
      nDohodak := 0
      nDopPio := 0
      nDopZdr := 0
      nPorOsn := 0
      nPorIzn := 0
      nTrosk := 0

      DO WHILE !Eof() .AND. field->godina == nGodina .AND. field->mjesec == nMjesec .AND. field->idradn == cIdRadnikTekuci

         // uvijek provjeri tip rada
         cT_tiprada := get_ld_rj_tip_rada( field->idradn, field->idrj )

         lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad ) .AND. cT_tipRada $ "A#U"

         // samo pozicionira bazu PAROBR na odgovarajuci zapis
         ld_pozicija_parobr( nMjesec, nGodina, IF( ld_vise_obracuna(), ld->obr, ), ld->idrj )

         // uzmi samo odgovarajuce tipove rada
         IF ( cVRada == "1" .AND. !( cT_tiprada $ "A#U" ) )
            SKIP
            LOOP
         ENDIF

         IF ( cVRada == "2" .AND. !( cT_tiprada $ "P" ) )
            SKIP
            LOOP
         ENDIF

         nNeto := field->uneto

         cTrosk := radn->trosk

         nKLO := radn->klo

         nL_odb := field->ulicodb

         nTrosk := 0

         IF cT_tiprada == "A"
            nTrosk := gAhTrosk
         ELSEIF cT_tiprada == "U"
            nTrosk := gUgTrosk
         ENDIF

         IF lInRS == .T.
            nTrosk := 0
         ENDIF

         // ako se ne koriste troskovi onda ih i nema !
         IF cTrosk == "N"
            nTrosk := 0
         ENDIF

         // prihod
         nPrihod := ld_get_bruto_osnova( nNeto, cT_tiprada, nL_odb, NIL, cTrosk )

         // rashod
         nRashod := nPrihod * ( nTrosk / 100 )

         // dohodak
         nDohodak := nPrihod - nRashod

         // ukupno dopr iz
         nDoprIz := u_dopr_iz( nDohodak, cT_tiprada )


         // osnovica za porez
         nPorOsn := ( nDohodak - nDoprIz ) - nL_odb

         // porez je ?
         nPorez := izr_porez( nPorOsn, "B" )

         IF lInRS == .T.
            nDoprIz := 0
            nPorOsn := 0
            nPorez := 0
         ENDIF

         SELECT ld

         // ocitaj_izbaci doprinose, njihove iznose
         nDopr1X := get_dopr( cDopr1X, cT_tipRada )
         nDopr2X := get_dopr( cDopr2X, cT_tipRada )

         // izracunaj doprinose
         nIDopr1X := round2( nDohodak * nDopr1X / 100, gZaok2 )
         nIDopr2X := round2( nDohodak * nDopr2X / 100, gZaok2 )

         IF lInRS == .T.
            // nema doprinosa za zdravstvo !
            nIDopr1X := 0
         ENDIF

         SELECT ld

         insert_rec_r_export( cR_jmb, ;
            cR_naziv, ;
            nPrihod, ;
            nRashod, ;
            nDohodak, ;
            nIDopr1X, ;
            nPorOsn, ;
            nPorez, ;
            nIDopr2X )

         SELECT ld
         SKIP

      ENDDO

   ENDDO

   RETURN .T.


// ----------------------------------------------
// stampa akontacije
// ----------------------------------------------
STATIC FUNCTION ak_print( dDatIspl, cPeriod, cTipRada )

   LOCAL cLine := ""
   LOCAL nPageNo := 0
   LOCAL nPoc := 1

   o_r_export_legacy()
   SELECT r_export
   GO TOP

   START PRINT CRET
   ? "#%LANDS#"

   // zaglavlje izvjestaja
   ak_zaglavlje( ++nPageNo, cTipRada, dDatIspl, cPeriod )
   P_COND
   // zaglavlje tabele
   cLine := ak_t_header( cTipRada )

   nUprihod := 0
   nUrashod := 0
   nUdohodak := 0
   nUDopPio := 0
   nUDopZdr := 0
   nUOsnPor := 0
   nUIznPor := 0

   // sracunaj samo total
   DO WHILE !Eof()
      nUPrihod += prihod
      nURashod += rashod
      nUDohodak += dohodak
      nUDopPio += dop_pio
      nUDopZdr += dop_zdr
      nUOsnPor += osn_por
      nUIznPor += izn_por
      SKIP
   ENDDO

   GO TOP

   // sada ispisi izvjestaj
   DO WHILE !Eof()

      ? jmb

      @ PRow(), PCol() + 1 SAY PadR( naziv, 30 )

      IF cTipRada == "1"
         @ PRow(), nPoc := PCol() + 1 SAY Str( prihod, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( rashod, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( dohodak, 12, 2 )
      ELSE
         @ PRow(), nPoc := PCol() + 1 SAY Str( dohodak, 12, 2 )
      ENDIF

      IF cTipRada $ "1#2"
         @ PRow(), PCol() + 1 SAY Str( dop_zdr, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( osn_por, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( izn_por, 12, 2 )
         @ PRow(), PCol() + 1 SAY Str( dop_pio, 12, 2 )
      ELSE
         @ PRow(), PCol() + 1 SAY Str( izn_por, 12, 2 )
      ENDIF

      IF ( nPageNo = 1 .AND. PRow() > 38 ) .OR. ;
            ( nPageNo <> 1 .AND. PRow() > 40 )

         ? cLine

         ? "UKUPNO ZA SVE STRANICE:"

         IF cTipRada == "1"
            @ PRow(), nPoc SAY Str( nUPrihod, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUrashod, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUdohodak, 12, 2 )
         ELSE
            @ PRow(), nPoc SAY Str( nUdohodak, 12, 2 )
         ENDIF

         IF cTipRada $ "1#2"
            @ PRow(), PCol() + 1 SAY Str( nUDopZdr, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUOsnPor, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUIznPor, 12, 2 )
            @ PRow(), PCol() + 1 SAY Str( nUDopPio, 12, 2 )
         ELSE
            @ PRow(), PCol() + 1 SAY Str( nUIznPor, 12, 2 )
         ENDIF

         ? cLine

         IF nPageNo = 1
            ak_potpis()
         ENDIF

         FF

         ak_zaglavlje( ++nPageNo, cTipRada, dDatIspl, cPeriod )
         P_COND
         ak_t_header( cTipRada )

      ENDIF

      SKIP
   ENDDO

   ? cLine

   ? "UKUPNO:"

   IF cTipRada == "1"

      @ PRow(), nPoc SAY Str( nUPrihod, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nUrashod, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nUdohodak, 12, 2 )

   ELSE

      @ PRow(), nPoc SAY Str( nUdohodak, 12, 2 )

   ENDIF

   IF cTipRada $ "1#2"
      @ PRow(), PCol() + 1 SAY Str( nUDopZdr, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nUOsnPor, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nUIznPor, 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( nUDopPio, 12, 2 )
   ELSE
      @ PRow(), PCol() + 1 SAY Str( nUIznPor, 12, 2 )
   ENDIF

   ? cLine

   ak_potpis()

   FF
   ENDPRINT

   RETURN .T.


STATIC FUNCTION ld_akontacija_delphirb_print( dDatIspl, cPeriod, cTipRada )

   LOCAL cLine := ""
   LOCAL nPageNo := 0
   LOCAL nPoc := 1
   LOCAL cIni := my_home() + "proizvj.ini"
   LOCAL cRtmFile := ""

   PRIVATE cKom := ""

   o_r_export_legacy()
   SELECT r_export
   INDEX ON naziv TAG "1"
   GO TOP

   // upisi podatke za header
   UzmiIzIni( cIni, "Varijable", "ISP_NAZ", cPredNaz, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "ISP_ADR", cPredAdr, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "ISP_JMB", cPredJMB, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "ISP_PER", cPeriod, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "ISP_DAT", DToC( dDatIspl ), "WRITE" )

   nUprihod := 0
   nUrashod := 0
   nUdohodak := 0
   nUDopPio := 0
   nUDopZdr := 0
   nUOsnPor := 0
   nUIznPor := 0

   // sracunaj samo total
   DO WHILE !Eof()
      nUPrihod += prihod
      nURashod += rashod
      nUDohodak += dohodak
      nUDopPio += dop_pio
      nUDopZdr += dop_zdr
      nUOsnPor += osn_por
      nUIznPor += izn_por
      SKIP
   ENDDO

   // upisi totale
   UzmiIzIni( cIni, "Varijable", "TOT_PRIH", nUPrihod, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_RAS", nURashod, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_DOH", nUDohodak, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_ZDR", nUDopZdr, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_OP", nUOsnPor, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_IP", nUIznPor, "WRITE" )
   UzmiIzIni( cIni, "Varijable", "TOT_PIO", nUDopPio, "WRITE" )

   SELECT r_export
   USE

   IF cTipRada == "1"
      cRtm := "aug1031"
   ELSEIF cTipRada == "2"
      cRtm := "asd1032"
   ELSEIF cTipRada == "3"
      cRtm := "pdn1033"
   ENDIF

   my_close_all_dbf()

   // stampaj akontaciju poreza delphi
   f18_rtm_print( AllTrim( cRtm ), "r_export", "1" )

   RETURN .T.




// ---------------------------------------
// potpis za obrazac GIP
// ---------------------------------------
STATIC FUNCTION ak_potpis()

   P_12CPI
   P_COND
   ? "Upoznat sam sa sankicajama propisanim Zakonom o Poreznoj upravi FBIH i izjavljujem"
   ? "da su svi podaci navedeni u ovoj prijavi tacni, potpuni i jasni", Space( 10 ) + "Potpis poreznog obveznika", Space( 5 ) + "Datum:"

   RETURN .T.


// ----------------------------------------
// stampa headera tabele
// ----------------------------------------
STATIC FUNCTION ak_t_header( cVRada )

   LOCAL aLines := {}
   LOCAL aTxt := {}
   LOCAL i
   LOCAL cLine := ""
   LOCAL cTxt1 := ""
   LOCAL cTxt2 := ""
   LOCAL cTxt3 := ""
   LOCAL cTxt4 := ""

   AAdd( aLines, { Replicate( "-", 13 ) } )
   AAdd( aLines, { Replicate( "-", 30 ) } )
   IF cVRada == "1"
      AAdd( aLines, { Replicate( "-", 12 ) } )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   AAdd( aLines, { Replicate( "-", 12 ) } )
   IF cVRada $ "1#2"
      AAdd( aLines, { Replicate( "-", 12 ) } )
      AAdd( aLines, { Replicate( "-", 12 ) } )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   AAdd( aLines, { Replicate( "-", 12 ) } )

   IF cVRada == "1"
      AAdd( aTxt, { "JMB poreznog", "obveznika", "", "7" } )
      AAdd( aTxt, { "Prezime i ime", "poreznog obveznika", "", "8" } )
      AAdd( aTxt, { "Iznos", "prihoda", "", "9" } )
      AAdd( aTxt, { "Iznos", "rashoda", "(20% ili 30%)", "10" } )
      AAdd( aTxt, { "Iznos", "dohotka", "(9 - 10)", "11" } )
      AAdd( aTxt, { "Zdravstveno", "osiguranje", "(11 x 0.04)", "12" } )
      AAdd( aTxt, { "Osnovica", "za porez", "(11 - 12)", "13" } )
      AAdd( aTxt, { "Iznos", "poreza", "(13 x 0.1)", "14" } )
      AAdd( aTxt, { "PIO", "", "(11 x 0.06)", "15" } )
   ELSEIF cVRada == "2"
      AAdd( aTxt, { "JMB poreznog", "obveznika", "", "6" } )
      AAdd( aTxt, { "Prezime i ime", "poreznog obveznika", "", "7" } )
      AAdd( aTxt, { "Iznos", "dohotka", "", "8" } )
      AAdd( aTxt, { "Zdravstveno", "osiguranje", "(8 x 0.04)", "9" } )
      AAdd( aTxt, { "Osnovica", "za porez", "(8 - 9)", "10" } )
      AAdd( aTxt, { "Iznos", "poreza", "(10 x 0.1)", "11" } )
      AAdd( aTxt, { "PIO", "", "(8 x 0.06)", "12" } )
   ELSEIF cVRada == "3"
      AAdd( aTxt, { "JMB poreznog", "obveznika", "", "6" } )
      AAdd( aTxt, { "Prezime i ime", "poreznog obveznika", "", "7" } )
      AAdd( aTxt, { "Isplaceni", "iznos", "", "8" } )
      AAdd( aTxt, { "Iznos", "poreza", "(8 x 0.1)", "9" } )
   ENDIF

   FOR i := 1 TO Len( aLines )
      cLine += aLines[ i, 1 ] + Space( 1 )
   NEXT

   FOR i := 1 TO Len( aTxt )

      // koliko je sirok tekst ?
      nTxtLen := Len( aLines[ i, 1 ] )

      // prvi red
      cTxt1 += PadC( "(" + aTxt[ i, 4 ] + ")", nTxtLen ) + Space( 1 )
      cTxt2 += PadC( aTxt[ i, 1 ], nTxtLen ) + Space( 1 )
      cTxt3 += PadC( aTxt[ i, 2 ], nTxtLen ) + Space( 1 )
      cTxt4 += PadC( aTxt[ i, 3 ], nTxtLen ) + Space( 1 )

   NEXT

   // ispisi zaglavlje tabele
   ? cLine
   ? cTxt1
   ? cTxt2
   ? cTxt3
   ? cTxt4
   ? cLine

   RETURN cLine



// ----------------------------------------
// stampa zaglavlja izvjestaja
// ----------------------------------------
STATIC FUNCTION ak_zaglavlje( nPage, cTipRada, dDIspl, cPeriod )

   LOCAL cObrazac
   LOCAL cInfo

   IF cTipRada == "1"
      cObrazac := "Obrazac AUG-1031"
      cInfo := "ZA POVREMENE SAMOSTALNE DJELATNOSTI"
   ELSEIF cTipRada == "2"
      cObrazac := "Obrazac ASD-1032"
      cInfo := "NA PRIHODE OD DRUGIH SAMOSTALNIH DJELATNOSTI"
   ELSEIF cTipRada == "3"
      cObrazac := "Obrazac PDN-1033"
      cInfo := "POVREMENE DJELATNOSTI U REPUBLICI SRPSKOJ"
   ENDIF

   ?
   P_10CPI
   B_ON
   ? Space( 10 ) + cObrazac
   ? Space( 2 ) + "AKONTACIJA POREZA PO ODBITKU"
   ? Space( 2 ) + cInfo
   B_OFF
   P_10CPI
   @ PRow(), PCol() + 10 SAY "Stranica: " + AllTrim( Str( nPage ) )
   P_COND

   IF cTipRada == "1"
      ? "  1) Vrsta prijave:"
      ? "     a) Povremene samostalne djelatnosti   b) autorski honorari"
      ?
   ELSE
      ?
   ENDIF

   ? "Dio 1 - podaci o isplatiocu"
   P_12CPI

   ? PadR( "Naziv: " + cPredNaz, 60 ), "JIB/JMB: " + cPredJmb
   ? PadR( "Adresa: " + cPredAdr, 60 ), "Datum isplate: " + DToC( dDIspl ), ;
      "Period: " + cPeriod

   ?
   P_10CPI
   P_COND
   ? Space( 1 ) + "Dio 2 - podaci o prihodima, porezu i doprinosima"

   RETURN .T.


STATIC FUNCTION insert_rec_r_export( cJMB, cRadnNaz, nPrihod, ;
      nRashod, nDohodak, nDopZdr, ;
      nOsn_por, nIzn_por, nDopPio )

   LOCAL nTArea := Select()

   o_r_export_legacy()
   SELECT r_export
   APPEND BLANK

   REPLACE jmb WITH cJMB
   REPLACE naziv WITH cRadnNaz
   REPLACE prihod WITH nPrihod
   REPLACE rashod WITH nRashod
   REPLACE dohodak WITH nDohodak
   REPLACE dop_zdr WITH nDopZdr
   REPLACE osn_por WITH nOsn_Por
   REPLACE izn_por WITH nIzn_Por
   REPLACE dop_pio WITH nDopPio

   SELECT ( nTArea )

   RETURN .T.


// ---------------------------------------------
// kreiranje pomocne tabele
// ---------------------------------------------
STATIC FUNCTION ld_aug_cre_dbf_r_export()

   LOCAL aDbf := {}

   AAdd( aDbf, { "JMB", "C", 13, 0 } )
   AAdd( aDbf, { "NAZIV", "C", 30, 0 } )
   AAdd( aDbf, { "PRIHOD", "N", 12, 2 } )
   AAdd( aDbf, { "RASHOD", "N", 12, 2 } )
   AAdd( aDbf, { "DOHODAK", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_ZDR", "N", 12, 2 } )
   AAdd( aDbf, { "OSN_POR", "N", 12, 2 } )
   AAdd( aDbf, { "IZN_POR", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_PIO", "N", 12, 2 } )

   xlsx_export_init( aDbf )

   RETURN .T.

STATIC FUNCTION o_tables()

   o_ld_obracuni()
   o_ld_parametri_obracuna()
   o_params()
   o_ld_rj()
   o_ld_radn()
   o_dopr()
   o_por()
   // select_o_ld()

   RETURN .T.
