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

MEMVAR gZaokr


/* -----------------------------------------------
 pomocna tabela finansijskog stanja magacina

 uslovi koji se u hash matrici trebaju koristi
 su:
 - "vise_konta" (D/N)
 - "konto" (lista konta ili jedan konto)
 - "datum_od"
 - "datum_do"
 - "tarife"
 - "vrste_dok"

koristi TKV

*/
FUNCTION kalk_gen_fin_stanje_magacina_za_tkv( hParams )

   LOCAL cUslovKonto := ""
   LOCAL dDatumOd := Date()
   LOCAL dDatumDo := Date()
   LOCAL _tarife := ""
   LOCAL _vrste_dok := ""
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL lViseKonta := .F.
   LOCAL nDbfArea, nTrec
   LOCAL _ulaz, _izlaz, nRabat
   LOCAL nNvUlaz, nNvIzlaz, nVPVUlaz, nVPVIzlaz
   LOCAL nMarzaVP, nMarzaMP, _tr_prevoz, _tr_prevoz_2
   LOCAL _tr_bank, _tr_zavisni, _tr_carina, _tr_sped
   LOCAL _br_fakt, _tip_dok, _tip_dok_naz, _id_partner
   LOCAL _partn_naziv, _partn_ptt, _partn_mjesto, _partn_adresa
   LOCAL _broj_dok, _dat_dok
   LOCAL cFilterKonto := ""
   LOCAL cFilterVrsteDok := ""
   LOCAL cFilterTarife := ""
   LOCAL cGledatiUslugeDN := "N"
   LOCAL cViseKontaDN := "N"
   LOCAL _cnt := 0
   LOCAL hKalkParams
   LOCAL cIdKonto
   LOCAL nVPC

   // uslovi generisanja se uzimaju iz hash matrice
   // moguce vrijednosti su:
   IF hb_HHasKey( hParams, "vise_konta" )
      cViseKontaDN := hParams[ "vise_konta" ]
   ENDIF

   IF hb_HHasKey( hParams, "konto" )
      cUslovKonto := hParams[ "konto" ]
   ENDIF
   IF hb_HHasKey( hParams, "datum_od" )
      dDatumOd := hParams[ "datum_od" ]
   ENDIF
   IF hb_HHasKey( hParams, "datum_do" )
      dDatumDo := hParams[ "datum_do" ]
   ENDIF
   IF hb_HHasKey( hParams, "tarife" )
      _tarife := hParams[ "tarife" ]
   ENDIF
   IF hb_HHasKey( hParams, "vrste_dok" )
      _vrste_dok := hParams[ "vrste_dok" ]
   ENDIF
   IF hb_HHasKey( hParams, "gledati_usluge" )
      cGledatiUslugeDN := hParams[ "gledati_usluge" ]
   ENDIF

   kalk_tkv_cre_r_export()  // napravi pomocnu tabelu

   _o_tbl() // otvori ponovo tabele izvjestaja

   IF cViseKontaDN == "D"
      lViseKonta := .T.
   ENDIF

   IF lViseKonta .AND. !Empty( cUslovKonto )
      cFilterKonto := Parsiraj( cUslovKonto, "mkonto" )
   ENDIF

   IF !Empty( _tarife )
      cFilterTarife := Parsiraj( _tarife, "idtarifa" )
   ENDIF

   IF !Empty( _vrste_dok )
      cFilterVrsteDok := Parsiraj( _vrste_dok, "idvd" )
   ENDIF


   IF !lViseKonta  // sinteticki konto
      IF Len( Trim( cUslovKonto ) ) <= 3 .OR. "." $ cUslovKonto
         IF "." $ cUslovKonto
            cUslovKonto := StrTran( cUslovKonto, ".", "" )
         ENDIF
         cUslovKonto := Trim( cUslovKonto )
      ENDIF
   ENDIF

   /*
   SELECT kalk
   SET ORDER TO TAG "5"
   // "idFirma+dtos(datdok)+idvd+brdok+rbr"
   find_kalk_za_period( xIdFirma, cIdVd, cIdPartner, cIdRoba, dDatOd, dDatDo, cOrderBy )
   */

