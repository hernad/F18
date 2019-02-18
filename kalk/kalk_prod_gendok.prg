/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

FIELD fcj, kolicina, mcsapp, TBankTr, pu_i, pkonto, rbr


FUNCTION kalk_prod_generacija_dokumenata()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. početno stanje prodavnica                               " )
   AAdd( _opcexe, {|| kalk_prod_pocetno_stanje() } )
   // TODO: izbaciti
   // AADD(_opc, "2. pocetno stanje (stara opcija/legacy)")
   // AADD(_opcexe, {|| PocStProd() } )
   AAdd( _opc, "2. inventura prodavnica" )
   AAdd( _opcexe, {|| kalk_prod_gen_ip() } )

   AAdd( _opc, "3. svedi mpc na mpc iz šifarnika dokumentom nivelacije" )
   AAdd( _opcexe, {|| kalk_prod_kartica_mpc_svedi_mpc_sif() } )


   f18_menu( "gdpr", nil, _izbor, _opc, _opcexe )

   RETURN .T.




STATIC FUNCTION kalk_prod_gen_ip()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. dokument inventura prodavnica               " )
   AAdd( _opcexe, {|| kalk_generisi_ip() } )
   AAdd( _opc, "2. inventura-razlika prema postojecoj IP " )
   AAdd( _opcexe, {|| gen_ip_razlika() } )
   AAdd( _opc, "3. na osnovu IP generisi 80-ku " )
   AAdd( _opcexe, {|| gen_ip_80() } )

   f18_menu( "pmi", nil, _izbor, _opc, _opcexe )

   RETURN .T.




FUNCTION kalk_generisi_niv_prodavnica_na_osnovu_druge_niv()

  // o_konto()
  // o_tarifa()
