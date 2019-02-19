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

STATIC s_nMjesecOd
STATIC s_nMjesecDo
STATIC s_nGodinaOd
STATIC s_nGodinaDo
STATIC s_nXml0ili1 := 0
MEMVAR GetList
MEMVAR dPerOd, dPerDo, nPorGodina

FUNCTION ld_olp_gip_obrazac()

   LOCAL nC1 := 20
   LOCAL i
   LOCAL cTPNaz
   LOCAL nKrug := 1
   LOCAL cRadneJedinice := Space( 60 )
   LOCAL cIdRjTekuca := Space( 2 )
   LOCAL cIdRadnik := Space( LEN_IDRADNIK )
   LOCAL cPrimDobra := Space( 100 )
   LOCAL cIdRj
   LOCAL nMjesecOd
   LOCAL nMjesecDo
   LOCAL nGodinaOd
   LOCAL nGodinaDo
   LOCAL cDopr10 := "10"
   LOCAL cDopr11 := "11"
   LOCAL cDopr12 := "12"
   LOCAL cDopr1X := "1X"
   LOCAL cVarijantaIzvjestaja := "2"
   LOCAL cTP_off := Space( 100 )
   LOCAL cObracun := gObracun
   LOCAL cWinPrint := "E"
   LOCAL nOper := 1
   LOCAL nGodina

   nGodina := Year( danasnji_datum() ) - 1

   ol_tmp_tbl()    // kreiraj pomocnu tabelu
   cIdRj := gLDRadnaJedinica
   nMjesecOd := ld_tekuci_mjesec()
   nMjesecDo := ld_tekuci_mjesec()
   nGodinaOd := ld_tekuca_godina()
   nGodinaDo := ld_tekuca_godina()

   cPredNaz := Space( 50 )
   cPredAdr := Space( 50 )
   cPredJMB := Space( 13 )

   cOperacija := "Novi"
   dDatUnosa := Date()
   dDatPodnosenja := Date()
   nBrZahtjeva := 1

   ol_o_tbl()
   cPredNaz := PadR( fetch_metric( "obracun_plata_preduzece_naziv", NIL, cPredNaz ), 100 )
   cPredAdr := PadR( fetch_metric( "obracun_plata_preduzece_adresa", NIL, cPredAdr ), 100 )
   cPredJMB := PadR( fetch_metric( "obracun_plata_preduzece_id_broj", NIL, cPredJMB ), 13 )

   Box( "#OBRAČUNSKI LISTOVI RADNIKA OLP, GIP", 17, 75 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radne jedinice: " GET cRadneJedinice PICT "@!S25"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Period od:" GET nMjesecOd PICT "99"
   @ box_x_koord() + 2, Col() + 1 SAY "/" GET nGodinaOd PICT "9999"

   @ box_x_koord() + 2, Col() + 1 SAY "do:" GET nMjesecDo PICT "99"
   @ box_x_koord() + 2, Col() + 1 SAY "/" GET nGodinaDo PICT "9999"
   @ box_x_koord() + 2, Col() + 1 SAY " GIP za godinu:" GET nGodina PICT "9999"
   IF ld_vise_obracuna()
      @ box_x_koord() + 2, Col() + 2 SAY8 "Obračun:" GET cObracun WHEN ld_help_broj_obracuna( .T., cObracun ) VALID ld_valid_obracun( .T., cObracun )
   ENDIF
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Radnik (prazno-svi radnici): " GET cIdRadnik  VALID Empty( cIdRadnik ) .OR. P_RADN( @cIdRadnik )
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "    Isplate u usl. ili dobrima:"  GET cPrimDobra PICT "@S30"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Tipovi koji ne ulaze u obrazac:"  GET cTP_off PICT "@S30"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "   Doprinos iz pio: " GET cDopr10
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "   Doprinos iz zdr: " GET cDopr11
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "   Doprinos iz nez: " GET cDopr12
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Doprinos iz ukupni: " GET cDopr1X
   @ box_x_koord() + 12, box_y_koord() + 2 SAY "Naziv preduzeca: " GET cPredNaz PICT "@S30"
   @ box_x_koord() + 12, Col() + 1 SAY "JID: " GET cPredJMB
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "Adresa: " GET cPredAdr PICT "@S30"

   @ box_x_koord() + 15, box_y_koord() + 2 SAY "(1) OLP-1021 / (2) GIP-1022 / (3,4) AOP:" GET cVarijantaIzvjestaja VALID cVarijantaIzvjestaja $ "1234"
   @ box_x_koord() + 15, Col() + 2 SAY "def.rj" GET cIdRjTekuca
   @ box_x_koord() + 15, Col() + 2 SAY "st./exp.(S/E)?" GET cWinPrint  VALID cWinPrint $ "SE" PICT "@!"


   READ
   // aRet := get_period_od_do( nMjesecOd, nGodinaOd, nMjesecDo, nGodinaDo )
   // dPerOd := aRet[ 1 ]
   // dPerDo := aRet[ 2 ]
   dPerOd := CToD( "01.01." + AllTrim( Str( nGodina ) ) )
   dPerDo := CToD( "31.12." + AllTrim( Str( nGodina ) ) )

   IF cWinPrint == "E"
      nPorGodina := nGodina
      @ box_x_koord() + 16, box_y_koord() + 2 SAY "P.godina" GET nPorGodina PICT "9999"
      @ box_x_koord() + 16, Col() + 2 SAY "Dat.podnos." GET dDatPodnosenja
      @ box_x_koord() + 16, Col() + 2 SAY "Dat.unosa" GET dDatUnosa
      @ box_x_koord() + 17, box_y_koord() + 2 SAY "operacija: 1 (novi) 2 (izmjena) 3 (brisanje)" GET nOper PICT "9"
      READ
   ENDIF

   cOperacija := g_operacija( nOper )

   clvbox()

   ESC_BCR

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   s_nMjesecOd := nMjesecOd
   s_nMjesecDo := nMjesecDo
   s_nGodinaOd := nGodinaOd
   s_nGodinaDo := nGodinaDo

   IF cWinPrint == "S"
      s_nXml0ili1 := 1
   ELSE
      s_nXml0ili1 := 0
   ENDIF


   set_metric( "obracun_plata_preduzece_naziv", NIL, AllTrim( cPredNaz ) )
   set_metric( "obracun_plata_preduzece_adresa", NIL, AllTrim( cPredAdr ) )
   set_metric( "obracun_plata_preduzece_id_broj", NIL, cPredJMB )

   seek_ld( NIL, { nGodinaOd, nGodinaDo }, NIL, NIL, cIdRadnik ) // seek_ld( cIdRj, nGodina, nMjesec, cObracun, cIdRadn, cTag )
   ld_obracunski_list_sort( cRadneJedinice, nGodinaOd, nGodinaDo, nMjesecOd, nMjesecDo, cIdRadnik, cVarijantaIzvjestaja, cObracun )
   ol_fill_data( cRadneJedinice, cIdRjTekuca, nGodinaOd, nGodinaDo, nMjesecOd, nMjesecDo, cIdRadnik, ;
      cPrimDobra, cTP_off, cDopr10, cDopr11, cDopr12, cDopr1X, cVarijantaIzvjestaja, cObracun )

   IF s_nXml0ili1 == 1    // stampa izvjestaja xml/oo3
      _xml_print( cVarijantaIzvjestaja )
   ELSE
      nBrZahtjeva := ld_mip_broj_obradjenih_radnika()
      _xml_export( cVarijantaIzvjestaja, nMjesecOd, nGodinaOd )
      MsgBeep( "Obradjeno " + AllTrim( Str( nBrZahtjeva ) ) + " zahtjeva." )
   ENDIF

   RETURN .T.



FUNCTION ol_fill_data( cRadneJedinice, cIdRjTekuca, nGodinaOd, nGodinaDo, nMjesecOd, nMjesecDo, ;
      cIdRadnik, cPrimDobra, cTP_off, cDopr10, cDopr11, cDopr12, cDopr1X, ;
      cRptTip, cObracun, cTp1, cTp2, cTp3, cTp4, cTp5 )

   LOCAL i
   LOCAL cPom
   LOCAL nPrDobra
   LOCAL nTP_off
   LOCAL nTp1 := 0
   LOCAL nTp2 := 0
   LOCAL nTp3 := 0
   LOCAL nTp4 := 0
   LOCAL nTp5 := 0
   LOCAL nTrosk := 0
   LOCAL nIDopr10 := 0000.00000
   LOCAL nIDopr11 := 0000.00000
   LOCAL nIDopr12 := 0000.00000
   LOCAL nIDopr1X := 0000.00000
   LOCAL lInRS := .F.
   LOCAL cIdRadnikTekuci, cTipRada

   // dodatni tipovi primanja
   IF cTp1 == nil
      cTp1 := ""
   ENDIF
   IF cTp2 == nil
      cTp2 := ""
   ENDIF
   IF cTp3 == nil
      cTp3 := ""
   ENDIF
   IF cTp4 == nil
      cTp4 := ""
   ENDIF
   IF cTp5 == nil
      cTp5 := ""
   ENDIF


   SELECT ld

   DO WHILE !Eof()

      IF ld_godina_mjesec_string( field->godina, field->mjesec ) <  ld_godina_mjesec_string( nGodinaOd, nMjesecOd )
         SKIP
         LOOP
      ENDIF

      IF ld_godina_mjesec_string( field->godina, field->mjesec ) >  ld_godina_mjesec_string( nGodinaDo, nMjesecDo )
         SKIP
         LOOP
      ENDIF

      cIdRadnikTekuci := field->idradn

      IF !Empty( cIdRadnik )
         IF cIdRadnikTekuci <> cIdRadnik
            SKIP
            LOOP
         ENDIF
      ENDIF

      cTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )
      lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad )

      ld_pozicija_parobr( ld->mjesec, ld->godina, iif( ld_vise_obracuna(), ld->obr, ), ld->idrj )

      select_o_radn( cIdRadnikTekuci )

      IF cRptTip $ "3#4"
         IF ( cTipRada $ " #I#N" )
            SELECT ld
            SKIP
            LOOP
         ENDIF
      ELSE
         IF !( cTipRada $ " #I#N" )
            SELECT ld
            SKIP
            LOOP
         ENDIF
      ENDIF

      SELECT ld

      nBruto := 0
      nTrosk := 0
      nBrDobra := 0
      nDoprStU := 0
      nDopPio := 0
      nDopZdr := 0
      nDopNez := 0
      nDopUk := 0
      nNeto := 0
      nPrDobra := 0
      nTP_off := 0
      nTp1 := 0
      nTp2 := 0
      nTp3 := 0
      nTp4 := 0
      nTp5 := 0

      DO WHILE !Eof() .AND. field->idradn == cIdRadnikTekuci

         IF ld_godina_mjesec_string( field->godina, field->mjesec ) < ld_godina_mjesec_string( nGodinaOd, nMjesecOd )
            SKIP
            LOOP
         ENDIF

         IF ld_godina_mjesec_string( field->godina, field->mjesec ) > ld_godina_mjesec_string( nGodinaDo, nMjesecDo )
            SKIP
            LOOP
         ENDIF

         cRadJed := ld->idrj   // radna jedinica

         cTipRada := get_ld_rj_tip_rada( ld->idradn, ld->idrj )    // uvijek provjeri tip rada, ako ima vise obracuna
         cTrosk := radn->trosk
         lInRS := radnik_iz_rs( radn->idopsst, radn->idopsrad )

         IF cRptTip $ "3#4"
            IF ( cTipRada $ " #I#N" )
               SKIP
               LOOP
            ENDIF
         ELSE
            IF !( cTipRada $ " #I#N" )
               SKIP
               LOOP
            ENDIF
         ENDIF

         ld_pozicija_parobr( ld->mjesec, ld->godina, IF( ld_vise_obracuna(), ld->obr, ),  ld->idrj )

         nPrDobra := 0
         nTP_off := 0

         IF !Empty( cPrimDobra )
            FOR t := 1 TO 60
               cPom := IF( t > 9, Str( t, 2 ), "0" + Str( t, 1 ) )
               IF ld->( FieldPos( "I" + cPom ) ) <= 0
                  EXIT
               ENDIF
               nPrDobra += IF( cPom $ cPrimDobra, LD->&( "I" + cPom ), 0 )
            NEXT
         ENDIF

         IF !Empty( cTP_off )
            FOR o := 1 TO 60
               cPom := IF( o > 9, Str( o, 2 ), "0" + Str( o, 1 ) )
               IF ld->( FieldPos( "I" + cPom ) ) <= 0
                  EXIT
               ENDIF
               nTP_off += IF( cPom $ cTP_off, LD->&( "I" + cPom ), 0 )
            NEXT
         ENDIF

         // ostali tipovi primanja
         IF !Empty( cTp1 )
            nTp1 := LD->&( "I" + cTp1 )
         ENDIF
         IF !Empty( cTp2 )
            nTp2 := LD->&( "I" + cTp2 )
         ENDIF
         IF !Empty( cTp3 )
            nTp3 := LD->&( "I" + cTp3 )
         ENDIF
         IF !Empty( cTp4 )
            nTp4 := LD->&( "I" + cTp4 )
         ENDIF
         IF !Empty( cTp5 )
            nTp5 := LD->&( "I" + cTp5 )
         ENDIF


         nNeto := field->uneto
         nKLO := get_koeficijent_licnog_odbitka( field->ulicodb )
         nL_odb := field->ulicodb

         // tipovi primanja koji ne ulaze u bruto osnovicu
         IF ( nTP_off > 0 )
            nNeto := ( nNeto - nTP_off )
         ENDIF

         nBruto := ld_get_bruto_osnova( nNeto, cTipRada, nL_odb )

         nMBruto := nBruto

         // prvo provjeri hoces li racunati mbruto
         IF calc_mbruto()
            // minimalni bruto
            nMBruto := min_bruto( nBruto, field->usati )
         ENDIF

         // ugovori o djelu
         IF cTipRada == "U" .AND. cTrosk <> "N"

            nTrosk := ROUND2( nMBruto * ( gUgTrosk / 100 ), gZaok2 )

            IF lInRs == .T.
               nTrosk := 0
            ENDIF

         ENDIF


         IF cTipRada == "A" .AND. cTrosk <> "N"  // autorski honorar

            nTrosk := ROUND2( nMBruto * ( gAhTrosk / 100 ), gZaok2 )

            IF lInRs == .T.
               nTrosk := 0
            ENDIF

         ENDIF

         IF cRptTip $ "3#4"
            // ovo je bruto iznos
            nMBruto := ( nBruto - nTrosk )
         ENDIF


         IF nMBruto <= 0    // ovo preskoci, nema ovdje GIP-a
            SELECT ld
            SKIP
            LOOP
         ENDIF

         // bruto primanja u uslugama ili dobrima
         // za njih posebno izracunaj bruto osnovicu
         IF nPrDobra > 0
            nBrDobra := ld_get_bruto_osnova( nPrDobra, cTipRada, nL_odb )
         ENDIF

         // ocitaj_izbaci doprinose, njihove iznose
         nDopr10 := get_dopr( cDopr10, cTipRada )
         nDopr11 := get_dopr( cDopr11, cTipRada )
         nDopr12 := get_dopr( cDopr12, cTipRada )
         nDopr1X := get_dopr( cDopr1X, cTipRada )

         // izracunaj doprinose
         nIDopr10 := Round( nMBruto * nDopr10 / 100, 4 )
         nIDopr11 := Round( nMBruto * nDopr11 / 100, 4 )
         nIDopr12 := Round( nMBruto * nDopr12 / 100, 4 )

         // zbirni je zbir ova tri doprinosa
         nIDopr1X := Round( nIDopr10 + nIDopr11 + nIDopr12, 4 )

         // ukupno dopr iz 31%
         // nDoprIz := u_dopr_iz( nMBruto, cTipRada )

         // osnovica za porez
         IF cRptTip $ "3#4"
            nPorOsn := ( nMBruto - nIDopr1X ) - nL_odb
         ELSE
            nPorOsn := ( nBruto - nIDopr1X ) - nL_odb
         ENDIF

         // ako je neoporeziv radnik, nema poreza
         IF !radn_oporeziv( radn->id, ld->idrj ) .OR. ( nBruto - nIDopr1X ) < nL_odb
            nPorOsn := 0
         ENDIF

         // porez je ?
         nPorez := izr_porez( nPorOsn, "B" )

         SELECT ld

         // na ruke je
         IF cRptTip $ "3#4"
            nNaRuke := Round( ( nMBruto - nIDopr1X - nPorez ) ;
               + nTrosk, 2 )
         ELSE
            nNaRuke := Round( nBruto - nIDopr1X - nPorez, 2 )
         ENDIF

         nIsplata := nNaRuke

         // da li se radi o minimalcu ?
         IF cTipRada $ " #I#N#"
            nIsplata := min_neto( nIsplata, field->usati )
         ENDIF

         nMjIspl := 0
         cIsplZa := ""
         cVrstaIspl := ""
         dDatIspl := Date()
         cObr := " "

         IF ld_vise_obracuna()
            cObr := field->obr
         ENDIF

         cTmpRj := field->idrj // radna jedinica
         IF !Empty( cIdRjTekuca )
            cTmpRj := cIdRjTekuca
         ENDIF

         dDatIspl := ld_get_datum_isplate_plate( cTmpRJ, field->godina,  field->mjesec, cObr, @nMjIspl, @cIsplZa, @cVrstaIspl )



         // ubaci u tabelu podatke
         _ins_tbl( cIdRadnikTekuci, ;
            cRadJed, ;
            cTipRada, ;
            "placa", ;
            dDatIspl, ;
            ld->mjesec, ;
            nMjIspl, ;
            cIsplZa, ;
            cVrstaIspl, ;
            ld->godina, ;
            nBruto - nBrDobra, ;
            nBrDobra, ;
            nBruto, ;
            nMBruto, ;
            nTrosk, ;
            nDopr1X, ;
            nIDopr10, ;
            nIDopr11, ;
            nIDopr12, ;
            nIDopr1X, ;
            nNaRuke, ;
            nKLO, ;
            nL_Odb, ;
            nPorOsn, ;
            nPorez, ;
            nIsplata, ;
            ld->usati, ;
            nTp1, ;
            nTp2, ;
            nTp3, ;
            nTp4, ;
            nTp5 )

         SELECT ld
         SKIP

      ENDDO

   ENDDO

   RETURN .T.

