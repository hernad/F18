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

MEMVAR gLDRadnaJedinica
FIELD r_bank, r_ime, r_prezime

THREAD STATIC __PAGE_LEN


FUNCTION ld_lista_isplate_toplog_obroka()

   LOCAL cRj := gLDRadnaJedinica
   LOCAL cMonthFrom := ld_tekuci_mjesec()
   LOCAL cMonthTo := ld_tekuci_mjesec()
   LOCAL cYear := ld_tekuca_godina()
   LOCAL cHours := PadR( "S01;S10;", 200 )
   LOCAL nHourLimit := 0
   LOCAL nMinHrLimit := 0
   LOCAL nKoef := 7
   LOCAL nAcontAmount := 70.00
   LOCAL nRptVar1 := 1
   LOCAL nRptVar2 := 1
   LOCAL nDays := 7.5
   LOCAL cKred := Space( 6 )
   LOCAL cExport

   o_tables()

   __PAGE_LEN := 60

   IF _get_vars( @cRj, @cMonthFrom, @cMonthTo, @cYear, @nDays, ;
         @cHours, @nHourLimit, @nMinHrLimit, @nKoef, @nAcontAmount, ;
         @nRptVar1, @nRptVar2, @cKred, @cExport ) == 0
      RETURN .F.
   ENDIF


   IF _gen_list( cRj, cMonthFrom, cMonthTo, cYear, nDays, ;
         cHours, nHourLimit, nMinHrLimit, nKoef, nAcontAmount, cKred ) == 0

      RETURN .F.
   ENDIF

   IF cExport == "D"
      _export_data( nRptVar1, nRptVar2, cKred )
   ELSE
      _print_list( cMonthFrom, cMonthTo, cYear, nRptVar1, nRptVar2, cKred )
   ENDIF

   my_close_all_dbf()

   RETURN .T.



// ---------------------------------------
// export podataka u txt fajl
// ---------------------------------------
STATIC FUNCTION _export_data( nVar1, nVar2, banka )

   LOCAL cTxt
   LOCAL _output_file := "to.txt"
   PRIVATE cLokacija
   PRIVATE cConstBrojTR
   PRIVATE nH
   PRIVATE cParKonv

   createfilebanka( banka )

   IF banka == NIL .OR. Empty( banka )
      _output_file := "to.txt"
   ELSE
      _output_file := "to_" + AllTrim( banka ) + ".txt"
   ENDIF

   SELECT _tmp
   INDEX ON r_bank + r_ime + r_prezime TAG "bank"
   GO TOP

   DO WHILE !Eof()

      cTxt := ""

      // tek.racun
      cTxt += FormatSTR( AllTrim( field->r_tr ), 25, .F., "" )

      // prezime - ime oca - ime
      cTxt += FormatSTR( AllTrim( field->r_prezime ) + ;
         " (" + ;
         AllTrim( field->r_imeoca ) + ;
         ") " + ;
         AllTrim( field->r_ime ), 40 )

      IF nVar1 = 1
         // iznos toplog obroka
         cTxt += FormatSTR( AllTrim( Str( field->r_to, 8, 2 ) ), 8, .T. )
      ELSE
         IF nVar2 = 1
            // isplata akontacije
            cTxt += FormatSTR( AllTrim( Str( field->r_acont, 8, 2 ) ), ;
               8, .T. )
         ELSE
            // isplata ostatka
            cTxt += FormatSTR( AllTrim( Str( field->r_total, 8, 2 ) ), ;
               8, .T. )
         ENDIF
      ENDIF

      // konverzija znakova...

      write2file( nH, to_win1250_encoding( hb_StrToUTF8( cTxt ) ), .T. )

      SKIP

   ENDDO

   closefilebanka( nH )

   // kopiraj fajl na desktop
   f18_copy_to_desktop( my_home(), _output_file, _output_file )

   RETURN .T.