//   o_sifk()
//   o_sifv()
   //o_roba()

   Box(, 4, 70 )

   cIdFirma := self_organizacija_id()
   cIdVD := "19"
   cOldDok := Space( 8 )
   cIdkonto := PadR( "1330", 7 )
   dDatDok := Date()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Prodavnica:" GET  cidkonto VALID P_Konto( @cidkonto )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum     :  " GET  dDatDok
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Dokument na osnovu koga se vrsi inventura:" GET cIdFirma
   @ box_x_koord() + 4, Col() + 2 SAY "-" GET cIdVD
   @ box_x_koord() + 4, Col() + 2 SAY "-" GET cOldDok

   READ
   ESC_BCR

   BoxC()

   o_koncij()
   o_kalk_pripr()
   // o_kalk()
   PRIVATE cBrDok := kalk_get_next_broj_v5( cIdFirma, "19", NIL )

   nRbr := 0
   SET ORDER TO TAG "1"
   // "KALKi1","idFirma+IdVD+BrDok+RBr","KALK")

   select_o_koncij( cIdkonto )


   find_kalk_by_broj_dokumenta( cIdfirma, cIdvd, cOlddok, "KALK_1", F_KALK + 300 )

   DO WHILE !Eof() .AND. cidfirma + cidvd + colddok == idfirma + idvd + brdok


      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nMPVU := nMPVI := nNVU := nNVI := 0
      nRabat := 0
      select_o_roba( cidroba )

      // SELECT kalk

      // SET ORDER TO TAG "4"
      // "KALKi4","idFirma+Pkonto+idroba+dtos(datdok)+PU_I+IdVD","KALK")
      // ?? drugi alias trebamo ?? SEEK cidfirma + cidkonto + cidroba
      find_kalk_by_pkonto_idroba(  cidfirma, cidkonto, cidroba )
      DO WHILE !Eof() .AND. cidfirma + cidkonto + cidroba == idFirma + pkonto + idroba

         IF ddatdok < datdok  // preskoci
            skip; LOOP
         ENDIF

         IF roba->tip $ "UT"
            skip; LOOP
         ENDIF

         IF pu_i == "1"
            nUlaz += kolicina - GKolicina - GKolicin2
            nMPVU += mpcsapp * kolicina
            nNVU += nc * kolicina

         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlaz += kolicina
            nMPVI += mpcsapp * kolicina
            nNVI += nc * kolicina

         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlaz -= kolicina
            nMPVU -= mpcsapp * kolicina
            nnvu -= nc * kolicina

         ELSEIF pu_i == "3"    // nivelacija
            nMPVU += mpcsapp * kolicina

         ELSEIF pu_i == "I"
            nIzlaz += gkolicin2
            nMPVI += mpcsapp * gkolicin2
            nNVI += nc * gkolicin2
         ENDIF

         SKIP
      ENDDO // po orderu 4

      SELECT KALK_1

      select_o_roba( cIdroba )

      SELECT kalk_pripr
      scatter()
      APPEND ncnl
      _idfirma := cidfirma; _idkonto := cidkonto; _pkonto := cidkonto; _pu_i := "3"
      _idroba := cidroba; _idtarifa := kalk->idtarifa
      _idvd := "19"; _brdok := cbrdok
      _rbr := rbr_u_char( ++nrbr )
      _kolicina := nUlaz - nIzlaz
      _datdok := _DatFaktP := ddatdok
      _fcj := kalk->fcj
      _mpc := kalk->mpc
      _mpcsapp := kalk->mpcsapp
      IF ( _kolicina > 0 .AND.  Round( ( nmpvu - nmpvi ) / _kolicina, 4 ) == Round( _fcj, 4 ) ) .OR. ;
            ( Round( _kolicina, 4 ) == 0 .AND. Round( nMpvu - nMpvi, 4 ) == 0 )
         _ERROR := "0"
      ELSE
         _ERROR := "1"
      ENDIF

      my_rlock()
      Gather2()
      my_unlock()

      SELECT kalk_1

      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_prod_kartica_mpc_svedi_mpc_sif()

   LOCAL dDok := Date()
   LOCAL nPom := 0
   PRIVATE cIdKontoProdavnica := fetch_metric( "kalk_sredi_karicu_mpc", my_user(), PadR( "1330", 7 ) )

   //o_konto()

   cSravnitiD := "D"
   PRIVATE cUvijekSif := "D"

   Box(, 6, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto prodavnice: " GET cIdKontoProdavnica PICT "@!" VALID P_konto( @cIdKontoProdavnica )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Sravniti do odredjenog datuma:" GET cSravnitiD VALID cSravnitiD $ "DN" PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Uvijek nivelisati na MPC iz sifrarnika:" GET cUvijekSif VALID cUvijekSif $ "DN" PICT "@!"
   READ
   ESC_BCR
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum do kojeg se sravnjava" GET dDok
   READ
   ESC_BCR
   BoxC()

   select_o_koncij( cIdKontoProdavnica )

   //o_roba()
   o_kalk_pripr()


   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   lGenerisao := .F.
   PRIVATE nRbr := 0

   cBrNiv := kalk_get_next_broj_v5( self_organizacija_id(), "19", NIL )
   find_kalk_by_pkonto_idroba( self_organizacija_id(), cIdKontoProdavnica )

   Box(, 6, 65 )

   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Generisem nivelaciju... 19-" + cBrNiv

   DO WHILE !Eof() .AND. field->idfirma + field->pkonto == self_organizacija_id() + cIdKontoProdavnica

      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nVPVU := nVPVI := nNVU := nNVI := 0
      nRabat := 0

      select_o_roba( cIdroba )
      SELECT kalk

      IF roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      cIdkonto := pkonto
      nUlazVPC  := kalk_get_mpc_by_koncij_pravilo()
      nStartMPC := nUlazVPC
      // od ove cijene pocinjemo

      nPosljVPC := nUlazVPC

      @ 2 + box_x_koord(), 2 + box_y_koord() SAY "ID roba: " + cIdRoba
      @ 3 + box_x_koord(), 2 + box_y_koord() SAY "Cijena u sifrarniku " + AllTrim( Str( nUlazVpc ) )
      DO WHILE !Eof() .AND. self_organizacija_id() + cidkonto + cidroba == idFirma + pkonto + idroba

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF cSravnitiD == "D"
            IF datdok > dDok
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF pu_i == "1"
            nUlaz += kolicina - gkolicina - gkolicin2
            nVPVU += mpcsapp * ( kolicina - gkolicina - gkolicin2 )
            nUlazVPC := mpcsapp
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlaz += kolicina
            nVPVI += mpcsapp * kolicina
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlaz -= kolicina
            nVPVU -= mpcsapp * kolicina
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ELSEIF pu_i == "3"
            // nivelacija
            nVPVU += mpcsapp * kolicina
            IF mpcsapp + fcj <> 0
               nPosljVPC := mpcsapp + fcj
            ENDIF
         ELSEIF pu_i == "I"
            nIzlaz += gkolicin2
            nVPVI += mpcsapp * gkolicin2
            IF mpcsapp <> 0
               nPosljVPC := mpcsapp
            ENDIF
         ENDIF
         SKIP
      ENDDO

      nRazlika := 0
      // nStanje := ROUND( nUlaz - nIzlaz, 4 )
      // nVPV := ROUND( nVPVU - nVPVI, 4 )
      nStanje := ( nUlaz - nIzlaz )
      nVPV := ( nVPVU - nVPVI )

      SELECT kalk_pripr

      IF cUvijekSif == "D"
         nUlazVPC := nStartMPC
      ENDIF

      IF Round( nStanje, 4 ) <> 0 .OR. Round( nVPV, 4 ) <> 0
         IF Round( nStanje, 4 ) <> 0
            IF cUvijekSif == "D" .AND. Round( nUlazVPC - nVPV / nStanje, 4 ) <> 0
               nRazlika := nUlazVPC - nVPV / nStanje
            ELSE
               // samo ako kartica nije ok
               IF Round( nPosljVPC - nVPV / nStanje, 4 ) = 0
                  // kartica izgleda ok
                  nRazlika := 0
               ELSE
                  nRazlika := nUlazVPC - nVPV / nStanje
                  // nova - stara cjena
               ENDIF
            ENDIF
         ELSE
            nRazlika := nVPV
         ENDIF

         IF Round( nRazlika, 4 ) <> 0

            lGenerisao := .T.
            @ 4 + box_x_koord(), 2 + box_y_koord() SAY "Generisao stavki: " + AllTrim( Str( ++nRbr ) )

            APPEND BLANK

            REPLACE idfirma WITH self_organizacija_id(), idroba WITH cIdRoba, idkonto WITH cIdKonto, ;
               datdok WITH dDok, ;
               idtarifa WITH roba->idtarifa, ;
               kolicina WITH nStanje, ;
               idvd WITH "19", brdok WITH cBrNiv, ;
               rbr WITH Str( nRbr, 3 ), ;
               pkonto WITH cIdKontoProdavnica, ;
               pu_i WITH "3"
               //datfaktp WITH dDok, ;

            IF ROUND( nStanje, 4 ) <> 0 .AND. ABS( nVPV / nStanje ) < 99999
               REPLACE fcj WITH nVPV / nStanje
               REPLACE mpcsapp WITH nRazlika
            ELSE
               REPLACE kolicina WITH 1
               REPLACE fcj WITH nRazlika + nUlazVPC
               REPLACE mpcsapp WITH -nRazlika
               REPLACE Tbanktr WITH "X"
            ENDIF

         ENDIF

      ENDIF

      SELECT kalk

   ENDDO

   BoxC()

   IF lGenerisao
      MsgBeep( "Generisana nivelacija u kalk_pripremi - obradite je!" )
   ENDIF

   my_close_all_dbf()

   RETURN .T.


// Generisanje dokumenta tipa 11 na osnovu 13-ke
FUNCTION kalk_13_to_11()

//   o_konto()
   o_kalk_pripr()
   o_kalk_pripr2()
   //o_kalk()
//   o_sifk()
//   o_sifv()
//   o_roba()

   SELECT kalk_pripr
   GO TOP
   PRIVATE cIdFirma := idfirma, cIdVD := idvd, cBrDok := brdok
   IF !( cidvd $ "13" )   .OR. Pitanje(, "Zelite li zaduziti drugu prodavnicu ?", "D" ) == "N"
      closeret
   ENDIF

   PRIVATE cProdavn := Space( 7 )
   Box(, 3, 35 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Prenos u prodavnicu:" GET cProdavn VALID P_Konto( @cProdavn )
   READ
   BoxC()
   PRIVATE cBrUlaz := "0"


   kalk_set_brkalk_za_idvd( "11", @cBrUlaz )

   SELECT kalk_pripr
   GO TOP
   PRIVATE nRBr := 0
   DO WHILE !Eof() .AND. cidfirma == idfirma .AND. cidvd == idvd .AND. cbrdok == brdok
      scatter()
      select_o_roba( _idroba )
      SELECT kalk_pripr2
      APPEND BLANK

      _idpartner := ""
      _rabat := prevoz := prevoz2 := _banktr := _spedtr := _zavtr := _nc := _marza := _marza2 := _mpc := 0

      _fcj := _fcj2 := _nc := kalk_pripr->nc
      _rbr := Str( ++nRbr, 3 )
      _kolicina := kalk_pripr->kolicina
      _idkonto := cProdavn
      _idkonto2 := kalk_pripr->idkonto2
      _brdok := cBrUlaz
      _idvd := "11"
      _MKonto := _Idkonto2;_MU_I := "5"     // izlaz iz magacina
      _PKonto := _Idkonto; _PU_I := "1"     // ulaz  u prodavnicu

      _TBankTr := ""    // izgenerisani dokument
      gather()

      SELECT kalk_pripr
      SKIP
   ENDDO

   my_close_all_dbf()

   RETURN .T.

/*
  Generisanje dokumenta tipa 41 ili 42 na osnovu 11-ke
*/

FUNCTION kalk_iz_11_u_41_42()

   o_kalk_edit()
   cIdFirma := self_organizacija_id()
   cIdVdU   := "11"
   cIdVdI   := "4"
   cBrDokU  := Space( Len( kalk_pripr->brdok ) )
   cBrDokI  := ""
   dDatDok    := CToD( "" )

   cBrFaktP   := Space( Len( kalk_pripr->brfaktp ) )
   cIdPartner := Space( Len( kalk_pripr->idpartner ) )
   dDatFaktP  := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 6, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 41/42 NA OSNOVU DOKUMENTA 11"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVdU + "-"
   @ Row(), Col() GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Formirati dokument (41 ili 42)  4"
   cPom := "2"
   @ Row(), Col() GET cPom VALID cPom $ "12" PICT "9"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Utvrditi NC po metodi iz parametara ? (D/N)" GET cPoMetodiNC VALID cPoMetodiNC $ "DN" PICT "@!"
   READ; ESC_BCR
   cIdVdI += cPom
   BoxC()

   IF cIdVdI == "41"
      Box(, 5, 75 )
      @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 41 NA OSNOVU DOKUMENTA 11"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj maloprodajne fakture" GET cBrFaktP
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum fakture            " GET dDatFaktP
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Sifra kupca              " GET cIdPartner VALID Empty( cIdPartner ) .OR. p_partner( @cIdPartner )
      READ
      BoxC()
   ENDIF

   kalk_set_brkalk_za_idvd( cIdVdI, @cBrDokI )


   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )
   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK

      PushWA()
      SELECT kalk_pripr; APPEND BLANK; Scatter()
      _idfirma   := cIdFirma
      _idroba    := KALK->idroba
      _idkonto   := KALK->idkonto
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := cBrFaktP
      _datfaktp  := IF( !Empty( dDatFaktP ), dDatFaktP, dDatDok )
      _idpartner := cIdPartner
      _rbr       := KALK->rbr
      _kolicina  := KALK->kolicina
      _fcj       := KALK->nc
      _tprevoz   := "A"
      _tmarza2   := "A"
      // _marza2    := KALK->(marza+marza2)
      _mpc       := KALK->mpc
      _idtarifa  := KALK->idtarifa
      _mpcsapp   := KALK->mpcsapp
      _pkonto    := KALK->pkonto
      _pu_i      := "5"
      _error     := "0"

      IF !Empty( kalk_metoda_nc() ) .AND. cPoMetodiNC == "D"
         nc1 := nc2 := 0

         ?
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, 0, 0, @nc1, @nc2, )


         IF kalk_metoda_nc() $ "13"; _fcj := nc1; ELSEIF kalk_metoda_nc() == "2"; _fcj := nc2; ENDIF
      ENDIF

      _nc     := _fcj
      _marza2 := _mpc - _nc

      SELECT kalk_pripr
      my_rlock()
      Gather()
      my_unlock()
      SELECT KALK
      PopWA()
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.


