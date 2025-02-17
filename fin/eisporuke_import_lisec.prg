#include "f18.ch"


FUNCTION fin_lisec_find_partner( cIdPartner, cClientName, cKupacDrzava )

   LOCAL hRet := hb_hash()
   LOCAL aPovezane, cPdvBroj, cIdBroj
   //lisecrn->accountid, lisecrn->client_name, lisecrn->client_country, lisecrn->reg_no, lisecrn->goni

   // get_partn_pdvb( cPartnerId )
   // AllTrim( get_partn_sifk_sifv( "PDVB", cPartnerId, .F. ) )
   hRet["pdv"] := .F.
   hRet["ino"] := .F.
   hRet["povezano_lice"] := .F.
   aPovezane := { PADR("0589", 6), PADR("3171", 6), PADR("3458",6), PADR("7437", 6), PADR("586268",6) }


   cPdvBroj := firma_pdv_broj( cIdPartner )
   cIdBroj := firma_id_broj( cIdPartner )

   IF cPDVBroj == "999999999999"
      hRet["id_partner"] := "GOTOVINA"
      RETURN hRet
   ENDIF

   IF TRIM(cClientName) == "KP" .OR. TRIM(cClientName) == "KPM"
      hRet["id_partner"] := "GOTOVINA"
      RETURN hRet
   ENDIF

   IF !Empty(cPdvBroj)
      PushWa()
      SELECT (F_SIFV)
      use_sql_sifv( "PARTN", "PDVB", NIL, cPdvBroj )
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
   ENDIF

   IF Len(cPdvBroj) <> 12 .and. Len(cIdBroj) == 13
      // Kupac ima ID broj - NE-PDV obveznik
      hRet["id_partner"] := LEFT(cIdPartner, 6)
      hRet["pdv"] := .F.
      RETURN hRet
   ENDIF

   IF cKupacDrzava != "Bosnia-Herzegovina"
      hRet["ino"] := .T.
   ENDIF

   //PushWa()
   //SELECT (F_PARTN)
   //find_partner_by_naz_or_id( upper(cClientName) )
   //PopWa()

   /*
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
   */

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

   LOCAL nUkupnoSaPDV, nOsnovica, nPDV

   //IF cFaktAvAvStor == "1"
   //   cSufix := "IN"

/*
select ih_invoice_no as broj_racuna, 
   rech.rg_info4 as broj_fiskalnog_racuna,
   (case when ih_type = 5 then 'STORNO' else 'PLUS' end) as storno_plus, 
   ih_cust_no as lisec_broj_kupca,
   kust.ku_land as zemlja,
   ih_curr_code as valuta, 
   ih_curr_rate as omjer,
   kust_adr.ku_name as ime_kupca,
   it.invoice_tot_net as iznos_bez_pdv, 
   it.invoice_tot_vat as ukupno_pdv,
   it.inv_tot_date::date as datum_fakture,
   datval.ipp_due_date::date as datum_valute
from fmk.lisec_invoice_header ih   
  left join fmk.lisec_kust kust on (kust.kunr = ih.ih_cust_no and kust.kust_manu_site='RAMA-GLAS')
  left join fmk.lisec_kust_adr kust_adr on (kust_adr.ku_nr  = kust.kunr and kust_adr.ku_vk_ek=0)
  left join fmk.lisec_invoice_totals it  on  it.invoice_no = ih.ih_invoice_no 
  left join fmk.lisec_rechnung_daten rech on rech.rg_nr = ih.ih_invoice_no
  left join fmk.lisec_invoice_partial_payments datval on datval.ipp_invoice_no = ih.ih_invoice_no 
  where ih_invoice_no = 2001396
  
  


   select ih_invoice_no as broj_racuna,rech.rg_info4 as broj_fiskalnog_racuna,
      (case when ih_type = 5 then 'STORNO' else 'PLUS' end) as storno_plus,
      ih_cust_no as lisec_broj_kupca,fmk.partn.id idpartner,kust.ku_land as kupac_drzava,
      kust_adr.ku_name as ime_kupca,
      ih_curr_code as valuta,ih_curr_rate as omjer,
      it.invoice_tot_net as iznos_bez_pdv,it.invoice_tot_vat as ukupno_pdv,
      it.inv_tot_date::date as datum_fakture,datval.ipp_due_date::date as datum_valute,
      kust_adr.*
   from fmk.lisec_invoice_header ih 
   left join fmk.lisec_kust kust on (kust.kunr = ih.ih_cust_no and trim(kust.kust_manu_site) in ('','RAMA-GLAS'))
   left join lateral (select * from fmk.lisec_kust_adr where fmk.lisec_kust_adr.ku_nr=kust.kunr and fmk.lisec_kust_adr.ku_vk_ek=0 and fmk.lisec_kust_adr.ku_name is not null limit 1) kust_adr on true
   left join fmk.lisec_invoice_totals it on it.invoice_no = ih.ih_invoice_no 
   left join fmk.lisec_rechnung_daten rech on rech.rg_nr = ih.ih_invoice_no 
   left join fmk.lisec_invoice_partial_payments datval on datval.ipp_invoice_no = ih.ih_invoice_no 
   LEFT JOIN fmk.partn on trim(kust.kust_kto_buch)=trim(fmk.partn.id) 
   WHERE it.inv_tot_date::date>='2025-01-31' and it.inv_tot_date::date<='2025-01-31'
         and (ih_invoice_no between 2000000 and 2999999)
         and rech.rg_info4 like '%22839%'
   ORDER BY rech.rg_info4

*/

