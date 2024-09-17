#include "hbcurl.ch"
#include "f18.ch"

//#DEFINE OFS_URL   "http://ofs.svc.test.out.ba:8000"
//#DEFINE OFS_API_KEY "0123456789abcdef0123456789abcdef"


FUNCTION ofs_get_params()
   LOCAL cUserName := my_user()
   LOCAL hParams := hb_hash()
   LOCAL nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )

   // url, api_key
   hParams := get_fiscal_device_params( nDeviceId, my_user() )
   
   return hParams

FUNCTION ofs_cleanup()
    LOCAL hParams := hb_hash()
    LOCAL nDeviceId 
 
    LOCAL cDokumentNaziv


    o_pos__pripr()
    my_dbf_pack()
    IF _pos_pripr->( RecCount2() ) == 0
       my_close_all_dbf()
       RETURN .F.
    ENDIF
 
    GO TOP
    hParams[ "idpos" ] := _pos_pripr->idpos
    my_close_all_dbf()
  
    altd()
 
    cleanup_pos_tmp( hParams )

    RETURN .T.



FUNCTION curl_hello()

    LOCAL hCurl, nRet, cData

    curl_global_init()

    if empty( hCurl := curl_easy_init() )
        MsgBeep( "curl init neuspjesan ?!")
    endif
    
    //If there's an authorization token, you attach it to the header like this:
    //curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, {"Authorization: " + cHeader} )

    //Set the URL:
    curl_easy_setopt( hCurl, HB_CURLOPT_URL, "https://download.cloud.out.ba/hello.txt" )  
    
    //Disabling the SSL peer verification (you can use it if you have no SSL certificate yet, but still want to test HTTPS)
    curl_easy_setopt(hCurl, HB_CURLOPT_FOLLOWLOCATION, 1)
    curl_easy_setopt(hCurl, HB_CURLOPT_SSL_VERIFYPEER, 0)

    //If you are sending a POST method request, you gotta attach your fields with this clause using
    //url-encoded pattern
    //If you are sending a GET method request, you can just delete this clause, because your parameters will be attached 
    //directly into your URL
    //curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, "example=param&example2=param2...")          

    //Setting the buffer
    curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )
    
    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "curl_ret: " + hb_ValToStr( nRet ) )
    ENDIF
  
  
    //Cleaning the curl instance
    curl_global_cleanup()   

    //I'm using hb_jsonDecode() so I can decode the responde into a JSON object
    //hb_jsonDecode(uValue)  

    MsgBeep("Response:" + Strtran(Strtran(cData, Chr(13), ""), Chr(10), ""))
    RETURN NIL


FUNCTION curl_init(hParams, cPath, cContentType, cMethod)
    local hCurl, aHeader
    
    curl_global_init()

    if empty( hCurl := curl_easy_init() )
        MsgBeep( "curl init neuspjesan ?!")
        return NIL
    endif

    curl_easy_setopt( hCurl, HB_CURLOPT_URL, hParams["url"] + cPath )  
    curl_easy_setopt( hCurl, HB_CURLOPT_CUSTOMREQUEST, cMethod )  
        
    //Disabling the SSL peer verification (you can use it if you have no SSL certificate yet, but still want to test HTTPS)
    curl_easy_setopt(hCurl, HB_CURLOPT_FOLLOWLOCATION, 1)
    curl_easy_setopt(hCurl, HB_CURLOPT_SSL_VERIFYPEER, 0)
    
    //If you are sending a POST method request, you gotta attach your fields with this clause using
    //url-encoded pattern
    //If you are sending a GET method request, you can just delete this clause, because your parameters will be attached 
    //directly into your URL
    //curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, "example=param&example2=param2...")          
    
    //Setting the buffer
    curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )
    curl_easy_setopt(hCurl, HB_CURLOPT_FOLLOWLOCATION, 1)
    curl_easy_setopt(hCurl, HB_CURLOPT_DEFAULT_PROTOCOL, "https")
        
    //    pHeaders = curl_slist_append(pHeaders, "Authorization: Bearer 0123456789abcdef0123456789abcdef")
    //    pHeaders = curl_slist_append(pHeaders, "RequestId: 12345")
    //    pHeaders = curl_slist_append(pHeaders, "Content-Type: application/json")
     //   curl_easy_setopt(curl, CURLOPT_HTTPHEADER, pHeaders)

    aHeader := {}
    IF  hParams["api_key"] != NIL
        AAdd(aHeader, "Authorization: Bearer " + hParams["api_key"])
    ENDIF
    AAdd(aHeader, "Content-Type: " + cContentType)
    curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, aHeader)
    

    return hCurl

