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

STATIC LEN_KOLICINA := 9
STATIC LEN_CIJENA := 12
STATIC LEN_VRIJEDNOST := 14

STATIC DEC_KOLICINA := 2
STATIC DEC_CIJENA := 2
STATIC DEC_VRIJEDNOST := 2


FUNCTION pf_traka_print()

   close_open_racun_tbl()
   st_pf_traka()

   RETURN .T.


FUNCTION pos_porezna_faktura_traka( lSilent )

   Alert( "POS porezna faktura ne radi" )
/*
   LOCAL lPfTraka

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   isPfTraka( @lPfTraka )

   IF !lSilent .AND. Pitanje(, "Štampati poreznu fakturu za zadnji račun (D/N)?", "D" ) == "N"
      RETURN .F.
   ENDIF

   close_open_racun_tbl()

   IF !lPfTraka
      IF !get_kup_data()
         RETURN .F.
      ENDIF
   ENDIF

   st_pf_traka()

   IF !lPfTraka
  --    porezna_faktura_azur_podataka_o_kupcu( gPosProdajnoMjesto )
   ENDIF
*/

   RETURN .T.


FUNCTION read_kup_data()

   LOCAL cKNaziv

   cKNaziv := get_dtxt_opis( "K01" )
   IF cKNaziv == "-"
      RETURN .F.
   ENDIF

   RETURN .T.

/*
pos

FUNCTION get_kup_data()

   LOCAL cKNaziv := Space( 35 )
   LOCAL cKAdres := Space( 35 )
   LOCAL cKIdBroj := Space( 13 )
   LOCAL cUnosOk := "D"
   LOCAL dDatIsp := Date()
   LOCAL GetList := {}
   LOCAL nMX
   LOCAL nMY

   SET CURSOR ON
   IF read_kup_data()
      cKNaziv := PadR( get_dtxt_opis( "K01" ), 35 )
      cKAdres := PadR( get_dtxt_opis( "K02" ), 35 )
      cKIdBroj := PadR( get_dtxt_opis( "K03" ), 13 )
      dDatIsp := get_drn_datum_isporuke()
      IF dDatIsp == nil
         dDatIsp := CToD( "" )
      ENDIF
   ENDIF

   Box(, 7, 65 )

   nMX := box_x_koord()
   nMY := box_y_koord()

   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Podaci o kupcu:" COLOR f18_color_i()
   @ 2 + box_x_koord(), 2 + box_y_koord() SAY8 "Naziv (pravnog ili fizičkog lica):" GET cKNaziv VALID !Empty( cKNaziv ) .AND. get_arr_kup_data( @cKNaziv, @cKAdres, @cKIdBroj ) PICT "@S20"
   READ

   box_x_koord( nMX )
   box_y_koord( nMY )

   @ 3 + box_x_koord(), 2 + box_y_koord() SAY "Adresa:" GET cKAdres VALID !Empty( cKAdres )
   @ 4 + box_x_koord(), 2 + box_y_koord() SAY "Identifikacijski broj:" GET cKIdBroj VALID !Empty( cKIdBroj )
   @ 5 + box_x_koord(), 2 + box_y_koord() SAY "Datum isporuke " GET dDatIsp

   @ 7 + box_x_koord(), 2 + box_y_koord() SAY "Unos podataka ispravan (D/N)?" GET cUnosOk VALID cUnosOk $ "DN" PICT "@!"
   READ

   BoxC()

   IF ( cUnosOk <> "D" ) .OR. ( LastKey() == K_ESC )
      RETURN .F.
   ENDIF

   // dodaj parametre u drntext
   add_drntext( "K01", cKNaziv )
   add_drntext( "K02", cKAdres )
   add_drntext( "K03", cKIdBroj )
   add_drn_datum_isporuke( dDatIsp )

   RETURN .T.
*/

FUNCTION pf_traka_line( nRazmak )

   LOCAL cPom

   cPom := Space( nRazmak )
   cPom += Replicate( "-", LEN_KOLICINA ) + " "
   cPom += Replicate( "-", LEN_CIJENA ) + " "
   cPom += Replicate( "-", LEN_VRIJEDNOST )

   RETURN cPom

