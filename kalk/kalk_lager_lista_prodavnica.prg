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

STATIC cTblKontrola := ""
STATIC s_cM
STATIC s_oPDF
STATIC PRINT_LEFT_SPACE := 0

FUNCTION kalk_lager_lista_prodavnica()

   PARAMETERS lPocStanje

   LOCAL lImaGresaka := .F. // indikator gresaka
   LOCAL cPicKol := kalk_pic_kolicina_bilo_gpickol()
   LOCAL cPicCDEm := kalk_prosiri_pic_cjena_za_2()
   LOCAL cPicDem := kalk_pic_iznos_bilo_gpicdem()
   LOCAL cSrKolNula := "0"
   LOCAL cUser := "<>"
   LOCAL cMpcIzSif := "N"

   // LOCAL cMinK := "N"
   // LOCAL _istek_roka := CToD( "" )

   LOCAL cPrintPdfOdt := "1"
   LOCAL cIdFirma, dDatOd, dDatDo, lPocStanje
   LOCAL hZaglParams := hb_Hash()
   LOCAL GetList := {}
   LOCAL cPrikazNabavneVrijednosti := "N"
   LOCAL cPredhStanje := "N"
   LOCAL cIdKonto
   LOCAL cBrDokPocStanje
   LOCAL xPrintOpt, bZagl
   LOCAL cIdRoba
   LOCAL aNazRoba
   LOCAL cLinija
   LOCAL cFilter := ".t."
   LOCAL cIdRobaUslov := Space( 60 )
   LOCAL cIdTarifaUslov := Space( 60 )
   LOCAL cIdVdUslov := Space( 60 )
   LOCAL cIdPartnerUslov := Space( 60 )
   LOCAL cIdRobaFilter
   LOCAL cFilterTarifa
   LOCAL cFilterIdVD
   LOCAL cFilterPartner
   LOCAL hParamsOdt
   LOCAL nCol1, nCol0
   LOCAL cGrupacijaK1
   LOCAL cPrikazNuleDN := "D"
   LOCAL nUlazKol, nIzlazKol, nPredhKol
   LOCAL nMpvUlaz, nMpvIzlaz, nNvUlaz, nNvIzlaz
   LOCAL nPredhMpvSaldo, nPredhNvSaldo
   LOCAL nPom, nLen, nRbr
   LOCAL nTotalUlazKol
   LOCAL nTotalIzlazKol
   LOCAL nTPKol
   LOCAL nTMPVU
   LOCAL nTMPVI
   LOCAL nTNVU
   LOCAL nTNVI
   LOCAL nTRabat
   LOCAL nTotalPredhMpvSaldo
   LOCAL nTotalPredhNvSaldo
   LOCAL cSredCij := "N"
   LOCAL nMpcSifarnik, nMpcSaKartice
   LOCAL nCr
   LOCAL nKolicina
   LOCAL nCol2 := 60
   LOCAL lDrugiRed

   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "1330", FIELD_LENGTH_IDKONTO )

   IF ( lPocStanje == NIL )
      lPocStanje := .F.
   ELSE
      lPocStanje := .T.
      o_kalk_pripr()
      cBrDokPocStanje := "00001   "
      Box(, 2, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Generacija poc. stanja  - broj dokumenta 80 -" GET cBrDokPocStanje
      READ
      BoxC()
   ENDIF

   cPrikazNuleDN := "D"
   // cK9 := Space( 3 )
   dDatOd := Date()
   dDatDo := Date()

   // PRIVATE cPrikazNuleDN := "D"
   // PRIVATE cSredCij := "N"
   // PRIVATE cPrikazDob := "N"
   // PRIVATE cPlVrsta := Space( 1 )
   // PRIVATE cPrikK2 := "N"

   Box(, 18, 70 )

   cGrupacijaK1 := Space( 4 )
   IF !lPocStanje
      cIdKonto := fetch_metric( "kalk_lager_lista_prod_id_konto", cUser, cIdKonto )
      cPrikazNabavneVrijednosti := fetch_metric( "kalk_lager_lista_prod_po_nabavnoj", cUser, "N" )
      cPrikazNuleDN := fetch_metric( "kalk_lager_lista_prod_prikaz_nula", cUser, cPrikazNuleDN )
      dDatOd := fetch_metric( "kalk_lager_lista_prod_datum_od", cUser, dDatOd )
      dDatDo := fetch_metric( "kalk_lager_lista_prod_datum_do", cUser, dDatDo )
      cPrintPdfOdt := fetch_metric( "kalk_lager_lista_prod_print", cUser, cPrintPdfOdt )
   ENDIF

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID P_Konto( @cIdKonto )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Artikli " GET cIdRobaUslov PICT "@!S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tarife  " GET cIdTarifaUslov PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Partneri" GET cIdPartnerUslov PICT "@!S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Vrste dokumenata  " GET cIdVdUslov PICT "@!S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz Nab.vrijednosti D/N" GET cPrikazNabavneVrijednosti  VALID cPrikazNabavneVrijednosti $ "DN" PICT "@!"
      @ box_x_koord() + 7, Col() + 1 SAY8 "MPC iz šifarnika D/N" GET cMpcIzSif VALID cMpcIzSif $ "DN" PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz stavki kojima je MPV 0 D/N" GET cPrikazNuleDN  VALID cPrikazNuleDN $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Varijanta štampe PDF/ODT (1/2)" GET cPrintPdfOdt VALID cPrintPdfOdt $ "12" PICT "@!"
      IF lPocStanje
         @ box_x_koord() + 11, box_y_koord() + 2 SAY "sredi kol=0, nv<>0 (0/1/2)" GET cSrKolNula VALID cSrKolNula $ "012" PICT "@!"
      ENDIF
      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Odabir grupacije k1 (prazno-svi)" GET cGrupacijaK1 PICT "@!"
      @ box_x_koord() + 14, box_y_koord() + 2 SAY "Prikaz prethodnog stanja" GET cPredhStanje PICT "@!" VALID cPredhStanje $ "DN"
      // @ box_x_koord() + 14, Col() + 2 SAY8 "Prikaz samo kritičnih zaliha (D/N/O) ?" GET cMinK PICT "@!" VALID cMink $ "DNO"

      READ
      ESC_BCR

      // hZaglParams[ "sint" ] := .F.
      hZaglParams[ "datod" ] := dDatOd
      hZaglParams[ "datdo" ] := dDatDo
      hZaglParams[ "nabavna" ] := cPrikazNabavneVrijednosti == "D"
      hZaglParams[ "predhodno" ] := cPredhStanje == "D"
      hZaglParams[ "konto" ] := cIdKonto
      hZaglParams[ "partneri_uslov" ] := cIdPartnerUslov
      hZaglParams[ "robe_uslov" ] := cIdRobaUslov

      cIdRobaFilter := Parsiraj( cIdRobaUslov, "IdRoba" )
      cFilterTarifa := Parsiraj( cIdTarifaUslov, "IdTarifa" )
      cFilterIdVD := Parsiraj( cIdVdUslov, "idvd" )
      cFilterPartner := Parsiraj( cIdPartnerUslov, "IdPartner" )
      IF cIdRobaFilter <> NIL .AND. cFilterTarifa <> NIL .AND. cFilterIdVD <> NIL
         EXIT
      ENDIF
      IF cFilterPartner <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   IF !lPocStanje
      set_metric( "kalk_lager_lista_prod_id_konto", cUser, cIdKonto )
      set_metric( "kalk_lager_lista_prod_po_nabavnoj", cUser, cPrikazNabavneVrijednosti )
      set_metric( "kalk_lager_lista_prod_prikaz_nula", cUser, cPrikazNuleDN )
      set_metric( "kalk_lager_lista_prod_datum_od", cUser, dDatOd )
      set_metric( "kalk_lager_lista_prod_datum_do", cUser, dDatDo )
      set_metric( "kalk_lager_lista_prod_print", cUser, cPrintPdfOdt )
   ENDIF

   my_close_all_dbf()

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "font_size" ] := 8
   xPrintOpt[ "opdf" ] := s_oPDF
   legacy_ptxt( .F. )

   IF lPocStanje
      o_kalk_pripr()
   ENDIF
   // lPrikK2 := .F.
   // IF cPrikK2 == "D"
   // lPrikK2 := .T.
   // ENDIF

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_by_pkonto_idroba( self_organizacija_id(), cIdKonto )
   MsgC()

   // PRIVATE lSMark := .F.
   // IF Right( Trim( cIdRobaUslov ), 1 ) = "*"
   // lSMark := .T.
   // ENDIF

   IF cIdRobaFilter <> ".t."
      cFilter += ".and." + cIdRobaFilter   // roba
   ENDIF
   IF cFilterTarifa <> ".t."
      cFilter += ".and." + cFilterTarifa   // tarifa
   ENDIF
   IF cFilterIdVD <> ".t."
      cFilter += ".and." + cFilterIdVD   // idvd
   ENDIF
   IF cFilterPartner <> ".t."
      cFilter += ".and." + cFilterPartner   // partner
   ENDIF

   SET FILTER TO &cFilter
   GO TOP
   EOF CRET

   IF cPrintPdfOdt == "2" // odt stampa
      hParamsOdt := hb_Hash()
      hParamsOdt[ "idfirma" ] := self_organizacija_id()
      hParamsOdt[ "idkonto" ] := cIdKonto
      hParamsOdt[ "nule" ] := cPrikazNuleDN == "D"
      hParamsOdt[ "datum_od" ] := dDatOd
      hParamsOdt[ "datum_do" ] := dDatDo
      kalk_prodavnica_llp_odt( hParamsOdt )
      RETURN .T.
   ENDIF

   nLen := 1

   cLinija := "----- ---------- " + Replicate( "-", 30 ) + " ---"
   nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
   cLinija += " " + REPL( "-", nPom )
   cLinija += " " + REPL( "-", nPom )
   cLinija += " " + REPL( "-", nPom )
   nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
   cLinija += " " + REPL( "-", nPom )
   cLinija += " " + REPL( "-", nPom )
   cLinija += " " + REPL( "-", nPom )
   cLinija += " " + REPL( "-", nPom )

   IF cPredhstanje == "D"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() ) - 2
      cLinija += " " + REPL( "-", nPom )
   ENDIF
   IF cSredCij == "D"
      nPom := Len( kalk_pic_cijena_bilo_gpiccdem() )
      cLinija += " " + REPL( "-", nLen )
   ENDIF

   s_cM := cLinija
   select_o_konto( cIdKonto )
   SELECT KALK

   bZagl := {|| kalk_zagl_lager_lista_prodavnica( hZaglParams ) }

   nTotalUlazKol := 0
   nTotalIzlazKol := 0
   nTPKol := 0
   nTMPVU := 0
   nTMPVI := 0
   nTNVU := 0
   nTNVI := 0
   // predhodna vrijednost
   nTotalPredhMpvSaldo := 0
   nTotalPredhNvSaldo := 0
   nTRabat := 0
   nCol1 := 50
   nCol0 := 50
   nRbr := 0

   IF f18_start_print( NIL, xPrintOpt,  "LAGER LISTA PRODAVNICA [" + AllTrim( cIdKonto ) + "] " + DToC( dDatOd ) + " - " + DToC( dDatDo )  + "  NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF
   Eval( bZagl )

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == kalk->idfirma + kalk->pkonto .AND. ispitaj_prekid()

      cIdRoba := kalk->Idroba
      select_o_roba( cIdRoba )
      // nMink := roba->mink
      SELECT KALK
      nPredhKol := 0
      nPredhNvSaldo := 0
      nPredhMpvSaldo := 0
      nUlazKol := 0
      nIzlazKol := 0
      nMpvUlaz := 0
      nMpvIzlaz := 0
      nNvUlaz := 0
      nNvIzlaz := 0
      // nRabat := 0

      IF roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      DO WHILE !Eof() .AND. cIdfirma + cIdkonto + cIdroba == kalk->idFirma + kalk->pkonto + kalk->idroba .AND. ispitaj_prekid()

         check_nova_strana( bZagl, s_oPDF )
         IF cPredhStanje == "D"
            IF kalk->datdok < dDatOd
               IF kalk->pu_i == "1"
                  kalk_sumiraj_kolicinu( kalk->kolicina, 0, @nPredhKol, 0, lPocStanje )
                  nPredhMpvSaldo += kalk->mpcsapp * kalk->kolicina
                  nPredhNvSaldo += kalk->nc * ( kalk->kolicina )

               ELSEIF kalk->pu_i == "5"
                  kalk_sumiraj_kolicinu( - kalk->kolicina, 0, @nPredhKol, 0, lPocStanje )
                  nPredhMpvSaldo -= kalk->mpcsapp * kalk->kolicina
                  nPredhNvSaldo -= kalk->nc * kalk->kolicina

               ELSEIF kalk->pu_i == "3"
                  // nivelacija
                  nPredhMpvSaldo += kalk->mpcsapp * kalk->kolicina
               ELSEIF kalk->pu_i == "I"
                  kalk_sumiraj_kolicinu( - kalk->gKolicin2, 0, @nPredhKol, 0, lPocStanje )
                  nPredhMpvSaldo -= kalk->mpcsapp * kalk->gkolicin2
                  nPredhNvSaldo -= kalk->nc * kalk->gkolicin2
               ENDIF
            ENDIF
         ELSE
            IF kalk->datdok < dDatod .OR. kalk->datdok > dDatdo
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF !Empty( cGrupacijaK1 )
            IF cGrupacijaK1 <> roba->k1
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF kalk->DatDok >= dDatOd
            // nisu predhodni podaci
            IF kalk->pu_i == "1"
               kalk_sumiraj_kolicinu( kalk->kolicina, 0, @nUlazKol, 0, lPocStanje )
               nCol1 := PCol() + 1
               nMpvUlaz += kalk->mpcsapp * kalk->kolicina
               nNvUlaz += kalk->nc * ( kalk->kolicina )

            ELSEIF kalk->pu_i == "5"
               IF kalk->idvd $ "12#13"
                  kalk_sumiraj_kolicinu( - kalk->kolicina, 0, @nUlazKol, 0, lPocStanje )
                  nMpvUlaz -= kalk->mpcsapp * kalk->kolicina
                  nNvUlaz -= kalk->nc * kalk->kolicina
               ELSE
                  kalk_sumiraj_kolicinu( 0, kalk->kolicina, 0, @nIzlazKol, lPocStanje )
                  nMpvIzlaz += kalk->mpcsapp * kalk->kolicina
                  nNvIzlaz += kalk->nc * kalk->kolicina
               ENDIF

            ELSEIF kalk->pu_i == "3"
               // nivelacija
               nMpvUlaz += kalk->mpcsapp * kalk->kolicina
            ELSEIF kalk->pu_i == "I"
               kalk_sumiraj_kolicinu( 0, kalk->gkolicin2, 0, @nIzlazKol, lPocStanje )
               nMpvIzlaz += kalk->mpcsapp * kalk->gkolicin2
               nNvIzlaz += kalk->nc * kalk->gkolicin2
            ENDIF
         ENDIF
         SKIP
      ENDDO

      // IF cMinK == "D" .AND. ( nUlazKol - nIzlazKol - nMink ) > 0
      // LOOP
      // ENDIF

      // ne prikazuj stavke 0
      IF cPrikazNuleDN == "D" .OR. Round( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo, 2 ) <> 0

         check_nova_strana( bZagl, s_oPDF )
         select_o_roba(  cIdRoba )
         SELECT kalk
         aNazRoba := Sjecistr( roba->naz, 30 )

         ? Str( ++nRbr, 4 ) + ".", cIdRoba
         nCr := PCol() + 1
         @ PRow(), PCol() + 1 SAY aNazRoba[ 1 ]
         @ PRow(), PCol() + 1 SAY roba->jmj

         nCol0 := PCol() + 1
         IF cPredhStanje == "D"
            @ PRow(), PCol() + 1 SAY nPredhKol PICT kalk_pic_kolicina_bilo_gpickol()
         ENDIF

         @ PRow(), PCol() + 1 SAY nUlazKol PICT kalk_pic_kolicina_bilo_gpickol()
         @ PRow(), PCol() + 1 SAY nIzlazKol PICT kalk_pic_kolicina_bilo_gpickol()
         @ PRow(), PCol() + 1 SAY nUlazKol - nIzlazKol + nPredhKol PICT kalk_pic_kolicina_bilo_gpickol()

         IF lPocStanje

            SELECT kalk_pripr
            IF Round( nUlazKol - nIzlazKol, 4 ) <> 0 .AND. cSrKolNula $ "01"
               APPEND BLANK
               REPLACE idFirma WITH cIdfirma
               REPLACE idroba WITH cIdRoba
               REPLACE idkonto WITH cIdKonto
               REPLACE datdok WITH dDatDo + 1
               REPLACE idTarifa WITH roba->idtarifa
               // REPLACE datfaktp WITH dDatDo + 1
               REPLACE kolicina WITH nUlazKol - nIzlazKol
               REPLACE idvd WITH "80"
               REPLACE brdok WITH cBrDokPocStanje
               REPLACE nc WITH ( nNvUlaz - nNvIzlaz + nPredhNvSaldo ) / ( nUlazKol - nIzlazKol + nPredhKol )
               REPLACE mpcsapp WITH ( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo ) / ( nUlazKol - nIzlazKol + nPredhKol )
               REPLACE TMarza2 WITH "A"
               IF koncij->NAZ == "N1"
                  REPLACE vpc WITH kalk_pripr->nc
               ENDIF

            ELSEIF cSrKolNula $ "12" .AND. Round( nUlazKol - nIzlazKol, 4 ) = 0

               IF ( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo ) <> 0
                  // 1 stavka (minus)
                  APPEND BLANK
                  REPLACE idFirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idTarifa WITH roba->idtarifa
                  // REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH -1
                  REPLACE idvd WITH "80"
                  REPLACE brdok WITH cBrDokPocStanje
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH 0
                  REPLACE mpcsapp WITH 0
                  REPLACE TMarza2 WITH "A"
                  IF koncij->NAZ == "N1"
                     REPLACE vpc WITH kalk_pripr->nc
                  ENDIF

                  // 2 stavka (plus i razlika mpv)
                  APPEND BLANK
                  REPLACE idFirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idTarifa WITH roba->idtarifa
                  // REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH 1
                  REPLACE idvd WITH "80"
                  REPLACE brdok WITH cBrDokPocStanje
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH 0
                  REPLACE mpcsapp WITH ;
                     ( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo )
                  REPLACE TMarza2 WITH "A"
                  IF koncij->NAZ == "N1"
                     REPLACE vpc WITH kalk_pripr->nc
                  ENDIF
               ENDIF
            ENDIF
            SELECT KALK

         ENDIF

         nCol1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY nMpvUlaz PICT kalk_pic_iznos_bilo_gpicdem()
         @ PRow(), PCol() + 1 SAY nMpvIzlaz PICT kalk_pic_iznos_bilo_gpicdem()
         @ PRow(), PCol() + 1 SAY nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo PICT kalk_pic_iznos_bilo_gpicdem()

         select_o_koncij( cIdKonto )
         select_o_roba( cIdRoba )

         nMpcSifarnik := kalk_get_mpc_by_koncij_pravilo()
         SELECT kalk
         nMpcSaKartice := 0
         nKolicina := nUlazKol - nIzlazKol + nPredhKol
         IF Round( nUlazKol - nIzlazKol + nPredhKol, 2 ) <> 0
            nMpcSaKartice := ( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo ) / nKolicina
            nCol2 := PCol() + 1
            @ PRow(), nCol2 SAY nMpcSaKartice PICT kalk_pic_cijena_bilo_gpiccdem()
            IF Round( nKolicina, 4 ) < 0
               ?? " ERRK"
               lImaGresaka := .T.
            ELSEIF Round( nMpcSaKartice, 2 ) <> Round( nMpcSifarnik, 2 )
               ?? " ERRC"
               lImaGresaka := .T.
            ENDIF
         ELSE // stanje artikla je 0
            nCol2 := PCol() + 1
            @ PRow(), nCol2 SAY nMpcSaKartice PICT kalk_pic_iznos_bilo_gpicdem()
            IF Round( ( nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo ), 4 ) <> 0
               ?? " ERR0"
               lImaGresaka := .T.
            ENDIF

         ENDIF

         IF cSredCij == "D"
            @ PRow(), PCol() + 1 SAY ( nNvUlaz - nNvIzlaz + nPredhNvSaldo + nMpvUlaz - nMpvIzlaz + nPredhMpvSaldo ) / nKolicina / 2 PICT "9999999.99"
         ENDIF

         lDrugiRed := .F.
         IF Len( aNazRoba ) > 1 .OR. cPredhStanje == "D" .OR. cPrikazNabavneVrijednosti == "D" .OR. Len( aNazRoba ) > 1
            @ PRow() + 1, 0 SAY ""
            IF Len( aNazRoba ) > 1
               @ PRow(), nCR  SAY aNazRoba[ 2 ]
            ENDIF
            @ PRow(), nCol0 - 1 SAY ""
            lDrugiRed := .T.
         ENDIF

         IF cPredhStanje == "D"
            @ PRow(), PCol() + 1 SAY nPredhMpvSaldo PICT kalk_pic_iznos_bilo_gpicdem()
         ENDIF

         IF cPrikazNabavneVrijednosti == "D"
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )

            IF Round( nUlazKol - nIzlazKol + nPredhKol, 4 ) <> 0
               @ PRow(), PCol() + 1 SAY ( nNvUlaz - nNvIzlaz + nPredhNvSaldo ) / nKolicina PICT kalk_pic_iznos_bilo_gpicdem()
            ELSE
               @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
            ENDIF

            @ PRow(), nCol1 SAY nNvUlaz PICT kalk_pic_iznos_bilo_gpicdem()
            // @ prow(),pcol()+1 SAY space(len(kalk_pic_iznos_bilo_gpicdem()))
            @ PRow(), PCol() + 1 SAY nNvIzlaz PICT kalk_pic_iznos_bilo_gpicdem()
            @ PRow(), PCol() + 1 SAY nNvUlaz - nNvIzlaz + nPredhNvSaldo PICT kalk_pic_iznos_bilo_gpicdem()
            IF Round( nMpcSifarnik, 4 ) <> Round( nMpcSaKartice, 4 )
               @ PRow(), PCol() + 1 SAY nMpcSifarnik PICT kalk_pic_cijena_bilo_gpiccdem()
            ENDIF
         ELSE
            IF Round( nMpcSifarnik, 4 ) <> Round( nMpcSaKartice, 4 )
               @ PRow() + iif( lDrugiRed, 0, 1 ), nCol2 SAY nMpcSifarnik PICT kalk_pic_cijena_bilo_gpiccdem()
            ENDIF
         ENDIF

         nTotalUlazKol += nUlazKol
         nTotalIzlazKol += nIzlazKol
         nTPKol += nPredhKol
         nTMPVU += nMpvUlaz
         nTMPVI += nMpvIzlaz
         nTNVU += nNvUlaz
         nTNVI += nNvIzlaz
         // nTRabat += nRabat
         nTotalPredhMpvSaldo += nPredhMpvSaldo
         nTotalPredhNvSaldo += nPredhNvSaldo

         IF roba_barkod_pri_unosu()
            ? Space( 6 ) + roba->barkod
         ENDIF

      ENDIF
   ENDDO

   ?U s_cM
   ?U "UKUPNO:"

   @ PRow(), nCol0 - 1 SAY ""

   IF cPredhStanje == "D"
      @ PRow(), PCol() + 1 SAY nTotalPredhMpvSaldo PICT kalk_pic_kolicina_bilo_gpickol()
   ENDIF
   @ PRow(), PCol() + 1 SAY nTotalUlazKol PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTotalIzlazKol PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTotalUlazKol - nTotalIzlazKol + nTPKol PICT kalk_pic_kolicina_bilo_gpickol()

   nCol1 := PCol() + 1
   @ PRow(), PCol() + 1 SAY nTMPVU PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nTMPVI PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nTMPVU - nTMPVI + nTotalPredhMpvSaldo PICT kalk_pic_iznos_bilo_gpicdem()

   IF cPrikazNabavneVrijednosti == "D"
      @ PRow() + 1, nCol0 - 1 SAY ""
      IF cPredhStanje == "D"
         @ PRow(), PCol() + 1 SAY nTotalPredhNvSaldo PICT kalk_pic_kolicina_bilo_gpickol()
      ENDIF
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY nTNVU PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nTNVI PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nTNVU - nTNVI + nTotalPredhNvSaldo PICT kalk_pic_iznos_bilo_gpicdem()
   ENDIF

   ?U s_cM

   f18_end_print( NIL, xPrintOpt )

   IF lImaGresaka
      MsgBeep( "Pogledati artikle za koje je u izvještaju stavljena oznaka ERR - GREŠKA" )
   ENDIF

   IF lPocStanje
      IF lImaGresaka .AND. Pitanje(, "Nulirati pripremu (radi ponavljanja procedure) ?", "D" ) == "D"
         SELECT kalk_pripr
         ZAP
      ELSE
         renumeracija_kalk_pripr( cBrDokPocStanje, "80" )
      ENDIF
   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION kalk_zagl_lager_lista_prodavnica( hZaglParams )

   LOCAL cTmp, nPom, cSc1, cSc2

   Preduzece()
   IF !Empty( hZaglParams[ "partneri_uslov" ] )
      ?U "Obuhvaćeni sljedeći partneri:", Trim( hZaglParams[ "partneri_uslov" ] )
   ENDIF
   select_o_konto( hZaglParams[ "konto" ] )
   ? "Prodavnica:", hZaglParams[ "konto" ], "-", konto->naz

   cSC1 := ""
   cSC2 := ""

   SELECT kalk
   ?U s_cM

   IF hZaglParams[ "predhodno" ]
      cTmp := " R.  * Artikal  *" + PadC( "Naziv", 30 ) + "*jmj*"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "Predh.st", nPom ) + "*"
      cTmp += PadC( "ulaz", nPom ) + " " + PadC( "izlaz", nPom ) + "*"
      cTmp += PadC( "STANJE", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += PadC( "PV.Dug.", nPom ) + "*"
      cTmp += PadC( "PV.Pot.", nPom ) + "*"
      cTmp += PadC( "PV", nPom ) + "*"
      nPom := Len( kalk_pic_cijena_bilo_gpiccdem() )
      cTmp += PadC( "PC.SA PDV", nPom ) + "*"
      cTmp += cSC1

      ?U cTmp

      cTmp := " br. *          *" + Space( 30 ) + "*   *"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "Kol/MPV", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + " " + REPL( " ", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += cSC2

      ?U cTmp

      IF hZaglParams[ "nabavna" ]
         cTmp := "     *          *" + Space( 30 ) + "*   *"
         nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
         cTmp += REPL( " ", nPom ) + "*"
         cTmp += REPL( " ", nPom ) + " " + REPL( " ", nPom ) + "*"
         nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
         cTmp += PadC( "SR.NAB.C", nPom ) + "*"
         cTmp += PadC( "NV.Dug.", nPom ) + "*"
         cTmp += PadC( "NV.Pot", nPom ) + "*"
         cTmp += PadC( "NV", nPom ) + "*"
         cTmp += REPL( " ", nPom ) + "*"
         cTmp += cSC2

         ?U cTmp
      ENDIF
   ELSE
      cTmp := " R.  * Artikal  *" + PadC( "Naziv", 30 ) + "*jmj*"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "ulaz", nPom ) + " " + PadC( "izlaz", nPom ) + "*"
      cTmp += PadC( "STANJE", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += PadC( "MPV.Dug.", nPom ) + "*"
      cTmp += PadC( "MPV.Pot.", nPom ) + "*"
      cTmp += PadC( "MPV", nPom ) + "*"
      cTmp += PadC( "MPC", nPom ) + "*"
      cTmp += cSC1
      ?U cTmp

      cTmp := " br. *          *" + Space( 30 ) + "*   *"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += REPL( " ", nPom ) + " " + REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += REPL( " ", nPom ) + "*"
      cTmp += cSC2

      ?U cTmp
      IF hZaglParams[ "nabavna" ]
         cTmp := "     *          *" + Space( 30 ) + "*   *"
         nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
         cTmp += REPL( " ", nPom ) + " " + REPL( " ", nPom ) + "*"
         nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
         cTmp += PadC( "Ncj", nPom ) + "*"
         cTmp += PadC( "NV.Dug.", nPom ) + "*"
         cTmp += PadC( "NV.Pot", nPom ) + "*"
         cTmp += PadC( "NV", nPom ) + "*"
         cTmp += REPL( " ", nPom ) + "*"
         cTmp += cSC2
         ?U cTmp
      ENDIF
   ENDIF

   IF hZaglParams[ "predhodno" ]
      cTmp := "     *    1     *" + PadC( "2", 30 ) + "* 3 *"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "4", nPom ) + "*"
      cTmp += PadC( "5", nPom ) + "*"
      cTmp += PadC( "6", nPom ) + "*"
      cTmp += PadC( "5 - 6", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += PadC( "7", nPom ) + "*"
      cTmp += PadC( "8", nPom ) + "*"
      cTmp += PadC( "7 - 8", nPom ) + "*"
      cTmp += PadC( "9", nPom ) + "*"
      cTmp += cSC2

      ?U cTmp

   ELSE
      cTmp := "     *    1     *" + PadC( "2", 30 ) + "* 3 *"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "4", nPom ) + "*"
      cTmp += PadC( "5", nPom ) + "*"
      cTmp += PadC( "4 - 5", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += PadC( "6", nPom ) + "*"
      cTmp += PadC( "7", nPom ) + "*"
      cTmp += PadC( "6 - 7", nPom ) + "*"
      cTmp += PadC( "8", nPom ) + "*"
      cTmp += cSC2
      ?U cTmp

   ENDIF

   ?U s_cM

   RETURN .T.


STATIC FUNCTION kalk_prodavnica_llp_odt( hParamsOdt )

   IF !kalk_gen_xml_lager_lista_prodavnica( hParamsOdt )
      MsgBeep( "Problem sa generisanjem podataka ili nema podataka !" )
      RETURN .F.
   ENDIF

   download_template( "kalk_llp.odt", "82a8c006e7e6349334332997fbb37e0683d1ea870ad4876a4d9904625afd8495" )

   IF generisi_odt_iz_xml( "kalk_llp.odt", my_home() + "data.xml" )
      prikazi_odt()
   ENDIF

   RETURN .T.


STATIC FUNCTION kalk_gen_xml_lager_lista_prodavnica( hParamsOdt )

   LOCAL cIdFirma := hParamsOdt[ "idfirma" ]
   LOCAL cIdKonto := hParamsOdt[ "idkonto" ]
   LOCAL cIdroba, nMpc, nMpcSif
   LOCAL nUlaz, nIzlaz, _nv_u, _nv_i, _mpv_u, _mpv_i, _rabat
   LOCAL _t_ulaz, _t_izlaz, _t_nv_u, _t_nv_i, _t_mpv_u, _t_mpv_i, _t_rabat
   LOCAL _rbr := 0
   LOCAL nNC

   select_o_konto( hParamsOdt[ "idkonto" ] )
   _t_ulaz := _t_izlaz := _t_nv_u := _t_nv_i := 0
   _t_mpv_u := _t_mpv_i := _t_rabat := 0

   create_xml( my_home() + "data.xml" )
   xml_head()

   xml_subnode( "ll", .F. )
   xml_node( "dat_od", DToC( hParamsOdt[ "datum_od" ] ) )
   xml_node( "dat_do", DToC( hParamsOdt[ "datum_do" ] ) )
   xml_node( "dat", DToC( Date() ) )
   xml_node( "tip", "PRODAVNICA" )
   xml_node( "fid", to_xml_encoding( self_organizacija_id() ) )
   xml_node( "fnaz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "kid", to_xml_encoding( hParamsOdt[ "idkonto" ] ) )
   xml_node( "knaz", to_xml_encoding( AllTrim( konto->naz ) ) )

   SELECT kalk

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == kalk->idfirma + kalk->pkonto .AND. ispitaj_prekid()

      cIdroba := kalk->Idroba
      select_o_roba( cIdroba )

      SELECT kalk

      nUlaz := 0
      nIzlaz := 0
      _nv_u := 0
      _nv_i := 0
      _mpv_u := 0
      _mpv_i := 0
      _rabat := 0
      DO WHILE !Eof() .AND. cIdFirma + cIdKonto + cIdroba == kalk->idfirma + kalk->pkonto + kalk->idroba .AND. ispitaj_prekid()

         IF kalk->datdok < hParamsOdt[ "datum_od" ] .OR. kalk->datdok > hParamsOdt[ "datum_do" ]
            SKIP
            LOOP
         ENDIF

         IF kalk->datdok >= hParamsOdt[ "datum_od" ]
            // nisu predhodni podaci
            IF kalk->pu_i == "1"
               kalk_sumiraj_kolicinu( kalk->kolicina, 0, @nUlaz, 0, .F., .F. )
               _mpv_u += kalk->mpcsapp * kalk->kolicina
               _nv_u += kalk->nc * ( kalk->kolicina )

            ELSEIF kalk->pu_i == "5"
               IF kalk->idvd $ "12#13"
                  kalk_sumiraj_kolicinu( - ( kalk->kolicina ), 0, @nUlaz, 0, .F., .F. )
                  _mpv_u -= kalk->mpcsapp * kalk->kolicina
                  _nv_u -= kalk->nc * kalk->kolicina
               ELSE
                  kalk_sumiraj_kolicinu( 0, kalk->kolicina, 0, @nIzlaz, .F., .F. )
                  _mpv_i += kalk->mpcsapp * kalk->kolicina
                  _nv_i += kalk->nc * kalk->kolicina
               ENDIF

            ELSEIF kalk->pu_i == "3"
               // nivelacija
               _mpv_u += kalk->mpcsapp * kalk->kolicina
            ELSEIF kalk->pu_i == "I"
               kalk_sumiraj_kolicinu( 0, kalk->gkolicin2, 0, @nIzlaz, .F., .F. )
               _mpv_i += kalk->mpcsapp * kalk->gkolicin2
               _nv_i += kalk->nc * kalk->gkolicin2
            ENDIF

         ENDIF

         SKIP

      ENDDO

      IF hParamsOdt[ "nule" ] .OR. Round( _mpv_u - _mpv_i, 2 ) <> 0 // ne prikazuj stavke 0

         select_o_koncij( cIdKonto )
         select_o_roba( cIdroba )
         nMpcSif := kalk_get_mpc_by_koncij_pravilo()

         SELECT kalk

         xml_subnode( "items", .F. )
         xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
         xml_node( "id", to_xml_encoding( cIdroba ) )
         xml_node( "naz", to_xml_encoding( AllTrim( roba->naz ) ) )
         xml_node( "barkod", to_xml_encoding( AllTrim( roba->barkod ) ) )
         xml_node( "tar", to_xml_encoding( AllTrim( roba->idtarifa ) ) )
         xml_node( "jmj", to_xml_encoding( AllTrim( roba->jmj ) ) )
         xml_node( "ulaz", Str( nUlaz, 12, 3 ) )
         xml_node( "izlaz", Str( nIzlaz, 12, 3 ) )
         xml_node( "stanje", Str( nUlaz - nIzlaz, 12, 3 ) )
         xml_node( "nvu", Str( _nv_u, 12, 3 ) )
         xml_node( "nvi", Str( _nv_i, 12, 3 ) )
         xml_node( "nv", Str( _nv_u - _nv_i, 12, 3 ) )
         xml_node( "mpvu", Str( _mpv_u, 12, 3 ) )
         xml_node( "mpvi", Str( _mpv_i, 12, 3 ) )
         xml_node( "mpv", Str( _mpv_u - _mpv_i, 12, 3 ) )
         xml_node( "rabat", Str( _rabat, 12, 3 ) )
         xml_node( "mpcs", Str( nMpcSif, 12, 3 ) )

         IF Round( nUlaz - nIzlaz, 3 ) <> 0
            nMpc := Round( ( _mpv_u - _mpv_i ) / ( nUlaz - nIzlaz ), 3 )
            nNC := Round( ( _nv_u - _nv_i ) / ( nUlaz - nIzlaz ), 3 )
         ELSE
            nMpc := 0
            nNC := 0
         ENDIF

         xml_node( "mpc", Str( Round( nMpc, 3 ), 12, 3 ) )
         xml_node( "nc", Str( Round( nNC, 3 ), 12, 3 ) )

         IF ( nMpcSif <> nMpc )
            xml_node( "err", "ERR" )
         ELSE
            xml_node( "err", "" )
         ENDIF

         _t_ulaz += nUlaz
         _t_izlaz += nIzlaz
         _t_mpv_u += _mpv_u
         _t_mpv_i += _mpv_i
         _t_nv_u += _nv_u
         _t_nv_i += _nv_i
         _t_rabat += _rabat

         xml_subnode( "items", .T. )

      ENDIF

   ENDDO

   xml_node( "ulaz", Str( _t_ulaz, 12, 3 ) )
   xml_node( "izlaz", Str( _t_izlaz, 12, 3 ) )
   xml_node( "stanje", Str( _t_ulaz - _t_izlaz, 12, 3 ) )
   xml_node( "nvu", Str( _t_nv_u, 12, 3 ) )
   xml_node( "nvi", Str( _t_nv_i, 12, 3 ) )
   xml_node( "nv", Str( _t_nv_u - _t_nv_i, 12, 3 ) )
   xml_node( "mpvu", Str( _t_mpv_u, 12, 3 ) )
   xml_node( "mpvi", Str( _t_mpv_i, 12, 3 ) )
   xml_node( "mpv", Str( _t_mpv_u - _t_mpv_i, 12, 3 ) )
   xml_node( "rabat", Str( _t_rabat, 12, 3 ) )

   xml_subnode( "ll", .T. )

   close_xml()
   my_close_all_dbf()

   IF _rbr > 0
      RETURN .T.
   ENDIF

   RETURN .F.
