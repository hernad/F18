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


STATIC LEN_RBR := 6
// naziv dobra
STATIC LEN_NAZIV := 0

STATIC LEN_UKUPNO := 99
STATIC LEN_KUPAC := 35
STATIC LEN_DATUM := 34

STATIC LEN_KOLICINA := 12
// 9999999.99
STATIC LEN_CIJENA := 10
STATIC LEN_VRIJEDNOST := 12

// 999.99 - popust
STATIC LEN_PROC2 := 6
STATIC DEC_PROC2 := 2

STATIC DEC_KOLICINA := 2
STATIC DEC_CIJENA := 2
STATIC DEC_VRIJEDNOST := 2

STATIC PIC_PROC2 := "999.99"
STATIC PIC_KOLICINA := ""
STATIC PIC_VRIJEDNOST := ""
STATIC PIC_CIJENA := ""

STATIC LEN_STRANICA := 58
STATIC LEN_REKAP_PDV := 7

STATIC RAZMAK := ""

STATIC nStr := 0
STATIC lPrintedTotal := .F.

// ako se koristi PTXT onda se ova korekcija primjenjuje
// za prikaz vecih fontova
STATIC nDuzStrKorekcija := 0

STATIC lShowPopust := .T.
STATIC lKomision := .F.

// linije sa "=" prva i zadnja
STATIC nSw1
// linija sa "-" prva
STATIC nSw2
// local sa "-" druga
STATIC nSw3
// linija ispod kupac
STATIC nSw4
// header broj redova - slika
STATIC nPicHRow
// footer broj redova - slika
STATIC nPicFRow

// ------------------------------------------------------
// glavna funkcija za poziv stampe fakture a4
// lStartPrint - pozovi funkcije stampe START PRINT
// -----------------------------------------------------
FUNCTION pf_a4_print( lStartPrint, cDocumentName )

   IF lStartPrint == NIL   // ako je nil onda je uvijek .t.
      lStartPrint := .T.
   ENDIF

   PIC_KOLICINA :=  PadL( AllTrim( Right( fakt_pic_kolicina(), LEN_KOLICINA ) ), LEN_KOLICINA, "9" )
   PIC_VRIJEDNOST := PadL( AllTrim( Right( fakt_pic_iznos(), LEN_VRIJEDNOST ) ), LEN_VRIJEDNOST, "9" )
   PIC_CIJENA := PadL( AllTrim( Right( fakt_pic_cijena(), LEN_CIJENA ) ), LEN_CIJENA, "9" )

   close_open_racun_tbl()

   SELECT drn
   GO TOP

   LEN_NAZIV( 53 )
   LEN_UKUPNO( 99 )
   IF Round( drn->ukpopust, 2 ) <> 0
      lShowPopust := .T.
   ELSE
      lShowPopust := .F.
      LEN_NAZIV += LEN_PROC2 + LEN_CIJENA + 2
   ENDIF

   IF ( gPdvDokVar == "1" )
      // stampaj racun
      st_pf_a4( lStartPrint, cDocumentName )
   ELSE
      st_pf_a4_2( lStartPrint, cDocumentName )
   ENDIF

   RETURN .T.


