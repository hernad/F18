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

STATIC LEN_COLONA :=  42
STATIC LEN_FOOTER := 14

STATIC lShowPopust

STATIC cLine
STATIC lPrintedTotal := .F.
STATIC nStr := 0
STATIC nDuzStrKorekcija := 0
STATIC nSw6

/* public F18 varijable koje lib koristi */
MEMVAR __print_opt


/*
   Korištenje:
   ----------
   - Prije poziva napniti drn.dbf, za to se koristi npr. fakt_stdok_pdv()

   Primjeri korištenja:
  ---------------------
   fakt/fakt_print_narudzbenica.prg
   - FUNCTION fakt_print_narudzbenica( cIdFirma, cIdTipDok, cBrDok )
   - FUNCTION fakt_print_narudzbenica_priprema()
*/

FUNCTION print_narudzbenica()

   PIC_KOLICINA( PadL( AllTrim( Right( fakt_pic_kolicina(), LEN_KOLICINA() ) ), LEN_KOLICINA(), "9" ) )
   PIC_VRIJEDNOST( PadL( AllTrim( Right( fakt_pic_iznos(), LEN_VRIJEDNOST() ) ), LEN_VRIJEDNOST(), "9" ) )
   PIC_CIJENA( PadL( AllTrim( Right( fakt_pic_cijena(), LEN_CIJENA() ) ), LEN_CIJENA(), "9" ) )

   close_open_racun_tbl()

   SELECT drn
   GO TOP

   IF EOF()
      RETURN .F.
   ENDIF

   LEN_NAZIV( 53 )
   LEN_UKUPNO( 99 )
   IF Round( drn->ukpopust, 2 ) <> 0
      lShowPopust := .T.
   ELSE
      lShowPopust := .F.
      LEN_NAZIV( LEN_NAZIV() + LEN_PROC2() + LEN_CIJENA() + 2 )
   ENDIF

   RETURN generisi_rpt()


STATIC FUNCTION generisi_rpt()

   LOCAL cNazivDobra, aNazivDobra
   LOCAL nLMargina // lijeva margina
   LOCAL nDodRedova // broj dodatnih redova
   LOCAL nSlTxtRow // broj redova slobodnog text-a
   LOCAL lSamoKol // prikaz samo kolicina
   LOCAL lZaglStr // zaglavlje na svakoj stranici
   LOCAL lDatOtp // prikaz datuma otpremnice i narudzbenice
   LOCAL cValuta // prikaz valute KM ili ???
   LOCAL lStZagl // automatski formirati zaglavlje
   LOCAL nGMargina // gornja margina

   STARTPRINT CRET .F.

   // nSw6 = prikaz samo kolicine 0, cijena 1
   nSw6 := Val( get_dtxt_opis( "X09" ) )

   lPrintedTotal := .F.

   get_nar_vars( @nLMargina, @nGMargina, @nDodRedova, @nSlTxtRow, @lSamoKol, @lZaglStr, @lStZagl, @lDatOtp, @cValuta )

   RAZMAK( Space( nLMargina ) )

   cLine := nar_line()

   nar_header()

   IF nSw6 == 0
      P_12CPI
   ENDIF

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   IF nSw6 > 0
      P_COND
   ENDIF

   st_zagl_data()

   nStr := 1

   SELECT rn
   DO WHILE !Eof()

      cNazivDobra := NazivDobra( rn->idroba, rn->robanaz, rn->jmj )
      aNazivDobra := SjeciStr( cNazivDobra, LEN_NAZIV() )

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

      IF nSw6 > 0

         // cijena bez pdv
         ?? show_number( rn->cjenbpdv, PIC_CIJENA() )
         ?? " "


         IF lShowPopust
            // procenat popusta
            ?? show_popust( rn->popust )
            ?? " "

            // cijena bez pd - popust
            ?? show_number( rn->cjen2bpdv, PIC_CIJENA() )
            ?? " "
         ENDIF


         // ukupno bez pdv
         ?? show_number( rn->cjenbpdv * rn->kolicina,  PIC_VRIJEDNOST() )
         ?? " "
      ENDIF

      IF Len( aNazivDobra ) > 1
         // DRUGI RED
         ? RAZMAK()
         ?? " "
         ?? Space( LEN_RBR() )
         ?? PadR( aNazivDobra[ 2 ], LEN_NAZIV() )
      ENDIF

      // provjeri za novu stranicu
      IF PRow() > ( nDodRedova + LEN_STRANICA() - DSTR_KOREKCIJA() )
         ++nStr
         Nstr_a4( nStr, .T., cValuta )
      endif

      SELECT rn
      SKIP
   ENDDO

   IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_FOOTER )
      ++nStr
      Nstr_a4( nStr, .T., cValuta )
   endif

   IF nSw6 > 0
      print_total( cValuta )
      lPrintedTotal := .T.

      IF PRow() > nDodRedova + ( LEN_STRANICA() - LEN_FOOTER )
         ++nStr
         Nstr_a4( nStr, .T. )
      endif
   ENDIF

   // dodaj text na kraju fakture
   nar_footer()


   FF
   ENDPRINT

   RETURN .T.


