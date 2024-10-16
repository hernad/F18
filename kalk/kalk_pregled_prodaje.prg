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


FUNCTION roba_pregled_prodaje_po_grupama()

   LOCAL GetList := {}

   cre_prodaja()
   o_partner()

   cPA := "N"
   dOd := CToD( "" )
   dDo := Date()
   qGrupe := qPodgrupe := qKupac := qOpstina := qKonta := Space( 80 )
   cMPVP := "S"
   cSaPSiPM := "D"

   Box( "#PREGLED PRODAJE - IZVJESTAJNI USLOVI", 10, 75 )
   DO WHILE .T.
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Grupe   " GET qGrupe    PICT "@S40!"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Podgrupe" GET qPodgrupe PICT "@S40!"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Za period od" GET dOd
      @ box_x_koord() + 4, Col() + 1 SAY "do" GET dDo
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Usporedni prikaz prethodne sedmice i 4 sedmice prije? (D/N)" GET cSaPSiPM PICT "@!" VALID cSaPSiPM $ "DN"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Kupci (prazno-svi)" GET qKupac PICT "@S40!"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Opstine prodaje (prazno-sve)" GET qOpstina PICT "@S40!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz pojedinacnih artikala (D/N)" GET cPA VALID cPA $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Izdvojiti ( M-maloprodaju / V-veleprodaju / S-sve )" GET cMPVP VALID cMPVP $ "MVS" PICT "@!"
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Konta " GET qKonta PICT "@S40!"
      READ
      ESC_BCR
      aUslG := Parsiraj( qGrupe, "cG" )
      aUslPG := Parsiraj( qPodgrupe, "cPodgrupa" )
      aUslKupac := Parsiraj( qKupac, "idpartner" )
      aUslMKonta := Parsiraj( qKonta, "mkonto" )
      aUslPKonta := Parsiraj( qKonta, "pkonto" )
      aUslOpstina := Parsiraj( qOpstina, "idops" )
      IF aUslG <> NIL .AND. aUslPG <> NIL .AND. aUslKupac <> NIL .AND. aUslOpstina <> NIL .AND. aUslMKonta <> NIL .AND. aUslPKonta <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

  // o_roba()
  // o_sifk()
  // o_sifv()

   MsgO( "Preuzimanje podataka sa SQL servera" )
   // SELECT KALK
   // SET ORDER TO TAG "7"   // idroba+idvd
   find_kalk_za_period( self_organizacija_id(), NIL, NIL, NIL, dOd, dDo, "idroba,idvd" )
   MsgC()

   MsgO( "generisanje tabele prodaje po grupama ..." )

   SELECT kalk
   DO WHILE !Eof()
      cIdRoba := idroba
      cG := cPodgrupa := ""

      select_o_roba( cIdRoba )
      info_bar( "gen", "prodaja po grupama:" + cIdRoba )

      cG := IzSifKRoba( "GR1", cIdRoba, .F. )

      // SELECT SIFV
      // HSEEK "ROBA    " + "GR1 " + PadR( cIdRoba, 15 )
      // IF Found()
      // cG  := Trim( naz )
      // ENDIF

      // HSEEK "ROBA    " + "GR2 " + PadR( cIdRoba, 15 )
      // IF Found()
      // cPodgrupa := Trim( naz )
      // ENDIF

      cPodgrupa := IzSifKRoba( "GR2", cIdRoba, .F. )

      cJMJ := ROBA->jmj
      nKJMJ := svedi_na_jedinicu_mjere( 1, cIdRoba, @cJMJ )
      SELECT KALK

      // ako roba nije obuhvacena izvjestajnim uslovima, preskoci je
      // -----------------------------------------------------------
      IF !&aUslG .OR. !&aUslPG  // .or. !(&aUslMKonta .or. &aUslPKonta)
         SEEK NovaSifra( cIdRoba )
         SKIP -1
         SKIP 1
         LOOP
      ENDIF

      // izracunaj prodanu kolicinu: nKol
      // i prodanu vrijednost: nIznos
      // ----------------------------------
      nKol := nIznos := 0
      nKolP1S := nKolP4S := 0
      DO WHILE !Eof() .AND. IDROBA == cIdRoba

         // izdvojena V
         IF cMPVP == "V" .AND. !( &aUslMKonta )
            SKIP
            LOOP
         ENDIF

         // izdvojena M
         IF cMPVP == "M" .AND. !( &aUslPKonta )
            SKIP
            LOOP
         ENDIF

         select_o_partner( kalk->idPartner )

         SELECT kalk

         IF cSaPSiPM == "D"
            IF !( DInRange( datdok, dOd, dDo ) .OR. DInRange( datdok, dOd - 7, dDo - 7 ) .OR. DInRange( datdok, dOd - 28, dDo - 28 ) ) .OR. !( &aUslKupac ) .OR. !( partn->( &aUslOpstina ) )
               SKIP 1
               LOOP
            ENDIF
         ELSE
            IF !( DInRange( datdok, dOd, dDo ) ) .OR. !( &aUslKupac ) .OR. !( partn->( &aUslOpstina ) )
               SKIP 1
               LOOP
            ENDIF
         ENDIF

         IF cMPVP $ "SM" .AND. pu_i == "5" .AND. idvd $ "41#42#43"
            // maloprodaja
            IF DInRange( datdok, dOd, dDo )
               nKol   += kolicina
               nIznos += ( kolicina * mpc )
            ELSEIF DInRange( datdok, dOd - 7, dDo - 7 )
               nKolP1S += kolicina
            ELSEIF DInRange( datdok, dOd - 28, dDo - 28 )
               nKolP4S += kolicina
            ENDIF

         ELSEIF cMPVP $ "SV" .AND. mu_i == "5" .AND. idvd $ "14#94"
            // veleprodaja
            IF DInRange( datdok, dOd, dDo )
               nKol   += kolicina
               nIznos += ( kolicina * VPC * ( 1 -RABATV / 100 ) )
            ELSEIF DInRange( datdok, dOd - 7, dDo - 7 )
               nKolP1S += kolicina
            ELSEIF DInRange( datdok, dOd - 28, dDo - 28 )
               nKolP4S += kolicina
            ENDIF
         ENDIF

         SKIP 1
      ENDDO

      IF nIznos <> 0 .OR. nKol <> 0
         SELECT PRODAJA
         APPEND BLANK
         REPLACE IDROBA WITH cIdRoba, ;
            IDG WITH cG, ;
            IDPG WITH cPodgrupa, ;
            NAZ WITH ROBA->naz, ;
            BJMJ  WITH  cJMJ, ;
            BKOLICINA  WITH  nKol * nKJMJ, ;
            BKOLP1S    WITH  nKolP1S * nKJMJ, ;
            BKOLP4S    WITH  nKolP4S * nKJMJ, ;
            JMJ        WITH  ROBA->jmj, ;
            KOLICINA   WITH  nKol, ;
            CIJENA     WITH  ROBA->vpc, ;
            IZNOS      WITH  nIznos
      ENDIF

      SELECT KALK
   ENDDO
   Msgc()

   // slijedi stampa izvjestaja na osnovu formirane baze prodaje
   // ----------------------------------------------------------
   SELECT PRODAJA
   GO TOP

   START PRINT CRET
   ?

   Preduzece( 0 )
   ?
   ? "Izvjestaj o prodaji" + IF( cMPVP == "M", " (samo u maloprodaji)", IF( cMPVP == "V", " (samo u veleprodaji)", "" ) ) + " za period od", dOd, "do", dDo
   ?
   IF !Empty( qGrupe )
      ? "Izdvojene grupe po uslovu '" + RTrim( qGrupe ) + "'"
   ENDIF
   IF !Empty( qPodgrupe )
      ? "Izdvojene podgrupe po uslovu '" + RTrim( qPodgrupe ) + "'"
   ENDIF
   IF !Empty( qKupac )
      ? "Izdvojeni kupci po uslovu '" + RTrim( qKupac ) + "'"
   ENDIF
   IF !Empty( qOpstina )
      ? "Izdvojene opstine prodaje po uslovu '" + RTrim( qOpstina ) + "'"
   ENDIF
   IF !Empty( qKonta )
      ? "Izdvojena konta prodaje po uslovu '" + RTrim( qKonta ) + "'"
   ENDIF
   ?

   gnLMarg := 0; gTabela := 1; gOstr := "N"

   cIDG  := IDG
   cIDPG := IDPG
   nKol1 := nKol1P1S := nKol1P4S := nIznos1 := 0
   nKol2 := nKol2P1S := nKol2P4S := nIznos2 := 0
   nKol9 := nKol9P1S := nKol9P4S := nIznos9 := 0
   gaSubTotal := {}
   gaDodStavke := {}
   nKol := 0
   aKol := {}

   // duzina i broj decimala
   PRIVATE nLen := 0
   PRIVATE nDec := 0
   GetPictDem( @nLen, @nDec )

   lPA := ( cPA == "D" )

   IF lPA
      AAdd( aKol, { "Artikal", {|| NAZ       }, .F., "C", 40, 0, 1, ++nKol } )
   ELSE
      AAdd( aKol, { "GRUPA/PODGRUPA", {|| ""        }, .F., "C", 65, 0, 1, ++nKol } )
   ENDIF
   AAdd( aKol, { "Kolicina", {|| BKOLICINA }, lPA, "N", nLen, nDec, 1, ++nKol } )

   IF cSaPSiPM == "D"
      AAdd( aKol, { "Kolicina", {|| BKOLP1S }, lPA, "N", 13, 3, 1, ++nKol } )
      AAdd( aKol, { "prije 7 dana", {|| "#"     }, .F., "C", 13, 0, 2,   nKol } )
      AAdd( aKol, { "Omjer kolic.", {|| SDiv( BKOLP1S, BKOLICINA ) }, .F., "N", 13, 3, 1, ++nKol } )
      AAdd( aKol, { "sada/pr.7d", {|| "#"     }, .F., "C", 13, 0, 2,   nKol } )
      AAdd( aKol, { "Kolicina", {|| BKOLP4S }, lPA, "N", 13, 3, 1, ++nKol } )
      AAdd( aKol, { "prije 28 dana", {|| "#"     }, .F., "C", 13, 0, 2,   nKol } )
      AAdd( aKol, { "Omjer kolic.", {|| SDiv( BKOLP4S, BKOLICINA ) }, .F., "N", 13, 3, 1, ++nKol } )
      AAdd( aKol, { "sada/pr.28d", {|| "#"     }, .F., "C", 13, 0, 2,   nKol } )
   ENDIF
   AAdd( aKol, { "BJMJ", {|| BJMJ      }, .F., "C", 10, 0, 1, ++nKol } )

   IF lPA .AND. cSaPSiPM <> "D"
      AAdd( aKol, { "Cijena bez", {|| CIJENA    }, .F., "N", 13, 3, 1, ++nKol } )
      AAdd( aKol, { "poreza", {|| "#"       }, .F., "C", 13, 0, 2,   nKol } )
      AAdd( aKol, { "JMJ", {|| JMJ       }, .F., "C", 10, 0, 1, ++nKol } )
   ENDIF

   IF cSaPSiPM <> "D"
      AAdd( aKol, { "Vrijednost", {|| IZNOS     }, lPA, "N", 13, 3, 1, ++nKol } )
   ENDIF

   aGr := {}
   print_lista_2( aKol,,, gTabela,,,, IF( lPA, {|| ForPPr() }, {|| ForPPr2() } ), ;
      IF( gOstr == "D",, -1 ),,,,,, .F. )

   ?
   IF PRow() > ( RPT_PAGE_LEN + dodatni_redovi_po_stranici() - Len( aGr ) )
      FF
   ENDIF
   ? "Rekapitulacija po grupama:"
   IF cSaPSiPM == "D"
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      ? PadC( "GRUPA", 40 ) + " " + PadC( "KOLICINA", 13 ) + " " + PadC( "KOLIC.PR.7d", 13 ) + " " + PadC( "OMJER SADA/7d", 13 ) + " " + PadC( "KOLIC.PR.28d", 13 ) + " " + PadC( "OMJ. SADA/28d", 13 ) + " " + PadC( "BJMJ", 10 ) + " " + PadC( "VRIJEDNOST", 13 )
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      nIznos := nKol := nKolP1S := nKolP4S := 0
      FOR i := 1 TO Len( aGr )
         ? PadR( aGr[ i, 1 ], 40 ) + " "
         ?? Str( aGr[ i, 2 ], 13, 3 ) + " "
         ?? Str( aGr[ i, 3 ], 13, 3 ) + " "
         ?? Str( SDiv( aGr[ i, 3 ], aGr[ i, 2 ] ), 13, 3 ) + " "
         ?? Str( aGr[ i, 4 ], 13, 3 ) + " "
         ?? Str( SDiv( aGr[ i, 4 ], aGr[ i, 2 ] ), 13, 3 ) + " "
         ?? PadR( aGr[ i, 5 ], 10 ) + " "
         ?? Str( aGr[ i, 6 ], 13, 3 )
         nKol += aGr[ i, 2 ]
         nKolP1S += aGr[ i, 3 ]
         nKolP4S += aGr[ i, 4 ]
         nIznos += aGr[ i, 6 ]
      NEXT
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      ? PadR( "UKUPNO", 40 ) + " " + Str( nKol, 13, 3 ) + " " + Str( nKolP1S, 13, 3 ) + " " + Str( SDiv( nKolP1S, nKol ), 13, 3 ) + " " + Str( nKolP4S, 13, 3 ) + " " + Str( SDiv( nKolP4S, nKol ), 13, 3 ) + " " + Space( 10 ) + " " + Str( nIznos, 13, 3 )
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
   ELSE
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      ? PadC( "GRUPA", 40 ) + " " + PadC( "KOLICINA", 13 ) + " " + PadC( "BJMJ", 10 ) + " " + PadC( "VRIJEDNOST", 13 )
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      nIznos := nKol := 0
      FOR i := 1 TO Len( aGr )
         ? PadR( aGr[ i, 1 ], 40 ), ;
            TRANS( aGr[ i, 2 ], kalk_pic_iznos_bilo_gpicdem() ), ;
            PadR( aGr[ i, 3 ], 10 ), ;
            TRANS( aGr[ i, 4 ], kalk_pic_iznos_bilo_gpicdem() )
         nKol += aGr[ i, 2 ]
         nIznos += aGr[ i, 4 ]
      NEXT
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
      ? PadR( "UKUPNO", 40 ) + " " + Str( nKol, 13, 3 ) + " " + Space( 10 ) + " " + Str( nIznos, 13, 3 )
      ? REPL( "-", 40 ) + " " + REPL( "-", 13 ) + " " + REPL( "-", 10 ) + " " + REPL( "-", 13 )
   ENDIF

   FF
   ENDPRINT
   CLOSERET

   RETURN .T.




