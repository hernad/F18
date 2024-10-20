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

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. početno stanje prodavnica                               " )
   AAdd( aOpcExe, {|| kalk_pocetno_stanje_prodavnica() } )
   // TODO: izbaciti
   // AADD(aOpc, "2. pocetno stanje (stara opcija/legacy)")
   // AADD(aOpcExe, {|| PocStProd() } )
   AAdd( aOpc, "2. inventura prodavnica" )
   AAdd( aOpcExe, {|| kalk_prod_gen_ip() } )

   AAdd( aOpc, "3. svedi mpc na mpc iz šifarnika dokumentom nivelacije" )
   AAdd( aOpcExe, {|| kalk_prod_kartica_mpc_svedi_mpc_sif() } )


   f18_menu( "gdpr", NIL, nIzbor, aOpc, aOpcExe )

   RETURN .T.




STATIC FUNCTION kalk_prod_gen_ip()

   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL nIzbor := 1

   AAdd( aOpc, "1. dokument inventura prodavnica               " )
   AAdd( aOpcExe, {|| kalk_generisi_ip() } )
   AAdd( aOpc, "2. inventura-razlika prema postojecoj IP " )
   AAdd( aOpcExe, {|| gen_ip_razlika() } )
   AAdd( aOpc, "3. na osnovu IP generisi 80-ku " )
   AAdd( aOpcExe, {|| gen_ip_80() } )

   f18_menu( "pmi", NIL, nIzbor, aOpc, aOpcExe )

   RETURN .T.