FUNCTION curl_end()
    
    //Cleaning the curl instance
    curl_global_cleanup()
    RETURN NIL


FUNCTION ofs_attention(hParams)

    LOCAL nRet, cData, hCurl
    IF hParams == NIL
        hParams := ofs_get_params()
    ENDIF
    hCurl := curl_init(hParams, "/api/attention", "application/text", "GET")

    IF hCurl == NIL
       return .F.
    endif

    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "attention curl_ret: " + hb_ValToStr( nRet ) )
        return .F.
    ENDIF
    
    curl_end()

    RETURN .T.


FUNCTION ofs_putpin(hParams)
    LOCAL GetList := {}
    LOCAL cPin := SPACE(4)
    LOCAL nRet, cData, hCurl
    LOCAL lOk := .F.

    IF hParams == NIL
        hParams := ofs_get_params()
    ENDIF
    DO WHILE .T.
        hCurl := curl_init(hParams, "/api/pin", "application/text", "POST")

        IF hCurl == NIL
          curl_end()
          lOk := .F.
          EXIT
        endif

        Box(,1, 80)
        Beep( 1 )
        @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi PIN fiskalnog uredjaja:" GET cPin PICT "@!S40"
        READ

        BoxC()

        IF LastKey() == K_ESC
            curl_end()
            lOk := .F.
            EXIT
        endif   

        curl_easy_setopt(hCurl, HB_CURLOPT_POSTFIELDS, cPin)
    
        cData := "XXXX"

        IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
          cData := curl_easy_dl_buff_get( hCurl )
          lOk := .T.
        ELSE
           Alert( "curl_ret: " + hb_ValToStr( nRet ) )    
           lOk := .F.
        ENDIF

        curl_end()

        IF lOk .and. cData == "0100"
            lOk := .T.
        ELSE
            Alert("PIN Povratni kod: " + cData + " ?!") 
            lOk := .F.
        ENDIF

        IF lOk
            EXIT
        ENDIF
        
    ENDDO


    RETURN lOk

/*
   cRet = "0"  // sve ok
   cRet = "1"  // uspjesno unijet pin 
   cRet = "99" // error
   cRet = "999" // error pomoci nema

*/  


FUNCTION ofs_status(hParams)
    
    LOCAL nRet, cData, hCurl
    LOCAL hResponseData, cGsc := "", cCode, cRet := "0"

    IF hParams == NIL
        hParams := ofs_get_params()
    ENDIF
    hCurl := curl_init(hParams, "/api/status", "application/json", "GET")

    IF hCurl == NIL
        return "99"
    endif

    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "status curl_ret: " + hb_ValToStr( nRet ) )
        cRet := "99"
    ENDIF
    
      
    IF cRet == "0"
        //I'm using hb_jsonDecode() so I can decode the responde into a JSON object
        hResponseData := hb_jsonDecode(cData)
        
        cGsc = "" 
        for each cCode in hResponseData["gsc"]
            cGsc := cGsc + cCode + "/"
        next
    ENDIF

    //altd()
    /*
    MsgBeep("STATUS #hardwareVersion: " + hResponseData["hardwareVersion"] +;
            "#sdcDateTime - tekuci datum: " + hResponseData["sdcDateTime"] +;
            "#last invoiceNumber: " + hResponseData["lastInvoiceNumber"] +;
            "#gsc: " + cGsc + "#" ;
            )
    */
    curl_end()

    //  Samo ako se koristi LPFR: proveriti da li je bezbednosni element prisutan pozivom /api/status (opisan u "Provera statusa") 
    // i proverom da li se u spisku statusa u polju gsc nalazi kod 1300. Ukoliko se ovaj kod nalazi onda treba 
    // prikazati adekvatnu poruku korisniku da bezbednosni element nije prisutan i nastaviti ovu proveru sve dok se ne izgubi kod 1300.
    
    // Samo ako se koristi LPFR: proveriti dali je neophodan unos PIN-a pozivom /api/status 
    // i proverom da li se u spisku statusa u polju gsc nalazi kod 1500.
    
    IF "1300" $ cGsc
        Alert("/api/status sadrzi kod: 1300 => Bezbjednosni element nije prisutan! STOP")
        cRet := "999"  
    ELSEIF "1500" $ cGsc
      // Alert("/api/status sadrzi kod: 1500 => Neophodan unos PIN-a. STOP")   
      IF ofs_putpin(hParams)
        cRet := "1"
      ELSE
        cRet := "99"
      ENDIF
    ENDIF

    RETURN cRet