STATIC FUNCTION get_nar_vars( nLMargina, nGMargina, nDodRedova, nSlTxtRow, lSamoKol, lZaglStr, lStZagl, lDatOtp, cValuta, cPDVStavka )

   nLMargina := Val( get_dtxt_opis( "P01" ) )
   nGMargina := Val( get_dtxt_opis( "P07" ) )
   nDodRedova := Val( get_dtxt_opis( "P06" ) )
   nSlTxtRow := Val( get_dtxt_opis( "P02" ) )
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

   RETURN NIL


STATIC FUNCTION st_zagl_data()


   LOCAL cRed1 := ""


   ? cLine

   cRed1 := RAZMAK()
   cRed1 += PadC( "R.br", LEN_RBR() )
   cRed1 += " " + PadR( _l( "Trgovački naziv dobra/usluge (sifra, naziv, jmj)" ), LEN_NAZIV() )

   cRed1 += " " + PadC( _l( "količina" ), LEN_KOLICINA() )

   IF nSw6 > 0
      cRed1 += " " + PadC( _l( "C.b.PDV" ), LEN_CIJENA() )
      IF lShowPopust
         cRed1 += " " + PadC( _l( "Pop.%" ), LEN_PROC2() )
         cRed1 += " " + PadC( _l( "C.2.b.PDV" ), LEN_CIJENA() )
      ENDIF
      cRed1 += " " + PadC( _l( "Uk.bez.PDV" ), LEN_VRIJEDNOST() )
   ENDIF

   ? cRed1

   ? cLine

   RETURN NIL

STATIC FUNCTION nar_line()

   LOCAL cLine

   cLine := RAZMAK()
   cLine += Replicate( "-", LEN_RBR() )
   cLine += " " + Replicate( "-", LEN_NAZIV() )
   // kolicina
   cLine += " " + Replicate( "-", LEN_KOLICINA() )

   IF nSw6 > 0
      // cijena b. pdv
      cLine += " " + Replicate( "-", LEN_CIJENA() )

      IF lShowPopust
         // popust
         cLine += " " + Replicate( "-", LEN_PROC2() )
         // cijen b. pdv - popust
         cLine += " " + Replicate( "-", LEN_CIJENA() )
      ENDIF

      // vrijednost b. pdv
      cLine += " " + Replicate( "-", LEN_VRIJEDNOST() )
   ENDIF

   RETURN cLine

