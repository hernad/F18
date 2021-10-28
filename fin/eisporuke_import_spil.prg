#include "f18.ch"

FUNCTION fin_spil_table_name( dDateOd, dDateDo )

   LOCAL cTableName := "fmk.spil_racuni_"
   IF year( dDateOd ) <> year( dDateDo )
      Alert( "godina za datume od-do moraju biti iste")
      RETURN ""
   ENDIF
  
   IF month( dDateOd ) <> month( dDateDo )
      Alert( "mjesec za datume od-do moraju biti iste")
      RETURN ""
   ENDIF
  
   // npr: 01.01.2021 - 31.01.2021 => fmk.spil_racuni_202101
   cTableName += AllTrim(Str(year(dDateOd))) + PadL(Alltrim(Str(month(dDateOd))), 2, "0")

   RETURN cTableName

FUNCTION fin_cre_spil_table( dDateOd, dDateDo )

  LOCAL cSql, oQuery 
  LOCAL cMSSQLQuery
  LOCAL cTableName := fin_spil_table_name( dDateOd, dDateDo)

  IF Empty( cTableName)
     RETURN .F.
  ENDIF

  cSql := "DROP FOREIGN TABLE IF EXISTS " + cTableName + ";"
  cSql += "CREATE FOREIGN TABLE " + cTableName  
  cSql += "("
  cSql += "fiscal_number varchar(50),"
  cSql += "reg_no varchar(20),"
  cSql += "goni varchar(20),"
  cSql += "tax_code varchar(4),"
  cSql += "inv_date date,"
  cSql += "ordernum varchar(20),"
  cSql += "doctype int,"
  cSql += "docstate int,"
  cSql += "accountid int,"
  cSql += "c_account_name varchar(50),"
  cSql += "client_name varchar(100),"
  cSql += "client_country varchar(40),"
  cSql += "client_email varchar(200),"
  cSql += "c_tax_number varchar(15),"
  cSql += "tax_rate decimal(18,2),"
  cSql += "inv_tot_excl decimal(18,2),"
  cSql += "inv_tot_tax decimal(18,2),"
  cSql += "inv_tot_incl decimal(18,2))"

  cMSSQLQuery := "select spil_EU_FiscalNumber.FiscalNumber as fiscal_number,"
  cMSSQLQuery += "client.RegistrationNo as reg_no, client.GONI as goni, client.TaxCode as tax_code,"
  cMSSQLQuery += "convert(date, invdate) as inv_date, ordernum, doctype, docstate, accountid, cAccountName as c_account_name,"
  cMSSQLQuery += "client.name as client_name, client.Physical5 as client_country, client.email as client_email,"
  cMSSQLQuery += "cTaxNumber as c_tax_number, taxrate as tax_rate, invTotExcl as inv_tot_excl, invTotTax as inv_tot_tax,"
  cMSSQLQuery += "InvTotIncl as inv_tot_incl" 
  cMSSQLQuery += " from spilInvNum" 
  cMSSQLQuery += " left join client on client.dclink=accountid"
  cMSSQLQuery += " left join spil_EU_FiscalNumber on spil_EU_fiscalnumber.OrderIndex = spilinvnum.OrderIndex"
  cMSSQLQuery += " where invdate>='" + sql_quote( dDateOd ) + "' and invdate<='" + sql_quote( dDateDo) + "'"
  cMSSQLQuery += " and (doctype=4 or doctype=8)"
  cMSSQLQuery += " order by invdate"

  cSql += " SERVER spil OPTIONS( query '" + cMSSQLQuery + "', row_estimate_method 'execute');"
  oQuery := run_sql_query( cSql )

  IF sql_error_in_query( oQuery, "CREATE" )
    RETURN .F.
  ENDIF
 
  RETURN .T. 