FUNCTION kalk_generisi_niv_prodavnica_na_osnovu_druge_niv()

   LOCAL GetList

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
      nUlazKol := nIzlazKol := 0
      nMPVU := nMPVI := nNVU := nNVI := 0
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
            nUlazKol += kolicina - GKolicina - GKolicin2
            nMPVU += mpcsapp * kolicina
            nNVU += nc * kolicina

         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlazKol += kolicina
            nMPVI += mpcsapp * kolicina
            nNVI += nc * kolicina

         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlazKol -= kolicina
            nMPVU -= mpcsapp * kolicina
            nnvu -= nc * kolicina

         ELSEIF pu_i == "3"    // nivelacija
            nMPVU += mpcsapp * kolicina

         ELSEIF pu_i == "I"
            nIzlazKol += gkolicin2
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
      _rbr := ++nRbr
      _kolicina := nUlazKol - nIzlazKol
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
   LOCAL GetList := {}
   LOCAL nMpcSaPDV, nMpcSaPDVSifarnik, nMpcSaPDVKartica
   LOCAL cIdRoba, cIdKontoProdavnica, cBrNiv
   LOCAL nIzlazKol, nUlazKol, nMpvIzlaz, nMpvUlaz, nRazlika, nStanjeKol
   LOCAL nMPVSaldo
   LOCAL cSravnitiD
   LOCAL cUvijekSif
   LOCAL nRbr
   LOCAL lGenerisao

   cIdKontoProdavnica := fetch_metric( "kalk_sredi_karicu_mpc", my_user(), PadR( "1330", 7 ) )

   cSravnitiD := "D"
   cUvijekSif := "D"

   Box(, 6, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Konto prodavnice: " GET cIdKontoProdavnica PICT "@!" VALID P_konto( @cIdKontoProdavnica )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Sravniti do odredjenog datuma:" GET cSravnitiD VALID cSravnitiD $ "DN" PICT "@!"
   // @ box_x_koord() + 4, box_y_koord() + 2 SAY "Uvijek nivelisati na MPC iz sifrarnika:" GET cUvijekSif VALID cUvijekSif $ "DN" PICT "@!"
   READ
   ESC_BCR
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum do kojeg se sravnjava" GET dDok
   READ
   ESC_BCR
   BoxC()

   // select_o_koncij( cIdKontoProdavnica )
   o_kalk_pripr()


   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI :=  0
   nTRabat := 0
   lGenerisao := .F.
   nRbr := 0

   cBrNiv := kalk_get_next_broj_v5( self_organizacija_id(), "19", NIL )
   find_kalk_by_pkonto_idroba( self_organizacija_id(), cIdKontoProdavnica )

   Box(, 6, 65 )

   @ 1 + box_x_koord(), 2 + box_y_koord() SAY8 "Generisanje nivelacije... 19-" + cBrNiv

   DO WHILE !Eof() .AND. field->idfirma + field->pkonto == self_organizacija_id() + cIdKontoProdavnica

      cIdRoba := kalk->Idroba
      nUlazKol := nIzlazKol := 0
      nMpvUlaz := nMpvIzlaz :=  0

      select_o_roba( cIdroba )
      SELECT kalk

      IF roba->tip $ "TU"
         SKIP
         LOOP
      ENDIF

      nMpcSaPDVSifarnik  := kalk_get_mpc_by_koncij_pravilo( cIdKontoProdavnica )
      // nPosljednjaMPCsaPDV := nMpcSaPDV

      @ 2 + box_x_koord(), 2 + box_y_koord() SAY "ID roba: " + cIdRoba
      @ 3 + box_x_koord(), 2 + box_y_koord() SAY8 "Cijena u šifarniku " + AllTrim( Str( nMpcSaPDVSifarnik ) )
      DO WHILE !Eof() .AND. self_organizacija_id() + cIdKontoProdavnica + cIdroba == kalk->idFirma + kalk->pkonto + kalk->idroba

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         IF cSravnitiD == "D"
            IF kalk->datdok > dDok
               SKIP
               LOOP
            ENDIF
         ENDIF

         IF kalk->pu_i == "1"
            nUlazKol += kalk->kolicina
            nMpvUlaz += kalk->mpcsapp * kalk->kolicina
            IF kalk->mpcsapp <> 0
               nMpcSaPDVKartica := kalk->mpcsapp
            ENDIF

         ELSEIF pu_i == "5"  .AND. !( kalk->idvd $ "12#13#22" )
            nIzlazKol += kalk->kolicina
            nMpvIzlaz += kalk->mpcsapp * kalk->kolicina
            IF kalk->mpcsapp <> 0
               nMpcSaPDVKartica := kalk->mpcsapp
            ENDIF
         ELSEIF kalk->pu_i == "5"  .AND. ( kalk->idvd $ "12#13#22" )    // povrat
            nUlazKol -= kalk->kolicina
            nMpvUlaz -= kalk->mpcsapp * kalk->kolicina
            IF kalk->mpcsapp <> 0
               nMpcSaPDVKartica := kalk->mpcsapp
            ENDIF
         ELSEIF pu_i == "3"
            // nivelacija
            nMpvUlaz += kalk->mpcsapp * kalk->kolicina
            IF kalk->mpcsapp + kalk->fcj <> 0
               nMpcSaPDVKartica := kalk->mpcsapp + kalk->fcj
            ENDIF
         ELSEIF pu_i == "I"
            nIzlazKol += kalk->gkolicin2
            nMpvIzlaz += kalk->mpcsapp * kalk->gkolicin2
            IF kalk->mpcsapp <> 0
               nMpcSaPDVKartica := kalk->mpcsapp
            ENDIF
         ENDIF
         SKIP
      ENDDO


      nRazlika := 0
      // nStanjeKol := ROUND( nUlazKol - nIzlazKol, 4 )
      // nMPVSaldo := ROUND( nMpvUlaz - nMpvIzlaz, 4 )
      nStanjeKol := nUlazKol - nIzlazKol
      nMPVSaldo := nMpvUlaz - nMpvIzlaz


      IF Round( nStanjeKol, 4 ) == 0 .AND. Round( nMPVSaldo, 4 ) == 0 // nula sve ok, preci na novu stavku
         SELECT KALK
         LOOP
      ENDIF

      IF cUvijekSif == "D"
         nMpcSaPDV := nMpcSaPDVSifarnik
      ELSE
         nMpcSaPDV := nMpcSaPDVKartica
      ENDIF

      IF Round( nStanjeKol, 4 ) <> 0
         IF Round( nMpcSaPDV - nMPVSaldo / nStanjeKol, 4 ) == 0
            nRazlika := 0 // kartica ok
         ELSE
            nRazlika := nMpcSaPDV - nMPVSaldo / nStanjeKol
         ENDIF
      ELSE
         nRazlika := nMPVSaldo
      ENDIF

      IF Round( nRazlika, 4 ) <> 0
         lGenerisao := .T.
         @ 4 + box_x_koord(), 2 + box_y_koord() SAY "Generisano stavki: " + AllTrim( Str( ++nRbr ) )
         SELECT kalk_pripr
         APPEND BLANK
         REPLACE idfirma WITH self_organizacija_id(), idroba WITH cIdRoba, ;
            datdok WITH dDok, ;
            idtarifa WITH roba->idtarifa, ;
            kolicina WITH nStanjeKol, ;
            idvd WITH "19", brdok WITH cBrNiv, ;
            rbr WITH nRbr, ;
            pkonto WITH cIdKontoProdavnica, ;
            pu_i WITH "3"
         // datfaktp WITH dDok, ;

         IF Round( nStanjeKol, 4 ) <> 0 //.AND. Abs( nMPVSaldo / nStanjeKol ) < 99999
            REPLACE fcj WITH nMPVSaldo / nStanjeKol
            REPLACE mpcsapp WITH nRazlika
         ELSE
            REPLACE kolicina WITH 1
            REPLACE fcj WITH nRazlika + nMpcSaPDV
            REPLACE mpcsapp WITH -nRazlika
            REPLACE Tbanktr WITH "X"
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

// o_konto()
   o_kalk_pripr()
   o_kalk_pripr2()
   // o_kalk()
// o_sifk()
// o_sifv()
// o_roba()

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
      SELECT kalk_pripr
      APPEND BLANK
      Scatter()
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

      ++nCnt
      @ 1 + box_x_koord(), 2 + box_y_koord() SAY AllTrim( Str( nCnt ) )

      SELECT pript
      SKIP
   ENDDO

   BoxC()

   RETURN .T.
