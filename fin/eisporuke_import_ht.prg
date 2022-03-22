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
   LOCAL nPDVStopa

   cQry := "select brdok, datdok, idpartner, dindem, idroba, txt, kolicina, cijena,"
   cQry += "COALESCE(substring( UPPER(txt),'(?:VOZ.*REG.*TAB.*|VOZ.*REG.*OZN.*|REG.*OZN.*VOZ.*)\s*([A-Z0-9a-z]{3,4}\-[A-Z0-9a-z]{1,2}\-[A-Z0-9a-z]{3,4})'),'') as regbr,"
   cQry += "COALESCE(substring(UPPER(txt),'(?:OSLOB.*PLA.*PDV.*PO.*LAN.*|NIJE.*OBR.*PDV.*PO.*LAN.*)(\d{2})\s*\..*PDV'), '') as clan"
   cQry += " FROM fmk.fakt_fakt"
   cQry += " WHERE idtipdok='10' and datdok BETWEEN " + sql_quote( dDatOd ) + " AND " + sql_quote( dDatDo )
   cQry += " AND rbr::INTEGER = 1"

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

        nPDVStopa := 0
        cIdPartner := htfakt->idpartner
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
           altd()
           lPDV := .F.
           nPDVStopa := 0.00
        ENDIF
    
        cIdKonto := Padr("2110", 7)
        IF lPDV
            cIdKontoPDV := Padr("4700", 7)
            cIdKontoPrihod := Padr("6110", 7)
         ELSE
            // Partner ne-PDV obveznik
            cIdKontoPDV := Padr("4730", 7)
            cIdKontoPrihod := Padr("61101", 7)
         ENDIF

         IF lIno
            cIdKonto := Padr("2120", 7)
            cIdKontoPrihod := Padr("6120", 7)
         ENDIF
         
         IF ht_povezana_lica(cIdPartner)
            cIdKonto := "2100"
            cIdKontoPrihod := "6100"
         ENDIF

         altd()
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
         hFinItem[ "iznos" ] := ROUND(htfakt->cijena * htfakt->kolicina * (1 + nPDVStopa/100.00), 2)
         hFinItem[ "rbr" ] := nRbr
         ++nRbr
         AADD( aFinItems, hFinItem)


         hFinItemPDV := hb_HClone(hFinItem)
         hFinItemPDV[ "datval" ] := CTOD("")
         hFinItemPDV[ "konto" ] := cIdKontoPDV
         hFinItemPDV[ "iznos" ] := Round(htfakt->cijena * htfakt->kolicina * nPDVStopa/100.00, 2)
         hFinItemPDV[ "d_p" ] := "2"
         hFinItemPDV[ "rbr" ] := nRbr
         hFinItemPDV[ "partner" ] := SPACE(6)
         IF Round(hFinItemPDV[ "iznos" ], 2) <> 0 
            AADD( aFinItems, hFinItemPDV)
            ++nRbr
         ENDIF

         
         hFinItemPrihod := hb_HClone(hFinItem)
         hFinItemPrihod[ "datval" ] := CTOD("")
         hFinItemPrihod[ "konto" ] := cIdKontoPrihod
         hFinItemPrihod[ "iznos" ] := htfakt->cijena * htfakt->kolicina 

         hFinItemPrihod[ "d_p" ] := "2"
         hFinItemPrihod[ "rbr" ] := nRbr
         hFinItemPrihod[ "brdok"] := htfakt->regbr
         hFinItemPrihod[ "partner" ] := SPACE(6)
         
         //IF cFaktAvAvStor <> "1" 
            // avansne fakture
         //   hFinItemPrihod[ "opis" ] += "ENAB: PRESKOCI"
         //   hFinItemPrihod[ "partner" ] := cIdPartner
         //ENDIF
         
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
   LOCAL aPovezane := { PADR("1805", 6), PADR("0589", 6), PADR("3171", 6), PADR("3458",6), PADR("7437", 6), PADR("586268",6) }

   IF Ascan( aPovezane, cIdPartner ) <> 0
        lPovezano := .T.
   ENDIF

   RETURN lPovezano


