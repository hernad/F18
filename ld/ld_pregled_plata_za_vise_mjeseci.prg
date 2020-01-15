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

MEMVAR GetList

FUNCTION ld_pregled_plata_za_period()

   LOCAL nC1 := 20
   LOCAL i
   LOCAL cTPNaz
   LOCAL cRj := Space( 60 )
   LOCAL cRadnik := fetch_metric( "ld_izvj_radnik", my_user(), Space( LEN_IDRADNIK ) )
   LOCAL cIdRj
   LOCAL nMjesec
   LOCAL cMjesecDo
   LOCAL nGodina
   LOCAL cIdOpcinaStanUslov := Space( 100 )
   LOCAL cKanton := Space( 100 )
   LOCAL cDoprPio := "70"
   LOCAL cDoprZdr := "80"
   LOCAL cDoprNez := "90"
   LOCAL cDoprD4 := Space( 2 )
   LOCAL cDoprD5 := Space( 2 )
   LOCAL cDoprD6 := Space( 2 )
   LOCAL cObracun := gObracun
   LOCAL cM4TipoviIzdvojitiPrimanja := fetch_metric( "ld_m4_izdvojena_primanja", NIL, Space( 100 ) )
   LOCAL nCount
   LOCAL lUkupnoZaRadnika := .T.

   napravi_pomocnu_tabelu()

   cIdRj := gLDRadnaJedinica
   nMjesec := fetch_metric( "ld_izv_mjesec_od", my_user(), ld_tekuci_mjesec() )
   nGodina := fetch_metric( "ld_izv_godina", my_user(), ld_tekuca_godina() )
   cMjesecDo := fetch_metric( "ld_izv_mjesec_do", my_user(), nMjesec )

   otvori_tabele()

   Box( "#PREGLED PLATA ZA PERIOD", 20, 75 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radne jedinice: " GET cRj PICT "@!S25"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Za mjesece od:" GET nMjesec PICT "99"
   @ box_x_koord() + 2, Col() + 2 SAY "do:" GET cMjesecDo PICT "99" VALID cMjesecDo >= nMjesec
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Godina: " GET nGodina PICT "9999"

   IF ld_vise_obracuna()
      @ box_x_koord() + 3, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   ENDIF

   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Radnik (prazno-svi radnici): " GET cRadnik ;
      VALID Empty( cRadnik ) .OR. P_RADN( @cRadnik )

   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Općina stanovanja (prazno-sve):" GET cIdOpcinaStanUslov PICT "@S30" WHEN Empty( cRadnik )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "           Kanton (prazno-sve):" GET cKanton PICT "@S30" WHEN Empty( cRadnik )

   @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Dodatni doprinosi za prikaz na izvještaju: "
   @ box_x_koord() + 10, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 1 : " GET cDoprPio
   @ box_x_koord() + 11, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 2 : " GET cDoprZdr
   @ box_x_koord() + 12, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 3 : " GET cDoprNez
   @ box_x_koord() + 13, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 4 : " GET cDoprD4
   @ box_x_koord() + 14, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 5 : " GET cDoprD5
   @ box_x_koord() + 15, box_y_koord() + 2 SAY8 " Šifra dodatnog doprinosa 6 : " GET cDoprD6

   @ box_x_koord() + 17, box_y_koord() + 2 SAY8 "Izdvojena primanja (bolovanje, neplaceno):" GET cM4TipoviIzdvojitiPrimanja PICT "@S20"

   // @ box_x_koord() + 19, box_y_koord() + 2 SAY8 "Prikazati ukupno za sve mjesece (D/N)" GET cTotal PICT "@!" VALID cTotal $ "DN"

   READ

   IF !Empty( cRadnik ) // za jednog radnika prikazati odvojeno po mjesecima
      lUkupnoZaRadnika := .F.
   ENDIF

   clvbox()

   ESC_BCR

   BoxC()


   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   set_metric( "ld_izvj_radnik", my_user(), cRadnik )
   set_metric( "ld_m4_izdvojena_primanja", NIL, cM4TipoviIzdvojitiPrimanja )
   set_metric( "ld_izv_mjesec_od", my_user(), nMjesec )
   set_metric( "ld_izv_godina", my_user(), nGodina )
   set_metric( "ld_izv_mjesec_do", my_user(), cMjesecDo )

   seek_pa_sortiraj_tabelu_ld( cRj, nGodina, nMjesec, cMjesecDo, cRadnik, cObracun )

   napuni_podatke( cRj, nGodina, nMjesec, cMjesecDo, cRadnik, ;
      cDoprPio, cDoprZdr, cDoprNez, cObracun, cDoprD4, cDoprD5, cDoprD6, ;
      cM4TipoviIzdvojitiPrimanja, lUkupnoZaRadnika, cIdOpcinaStanUslov, cKanton )


   prikazi_pregled( cRj, nGodina, nMjesec, cMjesecDo, cRadnik, ;
      cDoprPio, cDoprZdr, cDoprNez, cDoprD4, cDoprD5, cDoprD6, cIdOpcinaStanUslov, cKanton )

   RETURN .T.


STATIC FUNCTION napuni_podatke( cRj, nGodina, nMjesec, cMjesecDo, ;
      cRadnik, cDoprPio, cDoprZdr, cDoprNez, cObracun, cDop4, cDop5, cDop6, ;
      cM4TipoviIzdvojitiPrimanja, lUkupnoZaRadnika, cIdOpcinaStanUslov, cKanton )

   LOCAL i
   LOCAL cPom
   LOCAL lInRS := .F.
   LOCAL nNetoBP := 0
   LOCAL nUNetobp := 0
   LOCAL nPrimanje
   LOCAL nRadSatiM4
   LOCAL nRadIznosM4
   LOCAL nIzdvojenaPrimanjaSatiM4
   LOCAL nIzdvojenaPrimanjaIznosM4
   LOCAL nF_mj, nF_god
   LOCAL nSati, nR_sati, nB_sati, nNeto, nR_net, nB_neto
   LOCAL nR_neto
   LOCAL nUNeto
   LOCAL nPrim
   LOCAL nBruto
   LOCAL nUDopIz
   LOCAL nIDoprPio
   LOCAL nIDoprZdr
   LOCAL nIDoprNez
   LOCAL nIDoprD4
   LOCAL nIDoprD5
   LOCAL nIDoprD6
   LOCAL nOdbici
   LOCAL nL_odb
   LOCAL nPorez
   LOCAL nIsplata
   LOCAL nURad_izn
   LOCAL nUBol_izn
   LOCAL nUkRadnihSati
   LOCAL nUkIzdvojenaPrimanjaSati
   LOCAL bNulirajVarijable
   LOCAL nLOdbitak
   LOCAL aPrimanja

   bNulirajVarijable := {|| ;
      nSati := 0, ;
      nR_sati := 0, ;
      nB_sati := 0, ;
      nNeto := 0, ;
      nB_neto := 0, ;
      nR_neto := 0, ;
      nUNeto := 0, ;
      nPrim := 0, ;
      nBruto := 0, ;
      nUDopIz := 0, ;
      nIDoprPio := 0, ;
      nIDoprZdr := 0, ;
      nIDoprNez := 0, ;
      nIDoprD4 := 0, ;
      nIDoprD5 := 0, ;
      nIDoprD6 := 0, ;
      nOdbici := 0, ;
      nL_odb := 0, ;
      nPorez := 0, ;
      nIsplata := 0, ;
      nUNetobp := 0, ;
      nRadSatiM4 := 0, ;
      nRadIznosM4 := 0, ;
      nIzdvojenaPrimanjaSatiM4 := 0, ;
      nIzdvojenaPrimanjaIznosM4 := 0, ;
      nURad_izn := 0, ;
      nUBol_izn := 0, ;
      nUkRadnihSati := 0, ;
      nUkIzdvojenaPrimanjaSati := 0  }


   SELECT ld

   DO WHILE !Eof()


      IF !pripada_opcina_kanton( ld->idradn, cIdOpcinaStanUslov, cKanton )
         SKIP
         LOOP
      ENDIF

      IF ld_godina_mjesec_string( field->godina, field->mjesec ) < ld_godina_mjesec_string( nGodina, nMjesec )
         SKIP
         LOOP
      ENDIF

      IF ld_godina_mjesec_string( field->godina, field->mjesec ) >  ld_godina_mjesec_string( nGodina, cMjesecdo )
         SKIP
         LOOP
      ENDIF

      cIdRadnikTekuci := field->idradn

      lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad )

      IF !Empty( cRadnik )
         IF cIdRadnikTekuci <> cRadnik
            SKIP
            LOOP
         ENDIF
      ENDIF

      cTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )
      cOpor := g_oporeziv( ld->idradn, ld->idrj )

      ld_pozicija_parobr( ld->mjesec, ld->godina, IIF( ld_vise_obracuna(), ld->obr, ), ld->idrj )

      select_o_radn( cIdRadnikTekuci )

      cT_rnaziv := AllTrim( radn->ime ) + " " + AllTrim( radn->naz )

      SELECT ld


      Eval( bNulirajVarijable )


      DO WHILE !Eof() .AND. ld->idradn == cIdRadnikTekuci

         IF !pripada_opcina_kanton( ld->idradn, cIdOpcinaStanUslov, cKanton )
            SKIP
            LOOP
         ENDIF

         IF ld_godina_mjesec_string( field->godina, field->mjesec ) < ld_godina_mjesec_string( nGodina, nMjesec )
            SKIP
            LOOP
         ENDIF

         IF ld_godina_mjesec_string( field->godina, field->mjesec ) >  ld_godina_mjesec_string( nGodina, cMjesecdo )
            SKIP
            LOOP
         ENDIF

         nF_mj := field->mjesec
         nF_god := field->godina
         cId_rj := ld->idrj
         cObr_za := AllTrim( Str( ld->mjesec, 2, 0 ) ) + "/" + AllTrim( Str( ld->godina, 4, 0 ) )

         cTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj ) // uvijek provjeri tip rada, ako ima vise obracuna
         cTrosk := radn->trosk

         ld_pozicija_parobr( ld->mjesec, ld->godina, iif( ld_vise_obracuna(), ld->obr, ), ld->idrj )

         nPrKoef := 0


         IF cTipRada == "S" // propisani koeficijent
            nPrKoef := radn->sp_koef
         ENDIF


         //nIzdvojenaPrimanjaIznosM4 := 0 // bolovanje iznosi, sati
         //nIzdvojenaPrimanjaSatiM4 := 0

         nRadIznosM4 := 0 // redovan rad iznos, sati
         nRadSatiM4 := 0

         DO WHILE !Eof() .AND. ld->idradn == cIdRadnikTekuci .AND. ld->mjesec == nF_mj .AND. ld->godina == nF_god

            aPrimanja := sum_primanja_za_tipove_primanja( cM4TipoviIzdvojitiPrimanja )
            nIzdvojenaPrimanjaSatiM4 := aPrimanja[ 1 ]
            nIzdvojenaPrimanjaIznosM4 := aPrimanja[ 2 ]


            nPrim += field->uneto // primanja
            nOdbici += field->uodbici // odbici
            nSati += field->usati
            nIsplata += field->uiznos // isplata
            nLOdbitak := field->ulicodb // licni odbitak
            nL_odb += nLOdbitak


            IF ( nIzdvojenaPrimanjaIznosM4 != 0 ) .OR. ( nIzdvojenaPrimanjaSatiM4 != 0 )  // radni sati ukupni
               nRadSatiM4 := ( field->usati - nIzdvojenaPrimanjaSatiM4 )
               nRadIznosM4 := ( field->uneto - nIzdvojenaPrimanjaIznosM4 )
            ELSE
               nRadSatiM4 := ( field->usati )
               nRadIznosM4 := ( field->uneto )
            ENDIF

            nUkRadnihSati += nRadSatiM4 // totali za izdvojena primanja i radne sate
            nUkIzdvojenaPrimanjaSati += nIzdvojenaPrimanjaSatiM4


            nBrutoST := ld_get_bruto_osnova( ld->uneto, cTipRada, ld->ulicodb, nPrKoef, cTrosk ) // bruto sa troskovima
            nBr_bol := ld_get_bruto_osnova( nIzdvojenaPrimanjaIznosM4, cTipRada, ld->ulicodb, nPrKoef, cTrosk ) // bruto bolovanja
            nBr_rad := ld_get_bruto_osnova( nRadIznosM4, cTipRada, ld->ulicodb, nPrKoef, cTrosk )  // bruto rada

            nTrosk := 0


            IF cTipRada == "U" .AND. cTrosk <> "N" // ugovori o djelu

               nTrosk := ROUND2( nBrutoST * ( gUgTrosk / 100 ), gZaok2 )

               IF lInRs == .T.
                  nTrosk := 0
               ENDIF

            ENDIF


            IF cTipRada == "A" .AND. cTrosk <> "N" // autorski honorar

               nTrosk := ROUND2( nBrutoST * ( gAhTrosk / 100 ), gZaok2 )

               IF lInRs == .T.
                  nTrosk := 0
               ENDIF
            ENDIF

            nBrPoj := nBrutoST - nTrosk // bruto pojedinacno za radnika

            nMBrutoST := nBrPoj

            IF calc_mbruto() // minimalni bruto
               nMBrutoST := min_bruto( nBrPoj, ld->usati )
            ENDIF

            nBruto += nBrPoj // ukupni bruto


            nDoprIz := u_dopr_iz( nMBrutoST, cTipRada ) // ukupno dopr iz 31%
            nUDopIz += nDoprIz


            nDop_rad := u_dopr_iz( nBr_rad, cTipRada ) // doprinos za bol i rad
            nDop_bol := u_dopr_iz( nBr_bol, cTipRada )

            nURad_izn += ( nBr_rad - nDop_rad )
            nUBol_izn += ( nBr_bol - nDop_bol )


            nPorOsnP := ( nBrPoj - nDoprIz ) - nLOdbitak // osnovica za porez

            IF nPorOsnP < 0 .OR. !radn_oporeziv( ld->idradn, ld->idrj )
               nPorOsnP := 0
            ENDIF


            nPorPoj := izr_porez( nPorOsnP, "B" ) // porez je
            nPorez += nPorPoj


            nNetoBp := ( nBrPoj - nDoprIz ) // neto bez poreza
            nNeto := ( nBrPoj - nDoprIz - nPorPoj ) // neto isplata
            nNeto := min_neto( nNeto, ld->usati )  // minimalni neto uslov

            nUNeto += nNeto
            nUNetobp += nNetoBp


            IF !Empty( cDoprPio ) // ocitaj_izbaci doprinose, njihove iznose
               nDoprPIO := get_dopr( cDoprPIO, cTipRada )
               nIDoprPIO += round2( nMBrutoST * nDoprPIO / 100, gZaok2 )
            ENDIF

            IF !Empty( cDoprZdr )
               nDoprZDR := get_dopr( cDoprZDR, cTipRada )
               nIDoprZDR += round2( nMBrutoST * nDoprZDR / 100, gZaok2 )
            ENDIF

            IF !Empty( cDoprNez )
               nDoprNEZ := get_dopr( cDoprNEZ, cTipRada )
               nIDoprNEZ += round2( nMBrutoST * nDoprNEZ / 100, gZaok2 )
            ENDIF

            IF !Empty( cDop4 )
               nDoprD4 := get_dopr( cDop4, cTipRada )
               nIDoprD4 += round2( nMBrutoST * nDoprD4 / 100, gZaok2 )
            ENDIF
            IF !Empty( cDop4 )
               nDoprD5 := get_dopr( cDop5, cTipRada )
               nIDoprD5 += round2( nMBrutoST * nDoprD5 / 100, gZaok2 )
            ENDIF
            IF !Empty( cDop4 )
               nDoprD6 := get_dopr( cDop6, cTipRada )
               nIDoprD6 += round2( nMBrutoST * nDoprD6 / 100, gZaok2 )
            ENDIF


            SELECT ld
            SKIP

         ENDDO // godina, mjesec

         IF !lUkupnoZaRadnika
            dodaj_u_pomocnu_tabelu( nF_god, ;
               nF_mj, ;
               cIdRadnikTekuci, ;
               cId_rj, ;
               cObr_za, ;
               cT_rnaziv, ;
               nSati, ;
               nUkRadnihSati, ;
               nUkIzdvojenaPrimanjaSati, ;
               nPrim, ;
               nBruto, ;
               nUDopIZ, ;
               nIDoprPIO, ;
               nIDoprZDR, ;
               nIDoprNEZ, ;
               0, ;
               nL_Odb, ;
               nPorez, ;
               nUNetobp, ;
               nUNeto, ;
               nURad_izn, ;
               nUBol_izn, ;
               nOdbici, ;
               nIsplata, ;
               nIDoprD4, ;
               nIDoprD5, ;
               nIDoprD6 )
            Eval( bNulirajVarijable )
         ENDIF

      ENDDO // radnik


      IF lUkupnoZaRadnika
         dodaj_u_pomocnu_tabelu( nF_god, ;
            nF_mj, ;
            cIdRadnikTekuci, ;
            cId_rj, ;
            cObr_za, ;
            cT_rnaziv, ;
            nSati, ;
            nUkRadnihSati, ;
            nUkIzdvojenaPrimanjaSati, ;
            nPrim, ;
            nBruto, ;
            nUDopIZ, ;
            nIDoprPIO, ;
            nIDoprZDR, ;
            nIDoprNEZ, ;
            0, ;
            nL_Odb, ;
            nPorez, ;
            nUNetobp, ;
            nUNeto, ;
            nURad_izn, ;
            nUBol_izn, ;
            nOdbici, ;
            nIsplata, ;
            nIDoprD4, ;
            nIDoprD5, ;
            nIDoprD6 )

      ENDIF



   ENDDO

   RETURN .T.


