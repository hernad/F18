#include "hbcurl.ch"
#include "f18.ch"

#define NEWLINE Chr(13) + Chr(10)

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
  
    curl_global_cleanup()   

    MsgBeep("Response:" + Strtran(Strtran(cData, Chr(13), ""), Chr(10), ""))
    RETURN NIL


FUNCTION curl_init(hParams, cPath, cContentType, cMethod)
    local hCurl, aHeader, cParams, hRequestParam
    
    curl_global_init()

    IF hParams == NIL
       hParams := ofs_get_params()
    ENDIF

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
    if hb_HHasKey(hParams, "request_params")
       cParams := "" 
       // "example=param&example2=param2..."
       FOR each hRequestParam in hParams["request_params"]
           cParams := hRequestParam["name"] + "=" + hRequestParam["value"]
       NEXT
       hParams["c_req_params"] := cParams
       curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, cParams)          
    endif

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
    AAdd(aHeader, "Content-Type: " + cContentType + "; charset=UTF-8")
    
    curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, aHeader)
    
    return hCurl


FUNCTION curl_end()
    
    //Cleaning the curl instance
    curl_global_cleanup()
    RETURN NIL


FUNCTION ofs_attention(hParams)

    LOCAL nRet, cData, hCurl

    hCurl := curl_init(@hParams, "/api/attention", "application/text", "GET")

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

    DO WHILE .T.
        hCurl := curl_init(@hParams, "/api/pin", "application/text", "POST")

        IF hCurl == NIL
          curl_end()
          lOk := .F.
          EXIT
        endif

        Box(,1, 60)
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

   cVarijanta = "0" - check gsc code, aktiviraj unos pin-a ako treba
   cVarijanta = "P" - porezne stope  
   cVarijanta = "S" - osnovni statusni podaci


   cRet = "0"  // sve ok
   cRet = "1"  // uspjesno unijet pin 
   cRet = "99" // error
   cRet = "999" // error pomoci nema

*/


FUNCTION ofs_status(hParams, cVarijanta)
    
    LOCAL nRet, cData, hCurl
    LOCAL hResponseData, cGsc := "", cCode, cRet := "0"
    LOCAL oTaxRates, oTaxCategory, oTaxRate, nX, nRedova, oError, cPath, cContent, cMethod 


    IF cVarijanta == NIL
        cVarijanta := "0"
    ENDIF

    hCurl := curl_init(@hParams, cPath := "/api/status", cContent := "application/json", cMethod := "GET")
    hParams["path"] := cPath
    hParams["content"] := cContent
    hParams["method"] := cMethod
    

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
        hResponseData := hb_jsonDecode(cData)
        
        cGsc = "" 
        for each cCode in hResponseData["gsc"]
            cGsc := cGsc + cCode + "/"
        next
    ENDIF

    IF cRet == "0" .and. cVarijanta == "S"
        MsgBeep("STATUS #hardwareVersion: " + hResponseData["hardwareVersion"] +;
            "#sdcDateTime - tekuci datum: " + hResponseData["sdcDateTime"] +;
            "#last invoiceNumber: " + hResponseData["lastInvoiceNumber"] +;
            "#gsc: " + cGsc + "#" ;
            )
    ENDIF

 
    BEGIN SEQUENCE WITH {| err | Break( err ) }
        IF cRet == "0" .and. cVarijanta == "P"
    
            do while .t.
                //cCurrentTaxRates := ""
                nRedova := 1
                for each oTaxRates in hResponseData["currentTaxRates"]
                    nRedova ++
                    
                    for each oTaxCategory in oTaxRates["taxCategories"]
                        nRedova ++
                        for each oTaxRate in oTaxCategory["taxRates"]
                            nRedova ++
                        next
                        nRedova ++
                        
                    next
                    nRedova ++
                next
                Box(, nRedova, 70)
                nX := 1
                for each oTaxRates in hResponseData["currentTaxRates"]
                    @ box_x_koord() + (nX++), box_y_koord() + 2 SAY "**** Current Tax Rates ******"
                    
                    @ box_x_koord() + (nX++), box_y_koord() + 2 SAY "taxRates: " + oTaxRates["groupId"] + " : " + oTaxRates["validFrom"] + " {"
                    
                    for each oTaxCategory in oTaxRates["taxCategories"]
                        @ box_x_koord() + (nX++), box_y_koord() + 2 SAY SPACE(2) + "tax categ: " + AllTrim(Str(oTaxCategory["categoryType"])) + " - '" + convert_cyr_to_lat(oTaxCategory["name"]) + "' ["
                        for each oTaxRate in oTaxCategory["taxRates"]

                            @ box_x_koord() + (nX++), box_y_koord() + 2 SAY SPACE(10) + "(label: " + oTaxRate["label"] + " rate: " + AllTrim(Str(oTaxRate["rate"])) + " )"
                        next
                        @ box_x_koord() + (nX++), box_y_koord() + 2 SAY SPACE(2) + "]"
                    next
                    @ box_x_koord() + (nX++), box_y_koord() + 2 SAY "}"
                next
                inkey(0)
                BoxC()

                
                if lastkey() == K_ESC
                    exit
                endif
            enddo

        ENDIF
        
        curl_end()

    RECOVER USING oError
       Alert("Status - odgovor nije ocekivan!")
       bug_send_email_body( ;
        "CALL: " + hParams["url"] + "; path: " + hParams["path"] + "; content: " + hParams["content"] + "; method: " + hParams["method"] + NEWLINE +;
        REPLICATE("=", 95) + NEWLINE + NEWLINE +;
        "REQUEST: " + "<nema dodatnih podataka>" +;
        "RESPONSE: " + cData, .F. )
   

    END SEQUENCE

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

FUNCTION ofs_create_test_invoice()

    LOCAL hParams := ofs_get_params()
    LOCAL hCurl, nRet, cData, pHeaders, cApiKey, hResponseData, hInvoiceData, hPaymentLine, hItemLine 
    LOCAL cStatus1

    IF !ofs_attention(@hParams)
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

    hCurl := curl_init(@hParams, "/api/invoices", "application/json", "POST")
    
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


