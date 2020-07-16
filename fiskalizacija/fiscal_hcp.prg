/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

STATIC s_CmdOK := "CMD.OK"
STATIC cRazmak1 := " "
STATIC cAnswerDirectory := "FROM_FP"
STATIC s_cInputDir := "TO_FP"
STATIC s_cZahtjevNula := "0"

// trigeri
STATIC s_cTrigerCMD := "CMD"
STATIC s_cTrigerPLU := "PLU"
STATIC s_cTrigerTXT := "TXT"
STATIC s_cTrigerRCP := "RCP"
STATIC s_cTrigerClientsXML := "clients.XML"
STATIC s_cTrigerFooterXML := "footer.XML"

#define ERROR_ALT_Q -100

// fiskalne funkcije HCP fiskalizacije

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
// aData[14] - total racuna
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

<?xml version="1.0" encoding="UTF-8"?>
<PLU>
<DATA BCR="62842" VAT="1" MES="0" DEP="0" DSC="HD VRE&#262;ICA &#352;TAM bijela COD 280+(" PRC="0.10" LGR="0.00" />
</PLU>

PRC - Cijena

*/

FUNCTION fiskalni_hcp_racun( hFiskalniParams, aItems, aHeader, lStorno, nRacunTotal )

   LOCAL cXmlFile, cFiskalniFileName
   LOCAL nI, cIBK, cBrojRacuna, aFooter
   // LOCAL _v_pl
   LOCAL nTotalPlacanje
   LOCAL cReklamiraniRn
   LOCAL nKolicina
   LOCAL nCijena
   LOCAL cArtikalID
   LOCAL cArtikalBarKOD
   LOCAL nArtikalPLU
   LOCAL cRobaNaziv, cArtikalJMJ, cTmp
   // LOCAL cOperater := ""
   LOCAL lCustomer := .F.
   LOCAL nErrorLevel := 0
   LOCAL cCommand := ""
   LOCAL lDeleteAll := .T.
   LOCAL cDepartment
   LOCAL cIdTarifa
   LOCAL nRabat
   LOCAL cVrstaPlacanja

   IF aHeader <> NIL .AND. Len( aHeader ) > 0
      lCustomer := .T.
   ENDIF

   hcp_delete_tmp( hFiskalniParams, lDeleteAll ) // brisi tmp fajlove ako su ostali

   IF nRacunTotal == nil
      nRacunTotal := 0
   ENDIF

   IF lStorno // ako je lStorno posalji predkomandu

      // daj mi lStorno komandu
      cReklamiraniRn := AllTrim( aItems[ 1, 8 ] )
      cCommand := _on_storno( cReklamiraniRn )
      // posalji lStorno komandu
      nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

      IF nErrorLevel > 0
         RETURN nErrorLevel
      ENDIF

   ENDIF

   // programiraj artikal prije nego izdas racun
   nErrorLevel := hcp_plu( hFiskalniParams, aItems )
   IF nErrorLevel == ERROR_ALT_Q
        RETURN ERROR_ALT_Q
   ENDIF

   IF nErrorLevel > 0
      RETURN nErrorLevel
   ENDIF

   IF lCustomer
      nErrorLevel := hcp_cli( hFiskalniParams, aHeader ) // dodaj kupca

      IF nErrorLevel > 0
         RETURN nErrorLevel
      ENDIF

      // setuj triger za izdavanje racuna sa partnerom
      cIBK := aHeader[ 1, 1 ]
      cCommand := hcp_racun_partner( cIBK )
      nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

      IF nErrorLevel > 0
         RETURN nErrorLevel
      ENDIF
   ENDIF

   // posalji komandu za reset footera...
   cCommand := hcp_footer_off()
   nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   IF nErrorLevel > 0
      RETURN nErrorLevel
   ENDIF

   // to je zapravo broj racuna !!!
   cBrojRacuna := aItems[ 1, 1 ]
   // posalji footer...
   aFooter := {}
   AAdd( aFooter, { "Broj rn: " + cBrojRacuna } )
   nErrorLevel := hcp_footer( hFiskalniParams, aFooter, s_cTrigerFooterXML )
   IF nErrorLevel > 0
      RETURN nErrorLevel
   ENDIF

   // sredi mi naziv fajla...
   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], cBrojRacuna, s_cTrigerRCP )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName

   create_xml( cXmlFile )
   xml_head()
   xml_subnode( "RECEIPT" )

   nTotalPlacanje := 0

   FOR nI := 1 TO Len( aItems )

      nArtikalPLU := aItems[ nI, 9 ]
      cArtikalBarKOD := aItems[ nI, 12 ]
      cArtikalID := aItems[ nI, 3 ]
      cRobaNaziv := PadR( aItems[ nI, 4 ], 32 )
      cArtikalJMJ := get_jmj_hcp( aItems[ nI, 16 ] )
      nCijena := aItems[ nI, 5 ]
      nKolicina := aItems[ nI, 6 ]
      nRabat := aItems[ nI, 11 ]
      cIdTarifa := fiskalni_tarifa( aItems[ nI, 7 ], hFiskalniParams[ "pdv" ], "HCP" )
      cDepartment := "0"

      cTmp := ""
      // sta ce se koristiti za 'kod' artikla
      IF hFiskalniParams[ "plu_type" ] $ "P#D"
         // PLU artikla
         cTmp := 'BCR="' + AllTrim( Str( nArtikalPLU ) ) + '"'
      ELSEIF hFiskalniParams[ "plu_type" ] == "I"
         // ID artikla
         cTmp := 'BCR="' + AllTrim( cArtikalID ) + '"'
      ELSEIF hFiskalniParams[ "plu_type" ] == "B"
         // barkod artikla
         cTmp := 'BCR="' + AllTrim( cArtikalBarKOD ) + '"'
      ENDIF


      cTmp += cRazmak1 + 'VAT="' + cIdTarifa + '"' // poreska stopa
      // jedinica mjere
      cTmp += cRazmak1 + 'MES="' + cArtikalJMJ + '"'
      // odjeljenje
      cTmp += cRazmak1 + 'DEP="' + cDepartment + '"'
      // naziv artikla
      cTmp += cRazmak1 + 'DSC="' + to_xml_encoding( cRobaNaziv ) + '"'
      // cijena artikla
      cTmp += cRazmak1 + 'PRC="' + AllTrim( Str( nCijena, 12, 2 ) ) + '"'
      // kolicina artikla
      cTmp += cRazmak1 + 'AMN="' + AllTrim( Str( nKolicina, 12, 3 ) ) + '"'

      IF nRabat > 0
         // vrijednost popusta
         cTmp += cRazmak1 + 'DS_VALUE="' + AllTrim( Str( nRabat, 12, 2 ) ) + '"'
         // vrijednost popusta
         cTmp += cRazmak1 + 'DISCOUNT="' + "true" + '"'

      ENDIF

      xml_single_node( "DATA", cTmp )
   NEXT


   // vrste placanja, oznaka:
   //
   // "GOTOVINA"
   // "CEK"
   // "VIRMAN"
   // "KARTICA"
   //
   // iznos = 0, ako je 0 onda sve ide tom vrstom placanja

   cVrstaPlacanja := fiskalni_vrsta_placanja( aItems[ 1, 13 ], "HCP" )
   nTotalPlacanje := Abs( nRacunTotal )

   IF lStorno
      // ako je lStorno onda je placanje gotovina i iznos 0
      cVrstaPlacanja := "0"
      nTotalPlacanje := 0
   ENDIF

   cTmp := 'PAY="' + cVrstaPlacanja + '"'
   cTmp += cRazmak1 + 'AMN="' + AllTrim( Str( nTotalPlacanje, 12, 2 ) ) + '"'

   xml_single_node( "DATA", cTmp )
   xml_subnode( "RECEIPT", .T. )

   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nErrorLevel
   ENDIF

   hcp_create_cmd_ok( hFiskalniParams )

   IF (nErrorLevel := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )) <> ERROR_ALT_Q
      nErrorLevel := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerRCP )
   ELSE
      RETURN ERROR_ALT_Q
   ENDIF

   RETURN nErrorLevel



// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
FUNCTION hcp_delete_tmp( hFiskalniParams, lDeleteAll )

   LOCAL cTmp, cFiskalniFileName

   IF lDeleteAll == NIL
      lDeleteAll := .F.
   ENDIF

   MsgO( "brisem tmp fajlove..." )

   // input direktorij...
   cFiskalniFileName := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH
   cTmp := "*.*"

   AEval( Directory( cFiskalniFileName + cTmp ), {| aFile| FErase( cFiskalniFileName + ;
      AllTrim( aFile[ 1 ] ) ) } )

   IF lDeleteAll

      // output direktorij...
      cFiskalniFileName := hFiskalniParams[ "out_dir" ] + cAnswerDirectory + SLASH
      cTmp := "*.*"
      AEval( Directory( cFiskalniFileName + cTmp ), {| cFile | FErase( cFiskalniFileName + AllTrim( cFile[ 1 ] ) ) } )

   ENDIF

   // Sleep( 1 )
   MsgC()

   RETURN .T.



FUNCTION hcp_footer( hFiskalniParams, footer )

   LOCAL cXmlFile, cTmp, nI
   LOCAL nError := 0
   LOCAL cFiskalniFileName

   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula, s_cTrigerFooterXML )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName


   create_xml( cXmlFile )
   xml_head()
   xml_subnode( "FOOTER" )

   FOR nI := 1 TO Len( footer )
      cTmp := 'TEXT="' + AllTrim( footer[ nI, 1 ] ) + '"'
      cTmp += ' '
      cTmp += 'BOLD="false"'

      xml_single_node( "DATA", cTmp )
   NEXT

   xml_subnode( "FOOTER", .T. )

   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nError
   ENDIF

   // kreiraj triger cmd.ok
   hcp_create_cmd_ok( hFiskalniParams )

   nError := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )
   IF nError == ERROR_ALT_Q .OR. nError == 0
      RETURN nError
   ENDIF

   nError := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerFooterXML )

   RETURN nError