FUNCTION sum_primanja_za_tipove_primanja( cM4TipoviIzdvojitiPrimanja )

   LOCAL nPrimanje, cPom, aPrimanja := { 0, 0 }

   IF !Empty( cM4TipoviIzdvojitiPrimanja )
      FOR nPrimanje := 1 TO 60
         cPom := PadL( AllTrim( Str( nPrimanje ) ), 2, "0" )
         IF cPom $ cM4TipoviIzdvojitiPrimanja .AND. ( ld->( FieldPos( "I" + cPom ) ) != 0 )
            aPrimanja[ 1 ] += iif( cPom $ cM4TipoviIzdvojitiPrimanja, LD->&( "S" + cPom ), 0 )
            aPrimanja[ 2 ] += iif( cPom $ cM4TipoviIzdvojitiPrimanja, LD->&( "I" + cPom ), 0 )
         ENDIF
      NEXT
   ENDIF

   RETURN aPrimanja


STATIC FUNCTION prikazi_pregled( cRj, nGodina, cMjOd, cMjDo, cRadnik, ;
      cDop1, cDop2, cDop3, cDop4, cDop5, cDop6, cIdOpcinaStanUslov, cKanton )

   LOCAL cIdRadnikTekuci := ""
   LOCAL cLine := ""
   LOCAL nUSati := 0
   LOCAL nUNeto := 0
   LOCAL nUNetoBP := 0
   LOCAL nUPrim := 0
   LOCAL nUBruto := 0
   LOCAL nUDoprPio := 0
   LOCAL nUDoprZdr := 0
   LOCAL nUDoprNez := 0
   LOCAL nUDoprD4 := 0
   LOCAL nUDoprD5 := 0
   LOCAL nUDoprD6 := 0
   LOCAL nUDoprIZ := 0
   LOCAL nUPorez := 0
   LOCAL nUOdbici := 0
   LOCAL nULicOdb := 0
   LOCAL nUIsplata := 0
   LOCAL nUkRadnihSati := 0
   LOCAL nUkRadIznos := 0
   LOCAL nUkIzdvojenaPrimanjaSati := 0
   LOCAL nUkIzdvojenaPrimanjaIznos := 0
   LOCAL nRbr := 0
   LOCAL nPoc := 10
   LOCAL nCount := 0
   LOCAL nNBP_pt


   o_r_export()
   SELECT r_export
   GO TOP

   START PRINT CRET
   ?
   ? "#%LANDS#"
   P_COND2

   pregled_zaglavlje( cRj, nGodina, cMjOd, cMjDo, cRadnik, cIdOpcinaStanUslov, cKanton )

   cLine := pregled_header( cRadnik, cDop1, cDop2, cDop3, cDop4, cDop5, cDop6 )

   nUSati := 0
   nUNeto := 0
   nUNetoBP := 0
   nUPrim := 0
   nUBruto := 0
   nUDoprPio := 0
   nUDoprZdr := 0
   nUDoprNez := 0
   nUDoprD4 := 0
   nUDoprD5 := 0
   nUDoprD6 := 0
   nUDoprIZ := 0
   nUPorez := 0
   nUOdbici := 0
   nULicOdb := 0
   nUIsplata := 0
   nUkRadnihSati := 0
   nUkRadIznos := 0
   nUkIzdvojenaPrimanjaSati := 0
   nUkIzdvojenaPrimanjaIznos := 0


   nRbr := 0
   nPoc := 10
   nCount := 0

   DO WHILE !Eof()

      ? Str( ++nRbr, 4 ) + "."

      IF !Empty( cRadnik )
         @ PRow(), PCol() + 1 SAY PadR( field->obr_za, 7 )
      ELSE
         @ PRow(), PCol() + 1 SAY PadR( field->idradn, 7 )
      ENDIF

      @ PRow(), PCol() + 1 SAY field->naziv

      @ PRow(), nPoc := PCol() + 1 SAY Str( field->sati, 12, 2 )
      nUSati += field->sati

      @ PRow(), PCol() + 1 SAY Str( field->prim, 12, 2 )
      nUPrim += field->prim

      @ PRow(), PCol() + 1 SAY Str( field->bruto, 12, 2 )
      nUBruto += field->bruto

      @ PRow(), PCol() + 1 SAY Str( field->dop_iz, 12, 2 )
      nUDoprIz += field->dop_iz

      @ PRow(), PCol() + 1 SAY Str( field->l_odb, 12, 2 )
      nULicOdb += field->l_odb

      @ PRow(), PCol() + 1 SAY Str( field->izn_por, 12, 2 )
      nUPorez += field->izn_por

      @ PRow(), nNBP_pt := PCol() + 1 SAY Str( field->netobp, 12, 2 )
      nUNetobp += field->netobp

      @ PRow(), PCol() + 1 SAY Str( field->neto, 12, 2 )
      nUNeto += field->neto

      @ PRow(), PCol() + 1 SAY Str( field->odbici, 12, 2 )
      nUOdbici += field->odbici

      @ PRow(), PCol() + 1 SAY Str( field->isplata, 12, 2 )
      nUIsplata += field->isplata

      IF !Empty( cDop1 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_pio, 12, 2 )
         nUDoprPio += field->dop_pio
      ENDIF

      IF !Empty( cDop2 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_zdr, 12, 2 )
         nUDoprZdr += field->dop_zdr
      ENDIF

      IF !Empty( cDop3 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_nez, 12, 2 )
         nUDoprNez += field->dop_nez
      ENDIF

      IF !Empty( cDop4 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_4, 12, 2 )
         nUDoprD4 += field->dop_4
      ENDIF

      IF !Empty( cDop5 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_5, 12, 2 )
         nUDoprD5 += field->dop_5
      ENDIF

      IF !Empty( cDop6 )
         @ PRow(), PCol() + 1 SAY Str( field->dop_6, 12, 2 )
         nUDoprD6 += field->dop_6
      ENDIF

      IF ( field->b_neto != 0 .OR. field->b_sati != 0 ) // ovo je za drugi red izvjestaja, redovan rad
         ?
         @ PRow(), nPoc - 3 SAY "r: " + Str( field->r_sati, 12, 2 )
         @ PRow(), nNBP_pt SAY Str( field->r_neto, 12, 2 )

         nUkRadnihSati += field->r_sati
         nUkRadIznos += field->r_neto


         ?
         @ PRow(), nPoc - 3 SAY "i: " + Str( field->b_sati, 12, 2 ) // bolovanja
         @ PRow(), nNBP_pt SAY Str( field->b_neto, 12, 2 )

         nUkIzdvojenaPrimanjaSati += field->b_sati
         nUkIzdvojenaPrimanjaIznos += field->b_neto

      ELSE
         nUkRadnihSati += field->sati
         nUkRadIznos += field->netobp
      ENDIF

      ++nCount

      SKIP
   ENDDO

   ? cLine

   ? "UKUPNO:"
   @ PRow(), nPoc SAY Str( nUSati, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUPrim, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUBruto, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUDoprIz, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nULicOdb, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUPorez, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUNetoBP, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUNeto, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUOdbici, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nUIsplata, 12, 2 )

   IF !Empty( cDop1 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprPio, 12, 2 )
   ENDIF

   IF !Empty( cDop2 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprZdr, 12, 2 )
   ENDIF

   IF !Empty( cDop3 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprNez, 12, 2 )
   ENDIF

   IF !Empty( cDop4 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprD4, 12, 2 )
   ENDIF

   IF !Empty( cDop5 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprD5, 12, 2 )
   ENDIF

   IF !Empty( cDop6 )
      @ PRow(), PCol() + 1 SAY Str( nUDoprD6, 12, 2 )
   ENDIF


   IF ( nUkIzdvojenaPrimanjaIznos <> 0 ) // ako ima izdvojenih primanja

      // redovan rad
      ?
      @ PRow(), nPoc - 3 SAY "r: " + Str( nUkRadnihSati, 12, 2 )
      @ PRow(), nNBP_pt SAY Str( nUkRadIznos, 12, 2 )

      // izdvojena primanja
      ?
      @ PRow(), nPoc - 3 SAY "i: " + Str( nUkIzdvojenaPrimanjaSati, 12, 2 )
      @ PRow(), nNBP_pt SAY Str( nUkIzdvojenaPrimanjaIznos, 12, 2 )

   ENDIF

   ? cLine

   FF
   ENDPRINT

   RETURN .T.