// stampa fakture a4
FUNCTION st_pf_a4( lStartPrint, cDocumentName )

   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cSlovima
   LOCAL cLine
   LOCAL nI

   // lijeva margina
   PRIVATE nLMargina
   // broj dodatnih redova
   PRIVATE nDodRedova
   // broj redova slobodnog text-a
   PRIVATE nSlTxtRow
   // prikaz samo kolicina
   PRIVATE lSamoKol
   // zaglavlje na svakoj stranici
   PRIVATE lZaglStr
   // prikaz datuma otpremnice i narudzbenice
   PRIVATE lDatOtp
   // prikaz valute KM ili ???
   PRIVATE cValuta
   // automatski formirati zaglavlje
   PRIVATE lStZagl
   // gornja margina
   PRIVATE nGMargina

   nDuzStrKorekcija := 0

   lPrintedTotal := .F.

   IF lStartPrint
      START PRINT CRET
   ENDIF

   nSw1 := Val( get_dtxt_opis( "X04" ) )
   nSw2 := Val( get_dtxt_opis( "X05" ) )
   nSw3 := Val( get_dtxt_opis( "X06" ) )
   nSw4 := Val( get_dtxt_opis( "X07" ) )

   nPicHRow := Val( get_dtxt_opis( "X11" ) )
   nPicFRow := Val( get_dtxt_opis( "X12" ) )

   // uzmi glavne varijable za stampu fakture
   // razmak, broj redova sl.teksta,
   get_pfa4_vars( @nLMargina, @nGMargina, @nDodRedova, @nSlTxtRow, @lSamoKol, @lZaglStr, @lStZagl, @lDatOtp, @cValuta )

   // razmak ce biti
   RAZMAK := Space( nLMargina )

   // dodaj sliku headera
   IF nPicHRow > 1
      // put picture code
      ?
      gpPicH( nPicHRow )
   ENDIF

   IF lStZagl == .T.
      // zaglavlje por.fakt
      a4_header()
   ELSE
      // IF gPDFPrint <> "D"
      // ostavi prostor umjesto automatskog zaglavlja
      FOR i := 1 TO nGMargina
         ?
      NEXT
      // ELSE
      // ?
      // ENDIF
   ENDIF

   // podaci kupac i broj dokumenta itd....
   pf_a4_kupac()

   cLine := a4_line( "pf" )

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
      aNazivDobra := SjeciStr( cNazivDobra, LEN_NAZIV )

      // PRVI RED
      // redni broj ili podbroj
      ? RAZMAK

      IF Empty( rn->podbr )
         ?? PadL( rn->rbr + ")", LEN_RBR )
      ELSE
         ?? PadL( rn->rbr + "." + AllTrim( rn->podbr ), LEN_RBR )
      ENDIF
      ?? " "

      // idroba, naziv robe, kolicina, jmj
      ?? PadR( aNazivDobra[ 1 ], LEN_NAZIV )
      ?? " "

      nQty := PCol()

      ?? show_number( rn->kolicina, PIC_KOLICINA )
      ?? " "

      // cijene
      IF !lSamoKol

         // cijena bez pdv
         ?? show_number( rn->cjenbpdv, PIC_CIJENA )
         ?? " "

         IF lShowPopust
            // procenat popusta
            ?? show_popust( rn->popust )
            ?? " "

            // cijena bez pd - popust
            ?? show_number( rn->cjen2bpdv, PIC_CIJENA )
            ?? " "
         ENDIF

         // ukupno bez pdv
         ?? show_number( rn->cjenbpdv * rn->kolicina,  PIC_VRIJEDNOST )
      ENDIF


      IF Len( aNazivDobra ) > 1

         // OSTALI REDOVI
         FOR nI := 2 TO Len( aNazivDobra )
            ? RAZMAK
            ?? " "
            ?? Space( LEN_RBR )
            ?? PadR( aNazivDobra[ nI ], LEN_NAZIV )
         NEXT

      ENDIF

      // opis
      IF !Empty( rn->opis )
         ? RAZMAK
         ?? " "
         ?? Space( LEN_RBR )
         ?? AllTrim( rn->opis )
      ENDIF

      // c1, c2, c3
      IF !Empty( rn->c1 ) .OR. !Empty( rn->c2 ) .OR. !Empty( rn->c3 )
         ? RAZMAK
         ?? " "
         ?? Space( LEN_RBR )
         ?? AllTrim( rn->c1 ) + ", " + AllTrim( rn->c2 ) + ", " + AllTrim( rn->c3 )
      ENDIF

      // provjeri za novu stranicu
      IF PRow() > nDodRedova + LEN_STRANICA - DSTR_KOREKCIJA() - PICT_KOREKCIJA( nStr )
         ++nStr
         Nstr_a4( nStr, .T. )
      ENDIF

      SELECT rn
      SKIP

   ENDDO

   // provjeri za novu stranicu
   IF PRow() > nDodRedova + ( LEN_STRANICA - LEN_REKAP_PDV ) - DSTR_KOREKCIJA() - PICT_KOREKCIJA( nStr )

      ++nStr
      Nstr_a4( nStr, .T. )

   ENDIF

   ? cLine

   IF lSamoKol
      // prikazi ukupno kolicinu
      ?
      @ PRow(), nQty SAY show_number( drn->ukkol, PIC_KOLICINA )
   ENDIF

   IF !lSamoKol
      print_total( cValuta, cLine )
   ENDIF

   lPrintedTotal := .T.

   IF PRow() > nDodRedova + ( LEN_STRANICA - LEN_REKAP_PDV ) - DSTR_KOREKCIJA() - PICT_KOREKCIJA( nStr )
      ++nStr
      Nstr_a4( nStr, .T. )

   ENDIF

   ?

   // dodaj text na kraju fakture
   a4_footer()

   IF lStartPrint
      FF
      ENDPRINT
   ENDIF

   RETURN



// uzmi osnovne parametre za stampu dokumenta
FUNCTION get_pfa4_vars( nLMargina, nGMargina, nDodRedova, nSlTxtRow, lSamoKol, lZaglStr, lStZagl, lDatOtp, cValuta, cPDVStavka )

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

   RETURN