STATIC FUNCTION print_total( cValuta )

   LOCAL cSlovima

   ? cLine

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


   // provjeri i dodaj stavke vezane za popust
   IF Round( drn->ukpopust, 2 ) <> 0
      ? RAZMAK()
      ?? PadL( _l( "Popust (" ) + cValuta + ") :", LEN_UKUPNO() )
      ?? show_number( drn->ukpopust, PIC_VRIJEDNOST() )

      ? RAZMAK()
      ?? PadL( _l( "Uk.bez.PDV-popust (" ) + cValuta + ") :", LEN_UKUPNO() )
      ?? show_number( drn->ukbpdvpop, PIC_VRIJEDNOST() )
   ENDIF


   // obracun PDV-a
   ? RAZMAK()
   ?? PadL( _l( "PDV 17% :" ), LEN_UKUPNO() )
   ?? show_number( drn->ukpdv, PIC_VRIJEDNOST() )


   // zaokruzenje
   IF Round( drn->zaokr, 4 ) <> 0
      ? RAZMAK()
      ?? PadL( _l( "Zaokruzenje :" ), LEN_UKUPNO() )
      ?? show_number( drn->zaokr, PIC_VRIJEDNOST() )
   ENDIF

   ? cLine
   ? RAZMAK()
   // ipak izleti za dva karaktera rekapitulacija u bold rezimu
   ?? Space( 50 - 2 )
   B_ON
   ?? PadL( _l( "** SVEUKUPNO SA PDV  (" ) + cValuta + ") :", LEN_UKUPNO() - 50 )
   ?? Transform( drn->ukupno, PIC_VRIJEDNOST() )
   B_OFF


   cSlovima := get_dtxt_opis( "D04" )
   ? RAZMAK()
   B_ON
   ?? _l( "slovima: " ) + cSlovima
   B_OFF
   ? cLine

   RETURN NIL


// ----------------------------------------
// funkcija za ispis podataka o kupcu
// ----------------------------------------
STATIC FUNCTION nar_header()

   LOCAL cPom, cPom2
   LOCAL cLin
   LOCAL cPTT
   LOCAL cNaziv, cNaziv2
   LOCAL cAdresa, cAdresa2
   LOCAL cIdBroj, cIdBroj2
   LOCAL cMjesto, cMjesto2
   LOCAL cTelFax, cTelFax2
   LOCAL aKupac, aDobavljac
   LOCAL cDatDok
   LOCAL nPRowsDelta
   LOCAL cDestinacija

   nPRowsDelta := PRow()

   close_open_racun_tbl()
   SELECT drn
   GO TOP

   cDatDok := DToC( field->datdok )

   cNaziv := get_dtxt_opis( "K01" )
   cAdresa := get_dtxt_opis( "K02" )
   cIdBroj := get_dtxt_opis( "K03" )
   cDestinacija := get_dtxt_opis( "D08" )

   cTelFax := "tel: "
   cPom := AllTrim( get_dtxt_opis( "K13" ) )

   IF Empty( cPom )
      cPom := "-"
   ENDIF

   cTelFax += cPom
   cPom := AllTrim( get_dtxt_opis( "K14" ) )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cTelFax += ", fax: " + cPom

   // K10 - partner mjesto
   cMjesto := get_dtxt_opis( "K10" )
   // K11 - partner PTT
   cPTT := get_dtxt_opis( "K11" )


   PushWA()

   //SELECT F_PARTN
   //IF !Used()
    //  o_partner()
  // ENDIF

   select_o_partner( self_organizacija_id() )

   cNaziv2  := AllTrim( partn->naz )
   cMjesto2 := AllTrim( partn->ptt ) + " " + AllTrim( partn->mjesto )
   cAdresa2 := get_dtxt_opis( "I02" )
   // idbroj
   cIdBroj2 := get_dtxt_opis( "I03" )
   cTelFax2 := "tel: " + AllTrim( partn->telefon )  + ", fax: " + AllTrim( partn->fax )

   PopWa()

   cMjesto := AllTrim( cMjesto )
   IF !Empty( cPTT )
      cMjesto := AllTrim( cPTT ) + " " + cMjesto
   ENDIF

   aKupac := Sjecistr( cNaziv, LEN_COLONA )
   aDobavljac := SjeciStr( cNaziv2, LEN_COLONA )

   B_ON
   cPom := PadR( _l( "Naručioc:" ), LEN_COLONA ) + " " + PadR( _l( "Dobavljač:" ), LEN_COLONA )

   p_line( cPom, 12, .T. )

   cPom := PadR( Replicate( "-", LEN_COLONA - 2 ), LEN_COLONA )
   cLin := cPom + " " + cPom
   p_line( cLin, 12, .F. )

   // prvi red kupca, 10cpi, bold
   cPom := AllTrim( aKupac[ 1 ] )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom := PadR( cPom, LEN_COLONA )

   // prvi red dobavljaca, 10cpi, bold
   cPom2 := AllTrim( aDobavljac[ 1 ] )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := cPom +  " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .F. )


   cPom := AllTrim( cAdresa )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cAdresa2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF

   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )

   // mjesto
   cPom := AllTrim( cMjesto )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cMjesto2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )

   // idbroj
   cPom := AllTrim( cIdBroj )
   IF Empty( cPom )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cIdBroj2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF
   cPom := PadR( _l( "ID: " ) + cPom, LEN_COLONA )
   cPom += " " + PadR( _l( "ID: " ) + cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )


   // telfax
   cPom := AllTrim( cTelFax )
   IF Empty( cTelFax )
      cPom := "-"
   ENDIF
   cPom2 := AllTrim( cTelFax2 )
   IF Empty( cPom2 )
      cPom2 := "-"
   ENDIF


   cPom := PadR( cPom, LEN_COLONA )
   cPom += " " + PadR( cPom2, LEN_COLONA )
   p_line( cPom, 12, .T. )


   p_line( cLin, 12, .T. )

   B_OFF

   IF !Empty( cDestinacija )
      ?
      p_line( Replicate( "-", LEN_KUPAC() - 10 ), 12, .F. )
      cPom := _l( "Destinacija: " )  + AllTrim( cDestinacija )
      p_line( cPom, 12, .F. )
      ?
   ENDIF


   ?
   ?
   P_10CPI
   // broj dokumenta
   cPom := _l( "NARUDŽBENICA br. ___________ od " ) + cDatDok
   cPom := PadC( cPom, LEN_COLONA * 2 )
   p_line( cPom, 10, .T. )
   B_OFF
   ?
   cPom := _l( "Molimo da nam na osnovu ponude/dogovora/ugovora _________________ " )
   p_line( cPom, 12, .F. )
   cPom := _l( "isporučite sljedeca dobra/usluge:" )
   p_line( cPom, 12, .F. )

   nPRowsDelta := PRow() - nPRowsDelta
   IF IsPtxtOutput()
      nDuzStrKorekcija += nPRowsDelta * 7 / 100
   ENDIF

   RETURN NIL


