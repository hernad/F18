/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR gZaokr

STATIC s_cLinija
STATIC s_cTxt1
STATIC s_cTxt2
STATIC s_cTxt3


FUNCTION kalk_lager_lista_magacin()

   PARAMETERS fPocStanje

   LOCAL fimagresaka := .F.
   LOCAL cUser := "<>"
   LOCAL cExpXlsx := "N"
   LOCAL lExpXlsx := .F.
   LOCAL cPodaciOFakturiPartneraDN := "N"
   LOCAL cVpcIzSifarnikaDN := "D"
   LOCAL cTxtOdt := "1"
   LOCAL GetList := {}

   LOCAL nTUlazP  // ulaz, izlaz parovno
   LOCAL nTIzlazP
   LOCAL nKolicina
   LOCAL cPicDem
   LOCAL cPicCDem
   LOCAL cPicKol
   LOCAL cLine
   LOCAL cTxt1
   LOCAL cTxt2
   LOCAL cTxt3
   LOCAL cMIPart := ""
   LOCAL cMINumber := ""
   //LOCAL dMIDate := CToD( "" )
   LOCAL cMI_type := ""
   LOCAL cSrKolNula := "0"
   LOCAL dDatZadnjiUlaz := CToD( "" )
   LOCAL dL_izlaz := CToD( "" )
   LOCAL hParams
   LOCAL nVPC, nNC
   LOCAL cIdKonto
   LOCAL aHeader
   LOCAL cXlsxName, aXlsxFields
   LOCAL lVPC

   // pPicDem := kalk_prosiri_pic_iznos_za_2()
   // pPicCDem := kalk_prosiri_pic_cjena_za_2()
   // pPicKol := kalk_prosiri_pic_kolicina_za_2()

   cIdFirma := self_organizacija_id()
   cPrikazDob := "N"
   cIdKonto := PadR( "1320", FIELD_LENGTH_IDKONTO )

   PRIVATE nVPVU := 0
   PRIVATE nVPVI := 0

   PRIVATE nVPVRU := 0
   PRIVATE nVPVRI := 0

   PRIVATE nNVU := 0
   PRIVATE nNVI := 0

   // signalne zalihe
   PRIVATE lSignZal := .F.
   PRIVATE qqRGr := Space( 40 )
   PRIVATE qqRGr2 := Space( 40 )