// -------------------------------------------------------------
// kreiranje i otvaranje pomocne baze POM.DBF za pregled prodaje
// -------------------------------------------------------------
STATIC FUNCTION cre_prodaja()

   LOCAL cImeDbf
   LOCAL cAlias := "PRODAJA"

   cImeDBf := f18_ime_dbf( "prodaja" )

   FErase( cImeDbf )
   FErase( ImeDbfCdx( cImeDbf ) )


   aDbf := {}
   AAdd( aDBf, { 'IDROBA', 'C', 10,  0 } )
   AAdd( aDBf, { 'IDG', 'C', 10,  0 } )
   AAdd( aDBf, { 'IDPG', 'C', 10,  0 } )
   AAdd( aDBf, { 'NAZ', 'C', 250,  0 } )
   AAdd( aDBf, { 'BJMJ', 'C', 10,  0 } )
   AAdd( aDBf, { 'BKOLICINA', 'N', 18,  8 } )
   AAdd( aDBf, { 'BKOLP4S', 'N', 18,  8 } )
   AAdd( aDBf, { 'BKOLP1S', 'N', 18,  8 } )
   AAdd( aDBf, { 'JMJ', 'C',  4,  0 } )
   AAdd( aDBf, { 'KOLICINA', 'N', 18,  8 } )
   AAdd( aDBf, { 'CIJENA', 'N', 10,  4 } )
   AAdd( aDBf, { 'IZNOS', 'N', 18,  8 } )
   DBCREATE2 ( cImeDbf, aDbf )


   CREATE_INDEX( "1", "IDG + IDPG + IDROBA", cAlias )
   CREATE_INDEX( "2", "IDG + IDPG + Left( NAZ, 40 )", cAlias )


   USEX( cAlias )
   SET ORDER TO TAG "1"
   GO TOP

   RETURN .T.