// zaglavlje glavne tabele sa stavkama
STATIC FUNCTION st_zagl_data()

   LOCAL cLine
   LOCAL cRed1 := ""
   LOCAL cRed2 := ""
   LOCAL cRed3 := ""

   cLine := a4_line( "pf" )

   ? cLine

   cRed1 := RAZMAK
   cRed1 += PadC( "R.br", LEN_RBR )
   cRed1 += " " + PadR( "Trgovački naziv dobra/usluge (sifra, naziv, jmj)", LEN_NAZIV )
   cRed1 += " " + PadC( "količina", LEN_KOLICINA )
   cRed1 += " " + PadC( "C.b.PDV", LEN_CIJENA )
   IF lShowPopust
      cRed1 += " " + PadC( "Pop.%", LEN_PROC2 )
      cRed1 += " " + PadC( "C.2.b.PDV", LEN_CIJENA )
   ENDIF
   cRed1 += " " + PadC( "Uk.bez.PDV", LEN_VRIJEDNOST )

   ?U cRed1

   ? cLine

   RETURN .T.



// funkcija za ispis slobodnog teksta na kraju fakture
STATIC FUNCTION pf_a4_sltxt()

   LOCAL cLine
   LOCAL cTxt
   LOCAL nFTip
   LOCAL aTxt
   LOCAL n

   cLine := a4_line( "pf" )

   IF PRow() > nDodRedova + LEN_STRANICA - DSTR_KOREKCIJA() - PICT_KOREKCIJA( nStr )
      ++nStr
      Nstr_a4( NIL, .F. )
   ENDIF


   SELECT drntext
   SET ORDER TO TAG "1"
   HSEEK "F20"

   DO WHILE !Eof() .AND. field->tip = "F"
      n := 1
      nFTip := Val( Right( field->tip, 2 ) )
      IF nFTip < 51
         cTxt := AllTrim( field->opis )
         aTxt := SjeciStr( cTxt, 120 )
         FOR n := 1 TO Len( aTxt )
            p_line( aTxt[ n ], 17, .F., .T. )
         NEXT
      ENDIF

      IF PRow() > nDodRedova + LEN_STRANICA - DSTR_KOREKCIJA() - PICT_KOREKCIJA( nStr )
         ++nStr
         Nstr_a4( NIL, .F. )
      ENDIF

      SKIP
   ENDDO

   RETURN


// generalna funkcija footer
FUNCTION a4_footer()

   LOCAL cLine

   cLine := a4_line( "pf" )

   // ispisi slobodni text
   pf_a4_sltxt( cLine )
   ?
   P_12CPI
   ?

   cPotpis := get_dtxt_opis( "F10" )

   cPotpis := StrTran( cPotpis, "?S_5?", Space( 5 ) )
   cPotpis := StrTran( cPotpis, "?S_10?", Space( 10 ) )

   aPotpis := lomi_tarabe( cPotpis )

   FOR i := 1 TO Len( aPotpis )
      p_line( aPotpis[ i ], 10, .F. )
   NEXT

   RETURN



// --------------------------
// funkcija za ispis headera
// ----------------------------
FUNCTION a4_header()

   LOCAL cPom
   LOCAL nPom

   LOCAL nPos1

   LOCAL cDLHead
   LOCAL cSLHead
   LOCAL cINaziv
   LOCAL cIAdresa
   LOCAL cIIdBroj
   LOCAL cIBanke
   LOCAL aBanke
   LOCAL cITelef
   LOCAL cIWeb
   LOCAL cIText1
   LOCAL cIText2
   LOCAL cIText3
   LOCAL nPRowsDelta

   // double line header
   cDLHead := Replicate( "=", nSw1() )
   // single line header
   cSLHead := Replicate( "-", nSw3() )
   nPRowsDelta := PRow()
   // naziv
   cINaziv  := get_dtxt_opis( "I01" )
   // pomocni opis
   cIPNaziv  := get_dtxt_opis( "I20" )
   // adresa
   cIAdresa := get_dtxt_opis( "I02" )
   // idbroj
   cIIdBroj := get_dtxt_opis( "I03" )
   cIBanke  := get_dtxt_opis( "I09" )

   IF "##" $ cIBanke
      // rucno lomi
      aIBanke := {}

      DO WHILE .T.
         nPos1 := At( "##", cIBanke )
         IF nPos1 == 0
            // nema vise sta lomiti
            AAdd( aIBanke, cIBanke )
            EXIT
         ENDIF
         AAdd( aIBanke, Left( cIBanke, nPos1 - 1 ) )
         // ostatak
         cIBanke := SubStr( cIBanke, nPos1 + 2 )
      ENDDO

   ELSE
      aIBanke  := SjeciStr( cIBanke, 68 )
   ENDIF

   cITelef  := get_dtxt_opis( "I10" ) // telefoni
   cIWeb    := get_dtxt_opis( "I11" ) // email-web
   cIText1  := get_dtxt_opis( "I12" ) // sl.text 1
   cIText2  := get_dtxt_opis( "I13" ) // sl.text 2
   cIText3  := get_dtxt_opis( "I14" ) // sl.text 3

   p_line( cDLHead, 10, .T. )

   cTmp := AllTrim( cINaziv )
   aTmp := SjeciStr( cTmp, 74 )
   // ispisi naziv firme u gornjem dijelu zaglavlja
   FOR i := 1 TO Len( aTmp )
      p_line( aTmp[ i ], 10, .T. )
   NEXT

   // ispisi dodatni tekst ispod naziva firme
   IF !Empty( cIPNaziv )
      cTmp := AllTrim( cIPNaziv )
      aTmp := SjeciStr( cTmp, 74 )
      i := 1
      FOR i := 1 TO Len( aTmp )
         p_line( aTmp[ i ], 10, .T. )
      NEXT
   ENDIF

   IF nSw2 == 1
      // ako je 1 neka ima duzinu kao naziv firme
      nPom := Len( cINaziv )
   ELSEIF nSw2 == 0
      // ne prikazuj
      nPom := 0
   ELSE
      // duzina zadata
      nPom := nSw2
   ENDIF
   cPom := Replicate( "-", nPom )
   p_line( cPom, 10, .T. )


   p_line( _l( "Adresa: " ) + cIAdresa + _l( ", ID broj: " ) + cIIdBroj, 12, .F. )
   p_line( cITelef, 12, .F. )
   p_line( cIWeb, 12, .F. )
   p_line( cSLHead, 10, .F. )

   p_line( _l( "Banke: " ), 12, .F. )
   FOR i := 1 TO Len( aIBanke )
      IF i == 1
         ?? aIBanke[ i ]
      ELSE
         p_line( Space( 7 ) + aIBanke[ i ], 12, .F. )
      ENDIF
   NEXT

   IF !Empty( cIText1 + cIText2 + cIText3 )
      p_line( cSLHead, 10, .T. )
      p_line( cIText1, 12, .F. )
      p_line( cIText2, 12, .F. )
      p_line( cIText3, 12, .F. )
   ENDIF
   p_line( cDLHead, 10, .F. )
   ?

   nPRowsDelta := PRow() - nPRowsDelta
   IF IsPtxtOutput()
      nDuzStrKorekcija += nPRowsDelta * 7 / 100
   ENDIF

   RETURN



