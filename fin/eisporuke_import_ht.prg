#include "f18.ch"


FUNCTION fin_ht_get_fin_stavke(dDatod, dDatDo)

   LOCAL cTableName
   LOCAL cAlias := "HTFAKT"
   LOCAL cQry 
   LOCAL lError := .F.
   LOCAL nRbr, hFinItem, hFinItemPDV, hFinItemPrihod, cIdPartner
   LOCAL aFinItems := {}
   LOCAL cIdKonto, cIdKontoPDV, cIdKontoPrihod
   LOCAL lIno, lPDV, cSufix, hTxt
   LOCAL nPDVStopa, lPdvObveznik

   cQry := "select fakt_fakt.brdok, fakt_fakt.datdok, fakt_fakt.idpartner, fakt_fakt.dindem, fakt_fakt.idroba, fakt_fakt.txt, fakt_fakt.kolicina, fakt_fakt.cijena,"
   cQry += "fakt_doks.iznos - fakt_doks.rabat as neto, fakt_fakt.rbr::INTEGER,"
   cQry += "COALESCE(substring( UPPER(txt),'(?:VOZ.*REG.*TAB.*|VOZ.*REG.*OZN.*|REG.*OZN.*VOZ.*)[:]\s*([A-Z0-9a-z]{3,4}\-[A-Z0-9a-z]{1,2}\-[A-Z0-9a-z]{3,4})'),'') as regbr,"
   cQry += "COALESCE(substring(UPPER(txt),'(?:OSLOB.*PLA.*PDV.*PO.*LAN.*|NIJE.*OBR.*PDV.*PO.*LAN.*)(\d{2})\s*\..*PDV'), '') as clan"
   cQry += " FROM fmk.fakt_fakt"
   cQry += " LEFT join fmk.fakt_doks on fmk.fakt_doks.brdok=fmk.fakt_fakt.brdok"

   cQry += " WHERE fakt_fakt.idtipdok='10' and fakt_fakt.datdok BETWEEN " + sql_quote( dDatOd ) + " AND " + sql_quote( dDatDo )
   //cQry += " AND rbr::INTEGER = 1"
   cQry += " ORDER BY fmk.fakt_fakt.brdok, fmk.fakt_fakt.rbr::INTEGER"

   SELECT( F_POM )
   MsgO("Preuzimanje podataka sa servera")
      IF !use_sql( "htfakt", cQry, cAlias )
        lError := .T.
      ENDIF
   MsgC()

   IF lError
      Alert(_u("Greška pri preuzimanju " + cTableName + " ?!" ))
      RETURN .F.
   ENDIF

   nRbr := 1
   Box(, 3, 80)
      @ box_x_koord(), box_y_koord() + 10 SAY STR(htfakt->(reccount()), 5, 0)

      DO WHILE !EOF()

        IF htfakt->rbr == 1 // kupac i PDV samo iz prve stavke 
         nPDVStopa := 0
         cIdPartner := htfakt->idpartner
         lPdvObveznik := partner_is_pdv_obveznik( cIdPartner )

         IF partner_is_ino( cIdPartner )
               lIno := .T.
               lPDV := .F.
         ELSE
               lIno := .F.
               lPDV := .T.
         ENDIF

         // UP1 - PDV17
         IF TRIM(htfakt->idroba) == 'UP1'
               lPDV := .T.
               nPDVStopa := 17.00
         ENDIF

         IF !Empty(htfakt->clan)
            lPDV := .F.
            nPDVStopa := 0.00
         ENDIF
      
         cIdKonto := Padr("2112", 7)
         IF lPDV 
            IF lPdvObveznik
               cIdKontoPDV := Padr("4700", 7)
               cIdKontoPrihod := Padr("6210", 7)
            ELSE
               // Partner ne-PDV obveznik
               cIdKontoPDV := Padr("4730", 7)
               cIdKontoPrihod := Padr("62101", 7)
            ENDIF
         ENDIF

         IF lIno
               cIdKonto := Padr("2122", 7)
               cIdKontoPrihod := Padr("6220", 7)
         ENDIF

         IF lPdvObveznik .AND. !lPDV // PDV obveznik nepovezano pravno lice, oslobodjen po nekom clanu PDVa-
            cIdKonto := Padr("2112", 7)
            cIdKontoPrihod := Padr("6220", 7)
         ENDIF

         IF ht_povezana_lica(cIdPartner)
               cIdKonto := "2100"
               cIdKontoPrihod := "6200"
               IF !Empty(htfakt->clan) // oslobodjenje po clanovima 26, 27, 30
                  cIdKontoPrihod := Padr("62001", 7)
               ENDIF
         ENDIF
            
         hTxt := fakt_ftxt_decode_string( htfakt->txt )

         hFinItem := hb_hash()
         hFinItem[ "idfirma" ] := self_organizacija_id()
         hFinItem[ "idvn" ] := "14"
         hFinItem[ "brnal" ] := PadL( 0, 8, "0" )
         hFinItem[ "brdok" ] := htfakt->brdok
            
         hFinItem[ "opis" ] := "RN. " + AllTrim(htfakt->brdok)

         IF !Empty(htfakt->clan)
            hFinItem[ "opis"] += ", PDV0: CLAN" + htfakt->clan
         ENDIF
            
         hFinItem[ "datdok" ] := htfakt->datdok
         hFinItem[ "datval" ] := hTxt["datpl"]

         hFinItem[ "konto" ] := cIdKonto
         hFinItem[ "partner" ] := cIdPartner
         hFinItem[ "d_p" ] := "1"
         //hFinItem[ "iznos" ] := ROUND(htfakt->cijena * htfakt->kolicina * (1 + nPDVStopa/100.00), 2)
         hFinItem[ "iznos" ] := ROUND(htfakt->neto * (1 + nPDVStopa/100.00), 2)
         hFinItem[ "rbr" ] := nRbr

         ++nRbr
         AADD( aFinItems, hFinItem)

         hFinItemPDV := hb_HClone(hFinItem)
         hFinItemPDV[ "datval" ] := CTOD("")
         hFinItemPDV[ "konto" ] := cIdKontoPDV
         //hFinItemPDV[ "iznos" ] := Round(htfakt->cijena * htfakt->kolicina * nPDVStopa/100.00, 2)
         hFinItemPDV[ "iznos" ] := Round(htfakt->neto * nPDVStopa/100.00, 2)
         hFinItemPDV[ "d_p" ] := "2"
         hFinItemPDV[ "rbr" ] := nRbr
         hFinItemPDV[ "partner" ] := SPACE(6)
         IF htfakt->rbr == 1 // kupac i PDV samo iz prve stavke
            IF Round(hFinItemPDV[ "iznos" ], 2) <> 0 
               AADD( aFinItems, hFinItemPDV)
               ++nRbr
            ENDIF
         ENDIF

        ENDIF // stavka broj 1 
       
        hFinItemPrihod := hb_HClone(hFinItem)
        hFinItemPrihod[ "datval" ] := CTOD("")
        hFinItemPrihod[ "konto" ] := cIdKontoPrihod
        hFinItemPrihod[ "iznos" ] := htfakt->cijena * htfakt->kolicina 

        hFinItemPrihod[ "d_p" ] := "2"
        hFinItemPrihod[ "rbr" ] := nRbr
        hFinItemPrihod[ "brdok"] := htfakt->regbr
        hFinItemPrihod[ "partner" ] := SPACE(6)

        AADD( aFinItems, hFinItemPrihod)
        ++nRbr
         
        @ box_x_koord() + 2, box_y_koord() + 3 SAY "Rbr: " + Alltrim(Str(nRbr, 6, 0))
        SKIP

      ENDDO
   BoxC()

 
   RETURN aFinItems


