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


FUNCTION st_pf_a4_2( lStartPrint )

   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cRazmak
   LOCAL cLine
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
   PRIVATE cPDVSvStavka // varijanta fakture

   IF lStartPrint
      START PRINT CRET
   ENDIF

   // uzmi glavne varijable za stampu fakture
   // razmak, broj redova sl.teksta,
   get_pfa4_vars( @nLMargina, @nGMargina, @nDodRedova, @nSlTxtRow, @lSamoKol, @lZaglStr, @lStZagl, @lDatOtp, @cValuta, @cPDVSvStavka )

   cRazmak := Space( nLMargina )

   IF lStZagl
      pf_a4_header()
   ELSE
      FOR i := 1 TO nGMargina
         ?
      NEXT
   ENDIF

   pf_a4_kupac( cRazmak )

   pf_a4_line( @cLine, cRazmak )

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   P_COND

   st_zagl_data( cLine, cRazmak, "2" )

   SELECT rn

   nStr := 1
   aArtNaz := {}

   DO WHILE !Eof()

      IF PRow() > nDodRedova + 48 - nSlTxtRow
         ++nStr
         NStr( cLine, nStr, cRazmak, .T. )
      endif

      aArtNaz := SjeciStr( rn->robanaz, 40 )

      // PRVI RED

      IF Empty( rn->podbr )
         ? cRazmak + PadL( rn->rbr + ")", 6 ) + Space( 1 )
      ELSE
         ? cRazmak + PadL( rn->rbr + "." + AllTrim( rn->podbr ), 6 ) + Space( 1 )
      ENDIF

      ?? PadR( rn->idroba, 10 ) + Space( 1 )
      ?? PadR( aArtNaz[ 1 ], 40 ) + Space( 1 )
      ?? Transform( rn->kolicina, fakt_pic_kolicina() ) + Space( 1 )
      ?? rn->jmj + Space( 1 )

      IF !lSamoKol
         ?? Transform( rn->cjenbpdv, fakt_pic_cijena() ) + Space( 1 )
         ?? Transform( rn->cjen2bpdv, fakt_pic_cijena() ) + Space( 1 )

         IF cPDVSvStavka == "D"
            ?? Transform( rn->vpdv, fakt_pic_cijena() ) + Space( 1 )
         ELSE
            ?? Transform( rn->cjen2pdv, fakt_pic_cijena() ) + Space( 1 )
         ENDIF

         ?? Transform( rn->cjen2bpdv * rn->kolicina,  fakt_pic_iznos() )
      ENDIF

      cArtNaz2Red := Space( 40 )

      IF Len( aArtNaz ) > 1
         cArtNaz2Red := aArtNaz[ 2 ]
      ENDIF

      // DRUGI RED
      ? cRazmak + Space( 18 ) + PadR( cArtNaz2Red, 40 )

      IF !lSamoKol
         nPopust := rn->popust
         IF rn->( FieldPos( "poptp" ) ) <> 0
            IF rn->poptp <> 0
               nPopust := rn->poptp
            ENDIF
         ENDIF

         ?? Space( 22 ) + Transform( nPopust, "99.99%" ) + Space( 1 )

         IF cPDVSvStavka == "D"
            ?? Transform( rn->cjen2pdv, fakt_pic_cijena() ) + Space( 1 )
         ENDIF

         ?? PadL( Transform( rn->ppdv, "999.99%" ), 11 )

         ?? Space( Len( fakt_pic_iznos() ) + 2 )

         ?? Transform( rn->ukupno, fakt_pic_iznos() )

      ENDIF

      SKIP
   ENDDO

   ? cLine

   IF !lSamoKol
      ? cRazmak + PadL( "Ukupno bez PDV (" + cValuta + ") :", 95 ), PadL( Transform( drn->ukbezpdv, fakt_pic_iznos() ), 26 )
      IF Round( drn->ukpopust, 2 ) <> 0
         ? cRazmak + PadL( "Popust (" + cValuta + ") :", 95 ), PadL( Transform( drn->ukpopust, fakt_pic_iznos() ), 26 )
         ? cRazmak + PadL( "Uk.bez.PDV-popust (" + cValuta + ") :", 95 ), PadL( Transform( drn->ukbpdvpop, fakt_pic_iznos() ), 26 )
      ENDIF
      ? cRazmak + PadL( "PDV 17% :", 95 ), PadL( Transform( drn->ukpdv, fakt_pic_iznos() ), 26 )
      IF Round( drn->zaokr, 2 ) <> 0
         ? cRazmak + PadL( "Zaokruzenje (+/-):", 95 ), PadL( Transform( Abs( drn->zaokr ), fakt_pic_iznos() ), 26 )
      ENDIF

      ? cLine
      ? cRazmak + PadL( "S V E U K U P N O   S A   P D V (" + cValuta + ") :", 95 ), PadL( Transform( drn->ukupno, fakt_pic_iznos() ), 26 )

      IF drn->( FieldPos( "ukpoptp" ) ) <> 0
         IF Round( drn->ukpoptp, 2 ) <> 0
            // popust na teret prodavca
            ? cRazmak + PadL( "Popust na teret prodavca (" + cValuta + ") :", 95 ), PadL( Transform( drn->ukpoptp, fakt_pic_iznos() ), 26 )
            ? cRazmak + PadL( "S V E U K U P N O   S A   P D V -  P O P U S T  N A   T. P. (" + cValuta + ") : ZA PLATITI :", 95 ), PadL( Transform( drn->ukupno - drn->ukpoptp, fakt_pic_iznos() ), 26 )
         ENDIF
      ENDIF

      cSlovima := get_dtxt_opis( "D04" )
      ? cRazmak + "slovima: " + cSlovima
      ? cLine
   ENDIF

   ?
   pf_a4_footer( cRazmak, cLine )

   ?

   IF lStartPrint
      FF
      ENDPRINT
   ENDIF

   RETURN