// --------------------------------------
// setuje parametre izvjestaja
// --------------------------------------
STATIC FUNCTION _get_vars( cRj, cMonthFrom, cMonthTo, cYear, nDays, ;
      cHours, nHourLimit, nMinHrLimit, nKoef, nAcontAmount, ;
      nRptVar1, nRptVar2, cKred, cExport )

   LOCAL nBoxX := 22
   LOCAL nBoxY := 70
   LOCAL nX := 1
   LOCAL cColor := "BG+/B"

   cRj := fetch_metric( "ld_rptto_rj", my_user(), cRj )
   cMonthFrom := fetch_metric( "ld_rptto_month_from", my_user(), cMonthFrom )
   cMonthto := fetch_metric( "ld_rptto_month_to", my_user(), cMonthto )
   nDays := fetch_metric( "ld_rptto_days", my_user(), nDays )
   cYear := fetch_metric( "ld_rptto_year", my_user(), cYear )
   cHours := fetch_metric( "ld_rptto_hours", my_user(), cHours )
   nHourLimit := fetch_metric( "ld_rptto_hours_limit", my_user(), nHourLimit )
   nMinHrLimit := fetch_metric( "ld_rptto_min_limit", my_user(), nMinHrLimit )
   nKoef := fetch_metric( "ld_rptto_koef", my_user(), nKoef )
   nAcontAmount := fetch_metric( "ld_rptto_acc_amount", my_user(), nAcontAmount )
   nRptVar1 := fetch_metric( "ld_rptto_var_1", my_user(), nRptVar1 )
   nRptVar2 := fetch_metric( "ld_rptto_var_2", my_user(), nRptVar2 )
   cKred := fetch_metric( "ld_rptto_kred", my_user(), cKred )

   cExport := "N"

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "**** uslovi izvjestaja", ( nBoxY - 1 ) ) COLOR cColor

   nX += 1

   // radna jedinica....
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "RJ (prazno-sve):" GET cRj VALID Empty( cRj ) .OR. p_ld_rj( @cRj )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Mjesec od:" GET cMonthFrom PICT "99" VALID cMonthFrom <= cMonthTo
   @ box_x_koord() + nX, Col() + 1 SAY "do:" GET cMonthTo PICT "99"  VALID cMonthTo >= cMonthFrom

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Godina:" GET cYear PICT "9999" VALID !Empty( cYear )

   @ box_x_koord() + nX, Col() + 1 SAY "Banka (prazno-sve):" GET cKred VALID Empty( cKred ) .OR. P_Kred( @cKred )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Sati primanja koja utiču na isplatu:" GET cHours PICT "@S30" VALID !Empty( cHours )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Koeficijent:" GET nKoef PICT "99999.99"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Broj dana sa kojim se dijeli:" GET nDays PICT "99999.99"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Iznos akontacije:" GET nAcontAmount PICT "99999.99"
   @ box_x_koord() + nX, Col() + 1 SAY "KM"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Minimalni limit za sate:" GET nMinHrLimit PICT "999999"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Maksimalni limit za sate:" GET nHourLimit PICT "999999"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Varijanta izvještaja:" GET nRptVar1 PICT "9" VALID nRptVar1 > 0 .AND. nRptVar1 < 3

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "(1) kompletan obraćun" COLOR cColor

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "(2) samo lista sa radnicima za potpis" COLOR cColor

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY Space( 3 ) + "Varijanta prikaza:" GET nRptVar2 PICT "9" VALID nRptVar2 > 0 .AND. nRptVar2 < 3 WHEN nRptVar1 == 2

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY Space( 3 ) + "(1) isplata akontacije" COLOR cColor

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY Space( 3 ) + "(2) isplata razlike" COLOR cColor

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 Space( 3 ) + "Export izvještaja ?" ;
      GET cExport VALID cExport $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   set_metric( "ld_rptto_rj", my_user(), cRj )
   set_metric( "ld_rptto_month_from", my_user(), cMonthFrom )
   set_metric( "ld_rptto_month_to", my_user(), cMonthto )
   set_metric( "ld_rptto_days", my_user(), nDays )
   set_metric( "ld_rptto_year", my_user(), cYear )
   set_metric( "ld_rptto_hours", my_user(), cHours )
   set_metric( "ld_rptto_hours_limit", my_user(), nHourLimit )
   set_metric( "ld_rptto_min_limit", my_user(), nMinHrLimit )
   set_metric( "ld_rptto_koef", my_user(), nKoef )
   set_metric( "ld_rptto_acc_amount", my_user(), nAcontAmount )
   set_metric( "ld_rptto_var_1", my_user(), nRptVar1 )
   set_metric( "ld_rptto_var_2", my_user(), nRptVar2 )
   set_metric( "ld_rptto_kred", my_user(), cKred )

   RETURN 1


