/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2020 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


STATIC picBHD
STATIC picDEM
STATIC R1
STATIC R2
STATIC s_cIOSClan := ""


FUNCTION fin_ios_meni()

   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}


   picBHD := "@Z " + ( R1 := FormPicL( "9 " + gPicBHD, 16 ) )
   picDEM := "@Z " + ( R2 := FormPicL( "9 " + pic_iznos_eur(), 12 ) )
   R1 := R1 + " " + valuta_domaca_skraceni_naziv()
   R2 := R2 + " " + ValPomocna()

   AAdd( aOpc, "1. štampa ios-a            " )
   AAdd( aOpcExe, {|| fin_ios_print() } )

   AAdd( aOpc, "2. podešenje član-a" )
   AAdd( aOpcExe, {|| ios_clan_setup() } )

   f18_menu( "ios", .F., nIzbor, aOpc, aOpcExe )

   RETURN .T.



STATIC FUNCTION fin_ios_print()

   LOCAL dDatumDo := fetch_metric( "ios_datum_do", my_user(), Date() )
   LOCAL hParams := hb_Hash()
   LOCAL hParametriGenIOS := hb_Hash()
   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdKonto := fetch_metric( "ios_print_id_konto", my_user(), Space( 7 ) )
   LOCAL cIdPartner := fetch_metric( "ios_print_id_partner", my_user(), Space( 6 ) )
   LOCAL cKm1EUR2 := "1"
   LOCAL cKaoKartica := fetch_metric( "ios_print_kartica", my_user(), "D" )
   LOCAL cPrelomljeno := fetch_metric( "ios_print_prelom", my_user(), "N" )
   LOCAL lExportXLSX := "N"
   LOCAL cPrintTip12 := fetch_metric( "ios_print_tip", my_user(), "1" )

   // LOCAL _auto_gen := fetch_metric( "ios_auto_gen", my_user(), "D" )
   LOCAL dDatumIOS := fetch_metric( "ios_datum_gen", my_user(), Date() )
   LOCAL nX := 1
   LOCAL _launch, aDbfFields
   LOCAL cXmlIos := my_home() + "data.xml"
   LOCAL cTemplate := "ios.odt"
   LOCAL cIdPartnerTekuci
   LOCAL nCount, nCountLimit := 12000 // broj izgenerisanih stavki
   LOCAL cNastavak := "N"
   LOCAL GetList := {}
   LOCAL cPrintSaldo0DN := fetch_metric( "ios_print_saldo_0", my_user(), "D" )
   LOCAL cSortIznosDN := fetch_metric( "ios_sort_iznos", my_user(), "N" )
   LOCAL lStampaj

   download_template( "ios.odt",  "8d1fa4972d42e54cc0e97e5c8d8c525787fc6b7b4d7c07ce092c38897b48ce85" )
   download_template( "ios_2.odt", "c0ef9bd9871aa73d09c343c19681ae7a449ffbf0a7dd0196ca548a04fd080d03" )

 
   Box(, 19, 65, .F. )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 " Štampa IOS-a **** "

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " Datum generacije IOS-a:" GET dDatumIOS

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY " Gledati period do:" GET dDatumDo
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Firma "
   ?? self_organizacija_id(), "-", self_organizacija_naziv()

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Konto       :" GET cIdKonto VALID P_Konto( @cIdKonto )
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Partner     :" GET cIdPartner VALID Empty( cIdPartner ) .OR.  p_partner( @cIdPartner ) PICT "@!"
   @ box_x_koord() + nX, Col() + 2 SAY "nastavak od ovog partnera D/N " GET cNastavak PICT "@!" VALID cNastavak $ "DN"

   IF fin_dvovalutno()
      ++nX
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Prikaz " +   AllTrim( valuta_domaca_skraceni_naziv() ) + "/" +  AllTrim( ValPomocna() ) + " (1/2)" ;
         GET cKm1EUR2 VALID cKm1EUR2 $ "12"
   ENDIF

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz prebijenog stanja " GET cPrelomljeno  VALID cPrelomljeno $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Prikaz identično kartici " GET cKaoKartica  VALID cKaoKartica $ "DN" PICT "@!"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Export u XLSX (D/N)?" GET lExportXLSX   VALID lExportXLSX $ "DN" PICT "@!"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Način stampe ODT/TXT (1/2) ?" GET cPrintTip12   VALID cPrintTip12 $ "12"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Limit za broj izgenerisanih stavki ?" GET nCountLimit
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Print sa saldom 0?" GET cPrintSaldo0DN VALID cPrintSaldo0DN $ "DN" PICT "@!"

   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Sortirati prema iznosu?" GET cSortIznosDN VALID cSortIznosDN $ "DN" PICT "@!"

   READ

   ESC_BCR

   BoxC()

   set_metric( "ios_print_id_konto", my_user(), cIdKonto )
   set_metric( "ios_print_id_partner", my_user(), cIdPartner )
   set_metric( "ios_print_kartica", my_user(), cKaoKartica )
   set_metric( "ios_print_prelom", my_user(), cPrelomljeno )
   set_metric( "ios_print_tip", my_user(), cPrintTip12 )
   set_metric( "ios_print_saldo_0", my_user(), cPrintSaldo0DN )
   set_metric( "ios_datum_do", my_user(), dDatumDo )
   set_metric( "ios_datum_gen", my_user(), dDatumIOS )
   set_metric( "ios_sort_iznos", my_user(), cSortIznosDN)

   cIdFirma := Left( cIdFirma, 2 )

   ios_clan_setup( .F. )    // definisi clan i setuj staticku varijablu


   hParametriGenIOS := hb_Hash()
   hParametriGenIOS[ "id_konto" ] := cIdKonto
   hParametriGenIOS[ "id_firma" ] := cIdFirma
   hParametriGenIOS[ "id_partner" ] := NIL
   IF !Empty( cIdPartner ) .AND. cNastavak == "N" // samo jedan partner
      hParametriGenIOS[ "id_partner" ] := cIdPartner
   ENDIF

   hParametriGenIOS[ "saldo_nula" ] := "D"
   hParametriGenIOS[ "datum_do" ] := dDatumDo
   IF cNastavak == "N"
      // generisi podatke u IOS.dbf tabelu
      fin_ios_generacija( hParametriGenIOS )     
   ENDIF

   IF lExportXLSX == "D"    // eksport podataka u dbf tabelu
      aDbfFields := gaDbfFields()
      IF !xlsx_export_init( aDbfFields )
         RETURN .F.
      ENDIF
   ENDIF

   o_fin_ios()
   GO TOP

   SEEK cIdFirma + cIdKonto
   NFOUND CRET

   IF cPrintTip12 == "2" // txt forma
      IF !start_print()
         RETURN .F.
      ENDIF
   ELSE
      create_xml( cXmlIos )
      xml_head()
      xml_subnode( "ios", .F. )
   ENDIF

   SELECT ios
   nCount := 0


   /*
      IOS.DBF
      aDbf := {}
      AAdd( aDBf, { "IDFIRMA", "C",   2,  0 } )
      AAdd( aDBf, { "IDKONTO", "C",   7,  0 } )
      AAdd( aDBf, { "IDPARTNER", "C",   6,  0 } )
      AAdd( aDBf, { "IZNOSBHD", "B",  8,  2 } )
      AAdd( aDBf, { "IZNOSDEM", "B",  8,  2 } )

      CREATE_INDEX( "1", "IdFirma+IdKonto+IdPartner", _alias )
      INDEX ON IdFirma+IdKonto+STR(ABS(ROUND(IZNOSBHD,0)),12,0)+IdPartner TAG "IZNOSD" DESCENDING
   */
   
   IF cSortIznosDN == "D"
      SET ORDER TO TAG "IZNDES"
   ENDIF
   GO TOP

   Box( "#IOS generacija xml", 3, 60 )

   IF cNastavak == "D"
      lStampaj := .F.
   ELSE
      lStampaj := .T.
   ENDIF


   DO WHILE !Eof() .AND. cIdFirma == field->idfirma .AND. cIdKonto == field->idkonto

      cIdPartnerTekuci := ios->idpartner
    
      /*
      IF !Empty( cIdPartner )
         IF cNastavak == "N" .AND. ( cIdPartner <> cIdPartnerTekuci ) // samo jedan partner
            SKIP
            LOOP
         ENDIF

         IF cNastavak == "D" .AND. ( cIdPartnerTekuci < cIdPartner ) // nastavi od zadatog partnera
            SKIP
            LOOP
         ENDIF
      ENDIF
      */
      IF !lStampaj
         // trazi partnera
         IF cIdPartnerTekuci <> cIdPartner
            SKIP
            LOOP
         ELSE
            // nakon zadatog partnera nastavi stampu
            lStampaj := .T.
            SKIP
            LOOP
         ENDIF
      ENDIF

      // zadata je stampa je odredjenog partnera
      IF (!Empty( cIdPartner ) .AND. cNastavak=="N") 
         IF  cIdPartner <> cIdPartnerTekuci
           SKIP
           LOOP
         ENDIF
      ENDIF

      IF cPrintSaldo0DN == "N" .AND. Round( ios->iznosbhd, 2 ) == 0 // ne prikazati saldo 0
         SKIP
         LOOP
      ENDIF

      hParams := hb_Hash()
      hParams[ "id_partner" ] := cIdPartnerTekuci
      hParams[ "id_konto" ] := cIdKonto
      hParams[ "id_firma" ] := cIdFirma
      hParams[ "din_dem" ] := cKm1EUR2
      hParams[ "datum_do" ] := dDatumDo
      hParams[ "ios_datum" ] := dDatumIOS
      hParams[ "export_dbf" ] := lExportXLSX
      hParams[ "iznos_bhd" ] := ios->iznosbhd
      hParams[ "iznos_dem" ] := ios->iznosdem
      hParams[ "kartica" ] := cKaoKartica
      hParams[ "prelom" ] := cPrelomljeno

      IF cPrintTip12 == "2"
         print_ios_txt( hParams )
      ELSE
         nCount += print_ios_xml( hParams )
      ENDIF

      SKIP

      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Cnt: " + Str( nCount, 5 ) + " / limit: " + Str( nCountLimit, 5 )

      IF nCount > nCountLimit
         MsgBeep( "Posljednja obuhvaćena šifra parnera: " + cIdPartnerTekuci )
         EXIT
      ENDIF
   ENDDO

   BoxC()

   IF cPrintTip12 == "2"
      end_print()
   ELSE
      xml_subnode( "ios", .T. )
      close_xml()
   ENDIF

   IF cPrintTip12 == "2" .AND. lExportXLSX == "D"
      open_exported_xlsx()
   ENDIF

   my_close_all_dbf()

   IF cPrintTip12 == "1"

      IF Empty( cIdPartner ) .OR. cNastavak == "D" // vise partnera
         cTemplate := "ios_2.odt"
      ENDIF

      IF generisi_odt_iz_xml( cTemplate, cXmlIos )
         prikazi_odt()
      ENDIF

   ENDIF

   RETURN .T.


