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
STATIC aPorezi := {}
STATIC s_cM
//STATIC __txt1
//STATIC __txt2
//STATIC __txt3


FUNCTION kalk_lager_lista_prodavnica()

   PARAMETERS lPocStanje

   // indikator gresaka
   LOCAL lImaGresaka := .F.
   //LOCAL cKontrolnaTabela
   LOCAL cPicKol := kalk_pic_kolicina_bilo_gpickol()
   LOCAL cPicCDEm := kalk_prosiri_pic_cjena_za_2()
   LOCAL cPicDem := kalk_pic_iznos_bilo_gpicdem()
   LOCAL cSrKolNula := "0"
   LOCAL _curr_user := "<>"
   LOCAL cMpcIzSif := "N"
   LOCAL cMinK := "N"
   LOCAL _istek_roka := CToD( "" )
   LOCAL _item_istek_roka, _hAttrId, _sh_item_istek_roka
   LOCAL _print := "1"


   cIdFirma := self_organizacija_id()
   cIdKonto := PadR( "1320", FIELD_LENGTH_IDKONTO )

//   o_sifk()
//   o_sifv()
   // o_roba()
   // o_konto()
   // o_partner()

   //cKontrolnaTabela := "N"

   IF ( lPocStanje == NIL )
      lPocStanje := .F.
   ELSE
      lPocStanje := .T.
      o_kalk_pripr()
      cBrPSt := "00001   "
      Box(, 2, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Generacija poc. stanja  - broj dokumenta 80 -" GET cBrPSt
      READ
      BoxC()
   ENDIF

   cNula := "D"
   cK9 := Space( 3 )
   dDatOd := Date()
   dDatDo := Date()
   qqRoba := Space( 60 )
   qqTarifa := Space( 60 )
   qqidvd := Space( 60 )
   qqIdPartn := Space( 60 )
   PRIVATE cPNab := "N"
   PRIVATE cNula := "D"
   PRIVATE cTU := "N"
   PRIVATE cSredCij := "N"
   PRIVATE cPrikazDob := "N"
   PRIVATE cPlVrsta := Space( 1 )
   PRIVATE cPrikK2 := "N"
   PRIVATE aPorezi

   Box(, 18, 68 )

   cGrupacija := Space( 4 )
   cPredhStanje := "N"

   IF !lPocStanje
      cIdKonto := fetch_metric( "kalk_lager_lista_prod_id_konto", _curr_user, cIdKonto )
      cPNab := fetch_metric( "kalk_lager_lista_prod_po_nabavnoj", _curr_user, cPNab )
      cNula := fetch_metric( "kalk_lager_lista_prod_prikaz_nula", _curr_user, cNula )
      dDatOd := fetch_metric( "kalk_lager_lista_prod_datum_od", _curr_user, dDatOd )
      dDatDo := fetch_metric( "kalk_lager_lista_prod_datum_do", _curr_user, dDatDo )
      _print := fetch_metric( "kalk_lager_lista_prod_print", _curr_user, _print )
   ENDIF

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID P_Konto( @cIdKonto )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Artikli " GET qqRoba PICT "@!S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tarife  " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Partneri" GET qqIdPartn PICT "@!S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Vrste dokumenata  " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz Nab.vrijednosti D/N" GET cPNab  VALID cpnab $ "DN" PICT "@!"
      @ box_x_koord() + 7, Col() + 1 SAY "MPC iz sifrarnika D/N" GET cMpcIzSif VALID cMpcIzSif $ "DN" PICT "@!"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz stavki kojima je MPV 0 D/N" GET cNula  VALID cNula $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo


      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Varijanta štampe TXT/ODT (1/2)" GET _print VALID _print $ "12" PICT "@!"

      IF lPocStanje
         @ box_x_koord() + 11, box_y_koord() + 2 SAY "sredi kol=0, nv<>0 (0/1/2)" GET cSrKolNula VALID cSrKolNula $ "012" PICT "@!"
      ENDIF

      @ box_x_koord() + 12, box_y_koord() + 2 SAY "Prikaz robe tipa T/U  (D/N)" GET cTU VALID cTU $ "DN" PICT "@!"
      //@ box_x_koord() + 12, Col() + 2 SAY " generisati kontrolnu tabelu ? " GET cKontrolnaTabela VALID cKontrolnaTabela $ "DN" PICT "@!"
      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Odabir grupacije (prazno-svi) GET" GET cGrupacija PICT "@!"
      @ box_x_koord() + 14, box_y_koord() + 2 SAY "Prikaz prethodnog stanja" GET cPredhStanje PICT "@!" VALID cPredhStanje $ "DN"
      @ box_x_koord() + 14, Col() + 2 SAY8 "Prik. samo kritičnih zaliha (D/N/O) ?" GET cMinK PICT "@!" VALID cMink $ "DNO"

/*
      //IF IsVindija()
         cGr := Space( 10 )
         cPSPDN := "N"
         @ box_x_koord() + 16, box_y_koord() + 2 SAY "Grupa " GET cGr
         @ box_x_koord() + 17, box_y_koord() + 2 SAY "Pregled samo prodaje (D/N) " GET cPSPDN VALID !Empty( cPSPDN ) .AND. cPSPDN $ "DN"  PICT "@!"
      //ENDIF
*/
      READ
      ESC_BCR
      PRIVATE cUslovRoba := Parsiraj( qqRoba, "IdRoba" )
      PRIVATE aUsl2 := Parsiraj( qqTarifa, "IdTarifa" )
      PRIVATE aUsl3 := Parsiraj( qqIDVD, "idvd" )
      PRIVATE aUsl4 := Parsiraj( qqIdPartn, "IdPartner" )
      IF cUslovRoba <> NIL .AND. aUsl2 <> NIL .AND. aUsl3 <> NIL
         EXIT
      ENDIF
      IF aUsl4 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   IF !lPocStanje
      set_metric( "kalk_lager_lista_prod_id_konto", _curr_user, cIdKonto )
      set_metric( "kalk_lager_lista_prod_po_nabavnoj", _curr_user, cPNab )
      set_metric( "kalk_lager_lista_prod_prikaz_nula", _curr_user, cNula )
      set_metric( "kalk_lager_lista_prod_datum_od", _curr_user, dDatOd )
      set_metric( "kalk_lager_lista_prod_datum_do", _curr_user, dDatDo )
      set_metric( "kalk_lager_lista_prod_print", _curr_user, _print )
   ENDIF

   my_close_all_dbf()

   //IF ( cKontrolnaTabela == "D" )
  //    CreTblKontrola()
  // ENDIF

   IF lPocStanje
      o_kalk_pripr()
   ENDIF
   lPrikK2 := .F.
   IF cPrikK2 == "D"
      lPrikK2 := .T.
   ENDIF

  // o_sifk()
  // o_sifv()
   // o_roba()
   // o_tarifa()
   // o_konto()
   // o_partner()
   // o_koncij()

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_by_pkonto_idroba( self_organizacija_id(), cIdKonto )
   MsgC()

   PRIVATE lSMark := .F.
   IF Right( Trim( qqRoba ), 1 ) = "*"
      lSMark := .T.
   ENDIF

   PRIVATE cFilter := ".t."

   IF cUslovRoba <> ".t."
      cFilter += ".and." + cUslovRoba   // roba
   ENDIF
   IF aUsl2 <> ".t."
      cFilter += ".and." + aUsl2   // tarifa
   ENDIF
   IF aUsl3 <> ".t."
      cFilter += ".and." + aUsl3   // idvd
   ENDIF
   IF aUsl4 <> ".t."
      cFilter += ".and." + aUsl4   // partner
   ENDIF

   SET FILTER TO &cFilter
   GO TOP
   EOF CRET

   IF _print == "2"
      // odt stampa
      _params := hb_Hash()
      _params[ "idfirma" ] := self_organizacija_id()
      _params[ "idkonto" ] := cIdKonto
      _params[ "nule" ] := cNula == "D"
      _params[ "datum_od" ] := dDatOd
      _params[ "datum_do" ] := dDatDo
      kalk_prodavnica_llp_odt( _params )
      RETURN .T.
   ENDIF


   nLen := 1

   m := "----- ---------- -------------------- ---"
   nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
   m += " " + REPL( "-", nPom )
   m += " " + REPL( "-", nPom )
   m += " " + REPL( "-", nPom )
   nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
   m += " " + REPL( "-", nPom )
   m += " " + REPL( "-", nPom )
   m += " " + REPL( "-", nPom )
   m += " " + REPL( "-", nPom )

   IF cPredhstanje == "D"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() ) - 2
      m += " " + REPL( "-", nPom )
   ENDIF
   IF cSredCij == "D"
      nPom := Len( kalk_pic_cijena_bilo_gpiccdem() )
      m += " " + REPL( "-", nLen )
   ENDIF

   s_cM := m

   start PRINT cret
   ?
   select_o_konto( cIdKonto )
   SELECT KALK

   PRIVATE nTStrana := 0

   PRIVATE bZagl := {|| kalk_zagl_lager_lista_prodavnica() }

   nTUlaz := 0
   nTIzlaz := 0
   nTPKol := 0
   nTMpv := 0
   nTMPVU := 0
   nTMPVI := 0
   nTNVU := 0
   nTNVI := 0
   // predhodna vrijednost
   nTPMPV := 0
   nTPNV := 0
   nTRabat := 0
   nCol1 := 50
   nCol0 := 50
   nRbr := 0

   Eval( bZagl )

   DO WHILE !Eof() .AND. cIdFirma + cIdKonto == field->idfirma + field->pkonto .AND. IspitajPrekid()

      cIdRoba := field->Idroba

      IF lSMark .AND. SkLoNMark( "ROBA", cIdroba )
         SKIP
         LOOP
      ENDIF

      select_o_roba( cIdRoba )

      nMink := roba->mink