// Generisanje dokumenta tipa 11 na osnovu 10-ke
FUNCTION kalk_iz_10_u_11()

   o_kalk_edit()
   cIdFirma := self_organizacija_id()
   cIdVdU   := "10"
   cIdVdI   := "11"
   cBrDokU  := Space( Len( kalk_pripr->brdok ) )
   cIdKonto := Space( Len( kalk_pripr->idkonto ) )
   cBrDokI  := ""
   dDatDok    := CToD( "" )

   cBrFaktP   := ""
   cIdPartner := ""
   dDatFaktP  := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 6, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 11 NA OSNOVU DOKUMENTA 10"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVdU + "-"
   @ Row(), Col() GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Prodavn.konto zaduzuje   " GET cIdKonto VALID P_Konto( @cIdKonto )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Utvrditi NC po metodi iz parametara ? (D/N)" GET cPoMetodiNC VALID cPoMetodiNC $ "DN" PICT "@!"
   READ; ESC_BCR
   BoxC()


   kalk_set_brkalk_za_idvd( cIdVdI, @cBrDokI )


   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )

   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK
      PushWA()
      SELECT kalk_pripr
      APPEND BLANK
      Scatter()
      _idfirma   := cIdFirma
      _idroba    := KALK->idroba
      _idkonto   := cIdKonto
      _idkonto2  := KALK->idkonto
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := cBrFaktP
      _datfaktp  := IF( !Empty( dDatFaktP ), dDatFaktP, dDatDok )
      _idpartner := cIdPartner
      _rbr       := KALK->rbr
      _kolicina  := KALK->kolicina
      _fcj       := KALK->nc
      _tprevoz   := "R"
      _tmarza    := "A"
      _tmarza2   := "A"
      _vpc       := KALK->vpc
      // _marza2 := _mpc - _vpc
      // _mpc       := KALK->mpc
      _idtarifa  := KALK->idtarifa
      _mpcsapp   := KALK->mpcsapp
      _pkonto    := _idkonto
      _mkonto    := _idkonto2
      _mu_i      := "5"
      _pu_i      := "1"
      _error     := "0"

      IF !Empty( kalk_metoda_nc() ) .AND. cPoMetodiNC == "D"
         nc1 := nc2 := 0

          ?
         kalk_get_nabavna_prod( _idfirma, _idroba, _idkonto, 0, 0, @nc1, @nc2, )

         IF kalk_metoda_nc() $ "13"; _fcj := nc1; ELSEIF kalk_metoda_nc() == "2"; _fcj := nc2; ENDIF
      ENDIF

      _nc     := _fcj
      _marza  := _vpc - _nc

      SELECT kalk_pripr
      my_rlock()
      Gather()
      my_unlock()
      SELECT KALK
      PopWA()
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.