// -------------------------------------------------------------------
// hcp programiranje klijenti
// -------------------------------------------------------------------
FUNCTION hcp_cli( hFiskalniParams, aHeader )

   LOCAL cXmlFile, cFiskalniFileName, cTmp, nI
   LOCAL nError := 0

   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula, s_cTrigerClientsXML )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName

   create_xml( cXmlFile )
   xml_head()
   xml_subnode( "CLIENTS" )

   FOR nI := 1 TO Len( aHeader )

      cTmp := 'cIBK="' + aHeader[ nI, 1 ] + '"'
      cTmp += cRazmak1 + 'NAME="' + ;
         AllTrim( to_xml_encoding( aHeader[ nI, 2 ] ) ) + '"'
      cTmp += cRazmak1 + 'ADDRESS="' + ;
         AllTrim( to_xml_encoding( aHeader[ nI, 3 ] ) ) + '"'
      cTmp += cRazmak1 + 'TOWN="' + ;
         AllTrim( to_xml_encoding( aHeader[ nI, 5 ] ) ) + '"'

      xml_single_node( "DATA", cTmp )

   NEXT

   xml_subnode( "CLIENTS", .T. )
   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nError
   ENDIF

   hcp_create_cmd_ok( hFiskalniParams )

   nError := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )   
   IF nError == ERROR_ALT_Q .OR. nError == 0
      RETURN nError
   ENDIF

   nError := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerClientsXML )

   RETURN nError