STATIC FUNCTION print_ios_xml( hParams )

   LOCAL _rbr
   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdKonto := hParams[ "id_konto" ]
   LOCAL cIdPartner := hParams[ "id_partner" ]
   LOCAL nIznosKM := hParams[ "iznos_bhd" ]
   LOCAL nIznosDEM := hParams[ "iznos_dem" ]
   LOCAL cKm1EUR2 := hParams[ "din_dem" ]
   LOCAL dDatumDo := hParams[ "datum_do" ]
   LOCAL dDatumIOS := hParams[ "ios_datum" ]
   LOCAL cKaoKartica := hParams[ "kartica" ]
   LOCAL cPrelomljeno := hParams[ "prelom" ]
   LOCAL nSaldo1, nSaldo2, __saldo_1, __saldo_2
   LOCAL nDug1, nDug2, nDUkDug1, nDUkDug2, _u_dug_1z, _u_dug_2z
   LOCAL nPot1, nPot2, nDUkPot1, nDUkPot2, _u_pot_1z, _u_pot_2z

   LOCAL nTotalKM
   LOCAL nTotalEUR
   LOCAL nCount
   LOCAL cOtvSt, cBrDok

   // <ios_item>
   //
   // <firma>
   // <id>10</id>
   // <naz>...</naz>
   // .....
   // </firma>
   //
   // <partner>
   // <id>1231</id>
   // <naz>PARTNER XZX</naz>
   // .....
   // </partner>
   //
   // <ios_datum></ios_datum>
   //
   //
   //
   // </ios_item>

   xml_subnode( "ios_item", .F. )

   IF !ios_xml_partner( "firma", cIdFirma )
      MsgBeep( "Šifra partnera: " + cIdFirma + " Nedostaje !#Prekid" )
      RETURN -1
   ENDIF
   IF !ios_xml_partner( "partner", cIdPartner )
      MsgBeep( "Šifra partnera: " + cIdPartner + " Nedostaje !#Prekid" )
      RETURN -1
   ENDIF


   xml_node( "ios_datum", DToC( dDatumIOS ) )
   xml_node( "id_konto", to_xml_encoding( cIdKonto ) )
   xml_node( "id_partner", to_xml_encoding( cIdPartner ) )

   nTotalKM := nIznosKM
   nTotalEUR := nIznosDEM

   IF nIznosKM < 0
      nTotalKM := -nIznosKM
   ENDIF
   IF nIznosDEM < 0
      nTotalEUR := -nIznosDEM
   ENDIF

   IF cKm1EUR2 == "1"
      xml_node( "total", AllTrim( Str( nTotalKM, 12, 2 ) ) )
      xml_node( "valuta", to_xml_encoding ( valuta_domaca_skraceni_naziv() ) )
   ELSE
      xml_node( "total", AllTrim( Str( nTotalEUR, 12, 2 ) ) )
      xml_node( "valuta", to_xml_encoding ( ValPomocna() ) )
   ENDIF

   IF nIznosKM > 0
      xml_node( "dp", "1" )
   ELSE
      xml_node( "dp", "2" )
   ENDIF

   IF cKaoKartica == "D"
      // SET ORDER TO TAG "1"
      find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner, NIL, "idfirma,idvn,brnal" )
   ELSE
      // SET ORDER TO TAG "3"
      find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner, NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   ENDIF

   nDUkDug1 := 0
   nDUkDug2 := 0
   nDUkPot1 := 0
   nDUkPot2 := 0
   _u_dug_1z := 0
   _u_dug_2z := 0
   _u_pot_1z := 0
   _u_pot_2z := 0

   IF cKaoKartica == "D" // ako je kartica, onda nikad ne prelamaj
      cPrelomljeno := "N"
   ENDIF

   nCount := 0
   _rbr := 0

   DO WHILE !Eof() .AND. cIdFirma == suban->IdFirma .AND. cIdKonto == suban->IdKonto  .AND. cIdPartner == suban->IdPartner

      cBrDok := field->brdok
      __dat_dok := field->datdok
      __opis := AllTrim( field->opis )
      __dat_val := fix_dat_var( field->datval )
      nDug1 := 0
      nPot1 := 0
      nDug2 := 0
      nPot2 := 0
      cOtvSt := field->otvst

      DO WHILE !Eof() .AND. cIdFirma == suban->IdFirma .AND. cIdKonto == field->IdKonto  .AND. cIdPartner == suban->IdPartner ;
            .AND. ( cKaoKartica == "D" .OR. suban->brdok == cBrDok )

         IF field->datdok > dDatumDo
            SKIP
            LOOP
         ENDIF

         IF field->otvst = " "

            IF cKaoKartica == "D"

               nCount++
               xml_subnode( "data_kartica", .F. )

               xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
               xml_node( "brdok", to_xml_encoding( field->brdok ) )
               xml_node( "opis", to_xml_encoding( field->opis ) )
               xml_node( "datdok", DToC( field->datdok ) )
               xml_node( "datval", DToC( fix_dat_var( field->datval ) ) )

               IF cKm1EUR2 == "1"
                  xml_node( "dug", AllTrim( Str( iif( field->d_p == "1", field->iznosbhd, 0 ), 12, 2 ) ) )
                  xml_node( "pot", AllTrim( Str( iif( field->d_p == "2", field->iznosbhd, 0 ), 12, 2 ) ) )
               ELSE
                  xml_node( "dug", AllTrim( Str( iif( field->d_p == "1", field->iznosdem, 0 ), 12, 2 ) ) )
                  xml_node( "pot", AllTrim( Str( iif( field->d_p == "2", field->iznosdem, 0 ), 12, 2 ) ) )
               ENDIF

               xml_subnode( "data_kartica", .T. )

            ENDIF

            IF field->d_p = "1"
               nDug1 += field->IznosBHD
               nDug2 += field->IznosDEM
            ELSE
               nPot1 += field->IznosBHD
               nPot2 += field->IznosDEM
            ENDIF

            cOtvSt := " "

         ELSE


            IF field->d_p == "1"   // zatvorene stavke
               _u_dug_1z += field->IznosBHD
               _u_dug_2z += field->IznosDEM
            ELSE
               _u_pot_1z += field->IznosBHD
               _u_pot_2z += field->IznosDEM
            ENDIF

         ENDIF

         SKIP

      ENDDO

      IF cOtvSt == " "
         IF cPrelomljeno == "D"
            IF cKm1EUR2 == "1"
               IF ( nDug1 - nPot1 ) > 0    // domaca valuta
                  nDug1 := ( nDug1 - nPot1 )
                  nPot1 := 0
               ELSE
                  nPot1 := ( nPot1 - nDug1 )
                  nDug1 := 0
               ENDIF
            ELSE
               IF ( nDug2 - nPot2 ) > 0  // strana valuta
                  nDug2 := ( nDug2 - nPot2 )
                  nPot2 := 0
               ELSE
                  nPot2 := ( nPot2 - nDug2 )
                  nDug2 := 0
               ENDIF

            ENDIF

         ENDIF

         IF cKaoKartica == "N"

            IF !( Round( nDug1, 2 ) == 0 .AND. Round( nPot1, 2 ) == 0 ) // ispisi ove stavke ako dug i pot <> 0
               xml_subnode( "data_kartica", .F. )
               ++nCount
               xml_node( "rbr", AllTrim( Str( ++_rbr ) ) )
               xml_node( "brdok", to_xml_encoding( cBrDok ) )
               xml_node( "opis", to_xml_encoding( __opis ) )
               xml_node( "datdok", DToC( fix_dat_var( __dat_dok ) ) )
               xml_node( "datval", DToC( fix_dat_var( __dat_val ) ) )
               xml_node( "dug", AllTrim( Str( nDug1, 12, 2 ) ) )
               xml_node( "pot", AllTrim( Str( nPot1, 12, 2 ) ) )

               xml_subnode( "data_kartica", .T. )
            ENDIF

         ENDIF

         nDUkDug1 += nDug1
         nDUkPot1 += nPot1
         nDUkDug2 += nDug2
         nDUkPot2 += nPot2
      ENDIF

   ENDDO


   nSaldo1 := ( nDUkDug1 - nDUkPot1 ) // saldo
   nSaldo2 := ( nDUkDug2 - nDUkPot2 )

   IF cKm1EUR2 == "1"

      xml_node( "u_dug", AllTrim( Str( nDUkDug1, 12, 2 ) ) )
      xml_node( "u_pot", AllTrim( Str( nDUkPot1, 12, 2 ) ) )

      IF Round( _u_dug_1z - _u_pot_1z, 4 ) <> 0
         xml_node( "greska", AllTrim( Str( _u_dug_1z - _u_pot_1z, 12, 2  ) )  )
      ELSE
         xml_node( "greska", ""  )
      ENDIF

      IF nSaldo1 >= 0
         xml_node( "saldo", AllTrim( Str( nSaldo1, 12, 2 ) ) )
      ELSE
         nSaldo1 := -nSaldo1
         xml_node( "saldo", AllTrim( Str( nSaldo1, 12, 2 ) ) )
      ENDIF

   ELSE

      xml_node( "u_dug", AllTrim( Str( nDUkDug2, 12, 2 ) ) )
      xml_node( "u_pot", AllTrim( Str( nDUkPot2, 12, 2 ) ) )

      IF Round( _u_dug_2z - _u_pot_2z, 4 ) <> 0
         xml_node( "greska", AllTrim( Str( _u_dug_2z - _u_pot_2z, 12, 2  ) )  )
      ELSE
         xml_node( "greska", ""  )
      ENDIF

      IF nSaldo2 >= 0
         xml_node( "saldo", AllTrim( Str( nSaldo2, 12, 2 ) ) )
      ELSE
         nSaldo2 := -nSaldo2
         xml_node( "saldo", AllTrim( Str( nSaldo2, 12, 2 ) ) )
      ENDIF

   ENDIF

   xml_node( "mjesto", to_xml_encoding( AllTrim( gMjStr ) ) )
   xml_node( "datum", DToC( dDatumDo ) )

   xml_node( "clan", to_xml_encoding( s_cIOSClan ) )

   xml_subnode( "ios_item", .T. )

   SELECT ios

   RETURN nCount



