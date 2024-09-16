#include "hbcurl.ch"

#DEFINE OFS_URL   "http://ofs.svc.test.out.ba:8000"
#DEFINE OFS_API_KEY "0123456789abcdef0123456789abcdef"

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

FUNCTION ofs_create_invoice()

    LOCAL hCurl, nRet, cData, pHeaders, cApiKey, hResponseData, hInvoiceData, hPaymentLine, hItemLine 

    curl_global_init()

    hInvoiceData := hb_hash()
    // --data '{
    // "invoiceRequest": {
    //     "invoiceType": "Normal",
    //     "transactionType": "Sale",
    //     "payment": [
    //         {
    //             "amount": 100.00,
    //             "paymentType": "Cash"
    //         }
    //     ],
    //     "items": [
    //         {
    //             "name": "Artikl 1",
    //             "labels": [
    //                 "F"
    //             ],
    //             "totalAmount": 100.00,
    //             "unitPrice": 50.00,
    //             "quantity": 2.000
    //         }
    //     ],
    //     "cashier": "Radnik 1"
    // }
    // }
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
    
    if empty( hCurl := curl_easy_init() )
        MsgBeep( "curl init neuspjesan ?!")
    endif

    cApiKey := OFS_API_KEY
    
    //If there's an authorization token, you attach it to the header like this:
    
    //Set the URL:
    curl_easy_setopt( hCurl, HB_CURLOPT_URL, OFS_URL + "/api/invoices" )  
    curl_easy_setopt( hCurl, HB_CURLOPT_CUSTOMREQUEST, "POST" )  
        
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
    curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, ;
        { ;
          "Authorization: Bearer " + cApiKey,    ;
          "Content-Type: application/json" ;
        })
    
    cData := hb_jsonEncode(hInvoiceData)
    altd()

    curl_easy_setopt(hCurl, HB_CURLOPT_POSTFIELDS, cData)
            
    //Sending the request and getting the response
    IF ( nRet:= curl_easy_perform( hCurl ) ) == 0
        cData := curl_easy_dl_buff_get( hCurl )
    ELSE
        Alert( "curl_ret: " + hb_ValToStr( nRet ) )
    ENDIF
      
      
    //Cleaning the curl instance
    curl_global_cleanup()   
    
    //I'm using hb_jsonDecode() so I can decode the responde into a JSON object
    hResponseData := hb_jsonDecode(cData)
    
    altd()
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
    RETURN NIL