// -------------------------------------------------------------------
// hcp programiranje PLU
// -------------------------------------------------------------------
FUNCTION hcp_plu( hFiskalniParams, aItems )

   LOCAL cXmlFile
   LOCAL nError := 0
   LOCAL nI, cTmp, cFiskalniFileName
   LOCAL nArtikalPLU, cRobaNaziv, cArtikalJMJ, nArtikalCijena, cArtikalTarifa
   LOCAL cDepartment, nLager

   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula, s_cTrigerPLU )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName

   create_xml( cXmlFile )
   xml_head()

   xml_subnode( "PLU" )

   FOR nI := 1 TO Len( aItems )
      nArtikalPLU := aItems[ nI, 9 ]
      cRobaNaziv := PadR( aItems[ nI, 4 ], 32 )
      cArtikalJMJ := get_jmj_hcp( aItems[ nI, 16 ] )
      nArtikalCijena := aItems[ nI, 5 ]
      cArtikalTarifa := fiskalni_tarifa( aItems[ nI, 7 ], hFiskalniParams[ "pdv" ], "HCP" )
      cDepartment := "0"
      nLager := 0
      cTmp := 'BCR="' + AllTrim( Str( nArtikalPLU ) ) + '"'
      cTmp += cRazmak1 + 'VAT="' + cArtikalTarifa + '"'
      cTmp += cRazmak1 + 'MES="' + cArtikalJMJ + '"'
      cTmp += cRazmak1 + 'DEP="' + cDepartment + '"'
      cTmp += cRazmak1 + 'DSC="' + to_xml_encoding( cRobaNaziv ) + '"'
      cTmp += cRazmak1 + 'PRC="' + AllTrim( Str( nArtikalCijena, 12, 2 ) ) + '"'
      cTmp += cRazmak1 + 'LGR="' + AllTrim( Str( nLager, 12, 2 ) ) + '"'
      xml_single_node( "DATA", cTmp )
   NEXT

   xml_subnode( "PLU", .T. )
   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nError
   ENDIF


   hcp_create_cmd_ok( hFiskalniParams )
   nError := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )
   IF nError == ERROR_ALT_Q .OR. nError == 0
      RETURN nError
   ENDIF

   nError := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerPLU )

   RETURN nError



// -------------------------------------------------------------------
// ispis nefiskalnog teksta
// -------------------------------------------------------------------
FUNCTION hcp_txt( hFiskalniParams, cBrDok )

   LOCAL cCommand := ""
   LOCAL cXmlFile, cData, cTmp
   LOCAL nError := 0
   LOCAL cFiskalniFileName


   cCommand := 'TXT="POS RN: ' + AllTrim( cBrDok ) + '"'

   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula, s_cTrigerTXT )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName

   // otvori xml
   create_xml( cXmlFile )

   // upisi header
   xml_head()
   xml_subnode( "USER_TEXT" )

   IF !Empty( cCommand )

      cData := "DATA"
      cTmp := cCommand

      xml_single_node( cData, cTmp )

   ENDIF

   xml_subnode( "USER_TEXT", .T. )
   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nError
   ENDIF

   hcp_create_cmd_ok( hFiskalniParams )

   hcp_create_cmd_ok( hFiskalniParams )
   nError := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )
   IF nError == ERROR_ALT_Q .OR. nError == 0
      RETURN nError
   ENDIF
   nError := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerPLU )

   RETURN nError


FUNCTION hcp_cmd( hFiskalniParams, cCmd, cTrigerCMD )

   LOCAL cXmlFile
   LOCAL nError := 0
   LOCAL cFiskalniFileName
   LOCAL cData
   LOCAL cTmp

   cFiskalniFileName := fiscal_out_filename( hFiskalniParams[ "out_file" ], s_cZahtjevNula, cTrigerCMD )

   // putanja do izlaznog xml fajla
   cXmlFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + cFiskalniFileName

   create_xml( cXmlFile )
   xml_head()
   xml_subnode( "COMMAND" )

   IF !Empty( cCmd )

      cData := "DATA"
      cTmp := cCmd
      xml_single_node( cData, cTmp )

   ENDIF

   xml_subnode( "COMMAND", .T. )
   close_xml()

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nError
   ENDIF

   hcp_create_cmd_ok( hFiskalniParams )
   nError := hcp_read_odgovor( hFiskalniParams, cFiskalniFileName )
   IF nError == ERROR_ALT_Q .OR. nError == 0
      RETURN nError
   ENDIF

   nError := hcp_read_error( hFiskalniParams, cFiskalniFileName, s_cTrigerPLU )


   RETURN nError


// -------------------------------------------------
// ukljuci lStorno racuna
// -------------------------------------------------
STATIC FUNCTION _on_storno( broj_rn )

   LOCAL cCommand

   cCommand := 'CMD="REFUND_ON"'
   cCommand += cRazmak1 + 'NUM="' + AllTrim( broj_rn ) + '"'

   RETURN cCommand


// -------------------------------------------------
// ponistavanje footer-a
// -------------------------------------------------
STATIC FUNCTION hcp_footer_off()

   LOCAL cCommand

   cCommand := 'CMD="FOOTER_OFF"'

   RETURN cCommand