// definicija linije za glavnu tabelu sa stavkama
FUNCTION a4_line( cTip )

   LOCAL cLine

   IF cTip == "otpr_mp"
      otpr_mp_line()
      RETURN
   ENDIF

   // standardna porezna faktura

   cLine := RAZMAK
   cLine += Replicate( "-", LEN_RBR )
   cLine += " " + Replicate( "-", LEN_NAZIV )
   // kolicina
   cLine += " " + Replicate( "-", LEN_KOLICINA )
   // cijena b. pdv
   cLine += " " + Replicate( "-", LEN_CIJENA )

   IF lShowPopust
      // popust
      cLine += " " + Replicate( "-", LEN_PROC2 )
      // cijen b. pdv - popust
      cLine += " " + Replicate( "-", LEN_CIJENA )
   ENDIF
   // vrijednost b. pdv
   cLine += " " + Replicate( "-", LEN_VRIJEDNOST )

   RETURN cLine


FUNCTION pf_a4_kupac( cRazmak )

   LOCAL cPartMjesto
   LOCAL cPartPTT
   LOCAL cKNaziv
   LOCAL cKAdresa
   LOCAL cKIdBroj
   LOCAL cKPorBroj
   LOCAL cKBrRjes
   LOCAL cKBrUpisa
   LOCAL cKMjesto
   LOCAL cKTelFax
   LOCAL aKupac
   LOCAL cMjesto
   LOCAL cDatDok
   LOCAL cFiscal
   LOCAL cDatIsp
   LOCAL cDatVal
   LOCAL cTipDok := _l( "FAKTURA br. " )
   LOCAL cBrDok
   LOCAL cBrNar
   LOCAL cBrOtp
   LOCAL cIdVd
   LOCAL cDokVeza
   LOCAL n
   LOCAL nLines
   LOCAL i
   LOCAL cLinijaNarOtp
   LOCAL nRowsIznad
   LOCAL nRowsIspod
   LOCAL nRowsOdTabele
   LOCAL nPRowsDelta

   IF cRazmak <> NIL
      RAZMAK := cRazmak
   ENDIF

   nPRowsDelta := PRow()

   nSw4 := Val( get_dtxt_opis( "X07" ) )
   nRowsIznad := Val( get_dtxt_opis( "X01" ) )
   nRowsIspod := Val( get_dtxt_opis( "X02" ) )
   nRowsOdTabele := Val( get_dtxt_opis( "X03" ) )

   nShowRj := Val( get_dtxt_opis( "X10" ) )

   IF nRowsIznad == nil
      nRowsIznad := 0
   ENDIF

   IF nRowsIspod == nil
      nRowsIspod := 0
   ENDIF

   IF nRowsOdTabele == nil
      nRowsOdTabele := 0
   ENDIF

   IF nShowRj == nil
      nShowRj := 0
   ENDIF

   close_open_racun_tbl()
   SELECT drn
   GO TOP

   cDatDok := DToC( datdok )

   IF Empty( datIsp )
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
   cKIdBroj := get_dtxt_opis( "K15" )
   cKPdvBroj := get_dtxt_opis( "K16" )
   cDestinacija := get_dtxt_opis( "D08" )
   cRNalID := get_dtxt_opis( "O01" )
   cRnalDesc := get_dtxt_opis( "O02" )
   cIdVd := get_dtxt_opis( "D09" )
   cFiscal := AllTrim( get_dtxt_opis( "O10" ) )

   nLines := Val( get_dtxt_opis( "D30" ) )

   cDokVeza := ""

   nTmp := 30
   FOR n := 1 TO nLines
      cDokVeza += get_dtxt_opis( "D" + AllTrim( Str( nTmp + n ) ) )
   NEXT

   IF nShowRj == 1
      cIdRj := get_dtxt_opis( "D10" )
   ENDIF

   cPartMjesto := get_dtxt_opis( "K10" )
   cPartPTT := get_dtxt_opis( "K11" )
   cInoDomaci := AllTrim( get_dtxt_opis( "P11" ) )


   cKMjesto := AllTrim( cPartMjesto )
   IF !Empty( cPartPTT )
      cKMjesto := AllTrim( cPartPTT ) + " " + cKMjesto
   ENDIF

   aKupac := Sjecistr( cKNaziv, 30 )

   cPom := ""

   FOR i := 1 TO nRowsIznad
      ?
   NEXT

   lKomision := .F.

   DO CASE
   CASE cIdVd == "12" .AND. cInoDomaci == "KOMISION"
      cPom := _l( "Komisionar:" )
      lKomision := .T.

   CASE AllTrim( cInoDomaci ) == "INO"

      DO CASE
      CASE cIdVd $ "10#11#20#22#29"
         cPom := _l( "Ino-Kupac:" )
      OTHERWISE
         cPom := _l( "Partner" )
      ENDCASE

   CASE AllTrim( cInoDomaci ) == "DOMACA"

      DO CASE
      CASE cIdVd == "12"
         cPom := _l( "Prima:" )
      CASE cIdVd $ "10#11#20#29"
         cPom := _l( "Kupac:" )
      OTHERWISE
         cPom := _l( "Partner:" )
      ENDCASE

   OTHERWISE
      DO CASE
      CASE cIdVd == "12"
         cPom := _l( "Zaduzuje:" )
      CASE cIdVd $ "10#11#20#29"
         cPom := _l( "Kupac, oslobodjen PDV, cl. " ) + AllTrim( cInoDomaci )
      OTHERWISE
         cPom := _l( "Partner" )
      ENDCASE

   ENDCASE

   I_ON
   p_line( cPom, 10, .T. )
   p_line( Replicate( "-", nSw4 ), 10, .F. )
   I_OFF

   cPom := AllTrim( aKupac[ 1 ] )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC ), 10, .T. )
   B_OFF
   ?? PadL( cMjesto + ", " + cDatDok, LEN_DATUM )

   cPom := AllTrim( cKAdresa )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC ), 10, .T. )
   B_OFF
   IF cDatIsp <> DToC( CToD( "" ) )
      IF !( cIdVd $ "12#00#01" )
         ?? PadL( _l( "Datum isporuke: " ) + cDatIsp, LEN_DATUM )
      ENDIF
   ENDIF

   cPom := AllTrim( cKMjesto )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC ), 10, .T. )
   B_OFF
   IF cDatVal <> DToC( CToD( "" ) )
      IF !( cIdVd $ "12#00#01#20" )
         ?? PadL( _l( "Datum valute: " ) + cDatVal, LEN_DATUM )
      ENDIF
   ENDIF

   cPom := AllTrim( cKIdBroj )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom := _l( "ID broj: " ) + cPom
   p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC ), 10, .F. )

   IF !Empty( cKPdvBroj )
      cPom := AllTrim( cKPdvBroj )
      IF Empty( cPom )
         cPom := "-"
      ENDIF
      cPom := _l( "PDV broj: " ) + cPom
      p_line( Space( 2 ) + PadR( cPom, LEN_KUPAC ), 10, .F. )
   ENDIF

   cKTelFax := ""
   cPom := AllTrim( get_dtxt_opis( "K13" ) )
   IF !Empty( cPom )
      cKTelFax := _l( "tel: " ) + cPom
   ENDIF
   cPom := AllTrim( get_dtxt_opis( "K14" ) )
   IF !Empty( cPom )
      IF !Empty( cKTelFax )
         cKTelFax += ", "
      ENDIF
      cKTelFax += _l( "fax: " ) + cPom
   ENDIF

   IF !Empty( cKTelFax )
      p_line( Space( 2 ), 10, .F., .T. )
      P_12CPI
      ?? PadR( cKTelFax, LEN_KUPAC )
   ENDIF

   IF !Empty( cDokVeza ) .AND. cDokVeza <> "-"

      cDokVeza := "Veza: " + AllTrim( cDokVeza )
      aDokVeza := SjeciStr( cDokVeza, 70 )

      FOR i := 1 TO Len( aDokVeza )
         p_line( Space( 2 ), 10, .F., .T. )
         ?? aDokVeza[ i ]
      NEXT
   ENDIF

   IF !Empty( cRNalId ) .AND. cRNalId <> "-"

      cPom := " R.nal.: "
      cPom += "(" + cRNalId + ") " + cRNalDesc

      IF Empty( cDokVeza )
         p_line( Space( 2 ), 10, .F., .T. )
      ENDIF

      ?? AllTrim( cPom )
   ENDIF

   IF !Empty( cDestinacija )

      p_line( Replicate( "-", LEN_KUPAC - 10 ), 10, .F. )

      cPom := _l( "Za: " )  + AllTrim( cDestinacija )
      aPom := SjeciStr( cPom, 75 )

      B_ON

      FOR i := 1 TO Len( aPom )
         p_line( aPom[ i ], 12, .F. )
      NEXT

      B_OFF

      ?
   ENDIF

   IF !Empty( cFiscal ) .AND. cFiscal <> "0"
      p_line( "   Broj fiskalnog racuna: " + AllTrim( cFiscal ), 10, .F., .T. )
   ENDIF

   P_10CPI
   // broj dokumenta

   cPom := AllTrim( cTipDok )
   IF lKomision
      cPom := _l( "KOMISIONA DOSTAVNICA br. " )
   ENDIF

   IF nShowRj == 1
      cPom += cIdRj + "-" + cBrDok
   ELSE
      cPom += " " + cBrDok
   ENDIF

   cPom := AllTrim( cPom )
   p_line( PadL( cPom, LEN_KUPAC + LEN_DATUM ), 10, .T. )
   B_OFF

   // redova ispod
   FOR i := 1 TO nRowsIspod
      ?
   NEXT

   // ako je prikaz broja otpremnice itd...

   cLinijaNarOtp := ""
   cPom := cBrOtp
   lBrOtpr := .F.
   IF !Empty( cPom )
      cLinijaNarOtp := _l( "Broj otpremnice: " ) + cPom
      lBrOtpr := .T.
   ENDIF

   cPom := cBrNar
   IF !Empty( cPom )
      IF lBrOtpr
         cLinijaNarOtp += " , "
      ENDIF
      cLinijaNarOtp += _l( "Broj ugov./narudzb: " ) + cPom
   ENDIF

   IF !Empty( cLinijaNarOtp )
      p_line( cLinijaNarOtp, 12, .F. )

      FOR i := 1 TO nRowsOdTabele
         ?
      NEXT

   ELSE

      // samo ako maloprije nije bilo odvajanja
      // da ne pravimo nepotrebni prazan prostor
      IF nRowsIspod == 0
         FOR i := 1 TO nRowsOdTabele
            ?
         NEXT
      ENDIF

   ENDIF

   // koliko je redova odstampano u zaglavlju
   nPRowsDelta :=  PRow() - nPRowsDelta

   IF IsPtxtOutput()
      nDuzStrKorekcija += nPRowsDelta * 7 / 100
   ENDIF

   RETURN