FUNCTION fiskalni_ofs_racun_kopija(hParams)

    LOCAL nDeviceId, hFiskParams, aKupac, aRacunStavke, hKopija, cUUId, hRet
 
    nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )
    IF nDeviceId == NIL
        hRet := hb_hash()
        hRet["error"] := 500
        RETURN hRet
    ENDIF

    IF nDeviceId > 0
        hFiskParams := get_fiscal_device_params( nDeviceId, my_user() )
    ENDIF

    aKupac := NIL
    
    hParams["idvd"] := "42"
    //IF pos_is_storno_ofs( hParams[ "idpos" ], hParams["idvd"], hParams[ "datum" ], hParams[ "brdok" ] )
    //   nStorno := 1
    //   lStorno := .T.
    //ELSE
    //    nStorno := 0
    //    lStorno := .F.
    //ENDIF
    
    hParams["uplaceno"] := -1
    hParams["azuriran"] := .T.

    // uuid fiskalnog racuna ciju kopiju zelimo
    //cUUId := pos_get_fiskalni_dok_id_ofs( hParams )
    IF pos_is_storno_ofs(hParams)
        hParams["storno_fiskalni_broj"] := "A"
        hParams["storno_fiskalni_datum"] := "B"
    ELSE
        hParams["storno_fiskalni_broj"] := ""
        hParams["storno_fiskalni_datum"] := ""
    ENDIF

    aRacunStavke := pos_fiskalni_stavke_racuna_ofs( hParams, hFiskParams)
    
    hKopija := pos_get_broj_fiskalnog_racuna_ofs( hParams )

RETURN fiskalni_ofs_racun(hFiskParams, aRacunStavke, aKupac, hKopija)


FUNCTION json_date(dDatum)

    LOCAL cDat := DTOS(dDatum)
    // 20240530 => 2024-05-30
    RETURN LEFT(cDat, 4) + "-" + SUBSTR(cDat, 5,2) + "-" + SUBSTR(cDat, 7, 2) 


FUNCTION ofs_invoice_search()

    LOCAL GetList := {}
    local hRet, hCurl, hInvoiceSearchData, cDataRequest, nRet, cData
    LOCAL dDatOd := DATE(), dDatDo := DATE(), cLine
    LOCAL nI, nJ, hLine
    LOCAL nUkupnoRn, nUkupnoStorno, nCount := 0, cSep, nCntSale := 0, nCntRefund := 0, nPDV, nUkupnoPDV, hRetInvoice
    LOCAL cPict := "99999999.99"
    LOCAL hParams

    hRet := ofs_attention_status(@hParams)
    IF hRet["error"] <> 0
        RETURN hRet
    ENDIF

    Box(, 3, 60)
      @ box_x_koord() + 1, box_y_koord() + 1 SAY "Datum od" GET dDatOd
      @ box_x_koord() + 2, box_y_koord() + 1 SAY "      do" GET dDatOd
      READ
      
    BoxC()

    IF LastKey() == K_ESC
       return hRet
    ENDIF

    hParams["path"] = "/api/invoices/search"
    hParams["content"] := "application/json"
    hParams["method"] := "GET"
    hCurl := curl_init(@hParams, hParams["path"], hParams["content"] , hParams["method"])
    
    hInvoiceSearchData := hb_hash()
    hInvoiceSearchData["fromDate"] := json_date(dDatOd)
    hInvoiceSearchData["toDate"] := json_date(dDatDo)
    hInvoiceSearchData["invoiceTypes"] := { "Normal" }
    hInvoiceSearchData["transactionTypes"] := { "Sale", "Refund"}
    hInvoiceSearchData["paymentTypes"] := { "Cash", "Card", "WireTransfer", "Other" }
    
    cDataRequest := hb_jsonEncode(hInvoiceSearchData)
    nRet := curl_request(hCurl, cDataRequest, @cData)
    curl_end()

    IF nRet <> 0
        hRet["error"] := 801
    ENDIF
  
    nUkupnoRn := 0
    nUkupnoStorno := 0
    nCount := 0
    nUkupnoPDV := 0
    
    cData := StrTran(cData, "\n", "#")
    cData := StrTran(cData, '"', '')
    
    cSep := '#'

    FOR nI := 1 TO NumToken(cData, cSep)
        cLine := Token(cData, cSep, nI)
        //FOR nJ := 1 TO NumToken(cLine, ",")
        //RX4F7Y5L-RX4F7Y5L-137,Normal,Refund,2024-03-11T23:19:54.853+01:00,100.0000
        hLine := hb_hash()
        hLine["broj"] := Token(cLine, ",", 1)
        hRetInvoice := ofs_invoice_get(hLine["broj"])
        
        hLine["type"] := Token(cLine, ",", 2)
        hLine["transaction"] := Token(cLine, ",", 3) // Sale, Refund
        hLine["datetime"] := Token(cLine, ",", 4)
        hLine["amount"] := Token(cLine, ",", 5)
        
        // iako su labele K i A nepotrebne jer su uvijek 0
        nPDV := hRetInvoice["pdv"]["E"]
        nPDV += hRetInvoice["pdv"]["K"]
        nPDV += hRetInvoice["pdv"]["A"]
        
        IF hLine["transaction"] == "Sale"
            nUkupnoRn += VAL(hLine["amount"])
            nCntSale ++
            nUkupnoPDV += nPDV
        ELSEIF  hLine["transaction"] == "Refund"
            nUkupnoStorno += VAL(hLine["amount"])
            nUkupnoPDV -= nPDV
            nCntRefund ++
        ENDIF

        nCount ++
    NEXT


    DO WHILE .T.
        Box(, 12, 60)
            @ box_x_koord() + 1, box_y_koord() + 2 SAY "========= Pregled prometa: " + DTOC(dDatOd) + " - " + DtoC(dDatDo) + " ========"
            
            @ box_x_koord() + 3, box_y_koord() + 2 SAY "1.  (+)  Racuni:" ; @ ROW(), COL() + 2 SAY nUkupnoRn PICTURE cPict
            @ box_x_koord() + 4, box_y_koord() + 2 SAY "2.  (-)  Storno:" ; @ ROW(), COL() + 2 SAY nUkupnoStorno PICT cPict

            @ box_x_koord() + 6, box_y_koord() + 2 SAY "A) UKUPNO IZNOS:" ; @ ROW() , COL() + 2 SAY nUkupnoRn - nUkupnoStorno PICT cPict
            @ box_x_koord() + 7, box_y_koord() + 2 SAY "B)      BEZ PDV:" ; @ ROW() , COL() + 2 SAY (nUkupnoRn - nUkupnoStorno) - nUkupnoPDV PICT cPict
            @ box_x_koord() + 8, box_y_koord() + 2 SAY "A)          PDV:" ; @ ROW() , COL() + 2 SAY nUkupnoPDV PICT cPict


            @ box_x_koord() + 10, box_y_koord() + 2 SAY " Broj RN + / - :"
            @ ROW(), COL() + 2 SAY nCntSale PICT "999"
            @ ROW(), COL() + 2 SAY nCntRefund PICT "999"

            @ box_x_koord() + 12, box_y_koord() + 2 SAY "B)  UKUPNO BROJ:" ; @ ROW() , COL() + 2 SAY nCount PICT "999"
        
            inkey(0)
        BoxC()
        IF LastKey() == K_ESC
            exit
        ENDIF
    ENDDO