FUNCTION fin_spil_rn_count( dDateOd, dDateDo )

   LOCAL cTableName := fin_spil_table_name( dDateOd, dDateDo )
   LOCAL cQry := "select count(*) from " + cTableName
   LOCAL oQuery, oRow

   IF !fin_cre_spil_table( dDateOd, dDateDo )
      RETURN -1
   ENDIF

   MsgO("Preuzimanje " + cTableName + " sa SPIL servera")
   oQuery := run_sql_query( cQry )
   MsgC()
   oRow := oQuery:GetRow( 1 )

   RETURN oRow:FieldGet( oRow:FieldPos( "count" ) )


FUNCTION fin_spil_find_partner( cAccountId, cClientName, cClientCountry, cRegNo, cGoni)
   //spilrn->accountid, spilrn->client_name, spilrn->client_country, spilrn->reg_no, spilrn->goni

   // get_partn_pdvb( cPartnerId )
   // AllTrim( get_partn_sifk_sifv( "PDVB", cPartnerId, .F. ) )

   IF cRegNo == "999999999999"
      RETURN "GOTOVINA"
   ENDIF

   PushWa()
   altd()
   use_sql_sifv( "PARTN", "PDVB", NIL, cRegNo )
   PopWa()
   IF !Empty(sifv->idsif)
         // PDV obveznik
         RETURN LEFT(sifv->idsif, 6)
   ENDIF
   IF TRIM(cClientName) == "KP" .OR. TRIM(cClientName) == "KPM"
      RETURN "GOTOVINA"
   ENDIF

   RETURN REPLICATE("?", 6)



FUNCTION fin_spil_get_fin_stavke(dDatod, dDatDo)

   LOCAL cTableName := fin_spil_table_name( dDatOd, dDatDo )
   LOCAL cAlias := "SPILRN"
   LOCAL cQry := "select * from " + cTableName
   LOCAL lError := .F.
   LOCAL nRbr, hFinItem, hFinItemPDV, hFinItemPrihod, cIdPartner
   LOCAL aFinItems := {}

   IF !fin_cre_spil_table( dDatOd, dDatDo )
      RETURN -1
   ENDIF

   SELECT( F_POM )
   MsgO("Preuzimanje " + cTableName + " sa SPIL servera")
      IF !use_sql( "spilrn", cQry, cAlias )
        lError := .T.
      ENDIF
   MsgC()

   IF lError
      Alert(_u("Greška pri preuzimanju " + cTableName + " ?!" ))
      RETURN .F.
   ENDIF
  
   nRbr := 1
   Box(, 3, 80)
      DO WHILE !EOF()

         cIdPartner := fin_spil_find_partner( spilrn->accountid, spilrn->client_name, spilrn->client_country, spilrn->reg_no, spilrn->goni )
         IF cIdPartner != "GOTOVINA"
            hFinItem := hb_hash()
            hFinItem[ "idfirma" ] := self_organizacija_id()
            hFinItem[ "idvn" ] := "14"
            hFinItem[ "brnal" ] := PadL( 0, 8, "0" )
            hFinItem[ "brdok" ] := spilrn->ordernum
            hFinItem[ "opis" ] := "fisk_rn: " + Alltrim(spilrn->fiscal_number)
            hFinItem[ "datdok" ] := spilrn->inv_date
            hFinItem[ "konto" ] := Padr("2110", 7)
            hFinItem[ "partner" ] := cIdPartner
            hFinItem[ "d_p" ] := "1"
            hFinItem[ "iznos" ] := spilrn->inv_tot_excl + spilrn->inv_tot_tax
            hFinItem[ "rbr" ] := nRbr
            ++nRbr
            AADD( aFinItems, hFinItem)

            hFinItemPDV := hb_HClone(hFinItem)
            hFinItemPDV[ "konto" ] := Padr("4700", 7)
            hFinItemPDV[ "iznos" ] := spilrn->inv_tot_tax
            hFinItemPDV[ "d_p" ] := "2"
            hFinItemPDV[ "rbr" ] := nRbr
            hFinItemPDV[ "partner" ] := SPACE(6)
            AADD( aFinItems, hFinItemPDV)
            ++nRbr

            hFinItemPrihod := hb_HClone(hFinItem)
            hFinItemPrihod[ "konto" ] := Padr("6110", 7)
            hFinItemPrihod[ "iznos" ] := spilrn->inv_tot_excl
            hFinItemPrihod[ "d_p" ] := "2"
            hFinItemPrihod[ "rbr" ] := nRbr
            hFinItemPrihod[ "partner" ] := SPACE(6)
            AADD( aFinItems, hFinItemPrihod)
            ++nRbr
         ENDIF
         
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "Rbr: " + Alltrim(Str(nRbr, 5))
         SKIP

      ENDDO
   BoxC()

   RETURN aFinItems


