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

// pos komande
STATIC F_POS_RN := "POS_RN"
STATIC ANSW_DIR := "answer"
STATIC POLOG_LIMIT := 100

// ocekivana matrica
// aData
//
// 1 - broj racuna
// 2 - redni broj
// 3 - id roba
// 4 - roba naziv
// 5 - cijena
// 6 - kolicina
// 7 - tarifa
// 8 - broj racuna za storniranje
// 9 - roba plu
// 10 - plu cijena - cijena iz sifranika
// 11 - popust
// 12 - barkod
// 13 - vrsta placanja
// 14 - total racuna
// 15 - datum racuna

// --------------------------------------------------------
// fiskalni racun (FPRINT)
// aData - podaci racuna
// lStorno - da li se stampa storno ili ne (.T. ili .F. )
// --------------------------------------------------------
FUNCTION fiskalni_fprint_racun( hFiskalniParams, aRacunData, aKupac, lStorno )

   LOCAL cSeparator := ";"
   LOCAL aFprintArray := {}
   LOCAL aFprintStruct := {}
   LOCAL nErr := 0

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   aFprintStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN ) // uzmi strukturu tabele za pos racun
   aFprintArray := fisk_fprint_get_array( aRacunData, aKupac, lStorno, hFiskalniParams )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aFprintStruct, aFprintArray )

   RETURN nErr



// --------------------------------------------------
// provjerava unos pologa, maksimalnu vrijednost
// --------------------------------------------------
STATIC FUNCTION _max_polog( nPolog )

   LOCAL lOk := .T.

   IF nPolog > POLOG_LIMIT
      IF Pitanje(, "Depozit je > " + AllTrim( Str( POLOG_LIMIT ) ) + "! Da li je ovo ispravan unos (D/N) ?", "N" ) == "N"
         lOk := .F.
      ENDIF
   ENDIF

   RETURN lOk


FUNCTION fprint_unos_pologa( hFiskalniParams, nPolog, lShowBox )

   LOCAL cSep := ";"
   LOCAL aPolog := {}
   LOCAL aStruct := {}
   LOCAL GetList := {}

   IF nPolog == NIL
      nPolog := 0
   ENDIF

   IF lShowBox == NIL
      lShowBox := .F.
   ENDIF

   IF nPolog == 0 .OR. lShowBox
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Zadužujem kasu za:" GET nPolog PICT "999999.99" VALID _max_polog( nPolog )
      READ
      BoxC()

      IF nPolog = 0
         MsgBeep( "Vrijednost depozita mora biti <> 0 !" )
         RETURN .F.
      ENDIF
      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF
   ENDIF

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aPolog := fprint_unos_pologa_array( nPolog )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aPolog )

   RETURN .T.