STATIC FUNCTION st_zagl_data( cLine, cRazmak, cVarijanta )

   LOCAL cRed1 := ""
   LOCAL cRed2 := ""
   LOCAL cRed3 := ""

   IF cVarijanta == nil
      cVarijanta := "2"
   ENDIF

   ? cLine

   DO CASE
   CASE cVarijanta == "1"
      cRed1 := " R.br  Sifra      Naziv                                      Kolicina  jmj  C.bez PDV   C.bez PDV   Pojed.PDV   Sveukupno"
      cRed2 := Space( 75 ) + " Popust(%)   C.sa PDV    PDV(%)       sa PDV"
   CASE cVarijanta == "2"
      cRed1 := " R.br  Sifra      Naziv                                      Kolicina  jmj  C.bez PDV   C.bez PDV    C.sa PDV   Uk.bez PDV"
      cRed2 := Space( 75 ) + " Popust(%)     PDV(%)                Uk.sa PDV"
   ENDCASE

   IF !Empty( cRed1 )
      ? cRazmak + cRed1
   ENDIF
   IF !Empty( cRed2 )
      ? cRazmak + cRed2
   ENDIF
   IF !Empty( cRed3 )
      ? cRazmak + cRed3
   ENDIF

   ? cLine

   RETURN


FUNCTION pf_a4_sltxt( cRazmak, cLine )

   LOCAL cTxt
   LOCAL nFTip

   IF PRow() > nDodRedova + 48 - nSlTxtRow
      NStr( cLine, nil, cRazmak, .F. )
   ENDIF


   SELECT drntext
   SET ORDER TO TAG "1"
   HSEEK "F20"

   DO WHILE !Eof() .AND. field->tip = "F"
      nFTip := Val( Right( field->tip, 2 ) )
      IF nFTip < 51
         cTxt := AllTrim( field->opis )
         IF !Empty( cTxt )
            ? cRazmak + cTxt
         ENDIF
      ENDIF
      SKIP
   ENDDO

   RETURN


STATIC FUNCTION pf_a4_footer( cRazmak, cLine )

   pf_a4_sltxt( cRazmak, cLine )
   ?
   P_12CPI
   ?
   ? cRazmak + Space( 10 ) + get_dtxt_opis( "F10" )

   RETURN


