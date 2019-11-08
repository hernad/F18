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


FUNCTION GenMag()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. magacin početno stanje                    " )
   AAdd( _opcexe, {|| kalk_pocetno_stanje_magacin() } )

/*
   AAdd( _opc, "2. magacin početno stanje (stara opcija)" )
   AAdd( _opcexe, {|| kalk_pocetno_stanje_magacin_legacy() } )
   */

   AAdd( _opc, "3. inventure" )
   AAdd( _opcexe, {|| kalk_inventura_magacin_im_meni() } )


   AAdd( _opc, "4. magacin generacija 95 usklađenje nc" )
   AAdd( _opcexe, {|| kalk_gen_uskladjenje_nc_95() } )
/*
   AAdd( _opc, "4. nivelacija po zadatom %" )
   AAdd( _opcexe, {|| MNivPoProc() } )
*/

   f18_menu( "mmg", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION kalk_inventura_magacin_im_meni()

   PRIVATE Opc := {}
   PRIVATE opcexe := {}

   AAdd( Opc, "1. dokument inventure magacin                   " )
   AAdd( opcexe, {|| kalk_generacija_inventura_magacin_im() } )

   AAdd( Opc, "2. inventura-razlika prema postojećoj inventuri" )
   AAdd( opcexe, {|| kalk_generisanje_inventure_razlike_postojeca_magacin_im() } )


   PRIVATE Izbor := 1
   f18_menu_sa_priv_vars_opc_opcexe_izbor( "mmi" )

   RETURN .T.



FUNCTION Iz12u97()

   o_kalk_edit()

   cIdFirma    := self_organizacija_id()
   cIdVdU      := "12"
   cIdVdI      := "97"
   cBrDokU     := Space( Len( kalk_pripr->brdok ) )
   cBrDokI     := ""
   dDatDok     := CToD( "" )

   cIdPartner  := Space( Len( kalk_pripr->idpartner ) )
   dDatFaktP   := CToD( "" )

   cPoMetodiNC := "N"
   cKontoSklad := "13103  "

   Box(, 9, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 96/97 NA OSNOVU DOKUMENTA 11/12"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-"
   @ Row(), Col() GET cIdVdU VALID cIdVdU $ "11#12"
   @ Row(), Col() SAY "-" GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Dokument koji se formira (96/97)" GET cIdVdI VALID cIdVdI $ "96#97"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prenijeti na konto (prazno-ne prenositi)" GET cKontoSklad
   READ
   ESC_BCR
   BoxC()

   // utvrdimo broj nove kalkulacije
   find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVdI )
   // SELECT KALK_DOKS; SEEK cIdFirma + cIdVdI + Chr( 255 ); SKIP -1
   GO BOTTOM
   IF cIdFirma + cIdVdI == IDFIRMA + IDVD
      cBrDokI := brdok
   ELSE
      cBrDokI := Space( 8 )
   ENDIF

   kalk_fix_brdok_add_1( @cBrDokI )

   // pocnimo sa generacijom dokumenta
   SELECT KALK
   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )


   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK

      SELECT kalk_pripr; APPEND BLANK; Scatter()
      _idfirma   := cIdFirma
      _idkonto2  := KALK->idkonto2
      _idkonto   := cKontoSklad
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := KALK->( idkonto + brfaktp )
      _datfaktp  := dDatDok
      _idpartner := cIdPartner

      _fcj       := KALK->nc
      _fcj2      := KALK->nc
      _tprevoz   := "A"
      _tmarza2   := "A"
      _mkonto    := _idkonto2
      _mu_i      := "5"
      _error     := "0"
      _kolicina  := KALK->kolicina * IF( cIdVdU == "12", 1, -1 )
      _rbr       := KALK->rbr
      _idtarifa  := KALK->idtarifa
      _idroba    := KALK->idroba

      _nc        := KALK->nc
      _vpc       := KALK->vpc

      Gather()
      SELECT KALK
      SKIP 1
   ENDDO

   CLOSERET

   RETURN .T.





