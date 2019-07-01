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

MEMVAR gZaok2, gObracun


FUNCTION ld_specifikacija_plate_obr_2001()

   LOCAL GetList := {}
   LOCAL aPom := {}   // { LD->brbod, 1, nP77 (minuli rad), LD->uneto }
   LOCAL nGrupaPoslova := 5
   LOCAL nLM := 5
   LOCAL nLin
   LOCAL nPocetak
   LOCAL i := 0
   LOCAL j := 0
   LOCAL k := 0
   LOCAL nPreskociRedova
   LOCAL cLin
   LOCAL nPom
   LOCAL cRepSr := "N"
   LOCAL cDjelatnost := " "
   LOCAL oReport, hRec, cKey

   // PRIVATE gPici := "9,999,999,999,999,999" + iif( gZaok > 0, PadR( ".", gZaok + 1, "9" ), "" )
   LOCAL cPictureIznos := "9,999,999,999,999,999.99" // + iif( gZaok2 > 0, PadR( ".", gZaok2 + 1, "9" ), "" )
   LOCAL cPictureStopa := "999,999,999,999.99"
   LOCAL cIdRj
   LOCAL cUslovIdRj, cUslovOpstStan
   LOCAL cFilterRj, cFilterOpstStan
   LOCAL nDanOd, nDanDo, nMjesecOd, nGodinaOd, nMjesecDo, nGodinaDo
   LOCAL nBrutoOsnova := 0
   LOCAL nBrutoOsBenef := 0
   LOCAL nRadnikBrutoOsnovica := 0
   LOCAL nPojBrBenef := 0
   LOCAL nOstaleObaveze := 0
   LOCAL uNaRuke := 0
   LOCAL cFirmNaz := PadR( fetch_metric( "org_naziv", NIL, Space( 35 ) ), 35 )
   LOCAL cFirmAdresa := PadR( fetch_metric( "ld_firma_adresa", NIL, Space( 35 ) ), 35 )
   LOCAL cFirmOpc := PadR( fetch_metric( "ld_firma_opcina", NIL, Space( 35 ) ), 35 )
   LOCAL cVrstaDjelatnosti := PadR( fetch_metric( "ld_firma_vrsta_djelatnosti", NIL, Space( 50 ) ), 50 )
   LOCAL cRadn := Space( LEN_IDRADNIK )
   LOCAL dDatIspl
   LOCAL cMRad := fetch_metric( "ld_specifikacija_minuli_rad", NIL, cMRad )
   LOCAL cPrimanjaStvariUsluge := fetch_metric( "ld_specifikacija_primanja_dobra", NIL, cPrimanjaStvariUsluge )

   LOCAL cDoprIz1 := PadR( fetch_metric( "ld_specifikacija_doprinos_1", NIL, "10" ), 2 )
   LOCAL cDoprIz2 := PadR( fetch_metric( "ld_specifikacija_doprinos_2", NIL, "11" ), 2 )
   LOCAL cDoprIz3 := fetch_metric( "ld_specifikacija_doprinos_3", NIL, "12" )

   LOCAL cDoprNa1 := PadR( fetch_metric( "ld_specifikacija_doprinos_5", NIL, "20" ), 2 )
   LOCAL cDoprNa2 := PadR( fetch_metric( "ld_specifikacija_doprinos_6", NIL, "21" ), 2 )
   LOCAL cDoprNa3 := fetch_metric( "ld_specifikacija_doprinos_7", NIL, "22" )

   LOCAL cDodatniDoprPio := PadR( fetch_metric( "ld_specifikacija_doprinos_pio", NIL, "  " ), 2 )
   LOCAL cDodatniDoprZdravstvo := PadR( fetch_metric( "ld_specifikacija_doprinos_zdr", NIL, "  " ), 2 )
   LOCAL nUkDoprIZ := 0
   LOCAL cCOO1 := fetch_metric( "ld_specifikacija_c1", NIL, Space( 20 ) )
   LOCAL cCOO2 := fetch_metric( "ld_specifikacija_c2", NIL, Space( 20 ) )
   LOCAL cCOO3 := fetch_metric( "ld_specifikacija_c3", NIL, Space( 20 ) )
   LOCAL cCOO4 := fetch_metric( "ld_specifikacija_c4", NIL, Space( 20 ) )
   LOCAL cNOO1 := fetch_metric( "ld_specifikacija_n1", NIL, Space( 20 ) )
   LOCAL cNOO2 := fetch_metric( "ld_specifikacija_n2", NIL, Space( 20 ) )
   LOCAL cNOO3 := fetch_metric( "ld_specifikacija_n3", NIL, Space( 20 ) )
   LOCAL cNOO4 := fetch_metric( "ld_specifikacija_n4", NIL, Space( 20 ) )
   LOCAL nMjesec := ld_tekuci_mjesec()
   LOCAL nGodina := ld_tekuca_godina()
   LOCAL cObracun := gObracun
   //LOCAL nOmjerZdravstvo := fetch_metric( "ld_specifikacija_omjer_dopr_zdr", NIL, 10.2 )  - stopa zdravstvo u RS
   //LOCAL nOmjerNezaposlenost := fetch_metric( "ld_specifikacija_omjer_dopr_nezap", NIL, 30 ) - stopa nezaposlenost u RS
   LOCAL cVrstaIsplate := fetch_metric( "ld_specifikacija_vrsta_isplate", NIL, "A" )
   LOCAL cCheck11_14 :=  fetch_metric( "ld_specifikacija_check_11_14", NIL, "  " )
   LOCAL cFilt := ".t."

   LOCAL cDoprOO1
   LOCAL cDoprOO2
   LOCAL cDoprOO3
   LOCAL cDoprOO4
   LOCAL cDodDoprP
   LOCAL cDodDoprZ
   LOCAL t
   LOCAL nKoefLicniOdbici
   LOCAL nULicOdbitak
   LOCAL nP77
   // LOCAL nP78
   LOCAL nP79
   LOCAL nPrimanjaStvariUsluge, nUNet, nNetoOsn, nUNetoOsnova
   LOCAL nKoefDopr1X := 0, nKoefDopr2X := 0, nKoefDopr3X := 0
   LOCAL nKoefDopr5X := 0, nKoefDopr6X := 0, nKoefDopr7X := 0
   LOCAL nKoefDodatniDoprinosZdravstvo, nKoefDodatniDoprinosPio
   LOCAL nDopr1X, nDopr2X, nDopr3X  // iznosi dopr IZ
   LOCAL nDopr5X, nDopr6X, nDopr7X  // iznosi dopr NA

   LOCAL nRadnikPoreznaOsnovica := 0
   LOCAL nPojDoprIz := 0
   LOCAL nPoreznaOsnovicaUkupno := 0
   LOCAL nPorNaPlatu := 0
   LOCAL nPorezOstali := 0

   LOCAL nPorOlaksice  := 0
   LOCAL nBolPreko := 0
   LOCAL nObustave := 0
   LOCAL nOstOb1 := 0
   LOCAL nOstOb2 := 0
   LOCAL nOstOb3 := 0
   LOCAL nOstOb4 := 0

   LOCAL nUkupnoBrutoOsnovicaSaMinLimit := 0
   LOCAL nUkupnoBrutoOsnovicaStvariUsluge := 0

   //LOCAL lPDNE := .F.
   LOCAL aOps := {}
   LOCAL nOps
   LOCAL nObrCount := 0
   LOCAL cLdSpec2001GrupePoslovaAutoRucno := fetch_metric( "ld_grupe_poslova_specifikacija", NIL, "1" )
   LOCAL cMatBr := fetch_metric( "ld_specifikacija_maticni_broj", NIL, cMatBr )
   LOCAL nBrojZaposlenih
   LOCAL nUNeto
   LOCAL cTekuciRadnikTipRada
   LOCAL nDodDoprZ, nDodDoprP


   IF ValType( cDoprIz3 ) != "C"
     cDoprIz3 := "12"
   ENDIF
   IF ValType( cDoprNa3 ) != "C"
     cDoprNa3 := "22"
   ENDIF

   cDoprIz3 := PADR( cDoprIz3, 2 )  // fix pogresno pohranjene parametre
   cDoprNa3 := PADR( cDoprNa3, 3 )

   cMatBR := PadR( cMatBr, 13 )

   // LOCAL aSpec := {}