STATIC FUNCTION pf_a4_header()

   LOCAL cRazmak := Space( 3 )
   LOCAL cDLHead := Replicate( "=", 72 ) // double line header
   LOCAL cSLHead := Replicate( "-", 72 ) // single line header
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

   cINaziv  := get_dtxt_opis( "I01" ) // naziv
   cIAdresa := get_dtxt_opis( "I02" ) // adresa
   cIIdBroj := get_dtxt_opis( "I03" ) // idbroj
   cIBanke  := get_dtxt_opis( "I09" )
   aIBanke  := SjeciStr( cIBanke, 68 )
   cITelef  := get_dtxt_opis( "I10" ) // telefoni
   cIWeb    := get_dtxt_opis( "I11" ) // email-web
   cIText1  := get_dtxt_opis( "I12" ) // sl.text 1
   cIText2  := get_dtxt_opis( "I13" ) // sl.text 2
   cIText3  := get_dtxt_opis( "I14" ) // sl.text 3

   P_10CPI
   ? cRazmak + cDLHead
   B_ON
   ? cRazmak + cINaziv
   ? cRazmak + Replicate( "-", Len( cINaziv ) )
   B_OFF

   P_12CPI
   ? cRazmak + " Adresa: " + cIAdresa + ",     ID broj: " + cIIdBroj
   IF !Empty( cITelef )
      ? " " + cRazmak + cITelef
   ENDIF
   IF !Empty( cIWeb )
      ? " " + cRazmak + cIWeb
   ENDIF

   P_10CPI
   ? cRazmak + cSLHead

   P_12CPI
   ? cRazmak + " Banke: "
   FOR i := 1 TO Len( aIBanke )
      IF i == 1
         ?? aIBanke[ i ]
      ELSE
         ? " " + cRazmak + aIBanke[ i ] + " "
      ENDIF
   NEXT

   P_10CPI
   IF !Empty( cIText1 + cIText2 + cIText3 )
      ? cRazmak + cSLHead
      IF !Empty( cIText1 )
         ? cRazmak + cIText1
      ENDIF
      IF !Empty( cIText2 )
         ? cRazmak + cIText2
      ENDIF
      IF !Empty( cIText3 )
         ? cRazmak + cIText3
      ENDIF
   ENDIF

   ? cRazmak + cDLHead

   ?
   ?

   RETURN


STATIC FUNCTION pf_a4_line( cLine, cRazmak )

   cLine := cRazmak
   // RBR
   cLine += Replicate( "-", 6 ) + Space( 1 )
   // SIFRA
   cLine += Replicate( "-", 10 ) + Space( 1 )
   // NAZIV
   cLine += Replicate( "-", 40 ) + Space( 1 )
   // KOLICINA
   cLine += Replicate( "-", 11 ) + Space( 1 )
   // JMJ
   cLine += Replicate( "-", 3 ) + Space( 1 )
   // C.BEZ PDV
   cLine += Replicate( "-", 11 ) + Space( 1 )
   // C.BEZ PDV
   cLine += Replicate( "-", 11 ) + Space( 1 )
   // POJED.PDV
   cLine += Replicate( "-", 11 ) + Space( 1 )
   // SVEUKUPNO
   cLine += Replicate( "-", 11 ) + Space( 1 )

   RETURN




// funkcija za novu stranu
STATIC FUNCTION NStr( cLine, nStr, cRazmak, lShZagl )

   // {

   ? cLine
   ? cRazmak + "Prenos na sljedecu stranicu"
   ? cLine

   FF

   ? cLine
   IF nStr <> nil
      ? cRazmak, "       Strana:", Str( nStr, 3 )
   ENDIF
   IF lShZagl
      IF cPDVSvStavka == "D"
         st_zagl_data( cLine, cRazmak, "1" )
      ELSE
         st_zagl_data( cLine, cRazmak, "2" )
      ENDIF
   ELSE
      ? cLine
   ENDIF

   RETURN
// }
