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

STATIC s_cRazmak1 := " "
STATIC s_cZahtjevNula := "0"

FUNCTION fiskalni_tremol_racun( hFiskalniParams, aRacunStavke, aRacunHeader, lStornoRacun )

   LOCAL cFiskalniRacunBroj, cVrstaPlacanja, nTotalPlac, cXml, nI
   LOCAL nKolicina, nCijena, nPopust
   LOCAL cArtikalId, cArtikalNaz, cArtikalJmj, cTmp, cArtikalBarkod, cArtikalPLU, cOdjeljenje, cArtikalTarifa
   LOCAL lKupacNaRacunu := .F.
   LOCAL cCommand := ""
   LOCAL cKupacId, cKupacIme, cKupacAdresa, cKupacGrad
   LOCAL cFiscTxt, cFiskRefundTxt, cFiskKupacTxt, cFiskalniFajlName
   LOCAL cOutput

   tremol_delete_tmp( hFiskalniParams )  // pobrisi tmp fajlove i ostalo sto je u input direktoriju

   IF aRacunHeader <> NIL .AND. Len( aRacunHeader ) > 0  // ima podataka kupca
      lKupacNaRacunu := .T.
   ENDIF

   cFiskalniRacunBroj := aRacunStavke[ 1, FISK_INDEX_BRDOK ]
   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], cFiskalniRacunBroj )
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName // putanja do izlaznog xml fajla

   create_xml( cXml )
   cOutput := xml_head()

   cFiscTxt := 'TremolFpServer Command="Receipt"'
   cFiskRefundTxt := ''
   cFiskKupacTxt := ''

   IF lStornoRacun // ukljuci storno triger
      cFiskRefundTxt := ' RefundReceipt="' + AllTrim( aRacunStavke[ 1, FISK_INDEX_FISK_RACUN_STORNIRATI ] ) + '"'
   ENDIF

   // ukljuci kupac triger
   IF lKupacNaRacunu
      cKupacId := AllTrim( aRacunHeader[ 1, FISK_HEADER_INDEX_KUPAC_ID ] )
      cKupacIme := to_xml_encoding( AllTrim( aRacunHeader[ 1, FISK_HEADER_INDEX_KUPAC_NAZIV ] ) )
      cKupacAdresa := to_xml_encoding( AllTrim( aRacunHeader[ 1, FISK_HEADER_INDEX_KUPAC_ADRESA ] ) )
      cKupacGrad := to_xml_encoding( AllTrim( aRacunHeader[ 1, FISK_HEADER_INDEX_KUPAC_GRAD ] ) )
      cFiskKupacTxt += s_cRazmak1 + 'CompanyID="' + cKupacId + '"'
      cFiskKupacTxt += s_cRazmak1 + 'CompanyName="' + cKupacIme + '"'
      cFiskKupacTxt += s_cRazmak1 + 'CompanyHQ="' + cKupacGrad + '"'
      cFiskKupacTxt += s_cRazmak1 + 'CompanyAddress="' + cKupacAdresa + '"'
      cFiskKupacTxt += s_cRazmak1 + 'CompanyCity="' + cKupacGrad + '"'
   ENDIF

   cOutput += xml_subnode( cFiscTxt + cFiskRefundTxt + cFiskKupacTxt )

   nTotalPlac := 0
   FOR nI := 1 TO Len( aRacunStavke )
      cArtikalPLU := aRacunStavke[ nI, FISK_INDEX_PLU ]
      cArtikalBarkod := aRacunStavke[ nI, FISK_INDEX_BARKOD ]
      cArtikalId := aRacunStavke[ nI, FISK_INDEX_IDROBA ]
      cArtikalNaz := aRacunStavke[ nI, FISK_INDEX_ROBANAZIV ]
      cArtikalJmj := fisk_tremol_jmj( aRacunStavke[ nI, FISK_INDEX_JMJ ] )
      nCijena := aRacunStavke[ nI, FISK_INDEX_CIJENA ]
      nKolicina := aRacunStavke[ nI, FISK_INDEX_KOLICINA ]
      nPopust := aRacunStavke[ nI, FISK_INDEX_POPUST ]
      cArtikalTarifa := fiskalni_tarifa( aRacunStavke[ nI, FISK_INDEX_TARIFA ], hFiskalniParams[ "pdv" ], "TREMOL" )
      cOdjeljenje := "1"
      cTmp := ""
      cTmp += s_cRazmak1 + 'Description="' + to_xml_encoding( cArtikalNaz ) + '"'
      cTmp += s_cRazmak1 + 'Quantity="' + AllTrim( Str( nKolicina, 12, 3 ) ) + '"'
      cTmp += s_cRazmak1 + 'Price="' + AllTrim( Str( nCijena, 12, 2 ) ) + '"'
      cTmp += s_cRazmak1 + 'VatInfo="' + cArtikalTarifa + '"'
      cTmp += s_cRazmak1 + 'Department="' + cOdjeljenje + '"'
      cTmp += s_cRazmak1 + 'UnitName="' + cArtikalJmj + '"'
      IF nPopust > 0
         cTmp += s_cRazmak1 + 'Discount="' + AllTrim( Str( nPopust, 12, 2 ) ) + '%"'
      ENDIF
      cOutput += xml_single_node( "Item", cTmp )
   NEXT

   // vrste placanja, oznaka:
   // "GOTOVINA"
   // "CEK"
   // "VIRMAN"
   // "KARTICA"

   cVrstaPlacanja := fiskalni_vrsta_placanja( aRacunStavke[ 1, FISK_INDEX_VRSTA_PLACANJA ], "TREMOL" )
   nTotalPlac := aRacunStavke[ 1, FISK_INDEX_TOTAL ]

   IF aRacunStavke[ 1, FISK_INDEX_VRSTA_PLACANJA ] <> "0" .AND. !lStornoRacun
      cTmp := 'Type="' + cVrstaPlacanja + '"'
      cTmp += s_cRazmak1 + 'Amount="' + AllTrim( Str( nTotalPlac, 12, 2 ) ) + '"'
      xml_single_node( "Payment", cTmp )
   ENDIF

   // dodatna linija, broj veznog racuna u POS
   cTmp := 'Message="Vezni racun: ' + AllTrim( cFiskalniRacunBroj ) + '"'
   cOutput += xml_single_node( "AdditionalLine", cTmp )
   cOutput += xml_subnode( "TremolFpServer", .T. )
   close_xml()

   log_write_file( "FISC_RN:" + cOutput, 2 )

   RETURN 0