/*
   // IF IsVindija()
   cOpcine := Space( 50 )
   // ENDIF
*/

   kalk_llm_open_tables()

   IF fPocStanje == NIL
      fPocStanje := .F.
   ELSE
      fPocStanje := .T.
      o_kalk_pripr()
      cBrDokPocStanje := "00001   "
      Box(, 3, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Generacija poč.stanja  - broj dokumenta 16 -" GET cBrDokPocStanje
      READ
      ESC_BCR
      BoxC()
   ENDIF

   PRIVATE dDatOd := Date()
   PRIVATE dDatDo := Date()

   qqRoba := Space( 60 )
   qqTarifa := Space( 60 )
   qqidvd := Space( 60 )
   qqIdPartner := Space( 60 )

   PRIVATE cPNab := "N"
   PRIVATE p_cPrikazSamoNabavne := "N"
   PRIVATE cNulaDN := "N"
   PRIVATE cErr := "N"
   PRIVATE cNCSif := "N"
   PRIVATE cMink := "N"
   PRIVATE cSredCij := "N"
   PRIVATE cFaBrDok := Space( 40 )

   IF !Empty( cRNT1 )
      PRIVATE cRNalBroj := PadR( "", 40 )
   ENDIF

   IF !fPocStanje
      cIdKonto := fetch_metric( "kalk_lager_lista_id_konto", cUser, cIdKonto )
      cPNab := fetch_metric( "kalk_lager_lista_po_nabavnoj", cUser, cPNab )
      cNulaDN := fetch_metric( "kalk_lager_lista_prikaz_nula", cUser, cNulaDN )
      dDatOd := fetch_metric( "kalk_lager_lista_datum_od", cUser, dDatOd )
      dDatDo := fetch_metric( "kalk_lager_lista_datum_do", cUser, dDatDo )
      p_cPrikazSamoNabavne := fetch_metric( "kalk_lager_Lista_prikaz_do_nabavne", cUser, p_cPrikazSamoNabavne )
      cVpcIzSifarnikaDN := fetch_metric( "kalk_lager_Lista_vpc_iz_sif", cUser, cVpcIzSifarnikaDN )
      cTxtOdt := fetch_metric( "kalk_lager_print_varijanta", cUser, cTxtOdt )
      cExpXlsx := fetch_metric( "kalk_lager_mag_export", cUser, "N")
   ENDIF

   cArtikalNaz := Space( 30 )

   Box(, 21, 80 )

   DO WHILE .T.

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto   " GET cIdKonto VALID "." $ cidkonto .OR. P_Konto( @cIdKonto )
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Artikli " GET qqRoba PICT "@!S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Tarife  " GET qqTarifa PICT "@!S50"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Vrste dokumenata " GET qqIDVD PICT "@!S30"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Partneri " GET qqIdPartner PICT "@!S20"
      @ box_x_koord() + 6, Col() + 1 SAY "Br.fakture " GET cFaBrDok  PICT "@!S15"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz Nab.vrijednosti D/N" GET cPNab  VALID cpnab $ "DN" PICT "@!"

      @ box_x_koord() + 7, Col() + 1 SAY "Prikaz samo do nab.vr. D/N" GET p_cPrikazSamoNabavne  VALID p_cPrikazSamoNabavne $ "DN" PICT "@!"

      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "Pr.stavki kojima je NV 0 D/N" GET cNulaDN  VALID cNulaDN $ "DN" PICT "@!"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY8 "Prikaz 'ERR' ako je NV/Kolicina<>NC " GET cErr PICT "@!" VALID cErr $ "DN"
      @ box_x_koord() + 9, Col() + 1 SAY8 "VPC iz šifarnika robe (D/N)?" GET cVpcIzSifarnikaDN PICT "@!" VALID cVpcIzSifarnikaDN $ "DN"

      @ box_x_koord() + 10, box_y_koord() + 2 SAY8 "Datum od " GET dDatOd
      @ box_x_koord() + 10, Col() + 2 SAY8 "do" GET dDatDo

      @ box_x_koord() + 11, box_y_koord() + 2 SAY8 "Vrsta štampe TXT/ODT (1/2)" GET cTxtOdt VALID cTxtOdt $ "12" PICT "@!"

      @ box_x_koord() + 12, box_y_koord() + 2 SAY8 "Postaviti srednju NC u šifarnik?" GET cNCSif PICT "@!" VALID ( ( cpnab == "D" .AND. cncsif == "D" ) .OR. cNCSif == "N" )

      IF fPocStanje
         @ box_x_koord() + 13, box_y_koord() + 2 SAY8 "Sredi samo stavke kol=0, nv<>0 (0/1/2)"  GET cSrKolNula VALID cSrKolNula $ "012" PICT "@!"
      ENDIF

      @ box_x_koord() + 14, box_y_koord() + 2 SAY8 "Prikaz samo kritičnih zaliha (D/N/O) ?" GET cMinK PICT "@!" VALID cMink $ "DNO"

/*
      // IF IsVindija()
      cGr := Space( 10 )
      cPSPDN := "N"
      @ box_x_koord() + 15, box_y_koord() + 2 SAY8 "Grupa:" GET cGr
      @ box_x_koord() + 16, box_y_koord() + 2 SAY8 "Pregled samo prodaje (D/N)" GET cPSPDN VALID cPSPDN $ "DN" PICT "@!"
      @ box_x_koord() + 17, box_y_koord() + 2 SAY8 "Uslov po opcinama:" GET cOpcine PICT "@!S40"
      // ENDIF
*/

      // ako je roba - grupacija
      @ box_x_koord() + 17, box_y_koord() + 2 SAY "Grupa artikla:" GET qqRGr PICT "@S10"
      @ box_x_koord() + 17, box_y_koord() + 30 SAY "Podgrupa artikla:" GET qqRGr2 PICT "@S10"

      @ box_x_koord() + 18, box_y_koord() + 2 SAY8 "Naziv artikla sadrži"  GET cArtikalNaz

      IF !Empty( cRNT1 )
         @ box_x_koord() + 19, box_y_koord() + 2 SAY "Broj radnog naloga:"  GET cRNalBroj PICT "@S20"
      ENDIF

      @ box_x_koord() + 20, box_y_koord() + 2 SAY8 "Export izvještaja u XLSX (D-da/F-flat/N-e)?" GET cExpXlsx VALID cExpXlsx $ "DNF" PICT "@!"
      @ box_x_koord() + 21, box_y_koord() + 2 SAY "Podaci o fakturi partenra ?" GET cPodaciOFakturiPartneraDN VALID cPodaciOFakturiPartneraDN $ "DN" PICT "@!"

      READ
      ESC_BCR

      
      lVPC := is_magacin_evidencija_vpc( cIdKonto )


      PRIVATE aUsl1 := Parsiraj( qqRoba, "IdRoba" )
      PRIVATE aUsl2 := Parsiraj( qqTarifa, "IdTarifa" )
      PRIVATE aUsl3 := Parsiraj( qqIDVD, "idvd" )
      PRIVATE aUsl4 := Parsiraj( qqIDPartner, "idpartner" )
      PRIVATE aUsl5 := Parsiraj( cFaBrDok, "brfaktp" )

      qqRGr := AllTrim( qqRGr )
      qqRGr2 := AllTrim( qqRGr2 )

      //IF !Empty( cRnT1 ) .AND. !Empty( cRNalBroj )
      //   PRIVATE aUslRn := Parsiraj( cRNalBroj, "idzaduz2" )
      //ENDIF

      IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. aUsl3 <> NIL .AND. aUsl4 <> NIL .AND. ( Empty( cRnT1 ) .OR. Empty( cRNalBroj ) /*.OR. aUslRn <> NIL*/ ) .AND. aUsl5 <> nil
         EXIT
      ENDIF
   ENDDO
   BoxC()

   IF !fPocStanje
      set_metric( "kalk_lager_lista_id_konto", f18_user(), cIdKonto )
      set_metric( "kalk_lager_lista_po_nabavnoj", f18_user(), cPNab )
      set_metric( "kalk_lager_lista_prikaz_nula", f18_user(), cNulaDN )
      set_metric( "kalk_lager_lista_datum_od", f18_user(), dDatOd )
      set_metric( "kalk_lager_lista_datum_do", f18_user(), dDatDo )
      set_metric( "kalk_lager_lista_prikaz_do_nabavne", f18_user(), p_cPrikazSamoNabavne )
      set_metric( "kalk_lager_Lista_vpc_iz_sif", cUser, cVpcIzSifarnikaDN )
      set_metric( "kalk_lager_print_varijanta", cUser, cTxtOdt )
      set_metric( "kalk_lager_mag_export", cUser, cExpXlsx)
   ENDIF

   lSvodi := .F.

   // IF my_get_from_ini( "KALK_LLM", "SvodiNaJMJ", "N", KUMPATH ) == "D"
   // lSvodi := ( Pitanje(, "Svesti količine na osnovne jedinice mjere? (D/N)", "N" ) == "D" )
   // ENDIF

   // sinteticki konto
   fSint := .F.
   cSintK := cIdKonto


   IF "." $ cIdKonto
      cIdkonto := StrTran( cIdKonto, ".", "" )
      cIdkonto := Trim( cIdKonto )
      cSintK := cIdKonto
      fSint := .T.
      lSaberiStanjeZaSvaKonta := ( Pitanje(, "Računati stanje robe kao zbir stanja na svim obuhvacenim kontima? (D/N)", "N" ) == "D" )
   ENDIF

   IF cExpXlsx $ "DF"
      lExpXlsx := .T.
      aXlsxFields := kalk_llm_xls_fields()
      aHeader := {}
      IF cExpXlsx == "D"
        AADD( aHeader, { "Period", DTOC(dDatOd) + " -" + DTOC(dDatDo) } )
        AADD( aHeader, { "Magacin:", cIdKonto } )
        cXlsxName := "kalk_llm_" + Alltrim(cIdKonto) + ".xlsx"
      ELSE
         cXlsxName := "kalk_llm.xlsx" 
      ENDIF

      xlsx_export_init( aXlsxFields, aHeader, cXlsxName )
   ENDIF

   kalk_llm_open_tables()

   PRIVATE cFilt := ".t."

   IF aUsl1 <> ".t."
      cFilt += ".and." + aUsl1
   ENDIF

   IF aUsl2 <> ".t."
      cFilt += ".and." + aUsl2
   ENDIF
   IF aUsl3 <> ".t."
      cFilt += ".and." + aUsl3
   ENDIF
   IF aUsl4 <> ".t."
      cFilt += ".and." + aUsl4
   ENDIF
   IF !Empty( cFaBrDok ) .AND. aUsl5 <> ".t."
      cFilt += ".and." + aUsl5
   ENDIF

   IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
      cFilt += ".and. DatDok>=" + dbf_quote( dDatOd ) + ".and. DatDok<=" + dbf_quote( dDatDo )
   ENDIF
   IF fSint .AND. lSaberiStanjeZaSvaKonta
      cFilt += ".and. MKonto=" + dbf_quote( cSintK )
      cSintK := ""
   ENDIF

   //IF !Empty( cRNT1 ) .AND. !Empty( cRNalBroj )
  //    cFilt += ".and." + aUslRn
   //ENDIF

   MsgO( "Preuzimanje podataka sa SQL servera ..." )
   IF fSint .AND. lSaberiStanjeZaSvaKonta
      // HSEEK cIdFirma
      find_kalk_by_mkonto_idroba( cIdFirma, NIL, NIL, "idFirma,IdTarifa,idroba" )
      // kalk index tag ( "6", "idFirma+IdTarifa+idroba" )
      // SET ORDER TO TAG "6"
      GO TOP
   ELSE
      // SET ORDER TO TAG "3"
      // HSEEK cIdFirma + cIdKonto
      find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto )
   ENDIF
   MsgC()

   IF cFilt == ".t."
      SET FILTER TO
   ELSE
      SET FILTER TO &cFilt
   ENDIF
   GO TOP

   select_o_koncij( cIdKonto )

   SELECT kalk
   // ?E "trace-kalk-llm-11"

   IF cTxtOdt == "2"
      // stampa dokumenta u odt formatu
      hParams := hb_Hash()
      hParams[ "idfirma" ] := self_organizacija_id()
      hParams[ "idkonto" ] := cIdKonto
      hParams[ "roba_naz" ] := cArtikalNaz
      hParams[ "group_1" ] := qqRGr
      hParams[ "group_2" ] := qqRGr2
      hParams[ "nule" ] := ( cNulaDN == "D" )
      hParams[ "svodi_jmj" ] := lSvodi
      hParams[ "vpc_sif" ] := ( cVpcIzSifarnikaDN == "D" )
      hParams[ "datum_od" ] := dDatOd
      hParams[ "datum_do" ] := dDatDo
      kalk_magacin_llm_odt( hParams )
      RETURN .F.
   ENDIF

   EOF CRET

   nLen := 1

   kalk_llm_zaglavlje( @cLine, @cTxt1, @cTxt2, @cTxt3, cSredCij )

   s_cLinija := cLine
   s_cTxt1 := cTxt1
   s_cTxt2 := cTxt2
   s_cTxt3 := cTxt3

   IF koncij->naz $ "P1#P2"
      cPNab := "D"
   ENDIF

   gaZagFix := { 7, 5 }

   IF !start_print()
      RETURN .F.
   ENDIF
   ?

   PRIVATE nTStrana := 0
   PRIVATE bZagl := {|| kalk_zagl_lager_lista_magacin( cIdKonto ) }

   Eval( bZagl )

   nTUlaz := 0
   nTIzlaz := 0
   nTUlazP := 0
   nTIzlazP := 0
   nTVPVU := 0
   nTVPVI := 0
   nTVPVRU := 0
   nTVPVRI := 0
   nTNVU := 0
   nTNVI := 0
   nRazlika := 0
   nTNV := 0
   nNBUk := 0
   nNBCij := 0
   nTRabat := 0
   nCol1 := 50
   nCol0 := 50

   PRIVATE nRbr := 0

   // cMKonto
   DO WHILE !Eof() .AND. iif( fSint .AND. lSaberiStanjeZaSvaKonta, idfirma, idfirma + mkonto ) == cIdfirma + cSintK .AND. ispitaj_prekid()

      cIdRoba := field->Idroba

      nUlaz := 0
      nIzlaz := 0
      nVPVU := 0
      nVPVI := 0
      nVPVRU := 0
      nVPVRI := 0
      nNVU := 0
      nNVI := 0

      nRabat := 0

      cMIFakt := ""
      cMINumber := ""
      //dMIDate := CToD( "" )

      dDatZadnjiUlaz := CToD( "" )
      dL_izlaz := CToD( "" )

      select_o_roba(  cIdRoba )

      // pretrazi artikle po nazivu
      IF ( !Empty( cArtikalNaz ) .AND. At( AllTrim( cArtikalNaz ), AllTrim( roba->naz ) ) == 0 )
         SELECT kalk
         SKIP
         LOOP
      ENDIF

      IF !Empty( qqRGr ) .OR. !Empty( qqRGr2 ) // uslov za roba - grupacija
         IF !IsInGroup( qqRGr, qqRGr2, roba->id )
            SELECT kalk
            SKIP
            LOOP
         ENDIF
      ENDIF

      IF ( FieldPos( "MINK" ) ) <> 0
         nMink := roba->mink
      ELSE
         nMink := 0
      ENDIF

      SELECT kalk
      IF roba->tip $ "TUY"
         SKIP
         LOOP
      ENDIF

      cIdkonto := kalk->mkonto

      // cIdroba
      DO WHILE !Eof() .AND. iif( fSint .AND. lSaberiStanjeZaSvaKonta, cIdFirma + cIdRoba == idFirma + field->idroba, cIdFirma + cIdKonto + cIdRoba == idFirma + mkonto + field->idroba ) .AND. ispitaj_prekid()

         IF roba->tip $ "TU"
            SKIP
            LOOP
         ENDIF

         nVPC := vpc_magacin()

         IF kalk->mu_i == "1"

            IF !( kalk->idvd $ "12#22#94" )

               nKolicina := field->kolicina - field->gkolicina - field->gkolicin2
               nUlaz += nKolicina
               kalk_sumiraj_kolicinu( nKolicina, 0, @nTUlazP, @nTIzlazP )
               nCol1 := PCol() + 1
               //IF koncij->naz == "P2"
               //   nVPVU += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               //   nVPVRU += Round( roba->plc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
               //ELSE
               nVPVU += Round( nVPC * kolicina, gZaokr )
               nVPVRU += Round( nVPC * kolicina, gZaokr )
               //ENDIF

               nNVU += Round( nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            ELSE
               nKolicina := -field->kolicina
               nIzlaz += nKolicina
               kalk_sumiraj_kolicinu( 0, nKolicina, @nTUlazP, @nTIzlazP )
               //IF koncij->naz == "P2"
               //   nVPVI -= Round( roba->plc * kolicina, gZaokr )
               //   nVPVRI -= Round( roba->plc * kolicina, gZaokr )
               //ELSE
                  nVPVI -= Round( nVPC * kolicina, gZaokr )
                  nVPVRI -= Round( nVPC * kolicina, gZaokr )
               //ENDIF
               nNVI -= Round( nc * kolicina, gZaokr )
            ENDIF

            dDatZadnjiUlaz := field->datdok

         ELSEIF mu_i == "5"
            nKolicina := field->kolicina
            nIzlaz += nKolicina
            kalk_sumiraj_kolicinu( 0, nKolicina, @nTUlazP, @nTIzlazP )
            
            nVPVI += Round( nVPC * kolicina, gZaokr )
            nVPVRI += Round( nVPC * kolicina, gZaokr )
            
            nRabat += Round(  rabatv / 100 * vpc * kolicina, gZaokr )
            nNVI += Round( nc * kolicina, gZaokr )

            // datum zadnjeg izlaza
            dL_izlaz := field->datdok

         ELSEIF lVPC .and. field->mu_i == "3"  // nivelacija 18-ka
         
            nVPVU += Round( nVPC * kolicina, gZaokr )
            nVPVRU += Round( nVPC * kolicina, gZaokr )
            
   
         ELSEIF kalk->mu_i == "8"
            nKolicina := -field->kolicina
            nIzlaz += nKolicina
            kalk_sumiraj_kolicinu( 0, nKolicina, @nTUlazP, @nTIzlazP )
          
            nVPVI += Round( nVPC * ( - kolicina ), gZaokr )
            nVPVRI += Round( nVPC * ( - kolicina ), gZaokr )
            
            nRabat += Round(  rabatv / 100 * vpc * ( - kolicina ), gZaokr )
            nNVI += Round( nc * ( - kolicina ), gZaokr )
            nKolicina := -field->kolicina
            nUlaz += nKolicina
            kalk_sumiraj_kolicinu( nKolicina, 0, @nTUlazP, @nTIzlazP )

            nVPVU += Round( - nVPC * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            nVPVRU += Round( - nVPC * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
            
            nNVU += Round( - nc * ( kolicina - gkolicina - gkolicin2 ), gZaokr )
         ENDIF

         cMIPart := field->idpartner
         //dMIDate := field->datfaktp
         cMINumber := field->brfaktp
         cMI_type := field->mu_i

         SKIP
      ENDDO


      IF cMinK == "D" .AND. ( nUlaz - nIzlaz - nMink ) > 0
         LOOP
      ENDIF

      IF cNulaDN == "D" .OR. Round( nNVU - nNVI, 4 ) <> 0

         aNaz := Sjecistr( roba->naz, 20 )
         NovaStrana( bZagl )

         ? Str( ++nRbr, 6 ) + ".", cIdRoba
         nCr := PCol() + 1

         @ PRow(), PCol() + 1 SAY aNaz[ 1 ]

         cJMJ := ROBA->JMJ
         nVPCIzSif := ROBA->VPC

         IF lSvodi
            nKJMJ  := svedi_na_jedinicu_mjere( 1, cIdRoba, @cJMJ )
            cJMJ := PadR( cJMJ, Len( ROBA->JMJ ) )
         ELSE
            nKJMJ  := 1
         ENDIF

         @ PRow(), PCol() + 1 SAY cJMJ

         nCol0 := PCol() + 1

         // ulaz, izlaz, stanje
         @ PRow(), PCol() + 1 SAY say_kolicina( nKJMJ * nUlaz          )
         @ PRow(), PCol() + 1 SAY say_kolicina( nKJMJ * nIzlaz         )
         @ PRow(), PCol() + 1 SAY say_kolicina( nKJMJ * ( nUlaz - nIzlaz ) )

         IF fPocStanje

            SELECT kalk_pripr
            IF Round( nUlaz - nIzlaz, 4 ) <> 0 .AND. cSrKolNula $ "01"

               APPEND BLANK
               REPLACE idfirma WITH cIdfirma, ;
                  idroba WITH cIdRoba, ;
                  idkonto WITH cIdKonto, ;
                  datdok WITH dDatDo + 1, ;
                  idtarifa WITH roba->idtarifa, ;
                  kolicina WITH nUlaz - nIzlaz, ;
                  idvd WITH "16", ;
                  brdok WITH cBrDokPocStanje

                  //datfaktp WITH dDatDo + 1, ;

               REPLACE nc WITH ( nNVU - nNVI ) / ( nUlaz - nIzlaz )
               REPLACE vpc WITH ( nVPVU - nVPVI ) / ( nUlaz - nIzlaz )
               REPLACE vpc WITH nc

            ELSEIF cSrKolNula $ "12" .AND. Round( nUlaz - nIzlaz, 4 ) = 0

               // kontrolna opcija
               // kolicina 0, nabavna cijena <> 0
               IF ( nNVU - nNVI ) <> 0

                  // 1 stavka (minus)
                  APPEND BLANK
                  REPLACE idfirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idtarifa WITH roba->idtarifa
                  //REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH -1
                  REPLACE idvd WITH "16"
                  REPLACE brdok WITH cBrDokPocStanje
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH 0
                  REPLACE vpc WITH 0

                  REPLACE vpc WITH nc

                  // 2 stavka (plus i nv)
                  APPEND BLANK
                  REPLACE idfirma WITH cIdfirma
                  REPLACE idroba WITH cIdRoba
                  REPLACE idkonto WITH cIdKonto
                  REPLACE datdok WITH dDatDo + 1
                  REPLACE idtarifa WITH roba->idtarifa
                  //REPLACE datfaktp WITH dDatDo + 1
                  REPLACE kolicina WITH 1
                  REPLACE idvd WITH "16"
                  REPLACE brdok WITH cBrDokPocStanje
                  REPLACE brfaktp WITH "#KOREK"
                  REPLACE nc WITH ( nNVU - nNVI )
                  REPLACE vpc WITH nc


               ENDIF

            ENDIF

            SELECT kalk

         ENDIF

         nCol1 := PCol() + 1


         // NV
         @ PRow(), PCol() + 1 SAY kalk_say_iznos( nNVU )
         @ PRow(), PCol() + 1 SAY kalk_say_iznos( nNVI  )
         @ PRow(), PCol() + 1 SAY kalk_say_iznos( nNVU - nNVI )

         IF p_cPrikazSamoNabavne == "N"

            IF cVpcIzSifarnikaDN == "D"
               // sa vpc iz sifrarnika robe
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVU )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nRabat )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVI )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVU - nVPVI )
            ELSE
               // sa vpc iz tabele kalk
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVRU )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nRabat )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVRI )
               @ PRow(), PCol() + 1 SAY kalk_say_iznos( nVPVRU - nVPVRI )
            ENDIF

         ENDIF

         // provjeri greske sa NC
         IF !( koncij->naz = "P" )
            IF Round( nUlaz - nIzlaz, 4 ) <> 0
               IF cErr == "D" .AND. Round( ( nNVU - nNVI ) / ( nUlaz - nIzlaz ), 4 ) <> Round( roba->nc, 4 )
                  ?? " ERR"
                  fImaGreska := .T.
               ENDIF
            ELSE
               IF ( cErr == "D" .OR. fPocstanje ) .AND. ;
                     Round( ( nNVU - nNVI ), 4 ) <> 0
                  fImaGresaka := .T.
                  ?? " ERR"
               ENDIF
            ENDIF
         ENDIF

         IF cSredCij == "D"
            @ PRow(), PCol() + 1 SAY ( nNVU - nNVI + nVPVU - nVPVI ) / ( nUlaz - nIzlaz ) / 2 PICT "9999999.99"
         ENDIF

         // novi red
         @ PRow() + 1, 0 SAY ""
         IF Len( aNaz ) > 1
            @ PRow(), nCR  SAY aNaz[ 2 ]
         ENDIF


         IF cMink <> "N" .AND. nMink > 0
            @ PRow(), ncol0    SAY PadR( "min.kolic:", Len( kalk_prosiri_pic_kolicina_za_2() ) )
            @ PRow(), PCol() + 1 SAY say_kolicina( nKJMJ * nMink  )
         ENDIF

         // ulaz - prazno
         @ PRow(), nCol0 SAY Space( Len( kalk_prosiri_pic_kolicina_za_2() ) )
         // izlaz - prazno
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_kolicina_za_2() ) )
         // stanje - prazno
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_kolicina_za_2() ) )
         // nv.dug - prazno
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_iznos_za_2() ) )
         // nv.pot - prazno
         @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_iznos_za_2() ) )
         // prikazi NC
         IF Round( nUlaz - nIzlaz, 4 ) <> 0

            @ PRow(), PCol() + 1 SAY kalk_say_iznos( ( nNVU - nNVI ) / ( nUlaz - nIzlaz ) )

         ENDIF
         IF p_cPrikazSamoNabavne == "N"
            // pv.dug - prazno
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_iznos_za_2() ) )
            // rabat - prazno
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_iznos_za_2() ) )
            // pv.pot - prazno
            @ PRow(), PCol() + 1 SAY Space( Len( kalk_prosiri_pic_iznos_za_2() ) )
            // prikazi PC
            IF Round( nUlaz - nIzlaz, 4 ) <> 0
               @ PRow(), PCol() + 1 SAY say_cijena( nVPCIzSif )
            ENDIF
         ENDIF


         IF cMink == "O" .AND. nMink <> 0 .AND. ( nUlaz - nIzlaz - nMink ) < 0
            B_OFF
         ENDIF


         nTULaz += nKJMJ * nUlaz
         nTIzlaz += nKJMJ * nIzlaz
         nTVPVU += nVPVU
         nTVPVI += nVPVI
         nTVPVRU += nVPVRU
         nTVPVRI += nVPVRI
         nTNVU += nNVU
         nTNVI += nNVI
         nTNV += ( nNVU - nNVI )
         nTRabat += nRabat

         // prikaz dodatnih informacija na lager listi
         IF cPodaciOFakturiPartneraDN == "D"
            ? Space( 6 ) + podaci_o_fakturi_partnera( cMIPart, CTOD(""), cMINumber, cMI_type )
         ENDIF

      ENDIF

      IF roba_barkod_pri_unosu()
         ? Space( 6 ) + roba->barkod
      ENDIF

      IF lSignZal
         ?? Space( 6 ) + "p.kol: " + Str( IzSifKRoba( "PKOL", roba->id, .F. ) )
         ?? ", p.cij: " + Str( IzSifKRoba( "PCIJ", roba->id, .F. ) )
      ENDIF


      IF lExpXlsx

            cTmp := ""
            cTmp := roba->sifradob
            
            nNc := NIL
            IF Round( nUlaz - nIzlaz, 4 ) != 0.0 
               nNc := ( nNVU - nNVI ) / ( nUlaz - nIzlaz )   
            ELSE
               IF cNulaDN == "D" .OR. Round( nNVU - nNVI, 4 ) <> 0
                  // prikazati nule ili postoji neka nabavna vrijednost a kolicina 0
                  nNc := 0
               ENDIF
            ENDIF

            IF nNc != NIL
              kalk_llm_xlsx_export_fill_row( 0, roba->id, cTmp, roba->naz, roba->idtarifa, cJmj, ;
                  nUlaz, nIzlaz, ( nUlaz - nIzlaz ), nNVU, nNVI, ( nNVU - nNVI ), nNC, ;
                  nVPVU, nVPVI, ( nVPVU - nVPVI ), nVPCIzSif, nVPVRU, nVPVRI, dDatZadnjiUlaz, dL_izlaz )
            ENDIF

      ENDIF

   ENDDO

   ? s_cLinija
   ? "UKUPNO:"

   @ PRow(), nCol0 SAY say_kolicina( ntUlaz )
   @ PRow(), PCol() + 1 SAY say_kolicina( ntIzlaz )
   @ PRow(), PCol() + 1 SAY say_kolicina( ntUlaz - ntIzlaz )

   nCol1 := PCol() + 1

   // NV
   @ PRow(), PCol() + 1 SAY say_kolicina( ntNVU )
   @ PRow(), PCol() + 1 SAY say_kolicina( ntNVI )
   @ PRow(), PCol() + 1 SAY say_kolicina( ntNV )

   IF p_cPrikazSamoNabavne == "N"
      IF cVpcIzSifarnikaDN == "D"
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVU )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntRabat )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVI )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVU - NtVPVI )
      ELSE
         // PV - samo u pdv rezimu
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVRU )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntRabat )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVRI )
         @ PRow(), PCol() + 1 SAY say_kolicina( ntVPVRU - NtVPVRI )
      ENDIF
   ENDIF

   ? s_cLinija

   FF
   end_print()

   kalk_llm_open_tables()
   o_kalk_pripr()

   IF fimagresaka
      MsgBeep( "Pogledajte artikle za koje je u izvjestaju stavljena oznaka ERR - GRESKA" )
   ENDIF

   IF fPocStanje
      IF fimagresaka .AND. Pitanje(, "Nulirati pripremu (radi ponavljanja procedure) ?", "D" ) == "D"
         SELECT kalk_pripr
         my_dbf_zap()
      ELSE
         renumeracija_kalk_pripr( cBrDokPocStanje, "16" )
      ENDIF
   ENDIF

   IF lExpXlsx
      open_exported_xlsx()
   ENDIF

   my_close_all_dbf()

   RETURN .T.