// ----------------------------------------------
// otvori tabele za izvjestaj
// ----------------------------------------------
STATIC FUNCTION o_tables()

   o_ld_rj()
   o_kred()
   o_ld_radn()
   //select_o_ld()

   RETURN .T.



STATIC FUNCTION _gen_list( cRj, cMonthFrom, cMonthTo, cYear, nDays, ;
      cHours, nHourLimit, nMinHrLimit, nKoef, nAcontAmount, cKred )

   LOCAL cIdRadn
   LOCAL aHours := {}
   LOCAL i
   LOCAL nUSati
   LOCAL nCount := 0

   // napuni matricu aHours sa vrijednostima sati...
   aHours := TokToNiz( AllTrim( cHours ), ";" )


   cre_tmp_dbf()

   //SELECT ld
   //SET ORDER TO TAG "2"  // godina + mjesec + idradn + idrj
   //HSEEK Str( cYear, 4, 0 ) + Str( cMonthFrom, 2, 0 )
   seek_ld_2( NIL, cYear, cMonthFrom )

   Box(, 1, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "generacija izvještaja u toku...."

   DO WHILE !Eof() .AND. field->godina == cYear .AND. field->mjesec >= cMonthFrom .AND. field->mjesec <= cMonthTo

      cIdRadn := field->idradn

      nUSati := 0

      select_o_radn( cIdRadn )

      IF !Empty( cKred ) .AND. cKred <> radn->idbanka
         SELECT ld
         SKIP 1
         LOOP
      ENDIF

      SELECT ld

      DO WHILE !Eof() .AND. field->godina == cYear ;
            .AND. field->mjesec >= cMonthFrom ;
            .AND. field->mjesec <= cMonthTo ;
            .AND. field->idradn == cIdRadn

         IF !Empty( cRj ) .AND. field->idrj <> cRj

            SKIP
            LOOP

         ENDIF

         FOR i := 1 TO Len( aHours )

            // dodaj na sate
            nUSati += &( aHours[ i ] )

         NEXT

         SKIP

      ENDDO

      // ako ima sati i nije probijen limit ako postoji limit
      IF Round( nUSati, 2 ) > 0   .AND. ( nHourLimit == 0 .OR. ( nHourLimit <> 0 .AND. nUSati <= nHourLimit ) )

         SELECT _tmp
         APPEND BLANK

         Scatter()

         _r_bank := radn->idbanka
         _r_tr := radn->brtekr
         _r_ime := radn->ime
         _r_prezime := radn->naz
         _r_imeoca := radn->imerod
         _r_hours := nUSati
         _r_to := ROUND2( ( nUsati / nDays ) * nKoef, gZaok )

         IF Round( nMinHrLimit, 2 ) <> 0

            IF nUSati >= nMinHrLimit
               _r_acont := nAcontAmount
            ELSE
               _r_acont := 0
            ENDIF
         ELSE
            _r_acont := nAcontAmount
         ENDIF

         _r_total := _r_to - _r_acont

         Gather()

         ++ nCount

         @ box_x_koord() + 1, box_y_koord() + 2 SAY PadR( PadL( Str( nCount ), 5 ) + " " + AllTrim( radn->naz ) + ", " + AllTrim( Str( nUSati ) ), 60 )

      ENDIF

      SELECT ld

   ENDDO

   BoxC()

   RETURN nCount



// -----------------------------------------
// printanje liste iz _tmp tabele
// -----------------------------------------
STATIC FUNCTION _print_list( cMFrom, cMTo, cYear, nRptVar1, nRptVar2, cKred )

   LOCAL nRbr := 0
   LOCAL nUSati := 0
   LOCAL nUTotal := 0
   LOCAL nUAcont := 0
   LOCAL nUTo := 0
   LOCAL nUBSati := 0
   LOCAL nUBTotal := 0
   LOCAL nUBAcont := 0
   LOCAL nUBTo := 0
   LOCAL cLine


   SELECT _tmp
   // postavi index po bankama
   INDEX ON r_bank + r_prezime + r_ime TAG "bank"
   GO TOP

   // setuj liniju...
   _get_line( @cLine, nRptVar1, nRptVar2 )

   IF !start_print()
      RETURN .F.
   ENDIF

   // stampaj header
   _p_header( cLine, nRptVar1, nRptVar2, cMFrom, cMTo, cYear )

   cBank := "XYX"

   DO WHILE !Eof()

      // ako je ispis akontacije i spisak radnika, r_acont == 0, preskoci
      IF Round( r_acont, 2 ) == 0 .AND. nRptVar1 == 2 .AND. nRptVar2 == 1

         SKIP
         LOOP

      ENDIF

      // provjeri za novu stranu
      _new_page()

      IF nRptVar1 == 2

         ?

      ENDIF

      IF nRptVar1 == 1 .AND. cBank <> field->r_bank

         IF cBank <> "XYX"

            // total za banku pojedinacnu

            ? cLine
            ? PadR( "Ukupno za banku:", 37 )

            ?? nUBSati
            ?? nUBTo
            ?? nUBAcont
            ?? nUBTotal

            ? cLine

            ? p_potpis()

            FF

            P_10CPI

            _p_header( cLine, nRptVar1, nRptVar2, ;
               cMFrom, cMTo, cYear )

         ENDIF

         ? "Banka: " + field->r_bank + " - " +  get_kred_naz(  field->r_bank )
         ? Replicate( "-", 50 )

         cBank := r_bank

         // resetuj varijable
         nUBTo := 0
         nUBAcont := 0
         nUBTotal := 0
         nUBSati := 0

      ENDIF

      // r.br
      ? PadL( Str( ++nRbr, 3 ) + ".", 5 )

      ?? " "

      // prezime + ime
      ?? PadR( AllTrim( field->r_prezime ) + " (" + AllTrim( field->r_imeoca ) + ") " + AllTrim( field->r_ime ),  30 )

      ?? " "

      IF nRptVar1 == 1

         // usati...
         ?? field->r_hours

         nUSati += field->r_hours
         nUBSati += field->r_hours

         ?? " "

         // to
         ?? field->r_to

         nUTo += field->r_to
         nUBTo += field->r_to

         ?? " "

         // akontacija
         ?? field->r_acont

         nUAcont += field->r_acont
         nUBAcont += field->r_acont

         ?? " "

         // razlika
         ?? field->r_total

         nUTotal += field->r_total
         nUBTotal += field->r_total

         ?? " "

         // ziro racun u banci
         ?? Space( 5 ), field->r_tr

      ELSE

         IF nRptVar2 == 1

            // isplata akontacije...

            ?? field->r_acont
            ?? " "
            ?? _get_mp()

            nUAcont += field->r_acont
            nUBAcont += field->r_acont

         ELSE

            // isplata ostatka
            ?? field->r_total
            ?? " "
            ?? _get_mp()

            nUTotal += field->r_total
            nUBTotal += field->r_total

         ENDIF

      ENDIF


      SKIP

   ENDDO

   // print total

   _new_page()

   IF nRptVar1 == 1
      ? cLine
      ? PadR( "Ukupno za banku:", 37 )
      ?? nUBSati
      ?? nUBTo
      ?? nUBAcont
      ?? nUBTotal
   ENDIF

   ? cLine

   ? "UKUPNO:"
   ?? Space( 30 )

   IF nRptVar1 == 1

      ?? nUSati
      ?? nUTo
      ?? nUAcont
      ?? nUTotal

   ELSEIF nRptVar1 == 2

      IF nRptVar2 == 1

         ?? nUAcont

      ELSE

         ?? nUTotal

      ENDIF

   ENDIF

   ? cLine
   ?
   ? p_potpis()

   FF
   end_print()

   RETURN .T.


// ----------------------------------------------------
// vraca liniju za izvjestaj...
// ----------------------------------------------------
STATIC FUNCTION _get_line( cLine, nVar1 )

   LOCAL cTmp

   cTmp := ""
   // rbr
   cTmp += Replicate( "-", 5 )
   cTmp += " "
   // ime i prezime
   cTmp += Replicate( "-", 30 )
   cTmp += " "

   IF nVar1 == 1

      // sati
      cTmp += Replicate( "-", 10 )
      cTmp += " "
      // to
      cTmp += Replicate( "-", 12 )
      cTmp += " "
      // akontacija
      cTmp += Replicate( "-", 12 )
      cTmp += " "
      // razlika
      cTmp += Replicate( "-", 12 )
      cTmp += " "
      // racun
      cTmp += Replicate( "-", 30 )

   ELSE

      // iznos
      cTmp += Replicate( "-", 12 )
      cTmp += " "
      // potpis
      cTmp += Replicate( "-", 20 )

   ENDIF

   cLine := cTmp

   RETURN .T.



// ----------------------------------------
// vraca liniju za mjesto potpisa....
// ----------------------------------------
STATIC FUNCTION _get_mp()
   RETURN Replicate( "_", 20 )



// -----------------------------------------------
// stampa headera...
// -----------------------------------------------
STATIC FUNCTION _p_header( cLine, nVar1, nVar2, cMonthFrom, cMonthTo, cYear )

   LOCAL cTmp
   LOCAL cPom := "Akontacija"

   IF nVar2 == 2
      cPom := "Izn.ostatka"
   ENDIF

   cTmp := ""
   cTmp += PadC( "Rbr", 5 )
   cTmp += " "
   cTmp += PadC( "Prezime (ime oca) ime", 30 )
   cTmp += " "

   IF nVar1 == 1

      cTmp += PadC( "Sati", 10 )
      cTmp += " "
      cTmp += PadC( "Topli obrok", 12 )
      cTmp += " "
      cTmp += PadC( "Akontacija", 12 )
      cTmp += " "
      cTmp += PadC( "Razlika", 12 )
      cTmp += " "
      cTmp += PadC( "Tekuci racun", 30 )
   ELSE

      cTmp += PadC( cPom, 12 )
      cTmp += " "
      cTmp += PadR( "Potpis radnika", 20 )

   ENDIF

   // header

   ? "---------------------------------"
   ? "LISTA ZA ISPLATU TOPLOG OBROKA"
   ? "---------------------------------"
   ? "na dan: " + DToC( Date() )
   ? "za mjesec od " + Str( cMonthFrom, 2 ) + " do " + Str( cMonthTo, 2 ) + ", " + Str( cYear, 4 ) + " godine"

   ?

   P_COND
   // header tablele
   ? cLine
   ? cTmp
   ? cLine

   RETURN .T.




// -----------------------------
// kreiraj tmp tabelu...
// -----------------------------
STATIC FUNCTION cre_tmp_dbf()

   LOCAL aDbf := {}

   AAdd( aDbf, { "r_bank", "C", 6, 0 } )
   AAdd( aDbf, { "r_tr", "C", 30, 0 } )
   AAdd( aDbf, { "r_ime", "C", 30, 0 } )
   AAdd( aDbf, { "r_prezime", "C", 30, 0 } )
   AAdd( aDbf, { "r_imeoca", "C", 30, 0 } )
   AAdd( aDbf, { "r_hours", "N", 10, 0 } )
   AAdd( aDbf, { "r_to", "N", 12, 2 } )
   AAdd( aDbf, { "r_acont", "N", 12, 2 } )
   AAdd( aDbf, { "r_total", "N", 12, 2 } )

   IF File( my_home() + "_tmp.dbf" )
      FErase( my_home() + "_tmp.dbf" )
   ENDIF

   dbCreate( my_home() + "_tmp.dbf", aDbf )

   SELECT ( F_TMP_1 )
   my_use_temp( "_TMP", my_home() + "_tmp.dbf", .F., .T. )

   RETURN .T.


// --------------------------------------
// nova stranica...
// --------------------------------------
STATIC FUNCTION _new_page()

   IF PRow() > __PAGE_LEN
      FF
   ENDIF

   RETURN .T.