FUNCTION st_pf_traka()

   LOCAL cBrDok
   LOCAL dDatDok
   LOCAL aRNaz
   LOCAL cArtikal
   LOCAL cRazmak := Space( 1 )
   LOCAL cLine
   LOCAL lViseRacuna := .F.
   LOCAL nPFeed
   LOCAL cSjeTraSkv
   LOCAL cOtvLadSkv
   LOCAL nLeft1 := 22
   LOCAL nRedukcija
   LOCAL nSetCijene
   LOCAL lStRobaId

   STARTPRINTPORT CRET "LPT1", Space( 5 )

   cLine := pf_traka_line( 1 )

   pos_get_racun_broj_varijable( @nPFeed, @cOtvLadSkv, @cSjeTraSkv, @nSetCijene, @lStRobaId, @nRedukcija )

   hd_rb_traka( nRedukcija )

   kup_rb_traka()

   SELECT drn
   GO TOP
   // ako postoji vise zapisa onda ima vise racuna
   IF RecCount2() > 1
      lViseRacuna := .T.
   ENDIF

   SELECT rn
   SET ORDER TO TAG "1"
   GO TOP

   // mjesto i datum racuna
   ? cRazmak + drn->vrijeme + PadL( get_rn_mjesto() + "," + DToC( drn->datdok ), 32 )
   ? cRazmak + "Datum isporuke: " + DToC( drn->datisp )

   ? cLine

   // broj racuna
   ? Space( 12 ) + "FAKTURA br." + AllTrim( drn->brdok )

   ? cLine

   // opis kolona
   ? " R.br   Roba (sif - naziv, jmj)"
   ? cLine
   ? cRazmak + PadC( "kolicina", LEN_KOLICINA )  + " " + PadC( "C.bez PDV", LEN_CIJENA ) + PadC( " Uk b.PDV  ", LEN_VRIJEDNOST )
   IF Round( drn->ukpopust, 3 ) <> 0
      ? cRazmak + PadC( "-popust", LEN_KOLICINA ) + PadC( "C.2.bez PDV", LEN_CIJENA )
   ENDIF
   ? cLine

   SELECT rn

   // data
   DO WHILE !Eof()

      // rbr
      ? cRazmak + rn->rbr

      // artikal
      cArtikal := AllTrim( field->idroba ) + " - " + AllTrim( field->robanaz ) +  " (" + AllTrim( rn->jmj ) + ")"
      aRNaz := SjeciStr( cArtikal, 34 )
      FOR i := 1 TO Len( aRNaz )
         IF i == 1
            ?? cRazmak + aRNaz[ i ]
         ELSE
            ? Space( 5 ) + aRNaz[ i ]
         ENDIF
      NEXT

      // kolicina, jmj, cjena sa pdv
      ? cRazmak + Str( rn->kolicina, LEN_KOLICINA, DEC_KOLICINA ), Str( rn->cjenbpdv, LEN_CIJENA, DEC_CIJENA )


      // ukupna vrijednost bez pdv-a je uvijek bez popusta iskazana
      // jer se popust na dnu iskazuje
      ?? " "
      nPom := rn->cjenbpdv * rn->kolicina
      ?? Str( nPom,  LEN_VRIJEDNOST, DEC_VRIJEDNOST )

      // da li postoji popust
      IF Round( rn->cjen2pdv, 3 ) <> 0
         ? cRazmak
         ?? PadL( "-" + Str( rn->popust, 3 ) + "%", LEN_KOLICINA )
         ?? " "
         ?? Str( rn->cjen2bpdv, LEN_CIJENA, DEC_CIJENA )

      ENDIF


      SKIP
   ENDDO

   ? cLine

   ? cRazmak + PadL( "Ukupno bez PDV (KM):", nLeft1 ), Str( drn->ukbezpdv, LEN_VRIJEDNOST, DEC_VRIJEDNOST )
   // dodaj i popust
   IF Round( drn->ukpopust, 2 ) <> 0
      ? cRazmak + PadL( "Popust (KM):", nLeft1 ), Str( drn->ukpopust, LEN_VRIJEDNOST, DEC_VRIJEDNOST )
      ? cRazmak + PadL( "Uk.bez.PDV-popust (KM):", nLeft1 ), Str( drn->ukbpdvpop, LEN_VRIJEDNOST, DEC_VRIJEDNOST )
   ENDIF
   ? cRazmak + PadL( "PDV 17% :", nLeft1 ), Str( drn->ukpdv, LEN_VRIJEDNOST, DEC_VRIJEDNOST )

   IF Round( drn->zaokr, 2 ) <> 0
      ? cRazmak + PadL( "zaokruzenje (+/-):", nLeft1 ), Str( Abs( drn->zaokr ), LEN_VRIJEDNOST, DEC_VRIJEDNOST )
   ENDIF

   ? cLine
   ? cRazmak + PadL( "UKUPNO ZA NAPLATU (KM):", nLeft1 ), PadL( Transform( drn->ukupno, "******9." + Replicate( "9", DEC_VRIJEDNOST ) ), LEN_VRIJEDNOST )
   ? cLine

   ft_rb_traka()

   ?
   ? Space( 3 ) + "Fakturisao: ______________________"
   ?

   FOR i := 1 TO nPFeed
      ?
   NEXT

   sjeci_traku( cSjeTraSkv )

   ENDPRN2 13

   RETURN .T.