FUNCTION ofs_create_invoice()

    LOCAL hParams := ofs_get_params()
    LOCAL hCurl, nRet, cData, pHeaders, cApiKey, hResponseData, hInvoiceData, hPaymentLine, hItemLine 
    LOCAL cStatus1

    IF !ofs_attention(hParams)
        Alert("Fiskalni je mrtav?!")
       RETURN .F.
    ENDIF

    cStatus1 := ofs_status(hParams)

    IF cStatus1 == "999"
        // ovdje pomoci nema - status 1300 ne moze se popraviti unosom pin-a
        RETURN .F.
    ENDIF

    IF cStatus1 == "99"
      Alert("Neuspjesan unos PIN-a. Prekid izdavanja fiskalnog racuna!")
      RETURN .F.
    ENDIF

    // ako je doslo do unosa pin-a, ova - druga kontrola statusa mora dati otkljucan uredjaj
    IF cStatus1 == "1" .AND. ofs_status(hParams) != "0" 
       Alert("Nakon unosa PIN-a uredjaj i dalje nedostupan!? STOP!")
      
       RETURN .F.
    ENDIF

    hCurl := curl_init(hParams, "/api/invoices", "application/json", "POST")
    
    hInvoiceData := hb_hash()

    hInvoiceData["invoiceRequest"] := hb_hash()
    hInvoiceData["invoiceRequest"]["invoiceType"] := "Normal"
    hInvoiceData["invoiceRequest"]["transactionType"] := "Sale"
    hInvoiceData["invoiceRequest"]["payment"] := {}
    hPaymentLine := hb_hash()
    hPaymentLine["amount"] := 100.00
    hPaymentLine["paymentType"] := "Cash"
    AAdd(hInvoiceData["invoiceRequest"]["payment"], hPaymentLine)

    hInvoiceData["invoiceRequest"]["items"] := {}
    hItemLine := hb_hash()
    hItemLine["name"] := "Artikal 1"
    hItemLine["labels"] := { "F" }
    hItemLine["totalAmount"] := 100.00
    hItemLine["unitPrice"] := 50.00
    hItemLine["quantity"] := 2.000
    AAdd(hInvoiceData["invoiceRequest"]["items"], hItemLine)

    hItemLine := hb_hash()
    hItemLine["name"] := "Artikal 2"
    hItemLine["labels"] := { "F" }
    hItemLine["totalAmount"] := 30.00
    hItemLine["unitPrice"] := 10.00
    hItemLine["quantity"] := 3.000
    AAdd(hInvoiceData["invoiceRequest"]["items"], hItemLine)
    
    hInvoiceData["invoiceRequest"]["cashier"] := "Radnik 1"
    
    cData := hb_jsonEncode(hInvoiceData)
    //altd()

    curl_easy_setopt(hCurl, HB_CURLOPT_POSTFIELDS, cData)
            
    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "curl_ret: " + hb_ValToStr( nRet ) )
        curl_end()
    ENDIF
      
    
    //I'm using hb_jsonDecode() so I can decode the responde into a JSON object
    hResponseData := hb_jsonDecode(cData)
    
    //altd()
    //MsgBeep("Response: " + hResponseData["type"] + "#items_length:" + Str(hResponseData["items_length"], 2) + "#payment_length:" + Str(hResponseData["payment_length"], 2) + "#cashier:" + hResponseData["cashier"])
    MsgBeep("#businessName: " + hResponseData["businessName"] +;
            "#address: " + hResponseData["address"] +;
            "#invoiceNumber: " + hResponseData["invoiceNumber"] +;
            "#sdcDateTime: " + hResponseData["sdcDateTime"] +;
            "#totalAmount: " + Str(hResponseData["totalAmount"], 10,2) +;
            "#messages: " + hResponseData["messages"] +;
            "#taxItems(1).amount:" + Str(hResponseData["taxItems"][1]["amount"], 10,4) +;
            "#taxItems(1).label:" + hResponseData["taxItems"][1]["label"] +;
            "#" ;
            )
    RETURN .T.