RETURN hRet


FUNCTION ofs_invoice_get( cBrojRacuna )

    LOCAL GetList := {}
    local hRet, hCurl, nRet, cData
    LOCAL dDatOd := DATE(), dDatDo := DATE(), cLine
    LOCAL nI, nJ, hLine
    LOCAL nUkupnoRn, nUkupnoStorno, nCount := 0, cSep, nCntSale := 0, nCntRefund := 0
    LOCAL hParams := NIL, aRequestParams := {}, hRequestParam, hRacun, cLabel, cBrojRacunaResp, nPDVIznosResp
    LOCAL lInteractive := .F., oError

    hRet := ofs_attention_status(@hParams)
    IF hRet["error"] <> 0
        RETURN hRet
    ENDIF

    IF cBrojRacuna == NIL
        lInteractive := .T.
        cBrojRacuna := SPACE(25)
        Box(, 3, 60)
           @ box_x_koord() + 1, box_y_koord() + 1 SAY "Broj racuna:" GET cBrojRacuna VALID !Empty(cBrojRacuna)
        READ
        BoxC()

        IF LastKey() == K_ESC
            hRet["error"] := 909
        return hRet
        ENDIF
    ENDIF

    hParams["path"] = "/api/invoices"
    hParams["content"] := "application/json"
    hParams["method"] := "GET"

    hRequestParam := hb_hash()
    hRequestParam["name"] := "receiptLayout"
    hRequestParam["value"] := "Slip"
    AADD(aRequestParams, hRequestParam)
    //hRequestParam["name"] := "imageFormat"
    //hRequestParam["value"] := "Png"
    //AADD(aRequestParams, hRequestParam)
    hRequestParam["name"] := "includeHeaderAndFooter"
    hRequestParam["value"] := "true"
    AADD(aRequestParams, hRequestParam)
    hParams["request_params"] := aRequestParams
    // /api/invoices/RX4F7Y5L-RX4F7Y5L-138?receiptLayout=Slip&imageFormat=Png&includeHeaderAndFooter=true'

    hCurl := curl_init(@hParams, hParams["path"] + "/" + AllTrim(cBrojRacuna), hParams["content"] , hParams["method"])
    
    nRet := curl_request(hCurl, NIL, @cData)
    curl_end()

    IF nRet <> 0
        hRet["error"] := 801
        RETURN hRet
    ENDIF
  
    nUkupnoRn := 0
    nUkupnoStorno := 0
    nCount := 0
    
    hRacun := hb_jsonDecode(cData)

    BEGIN SEQUENCE WITH {| err | Break( err ) }
 
        IF Valtype(hRacun["invoiceResponse"]) == "H" .and. ValType(hRacun["invoiceResponse"]) == "H"
            hRet["error"] := 0
        ENDIF

    
     RECOVER USING oError
        hRet["error"] := 752
        Alert( _u( "invoice_get odgovor ne sadrzi obavezna polja: invoiceRequest + invoiceResponse!" ) )
        bug_send_email_body( ;
            "CALL: " + hParams["url"] + "; path: " + hParams["path"] + "/" + AllTrim(cBrojRacuna) + "; content: " + hParams["content"] + "; method: " + hParams["method"] + NEWLINE +;
            REPLICATE("=", 95) + NEWLINE + NEWLINE +;
            "REQUEST: " + hParams["c_req_params"] + NEWLINE + NEWLINE +;
            "RESPONSE: " + cData, .F. )
        hRet["broj"] := ""
        hRet["datum"] := ""
        RETURN hRet

     END SEQUENCE

    // label E za PDV17
    cLabel := hRacun["invoiceResponse"]["taxItems"][1]["label"]
    cBrojRacunaResp := hRacun["invoiceResponse"]["invoiceNumber"]
    nPDVIznosResp := hRacun["invoiceResponse"]["taxItems"][1]["amount"]

    IF lInteractive
        IF !hb_hhaskey(hRacun, "invoiceResponse")
            Alert("Nepostojeci racun!")
            hRet["error"] := 979
            RETURN hRet

        ENDIF
        
        Alert("Racun cashier: " + hRacun["invoiceRequest"]["cashier"])

    
        IF fiskalni_tarifa(  "PDV17", "D", "OFS" ) == cLabel
        Alert( cBrojRacunaResp + ": iznos PDV17 label: " + cLabel + " iznos: " + Str(nPDVIznosResp, 8, 2))
        ENDIF
        
        // label K za PDV0
        IF fiskalni_tarifa(  "PDV0", "D", "OFS" ) == hRacun["invoiceResponse"]["taxItems"][1]["label"]
            Alert(cBrojRacunaResp + ": iznos PDV0 label: " + cLabel + " iznos: " + Str(nPDVIznosResp, 8, 2))
        ENDIF
    ENDIF

    hRet["pdv"] := hb_hash()
    hRet["pdv"]["E"] := 0.0
    hRet["pdv"]["K"] := 0.0
    hRet["pdv"]["A"] := 0.0
    hRet["pdv"][cLabel] := nPDVIznosResp

        
    //hResponseData := hb_jsonDecode(cData)
    