// -------------------------------------------------
// iskljuci lStorno racuna
// -------------------------------------------------
STATIC FUNCTION hcp_storno_off()

   LOCAL cCommand

   cCommand := 'CMD="REFUND_OFF"'

   RETURN cCommand


// -------------------------------------------------
// ukljuci racun za klijenta
// -------------------------------------------------
STATIC FUNCTION hcp_racun_partner( cIBK )

   LOCAL cCommand

   cCommand := 'CMD="SET_CLIENT"'
   cCommand += cRazmak1 + 'NUM="' + AllTrim( cIBK ) + '"'

   RETURN cCommand




STATIC FUNCTION get_jmj_hcp( cJmj )

   LOCAL cRet := "0"

   DO CASE
   CASE Upper( AllTrim( cJmj ) ) = "KOM"
      cRet := "0"
   CASE Upper( AllTrim( cJmj ) ) = "LIT"
      cRet := "1"
   ENDCASE

   RETURN cRet




// -----------------------------------------------------
// dnevni fiskalni izvjestaj
// -----------------------------------------------------
FUNCTION hcp_z_rpt( hFiskalniParams )

   LOCAL cCommand, nErrorLevel
   LOCAL _param_date, _param_time
   LOCAL _rpt_type := "Z"
   LOCAL _last_date
   LOCAL _last_time

   _param_date := "zadnji_" + _rpt_type + "_izvjestaj_datum"
   _param_time := "zadnji_" + _rpt_type + "_izvjestaj_vrijeme"

   // iscitaj zadnje formirane izvjestaje...
   _last_date := fetch_metric( _param_date, NIL, CToD( "" ) )
   _last_time := PadR( fetch_metric( _param_time, NIL, "" ), 5 )

   IF Date() == _last_date
      MsgBeep( "Zadnji dnevni izvjestaj radjen " + DToC( _last_date ) + " u " + _last_time )
   ENDIF

   cCommand := 'CMD="Z_REPORT"'
   nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   // upisi zadnji dnevni izvjestaj
   set_metric( _param_date, NIL, Date() )
   set_metric( _param_time, NIL, Time() )

   // ako se koriste dinamicki plu kodovi resetuj prodaju
   // pobrisi artikle
   IF hFiskalniParams[ "plu_type" ] == "D"

      MsgO( "resetujem prodaju..." )

      // reset sold plu
      cCommand := 'CMD="RESET_SOLD_PLU"'
      nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

      // ako su dinamicki PLU kodovi
      cCommand := 'CMD="DELETE_ALL_PLU"'
      nErrorLevel := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

      // resetuj PLU brojac u bazi...
      auto_plu( .T., .T., hFiskalniParams )

      MsgC()

   ENDIF

   // ako se koristi opcija automatskog pologa
   IF hFiskalniParams[ "auto_avans" ] > 0

      MsgO( "Automatski unos pologa u uredjaj... sacekajte." )

      // daj malo prostora
      Sleep( 5 )

      // unesi polog vrijednosti iz parametra
      nErrorLevel := hcp_polog( hFiskalniParams, hFiskalniParams[ "auto_avans" ] )

      MsgC()

   ENDIF

   RETURN .T.


// -----------------------------------------------------
// presjek stanja
// -----------------------------------------------------
FUNCTION hcp_x_rpt( hFiskalniParams )

   LOCAL cCommand, nError

   cCommand := 'CMD="X_REPORT"'
   nError := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   RETURN .T.





// -----------------------------------------------------
// presjek stanja SUMMARY
// -----------------------------------------------------
FUNCTION hcp_s_rpt( hFiskalniParams )

   LOCAL cCommand
   LOCAL _date_from := Date() -30
   LOCAL _date_to := Date()
   LOCAL _txt_date_from := ""
   LOCAL _txt_date_to := ""
   LOCAL GetList := {}
   LOCAL nError

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od:" GET _date_from
   @ box_x_koord() + 1, Col() + 1 SAY "do:" GET _date_to
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   _txt_date_from := fprint_formatiranje_datuma( _date_from )
   _txt_date_to := fprint_formatiranje_datuma( _date_to )

   cCommand := 'CMD="SUMMARY_REPORT" FROM="' + _txt_date_from + '" TO="' + _txt_date_to + '"'
   nError := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   RETURN .T.