// sa artiklima
// ------------
FUNCTION ForPPr()

   // {
   LOCAL lVrati := .T.
   gaSubTotal  := {}
   gaDodStavke := {}
   cIDG  := IDG
   cIDPG := IDPG
   cST1  := OpisSubGr( cIdG )
   cST2  := OpisSubPG( cIdG, cIdPG )
   nKol1 += bkolicina; nIznos1 += iznos
   nKol2 += bkolicina; nIznos2 += iznos
   nKol1P1S += bkolp1s
   nKol2P1S += bkolp1s
   nKol1P4S += bkolp4s
   nKol2P4S += bkolp4s
   cBJMJ := BJMJ
   SKIP 1
   IF cIDG <> IDG .OR. Eof()
      // stampaj subtot.podgrupa
      // stampaj subtot.grupa
      IF cSaPSiPM == "D"
         gaSubTotal := { {, nKol2, nKol2P1S, SDiv( nKol2P1S, nKol2 ), nKol2P4S, SDiv( nKol2P4S, nKol2 ), cBJMJ,,, nIznos2, cST2 }, ;
            {, nKol1, nKol1P1S, SDiv( nKol1P1S, nKol1 ), nKol1P4S, SDiv( nKol1P4S, nKol1 ), cBJMJ,,, nIznos1, cST1 } }
         AAdd( aGr, { cST1, nKol1, nKol1P1S, nKol1P4S, cBJMJ, nIznos1 } )
      ELSE
         gaSubTotal := { {, nKol2, cBJMJ,,, nIznos2, cST2 }, ;
            {, nKol1, cBJMJ,,, nIznos1, cST1 } }
         AAdd( aGr, { cST1, nKol1, cBJMJ, nIznos1 } )
      ENDIF
      nKol1 := nIznos1 := 0
      nKol2 := nIznos2 := 0
      nKol1P1S := nKol2P1S := 0
      nKol1P4S := nKol2P4S := 0
   ELSEIF cIDPG <> IDPG
      // stampaj subtot.podgrupa
      IF cSaPSiPM == "D"
         gaSubTotal := { {, nKol2, nKol2P1S, SDiv( nKol2P1S, nKol2 ), nKol2P4S, SDiv( nKol2P4S, nKol2 ), cBJMJ,,, nIznos2, cST2 } }
      ELSE
         gaSubTotal := { {, nKol2, cBJMJ,,, nIznos2, cST2 } }
      ENDIF
      nKol2 := nIznos2 := 0
      nKol2P1S := nKol2P4S := 0
   ELSE
      gaSubTotal := {}
   ENDIF
   SKIP -1

   RETURN lVrati
