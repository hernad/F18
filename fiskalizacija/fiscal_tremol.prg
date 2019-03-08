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
STATIC s_nNemaOut := -20
STATIC s_cZahtjevNula := "0"

// fiskalne funkcije TREMOL fiskalizacije

// struktura matrice aData
//
// aData[1] - broj racuna (C)
// aData[2] - redni broj stavke (C)
// aData[3] - id roba
// aData[4] - roba naziv
// aData[5] - cijena
// aData[6] - kolicina
// aData[7] - tarifa
// aData[8] - broj racuna za storniranje
// aData[9] - roba plu
// aData[10] - plu cijena
// aData[11] - popust
// aData[12] - barkod
// aData[13] - vrsta placanja
// aData[14] - total
// aData[15] - datum racuna
// aData[16] - roba jmj

// struktura matrice aKupac
//
// aKupac[1] - idbroj kupca
// aKupac[2] - naziv
// aKupac[3] - adresa
// aKupac[4] - postanski broj
// aKupac[5] - grad stanovanja


/*
 stampa fiskalnog racuna tring fiskalizacija
*/

FUNCTION fiskalni_tremol_racun( hFiskalniParams, aRacunStavke, aRacunHeader, lStornoRacun, cContinue )

   LOCAL cFiskalniRacunBroj, _vr_plac, nTotalPlac, cXml, nI
   LOCAL _reklamni_broj, nKolicina, nCijena, nPopust
   LOCAL _art_id, cArtikalNaz, cArtikalJmj, cTmp, _art_barkod, _art_plu, cOdjeljenje, cArtikalTarifa
   LOCAL lKupacNaRacunu := .F.
   LOCAL _err_level := 0
   LOCAL _oper := ""
   LOCAL cCommand := ""
   LOCAL _cust_id, _cust_name, _cust_addr, _cust_city
   LOCAL _fiscal_no := 0
   LOCAL cFiscTxt, _fisc_rek_txt, _fisc_cust_txt, cFiskalniFajlName

   tremol_delete_tmp( hFiskalniParams )  // pobrisi tmp fajlove i ostalo sto je u input direktoriju

   IF cContinue == nil
      cContinue := "0"
   ENDIF


   IF aRacunHeader <> NIL .AND. Len( aRacunHeader ) > 0  // ima podataka kupca
      lKupacNaRacunu := .T.
   ENDIF

   cFiskalniRacunBroj := aRacunStavke[ 1, 1 ]
   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], cFiskalniRacunBroj )
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName // putanja do izlaznog xml fajla

   create_xml( cXml )
   xml_head()

   cFiscTxt := 'TremolFpServer Command="Receipt"'
   _fisc_rek_txt := ''
   _fisc_cust_txt := ''

   IF cContinue == "1" // https://redmine.bring.out.ba/issues/36372
      // cFiscTxt += ' Continue="' + cContinue + '"'
   ENDIF

   IF lStornoRacun // ukljuci storno triger
      _fisc_rek_txt := ' RefundReceipt="' + AllTrim( aRacunStavke[ 1, 8 ] ) + '"'
   ENDIF

   // ukljuci kupac triger
   IF lKupacNaRacunu
      // aKupac[1] - idbroj kupca
      // aKupac[2] - naziv
      // aKupac[3] - adresa
      // aKupac[4] - postanski broj
      // aKupac[5] - grad stanovanja
      _cust_id := AllTrim( aRacunHeader[ 1, 1 ] )
      _cust_name := to_xml_encoding( AllTrim( aRacunHeader[ 1, 2 ] ) )
      _cust_addr := to_xml_encoding( AllTrim( aRacunHeader[ 1, 3 ] ) )
      _cust_city := to_xml_encoding( AllTrim( aRacunHeader[ 1, 5 ] ) )

      _fisc_cust_txt += s_cRazmak1 + 'CompanyID="' + _cust_id + '"'
      _fisc_cust_txt += s_cRazmak1 + 'CompanyName="' + _cust_name + '"'
      _fisc_cust_txt += s_cRazmak1 + 'CompanyHQ="' + _cust_city + '"'
      _fisc_cust_txt += s_cRazmak1 + 'CompanyAddress="' + _cust_addr + '"'
      _fisc_cust_txt += s_cRazmak1 + 'CompanyCity="' + _cust_city + '"'

   ENDIF

   // ubaci u xml
   xml_subnode( cFiscTxt + _fisc_rek_txt + _fisc_cust_txt )

   nTotalPlac := 0

   FOR nI := 1 TO Len( aRacunStavke )

      _art_plu := aRacunStavke[ nI, 9 ]
      _art_barkod := aRacunStavke[ nI, 12 ]
      _art_id := aRacunStavke[ nI, 3 ]
      // cArtikalNaz := PadR( aRacunStavke[ nI, 4 ], 32 )
      cArtikalNaz := aRacunStavke[ nI, 4 ]
      cArtikalJmj := _g_jmj( aRacunStavke[ nI, 16 ] )
      nCijena := aRacunStavke[ nI, 5 ]
      nKolicina := aRacunStavke[ nI, 6 ]
      nPopust := aRacunStavke[ nI, 11 ]
      cArtikalTarifa := fiscal_txt_get_tarifa( aRacunStavke[ nI, 7 ], hFiskalniParams[ "pdv" ], "TREMOL" )
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
      xml_single_node( "Item", cTmp )

   NEXT

   // vrste placanja, oznaka:
   // "GOTOVINA"
   // "CEK"
   // "VIRMAN"
   // "KARTICA"

   _vr_plac := fiscal_txt_get_vr_plac( aRacunStavke[ 1, 13 ], "TREMOL" )
   nTotalPlac := aRacunStavke[ 1, 14 ]

   IF aRacunStavke[ 1, 13 ] <> "0" .AND. !lStornoRacun

      cTmp := 'Type="' + _vr_plac + '"'
      cTmp += s_cRazmak1 + 'Amount="' + AllTrim( Str( nTotalPlac, 12, 2 ) ) + '"'

      xml_single_node( "Payment", cTmp )

   ENDIF

   // dodatna linija, broj veznog racuna
   cTmp := 'Message="Vezni racun: ' + cFiskalniRacunBroj + '"'
   xml_single_node( "AdditionalLine", cTmp )
   xml_subnode( "TremolFpServer", .T. )
   close_xml()

   RETURN _err_level



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

// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
FUNCTION tremol_delete_tmp( dev_param )

   LOCAL cTmp
   LOCAL _f_path

   MsgO( "brisem tmp fajlove..." )

   _f_path := dev_param[ "out_dir" ]
   cTmp := "*.*"

   AEval( Directory( _f_path + cTmp ), {| aFile | FErase( _f_path + ;
      AllTrim( aFile[ 1 ] ) ) } )

   Sleep( 1 )

   MsgC()

   RETURN .T.




// -------------------------------------------------------------------
// -------------------------------------------------------------------
FUNCTION tremol_polog( hFiskalniParams, AUTO )

   LOCAL cXml
   LOCAL nErrorLevel := 0
   LOCAL cCommand := ""
   LOCAL cFiskalniFajlName
   LOCAL _value := 0

   IF AUTO == NIL
      AUTO := .F.
   ENDIF

   IF AUTO
      _value := hFiskalniParams[ "auto_avans" ]
   ENDIF

   IF _value = 0

      // box - daj iznos pologa

      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unosim polog od:" GET _value PICT "9999999.99"
      READ
      BoxC()

      IF LastKey() == K_ESC .OR. _value = 0
         RETURN
      ENDIF

   ENDIF

   IF _value < 0
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

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "TremolFpServer " + cCommand )

   cCommand := 'Amount="' +  AllTrim( Str( Abs( _value ), 12, 2 ) ) + '"'

   xml_single_node( "Cash", cCommand )

   xml_subnode( "/TremolFpServer" )

   close_xml()

   RETURN nErrorLevel




// -------------------------------------------------------------------
// tremol reset artikala
// -------------------------------------------------------------------
FUNCTION tremol_reset_plu( hFiskalniParams )

   LOCAL cXml, cFiskalniFajlName
   LOCAL nErrorLevel := 0
   LOCAL cCommand := ""

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