STATIC FUNCTION pregled_header( cRadnik, cDop1, cDop2, cDop3, cDop4, cDop5, cDop6 )

   LOCAL aLines := {}
   LOCAL aTxt := {}
   LOCAL i
   LOCAL cLine := ""
   LOCAL cTxt1 := ""
   LOCAL cTxt2 := ""
   LOCAL cTxt3 := ""
   LOCAL cTxt4 := ""
   LOCAL nTxtLen

   AAdd( aLines, { Replicate( "-", 5 ) } )
   AAdd( aLines, { Replicate( "-", 7 ) } )
   AAdd( aLines, { Replicate( "-", 20 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )
   AAdd( aLines, { Replicate( "-", 12 ) } )

   IF !Empty( cDop1 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   IF !Empty( cDop2 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   IF !Empty( cDop3 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   IF !Empty( cDop4 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   IF !Empty( cDop5 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF
   IF !Empty( cDop6 )
      AAdd( aLines, { Replicate( "-", 12 ) } )
   ENDIF

   AAdd( aTxt, { "Red.", "br", "", "1" } )
   IF !Empty( cRadnik )
      AAdd( aTxt, { "Obr.", "za mj", "", "2" } )
   ELSE
      AAdd( aTxt, { "Šifra", "radn.", "", "2" } )
   ENDIF
   AAdd( aTxt, { "Naziv", "radnika", "", "3" } )
   AAdd( aTxt, { "Sati", "", "", "4" } )
   AAdd( aTxt, { "Primanja", "", "", "5" } )
   AAdd( aTxt, { "Bruto plata", "(5 x koef.)", "", "6" } )
   AAdd( aTxt, { "Doprinos", "iz plaće", "( 31% )", "7" } )
   AAdd( aTxt, { "Lični odbici", "", "", "8" } )
   AAdd( aTxt, { "Porez", "na dohodak", "10%", "9" } )
   AAdd( aTxt, { "Neto", "plata", "(6-7)", "10" } )
   AAdd( aTxt, { "Na", "ruke", "(6-7-9)", "11" } )
   AAdd( aTxt, { "Odbici", "", "", "12" } )
   AAdd( aTxt, { "Za isplatu", "", "(11+12)", "13" } )
   IF !Empty( cDop1 )
      AAdd( aTxt, { "Doprinos", "1", procenat_doprinosa( cDop1 ), "14" } )
   ENDIF
   IF !Empty( cDop2 )
      AAdd( aTxt, { "Doprinos", "2", procenat_doprinosa( cDop2 ), "15" } )
   ENDIF
   IF !Empty( cDop3 )
      AAdd( aTxt, { "Doprinos", "3", procenat_doprinosa( cDop3 ), "16" } )
   ENDIF
   IF !Empty( cDop4 )
      AAdd( aTxt, { "Doprinos", "4", procenat_doprinosa( cDop4 ), "17" } )
   ENDIF
   IF !Empty( cDop5 )
      AAdd( aTxt, { "Doprinos", "5", procenat_doprinosa( cDop5 ), "18" } )
   ENDIF
   IF !Empty( cDop6 )
      AAdd( aTxt, { "Doprinos", "6", procenat_doprinosa( cDop6 ), "19" } )
   ENDIF

   FOR i := 1 TO Len( aLines )
      cLine += aLines[ i, 1 ] + Space( 1 )
   NEXT

   FOR i := 1 TO Len( aTxt )
      nTxtLen := Len( aLines[ i, 1 ] )
      cTxt1 += PadC( "(" + aTxt[ i, 4 ] + ")", nTxtLen ) + Space( 1 )
      cTxt2 += PadC( aTxt[ i, 1 ], nTxtLen ) + Space( 1 )
      cTxt3 += PadC( aTxt[ i, 2 ], nTxtLen ) + Space( 1 )
      cTxt4 += PadC( aTxt[ i, 3 ], nTxtLen ) + Space( 1 )
   NEXT

   ?U cLine
   ?U cTxt1
   ?U cTxt2
   ?U cTxt3
   ?U cTxt4
   ?U cLine

   RETURN cLine



STATIC FUNCTION procenat_doprinosa( cDop )

   LOCAL cProc := ""
   LOCAL nTmp
   LOCAL nTArea := Select()

   nTmp := get_dopr( cDop, " " ) // daj za tip rada " "

   IF nTmp <> 0
      cProc := AllTrim( Str( nTmp ) ) + " %"
   ENDIF

   SELECT ( nTArea )

   RETURN cProc


STATIC FUNCTION pregled_zaglavlje( cRj, nGodina, cMjOd, cMjDo, cRadnik, cIdOpcinaStanUslov, cKanton )

   ? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?

   IF Empty( cRj )
      ? "Pregled za sve RJ:"
   ELSE
      ?  "RJ:", cRj
   ENDIF

   IF !Empty( cIdOpcinaStanUslov )
      ?U "Općina stanovanja:", AllTrim( cIdOpcinaStanUslov )
   ENDIF

   IF !Empty( cKanton )
      ?U "Kanton:", AllTrim( cKanton )
   ENDIF

   ?? Space( 2 ) + "Mjesec od:", Str( cMjOd, 2 ), "do:", Str( cMjDo, 2 )
   ?? Space( 4 ) + "Godina:", Str( nGodina, 5 )

   IF !Empty( cRadnik )
      ? "Radnik: " + cRadnik
   ENDIF

   RETURN .T.



STATIC FUNCTION pripada_opcina_kanton( cIdRadnik, cIdOpcinaStanUslov, cIdKanton )

   LOCAL nTArea := Select()
   LOCAL lOk := .T.

   select_o_radn( cIdRadnik )

   IF !Empty( cIdOpcinaStanUslov ) .AND. !( radn->idopsst $ cIdOpcinaStanUslov )
      lOk := .F.
   ENDIF

   IF !Empty( cIdKanton )

      select_o_ops( radn->idopsst )
      IF !( ops->idkan $ cIdKanton )
         lOk := .F.
      ENDIF

   ENDIF

   SELECT ( nTArea )

   RETURN lOk





STATIC FUNCTION seek_pa_sortiraj_tabelu_ld( cRj, nGodina, nMjesec, cMjesecDo, cRadnik, cObr )

   LOCAL cFilter := ""
   //PRIVATE cObracun := cObr

   seek_ld( NIL, nGodina, NIL, NIL, cRadnik )

   IF !Empty( cObr )
      cFilter += "obr == " + _filter_quote( cObr )
   ENDIF

   IF !Empty( cRj )

      IF !Empty( cFilter )
         cFilter += " .and. "
      ENDIF

      cFilter += Parsiraj( cRj, "IDRJ" )

   ENDIF

   IF !Empty( cFilter )
      SET FILTER TO &cFilter
      GO TOP
   ENDIF

   IF Empty( cRadnik )
      INDEX ON Str( godina, 4, 0 ) + SortPrez( idradn ) + Str( mjesec, 2, 0 ) + idrj TO "tmpld"
      // GO TOP
      // SEEK Str( nGodina, 4 )
   ELSE
      SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
      // GO TOP
      // SEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) + cObracun + cRadnik
   ENDIF
   GO TOP

   RETURN .T.


STATIC FUNCTION dodaj_u_pomocnu_tabelu( nGodina, nMjesec, cRadnik, cIdRj, cObrZa, cIme, ;
      nSati, nR_sati, ;
      nB_sati, nPrim, nBruto, nDoprIz, nDopPio, ;
      nDopZdr, nDopNez, nOporDoh, nLOdb, nPorez, nNetoBp, nNeto, ;
      nR_neto, nB_neto, nOdbici, nIsplata, nDop4, nDop5, nDop6 )

   LOCAL nTArea := Select()

   o_r_export()
   SELECT r_export
   APPEND BLANK

   REPLACE godina WITH nGodina
   REPLACE mjesec WITH nMjesec
   REPLACE idrj WITH cIdRj
   REPLACE idradn WITH cRadnik
   REPLACE obr_za WITH cObrZa
   REPLACE naziv WITH cIme
   REPLACE sati WITH nSati
   REPLACE b_sati WITH nB_Sati
   REPLACE r_sati WITH nR_Sati
   REPLACE neto WITH nNeto
   REPLACE b_neto WITH nB_Neto
   REPLACE r_neto WITH nR_Neto
   REPLACE netobp WITH nNetoBp
   REPLACE prim WITH nPrim
   REPLACE bruto WITH nBruto
   REPLACE dop_iz WITH nDoprIz
   REPLACE dop_pio WITH nDopPio
   REPLACE dop_zdr WITH nDopZdr
   REPLACE dop_nez WITH nDopNez
   REPLACE dop_4 WITH nDop4
   REPLACE dop_5 WITH nDop5
   REPLACE dop_6 WITH nDop6
   REPLACE l_odb WITH nLOdb
   REPLACE izn_por WITH nPorez
   REPLACE opordoh WITH nOporDoh
   REPLACE odbici WITH nOdbici
   REPLACE isplata WITH nIsplata

   SELECT ( nTArea )

   RETURN .T.



STATIC FUNCTION napravi_pomocnu_tabelu()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IDRJ", "C", 2, 0 } )
   AAdd( aDbf, { "GODINA", "N", 4, 0 } )
   AAdd( aDbf, { "MJESEC", "N", 2, 0 } )
   AAdd( aDbf, { "IDRADN", "C", 6, 0 } )
   AAdd( aDbf, { "OBR_ZA", "C", 15, 0 } )
   AAdd( aDbf, { "NAZIV", "C", 20, 0 } )
   AAdd( aDbf, { "SATI", "N", 12, 2 } )
   AAdd( aDbf, { "R_SATI", "N", 12, 2 } )
   AAdd( aDbf, { "B_SATI", "N", 12, 2 } )
   AAdd( aDbf, { "PRIM", "N", 12, 2 } )
   AAdd( aDbf, { "NETO", "N", 12, 2 } )
   AAdd( aDbf, { "R_NETO", "N", 12, 2 } )
   AAdd( aDbf, { "B_NETO", "N", 12, 2 } )
   AAdd( aDbf, { "NETOBP", "N", 12, 2 } )
   AAdd( aDbf, { "BRUTO", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_IZ", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_PIO", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_ZDR", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_NEZ", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_4", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_5", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_6", "N", 12, 2 } )
   AAdd( aDbf, { "IZN_POR", "N", 12, 2 } )
   AAdd( aDbf, { "OPORDOH", "N", 12, 2 } )
   AAdd( aDbf, { "L_ODB", "N", 12, 2 } )
   AAdd( aDbf, { "ODBICI", "N", 12, 2 } )
   AAdd( aDbf, { "ISPLATA", "N", 12, 2 } )

   xlsx_export_init( aDbf )

   RETURN .T.


STATIC FUNCTION otvori_tabele()

   // o_ld_obracuni()
   // o_ld_parametri_obracuna()
   o_params()
   // o_ld_rj()
   // o_ld_radn()
   // o_koef_beneficiranog_radnog_staza()
   // o_ld_vrste_posla()
   // o_tippr()
   // o_kred()
   // o_dopr()
   // o_por()
   // select_o_ld()

   RETURN .T.