STATIC FUNCTION podaci_o_fakturi_partnera( cPartner, dDatum, cFaktura, cMU_I )

      LOCAL cRet := ""
      LOCAL cMIPart := ""
      LOCAL cTip := ""

      IF !Empty( cPartner )

         cMIPart := AllTrim( get_partner_naziv( cPartner ) )
         IF cMU_I == "1"
            cTip := "dob.:"
         ELSE
            cTip := "kup.:"
         ENDIF
         cRet := DToC( dDatum )
         cRet += ", "
         cRet += "br.dok: "
         cRet += AllTrim( cFaktura )
         cRet += ", "
         cRet += cTip
         cRet += " "
         cRet += cPartner
         cRet += " ("
         cRet += cMIPart
         cRet += ")"

      ENDIF

      RETURN cRet

STATIC FUNCTION kalk_llm_xls_fields()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IDROBA", "C", 10, 0, "Roba_ID", 10 } )
   AAdd( aDbf, { "SIFRADOB", "C", 10, 0, "Sifra_Dob", 10 } )
   AAdd( aDbf, { "NAZIV", "C", 40, 0,  "Naziv", 30 } )
   AAdd( aDbf, { "TARIFA", "C", 6, 0, "Tarifa", 8 } )
   AAdd( aDbf, { "JMJ", "C", 3, 0, "jmj", 5 } )
   AAdd( aDbf, { "ULAZ", "M", 15, 4, "kol_ulaz", 15 } )
   AAdd( aDbf, { "IZLAZ", "M", 15, 4, "kol_izl", 15 } )
   AAdd( aDbf, { "STANJE", "M", 15, 4, "kol_stanje", 15 } )
   AAdd( aDbf, { "NVDUG", "M", 20, 3, "NV_dug", 17 } )
   AAdd( aDbf, { "NVPOT", "M", 20, 3, "NV_pot", 17 } )
   AAdd( aDbf, { "NV", "M", 15, 4, "NV", 17 } )
   AAdd( aDbf, { "NC", "M", 15, 4, "NC", 15 } )

   AAdd( aDbf, { "PVDUG", "M", 20, 3, "VPV_dug", 14 } )
   AAdd( aDbf, { "PVPOT", "M", 20, 3, "VPV_pot", 14 } )

   AAdd( aDbf, { "PVRDUG", "M", 20, 3, "VPV_R_dug", 14 } )
   AAdd( aDbf, { "PVRPOT", "M", 20, 3, "VPV_R_pot", 14 } )

   AAdd( aDbf, { "PV", "M", 15, 3, "VPV", 14 } )
   AAdd( aDbf, { "PC", "M", 15, 3, "VPC", 10 } )
   AAdd( aDbf, { "D_ULAZ", "D", 8, 0, "D_Poslj_Ul", 12 } )
   AAdd( aDbf, { "D_IZLAZ", "D", 8, 0, "D_poslj_Izl", 12  } )

   RETURN aDbf