// }


// bez artikala
// ------------
FUNCTION ForPPr2()

   // {
   LOCAL lVrati := .T.
   gaSubTotal  := {}
   gaDodStavke := {}
   cIDG  := IDG
   cIDPG := IDPG
   cST1  := OpisSubGr( cIdG )
   cST2  := OpisSubPG( cIdG, cIdPG )
   cST9  := "S V E    U K U P N O"
   nKol1 += bkolicina; nIznos1 += iznos
   nKol2 += bkolicina; nIznos2 += iznos
   nKol9 += bkolicina; nIznos9 += iznos
   nKol1P1S += bkolp1s
   nKol2P1S += bkolp1s
   nKol9P1S += bkolp1s
   nKol1P4S += bkolp4s
   nKol2P4S += bkolp4s
   nKol9P4S += bkolp4s
   cBJMJ := BJMJ
   SKIP 1
   IF cIDG <> IDG .OR. Eof()
      // stampaj subtot.podgrupa
      // stampaj subtot.grupa
      IF cSaPSiPM == "D"
         gaSubTotal := { {, nKol2, nKol2P1S, SDiv( nKol2P1S, nKol2 ), nKol2P4S, SDiv( nKol2P4S, nKol2 ), cBJMJ, nIznos2, cST2 }, ;
            {, nKol1, nKol1P1S, SDiv( nKol1P1S, nKol1 ), nKol1P4S, SDiv( nKol1P4S, nKol1 ), cBJMJ, nIznos1, cST1 } }
         AAdd( aGr, { cST1, nKol1, nKol1P1S, nKol1P4S, cBJMJ, nIznos1 } )
      ELSE
         gaSubTotal := { {, nKol2, cBJMJ, nIznos2, cST2 }, ;
            {, nKol1, cBJMJ, nIznos1, cST1 } }
         AAdd( aGr, { cST1, nKol1, cBJMJ, nIznos1 } )
      ENDIF
      nKol1 := nIznos1 := 0
      nKol2 := nIznos2 := 0
      nKol1P1S := nKol2P1S := 0
      nKol1P4S := nKol2P4S := 0
      // stampaj sve ukupno
      IF Eof()
         IF cSaPSiPM == "D"
            AAdd( gaSubTotal, {, nKol9, nKol9P1S, SDiv( nKol9P1S, nKol9 ), nKol9P4S, SDiv( nKol9P4S, nKol9 ), cBJMJ, nIznos9, cST9 } )
         ELSE
            AAdd( gaSubTotal, {, nKol9, cBJMJ, nIznos9, cST9 } )
         ENDIF
      ENDIF
   ELSEIF cIDPG <> IDPG
      // stampaj subtot.podgrupa
      IF cSaPSiPM == "D"
         gaSubTotal := { {, nKol2, nKol2P1S, SDiv( nKol2P1S, nKol2 ), nKol2P4S, SDiv( nKol2P4S, nKol2 ), cBJMJ, nIznos2, cST2 } }
      ELSE
         gaSubTotal := { {, nKol2, cBJMJ, nIznos2, cST2 } }
      ENDIF
      nKol2 := nIznos2 := 0
      nKol2P1S := 0
      nKol2P4S := 0
   ELSE
      gaSubTotal := {}
   ENDIF
   SKIP -1

   RETURN .F.
