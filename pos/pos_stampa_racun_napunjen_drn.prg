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

STATIC LEN_TRAKA  := 40
STATIC LEN_RAZMAK :=  0
STATIC LEN_RBR    :=  3
STATIC LEN_NAZIV  := 25
STATIC LEN_UKUPNO := 10

STATIC PIC_UKUPNO := "9999999.99"

FUNCTION pos_stampa_racun_napunjen_drn( lPriprema )

   LOCAL nIznUkupno
   LOCAL lPrintPfTraka := .F.
   LOCAL lGetKupData := .F.
   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cLine
   LOCAL lViseRacuna := .F.
   LOCAL nPFeed
   // sekv.otvaranja ladice
   LOCAL cOtvLadSkv
   // prikaz kupca na racunu
   LOCAL lKupac
   // sekv.sjecenja trake
   LOCAL cSjeTraSkv
   LOCAL cZakBr := ""
   LOCAL nSetCijene
   LOCAL lStRobaId
   LOCAL nRedukcija
   LOCAL cRb_row
   LOCAL aRb_row
   LOCAL aRb_row_1
   LOCAL aRb_row_2
   LOCAL nRedova1
   LOCAL nRedova2
   LOCAL cPop_row
   LOCAL cPom
   LOCAL nLen
   LOCAL cNum

   close_open_racun_tbl()
   nIznUkupno := get_rb_ukupno()


   rb_traka_line( @cLine )
   // uzmi glavne varijable
   pos_get_racun_broj_varijable( @nPFeed, @cOtvLadSkv, @cSjeTraSkv, @nSetCijene, @lStRobaId, @nRedukcija, @lKupac )

   START PRINT CRET

   hd_rb_traka( nRedukcija )

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   // mjesto i datum racuna
   ? Space( LEN_RAZMAK ) + " " + drn->vrijeme + PadL( get_rn_mjesto() + ", " + DToC( drn->datdok ), 32 )

   ? cLine
   // broj racuna
   cPom :=  "POS RACUN br. " + AllTrim( drn->brdok )
   IF lPriprema
      // IF lStartPrint
      cPom += Space( 8 ) + "PREPIS"
      // ENDIF
   ENDIF

   ? PadC( cPom, LEN_TRAKA )

   ? cLine
   cPom := ""
   cPom += PadC( "Rbr", LEN_RBR )
   cPom += " "
   cPom += PadC( "Artikal (jmj), kol x cij", LEN_NAZIV )
   cPom += " "
   IF nSetCijene == 2
      cPom += PadC( "Uk.sa.PDV", LEN_UKUPNO )
   ELSE
      cPom += PadC( "Uk.sa.PDV", LEN_UKUPNO )
   ENDIF

   ? cPom
   ? cLine

   SELECT rn

   // stampa stavki racuna
   DO WHILE !Eof()

      // odredi tip cijene za prikaz
      IF nSetCijene == 2 // cijena sa pdv
         nPdvCijena := rn->cjenpdv
         nRnUkupno := rn->ukupno
      ELSE
         nPdvCijena := rn->cjenbpdv
         nRnUkupno := rn->ukupno
      ENDIF

      // R.br
      cStr1 := PadR( rn->rbr, LEN_RBR ) +  " "

      // id.roba
      IF lStRobaId // prikaz id robe .t.
         cStr1 += AllTrim( rn->idroba ) + " - "
      ENDIF

      // naziv
      cStr1 += AllTrim( rn->robanaz )
      // jmj
      cStr1 += " (" + AllTrim( rn->jmj ) + ")"
      // prvi dio do kolicine
      cStr2 := ""

      // kolicina
      cStr2 += " " + AllTrim( show_number( rn->kolicina, NIL, - 10 ) )
      // puta
      cStr2 += " x "
      // cijena
      cStr2 += AllTrim( show_number( nPdvCijena, NIL, - 10 ) )


      // da li postoji popust
      IF Round( rn->cjen2pdv, 4 ) <> 0

         // cijena sa pdv
         IF nSetCijene == 2
            nPopcjen := rn->cjen2pdv
         ELSE
            nPopcjen := rn->cjen2bpdv
         ENDIF
         cStr2 += " , cij-pop " + AllTrim( show_number( rn->popust, NIL, - 5 ) ) + "% = "
         cStr2 += AllTrim( show_number( nPopcjen, NIL, - 10 ) )

      ENDIF

      cNum := AllTrim( show_number( nRnUkupno, PIC_UKUPNO ) )
      // sve spoji pa presjeci
      aRb_row_1 := SjeciStr( cStr1 + cStr2, LEN_TRAKA - LEN_RAZMAK - LEN_RBR - 1 )
      // trebam redova u varijanti 1
      nRedova1 := Len( aRb_row_1 )
      IF  LEN_RAZMAK + LEN_RBR + 1 + Len( Trim( aRb_row_1[ nRedova1 ] ) ) + 1 + Len( cNum ) > LEN_TRAKA
         ++nRedova1
      ENDIF

      // varijanta 2 prvo presjeci string 1
      aRb_row_2 := SjeciStr( cStr1, LEN_TRAKA - LEN_RAZMAK - LEN_RBR - 1 )
      // nastiklaj matricu
      SjeciStr( cStr2, LEN_TRAKA - LEN_RAZMAK - LEN_RBR - 1, @aRb_row_2 )

      nRedova2 := Len( aRb_row_2 )
      IF  LEN_RAZMAK + LEN_RBR + 1 + Len( Trim( aRb_row_2[ nRedova2 ] ) ) + 1 + Len( cNum ) > LEN_TRAKA
         ++nRedova2
      ENDIF

      IF nRedova2 > nRedova1
         aRb_row := aRb_row_1
      ELSE
         // ljepsa varijanta
         aRb_row := aRb_row_2
      ENDIF

      // prikazi sve do predzadnjeg reda
      FOR i := 1 TO ( Len( aRb_row ) - 1 )
         ? Space( LEN_RAZMAK )
         IF i > 1
            ?? Space( LEN_RBR + 1 )
         ENDIF
         ?? aRb_row[ i ]

         nLenRow := Len( Trim( aRb_row[ i ] ) )
      NEXT

      // ostaje prikaz zadnjeg reda
      cPom := Trim( aRb_row[ Len( aRb_row ) ] )
      nLen := Len( cPom )

      // ako se ne moze nastiklati iznos ukupno na zadnji red
      // onda ga i neces dodavati sad
      IF LEN_RAZMAK + LEN_RBR + 1 + nLen + 1 + Len( cNum )  > LEN_TRAKA
         ? Space( LEN_RAZMAK )
         ?? Space( LEN_RBR + 1 )
         ?? cPom
         cPom := ""
         nLen := 0
      ENDIF

      // ispis zadnjeg reda
      ? Space( LEN_RAZMAK )
      // nije prvi red napravi indent za redni broj
      IF Len( aRb_row ) > 1
         ?? Space( LEN_RBR + 1 )
         cPom += PadL( cNum, LEN_TRAKA - nLen - LEN_RBR - LEN_RAZMAK - 1 )
      ELSE
         // prvi red
         cPom += PadL( cNum, LEN_TRAKA - nLen - LEN_RAZMAK )
      ENDIF
      ?? cPom

      SKIP
   ENDDO
   ? cLine

   ? Space( LEN_RAZMAK ) + PadL( "Ukupno bez PDV (KM):", LEN_TRAKA - LEN_UKUPNO - 1 ), show_number( drn->ukbezpdv, PIC_UKUPNO )
   // dodaj i popust
   IF Round( drn->ukpopust, 2 ) <> 0
      ? Space( LEN_RAZMAK ) + PadL( "Popust (KM):", LEN_TRAKA - LEN_UKUPNO - 1 ), show_number( drn->ukpopust, PIC_UKUPNO )
      ? Space( LEN_RAZMAK ) + PadL( "Uk.bez.PDV-popust (KM):", LEN_TRAKA - LEN_UKUPNO - 1 ), show_number( drn->ukbpdvpop, PIC_UKUPNO )
   ENDIF
   ? Space( LEN_RAZMAK ) + PadL( "PDV 17% :", LEN_TRAKA - LEN_UKUPNO - 1 ), show_number( drn->ukpdv, PIC_UKUPNO )

   IF Round( drn->zaokr, 2 ) <> 0
      ? Space( LEN_RAZMAK ) + PadL( "zaokruzenje (+/-):", LEN_TRAKA - LEN_UKUPNO - 1 ), show_number( Abs( drn->zaokr ), PIC_UKUPNO )
   ENDIF

   ? cLine
   ? Space( LEN_RAZMAK ) + PadL( "UKUPNO ZA NAPLATU (KM):", LEN_TRAKA - LEN_UKUPNO - 1 ), PadL( show_number( drn->ukupno, "******9.99" ), LEN_UKUPNO )
   ? cLine

   ft_rb_traka()

   ENDPRINT

   RETURN .T.