FUNCTION fprint_dupliciraj_racun( hFiskalniParams, hRacunParams )

   LOCAL cSep := ";"
   LOCAL aDouble := {}
   LOCAL aStruct := {}
   LOCAL dDatumFrom := Date()
   LOCAL dDatumTo := dDatumFrom
   LOCAL cTimeVrijemeFrom := "12"
   LOCAL cTM_from := "30"
   LOCAL cTimeVrijemeTo := "12"
   LOCAL cTM_to := "31"
   LOCAL cTimeFrom
   LOCAL cTimeTo
   LOCAL cType := "F"
   LOCAL lBoxPrikazati := .F.
   LOCAL GetList := {}

   IF hRacunParams == NIL
      lBoxPrikazati := .T.
   ENDIF

   IF lBoxPrikazati

      Box(, 10, 60 )

      set_cursor_on()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Za datum od:" GET dDatumFrom
      @ box_x_koord() + 1, Col() + 1 SAY "vrijeme od (hh:mm):" GET cTimeVrijemeFrom
      @ box_x_koord() + 1, Col() SAY ":" GET cTM_from
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "         do:" GET dDatumTo
      @ box_x_koord() + 2, Col() + 1 SAY "vrijeme do (hh:mm):" GET cTimeVrijemeTo
      @ box_x_koord() + 2, Col() SAY ":" GET cTM_to
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "--------------------------------------"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "A - duplikat svih dokumenata"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "F - duplikat fiskalnog računa"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "R - duplikat reklamnog računa"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Z - duplikat Z izvještaja"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "X - duplikat X izvještaja"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "P - duplikat periodičnog izvještaja" GET cType VALID cType $ "AFRZXP" PICT "@!"

      READ
      BoxC()
      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

      // dodaj i sekunde na kraju
      cTimeFrom := cTimeVrijemeFrom + cTM_from + "00"
      cTimeTo := cTimeVrijemeTo + cTM_to + "00"

   ELSE

      IF Empty( hRacunParams[ "vrijeme" ] )
         MsgBeep( "Opciju nije moguće izvršiti, nije definisano vrijeme !" )
         RETURN .F.
      ENDIF

      IF hRacunParams[ "datum" ] == CToD( "" )
         MsgBeep( "Opciju nije moguće izvršiti, nije definisan datum !" )
         RETURN .F.
      ENDIF

      // imamo parametre racuna...
      IF hRacunParams[ "storno" ]
         cType := "R"
      ELSE
         cType := "F"
      ENDIF


      dDatumFrom := hRacunParams[ "datum" ]
      dDatumTo := hRacunParams[ "datum" ]

      // vrijeme 15:34
      cTimeFrom := fprint_fix_time( hRacunParams[ "vrijeme" ], -.5 )
      cTimeTo := fprint_fix_time( hRacunParams[ "vrijeme" ], 1 )

   ENDIF

   // uzmi strukturu tabele za pos racun
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )

   // iscitaj pos matricu
   aDouble := fprint_duplikat_dokumenta( cType, dDatumFrom, dDatumTo, cTimeFrom, cTimeTo )

   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aDouble )

   RETURN .T.



STATIC FUNCTION fprint_fix_time( cTimeIn, nFix )

   LOCAL cTime := ""
   LOCAL aTmp := TokToNiz( cTimeIn, ":" )
   LOCAL cHour := aTmp[ 1 ]
   LOCAL cMinuta := aTmp[ 2 ]

   cTime := hb_DateTime( 0, 0, 0, Val( cHour ), Val( cMinuta ) + nFix, 0 )
   cTime := Right( AllTrim( hb_TToC( cTime ) ), 12 )
   cTime := PadR( cTime, 5 ) + "00"
   cTime := StrTran( cTime, ":", "" )

   RETURN cTime


FUNCTION fprint_komanda_301_zatvori_racun( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aVoid := {}
   LOCAL aStruct := {}

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN ) // uzmi strukturu tabele za pos racun
   // iscitaj pos matricu
   aVoid := fprint_nasilno_zatvori_racun_iznos_0()
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aVoid )

   RETURN .T.


FUNCTION fprint_non_fiscal_text( hFiskalniParams, cTxt )

   LOCAL cSep := ";"
   LOCAL aTxt := {}
   LOCAL aStruct := {}

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN ) // uzmi strukturu tabele za pos racun
   aTxt := fprint_non_fiscal_text_posalji_na_uredjaj( to_win1250_encoding( cTxt ) )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aTxt )

   RETURN .T.


FUNCTION fprint_delete_plu( hFiskalniParams, lSilent )

   LOCAL cSep := ";"
   LOCAL aDel := {}
   LOCAL aStruct := {}
   LOCAL nMaxPlu := 0
   LOCAL GetList := {}

   IF lSilent == NIL
      lSilent := .T.
   ENDIF

   IF !lSilent
      IF !spec_funkcije_sifra( "RESET" )
         RETURN .F.
      ENDIF
      Box(, 1, 50 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi max.plu vrijednost:" GET nMaxPlu PICT "9999999999"
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

   ENDIF

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aDel := fprint_brisi_artikle_iz_uredjaja( nMaxPlu, hFiskalniParams )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aDel )

   RETURN .T.


FUNCTION fiscal_fprint_zatvori_racun( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aClose := {}
   LOCAL aStruct := {}

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aClose := fprint_zatvori_racun()
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aClose )

   RETURN .T.