// -------------------------------------------------------------------
// tremol komanda
// -------------------------------------------------------------------
FUNCTION tremol_cmd( hFiskalniParams, cmd )

   LOCAL cXml
   LOCAL nErrorLevel := 0
   LOCAL cFiskalniFajlName

   cFiskalniFajlName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula )

   // putanja do izlaznog xml fajla
   cXml := hFiskalniParams[ "out_dir" ] + cFiskalniFajlName

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "TremolFpServer " + cmd )

   close_xml()

   // provjeri greske...
   IF tremol_cekam_fajl_odgovora( hFiskalniParams, cFiskalniFajlName )
      // procitaj poruku greske
      nErrorLevel := tremol_read_error( hFiskalniParams, cFiskalniFajlName )
   ELSE
      nErrorLevel := s_nNemaOut
   ENDIF

   RETURN nErrorLevel



// ------------------------------------------
// vraca jedinicu mjere
// ------------------------------------------
STATIC FUNCTION _g_jmj( jmj )

   LOCAL _ret := ""

   DO CASE

   CASE Upper( AllTrim( jmj ) ) = "LIT"
      _ret := "l"
   CASE Upper( AllTrim( jmj ) ) = "GR"
      _ret := "g"
   CASE Upper( AllTrim( jmj ) ) = "KG"
      _ret := "kg"

   ENDCASE

   RETURN _ret



// -----------------------------------------------------
// ItemZ
// -----------------------------------------------------
FUNCTION tremol_z_item( dev_param )

   LOCAL cCommand, nErrorLevel

   cCommand := 'Command="Report" Type="ItemZ" /'
   nErrorLevel := tremol_cmd( dev_param, cCommand )

   RETURN nErrorLevel


// -----------------------------------------------------
// ItemX
// -----------------------------------------------------
FUNCTION tremol_x_item( dev_param )

   LOCAL cCommand

   cCommand := 'Command="Report" Type="ItemX" /'
   nErrorLevel := tremol_cmd( dev_param, cCommand )

   RETURN nErrorLevel


// -----------------------------------------------------
// dnevni fiskalni izvjestaj
// -----------------------------------------------------
FUNCTION tremol_z_rpt( dev_param )

   LOCAL cCommand
   LOCAL nErrorLevel
   LOCAL _param_date, _param_time
   LOCAL _rpt_type := "Z"

   IF Pitanje(, "Stampati dnevni izvjestaj", "D" ) == "N"
      RETURN
   ENDIF

   _param_date := "zadnji_" + _rpt_type + "_izvjestaj_datum"
   _param_time := "zadnji_" + _rpt_type + "_izvjestaj_vrijeme"

   // iscitaj zadnje formirane izvjestaje...
   _last_date := fetch_metric( _param_date, NIL, CToD( "" ) )
   _last_time := PadR( fetch_metric( _param_time, NIL, "" ), 5 )

   IF Date() == _last_date
      MsgBeep( "Zadnji dnevni izvjestaj radjen " + DToC( _last_date ) + " u " + _last_time )
   ENDIF

   cCommand := 'Command="Report" Type="DailyZ" /'
   nErrorLevel := tremol_cmd( dev_param, cCommand )

   // upisi zadnji dnevni izvjestaj
   set_metric( _param_date, NIL, Date() )
   set_metric( _param_time, NIL, Time() )

   // ako se koristi opcija automatskog pologa
   IF dev_param[ "auto_avans" ] > 0

      MsgO( "Automatski unos pologa u uredjaj... sacekajte." )

      // daj mi malo prostora
      Sleep( 10 )

      // pozovi opciju pologa
      nErrorLevel := tremol_polog( dev_param, .T. )

      MsgC()

   ENDIF

   RETURN nErrorLevel


// -----------------------------------------------------
// presjek stanja
// -----------------------------------------------------
FUNCTION tremol_x_rpt( dev_param )

   LOCAL cCommand
   LOCAL nErrorLevel

   cCommand := 'Command="Report" Type="DailyX" /'
   nErrorLevel := tremol_cmd( dev_param, cCommand )

   RETURN