FUNCTION tremol_restart( hFiskalniParams )

   LOCAL cScreen
   LOCAL cScript
   LOCAL nErrorLevel

   IF hFiskalniParams[ "restart_service" ] == "N"
      RETURN .F.
   ENDIF

   cScript := "start " + EXEPATH + "fp_rest.bat"

   SAVE SCREEN TO cScreen
   CLEAR SCREEN

   ? "Restartujem server..."
   nErrorLevel := f18_run( cScript )

   RESTORE SCREEN FROM cScreen

   RETURN nErrorLevel


FUNCTION tremol_delete_tmp( hFiskParams )

   LOCAL cTmp
   LOCAL _f_path

   MsgO( "brisem tmp fajlove..." )

   _f_path := hFiskParams[ "out_dir" ]
   cTmp := "*.*"

   AEval( Directory( _f_path + cTmp ), {| aFile | FErase( _f_path + ;
      AllTrim( aFile[ 1 ] ) ) } )
   Sleep( 1 )

   MsgC()

   RETURN .T.




FUNCTION tremol_polog( hFiskalniParams, AUTO )

   LOCAL cXml
   LOCAL nErrorLevel := 0
   LOCAL cCommand := ""
   LOCAL cFiskalniFajlName
   LOCAL nValue := 0
   LOCAL GetList := {}

   IF AUTO == NIL
      AUTO := .F.
   ENDIF

   IF AUTO
      nValue := hFiskalniParams[ "auto_avans" ]
   ENDIF

   IF nValue == 0

      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unosim polog od:" GET nValue PICT "9999999.99"
      READ
      BoxC()

      IF LastKey() == K_ESC .OR. nValue = 0
         RETURN .F.
      ENDIF

   ENDIF

   IF nValue < 0
      // polog komanda
      cCommand := 'Command="CashOut"'
   ELSE
      // polog komanda
      cCommand := 'Command="CashIn"'
   ENDIF

   // izlazni fajl
   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula )

   // putanja do izlaznog xml fajla
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName

   create_xml( cXml )
   xml_head()
   xml_subnode( "TremolFpServer " + cCommand )

   cCommand := 'Amount="' +  AllTrim( Str( Abs( nValue ), 12, 2 ) ) + '"'

   xml_single_node( "Cash", cCommand )
   xml_subnode( "/TremolFpServer" )

   close_xml()

   RETURN nErrorLevel