// -----------------------------------------------------
// vraca broj fiskalnog racuna
// -----------------------------------------------------
FUNCTION fiskalni_hcp_get_broj_racuna( hFiskalniParams, lStorno )

   LOCAL cCommand
   LOCAL nBrojFiskalnog := 0
   //LOCAL cFajlOdgovora := "BILL_S~1.XML"
   LOCAL cFajlOdgovora := "bill_state.xml"
   LOCAL nError

//#ifdef __PLATFORM__UNIX

   
//#endif

   // posalji komandu za stanje fiskalnog racuna
   cCommand := 'CMD="RECEIPT_STATE"'
   nError := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   // testni rezim uredjaja
   IF hFiskalniParams[ "print_fiscal" ] == "T"
      RETURN nBrojFiskalnog := 999
   ENDIF

   // ako nema gresaka, iscitaj broj racuna
   IF nError == 0
      nBrojFiskalnog := hcp_read_broj_racuna( hFiskalniParams, cFajlOdgovora, lStorno )
   ENDIF

   RETURN nBrojFiskalnog




// -----------------------------------------------------
// reset prodaje
// -----------------------------------------------------
FUNCTION hcp_reset( hFiskalniParams )

   LOCAL cCommand
   LOCAL nError

   cCommand := 'CMD="RESET_SOLD_PLU"'
   nError := hcp_cmd( hFiskalniParams, cCommand, s_cTrigerCMD )

   RETURN .T.





// ---------------------------------------------------
// polog pazara
// ---------------------------------------------------
FUNCTION hcp_polog( hDevParams, value )

   LOCAL cCommand
   LOCAL GetList := {}
   LOCAL nError

   IF value == nil
      value := 0
   ENDIF

   IF value = 0

      // box - daj broj racuna
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unosim polog od:" GET value PICT "99999.99"
      READ
      BoxC()

      IF LastKey() == K_ESC .OR. value = 0
         RETURN .F.
      ENDIF

   ENDIF

   IF value < 0
      // polog komanda
      cCommand := 'CMD="CASH_OUT"'
   ELSE
      // polog komanda
      cCommand := 'CMD="CASH_IN"'
   ENDIF

   cCommand += cRazmak1 + 'VALUE="' +  AllTrim( Str( Abs( value ), 12, 2 ) ) + '"'
   nError := hcp_cmd( hDevParams, cCommand, s_cTrigerCMD )

   RETURN .T.




