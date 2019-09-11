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

MEMVAR __print_opt, gZaokr

STATIC s_nOpisDuzina := 70


FUNCTION kalk_tkv()

   LOCAL hParams
   LOCAL nCount := 0

   IF !get_params_tkv( @hParams )
      RETURN .F.
   ENDIF
   nCount := kalk_gen_fin_stanje_magacina_za_tkv( hParams )
   IF nCount > 0
      stampaj_tkv( hParams )
   ENDIF

   RETURN .T.


FUNCTION kalk_gen_fin_stanje_magacina_za_tkv( hParams )

   LOCAL cUslovKonto := ""
   LOCAL dDatumOd := Date()
   LOCAL dDatumDo := Date()
   LOCAL cUslovTarife := ""
   LOCAL cUslovIdVD := ""
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL lViseKonta := .F.
   LOCAL nDbfArea
   LOCAL nVPVRabat
   LOCAL nNvUlaz, nNvIzlaz, nVPVUlaz, nVPVIzlaz
   LOCAL nMarzaVP, nMarzaMP, nPrevozTr, nPrevoz2Tr
   LOCAL nBankTr, nZavisniTr, nCarinTr, nSpedTr
   LOCAL cBrFaktP, cIdVd, cTipDokumentaNaziv, cIdPartner
   LOCAL cPartnerNaziv, cPartnerPTT, cPartnerMjesto, cPartnerAdresa
   LOCAL cIdVdBrDok, dDatDok
   LOCAL cFilterKonto := ""
   LOCAL cFilterVrsteDok := ""
   LOCAL cFilterTarife := ""
   LOCAL cGledatiUslugeDN := "N"
   LOCAL cViseKontaDN := "N"
   LOCAL nCount := 0
   LOCAL hKalkParams
   LOCAL cIdKonto
   LOCAL nVPC
   LOCAL cBrDok
   LOCAL nRealizacija, nRealizacijaNv
   LOCAL hRec

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
      cUslovTarife := hParams[ "tarife" ]
   ENDIF
   IF hb_HHasKey( hParams, "vrste_dok" )
      cUslovIdVD := hParams[ "vrste_dok" ]
   ENDIF
   IF hb_HHasKey( hParams, "gledati_usluge" )
      cGledatiUslugeDN := hParams[ "gledati_usluge" ]
   ENDIF

   kalk_hernad_tkv_cre_r_export()  // napravi pomocnu tabelu

   IF cViseKontaDN == "D"
      lViseKonta := .T.
   ENDIF

   IF lViseKonta .AND. !Empty( cUslovKonto )
      cFilterKonto := Parsiraj( cUslovKonto, "mkonto" )
   ENDIF

   IF !Empty( cUslovTarife )
      cFilterTarife := Parsiraj( cUslovTarife, "idtarifa" )
   ENDIF

   IF !Empty( cUslovIdVD )
      cFilterVrsteDok := Parsiraj( cUslovIdVD, "idvd" )
   ENDIF


   IF !lViseKonta  // sinteticki konto
      IF Len( Trim( cUslovKonto ) ) <= 3 .OR. "." $ cUslovKonto
         IF "." $ cUslovKonto
            cUslovKonto := StrTran( cUslovKonto, ".", "" )
         ENDIF
         cUslovKonto := Trim( cUslovKonto )
      ENDIF
   ENDIF


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

   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. ispitaj_prekid()

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

      nVPVUlaz := 0
      nVPVIzlaz := 0
      nNvUlaz := 0
      nNvIzlaz := 0
      nVPVRabat := 0
      nMarzaVP := 0
      nMarzaMP := 0
      nBankTr := 0
      nZavisniTr := 0
      nCarinTr := 0
      nPrevozTr := 0
      nPrevoz2Tr := 0
      nSpedTr := 0
      nRealizacija := 0
      nRealizacijaNv := 0

      // _id_d_firma := field->idfirma
      cBrDok := field->brdok
      cBrFaktP := field->brfaktp
      cIdPartner := field->idpartner
      dDatDok := field->datdok
      cIdVdBrDok := field->idvd + "-" + field->brdok
      cIdVd := field->idvd

      nDbfArea := Select()
      select_o_tdok( cIdVd )
      cTipDokumentaNaziv := field->naz
      select_o_partner( cIdPartner )
      cPartnerNaziv := field->naz
      cPartnerPTT := field->ptt
      cPartnerMjesto := field->mjesto
      cPartnerAdresa := field->adresa

      SELECT ( nDbfArea )
      DO WHILE !Eof() .AND. cIdFirma + DToS( dDatDok ) + cIdVdBrDok == field->idfirma + DToS( field->datdok ) + field->idvd + "-" + field->brdok .AND. ispitaj_prekid()

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
         SELECT kalk
         nVPC := vpc_magacin_rs()

         IF kalk->mu_i == "1" // .AND. !( field->idvd $ "12#94" )  // ulazne kalkulacije
            nVPVUlaz += Round(  nVpc * field->kolicina, gZaokr )
            nNvUlaz += Round( field->nc * field->kolicina, gZaokr )

         ELSEIF kalk->mu_i == "5" .AND. kalk->idvd != "KO" .AND. kalk->idvd != "14" // izlazne kalkulacije
            nVPVIzlaz += Round( nVpc * field->kolicina, gZaokr )
            nVPVRabat += Round( ( field->rabatv / 100 ) * nVPC * field->kolicina, gZaokr )
            nNvIzlaz += Round( field->nc * field->kolicina, gZaokr )

         ELSEIF kalk->idvd == "14"
            nRealizacija += Round( nVpc * field->kolicina, gZaokr )
            nVPVRabat += Round( ( field->rabatv / 100 ) * nVPC * field->kolicina, gZaokr )
            nRealizacijaNv += Round( field->nc * field->kolicina, gZaokr )

         ELSEIF kalk->idvd == "KO"
            nRealizacija += Round( nVpc * field->kolicina, gZaokr )
            nVPVRabat += Round( ( field->rabatv / 100 ) * nVPC * field->kolicina, gZaokr )
            nRealizacijaNv += 0

         ENDIF

         nMarzaVP += kalk_marza_veleprodaja()
         nMarzaMP += kalk_marza_maloprodaja()
         nPrevozTr += field->prevoz
         nPrevoz2Tr += field->prevoz2
         nBankTr += field->banktr
         nSpedTr += field->spedtr
         nCarinTr += field->cardaz
         nZavisniTr += field->zavtr

         SKIP 1

      ENDDO

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVd + "-" + cBrDok

      hRec := hb_Hash()
      hRec[ "idfirma" ] := cIdFirma
      hRec[ "idvd" ] := cIdVd
      hRec[ "brdok" ] := cBrDok
      hRec[ "datum" ] := dDatDok
      hRec[ "vr_dok" ] := cTipDokumentaNaziv
      hRec[ "idpartner" ] := cIdPartner
      hRec[ "part_naz" ] := cPartnerNaziv
      hRec[ "part_mj" ] := cPartnerMjesto
      hRec[ "part_ptt" ] := cPartnerPTT
      hRec[ "part_adr" ] := cPartnerAdresa
      hRec[ "br_fakt" ] := cBrFaktP
      hRec[ "nv_dug" ] := nNvUlaz
      hRec[ "nv_izlaz" ] := nNvIzlaz
      hRec[ "nv_real" ] := nRealizacijaNv
      hRec[ "nv_pot" ] := nNvIzlaz + nRealizacijaNv
      hRec[ "vp_marza" ] := nRealizacija - nVPVRabat - nRealizacijaNv

      //hRec[ "vp_dug" ] := nVPVUlaz
      //hRec[ "vp_pot" ] := nVpvIzlaz

      hRec[ "vp_rabat" ] := nVPVRabat
      hRec[ "vp_real" ] := nRealizacija
      hRec[ "vp_real_nt" ] := nRealizacija - nVPVRabat


      o_r_export()
      APPEND BLANK
      dbf_update_rec( hRec )

      ++nCount
      SELECT kalk

   ENDDO

   BoxC()

   RETURN nCount