STATIC FUNCTION ios_clan_setup( setup_box )

   LOCAL cTxt := ""
   LOCAL _clan

   IF setup_box == NIL
      setup_box := .T.
   ENDIF

   // ovo je tekuci defaultni clan
   cTxt := "Prema clanu 28. stav 4. Zakona o racunovodstvu i reviziji u FBIH (Sl.novine FBIH, broj 83/09) "
   cTxt += "na ovu nasu konfirmaciju ste duzni odgovoriti u roku od osam dana. "
   cTxt += "Ukoliko u tom roku ne primimo potvrdu ili osporavanje iskazanog stanja, smatracemo da je "
   cTxt += "usaglasavanje izvrseno i da je stanje isto."

   _clan := PadR( fetch_metric( "ios_clan_txt", NIL, cTxt ), 500 )

   IF setup_box
      Box(, 2, 70 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Definisanje clan-a na IOS-u:"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY ":" GET _clan PICT "@S65"
      READ
      BoxC()

      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF
   ENDIF


   set_metric( "ios_clan_txt", NIL, AllTrim( _clan ) )
   s_cIOSClan := AllTrim( _clan )

   RETURN .T.



STATIC FUNCTION fin_ios_spec_vars( hParams )

   LOCAL cIdFirma := self_organizacija_id()
   LOCAL cIdKonto := fetch_metric( "ios_spec_id_konto", my_user(), Space( 7 ) )
   LOCAL cPrikazSaSaldoNulaDN := "D"
   LOCAL dDatumDo := Date()

   // o_konto()

   Box( "", 6, 60 )
      @ box_x_koord() + 1, box_y_koord() + 6 SAY "SPECIFIKACIJA IOS-a"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "
      ?? self_organizacija_id(), "-", self_organizacija_naziv()
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto: " GET cIdKonto VALID P_Konto( @cIdKonto )
      @ box_x_koord() + 5, box_y_koord() + 2 SAY8 "Datum do kojeg se generiše  :" GET dDatumDo
      @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Prikaz partnera sa saldom 0 :" GET cPrikazSaSaldoNulaDN VALID cPrikazSaSaldoNulaDN $ "DN" PICT "@!"
      READ
   BoxC()

   // SELECT konto
   USE

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF


   set_metric( "ios_spec_id_konto", my_user(), cIdKonto )
   cIdFirma := Left( cIdFirma, 2 )

   hParams[ "id_konto" ] := cIdKonto
   hParams[ "id_firma" ] := cIdFirma
   hParams[ "saldo_nula" ] := cPrikazSaSaldoNulaDN
   hParams[ "datum_do" ] := dDatumDo

   RETURN .T.



/*
   generisanje ios.dbf
*/

STATIC FUNCTION fin_ios_generacija( hParams )

   LOCAL dDatumDo, cIdFirma, cIdKonto, cPrikazSaSaldoNulaDN
   LOCAL cIdPartner, hRec, nCount, nCountPartner
   LOCAL lAuto := .F.
   LOCAL nDug1, nDug2, nDUkDug1, nDUkDug2
   LOCAL nPot1, nPot2, nDUkPot1, nDUkPot2
   LOCAL nSaldo1, nSaldo2
   LOCAL cIdPartnerTekuci
   LOCAL lNeaktivanPartner

   IF hParams == NIL
      MsgBeep( "Napomena: ova opcija puni pomoćnu tabelu na osnovu koje se#štampaju IOS obrasci" )
      hParams := hb_Hash()
   ELSE
      lAuto := .T.
   ENDIF

   IF !lAuto .AND. !fin_ios_spec_vars( @hParams )
      RETURN .F.
   ENDIF

   cIdFirma := hParams[ "id_firma" ]
   cIdKonto := hParams[ "id_konto" ]
   cIdPartner := hParams[ "id_partner" ]

   dDatumDo := hParams[ "datum_do" ]
   cPrikazSaSaldoNulaDN := hParams[ "saldo_nula" ]

   MsgO("Preuzimanje podataka sa servera...")

   o_suban()
   o_fin_ios()

   SELECT ios  // reset tabele IOS
   my_dbf_zap()

   find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner )
   MsgC()

   EOF CRET

   Box(, 5, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Generacija IOS tabele u toku ..."

   DO WHILE !Eof() .AND. cIdFirma == suban->idfirma .AND. cIdKonto == suban->idkonto

      cIdPartnerTekuci := suban->idpartner

      nDug1 := 0
      nDUkDug1 := 0
      nDug2 := 0
      nDUkDug2 := 0
      nPot1 := 0
      nDUkPot1 := 0
      nPot2 := 0
      nDUkPot2 := 0
      nSaldo1 := 0
      nSaldo2 := 0

      nCountPartner := 0
      select_o_partner( cIdPartnerTekuci )
      SELECT suban
      lNeaktivanPartner := (partn->_kup == "X")

      nCount := 0
      DO WHILE !Eof() .AND. cIdFirma == suban->idfirma  .AND. cIdKonto == suban->idkonto  .AND. cIdPartnerTekuci == suban->idpartner
         IF (suban->datdok > dDatumDo) .OR. lNeaktivanPartner
            SKIP
            LOOP
         ENDIF

         IF field->otvst == " "
            IF field->d_p == "1"
               nDug1 += suban->iznosbhd
               nDUkDug1 += suban->Iznosbhd
               nDug2 += suban->Iznosdem
               nDUkDug2 += suban->Iznosdem
            ELSE
               nPot1 += suban->IznosBHD
               nDUkPot1 += suban->IznosBHD
               nPot2 += suban->IznosDEM
               nDUkPot2 += suban->IznosDEM
            ENDIF
         ENDIF

         @ box_x_koord() + 5, box_y_koord() + 5 SAY Str(++nCountPartner, 5, 0)
         SKIP
      ENDDO

      nSaldo1 := nDug1 - nPot1
      nSaldo2 := nDug2 - nPot2

      IF !lNeaktivanPartner // neaktivne partnere ne dodavati u ios.dbf
         IF (Round( nSaldo1, 2 ) <> 0) .OR. (cPrikazSaSaldoNulaDN == "D") 

           SELECT ios
           APPEND BLANK
           hRec := dbf_get_rec()

           hRec[ "idfirma" ] := cIdFirma
           hRec[ "idkonto" ] := cIdKonto
           hRec[ "idpartner" ] := cIdPartnerTekuci
           hRec[ "iznosbhd" ] := nSaldo1
           hRec[ "iznosdem" ] := nSaldo2
           dbf_update_rec( hRec )
           @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( "Partner: " + cIdPartnerTekuci + ", saldo: " + AllTrim( Str( nSaldo1, 12, 2 ) ), 60 )

           ++nCount
         ENDIF
      ENDIF

      SELECT suban

   ENDDO

   BoxC()

   RETURN nCount



STATIC FUNCTION ios_xml_partner( cSubnode, cIdPartner )

   LOCAL cJIB, cPdvBroj, cIdBroj

   select_o_partner( cIdPartner )

   IF !Found() .AND. !Empty( cIdPartner )
      RETURN .F.
   ENDIF

   xml_subnode( cSubnode, .F. )

   IF Empty( cIdPartner )
      xml_node( "id", to_xml_encoding( "-" ) )
      xml_node( "naz", to_xml_encoding( "-" ) )
      xml_node( "naz2", to_xml_encoding( "-" ) )
      xml_node( "mjesto", to_xml_encoding( "-" ) )
      xml_node( "adresa", to_xml_encoding( "-" ) )
      xml_node( "ptt", to_xml_encoding( "-" ) )
      xml_node( "ziror", to_xml_encoding( "-" ) )
      xml_node( "tel", to_xml_encoding( "-" ) )
      xml_node( "jib", "-" )
   ELSE
      xml_node( "id", to_xml_encoding( cIdPartner ) )
      xml_node( "naz", to_xml_encoding( partn->naz ) )
      xml_node( "naz2", to_xml_encoding( partn->naz2 ) )
      xml_node( "mjesto", to_xml_encoding( partn->mjesto ) )
      xml_node( "adresa", to_xml_encoding( partn->adresa ) )
      xml_node( "ptt", to_xml_encoding( partn->ptt ) )
      xml_node( "ziror", to_xml_encoding( partn->ziror ) )
      xml_node( "tel", to_xml_encoding( partn->telefon ) )

      cJIB := firma_pdv_broj( cIdPartner )

      cPdvBroj := cJIB
      cIdBroj := firma_id_broj( cIdPartner )

      xml_node( "jib", cJIB )
      xml_node( "pdvbr", cPdvBroj )
      xml_node( "idbbr", cIdBroj )
   ENDIF

   xml_subnode( cSubnode, .T. )

   RETURN .T.



STATIC FUNCTION print_ios_txt( hParams )

   LOCAL _rbr
   LOCAL _n_opis := 0
   LOCAL cIdFirma := hParams[ "id_firma" ]
   LOCAL cIdKonto := hParams[ "id_konto" ]
   LOCAL cIdPartner := hParams[ "id_partner" ]
   LOCAL nIznosKM := hParams[ "iznos_bhd" ]
   LOCAL nIznosDEM := hParams[ "iznos_dem" ]
   LOCAL cKm1EUR2 := hParams[ "din_dem" ]
   LOCAL dDatumDo := hParams[ "datum_do" ]
   LOCAL dDatumIOS := hParams[ "ios_datum" ]
   LOCAL lExportXLSX := hParams[ "export_dbf" ]
   LOCAL cKaoKartica := hParams[ "kartica" ]
   LOCAL cPrelomljeno := hParams[ "prelom" ]
   LOCAL cPartnerNaziv

   ?

   @ PRow(), 58 SAY "OBRAZAC: I O S"
   @ PRow() + 1, 1 SAY cIdFirma

   select_o_partner( cIdFirma )

   @ PRow(), 5 SAY AllTrim( partn->naz )
   @ PRow(), PCol() + 1 SAY AllTrim( partn->naz2 )
   @ PRow() + 1, 5 SAY partn->Mjesto
   @ PRow() + 1, 5 SAY partn->Adresa
   @ PRow() + 1, 5 SAY partn->ptt
   @ PRow() + 1, 5 SAY partn->ZiroR
   @ PRow() + 1, 5 SAY firma_pdv_broj( cIdFirma )

   ?

   select_o_partner( cIdPartner )

   @ PRow(), 45 SAY cIdPartner
   ?? " -", AllTrim( partn->naz )
   @ PRow() + 1, 45 SAY partn->mjesto
   @ PRow() + 1, 45 SAY partn->adresa
   @ PRow() + 1, 45 SAY partn->ptt
   @ PRow() + 1, 45 SAY partn->ziror

   IF !Empty( partn->telefon )
      @ PRow() + 1, 45 SAY "Telefon: " + partn->telefon
   ENDIF

   @ PRow() + 1, 45 SAY firma_pdv_broj( cIdPartner )

   cPartnerNaziv := partn->naz

   ?
   ?
   @ PRow(), 6 SAY "IZVOD OTVORENIH STAVKI NA DAN :"
   @ PRow(), PCol() + 2 SAY dDatumIOS
   @ PRow(), PCol() + 1 SAY "GODINE"
   ?
   ?
   @ PRow(), 0 SAY8 "VAŠE STANJE NA KONTU" ; @ PRow(), PCol() + 1 SAY cIdKonto
   @ PRow(), PCol() + 1 SAY " - " + cIdPartner
   @ PRow() + 1, 0 SAY8 "PREMA NAŠIM POSLOVNIM KNJIGAMA NA DAN:"
   @ PRow(), 39 SAY dDatumIOS
   @ PRow(), 48 SAY "GODINE"
   ?
   ?
   @ PRow(), 0 SAY "POKAZUJE SALDO:"

   qqIznosBHD := nIznosKM
   qqIznosDEM := nIznosDEM

   IF nIznosKM < 0
      qqIznosBHD := -nIznosKM
   ENDIF

   IF nIznosDEM < 0
      qqIznosDEM := -nIznosDEM
   ENDIF

   IF cKm1EUR2 == "1"
      @ PRow(), 16 SAY qqIznosBHD PICT R1
   ELSE
      @ PRow(), 16 SAY qqIznosDEM PICT R2
   ENDIF

   ?
   ?

   @ PRow(), 0 SAY "U"

   IF nIznosKM > 0
      @ PRow(), PCol() + 1 SAY8 "NAŠU"
   ELSE
      @ PRow(), PCol() + 1 SAY8 "VAŠU"
   ENDIF

   @ PRow(), PCol() + 1 SAY "KORIST I SASTOJI SE IZ SLIJEDECIH OTVORENIH STAVKI:"

   P_COND

   m := "       ---- ---------- -------------------- -------- -------- ---------------- ----------------"

   ? m
   ? "       *R. *   BROJ   *    OPIS            * DATUM  * VALUTA *       IZNOS  U  " + iif( cKm1EUR2 == "1", valuta_domaca_skraceni_naziv(), ValPomocna() ) + "            *"
   ? "       *Br.*          *                    *                 * --------------------------------"
   ?U "       *   *  RAČUNA  *                    * RA�UNA * RAČUNA *     DUGUJE     *   POTRAŽUJE   *"
   ? m

   nCol1 := 62

   IF cKaoKartica == "D"
      find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner, NIL, "idfirma,idvn,brnal" )
   ELSE
      find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner, NIL, "IdFirma,IdKonto,IdPartner,brdok" )
   ENDIF


   nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0
   nDugBHDZ := nPotBHDZ := nDugDEMZ := nPotDEMZ := 0
   _rbr := 0


   IF cKaoKartica == "D"    // ako je kartica, onda nikad ne prelamaj
      cPrelomljeno := "N"
   ENDIF

   DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cIdKonto == field->IdKonto .AND. cIdPartner == field->idPartner

      cBrDok := field->brdok
      dDatdok := field->datdok
      cOpis := AllTrim( field->opis )
      dDatVal := fix_dat_var( field->datval )
      nDBHD := 0
      nPBHD := 0
      nDDEM := 0
      nPDEM := 0
      cOtvSt := field->otvst

      DO WHILE !Eof() .AND. cIdFirma == field->IdFirma .AND. cIdKonto == field->IdKonto ;
            .AND. cIdPartner == field->IdPartner .AND. ( cKaoKartica == "D" .OR. field->brdok == cBrdok )

         IF field->datdok > dDatumDo
            SKIP
            LOOP
         ENDIF

         IF field->otvst = " "

            IF cKaoKartica == "D"

               IF PRow() > 61 + dodatni_redovi_po_stranici()
                  FF
               ENDIF

               @ PRow() + 1, 8 SAY + + _rbr PICT '999'
               @ PRow(), PCol() + 1 SAY field->BrDok
               _n_opis := PCol() + 1
               @ PRow(), _n_opis SAY PadR( field->Opis, 20 )
               @ PRow(), PCol() + 1 SAY field->DatDok
               @ PRow(), PCol() + 1 SAY fix_dat_var( field->DatVal )

               IF cKm1EUR2 == "1"
                  @ PRow(), nCol1 SAY iif( field->D_P == "1", field->iznosbhd, 0 ) PICT picBHD
                  @ PRow(), PCol() + 1 SAY iif( field->D_P == "2", field->iznosbhd, 0 ) PICT picBHD
               ELSE
                  @ PRow(), nCol1 SAY iif( field->D_P == "1", field->iznosdem, 0 ) PICT picBHD
                  @ PRow(), PCol() + 1 SAY iif( field->D_P == "2", field->iznosdem, 0 ) PICT picBHD
               ENDIF

               IF lExportXLSX == "D"
                  xlsx_export_fill_row( cIdPartner, ;
                     cPartnerNaziv, ;
                     field->brdok, ;
                     field->opis, ;
                     field->datdok, ;
                     fix_dat_var( field->datval ), ;
                     iif( field->d_p == "1", field->iznosbhd, 0 ), ;
                     iif( field->d_p == "2", field->iznosbhd, 0 ) )
               ENDIF

            ENDIF

            IF field->d_p = "1"
               nDBHD += field->IznosBHD
               nDDEM += field->IznosDEM
            ELSE
               nPBHD += field->IznosBHD
               nPDEM += field->IznosDEM
            ENDIF

            cOtvSt := " "

         ELSE

            IF field->D_P == "1"
               nDugBHDZ += field->IznosBHD
               nDugDEMZ += field->IznosDEM
            ELSE
               nPotBHDZ += field->IznosBHD
               nPotDEMZ += field->IznosDEM
            ENDIF

         ENDIF

         SKIP

      ENDDO

      IF cOtvSt == " "

         IF cKaoKartica == "N"

            IF PRow() > 61 + dodatni_redovi_po_stranici()
               FF
            ENDIF

            @ PRow() + 1, 8 SAY + + _rbr PICT "999"
            @ PRow(), PCol() + 1  SAY cBrDok
            _n_opis := PCol() + 1
            @ PRow(), _n_opis SAY PadR( cOpis, 20 )
            @ PRow(), PCol() + 1 SAY dDatDok
            @ PRow(), PCol() + 1 SAY fix_dat_var( dDatVal, .T. )

         ENDIF

         IF cKm1EUR2 == "1"

            IF cPrelomljeno == "D"

               IF ( nDBHD - nPBHD ) > 0
                  nDBHD := ( nDBHD - nPBHD )
                  nPBHD := 0
               ELSE
                  nPBHD := ( nPBHD - nDBHD )
                  nDBHD := 0
               ENDIF

            ENDIF

            IF cKaoKartica == "N"

               @ PRow(), nCol1 SAY nDBHD PICT picBHD
               @ PRow(), PCol() + 1 SAY nPBhD PICT picBHD

               IF lExportXLSX == "D"
                  xlsx_export_fill_row( cIdPartner, ;
                     cPartnerNaziv, ;
                     cBrDok, ;
                     cOpis, ;
                     dDatdok, ;
                     fix_dat_var( dDatval, .T. ), ;
                     nDBHD, ;
                     nPBHD )
               ENDIF

            ENDIF

         ELSE
            IF cPrelomljeno == "D"
               IF ( nDDEM - nPDEM ) > 0
                  nDDEM := ( nDDEM - nPDEM )
                  nPBHD := 0
               ELSE
                  nPDEM := ( nPDEM - nDDEM )
                  nDDEM := 0
               ENDIF
            ENDIF

            IF cKaoKartica == "N"

               @ PRow(), nCol1 SAY nDDEM PICT picBHD
               @ PRow(), PCol() + 1 SAY nPDEM PICT picBHD

               IF lExportXLSX == "D"
                  xlsx_export_fill_row( cIdPartner, ;
                     cPartnerNaziv, ;
                     cBrdok, ;
                     cOpis, ;
                     dDatdok, ;
                     fix_dat_var( dDatval, .T. ), ;
                     nDDEM, ;
                     nPDEM )
               ENDIF

            ENDIF
         ENDIF

         nDugBHD += nDBHD
         nPotBHD += nPBHD
         nDugDem += nDDem
         nPotDem += nPDem

      ENDIF

      fin_print_ostatak_opisa( cOpis, _n_opis )

   ENDDO

   IF PRow() > 61 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   @ PRow() + 1, 0 SAY m
   @ PRow() + 1, 8 SAY "UKUPNO:"

   IF cKm1EUR2 == "1"
      @ PRow(), nCol1 SAY nDugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
   ELSE
      @ PRow(), nCol1 SAY nDugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
   ENDIF

   // ako je promet zatvorenih stavki <> 0  prikazi ga ????
   IF cKm1EUR2 == "1"
      IF Round( nDugBHDZ - nPOTBHDZ, 4 ) <> 0
         @ PRow() + 1, 0 SAY m
         @ PRow() + 1, 8 SAY "ZATVORENE STAVKE"
         @ PRow(), nCol1 SAY ( nDugBHDZ - nPOTBHDZ ) PICT picBHD
         @ PRow(), PCol() + 1 SAY  " GRE�KA !!"
      ENDIF
   ELSE
      IF Round( nDugDEMZ - nPOTDEMZ, 4 ) <> 0
         @ PRow() + 1, 0 SAY m
         @ PRow() + 1, 8 SAY "ZATVORENE STAVKE"
         @ PRow(), nCol1 SAY ( nDugDEMZ - nPOTDEMZ ) PICT picBHD
         @ PRow(), PCol() + 1 SAY " GRE�KA !!"
      ENDIF
   ENDIF

   @ PRow() + 1, 0 SAY m
   @ PRow() + 1, 8 SAY "SALDO:"

   nSaldoBHD := ( nDugBHD - nPotBHD )
   nSaldoDEM := ( nDugDEM - nPotDEM )

   IF cKm1EUR2 == "1"
      IF nSaldoBHD >= 0
         @ PRow(), nCol1 SAY nSaldoBHD PICT picBHD
         @ PRow(), PCol() + 1 SAY 0 PICT picBHD
      ELSE
         nSaldoBHD := -nSaldoBHD
         nSaldoDEM := -nSaldoDEM
         @ PRow(), nCol1 SAY 0 PICT picBHD
         @ PRow(), PCol() + 1 SAY nSaldoBHD PICT picBHD
      ENDIF
   ELSE
      IF nSaldoDEM >= 0
         @ PRow(), nCol1 SAY nSaldoDEM PICT picBHD
         @ PRow(), PCol() + 1 SAY 0 PICT picBHD
      ELSE
         nSaldoDEM := -nSaldoDEM
         @ PRow(), nCol1 SAY 0 PICT picBHD
         @ PRow(), PCol() + 1 SAY nSaldoDEM PICT picBHD
      ENDIF
   ENDIF

   ? m

   F10CPI

   ?

   IF PRow() > 61 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   ?
   ?

   F12CPI

   @ PRow(), 13 SAY "POSILJALAC IZVODA:"
   @ PRow(), 53 SAY "POTVRDJUJEMO SAGLASNOST"
   @ PRow() + 1, 50 SAY "OTVORENIH STAVKI:"

   ?
   ?
   @ PRow(), 10 SAY "__________________"
   @ PRow(), 50 SAY "______________________"

   IF PRow() > 58 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   ?
   ?

   @ PRow(), 10 SAY "__________________ M.P."
   @ PRow(), 50 SAY "______________________ M.P."

   ?
   ?

   @ PRow(), 10 SAY Trim( gMjStr ) + ", " + DToC( Date() )
   @ PRow(), 52 SAY "( MJESTO I DATUM )"

   IF PRow() > 52 + dodatni_redovi_po_stranici()
      FF
   ENDIF

   ?
   ?

   @ PRow(), 0 SAY "Prema clanu 28. stav 4. Zakona o racunovodstvu i reviziji u FBIH (Sl.novine FBIH, broj 83/09)"
   @ PRow() + 1, 0 SAY "na ovu nasu konfirmaciju ste duzni odgovoriti u roku od osam dana."
   @ PRow() + 1, 0 SAY "Ukoliko u tom roku ne primimo potvrdu ili osporavanje iskazanog stanja, smatracemo da je"
   @ PRow() + 1, 0 SAY "usaglasavanje izvrseno i da je stanje isto."

   ?
   ?

   @ PRow(), 0 SAY "NAPOMENA: OSPORAVAMO ISKAZANO STANJE U CJELINI _______________ DJELIMI�NO"
   @ PRow() + 1, 0 SAY "ZA IZNOS OD  " + valuta_domaca_skraceni_naziv() + "= _______________ IZ SLIJEDE�IH RAZLOGA:"
   @ PRow() + 1, 0 SAY "_________________________________________________________________________"

   ?
   ?

   @ PRow(), 0 SAY "_________________________________________________________________________"
   ?
   ?
   @ PRow(), 48 SAY8 "DUŽNIK:"
   @ PRow() + 1, 40 SAY "_______________________ M.P."
   @ PRow() + 1, 44 SAY "( MJESTO I DATUM )"

   SELECT ios

   RETURN .T.



