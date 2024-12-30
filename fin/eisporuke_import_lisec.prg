#include "f18.ch"


FUNCTION fin_lisec_find_partner( cAccountId, cClientName, cClientCountry, cRegNo, cGoni, cTaxNumber)

   LOCAL hRet := hb_hash()
   LOCAL aPovezane
   //lisecrn->accountid, lisecrn->client_name, lisecrn->client_country, lisecrn->reg_no, lisecrn->goni

   // get_partn_pdvb( cPartnerId )
   // AllTrim( get_partn_sifk_sifv( "PDVB", cPartnerId, .F. ) )
   hRet["pdv"] := .F.
   hRet["ino"] := .F.
   hRet["povezano_lice"] := .F.
   aPovezane := { PADR("0589", 6), PADR("3171", 6), PADR("3458",6), PADR("7437", 6), PADR("586268",6) }

   Alert("not implemented!")

   IF cRegNo == "999999999999"
      hRet["id_partner"] := "GOTOVINA"
      RETURN hRet
   ENDIF

   IF !Empty(cRegNo)
      PushWa()
      SELECT (F_SIFV)
      use_sql_sifv( "PARTN", "PDVB", NIL, cRegNo )
      PopWa()
      IF !Empty(sifv->idsif)
            // PDV obveznik
            hRet["id_partner"] := LEFT(sifv->idsif, 6)
            IF Ascan( aPovezane, hRet["id_partner"] ) <> 0
               hRet["povezano_lice"] := .T.
            ENDIF 
            hRet["pdv"] := .T.
            RETURN hRet 
      ENDIF
      IF TRIM(cClientName) == "KP" .OR. TRIM(cClientName) == "KPM"
         hRet["id_partner"] := "GOTOVINA"
         RETURN hRet
      ENDIF
   ENDIF

   IF !Empty(cRegNo)
      PushWa()
      SELECT (F_SIFV)
      use_sql_sifv( "PARTN", "IDBR", NIL, cGoni )
      PopWa()
      IF !Empty(sifv->idsif)
         // Kupac ima ID broj - NE-PDV obveznik
         hRet["id_partner"] := LEFT(sifv->idsif, 6)
         hRet["pdv"] := .F.
         RETURN hRet
      ENDIF
   ENDIF

   IF cTaxNumber == "G2" // G1 domaci
      hRet["ino"] := .T.
   ENDIF

   PushWa()
   SELECT (F_PARTN)
   find_partner_by_naz_or_id( upper(cClientName) )
   PopWa()

   IF partn->(reccount()) == 1
      // partner pronadjen po nazivu
      hRet["id_partner"] := partn->id
      IF partner_is_ino( hRet["id_partner"] )
          hRet["ino"] := .T.
      ELSE
          hRet["ino"] := .F.
      ENDIF
      RETURN hRet
   ENDIF

   hRet["id_partner"] := REPLICATE("?", 6)
   RETURN hRet
 