// }


// funkcija za novu stranu
STATIC FUNCTION NStr_a4( nStr, lShZagl )

   // {
   LOCAL cLine

   cLine := a4_line( "pf" )

   // korekcija duzine je na svako strani razlicita
   nDuzStrKorekcija := 0

   P_COND
   ? cLine
   p_line( _l( "Prenos na sljedecu stranicu" ), 17, .F. )
   ? cLine

   IF nPicFRow > 0
      // za sada nam ne treba....
      // ?
      // gpPicF()
   ENDIF

   FF

   P_COND
   ? cLine
   IF nStr <> nil
      p_line( _l( "       Strana:" ) + Str( nStr, 3 ), 17, .F. )
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



// ---------------------------------------
// printaj rekapitulaciju PDV-a
// ---------------------------------------
STATIC FUNCTION print_total( cValuta, cLine )

   ? RAZMAK
   ?? PadL( _l( "Ukupno bez PDV (" ) + cValuta + ") :", LEN_UKUPNO )
   ?? show_number( drn->ukbezpdv, PIC_VRIJEDNOST )

   // provjeri i dodaj stavke vezane za popust
   IF Round( drn->ukpopust, 2 ) <> 0
      ? RAZMAK
      ?? PadL( _l( "Popust (" ) + cValuta + ") :", LEN_UKUPNO )
      ?? show_number( drn->ukpopust, PIC_VRIJEDNOST )

      ? RAZMAK
      ?? PadL( _l( "Uk.bez.PDV-popust (" ) + cValuta + ") :", LEN_UKUPNO )
      ?? show_number( drn->ukbpdvpop, PIC_VRIJEDNOST )
   ENDIF


   ? RAZMAK
   ?? PadL( _l( "PDV 17% :" ), LEN_UKUPNO )
   ?? show_number( drn->ukpdv, PIC_VRIJEDNOST )

   // zaokruzenje
   IF Round( drn->zaokr, 2 ) <> 0
      ? RAZMAK
      ?? PadL( _l( "Zaokruzenje (+/-):" ), LEN_UKUPNO )
      ?? show_number( Abs( drn->zaokr ), PIC_VRIJEDNOST )
   ENDIF

   ? cLine
   ? RAZMAK
   // ipak izleti za dva karaktera rekapitulacija u bold rezimu
   ?? Space( 50 - 2 )
   B_ON
   ?? PadL( _l( "** SVEUKUPNO SA PDV  (" ) + cValuta + ") :", LEN_UKUPNO - 50 )
   ?? show_number( drn->ukupno, PIC_VRIJEDNOST )
   B_OFF

   // popust na teret prodavca
   IF drn->( FieldPos( "ukpoptp" ) ) <> 0
      IF Round( drn->ukpoptp, 2 ) <> 0
         ? RAZMAK
         ?? PadL( _l( "Popust na teret prodavca (" ) + cValuta + ") :", LEN_UKUPNO )
         ?? show_number( drn->ukpoptp, PIC_VRIJEDNOST )

         ? RAZMAK
         ?? Space( 50 - 2 )
         B_ON
         ? PadL( _l( "SVEUKUPNO SA PDV - POPUST NA T.P. (" ) + cValuta + _l( ") : ZA PLATITI :" ), LEN_UKUPNO - 50 )
         ?? show_number( drn->ukupno - drn->ukpoptp, PIC_VRIJEDNOST )
         B_OFF
      ENDIF
   ENDIF

   cSlovima := get_dtxt_opis( "D04" )
   ? RAZMAK
   B_ON
   ?? _l( "slovima: " ) + cSlovima
   B_OFF
   ? cLine

   RETURN