RETURN hRet

   
FUNCTION ofs_attention_status(hParams)

    LOCAL hRet := hb_hash(), cStatus1 

    hRet["error"] := 0
    hRet["broj"] := ""
    hRet["datum"] := ""
    hRet["json"] := ""

    IF !ofs_attention(@hParams)
        Alert("Fiskalni nije ukljucen ?! STOP!")
        hRet["error"] := FISK_NEMA_ODGOVORA
       RETURN hRet
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

RETURN hRet


FUNCTION curl_request(hCurl, cDataRequest, cData)

    LOCAL nRet

    curl_easy_setopt(hCurl, HB_CURLOPT_POSTFIELDS, cDataRequest)
            
    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "curl_ret: " + hb_ValToStr( nRet ) )
        return nRet
    ENDIF

RETURN 0


function ofs_money(nMoney)
   LOCAL cMoney := AllTrim(STR(nMoney, 12, 2))
   LOCAL nTmp := Val(cMoney)

  return round(nTmp,2)


function ofs_quantity(nMoney)
  return round(nMoney,3)


/*
   return hRet["error"] numeric
          hRet["broj"] char, hRet["datum"] char, hRet["json"] char 
 */
FUNCTION fiskalni_ofs_racun( hParams, aRacunStavke, aKupac, hKopija )

    LOCAL cVrstaPlacanja, cOperater, nTotal, nI
    LOCAL cArtikalNaz, cArtikalJmj, cArtikal, nCijena, nKolicina, cArtikalTarifa, nPopust, nPopustIznos
    LOCAL lStorno, oError, cDataRequest
    LOCAL cUrl, cPath, cContent, cMethod

    //LOCAL hParams := ofs_get_params()
    LOCAL hCurl, nRet, cData, pHeaders, cApiKey, hResponseData, hInvoiceData, hPaymentLine, hItemLine 
    LOCAL cStatus1, cInvoiceType, cTransactionType, cFullStornoRacun, cStornoFiskalniBroj, cStornoFiskalniDatum
    LOCAL hRet := hb_hash(), cReferentDocumentNumber, cReferentDocumentDT

    hRet["error"] := 0
    hRet["broj"] := ""
    hRet["datum"] := ""
    hRet["json"] := ""
    
    altd()
    cInvoiceType := "Normal"
    
    cFullStornoRacun := aRacunStavke[ 1, FISK_INDEX_FISK_RACUN_STORNIRATI ]
    cStornoFiskalniBroj := Token( cFullStornoRacun, "_", 1)
    cStornoFiskalniDatum := Token( cFullStornoRacun, "_", 2)

    IF !Empty(cStornoFiskalniBroj)
        lStorno := .T.
    ELSE
        lStorno := .F.
    ENDIF   

    cTransactionType := "Sale"
    IF lStorno
        cTransactionType := "Refund"

        // Refundacija računa ima isti sadržaj kao i originalni račun sa postavljenim poljem invoiceRequest.transactionType na Refund
        // i uz dodata dva polja u invoiceRequest objektu koja se referišu na prvi račun:
   
        // referentDocumentNumber (string) - broj originalnog računa
        // referentDocumentDT (timestamp) - vreme originalnog računa
        cReferentDocumentNumber := cStornoFiskalniBroj
        cReferentDocumentDT := cStornoFiskalniDatum

        //STEP Sale.Refund.Referent
    ENDIF

    IF hKopija != NIL
        cInvoiceType := "Copy"
        // Kopija računa ima isti sadržaj kao i originalni račun sa postavljenim 
        // poljem invoiceRequest.invoiceType na Copy i uz dodata dva polja u invoiceRequest objektu koja se referišu na prvi račun:

        // referentDocumentNumber (string) - broj originalnog računa
        // referentDocumentDT (timestamp) - vreme originalnog računa
        cReferentDocumentNumber := hKopija["fiskalni_broj"]
        cReferentDocumentDT := hKopija["fiskalni_datum"]    
    
        // Napomena:
        // Ako je racun Refund i pravimo kopiju tog racuna onda se prebrise informacija 
        // iz koraka STEP Sale.Refund.Referent 
    ENDIF

    cVrstaPlacanja := aRacunStavke[ 1, FISK_INDEX_VRSTA_PLACANJA ]
    
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
     
    hRet := ofs_attention_status(@hParams)
    if hRet["error"] <> 0
        RETURN hRet
    endif

    cUrl := hParams["url"]
    hCurl := curl_init(@hParams, cPath := "/api/invoices", cContent := "application/json", cMethod := "POST")
    
    hInvoiceData := hb_hash()

    hInvoiceData["invoiceRequest"] := hb_hash()
    
    hInvoiceData["invoiceRequest"]["invoiceType"] := cInvoiceType
    if cInvoiceType == "Copy"
        hInvoiceData["invoiceRequest"]["referentDocumentNumber"] := cReferentDocumentNumber
        hInvoiceData["invoiceRequest"]["referentDocumentDT"] := cReferentDocumentDT
    endif
    hInvoiceData["invoiceRequest"]["transactionType"] := cTransactionType
    
    hInvoiceData["invoiceRequest"]["payment"] := {}
    hPaymentLine := hb_hash()
    hPaymentLine["amount"] := ofs_money(nTotal)
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

  
    hInvoiceData["invoiceRequest"]["items"] := {}

    FOR nI := 1 TO Len( aRacunStavke )
        cArtikalNaz := aRacunStavke[ nI, FISK_INDEX_ROBANAZIV ]
        //cArtikalJmj := aRacunStavke[ nI, FISK_INDEX_JMJ ]
        //cArtikal := hb_StrToUTF8(TRIM(cArtikalNaz) + " (" + cArtikalJmj + ")")
      
        cArtikal := izbaci_nasa_slova(hb_StrToUTF8(TRIM(cArtikalNaz)))

        nCijena := aRacunStavke[ nI, FISK_INDEX_CIJENA ]
        nPopust := aRacunStavke[ nI, FISK_INDEX_POPUST ]
        nPopustIznos := aRacunStavke[ nI, FISK_INDEX_CIJENA ] - aRacunStavke[ nI, FISK_INDEX_NETO_CIJENA ]
        //nCijena := aRacunStavke[ nI, FISK_INDEX_NETO_CIJENA ]
        nKolicina := aRacunStavke[ nI, FISK_INDEX_KOLICINA ]

        cArtikalTarifa := fiskalni_tarifa( aRacunStavke[ nI, FISK_INDEX_TARIFA ], hParams[ "pdv" ], "OFS" )
        
        hItemLine := hb_hash()
        hItemLine["name"] := cArtikal
        hItemLine["labels"] := { cArtikalTarifa }
        hItemLine["totalAmount"] := ofs_money((nCijena - nPopustIznos) * nKolicina)
        hItemLine["unitPrice"] := ofs_money(nCijena)
        hItemLine["discount"] := ofs_money(nPopust)
        hItemLine["discountAmount"] := ofs_money(nPopustIznos)
        hItemLine["quantity"] := ofs_quantity(nKolicina)
        AAdd(hInvoiceData["invoiceRequest"]["items"], hItemLine)
            
    NEXT
    
    hInvoiceData["invoiceRequest"]["cashier"] := cOperater
    
    cDataRequest := hb_jsonEncode(hInvoiceData)
    //altd()
    
    nRet := curl_request(hCurl, cDataRequest, @cData)
    curl_end()

    IF nRet <> 0
       hRet["error"] = 702
       return hRet
    ENDIF
    
    
    hRet["json"] := cData
    hResponseData := hb_jsonDecode(cData)
    
    BEGIN SEQUENCE WITH {| err | Break( err ) }
 
        hRet["broj"] := hResponseData["invoiceNumber"]
        hRet["datum"] := hResponseData["sdcDateTime"]
    
     RECOVER USING oError
        Alert( _u( "Fiskalni odgovor ne sadrzi obavezna polja: invoiceNumber + sdcDateTime!" ) )
        bug_send_email_body( ;
            "CALL: " + cUrl + "; path: " + cPath + "; content: " + cContent + "; method: " + cMethod + NEWLINE +;
            REPLICATE("=", 95) + NEWLINE + NEWLINE +;
            "REQUEST:" + cDataRequest  + NEWLINE + NEWLINE +;
            "RESPONSE: " + cData, .F. )
        hRet["broj"] := ""
        hRet["datum"] := ""

     END SEQUENCE

 
