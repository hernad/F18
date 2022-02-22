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

//STATIC __var_obr

FUNCTION ld_rekapitulacija_sql( lSveRj )

   LOCAL aBeneficirani := {}
   LOCAL nPoreskaOsnovica0
   LOCAL lRsObracun := .F.
   LOCAL i
   LOCAL hParams
   LOCAL cRekapTipoviOut := fetch_metric("ld_rekap_out", NIL, SPACE(10)), lRekapTO := .F.
   LOCAL nIzbitiIzNeto, nIzbitiIzOstalo
   LOCAL nURadniciBrutoOsnova
   LOCAL cRekapSamoTODN := "N"
   LOCAL nULOdbitak
   LOCAL nUkRadnMinBrutoOsn
   LOCAL nPorOsnova
   LOCAL nUkPorBruto, nUkPorNeto

   PRIVATE nC1 := 20
   PRIVATE cTPNaz
   PRIVATE cUmPDNeKontamStajeOvoVazdajeN := "N"
   PRIVATE nKrug := 1
   PRIVATE nUPorOl := 0
   PRIVATE cFilt1 := ""
   PRIVATE cNaslovRekap := "LD: Rekapitulacija primanja"
   PRIVATE aUsl1, aUsl2
   PRIVATE aNetoMj
   PRIVATE cDoprSpace := ""
   PRIVATE cLDLijevaMargina := ""

   cTpLine := _gtprline()
   cDoprLine := _gdoprline( cDoprSpace )
   cMainLine := _gmainline()
   cMainLine := Replicate( "-", 2 ) + cMainLine

   cIdRadn := Space( LEN_IDRADNIK )
   cIdRj := gLDRadnaJedinica
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()
   cObracun := gObracun
   nMjesecDo := nMjesec
   nStrana := 0
   aUkTr := {}
   nBO := 0
   cRTipRada := " " // R - lRSObracun
   nKoefLO := 0
   PRIVATE nStepenInvaliditeta := 0
   PRIVATE nVrstaInvaliditeta := 0

   IF lSveRj == NIL
      lSveRj := .F.
   ENDIF

   o_ld_rekap()

   cIdRadn := Space( 6 )
   cStrSpr := Space( 3 )
   cOpsSt := Space( 4 )
   cOpsRad := Space( 4 )
   cK4 := "S"

   IF lSveRj
      qqRJ := Space( 60 )
      ld_rekap_get_vars_svi( cRekapTipoviOut, @cRekapSamoTODN, @cRtipRada )
      IF ( LastKey() == K_ESC )
         RETURN .F.
      ENDIF
   ELSE
      qqRJ := Space( 2 )
      ld_rekap_get_vars_rj( cRekapTipoviOut, @cRekapSamoTODN, @cRTipRada )
      IF ( LastKey() == K_ESC )
         RETURN .F.
      ENDIF
   ENDIF

   IF cRTipRada == "R"
      lRsObracun := .T.
   ENDIF

   lRekapTO := .F. // rekapitulacija samo TO
   IF cRekapSamoTODN == "D"
      lRekapTO := .T.
   ENDIF

   cObracun := Trim( cObracun )

   hParams := hb_Hash()
   hParams[ "svi" ] := lSveRj
   hParams[ "str_sprema" ] := cStrSpr
   hParams[ "q_rj" ] := qqRj

   hParams[ "usl1" ] := aUsl1
   hParams[ "mjesec" ] := nMjesec
   hParams[ "mjesec_do" ] := nMjesecDo

   hParams[ "obracun" ] := cObracun
   hParams[ "godina" ] := nGodina

   use_sql_ld_ld( nGodina, nMjesec, nMjesecDo, nVrstaInvaliditeta, nStepenInvaliditeta, hParams )

   IF lSveRj
      SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
   ELSE
      SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "1" ) )
   ENDIF


   IF !lSveRj
      SEEK Str( nGodina, 4, 0 ) + cIdRj + Str( nMjesec, 2, 0 ) + cObracun // after ld_sql open
      EOF CRET
   ELSE
      SEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun // after ld_sql open
      EOF CRET
   ENDIF

   ld_porezi_i_doprinosi_iz_sezone( nGodina, nMjesecDo )

   cre_ops_ld_temp()
   cre_rekld_temp()

   open_rekld()
   O_OPSLD

   SELECT ld

   START PRINT CRET
   ?
   P_12CPI

   ld_pozicija_parobr( nMjesec, nGodina, cObracun, iif( !lSveRj, cIdRj, ) )  // pozicionira bazu PAROBR na odgovarajuci zapis

   PRIVATE aRekap[ cLDPolja, 2 ]

   FOR i := 1 TO cLDPolja
      aRekap[ i, 1 ] := 0
      aRekap[ i, 2 ] := 0
   NEXT

   nT1 := 0
   nT2 := 0
   nT3 := 0
   nT4 := 0
   nUNeto := 0
   nUNetoOsnova := 0
   nDoprOsnova := 0
   nDoprOsnOst := 0
   nPorOsnova := 0
   nPorNROsnova := 0
   nUPorNROsnova := 0
   nURadniciBrutoOsnova := 0
   nUkRadnMinBrutoOsn := 0
   nURadn_bbo := 0
   nUPorOsnova := 0
   nULOdbitak := 0
   nUBNOsnova := 0
   nUDoprIz := 0
   nUkRadnikDoprinosiIz := 0
   nUIznos := 0
   nUSati := 0
   nUOdbici := 0
   nUOstalaPrimanja := 0
   nUOstalaPrimanjaMinus := 0
   nLjudi := 0
   nUBBTrosk := 0
   nURTrosk := 0

   PRIVATE aNeta := {}

   SELECT ld

   IF nMjesec != nMjesecDo
      IF lSveRj
         GO TOP
         PRIVATE bUslov := {|| field->godina == nGodina .AND. field->mjesec >= nMjesec .AND. field->mjesec <= nMjesecDo .AND. field->obr = cObracun }
      ELSE
         PRIVATE bUslov := {|| field->godina == nGodina .AND. field->idrj == cIdRj .AND. field->mjesec >= nMjesec .AND. field->mjesec <= nMjesecDo .AND. field->obr = cObracun }
      ENDIF
   ELSE
      IF lSveRj
         PRIVATE bUslov := {|| nGodina == field->godina .AND. nMjesec == field->mjesec .AND. field->obr == cObracun }
      ELSE
         PRIVATE bUslov := {|| nGodina == field->godina .AND. cIdrj == field->idrj .AND. nMjesec == field->mjesec .AND. field->obr == cObracun }
      ENDIF
   ENDIF

   ld_rekap_calc_totals( bUslov, lSveRj, @aBeneficirani, cRekapTipoviOut, lRekapTO, ;
           @nUSati, @nUNeto, @nULOdbitak, @nUIznos, @nUOdbici, @nIzbitiIzNeto, @nIzbitiIzOstalo, @nURadniciBrutoOsnova, @nUkRadnMinBrutoOsn)

   IF nLjudi == 0
      nLjudi := 9999999
   ENDIF

   B_ON
   ?? cNaslovRekap
   B_OFF

   IF !Empty( cStrSpr )
      ??U Space( 1 ) + "za radnike stručne spreme:", cStrSpr
   ENDIF

   IF !Empty( cOpsSt )
      ?U "Općina stanovanja:", cOpsSt
   ENDIF

   IF !Empty( cOpsRad )
      ?U "Općina rada:", cOpsRad
   ENDIF

   IF lSveRj
      zagl_rekapitulacija_plata_svi()
   ELSE
      zagl_rekapitulacija_plata_rj()
   ENDIF

   ? cTpLine

   cLinija := cTpLine

   ld_ispis_po_tipovima_primanja( lSveRj, cRekapTipoviOut, lRekapTO, nUNeto, nUSati, nIzbitiIzNeto, nIzbitiIzOstalo )

   ? cTpLine

   nPosY := 60

   ? "Ukupno (primanja sa obustavama):"
   @ PRow(), nPosY SAY nUNeto - nIzbitiIzNeto + nUOstalaPrimanja + nUOstalaPrimanjaMinus PICT gpici
   ?? "", gValuta

   ? cTpLine

   ?
   ProizvTP()

   IF cRTipRada $ "A#U"
      ? cMainLine
      ?U "a) UKUPNI BRUTO SA TROŠKOVIMA "
      @ PRow(), 60 SAY nUBBTrosk PICT gPicI
      ?U "b) UKUPNI TROŠKOVI "
      @ PRow(), 60 SAY nURTrosk PICT gPici
   ENDIF


   // 1. BRUTO IZNOS
   // setuje se varijabla nBO
   ld_say_bruto( nURadniciBrutoOsnova )

   // 2. DOPRINOSI
   PRIVATE nDopr
   PRIVATE nDopr2

   ?U "2. OBRAČUN DOPRINOSA:"

   // bruto osnova minimalca
   IF nURadniciBrutoOsnova < nUkRadnMinBrutoOsn
      ?? " min.bruto satnica * sati"
      @ PRow(), 60 SAY nUkRadnMinBrutoOsn PICT gPici
   ENDIF

   ? cMainLine

   cLinija := cDoprLine

   ld_obr_doprinos( nGodina, nMjesec, @nDopr, @nDopr2, cRTipRada, aBeneficirani, nUkRadnMinBrutoOsn )

   nTOporDoh := nURadniciBrutoOsnova - nUDoprIz

   ? cMainLine
   ? "3. UKUPNO BRUTO - DOPRINOSI IZ PLATE"
   @ PRow(), 60 SAY nTOporDoh PICT gPici

   ? cMainLine
   ?U "4. LIČNI ODBICI UKUPNO"
   IF lRekapTO
      nULOdbitak := 0
   ENDIF
   @ PRow(), 60 SAY nULOdbitak PICT gPici

   

   ? cMainLine

   IF lRsObracun
      ?U "5. OSNOVICA ZA OBRAČUN POREZA NA PLATU (1-4)"
      nPoreskaOsnovica0 := nURadniciBrutoOsnova - nULOdbitak
   ELSE
      ?U "5. OSNOVICA ZA OBRAČUN POREZA NA PLATU (1-2-4)"
      nPoreskaOsnovica0 := nURadniciBrutoOsnova - nUDoprIz - nULOdbitak
   ENDIF
   @ PRow(), 60 SAY nPoreskaOsnovica0 PICT gPici
   ? cMainLine


   PRIVATE nPor
   PRIVATE nPor2
   PRIVATE nPorOps
   PRIVATE nPorOps2
   PRIVATE nUZaIspl

   nUZaIspl := 0
   nPorez1 := 0
   nPorez2 := 0
   nPorOp1 := 0
   nPorOp2 := 0
   nPorOl1 := 0
   //nPorOsnova := 0
   //nPorB := 0
   nPorR := 0

   nPorOsnova := ld_obr_porez( lRsObracun, nGodina, nMjesec, @nUkPorBruto, @nPor2, @nPorOps, @nPorOps2, @nUPorOl, "B" )    // obracunaj porez na bruto

   //nPorB := nUkPorBruto

   // ako je stvarna osnova veca od ove BRUTO - DOPRIZ - ODBICI, rijec je o radnicima koji nemaju poreza
   IF Round( nPorOsnova, 2 ) > Round( nPoreskaOsnovica0, 2 )
      ?U _l( "! razlika osnovice poreza (radi radnika bez poreza):" )
      @ PRow(), 60 SAY nPoreskaOsnovica0 - nPorOsnova PICT gpici
      ?
   ENDIF

   nPorez1 += nUkPorBruto
   nPorez2 += nPor2 // vazda 0

   nPorOp1 += nPorOps
   nPorOp2 += nPorOps2 // garant vazda 0

   nPorOl1 += nUPorOl
   nNetoIspl := nUPorNROsnova
   nUZaIspl := nNetoIspl + nUOstalaPrimanjaMinus + nUOstalaPrimanja

   ? cMainLine
   ? "6. UKUPNA NETO PLATA"
   @ PRow(), 60 SAY nNetoIspl PICT gPici

   ? cMainLine
   ?U "7. OSNOVICA ZA OBRAČUN OSTALIH NAKNADA (6)"
   @ PRow(), 60 SAY nNetoIspl PICT gPici
   ? cMainLine

   ld_obr_porez( lRsObracun, nGodina, nMjesec, @nUkPorNeto, @nPor2, @nPorOps, @nPorOps2, @nUPorOl, "R" )

   //nPorR := nPor
   nPorez1 += nUkPorNeto
   nPorez2 += nPor2 // vazda 0
   nPorOp1 += nPorOps
   nPorOp2 += nPorOps2
   nPorOl1 += nUPorOl

   ? cMainLine
   ? "8. UKUPNO ODBICI/NAKNADE IZ PLATE:"
   ? "             ODBICI:"
   @ PRow(), 60 SAY nUOstalaPrimanjaMinus PICT gPici
   ? "     OSTALE NAKNADE:"
   @ PRow(), 60 SAY nUOstalaPrimanja PICT gPici
   ? cMainLine

   ? cMainLine
   IF cRTipRada $ "A#U"
      ?U "9. UKUPNO ZA ISPLATU (bruto-dopr-porez+troškovi):"
   ELSE
      ?U "9. UKUPNO ZA ISPLATU (bruto-dopr-porez+odbici+naknade):"
   ENDIF
   @ PRow(), 60 SAY nUZaIspl PICT gPici
   ? cMainLine

   ?

   cLinija := "-----------------------------------------------------------"

   ? cLinija
   ? "OPOREZIVA PRIMANJA:"
   @ PRow(), PCol() + 1 SAY nUNeto PICT gpici
   ?? "(" + "za isplatu:"
   @ PRow(), PCol() + 1 SAY nUZaIspl PICT gpici
   ?? "," + "Obustave:"
   @ PRow(), PCol() + 1 SAY -nUOstalaPrimanjaMinus PICT gpici
   ?? ")"
   ? "    " + "OSTALE NAKNADE:"
   @ PRow(), PCol() + 1 SAY nUOstalaPrimanja PICT gpici  // dodatna primanja van neta
   ? cLinija
   
   ? " " + "OPOREZIVI DOHODAK (1):"
   @ PRow(), PCol() + 1 SAY nURadniciBrutoOsnova - nUDoprIz PICT gpici
   IF lRsObracun
      ? "         " + "POREZ  8% (2):"
   ELSE
      ? "         " + "POREZ 10% (2):"
   ENDIF

   //IF cUmPDNeKontamStajeOvoVazdajeN == "D"
   //   @ PRow(), PCol() + 1 SAY nPorB - nPorOl1 - nPorez2    PICT gpici
   //ELSE
      @ PRow(), PCol() + 1 SAY nUkPorBruto - nPorOl1    PICT gpici
   //ENDIF
   ? "     " + "OSTALI POREZI (3):"
   @ PRow(), PCol() + 1 SAY nPorR PICT gpici
   
   ? "         " + "DOPRINOSI (4):"
   IF cUmPDNeKontamStajeOvoVazdajeN == "D"
      @ PRow(), PCol() + 1 SAY nDopr - nDopr2    PICT gpici
   ELSE
      @ PRow(), PCol() + 1 SAY nDopr    PICT gpici
   ENDIF

   ? cLinija

   IF cUmPDNeKontamStajeOvoVazdajeN == "D"
      ? " POTREBNA SREDSTVA (1 + 3 + 4):"
      @ PRow(), PCol() + 1 SAY ( nURadniciBrutoOsnova - nUDoprIz ) + ( nPorR ) + nDopr - nPorez2 - nDopr2    PICT gpici
   ELSE
      ? " POTREBNA SREDSTVA (1 + 3 + 4 + ost.nakn.):"
      @ PRow(), PCol() + 1 SAY ( nURadniciBrutoOsnova - nUDoprIz ) + ( nPorR ) + nDopr + nUOstalaPrimanja PICT gpici
   ENDIF

   ? cLinija
   ?
   ?U "Izvršena obrada na ", Str( nLjudi, 5 ), "radnika"
   ?

   IF nUSati == 0
      nUSati := 999999
   ENDIF

   ?U "Prosječni neto/satu je ", AllTrim( Transform( nNetoIspl, gPici ) ), "/", AllTrim( Str( nUSati ) ), "=", AllTrim( Transform( nNetoIspl / nUsati, gpici ) ), "*", AllTrim( Transform( parobr->k1, "999" ) ), "=", AllTrim( Transform( nNetoIspl / nUsati * parobr->k1, gpici ) )

   P_12CPI
   ?
   ?
   ?  PadC( "     " + "Obradio:" + "                                 " + "Direktor:" + "    ", 80 )
   ?
   ?  PadC( "_____________________                    __________________", 80 )
   ?
   FF

   my_close_all_dbf()

   ENDPRINT

   IF f18_use_module( "virm" ) .AND. Pitanje(, "Generisati virmane za ovaj obračun plate ? (D/N)", "D" ) == "D"
      virm_set_global_vars()
      set_metric( "virm_godina", my_user(), nGodina )
      set_metric( "virm_mjesec", my_user(), nMjesec )
      ld_virm_prenos( .T. )
      unos_virmana()
      my_close_all_dbf()
   ENDIF

   RETURN .T.