/*
      //IF IsVindija()
         IF !Empty( cGr )
            IF AllTrim( cGr ) <> AllTrim( IzSifKRoba( "GR1", cIdRoba, .F. ) )
               SELECT kalk
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF ( cPSPDN == "D" )
            SELECT kalk
            IF !( kalk->idvd $ "41#42#43" ) .AND. !( kalk->pu_i == "5" )
               SKIP
               LOOP
            ENDIF
            SELECT roba
         ENDIF
      //ENDIF
*/
      SELECT KALK

      nPKol := 0
      nPNV := 0
      nPMPV := 0
      nUlaz := 0
      nIzlaz := 0
      nMPVU := 0
      nMPVI := 0
      nNVU := 0
      nNVI := 0
      nRabat := 0

      IF cTU == "N" .AND. roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      DO WHILE !Eof() .AND. cIdfirma + cIdkonto + cIdroba == field->idFirma + field->pkonto + field->idroba .AND. IspitajPrekid()

         IF lSMark .AND. SkLoNMark( "ROBA", cIdroba )
            SKIP
            LOOP
         ENDIF


         IF cPredhStanje == "D"
            IF field->datdok < dDatOd
               IF field->pu_i == "1"

                  kalk_sumiraj_kolicinu( field->kolicina, 0, @nPKol, 0, lPocStanje, lPrikK2 )
                  nPMPV += field->mpcsapp * field->kolicina
                  nPNV += field->nc * ( field->kolicina )

               ELSEIF field->pu_i == "5"

                  aPorezi := {}
                  set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idroba, @aPorezi, field->idtarifa )
                  aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcsapp, field->nc )
                  nPor1 := aIPor[ 1 ]
                  set_pdv_public_vars()

                  kalk_sumiraj_kolicinu( - ( field->kolicina ), 0, @nPKol, 0, lPocStanje, lPrikK2 )

                  // vrijednost sa popustom
                  // nPMPV -= ( field->mpc + nPor1 ) * field->kolicina

                  nPMPV -= field->mpcsapp * field->kolicina
                  nPNV -= field->nc * field->kolicina

               ELSEIF field->pu_i == "3"
                  // nivelacija
                  nPMPV += field->mpcsapp * field->kolicina
               ELSEIF pu_i == "I"
                  kalk_sumiraj_kolicinu( - ( field->gKolicin2 ), 0, @nPKol, 0, lPocStanje, lPrikK2 )
                  nPMPV -= field->mpcsapp * field->gkolicin2
                  nPNV -= field->nc * field->gkolicin2
               ENDIF
            ENDIF
         ELSE
            IF field->datdok < dDatod .OR. field->datdok > dDatdo
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF cTU == "N" .AND. roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF !Empty( cGrupacija )
            IF cGrupacija <> roba->k1
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF field->DatDok >= dDatOd
            // nisu predhodni podaci
            IF field->pu_i == "1"
               kalk_sumiraj_kolicinu( field->kolicina, 0, @nUlaz, 0, lPocStanje, lPrikK2 )
               nCol1 := PCol() + 1
               nMPVU += field->mpcsapp * field->kolicina
               nNVU += field->nc * ( field->kolicina )
            ELSEIF field->pu_i == "5"

               aPorezi := {}
               set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idroba, @aPorezi, field->idtarifa )
               aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcsapp, field->nc )
               nPor1 := aIPor[ 1 ]
               set_pdv_public_vars()

               IF idvd $ "12#13"
                  kalk_sumiraj_kolicinu( - ( field->kolicina ), 0, @nUlaz, 0, lPocStanje, lPrikK2 )
                  nMPVU -= field->mpcsapp * field->kolicina
                  nNVU -= field->nc * field->kolicina
               ELSE
                  kalk_sumiraj_kolicinu( 0, field->kolicina, 0, @nIzlaz, lPocStanje, lPrikK2 )
                  // vrijednost sa popustom
                  // nMPVI += ( field->mpc + nPor1 ) * field->kolicina
                  nMPVI += field->mpcsapp * field->kolicina
                  nNVI += field->nc * field->kolicina
               ENDIF

            ELSEIF field->pu_i == "3"
               // nivelacija
               nMPVU += field->mpcsapp * field->kolicina
            ELSEIF field->pu_i == "I"
               kalk_sumiraj_kolicinu( 0, field->gkolicin2, 0, @nIzlaz, lPocStanje, lPrikK2 )
               nMPVI += field->mpcsapp * field->gkolicin2
               nNVI += field->nc * field->gkolicin2
            ENDIF
         ENDIF
         SKIP
      ENDDO

      IF cMinK == "D" .AND. ( nUlaz - nIzlaz - nMink ) > 0
         LOOP
      ENDIF

      // ne prikazuj stavke 0
      IF cNula == "D" .OR. Round( nMPVU - nMPVI + nPMPV, 2 ) <> 0

         IF PRow() > page_length()
            FF
            Eval( bZagl )
         ENDIF

         select_o_roba(  cIdRoba )

         SELECT kalk
         aNaz := Sjecistr( roba->naz, 20 )

         ? Str( ++nRbr, 4 ) + ".", cIdRoba

         nCr := PCol() + 1

         @ PRow(), PCol() + 1 SAY aNaz[ 1 ]
         @ PRow(), PCol() + 1 SAY roba->jmj

         nCol0 := PCol() + 1

         IF cPredhStanje == "D"
            @ PRow(), PCol() + 1 SAY nPKol PICT kalk_pic_kolicina_bilo_gpickol()
         ENDIF

         @ PRow(), PCol() + 1 SAY nUlaz PICT kalk_pic_kolicina_bilo_gpickol()
         @ PRow(), PCol() + 1 SAY nIzlaz PICT kalk_pic_kolicina_bilo_gpickol()
         @ PRow(), PCol() + 1 SAY nUlaz - nIzlaz + nPkol PICT kalk_pic_kolicina_bilo_gpickol()

         IF lPocStanje

            SELECT kalk_pripr

            IF Round( nUlaz - nIzlaz, 4 ) <> 0 .AND. cSrKolNula $ "01"

               APPEND BLANK

               REPLACE idFirma WITH cIdfirma
               REPLACE idroba WITH cIdRoba
               REPLACE idkonto WITH cIdKonto
               REPLACE datdok WITH dDatDo + 1
               REPLACE idTarifa WITH set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, cIdRoba, @aPorezi )
               REPLACE datfaktp WITH dDatDo + 1
               REPLACE kolicina WITH nulaz - nizlaz
               REPLACE idvd WITH "80"
               REPLACE brdok WITH cBRPST
               REPLACE nc WITH ( nNVU - nNVI + nPNV ) / ( nulaz - nizlaz + nPKol )
               REPLACE mpcsapp WITH ( nMPVU - nMPVI + nPMPV ) / ( nulaz - nizlaz + nPKol )
               REPLACE TMarza2 WITH "A"

               IF koncij->NAZ == "N1"
                  REPLACE vpc WITH nc
               ENDIF

            ELSEIF cSrKolNula $ "12" .AND. Round( nUlaz - nIzlaz, 4 ) = 0

               IF ( nMPVU - nMPVI + nPMPV ) <> 0

                  // 1 stavka (minus)
                  APPEND BLANK

                  REPLACE idFirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idTarifa WITH set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, cIdRoba, @aPorezi )
                  REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH -1
                  REPLACE idvd WITH "80"
                  REPLACE brdok WITH cBRPST
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH 0
                  REPLACE mpcsapp WITH 0
                  REPLACE TMarza2 WITH "A"

                  IF koncij->NAZ == "N1"
                     REPLACE vpc WITH nc
                  ENDIF

                  // 2 stavka (plus i razlika mpv)
                  APPEND BLANK

                  REPLACE idFirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idTarifa WITH set_pdv_array_by_koncij_region_roba_idtarifa_2_3( cIdKonto, cIdRoba, @aPorezi )
                  REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH 1
                  REPLACE idvd WITH "80"
                  REPLACE brdok WITH cBRPST
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH 0
                  REPLACE mpcsapp WITH ;
                     ( nMPVU - nMPVI + nPMPV )
                  REPLACE TMarza2 WITH "A"

                  IF koncij->NAZ == "N1"
                     REPLACE vpc WITH nc
                  ENDIF

               ENDIF

            ENDIF

            SELECT KALK

         ENDIF

         nCol1 := PCol() + 1

         @ PRow(), PCol() + 1 SAY nMPVU PICT kalk_pic_iznos_bilo_gpicdem()
         @ PRow(), PCol() + 1 SAY nMPVI PICT kalk_pic_iznos_bilo_gpicdem()
         @ PRow(), PCol() + 1 SAY nMPVU - nMPVI + nPMPV PICT kalk_pic_iznos_bilo_gpicdem()

         select_o_koncij( cIdKonto )
         select_o_roba( cIdRoba )

         _mpc := kalk_get_mpc_by_koncij_pravilo()

         SELECT kalk

         IF Round( nUlaz - nIzlaz + nPKOL, 2 ) <> 0

            // if cMpcIzSif == "D"
            // @ prow(), pcol() + 1 SAY _mpc pict kalk_pic_cijena_bilo_gpiccdem()
            // nTMpv += ( ( nUlaz - nIzlaz + nPKOL ) * _mpc )
            // else
            // mpcsapdv
            @ PRow(), PCol() + 1 SAY ( nMPVU - nMPVI + nPMPV ) / ( nUlaz - nIzlaz + nPKol ) PICT kalk_pic_cijena_bilo_gpiccdem()

            // if ROUND(( nMPVU - nMPVI + nPMPV ) / ( nUlaz - nIzlaz + nPKol ), 2) <> ROUND( _mpc, 2 )
            // ?? " ERR MPC =", ALLTRIM( STR( _mpc, 12, 2 )  )
            // endif
            // endif

         ELSE

            // stanje artikla je 0
            @ PRow(), PCol() + 1 SAY 0 PICT kalk_pic_iznos_bilo_gpicdem()

            IF Round( ( nMPVU - nMPVI + nPMPV ), 4 ) <> 0
               ?? " ERR"
               lImaGresaka := .T.
            ENDIF

         ENDIF

         IF cSredCij == "D"
            @ PRow(), PCol() + 1 SAY ( nNVU - nNVI + nPNV + nMPVU - nMPVI + nPMPV ) / ( nUlaz - nIzlaz + nPKol ) / 2 PICT "9999999.99"
         ENDIF

         IF Len( aNaz ) > 1 .OR. cPredhStanje == "D" .OR. cPNab == "D"
            @ PRow() + 1, 0 SAY ""
            IF Len( aNaz ) > 1
               @ PRow(), nCR  SAY aNaz[ 2 ]
            ENDIF
            @ PRow(), nCol0 - 1 SAY ""
         ENDIF

        // IF ( cKontrolnaTabela == "D" )
        //    AzurKontrolnaTabela( cIdRoba, nUlaz - nIzlaz + nPkol, nMpvU - nMpvI + nPMpv )
        // ENDIF

         IF cPredhStanje == "D"
            @ PRow(), PCol() + 1 SAY nPMPV PICT kalk_pic_iznos_bilo_gpicdem()
         ENDIF

         IF cPNab == "D"

            @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_kolicina_bilo_gpickol() ) )

            IF Round( nUlaz - nIzlaz + nPKol, 4 ) <> 0
               @ PRow(), PCol() + 1 SAY ( nNVU - nNVI + nPNV ) / ( nUlaz - nIzlaz + nPKol ) PICT kalk_pic_iznos_bilo_gpicdem()
            ELSE
               @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
            ENDIF

            @ PRow(), nCol1 SAY nNVU PICT kalk_pic_iznos_bilo_gpicdem()
            // @ prow(),pcol()+1 SAY space(len(kalk_pic_iznos_bilo_gpicdem()))
            @ PRow(), PCol() + 1 SAY nNVI PICT kalk_pic_iznos_bilo_gpicdem()
            @ PRow(), PCol() + 1 SAY nNVU - nNVI + nPNV PICT kalk_pic_iznos_bilo_gpicdem()
            @ PRow(), PCol() + 1 SAY _mpc PICT kalk_pic_cijena_bilo_gpiccdem()

         ENDIF


         nTULaz += nUlaz
         nTIzlaz += nIzlaz

         nTPKol += nPKol

         nTMPVU += nMPVU
         nTMPVI += nMPVI

         nTNVU += nNVU
         nTNVI += nNVI

         nTRabat += nRabat

         nTPMPV += nPMPV
         nTPNV += nPNV

         IF roba_barkod_pri_unosu()
            ? Space( 6 ) + roba->barkod
         ENDIF


      ENDIF

   ENDDO

   ? s_cM
   ? "UKUPNO:"

   @ PRow(), nCol0 - 1 SAY ""

   IF cPredhStanje == "D"
      @ PRow(), PCol() + 1 SAY nTPMPV PICT kalk_pic_kolicina_bilo_gpickol()
   ENDIF

   @ PRow(), PCol() + 1 SAY nTUlaz PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTIzlaz PICT kalk_pic_kolicina_bilo_gpickol()
   @ PRow(), PCol() + 1 SAY nTUlaz - nTIzlaz + nTPKol PICT kalk_pic_kolicina_bilo_gpickol()

   nCol1 := PCol() + 1

   @ PRow(), PCol() + 1 SAY nTMPVU PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nTMPVI PICT kalk_pic_iznos_bilo_gpicdem()

   @ PRow(), PCol() + 1 SAY nTMPVU - nTMPVI + nTPMPV PICT kalk_pic_iznos_bilo_gpicdem()
   @ PRow(), PCol() + 1 SAY nTMpv PICT kalk_pic_iznos_bilo_gpicdem()

   IF cPNab == "D"
      @ PRow() + 1, nCol0 - 1 SAY ""
      IF cPredhStanje == "D"
         @ PRow(), PCol() + 1 SAY nTPNV PICT kalk_pic_kolicina_bilo_gpickol()
      ENDIF
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY Space( Len( kalk_pic_iznos_bilo_gpicdem() ) )
      @ PRow(), PCol() + 1 SAY nTNVU PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nTNVI PICT kalk_pic_iznos_bilo_gpicdem()
      @ PRow(), PCol() + 1 SAY nTNVU - nTNVI + nTPNV PICT kalk_pic_iznos_bilo_gpicdem()
   ENDIF

   ? s_cM

   FF
   ENDPRINT

   IF lImaGresaka
      MsgBeep( "Pogledajte artikle za koje je u izvjestaju stavljena oznaka ERR - GRESKA" )
   ENDIF

   IF lPocStanje
      IF lImaGresaka .AND. Pitanje(, "Nulirati pripremu (radi ponavljanja procedure) ?", "D" ) == "D"
         SELECT kalk_pripr
         ZAP
      ELSE
         renumeracija_kalk_pripr( cBrPSt, "80" )
      ENDIF
   ENDIF


   my_close_all_dbf()

   RETURN .T.