// ----------------------------------------
// export xml-a
// ----------------------------------------
STATIC FUNCTION _xml_export( cTip, mjesec, godina )

   LOCAL cMsg
   LOCAL _id_br, _naziv, _adresa, _mjesto
   LOCAL _lokacija, nMakeDir, _error, _a_files
   LOCAL _output_file := ""

   IF s_nXml0ili1 == 1
      RETURN .F.
   ENDIF

   IF cTip == "1"
      RETURN .T.
   ENDIF

   _id_br  := fetch_metric( "org_id_broj", NIL, PadR( "<POPUNI>", 13 ) )
   _naziv  := fetch_metric( "org_naziv", NIL, PadR( "<POPUNI naziv>", 100 ) )
   _adresa := fetch_metric( "org_adresa", NIL, PadR( "<POPUNI adresu>", 100 ) )
   _mjesto   := fetch_metric( "org_mjesto", NIL, PadR( "<POPUNI mjesto>", 100 ) )

   Box(, 6, 70 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY " - Firma/Organizacija - "
   @ box_x_koord() + 3, box_y_koord() + 2 SAY " Id broj: " GET _id_br
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "   Naziv: " GET _naziv PICT "@S50"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "  Adresa: " GET _adresa PICT "@S50"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "  Mjesto: " GET _mjesto PICT "@S50"
   READ

   BoxC()

   set_metric( "org_id_broj", NIL, _id_br )
   set_metric( "org_naziv", NIL, _naziv )
   set_metric( "org_adresa", NIL, _adresa )
   set_metric( "org_mjesto", NIL, _mjesto )

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   _id_br := AllTrim( _id_br )

   _lokacija := my_home() + "export" + SLASH

   IF DirChange( _lokacija ) != 0

      nMakeDir := MakeDir ( _lokacija )
      IF nMakeDir != 0
         MsgBeep( "kreiranje " + _lokacija + " neuspjesno ?!" )
         log_write( "dircreate err:" + _lokacija, 6 )
         RETURN .F.
      ENDIF

   ENDIF

   DirChange( _lokacija )

   // napuni xml fajl
   _fill_e_xml( _id_br + ".xml" )

   cMsg := "Generacija obrasca završena.#"
   cMsg += "Fajl se nalazi na desktopu u folderu F18_dokumenti"

   MsgBeep( cMsg )

   DirChange( my_home() )

   my_close_all_dbf()

   _output_file := "gip_" + AllTrim( my_server_params()[ "database" ] ) + "_" + ;
      AllTrim( Str( mjesec ) ) + "_" + AllTrim( Str( godina ) ) + ".xml"

   // kopiraj fajl na desktop
   f18_copy_to_desktop( _lokacija, _id_br + ".xml", _output_file )

   RETURN .T.


// ----------------------------------------
// stampa xml-a
// ----------------------------------------
STATIC FUNCTION _xml_print( tip )

   LOCAL _template
   LOCAL _xml_file := my_home() + "data.xml"

   IF s_nXml0ili1 == 0
      RETURN .F.
   ENDIF

   download_template( "ld_aop.odt", "bd41446955e753f0e4f1e34b9f5f70aa44fcb455167117abfdb80403d18e938e" )
   download_template( "ld_aop2.odt", "c010ca96454ca0e69c09a34c6293a919124a8f25409553946014b2ca56298fee" )
   download_template( "ld_olp.odt", "8e019f9d8a646fe5ec3b5aee9b49d0e5b147cc6c54fbdd2ee4ebefcb4e589588" )
   download_template( "ld_gip.odt", "9bb6dbb630c362cb0363d1830c3408e03ba28ff82882bfe9388577f6eeb62085" )


   _fill_xml( tip, _xml_file )

   DO CASE
   CASE tip == "1"
      _template := "ld_olp.odt"
   CASE tip == "2"
      _template := "ld_gip.odt"
   CASE tip == "3"
      _template := "ld_aop.odt"
   CASE tip == "4"
      _template := "ld_aop2.odt"
   ENDCASE

   IF generisi_odt_iz_xml( _template, _xml_file )
      prikazi_odt()
   ENDIF

   RETURN .T.


// ------------------------------------
// header za export
// ------------------------------------
STATIC FUNCTION _xml_head()

   LOCAL cStr := '<?xml version="1.0" encoding="UTF-8"?><PaketniUvozObrazaca xmlns="urn:PaketniUvozObrazaca_V1_0.xsd">'

   xml_head( .T., cStr )

   RETURN .T.



// --------------------------------------------
// filuje xml fajl sa podacima za export
// --------------------------------------------
STATIC FUNCTION _fill_e_xml( file_name )

   LOCAL nTArea := Select()
   LOCAL nT_prih := 0
   LOCAL nT_pros := 0
   LOCAL nT_bruto := 0
   LOCAL nT_neto := 0
   LOCAL nT_poro := 0
   LOCAL nT_pori := 0
   LOCAL nT_dop_s := 0
   LOCAL nT_dop_u := 0
   LOCAL nT_d_zdr := 0
   LOCAL nT_d_pio := 0
   LOCAL nT_d_nez := 0
   LOCAL nT_bbd := 0
   LOCAL nT_klo := 0
   LOCAL nT_lodb := 0

   // otvori xml za upis
   create_xml( file_name )

   // upisi header
   _xml_head()

   // ovo ne treba zato što je u headeru sadržan ovaj prvi sub-node
   // <paketniuvozobrazaca>
   // xml_subnode("PaketniUvozObrazaca", .f.)

   // <podacioposlodavcu>
   xml_subnode( "PodaciOPoslodavcu", .F. )

   // naziv firme
   xml_node( "JIBPoslodavca", AllTrim( cPredJmb ) )
   xml_node( "NazivPoslodavca", to_xml_encoding( AllTrim( cPredNaz ) ) )
   xml_node( "BrojZahtjeva", Str( nBrZahtjeva ) )
   xml_node( "DatumPodnosenja", xml_date( dDatPodnosenja ) )

   xml_subnode( "PodaciOPoslodavcu", .T. )

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      // po radniku
      cIdRadnikTekuci := field->idradn

      select_o_radn( cIdRadnikTekuci )

      SELECT r_export

      xml_subnode( "Obrazac1022", .F. )
      xml_subnode( "Dio1PodaciOPoslodavcuIPoreznomObvezniku", .F. )

      xml_node( "JIBJMBPoslodavca", AllTrim( cPredJmb ) )
      xml_node( "Naziv", to_xml_encoding( AllTrim( cPredNaz ) ) )
      xml_node( "AdresaSjedista", to_xml_encoding( AllTrim( cPredAdr ) ) )
      xml_node( "JMBZaposlenika", AllTrim( radn->matbr ) )
      xml_node( "ImeIPrezime", to_xml_encoding( AllTrim( radn->ime ) + " " + ;
         AllTrim( radn->naz ) ) )
      xml_node( "AdresaPrebivalista", to_xml_encoding( AllTrim( radn->streetname ) + ;
         " " + AllTrim( radn->streetnum ) ) )
      xml_node( "PoreznaGodina", Str( nPorGodina ) )
      xml_node( "PeriodOd", xml_date( dPerOd ) )
      xml_node( "PeriodDo", xml_date( dPerDo ) )

      xml_subnode( "Dio1PodaciOPoslodavcuIPoreznomObvezniku", .T. )
      xml_subnode( "Dio2PodaciOPrihodimaDoprinosimaIPorezu", .F. )

      nT_prih := 0
      nT_pros := 0
      nT_bruto := 0
      nT_neto := 0
      nT_poro := 0
      nT_pori := 0
      nT_dop_s := 0
      nT_dop_u := 0
      nT_d_zdr := 0
      nT_d_pio := 0
      nT_d_nez := 0
      nT_bbd := 0
      nT_klo := 0
      nT_lodb := 0

      nCnt := 0

      DO WHILE !Eof() .AND. field->idradn == cIdRadnikTekuci

         // ukupni doprinosi
         REPLACE field->dop_uk WITH field->dop_pio + ;
            field->dop_nez + field->dop_zdr

         REPLACE field->osn_por WITH ( field->bruto - field->dop_uk ) - ;
            field->l_odb

         // ako je neoporeziv radnik, nema poreza
         IF !radn_oporeziv( field->idradn, field->idrj ) .OR. ;
               field->osn_por < 0
            REPLACE field->osn_por WITH 0
         ENDIF

         IF field->osn_por > 0
            REPLACE field->izn_por WITH field->osn_por * 0.10
         ELSE
            REPLACE field->izn_por WITH 0
         ENDIF

         REPLACE field->neto WITH ( field->bruto - field->dop_uk ) - ;
            field->izn_por

         IF field->tiprada $ " #I#N#"
            REPLACE field->neto WITH ;
               min_neto( field->neto, field->sati )
         ENDIF


         xml_subnode( "PodaciOPrihodimaDoprinosimaIPorezu", .F. )

         xml_node( "Mjesec", Str( field->mj_ispl ) )
         xml_node( "IsplataZaMjesecIGodinu", ;
            to_xml_encoding( AllTrim( field->ispl_za ) ) )
         xml_node( "VrstaIsplate", ;
            to_xml_encoding( AllTrim( field->vr_ispl ) ) )
         xml_node( "IznosPrihodaUNovcu", ;
            Str( field->prihod, 12, 2 ) )
         xml_node( "IznosPrihodaUStvarimaUslugama", ;
            Str( field->prihost, 12, 2 ) )
         xml_node( "BrutoPlaca", Str( field->bruto, 12, 2 ) )
         xml_node( "IznosZaPenzijskoInvalidskoOsiguranje", ;
            Str( field->dop_pio, 12, 2 ) )
         xml_node( "IznosZaZdravstvenoOsiguranje", ;
            Str( field->dop_zdr, 12, 2 ) )
         xml_node( "IznosZaOsiguranjeOdNezaposlenosti", ;
            Str( field->dop_nez, 12, 2 ) )
         xml_node( "UkupniDoprinosi", Str( field->dop_uk, 12, 2 ) )
         xml_node( "PlacaBezDoprinosa", ;
            Str( field->bruto - field->dop_uk, 12, 2 ) )

         xml_node( "FaktorLicnihOdbitakaPremaPoreznojKartici", ;
            Str( field->klo, 12, 2 ) )

         xml_node( "IznosLicnogOdbitka", Str( field->l_odb, 12, 2 ) )

         xml_node( "OsnovicaPoreza", Str( field->osn_por, 12, 2 ) )
         xml_node( "IznosUplacenogPoreza", Str( field->izn_por, 12, 2 ) )

         xml_node( "NetoPlaca", Str( field->neto, 12, 2 ) )
         xml_node( "DatumUplate", xml_date( field->datispl ) )

         // xml_node("opis", to_xml_encoding( ALLTRIM( field->naziv ) ) )
         // xml_node("uk", STR( field->ukupno, 12, 2 ) )

         xml_subnode( "PodaciOPrihodimaDoprinosimaIPorezu", .T. )

         nT_prih += field->prihod
         nT_pros += field->prihost
         nT_bruto += field->bruto
         nT_neto += field->neto
         nT_poro += field->osn_por
         nT_pori += field->izn_por
         nT_dop_s += field->dop_u_st
         nT_dop_u += field->dop_uk
         nT_d_zdr += field->dop_zdr
         nT_d_pio += field->dop_pio
         nT_d_nez += field->dop_nez
         nT_bbd += ( field->bruto - field->dop_uk )
         nT_klo += field->klo
         nT_lodb += field->l_odb

         SKIP
      ENDDO

      xml_subnode( "Ukupno", .F. )

      xml_node( "IznosPrihodaUNovcu", Str( nT_prih, 12, 2 ) )
      xml_node( "IznosPrihodaUStvarimaUslugama", ;
         Str( nT_pros, 12, 2 ) )

      xml_node( "BrutoPlaca", Str( nT_bruto, 12, 2 ) )
      xml_node( "IznosZaPenzijskoInvalidskoOsiguranje", ;
         Str( nT_d_pio, 12, 2 ) )

      xml_node( "IznosZaZdravstvenoOsiguranje", ;
         Str( nT_d_zdr, 12, 2 ) )

      xml_node( "IznosZaOsiguranjeOdNezaposlenosti", ;
         Str( nT_d_nez, 12, 2 ) )

      xml_node( "UkupniDoprinosi", Str( nT_dop_u, 12, 2 ) )
      xml_node( "PlacaBezDoprinosa", Str( nT_bbd, 12, 2 ) )
      xml_node( "IznosLicnogOdbitka", Str( nT_lodb, 12, 2 ) )
      xml_node( "OsnovicaPoreza", Str( nT_poro, 12, 2 ) )
      xml_node( "IznosUplacenogPoreza", Str( nT_pori, 12, 2 ) )
      xml_node( "NetoPlaca", Str( nT_neto, 12, 2 ) )

      xml_subnode( "Ukupno", .T. )

      xml_subnode( "Dio2PodaciOPrihodimaDoprinosimaIPorezu", .T. )

      xml_subnode( "Dio3IzjavaPoslodavcaIsplatioca", .F. )
      xml_node( "JIBJMBPoslodavca", AllTrim( cPredJmb ) )
      xml_node( "DatumUnosa", xml_date( dDatUnosa ) )
      xml_node( "NazivPoslodavca", to_xml_encoding( AllTrim( cPredNaz ) ) )
      xml_subnode( "Dio3IzjavaPoslodavcaIsplatioca", .T. )

      xml_subnode( "Dokument", .F. )
      xml_node( "Operacija", cOperacija )
      xml_subnode( "Dokument", .T. )


      xml_subnode( "Obrazac1022", .T. )

   ENDDO

   // zatvori <PaketniUvoz...>
   xml_subnode( "PaketniUvozObrazaca", .T. )

   // zatvori xml fajl
   close_xml()

   SELECT ( nTArea )

   RETURN .T.



// --------------------------------------------
// filuje xml fajl sa podacima izvjestaja
// --------------------------------------------
STATIC FUNCTION _fill_xml( cTip, xml_file )

   LOCAL nTArea := Select()
   LOCAL nT_prih := 0
   LOCAL nT_pros := 0
   LOCAL nT_bruto := 0
   LOCAL nT_mbruto := 0
   LOCAL nT_trosk := 0
   LOCAL nT_bbtr := 0
   LOCAL nT_bbd := 0
   LOCAL nT_neto := 0
   LOCAL nT_poro := 0
   LOCAL nT_pori := 0
   LOCAL nT_dop_s := 0
   LOCAL nT_dop_u := 0
   LOCAL nT_d_zdr := 0
   LOCAL nT_d_pio := 0
   LOCAL nT_d_nez := 0
   LOCAL nT_klo := 0
   LOCAL nT_lodb := 0

   // otvori xml za upis
   create_xml( xml_file )
   // upisi header
   xml_head()

   xml_subnode( "rpt", .F. )

   // naziv firme
   xml_node( "p_naz", to_xml_encoding( AllTrim( cPredNaz ) ) )
   xml_node( "p_adr", to_xml_encoding( AllTrim( cPredAdr ) ) )
   xml_node( "p_jmb", AllTrim( cPredJmb ) )
   xml_node( "p_per", g_por_per() )

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      // po radniku
      cIdRadnikTekuci := field->idradn

      select_o_radn( cIdRadnikTekuci )

      SELECT r_export

      xml_subnode( "radnik", .F. )

      xml_node( "ime", to_xml_encoding( AllTrim( radn->ime ) + ;
         " (" + AllTrim( radn->imerod ) + ;
         ") " + AllTrim( radn->naz ) ) )

      xml_node( "mb", AllTrim( radn->matbr ) )

      xml_node( "adr", to_xml_encoding( AllTrim( radn->streetname ) + ;
         " " + AllTrim( radn->streetnum ) ) )

      nT_prih := 0
      nT_pros := 0
      nT_bruto := 0
      nT_mbruto := 0
      nT_trosk := 0
      nT_bbtr := 0
      nT_bbd := 0
      nT_neto := 0
      nT_poro := 0
      nT_pori := 0
      nT_dop_s := 0
      nT_dop_u := 0
      nT_d_zdr := 0
      nT_d_pio := 0
      nT_d_nez := 0
      nT_klo := 0
      nT_lodb := 0

      nCnt := 0

      DO WHILE !Eof() .AND. field->idradn == cIdRadnikTekuci

         // ukupni doprinosi
         REPLACE field->dop_uk WITH field->dop_pio + ;
            field->dop_nez + field->dop_zdr

         IF cTip $ "3#4"
            REPLACE field->osn_por WITH ;
               ( field->mbruto - field->dop_zdr )
         ELSE
            REPLACE field->osn_por WITH ;
               ( field->bruto - field->dop_uk ) - ;
               field->l_odb
         ENDIF

         // ako je neoporeziv radnik, nema poreza
         IF !radn_oporeziv( field->idradn, field->idrj ) .OR. ;
               field->osn_por < 0
            REPLACE field->osn_por WITH 0
         ENDIF

         IF field->osn_por > 0
            REPLACE field->izn_por WITH field->osn_por * 0.10
         ELSE
            REPLACE field->izn_por WITH 0
         ENDIF

         IF cTip $ "3#4"
            REPLACE field->neto WITH ;
               ( ( field->mbruto - field->dop_zdr ) - ;
               field->izn_por ) + field->trosk
         ELSE
            REPLACE field->neto WITH ;
               ( field->bruto - field->dop_uk ) - ;
               field->izn_por
         ENDIF

         IF ( cTip <> "3" .OR. cTip <> "4" ) .AND. ;
               field->tiprada $ " #I#N#"
            REPLACE field->neto WITH ;
               min_neto( field->neto, field->sati )
         ENDIF

         xml_subnode( "obracun", .F. )

         xml_node( "rbr", Str( ++nCnt ) )
         xml_node( "pl_opis", to_xml_encoding( AllTrim( field->mj_opis ) ) )
         xml_node( "mjesec", Str( field->mj_ispl ) )
         xml_node( "godina", Str( field->godina ) )
         xml_node( "isp_m", to_xml_encoding( AllTrim( field->mj_naz ) ) )
         xml_node( "isp_z", to_xml_encoding( AllTrim( field->ispl_za ) ) )
         xml_node( "isp_v", to_xml_encoding( g_v_ispl( AllTrim( field->vr_ispl ) ) ) )
         xml_node( "prihod", Str( field->prihod, 12, 2 ) )
         xml_node( "prih_o", Str( field->prihost, 12, 2 ) )
         xml_node( "bruto", Str( field->bruto, 12, 2 ) )
         xml_node( "trosk", Str( field->trosk, 12, 2 ) )
         xml_node( "bbtr", Str( field->bruto - field->trosk, 12, 2 ) )
         xml_node( "do_us", Str( field->dop_u_st, 12, 2 ) )
         xml_node( "do_uk", Str( field->dop_uk, 12, 2 ) )
         xml_node( "do_pio", Str( field->dop_pio, 12, 2 ) )
         xml_node( "do_zdr", Str( field->dop_zdr, 12, 2 ) )
         xml_node( "do_nez", Str( field->dop_nez, 12, 2 ) )
         xml_node( "bbd", Str( field->bruto - field->dop_uk, 12, 2 ) )
         xml_node( "neto", Str( field->neto, 12, 2 ) )
         xml_node( "klo", Str( field->klo, 12, 2 ) )
         xml_node( "l_odb", Str( field->l_odb, 12, 2 ) )
         xml_node( "p_osn", Str( field->osn_por, 12, 2 ) )
         xml_node( "p_izn", Str( field->izn_por, 12, 2 ) )
         xml_node( "uk", Str( field->ukupno, 12, 2 ) )
         xml_node( "d_isp", DToC( field->datispl ) )
         xml_node( "opis", to_xml_encoding( AllTrim( field->naziv ) ) )

         xml_subnode( "obracun", .T. )

         nT_prih += field->prihod
         nT_pros += field->prihost
         nT_bruto += field->bruto
         nT_trosk += field->trosk
         nT_bbtr += ( field->bruto - field->trosk )
         nT_bbd += ( field->bruto - field->dop_uk )
         nT_neto += field->neto
         nT_poro += field->osn_por
         nT_pori += field->izn_por
         nT_dop_s += field->dop_u_st
         nT_dop_u += field->dop_uk
         nT_d_zdr += field->dop_zdr
         nT_d_pio += field->dop_pio
         nT_d_nez += field->dop_nez
         nT_klo += field->klo
         nT_lodb += field->l_odb

         SKIP
      ENDDO

      // upisi totale za radnika
      xml_subnode( "total", .F. )

      xml_node( "prihod", Str( nT_prih, 12, 2 ) )
      xml_node( "prih_o", Str( nT_pros, 12, 2 ) )
      xml_node( "bruto", Str( nT_bruto, 12, 2 ) )
      xml_node( "trosk", Str( nT_trosk, 12, 2 ) )
      xml_node( "bbtr", Str( nT_bbtr, 12, 2 ) )
      xml_node( "bbd", Str( nT_bbd, 12, 2 ) )
      xml_node( "neto", Str( nT_neto, 12, 2 ) )
      xml_node( "p_izn", Str( nT_pori, 12, 2 ) )
      xml_node( "p_osn", Str( nT_poro, 12, 2 ) )
      xml_node( "do_st", Str( nT_dop_s, 12, 2 ) )
      xml_node( "do_uk", Str( nT_dop_u, 12, 2 ) )
      xml_node( "do_pio", Str( nT_d_pio, 12, 2 ) )
      xml_node( "do_zdr", Str( nT_d_zdr, 12, 2 ) )
      xml_node( "do_nez", Str( nT_d_nez, 12, 2 ) )
      xml_node( "klo", Str( nT_klo, 12, 2 ) )
      xml_node( "l_odb", Str( nT_lodb, 12, 2 ) )

      xml_subnode( "total", .T. )

      // zatvori radnika
      xml_subnode( "radnik", .T. )

   ENDDO

   // zatvori <rpt>
   xml_subnode( "rpt", .T. )

   SELECT ( nTArea )

   // zatvori xml fajl za upis
   close_xml()

   RETURN .T.


// ----------------------------------------------------------
// vraca string poreznog perioda
// ----------------------------------------------------------
STATIC FUNCTION g_por_per()

   LOCAL cRet := ""

   cRet += AllTrim( Str( s_nMjesecOd ) ) + "/" + AllTrim( Str( s_nGodinaOd ) )
   cRet += " - "
   cRet += AllTrim( Str( s_nMjesecDo ) ) + "/" + AllTrim( Str( s_nGodinaDo ) )
   cRet += " godine"

   RETURN cRet



// -------------------------------------------
// vraca string sa datumom uslovskim
// -------------------------------------------
FUNCTION ld_godina_mjesec_string( nGod, nMj )

   LOCAL cRet

   cRet := Str( nGod, 4, 0 ) + Str( nMj, 2, 0 )

   RETURN cRet


STATIC FUNCTION get_period_od_do( nMjesecOd, nGodinaOd, nMjesecDo, nGodinaDo )

   LOCAL cTmp := ""
   LOCAL dPerOd, dPerDo

   cTmp += "01" + "."
   cTmp += PadL( AllTrim( Str( nMjesecOd ) ), 2, "0" ) + "."
   cTmp += AllTrim( Str( nGodinaOd ) )
   dPerOd := CToD( cTmp )

   cTmp := g_day( nMjesecDo ) + "."
   cTmp += PadL( AllTrim( Str( nMjesecDo ) ), 2, "0" ) + "."
   cTmp += AllTrim( Str( nGodinaDo ) )
   dPerDo := CToD( cTmp )

   RETURN { dPerOd, dPerDo }

// ------------------------------------------
// vraca koliko dana ima u mjesecu
// ------------------------------------------
FUNCTION g_day( nMonth )

   LOCAL cDay := "31"

   DO CASE
   CASE nMonth = 1
      cDay := "31"
   CASE nMonth = 2
      cDay := "28"
   CASE nMonth = 3
      cDay := "31"
   CASE nMonth = 4
      cDay := "30"
   CASE nMonth = 5
      cDay := "31"
   CASE nMonth = 6
      cDay := "30"
   CASE nMonth = 7
      cDay := "31"
   CASE nMonth = 8
      cDay := "31"
   CASE nMonth = 9
      cDay := "30"
   CASE nMonth = 10
      cDay := "31"
   CASE nMonth = 11
      cDay := "30"
   CASE nMonth = 12
      cDay := "31"

   ENDCASE

   RETURN cDay



// -------------------------------------
// vraca vrstu isplate
// -------------------------------------
FUNCTION g_v_ispl( cId )

   LOCAL cIspl := "Plata"

   IF cId == "1"
      cIspl := "Plata"
   ELSEIF cId == "2"
      cIspl := "Plata + ostalo"
   ENDIF

   RETURN cIspl



STATIC FUNCTION g_operacija( nOper )

   LOCAL cOperacija := ""

   IF nOper = 1
      cOperacija := "Novi"
   ELSEIF nOper = 2
      cOperacija := "Izmjena"
   ELSEIF nOper = 3
      cOperacija := "Brisanje"
   ELSE
      cOperacija := "Novi"
   ENDIF

   RETURN cOperacija


// -----------------------------------------------
// vraca broj zahtjeva
// -----------------------------------------------
FUNCTION ld_mip_broj_obradjenih_radnika()

   LOCAL nTArea := Select()
   LOCAL cIdRadnikTekuci
   LOCAL nCnt
   LOCAL nRet := 0

   SELECT r_export
   SET ORDER TO TAG "1"
   GO TOP

   DO WHILE !Eof()

      cIdRadnikTekuci := field->idradn
      nCnt := 0

      DO WHILE !Eof() .AND. field->idradn == cIdRadnikTekuci
         nCnt := 1
         SKIP
      ENDDO

      nRet += nCnt

   ENDDO

   SELECT ( nTArea )

   RETURN nRet




// ---------------------------------------
// otvara potrebne tabele
// ---------------------------------------
FUNCTION ol_o_tbl()

   // o_ld_obracuni()
   // o_ld_parametri_obracuna()
   o_params()
   // o_ld_rj()
   // o_ld_radn()
   // o_koef_beneficiranog_radnog_staza()
   // o_ld_vrste_posla()
   // o_tippr()
   // o_kred()
   // o_dopr()
   // o_por()
   // select_o_ld()

   RETURN .T.


FUNCTION ld_obracunski_list_sort( cRadneJedinice, nGodinaOd, nGodinaDo, nMjesecOd, nMjesecDo, ;
      cIdRadnik, cVarijantaIzvjestaja, cObr )

   LOCAL cFilter := ""
   PRIVATE cObracun := cObr

   IF !Empty( cObr )
      cFilter += "obr == " + dbf_quote( cObr )
   ENDIF

   IF !Empty( cRadneJedinice )
      IF !Empty( cFilter )
         cFilter += " .and. "
      ENDIF
      cFilter += Parsiraj( cRadneJedinice, "IDRJ" )
   ENDIF

   IF !Empty( cFilter )
      SET FILTER TO &cFilter
      GO TOP
   ENDIF

   IF Empty( cIdRadnik )
      IF cVarijantaIzvjestaja $ "1#2"
         INDEX ON SortPrez( idradn ) + Str( godina, 4, 0 ) + Str( mjesec, 4, 0 ) + idrj TO "tmpld"
         GO TOP
      ELSE
         INDEX ON Str( godina, 4, 0 ) + Str( mjesec, 4, 0 ) + SortPrez( idradn ) + idrj TO "tmpld"
         GO TOP
      ENDIF
   ELSE
      SET ORDER TO TAG ( ld_index_tag_vise_obracuna( "2" ) )
      GO TOP
      SEEK Str( nGodinaOd, 4, 0 ) + Str( nMjesecOd, 2, 0 ) + cObracun + cIdRadnik
   ENDIF

   RETURN .T.


// ---------------------------------------------
// upisivanje podatka u pomocnu tabelu za rpt
// ---------------------------------------------
STATIC FUNCTION _ins_tbl( cIdRadnik, cIdRj, cTipRada, cNazIspl, dDatIsplate, ;
      nMjesec, nMjisp, cIsplZa, cVrsta, ;
      nGodina, nPrihod, ;
      nPrihOst, nBruto, nMBruto, nTrosk, nDop_u_st, nDopPio, ;
      nDopZdr, nDopNez, nDop_uk, nNeto, nKLO, ;
      nLOdb, nOsn_por, nIzn_por, nUk, nUSati, nIzn1, nIzn2, ;
      nIzn3, nIzn4, nIzn5 )

   LOCAL nTArea := Select()

   o_r_export()
   SELECT r_export
   APPEND BLANK

   REPLACE tiprada WITH cTipRada
   REPLACE idrj WITH cIdRj
   REPLACE idradn WITH cIdRadnik
   REPLACE naziv WITH cNazIspl
   REPLACE mjesec WITH nMjesec
   REPLACE mj_opis WITH ld_naziv_mjeseca( nMjIspl, nGodina, .F., .T. )
   REPLACE mj_naz WITH ld_naziv_mjeseca( nMjIspl, nGodina, .F., .F. )
   REPLACE mj_ispl WITH nMjIspl
   REPLACE ispl_za WITH cIsplZa
   REPLACE vr_ispl WITH cVrsta
   REPLACE godina WITH nGodina
   REPLACE datispl WITH dDatIsplate
   REPLACE prihod WITH nPrihod
   REPLACE prihost WITH nPrihOst
   REPLACE bruto WITH nBruto
   REPLACE mbruto WITH nMBruto
   REPLACE trosk WITH nTrosk
   REPLACE dop_u_st WITH nDop_u_st
   REPLACE dop_pio WITH nDopPio
   REPLACE dop_zdr WITH nDopZdr
   REPLACE dop_nez WITH nDopNez
   REPLACE dop_uk WITH nDop_uk
   REPLACE neto WITH nNeto
   REPLACE klo WITH nKlo
   REPLACE l_odb WITH nLOdb
   REPLACE osn_por WITH nOsn_Por
   REPLACE izn_por WITH nIzn_Por
   REPLACE ukupno WITH nUk
   REPLACE sati WITH nUSati

   IF nIzn1 <> nil
      REPLACE tp_1 WITH nIzn1
   ENDIF
   IF nIzn2 <> nil
      REPLACE tp_2 WITH nIzn2
   ENDIF
   IF nIzn3 <> nil
      REPLACE tp_3 WITH nIzn3
   ENDIF
   IF nIzn4 <> nil
      REPLACE tp_4 WITH nIzn4
   ENDIF
   IF nIzn5 <> nil
      REPLACE tp_5 WITH nIzn5
   ENDIF


   SELECT ( nTArea )

   RETURN



// ---------------------------------------------
// kreiranje pomocne tabele
// ---------------------------------------------
FUNCTION ol_tmp_tbl()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IDRADN", "C", 6, 0 } )
   AAdd( aDbf, { "IDRJ", "C", 2, 0 } )
   AAdd( aDbf, { "TIPRADA", "C", 1, 0 } )
   AAdd( aDbf, { "NAZIV", "C", 15, 0 } )
   AAdd( aDbf, { "DATISPL", "D", 8, 0 } )
   AAdd( aDbf, { "MJESEC", "N", 2, 0 } )
   AAdd( aDbf, { "MJ_NAZ", "C", 15, 0 } )
   AAdd( aDbf, { "MJ_OPIS", "C", 15, 0 } )
   AAdd( aDbf, { "MJ_ISPL", "N", 2, 0 } )
   AAdd( aDbf, { "ISPL_ZA", "C", 50, 0 } )
   AAdd( aDbf, { "VR_ISPL", "C", 50, 0 } )
   AAdd( aDbf, { "GODINA", "N", 4, 0 } )
   AAdd( aDbf, { "PRIHOD", "N", 12, 2 } )
   AAdd( aDbf, { "PRIHOST", "N", 12, 2 } )
   AAdd( aDbf, { "BRUTO", "N", 12, 2 } )
   AAdd( aDbf, { "MBRUTO", "N", 12, 2 } )
   AAdd( aDbf, { "TROSK", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_U_ST", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_PIO", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_ZDR", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_NEZ", "N", 12, 2 } )
   AAdd( aDbf, { "DOP_UK", "N", 12, 4 } )
   AAdd( aDbf, { "NETO", "N", 12, 2 } )
   AAdd( aDbf, { "KLO", "N", 5, 2 } )
   AAdd( aDbf, { "L_ODB", "N", 12, 2 } )
   AAdd( aDbf, { "OSN_POR", "N", 12, 2 } )
   AAdd( aDbf, { "IZN_POR", "N", 12, 2 } )
   AAdd( aDbf, { "UKUPNO", "N", 12, 2 } )
   AAdd( aDbf, { "SATI", "N", 12, 2 } )
   AAdd( aDbf, { "TP_1", "N", 12, 2 } )
   AAdd( aDbf, { "TP_2", "N", 12, 2 } )
   AAdd( aDbf, { "TP_3", "N", 12, 2 } )
   AAdd( aDbf, { "TP_4", "N", 12, 2 } )
   AAdd( aDbf, { "TP_5", "N", 12, 2 } )

   create_dbf_r_export( aDbf )

   o_r_export()
   INDEX ON idradn + Str( godina, 4 ) + Str( mjesec, 2 ) TAG "1"

   RETURN
