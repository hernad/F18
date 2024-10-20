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


STATIC nStr := 0
STATIC lPrintedTotal := .F.
STATIC cLine
// ako se koristi PTXT onda se ova korekcija primjenjuje
// za prikaz vecih fontova
STATIC nDuzStrKorekcija := 0

// glavna funkcija za poziv stampe fakture a4
// lStartPrint - pozovi funkcije stampe START PRINT
FUNCTION fakt_otpremnica_mp_13_print( lStartPrint )


   // ako je nil onda je uvijek .t.
   IF lStartPrint == nil
      lStartPrint := .T.
   ENDIF

   PIC_KOLICINA( PadL( AllTrim( Right( fakt_pic_kolicina(), LEN_KOLICINA() ) ), LEN_KOLICINA(), "9" ) )
   PIC_VRIJEDNOST( PadL( AllTrim( Right( fakt_pic_iznos(), LEN_VRIJEDNOST() ) ), LEN_VRIJEDNOST(), "9" ) )
   PIC_CIJENA( PadL( AllTrim( Right( fakt_pic_cijena(), LEN_CIJENA() ) ), LEN_CIJENA(), "9" ) )

   nDuzStrKorekcija := 0

   close_open_racun_tbl()

   SELECT drn
   GO TOP

   LEN_NAZIV( 52 )
   LEN_UKUPNO( 80 )

   otpr_mp( lStartPrint )

   RETURN .T.



// stampa otpremnica maloprodaja
FUNCTION otpr_mp( lStartPrint )


   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cSlovima

   PRIVATE nLMargina // lijeva margina
   PRIVATE nDodRedova // broj dodatnih redova
   PRIVATE nSlTxtRow // broj redova slobodnog text-a
   PRIVATE lSamoKol // prikaz samo kolicina
   PRIVATE lZaglStr // zaglavlje na svakoj stranici
   PRIVATE lDatOtp // prikaz datuma otpremnice i narudzbenice
   PRIVATE cValuta // prikaz valute KM ili ???
   PRIVATE lStZagl // automatski formirati zaglavlje
   PRIVATE nGMargina // gornja margina


   IF lStartPrint
      START PRINT CRET
   ENDIF

   // uzmi glavne varijable za stampu fakture
   // razmak, broj redova sl.teksta,
   get_omp_vars( @nLMargina, @nGMargina, @nDodRedova, @nSlTxtRow, @lSamoKol, @lZaglStr, @lStZagl, @lDatOtp, @cValuta )

   // razmak ce biti
   RAZMAK( Space( nLMargina ) )

   IF lStZagl
      // zaglavlje por.fakt
      a4_header()
   ELSE
      // ostavi prostor umjesto automatskog zaglavlja
      FOR i := 1 TO nGMargina
         ?
      NEXT
   ENDIF

   // podaci kupac i broj dokumenta itd....
   omp_kupac()

   cLine := a4_line( "otpr_mp" )

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   P_COND

   st_zagl_data()

   SELECT rn

   nStr := 1
   aArtNaz := {}

   // data
   DO WHILE !Eof()


      // uzmi naziv u matricu
      cNazivDobra := NazivDobra( rn->idroba, rn->robanaz, rn->jmj )
      aNazivDobra := SjeciStr( cNazivDobra, LEN_NAZIV() )

      // PRVI RED
      // redni broj ili podbroj
      ? RAZMAK()

      IF Empty( rn->podbr )
         ?? PadL( rn->rbr + ")", LEN_RBR() )
      ELSE
         ?? PadL( rn->rbr + "." + AllTrim( rn->podbr ), LEN_RBR() )
      ENDIF
      ?? " "

      // idroba, naziv robe, kolicina, jmj
      ?? PadR( aNazivDobra[ 1 ], LEN_NAZIV() )
      ?? " "
      ?? show_number( rn->kolicina, PIC_KOLICINA() )
      ?? " "

      // cijena bez pdv
      ?? show_number( rn->cjenbpdv, PIC_CIJENA() )
      ?? " "

      // ukupno bez pdv
      ?? show_number( rn->cjenbpdv * rn->kolicina,  PIC_VRIJEDNOST() )
      ?? " "

      // cijena sa PDV
      ?? show_number( rn->cjenpdv, PIC_CIJENA() )
      ?? " "

      // uk sa PDV
      ?? show_number( rn->ukupno, PIC_VRIJEDNOST() )
      ?? " "



      IF Len( aNazivDobra ) > 1
         // DRUGI RED
         ? RAZMAK()
         ?? " "
         ?? Space( LEN_RBR() )
         ?? PadR( aNazivDobra[ 2 ], LEN_NAZIV() )
      ENDIF

      // opis
      IF !Empty( rn->opis )
         ? RAZMAK()
         ?? " "
         ?? Space( LEN_RBR() )
         ?? AllTrim( rn->opis )
      ENDIF
      // c1, c2, c3
      IF !Empty( rn->c1 ) .OR. !Empty( rn->c2 ) .OR. !Empty( rn->c3 )
         ? RAZMAK()
         ?? " "
         ?? Space( LEN_RBR() )
         ?? AllTrim( rn->c1 ) + ", " + AllTrim( rn->c2 ) + ", " + AllTrim( rn->c3 )
      ENDIF

      // provjeri za novu stranicu
      IF PRow() > nDodRedova + LEN_STRANICA() - DSTR_KOREKCIJA()
         ++nStr
         Nstr_a4( nStr, .T. )
      ENDIF

      SELECT rn
      SKIP
   ENDDO

   // provjeri za novu stranicu
   IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_REKAP_PDV() )
      ++nStr
      Nstr_a4( nStr, .T. )
   ENDIF




   print_total()
   lPrintedTotal := .T.


   IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_REKAP_PDV() )
      ++nStr
      Nstr_a4( nStr, .T. )
   ENDIF

   ?
   // dodaj text na kraju fakture
   a4_footer()

   ?

   IF lStartPrint
      FF
      ENDPRINT
   ENDIF

   RETURN .T.