FUNCTION kup_rb_traka()

   LOCAL cKNaziv
   LOCAL cKAdres
   LOCAL cKIdBroj
   LOCAL cRazmak := Space( 2 )
   LOCAL cDokVeza := ""
   LOCAL i

   cKNaziv := get_dtxt_opis( "K01" )
   cKAdres := get_dtxt_opis( "K02" )
   cKIdBroj := get_dtxt_opis( "K03" )
   cDokVeza := get_dtxt_opis( "D11" )

   ? cRazmak + "Kupac:"
   ? cRazmak + cKNaziv
   ? cRazmak + cKAdres
   ? cRazmak + "Ident.br:" + cRazmak + cKIdBroj

   IF !Empty( cDokVeza ) .AND. AllTrim( cDokVeza ) <> "-"

      cDokVeza := "veza: " + AllTrim( cDokVeza )

      aTmp := SjeciStr( cDokVeza, 34 )

      FOR i := 1 TO Len( aTmp )
         ? cRazmak + aTmp[ i ]
      NEXT

   ENDIF

   ?

   RETURN .T.


/*

// vraca matricu sa dostupnim kupcima koji pocinju sa cKupac
FUNCTION get_arr_kup_data( cKupac, cKAdr, cKIdBroj )

   LOCAL aKupci := {}
   LOCAL nKupIzbor

   IF Right( AllTrim( cKupac ), 2 ) <> ".."
      RETURN .T.
   ENDIF

   aKupci := pos_find_kupac_podaci( cKupac )

   IF Len( aKupci ) > 0

      nKupIzbor := list_kup_data( aKupci )

      // odabrano je ESC
      IF nKupIzbor == nil
         RETURN .F.
      ENDIF

      cKupac := aKupci[ nKupIzbor, 1 ]
      cKAdr := aKupci[ nKupIzbor, 2 ]
      cKIdBroj := aKupci[ nKupIzbor, 3 ]

      RETURN .T.
   ELSE
      MsgBeep( "Trazeni pojam ne postoji u tabeli kupaca !" )
   ENDIF

   RETURN .F.


FUNCTION list_kup_data( aKupci )

   LOCAL nIzbor
   LOCAL cPom

   PRIVATE Izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   FOR i := 1 TO Len( aKupci )
      cPom := Str( i, 2 ) + ". " + Trim( aKupci[ i, 1 ] ) + " - " + Trim( aKupci[ i, 2 ] )
      cPom := PadR( cPom, 50 )
      AAdd( opc, cPom )
      AAdd( opcexe, {|| nIzbor := Izbor, Izbor := 0 } )
   NEXT

   Izbor := 1
   f18_menu_sa_priv_vars_opc_opcexe_izbor( "kup" )

   RETURN nIzbor

*/