FUNCTION pos_get_racun_broj_varijable( nFeedLines, cOLadSkv, cSTrakSkv, nPdvCijene, lStampId, nVrRedukcije, lPrKupac )

   LOCAL cTmp

   // broj linija za odcjepanje trake
   nFeedLines := Val( get_dtxt_opis( "P12" ) )
   cOLadSkv := get_dtxt_opis( "P13" ) // sekv.za otv.ladice
   cSTrakSkv := get_dtxt_opis( "P14" ) // sekv.za sjec.trake
   nPdvCijene := Val( get_dtxt_opis( "P20" ) ) // cijene sa pdv, bez pdv
   cTmp := get_dtxt_opis( "P21" ) // prikaz id artikal na racunu
   lStampId := .F.
   lPrKupac := .F.

   IF ( cTmp == "D" )
      lStampId := .T.
   ENDIF

   nVrRedukcije := Val( get_dtxt_opis( "P22" ) ) // redukcija trake

   /*
   // ispis kupca na racunu
   cTmp := get_dtxt_opis( "P23" )
   IF cTmp == "D"
      lPrKupac := .T.
   ENDIF
   */

   RETURN .T.


FUNCTION isAzurDok( lRet )

   LOCAL cTemp

   cTemp := get_dtxt_opis( "D01" )
   IF cTemp == "A"
      lRet := .T.
   ELSEIF cTemp == "S"
      lRet := .T.
   ELSE
      lRet := .F.
   ENDIF

   RETURN .T.