RETURN hRet


FUNCTION is_ofs_fiskalni()

    LOCAL nDeviceId, hParams
 
    nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )
    IF nDeviceId == NIL
       RETURN .F.
    ENDIF

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
    
    IF Empty(cBrojFiskRacuna)
       return .F.
    ENDIF

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
 
/*
    hRet["fiskalni_broj"] := Token( cGet, "_", 1)
    hRet["fiskalni_datum"] := Token( cGet, "_", 2)
*/
FUNCTION pos_get_broj_fiskalnog_racuna_ofs( hParams )

    LOCAL cQuery, oRet, oError, hRet, cGet
    
    LOCAL cIdPos, cIdVd, dDatDok, cBrDok, nBrojFiskRacuna, cBrojFiskRacuna, cDatumFiskRacuna, cJson
    
    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]
    
    hRet := hb_hash()
    hRet["fiskalni_broj"] := ""
    hRet["fiskalni_datum"] := ""
   
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".get_broj_dat_fiskalnog_racuna_ofs(" + ;
        sql_quote( cIdPos ) + "," + ;
        sql_quote( cIdVd ) + "," + ;
        sql_quote( dDatDok ) + "," + ;
        sql_quote( cBrDok ) + ")"
    
    BEGIN SEQUENCE WITH {| err | Break( err ) }
    
        oRet := run_sql_query( cQuery )
        IF is_var_objekat_tpqquery( oRet )
            cGet := oRet:FieldGet( 1 )
            hRet := hb_hash()
            hRet["fiskalni_broj"] := Token( cGet, "_", 1)
            hRet["fiskalni_datum"] := Token( cGet, "_", 2)
        ENDIF
    
    RECOVER USING oError
        Alert( _u( "get broj fisk racuna ofs za POS: " +  cIdPos + "-" + cIdVd + "-" + cBrdok + dtoc(dDatDok) + " neuspješan?!" ) )
        QUIT_1
    END SEQUENCE
  
    RETURN hRet
    