// uzmi osnovne parametre za stampu dokumenta
FUNCTION get_omp_vars( nLMargina, nGMargina, nDodRedova, nSlTxtRow, lSamoKol, lZaglStr, lStZagl, lDatOtp, cValuta, cPDVStavka )

   // {

   // uzmi podatak za lijevu marginu
   nLMargina := Val( get_dtxt_opis( "P01" ) )

   // uzmi podatak za gornju marginu
   nGMargina := Val( get_dtxt_opis( "P07" ) )

   // broj dodatnih redova po listu
   nDodRedova := Val( get_dtxt_opis( "P06" ) )

   // uzmi podatak za duzinu slobodnog teksta
   nSlTxtRow := Val( get_dtxt_opis( "P02" ) )

   // varijanta fakture (porez na svaku stavku D/N)
   cPDVStavka := get_dtxt_opis( "P11" )

   // da li se prikazuju samo kolicine
   lSamoKol := .F.
   IF get_dtxt_opis( "P03" ) == "D"
      lSamoKol := .T.
   ENDIF

   // da li se kreira zaglavlje na svakoj stranici
   lZaglStr := .F.
   IF get_dtxt_opis( "P04" ) == "D"
      lZaglStr := .T.
   ENDIF

   // da li se kreira zaglavlje na svakoj stranici
   lStZagl := .F.
   IF get_dtxt_opis( "P10" ) == "D"
      lStZagl := .T.
   ENDIF

   // da li se ispisuji podaci otpremnica itd....
   lDatOtp := .T.
   IF get_dtxt_opis( "P05" ) == "N"
      lZaglStr := .F.
   ENDIF

   // valuta dokuemnta
   cValuta := get_dtxt_opis( "D07" )

   nSw1( Val( get_dtxt_opis( "X04" ) ) )
   nSw2( Val( get_dtxt_opis( "X05" ) ) )
   nSw3( Val( get_dtxt_opis( "X06" ) ) )
   nSw4( Val( get_dtxt_opis( "X07" ) ) )

   RETURN .T.


// zaglavlje glavne tabele sa stavkama
STATIC FUNCTION st_zagl_data()



   LOCAL cRed1 := ""
   LOCAL cRed2 := ""
   LOCAL cRed3 := ""

   cLine := a4_line( "otpr_mp" )

   ? cLine

   cRed1 := RAZMAK()
   cRed1 += PadC( "R.br", LEN_RBR() )
   cRed1 += " " + PadR( "Trgovacki naziv dobra (sifra, naziv, jmj)", LEN_NAZIV() )

   cRed1 += " " + PadC( "kolicina", LEN_KOLICINA() )
   cRed1 += " " + PadC( "C.b.PDV", LEN_CIJENA() )
   cRed1 += " " + PadC( "Uk.bez.PDV", LEN_VRIJEDNOST() )

   cRed1 += " " + PadC( "C.sa.PDV", LEN_CIJENA() )
   cRed1 += " " + PadC( "Uk.sa.PDV", LEN_VRIJEDNOST() )

   ?U cRed1

   ?U cLine

   RETURN .T.