FUNCTION fin_lisec_get_fin_stavke( cFaktAvAvStor, dDatod, dDatDo)

   LOCAL cTableName
   LOCAL cAlias := "LISECRN"
   LOCAL cQry 
   LOCAL lError := .F.
   LOCAL nRbr, hFinItem, hFinItemPDV, hFinItemPrihod, cIdPartner
   LOCAL aFinItems := {}
   LOCAL cIdKonto, cIdKontoPDV, cIdKontoPrihod
   LOCAL hPartner, cSufix

   
   //IF cFaktAvAvStor == "1"
   //   cSufix := "IN"

   cQry := "select * from " + cTableName


   SELECT( F_POM )
   MsgO("Preuzimanje " + cTableName + " sa LISEC servera")
      IF !use_sql( "lisecrn", cQry, cAlias )
        lError := .T.
      ENDIF
   MsgC()

   IF lError
      Alert(_u("Greška pri preuzimanju " + cTableName + " ?!" ))
      RETURN .F.
   ENDIF

   nRbr := 1
   Box(, 3, 80)
      @ box_x_koord(), box_y_koord() + 10 SAY STR(lisecrn->(reccount()), 5, 0)

      DO WHILE !EOF()

         IF cFaktAvAvStor == "2" .AND. lisecrn->type_id <> 0
            // typeid = 0 su regularne avansne fakture
            SKIP
            LOOP
         ENDIF

         IF cFaktAvAvStor == "3" .AND. lisecrn->type_id <> 1
            // typeid = 1 su storno avansne fakture
            SKIP
            LOOP
         ENDIF

         hPartner := fin_lisec_find_partner( lisecrn->accountid, lisecrn->client_name, lisecrn->client_country, lisecrn->reg_no, lisecrn->goni, lisecrn->c_tax_number )

         IF hPartner["id_partner"] == "GOTOVINA"
            //cIdPartner := ""
            //cIdKonto := "20500" // blagajna ?
            //cIdKontoPDV := Padr("4730", 7)
            //cIdKontoPrihod := Padr("61101", 7)
            SKIP
            LOOP
            // preskacemo KP i KPM, to se posebno unosi u 66 FIN naloge
         ENDIF

         cIdPartner := hPartner["id_partner"]
         cIdKonto := Padr("2110", 7)
         IF hPartner["pdv"]
            cIdKontoPDV := Padr("4700", 7)
            cIdKontoPrihod := Padr("6110", 7)
         ELSE
            // Partner ne-PDV obveznik
            cIdKontoPDV := Padr("4730", 7)
            cIdKontoPrihod := Padr("61101", 7)
         ENDIF

         IF hPartner["ino"] // ino partner
            cIdKonto := Padr("2120", 7)
            cIdKontoPrihod := Padr("6120", 7)
         ENDIF
         
         IF hPartner["povezano_lice"] // povezana pravna lica
            cIdKonto := "2100"
            cIdKontoPrihod := "6100"
         ENDIF

         IF trim(lisecrn->client_name) == "FL-BANKINO"
            // uplata banka ino partner
            cIdKonto := "2123"
         ENDIF
         
         IF trim(lisecrn->client_name) == "FL-BANK"
            // uplata banka domaci klijent
            cIdKonto := "2118"
         ENDIF

         IF cFaktAvAvStor <> "1"
            // avansne fakture
            IF hPartner["pdv"]
               cIdKontoPDV := "4710"
            ELSE
               cIdKontoPDV := "47101" // ne-PDV obveznik
            ENDIF
            cIdKontoPrihod := "4340" // partner koji je uplatio
         ENDIF

         hFinItem := hb_hash()
         hFinItem[ "idfirma" ] := self_organizacija_id()
         hFinItem[ "idvn" ] := "14"
         hFinItem[ "brnal" ] := PadL( 0, 8, "0" )
         hFinItem[ "brdok" ] := lisecrn->order_number
         IF cFaktAvAvStor == "1"
            hFinItem[ "opis" ] := "RN. " + AllTrim(lisecrn->order_number)  + ", FISK_RN " + Alltrim(lisecrn->fiscal_number) + ""
         ELSE
            IF cFaktAvAvStor == "2"
               // AV.RN. (RC036046)
               hFinItem[ "opis" ] := "AV.RN."
            ELSEIF cFaktAvAvStor == "3"
               // ST.AV. (RC036046/S)
               hFinItem[ "opis" ] := "ST.AV."
            ENDIF   
            hFinItem[ "opis" ] += " " + AllTrim(lisecrn->order_number) + " "
         ENDIF
         hFinItem[ "datdok" ] := lisecrn->inv_date
         hFinItem[ "datval" ] := lisecrn->pay_date
         hFinItem[ "konto" ] := cIdKonto
         hFinItem[ "partner" ] := cIdPartner
         hFinItem[ "d_p" ] := "1"
         hFinItem[ "iznos" ] := lisecrn->inv_tot_excl + lisecrn->inv_tot_tax
         IF cFaktAvAvStor == "3" // storno avansne fakture RC
            hFinItem[ "iznos" ] := hFinItem[ "iznos" ] * -1
         ENDIF 
         
         hFinItem[ "rbr" ] := nRbr
         ++nRbr
         AADD( aFinItems, hFinItem)

         IF cIdPartner == REPLICATE("?", 6)
            hFinItem[ "opis" ] += " ; " + trim(lisecrn->client_name) + " " + trim(lisecrn->client_country)
         ENDIF

         hFinItemPDV := hb_HClone(hFinItem)
         hFinItemPDV[ "datval" ] := CTOD("")
         hFinItemPDV[ "konto" ] := cIdKontoPDV
         hFinItemPDV[ "iznos" ] := lisecrn->inv_tot_tax
         IF cFaktAvAvStor == "3" // storno RC
            hFinItemPDV[ "iznos" ] := hFinItemPDV[ "iznos" ] * -1
         ENDIF
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
         hFinItemPrihod[ "iznos" ] := lisecrn->inv_tot_excl
         IF cFaktAvAvStor == "3" // storno RC
            hFinItemPrihod[ "iznos" ] := hFinItemPrihod[ "iznos" ] * -1
         ENDIF

         hFinItemPrihod[ "d_p" ] := "2"
         hFinItemPrihod[ "rbr" ] := nRbr
         hFinItemPrihod[ "partner" ] := SPACE(6)
         
         IF cFaktAvAvStor <> "1" 
            // avansne fakture
            hFinItemPrihod[ "opis" ] += "ENAB: PRESKOCI"
            hFinItemPrihod[ "partner" ] := cIdPartner
         ENDIF
         
         AADD( aFinItems, hFinItemPrihod)
         ++nRbr
         
         @ box_x_koord() + 2, box_y_koord() + 3 SAY "Rbr: " + Alltrim(Str(nRbr, 6, 0))
         SKIP

      ENDDO
   BoxC()

   
   RETURN aFinItems