/*
   MsgO( "Preuzimanje podataka sa servera " + DToC( dDatumOd ) + "-" + DToC( dDatumDo ) + " ..." )
   find_kalk_za_period( cIdFirma, NIL, NIL, NIL, dDatumOd, dDatumDo, "idFirma,datdok,idvd,brdok,rbr" )
   MsgC()
*/

   hKalkParams := hb_Hash()
   hKalkParams[ "idfirma" ] := cIdFirma

   IF Len( Trim( cUslovKonto ) ) == 3  // sinteticki konto
      cIdkonto := Trim( cUslovKonto )
      hKalkParams[ "mkonto_sint" ] := cIdKonto
   ELSE
      hKalkParams[ "mkonto" ] := cUslovKonto
   ENDIF

   IF !Empty( dDatumOd )
      hKalkParams[ "dat_od" ] := dDatumOd
   ENDIF

   IF !Empty( dDatumDo )
      hKalkParams[ "dat_do" ] := dDatumDo
   ENDIF

   hKalkParams[ "order_by" ] := "idFirma,datdok,mkonto,idvd,brdok,rbr"
   MsgO( "Preuzimanje podataka sa servera " + DToC( dDatumOd ) + "-" + DToC( dDatumDo ) + " ..." )
   find_kalk_za_period( hKalkParams )
   MsgC()

   select_o_koncij( cUslovKonto )

   SELECT kalk

   Box(, 2, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 PadR( "Generisanje pomoćne tabele u toku...", 58 ) COLOR f18_color_i()

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. IspitajPrekid()

      IF !lViseKonta .AND. field->mkonto <> cUslovKonto
         SKIP
         LOOP
      ENDIF

      IF ( field->datdok < dDatumOd .OR. field->datdok > dDatumDo )
         SKIP
         LOOP
      ENDIF


      IF lViseKonta .AND. !Empty( cFilterKonto )
         IF !Tacno( cFilterKonto )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( cFilterVrsteDok )
         IF !Tacno( cFilterVrsteDok )
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF !Empty( cFilterTarife )
         IF !Tacno( cFilterTarife )
            SKIP
            LOOP
         ENDIF
      ENDIF

      _ulaz := 0
      _izlaz := 0
      nVPVUlaz := 0
      nVPVIzlaz := 0
      nNvUlaz := 0
      nNvIzlaz := 0
      nRabat := 0
      nMarzaVP := 0
      nMarzaMP := 0
      _tr_bank := 0
      _tr_zavisni := 0
      _tr_carina := 0
      _tr_prevoz := 0
      _tr_prevoz_2 := 0
      _tr_sped := 0

      _id_d_firma := field->idfirma
      _d_br_dok := field->brdok
      _br_fakt := field->brfaktp
      _id_partner := field->idpartner
      _dat_dok := field->datdok
      _broj_dok := field->idvd + "-" + field->brdok
      _tip_dok := field->idvd

      nDbfArea := Select()

      SELECT tdok
      HSEEK _tip_dok
      _tip_dok_naz := field->naz

      select_o_partner( _id_partner )

      _partn_naziv := field->naz
      _partn_ptt := field->ptt
      _partn_mjesto := field->mjesto
      _partn_adresa := field->adresa

      SELECT ( nDbfArea )

      DO WHILE !Eof() .AND. cIdFirma + DToS( _dat_dok ) + _broj_dok == field->idfirma + DToS( field->datdok ) + field->idvd + "-" + field->brdok .AND. IspitajPrekid()

         // ispitivanje konta u varijanti jednog konta i datuma
         IF !lViseKonta .AND. ( field->datdok < dDatumOd .OR. field->datdok > dDatumDo .OR. field->mkonto <> cUslovKonto )
            SKIP
            LOOP
         ENDIF

         IF lViseKonta .AND. !Empty( cFilterKonto )
            IF !Tacno( cFilterKonto )
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF !Empty( cFilterVrsteDok )
            IF !Tacno( cFilterVrsteDok )
               SKIP
               LOOP
            ENDIF
         ENDIF


         IF !Empty( cFilterTarife )
            IF !Tacno( cFilterTarife )
               SKIP
               LOOP
            ENDIF
         ENDIF


         IF kalk->idvd == "IM" // inventura magacin ne treba
            SKIP
            LOOP
         ENDIF

         select_o_roba( kalk->idroba )

         IF cGledatiUslugeDN == "N" .AND. roba->tip $ "U"
            SELECT kalk
            SKIP
            LOOP
         ENDIF

         SELECT kalk

         nVPC := vpc_magacin_rs()

         IF field->mu_i == "1" .AND. !( field->idvd $ "12#22#94" )  // ulazne kalkulacije
            nVPVUlaz += Round(  nVpc * ( field->kolicina - field->gkolicina - field->gkolicin2 ), gZaokr )
            nNvUlaz += Round( field->nc * ( field->kolicina - field->gkolicina - field->gkolicin2 ), gZaokr )

         ELSEIF field->mu_i == "5"  // izlazne kalkulacije
            nVPVIzlaz += Round( nVpc * field->kolicina, gZaokr )
            nRabat += Round( ( field->rabatv / 100 ) * nVPC * field->kolicina, gZaokr )
            nNvIzlaz += Round( field->nc * field->kolicina, gZaokr )

         ELSEIF field->mu_i == "1" .AND. ( field->idvd $ "12#22#94" )  // povrati
            nVPVIzlaz -= Round( nVPC * field->kolicina, gZaokr )
            nRabat -= Round( ( field->rabatv / 100 ) * field->vpc * field->kolicina, gZaokr )
            nNvIzlaz -= Round( field->nc * field->kolicina, gZaokr )

         ELSEIF field->mu_i == "3"  // nivelacija
            nVPVUlaz += Round( nVPC * field->kolicina, gZaokr )
         ENDIF

         nMarzaVP += kalk_marza_veleprodaja()
         nMarzaMP += kalk_marza_maloprodaja()
         _tr_prevoz += field->prevoz
         _tr_prevoz_2 += field->prevoz2
         _tr_bank += field->banktr
         _tr_sped += field->spedtr
         _tr_carina += field->cardaz
         _tr_zavisni += field->zavtr

         SKIP 1

      ENDDO

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + _id_d_firma + "-" + _tip_dok + "-" + _d_br_dok

      kalk_fin_stanje_add_to_r_export( _id_d_firma, _tip_dok, _d_br_dok, _dat_dok, _tip_dok_naz, _id_partner, ;
         _partn_naziv, _partn_mjesto, _partn_ptt, _partn_adresa, _br_fakt, ;
         nNvUlaz, nNvIzlaz, nNvUlaz - nNvIzlaz, ;
         nVPVUlaz, nVPVIzlaz, nVPVUlaz - nVPVIzlaz, ;
         nRabat, nMarzaVP, nMarzaMP, ;
         _tr_prevoz, _tr_prevoz_2, _tr_bank, _tr_sped, _tr_carina, _tr_zavisni )

      ++_cnt

   ENDDO

   BoxC()

   RETURN _cnt



FUNCTION vpc_magacin_rs_priprema()
   RETURN vpc_magacin_rs( .T. )


FUNCTION vpc_magacin_rs( lKalkPriprema )

   LOCAL nVPC, nAlias

   hb_default( @lKalkPriprema, .F. )

   IF lKalkPriprema
      IF kalk_pripr->IdVd $ "14#10" // u dokumentu je vpc
         nVPC := kalk_pripr->vpc
      ELSE
         // HACK: u dokument nije pohranjena vpc, uzeti iz robe
         // select_o_roba( kalk->idroba ) ne treba ovo je vec uradjeno u nadfunkciji
         IF kalk_pripr->idpartner == PadR( "118169", 7 ) // HACK-2: majop
            nVPC := roba->vpc2
         ELSE
            nVPC := roba->vpc
         ENDIF
      ENDIF

   ELSE
      IF kalk->IdVd $ "14#10"
         nVPC := kalk->vpc
      ELSE
         // select_o_roba( kalk->idroba ) ne treba ovo je vec uradjeno u nadfunkciji
         IF kalk->idpartner == PadR( "118169", 7 ) // majop
            nVPC := roba->vpc2
         ELSE
            nVPC := roba->vpc
         ENDIF
      ENDIF
   ENDIF

   RETURN nVPC

STATIC FUNCTION kalk_tkv_cre_r_export()

   LOCAL _dbf := {}

   AAdd( _dbf, { "idfirma", "C",  2, 0 } )
   AAdd( _dbf, { "idvd", "C",  2, 0 } )
   AAdd( _dbf, { "brdok", "C",  8, 0 } )
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
   AAdd( _dbf, { "marza", "N", 15, 2 } )
   AAdd( _dbf, { "marza2", "N", 15, 2 } )
   AAdd( _dbf, { "t_prevoz", "N", 15, 2 } )
   AAdd( _dbf, { "t_prevoz2", "N", 15, 2 } )
   AAdd( _dbf, { "t_bank", "N", 15, 2 } )
   AAdd( _dbf, { "t_sped", "N", 15, 2 } )
   AAdd( _dbf, { "t_cardaz", "N", 15, 2 } )
   AAdd( _dbf, { "t_zav", "N", 15, 2 } )

   create_dbf_r_export( _dbf )

   RETURN _dbf


// ---------------------------------------
// dodaj podatke u r_export tabelu
// ---------------------------------------
STATIC FUNCTION kalk_fin_stanje_add_to_r_export( id_firma, id_tip_dok, broj_dok, datum_dok, vrsta_dok, id_partner, ;
      part_naz, part_mjesto, part_ptt, part_adr, broj_fakture, ;
      n_v_dug, n_v_pot, n_v_saldo, ;
      v_p_dug, v_p_pot, v_p_saldo, ;
      v_p_rabat, marza, marza_2, tr_prevoz, tr_prevoz_2, ;
      tr_bank, tr_sped, tr_carina, tr_zavisni )

   LOCAL nDbfArea := Select()
   LOCAL hRec

   o_r_export()

   APPEND BLANK

   hRec := hb_Hash()
   hRec[ "idfirma" ] := id_firma
   hRec[ "idvd" ] := id_tip_dok
   hRec[ "brdok" ] := broj_dok
   hRec[ "datum" ] := datum_dok
   hRec[ "vr_dok" ] := vrsta_dok
   hRec[ "idpartner" ] := id_partner
   hRec[ "part_naz" ] := part_naz
   hRec[ "part_mj" ] := part_mjesto
   hRec[ "part_ptt" ] := part_ptt
   hRec[ "part_adr" ] := part_adr
   hRec[ "br_fakt" ] := broj_fakture
   hRec[ "nv_dug" ] := n_v_dug
   hRec[ "nv_pot" ] := n_v_pot
   hRec[ "nv_saldo" ] := n_v_saldo
   hRec[ "vp_dug" ] := v_p_dug
   hRec[ "vp_pot" ] := v_p_pot
   hRec[ "vp_saldo" ] := v_p_saldo
   hRec[ "vp_rabat" ] := v_p_rabat
   hRec[ "marza" ] := marza
   hRec[ "marza2" ] := marza_2
   hRec[ "t_prevoz" ] := tr_prevoz
   hRec[ "t_prevoz2" ] := tr_prevoz_2
   hRec[ "t_bank" ] := tr_bank
   hRec[ "t_sped" ] := tr_sped
   hRec[ "t_cardaz" ] := tr_carina
   hRec[ "t_zav" ] := tr_zavisni

   dbf_update_rec( hRec )

   SELECT ( nDbfArea )

   RETURN .T.


STATIC FUNCTION _o_tbl()

   // o_kalk()
   // o_sifk()
   // o_sifv()
   o_tdok()
   // o_roba()
   // o_koncij()
// o_konto()
// o_partner()

   RETURN .T.