FUNCTION fiskalni_ofs_racun( hParams, aRacunStavke, aKupac, lStorno )

    LOCAL cVrstaPlacanja, cOperater, nTotal, nI
    LOCAL cArtikalNaz, cArtikalJmj, cArtikal, nCijena, nKolicina, cArtikalTarifa

    //LOCAL hParams := ofs_get_params()
    LOCAL hCurl, nRet, cData, pHeaders, cApiKey, hResponseData, hInvoiceData, hPaymentLine, hItemLine 
    LOCAL cStatus1
    LOCAL hRet := hb_hash()

    hRet["error"] := 0
    hRet["broj"] := ""
    hRet["datum"] := ""
    hRet["json"] := ""
   
    IF lStorno == NIL
        lStorno := .F.
    ENDIF
    
    

    cVrstaPlacanja := AllTrim( aRacunStavke[ 1, FISK_INDEX_VRSTA_PLACANJA ] )
        
    IF !Empty( hParams[ "op_id" ] ) // provjeri operatera i lozinku iz podesenja...
        cOperater := hParams[ "op_id" ]
    ENDIF
 
    //   IF !Empty( hParams[ "op_pwd" ] )
    //       cOperaterPassword := hFiskalniParams[ "op_pwd" ]
    //   ENDIF
             
    nTotal := aRacunStavke[ 1, FISK_INDEX_TOTAL ] // ukupno racun
     
    IF nTotal == NIL
        nTotal := 0
    ENDIF
     
    IF !ofs_attention(hParams)
        Alert("Fiskalni je mrtav?!")
       RETURN .F.
    ENDIF

    cStatus1 := ofs_status(hParams)

    IF cStatus1 == "999"
        // ovdje pomoci nema - status 1300 ne moze se popraviti unosom pin-a
        hRet["error"] := FISK_NEMA_ODGOVORA
        RETURN hRet
    ENDIF

    IF cStatus1 == "99"
      Alert("Neuspjesan unos PIN-a. Prekid izdavanja fiskalnog racuna!")
      hRet["error"] := FISK_NEMA_ODGOVORA
      RETURN hRet

    ENDIF

    // ako je doslo do unosa pin-a, ova - druga kontrola statusa mora dati otkljucan uredjaj
    IF cStatus1 == "1" .AND. ofs_status(hParams) != "0" 
       Alert("Nakon unosa PIN-a uredjaj i dalje nedostupan!? STOP!")
       hRet["error"] := FISK_NEMA_ODGOVORA
       RETURN hRet
    ENDIF

    hCurl := curl_init(hParams, "/api/invoices", "application/json", "POST")
    
    hInvoiceData := hb_hash()

    hInvoiceData["invoiceRequest"] := hb_hash()
    
    hInvoiceData["invoiceRequest"]["invoiceType"] := "Normal"
    hInvoiceData["invoiceRequest"]["transactionType"] := "Sale"
    
    hInvoiceData["invoiceRequest"]["payment"] := {}
    hPaymentLine := hb_hash()
    hPaymentLine["amount"] := nTotal
    hPaymentLine["paymentType"] := cVrstaPlacanja
    AAdd(hInvoiceData["invoiceRequest"]["payment"], hPaymentLine)

    // 5. kupac - podaci
    //IF aKupac <> NIL .AND. Len( aKupac ) > 0
    
        //// aKupac = { idbroj, naziv, adresa, ptt, mjesto }
        //
        //// 1. id broj
        //cTmp += AllTrim( aKupac[ 1, 1 ] )
        //cTmp += cTackaZarez
    
        //// 2. naziv
        //cTmp += AllTrim( PadR( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 2 ] ), lConvertTo852 ), 36 ) )
        //cTmp += cTackaZarez
    
        //// 3. adresa
        //cTmp += AllTrim( PadR( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 3 ] ), lConvertTo852 ), 36 ) )
        //cTmp += cTackaZarez
    
        //// 4. ptt, mjesto
        //cTmp += AllTrim( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 4 ] ), lConvertTo852 ) ) + " " + ;
        //   AllTrim( to_win1250_encoding( hb_StrToUTF8( aKupac[ 1, 5 ] ), lConvertTo852 ) )
    
        //cTmp += cTackaZarez
        //cTmp += cTackaZarez
        //cTmp += cTackaZarez
    
        //AAdd( aArr, { cTmp } )
    
    //ENDIF

    //IF lStorno == .T.
    //   cRek_rn := AllTrim( aRacunData[ 1, FISK_INDEX_FISK_RACUN_STORNIRATI ] )
    // ENDIF  
    
    hInvoiceData["invoiceRequest"]["items"] := {}

    FOR nI := 1 TO Len( aRacunStavke )
        cArtikalNaz := aRacunStavke[ nI, FISK_INDEX_ROBANAZIV ]
        cArtikalJmj := aRacunStavke[ nI, FISK_INDEX_JMJ ]
        cArtikal := hb_StrToUTF8(TRIM(cArtikalNaz) + " (" + cArtikalJmj + ")")

        nCijena := aRacunStavke[ nI, FISK_INDEX_NETO_CIJENA ]
        nKolicina := aRacunStavke[ nI, FISK_INDEX_KOLICINA ]
        //nPopust := aRacunStavke[ nI, FISK_INDEX_POPUST ]
        
        cArtikalTarifa := fiskalni_tarifa( aRacunStavke[ nI, FISK_INDEX_TARIFA ], hParams[ "pdv" ], "OFS" )
        
        hItemLine := hb_hash()
        hItemLine["name"] := cArtikal
        hItemLine["labels"] := { cArtikalTarifa }
        hItemLine["totalAmount"] := ROUND(nCijena * nKolicina, 2)
        hItemLine["unitPrice"] := nCijena
        hItemLine["quantity"] := nKolicina
        AAdd(hInvoiceData["invoiceRequest"]["items"], hItemLine)
            
    NEXT
    
    hInvoiceData["invoiceRequest"]["cashier"] := cOperater
    
    cData := hb_jsonEncode(hInvoiceData)
    //altd()

    curl_easy_setopt(hCurl, HB_CURLOPT_POSTFIELDS, cData)
            
    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "curl_ret: " + hb_ValToStr( nRet ) )
        curl_end()
    ENDIF
      
    hRet["json"] := cData
    hResponseData := hb_jsonDecode(cData)
    
    MsgBeep("#businessName: " + hResponseData["businessName"] +;
            "#address: " + hResponseData["address"] +;
            "#invoiceNumber: " + hResponseData["invoiceNumber"] +;
            "#sdcDateTime: " + hResponseData["sdcDateTime"] +;
            "#totalAmount: " + Str(hResponseData["totalAmount"], 10,2) +;
            "#messages: " + hResponseData["messages"] +;
            "#taxItems(1).amount:" + Str(hResponseData["taxItems"][1]["amount"], 10,4) +;
            "#taxItems(1).label:" + hResponseData["taxItems"][1]["label"] +;
            "#" ;
            )
    
    
    hRet["broj"] := hResponseData["invoiceNumber"]
    hRet["datum"] := hResponseData["sdcDateTime"]
    
    