// ---------------------------------------------------------
// filovanje tabele sa podacima
// ---------------------------------------------------------
STATIC FUNCTION xlsx_export_fill_row( cIdPart, cNazPart, cBrRn, cOpis, dDatum, dValuta, nDug, nPot )

   LOCAL nDbfArea := Select()

   o_r_export_legacy()
   APPEND BLANK

   REPLACE field->idpartner WITH cIdPart
   REPLACE field->partner WITH cNazPart
   REPLACE field->brrn WITH cBrRn
   REPLACE field->opis WITH cOpis
   REPLACE field->datum WITH dDatum
   REPLACE field->valuta WITH dValuta
   REPLACE field->duguje WITH nDug
   REPLACE field->potrazuje WITH nPot

   SELECT ( nDbfArea )

   RETURN .T.


// ------------------------------------------
// vraca strukturu tabele za export
// ------------------------------------------
STATIC FUNCTION gaDbfFields()

   LOCAL aDbf := {}

   AAdd( aDbf, { "idpartner", "C", 10, 0 } )
   AAdd( aDbf, { "partner", "C", 40, 0 } )
   AAdd( aDbf, { "brrn", "C", 10, 0 } )
   AAdd( aDbf, { "opis", "C", 40, 0 } )
   AAdd( aDbf, { "datum", "D", 8, 0 } )
   AAdd( aDbf, { "valuta", "D", 8, 0 } )
   AAdd( aDbf, { "duguje", "N", 15, 5 } )
   AAdd( aDbf, { "potrazuje", "N", 15, 5 } )

   RETURN aDbf



// ---------------------------------------------------------
// linija za specifikaciju iosa
// ---------------------------------------------------------
STATIC FUNCTION _ios_spec_get_line()

   LOCAL cLine
   LOCAL _space := Space( 1 )

   cLine := "-----"
   cLine += _space
   cLine += "------"
   cLine += _space
   cLine += "------------------------------------"
   cLine += _space
   cLine += "-----"
   cLine += _space
   cLine += "-----------------"
   cLine += _space
   cLine += "---------------"
   cLine += _space
   cLine += "----------------"
   cLine += _space
   cLine += "----------------"
   cLine += _space
   cLine += "----------------"

   IF fin_dvovalutno()
      cLine += _space
      cLine += "------------"
      cLine += _space
      cLine += "------------"
      cLine += _space
      cLine += "------------"
      cLine += _space
      cLine += "------------"
   ENDIF

   RETURN cLine
