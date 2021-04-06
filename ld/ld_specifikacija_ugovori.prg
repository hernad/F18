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


FUNCTION ld_specifikacija_plate_ostali()

   LOCAL GetList := {}
   LOCAL aPom := {}
   LOCAL i := 0
   LOCAL j := 0
   LOCAL k := 0
   LOCAL nPom
   LOCAL uNaRuke
   LOCAL aOps := {}
   LOCAL _proizvj_ini := my_home() + "proizvj.ini"
   LOCAL cMatBr := Space( 13 )
   PRIVATE aSpec := {}
   PRIVATE gPici := "9,999,999,999,999,999" + IF( gZaok > 0, PadR( ".", gZaok + 1, "9" ), "" )
   PRIVATE gPici2 := "9,999,999,999,999,999" + IF( gZaok2 > 0, PadR( ".", gZaok2 + 1, "9" ), "" )
   PRIVATE gPici3 := "999,999,999,999.99"

   cIdRJ := "  "
   qqIDRJ := ""
   qqOpSt := ""

   nPorOlaksice := 0
   nBrutoOsnova := 0
   nBrutoOsBenef := 0
   nPojBrOsn := 0
   nPojBrBenef := 0
   nPorOsnovica := 0
   uNaRuke := 0

   nDanOd := prvi_dan_mjeseca( ld_tekuci_mjesec() )
   nMjesecOd := ld_tekuci_mjesec()
   nGodinaOd := ld_tekuca_godina()
   nDanDo := zadnji_dan_mjeseca( ld_tekuci_mjesec() )
   nMjesecDo := ld_tekuci_mjesec()
   nGodinaDo := ld_tekuca_godina()

   // varijable izvjestaja
   nMjesec := ld_tekuci_mjesec()
   nGodina := ld_tekuca_godina()

   cObracun := gObracun

   cDopr1 := "1X"
   cDopr2 := "2X"

   cFirmNaz := Space( 35 )
   cFirmAdresa := Space( 35 )
   cFirmOpc := Space( 35 )
   cFirmVD := Space( 50 )

   ld_specifikacije_otvori_tabele()

   cFirmNaz := fetch_metric( "org_naziv", NIL, cFirmNaz )
   cFirmNaz := PadR( cFirmNaz, 35 )

   cFirmAdresa := fetch_metric( "ld_firma_adresa", NIL, cFirmAdresa )
   cFirmAdresa := PadR( cFirmAdresa, 35 )

   cFirmOpc := fetch_metric( "ld_firma_opcina", NIL, cFirmOpc )
   cFirmOpc := PadR( cFirmOpc, 35 )

   cFirmVD := fetch_metric( "ld_firma_vrsta_djelatnosti", NIL, cFirmVD )
   cFirmVD := PadR( cFirmVD, 50 )

   cDopr1 := fetch_metric( "ld_spec_ugovori_doprinos_1", NIL, cDopr1 )
   cDopr2 := fetch_metric( "ld_spec_ugovori_doprinos_2", NIL, cDopr2 )

   qqIdRj := fetch_metric( "ld_specifikacija_rj", NIL, qqIdRJ )
   qqOpSt := fetch_metric( "ld_specifikacija_opcine", NIL, qqOpSt )

   qqIdRj := PadR( qqIdRj, 80 )
   qqOpSt := PadR( qqOpSt, 80 )

   cMatBr := fetch_metric( "ld_specifikacija_maticni_broj", NIL, cMatBr )
   cMatBR := PadR( cMatBr, 13 )

   dDatIspl := Date()

   DO WHILE .T.

      Box(, 11, 75 )

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno-sve): "  GET qqIdRJ PICT "@!S15"

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Opstina stanov.(prazno-sve): "  GET qqOpSt PICT "@!S20"

      @ box_x_koord() + 2, Col() + 1 SAY "Obr.:" GET cObracun ;
         WHEN ld_help_broj_obracuna( .T., cObracun )  VALID ld_valid_obracun( .T., cObracun )

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Period od:" GET nDanOd PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nMjesecOd PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nGodinaOd PICT "9999"
      @ box_x_koord() + 3, Col() + 1 SAY "do:" GET nDanDo PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nMjesecDo PICT "99"
      @ box_x_koord() + 3, Col() + 1 SAY "/" GET nGodinaDo PICT "9999"


      @ box_x_koord() + 4, box_y_koord() + 2 SAY " Naziv: " GET cFirmNaz
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Adresa: " GET cFirmAdresa
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Opcina: " GET cFirmOpc
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Vrsta djelatnosti: " GET cFirmVD

      @ box_x_koord() + 4, box_y_koord() + 52 SAY "ID.broj :" GET cMatBR
      @ box_x_koord() + 5, box_y_koord() + 52 SAY "Dat.ispl:" GET dDatIspl


      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Doprinos zdravstvo (iz)" GET cDopr1
      @ box_x_koord() + 10, box_y_koord() + 2 SAY "     Doprinos pio (na)" GET cDopr2

      READ
      clvbox()
      ESC_BCR
      BoxC()

      aUslRJ := Parsiraj( qqIdRj, "IDRJ" )
      aUslOpSt := Parsiraj( qqOpSt, "IDOPSST" )
      IF ( aUslRJ <> NIL .AND. aUslOpSt <> NIL )
         EXIT
      ENDIF
   ENDDO

   set_metric( "org_naziv", NIL, cFirmNaz )
   set_metric( "ld_firma_adresa", NIL, cFirmAdresa )
   set_metric( "ld_firma_opcina", NIL, cFirmOpc )
   set_metric( "ld_firma_vrsta_djelatnosti", NIL, cFirmVD )
   set_metric( "ld_spec_ugovori_doprinos_1", NIL, cDopr1 )
   set_metric( "ld_spec_ugovori_doprinos_2", NIL, cDopr2 )

   qqIdRj := Trim( qqIdRj )
   qqOpSt := Trim( qqOpSt )

   set_metric( "ld_specifikacija_rj", NIL, qqIdRJ )
   set_metric( "ld_specifikacija_opcine", NIL, qqOpSt )
   set_metric( "ld_specifikacija_maticni_broj", NIL, cMatBr )

   ld_porezi_i_doprinosi_iz_sezone( nGodina, nMjesec )

   cIniName := _proizvj_ini

   UzmiIzIni( cIniName, 'Varijable', "NAZ", cFirmNaz, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "ADRESA", cFirmAdresa, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "OPCINA", cFirmOpc, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "VRDJ", cFirmVD, 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', "GODOD", Razrijedi( Str( nGodinaOd, 4 ) ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "GODDO", Razrijedi( Str( nGodinaDo, 4 ) ), 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', "MJOD", Razrijedi( StrTran( Str( nMjesecOd, 2 ), " ", "0" ) ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "MJDO", Razrijedi( StrTran( Str( nMjesecDo, 2 ), " ", "0" ) ), 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', "DANOD", Razrijedi( StrTran( Str( nDanOd, 2 ), " ", "0" ) ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "DANDO", Razrijedi( StrTran( Str( nDanDo, 2 ), " ", "0" ) ), 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', "MATBR", Razrijedi( cMatBR ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', "DATISPL", DToC( dDatIspl ), 'WRITE' )

   cObracun := Trim( cObracun )

   ld_pozicija_parobr( nMjesec, nGodina, cObracun, Left( qqIdRJ, 2 ) )

   // SELECT LD
   // SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )

   // GO TOP
   // HSEEK Str( nGodina, 4 ) + Str( nMjesec, 2 )
   seek_ld_2( NIL, nGodina, nMjesec )


   PRIVATE cFilt := ".t."

   IF !Empty( qqIdRJ )
      cFilt += ( ".and." + aUslRJ )
   ENDIF

   IF !Empty( cObracun )
      cFilt += ( ".and. OBR==" + dbf_quote( cObracun ) )
   ENDIF

   SET FILTER TO &cFilt
   GO TOP


   nUNeto := 0
   nPorNaPlatu := 0
   nKoefLO := 0
   nURadnika := 0
   nULicOdbitak := 0
   nUPorOsn := 0
   nPovD1X := 0
   nPovD2X := 0
   nDrD1X := 0
   nDrD2X := 0
   nTrosk := 0
   nUTrosk := 0
   nBO := 0
   nUBrSaTr := 0
   nUkupno := 0
   nUOsnDr := 0
   nUOsnPov := 0
   nBrOsnPov := 0
   nBrOsnDr := 0
   nPNaPlPov := 0
   nPNaPlDr := 0

   // prvo resetuj stare ini vrijednosti
   nPom := 0
   UzmiIzIni( cIniName, 'Varijable', 'POVPRIH', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVRASH', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVDOH', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRDOH', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVDZ', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVDP', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRDZDR', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRDPIO', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DZDRU', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DPIOU', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVPOSN', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVPIZN', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRPOSN', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRPIZN', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POREZ', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'U016', nPom, 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'UKOBAV', nPom, 'WRITE' )


   DO WHILE Str( nGodina, 4 ) + Str( nMjesec, 2 ) == Str( godina, 4 ) + Str( mjesec, 2 )

      select_o_radn( LD->idradn )
      select_o_ops( radn->idopsst )
      SELECT RADN
      cRTR := get_ld_rj_tip_rada( ld->idradn, ld->idrj )

      // ugovor o djelu, aut.honorar i predsjednici
      IF !( cRTR $ "U#A#P" )
         SELECT ld
         SKIP
         LOOP
      ENDIF

      nRSpr_koef := 0
      nTrosk := 0

      lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad ) .AND. cRTR $ "A#U"

      // da li koristi troskove
      cKTrosk := radn->trosk

      SELECT LD

      IF !( RADN->( &aUslOpSt ) )
         SKIP 1
         LOOP
      ENDIF

      nKoefLO := ld->ulicodb
      nULicOdbitak += nKoefLO

      nUNeto += ld->uneto

      nBrSaTr := ld_get_bruto_osnova( ld->uneto, cRTR, nKoefLO, nRSpr_koef, cKTrosk )

      // samo za povremene
      IF cRTR $ "A#U"
         nUBrSaTr += nBrSaTr
      ENDIF

      nPTrosk := 0

      IF cRTR == "U"
         nPTrosk := gUgTrosk
      ELSEIF cRTR == "A"
         nPTrosk := gAHTrosk
      ELSE
         nPTrosk := 0
      ENDIF

      IF cRTR $ "A#U" .AND. lInRS == .T.
         nPTrosk := 0
      ENDIF

      // ako netrebaju troskovi onda ih nema
      IF cKTrosk == "N"
         nPTrosk := 0
      ENDIF

      IF cRTR $ "A#U"
         // troskovi su ?
         nTrosk := nBrSaTr * ( nPTrosk / 100 )
         nUTrosk += nTrosk
      ENDIF

      // prava bruto osnova bez troskova je ?
      nBO := nBrSaTr - nTrosk

      IF cRTR $ "A#U"
         nBrOsnPov += nBO
      ELSE
         nBrOsnDr += nBO
      ENDIF

      IF cRTR $ "A#U"
         // prihodi
         nPom := nUBrSaTr
         UzmiIzIni( cIniName, 'Varijable', 'POVPRIH', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

         // rashodi
         nPom := nUTrosk
         UzmiIzIni( cIniName, 'Varijable', 'POVRASH', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

         // dohodak
         nPom := nBrOsnPov
         UzmiIzIni( cIniName, 'Varijable', 'POVDOH', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

      ELSE
         nPom := nBrOsnDr
         UzmiIzIni( cIniName, 'Varijable', 'DRDOH', FormNum2( nPom, 16, gPici2 ), 'WRITE' )
      ENDIF

      select_o_dopr()
      GO TOP

      DO WHILE !Eof()

         IF DOPR->poopst == "1"

            nBOO := 0

            FOR i := 1 TO Len( aOps )
               IF !( DOPR->id $ aOps[ i, 2 ] )
                  nBOO += aOps[ i, 3 ]
               ENDIF
            NEXT
            nBOO := ld_get_bruto_osnova( nBOO, cRTR, nKoefLO )
         ELSE
            IF cRTR $ "A#U"
               nBOO := nBrOsnPov
            ELSE
               nBOO := nBrOsnDr
            ENDIF
         ENDIF

         SKIP 1
      ENDDO

      IF cRTR == "U"
         nkD1X := get_dopr( cDopr1, "U" )
         nkD2X := get_dopr( cDopr2, "U" )
      ELSEIF cRTR == "A"
         nkD1X := get_dopr( cDopr1, "A" )
         nkD2X := get_dopr( cDopr2, "A" )
      ELSE
         nkD1X := get_dopr( cDopr1, "P" )
         nkD2X := get_dopr( cDopr2, "P" )
      ENDIF

      IF cRTR $ "A#U"
         // povremeni poslovi doprinosi
         IF lInRS == .F.
            nPovD1X := round2( nBrOsnPov * nkD1X / 100, gZaok2 )
         ENDIF
         nPovD2X := round2( nBrOsnPov * nkD2X / 100, gZaok2 )
      ELSE
         // ostali poslovi doprinosi
         nDrD1X := round2( nBrOsnDr * nkD1X / 100, gZaok2 )
         nDrD2X := round2( nBrOsnDr * nkD2X / 100, gZaok2 )
      ENDIF

      nPojD1X := round2( nBO * nkD1X / 100, gZaok2 )

      // upisi povremeni poslovi doprinosi
      nPom := nPovD1X
      UzmiIzIni( cIniName, 'Varijable', 'POVDZ', FormNum2( nPom, 16, gPici2 ), 'WRITE' )
      nPom := nPovD2X
      UzmiIzIni( cIniName, 'Varijable', 'POVDP', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

      // upisi ostali samostalni rad - doprinosi
      nPom := nDrD1X
      UzmiIzIni( cIniName, 'Varijable', 'DRDZDR', FormNum2( nPom, 16, gPici2 ), 'WRITE' )
      nPom := nDrD2X
      UzmiIzIni( cIniName, 'Varijable', 'DRDPIO', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

      // ukupno dopr.zdravstvo
      nPom := nPovD1X + nDrD1X
      UzmiIzIni( cIniName, 'Varijable', 'DZDRU', FormNum2( nPom, 16, gPici2 ), 'WRITE' )
      // ukupno dopr.pio
      nPom := nPovD2X + nDrD2X
      UzmiIzIni( cIniName, 'Varijable', 'DPIOU', FormNum2( nPom, 16, gPici2 ), 'WRITE' )

      IF cRTR $ "A#U"
         nOsnPov := ( nBO - nPojD1X )
         IF lINRS == .T.
            nOsnPov := 0
         ENDIF
         nUOsnPov += nOsnPov
      ELSE
         nOsnDr := ( nBO - nPojD1X )
         nUOsnDr += nOsnDr
      ENDIF


      // porez na platu i ostali porez
      select_o_por()
      GO TOP

      DO WHILE !Eof()

         ld_opstina_stanovanja_rada( POR->poopst )

         IF !ld_ima_u_ops_porez_ili_doprinos( "POR", POR->id )
            SKIP 1
            LOOP
         ENDIF

         IF por->por_tip == "B"
            IF cRTR $ "A#U"
               nPNaPlPov  += POR->iznos * Max( nOsnPov, PAROBR->prosld * gPDLimit / 100 ) / 100
            ELSE
               nPNaPlDr  += POR->iznos * Max( nOsnDr, PAROBR->prosld * gPDLimit / 100 ) / 100
            ENDIF
         ENDIF
         SKIP 1
      ENDDO

      SELECT LD

      nURadnika++

      SKIP 1

   ENDDO

   nPNaPlPov := round2( nPNaPlPov, gZaok2 )
   nPNaPlDr := round2( nPNaPlDr, gZaok2 )

   nUkupno := nPNaPlPov + nPNaPlDr + nPovD1X + nPovD2X + nDrD1X + nDrD2X

   UzmiIzIni( cIniName, 'Varijable', 'POVPOSN', FormNum2( nUOsnPov, 16, gPici2 ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'POVPIZN', FormNum2( nPNaPlPov, 16, gPici2 ), 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', 'DRPOSN', FormNum2( nUOsnDr, 16, gPici2 ), 'WRITE' )
   UzmiIzIni( cIniName, 'Varijable', 'DRPIZN', FormNum2( nPNaPlDr, 16, gPici2 ), 'WRITE' )

   UzmiIzIni( cIniName, 'Varijable', 'POREZ', FormNum2( nPNaPlDr + nPNaPlPov, 16, gPici2 ), 'WRITE' )

   // ukupno radnika
   UzmiIzIni( cIniName, 'Varijable', 'U016', Str( nURadnika, 0 ), 'WRITE' )

   nPom = nUkupno
   UzmiIzIni( cIniName, 'Varijable', 'UKOBAV', FormNum2( nPom, 16, gPici2 ), 'WRITE' )


   IniRefresh()
   // Odstampaj izvjestaj

   my_close_all_dbf()

   IF LastKey() != K_ESC

      cSpecRtm := "specbu"
      f18_rtm_print( cSpecRtm, "DUMMY", "1" )

   ENDIF

   RETURN