FUNCTION fin_lisec_import()

   LOCAL dDatOd := fetch_metric("fin_lisec_od", my_user(), Date()), dDatDo := fetch_metric("fin_lisec_do", my_user(), Date())
   LOCAL GetList := {}
   LOCAL nRbr, aFinItems
   LOCAL cFaktAvAvStor := "1"

   Box(, 3, 60)
     @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od" GET dDatOd
     @ box_x_koord() + 1, col() + 2 SAY "do"  GET dDatDo
     //@ box_x_koord() + 3, box_y_koord() + 2 SAY "Fakture (1)/Avans (2)/Avans-Storno (3)"  GET cFaktAvAvStor VALID cFaktAvAvStor $ "123"
     @ box_x_koord() + 3, box_y_koord() + 2 SAY "Fakture (1)"  GET cFaktAvAvStor VALID cFaktAvAvStor $ "1"
     
     READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

  
   aFinItems := fin_lisec_get_fin_stavke(cFaktAvAvStor, dDatod, dDatDo)

   FOR nRbr := 1 TO LEN( aFinItems )
      fin_lisec_pripr_fill( aFinItems[ nRbr ] )
   NEXT

   set_metric("fin_lisec_od", my_user(), dDatOd)
   set_metric("fin_lisec_do", my_user(), dDatDo)
   
   RETURN .T.


STATIC FUNCTION fin_lisec_pripr_fill( hFinItem )

   LOCAL dDatVal
   Box(, 2, 50)
   select_o_fin_pripr()
   APPEND BLANK

   @ box_x_koord() + 1, box_y_koord() + 2 SAY STR(hFinItem[ "rbr" ], 5, 0)
   IF LEFT(hFinItem[ "brdok" ], 2) == "IN"
      dDatVal := hFinItem[ "datval" ]
   ELSE
      dDatVal := CTOD("")
   ENDIF

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


FUNCTION fin_lisec_active()

   IF !Empty(fetch_metric( "fin_lisec_host", NIL, "" ))
     RETURN .T.
   ENDIF

   RETURN .F.

/*
FUNCTION fin_parametri_import_lisec()

    LOCAL nX := 1
    LOCAL cHost := PADR(fetch_metric( "fin_lisec_host", NIL, "" ), 30)
    LOCAL cUser := PADR(fetch_metric( "fin_lisec_user", NIL, "" ), 30)
    LOCAL cPassword := PADR(fetch_metric( "fin_lisec_password", NIL, "" ), 30)
    LOCAL cDatabase := PADR(fetch_metric( "fin_lisec_db", NIL, "" ), 30)
    LOCAL GetList := {}
 
    Box(, 10, 70 )
 
    SET CURSOR ON
 
    @ box_x_koord() + nX, box_y_koord() + 2 SAY "  PRAMETRI LISEC -> F18:"
 
    nX += 2
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "LISEC Host:" GET cHost
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "      user:" GET cUser
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  password:" GET cPassword
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  Database:" GET cDatabase

    READ
    BoxC()
 
    IF LastKey() <> K_ESC
       set_metric( "fin_lisec_host", NIL, cHost )
       set_metric( "fin_lisec_user", NIL, cUser )
       set_metric( "fin_lisec_password", NIL, cPassword )
       set_metric( "fin_lisec_db", NIL, cDatabase )

    ENDIF
 
    RETURN .T.
*/ 