FUNCTION NazivDobra( cIdRoba, cRobaNaz, cJmj )

   LOCAL cPom

   cPom := AllTrim( cIdRoba )
   cPom += " - " + AllTrim( cRobaNaz )
   IF !Empty( cJmj )
      cPom += " (" + AllTrim ( cJmj ) + ")"
   ENDIF

   RETURN cPom



FUNCTION show_popust( nPopust )

   LOCAL cPom
   LOCAL i

   FOR i := 0 TO 2
      IF Round( nPopust, i ) == Round( nPopust, 2 )
         cPom := Str( nPopust, LEN_PROC2, i )
         EXIT
      ENDIF
   NEXT

   cPom := AllTrim( cPom )

   IF Len( cPom ) < LEN_PROC2
      // ima prostora za dodati znak %
      cPom += "%"
   ENDIF

   RETURN PadL( cPom, LEN_PROC2 )



FUNCTION p_line( cPLine, nCpi, lBold, lNewLine )

   IF lNewLine == nil
      lNewline := .F.
   ENDIF

   IF Empty( cPLine )
      IF lNewLine
         IF Len( cPLine ) == 0
            cPLine := " "
         ENDIF
      ELSE
         RETURN
      ENDIF
   ENDIF

   ?
   P_COND
   ?? RAZMAK
   DO CASE
   CASE ( nCpi == 12 )
      P_12CPI
   CASE ( nCpi == 10 )
      P_10CPI
   CASE ( nCpi == 17 )
      P_COND
   CASE ( nCpi == 20 )
      P_COND2
   ENDCASE

   IF lBold
      B_ON
   ENDIF
   ??  cPLine

   RETURN