// -----------------------------------------------------
// periodicni izvjestaj
// -----------------------------------------------------
FUNCTION tremol_per_rpt( dev_param )

   LOCAL cCommand, nErrorLevel
   LOCAL _start
   LOCAL _end
   LOCAL _date_start := Date() - 30
   LOCAL _date_end := Date()

   IF Pitanje(, "Stampati periodicni izvjestaj", "D" ) == "N"
      RETURN
   ENDIF

   Box(, 1, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Od datuma:" GET _date_start
   @ box_x_koord() + 1, Col() + 1 SAY "do datuma:" GET _date_end
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN
   ENDIF

   // 2010-10-01 : YYYY-MM-DD je format datuma
   _start := tremol_fix_xml_date( _date_start )
   _end := tremol_fix_xml_date( _date_end )

   cCommand := 'Command="Report" Type="Date" Start="' + _start + ;
      '" End="' + _end + '" /'

   nErrorLevel := tremol_cmd( dev_param, cCommand )

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
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "račun je reklamirani (D/N)?" GET cRefundDN ;
      VALID cRefundDN $ "DN" PICT "@!"
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

   nErrorLevel := tremol_cmd( hFiskalniParams, cCommand )

   RETURN nErrorLevel




FUNCTION tremol_cekam_fajl_odgovora( hFiskalniParams, cFajl, nTimeOut )

   LOCAL cTmp
   LOCAL nTime
   LOCAL nCount := 0

   IF nTimeOut == NIL
      nTimeOut := hFiskalniParams[ "timeout" ]
   ENDIF

   nTime := nTimeOut

   // napravi mi konstrukciju fajla koji cu gledati
   // replace *.xml -> *.out
   // out je fajl odgovora
   cTmp := hFiskalniParams[ "out_dir" ] + StrTran( cFajl, "xml", "out" )

   Box(, 3, 60 )

   // ispisi u vrhu id, naz uredjaja
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Uredjaj ID: " + AllTrim( Str( hFiskalniParams[ "id" ] ) ) + ;
      " : " + PadR( hFiskalniParams[ "name" ], 40 )

   DO WHILE nTime > 0

      --nTime

      // provjeri kada bude trecina vremena...
      IF nTime = ( nTimeOut * 0.7 ) .AND. nCount = 0

         IF hFiskalniParams[ "restart_service" ] == "D" .AND. Pitanje(, "Restartovati server", "D" ) == "D"

            // pokreni restart proceduru
            tremol_restart( hFiskalniParams )
            // restartuj vrijeme
            nTime := nTimeOut
            ++nCount

         ENDIF

      ENDIF

      // fajl se pojavio - izadji iz petlje !
      IF File( cTmp )
         EXIT
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 PadR( "Čekam odgovor... " + ;
         AllTrim( Str( nTime ) ), 48 )

      IF nTime == 0 .OR. LastKey() == K_ALT_Q
         BoxC()
         RETURN .F.
      ENDIF

      Sleep( 1 )

   ENDDO

   BoxC()

   IF !File( cTmp )
      MsgBeep( "Ne postoji fajl odgovora (OUT) !!!!" )
      RETURN .F.
   ENDIF

   RETURN .T.



// ------------------------------------------------------------
// citanje gresaka za TREMOL driver
//
// nFisc_no - broj fiskalnog isjecka
//
// ------------------------------------------------------------
FUNCTION tremol_read_error( hFiskalniParams, cFajl, nFiscNo )

   LOCAL oFile, cFiscTxt, _err_txt, _linija, _m, cTmp
   LOCAL aErrors := {}
   LOCAL aTmp2 := {}
   LOCAL nScan
   LOCAL nErrorLevel := 0
   LOCAL cFiskalniFajlName

   // primjer: c:\fiscal\00001.out
   cFiskalniFajlName := AllTrim( hFiskalniParams[ "out_dir" ] + StrTran( cFajl, "xml", "out" ) )

   nFiscNo := 0

   oFile := TFileRead():New( cFiskalniFajlName )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFiskalniFajlName ) )
      RETURN -9
   ENDIF

   cFiscTxt := ""

   // prodji kroz svaku liniju i procitaj zapise
   // 1 liniju preskoci zato sto ona sadrzi
   // <?xml version="1.0"...>
   WHILE oFile:MoreToRead()

      // uzmi u cErr liniju fajla
      _err_txt := hb_StrToUTF8( oFile:ReadLine()  )

      // skloni "<" i ">" itd...
      _err_txt := StrTran( _err_txt, '<?xml version="1.0" ?>', "" )
      _err_txt := StrTran( _err_txt, ">", "" )
      _err_txt := StrTran( _err_txt, "<", "" )
      _err_txt := StrTran( _err_txt, "/", "" )
      _err_txt := StrTran( _err_txt, '"', "" )
      _err_txt := StrTran( _err_txt, "TremolFpServerOutput", "" )
      _err_txt := StrTran( _err_txt, "Output Change", "OutputChange" )
      _err_txt := StrTran( _err_txt, "Output Total", "OutputTotal" )