// generisi 80-ku na osnovu IP-a
FUNCTION gen_ip_80()

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cTipDok := "IP"
   LOCAL cIpBrDok := Space( 8 )
   LOCAL dDat80 := Date()
   LOCAL nCnt := 0
   LOCAL cNxt80 := Space( 8 )

   Box(, 5, 65 )
   @ 1 + box_x_koord(), 2 + box_y_koord() SAY "Postojeci dokument IP -> " + cIdFirma + "-" + cTipDok + "-" GET cIpBrDok VALID !Empty( cIpBrDok )
   @ 2 + box_x_koord(), 2 + box_y_koord() SAY "Datum dokumenta" GET dDat80 VALID !Empty( dDat80 )
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF Pitanje(, "Generisati 80-ku (D/N)?", "D" ) == "N"
      RETURN .F.
   ENDIF

   // kopiraj dokument u pript
   IF !kalk_copy_kalk_azuriran_u_pript( cIdFirma, cTipDok, cIpBrDok )
      RETURN .F.
   ENDIF

   o_kalk_doks()
   o_kalk()
   o_kalk_pript()
   o_kalk_pripr()

   cNxt80 := kalk_get_next_kalk_doc_uvecaj( self_organizacija_id(), "80" )

   // obradi dokument u kalk_pripremu -> konvertuj u 80
   SELECT pript
   SET ORDER TO TAG "2"
   GO TOP

   Box(, 1, 30 )

   DO WHILE !Eof()

      Scatter()

      SELECT kalk_pripr
      APPEND BLANK

      _gkolicina := 0
      _gkolicin2 := 0
      _idvd := "80"
      _error := "0"
      _tmarza2 := "A"
      _datdok := dDat80
      _datfaktp := dDat80
      _brdok := cNxt80

      Gather()

      ++ nCnt
      @ 1 + box_x_koord(), 2 + box_y_koord() SAY AllTrim( Str( nCnt ) )

      SELECT pript
      SKIP
   ENDDO

   BoxC()

   RETURN .T.