STATIC FUNCTION kalk_llm_xlsx_export_fill_row( nVar, cIdRoba, cSifDob, cNazRoba, cTarifa, cJmj, ;
      nUlaz, nIzlaz, nSaldo, nNVDug, nNVPot, nNV, nNC, ;
      nPVDug, nPVPot, nPV, nPC, nPVrdug, nPVrpot, dDatZadnjiUlaz, dL_izlaz )

   LOCAL hRow := hb_hash()

   IF nVar == nil
      nVar := 0
   ENDIF

   IF p_cPrikazSamoNabavne == "D"  // resetuj varijable
      nPVDug := 0
      nPVPot := 0
      nPV := 0
      nPC := 0
   ENDIF

   hRow[ "idroba" ] := Trim( cIdRoba )
   hRow[ "sifradob" ] := Trim( cSifDob )
   hRow[ "naziv" ] := Trim( cNazRoba )
   hRow[ "tarifa" ] := Trim( cTarifa )
   hRow[ "jmj" ] := Trim( cJmj )
   hRow[ "ulaz" ] := nUlaz
   hRow[ "izlaz" ] := nIzlaz
   hRow[ "stanje" ] := nSaldo
   hRow[ "nvdug" ] := nNVDug
   hRow[ "nvpot" ] := nNVPot
   hRow[ "nv" ] := nNV
   hRow[ "nc" ] := nNC

   hRow[ "pvdug" ] := nPVDug
   hRow[ "pvpot" ] :=nPVPot
   hRow[ "pvrdug" ] := nPVrDug
   hRow[ "pvrpot" ] := nPVrPot
   hRow[ "pv" ] := nPV
   hRow[ "pc" ] := nPC
   hRow[ "d_ulaz" ] := dDatZadnjiUlaz
   hRow[ "d_izlaz" ] :=dL_izlaz

   xlsx_export_do_fill_row( hRow )

   RETURN .T.



