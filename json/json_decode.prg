
procedure main()
local hRet := hb_hash(), cData, hResponseData, cKey, oFile, cKey2

oFile := TFileRead():New( "test.json" )
oFile:Open()

IF oFile:Error()
      Alert( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
      RETURN .F.
ENDIF

cData := ""
DO WHILE oFile:MoreToRead()
      cData += oFile:ReadLine()
ENDDO

oFile:Close()

/*
? "==============================================================="
? cData

? "==============================================================="
*/

hResponseData := hb_jsonDecode(cData)

? "=== response keys ============:"
for each cKey in hResponseData:keys
      ? cKey

next

?
? "==== invoiceResponse keys========"
for each cKey2 in hResponseData["invoiceResponse"]:Keys
      ? cKey2
next

inke(0)

hRet["broj"] := hResponseData["invoiceResponse"]["invoiceNumber"]
hRet["datum"] := hResponseData["invoiceResponse"]["sdcDateTime"]

? "=========== odgovor ====="
? hRet["broj"]
? hRet["datum"]

return    