FUNCTION kalk_generisi_95_za_manjak_16_za_visak()

   LOCAL nFaktVPC := 0, lOdvojiVisak := .F., nBrSl := 0

   o_koncij()
   o_kalk_pripr()
   o_kalk_pripr2()
   // o_kalk()
  // o_sifk()
  // o_sifv()
  // o_roba()

   SELECT kalk_pripr
   GO TOP
   PRIVATE cIdFirma := idfirma, cIdVD := idvd, cBrDok := brdok

   IF !( cidvd $ "IM" )
      closeret
   ENDIF
   select_o_koncij( kalk_pripr->idkonto )

   lOdvojiVisak := Pitanje(, "Napraviti poseban dokument za visak?", "N" ) == "D"

   PRIVATE cBrOtp := kalk_get_next_broj_v5( cIdFirma, "95", NIL )
   IF lOdvojiVisak
      o_kalk_pripr9()
      PRIVATE cBrDop := kalk_get_next_broj_v5( cIdFirma, "16", NIL )
      DO WHILE .T.

         SELECT kalk_pripr9
         SEEK cIdFirma + "16" + cBrDop
         IF Found()
            Beep( 1 )
            IF Pitanje(, "U smecu vec postoji " + cidfirma + "-16-" + cbrdop + ", zelite li ga izbrisati?", "D" ) == "D"
               DO WHILE !Eof() .AND. idfirma + idvd + brdok == cIdFirma + "16" + cBrDop
                  SKIP 1; nBrSl := RecNo(); SKIP -1; my_delete(); GO ( nBrSl )
               ENDDO
               EXIT
            ELSE   // probaj sljedeci broj dokumenta
               cBrDop := PadR( NovaSifra( Trim( cBrDop ) ), 8 )
            ENDIF
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF

   SELECT kalk_pripr
   GO TOP
   PRIVATE nRBr := 0, nRBr2 := 0
   DO WHILE !Eof() .AND. cidfirma == idfirma .AND. cidvd == idvd .AND. cbrdok == brdok
      scatter()

      select_o_roba( _idroba )

      IF koncij->naz <> "N1"
         kalk_vpc_po_kartici( @nFaktVPC, _idfirma, _idkonto, _idroba )
      ENDIF

      SELECT kalk_pripr

      IF Round( kolicina - gkolicina, 3 ) <> 0   // popisana-stvarna=(>0 visak,<0 manjak)
         IF lOdvojiVisak .AND. Round( kolicina - gkolicina, 3 ) > 0  // visak odvojiti
            PRIVATE nKolZn := nKols := nc1 := nc2 := 0, dDatNab := CToD( "" )

            SELECT kalk_pripr9
            APPEND BLANK

            _nc := 0; nc1 := 0; nc2 := 0
            kalk_get_nabavna_mag( _datdok, _idfirma, _idroba, _idkonto, 0, 0, @nc1, @nc2, _datdok )
            IF kalk_metoda_nc() $ "13"; _nc := nc1; ELSEIF kalk_metoda_nc() == "2"; _nc := nc2; ENDIF
            SELECT kalk_pripr9

            _idpartner := ""
            _rabat := prevoz := prevoz2 := _banktr := _spedtr := _zavtr := _marza := _marza2 := _mpc := 0
            _kolicina := kalk_pripr->( kolicina - gkolicina )
            _gkolicina := _gkolicin2 := _mpc := 0
            _idkonto := _idkonto
            _Idkonto2 := ""
            _VPC := nFaktVPC
            _rbr := RedniBroj( ++nrbr2 )

            _brdok := cBrDop
            _MKonto := _Idkonto;_MU_I := "1"     // ulaz
            _PKonto := "";      _PU_I := ""
            _idvd := "16"
            _ERROR := ""
            gather()
         ELSE
            PRIVATE nKolZn := nKols := nc1 := nc2 := 0, dDatNab := CToD( "" )
            SELECT kalk_pripr2
            APPEND BLANK

            _idpartner := ""
            _rabat := prevoz := prevoz2 := _banktr := _spedtr := _zavtr := _nc := _marza := _marza2 := _mpc := 0
            _kolicina := kalk_pripr->( -kolicina + gkolicina )
            _gkolicina := _gkolicin2 := _mpc := 0
            _idkonto2 := _idkonto
            _Idkonto := ""
            _VPC := nFaktVPC
            _rbr := RedniBroj( ++nrbr )

            _brdok := cBrOtp
            _MKonto := _Idkonto;_MU_I := "5"     // izlaz
            _PKonto := "";      _PU_I := ""
            _idvd := "95"
            _ERROR := ""
            gather()
         ENDIF
      ENDIF
      SELECT kalk_pripr
      SKIP
   ENDDO

   IF nRBr2 > 0
      Msg( "Visak koji se pojavio evidentiran je u smecu kao dokument#" + cIdFirma + "-16-" + cBrDop + "#Po zavrsetku obrade manjka, vratite ovaj dokument iz smeca i obradite ga!", 60 )
   ENDIF

   closeret

   RETURN .T.