STATIC FUNCTION kalk_llm_zaglavlje( cLine, cTxt1, cTxt2, cTxt3, cSredCij )

   LOCAL aLLM := {}
   LOCAL nPom

   // r.br
   nPom := 7
   AAdd( aLLM, { nPom, PadC( "R.", nPom ), PadC( "br.", nPom ), PadC( "", nPom ) } )

   // artikl
   nPom := 10
   AAdd( aLLM, { nPom, PadC( "Artikal", nPom ), PadC( "", nPom ), PadC( "1", nPom ) } )

   // naziv
   nPom := 20
   AAdd( aLLM, { nPom, PadC( "Naziv", nPom ), PadC( "", nPom ), PadC( "2", nPom ) } )

   // jmj
   nPom := 3
   AAdd( aLLM, { nPom, PadC( "jmj", nPom ), PadC( "", nPom ), PadC( "3", nPom ) } )

   nPom := Len( kalk_prosiri_pic_kolicina_za_2() )
   // ulaz
   AAdd( aLLM, { nPom, PadC( "ulaz", nPom ), PadC( "", nPom ), PadC( "4", nPom ) } )
   // izlaz
   AAdd( aLLM, { nPom, PadC( "izlaz", nPom ), PadC( "", nPom ), PadC( "5", nPom ) } )
   // stanje
   AAdd( aLLM, { nPom, PadC( "STANJE", nPom ), PadC( "", nPom ), PadC( "4 - 5", nPom ) } )


   // NV podaci
   // -------------------------------
   nPom := Len( kalk_prosiri_pic_cjena_za_2() )
   // nv dug.
   AAdd( aLLM, { nPom, PadC( "NV.Dug.", nPom ), PadC( "", nPom ), PadC( "6", nPom ) } )
   // nv pot.
   AAdd( aLLM, { nPom, PadC( "NV.Pot.", nPom ), PadC( "", nPom ), PadC( "7", nPom ) } )
   // NV
   AAdd( aLLM, { nPom, PadC( "NV", nPom ), PadC( "NC", nPom ), PadC( "6 - 7", nPom ) } )

   IF p_cPrikazSamoNabavne == "N"
      nPom := Len( kalk_prosiri_pic_cjena_za_2() )
      // pv.dug
      AAdd( aLLM, { nPom, PadC( "PV.Dug.", nPom ), PadC( "", nPom ), PadC( "8", nPom ) } )
      // rabat
      AAdd( aLLM, { nPom, PadC( "Rabat", nPom ), PadC( "", nPom ), PadC( "9", nPom ) } )
      // pv pot.
      AAdd( aLLM, { nPom, PadC( "PV.Pot.", nPom ), PadC( "", nPom ), PadC( "10", nPom ) } )
      // PV
      AAdd( aLLM, { nPom, PadC( "PV", nPom ), PadC( "PC", nPom ), PadC( "8 - 10", nPom ) } )
   ENDIF


   IF cSredCij == "D"
      nPom := Len( kalk_prosiri_pic_cjena_za_2() )
      // sredi cijene
      AAdd( aLLM, { nPom, PadC( "Sred.cij", nPom ), PadC( "", nPom ), PadC( "", nPom ) } )
   ENDIF

   cLine := SetRptLineAndText( aLLM, 0 )
   cTxt1 := SetRptLineAndText( aLLM, 1, "*" )
   cTxt2 := SetRptLineAndText( aLLM, 2, "*" )
   cTxt3 := SetRptLineAndText( aLLM, 3, "*" )

   RETURN .T.