FUNCTION tremol_reset_plu_artikla( hFiskalniParams )

   LOCAL cXml, cFiskalniFajlName
   LOCAL nErrorLevel := 0
   LOCAL cCommand

   IF !spec_funkcije_sifra( "RPLU" )
      RETURN 0
   ENDIF

   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula )

   // putanja do izlaznog xml fajla
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName

   create_xml( cXml )
   xml_head()

   cCommand := 'Command="DirectIO"'

   xml_subnode( "TremolFpServer " + cCommand )
   cCommand := 'Command="1"'
   cCommand += s_cRazmak1 + 'Data="0"'
   cCommand += s_cRazmak1 + 'Object="K00000;F142HZ              ;0;$"'

   xml_single_node( "DirectIO", cCommand )
   xml_subnode( "/TremolFpServer" )

   close_xml()

   IF tremol_cekam_fajl_odgovora( hFiskalniParams, cFiskalniFajlName )
      nErrorLevel := tremol_read_error( hFiskalniParams, cFiskalniFajlName )
   ENDIF

   RETURN nErrorLevel



FUNCTION tremol_komanda( hFiskalniParams, cmd )

   LOCAL cXml
   LOCAL nErrorLevel
   LOCAL cFiskalniFajlName

   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula )

   // putanja do izlaznog xml fajla
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName

   create_xml( cXml )
   xml_head()
   xml_subnode( "TremolFpServer " + cmd )

   close_xml()

   IF tremol_cekam_fajl_odgovora( hFiskalniParams, cFiskalniFajlName )
      nErrorLevel := tremol_read_error( hFiskalniParams, cFiskalniFajlName )
   ELSE
      nErrorLevel := FISK_NEMA_ODGOVORA
   ENDIF

   RETURN nErrorLevel



STATIC FUNCTION fisk_tremol_jmj( cJmj )

   LOCAL cRet := ""

   DO CASE

   CASE Upper( AllTrim( cJmj ) ) = "LIT"
      cRet := "l"
   CASE Upper( AllTrim( cJmj ) ) = "GR"
      cRet := "g"
   CASE Upper( AllTrim( cJmj ) ) = "KG"
      cRet := "kg"

   ENDCASE

   RETURN cRet



// -----------------------------------------------------
// ItemZ
// -----------------------------------------------------
FUNCTION tremol_z_item( hFiskParams )

   LOCAL cCommand, nErrorLevel

   cCommand := 'Command="Report" Type="ItemZ" /'
   nErrorLevel := tremol_komanda( hFiskParams, cCommand )

   RETURN nErrorLevel


// -----------------------------------------------------
// ItemX
// -----------------------------------------------------
FUNCTION tremol_x_item( hFiskParams )

   LOCAL cCommand, nErrorLevel

   cCommand := 'Command="Report" Type="ItemX" /'
   nErrorLevel := tremol_komanda( hFiskParams, cCommand )

   RETURN nErrorLevel


// -----------------------------------------------------
// dnevni fiskalni izvjestaj
// -----------------------------------------------------
FUNCTION tremol_z_rpt( hFiskParams )

   LOCAL cCommand
   LOCAL nErrorLevel
   LOCAL cParamDate, cParamTime
   LOCAL _rpt_type := "Z"

   IF Pitanje(, "Štampati dnevni izvjestaj", "D" ) == "N"
      RETURN .F.
   ENDIF

   cParamDate := "zadnji_" + _rpt_type + "_izvjestaj_datum"
   cParamTime := "zadnji_" + _rpt_type + "_izvjestaj_vrijeme"

   // iscitaj zadnje formirane izvjestaje...
   _last_date := fetch_metric( cParamDate, NIL, CToD( "" ) )
   _last_time := PadR( fetch_metric( cParamTime, NIL, "" ), 5 )

   IF Date() == _last_date
      MsgBeep( "Zadnji dnevni izvjestaj radjen " + DToC( _last_date ) + " u " + _last_time )
   ENDIF

   cCommand := 'Command="Report" Type="DailyZ" /'
   nErrorLevel := tremol_komanda( hFiskParams, cCommand )

   // upisi zadnji dnevni izvjestaj
   set_metric( cParamDate, NIL, Date() )
   set_metric( cParamTime, NIL, Time() )

   // ako se koristi opcija automatskog pologa
   IF hFiskParams[ "auto_avans" ] > 0

      MsgO( "Automatski unos pologa u uredjaj... sacekajte." )

      // daj mi malo prostora
      Sleep( 10 )

      // pozovi opciju pologa
      nErrorLevel := tremol_polog( hFiskParams, .T. )

      MsgC()

   ENDIF

   RETURN nErrorLevel