/* MNivPoProc()
 *     Nivelacija u magacinu po procentima


FUNCTION MNivPoProc()


   LOCAL nStopa := 0.0, nZaokr := 1

   o_konto()
   o_tarifa()
--   o_sifk()
--   o_sifv()
//   o_roba()
   cVarijanta := "3"
   Box(, 7, 60 )
   cIdFirma := self_organizacija_id()
   cIdkonto := PadR( "1310", 7 )
   dDatDok := Date()
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Magacin    :" GET  cidkonto VALID P_Konto( @cidkonto )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum      :" GET  dDatDok
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Cijenu zaokruziti na (br.decimalnih mjesta) :" GET nZaokr PICT "9"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "(1) promjena prema stopama iz polja ROBA->N1"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "(2) promjena prema stopama iz polja ROBA->N2"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "(3) promjena prema jedinstvenoj stopi      ?"  GET cVarijanta VALID cVarijanta $ "123"
   read; ESC_BCR

   IF cvarijanta == "3"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Stopa promjene cijena (- za smanjenje)      :" GET nStopa PICT "999.99%"
      read;ESC_BCR
   ENDIF

   BoxC()

   o_koncij()
   o_kalk_pripr()
   -- o_kalk()
   --PRIVATE cBrDok := kalk_sljedeci_broj( cidfirma, "18", 8 )

   nRbr := 0
   ## SET ORDER TO TAG "3"  // "3","idFirma+mkonto+idroba+dtos(datdok)+podbr+MU_I+IdVD",KUMPATH+"KALK")

   MsgO( "Generacija dokumenta 18 - " + cbrdok )

   --SELECT koncij; SEEK Trim( cidkonto )
   SELECT kalk
   HSEEK cidfirma + cidkonto
   DO WHILE !Eof() .AND. cidfirma + cidkonto == idfirma + mkonto

      cIdRoba := Idroba
      nUlaz := nIzlaz := 0
      nVPVU := nVPVI := nNVU := nNVI := 0
      nRabat := 0
    --  SELECT roba; HSEEK cidroba; SELECT kalk
      DO WHILE !Eof() .AND. cidfirma + cidkonto + cidroba == idFirma + mkonto + idroba

         IF ddatdok < datdok  // preskoci
            skip; LOOP
         ENDIF
         IF roba->tip $ "UT"
            skip; LOOP
         ENDIF

         IF mu_i == "1"
            IF !( idvd $ "12#22#94" )
               nUlaz += kolicina - gkolicina - gkolicin2
               IF koncij->naz == "P2"
                  nVPVU += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ELSE
                  nVPVU += Round( vpc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               ENDIF
               nNVU += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               nIzlaz -= kolicina
               IF koncij->naz == "P2"
                  nVPVI -= Round( roba->plc * kolicina, gZaokr )
               ELSE
                  nVPVI -= Round( vpc * kolicina, gZaokr )
               ENDIF
               nNVI -= Round( nc * kolicina, gZaokr )
            ENDIF
         ELSEIF mu_i == "5"
            nIzlaz += kolicina
            IF koncij->naz == "P2"
               nVPVI += Round( roba->plc * kolicina, gZaokr )
            ELSE
               nVPVI += Round( vpc * kolicina, gZaokr )
            ENDIF
            nNVI += nc * kolicina
         ELSEIF mu_i == "3"    // nivelacija
            nVPVU += Round( vpc * kolicina, gZaokr )
         ENDIF

         SKIP
      ENDDO

    --  SELECT roba; HSEEK cidroba; SELECT kalk
      IF  ( cVarijanta = "1" .AND. roba->n1 = 0 )
         skip; LOOP
      ENDIF
      IF  ( cVarijanta = "2" .AND. roba->n2 = 0 )
         skip; LOOP
      ENDIF
      IF ( Round( nulaz - nizlaz, 4 ) <> 0 ) .OR. ( Round( nvpvu - nvpvi, 4 ) <> 0 )

         SELECT kalk_pripr
         scatter()
         APPEND ncnl
         _idfirma := cidfirma; _idkonto := cidkonto; _mkonto := cidkonto; _pu_i := _mu_i := ""
         _idroba := cidroba; _idtarifa := roba->idtarifa
         _idvd := "18"; _brdok := cbrdok
         _rbr := RedniBroj( ++nrbr )
         _kolicina := nUlaz - nIzlaz
         _datdok := _DatFaktP := ddatdok
         _ERROR := ""
         _MPCSAPP := KoncijVPC()   // stara cijena

         IF cVarijanta == "1"  // roba->n1
            _VPC := Round( -_mpcsapp * roba->N1 / 100, nZaokr )
         ELSEIF cVarijanta == "2"
            _VPC := Round( -_mpcsapp * roba->N2 / 100, nZaokr )
         ELSE
            _VPC := Round( _mpcsapp * nStopa / 100, nZaokr )
         ENDIF
         Gather2()
         SELECT kalk
      ENDIF

   ENDDO
   MsgC()
   CLOSERET

   RETURN .T.

*/