FUNCTION fprint_manual_cmd( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aManCmd := {}
   LOCAL aStruct := {}
   LOCAL nCmd := 0
   LOCAL cCond := Space( 150 )
   LOCAL cErr := "N"
   LOCAL nErr := 0
   LOCAL GetList := {}

   Box(, 4, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "**** PROIZVOLJNE KOMANDE ****"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "   broj komande:" GET nCmd PICT "999" VALID nCmd > 0
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "        komanda:" GET cCond PICT "@S40"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "provjera greške:" GET cErr PICT "@!" VALID cErr $ "DN"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aManCmd := fprint_manuelne_komande( nCmd, cCond )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aManCmd )

   IF cErr == "D"
      nErr := fprint_read_error( hFiskalniParams, 0 )
      IF nErr <> 0
         MsgBeep( "Postoji greška kod izvršenja proizvoljne komande !" )
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION fprint_sold_plu( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aPlu := {}
   LOCAL aStruct := {}
   LOCAL nErr := 0
   LOCAL cType := "0"
   LOCAL GetList := {}

   Box(, 4, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "**** uslovi pregleda artikala ****" COLOR f18_color_i()
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "0 - samo u današnjem prometu "
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "1 - svi programirani          -> " GET cType VALID cType $ "01"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   fprint_delete_answer( hFiskalniParams )
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aPlu := fprint_izvjestaj_o_prodanim_plu( cType )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aPlu )

   RETURN .T.


FUNCTION fprint_daily_rpt( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aDaily := {}
   LOCAL aStruct := {}
   LOCAL nErr := 0
   LOCAL cType := "0"
   LOCAL cReportTip := "Z"
   LOCAL cParamDate, cParamTime
   LOCAL dLastDate, cLastTime
   LOCAL GetList := {}

   cType := fetch_metric( "fiscal_fprint_daily_type", my_user(), cType )

   Box(, 4, 55 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "**** varijanta dnevnog izvještaja ****" COLOR f18_color_i()
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "0 - z-report (dnevni izvještaj)"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "2 - x-report   (presjek stanja) -> " GET cType VALID cType $ "02"
   READ
   BoxC()
   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "fiscal_fprint_daily_type", my_user(), cType )

   IF cType == "2"
      cReportTip := "X"
   ENDIF

   cParamDate := "zadnji_" + cReportTip + "_izvjestaj_datum"
   cParamTime := "zadnji_" + cReportTip + "_izvjestaj_vrijeme"

   dLastDate := fetch_metric( cParamDate, nil, CToD( "" ) )
   cLastTime := PadR( fetch_metric( cParamTime, nil, "" ), 5 )

   IF cReportTip == "Z" .AND. dLastDate == Date()
      MsgBeep( "Zadnji Z izvještaj rađen: " + DToC( dLastDate ) + ", u " + cLastTime )
   ENDIF

   IF Pitanje(, "Štampati dnevni izvještaj ?", "D" ) == "N"
      RETURN .F.
   ENDIF

   fprint_delete_answer( hFiskalniParams )
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aDaily := fprint_dnevni_fiskalni_izvjestaj( cType )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aDaily )
   nErr := fprint_read_error( hFiskalniParams, 0 )

   IF nErr <> 0
      MsgBeep( "Greška sa štampom dnevnog izvještaja !" )
      RETURN .F.
   ENDIF

   set_metric( cParamDate, nil, Date() )
   set_metric( cParamTime, nil, Time() )
   IF hFiskalniParams[ "plu_type" ] == "D" .AND. cReportTip == "Z"

      MsgO( "Nuliram stanje uređaja ..." )
      IF hFiskalniParams[ "type" ] == "P"
         fprint_delete_answer( hFiskalniParams )
         Sleep( 10 )
         fprint_delete_plu( hFiskalniParams, .T. )
         nErr := fprint_read_error( hFiskalniParams, 0, NIL, 500 )
         IF nErr <> 0
            MsgBeep( "Greška sa nuliranjem stanja uređaja !" )
            RETURN .F.
         ENDIF
      ENDIF
      MsgC()

      auto_plu( .T., .T., hFiskalniParams )
      MsgBeep( "Stanje fiskalnog uređaja je nulirano." )

   ENDIF

   IF hFiskalniParams[ "auto_avans" ] <> 0 .AND. cReportTip == "Z"
      MsgO( "Automatski unos pologa u fiskalni uređaj... sačekajte." )
      Sleep( 10 )
      fprint_unos_pologa( hFiskalniParams, hFiskalniParams[ "auto_avans" ] )
      MsgC()
   ENDIF

   RETURN .T.



FUNCTION fprint_izvjestaj_za_period( hFiskalniParams )

   LOCAL cSep := ";"
   LOCAL aPer := {}
   LOCAL aStruct := {}
   LOCAL nErrLevel := 0
   LOCAL dDatumFrom := Date() - 30
   LOCAL dDatumTo := Date()
   LOCAL GetList := {}

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Za period od" GET dDatumFrom
   @ box_x_koord() + 1, Col() + 1 SAY "do" GET dDatumTo
   READ
   BoxC()
   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aPer := fprint_fiskalni_izvjestaj_od_do( dDatumFrom, dDatumTo )
   fiskalni_array_to_fajl( hFiskalniParams[ "out_dir" ], hFiskalniParams[ "out_file" ], aStruct, aPer )
   nErrLevel := fprint_read_error( hFiskalniParams, 0 )

   IF nErrLevel <> 0
      MsgBeep( "Postoji greška sa štampanjem izvještaja !" )
   ENDIF

   RETURN nErrLevel


STATIC FUNCTION fisk_fprint_get_array( aData, aKupac, lStorno, hFiskalniParams )

   LOCAL aArr := {}
   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL i
   LOCAL cRek_rn := ""
   LOCAL cRnBroj
   LOCAL cOperator := "1"
   LOCAL cOperaterPassword := "000000"
   LOCAL nTotal := 0
   LOCAL cVrstaPlacanja := "0"
   LOCAL lConvertTo852 := .T.
   LOCAL cOperater

   IF !Empty( hFiskalniParams[ "op_id" ] ) // provjeri operatera i lozinku iz podesenja...
      cOperater := hFiskalniParams[ "op_id" ]
   ENDIF
   IF !Empty( hFiskalniParams[ "op_pwd" ] )
      cOperaterPassword := hFiskalniParams[ "op_pwd" ]
   ENDIF

   cVrstaPlacanja := AllTrim( aData[ 1, 13 ] )
   nTotal := aData[ 1, 14 ]

   IF nTotal == NIL
      nTotal := 0
   ENDIF

   // ocekuje se matrica formata
   // aData { brrn, rbr, idroba, nazroba, cijena, kolicina, porstopa,
   // rek_rn, plu, plu_cijena, popust, barkod, vrsta plac, total racuna }
   fprint_dodaj_artikle_za_racun( @aArr, aData, lStorno, hFiskalniParams )

   cRnBroj := AllTrim( aData[ 1, 1 ] ) // broj racuna
   cLogic := "1"

   // 1) otvaranje fiskalnog racuna
   cTmp := "48"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += hFiskalniParams[ "iosa" ]
   cTmp += cSep
   cTmp += cOperator
   cTmp += cSep
   cTmp += cOperaterPassword
   cTmp += cSep

   IF lStorno == .T.
      cRek_rn := AllTrim( aData[ 1, 8 ] )
      cTmp += cSep
      cTmp += cRek_rn
      cTmp += cSep
   ELSE
      cTmp += cSep
   ENDIF
   AAdd( aArr, { cTmp } )

   // 2. prodaja stavki
   FOR i := 1 TO Len( aData )
      cTmp := "52"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep

      // kod PLU
      cTmp += AllTrim( Str( aData[ i, 9 ] ) )
      cTmp += cSep
      // kolicina 0-99999.999
      cTmp += AllTrim( Str( aData[ i, 6 ], 12, 3 ) )
      cTmp += cSep
      // popust 0-99.99%
      IF aData[ i, 10 ] > 0
         cTmp += "-" + AllTrim( Str( aData[ i, 11 ], 10, 2 ) )
      ENDIF
      cTmp += cSep

      AAdd( aArr, { cTmp } )
   NEXT

   // 3. subtotal
   cTmp := "51"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )
   // 4. nacin placanja
   cTmp := "53"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   // 0 - cash
   // 1 - card
   // 2 - chek
   // 3 - virman

   IF ( cVrstaPlacanja <> "0" .AND. !lStorno ) .OR. ( cVrstaPlacanja == "0" .AND. nTotal <> 0 .AND. !lStorno )
      // imamo drugu vrstu placanja
      cTmp += cVrstaPlacanja
      cTmp += cSep
      cTmp += AllTrim( Str( nTotal, 12, 2 ) )
      cTmp += cSep
   ELSE
      cTmp += cSep
      cTmp += cSep
   ENDIF

   AAdd( aArr, { cTmp } )

   // radi zaokruzenja kod virmanskog placanja
   // salje se jos jedna linija 53 ali prazna
   IF cVrstaPlacanja <> "0" .AND. !lStorno

      cTmp := "53"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += cSep
      cTmp += cSep
      AAdd( aArr, { cTmp } )

   ENDIF

   // 5. kupac - podaci
   IF aKupac <> NIL .AND. Len( aKupac ) > 0

      // aKupac = { idbroj, naziv, adresa, ptt, mjesto }
      // postoje podaci...
      cTmp := "55"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep

      // 1. id broj
      cTmp += AllTrim( aKupac[ 1, 1 ] )
      cTmp += cSep

      // 2. naziv
      cTmp += AllTrim( PadR( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 2 ] ), lConvertTo852 ), 36 ) )
      cTmp += cSep

      // 3. adresa
      cTmp += AllTrim( PadR( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 3 ] ), lConvertTo852 ), 36 ) )
      cTmp += cSep

      // 4. ptt, mjesto
      cTmp += AllTrim( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 4 ] ), lConvertTo852 ) ) + " " + ;
         AllTrim( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 5 ] ), lConvertTo852 ) )

      cTmp += cSep
      cTmp += cSep
      cTmp += cSep

      AAdd( aArr, { cTmp } )

   ENDIF

   // 6. otvaranje ladice
   cTmp := "106"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   // 7. zatvaranje racuna
   cTmp := "56"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_manuelne_komande( nCmd, cCond )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"

   // broj komande
   cTmp := AllTrim( Str( nCmd ) )
   // ostali regularni dio
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   IF !Empty( cCond )
      // ostatak komande
      cTmp += AllTrim( cCond )
   ENDIF
   AAdd( aArr, { cTmp } )

   RETURN aArr