// -----------------------------------------------------
// presjek stanja
// -----------------------------------------------------
FUNCTION tremol_x_rpt( hFiskParams )

   LOCAL cCommand
   LOCAL nErrorLevel

   cCommand := 'Command="Report" Type="DailyX" /'
   nErrorLevel := tremol_komanda( hFiskParams, cCommand )

   RETURN .T.


// -----------------------------------------------------
// periodicni izvjestaj
// -----------------------------------------------------
FUNCTION tremol_per_rpt( hFiskParams )

   LOCAL cCommand, nErrorLevel
   LOCAL _start
   LOCAL _end
   LOCAL _date_start := Date() - 30
   LOCAL _date_end := Date()
   LOCAL GetList := {}

   IF Pitanje(, "Štampati periodicni izvjestaj", "D" ) == "N"
      RETURN .F.
   ENDIF

   Box(, 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Od datuma:" GET _date_start
   @ box_x_koord() + 1, Col() + 1 SAY "do datuma:" GET _date_end
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // 2010-10-01 : YYYY-MM-DD je format datuma
   _start := tremol_fix_xml_date( _date_start )
   _end := tremol_fix_xml_date( _date_end )

   cCommand := 'Command="Report" Type="Date" Start="' + _start + ;
      '" End="' + _end + '" /'

   nErrorLevel := tremol_komanda( hFiskParams, cCommand )

   RETURN nErrorLevel


FUNCTION tremol_stampa_kopije_racuna( hFiskalniParams )

   LOCAL cCommand
   LOCAL cFiskalniRacunBroj := Space( 10 )
   LOCAL cRefundDN := "N"
   LOCAL nErrorLevel
   LOCAL GetList := {}

   // box - daj broj racuna
   Box(, 2, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj računa:" GET cFiskalniRacunBroj ;
      VALID !Empty( cFiskalniRacunBroj )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "račun je reklamirani (D/N)?" GET cRefundDN VALID cRefundDN $ "DN" PICT "@!"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // <TremolFpServer Command="PrintDuplicate" Type="0" Document="2"/>

   cCommand := 'Command="PrintDuplicate"'

   IF cRefundDN == "N"
      // obicni racun
      cCommand += s_cRazmak1 + 'Type="0"'
   ELSE
      // reklamni racun
      cCommand += s_cRazmak1 + 'Type="1"'
   ENDIF

   cCommand += s_cRazmak1 + 'Document="' +  AllTrim( cFiskalniRacunBroj ) + '" /'
   nErrorLevel := tremol_komanda( hFiskalniParams, cCommand )

   RETURN nErrorLevel



FUNCTION tremol_cekam_fajl_odgovora( hFiskalniParams, cFajl, nTimeOut )

   LOCAL cTmp
   LOCAL nTime
   LOCAL nCount := 0
   LOCAL cStatus
   LOCAL cMsg
   LOCAL cDN := " "
   LOCAL GetList := ""
   LOCAL nBroj

   IF nTimeOut == NIL
      nTimeOut := hFiskalniParams[ "timeout" ]
   ENDIF

   cTmp := hFiskalniParams[ "out_dir" ] + StrTran( cFajl, "xml", "out" )

   DO WHILE .T.  // loop za izmjenu trake

      nTime := nTimeOut
      Box( "#<ALT-Q> Prekid", 5, 60 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Uredjaj ID: " + AllTrim( Str( hFiskalniParams[ "id" ] ) ) + ;
         " : " + PadR( hFiskalniParams[ "name" ], 40 )

      cStatus := "CEKAM"
      DO WHILE nTime > 0

         --nTime
         IF nTime = ( nTimeOut * 0.7 ) .AND. nCount = + 0 // provjeri kada bude trecina vremena...
            IF hFiskalniParams[ "restart_service" ] == "D" .AND. Pitanje(, "Restartovati server", "D" ) == "D"
               tremol_restart( hFiskalniParams ) // pokreni restart proceduru
               nTime := nTimeOut // restartuj vrijeme
               ++nCount
            ENDIF

         ENDIF

         IF File( cTmp ) // fajl se pojavio - izadji iz petlje !
            cStatus := "FAJL"
            EXIT
         ENDIF

         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 PadR( "TREMOL: Čekam odgovor... " + AllTrim( Str( nTime ) ), 48 )
         IF nTime == 0
            cStatus := "TIMEOUT"
            log_write_file("FISK_RN_ERROR: TIMEOUT isteklo", 2)
            EXIT
         ENDIF

         IF LastKey() == K_ALT_Q
            cStatus := "ALTQ"
            log_write_file("FISK_RN_ERROR: ALTQ - prekid", 2)
            EXIT
         ENDIF
         Sleep( 1 )

      ENDDO
      BoxC()

      IF cStatus == "FAJL"
         EXIT
      ELSE
         IF Pitanje(, "Nestalo je trake? Ako vršite zamjenu odgovorite sa 'D'", " " ) == "D"
            log_write_file("FISK_RN_ERROR: nestalo trake = D - ceka se zamjena", 2)
            LOOP
         ELSE
            log_write_file("FISK_RN_ERROR: nije nestalo trake", 2)
            EXIT
         ENDIF
      ENDIF

   ENDDO

   IF cStatus != "FAJL"
      cMsg := "TREMOL: Ne postoji fajl odgovora (OUT) ?!"
      MsgBeep( cMsg )
      log_write_file("FISK_RN_ERROR: " + cMsg, 2)

      Box("#FISK_RN", 3, 60)
          @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Da li je fiskalni račun ipak odštampan kupcu (D/N) ?" GET cDN PICT "@!" VALID cDN $ "DN"
          READ
          IF LastKey() == K_ESC .OR. cDN == "N"
             BoxC()
             log_write_file( "FISK_RN_ERROR fisk rn nije odstaman", 2)
             RETURN -1
          ENDIF
          @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Broj fiskalnog računa ?" GET nBroj VALID nBroj > 0
          READ
          IF LastKey() == K_ESC
             BoxC()
             log_write_file( "FISK_RN_ERROR set broj fisk rn - ESC", 2)
             RETURN -2
          ENDIF
      BoxC()

      Alert("Vaši odgovori su zabilježeni !")
      cMsg := "FISK_RN_ERROR: fiskalni račun " + AllTrim( Str( nBroj ) ) + " je ipak odštampan kupcu!"
      log_write_file( cMsg, 2)
      log_write( cMsg, 2)
      RETURN nBroj

   ENDIF

   RETURN 0


FUNCTION tremol_read_error( hFiskalniParams, cFajl, nBrojFiskalnoRacunaOut )

   LOCAL oFile, cErrorLine, aLinije, nI, cTmp
   LOCAL aErrors := {}
   LOCAL aTmp2
   LOCAL nScan
   LOCAL nErrorLevel := FISK_ERROR_NEPOZNATO
   LOCAL cFiskalniFajlName
   LOCAL lFiskalniRacun

   // primjer: c:\fiscal\00001.out
   cFiskalniFajlName := AllTrim( hFiskalniParams[ "out_dir" ] + StrTran( cFajl, "xml", "out" ) )

   IF nBrojFiskalnoRacunaOut == NIL
      lFiskalniRacun := .F.
   ELSE
      lFiskalniRacun := .T.
   ENDIF

   oFile := TFileRead():New( cFiskalniFajlName )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFiskalniFajlName ) )
      RETURN FISK_ERROR_CITANJE_FAJLA
   ENDIF

   // prodji kroz svaku liniju i procitaj zapise
   // 1 liniju preskoci zato sto ona sadrzi
   // <?xml version="1.0"...>
   DO WHILE oFile:MoreToRead()
      cErrorLine := hb_StrToUTF8( oFile:ReadLine()  ) // uzmi u cErr liniju fajla
      cErrorLine := StrTran( cErrorLine, '<?xml version="1.0" ?>', "" ) // skloni "<" i ">"
      cErrorLine := StrTran( cErrorLine, ">", "" )
      cErrorLine := StrTran( cErrorLine, "<", "" )
      cErrorLine := StrTran( cErrorLine, "/", "" )
      cErrorLine := StrTran( cErrorLine, '"', "" )
      cErrorLine := StrTran( cErrorLine, "TremolFpServerOutput", "" )
      cErrorLine := StrTran( cErrorLine, "Output Change", "OutputChange" )
      cErrorLine := StrTran( cErrorLine, "Output Total", "OutputTotal" )

#ifdef __PLATFORM__LINUX
      // ovo je novi red na linux-u
      cErrorLine := StrTran( cErrorLine, Chr( 10 ), "" )
      cErrorLine := StrTran( cErrorLine, Chr( 9 ), " " )
#endif

      // dobijamo npr:
      // ErrorCode=0 ErrorOPOS=OPOS_SUCCESS ErrorDescription=Uspjesno kreiran
      // Output Change=0.00 ReceiptNumber=00552 Total=51.20
      aLinije := TokToNiz( cErrorLine, Space( 1 ) )

      // dobit cemo>
      // aLinija[1] = "ErrorCode=0"
      // aLinija[2] = "ErrorOPOS=OPOS_SUCCESS"
      // ...
      FOR nI := 1 TO Len( aLinije )
         AAdd( aErrors, aLinije[ nI ] )
      NEXT

   ENDDO

   oFile:Close()

   // <?xml version="1.0" ?>
   // <TremolFpServerOutput ErrorCode="0" ErrorFP="0" ErrorDescription="">
   // <Output Total="7.40" Change="0.00" ReceiptNumber="BROJRACUNA">
   // </TremolFpServerOutput>

#ifdef __PLATFORM__LINUX
   nScan := AScan( aErrors, {| cLinija | "ErrorFP=0" $ cLinija } ) // potrazimo gresku...
#else
   nScan := AScan( aErrors, {| val | "OPOS_SUCCESS" $ val } )
#endif
   IF nScan > 0 // nema greske, komanda je uspjela; ako je rijec o racunu uzmi broj fiskalnog racuna
      nScan := AScan( aErrors, {| val | "ReceiptNumber" $ val } )
      IF nScan <> 0
         // ReceiptNumber=241412
         aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
         // ovo ce biti broj racuna
         cTmp := AllTrim( aTmp2[ 2 ] )
         IF !Empty( cTmp )
            nBrojFiskalnoRacunaOut := Val( cTmp )
         ENDIF

      ENDIF

      FErase( cFiskalniFajlName ) // pobrisi fajl, izdaji
      RETURN 0

   ELSE
      IF lFiskalniRacun
         RETURN FISK_ERROR_NEMA_BROJA_RACUNA
      ENDIF
   ENDIF

   cTmp := ""
   nScan := AScan( aErrors, {| cLinija | "ErrorCode" $ cLinija } ) // imamo gresku !!! ispisi je
   IF nScan <> 0
      // ErrorCode=241412
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += "ErrorCode: " + AllTrim( aTmp2[ 2 ] )
      // ovo je ujedino i error kod
      nErrorLevel := Val( aTmp2[ 2 ] )
   ENDIF

   IF is_linux()
      cTmp := "ErrorFP"
   ELSE
      cTmp := "ErrorOPOS"
   ENDIF

   nScan := AScan( aErrors, {| cLinija | cTmp $ cLinija } )
   IF nScan <> 0
      // ErrorOPOS=xxxxxxx
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += " ErrorOPOS: " + AllTrim( aTmp2[ 2 ] )
   ENDIF

   nScan := AScan( aErrors, {| val | "ErrorDescription" $ val } )
   IF nScan <> 0
      // ErrorDescription=xxxxxxx
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += " Description: " + AllTrim( aTmp2[ 2 ] )
   ENDIF

   IF !Empty( cTmp )
      MsgBeep( "TREMOL: " + cTmp )
   ENDIF
   FErase( cFiskalniFajlName ) // obrisi fajl out na kraju !

   RETURN nErrorLevel


STATIC FUNCTION tremol_fix_xml_date( dDate )

   LOCAL xRet := ""
   LOCAL cTmp

   cTmp := AllTrim( Str( Year( dDate ) ) )
   xRet += cTmp
   xRet += "-"
   cTmp := PadL( AllTrim( Str( Month( dDate ) ) ), 2, "0" )
   xRet += cTmp
   xRet += "-"
   cTmp := PadL( AllTrim( Str( Day( dDate ) ) ), 2, "0" )
   xRet += cTmp

   RETURN xRet