STATIC FUNCTION kalk_zagl_lager_lista_magacin( cIdKonto )

   LOCAL nTArea := Select()

   Preduzece()

   P_COND2

   select_o_konto( cIdKonto )

   SET CENTURY ON

   ?? "KALK: LAGER LISTA ZA PERIOD", dDatOd, "-", dDatdo, "  na dan", Date(), Space( 12 ), "Str:", Str( ++nTStrana, 4 )

   SET CENTURY OFF

   ? "Magacin:", cIdkonto, "-", AllTrim( konto->naz )
   IF !Empty( cRNT1 ) .AND. !Empty( cRNalBroj )
      ?? ", uslov radni nalog: " + AllTrim( cRNalBroj )
   ENDIF

   ? s_cLinija
   ? s_cTxt1
   ? s_cTxt2
   ? s_cTxt3
   ? s_cLinija

   SELECT ( nTArea )

   RETURN .T.



/* kalk_pocetno_stanje_magacin_legacy()
 *     Generacija pocetnog stanja magacina
 */

FUNCTION kalk_pocetno_stanje_magacin_legacy()

   kalk_lager_lista_magacin( .T. )

   RETURN .T.


/* IsInGroup(cGr, cPodGr, cIdRoba)
 *     Provjerava da li artikal pripada odredjenoj grupi i podgrupi
 *   param: cGr - grupa
 *   param: cPodGr - podgrupa
 *   param: cIdRoba - id roba
 */
FUNCTION IsInGroup( cGr, cPodGr, cIdRoba )

   bRet := .F.

   IF Empty( cGr )
      RETURN .T.
   ENDIF

   IF AllTrim( IzSifKRoba( "GR1", cIdRoba, .F. ) ) $ AllTrim( cGr )
      bRet := .T.
   ELSE
      bRet := .F.
   ENDIF

   IF bRet
      IF !Empty( cPodGr )
         IF AllTrim( IzSifKRoba( "GR2", cIdRoba, .F. ) ) $ AllTrim( cPodGr )
            bRet := .T.
         ELSE
            bRet := .F.
         ENDIF
      ELSE
         bRet := .T.
      ENDIF
   ENDIF

   RETURN bRet



STATIC FUNCTION kalk_llm_open_tables()

   IF select_o_koncij()
      ?E "open koncij ok"
   ELSE
      ?E "open koncij ERROR?!"
   ENDIF


   RETURN .T.