STATIC FUNCTION fprint_non_fiscal_text_posalji_na_uredjaj( cTxt )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"

   // otvori non-fiscal racun
   cTmp := "38"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   // ispisi tekst
   cTmp := "42"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += AllTrim( PadR( cTxt, 30 ) )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   // zatvori non-fiscal racun
   cTmp := "39"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_brisi_artikle_iz_uredjaja( nMaxPlu, hFiskalniParams )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   // komanda za brisanje artikala je 3
   LOCAL cCmd := "3"
   LOCAL cCmdType := ""
   LOCAL nTArea := Select()
   LOCAL nLastPlu := 0

   IF nMaxPlu <> 0
      // ovo ce biti granicni PLU za reset
      nLastPlu := nMaxPlu
   ELSE
      // uzmi zadnji PLU iz parametara
      nLastPlu := fiskalni_get_last_plu( hFiskalniParams[ "id" ] )
   ENDIF

   SELECT ( nTArea )

   // brisat ces sve od plu = 1 do zadnji plu
   cCmdType := "1;" + AllTrim( Str( nLastPlu ) )

   cLogic := "1"
   // brisanje PLU kodova iz uredjaja
   cTmp := "107"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cCmd
   cTmp += cSep
   cTmp += cCmdType
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_zatvori_racun()

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"
   // 7. zatvaranje racuna
   cTmp := "56"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr


FUNCTION fprint_formatiranje_datuma( dDate )

   LOCAL cRet := ""
   LOCAL nM := Month( dDate )
   LOCAL nD := Day( dDate )
   LOCAL nY := Year( dDate )

   // format datuma treba da bude DDMMYY
   cRet := PadL( AllTrim( Str( nD ) ), 2, "0" )
   cRet += PadL( AllTrim( Str( nM ) ), 2, "0" )
   cRet += Right( AllTrim( Str( nY ) ), 2 )

   RETURN cRet



STATIC FUNCTION fprint_fiskalni_izvjestaj_od_do( dDatumFrom, dDatumTo )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL cD_from
   LOCAL cD_to
   LOCAL aArr := {}

   cD_from := fprint_formatiranje_datuma( dDatumFrom )
   cD_to := fprint_formatiranje_datuma( dDatumTo )

   cLogic := "1"
   cTmp := "79"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cD_from
   cTmp += cSep
   cTmp += cD_to
   cTmp += cSep
   cTmp += cSep
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_izvjestaj_o_prodanim_plu( cType )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   // 0 - samo u toku dana
   // 1 - svi programirani

   IF cType == nil
      cType := "0"
   ENDIF

   cLogic := "1"
   cTmp := "111"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cType
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_dnevni_fiskalni_izvjestaj( cType )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   // "N" - bez ciscenja prodaje
   // "A" - sa ciscenjem prodaje
   LOCAL cOper := "A"

   // 0 - "Z"
   // 2 - "X"
   IF cType == nil
      cType := "0"
   ENDIF

   IF cType == "2"
      // kod X reporta ne treba zadnji parametar
      cOper := ""
   ENDIF

   cLogic := "1"
   cTmp := "69"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cType
   cTmp += cSep

   // ovo se dodaje samo kod Z reporta
   IF !Empty ( cOper )
      cTmp += cOper
      cTmp += cSep
   ENDIF
   AAdd( aArr, { cTmp } )

   RETURN aArr