/*
   u p2.pos_fisk_doks.ref_storno_fisk_dok postoji ovaj racun

   FUNCTION p15.pos_is_storno( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar) RETURNS boolean
*/
FUNCTION pos_is_storno_ofs( hParams )

    LOCAL cQuery, oRet, lValue 
    LOCAL cIdPos, cIdVd, dDatDok, cBrDok
    
    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]

    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_is_storno_ofs(" + ;
       sql_quote( cIdPos ) + "," + ;
       sql_quote( cIdVd ) + "," + ;
       sql_quote( dDatDok ) + "," + ;
       sql_quote( cBrDok ) + ")"
 
    oRet := run_sql_query( cQuery )
    IF is_var_objekat_tpqquery( oRet )
       lValue := oRet:FieldGet( 1 )
       IF lValue <> NIL
          RETURN lValue
       ELSE
          RETURN .F.
       ENDIF
    ENDIF
 
    RETURN .F.
 
// vraca u formatu: invoice_number || '_' || sdc_date_time
// SELECT p15.pos_storno_broj_rn( '1 ','42','2019-03-15','       8' );  =>  ABC-DE-FG_2024010203
 
FUNCTION pos_storno_broj_rn_ofs( cIdPos, cIdVd, dDatDok, cBrDok )
 
    LOCAL cQuery, oRet, cValue
 
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".pos_storno_broj_rn_ofs(" + ;
       sql_quote( cIdPos ) + "," + ;
       sql_quote( cIdVd ) + "," + ;
       sql_quote( dDatDok ) + "," + ;
       sql_quote( cBrDok ) + ")"
 
    oRet := run_sql_query( cQuery )
    IF is_var_objekat_tpqquery( oRet )
       cValue := oRet:FieldGet( 1 )
       IF cValue <> NIL
          RETURN cValue
       ELSE
          RETURN "_"
       ENDIF
    ENDIF
 
RETURN "_"


/*
   broj fiskalnog racuna koji je storno dokumenta ciji je uuid= cUUIDFiskStorniran

  PSQL FUNCTION p15.fisk_broj_rn_by_storno_ref_ofs( uuidFiskStorniran text ) RETURNS varchar
*/
FUNCTION pos_fisk_broj_rn_by_storno_ref_ofs( cUUIDFiskStorniran )

    LOCAL cQuery, oRet, cValue
 
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".fisk_broj_rn_by_storno_ref_ofs(" + ;
       sql_quote( cUUIDFiskStorniran ) +  ")"
 
    oRet := run_sql_query( cQuery )
    IF is_var_objekat_tpqquery( oRet )
        // stored procedura vraca string: invoice_number || '_' || sdc_date_time
       cValue := oRet:FieldGet( 1 )
       IF cValue <> NIL
          RETURN cValue
       ELSE
          RETURN "-"
       ENDIF
    ENDIF
 
RETURN "-"


FUNCTION pos_storno_racun_ofs( hParams )

    IF !hb_HHasKey( hParams, "datum" )
       hParams[ "datum" ] := NIL
    ENDIF
    IF !hb_HHasKey( hParams, "brdok" )
       hParams[ "brdok" ] := NIL
    ENDIF
    IF !hb_HHasKey( hParams, "idpos" )
       hParams[ "idpos" ] := pos_pm()
    ENDIF
    IF hParams[ "datum" ] == nil
       hParams[ "datum" ] := danasnji_datum()
    ENDIF
    IF hParams[ "brdok" ] == nil
       hParams[ "brdok" ] := Space( FIELD_LEN_POS_BRDOK )
    ENDIF
    hParams[ "browse" ] := .F.


    pronadji_fiskalni_racun_za_storniranje_ofs(@hParams)
    
    IF Pitanje(, "Stornirati POS " + pos_dokument( hParams ) + " [" + hParams[ "fiskalni_broj" ] + "] ?", "D" ) == "D"
        // hParams["fisk_rn"] i hParams["fisk_id"] se upisuju u _pos_pripr
        // da li nam je neophodan fisk_rn koji je numeric ? nije 
        //AAdd( aDBf, { 'fisk_rn', 'I',  4,  0 } )
        //AAdd( aDBf, { 'fisk_id', 'C',  36,  0 } )
        hParams[ "fisk_rn" ] := 999
        pos_napravi_u_pripremi_storno_dokument( hParams )
    ENDIF

    PopWa()
 
RETURN .T.


FUNCTION pronadji_fiskalni_racun_za_storniranje_ofs(hParams)
    LOCAL GetList := {}
    local hRet, cOldFiskFullRn, cMsg, cFullBroj
 
    PushWA()
    Box(, 5, 55 )
    @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum:" GET hParams[ "datum" ]
    @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Stornirati POS račun broj:" GET hParams[ "brdok" ] VALID {|| pos_lista_racuna( @hParams ), .T. }
    READ
    BoxC()
    IF LastKey() == K_ESC .OR. Empty( hParams[ "brdok" ] )
        PopWa()
        RETURN .F.
    ENDIF

    if is_fiskalizacija_off()
        // omoguciti izradu storna kad je fiskalizacija off
        // kad se vrati fiskalizacija morace se unijeti fiskalni racun koji se stornira
        hParams["fiskalni_broj"] = ""
        hParams["fiskalni_datum"] = ""
        RETURN .T.
    endif

    hParams[ "idvd" ] := "42"
    hRet := pos_get_broj_fiskalnog_racuna_ofs( hParams )
    hParams[ "fiskalni_broj" ] := hRet["fiskalni_broj"]
    hParams[ "fiskalni_datum" ] := hRet["fiskalni_datum"]
    cFullBroj := hParams[ "fiskalni_broj" ] + "_" + hParams["fiskalni_datum"]

    hParams[ "fisk_id" ] := pos_get_fiskalni_dok_id_ofs( hParams )
    // trazimo da li je vec storniranje ovog fiskalnog racuna
    IF ( cOldFiskFullRn := pos_fisk_broj_rn_by_storno_ref_ofs( hParams[ "fisk_id" ] ) ) <> "_"
        cMsg := "Već postoji storno istog RN, broj FISK: " + cOldFiskFullRn
        MsgBeep( cMsg )
        error_bar( "fisk", cMsg )
        PopWa()
        RETURN .F.
    ENDIF

    info_bar( "fisk", "Broj fiskalnog računa: " +  cFullBroj)
    IF LastKey() == K_ESC .OR. Empty(hParams[ "fiskalni_broj" ])
        MsgBeep( "Broj fiskalnog računa prazan?! Ne može storno!" )
        PopWa()
        RETURN .F.
    ENDIF
return .t.


FUNCTION pos_get_fiskalni_dok_id_ofs( hParams )

    LOCAL cQuery, oRet, cValue, cIdVd, cIdPos, dDatDok, cBrDok
 
    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]
    
    IF Empty( cIdPos )
       RETURN 0
    ENDIF
 
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".fisk_dok_id_ofs(" + ;
       sql_quote( cIdPos ) + "," + ;
       sql_quote( cIdVd ) + "," + ;
       sql_quote( dDatDok ) + "," + ;
       sql_quote( cBrDok ) + ")"
 
    oRet := run_sql_query( cQuery )
    IF is_var_objekat_tpqquery( oRet )
       cValue := oRet:FieldGet( 1 )
       IF cValue <> NIL
          RETURN cValue
       ELSE
          RETURN ""
       ENDIF
    ENDIF
 
    RETURN ""


