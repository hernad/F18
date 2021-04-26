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


THREAD STATIC DUZ_STRANA := 70
THREAD STATIC s_cRadniSatiDN := "N"

MEMVAR cLDLijevaMargina

FUNCTION ld_kartica_redovan_rad( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, aNeta, cKarticaSifreTO, lKarticaTO )

   LOCAL nKRedova
   LOCAL cDoprSpace := Space( 3 )
   LOCAL cTprLine
   LOCAL cDoprLine
   LOCAL cMainLine
   LOCAL cRadniSatiDN := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL aBeneficirani := {}
   LOCAL lFoundTippr
   LOCAL nI
   PRIVATE cPom

   PRIVATE cLDLijevaMargina := ""

   s_cRadniSatiDN := cRadniSatiDN

   cTprLine := _gtprline()
   cDoprLine := _gdoprline( cDoprSpace )
   cMainLine := _gmainline()

   nKRedova := ld_kartica_redova()

   Eval( bZagl )

   IF gTipObr == "2" .AND. parobr->k1 <> 0
      ?? _l( "        Bod-sat:" )
      @ PRow(), PCol() + 1 SAY parobr->vrbod / parobr->k1 * brbod PICT "99999.99999"
   ENDIF

   cUneto := "D"
   nRRsati := 0
   nOsnNeto := 0
   nOsnOstalo := 0
   nOstalaPrimanjaPlus := 0
   nOstalaPrimanjaNegativno := 0
   // nLicniOdbitak := g_licni_odb( radn->id )
   nLicniOdbitak := ld->ulicodb
   nKoefOdbitka := get_koeficijent_licnog_odbitka( nLicniOdbitak )
   cRTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

   ? cTprLine
   IF gPrBruto == "X"
      ? cLDLijevaMargina + " Vrsta                  Opis         sati/iznos            ukupno bruto"
   ELSE
      ? cLDLijevaMargina + " Vrsta                  Opis         sati/iznos             ukupno"
   ENDIF

   ? cTprLine

   FOR nI := 1 TO cLDPolja
      cPom := PadL( AllTrim( Str( nI ) ), 2, "0" )
     
      // razdvojiti karticu na dva dijela - 1) bez TO, 2) samo TO
      IF !Empty(cKarticaSifreTO)
         IF lKarticaTO
            // 2) kartica samo prikaz TO
            IF !(cPom $ TRIM(cKarticaSifreTO))
               LOOP
            ENDIF
         ELSE
            // 1) kartica prikaz stavki bez TO
            IF (cPom $ TRIM(cKarticaSifreTO))
               LOOP
            ENDIF
         ENDIF
      ENDIF
    
      select_o_tippr( cPom )
      lFoundTippr := Found()

      IF tippr->uneto == "N" .AND. cUneto == "D"
         IF Empty(cKarticaSifreTO) 
            cUneto := "N"
            ? cTprLine
            // prikaz ukupno neto
            ? cLDLijevaMargina + "Ukupno:"

            @ PRow(), nC1 + 8  SAY  _USati  PICT gpics
            ?? Space( 1 ) + "sati"
            nPom := _calc_tpr( _UNeto, .T. )
            @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPom PICT gpici
            ?? "", gValuta
            ? cTprLine
         ELSE
            ? cTprLine
         ENDIF

      ENDIF


      IF lFoundTipPr .AND. tippr->aktivan == "D"

         IF _I&cPom <> 0 .OR. _S&cPom <> 0

            nDJ := At( "#", tippr->naz )
            cDJ := Right( AllTrim( tippr->naz ), nDJ + 1 )
            cTPNaz := tippr->naz

            ? cLDLijevaMargina + tippr->id + "-" + ;
               PadR( cTPNAZ, Len( tippr->naz ) ), sh_tp_opis( tippr->id, radn->id )
            nC1 := PCol()

            IF tippr->fiksan $ "DN"

               @ PRow(), PCol() + 8 SAY _S&cPom PICT gpics
               ?? " s"

               nPom := _calc_tpr( _I&cPom )
               @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPom PICT gpici

               IF tippr->id == "01" .AND. s_cRadniSatiDN == "D"
                  nRRSati := _S&cPom
               ENDIF

            ELSEIF tippr->fiksan == "P"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), PCol() + 8 SAY _S&cPom  PICT "999.99%"
               @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPom  PICT gpici

            ELSEIF tippr->fiksan == "B"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), PCol() + 8 SAY _S&cPom  PICT "999999"; ?? " b"
               @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPom PICT gpici

            ELSEIF tippr->fiksan == "C"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPom PICT gpici
            ENDIF

            IF "_K" == Right( AllTrim( tippr->opis ), 2 )

               nKumPrim := ld_kumulativna_primanja( _IdRadn, cPom )

               IF SubStr( AllTrim( tippr->opis ), 2, 1 ) == "1"
                  nKumPrim := nKumPrim + radn->n1
               ELSEIF SubStr( AllTrim( tippr->opis ), 2, 1 ) == "2"
                  nKumPrim := nKumPrim + radn->n2
               ELSEIF SubStr( AllTrim( tippr->opis ), 2, 1 ) == "3"
                  nKumPrim := nKumPrim + radn->n3
               ENDIF

               IF tippr->uneto == "N"
                  nKumPrim := Abs( nKumPrim )
               ENDIF

               ? cLPom := cLDLijevaMargina + "   ----------------------------- ----------------------------"
               ?U cLDLijevaMargina + "    SUMA IZ PRETHODNIH OBRAČUNA   UKUPNO (SA OVIM OBRAČUNOM)"
               ? cLPom
               ? cLDLijevaMargina + "   " + PadC( Str( nKumPrim - Abs( _I&cPom ) ), 29 ) + " " + PadC( Str( nKumPrim ), 28 )
               ? cLPom
            ENDIF

            IF tippr->( FieldPos( "TPR_TIP" ) ) <> 0
               // uzmi osnovice
               IF tippr->tpr_tip == "N"
                  nOsnNeto += _I&cPom
               ELSEIF tippr->tpr_tip == "2"
                  nOsnOstalo += _I&cPom
                  IF _I&cPom > 0
                     nOstalaPrimanjaPlus += _I&cPom
                  ELSE
                     nOstalaPrimanjaNegativno += _I&cPom
                  ENDIF
               ELSEIF tippr->tpr_tip == " "
                  // standardni tekuci sistem
                  IF tippr->uneto == "D"
                     nOsnNeto += _I&cPom
                  ELSE
                     nOsnOstalo += _I&cPom
                     IF _I&cPom > 0
                        nOstalaPrimanjaPlus += _I&cPom
                     ELSE
                        nOstalaPrimanjaNegativno += _I&cPom
                     ENDIF

                  ENDIF

               ENDIF

            ELSE
               // standardni tekuci sistem
               IF tippr->uneto == "D"
                  nOsnNeto += _I&cPom
               ELSE
                  nOsnOstalo += _I&cPom
                  IF _I&cPom > 0
                     nOstalaPrimanjaPlus += _I&cPom
                  ELSE
                     nOstalaPrimanjaNegativno += _I&cPom
                  ENDIF
               ENDIF
            ENDIF


            IF "SUMKREDITA" $ tippr->formula .AND. gReKrKP == "1"

               P_COND
               ? cTprLine
               ?U cLDLijevaMargina + "  ", "Od toga pojedinačni krediti:"

               seek_radkr( _godina, _mjesec, _idradn )
               DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn
                  select_o_kred( radkr->idkred )
                  SELECT radkr
                  ? cLDLijevaMargina + "  ", idkred, Left( kred->naz, 22 ), naosnovu
                  @ PRow(), 58 + Len( cLDLijevaMargina ) SAY iznos PICT "(" + gpici + ")"

                  SELECT radkr
                  SKIP
               ENDDO

               ? cTprLine
               P_12CPI
               SELECT ld

            ELSEIF "SUMKREDITA" $ tippr->formula

               seek_radkr( _godina, _mjesec, _idradn)
               ukredita := 0

               P_COND

               ? m2 := cLDLijevaMargina + "   ------------------------------------------------  --------- --------- -------"
               ? cLDLijevaMargina + "        Kreditor      /              na osnovu         Ukupno    Ostalo   Rata"
               ? m2

               DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn

                  select_o_kred( radkr->idkred )
                  SELECT radkr
                  aIznosi := ld_iznosi_za_kredit( idradn, idkred, naosnovu, _mjesec, _godina )
                  ? cLDLijevaMargina + " ", idkred, Left( kred->naz, 22 ), PadR( naosnovu, 20 )
                  @ PRow(), PCol() + 1 SAY aIznosi[ 1 ] PICT "999999.99" // ukupno
                  @ PRow(), PCol() + 1 SAY aIznosi[ 1 ] - aIznosi[ 2 ] PICT "999999.99"// ukupno-placeno
                  @ PRow(), PCol() + 1 SAY iznos PICT "9999.99"

                  ukredita += iznos

                  SELECT RADKR
                  SKIP
               ENDDO

               P_12CPI

               IF !lSkrivena .AND. PRow() > 55 + dodatni_redovi_po_stranici()
                  FF
               ENDIF

               SELECT ld
            ENDIF
         ENDIF
      ENDIF
   NEXT

   IF cVarijanta == "5"
      //SELECT ld
      PushWA()
      //SET ORDER TO TAG "2"
      seek_ld_2( _idrj, _godina, _mjesec, "1", _idradn)

      ?
      ? cLDLijevaMargina + "Od toga 1. dio:"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY UIznos PICT gpici
      ? cTprLine

      seek_ld_2( _idrj, _godina, _mjesec, "2", _idradn)

      ? cLDLijevaMargina + "Od toga 2. dio:"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY UIznos PICT gpici
      ? cTprLine
      SELECT ld
      PopWA()
   ENDIF

   IF s_cRadniSatiDN == "D"
      ? "NAPOMENA: Ostaje da se plati iz preraspodjele radnog vremena "
      ?? AllTrim( Str( ( ld->radsat ) - nRRSati ) )  + _l( " sati." )
      ?U "          Ostatak predhodnih obračuna: " + GetStatusRSati( ld->idradn ) + Space( 1 ) + _l( "sati" )
      ?
   ENDIF

   IF gSihtarica == "D"
      nTmp := get_siht( .T., nGodina, nMjesec, ld->idradn, "" )
      IF ld->usati < nTmp
         ?U "Greška: sati po šihtarici većnI od uk.sati plaće !"
      ENDIF
   ENDIF

   IF gPrBruto $ "D#X"

      select_o_por()
      select_o_dopr()

      SELECT ( F_KBENEF )
      IF !Used()
         o_koef_beneficiranog_radnog_staza()
      ENDIF

      nBFO := 0

      nOsnZaBr := nOsnNeto

      nBrutoOsnova := ld_get_bruto_osnova( nOsnZaBr, cRTipRada, nLicniOdbitak )
      IF is_radn_k4_bf_ide_u_benef_osnovu()
         nTmp2 := nOsnZaBr - IF( !Empty( gBFForm ),  &( gBFForm ), 0 )
         nBFo := ld_get_bruto_osnova( nTmp2, cRTipRada, nLicniOdbitak )
         add_to_a_benef( @aBeneficirani, AllTrim( radn->k3 ), ld_beneficirani_stepen(), nBFO )
      ENDIF

      nBoMin := nBrutoOsnova
      IF cRTipRada $ " #nI#N"
         IF ld_calc_min_bruto_yes_no()
            nBoMin := ld_min_bruto_osnova( nBrutoOsnova, ld->usati )
         ENDIF
      ENDIF

      ? cMainLine

      IF gPrBruto == "X"
         ? cLDLijevaMargina + "1. BRUTO PLATA :  "
      ELSE
         ? cLDLijevaMargina + "1. BRUTO PLATA :  ", ld_bruto_isplata_ispis( nOsnZaBr, cRTipRada, nLicniOdbitak )
      ENDIF

      IF cRTipRada == "nI"
         ?
      ENDIF

      //@ PRow(), 60 + Len( cLDLijevaMargina ) SAY nBrutoOsnova PICT gpici
      @ PRow(), PCol() + 1 SAY nBrutoOsnova PICT gpici

      ? cMainLine

      IF lSkrivena
         ? cMainLine
      ENDIF

      ?U cLDLijevaMargina + "Obračun doprinosa: "

      IF ( nBrutoOsnova < nBoMin )
         ??  "minimalna bruto satnica * sati"
         @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nBoMin PICT gpici
         ? cLDLijevaMargina + cDoprLine
      ENDIF

      select_o_dopr()
      GO TOP

      nPom := 0
      nDopr := 0
      nUkDoprIz := 0
      nC1 := 20 + Len( cLDLijevaMargina )

      DO WHILE !Eof()

         IF cRTipRada $ tr_list() .AND. Empty( dopr->tiprada )
         ELSEIF dopr->tiprada <> cRTipRada
            SKIP
            LOOP
         ENDIF

         IF dopr->( FieldPos( "DOP_TIP" ) ) <> 0

            IF dopr->dop_tip == "N" .OR. dopr->dop_tip == " "
               nOsn := nOsnNeto
            ELSEIF dopr->dop_tip == "2"
               nOsn := nOsnOstalo
            ELSEIF dopr->dop_tip == "P"
               nOsn := nOsnNeto + nOsnOstalo
            ENDIF

         ENDIF

         ld_opstina_stanovanja_rada( DOPR->poopst )

         IF gKarSDop == "N" .AND. Left( dopr->id, 1 ) <> "1"
            SKIP
            LOOP
         ENDIF

         IF !ld_ima_u_ops_porez_ili_doprinos( "DOPR", DOPR->id ) .OR. !lPrikSveDopr .AND. !DOPR->ID $ cPrikDopr
            SKIP 1
            LOOP
         ENDIF

         IF Right( id, 1 ) == "X"
            ? cDoprLine
         ENDIF

         IF dopr->id == "1X"
            ? cLDLijevaMargina + "2. " + id, "-", naz
         ELSE
            ? cLDLijevaMargina + cDoprSpace + id, "-", naz
         ENDIF

         @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"

         IF Empty( field->idkbenef )
            @ PRow(), PCol() + 1 SAY nBoMin PICT gPici
            nC1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nPom := Max( dopr->dlimit, Round( iznos / 100 * nBOMin, gZaok2 ) ) PICT gPici
            IF dopr->id == "1X"
               nUkDoprIz += nPom
            ENDIF
         ELSE
            nPom0 := AScan( aBeneficirani, {| x | x[ 1 ] == idkbenef } )
            IF nPom0 <> 0
               nPom2 := aBeneficirani[ nPom0, 3 ]
            ELSE
               nPom2 := 0
            ENDIF
            IF Round( nPom2, gZaok2 ) <> 0
               @ PRow(), PCol() + 1 SAY nPom2 PICT gpici
               nC1 := PCol() + 1
               nPom := Max( dlimit, Round( iznos / 100 * nPom2, gZaok2 ) )
               @ PRow(), PCol() + 1 SAY nPom PICT gpici
            ENDIF
         ENDIF

         IF Right( id, 1 ) == "X"
            ? cDoprLine
            nDopr += nPom
         ENDIF

         IF !lSkrivena .AND. PRow() > 64 + dodatni_redovi_po_stranici()
            FF
         ENDIF

         SKIP 1

      ENDDO

      nOporDoh := nBrutoOsnova - nUkDoprIz

      ? cLDLijevaMargina + "3. BRUTO - DOPRINOSI IZ PLATE (1-2)"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOporDoh PICT gpici

      ? cMainLine
      IF nLicniOdbitak > 0
         ?U cLDLijevaMargina + "4. LIČNI ODBITAK", Space( 14 )
         ?? AllTrim( Str( gOsnLOdb ) ) + " * koef. " + ;
            AllTrim( Str( nKoefOdbitka ) ) + " = "
         @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nLicniOdbitak PICT gpici
      ELSE
         ?U cLDLijevaMargina + "4. LIČNI ODBITAK"
         @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nLicniOdbitak PICT gpici

      ENDIF

      ? cMainLine

      nPorOsnovica := ( nBrutoOsnova - nUkDoprIz - nLicniOdbitak )
      IF nPorOsnovica < 0 .OR. !radn_oporeziv( radn->id, ld->idrj )
         nPorOsnovica := 0
      ENDIF

      ?  cLDLijevaMargina + "5. OSNOVICA ZA POREZ NA PLATU (1-2-4)"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPorOsnovica PICT gpici

      ? cMainLine
      ? cLDLijevaMargina + "6. POREZ NA PLATU"

      select_o_por()
      GO TOP

      nPom := 0
      nPor := 0
      nC1 := 30 + Len( cLDLijevaMargina )
      nPorOl := 0

      DO WHILE !Eof()

         cAlgoritam := get_algoritam()

         ld_opstina_stanovanja_rada( POR->poopst )
         IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
            SKIP 1
            LOOP
         ENDIF

         IF por->por_tip <> "B"
            SKIP
            LOOP
         ENDIF

         aPor := obr_por( por->id, nPorOsnovica, 0 )
         nPor += isp_por( aPor, cAlgoritam, cLDLijevaMargina, .T., .T. )

         SKIP 1
      ENDDO

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nPor PICT gpici

      nUkIspl := ROUND2( nBrutoOsnova - nUkDoprIz - nPor, gZaok2 )

      nMUkIspl := nUkIspl

      IF cRTipRada $ " #nI#N"
         nMUkIspl := min_neto( nUkIspl, ld->usati )
      ENDIF

      ? cMainLine

      IF nUkIspl < nMUkIspl
         ? cLDLijevaMargina + "7. Minimalna neto isplata : min.neto satnica * sati"
      ELSE
         ? cLDLijevaMargina + "7. NETO PLATA (1-2-6)"
      ENDIF

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nMUkIspl PICT gpici

      ? cMainLine
      ? cLDLijevaMargina + "8. NEOPOREZIVE NAKNADE I ODBICI (preb.stanje)"

      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOsnOstalo PICT gpici

      ? cLDLijevaMargina + "  * naknade (+ primanja): "
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOstalaPrimanjaPlus PICT gPICI

      ? cLDLijevaMargina + "  *  odbici (- primanja): "
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nOstalaPrimanjaNegativno PICT gPICI

      nZaIsplatu := ROUND2( nMUkIspl + nOsnOstalo, gZaok2 )

      ? cMainLine
      ?  cLDLijevaMargina + "UKUPNO ZA ISPLATU SA NAKNADAMA I ODBICIMA (7+8)"
      @ PRow(), 60 + Len( cLDLijevaMargina ) SAY nZaIsplatu PICT gpici

      ? cMainLine

      IF !lSkrivena .AND. PRow() > 64 + dodatni_redovi_po_stranici()
         FF
      ENDIF

      ?
      IF gPotp <> "D"
         IF PCount() == 0
            FF
         ENDIF
      ENDIF

   ENDIF

   ld_kartica_potpis()

   IF lSkrivena
      IF PRow() < nKRSK + 5
         nPom := nKRSK - PRow()
         FOR nI := 1 TO nPom
            ?
         NEXT
      ELSE
         FF
      ENDIF
   ELSEIF c2K1L == "N"
      FF
   ELSEIF gPrBruto $ "D#X"
      FF
   ELSEIF lNKNS
      FF
   ELSEIF ( nRBRKart % 2 == 0 )
      FF
   ELSEIF ( nRBRKart % 2 <> 0 ) .AND. ( DUZ_STRANA - PRow() < nKRedova )
      --nRBRKart
      FF
   ENDIF

   RETURN .T.
