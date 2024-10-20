/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_cDelimiter
STATIC s_nRbr
STATIC s_aPartArr := {}
STATIC s_cKtoBanka := "2000   "
STATIC s_cKtoDobavljac
STATIC s_cKtoKupac
STATIC s_cKtoProvizija
STATIC s_cIdVN := "IB"


FUNCTION import_elektronsko_bankarstvo_bbi( cTxt )

   LOCAL nItems
   LOCAL cImpView
   LOCAL lRet := .T.

   IF cTxt == nil
      cTxt := ""
   ENDIF


   IF provjeri_priprema_prazna() > 0
      IF Pitanje( , "Nulirati pripremu ?", "N" ) == "D"
         open_exclusive_zap_close( "fin_pripr" )
         o_fin_pripr()
      ELSE
         MsgBeep( "Priprema mora biti prazna !#Ispraznite pripremu i ponovite proceduru." )
         RETURN .F.
      ENDIF
   ENDIF


   IF import_elba_parametri( @cTxt, @cImpView ) == 0
      MsgBeep( "Prekidam operaciju..." )
      RETURN .F.
   ENDIF

   o_fin_pripr()
   //o_nalog()


   s_cDelimiter := Chr( 9 ) // delimiter je TAB
   s_cKtoKupac := get_konto_rule_elba_c3( "KTO_KUPAC" ) // kupac konto
   s_cKtoDobavljac := get_konto_rule_elba_c3( "KTO_DOBAV" )
   s_cKtoProvizija := get_konto_rule_elba_c3( "KTO_PROVIZ" )

   IF s_cKtoProvizija == "XX"
      Alert( "podesiti parametar rules/c3: KTO_PROVIZ" )
      lRet := .F.
   ENDIF

   IF s_cKtoKupac == "XX"
      Alert( "podesiti parametar rules/c3: KTO_KUPAC" )
      lRet := .F.
   ENDIF

   IF s_cKtoDobavljac == "XX"
      Alert( "podesiti parametar rules/c3: KTO_DOBAV" )
      lRet := .F.
   ENDIF

   IF !lRet
      RETURN .F.
   ENDIF

   nItems := process_elba_items( cTxt, cImpView ) // napuni pripremu sa stavkama... iz txt

   IF nItems > 0
      MsgBeep( "Obradjeno: " + AllTrim( Str( nItems ) ) + " stavki.#Stavke se nalaze u pripremi." )
   ENDIF

   RETURN .T.

// -------------------------------------------------------
// provjerava koliko zapisa postoji u pripremi
// -------------------------------------------------------
STATIC FUNCTION provjeri_priprema_prazna()

   LOCAL nReturn := 0

   o_fin_pripr()
   SELECT fin_pripr
   nReturn := RecCount2()

   RETURN nReturn