FUNCTION isPfTraka( lRet )

   // inace iscitati parametar
   IF gPorFakt == "D"
      lRet := .T.
   ELSE
      lRet := .F.
   ENDIF

   RETURN



// ---------------------------------------
// vraca ukupan iznos racuna
// ---------------------------------------
FUNCTION get_rb_ukupno()

   LOCAL nUkupno := 0
   LOCAL nTArea := Select()

   SELECT drn
   GO TOP
   DO WHILE !Eof()
      nUkupno += field->ukupno
      SKIP
   ENDDO

   SELECT ( nTArea )

   RETURN nUkupno


FUNCTION get_rn_mjesto()

   LOCAL cMjesto := get_dtxt_opis( "R01" )

   RETURN cMjesto



FUNCTION rb_traka_line( cLine )

   cLine := Replicate( "-", LEN_RBR ) + " " + Replicate( "-", LEN_NAZIV ) + " " + Replicate( "-", LEN_UKUPNO )

   RETURN .T.





FUNCTION hd_rb_traka( nRedukcija )

   LOCAL cDuplaLin
   LOCAL cINaziv
   LOCAL cIAdresa
   LOCAL cIIdBroj
   LOCAL cIPM
   LOCAL cITelef
   LOCAL cRaz2 := Space( LEN_RAZMAK + 1 )

   cDuplaLin := Replicate( "=", LEN_TRAKA - LEN_RAZMAK - 1 )
   cINaziv := get_dtxt_opis( "I01" )
   cIAdresa := get_dtxt_opis( "I02" )
   cIIdBroj := get_dtxt_opis( "I03" )
   cIPM := AllTrim( get_dtxt_opis( "I04" ) )
   cITelef := AllTrim( get_dtxt_opis( "I05" ) )

   // stampaj header

   IF ( nRedukcija < 1 )
      ? Space( LEN_RAZMAK ) + " " + cDuplaLin
   ENDIF

   ? cRaz2 + " " + cINaziv

   IF ( nRedukcija < 1 )
      ? cRaz2 + " " + Replicate( "-", Len( cINaziv ) )
   ENDIF

   ? cRaz2 + " Adresa : " + cIAdresa
   ? cRaz2 + " ID broj: " + cIIdBroj

   IF ( nRedukcija < 1 )
      ? cRaz2 + " " + Replicate( "-", LEN_TRAKA - 11 )
   ENDIF

   IF !Empty( cIPM ) .AND. cIPM <> "-"
      IF ( nRedukcija > 0 )
         ? cRaz2 + "  PM:", cIPM
      ELSE
         ? cRaz2 + " Prodajno mjesto:"
         ? cRaz2 + " " + cIPM
      ENDIF
   ENDIF

   IF !Empty( cITelef ) .AND. cITelef <> "-"
      ? cRaz2 + " Telefon: " + cITelef
   ENDIF

   IF ( nRedukcija < 1 )
      ? Space( LEN_RAZMAK ) + " " + cDuplaLin
   ENDIF

   ?

   RETURN .T.


FUNCTION ft_rb_traka( cIdRadnik )

   LOCAL cRadnik
   LOCAL cVrstaP
   LOCAL cPomTxt1
   LOCAL cPomTxt2
   LOCAL cPomTxt3

   cRadnik := get_dtxt_opis( "R02" )
   cVrstaP := get_dtxt_opis( "R05" )
   cPomTxt1 := get_dtxt_opis( "R06" )
   cPomTxt2 := get_dtxt_opis( "R07" )
   cPomTxt3 := get_dtxt_opis( "R08" )

   // g_br_stola( @cBrStola )
   // g_vez_racuni( @aVezRacuni )

   ? Space( LEN_RAZMAK ) + " " + PadR( cRadnik, 27 )
   ?

   ? Space( LEN_RAZMAK ) + " Placanje izvrseno: " + cVrstaP

   // pomocni text na racunu
   IF !Empty( cPomTXT1 )
      ?
      ? Space( LEN_RAZMAK ) + " " + cPomTxt1
   ENDIF
   IF !Empty( cPomTxt2 )
      ? Space( LEN_RAZMAK ) + " " + cPomTxt2
   ENDIF
   IF !Empty( cPomTxt3 )
      ? Space( LEN_RAZMAK ) + " " + cPomTxt3
   ENDIF

   RETURN .T.