/* KorekPC()
 *     Korekcija prodajne cijene - pravljenje nivelacije za magacin
 */

FUNCTION KorekPC()

   LOCAL dDok := Date(), nPom := 0, nRobaVPC := 0
   PRIVATE cMagac := PadR( "1310   ", FIELD_LENGTH_IDKONTO )

   o_koncij()
   o_konto()
   PRIVATE cSravnitiD := "D"
   PRIVATE cUvijekSif := "D"

   Box(, 6, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Magacinski konto" GET cMagac PICT "@!" VALID P_konto( @cMagac )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Sravniti do odredjenog datuma:" GET cSravnitiD VALID cSravnitiD $ "DN" PICT "@!"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Uvijek nivelisati na VPC iz sifrarnika:" GET cUvijekSif VALID cUvijekSif $ "DN" PICT "@!"
   read;ESC_BCR
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Datum do kojeg se sravnjava" GET dDok
   read;ESC_BCR
   BoxC()
//   o_roba()
   o_kalk_pripr()


   nTUlaz := nTIzlaz := 0
   nTVPVU := nTVPVI := nTNVU := nTNVI := 0
   nTRabat := 0
   PRIVATE nRbr := 0


   cBrNiv :=  kalk_get_next_broj_v5( self_organizacija_id(), "18", NIL )

   find_kalk_by_mkonto_idroba( self_organizacija_id(), gMagac )
   GO TOP
   DO WHILE !Eof() .AND. idfirma + mkonto = self_organizacija_id() + cMagac

      cIdRoba := Idroba; nUlaz := nIzlaz := 0; nVPVU := nVPVI := nNVU := nNVI := 0; nRabat := 0
      select_o_roba( cidroba )

      SELECT kalk
      IF roba->tip $ "TU"; skip; loop; ENDIF

      cIdkonto  := mkonto
      nUlazVPC  := UzmiVPCSif( cIdKonto, .T. )
      nPosljVPC := nUlazVPC
      nRobaVPC  := nUlazVPC
      DO WHILE !Eof() .AND. self_organizacija_id() + cidkonto + cidroba == idFirma + mkonto + idroba

         IF roba->tip $ "TU"; skip; loop; ENDIF
         IF cSravnitiD == "D"
            IF datdok > dDok
               skip; LOOP
            ENDIF
         ENDIF
         IF mu_i == "1"
            IF !( idvd $ "12#22#94" )
               nUlaz += kolicina - gkolicina - gkolicin2
               nVPVU += vpc * ( kolicina - gkolicina - gkolicin2 )
               nNVU += nc * ( kolicina - gkolicina - gkolicin2 )
               nUlazVPC := vpc
               IF vpc <> 0
                  nPosljVPC := vpc
               ENDIF
            ELSE
               nIzlaz -= kolicina
               nVPVI -= vpc * kolicina
               nNVI -= nc * kolicina
               IF vpc <> 0; nPosljVPC := vpc; ENDIF
            ENDIF
         ELSEIF mu_i == "5"
            nIzlaz += kolicina
            nVPVI += vpc * kolicina
            nRabat += vpc * rabatv / 100 * kolicina
            nNVI += nc * kolicina
            IF vpc <> 0; nPosljVPC := vpc; ENDIF
         ELSEIF mu_i == "3"    // nivelacija
            nVPVU += vpc * kolicina
            IF mpcsapp + vpc <> 0; nPosljVPC := mpcsapp + vpc; ENDIF
         ENDIF
         SKIP
      ENDDO


      nRazlika := 0
      nStanje := Round( nUlaz - nIzlaz, 4 )
      nVPV := Round( nVPVU - nVPVI, 4 )
      SELECT kalk_pripr

      IF cUvijekSif == "D" .AND. nUlazVPC <> nRobaVPC  ;
            .AND. nPosljVPC <> nRobaVPC
         MsgBeep( "Artikal " + cIdRoba + " ima zadnji ulaz =" + Str( nUlazVPC, 10, 3 ) + "##" + ;
            "            Cijena u sifrarniku je =" + Str( nRobaVPC, 10, 3 ) )
         IF Pitanje(, "Nivelisati na stanje iz sifrarnika ?", " " ) == "D"
            nUlazVPC := nRobaVPC
         ELSEIF Pitanje(, "Ako to ne zelite, zelite li staviti u sifrarnik cijenu sa ulaza ?", " " ) == "D"
            //SELECT roba
            ObSetVPC( nUlazVPC )
            SELECT kalk_pripr
         ENDIF
      ENDIF

      IF nStanje <> 0 .OR. nVPV <> 0
         IF nStanje <> 0
            IF cUvijekSif == "D" .AND. Round( nUlazVPC - nVPV / nStanje, 4 ) <> 0
               IF Round( nVPV / nStanje - nRobaVPC, 4 ) <> 0
                  // knjizno stanje razlicito od cijene u sifrarniku
                  nRazlika := nUlazVPC - nVPV / nStanje
               ELSE
                  nRazlika := 0
               ENDIF
            ELSE  // samo ako kartica nije ok
               IF Round( nPosljVPC - nVPV / nStanje, 4 ) = 0  // kartica izgleda ok
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
            ++nRbr
            APPEND BLANK
            REPLACE idfirma WITH self_organizacija_id(), idroba WITH cIdRoba, idkonto WITH cIdKonto, ;
               datdok WITH dDok, ;
               idtarifa WITH roba->idtarifa, ;
               datfaktp WITH dDok, ;
               kolicina WITH nStanje, ;
               idvd WITH "18", brdok WITH cBrNiv, ;
               rbr WITH Str( nRbr, 3 ), ;
               mkonto WITH cMagac, ;
               mu_i WITH "3"
            IF nStanje <> 0
               REPLACE   mpcsapp WITH nVPV / nStanje, ;
                  vpc     WITH nRazlika
            ELSE
               REPLACE   kolicina WITH 1, ;
                  mpcsapp WITH nRazlika + nUlazVPC, ;
                  vpc     WITH -nRazlika, ;
                  Tbanktr WITH "X"
            ENDIF

         ENDIF  // nRazlika<>0
      ENDIF
      SELECT kalk

   ENDDO

   my_close_all_dbf()

   RETURN .T.





FUNCTION kalk_generisi_prijem16_iz_otpreme96()

   LOCAL cBrUlaz

   o_koncij()
   o_kalk_pripr2()
   o_kalk_pripr()
   // o_kalk()
//   o_sifk()
  // o_sifv()
//   o_roba()

   SELECT kalk_pripr
   GO TOP

   PRIVATE cIdFirma := field->idfirma, cIdVD := field->idvd, cBrDok := field->brdok

   IF !( cIdvd $ "96#95" )  .OR. Empty( field->idkonto )
      closeret
   ENDIF


/*
   PRIVATE cBrUlaz := "0"

   find_kalk_doks_by_broj_fakture( cIdFirma, "16" )
   GO BOTTOM

   IF idvd <> "16"
      cBrUlaz := Space( 8 )
   ELSE
      cBrUlaz := brdok
   ENDIF

   IF my_get_from_ini( "KALKSI", "EvidentirajOtpis", "N", KUMPATH ) == "D"
      cBrUlaz := StrTran( cBrUlaz, "-X", "  " )
   ENDIF

   kalk_fix_brdok_add_1( @cBrUlaz )
*/

   // PRIVATE cBrUlaz := kalk_get_next_broj_v5( cIdFirma, "16", field->idkonto )
   cBrUlaz := "G" + SubStr( field->brdok, 2 )


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

      _TPrevoz := "%"
      _TCarDaz := "%"
      _TBankTr := "%"
      _TSpedtr := "%"
      _TZavTr := "%"
      _TMarza := "%"
      _TMarza := "A"
      _gkolicina := _gkolicin2 := _mpc := 0
      select_o_koncij( kalk_pripr->idkonto2 )

      IF koncij->naz == "N1"  // otprema je izvrsena iz magacina koji se vodi po nc
         select_o_koncij( kalk_pripr->idkonto )
         IF koncij->naz <> "N1"     // ulaz u magacin sa vpc
            _VPC := KoncijVPC()
            _marza := KoncijVPC() - kalk_pripr->nc
            _tmarza := "A"
         ELSE
            _VPC := kalk_pripr->vpc
         ENDIF
      ELSE
         _VPC := kalk_pripr->vpc
      ENDIF
      SELECT kalk_pripr2
      _fcj := _fcj2 := _nc := kalk_pripr->nc
      _rbr := Str( ++nRbr, 3 )
      _kolicina := kalk_pripr->kolicina
      _BrFaktP := Trim( kalk_pripr->idkonto2 ) + "/" + kalk_pripr->brfaktp
      _idkonto := kalk_pripr->idkonto
      _idkonto2 := ""
      _brdok := cBrUlaz
      _MKonto := _Idkonto
      _MU_I := "1"     // ulaz
      _PKonto := ""
      _PU_I := ""
      _idvd := "16"

      _TBankTr := "X"    // izgenerisani dokument
      gather()

      SELECT kalk_pripr
      SKIP

   ENDDO

   my_close_all_dbf()

   RETURN .T.




/* kalk_gen_16_iz_96
 *


FUNCTION kalk_gen_16_iz_96()



   LOCAL cIdFirma    := self_organizacija_id()
   LOCAL cIdVdU      := "96"
   LOCAL cIdVdI      := "16"
   LOCAL cBrDokU     := Space( Len( kalk_pripr->brdok ) )
   LOCAL cBrDokI     := ""
   LOCAL dDatDok     := CToD( "" )

   o_kalk_edit()
   cIdPartner  := Space( Len( kalk_pripr->idpartner ) )
   dDatFaktP   := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 6, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 16 NA OSNOVU DOKUMENTA 96"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-" + cIdVdU + "-"
   --@ Row(), Col() GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma + cIdVdU + cBrDokU )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   READ; ESC_BCR
   BoxC()


   cBrDokI := kalk_get_next_broj_v5( cIdFirma, cIdVdI, NIL )


   // pocnimo sa generacijom dokumenta
   SELECT KALK
   SEEK cIdFirma + cIdVDU + cBrDokU
   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK
      PushWA()
      Scatter()
      SELECT kalk_pripr; APPEND BLANK
      _idfirma   := cIdFirma
      _idkonto   := KALK->idkonto2
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := KALK->( idkonto + brfaktp )
      _datfaktp  := dDatDok
      _idpartner := cIdPartner
      _fcj       := KALK->nc
      _fcj2      := KALK->nc
      _tprevoz   := "A"
      _tmarza2   := "A"
      _mkonto    := KALK->idkonto2
      _mu_i      := "1"
      _error     := "0"
      SELECT kalk_pripr; Gather()
      SELECT KALK; PopWA()
      SKIP 1
   ENDDO

   CLOSERET

   RETURN .F.
 */



/* Iz16u14
 *     Od 16 napravi 14
 */

FUNCTION Iz16u14()

   o_kalk_edit()

   cIdFirma    := self_organizacija_id()
   cIdVdU      := "16"
   cIdVdI      := "14"
   cBrDokU     := Space( Len( kalk_pripr->brdok ) )
   cBrDokI     := ""
   dDatDok     := CToD( "" )

   cIdPartner  := Space( Len( kalk_pripr->idpartner ) )
   cBrFaktP    := Space( Len( kalk_pripr->brfaktp ) )
   dDatFaktP   := CToD( "" )

   cPoMetodiNC := "N"

   Box(, 8, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "FORMIRANJE DOKUMENTA 14 NA OSNOVU DOKUMENTA 16"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-"
   @ Row(), Col() SAY cIdVdU
   @ Row(), Col() SAY "-" GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Broj fakture" GET cBrFaktP
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "Datum fakture" GET dDatFaktP
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Kupac" GET cIdPartner VALID p_partner( @cIdPartner )
   READ; ESC_BCR
   BoxC()

   cBrDokI := kalk_get_next_broj_v5( cIdFirma, cIdVdI, NIL )


   // pocnimo sa generacijom dokumenta
   SELECT KALK
   SEEK cIdFirma + cIdVDU + cBrDokU
   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK
      SELECT kalk_pripr; APPEND BLANK; Scatter()
      _idfirma   := cIdFirma
      _idkonto2  := KALK->idkonto
      _idvd      := cIdVDI
      _brdok     := cBrDokI
      _datdok    := dDatDok

      _brfaktp   := cBrFaktP
      _datfaktp  := dDatFaktP
      _idpartner := cIdPartner

      _fcj       := KALK->nc
      _fcj2      := KALK->nc
      _tprevoz   := "A"
      _tmarza2   := "A"
      _mkonto    := _idkonto2
      _mu_i      := "5"
      _error     := "0"
      _kolicina  := KALK->kolicina
      _rbr       := KALK->rbr
      _idtarifa  := KALK->idtarifa
      _idroba    := KALK->idroba

      _nc        := KALK->nc
      _vpc       := KALK->vpc

      Gather()
      SELECT KALK
      SKIP 1
   ENDDO

   my_close_all_dbf()

   RETURN .T.