/*
   nStorno > 0 => lStorno = .T.
   nUplaceniIznos <  0 => gledamo azurirani racun
*/
FUNCTION pos_fiskalni_stavke_racuna_ofs( hParams, hFiskParams )

    LOCAL cIdPos, cIdVd, dDatDok, cBrDok
    LOCAL aStavkeRacuna := {}
    LOCAL nPLU
    LOCAL cBrojFiskRNStorno := ""
    LOCAL nPOSRabatProcenat
    LOCAL cRobaBarkod, cIdRoba, cRobaNaziv, cJMJ
    LOCAL nRbr := 0
    LOCAL nPosRacunUkupno, nPosRacunUkupnoCheck
    LOCAL cVrstaPlacanja
    LOCAL nLevel
    LOCAL aStavka
    LOCAL lStorno
    LOCAL lTmpTabele := .T.
    LOCAL nI
    LOCAL nUplaceniIznos, lAzuriraniDokument
 

    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]
    nUplaceniIznos := hParams["uplaceno"]
    lAzuriraniDokument := hParams["azuriran"]


    // kod direktnog poziva kopije ofs fiskalnog racuna moze se desiti da nisu inicijalizovani params
    //IF hFiskParams <> NIL .and. s_hFiskalniUredjajParams == NIL
    //  init_fisk_params(hFiskParams)
    //ENDIF
 
    lStorno := !Empty( hParams["storno_fiskalni_broj"] )
 
    if !lAzuriraniDokument
       IF !seek_pos_doks_tmp( cIdPos, cIdVd, dDatDok, cBrdok)
         lTmpTabele := .F.
         IF !seek_pos_doks( cIdPos, cIdVd, dDatDok, cBrDok ) // mora postojati ažurirani pos račun
            RETURN NIL
         ENDIF
       ENDIF
    ENDIF

    cVrstaPlacanja := pos_get_vrsta_placanja_0123( pos_doks->idvrstep)
    nPosRacunUkupno := pos_iznos_racuna( cIdPos, cIdVd, dDatDok, cBrDok, lTmpTabele)
 
    IF nUplaceniIznos > 0
       nPosRacunUkupno := nUplaceniIznos
    ENDIF
 
    IF !seek_pos_pos_tmp( cIdPos, cIdVd, dDatDok, cBrDok )
      IF !seek_pos_pos( cIdPos, cIdVd, dDatDok, cBrDok )
          RETURN NIL
      ENDIF
    ENDIF
 
    nPosRacunUkupnoCheck := 0
    DO WHILE !Eof() .AND. pos->idpos == cIdPos .AND. pos->idvd == cIdVd  .AND. DToS( pos->Datum ) == DToS( dDatDok ) .AND. pos->brdok == cBrDok
 
       aStavka := Array( FISK_INDEX_LEN )
       IF lStorno
          cBrojFiskRNStorno := hParams["storno_fiskalni_broj"] + "_" + hParams["storno_fiskalni_datum"]
       ELSE
          cBrojFiskRNStorno := ""   
       ENDIF
       cIdRoba := field->idroba
 
       select_o_roba( cIdRoba )
         
       cRobaBarkod := roba->barkod
       cJMJ := roba->jmj
 
       SELECT pos
       nPOSRabatProcenat := 0
       aStavka[ FISK_INDEX_NETO_CIJENA ] := field->cijena
       IF field->ncijena > 0  // cijena = 100, ncijena = 90 (cijena sa uracunatim popustom), popust = 10%
          nPOSRabatProcenat := ( ( field->cijena - field->ncijena ) / field->cijena ) * 100
          nPOSRabatProcenat := ROUND(nPOSRabatProcenat, 2)
          aStavka[ FISK_INDEX_NETO_CIJENA ] := field->ncijena
       ENDIF
 

       cRobaNaziv := trim(roba->naz)
       aStavka[ FISK_INDEX_BRDOK ] := AllTrim(cIdPos) + "-" + AllTrim(cBrDok)
       aStavka[ FISK_INDEX_RBR ] := AllTrim( Str( ++nRbr ) )
       aStavka[ FISK_INDEX_IDROBA ] := cIdRoba
       aStavka[ FISK_INDEX_ROBANAZIV ] := cRobaNaziv
       aStavka[ FISK_INDEX_CIJENA ] := pos->cijena
       aStavka[ FISK_INDEX_KOLICINA ] := Abs( pos->kolicina ) // uvijek pozitivna vrijednost
       aStavka[ FISK_INDEX_TARIFA ] := pos->idtarifa
       // broj + _ + datum racuna koji se stornira
       aStavka[ FISK_INDEX_FISK_RACUN_STORNIRATI ] := cBrojFiskRNStorno
 
       aStavka[ FISK_INDEX_PLU ] := nPLU
       aStavka[ FISK_INDEX_PLU_CIJENA ] := pos->cijena
       
       aStavka[ FISK_INDEX_POPUST ] := nPOSRabatProcenat
       aStavka[ FISK_INDEX_BARKOD ] := cRobaBarkod
       aStavka[ FISK_INDEX_VRSTA_PLACANJA ] := cVrstaPlacanja
       aStavka[ FISK_INDEX_TOTAL ] := nPosRacunUkupno
       aStavka[ FISK_INDEX_DATUM ] := dDatDok
       aStavka[ FISK_INDEX_JMJ ] :=  cJMJ
 
       // ROUND( kolicina * cijena * (1-POPUST/100), 2)
       nPosRacunUkupnoCheck += ROUND(aStavka[ FISK_INDEX_KOLICINA ] * aStavka[ FISK_INDEX_CIJENA ] * (1 - aStavka[ FISK_INDEX_POPUST ]/100.00), 2) 
       AAdd( aStavkeRacuna, aStavka )
       SKIP
    ENDDO
 
 
    IF ROUND(nPosRacunUkupno, 2) <> ROUND(nPosRacunUkupnoCheck, 2)
       FOR nI := 1 TO LEN(aStavkeRacuna)
          // moze se desiti da je radi gresaka zaokruzenja kada ima popusta ukupan iznos koji izracuna fiskalni i ukupan iznos
          // pri pos_iznos_racuna( cIdPos, cIdVd, dDatDok, cBrDok, lTmpTabele) ima razliku
          // nPosRacunUkupnoCheck proracunava cijenu onako kako racuna fiskalni
          aStavkeRacuna[nI, FISK_INDEX_TOTAL] := nPosRacunUkupnoCheck
       NEXT
    ENDIF
 
    IF Len( aStavkeRacuna ) == 0
       MsgBeep( "Nema stavki za štampu na fiskalni uređaj !" )
       RETURN NIL
    ENDIF
 
    //nLevel := 1
    //IF provjeri_kolicine_i_cijene_fiskalnog_racuna( @aStavkeRacuna, lStorno, nLevel, s_hFiskalniUredjajParams[ "drv" ] ) < 0
    //   RETURN NIL
    //ENDIF
 
    RETURN aStavkeRacuna
 