FUNCTION fin_ht_import()

   LOCAL dDatOd := fetch_metric("fin_ht_od", my_user(), Date()), dDatDo := fetch_metric("fin_ht_do", my_user(), Date())
   LOCAL GetList := {}
   LOCAL nRbr, aFinItems
   

   Box(, 3, 60)
     @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od" GET dDatOd
     @ box_x_koord() + 1, col() + 2 SAY "do"  GET dDatDo
     READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   altd()

   aFinItems := fin_ht_get_fin_stavke(dDatod, dDatDo)
   altd()

   FOR nRbr := 1 TO LEN( aFinItems )
      fin_ht_pripr_fill( aFinItems[ nRbr ] )
   NEXT

   set_metric("fin_ht_od", my_user(), dDatOd)
   set_metric("fin_ht_do", my_user(), dDatDo)
   
   RETURN .T.


STATIC FUNCTION fin_ht_pripr_fill( hFinItem )

   LOCAL dDatVal
   Box(, 2, 50)
   select_o_fin_pripr()
   APPEND BLANK

   @ box_x_koord() + 1, box_y_koord() + 2 SAY STR(hFinItem[ "rbr" ], 5, 0)
   dDatVal := hFinItem[ "datval" ]


   RREPLACE idfirma WITH hFinItem[ "idfirma" ], ;
            idvn WITH hFinItem[ "idvn" ], ;
            brnal WITH hFinItem[ "brnal" ], ;
            brdok WITH hFinItem[ "brdok" ], ;
            opis WITH hFinItem[ "opis" ], ;
            rbr WITH hFinItem[ "rbr" ], ;
            datdok WITH hFinItem[ "datdok" ], ;
            datval WITH dDatVal, ;
            idkonto WITH hFinItem[ "konto" ], ;
            idpartner WITH hFinItem[ "partner" ], ;
            d_p WITH hFinItem[ "d_p" ], ;
            iznosbhd WITH hFinItem[ "iznos" ], ;
            iznosdem WITH fin_km_to_eur(hFinItem["iznos"], hFinItem["datdok"])
   
   BoxC()

   RETURN .T.

FUNCTION is_ht()

  IF "HANO TRANS" $ self_organizacija_naziv()
      RETURN .T.
  ENDIF

  RETURN .F.

 
STATIC FUNCTION ht_povezana_lica(cIdPartner)

   LOCAL lPovezano := .F.
   LOCAL aPovezane := { PADR("20", 6), PADR("0001", 6), PADR("1000", 6), PADR("1805", 6), PADR("7874", 6) }

   IF Ascan( aPovezane, cIdPartner ) <> 0
        lPovezano := .T.
   ENDIF

   RETURN lPovezano