// zaglavlje llp
FUNCTION kalk_zagl_lager_lista_prodavnica( lSint )

   IF lSint == NIL
      lSint := .F.
   ENDIF

   Preduzece()
   P_COND
   ?? "KALK: LAGER LISTA  PRODAVNICA ZA PERIOD", dDatOd, "-", dDatDo, " NA DAN "
   ?? Date(), Space( 12 ), "Str:", Str( ++nTStrana, 3 )

   IF !lSint .AND. !Empty( qqIdPartn )
      ? "Obuhvaceni sljedeci partneri:", Trim( qqIdPartn )
   ENDIF

   IF lSint
      ? "Kriterij za prodavnice:", qqKonto
   ELSE
      select_o_konto( cIdkonto )
      ? "Prodavnica:", cIdKonto, "-", konto->naz
   ENDIF

   cSC1 := ""
   cSC2 := ""

   SELECT kalk
   ?U s_cM

   IF cPredhStanje == "D"


      cTmp := " R.  * Artikal  *   Naziv            *jmj*"
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



      cTmp := " br. *          *                    *   *"
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

      IF cPNab == "D"

         cTmp := "     *          *                    *   *"
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
      cTmp := " R.  * Artikal  *   Naziv            *jmj*"
      nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
      cTmp += PadC( "ulaz", nPom ) + " " + PadC( "izlaz", nPom ) + "*"
      cTmp += PadC( "STANJE", nPom ) + "*"
      nPom := Len( kalk_pic_iznos_bilo_gpicdem() )
      cTmp += PadC( "PV.Dug.", nPom ) + "*"
      cTmp += PadC( "PV.Pot.", nPom ) + "*"
      cTmp += PadC( "PV", nPom ) + "*"
      cTmp += PadC( "PC.SA PDV", nPom ) + "*"
      cTmp += cSC1
      ?U cTmp

      cTmp := " br. *          *                    *   *"
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

      IF cPNab == "D"

         cTmp := "     *          *                    *   *"
         nPom := Len( kalk_pic_kolicina_bilo_gpickol() )
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
   ENDIF

   IF cPredhStanje == "D"

      cTmp := "     *    1     *        2           * 3 *"
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

      cTmp := "     *    1     *        2           * 3 *"
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

   RETURN