FUNCTION len_rbr( xPom )

   IF xPom <> NIL
      LEN_RBR := xPom
   ENDIF

   RETURN LEN_RBR


FUNCTION len_naziv( xPom )

   IF xPom <> NIL
      LEN_NAZIV := xPom
   ENDIF

   RETURN LEN_NAZIV

FUNCTION len_ukupno( xPom )

   IF xPom <> NIL
      LEN_UKUPNO := xPom
   ENDIF

   RETURN LEN_UKUPNO

FUNCTION len_kupac( xPom )

   IF xPom <> NIL
      LEN_KUPAC := xPom
   ENDIF

   RETURN LEN_KUPAC

FUNCTION len_datum( xPom )

   IF xPom <> NIL
      LEN_DATUM := xPom
   ENDIF

   RETURN LEN_DATUM

FUNCTION len_kolicina( xPom )

   IF xPom <> NIL
      LEN_KOLICINA := xPom
   ENDIF

   RETURN LEN_KOLICINA

FUNCTION len_cijena( xPom )

   IF xPom <> NIL
      LEN_CIJENA := xPom
   ENDIF

   RETURN LEN_CIJENA

FUNCTION len_vrijednost( xPom )

   IF xPom <> NIL
      LEN_VRIJEDNOST := xPom
   ENDIF

   RETURN LEN_VRIJEDNOST