STATIC FUNCTION nar_footer()

   LOCAL cPom

   ?
   cPom := _l( "USLOVI NABAVKE:" )
   p_line( cPom, 12, .T. )
   cPom := "----------------"
   p_line( cPom, 12, .T. )
   ?
   cPom := _l( "Mjesto isporuke _______________________  Način placanja: gotovina/banka/kompenzacija" )
   p_line( cPom, 12, .T. )
   ?
   cPom := _l( "Vrijeme isporuke _____________________________________________________________" )
   ?
   p_line( cPom, 12, .T. )
   ?
   cPom := _l( "Napomena: Molimo popuniti prazna polja, te zaokružiti željene opcije" )
   p_line( cPom, 20, .F. )

   ?
   cPom := PadL( _l( " M.P.          " ), LEN_COLONA ) + " "
   cPom += PadC( _l( "Za naručioca:" ), LEN_COLONA )
   p_line( cPom, 12, .F. )
   ?
   cPom := PadC( " ", LEN_COLONA ) + " "
   cPom += PadC( Replicate( "-", LEN_COLONA - 4 ), LEN_COLONA )
   p_line( cPom, 12, .F. )

   ?

   RETURN NIL

// -----------------------------------------
// funkcija za novu stranu
// -----------------------------------------
STATIC FUNCTION NStr_a4( nStr, lShZagl, cValuta )

   nDuzStrKorekcija := 0

   P_COND
   ? cLine
   p_line( _l( "Prenos na sljedeću stranicu" ), 17, .F. )
   ? cLine

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
         print_total( cLine, cValuta )
      ENDIF
   ELSE
      ? cLine
   ENDIF

   RETURN NIL


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