STATIC FUNCTION fprint_duplikat_dokumenta( cType, dDatumFrom, dDatumTo, cTimeFrom, cTimeTo )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}
   LOCAL cStart := ""
   LOCAL cEnd := ""
   LOCAL cParam := "0"

   // sredi start i end linije
   cStart := fprint_formatiranje_datuma( dDatumFrom ) + cTimeFrom
   cEnd := fprint_formatiranje_datuma( dDatumTo ) + cTimeTo

   cLogic := "1"
   cTmp := "109"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cType
   cTmp += cSep
   cTmp += cStart
   cTmp += cSep
   cTmp += cEnd
   cTmp += cSep
   cTmp += cParam
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_unos_pologa_array( nIznos )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}
   LOCAL cZnak := "+"

   IF nIznos < 0
      cZnak := ""
   ENDIF

   cLogic := "1"
   cTmp := "70"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cZnak + AllTrim( Str( nIznos ) )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_nasilno_zatvori_racun_iznos_0()

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"

   cTmp := "301"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep

   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION fprint_dodaj_artikle_za_racun( aArr, aData, lStorno, hFiskalniParams )

   LOCAL i
   LOCAL cTmp := ""

   // opcija dodavanja artikla u printer <1|2>
   // 1 - dodaj samo jednom
   // 2 - mozemo dodavati vise puta
   LOCAL cOp_add := "2"
   // opcija promjene cijene u printeru
   LOCAL cOp_ch := "4"
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL lConvertTo852 := .T.

   // ocekuje se matrica formata
   // aData { brrn, rbr, idroba, nazroba, cijena, kolicina, porstopa,
   // rek_rn, plu, plu_cijena, popust }

   cLogic := "1"

   FOR i := 1 TO Len( aData )

      // 1. dodavanje artikla u printer
      cTmp := "107"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep

      cTmp += cOp_add // opcija dodavanja "2"
      cTmp += cSep

      cTmp += fiskalni_tarifa( aData[ i, 7 ], hFiskalniParams[ "pdv" ], "FPRINT" ) // poreska stopa
      cTmp += cSep

      // plu kod
      cTmp += AllTrim( Str( aData[ i, 9 ] ) )
      cTmp += cSep

      // plu cijena
      cTmp += AllTrim( Str( aData[ i, 10 ], 12, 2 ) )
      cTmp += cSep

      // plu naziv
      cTmp += to_win1250_encoding( AllTrim( PadR( hb_StrToUTF8( aData[ i, 4 ] ), 32 ) ), lConvertTo852 )
      cTmp += cSep

      AAdd( aArr, { cTmp } )

      // 2. dodavanje stavke promjena cijene - ako postoji

      cTmp := "107"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep

      // opcija dodavanja "4"
      cTmp += cOp_ch
      cTmp += cSep

      // plu kod
      cTmp += AllTrim( Str( aData[ i, 9 ] ) )
      cTmp += cSep

      // plu cijena
      cTmp += AllTrim( Str( aData[ i, 10 ], 12, 2 ) )
      cTmp += cSep
      AAdd( aArr, { cTmp } )

   NEXT

   RETURN .T.


