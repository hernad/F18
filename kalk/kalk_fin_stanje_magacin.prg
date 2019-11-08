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




FUNCTION finansijsko_stanje_magacin()

   LOCAL cTipDok, cDokNaz
   LOCAL  _a_exp
   LOCAL lExport := .F.
   LOCAL cExportDN := "N"
   LOCAL _launch
   LOCAL cPartnNaz, cPartnMj, cPartnPtt
   LOCAL hParams
   LOCAL nVPC

   _o_tbl()

   PicDEM := kalk_prosiri_pic_iznos_za_2()
   PicCDEM := kalk_prosiri_pic_cjena_za_2()

   cIdKonto := PadR( "1320", FIELD_LENGTH_IDKONTO )
   dDatOd := CToD( "" )
   dDatDo := Date()
   qqRoba := Space( 60 )
   qqMKonta := Space( 60 )
   qqTarifa := Space( 60 )
   qqidvd := Space( 60 )
   PRIVATE cPNab := "N"
   PRIVATE cNula := "D"
   PRIVATE cErr := "N"
   PRIVATE cPapir := "1"

   Box( , 11, 60 )

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Varijanta (1/2)" GET cPapir VALID cPapir $ "12"

      READ

      IF cPapir == "2"
         qqidvd := PadR( "10;", 60 )
      ENDIF

      PRIVATE cViseKonta := "N"

      @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Više konta (D/N)" GET cViseKonta VALID cViseKonta $ "DN" PICT "@!"

      READ

      IF cViseKonta == "N"
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID "." $ cidkonto .OR. P_Konto( @cIdKonto )
      ELSE
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Konta " GET qqMKonta PICT "@!S30"
      ENDIF

      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Tarife  " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Vrste dokumenata  " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od " GET dDatOd
      @ box_x_koord() + 9, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Export podataka XLSX (D/N) ?" GET cExportDN VALID cExportDN $ "DN" PICT "@!"

      READ

      ESC_BCR

      PRIVATE cUslovTarifa := Parsiraj( qqTarifa, "IdTarifa" )
      PRIVATE cUslovIdVD := Parsiraj( qqIDVD, "idvd" )

      IF cViseKonta == "D"
         PRIVATE cUslovKonta := Parsiraj( qqMKonta, "mkonto" )
      ENDIF

      IF cUslovTarifa <> NIL
         EXIT
      ENDIF

      IF cUslovIdVD <> NIL
         EXIT
      ENDIF

      IF cViseKonta == "D" .AND. cUslovKonta <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   // treba li exportovati podatke
   IF cExportDN == "D"
      lExport := .T.
   ENDIF

   IF lExport
      _cre_tmp_tbl()
      _o_tbl()

   ENDIF

   cIdFirma := self_organizacija_id()
   hParams := hb_Hash()

   hParams[ "idfirma" ] := cIdFirma

   IF Len( Trim( cIdkonto ) ) == 3  // sinteticki konto
      cIdkonto := Trim( cIdkonto )
      hParams[ "mkonto_sint" ] := cIdKonto
   ELSE
      hParams[ "mkonto" ] := cIdKonto
   ENDIF

   IF !Empty( dDatOd )
      hParams[ "dat_od" ] := dDatOd
   ENDIF

   IF !Empty( dDatDo )
      hParams[ "dat_do" ] := dDatDo
   ENDIF

   hParams[ "order_by" ] := "idFirma,datdok,idvd,brdok,rbr"

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   find_kalk_za_period( hParams )
   MsgC()

   select_o_koncij( cIdkonto )

   SELECT kalk
   EOF CRET

   nLen := 1

   aFLLM := {}
   AAdd( aFLLM, { 6, " R.br" } )
   AAdd( aFLLM, { 8, " Datum" } )
   AAdd( aFLLM, { 11, " Broj dok." } )
   IF cPapir == "2"
      AAdd( aFLLM, { 32, " Sifra i naziv partnera" } )
      AAdd( aFLLM, { 13, "fakt./otp" } )
      AAdd( aFLLM, { 10, " NV Dug." } )
      AAdd( aFLLM, { Len( PicDem ), c10T1 } )
      AAdd( aFLLM, { Len( PicDem ), c10T2 } )
      AAdd( aFLLM, { Len( PicDem ), c10T3 } )
      AAdd( aFLLM, { Len( PicDem ), c10T4 } )
      AAdd( aFLLM, { Len( PicDem ), c10T5 } )
      AAdd( aFLLM, { Len( PicDem ), " marza" } )
      AAdd( aFLLM, { Len( PicDem ), " VPV Dug." } )
   ELSE
      AAdd( aFLLM, { Len( PicDem ), " NV.Dug." } )
      AAdd( aFLLM, { Len( PicDem ), " NV.Pot." } )
      AAdd( aFLLM, { Len( PicDem ), " NV" } )
      AAdd( aFLLM, { Len( PicDem ), " VPV Dug." } )
      AAdd( aFLLM, { Len( PicDem ), " VPV Pot." } )
      AAdd( aFLLM, { Len( PicDem ), " VPV" } )
      AAdd( aFLLM, { Len( PicDem ), " Rabat" } )
   ENDIF
   PRIVATE cLine := SetRptLineAndText( aFLLM, 0 )
   PRIVATE cText1 := SetRptLineAndText( aFLLM, 1, "*" )

   START PRINT CRET

   ?

   IF cPapir == "2"
      P_COND2
   ELSE
      P_COND
   ENDIF

   PRIVATE nTStrana := 0
   PRIVATE bZagl := {|| kalk_zagl_fin_stanje_magacin() }

   Eval( bZagl )
   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   nCol1 := nCol0 := 27
   PRIVATE nRbr := 0

   IF cPapir != "4"
      ntDod1 := ntDod2 := ntDod3 := ntDod4 := ntDod5 := ntDod6 := ntDod7 := ntDod8 := 0
   ENDIF

   DO WHILE !Eof() .AND. cIdfirma == idfirma
      nUlaz := 0
      nIzlaz := 0
      nVPVU := 0
      nVPVI := 0
      nNVU := 0
      nNVI := 0
      nRabat := 0
      IF cPapir != "4"
         nDod1 := nDod2 := nDod3 := nDod4 := nDod5 := nDod6 := nDod7 := nDod8 := 0
      ENDIF

      IF cViseKonta == "N" .AND. mkonto <> cIdkonto
         SKIP
         LOOP
      ENDIF

      cBrFaktP := brfaktp
      cIdPartner := idpartner
      dDatDok := datdok
      cBroj := idvd + "-" + brdok
      cTipDok := idvd


      SELECT tdok
      HSEEK cTipDok
      cDokNaz := field->naz

      select_o_partner( cIdPartner )

      cPartnNaz := field->naz
      cPartnPtt := field->ptt
      cPartnMj := field->mjesto
      cPartnAdr := field->adresa

      SELECT KALK

      info_bar( "kalk_mag", DToC( dDatDok ) +  " " + mkonto + " : " + cBroj )

      DO WHILE !Eof() .AND. cIdFirma + DToS( dDatDok ) + cBroj == idFirma + DToS( datdok ) + idvd + "-" + brdok

         IF cViseKonta == "N" .AND. ( datdok < dDatOd .OR. datdok > dDatDo .OR. mkonto <> cidkonto )
            SKIP
            LOOP
         ENDIF

         IF Len( cUslovTarifa ) <> 0
            IF !Tacno( cUslovTarifa )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF Len( cUslovIdVD ) <> 0
            IF !Tacno( cUslovIdVD )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF cViseKonta == "D" .AND. Len( cUslovKonta ) <> 0
            IF !Tacno( cUslovKonta )
               SKIP
               LOOP
            ENDIF
         ENDIF

         select_o_roba( kalk->idroba )
         SELECT KALK
         nVPC := vpc_magacin_rs()

         IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
            nVPVU += Round( nVPC * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            nNVU += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
         ELSEIF mu_i == "5"
            nVPVI += Round( nVPC * kolicina, gZaokr )
            nRabat += Round( rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI += Round( nc * kolicina, gZaokr )
         ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
            nVPVI -= Round( nVPC * kolicina, gZaokr )
            nRabat -= Round( rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI -= Round( nc * kolicina, gZaokr )
         ELSEIF mu_i == "3"    // nivelacija
            nVPVU += Round( nVPC * kolicina, gZaokr )
         ENDIF

         IF cPapir != "4"
            nDod1 += kalk_marza_veleprodaja()
            nDod2 += kalk_marza_maloprodaja()
            nDod3 += prevoz; nDod4 += prevoz2; nDod5 += banktr
            nDod6 += spedtr; nDod7 += cardaz; nDod8 += zavtr
         ENDIF

         SKIP 1

      ENDDO

      IF Round( nNVU - nNVI, 4 ) == 0 .AND. Round( nVPVU - nVPVI, 4 ) == 0
         LOOP
      ENDIF

      IF PRow() > page_length()
         FF
         Eval( bZagl )
      ENDIF

      ? Str( ++nRbr, 5 ) + ".", dDatDok, cBroj
      nCol1 := PCol() + 1

      nTVPVU += nVPVU; nTVPVI += nVPVI
      nTNVU += nNVU; nTNVI += nNVI
      nTRabat += nRabat
      ntDod1 += nDod1; ntDod2 += nDod2; ntDod3 += nDod3; ntDod4 += nDod4; ntDod5 += nDod5
      ntDod6 += nDod6; ntDod7 += nDod7; ntDod8 += nDod8

      IF cPapir = "2"
         @ PRow(), PCol() + 1 SAY cIdPartner + " " + PadR( cPartnNaz, 28 ) + " " + cBrFaktP
         @ PRow(), PCol() + 1 SAY nNVU PICT picdem
         @ PRow(), PCol() + 1 SAY nDod3 PICT picdem
         @ PRow(), PCol() + 1 SAY nDod5 PICT picdem
         @ PRow(), PCol() + 1 SAY nDod6 PICT picdem
         @ PRow(), PCol() + 1 SAY nDod7 PICT picdem
         @ PRow(), PCol() + 1 SAY nDod8 PICT picdem
         @ PRow(), PCol() + 1 SAY nDod1 PICT picdem
         @ PRow(), PCol() + 1 SAY nVPVU PICT picdem
      ELSE
         @ PRow(), PCol() + 1 SAY nNVU PICT picdem
         @ PRow(), PCol() + 1 SAY nNVI PICT picdem
         @ PRow(), PCol() + 1 SAY nTNVU - nTNVI PICT picdem
         @ PRow(), PCol() + 1 SAY nVPVU PICT picdem
         @ PRow(), PCol() + 1 SAY nVPVI PICT picdem
         @ PRow(), PCol() + 1 SAY nTVPVU - nTVPVI PICT picdem
         @ PRow(), PCol() + 1 SAY nRabat PICT picdem
      ENDIF

      IF lExport

         _add_to_exp( cBroj, dDatDok, cDokNaz, cIdPartner, ;
            cPartnNaz, cPartnMj, cPartnPtt, cPartnAdr, cBrFaktP, ;
            nNVU, nNVI, nTNVU - nTNVI, ;
            nVPVU, nVPVI, nTVPVU - nTVPVI, ;
            nRabat )

      ENDIF

   ENDDO

   ? cLine
   ? "UKUPNO:"

   IF cPapir == "2"
      @ PRow(), PCol() + 64 SAY ntNVU PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod3 PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod5 PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod6 PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod7 PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod8 PICT picdem
      @ PRow(), PCol() + 1 SAY ntDod1 PICT picdem
      @ PRow(), PCol() + 1 SAY ntVPVU PICT picdem
   ELSE
      @ PRow(), nCol1    SAY ntNVU PICT picdem
      @ PRow(), PCol() + 1 SAY ntNVI PICT picdem
      @ PRow(), PCol() + 1 SAY ntNVU - NtNVI PICT picdem
      @ PRow(), PCol() + 1 SAY ntVPVU PICT picdem
      @ PRow(), PCol() + 1 SAY ntVPVI PICT picdem
      @ PRow(), PCol() + 1 SAY ntVPVU - NtVPVI PICT picdem
      @ PRow(), PCol() + 1 SAY ntRabat PICT picdem
   ENDIF

   ? cLine

   IF lExport
      // dodaj stavku ukupno
      _add_to_exp( "UKUPNO:", CToD( "" ), "", "", ;
         "", "", "", "", "", ;
         nTNVU, nTNVI, nTNVU - nTNVI, ;
         nTVPVU, nTVPVI, nTVPVU - nTVPVI, ;
         nTRabat )
   ENDIF

   FF
   ENDPRINT

   // pregled izvjestaja nakon generisanja u spreadsheet aplikaciji
   IF lExport
      open_r_export_table()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION kalk_zagl_fin_stanje_magacin()

   Preduzece()

   IF cPapir == "2"
      P_COND2
   ELSE
      P_COND
   ENDIF

   IF cViseKonta == "N"
      select_o_konto( cIdkonto )
   ENDIF

   ??U "KALK:MAG Finansijsko stanje za period", dDatOd, "-", dDatDo, " NA DAN "
   ?? Date(), Space( 10 ), "Str:", Str( ++nTStrana, 3 )

   IF cViseKonta == "N"
      ? "Magacin:", cIdKonto, "-", konto->naz
   ELSE
      ? "Magacini:", qqMKonta
   ENDIF

   SELECT kalk

   ? cLine
   ? cText1
   ? cLine

   RETURN .T.


// ----------------------------------------------
// kreiranje pomocne tabele izvjestaja
// ----------------------------------------------
STATIC FUNCTION _cre_tmp_tbl()

   LOCAL _dbf := {}

   AAdd( _dbf, { "broj", "C", 10, 0 } )
   AAdd( _dbf, { "datum", "D",  8, 0 } )
   AAdd( _dbf, { "vr_dok", "C", 30, 0 } )
   AAdd( _dbf, { "idpartner", "C",  6, 0 } )
   AAdd( _dbf, { "part_naz", "C", 100, 0 } )
   AAdd( _dbf, { "part_mj", "C", 50, 0 } )
   AAdd( _dbf, { "part_ptt", "C", 10, 0 } )
   AAdd( _dbf, { "part_adr", "C", 50, 0 } )
   AAdd( _dbf, { "br_fakt", "C", 20, 0 } )
   AAdd( _dbf, { "nv_dug", "N", 15, 2 } )
   AAdd( _dbf, { "nv_pot", "N", 15, 2 } )
   AAdd( _dbf, { "nv_saldo", "N", 15, 2 } )
   AAdd( _dbf, { "vp_dug", "N", 15, 2 } )
   AAdd( _dbf, { "vp_pot", "N", 15, 2 } )
   AAdd( _dbf, { "vp_saldo", "N", 15, 2 } )
   AAdd( _dbf, { "vp_rabat", "N", 15, 2 } )

   create_dbf_r_export( _dbf )

   RETURN _dbf


STATIC FUNCTION _add_to_exp( broj_dok, datum_dok, vrsta_dok, id_partner, ;
      part_naz, part_mjesto, part_ptt, part_adr, broj_fakture, ;
      n_v_dug, n_v_pot, n_v_saldo, ;
      v_p_dug, v_p_pot, v_p_saldo, ;
      v_p_rabat )

   select_o_r_export()

   APPEND BLANK
   REPLACE field->broj WITH broj_dok
   REPLACE field->datum WITH datum_dok
   REPLACE field->vr_dok WITH vrsta_dok
   REPLACE field->idpartner WITH id_partner
   REPLACE field->part_naz WITH part_naz
   REPLACE field->part_mj WITH part_mjesto
   REPLACE field->part_ptt WITH part_ptt
   REPLACE field->part_adr WITH part_adr
   REPLACE field->br_fakt WITH broj_fakture
   REPLACE field->nv_dug WITH n_v_dug
   REPLACE field->nv_pot WITH n_v_pot
   REPLACE field->nv_saldo WITH n_v_saldo
   REPLACE field->vp_dug WITH v_p_dug
   REPLACE field->vp_pot WITH v_p_pot
   REPLACE field->vp_saldo WITH v_p_saldo
   REPLACE field->vp_rabat WITH v_p_rabat

   SELECT KALK

   RETURN .T.




// -----------------------------------
// otvaranje potrebnih tabela
// -----------------------------------
STATIC FUNCTION _o_tbl()

   // o_sifk()
   // o_sifv()
   o_tdok()
   // o_roba()
   o_koncij()
   // o_konto()
   // o_partner()

   RETURN .T.