STATIC FUNCTION import_elba_parametri( cFile, cImpView )

   LOCAL nX := 1
   LOCAL cImpOk := "D"
   LOCAL GetList := {}

   cFile := fetch_metric( "import_elba_lokacija_fajla", my_user(), my_home() + "bbi.txt" )
   cFile := PadR( cFile, 200 )
   cImpView := "D"

   Box(, 12, 77 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Parametri importa" COLOR "BG+/B"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Lokacija i naziv fajla za import:"
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 GET cFile PICT "@S70" VALID valid_file( cFile )
   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pregled importa (D/N)?" GET cImpView VALID cImpView $ "DN" PICT "@!"
   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Vrsta Naloga ?" GET s_cIdVN

   nX++
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Konto Banka ?" GET s_cKtoBanka

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Importovati podatke (D/N)?" GET cImpOk VALID cImpOk $ "DN" PICT "@!"

   READ

   BoxC()

   IF LastKey() == K_ESC .OR. cImpOk == "N"
      RETURN 0
   ENDIF

   cFile := AllTrim( cFile )
   set_metric( "import_elba_lokacija_fajla", my_user(), cFile )

   RETURN 1


STATIC FUNCTION valid_file( cFile )

   LOCAL lRet := .T.

   cFile := AllTrim( cFile )

   IF Empty( cFile )
      MsgBeep( "Lokacija i ime fajla moraju biti popunjeni !" )
      lRet := .F.
   ELSE
      IF !File( cFile )
         MsgBeep( "Ovaj fajl ne postoji !" )
         lRet := .F.
      ENDIF
   ENDIF

   RETURN lRet


// -------------------------------------------------------
// vraca matricu napunjenu stavkama iz txt fajla...
// -------------------------------------------------------
STATIC FUNCTION process_elba_items( cTxt, cImpView )

   LOCAL nItems := 0
   LOCAL aHeader := {}
   LOCAL aItem := {}
   LOCAL cTemp := ""
   LOCAL i
   LOCAL cNalBr
   LOCAL hFinItem
   LOCAL oFile


   PRIVATE GetList := {}

   s_nRbr := 0

   oFile := TFileRead():New( cTxt )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
      RETURN 0
   ENDIF

   Box( , 22, 90 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Vršim import podataka u pripremu ..." COLOR "BG+/B"

   DO WHILE oFile:MoreToRead()

      cTemp := hb_StrToUTF8( oFile:ReadLine() )

      IF Empty( cTemp )
         LOOP
      ENDIF

      aItem := TokToNiz( cTemp, s_cDelimiter )
      IF Len( aItem ) == 3

         aHeader := aItem
         @ box_x_koord() + 4, box_y_koord() + 2 SAY "Izvod broj: " + PadL( aHeader[ 1 ], 8, "0" )
         LOOP
      ENDIF



      hFinItem := get_elba_stavka_from_txt( @aItem )
      // hFinItem[ "brnal" ] := PadL( aHeader[ 1 ], 8, "0" )
      hFinItem[ "brnal" ]  := PadL( 0, 8, "0" )
      hFinItem[ "brdok" ] := aHeader[ 1 ] // broj izvoda
      hFinItem[ "idvn" ] := s_cIdVN

      IF !put_elba_item_into_pripr( hFinItem, cImpView )
         EXIT
      ENDIF

      ++nItems
      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( "", 60 ) COLOR "BG+/B"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "stavka " + AllTrim( Str( nItems ) ) COLOR "BG+/B"

   ENDDO

   oFile:Close()


   SELECT fin_pripr // sada uzmi pravi broj naloga i broj veze
   SET ORDER TO TAG "0"
   GO TOP

/*
   my_flock()

   DO WHILE !Eof()
      REPLACE brnal WITH __nalbr
      REPLACE brdok WITH __nalbr
      SKIP
   ENDDO

   my_unlock()
*/

   SET ORDER TO TAG "1"
   GO TOP

   BoxC()

   RETURN nItems


STATIC FUNCTION get_elba_stavka_from_txt( aItem )

   LOCAL nItemLen := Len( aItem )
   LOCAL hRet := hb_Hash()
   LOCAL nSeek

   // 1 01.01.2015 05.01.2015
      /*
        1) +
        2) 05.01.2015 00:00:00
        3) 5126150056584993
        4) 500251
        5) 161
        6) 1610000030010065
        7) ZINNS DOO SARAJEVO DOBOJSKA 5171000NOVO SARAJEVO 033 523443
        8 UPLATA RACUNA
        9) BAM
       10) 126.36
       */



   hRet[ "idfirma" ] := self_organizacija_id()
   hRet[ "transakcija" ] := aItem[ 1 ]
   hRet[ "datdok" ] := elba_fix_dat_var( aItem[ 2 ] )


   IF  Len( aItem ) == 11 .AND. "BBI DD" $ aItem[ 8 ] // bbi naknade

      // - 2-31.08.2015 3-1112152438185842000003 4-IZ 5-169363885
      // 0 -  8-BBI DD Sarajevo  9-Naplata mjesecne naknade za vodenje racuna 10-J 11-8.00
      hRet[ "banka" ] := "0"
      hRet[ "partner_opis" ] := aItem[ 8 ]
      hRet[ "opis" ] := aItem[ 9 ]
      hRet[ "iznos" ] := Val( aItem[ 11 ] )

   ELSEIF  Len( aItem ) == 12 // bbi standardna transakcija

      // + 2-26.08.2015 3-1112152383794710000004 4-IZ 5-169331203
      // 0 - 8-3383202251226837 9-RASMER PRIVREDNO DRUSTVO ZA TRGOV INU NA VELIKO I MALO EXPORT IMPORT I USLUGE D.O.O. SARAJEVO, KAME
      // 10-UPL RN
      // 11-J 12-122.85

      hRet[ "banka" ] := aItem[ 8 ]
      hRet[ "partner_opis" ] := aItem[ 9 ]
      hRet[ "opis" ] := aItem[ 10 ]
      hRet[ "iznos" ] := Val( aItem[ 12 ] )

   ELSEIF Len( aItem ) == 10 // sberbank standardna transakcija

      hRet[ "banka" ] := aItem[ 6 ]
      hRet[ "partner_opis" ] := aItem[ 7 ]
      hRet[ "opis" ] := aItem[ 8 ]
      hRet[ "iznos" ] := Val( aItem[ 10 ] )


   ELSEIF Len( aItem ) == 9 .AND. "Naplata mjese" $ aItem[ 7 ]  // sberbank mjesecna naknada

      // - 31.01.2015 00:00:00 1130150308098652000003 160331
      // 140  Sberbank BH d.d. Sarajevo Naplata mjesečne naknade za vođenje računa BAM 14.9

      hRet[ "banka" ] := "0"
      hRet[ "partner_opis" ] := aItem[ 6 ]
      hRet[ "opis" ] := aItem[ 7 ]
      hRet[ "iznos" ] := Val( aItem[ 9 ] )

   ELSEIF Len( aItem ) == 8 .AND. "POVRAT NALOGA" $ aItem[ 6 ] // sberbank

      // + 25.05.2015 00:00:00 1150151454178865000002 500251
      // Sberbank BH d.d. Sarajevo 6-POVRAT NALOGA 5149151429905196-POGR ESNA VRSTA PRIHODA BAM 8-150

      hRet[ "banka" ] := "1"
      hRet[ "partner" ] := "POVRAT"
      hRet[ "partner_opis" ] := aItem[ 5 ]
      hRet[ "opis" ] := aItem[ 6 ]
      hRet[ "iznos" ] := Val( aItem[ 8 ] )

   ELSE
      Pitanje(, "Zapis neispravan. Zaistaviti obradu ?", " " )
      Alert( "Format zapisa nerazumljiv : " + pp( aItem ) )
      RETURN .F.
   ENDIF



   IF "Provizija  banke za realizaciju naloga sa brojem" $ hRet[ "opis" ] .OR. hRet[ "banka" ] == "0"
      hRet[ "partner" ] := "PROVIZIJA"
   ELSE
      hRet[ "partner" ] := get_partner_by_banka( hRet[ "banka" ] )
   ENDIF


   // IF Empty( hRet[ "partner" ] )
   // hRet[ "partner" ] := get_partner_by_elba_partner_opis( hRet[ "partner_opis" ] )
   // ENDIF

   IF Empty( hRet[ "partner" ] )

      Msgbeep( "Nepostojeći partner !#Opis: " + PadR( hRet[ "partner_opis" ], 50 ) )
      hRet[ "partner" ] := PadR( hRet[ "partner_opis" ], 3 ) + ".."

      IF Pitanje( PadR( hRet[ "opis" ], 70 ), PadR( "TRAŽITI " + hRet[ "partner_opis" ] + " -> " +  hRet[ "partner" ], 80 ), " " ) == "D"
         p_partner( @hRet[ "partner" ] )
         IF Pitanje( , "SET " + hRet[ "partner_opis" ] + " -> " +  hRet[ "partner" ], "D" ) == "D"
            set_banku_za_partnera( hRet[ "partner" ], hRet[ "banka" ] )
         ENDIF
      ENDIF

   ENDIF


   IF hRet[ "partner" ] != "PROVIZIJA"
      nSeek := AScan( s_aPartArr, {| xVal | xVal[ 2 ] == hRet[ "partner" ] } )

      IF nSeek == 0
         AAdd( s_aPartArr, { hRet[ "partner_opis" ], hRet[ "partner" ] } )
      ENDIF
   ENDIF

   IF hRet[ "transakcija" ] == "+"
      hRet[ "d_p" ] := "2"
      hRet[ "konto" ] := s_cKtoKupac
   ELSE

      hRet[ "d_p" ] := "1"
      IF hRet[ "partner" ] == "PROVIZIJA"
         hRet[ "konto" ] := s_cKtoProvizija
         hRet[ "partner" ] := ""
      ELSE
         hRet[ "konto" ] := s_cKtoDobavljac
      ENDIF

   ENDIF

   RETURN hRet



STATIC FUNCTION put_elba_item_into_pripr( hFinItem, cImpView )

   LOCAL cFirma
   LOCAL cBrNal
   LOCAL cDP

   LOCAL nCurr := 1

/*
   cPartRule := rule_get_partner_na_osnovu_konta( cKonto )
   IF !Empty( cPartRule ) .AND. AllTrim( cPartRule ) <> "XX" // i postavi to kao partnera za ovu stavku
      cPartner := cPartRule
   ENDIF
*/

   ++s_nRbr



   hFinItem[ "opis" ] := PadR( hFinItem[ "opis" ], 100 )
   hFinItem[ "brdok" ] := PadR( hFinItem[ "brdok" ], 10 )

   IF cImpView == "D"

      @ box_x_koord() + 4, box_y_koord() + 30 SAY "Banka: "
      @ box_x_koord() + 4, Col() + 2 SAY hFinItem[ "banka" ]

      @ box_x_koord() + 6, box_y_koord() + 2 SAY Space( 70 )
      @ box_x_koord() + 6, box_y_koord() + 2 SAY PadR( hFinItem[ "partner_opis" ], 45 ) + " -> partner: " ;
         GET hFinItem[ "partner" ] ;
         WHEN hFinItem[ "konto" ] != s_cKtoProvizija ; // ako je konto provizije onda se nema sta gledati partner
         VALID postoji_partner( hFinItem[ "partner" ], hFinItem[ "partner_opis" ] ) .AND. p_partner( @hFinItem[ "partner" ] )

      @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "datum knjiženja:" GET hFinItem[ "datdok" ]
      @ box_x_koord() + 7, Col() + 2 SAY8 "broj veze:" GET hFinItem[ "brdok" ]
      @ box_x_koord() + 8, box_y_koord() + 2 SAY8 "opis knjiženja:" GET hFinItem[ "opis" ] PICT "@S60"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY Replicate( "=", 60 )


      @ box_x_koord() + 11, box_y_koord() + 2 SAY PadR( "Rbr.stavke:", 20 ) GET s_nRbr PICT "999"
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "dug/pot:" GET hFinItem[ "d_p" ]
      @ box_x_koord() + 12, Col() + 2 SAY "konto:" GET hFinItem[ "konto" ]
      @ box_x_koord() + 12, Col() + 2 SAY PadR( "IZNOS STAVKE:", 20, 20 ) GET hFinItem[ "iznos" ] PICT "9999999.99"

      IF LastKey() <> K_ESC
         READ
      ELSE
         RETURN .F.
      ENDIF

   ENDIF

   SELECT fin_pripr
   APPEND BLANK

   RREPLACE field->idfirma WITH hFinItem[ "idfirma" ], ;
      field->idvn WITH hFinItem[ "idvn" ], ;
      field->brnal WITH hFinItem[ "brnal" ], ;
      field->brdok WITH hFinItem[ "brdok" ], ;
      field->opis WITH Trim( hFinItem[ "opis" ] ) + " / " + hFinItem[ "partner_opis" ], ;
      field->rbr WITH s_nRbr, ;
      field->datdok WITH hFinItem[ "datdok" ], ;
      field->idkonto WITH hFinItem[ "konto" ], ;
      field->idpartner WITH hFinItem[ "partner" ], ;
      field->d_p WITH hFinItem[ "d_p" ], ;
      field->iznosbhd WITH hFinItem[ "iznos" ]


   ++s_nRbr


   hFinItem[ "konto" ] := s_cKtoBanka


   SELECT fin_pripr
   APPEND BLANK

   RREPLACE field->idfirma WITH hFinItem[ "idfirma" ], ;
      field->idvn WITH hFinItem[ "idvn" ], ;
      field->brnal WITH hFinItem[ "brnal" ], ;
      field->brdok WITH hFinItem[ "brdok" ], ;
      field->opis WITH Trim( hFinItem[ "opis" ] ) + " / " + hFinItem[ "partner_opis" ], ;
      field->rbr WITH s_nRbr, ;
      field->datdok WITH hFinItem[ "datdok" ], ;
      field->idkonto WITH hFinItem[ "konto" ], ;
      field->idpartner WITH "", ;
      field->d_p WITH iif( hFinItem[ "d_p" ] == "1", "2", "1" ), ;
      field->iznosbhd WITH hFinItem[ "iznos" ]

   RETURN .T.



STATIC FUNCTION elba_fix_dat_var( cDate )

   LOCAL dDate

   dDate := CToD( Left( cDate, 10 ) ) // 05.01.2015 00:00:00

   RETURN dDate


FUNCTION postoji_partner( cIdPartner, cPartnerOpis )

   LOCAL lRet

   PushWA()
   select_o_partner( cIdPartner )

   lRet := Found()
   PopWA()


   IF !lRet .AND. Pitanje( "#" + cPartnerOpis, "Nepostojeći partner " + cIdPartner + " ! Ručno podesiti? ", "N" ) == "D"
      RETURN .T.
   ENDIF

   RETURN  lRet





STATIC FUNCTION get_konto_prema_opisu( cTrans, cOpis )

   LOCAL cKonto := "?????"
   LOCAL cKtoKup := s_cKontoKupac

   IF "NR" $ cOpis
      cKonto := get_konto_rule_elba_c3( "KT_UPLATA", "NR" )
      RETURN cKonto

   ELSEIF "PRK" $ cOpis
      cKonto := get_konto_rule_elba_c3( "KTO_UPLATA", "PRK" )
      RETURN cKonto

   ENDIF

   // ako je uplata na nas racun onda je to KUPAC 2120
   IF AllTrim( cTrans ) == "+"
      cKonto := cKtoKup
      RETURN cKonto
   ENDIF


   IF AllTrim( cTrans ) == "-"

      DO CASE

      CASE "PROVIZIJA" $ Upper( cOpis )
         cKonto := get_konto_rule_elba_c3( "KTO_UPLATA", "PROVIZIJA" )

      CASE "PDV" $ cOpis
         cKonto := get_konto_rule_elba_c3( "KTO_UPLATA", "PDV" )

      OTHERWISE
         cKonto := get_konto_rule_elba_c3( "KTO_UPLATA" )
      ENDCASE

   ENDIF

   RETURN cKonto



STATIC FUNCTION get_partnera( cTrType, cTxt, cTrRN )

   LOCAL nSeek

   cTxt := KonvZnWin( cTxt )


   IF AllTrim( cTrRN ) $ "#PRK#NR#"
      RETURN ""
   ENDIF


   nSeek := AScan( s_aPartArr, {| xVal | xVal[ 1 ] == cTxt } ) // pokusaj pronaci po matrici

   IF nSeek <> 0
      RETURN s_aPartArr[ nSeek, 2 ]  // nasao sam ga u matrici
   ENDIF

   IF AllTrim( cTrType ) == "+"
      get_partnera_za_uplate( cTxt ) // trazi partnera za uplate na zr

   ELSEIF AllTrim( cTrType ) == "-"

      get_partner_za_isplate_sa_zr( cTxt, cTrRN ) // trazi partnera za isplate sa zr
   ENDIF

   RETURN .T.


// -----------------------------------------------
// vraca id partnera za uplate na zr
// -----------------------------------------------
STATIC FUNCTION get_partnera_za_uplate( cTxt )

   LOCAL nTArea := Select()
   LOCAL cDesc := ""
   LOCAL cBank := ""
   LOCAL cPartnId := "?????"
   LOCAL nSeek

   IF Left( cTxt, 1 ) == "/"  // uzmi banku i opis ako postoji "/"

      cDesc := AllTrim( SubStr( cTxt, 18, Len( cTxt ) ) )
      cBank := AllTrim( SubStr( cTxt, 2, 16 ) )

   ELSE
      cDesc := AllTrim( cTxt )

   ENDIF

   SELECT ( nTArea )

   RETURN cPartnId


STATIC FUNCTION get_partner_za_isplate_sa_zr( cTxt, cTrRN )

   LOCAL nTArea := Select()
   LOCAL cDesc := ""
   LOCAL cBank := ""
   LOCAL cPartnId := "?????"
   LOCAL nSeek

   IF Left( cTxt, 1 ) == "/" // uzmi banku i opis ako postoji "/"
      cDesc := AllTrim( SubStr( cTxt, 18, Len( cTxt ) ) )
   ELSE
      cDesc := AllTrim( cTxt )
   ENDIF

   cPartnId := get_partner_by_banka( cTrRN )

   IF Empty( cPartnId )

      cPartnId := get_partner_by_elba_partner_opis( cDesc )

      Msgbeep( "Nepostojeći partner !#Opis: " + PadR( cTxt, 50 ) + "#" + "trans.rn: " + cTrRN )

      cPartnId := PadR( cDesc, 4 )

      p_partner( @cPartnId )

      set_banku_za_partnera( cPartnId, cTrRN )

   ENDIF


   nSeek := AScan( s_aPartArr, {| xVal | xVal[ 2 ] == cPartnId } )

   IF nSeek == 0
      AAdd( s_aPartArr, { cTxt, cPartnId } )
   ENDIF

   SELECT ( nTArea )

   RETURN cPartnId




STATIC FUNCTION set_banku_za_partnera( cIdPartner, cBank )

   LOCAL cRead := ""
   LOCAL cOldBank
   LOCAL cNewBank

   IF Empty( cBank )
      RETURN .F.
   ENDIF

   PushWA()
   //o_sifk()
   //o_sifv()

   cNewBank := ""
   cOldBank := AllTrim( get_partn_sifk_sifv( "BANK", cIdPartner ) )  // stara banka

   IF !Empty( cOldBank ) // dodaj staru banku ako postoji
      cNewBank += cOldBank
      IF Right( cNewBank, 1 ) <> ","  // dodaj i , posto je potrebno
         cNewBank += ","
      ENDIF
   ENDIF

   cNewBank += cBank

   USifK( "PARTN", "BANK", cIdPartner, cNewBank )

   PopWA()

   RETURN .T.



STATIC FUNCTION get_partner_by_banka( cBanka )

   LOCAL cIdPartner := ""

   o_partner()
   IF ImaUSifv( "PARTN", "BANK", cBanka, @cIdPartner )
      RETURN PadR( cIdPartner, 6 )
   ENDIF

   RETURN Space( 6 )



STATIC FUNCTION get_partner_by_elba_partner_opis( cDesc )

   LOCAL aTemp
   LOCAL cTemp := ""
   LOCAL cPartner := ""

   IF Empty( cDesc )
      RETURN cPartner
   ENDIF

   aTemp := TokToNiz( cDesc, " " )

   IF Len( aTemp ) > 1
      cTemp := AllTrim( aTemp[ 1 ] )

      IF Len( cTemp ) < 4
         cTemp += " " + AllTrim( aTemp[ 2 ] )
      ENDIF

   ELSE
      cTemp := AllTrim( aTemp[ 1 ] )

   ENDIF

   find_partner_by_naz_or_id( cTemp )

   IF RecCount() == "1"
      cPartner := partn->id
   ENDIF

   RETURN cPartner



FUNCTION get_konto_rule_elba_c3( cCond, cPartner )

   LOCAL cObj := "ELBA_IMPORT"
   LOCAL cMod := programski_modul()
   LOCAL cKonto := "XX"

   PushWA()
   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "OBJC3"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c3( cCond )

   IF cPartner == nil
      cPartner := ""
   ENDIF

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) ;
         .AND. field->rule_obj == get_rule_field_obj( cObj ) ;
         .AND. field->rule_c3 == get_rule_field_c3( cCond )

      IF Empty( cPartner )

         IF Empty( field->rule_c5 )
            cKonto := PadR( field->rule_c6, 7 )
            EXIT
         ENDIF

      ELSE

         IF AllTrim( cPartner ) == AllTrim( field->rule_c5 )
            cKonto := PadR( field->rule_c6, 7 )
            EXIT
         ENDIF

      ENDIF

      SKIP
   ENDDO

   PopWa()

   RETURN cKonto


/*
FUNCTION rule_get_partner_na_osnovu_konta( cKonto )

   LOCAL cObj := "ELBA_IMPORT"
   LOCAL cMod := programski_modul()
   LOCAL cCond := "KTO_PARTN"
   LOCAL cPartn := ""

   PushWA()
   O_RULES
   SELECT fmkrules
   SET ORDER TO TAG "OBJC3"
   GO TOP

   SEEK get_rule_field_mod( cMod ) + get_rule_field_obj( cObj ) + get_rule_field_c3( cCond )

   DO WHILE !Eof() .AND. field->modul_name == get_rule_field_mod( cMod ) .AND. ;
         field->rule_obj == get_rule_field_obj( cObj ) .AND. ;
         field->rule_c3 == get_rule_field_c3( cCond )

      IF AllTrim( cKonto ) == AllTrim( field->rule_c6 )
         cPartn := PadR( field->rule_c5, 6 )
         EXIT
      ENDIF
      SKIP

   ENDDO

   PopWA()

   RETURN cPartn
*/