STATIC FUNCTION nStr()

   IF PRow() > 64 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   RETURN .T.


STATIC FUNCTION ld_rekap_calc_totals( bUslovMjesecGodinaObracun, lSveRj, aBeneficirani, cRekapTipoviOut, lRekapTO, ;
             nUSati, nUNeto, nULOdbitak, nUIznos, nUOdbici, nIzbitiIzNeto, nIzbitiIzOstalo, nURadniciBrutoOsnova, nUkRadnMinBrutoOsn ) // po referenci
   LOCAL i
   LOCAL cAlgoritam
   LOCAL cTpr
   LOCAL cOpis2
   LOCAL cTprField
   LOCAL nOsnovaNeto
   LOCAL nOsnNetoZaBrutoOsnIPorez, nOsnOstaloZaBrutoOsnIPorez
   LOCAL nRadnikMinBrutoOsn
   LOCAL nRadnikBrutoOsnova
   
   LOCAL bIskljuciPrimanja := { | cTip | !Empty(cRekapTipoviOut) .AND. cTip $ cRekapTipoviOut }

   IF lRekapTO // rekapitulacija TO - samo primanja navedena u cRekaptTipoviOut, npr. "08,32"
      bIskljuciPrimanja := { | cTip | !Empty(cRekapTipoviOut) .AND. !(cTip $ cRekapTipoviOut) }
   ENDIF

   nIzbitiIzNeto := 0
   nIzbitiIzOstalo := 0

   nPorol := 0
   nRadnikBrutoOsnova := 0
   nRadn_bbo := 0
   nRadnikMinBrutoOsn := 0
   nPor := 0
   aNetoMj := {}
   
   DO WHILE !Eof() .AND. Eval( bUslovMjesecGodinaObracun ) // petlja radnik
   
      IF ld_vise_obracuna() .AND. Empty( cObracun )
         ScatterS( godina, mjesec, idrj, idradn )
      ELSE
         Scatter()
      ENDIF

      select_o_radn( _idradn )
      select_o_vposla( _idvposla )
      ld_pozicija_parobr( ld->mjesec, ld->godina, cObracun, ld->idrj )

      SELECT ld

      cTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

      // ------------------------- FILTERI -- START ----------
      // provjeri tip rada
      IF cTipRada $ ld_tiprada_list() .AND. Empty( cRTipRada )
         // ovo je u redu...
      ELSEIF ( cRTipRada <> cTipRada )
         SELECT ld
         SKIP 1
         LOOP
      ENDIF

      IF ( ( !Empty( cOpsSt ) .AND. cOpsSt <> radn->idopsst ) ) .OR. ( ( !Empty( cOpsRad ) .AND. cOpsRad <> radn->idopsrad ) )
         SELECT ld
         SKIP 1
         LOOP
      ENDIF

      IF ( IsRamaGlas() .AND. cK4 <> "S" )
         IF ( cK4 = "P" .AND. !radn->k4 = "P" .OR. cK4 = "N" .AND. radn->k4 = "P" )
            SELECT ld
            SKIP 1
            LOOP
         ENDIF
      ENDIF
      // ------------------------- FILTERI -- END ---------------

      nOsnNetoZaBrutoOsnIPorez := 0
      nOsnOstaloZaBrutoOsnIPorez := 0
      nRadnikLicniOdbitak := _ulicodb
      IF lRekapTO
         nRadnikLicniOdbitak := 0
      ENDIF
      nKoefLO := nRadnikLicniOdbitak

      cTrosk := radn->trosk
      lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad ) .AND. cTipRada $ "A#U"


      FOR i := 1 TO cLDPolja // prolazak po tipovima primanja - prvi put, calc:  nIzbitiIzNeto, nIzbitiIzOstalo

         cTprField := PadL( AllTrim( Str( i ) ), 2, "0" )
         select_o_tippr( cTprField )
         SELECT ld

         cTpr := "_I" + cTprField
         IF Eval(bIskljuciPrimanja, cTprField)
            // tip primanja npr. TO neoporezivi izbaciti
            IF tippr->uneto == "D"
              nIzbitiIzNeto += &cTpr
            ELSE
              nIzbitiIzOstalo += &cTpr
            ENDIF
            loop
         ENDIF

         IF &cTpr == 0
            LOOP
         ENDIF

         //IF tippr->( FieldPos( "TPR_TIP" ) ) <> 0 // polje tippr.tpr_tip postoji 
            IF tippr->tpr_tip == "N"
               nOsnNetoZaBrutoOsnIPorez += &cTpr

            ELSEIF tippr->tpr_tip == "2"
               nOsnOstaloZaBrutoOsnIPorez += &cTpr

            ELSEIF tippr->tpr_tip == " "
               IF tippr->uneto == "D"
                  nOsnNetoZaBrutoOsnIPorez += &cTpr

               ELSEIF tippr->uneto == "N"
                  nOsnOstaloZaBrutoOsnIPorez += &cTpr

               ENDIF
            ENDIF
         //ELSE
         //   IF tippr->uneto == "D"
         //      // osnovica ostalo
         //      nOsnNetoZaBrutoOsnIPorez += &cTpr
         //   ELSEIF tippr->uneto == "N"
         //      // osnovica ostalo
         //      nOsnOstaloZaBrutoOsnIPorez += &cTpr
         //   ENDIF
         //ENDIF
      NEXT // end prolazak po tipovima primanja - prvi put

      nOsnovaNeto := Max( _uneto - nIzbitiIzNeto, PAROBR->prosld * gPDLimit / 100 )

      nRSpr_koef := 0
      IF cTipRada == "S"
         nRSpr_koef := radn->sp_koef
      ENDIF

      // br.osn za radnika
      nRadnikBrutoOsnova := ld_get_bruto_osnova( nOsnNetoZaBrutoOsnIPorez, cTipRada, nKoefLO, nRSpr_koef, cTrosk )
      nTrosk := 0

      IF cTipRada $ "A#U"
         IF cTrosk <> "N"
            IF cTipRada == "A"
               nTrosk := gAHTrosk
            ELSEIF cTipRada == "U"
               nTrosk := gUgTrosk
            ENDIF
            // ako je u rs-u
            IF lInRS == .T.
               nTrosk := 0
            ENDIF
         ENDIF
      ENDIF

      // troskovi za ugovore i honorare
      nRTrosk := nRadnikBrutoOsnova * ( nTrosk / 100 )
      // ukupno bez troskova
      nUBBTrosk += nRadnikBrutoOsnova
      // ukupno troskovi
      nURTrosk += nRTrosk

      // troskove uzmi ako postoje, i to je osnovica
      nRadnikBrutoOsnova := nRadnikBrutoOsnova - nRTrosk

      IF cTipRada $ " #I#N"
         nRadnikMinBrutoOsn := nRadnikBrutoOsnova
         IF ld_calc_min_bruto_yes_no()
            // minimalna bruto osnova
            nRadnikMinBrutoOsn := ld_min_bruto_osnova( nRadnikBrutoOsnova, _usati )
         ENDIF
         // ukupno minimalna bruto osnova
         nUkRadnMinBrutoOsn += nRadnikMinBrutoOsn

      ELSE
         nRadnikMinBrutoOsn := nRadnikBrutoOsnova
         nUkRadnMinBrutoOsn += nRadnikBrutoOsnova
      ENDIF

      // ukupno bruto osnova
      nURadniciBrutoOsnova += nRadnikBrutoOsnova

      IF is_radn_k4_bf_ide_u_benef_osnovu()
         // beneficirani staz za radnika
         nRadn_bbo := ld_get_bruto_osnova( nOsnNetoZaBrutoOsnIPorez - if( !Empty( gBFForm ), &gBFForm, 0 ), cTipRada, nKoefLO, nRSpr_koef )
         nURadn_bbo += nRadn_bbo
         // upisi osnovicu...
         add_to_a_benef( @aBeneficirani, AllTrim( radn->k3 ), ld_beneficirani_stepen(), nRadn_bbo )
      ENDIF

      // da bi dobio osnovicu za poreze
      // moram vidjeti i koliko su doprinosi IZ
      nRadnikDoprinosiIz := ld_uk_doprinosi_iz( nRadnikMinBrutoOsn, cTipRada )

      IF lInRS == .T.
         nRadnikDoprinosiIz := 0
      ENDIF

      // ukupni doprinosi iz
      nUkRadnikDoprinosiIz += nRadnikDoprinosiIz
      // osnovica za poreze
      nRadnikPoreskaOsnova := ROUND2( ( nRadnikBrutoOsnova - nRadnikDoprinosiIz ) - nRadnikLicniOdbitak, gZaok2 )

      IF lInRS == .T.
         nRadnikPoreskaOsnova := 0
      ENDIF

      // ovo je total poreske osnove za radnika
      nPorOsnova := nRadnikPoreskaOsnova
      IF nPorOsnova < 0 .OR. !radn_oporeziv( ld->idradn, ld->idrj )
         nPorOsnova := 0
      ENDIF

      // ovo je total poreske osnove
      nUPorOsnova += nPorOsnova

      select_o_por()   // obradi poreze
      GO TOP

      nPor := 0
      nPorOl := 0
      DO WHILE !Eof() // petlja porezi

         cAlgoritam := ld_get_por_algoritam()
         ld_opstina_stanovanja_rada( POR->poopst )

         IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
            SKIP 1
            LOOP
         ENDIF
         IF por->por_tip == "B" // bruto
            aPor := ld_obr_por( por->id, nPorOsnova, 0 )
         ELSE
            aPor := ld_obr_por( por->id, nOsnNetoZaBrutoOsnIPorez, nOsnOstaloZaBrutoOsnIPorez )
         ENDIF

         // samo izracunaj total, ne ispisuj porez

         nTmpP := ld_ispis_poreza( aPor, cAlgoritam, "", .F. )
         IF nTmpP < 0
            nTmpP := 0
         ENDIF

         IF por->por_tip == "B" // bruto
            nPor += nTmpP
         ENDIF

         IF cAlgoritam == "S" // stepenasti obracun
            ld_popuni_ops_ld( cAlgoritam, por->id, aPor, nOsnovaNeto, nOsnNetoZaBrutoOsnIPorez, nOsnOstaloZaBrutoOsnIPorez, nRadnikMinBrutoOsn )
         ENDIF

         select_o_por()
         SKIP

      ENDDO // end petlja porezi

      // neto na ruke osnova
      // BRUTO - DOPR_IZ - POREZ
      nPorNROsnova := ROUND2 ( ( nRadnikBrutoOsnova - nRadnikDoprinosiIz ) - nPor, gZaok2 )
      // minimalna neto osnova
      nPorNrOsnova := min_neto( nPorNROsnova, _usati )

      IF cTipRada $ "A#U"
         // poreska osnova ugovori o djelu cine i troskovi
         nPorNROsnova += nRTrosk
      ENDIF

      IF lInRS == .T.
         nPorNROsnova := 0
      ENDIF

      nUPorNROsnova += nPorNROsnova
      nPom := AScan( aNeta, {| x | x[ 1 ] == vposla->idkbenef } )
      IF nPom == 0
         AAdd( aNeta, { vposla->idkbenef, nOsnovaNeto } )
      ELSE
         aNeta[ nPom, 2 ] += nOsnovaNeto
      ENDIF

      FOR i := 1 TO cLDPolja // prolazak po tipovima primanja - drugi put
         cPom := PadL( AllTrim( Str( i ) ), 2, "0" )
         IF Eval(bIskljuciPrimanja, cPom)
            // tip primanja npr. TO neoporezivi izbaciti
            loop
         ENDIF

         select_o_tippr( cPom )
         SELECT ld
         aRekap[ i, 1 ] += _S&cPom  // sati
         nIznos := _I&cPom
         aRekap[ i, 2 ] += nIznos  // iznos
         IF tippr->uneto == "N" .AND. nIznos <> 0
            IF nIznos > 0
               nUOstalaPrimanja += nIznos
            ELSE
               nUOstalaPrimanjaMinus += nIznos
            ENDIF
         ENDIF
      NEXT // end prolazak po tipovima primanja - drugi put radi nUOstalaPrimanja, nUOstalaPrimanjaMinus

      ++nLjudi

      nUSati += _USati  // ukupno sati
      nUNeto += _UNeto  // ukupno neto iznos
      nULOdbitak += nRadnikLicniOdbitak
      nUNetoOsnova += nOsnovaNeto // ukupno neto osnova

      IF is_radn_k4_bf_ide_u_benef_osnovu()
         nUBNOsnova += nOsnovaNeto - IIF( !Empty( gBFForm ), &gBFForm, 0 )
      ENDIF

      cTR := IIF( RADN->isplata $ "TR#SK", RADN->idbanka, Space( FIELD_LD_RADN_IDBANKA ) )

      IF Len( aUkTR ) > 0 .AND. ( nPomTR := AScan( aUkTr, {| x | x[ 1 ] == cTR } ) ) > 0
         aUkTR[ nPomTR, 2 ] += _uiznos
      ELSE
         AAdd( aUkTR, { cTR, _uiznos } )
      ENDIF

      nUIznos += _UIznos // ukupno iznos
      nUOdbici += _UOdbici  // ukupno odbici

      IF nMjesec <> nMjesecDo
         nPom := AScan( aNetoMj, {| x | x[ 1 ] == mjesec } )
         IF nPom > 0
            aNetoMj[ nPom, 2 ] += _uneto
            aNetoMj[ nPom, 3 ] += _usati
         ELSE
            nTObl := Select()
            nTRec := PAROBR->( RecNo() )
            ld_pozicija_parobr( mjesec, godina, IIF( ld_vise_obracuna(), cObracun, ), IIF( !lSveRj, cIdRj, ) )
            // samo pozicionira bazu PAROBR na odgovarajuCi zapis
            AAdd( aNetoMj, { mjesec, _uneto, _usati, PAROBR->k3, PAROBR->k1 } )
            SELECT PAROBR
            GO ( nTRec )
            SELECT ( nTObl )
         ENDIF
      ENDIF

      // napuni opsld sa ovim porezom
      ld_popuni_ops_ld( /*cTip*/, /*cPorId*/, /*aPorezi*/, nOsnovaNeto, nOsnNetoZaBrutoOsnIPorez, nOsnOstaloZaBrutoOsnIPorez, nRadnikMinBrutoOsn)

      IF RADN->isplata == "TR"  // radnik isplata na tekuci racun
         cOpis2 := RADNIK_PREZ_IME
         ld_rekap_ld( "IS_" + RADN->idbanka, nGodina, nMjesecDo, _UIznos - nIzbitiIzNeto - nIzbitiIzOstalo, 0, RADN->idbanka, RADN->brtekr, cOpis2, .T. )
      ENDIF

      SELECT ld
      SKIP
   ENDDO // end petlja radnik


   RETURN .T.


// ----------------------------------------------------------
// ispisuje i vraca bruto osnovicu za daljnji obracun
// ----------------------------------------------------------
STATIC FUNCTION ld_say_bruto( nIznos )

   //nBO := nIznos

   ? cMainLine
   IF cRTiprada $ "A#U"
      ? _l( "1. BRUTO PLATA (bruto sa troskovima - troskovi):" )
   ELSE
      ? _l( "1. BRUTO PLATA UKUPNO:" )
   ENDIF
   @ PRow(), 60 SAY nIznos PICT gpici
   ? cMainLine

   RETURN .T.