// kreiranje kontrolne tabele
STATIC FUNCTION CreTblKontrola()

   LOCAL aDbf
   LOCAL cCdx

   aDbf := {}
   cTblKontrola := my_home() + "kontrola.dbf"

   AAdd( aDbf, { "ID", "C", 10, 0 } )
   AAdd( aDbf, { "kolicina", "N", 12, 2 } )
   AAdd( aDbf, { "Mpv", "N", 10, 2 } )

   dbCreate( cTblKontrola, aDbf )
   my_use_temp( "KONTROLA", cTblKontrola, .F., .T. )
   INDEX ON id TAG "ID"

   RETURN .T.

/*
// azuriranje kontrolne tabele
STATIC FUNCTION AzurKontrolnaTabela( cIdRoba, nStanje, nMpv )

   LOCAL nArea

   nArea := Select()

   SELECT ( F_TMP_1 )

   IF !Used()
      USE ( cTblKontrola )
   ENDIF

   SELECT kontrola
   APPEND BLANK
   REPLACE id WITH cIdRoba
   REPLACE kolicina WITH nStanje
   REPLACE Mpv WITH nMpv

   Select( nArea )

   RETURN .T.
*/


STATIC FUNCTION kalk_prodavnica_llp_odt( params )

   IF !_gen_xml( params )
      MsgBeep( "Problem sa generisanjem podataka ili nema podataka !" )
      RETURN .F.
   ENDIF

   download_template( "kalk_llp.odt", "82a8c006e7e6349334332997fbb37e0683d1ea870ad4876a4d9904625afd8495" )

   IF generisi_odt_iz_xml( "kalk_llp.odt", my_home() + "data.xml" )
      prikazi_odt()
   ENDIF

   RETURN .T.