if cFaktAvAvStor == "1" // fakture

   cQry := "select ih_invoice_no as broj_racuna," 
   cQry += "rech.rg_info4 as broj_fiskalnog_racuna,"
   //(case when ih_type = 5 then 'STORNO' else 'PLUS' end) as storno_plus, 
   cQry += "(case when ih_type = 5 then 'STORNO' else 'PLUS' end) as storno_plus," 
   cQry += "ih_cust_no as lisec_broj_kupca,"
   cQry += "fmk.partn.id idpartner,"
   
   cQry += "kust.ku_land as kupac_drzava,"
   cQry += "kust_adr.ku_name as ime_kupca,"

   cQry += "ih_curr_code as valuta," 
   cQry += "ih_curr_rate as omjer,"
   
   cQry += "it.invoice_tot_net as iznos_bez_pdv,"
   cQry += "it.invoice_tot_vat as ukupno_pdv,"
   cQry += "it.inv_tot_date::date as datum_fakture,"
   cQry += "datval.ipp_due_date::date as datum_valute"
   cQry += " from fmk.lisec_invoice_header ih"   
   cQry += " left join fmk.lisec_kust kust on (kust.kunr = ih.ih_cust_no and trim(kust.kust_manu_site) in ('','RAMA-GLAS'))"
   cQry += " left join lateral (select * from fmk.lisec_kust_adr where fmk.lisec_kust_adr.ku_nr=kust.kunr and fmk.lisec_kust_adr.ku_vk_ek=0 and fmk.lisec_kust_adr.ku_name is not null limit 1) kust_adr on true"
   cQry += " left join fmk.lisec_invoice_totals it on it.invoice_no = ih.ih_invoice_no" 
   cQry += " left join fmk.lisec_rechnung_daten rech on rech.rg_nr = ih.ih_invoice_no"
   cQry += " left join fmk.lisec_invoice_partial_payments datval on datval.ipp_invoice_no = ih.ih_invoice_no" 
   cQry += " LEFT JOIN fmk.partn on trim(kust.kust_kto_buch)=trim(fmk.partn.id)"

   //where ih_invoice_no = 3000000
   cQry += " WHERE it.inv_tot_date::date>=" + sql_quote(dDatOd) + " and it.inv_tot_date::date<=" + sql_quote(dDatDo)
   cQry += " ORDER BY rech.rg_info4"

elseif cFaktAvAvStor == "2"

   // AV

   cQry := "SELECT order_no as broj_racuna," 
   cQry += " order_tot_net iznos_bez_pdv, round(order_tot_net*0.17,2) as ukupno_pdv,"
   cQry += " aufk.bestell_dat::date datum_fakture, aufk.bestell_dat::date datum_valute,"
   cQry += "'PLUS' as storno_plus,"
   cQry += "kust.ku_land as kupac_drzava,"
   cQry += "kust_adr.ku_name as ime_kupca,"

   cQry += " aufk.kunr lisec_broj_kupca, fmk.partn.id idpartner"

   cQry += " FROM fmk.lisec_order_totals ot"
   cQry += " JOIN fmk.lisec_auf_kopf aufk on ot.order_no=aufk.auf_nr"
   cQry += " join fmk.lisec_doc_origin doc on doc.doc_no=ot.order_no"

   cQry += " left join fmk.lisec_kust kust on (kust.kunr = ih.ih_cust_no and trim(kust.kust_manu_site) in ('','RAMA-GLAS'))"

   cQry += " left join lateral (select * from fmk.lisec_kust_adr where fmk.lisec_kust_adr.ku_nr=kust.kunr and fmk.lisec_kust_adr.ku_vk_ek=0 and fmk.lisec_kust_adr.ku_name is not null limit 1) kust_adr on true"
   cQry += " LEFT JOIN fmk.partn on trim(kust.kust_kto_buch)=trim(fmk.partn.id)"

   cQry += " where doc.origin_type = 3"
   cQry += " and aufk.bestell_dat::date between "  + sql_quote(dDatOd) + " and  " + sql_quote(dDatDo)
   cQry += " and (order_no between 60000 and 90000)"  // opseg avansne fakture 
   cQry += " and aufk.kunr not in (4, 6)" // kupci KP, KPM
   cQry += " order by ot.order_no"