FUNCTION pos_racun_u_pripremi_broj_storno_rn_ofs()

    LOCAL nStorno, hParams := hb_hash(), cInvoiceNumberDate, cUUID, hRet := hb_hash()
    
    PushWa()
    SELECT _pos_pripr
    GO TOP

    // AAdd( aDBf, { 'fisk_rn', 'I',  4,  0 } )
    // AAdd( aDBf, { 'fisk_id', 'C',  36,  0 } )
    cUUID := _pos_pripr->fisk_id

    hParams[ "idpos" ] := _pos_pripr->idpos
    hParams[ "idvd" ] := _pos_pripr->idvd
    hParams[ "brdok" ] := _pos_pripr->brdok
    hParams[ "datum" ] := _pos_pripr->datum
    
    cInvoiceNumberDate := pos_get_invoice_number_date_from_fisk_doks_ofs_by_uuid( cUUID )
    hRet[ "storno_fiskalni_broj" ] := Token( cInvoiceNumberDate, "_", 1)
    hRet[ "storno_fiskalni_datum" ] := Token( cInvoiceNumberDate, "_", 2)

   
    PopWa()

RETURN hRet


// CREATE OR REPLACE FUNCTION p15.set_ref_storno_fisk_dok( cIdPos varchar, cIdVd varchar, dDatDok date, cBrDok varchar, uuidFiskStorniran text ) RETURNS void

FUNCTION pos_set_ref_storno_fisk_dok_ofs( hParams, cUUIDFiskStorniran )

    LOCAL cQuery, oError

    LOCAL cIdPos, cIdVd, dDatDok, cBrDok
     
    cIdPos := hParams["idpos"]
    cIdVd := hParams["idvd"]
    dDatDok := hParams["datum"]
    cBrDok := hParams["brdok"]
    IF Empty( cIdPos )
       RETURN .F.
    ENDIF
 
    cQuery := "SELECT " + pos_prodavnica_sql_schema() + ".set_ref_storno_fisk_dok_ofs(" + ;
       sql_quote( cIdPos ) + "," + ;
       sql_quote( cIdVd ) + "," + ;
       sql_quote( dDatDok ) + "," + ;
       sql_quote( cBrDok ) + "," + ;
       sql_quote( cUUIDFiskStorniran ) +  ")"
 
    BEGIN SEQUENCE WITH {| err | Break( err ) }
       run_sql_query( cQuery )
 
    RECOVER USING  oError
       ?E oError:description
       RETURN .F.
    END SEQUENCE
 
RETURN .T.


FUNCTION pos_get_invoice_number_date_from_fisk_doks_ofs_by_uuid( cUUID )

    LOCAL cQuery, oError, oRet, cGet

    // select invoice_number || '_' || sdc_date_time from p23.pos_fisk_doks_ofs where dok_id = <cUUID>  
    cQuery := "SELECT invoice_number || '_' || sdc_date_time  from " +;
              pos_prodavnica_sql_schema() + ".pos_fisk_doks_ofs" + ;
                " WHERE dok_id = " + sql_quote( cUUID ) + "::uuid"

    
    BEGIN SEQUENCE WITH {| err | Break( err ) }
        oRet := run_sql_query( cQuery )
        IF is_var_objekat_tpqquery( oRet )
           cGet := oRet:FieldGet( 1 )
        ENDIF
 
    RECOVER USING  oError
       ?E oError:description
       RETURN ""
    END SEQUENCE
 
RETURN cGet



// https://en.wikipedia.org/wiki/Bosnian_language

// https://www.w3schools.com/charsets/ref_utf_cyrillic.asp

FUNCTION convert_cyr_to_lat( cCyrStr )
    LOCAL nFind, nI, cRet, cSlovo

    LOCAL aMap := {;
        {  Chr(208) + Chr(145), "B" }, ;
        {  Chr(208) + Chr(181), "e" }, ;
        {  Chr(208) + Chr(183), "z" }, ;
        {  Chr(32),             " " }, ;
        {  Chr(208) + Chr(159), "P" }, ;    
        {  Chr(208) + Chr(148), "D"}, ;
        {  Chr(208) + Chr(146), "V" }, ;
        {  Chr(208) + Chr(130), "Đ" }, ;
        {  Chr(208) + Chr(137), "LJ"}, ; 
        {  Chr(208) + Chr(144), "A"}, ;
        {  Chr(208) + Chr(147), "G"} ;   
    }

    // https://www.cogsci.ed.ac.uk/~richard/utf-8.cgi?input=1033&mode=decimal
    // Character 	Љ
    // UTF-8 bytes as Latin-1 characters bytes 	Ð <89> => Chr(208) + 0x89 => 137 => Chr(137)

    cRet := ""
    //FOR nI := 1 TO LEN(cCyrStr)
    //  cSlovo := SUBSTR(cCyrStr, nI, 2)
    //  nFind := Ascan(aMap[nI, 1],  cSlovo)
    //  IF nFind == 0
    //    cRet += cSlovo
    //  ELSE
    //    cRet += aMap[nI, 2]
    //  ENDIF
    //NEXT

    cRet := cCyrStr
    FOR nI := 1 TO Len(aMap)
        cRet := StrTran(cRet, aMap[nI, 1], aMap[nI, 2] )
    NEXT

    cRet := hb_Utf8ToStr(cRet)
    
RETURN cRet

FUNCTION izbaci_nasa_slova( cNaziv )
    LOCAL nFind, nI, cRet, cSlovo

    LOCAL aMap := {;
        { "Ć", "C" }, ;
        { "Š", "S" }, ;
        { "Č", "C"}, ;
        { "Đ", "DJ"} ;
    }

    // https://www.cogsci.ed.ac.uk/~richard/utf-8.cgi?input=1033&mode=decimal
    // Character 	Љ
    // UTF-8 bytes as Latin-1 characters bytes 	Ð <89> => Chr(208) + 0x89 => 137 => Chr(137)

    cRet := ""
    //FOR nI := 1 TO LEN(cCyrStr)
    //  cSlovo := SUBSTR(cCyrStr, nI, 2)
    //  nFind := Ascan(aMap[nI, 1],  cSlovo)
    //  IF nFind == 0
    //    cRet += cSlovo
    //  ELSE
    //    cRet += aMap[nI, 2]
    //  ENDIF
    //NEXT

    cRet := cNaziv
    FOR nI := 1 TO Len(aMap)
        cRet := StrTran(cRet, aMap[nI, 1], aMap[nI, 2] )
    NEXT

    //cRet := hb_Utf8ToStr(cRet)
    
RETURN cRet