RETURN hRet


FUNCTION is_ofs_fiskalni()

    LOCAL nDeviceId, hParams
 
    nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )
    IF nDeviceId > 0
        hParams := get_fiscal_device_params( nDeviceId, my_user() )
    ENDIF

 
    IF !hb_HHasKey( hParams, "drv" )
       RETURN .F.
    ENDIF
 
    RETURN hParams[ "drv" ] == "OFS"


FUNCTION pos_set_broj_fiskalnog_racuna_ofs( hParams )

    LOCAL cQuery, oRet, oError, lRet := .F.
  
    LOCAL cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskRacuna, cBrojFiskRacuna, cDatumFiskRacuna, cJson
 
    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]
    cBrojFiskRacuna := hParams["fiskalni_broj"]
    cDatumFiskRacuna := hParams["fiskalni_datum"]
    cJson := hParams["json"]
    
    altd()
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".broj_fiskalnog_racuna_ofs(" + ;
       sql_quote( cIdPos ) + "," + ;
       sql_quote( cIdVd ) + "," + ;
       sql_quote( dDatDok ) + "," + ;
       sql_quote( cBrDok ) + "," + ;
       sql_quote( cBrojFiskRacuna ) + "," +;
       sql_quote( cDatumFiskRacuna ) + "," +;
       sql_quote( hb_Utf8ToStr(cJson) ) + ")"
 
    BEGIN SEQUENCE WITH {| err | Break( err ) }
 
       oRet := run_sql_query( cQuery )
       IF is_var_objekat_tpqquery( oRet )
          IF (!(oRet:FieldGet( 1 ) == "")) .OR. cBrojFiskRacuna == "-"
             lRet := .T.
          ENDIF
       ENDIF
 
    RECOVER USING oError
       Alert( _u( "Setovanje FISK broja " + AllTrim( cBrojFiskRacuna ) + " neuspješno. Dupli broj?!" ) )
    END SEQUENCE
 
    RETURN lRet
 