// definicija linije za glavnu tabelu sa stavkama

FUNCTION otpr_mp_line()

   LOCAL cLine

   cLine := RAZMAK()
   cLine += Replicate( "-", LEN_RBR() )
   cLine += " " + Replicate( "-", LEN_NAZIV() )
   // kolicina
   cLine += " " + Replicate( "-", LEN_KOLICINA() )

   // cijena b. pdv
   cLine += " " + Replicate( "-", LEN_CIJENA() )
   // vrijednost b. pdv
   cLine += " " + Replicate( "-", LEN_VRIJEDNOST() )

   // cijena s. pdv
   cLine += " " + Replicate( "-", LEN_CIJENA() )
   // vrijednost s. pdv
   cLine += " " + Replicate( "-", LEN_VRIJEDNOST() )

   RETURN cLine



STATIC FUNCTION print_total()

   ? cLine

   // kolona bez PDV

   ? RAZMAK()
   ?? Space( LEN_UKUPNO() - ( LEN_KOLICINA() + LEN_CIJENA() + 2 ) )

   IF Round( drn->ukkol, 2 ) <> 0
      ?? show_number( drn->ukkol, PIC_KOLICINA() )
   ELSE
      ?? Space( LEN_KOLICINA() )
   ENDIF
   ?? " "

   ?? Space( LEN_CIJENA() )
   ?? " "

   ?? show_number( drn->ukbezpdv, PIC_VRIJEDNOST() )

   // cijene se ne rekapituliraju
   ?? " "
   ?? Space( Len( PIC_CIJENA() ) )

   // ukupno sa PDV
   ?? " "
   ?? show_number( drn->ukupno, PIC_VRIJEDNOST() )

   // obracun PDV-a
   ? RAZMAK()
   ?? PadL( "PDV 17% :", LEN_UKUPNO() )
   ?? show_number( drn->ukpdv, PIC_VRIJEDNOST() )

   // zaokruzenje
   IF Round( drn->zaokr, 4 ) <> 0
      ? RAZMAK()
      ?? PadL( "Zaokruzenje :", LEN_UKUPNO() )
      ?? show_number( drn->zaokr, PIC_VRIJEDNOST() )
   ENDIF

   ? cLine
   ? RAZMAK()
   // ipak izleti za dva karaktera rekapitulacija u bold rezimu
   ?? Space( 50 - 2 )
   B_ON
   ?? PadL( "** SVEUKUPNO SA PDV  (" + cValuta + ") :", LEN_UKUPNO() - 50 )
   ?? show_number( drn->ukupno, PIC_VRIJEDNOST() )
   B_OFF


   cSlovima := get_dtxt_opis( "D04" )
   ? RAZMAK()
   B_ON
   ?? "slovima: " + cSlovima
   B_OFF
   ? cLine

   RETURN