// ---------------------------------------------------
// stampa kopije racuna
// ---------------------------------------------------
FUNCTION hcp_rn_copy( hDevParams )

   LOCAL cCommand
   LOCAL _broj_rn := Space( 10 )
   LOCAL _refund := "N"
   LOCAL nError := 0
   LOCAL GetList := {}

   // box - daj broj racuna
   Box(, 2, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj racuna:" GET _broj_rn ;
      VALID !Empty( _broj_rn )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "racun je reklamni (D/N)?" GET _refund ;
      VALID _refund $ "DN" PICT "@!"
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   IF _refund == "N"
      // obicni racun
      cCommand := 'CMD="RECEIPT_COPY"'
   ELSE
      // reklamirani racun
      cCommand := 'CMD="REFUND_RECEIPT_COPY"'
   ENDIF

   cCommand += cRazmak1 + 'NUM="' +  AllTrim( _broj_rn ) + '"'

   nError := hcp_cmd( hDevParams, cCommand, s_cTrigerCMD )

   RETURN .T.


STATIC FUNCTION hcp_read_odgovor( hDevParams, cFileName, nTimeOut )

   LOCAL nError := 0
   LOCAL cTmp

   IF nTimeOUT == nil
      nTimeOUT := 30
   ENDIF

   cTmp := hDevParams[ "out_dir" ] + cAnswerDirectory + SLASH + StrTran( cFileName, "XML", "OK" )

   Box(, 3, 60 )
  
   @ box_x_koord() + 0, box_y_koord() + 10 SAY "<Alt-Q> prekid"
   @ box_x_koord() + 1, box_y_koord() + 2 SAY _u("Uređaj ID: ") + AllTrim( Str( hDevParams[ "id" ] ) ) + " : " + PadR( hDevParams[ "name" ], 40 )

   DO WHILE nTimeOut > 0 
      
      IF (LastKey() == K_ALT_Q) .AND. Pitanje(,"Prekinuti slanje na fiskalni ?", "N" ) == "D"
         BoxC()
         altd()
         RETURN ERROR_ALT_Q
      ENDIF

      -- nTimeOut
      Sleep( 0.2 )

      IF File( cTmp )
         // fajl se pojavio - izadji iz petlje !
         EXIT
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( _u("Čekam odgovor HCP OK: ") + AllTrim( Str( nTimeOut ) ), 48 )

      IF nTimeOut == 0
         BoxC()
         RETURN -10
      ENDIF

      Sleep( 0.4 )

   ENDDO

   BoxC()

   IF !File( cTmp )
      nError := -1
   ELSE
      // obrisi fajl "OK"
      FErase( cTmp )
   ENDIF

   RETURN nError



FUNCTION hcp_create_cmd_ok( hFiskalniParams )

   LOCAL cTmp

   cTmp := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + s_CmdOK

   // iskoristit cu postojecu funkciju za kreiranje xml fajla...
   create_xml( cTmp )
   close_xml()

   RETURN .T.



FUNCTION hcp_delete_cmd_ok( hFiskalniParams )

   LOCAL cTmpFile

   cTmpFile := hFiskalniParams[ "out_dir" ] + s_cInputDir + SLASH + s_CmdOK

   IF FErase( cTmpFile ) < 0
      MsgBeep( "greska sa brisanjem fajla CMD.OK !" )
   ENDIF

   RETURN .T.





// --------------------------------------------------
// brise fajl greske
// --------------------------------------------------
FUNCTION hcp_delete_error( hFiskalniParams, cFileName )

   LOCAL nError := 0
   LOCAL cFiskalniFileName

   // primjer: c:\hcp\from_fp\RAC001.ERR
   cFiskalniFileName := hFiskalniParams[ "out_dir" ] + cAnswerDirectory + SLASH + StrTran( cFileName, "XML", "ERR" )
   IF FErase( cFiskalniFileName ) < 0
      MsgBeep( "greska sa brisanjem fajla..." )
   ENDIF

   RETURN .T.



// -----------------------------------------------
// citanje fajla bill_state.xml
//
// nTimeOut - time out fiskalne operacije
// ------------------------------------------------
FUNCTION hcp_read_broj_racuna( hFiskalniParams, cFileName, lStorno )

   LOCAL nBrojFiskalnog
   LOCAL oFile, nTime, cFiskalniFileName
   LOCAL nError := 0
   LOCAL aRacunData, cLine, cScanTxt, nScan
   LOCAL _receipt, cMsg

   IF lStorno == nil
      lStorno := .F.
   ENDIF

   nTime := hFiskalniParams[ "timeout" ]

   // primjer: c:\hcp\from_fp\bill_state.xml
   cFiskalniFileName := hFiskalniParams[ "out_dir" ] + cAnswerDirectory + SLASH + cFileName

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY _u("Uređaj ID: ") + AllTrim( Str( hFiskalniParams[ "id" ] ) ) + ;
      " : " + PadR( hFiskalniParams[ "name" ], 40 )

   DO WHILE nTime > 0

      -- nTime
      IF File( cFiskalniFileName )
         // fajl se pojavio - izadji iz petlje !
         EXIT
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( _u("Čekam na fiskalni uredjaj: ") + AllTrim( Str( nTime ) ), 48 )

      IF nTime == 0 .OR. LastKey() == K_ALT_Q
         BoxC()
         RETURN -9
      ENDIF

      Sleep( 1 )

   ENDDO

   BoxC()

   IF !File( cFiskalniFileName )
      MsgBeep( "Fajl " + cFiskalniFileName + " ne postoji !!!" )
      nError := -9
      RETURN nError
   ENDIF

   nBrojFiskalnog := 0

   cFiskalniFileName := AllTrim( cFiskalniFileName )

   oFile := TFileRead():New( cFiskalniFileName )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFiskalniFileName ) )
      RETURN -9
   ENDIF

   // prodji kroz svaku liniju i procitaj zapise
   WHILE oFile:MoreToRead()

      // uzmi u cLine liniju fajla
      cLine := hb_StrToUTF8( oFile:ReadLine() )

      IF Upper( "xml version" ) $ Upper( cLine )
         // ovo je prvi red, preskoci
         LOOP
      ENDIF

      // zamjeni ove znakove...
      cLine := StrTran( cLine, ">", "" )
      cLine := StrTran( cLine, "<", "" )
      cLine := StrTran( cLine, "'", "" )

      aRacunData := TokToNiz( cLine, " " )

      cScanTxt := "RECEIPT_NUMBER"

      IF lStorno
         cScanTxt := "REFOUND_RECEIPT_NUMBER"
      ENDIF

      nScan := AScan( aRacunData, {| val | cScanTxt $ val } )

      IF nScan > 0

         _receipt := TokToNiz( aRacunData[ nScan ], "=" )
         nBrojFiskalnog := Val( _receipt[ 2 ] )

         cMsg := "Formiran "

         IF lStorno
            cMsg += "rekl."
         ENDIF

         cMsg += "fiskalni racun: "
         MsgBeep( cMsg + AllTrim( Str( nBrojFiskalnog ) ) )

         EXIT

      ENDIF

   ENDDO

   oFile:Close()

   // brisi fajl odgovora
   IF nBrojFiskalnog > 0
      FErase( cFiskalniFileName )
   ENDIF

   RETURN nBrojFiskalnog