/* 
   // Avansne fakture

   select order_no, 
        order_tot_net iznos, 
        aufk.bestell_dat::date datum_rn, 
        aufk.kunr lisec_kupac_broj 
    from fmk.lisec_order_totals ot
     join fmk.lisec_auf_kopf aufk on  ot.order_no=aufk.auf_nr 
     join fmk.lisec_doc_origin doc on doc.doc_no=ot.order_no 
  where doc.origin_type = 3 and aufk.bestell_dat::date between '2025-01-29' and '2025-01-30'
        and (order_no between 8000 and 8999)
        and aufk.kunr not in (4, 6) 
  order by order_no
*/  
   
elseif cFaktAvAvStor == "3"

/* 
   // STORNO Avansne fakture

   select order_no as broj_racuna, 
     order_tot_net iznos_bez_pdv, 
     round(order_tot_net*0.17,2) as ukupno_pdv, 
     aufk.bestell_dat::date datum_fakture, 
     aufk.bestell_dat::date datum_valute,kust.ku_land as kupac_drzava,
     kust_adr.ku_name as ime_kupca,'PLUS' as storno_plus, 
     aufk.kunr lisec_broj_kupca, fmk.partn.id idpartner FROM fmk.lisec_order_totals ot 
     JOIN fmk.lisec_auf_kopf aufk on ot.order_no=aufk.auf_nr join fmk.lisec_doc_origin doc on doc.doc_no=ot.order_no 
     LEFT JOIN fmk.lisec_kust kust on (kust.kunr = aufk.kunr and kust.kust_manu_site='RAMA-GLAS') 
     left join fmk.lisec_kust_adr kust_adr on (kust_adr.ku_nr = kust.kunr and kust_adr.ku_vk_ek=0) 
     LEFT JOIN fmk.partn on trim(kust.kust_kto_buch)=trim(fmk.partn.id) 
     where doc.origin_type = 3 and aufk.bestell_dat::date between '2025-02-05' and  '2025-02-05' 
        and (order_no between 8000 and 8999) and aufk.kunr not in (4, 6)
*/

   cQry := "select order_no as broj_racuna,"
   cQry += " order_tot_net iznos_bez_pdv, round(order_tot_net*0.17,2) as ukupno_pdv,"
   cQry += " aufk.bestell_dat::date datum_fakture, aufk.bestell_dat::date datum_valute," 

   cQry += "kust.ku_land as kupac_drzava,"
   cQry += "kust_adr.ku_name as ime_kupca,"
   
   cQry += "'PLUS' as storno_plus,"

   cQry += " aufk.kunr lisec_broj_kupca, fmk.partn.id idpartner"
   cQry += " FROM fmk.lisec_order_totals ot"
   cQry += " JOIN fmk.lisec_auf_kopf aufk on ot.order_no=aufk.auf_nr"
   cQry += " join fmk.lisec_doc_origin doc on doc.doc_no=ot.order_no"
   
   cQry += " left join fmk.lisec_kust kust on (kust.kunr = ih.ih_cust_no and trim(kust.kust_manu_site) in ('','RAMA-GLAS'))"

   cQry += " left join lateral (select * from fmk.lisec_kust_adr where fmk.lisec_kust_adr.ku_nr=kust.kunr and fmk.lisec_kust_adr.ku_vk_ek=0 and fmk.lisec_kust_adr.ku_name is not null limit 1) kust_adr on true"
   cQry += " LEFT JOIN fmk.partn on trim(kust.kust_kto_buch)=trim(fmk.partn.id)"
   cQry += " where doc.origin_type = 3"
   cQry += " and aufk.bestell_dat::date between "  + sql_quote(dDatOd) + " and  " + sql_quote(dDatDo)
   cQry += " and (order_no between 8000 and 8999)"  // opseg storno avansne fakture 
   cQry += " and aufk.kunr not in (4, 6)" // kupci KP, KPM
   cQry += " order by ot.order_no" 