// -----------------------------------------------
// funkcija za ispis podataka o kupcu, dokument,
// datum fakture, otpremnica itd..
// -----------------------------------------------
STATIC FUNCTION omp_kupac()

   // {
   LOCAL cPartMjesto
   LOCAL cPartPTT

   LOCAL cKNaziv
   LOCAL cKAdresa
   LOCAL cKIdBroj
   LOCAL cKPorBroj
   LOCAL cKBrRjes
   LOCAL cKBrUpisa
   LOCAL cKMjesto
   LOCAL aKupac
   LOCAL cMjesto
   LOCAL cDatDok
   LOCAL cDatIsp
   LOCAL cDatVal
   LOCAL cTipDok := "OTPREMNICA MP br. "
   LOCAL cBrDok
   LOCAL cBrNar
   LOCAL cBrOtp
   LOCAL nPRowsDelta

   nPRowsDelta := PRow()

   close_open_racun_tbl()
   SELECT drn
   GO TOP

   cDatDok := DToC( datdok )

   IF Empty( datIsp )
      // posto je ovo obavezno polje na racunu
      // stavicemo ako nije uneseno da je datum isporuke
      // jednak datumu dokumenta
      cDatIsp := DToC( datDok )
   ELSE
      cDatIsp := DToC( datisp )
   ENDIF

   cDatVal := DToC( field->datval )
   cBrDok := field->brdok

   cBrNar := get_dtxt_opis( "D06" )
   cBrOtp := get_dtxt_opis( "D05" )
   cMjesto := get_dtxt_opis( "D01" )
   cTipDok := get_dtxt_opis( "D02" )
   cKNaziv := get_dtxt_opis( "K01" )
   cKAdresa := get_dtxt_opis( "K02" )
   cKIdBroj := get_dtxt_opis( "K03" )
   cDestinacija := get_dtxt_opis( "D08" )

   // K10 - partner mjesto
   cPartMjesto := get_dtxt_opis( "K10" )
   // K11 - partner PTT
   cPartPTT := get_dtxt_opis( "K11" )


   cKMjesto := AllTrim( cPartMjesto )
   IF !Empty( cPartPTT )
      cKMjesto := AllTrim( cPartPTT ) + " " + cKMjesto
   ENDIF

   aKupac := Sjecistr( cKNaziv, 30 )

   I_ON
   p_line( "Zaduzuje:", 10, .T. )
   p_line( Replicate( "-", LEN_KUPAC() - 10 ), 10, .F. )
   I_OFF

   // prvi red kupca, 10cpi, bold
   cPom := AllTrim( aKupac[ 1 ] )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC() ), 10, .T. )
   B_OFF
   // u istom redu mjesto
   ?? PadL( cMjesto + ", " + cDatDok, LEN_DATUM() )


   // adresa, 10cpi, bold
   cPom := AllTrim( cKAdresa )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC() ), 10, .T. )
   B_OFF
   // u istom redu datum isporuke
   IF cDatIsp <> DToC( CToD( "" ) )
      ?? PadL( "Datum isporuke: " + cDatIsp, LEN_DATUM() )
   ENDIF

   // mjesto
   cPom := AllTrim( cKMjesto )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cKMjesto, LEN_KUPAC() ), 10, .T. )
   B_OFF
   // u istom redu datum valute
   IF cDatVal <> DToC( CToD( "" ) )
      ?? PadL( "Datum valute: " + cDatVal, LEN_DATUM() )
   ENDIF


   IF !Empty( cDestinacija )
      p_line( Replicate( "-", LEN_KUPAC() - 10 ), 10, .F. )
      cPom := "Za: "  + AllTrim( cDestinacija )
      p_line( cPom, 12, .F. )
      ?
   ENDIF

   ?
   P_10CPI
   // broj dokumenta
   p_line( PadL( cTipDok + cBrDok, LEN_KUPAC() + LEN_DATUM() ), 10, .T. )
   B_OFF
   ?

   nPRowsDelta := PRow() - nPRowsDelta
   IF IsPtxtOutput()
      nDuzStrKorekcija += nPRowsDelta * 7 / 100
   ENDIF

   RETURN

// ------------------------------------
// funkcija za novu stranu
// ------------------------------------
STATIC FUNCTION NStr_a4( nStr, lShZagl )

   // {

   // korekcija duzine je na svako strani razlicita
   nDuzStrKorekcija := 0

   P_COND
   ? cLine
   p_line( "Prenos na sljedecu stranicu", 17, .F. )
   ? cLine

   FF

   P_COND
   ? cLine
   IF nStr <> nil
      p_line( "       Strana:" + Str( nStr, 3 ), 17, .F. )
   ENDIF

   // total nije odstampan znaci ima jos podataka
   IF lShZagl
      IF !lPrintedTotal
         st_zagl_data()
      ELSE
         // vec je odstampan, znaci nema vise stavki
         // najbolje ga prenesi na ovu stranu koja je posljednja
         print_total( cValuta, cLine )
      ENDIF
   ELSE
      ? cLine
   ENDIF

   RETURN


// --------------------------------
// korekcija za duzinu strane
// --------------------------------
STATIC FUNCTION DSTR_KOREKCIJA()

   LOCAL nPom

   nPom := Round( nDuzStrKorekcija, 0 )
   IF Round( nDuzStrKorekcija - nPom, 1 ) > 0.2
      nPom ++
   ENDIF

   RETURN nPom

   RETURN