// }

STATIC FUNCTION OpisSubGr( cId )

   // {
   LOCAL cVrati
   cVrati := "UKUPNO GRUPA '" + cId + "-" + my_get_from_ini( "VINDIJA", "NazGr" + cId, "", KUMPATH ) + "'"

   RETURN cVrati
// }

STATIC FUNCTION OpisSubPG( cIdG, cIdPG )

   // {
   LOCAL cVrati
   cVrati := "PODGRUPA '" + cIdPG + "-" + my_get_from_ini( "VINDIJA", "NazPG" + cIdG + cIdPG, "", KUMPATH ) + "'"

   RETURN cVrati
// }


FUNCTION SDiv( nDjelilac, nDijeljenik )

   // {
   LOCAL nV
   IF nDjelilac <> 0
      nV := nDijeljenik / nDjelilac
   ELSE
      nV := 0
   ENDIF

   RETURN nV



/* GetPictDem(nLen, nDec)
 *     Vraca velicinu i broj decimala num polja
 *   param: nLen
 *   param: nDec
 */
FUNCTION GetPictDem( nLen, nDec )

   // ovo odmah znamo = duzina
   nLen := Len( kalk_pic_iznos_bilo_gpicdem() )

   // sracunaj broj decimala
   nAt := At( ".", kalk_pic_iznos_bilo_gpicdem() )
   nPom := SubStr( kalk_pic_iznos_bilo_gpicdem(), ( nAt + 1 ), ( nLen - nAt ) )

   nDec := Len( nPom )

   RETURN .T.