#ifdef __PLATFORM__LINUX
      // ovo je novi red na linux-u
      _err_txt := StrTran( _err_txt, Chr( 10 ), "" )
      _err_txt := StrTran( _err_txt, Chr( 9 ), " " )
#endif

      // dobijamo npr.
      //
      // ErrorCode=0 ErrorOPOS=OPOS_SUCCESS ErrorDescription=Uspjesno kreiran
      // Output Change=0.00 ReceiptNumber=00552 Total=51.20

      _linija := TokToNiz( _err_txt, Space( 1 ) )
      // dobit cemo
      //
      // aLinija[1] = "ErrorCode=0"
      // aLinija[2] = "ErrorOPOS=OPOS_SUCCESS"
      // ...

      FOR _m := 1 TO Len( _linija )
         AAdd( aErrors, _linija[ _m ] )
      NEXT

   ENDDO

   oFile:Close()

   // potrazimo gresku...
#ifdef __PLATFORM__LINUX
   nScan := AScan( aErrors, {| val | "ErrorFP=0" $ val } )
#else
   nScan := AScan( aErrors, {| val | "OPOS_SUCCESS" $ val } )
#endif

   IF nScan > 0

      // nema greske, komanda je uspjela !
      // ako je rijec o racunu uzmi broj fiskalnog racuna
      nScan := AScan( aErrors, {| val | "ReceiptNumber" $ val } )
      IF nScan <> 0
         // ReceiptNumber=241412
         aTmp2 := {}
         aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
         // ovo ce biti broj racuna
         cTmp := AllTrim( aTmp2[ 2 ] )
         IF !Empty( cTmp )
            nFiscNo := Val( cTmp )
         ENDIF

      ENDIF

      // pobrisi fajl, izdaji
      FErase( cFiskalniFajlName )
      RETURN nErrorLevel

   ENDIF

   // imamo gresku !!! ispisi je
   cTmp := ""
   nScan := AScan( aErrors, {| val | "ErrorCode" $ val } )
   IF nScan <> 0

      // ErrorCode=241412
      aTmp2 := {}
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += "ErrorCode: " + AllTrim( aTmp2[ 2 ] )
      // ovo je ujedino i error kod
      nErrorLevel := Val( aTmp2[ 2 ] )

   ENDIF

   cTmp := "ErrorOPOS"
#ifdef __PLATFORM__LINUX
   cTmp := "ErrorFP"
#endif

   nScan := AScan( aErrors, {| val | cTmp $ val } )

   IF nScan <> 0
      // ErrorOPOS=xxxxxxx
      aTmp2 := {}
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += " ErrorOPOS: " + AllTrim( aTmp2[ 2 ] )

   ENDIF

   nScan := AScan( aErrors, {| val | "ErrorDescription" $ val } )
   IF nScan <> 0
      // ErrorDescription=xxxxxxx
      aTmp2 := {}
      aTmp2 := TokToNiz( aErrors[ nScan ], "=" )
      cTmp += " Description: " + AllTrim( aTmp2[ 2 ] )
   ENDIF

   IF !Empty( cTmp )
      MsgBeep( cTmp )
   ENDIF

   // obrisi fajl out na kraju !!!
   FErase( cFiskalniFajlName )

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