FUNCTION fin_spil_import()

   LOCAL dDatOd := fetch_metric("fin_spil_od", my_user(), Date()), dDatDo := fetch_metric("fin_spil_do", my_user(), Date())
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

   // Alert(Str(fin_spil_rn_count(dDatOd, dDatDo)))

   aFinItems := fin_spil_get_fin_stavke(dDatod, dDatDo)

   FOR nRbr := 1 TO LEN( aFinItems )
      fin_spil_pripr_fill( aFinItems[ nRbr ] )
   NEXT

   set_metric("fin_spil_od", my_user(), dDatOd)
   set_metric("fin_spil_do", my_user(), dDatDo)
   
   RETURN .T.


STATIC FUNCTION fin_spil_pripr_fill( hFinItem )

   select_o_fin_pripr()
   APPEND BLANK

   RREPLACE idfirma WITH hFinItem[ "idfirma" ], ;
            idvn WITH hFinItem[ "idvn" ], ;
            brnal WITH hFinItem[ "brnal" ], ;
            brdok WITH hFinItem[ "brdok" ], ;
            opis WITH hFinItem[ "opis" ], ;
            rbr WITH hFinItem[ "rbr" ], ;
            datdok WITH hFinItem[ "datdok" ], ;
            idkonto WITH hFinItem[ "konto" ], ;
            idpartner WITH hFinItem[ "partner" ], ;
            d_p WITH hFinItem[ "d_p" ], ;
            iznosbhd WITH hFinItem[ "iznos" ], ;
            iznosdem WITH fin_km_to_eur(hFinItem["iznos"], hFinItem["datdok"])
   
   RETURN .T.


FUNCTION fin_spil_active()

   IF !Empty(fetch_metric( "fin_spil_host", NIL, "" ))
     RETURN .T.
   ENDIF

   RETURN .F.


FUNCTION fin_parametri_import_spil()

    LOCAL nX := 1
    LOCAL cHost := PADR(fetch_metric( "fin_spil_host", NIL, "" ), 30)
    LOCAL cUser := PADR(fetch_metric( "fin_spil_user", NIL, "" ), 30)
    LOCAL cPassword := PADR(fetch_metric( "fin_spil_password", NIL, "" ), 30)
    LOCAL cDatabase := PADR(fetch_metric( "fin_spil_db", NIL, "" ), 30)
    LOCAL GetList := {}
 
    Box(, 10, 70 )
 
    SET CURSOR ON
 
    @ box_x_koord() + nX, box_y_koord() + 2 SAY "  PRAMETRI SPIL -> F18:"
 
    nX += 2
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "MSSQL Host:" GET cHost
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "      user:" GET cUser
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  password:" GET cPassword
    @ box_x_koord() + nX++, box_y_koord() + 2 SAY "  Database:" GET cDatabase

    READ
    BoxC()
 
    IF LastKey() <> K_ESC
       set_metric( "fin_spil_host", NIL, cHost )
       set_metric( "fin_spil_user", NIL, cUser )
       set_metric( "fin_spil_password", NIL, cPassword )
       set_metric( "fin_spil_db", NIL, cDatabase )

    ENDIF
 
    RETURN .T.
 