// ------------------------------------------------
// citanje gresaka za HCP driver
//
// nTimeOut - time out fiskalne operacije
// nFisc_no - broj fiskalnog isjecka
// ------------------------------------------------
FUNCTION hcp_read_error( hFiskalniParams, cFileName )

   LOCAL nError := 0
   LOCAL cFiskalniFileName, nI, nTime
   LOCAL nBrojFiskalnog, cLine, oFile
   LOCAL cErrorCode, _err_descr
   LOCAL aErrors

   nTime := hFiskalniParams[ "timeout" ]

   // primjer: c:\hcp\from_fp\RAC001.ERR
   cFiskalniFileName := hFiskalniParams[ "out_dir" ] + cAnswerDirectory + SLASH + StrTran( cFileName, "XML", "ERR" )

   Box("#hcp_read_err", 3, 60 )

   @ box_x_koord(), box_y_koord() + 35 SAY "<Alt-Q> Prekid"
   @ box_x_koord() + 1, box_y_koord() + 2 SAY _u("Uređaj ID: ") + AllTrim( Str( hFiskalniParams[ "id" ] ) ) + ;
      " : " + PadR( hFiskalniParams[ "name" ], 40 )

   DO WHILE nTime > 0 .OR. LastKey() == K_ALT_Q

      -- nTime
      IF File( cFiskalniFileName )
         // fajl se pojavio - izadji iz petlje !
         EXIT
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( _u("Čekam na fiskalni uređaj: ") + AllTrim( Str( nTime ) ), 48 )

      IF nTime == 0 .OR. LastKey() == K_ALT_Q
         BoxC()
         RETURN -9
      ENDIF

      Sleep( 0.7 )

   ENDDO

   BoxC()

   IF !File( cFiskalniFileName )
      MsgBeep( "Fajl " + cFiskalniFileName + " ne postoji !!!" )
      nError := -9
      RETURN nError
   ENDIF

   nBrojFiskalnog := 0

   oFile := TFileRead():New( cFiskalniFileName )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFiskalniFileName ) )
      RETURN -9
   ENDIF

   cErrorCode := ""

   // prodji kroz svaku liniju i procitaj zapise
   WHILE oFile:MoreToRead()

      // uzmi u cLine liniju fajla
      cLine := hb_StrToUTF8( oFile:ReadLine() )
      aErrors := TokToNiz( cLine, "-" )

      // ovo je kod greske, npr. 1
      cErrorCode := AllTrim( aErrors[ 1 ] )
      _err_descr := AllTrim( aErrors[ 2 ] )

      IF !Empty( cErrorCode )
         EXIT
      ENDIF

   ENDDO

   oFile:Close()

   IF !Empty( cErrorCode )
      MsgBeep( "Greska: " + cErrorCode + " - " + _err_descr )
      nError := Val( cErrorCode )
      FErase( cFiskalniFileName )
   ENDIF

   RETURN nError