// -----------------------------------------------------
// generisanje xml fajla
// -----------------------------------------------------
STATIC FUNCTION _gen_xml( params )

   LOCAL _idfirma := params[ "idfirma" ]
   LOCAL _idkonto := params[ "idkonto" ]
   LOCAL _idroba, _mpc, _mpcs
   LOCAL _ulaz, _izlaz, _nv_u, _nv_i, _mpv_u, _mpv_i, _rabat
   LOCAL _t_ulaz, _t_izlaz, _t_nv_u, _t_nv_i, _t_mpv_u, _t_mpv_i, _t_rabat
   LOCAL _rbr := 0

   PRIVATE aPorezi

   select_o_konto( params[ "idkonto" ] )

   _t_ulaz := _t_izlaz := _t_nv_u := _t_nv_i := 0
   _t_mpv_u := _t_mpv_i := _t_rabat := 0

   create_xml( my_home() + "data.xml" )
   xml_head()

   xml_subnode( "ll", .F. )

   xml_node( "dat_od", DToC( params[ "datum_od" ] ) )
   xml_node( "dat_do", DToC( params[ "datum_do" ] ) )
   xml_node( "dat", DToC( Date() ) )
   xml_node( "tip", "PRODAVNICA" )
   xml_node( "fid", to_xml_encoding( self_organizacija_id() ) )
   xml_node( "fnaz", to_xml_encoding( self_organizacija_naziv() ) )
   xml_node( "kid", to_xml_encoding( params[ "idkonto" ] ) )
   xml_node( "knaz", to_xml_encoding( AllTrim( konto->naz ) ) )

   SELECT kalk

   DO WHILE !Eof() .AND. _idfirma + _idkonto == field->idfirma + field->pkonto .AND. IspitajPrekid()

      _idroba := field->Idroba

      select_o_roba( _idroba )

      SELECT kalk

      _ulaz := 0
      _izlaz := 0
      _nv_u := 0
      _nv_i := 0
      _mpv_u := 0
      _mpv_i := 0
      _rabat := 0

      DO WHILE !Eof() .AND. _idfirma + _idkonto + _idroba == field->idfirma + field->pkonto + field->idroba .AND. IspitajPrekid()

         IF field->datdok < params[ "datum_od" ] .OR. field->datdok > params[ "datum_do" ]
            SKIP
            LOOP
         ENDIF

         IF field->datdok >= params[ "datum_od" ]
            // nisu predhodni podaci
            IF field->pu_i == "1"
               kalk_sumiraj_kolicinu( field->kolicina, 0, @_ulaz, 0, .F., .F. )
               _mpv_u += field->mpcsapp * field->kolicina
               _nv_u += field->nc * ( field->kolicina )
            ELSEIF field->pu_i == "5"
               aPorezi := {}
               set_pdv_array_by_koncij_region_roba_idtarifa_2_3( field->pkonto, field->idroba, @aPorezi, field->idtarifa )
               aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, field->mpc, field->mpcsapp, field->nc )
               nPor1 := aIPor[ 1 ]
               set_pdv_public_vars()
               IF field->idvd $ "12#13"
                  kalk_sumiraj_kolicinu( - ( field->kolicina ), 0, @_ulaz, 0, .F., .F. )
                  _mpv_u -= field->mpcsapp * field->kolicina
                  _nv_u -= field->nc * field->kolicina
               ELSE
                  kalk_sumiraj_kolicinu( 0, field->kolicina, 0, @_izlaz, .F., .F. )
                  _mpv_i += field->mpcsapp * field->kolicina
                  _nv_i += field->nc * field->kolicina
               ENDIF

            ELSEIF field->pu_i == "3"
               // nivelacija
               _mpv_u += field->mpcsapp * field->kolicina
            ELSEIF field->pu_i == "I"
               kalk_sumiraj_kolicinu( 0, field->gkolicin2, 0, @_izlaz, .F., .F. )
               _mpv_i += field->mpcsapp * field->gkolicin2
               _nv_i += field->nc * field->gkolicin2
            ENDIF

         ENDIF

         SKIP

      ENDDO

      // ne prikazuj stavke 0
      IF params[ "nule" ] .OR. Round( _mpv_u - _mpv_i, 2 ) <> 0

         select_o_koncij( _idkonto )
         select_o_roba( _idroba )

         _mpcs := kalk_get_mpc_by_koncij_pravilo()

         SELECT kalk

         xml_subnode( "items", .F. )

         xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
         xml_node( "id", to_xml_encoding( _idroba ) )
         xml_node( "naz", to_xml_encoding( AllTrim( roba->naz ) ) )
         xml_node( "barkod", to_xml_encoding( AllTrim( roba->barkod ) ) )
         xml_node( "tar", to_xml_encoding( AllTrim( roba->idtarifa ) ) )
         xml_node( "jmj", to_xml_encoding( AllTrim( roba->jmj ) ) )

         xml_node( "ulaz", Str( _ulaz, 12, 3 ) )
         xml_node( "izlaz", Str( _izlaz, 12, 3 ) )
         xml_node( "stanje", Str( _ulaz - _izlaz, 12, 3 ) )

         xml_node( "nvu", Str( _nv_u, 12, 3 ) )
         xml_node( "nvi", Str( _nv_i, 12, 3 ) )
         xml_node( "nv", Str( _nv_u - _nv_i, 12, 3 ) )

         xml_node( "mpvu", Str( _mpv_u, 12, 3 ) )
         xml_node( "mpvi", Str( _mpv_i, 12, 3 ) )
         xml_node( "mpv", Str( _mpv_u - _mpv_i, 12, 3 ) )

         xml_node( "rabat", Str( _rabat, 12, 3 ) )

         xml_node( "mpcs", Str( _mpcs, 12, 3 ) )

         IF Round( _ulaz - _izlaz, 3 ) <> 0
            _mpc := Round( ( _mpv_u - _mpv_i ) / ( _ulaz - _izlaz ), 3 )
            _nc := Round( ( _nv_u - _nv_i ) / ( _ulaz - _izlaz ), 3 )
         ELSE
            _mpc := 0
            _nc := 0
         ENDIF

         xml_node( "mpc", Str( Round( _mpc, 3 ), 12, 3 ) )
         xml_node( "nc", Str( Round( _nc, 3 ), 12, 3 ) )

         IF ( _mpcs <> _mpc )
            xml_node( "err", "ERR" )
         ELSE
            xml_node( "err", "" )
         ENDIF

         _t_ulaz += _ulaz
         _t_izlaz += _izlaz

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
      _ok := .T.
   ENDIF

   RETURN _ok