STATIC FUNCTION get_params_tkv( hParams )

   LOCAL lRet := .F.
   LOCAL nX := 1
   LOCAL cUslovKonta := fetch_metric( "kalk_tkv_konto", my_user(), Space( 200 ) )
   LOCAL _d_od := fetch_metric( "kalk_tkv_datum_od", my_user(), Date() - 30 )
   LOCAL _d_do := fetch_metric( "kalk_tkv_datum_do", my_user(), Date() )
   LOCAL cIdVd := fetch_metric( "kalk_tkv_vrste_dok", my_user(), Space( 200 ) )
   LOCAL _usluge := fetch_metric( "kalk_tkv_gledati_usluge", my_user(), "N" )
   LOCAL cNabavneiliProdajneCijene := fetch_metric( "kalk_tkv_tip_obrasca", my_user(), "P" )
   LOCAL cViseKontaDN := "D"
   LOCAL cXlsxDN := "D"
   LOCAL GetList := {}

   Box(, 15, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "*** magacin - izvještaj TKV"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od" GET _d_od
   @ box_x_koord() + nX, Col() + 1 SAY "do" GET _d_do
   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "     Konto (prazno-svi):" GET cUslovKonta PICT "@S35"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Vrste dok. (prazno-svi):" GET cIdVd PICT "@S35"
   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Gledati [N] nabavne cijene [P] prodajne cijene ?" GET cNabavneiliProdajneCijene PICT "@!" VALID cNabavneiliProdajneCijene $ "PN"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Gledati usluge (D/N) ?" GET _usluge PICT "@!" VALID _usluge $ "DN"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Export XLSX (D/N) ?" GET cXlsxDN PICT "@!" VALID cXlsXDN $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN lRet
   ENDIF

   lRet := .T.

   hParams := hb_Hash()
   hParams[ "datum_od" ] := _d_od
   hParams[ "datum_do" ] := _d_do
   hParams[ "konto" ] := cUslovKonta
   hParams[ "vrste_dok" ] := cIdVd
   hParams[ "gledati_usluge" ] := _usluge
   hParams[ "nab_ili_prod" ] := cNabavneiliProdajneCijene

   // ako postoji tacka u kontu onda gledaj
   IF Right( AllTrim( cUslovKonta ), 1 ) == "."
      cViseKontaDN := "N"
   ENDIF
   hParams[ "vise_konta" ] := cViseKontaDN
   hParams[ "xlsx" ] := iif( cXlsXDN == "D", .T., .F. )

   // snimi sql/db parametre
   set_metric( "kalk_tkv_konto", my_user(), cUslovKonta )
   set_metric( "kalk_tkv_datum_od", my_user(), _d_od )
   set_metric( "kalk_tkv_datum_do", my_user(), _d_do )
   set_metric( "kalk_tkv_vrste_dok", my_user(), cIdVd )
   set_metric( "kalk_tkv_gledati_usluge", my_user(), _usluge )
   set_metric( "kalk_tkv_tip_obrasca", my_user(), cNabavneiliProdajneCijene )

   RETURN lRet


STATIC FUNCTION stampaj_tkv( hParams )

   LOCAL nRedBr := 0
   LOCAL cLinija, cOpisKnjizenja
   LOCAL _n_opis, nColIznosi
   LOCAL nTotalDuguje, nTotalPotrazuje, nTotalRabat
   LOCAL aOpisKnjizenja := {}
   LOCAL nI
   LOCAL cNabIliProd := hParams[ "nab_ili_prod" ]

   cLinija := get_linija()

   START PRINT CRET

   ?
   P_COND

   tkv_zaglavlje( hParams )
   ? cLinija
   tkv_header()
   ? cLinija

   nTotalDuguje := 0
   nTotalPotrazuje := 0
   nTotalRabat := 0

   SELECT r_export
   GO TOP

   DO WHILE !Eof()

      // preskoci ako su stavke = 0
      //IF ( Round( field->vp_saldo, 2 ) == 0 .AND. Round( field->nv_saldo, 2 ) == 0 )
      //   SKIP
      //   LOOP
      //ENDIF

      ? PadL( AllTrim( Str( ++nRedBr ) ), 6 ) + "."
      @ PRow(), PCol() + 1 SAY field->datum
      cOpisKnjizenja := AllTrim( field->vr_dok )
      cOpisKnjizenja += " "
      cOpisKnjizenja += "broj: "
      cOpisKnjizenja += AllTrim( field->idvd ) + "-" + AllTrim( field->brdok )
      cOpisKnjizenja += ", "
      cOpisKnjizenja += "veza: " + AllTrim( field->br_fakt )
      cOpisKnjizenja += ", "
      cOpisKnjizenja += AllTrim( field->part_naz )
      cOpisKnjizenja += ", "
      cOpisKnjizenja += AllTrim( field->part_adr )
      cOpisKnjizenja += ", "
      cOpisKnjizenja += AllTrim( field->part_mj )
      aOpisKnjizenja := SjeciStr( cOpisKnjizenja, s_nOpisDuzina )

      // opis knjizenja
      @ PRow(), _n_opis := PCol() + 1 SAY aOpisKnjizenja[ 1 ]

      //IF cNabIliProd == "N"

         @ PRow(), nColIznosi := PCol() + 1 SAY Str( field->nv_dug, 12, 2 )

         @ PRow(), nColIznosi := PCol() + 1 SAY Str( field->nv_izlaz, 12, 2 )
         @ PRow(), nColIznosi := PCol() + 1 SAY Str( field->nv_real, 12, 2 )
         @ PRow(), nColIznosi := PCol() + 1 SAY Str( field->nv_pot, 12, 2 )  // nv_izlaz + nv_real

         // razduzenje bez PDV

         //@ PRow(), PCol() + 1 SAY Str( field->vp_pot, 12, 2 )

      //ELSEIF cNabIliProd == "P"

         // zaduzenje bez PDV
         //@ PRow(), nColIznosi := PCol() + 1 SAY Str( field->vp_dug, 12, 2 )

         // razduzenje bez PDV
         //@ PRow(), PCol() + 1 SAY Str( field->vp_pot, 12, 2 )

      //ENDIF


      @ PRow(), PCol() + 1 SAY Str( field->vp_rabat, 12, 2 )

      //IF cNabIliProd == "N"
         nTotalDuguje += field->nv_dug
      //ELSEIF cNabIliProd == "P"
      //   nTotalDuguje += field->vp_dug
      //ENDIF

      //nTotalPotrazuje += field->vp_pot
      //nTotalRabat += field->vp_rabat

      FOR nI := 2 TO Len( aOpisKnjizenja )
         ?
         @ PRow(), _n_opis SAY aOpisKnjizenja[ nI ]
      NEXT

      SKIP

   ENDDO

   ? cLinija

   ? "UKUPNO:"
   @ PRow(), nColIznosi SAY Str( nTotalDuguje, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nTotalPotrazuje, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nTotalRabat, 12, 2 )

   ?U "SALDO TRGOVAČKE KNJIGE:"
   @ PRow(), nColIznosi SAY Str( nTotalDuguje - nTotalPotrazuje, 12, 2 )

   ? cLinija

   FF
   ENDPRINT

   IF hParams[ "xlsx" ]
      open_r_export_table()
   ENDIF

   RETURN .T.




STATIC FUNCTION get_linija()

   LOCAL cLinija

   cLinija := ""
   cLinija += Replicate( "-", 7 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 8 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", s_nOpisDuzina )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )
   cLinija += Space( 1 )
   cLinija += Replicate( "-", 12 )

   RETURN cLinija



STATIC FUNCTION tkv_zaglavlje( hParams )

   ? self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )
   ?
   ?U Space( 10 ), "TRGOVAČKA KNJIGA NA VELIKO (TKV) za period od:", hParams[ "datum_od" ], "do:", hParams[ "datum_do" ]
   ?
   ? "Uslov za skladista: "

   IF !Empty( AllTrim( hParams[ "konto" ] ) )
      ?? AllTrim( hParams[ "konto" ] )
   ELSE
      ?? " sva skladista"
   ENDIF

   ? "na dan", Date()

   ?

   RETURN .T.



STATIC FUNCTION tkv_header()

   LOCAL cRow1, cRow2

   cRow1 := ""
   cRow2 := ""

   cRow1 += PadR( "R.Br", 7 )
   cRow2 += PadR( "", 7 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Datum", 8 )
   cRow2 += PadC( "dokum.", 8 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadR( "", s_nOpisDuzina )
   cRow2 += PadR( "Opis knjizenja", s_nOpisDuzina )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Zaduzenje", 12 )
   cRow2 += PadC( "bez PDV-a", 12 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Razduzenje", 12 )
   cRow2 += PadC( "bez PDV-a", 12 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Odobreni", 12 )
   cRow2 += PadC( "rabat", 12 )

   ? cRow1
   ? cRow2

   RETURN .T.


   STATIC FUNCTION kalk_hernad_tkv_cre_r_export()

      LOCAL aDbf := {}

      AAdd( aDbf, { "idfirma", "C",  2, 0 } )
      AAdd( aDbf, { "idvd", "C",  2, 0 } )
      AAdd( aDbf, { "brdok", "C",  8, 0 } )
      AAdd( aDbf, { "datum", "D",  8, 0 } )
      AAdd( aDbf, { "vr_dok", "C", 30, 0 } )
      AAdd( aDbf, { "idpartner", "C",  6, 0 } )
      AAdd( aDbf, { "part_naz", "C", 100, 0 } )
      AAdd( aDbf, { "part_mj", "C", 50, 0 } )
      AAdd( aDbf, { "part_ptt", "C", 10, 0 } )
      AAdd( aDbf, { "part_adr", "C", 50, 0 } )
      AAdd( aDbf, { "br_fakt", "C", 20, 0 } )
      AAdd( aDbf, { "nv_dug", "N", 15, 2 } )
      AAdd( aDbf, { "nv_izlaz", "N", 15, 2 } )
      AAdd( aDbf, { "nv_real", "N", 15, 2 } )
      AAdd( aDbf, { "nv_pot", "N", 15, 2 } )

      //AAdd( aDbf, { "vp_dug", "N", 15, 2 } )
      //AAdd( aDbf, { "vp_pot", "N", 15, 2 } )
      AAdd( aDbf, { "vp_marza", "N", 15, 2 } )

      AAdd( aDbf, { "vp_rabat", "N", 15, 2 } )
      AAdd( aDbf, { "vp_real", "N", 15, 2 } )
      AAdd( aDbf, { "vp_real_nt", "N", 15, 2 } )

      create_dbf_r_export( aDbf )

      RETURN aDbf