FUNCTION fprint_delete_answer( hFiskalniParams )

   LOCAL cFileName

   cFileName := hFiskalniParams[ "out_dir" ] + ANSW_DIR + SLASH + hFiskalniParams[ "out_answer" ]
   IF Empty( hFiskalniParams[ "out_answer" ] )
      cFileName := hFiskalniParams[ "out_dir" ] + ANSW_DIR + SLASH + hFiskalniParams[ "out_file" ]
   ENDIF

   // ako postoji fajl obrisi ga
   IF File( cFileName )
      IF FErase( cFileName ) = -1
         MsgBeep( "Greška sa brisanjem fajla odgovora !" )
      ENDIF
   ENDIF

   RETURN .T.



FUNCTION fprint_delete_out( file_path )

   IF File( file_path )
      IF FErase( file_path ) = -1
         MsgBeep( "Greška sa brisanjem izlaznog fajla !" )
      ENDIF
   ENDIF

   RETURN .T.


// ------------------------------------------------
// citanje gresaka za FPRINT driver
// vraca broj
// 0 - sve ok
// -9 - ne postoji answer fajl
//
// nFisc_no - broj fiskalnog isjecka
// ------------------------------------------------
FUNCTION fprint_read_error( hFiskalniParams, nBrojFiskalnog, lStorno, nTimeOut )

   LOCAL nErrLevel := 0
   LOCAL cFileName
   LOCAL nI
   LOCAL cErrorMsg
   LOCAL cErrorLinija
   LOCAL nTime
   LOCAL _serial := hFiskalniParams[ "serial" ]
   LOCAL oFile, _msg, cTmp
   LOCAL cFiskalniTxt

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   IF nTimeOut == NIL
      nTimeOut := hFiskalniParams[ "timeout" ]
   ENDIF

   IF hFiskalniParams[ "print_fiscal" ] == "T"
      MsgO( "TEST: emulacija štampe na fiskalni uređaj u toku..." )
      Sleep( 4 )
      MsgC()
      nBrojFiskalnog := 100
      RETURN nErrLevel
   ENDIF

   nTime := nTimeOut

   cFileName := hFiskalniParams[ "out_dir" ] + ANSW_DIR + SLASH + hFiskalniParams[ "out_answer" ]
   IF Empty( AllTrim( hFiskalniParams[ "out_answer" ] ) )
      cFileName := hFiskalniParams[ "out_dir" ] + ANSW_DIR + SLASH + hFiskalniParams[ "out_file" ]
   ENDIF

   Box( , 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Uređaj ID:" + AllTrim( Str( hFiskalniParams[ "id" ] ) ) +  " : " + PadR( hFiskalniParams[ "name" ], 40 )

   DO WHILE nTime > 0

      -- nTime
      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 PadR( "Čeka se odgovor fiskalnog uređaja: " + AllTrim( Str( nTime ) ), 48 )

      Sleep( 1 )

#ifdef TEST
      IF .T.
#else
      IF File( cFileName )
#endif
         log_write( "FISC: fajl odgovora se pojavio", 7 )
         EXIT
      ENDIF

      IF nTime == 0 .OR. LastKey() == K_ALT_Q
         log_write( "FISC ERR: timeout !", 2 )
         BoxC()
         nBrojFiskalnog := 0
         RETURN -9
      ENDIF

   ENDDO

   BoxC()

#ifndef TEST
   IF !File( cFileName )
      MsgBeep( "Fajl " + cFileName + " ne postoji !" )
      nBrojFiskalnog := 0
      nErrLevel := -9
      RETURN nErrLevel
   ENDIF
#endif

   nBrojFiskalnog := 0
   cFiskalniTxt := ""

   cFileName := AllTrim( cFileName )
   oFile := TFileRead():New( cFileName )
   oFile:Open()
   IF oFile:Error()
      cErrorMsg := "FISC ERR: " + oFile:ErrorMsg( "Problem sa otvaranjem fajla: " )
      log_write( cErrorMsg, 2 )
      MsgBeep( cErrorMsg )
      nErrLevel := -9
      RETURN nErrLevel
   ENDIF

   cTmp := ""
   WHILE oFile:MoreToRead()

      cErrorLinija := hb_StrToUTF8( oFile:ReadLine() )
      cTmp += cErrorLinija + " ## "
      IF ( "107,1," + _serial ) $ cErrorLinija
         LOOP
      ENDIF

      // ovu liniju zapamti, sadrzi fiskalni racun broj
      // komanda 56, zatvaranje racuna
      IF ( "56,1," + _serial ) $ cErrorLinija
         cFiskalniTxt := cErrorLinija
      ENDIF

      IF "Er;" $ cErrorLinija
         oFile:Close()
         cErrorMsg := "FISC ERR:" + AllTrim( cErrorLinija )
         log_write( cErrorMsg, 2 )
         MsgBeep( cErrorMsg )
         nErrLevel := nivo_greske_na_osnovu_odgovora( cErrorLinija )
         RETURN nErrLevel
      ENDIF

   ENDDO

   oFile:Close()
   log_write_file( "FISC ANSWER fajl sadržaj: " + cTmp, 3 )

   IF Empty( cFiskalniTxt )
      log_write_file( "ERR FISC nema komande 56,1," + _serial + " - broj fiskalnog računa, možda vam nije dobar serijski broj !", 1 )
   ELSE
      nBrojFiskalnog := fisc_get_broj_fiskalnog_racuna( cFiskalniTxt, lStorno )
   ENDIF

   RETURN nErrLevel



/*
   Opis: vraća nivo greške na osnovu linije na kojoj se pojavio ERR

   Usage: nivo_greske_na_osnovu_odgovora( line ) => 1

   Parameters:
     line - sekvenca iz fajla odgovora sa ERR markerom "55,1,1000123;ERR;"

   Return:
     2 - u slučaju greške na liniji 55
     1 - u slučaju bilo koje druge greške
*/

STATIC FUNCTION nivo_greske_na_osnovu_odgovora( line )

   LOCAL nLevel := 1

   DO CASE
   CASE "55,1," $ line
      nLevel := 2
   ENDCASE

   RETURN nLevel


// ------------------------------------------------
// vraca broj fiskalnog isjecka
// ------------------------------------------------
STATIC FUNCTION fisc_get_broj_fiskalnog_racuna( txt, lStorno )

   LOCAL _fiscal_no := 0
   LOCAL aTmp := {}
   LOCAL _a_fisc := {}
   LOCAL _fisc_txt := ""
   LOCAL _n_pos := 2

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   // pozicija u odgovoru
   // 3 - regularni racun
   // 4 - storno racun

   IF lStorno
      _n_pos := 3
   ENDIF

   aTmp := toktoniz( txt, ";" )
   _fisc_txt := aTmp[ 2 ]
   _a_fisc := toktoniz( _fisc_txt, "," )

   IF Len( _a_fisc ) < 2
      log_write( "ERROR fiscal out, nema elemenata !", 3 )
      RETURN _fiscal_no
   ENDIF

   _fiscal_no := Val( _a_fisc[ _n_pos ] )

   log_write( "FISC RN: " + AllTrim( Str( _fiscal_no ) ), 3 )

   RETURN _fiscal_no