endif   

   SELECT( F_POM )
   MsgO("Preuzimanje podataka sa LISEC servera")
      IF !use_sql( "lisecrn", cQry, cAlias )
        lError := .T.
      ENDIF
   MsgC()

   IF lError
      Alert(_u("Greška pri preuzimanju LISEC podataka ?!" ))
      RETURN .F.
   ENDIF

   nRbr := 1
   Box(, 3, 80)
      @ box_x_koord(), box_y_koord() + 10 SAY STR(lisecrn->(reccount()), 5, 0)

      DO WHILE !EOF()

         hPartner := fin_lisec_find_partner( lisecrn->idpartner, lisecrn->ime_kupca, lisecrn->kupac_drzava )

         IF hPartner["id_partner"] == "GOTOVINA"
            //cIdPartner := ""
            //cIdKonto := "20500" // blagajna ?
            //cIdKontoPDV := Padr("4730", 7)
            //cIdKontoPrihod := Padr("61101", 7)
            SKIP
            LOOP
            // preskacemo KP i KPM, to se posebno unosi u 66 FIN naloge
         ENDIF


         nOsnovica := lisecrn->iznos_bez_pdv 
         nPDV := lisecrn->ukupno_pdv
         IF cFaktAvAvStor == "1"
            // https://redmine.bring.out.ba/issues/41618 lisec zaokruzenje
            //
            if ABS(nPDV) <> 0
              nUkupnoSaPDV := nOsnovica + nPDV
              nOsnovica := round(nUkupnoSaPDV / 1.17, 2)
              nPDV := round(nOsnovica * 0.17, 2)
            endif
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

         IF trim(lisecrn->ime_kupca) == "FL-BANKINO"
            // uplata banka ino partner
            cIdKonto := "2123"
         ENDIF
         
         IF trim(lisecrn->ime_kupca) == "FL-BANK"
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
         hFinItem[ "brdok" ] := AllTrim(STR(lisecrn->broj_racuna, 10,0))
         IF cFaktAvAvStor == "1"
            hFinItem[ "opis" ] := "RN. " + AllTrim(STR(lisecrn->broj_racuna, 10,0))  + ", FISK_RN " + Alltrim(lisecrn->broj_fiskalnog_racuna) + ""
         ELSE
            IF cFaktAvAvStor == "2"
               hFinItem[ "opis" ] := "AV.RN."
            ELSEIF cFaktAvAvStor == "3"
               hFinItem[ "opis" ] := "ST.AV."
            ENDIF   
            hFinItem[ "opis" ] += " " + AllTrim(STR(lisecrn->broj_racuna, 10,0)) + " "
         ENDIF

         hFinItem[ "datdok" ] := lisecrn->datum_fakture
         hFinItem[ "datval" ] := lisecrn->datum_valute

         hFinItem[ "konto" ] := cIdKonto
         hFinItem[ "partner" ] := cIdPartner
         hFinItem[ "d_p" ] := "1"

         if lisecrn->storno_plus == "STORNO"
            hFinItem[ "iznos" ] := - (nOsnovica + nPDV)
         else   
            hFinItem[ "iznos" ] := nOsnovica + nPDV
         endif

         //IF cFaktAvAvStor == "3" // storno avansne fakture RC
         //   hFinItem[ "iznos" ] := hFinItem[ "iznos" ] * -1
         //ENDIF 
         
         hFinItem[ "rbr" ] := nRbr
         ++nRbr
         AADD( aFinItems, hFinItem)

         IF cIdPartner == REPLICATE("?", 6)
            hFinItem[ "opis" ] += " ; " + trim(lisecrn->ime_kupca) + " " + trim(lisecrn->kupac_drzava)
         ENDIF

         hFinItemPDV := hb_HClone(hFinItem)
         hFinItemPDV[ "datval" ] := CTOD("")
         hFinItemPDV[ "konto" ] := cIdKontoPDV
         IF lisecrn->storno_plus == "STORNO"
            hFinItemPDV[ "iznos" ] := - nPDV
         ELSE
            hFinItemPDV[ "iznos" ] := nPDV
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
         IF lisecrn->storno_plus == "STORNO"
            hFinItemPrihod[ "iznos" ] := -nOsnovica
         ELSE
            hFinItemPrihod[ "iznos" ] := nOsnovica
         ENDIF
         //IF cFaktAvAvStor == "3" // storno RC
         //   hFinItemPrihod[ "iznos" ] := hFinItemPrihod[ "iznos" ] * -1
         //ENDIF

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
     @ box_x_koord() + 3, box_y_koord() + 2 SAY "Fakture (1)/Avans (2)/Avans-Storno (3)"  GET cFaktAvAvStor VALID cFaktAvAvStor $ "123"
 
     
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
   //IF LEFT(hFinItem[ "brdok" ], 2) == "IN"
   dDatVal := hFinItem[ "datval" ]
   //ELSE
   //   dDatVal := CTOD("")
   //ENDIF

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