/*
   FOR i := 1 TO nGrupaPoslova + 1
      AAdd( aSpec, { 0, 0, 0, 0 } ) // br.bodova, br.radnika, minuli rad, uneto
   NEXT
*/

   download_template_ld_obr_2001()

   cIdRJ := "  "
   cUslovIdRj := ""
   cUslovOpstStan := ""

   // prvi dan mjeseca
   nDanOd := prvi_dan_mjeseca( ld_tekuci_mjesec() )
   nMjesecOd := ld_tekuci_mjesec()
   nGodinaOd := ld_tekuca_godina()
   // posljednji dan mjeseca
   nDanDo := zadnji_dan_mjeseca( ld_tekuci_mjesec() )
   nMjesecDo := ld_tekuci_mjesec()
   nGodinaDo := ld_tekuca_godina()

   ld_specifikacije_otvori_tabele()

   /*
   SELECT ops

   IF ( FieldPos( "DNE" ) <> 0 )
      GO TOP
      DO WHILE !Eof()
         AAdd( aOps, { id, dne, 0 } ) // sifra opstine, dopr.koje nema, neto
         SKIP 1
      ENDDO
      lPDNE := .T.
   ELSE
      lPDNE := .F.
   ENDIF
*/

   cUslovIdRj := fetch_metric( "ld_specifikacija_rj", NIL, cUslovIdRj )
   cUslovOpstStan := fetch_metric( "ld_specifikacija_opcine", NIL, cUslovOpstStan )
   cUslovIdRj := PadR( cUslovIdRj, 100 )
   cUslovOpstStan := PadR( cUslovOpstStan, 100 )

   dDatIspl := Date()

   DO WHILE .T.
      Box(, 23 + iif( cLdSpec2001GrupePoslovaAutoRucno == "1", 0, 1 ), 75 )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): " GET cUslovIdRj PICT "@!S15"
      @ box_x_koord() + 1, Col() + 1 SAY "Djelatnost" GET cDjelatnost VALID val_tiprada( cDjelatnost ) PICT "@!"
      @ box_x_koord() + 1, Col() + 1 SAY "Spec.za RS" GET cRepSr VALID cRepSr $ "DN" PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Opština stan (prazno-sve): " GET cUslovOpstStan PICT "@!S20"

      IF ld_vise_obracuna()
         @ box_x_koord() + 2, Col() + 1 SAY "Obr.:" GET cObracun  WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Period od:" GET nDanOd PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nMjesecOd PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nGodinaOd PICT "9999"
      @ box_x_koord() + 3, Col() + 1 SAY "do:" GET nDanDo PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nMjesecDo PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nGodinaDo PICT "9999"

      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 " Naziv: " GET cFirmNaz
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Adresa: " GET cFirmAdresa
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Općina: " GET cFirmOpc
      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Vrsta djelatnosti: " GET cVrstaDjelatnosti

      @ box_x_koord() + 4, box_y_koord() + 52 SAY "ID.broj :" GET cMatBR
      @ box_x_koord() + 5, box_y_koord() + 52 SAY "Dat.ispl:" GET dDatIspl

      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Prim.u usl.ili dobrima (npr: 12;14;)" GET cPrimanjaStvariUsluge  PICT "@!S20"

      @ box_x_koord() + 10, box_y_koord() + 2 SAY "Dopr. pio (iz)" GET cDoprIz1
      @ box_x_koord() + 10, Col() + 2 SAY "Dopr. pio (na)" GET cDoprNa1
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Dopr. zdr (iz)" GET cDoprIz2
      @ box_x_koord() + 11, Col() + 2 SAY "Dopr.zdr (na)" GET cDoprNa2
      //@ box_x_koord() + 11, Col() + 1 SAY "Omjer dopr.zdr (%):" GET nOmjerZdravstvo PICT "999.99999"
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Dopr.nez (iz)" GET cDoprIz3
      @ box_x_koord() + 12, Col() + 2 SAY "Dopr.nez (na)" GET cDoprNa3
      //@ box_x_koord() + 12, Col() + 1 SAY "Omjer dopr.nez (%):" GET nOmjerNezaposlenost PICT "999.99999"

      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Dod.dopr. pio" GET cDodatniDoprPio PICT "@S35"
      @ box_x_koord() + 14, box_y_koord() + 2 SAY "Dod.dopr. zdr" GET cDodatniDoprZdravstvo PICT "@S35"

      @ box_x_koord() + 15, box_y_koord() + 2 SAY "Ost.obaveze: NAZIV                  USLOV"
      @ box_x_koord() + 16, box_y_koord() + 2 SAY " 1." GET cCOO1
      @ box_x_koord() + 16, box_y_koord() + 30 GET cNOO1
      @ box_x_koord() + 17, box_y_koord() + 2 SAY " 2." GET cCOO2
      @ box_x_koord() + 17, box_y_koord() + 30 GET cNOO2
      @ box_x_koord() + 18, box_y_koord() + 2 SAY " 3." GET cCOO3
      @ box_x_koord() + 18, box_y_koord() + 30 GET cNOO3
      @ box_x_koord() + 19, box_y_koord() + 2 SAY " 4." GET cCOO4
      @ box_x_koord() + 19, box_y_koord() + 30 GET cNOO4

      @ box_x_koord() + 21, box_y_koord() + 2 SAY "Isplata: 'A' doprinosi+porez, 'B' samo doprinosi, 'C' samo porez" GET cVrstaIsplate VALID cVrstaIsplate $ "ABC" PICT "@!"
      @ box_x_koord() + 22, box_y_koord() + 2 SAY "Polje 11/12/13/14 ?" GET cCheck11_14 VALID cCheck11_14 $ "  #11#12#13#14" PICT "@!"

      READ

      clvbox()
      ESC_BCR
      BoxC()

      cFilterRj := Parsiraj( cUslovIdRj, "IDRJ" )
      cFilterOpstStan := Parsiraj( cUslovOpstStan, "IDOPSST" )
      IF ( cFilterRj <> NIL .AND. cFilterOpstStan <> NIL )
         EXIT
      ENDIF
   ENDDO

   set_metric( "org_naziv", NIL, cFirmNaz )
   set_metric( "ld_firma_adresa", NIL, cFirmAdresa )
   set_metric( "ld_firma_opcina", NIL, cFirmOpc )
   set_metric( "ld_firma_vrsta_djelatnosti", NIL, cVrstaDjelatnosti )
   set_metric( "ld_specifikacija_minuli_rad", NIL, cMRad )
   set_metric( "ld_specifikacija_primanja_dobra", NIL, cPrimanjaStvariUsluge )
   set_metric( "ld_specifikacija_doprinos_1", NIL, cDoprIz1 )
   set_metric( "ld_specifikacija_doprinos_2", NIL, cDoprIz2 )
   set_metric( "ld_specifikacija_doprinos_3", NIL, cDoprIz3 )

   set_metric( "ld_specifikacija_doprinos_5", NIL, cDoprNa1 )
   set_metric( "ld_specifikacija_doprinos_6", NIL, cDoprNa2 )
   set_metric( "ld_specifikacija_doprinos_7", NIL, cDoprNa3 )

   set_metric( "ld_specifikacija_doprinos_pio", NIL, cDodatniDoprPio )
   set_metric( "ld_specifikacija_doprinos_zdr", NIL, cDodatniDoprZdravstvo )
   set_metric( "ld_specifikacija_c1", NIL, cCOO1 )
   set_metric( "ld_specifikacija_c2", NIL, cCOO2 )
   set_metric( "ld_specifikacija_c3", NIL, cCOO3 )
   set_metric( "ld_specifikacija_c4", NIL, cCOO4 )
   set_metric( "ld_specifikacija_n1", NIL, cNOO1 )
   set_metric( "ld_specifikacija_n2", NIL, cNOO2 )
   set_metric( "ld_specifikacija_n3", NIL, cNOO3 )
   set_metric( "ld_specifikacija_n4", NIL, cNOO4 )
   set_metric( "ld_specifikacija_vrsta_isplate", NIL, cVrstaIsplate )
   //set_metric( "ld_specifikacija_omjer_dopr_zdr", NIL, nOmjerZdravstvo )
   //set_metric( "ld_specifikacija_omjer_dopr_nezap", NIL, nOmjerNezaposlenost )

   cUslovIdRj := Trim( cUslovIdRj )
   cUslovOpstStan := Trim( cUslovOpstStan )

   set_metric( "ld_specifikacija_rj", NIL, cUslovIdRj )
   set_metric( "ld_specifikacija_opcine", NIL, cUslovOpstStan )
   set_metric( "ld_specifikacija_maticni_broj", NIL, cMatBr )
   set_metric( "ld_specifikacija_check_11_14", NIL, cCheck11_14 )

   ld_porezi_i_doprinosi_iz_sezone( nGodina, nMjesec )


   hRec := hb_Hash()
   oReport := YargReport():New( iif( cRepSr == "D", "ld_obr_2001-A", "ld_obr_2001" ), "xlsx" )

   hRec[ "naziv" ] := cFirmNaz
   hRec[ "adresa" ] := cFirmAdresa
   hRec[ "opcina" ] :=  cFirmOpc
   hRec[ "vrsta_djelatnosti" ] :=  cVrstaDjelatnosti

   DO CASE
   CASE cVrstaIsplate == "A"
      hRec[ "check_15a" ] := "X"
   CASE cVrstaIsplate == "B"
      hRec[ "check_15b" ] := "X"
   CASE cVrstaIsplate == "C"
      hRec[ "check_15c" ] := "X"
   ENDCASE

   DO CASE
   CASE cCheck11_14 == "11"
      hRec[ "check_11" ] := "X"
   CASE cCheck11_14 == "12"
      hRec[ "check_12" ] := "X"
   CASE cCheck11_14 == "13"
      hRec[ "check_13" ] := "X"
   CASE cCheck11_14 == "14"
      hRec[ "check_14" ] := "X"
   ENDCASE


   hRec[ "d_od_1" ] := SubStr( PadL( AllTrim( Str( nDanOd, 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "d_od_2" ] := SubStr( PadL( AllTrim( Str( nDanOd, 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "m_od_1" ] := SubStr( PadL( AllTrim( Str( nMjesecOd, 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "m_od_2" ] := SubStr( PadL( AllTrim( Str( nMjesecOd, 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "g_od_1" ] := SubStr( PadL( AllTrim( Str( nGodinaOd, 4 ) ), 4, "0" ), 1, 1 )
   hRec[ "g_od_2" ] := SubStr( PadL( AllTrim( Str( nGodinaOd, 4 ) ), 4, "0" ), 2, 1 )
   hRec[ "g_od_3" ] := SubStr( PadL( AllTrim( Str( nGodinaOd, 4 ) ), 4, "0" ), 3, 1 )
   hRec[ "g_od_4" ] := SubStr( PadL( AllTrim( Str( nGodinaOd, 4 ) ), 4, "0" ), 4, 1 )


   hRec[ "d_do_1" ] := SubStr( PadL( AllTrim( Str( nDanDo, 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "d_do_2" ] := SubStr( PadL( AllTrim( Str( nDanDo, 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "m_do_1" ] := SubStr( PadL( AllTrim( Str( nMjesecDo, 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "m_do_2" ] := SubStr( PadL( AllTrim( Str( nMjesecDo, 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "g_do_1" ] := SubStr( PadL( AllTrim( Str( nGodinaDo, 4 ) ), 4, "0" ), 1, 1 )
   hRec[ "g_do_2" ] := SubStr( PadL( AllTrim( Str( nGodinaDo, 4 ) ), 4, "0" ), 2, 1 )
   hRec[ "g_do_3" ] := SubStr( PadL( AllTrim( Str( nGodinaDo, 4 ) ), 4, "0" ), 3, 1 )
   hRec[ "g_do_4" ] := SubStr( PadL( AllTrim( Str( nGodinaDo, 4 ) ), 4, "0" ), 4, 1 )

   hRec[ "j1" ] := SubStr( cMatBR, 1, 1 )
   hRec[ "j2" ] := SubStr( cMatBR, 2, 1 )
   hRec[ "j3" ] := SubStr( cMatBR, 3, 1 )
   hRec[ "j4" ] := SubStr( cMatBR, 4, 1 )
   hRec[ "j5" ] := SubStr( cMatBR, 5, 1 )
   hRec[ "j6" ] := SubStr( cMatBR, 6, 1 )
   hRec[ "j7" ] := SubStr( cMatBR, 7, 1 )
   hRec[ "j8" ] := SubStr( cMatBR, 8, 1 )
   hRec[ "j9" ] := SubStr( cMatBR, 9, 1 )
   hRec[ "j10" ] := SubStr( cMatBR, 10, 1 )
   hRec[ "j11" ] := SubStr( cMatBR, 11, 1 )
   hRec[ "j12" ] := SubStr( cMatBR, 12, 1 )
   hRec[ "j13" ] := SubStr( cMatBR, 13, 1 )


   hRec[ "d_up_1" ] := SubStr( PadL( AllTrim( Str( Day( dDatIspl ), 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "d_up_2" ] := SubStr( PadL( AllTrim( Str( Day( dDatIspl ), 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "m_up_1" ] := SubStr( PadL( AllTrim( Str( Month( dDatIspl ), 2 ) ), 2, "0" ), 1, 1 )
   hRec[ "m_up_2" ] := SubStr( PadL( AllTrim( Str( Month( dDatIspl ), 2 ) ), 2, "0" ), 2, 1 )

   hRec[ "g_up_1" ] := SubStr( PadL( AllTrim( Str( Year( dDatIspl ), 4 ) ), 4, "0" ), 1, 1 )
   hRec[ "g_up_2" ] := SubStr( PadL( AllTrim( Str( Year( dDatIspl ), 4 ) ), 4, "0" ), 2, 1 )
   hRec[ "g_up_3" ] := SubStr( PadL( AllTrim( Str( Year( dDatIspl ), 4 ) ), 4, "0" ), 3, 1 )
   hRec[ "g_up_4" ] := SubStr( PadL( AllTrim( Str( Year( dDatIspl ), 4 ) ), 4, "0" ), 4, 1 )

   cObracun := Trim( cObracun )

   ld_pozicija_parobr( nMjesec, nGodina, cObracun, Left( cUslovIdRj, 2 ) )

   // SELECT LD
   // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )

   seek_ld_2( NIL, nGodina, nMjesec )
   // GO TOP
   // HSEEK Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 )


   IF !Empty( cUslovIdRj )
      cFilt += ( ".and." + cFilterRj )
   ENDIF

   IF !Empty( cObracun )
      cFilt += ( ".and. OBR==" + dbf_quote( cObracun ) )
   ENDIF

   SET FILTER TO &cFilt
   GO TOP


   cObracun := Trim( cObracun )
   cDoprOO1 := ld_izrezi_string( "D->", 2, @cNOO1 )
   cDoprOO2 := ld_izrezi_string( "D->", 2, @cNOO2 )
   cDoprOO3 := ld_izrezi_string( "D->", 2, @cNOO3 )
   cDoprOO4 := ld_izrezi_string( "D->", 2, @cNOO4 )

   cDodDoprP := ld_izrezi_string( "D->", 2, @cDodatniDoprPio )
   cDodDoprZ := ld_izrezi_string( "D->", 2, @cDodatniDoprZdravstvo )

   ld_pozicija_parobr( nMjesec, nGodina, cObracun, Left( cUslovIdRj, 2 ) )

   seek_ld_2( NIL, nGodina, nMjesec )

   IF !Empty( cUslovIdRj )
      cFilt += ( ".and." + cFilterRj )
   ENDIF

   IF !Empty( cObracun )
      cFilt += ( ".and. OBR==" + dbf_quote( cObracun ) )
   ENDIF

   SET FILTER TO &cFilt
   GO TOP


   IF Eof()
      MsgBeep( "Obračun za ovaj mjesec ne postoji !" )
      // my_close_all_dbf()
      RETURN .T.
   ENDIF

   nUNeto := 0
   nUNetoOsnova := 0
   nPorNaPlatu := 0
   nKoefLicniOdbici := 0
   nBrojZaposlenih := 0
   nULicOdbitak := 0
   nDodDoprZ := 0
   nDodDoprP := 0

   DO WHILE Str( nGodina, 4, 0 ) + Str( nMjesec, 2, 0 ) == Str( ld->godina, 4, 0 ) + Str( ld->mjesec, 2, 0 )

      select_o_radn( LD->idradn )
      cTekuciRadnikTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )
      nRSpr_koef := 0
      IF cTekuciRadnikTipRada == "S"
         nRSpr_koef := radn->sp_koef
      ENDIF

      //IF cTekuciRadnikTipRada $ "I#N" .AND.
         //
      //ELSE
      IF !Empty( cDjelatnost ) .AND. cDjelatnost <> cTekuciRadnikTipRada
         info_bar( "ld_spec", ld->idradn + " djelatnost:" + cDjelatnost + " <>  radn: " + cTekuciRadnikTipRada + " SKIP!" )
         SELECT ld
         SKIP
         LOOP
      ENDIF

      IF cRepSr == "N" // preskoci RS
         IF radnik_iz_rs( radn->idopsst, radn->idopsrad )
            SELECT ld
            SKIP
            LOOP
         ENDIF
      ELSE  // preskoci FBiH
         IF !radnik_iz_rs( radn->idopsst, radn->idopsrad )
            SELECT ld
            SKIP
            LOOP
         ENDIF
      ENDIF

      SELECT LD
      IF !( RADN->( &cFilterOpstStan ) )
         SKIP 1
         LOOP
      ENDIF

      nKoefLicniOdbici := ld->ulicodb
      nULicOdbitak += nKoefLicniOdbici
      nP77 := iif( !Empty( cMRad ), LD->&( "I" + cMRad ), 0 )
      // nP78 := iif( !Empty( cPorOl ), LD->&( "I" + cPorOl ), 0 )
      nP79 := 0

/*
      IF !Empty( cBolPr ) .OR. !Empty( cBolPr )
         FOR t := 1 TO 99
            cPom := IF( t > 9, Str( t, 2 ), "0" + Str( t, 1 ) )
            IF LD->( FieldPos( "I" + cPom ) ) <= 0
               EXIT
            ENDIF
            nP79 += IF( cPom $ cBolPr, LD->&( "I" + cPom ), 0 )
         NEXT
      ENDIF
*/

      nP80 := nP81 := nP82 := nP83 := nP84 := nP85 := 0

      IF LD->uneto > 0  // zbog bol.preko 42 dana koje ne ide u neto
         IF Len( aPom ) < 1 .OR. ( nPom := AScan( aPom, {| x | x[ 1 ] == LD->brbod } ) ) == 0
            AAdd( aPom, { LD->brbod, 1, nP77, LD->uneto } )
         ELSE
            IF !( ld_vise_obracuna() .AND. Empty( cObracun ) .AND. LD->obr $ "23456789" )
               aPom[ nPom, 2 ] += 1  // broj radnika
            ENDIF
            aPom[ nPom, 3 ] += nP77  // minuli rad
            aPom[ nPom, 4 ] += LD->uneto // neto
         ENDIF
      ENDIF


      nPrimanjaStvariUsluge := 0
      IF !Empty( cPrimanjaStvariUsluge )
         FOR t := 1 TO 99
            cPom := IF( t > 9, Str( t, 2 ), "0" + Str( t, 1 ) )
            IF LD->( FieldPos( "I" + cPom ) ) <= 0
               EXIT
            ENDIF
            nPrimanjaStvariUsluge += IF( cPom $ cPrimanjaStvariUsluge, LD->&( "I" + cPom ), 0 )
         NEXT
      ENDIF

      nUNeto += ld->uneto
      nNetoOsn := Max( ld->uneto, PAROBR->prosld * gPDLimit / 100 )
      nUNetoOsnova += nNetoOsn

      // prvo doprinosi i bruto osnova
      nRadnikBrutoOsnovica := ld_get_bruto_osnova( nNetoOsn, cTekuciRadnikTipRada, nKoefLicniOdbici, nRSpr_koef )

      nRadnikBrutoStvariUsluge := 0
      IF nPrimanjaStvariUsluge > 0
         nRadnikBrutoStvariUsluge := ld_get_bruto_osnova( nPrimanjaStvariUsluge, cTekuciRadnikTipRada, nKoefLicniOdbici, nRSpr_koef )
      ENDIF

      nMPojBrOsn := nRadnikBrutoOsnovica

      IF calc_mbruto()
         nMPojBrOsn := min_bruto( nRadnikBrutoOsnovica, field->usati ) // minimalni bruto
      ENDIF

      nBrutoOsnova += nRadnikBrutoOsnovica
      nUkupnoBrutoOsnovicaStvariUsluge += nRadnikBrutoStvariUsluge
      nUkupnoBrutoOsnovicaSaMinLimit += nMPojBrOsn


      aBeneficirani := {}

      IF is_radn_k4_bf_ide_u_benef_osnovu()     // beneficirani radnici

         cFFTmp := gBFForm
         gBFForm := StrTran( gBFForm, "_", "" )

         nPojBrBenef := ld_get_bruto_osnova( nNetoOsn - IF( !Empty( gBFForm ), &gBFForm, 0 ), cTekuciRadnikTipRada, nKoefLicniOdbici, nRSpr_koef )

         nBrutoOsBenef += nPojBrBenef
         _benef_st := BenefStepen()
         add_to_a_benef( @aBeneficirani, AllTrim( radn->k3 ), _benef_st, nPojBrBenef )

         gBFForm := cFFtmp

      ENDIF

      nPom := nUkupnoBrutoOsnovicaSaMinLimit

      nKoefDodatniDoprinosZdravstvo := 0
      nKoefDodatniDoprinosPio := 0

      o_dopr()
      GO TOP
      DO WHILE !Eof()

/*
         IF DOPR->poopst == "1" .AND. lPDNE
            nBOO := 0
            FOR i := 1 TO Len( aOps )
               IF !( DOPR->id $ aOps[ i, 2 ] )
                  nBOO += aOps[ i, 3 ]
               ENDIF
            NEXT
            nBOO := ld_get_bruto_osnova( nBOO, cTekuciRadnikTipRada, nKoefLicniOdbici )
         ELSE
         */
         nBOO := nUkupnoBrutoOsnovicaSaMinLimit
         // ENDIF

         IF ID $ cDodDoprP
            nKoefDodatniDoprinosPio += iznos
            IF !Empty( field->idkbenef )
               nDodDoprP += ROUND2( Max( DLIMIT, get_benef_osnovica( aBeneficirani, field->idkbenef ) * iznos / 100 ), gZaok2 )
            ELSE
               nDodDoprP += ROUND2( Max( DLIMIT, nBOO * iznos / 100 ), gZaok2 )
            ENDIF
         ENDIF

         IF ID $ cDodDoprZ
            nKoefDodatniDoprinosZdravstvo += iznos
            IF !Empty( field->idkbenef )
               // beneficirani
               nDodDoprZ += ROUND2( Max( DLIMIT, get_benef_osnovica( aBeneficirani, field->idkbenef ) * iznos / 100 ), gZaok2 )
            ELSE
               nDodDoprZ += ROUND2( Max( DLIMIT, nBOO * iznos / 100 ), gZaok2 )
            ENDIF
         ENDIF

         SKIP 1

      ENDDO

      nKoefDopr1X := find_field_by_id( "dopr", cDoprIz1, "iznos" )
      nKoefDopr2X := find_field_by_id( "dopr", cDoprIz2, "iznos" )
      nKoefDopr3X := find_field_by_id( "dopr", cDoprIz3, "iznos" )

      nKoefDopr5X := find_field_by_id( "dopr", cDoprNa1, "iznos" )
      nKoefDopr6X := find_field_by_id( "dopr", cDoprNa2, "iznos" )
      nKoefDopr7X := find_field_by_id( "dopr", cDoprNa3, "iznos" )

      //nPom := nKoefDopr1X + nKoefDopr2X //+ nKoefDopr3X


      hRec[ "stopa_16" ] := FormNum2( nKoefDopr1X, 16, cPictureIznos ) + "%"  // PIO iz
      hRec[ "stopa_17" ] := FormNum2( nKoefDopr2X, 16, cPictureIznos ) + "%"  // zdravstvo iz
      hRec[ "stopa_18" ] := FormNum2( nKoefDopr3X, 16, cPictureIznos ) + "%"  // nezaposlenost iz
      hRec[ "stopa_20" ] := FormNum2( nKoefDopr5X, 16, cPictureIznos ) + "%"  // PIO na
      hRec[ "stopa_21" ] := FormNum2( nKoefDopr6X, 16, cPictureIznos ) + "%"  // zdrav na
      hRec[ "stopa_22" ] := FormNum2( nKoefDopr7X, 16, cPictureIznos ) + "%"  // nezap na

      nPom := nKoefDopr5X + nKoefDopr6X + nKoefDodatniDoprinosZdravstvo + nKoefDodatniDoprinosPio

      hRec[ "stopa_23" ] := FormNum2( nKoefDodatniDoprinosPio, 16, cPictureIznos ) + "%"  // dodatni PIO i invalid
      hRec[ "stopa_24" ] := FormNum2( nKoefDodatniDoprinosZdravstvo, 16, cPictureIznos ) + "%"  // dodatni zdravstvo



      nPojDoprIZ := round2( ( nMPojBrOsn * nKoefDopr1X / 100 ), gZaok2 ) + ;
         round2( ( nMPojBrOsn * nKoefDopr2X / 100 ), gZaok2 ) + ;
         round2( ( nMPojBrOsn * nKoefDopr3X / 100 ), gZaok2 )

      nRadnikPoreznaOsnovica := ( nRadnikBrutoOsnovica - nPojDoprIz ) - nKoefLicniOdbici

      IF nRadnikPoreznaOsnovica >= 0 .AND. radn_oporeziv( radn->id, ld->idrj )
         // osnovica za porez na platu
         // nPoreznaOsnovicaUkupno := ( nBrutoOsnova - nUKDoprIZ ) - nULicOdbitak
         nPoreznaOsnovicaUkupno += nRadnikPoreznaOsnovica
      ENDIF

      // osnovica mora biti veca od 0
      IF nPoreznaOsnovicaUkupno < 0
         nPoreznaOsnovicaUkupno := 0
      ENDIF

      // resetuj varijable
      nPorNaPlatu := 0
      nPorezOstali := 0

      o_por()   // porez na platu i ostali porez
      GO TOP
      DO WHILE !Eof()

         PozicOps( POR->poopst )
         IF !ImaUOp( "POR", POR->id )
            SKIP 1
            LOOP
         ENDIF
         IF por->por_tip == "B"
            nPorNaPlatu  += POR->iznos * Max( nPoreznaOsnovicaUkupno, PAROBR->prosld * gPDLimit / 100 ) / 100
         ENDIF
         SKIP 1
      ENDDO

      SELECT LD

      nBrojZaposlenih++
      // nPorOlaksice += nP78
      nBolPreko += nP79
      nObustave += nP80
      nOstaleObaveze += nP81
      nOstOb1 += nP82
      nOstOb2 += nP83
      nOstOb3 += nP84
      nOstOb4 += nP85

/*
      IF lPDNE
         nOps := AScan( aOps, {| x | x[ 1 ] == RADN->idopsst } )
         IF nOps > 0
            aOps[ nOps, 3 ] += Max( ld->uneto, PAROBR->prosld * gPDLimit / 100 )
         ELSE
            AAdd( aOps, { RADN->idopsst, "", Max( ld->uneto, PAROBR->prosld * gPDLimit / 100 ) } )
         ENDIF
      ENDIF
*/
      ++nObrCount

      SKIP 1

   ENDDO

   // =============================== kraj proracuna - prolaska kroz tabelu radnika =============================


   nDopr1X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr1X / 100, gZaok2 ) // iznos pio iz
   hRec[ "iznos_16" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr1X, cVrstaIsplate ), 16, cPictureIznos )

   nDopr2X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr2X / 100, gZaok2 ) // iznos zdr iz
   hRec[ "iznos_17" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr2X, cVrstaIsplate ), 16, cPictureIznos )

   nDopr3X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr3X / 100, gZaok2 ) // iznos nez iz
   hRec[ "iznos_18" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr3X, cVrstaIsplate ), 16, cPictureIznos )

   nUkDoprIZ := nDopr1X + nDopr2X + nDopr3X
   hRec[ "iznos_19" ] := FormNum2( isplata_dopr_kontrola_iznosa( nUkDoprIZ, cVrstaIsplate ), 16, cPictureIznos )

   nDopr5X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr5X / 100, gZaok2 )  // iznos pio na
   hRec[ "iznos_20" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr5X, cVrstaIsplate ), 16, cPictureIznos )

   nDopr6X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr6X / 100, gZaok2 )
   hRec[ "iznos_21" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr6X, cVrstaIsplate ), 16, cPictureIznos )

   nDopr7X := round2( nUkupnoBrutoOsnovicaSaMinLimit * nKoefDopr7X / 100, gZaok2 )
   hRec[ "iznos_22" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr7X, cVrstaIsplate ), 16, cPictureIznos )

   // dodatni doprinos zdr i pio
   hRec[ "iznos_23" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDodDoprP, cVrstaIsplate ), 16, cPictureIznos )
   hRec[ "iznos_24" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDodDoprZ, cVrstaIsplate ), 16, cPictureIznos )
   hRec[ "iznos_25" ] := FormNum2( isplata_dopr_kontrola_iznosa( nDopr5X + nDopr6X + nDopr7X + nDodDoprP + nDodDoprZ, cVrstaIsplate ), 16, cPictureIznos )

   hRec[ "broj_zaposlenih" ] := AllTrim( Str( nBrojZaposlenih, 6, 0 ) )
   hRec[ "place_u_novcu" ] := FormNum2( nUkupnoBrutoOsnovicaSaMinLimit, 16, cPictureIznos )
   hRec[ "place_u_stvarima" ] := FormNum2( nUkupnoBrutoOsnovicaStvariUsluge, 16, cPictureIznos )
   hRec[ "ukupne_place" ] := FormNum2( nUkupnoBrutoOsnovicaSaMinLimit + nUkupnoBrutoOsnovicaStvariUsluge, 16, cPictureIznos )

   IF nObrCount == 0
      MsgBeep( "Štampa specifikacije nije moguća, nema obračuna !" )
      RETURN .T.
   ENDIF

   nPorNaPlatu := round2( nPorNaPlatu, gZaok2 )

   // obustave iz place
   // UzmiIzIni( cIniName, 'Varijable', 'O18I', FormNum2( - nObustave, 16, cPictureIznos ), 'WRITE' )

   // Ostale obaveze = OstaleObaveze.1


/*
   ASort( aPom, , , {| x, y | x[ 1 ] > y[ 1 ] } )
   FOR i := 1 TO Len( aPom )
      IF cLdSpec2001GrupePoslovaAutoRucno == "1"
         IF i <= nGrupaPoslova
            aSpec[ i, 1 ] := aPom[ i, 1 ]
            aSpec[ i, 2 ] := aPom[ i, 2 ]
            aSpec[ i, 3 ] := aPom[ i, 3 ]
            aSpec[ i, 4 ] := aPom[ i, 4 ]
         ELSE
            aSpec[ nGrupaPoslova, 2 ] += aPom[ i, 2 ]
            aSpec[ nGrupaPoslova, 3 ] += aPom[ i, 3 ]
            aSpec[ nGrupaPoslova, 4 ] += aPom[ i, 4 ]
         ENDIF
      ELSE     // gcLdSpec2001GrupePoslovaAutoRucno=="2"
         DO CASE
         CASE aPom[ i, 1 ] <= nLimG5
            aSpec[ 5, 1 ] := aPom[ i, 1 ]
            aSpec[ 5, 2 ] += aPom[ i, 2 ]
            aSpec[ 5, 3 ] += aPom[ i, 3 ]
            aSpec[ 5, 4 ] += aPom[ i, 4 ]
         CASE aPom[ i, 1 ] <= nLimG4
            aSpec[ 4, 1 ] := aPom[ i, 1 ]
            aSpec[ 4, 2 ] += aPom[ i, 2 ]
            aSpec[ 4, 3 ] += aPom[ i, 3 ]
            aSpec[ 4, 4 ] += aPom[ i, 4 ]
         CASE aPom[ i, 1 ] <= nLimG3
            aSpec[ 3, 1 ] := aPom[ i, 1 ]
            aSpec[ 3, 2 ] += aPom[ i, 2 ]
            aSpec[ 3, 3 ] += aPom[ i, 3 ]
            aSpec[ 3, 4 ] += aPom[ i, 4 ]
         CASE aPom[ i, 1 ] <= nLimG2
            aSpec[ 2, 1 ] := aPom[ i, 1 ]
            aSpec[ 2, 2 ] += aPom[ i, 2 ]
            aSpec[ 2, 3 ] += aPom[ i, 3 ]
            aSpec[ 2, 4 ] += aPom[ i, 4 ]
         CASE aPom[ i, 1 ] <= nLimG1
            aSpec[ 1, 1 ] := aPom[ i, 1 ]
            aSpec[ 1, 2 ] += aPom[ i, 2 ]
            aSpec[ 1, 3 ] += aPom[ i, 3 ]
            aSpec[ 1, 4 ] += aPom[ i, 4 ]
         ENDCASE
      ENDIF
      aSpec[ nGrupaPoslova + 1, 2 ] += aPom[ i, 2 ]; aSpec[ nGrupaPoslova + 1, 3 ] += aPom[ i, 3 ]
      aSpec[ nGrupaPoslova + 1, 4 ] += aPom[ i, 4 ]
   NEXT

*/


   o_por()
   GO TOP
   SEEK "01"

   nPom := nPorNaPlatu - nPorOlaksice // efektivno porez na dohodak
   hRec[ "iznos_29" ] :=   FormNum2( isplata_poreza_kontrola_iznosa( nPom, cVrstaIsplate ), 16, cPictureIznos )


   nPorOlaksice   := Abs( nPorOlaksice   )
   nBolPreko      := Abs( nBolPreko      )
   nObustave      := Abs( nObustave      )
   nOstOb1        := Abs( nOstOb1        )
   nOstOb2        := Abs( nOstOb2        )
   nOstOb3        := Abs( nOstOb3        )
   nOstOb4        := Abs( nOstOb4        )
   nOstaleObaveze := Abs( iif( nOstaleObaveze == 0, nOstOb1 + nOstOb2 + nOstOb3 + nOstOb4, nOstaleObaveze ) )

   IF cVrstaIsplate == "A"
      // sve obaveze
      nPom := nDopr1X + nDopr2x + nDopr3X + nDopr5x + nDopr6x + nDopr7X + nPorNaPlatu + nPorezOstali - nPorOlaksice + nOstaleOBaveze + nDodDoprP + nDodDoprZ

   ELSEIF cVrstaIsplate == "B"
      // samo doprinosi
      nPom := nDopr1X + nDopr2x + nDopr3X + nDopr5x + nDopr6x + nDopr7X + nDodDoprP + nDodDoprZ

   ELSEIF cVrstaIsplate == "C"
      // samo porez
      nPom := nPorNaPlatu + nPorezOstali - nPorOlaksice + nOstaleOBaveze
   ENDIF

   nPom := nUkupnoBrutoOsnovicaSaMinLimit - nUkupnoBrutoOsnovicaStvariUsluge
   nUUNR := nPom

   // ukupno ostalo
   nPom := nUkupnoBrutoOsnovicaStvariUsluge
   nUUsluge := nPom
   // UzmiIzIni( cIniName, 'Varijable', 'UNUS', FormNum2( nPom, 16, cPictureIznos ), 'WRITE' )

   // ukupno ostalo
   nPom := nUUNR + nUUsluge

   // ukupno placa_i_obaveze = obaveze + ukupno_neto + poreskeolaksice
   nPom := nPom + nUNETO + nPorOlaksice

   // obustave
   nPom := nObustave

   // neto za isplatu  = neto  + nPorOlaksice
   // -----------------------------------------
   // varijanta D - specificno za FEB jer treba da izbazi bol.preko.42
   // dana iz neta za isplatu na specifikaciji, vec je uracunat u netu.

   // IF my_get_from_ini( 'LD', 'BolPreko42IzbaciIz19', 'N', KUMPATH ) == 'D'
   // nPom := nUNETO + nPorOlaksice - nObustave
   // ELSE
   //nPom := nUNETO + nBolPreko + nPorOlaksice - nObustave
   // ENDIF

   // PIO iz + PIO na placu
  // nPom := nDopr1x + nDopr5x + nDodDoprP

   // zdravsveno iz + zdravstveno na placu
   //nPom := nDopr2x + nDopr6x + nDodDoprZ
   //nPom2 := nPom

   // zdravstvo za RS
   //nPom := nPom2 * ( nOmjerZdravstvo / 100 )
   //nD21a := nPom

   // nezaposlenost iz + nezaposlenost na placu
   //nPom := nDopr3x + nDopr7x
   //nPom2 := nPom

   // nezaposlenost za RS
   //nPom := nPom2 * ( nOmjerNezaposlenost / 100 )
   //nD22a := nPom

//   nPom := nPorNaPlatu - nPorOlaksice
//   nPom := nPorezOstali
//   nPom := nOstaleObaveze + nPorezOstali

/*
   // ukupno za RS obaveze

   IF cVrstaIsplate == "A"
      nPom := nDopr1x + nDopr5x + nD21a + nD22a + nPorNaPlatu

   ELSEIF cVrstaIsplate == "B"
      nPom := nDopr1x + nDopr5x + nD21a + nD22a

   ELSEIF cVrstaIsplate == "C"
      nPom := nPorNaPlatu
   ENDIF
*/

   my_close_all_dbf()
   hb_cdpSelect( "SL852" )
   FOR EACH cKey in hRec:keys()
      IF ValType( hRec[ cKey ] ) == "C"
         hRec[ cKey ] := to_xml_encoding (  hRec[ cKey ] ) // hRec[ cKey ] je cp852 string
      ENDIF
   NEXT

   my_close_all_dbf()
   oReport:aRecords := { hRec }
   oReport:run()

   RETURN .T.