FUNCTION len_proc2( xPom )

   IF xPom <> NIL
      LEN_PROC2 := xPom
   ENDIF

   RETURN LEN_PROC2

FUNCTION dec_proc2( xPom )

   IF xPom <> NIL
      DEC_PROC2 := xPom
   ENDIF

   RETURN DEC_PROC2

FUNCTION dec_kolicina( xPom )

   IF xPom <> NIL
      DEC_KOLICINA := xPom
   ENDIF

   RETURN DEC_KOLICINA

FUNCTION dec_cijena( xPom )

   IF xPom <> NIL
      DEC_CIJENA := xPom
   ENDIF

   RETURN DEC_CIJENA

FUNCTION dec_vrijednost( xPom )

   IF xPom <> NIL
      DEC_VRIJEDNOST := xPom
   ENDIF

   RETURN DEC_VRIJEDNOST

FUNCTION pic_proc2( xPom )

   IF xPom <> NIL
      PIC_PROC2 := xPom
   ENDIF

   RETURN PIC_PROC2


FUNCTION pic_kolicina( xPom )

   IF xPom <> NIL
      PIC_KOLICINA := xPom
   ENDIF

   RETURN PIC_KOLICINA

FUNCTION pic_cijena( xPom )

   IF xPom <> NIL
      PIC_CIJENA := xPom
   ELSEIF Empty( PIC_CIJENA )
      PIC_CIJENA := PadL( AllTrim( Right( fakt_pic_cijena(), LEN_CIJENA ) ), LEN_CIJENA, "9" )
   ENDIF

   RETURN PIC_CIJENA

FUNCTION pic_vrijednost( xPom )

   IF xPom <> NIL
      PIC_VRIJEDNOST := xPom
   ENDIF

   RETURN PIC_VRIJEDNOST

FUNCTION len_stranica( xPom )

   IF xPom <> NIL
      LEN_STRANICA := xPom
   ENDIF

   RETURN LEN_STRANICA

FUNCTION len_rekap_pdv( xPom )

   IF xPom <> NIL
      LDE_REKAP_PDV := xPom
   ENDIF

   RETURN LEN_REKAP_PDV



FUNCTION razmak( xPom )

   IF xPom <> NIL
      RAZMAK := xPom
   ENDIF

   RETURN RAZMAK



FUNCTION nSw1( xPom )

   IF xPom <> NIL
      nSw1 := xPom
   ENDIF

   RETURN nSw1



FUNCTION nSw2( xPom )

   IF xPom <> NIL
      nSw2 := xPom
   ENDIF

   RETURN nSw2



FUNCTION nSw3( xPom )

   IF xPom <> NIL
      nSw3 := xPom
   ENDIF

   RETURN nSw3



FUNCTION nSw4( xPom )

   IF xPom <> NIL
      nSw4 := xPom
   ENDIF

   RETURN nSw4



FUNCTION nSw5( xPom )

   IF xPom <> NIL
      nSw5 := xPom
   ENDIF

   RETURN nSw5




FUNCTION lomi_tarabe( cLomi )

   LOCAL nPos1
   LOCAL aLomi

   // rucno lomi
   aLomi := {}

   DO WHILE .T.
      nPos1 := At( "##", cLomi )
      IF nPos1 == 0
         // nema vise sta lomiti
         AAdd( aLomi, cLomi )
         EXIT
      ENDIF
      AAdd( aLomi, Left( cLomi, nPos1 - 1 ) )
      // ostatak
      cLomi := SubStr( cLomi, nPos1 + 2 )
   ENDDO

   RETURN aLomi



FUNCTION IsPtxtOutput()
   RETURN gpIni == "#%INI__#"


// --------------------------------
// korekcija za duzinu strane
// --------------------------------
STATIC FUNCTION DSTR_KOREKCIJA()

   LOCAL nPom

   nPom := Round( nDuzStrKorekcija, 0 )
   IF Round( nDuzStrKorekcija - nPom, 1 ) > 0.2
      nPom++
   ENDIF

   RETURN nPom


// --------------------------------
// PICTURE korekcija duzine
// --------------------------------
STATIC FUNCTION PICT_KOREKCIJA( nStr )

   LOCAL nPom

   IF nPicHRow == nil
      nPicHRow := 0
   ENDIF
   IF nPicFRow == nil
      nPicFRow := 0
   ENDIF

   IF nStr == 1
      nPom := ( nPicHRow + nPicFRow )
   ELSE
      nPom := nPicFRow
   ENDIF

   RETURN nPom
