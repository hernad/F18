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


THREAD STATIC DUZ_STRANA := 70
THREAD STATIC __radni_sati := "N"


FUNCTION ld_kartica_redovan_rad( cIdRj, nMjesec, nGodina, cIdRadn, cObrac, aNeta )

   LOCAL nKRedova
   LOCAL cDoprSpace := Space( 3 )
   LOCAL cTprLine
   LOCAL cDoprLine
   LOCAL cMainLine
   LOCAL _radni_sati := fetch_metric( "ld_radni_sati", NIL, "N" )
   LOCAL _a_benef := {}
   LOCAL lFoundTippr

   PRIVATE cLMSK := ""

   __radni_sati := _radni_sati

   cTprLine := _gtprline()
   cDoprLine := _gdoprline( cDoprSpace )
   cMainLine := _gmainline()

   nKRedova := kart_redova()

   Eval( bZagl )

   IF gTipObr == "2" .AND. parobr->k1 <> 0
      ?? _l( "        Bod-sat:" )
      @ PRow(), PCol() + 1 SAY parobr->vrbod / parobr->k1 * brbod PICT "99999.99999"
   ENDIF

   cUneto := "D"
   nRRsati := 0
   nOsnNeto := 0
   nOsnOstalo := 0
   nOstPoz := 0
   nOstNeg := 0
   // nLicOdbitak := g_licni_odb( radn->id )
   nLicOdbitak := ld->ulicodb
   nKoefOdbitka := get_koeficijent_licnog_odbitka( nLicOdbitak )
   cRTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

   ? cTprLine
   IF gPrBruto == "X"
      ? cLMSK + " Vrsta                  Opis         sati/iznos            ukupno bruto"
   ELSE
      ? cLMSK + " Vrsta                  Opis         sati/iznos             ukupno"
   ENDIF

   ? cTprLine

   FOR nI := 1 TO cLDPolja

      cPom := PadL( AllTrim( Str( nI ) ), 2, "0" )

      select_o_tippr( cPom )
      lFoundTippr := Found()

      IF tippr->uneto == "N" .AND. cUneto == "D"

         cUneto := "N"

         ? cTprLine
         ? cLMSK + "Ukupno:"

         @ PRow(), nC1 + 8  SAY  _USati  PICT gpics
         ?? Space( 1 ) + "sati"
         nPom := _calc_tpr( _UNeto, .T. )
         @ PRow(), 60 + Len( cLMSK ) SAY nPom PICT gpici
         ?? "", gValuta
         ? cTprLine

      ENDIF

      IF lFoundTipPr .AND. tippr->aktivan == "D"

         IF _I&cPom <> 0 .OR. _S&cPom <> 0

            nDJ := At( "#", tippr->naz )
            cDJ := Right( AllTrim( tippr->naz ), nDJ + 1 )
            cTPNaz := tippr->naz

            ? cLMSK + tippr->id + "-" + ;
               PadR( cTPNAZ, Len( tippr->naz ) ), sh_tp_opis( tippr->id, radn->id )
            nC1 := PCol()

            IF tippr->fiksan $ "DN"

               @ PRow(), PCol() + 8 SAY _S&cPom PICT gpics
               ?? " s"

               nPom := _calc_tpr( _I&cPom )
               @ PRow(), 60 + Len( cLMSK ) SAY nPom PICT gpici


               IF tippr->id == "01" .AND. __radni_sati == "D"

                  nRRSati := _S&cPom

               ENDIF

            ELSEIF tippr->fiksan == "P"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), PCol() + 8 SAY _S&cPom  PICT "999.99%"
               @ PRow(), 60 + Len( cLMSK ) SAY nPom  PICT gpici

            ELSEIF tippr->fiksan == "B"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), PCol() + 8 SAY _S&cPom  PICT "999999"; ?? " b"
               @ PRow(), 60 + Len( cLMSK ) SAY nPom PICT gpici

            ELSEIF tippr->fiksan == "C"
               nPom := _calc_tpr( _I&cPom )
               @ PRow(), 60 + Len( cLMSK ) SAY nPom PICT gpici
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

               ? cLPom := cLMSK + "   ----------------------------- ----------------------------"
               ?U cLMSK + "    SUMA IZ PRETHODNIH OBRAČUNA   UKUPNO (SA OVIM OBRAČUNOM)"
               ? cLPom
               ? cLMSK + "   " + PadC( Str( nKumPrim - Abs( _I&cPom ) ), 29 ) + " " + PadC( Str( nKumPrim ), 28 )
               ? cLPom
            ENDIF

            IF tippr->( FieldPos( "TPR_TIP" ) ) <> 0
               // uzmi osnovice
               IF tippr->tpr_tip == "N"
                  nOsnNeto += _I&cPom
               ELSEIF tippr->tpr_tip == "2"
                  nOsnOstalo += _I&cPom
                  IF _I&cPom > 0
                     nOstPoz += _I&cPom
                  ELSE
                     nOstNeg += _I&cPom
                  ENDIF
               ELSEIF tippr->tpr_tip == " "
                  // standardni tekuci sistem
                  IF tippr->uneto == "D"
                     nOsnNeto += _I&cPom
                  ELSE
                     nOsnOstalo += _I&cPom
                     IF _I&cPom > 0
                        nOstPoz += _I&cPom
                     ELSE
                        nOstNeg += _I&cPom
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
                     nOstPoz += _I&cPom
                  ELSE
                     nOstNeg += _I&cPom
                  ENDIF
               ENDIF
            ENDIF


            IF "SUMKREDITA" $ tippr->formula .AND. gReKrKP == "1"

               P_COND

               ? cTprLine
               ?U cLMSK + "  ", "Od toga pojedinačni krediti:"

               seek_radkr( _godina, _mjesec, _idradn )
               DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn
                  select_o_kred( radkr->idkred )
                  SELECT radkr
                  ? cLMSK + "  ", idkred, Left( kred->naz, 22 ), naosnovu
                  @ PRow(), 58 + Len( cLMSK ) SAY iznos PICT "(" + gpici + ")"

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

               ? m2 := cLMSK + "   ------------------------------------------------  --------- --------- -------"
               ? cLMSK + "        Kreditor      /              na osnovu         Ukupno    Ostalo   Rata"
               ? m2

               DO WHILE !Eof() .AND. _godina == godina .AND. _mjesec = mjesec .AND. idradn == _idradn

                  select_o_kred( radkr->idkred )

                  SELECT radkr
                  aIznosi := ld_iznosi_za_kredit( idradn, idkred, naosnovu, _mjesec, _godina )
                  ? cLMSK + " ", idkred, Left( kred->naz, 22 ), PadR( naosnovu, 20 )
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
      //HSEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + "1" + _idradn + _idrj

      ?
      ? cLMSK + "Od toga 1. dio:"
      @ PRow(), 60 + Len( cLMSK ) SAY UIznos PICT gpici
      ? cTprLine


      //HSEEK Str( _godina, 4 ) + Str( _mjesec, 2 ) + "2" + _idradn + _idrj
      seek_ld_2( _idrj, _godina, _mjesec, "2", _idradn)

      ? cLMSK + "Od toga 2. dio:"
      @ PRow(), 60 + Len( cLMSK ) SAY UIznos PICT gpici
      ? cTprLine
      SELECT ld
      PopWA()
   ENDIF

   IF __radni_sati == "D"
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

      nBO := 0
      nBFO := 0

      nOsnZaBr := nOsnNeto

      nBo := ld_get_bruto_osnova( nOsnZaBr, cRTipRada, nLicOdbitak )

      IF is_radn_k4_bf_ide_u_benef_osnovu()

         nTmp2 := nOsnZaBr - IF( !Empty( gBFForm ),  &( gBFForm ), 0 )
         nBFo := ld_get_bruto_osnova( nTmp2, cRTipRada, nLicOdbitak )

         _benef_st := BenefStepen()
         add_to_a_benef( @_a_benef, AllTrim( radn->k3 ), _benef_st, nBFO )

      ENDIF

      nBoMin := nBo

      IF cRTipRada $ " #nI#N"
         IF calc_mbruto()
            nBoMin := min_bruto( nBo, ld->usati )
         ENDIF
      ENDIF

      ? cMainLine

      IF gPrBruto == "X"
         ? cLMSK + "1. BRUTO PLATA :  "
      ELSE
         ? cLMSK + "1. BRUTO PLATA :  ", ld_bruto_isplata_ispis( nOsnZaBr, cRTipRada, nLicOdbitak )
      ENDIF

      IF cRTipRada == "nI"
         ?
      ENDIF

      //@ PRow(), 60 + Len( cLMSK ) SAY nBo PICT gpici
      @ PRow(), PCol() + 1 SAY nBo PICT gpici

      ? cMainLine

      IF lSkrivena
         ? cMainLine
      ENDIF

      ?U cLmSK + "Obračun doprinosa: "

      IF ( nBo < nBoMin )
         ??  "minimalna bruto satnica * sati"
         @ PRow(), 60 + Len( cLMSK ) SAY nBoMin PICT gpici
         ? cLmSk + cDoprLine
      ENDIF

      select_o_dopr()
      GO TOP

      nPom := 0
      nDopr := 0
      nUkDoprIz := 0
      nC1 := 20 + Len( cLMSK )

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

         PozicOps( DOPR->poopst )

         IF gKarSDop == "N" .AND. Left( dopr->id, 1 ) <> "1"
            SKIP
            LOOP
         ENDIF

         IF !ImaUOp( "DOPR", DOPR->id ) .OR. !lPrikSveDopr .AND. !DOPR->ID $ cPrikDopr
            SKIP 1
            LOOP
         ENDIF

         IF Right( id, 1 ) == "X"
            ? cDoprLine
         ENDIF

         IF dopr->id == "1X"
            ? cLMSK + "2. " + id, "-", naz
         ELSE
            ? cLMSK + cDoprSpace + id, "-", naz
         ENDIF

         @ PRow(), PCol() + 1 SAY iznos PICT "99.99%"

         IF Empty( field->idkbenef )
            @ PRow(), PCol() + 1 SAY nBoMin PICT gpici
            nC1 := PCol() + 1
            @ PRow(), PCol() + 1 SAY nPom := Max( dopr->dlimit, Round( iznos / 100 * nBOMin, gZaok2 ) ) PICT gpici
            IF dopr->id == "1X"
               nUkDoprIz += nPom
            ENDIF
         ELSE
            nPom0 := AScan( _a_benef, {| x | x[ 1 ] == idkbenef } )
            IF nPom0 <> 0
               nPom2 := _a_benef[ nPom0, 3 ]
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

      nOporDoh := nBO - nUkDoprIz

      ? cLMSK + "3. BRUTO - DOPRINOSI IZ PLATE (1-2)"
      @ PRow(), 60 + Len( cLMSK ) SAY nOporDoh PICT gpici

      ? cMainLine

      IF nLicOdbitak > 0

         ?U cLMSK + "4. LIČNI ODBITAK", Space( 14 )
         ?? AllTrim( Str( gOsnLOdb ) ) + " * koef. " + ;
            AllTrim( Str( nKoefOdbitka ) ) + " = "
         @ PRow(), 60 + Len( cLMSK ) SAY nLicOdbitak PICT gpici

      ELSE

         ?U cLMSK + "4. LIČNI ODBITAK"
         @ PRow(), 60 + Len( cLMSK ) SAY nLicOdbitak PICT gpici

      ENDIF

      ? cMainLine

      nPorOsnovica := ( nBO - nUkDoprIz - nLicOdbitak )

      IF nPorOsnovica < 0 .OR. !radn_oporeziv( radn->id, ld->idrj )
         nPorOsnovica := 0
      ENDIF

      ?  cLMSK + "5. OSNOVICA ZA POREZ NA PLATU (1-2-4)"
      @ PRow(), 60 + Len( cLMSK ) SAY nPorOsnovica PICT gpici

      ? cMainLine

      ? cLMSK + "6. POREZ NA PLATU"

      select_o_por()
      GO TOP

      nPom := 0
      nPor := 0
      nC1 := 30 + Len( cLMSK )
      nPorOl := 0

      DO WHILE !Eof()

         cAlgoritam := get_algoritam()

         PozicOps( POR->poopst )

         IF !ImaUOp( "POR", POR->id )
            SKIP 1
            LOOP
         ENDIF

         IF por->por_tip <> "B"
            SKIP
            LOOP
         ENDIF

         aPor := obr_por( por->id, nPorOsnovica, 0 )
         nPor += isp_por( aPor, cAlgoritam, cLMSK, .T., .T. )

         SKIP 1
      ENDDO

      @ PRow(), 60 + Len( cLMSK ) SAY nPor PICT gpici

      nUkIspl := ROUND2( nBO - nUkDoprIz - nPor, gZaok2 )

      nMUkIspl := nUkIspl

      IF cRTipRada $ " #nI#N"
         nMUkIspl := min_neto( nUkIspl, ld->usati )
      ENDIF

      ? cMainLine

      IF nUkIspl < nMUkIspl
         ? cLMSK + "7. Minimalna neto isplata : min.neto satnica * sati"
      ELSE
         ? cLMSK + "7. NETO PLATA (1-2-6)"
      ENDIF

      @ PRow(), 60 + Len( cLMSK ) SAY nMUkIspl PICT gpici

      ? cMainLine
      ? cLMSK + "8. NEOPOREZIVE NAKNADE I ODBICI (preb.stanje)"

      @ PRow(), 60 + Len( cLMSK ) SAY nOsnOstalo PICT gpici

      ? cLMSK + "  - naknade (+ primanja): "
      @ PRow(), 60 + Len( cLMSK ) SAY nOstPoz PICT gPICI

      ? cLMSK + "  -  odbici (- primanja): "
      @ PRow(), 60 + Len( cLMSK ) SAY nOstNeg PICT gPICI

      nZaIsplatu := ROUND2( nMUkIspl + nOsnOstalo, gZaok2 )

      ? cMainLine
      ?  cLMSK + "UKUPNO ZA ISPLATU SA NAKNADAMA I ODBICIMA (7+8)"
      @ PRow(), 60 + Len( cLMSK ) SAY nZaIsplatu PICT gpici

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

   kart_potpis()

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
