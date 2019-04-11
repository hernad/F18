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


STATIC LEN_KOLICINA := 8
STATIC LEN_CIJENA := 10
STATIC LEN_VRIJEDNOST := 12
STATIC PIC_KOLICINA := ""
STATIC PIC_VRIJEDNOST := ""
STATIC PIC_CIJENA := ""
STATIC __zahtjev_nula := "0"

STATIC __xml_head := 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'

// direktorij odgovora
STATIC _d_answer := "odgovori"

// trigeri za naziv fajla
// stampa fiskalnog racuna
STATIC _tr_rac := "sfr"
// stampa reklamnog racuna
STATIC _tr_rrac := "srr"
// stampa dnevnog izvjestaja
STATIC _tr_drep := "sdi"
// stampa periodicnog izvjestaja
STATIC _tr_prep := "spi"
// stampa nefiskalni tekst
STATIC _tr_ntxt := "snd"
// unos novca
STATIC _tr_p_in := "un"
// povrat novca
STATIC _tr_p_out := "pn"
// stampa duplikata
STATIC _tr_dbl := "dup"
// reset data on PU server
STATIC _tr_x := "rst"
// inicijalizacija
STATIC _tr_init := "init"
// ponisti racun
STATIC _tr_crac := "pon"
// presjek stanja
STATIC _tr_xrpt := "sps"

// legenda nTrig vrijednosti za trigere...
// 1 - stampa racuna
// 2 - stampa reklamnog racuna
// 3 - stampa dnevnog izvjestaja
// 4 - stampa periodicnog izvjestaja
// 5 - stampa presjeka stanja x-rep
// 6 - polog ulaz
// 7 - polog izlaz
// 8 - duplikat
// 9 - reset podataka na serveru PU
// 10 - inicijalizacija
// 11 - ponisti racun

// ocekivana matrica aData:
//
// 1 - broj racuna
// 2 - redni broj
// 3 - id roba
// 4 - roba naziv
// 5 - cijena
// 6 - kolicina
// 7 - tarifa
// 8 - broj racuna za storniranje
// 9 - roba plu
// 10 - plu cijena - cijena iz sifranika
// 11 - popust
// 12 - barkod
// 13 - vrsta placanja
// 14 - total racuna
// 15 - datum racuna
// 16 - roba jmj


// struktura matrice aKupac
//
// aKupac[1] - idbroj kupca
// aKupac[2] - naziv
// aKupac[3] - adresa
// aKupac[4] - postanski broj
// aKupac[5] - grad stanovanja


// -------------------------------------------------------------------
// stampa fiskalnog racuna tring fiskalizacija
// -------------------------------------------------------------------
FUNCTION tring_rn( dev_param, items, head, storno )

   LOCAL _xml, _vrsta_zahtjeva
   LOCAL nI
   LOCAL _racun_broj
   LOCAL _vr_plac, _total_plac
   LOCAL _art_plu, _art_naz, _art_jmj, _cijena, _kolicina
   LOCAL _rabat, _grupa, _plu
   LOCAL _customer := .F.
   LOCAL _err_level := 0
   LOCAL _reklamni_racun
   LOCAL _trig
   LOCAL cFileName := dev_param[ "out_file" ]
   LOCAL _f_path := dev_param[ "out_dir" ]

   // stampanje racuna
   _vrsta_zahtjeva := "0"

   IF storno
      // stampanje reklamnog racuna
      _vrsta_zahtjeva := "2"
      _reklamni_racun := AllTrim( items[ 1, 8 ] )
   ENDIF

   PIC_KOLICINA := "9999999.99"
   PIC_VRIJEDNOST := "9999999.99"
   PIC_CIJENA := "9999999.99"

   IF head <> NIL .AND. Len( head ) > 0
      _customer := .T.
   ENDIF

   // to je zapravo broj racuna !!!
   _racun_broj := items[ 1, 1 ]

   _trig := 1

   // putanja do izlaznog xml fajla
   IF storno
      cFileName := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_rrac )
      _trig := 2
   ELSE
      cFileName := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_rac )
   ENDIF

   // c:\tring\xml\sfr.001
   _xml := _f_path + cFileName

   // brisi answer
   tring_delete_answer( dev_param, _trig )

   // otvori xml
   create_xml( _xml )

   // upisi header
   xml_head()

   xml_subnode( "RacunZahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", _racun_broj )

   // 0 - stampa sve stavke i zatvara racun
   // 1 - stampa stavku po stavku
   //
   // Mi cemo koristiti varijantu "0"
   xml_node( "VrstaZahtjeva", _vrsta_zahtjeva )

   xml_subnode( "NoviObjekat", .F. )

   // ako ima podataka o kupcu
   IF _customer

      xml_subnode( "Kupac", .F. )

      xml_node( "IDbroj", head[ 1, 1 ] )
      xml_node( "Naziv", to_xml_encoding( head[ 1, 2 ] ) )
      xml_node( "Adresa", to_xml_encoding( head[ 1, 3 ] ) )
      xml_node( "PostanskiBroj", head[ 1, 4 ] )
      xml_node( "Grad", to_xml_encoding( head[ 1, 5 ] ) )
      xml_subnode( "Kupac", .T. )

   ENDIF

   xml_subnode( "StavkeRacuna", .F. )

   FOR nI := 1 TO Len( items )

      _art_id := items[ nI, 3 ]
      _art_naz := AllTrim( PadR( items[ nI, 4 ], 36 ) )
      _art_jmj := items[ nI, 16 ]
      _cijena := items[ nI, 5 ]
      _kolicina := items[ nI, 6 ]
      _rabat := items[ nI, 11 ]
      _tarifa := fiskalni_tarifa( items[ nI, 7 ], dev_param[ "pdv" ], "TRING" )
      _grupa := ""
      _plu := AllTrim( Str( items[ nI, 9 ] ) )

      xml_subnode( "RacunStavka", .F. )

      xml_subnode( "artikal", .F. )

      xml_node( "Sifra", _plu )
      xml_node( "Naziv", to_xml_encoding( _art_naz ) )
      xml_node( "JM", to_xml_encoding( PadR( _art_jmj, 2 ) ) )
      xml_node( "Cijena", show_number( _cijena, PIC_CIJENA ) )
      xml_node( "Stopa", _tarifa )

      xml_subnode( "artikal", .T. )

      xml_node( "Kolicina", show_number( _kolicina, PIC_KOLICINA ) )
      xml_node( "Rabat", show_number( _rabat, PIC_VRIJEDNOST ) )

      xml_subnode( "RacunStavka", .T. )

   NEXT

   xml_subnode( "StavkeRacuna", .T. )

   // vrste placanja, oznaka:
   // "GOTOVINA"
   // "CEK"
   // "VIRMAN"
   // "KARTICA"

   IF AllTrim( items[ 1, 13 ] ) == "3" .AND. storno
      _vr_plac := fiskalni_vrsta_placanja( "2", "TRING" )
   ELSE
      _vr_plac := fiskalni_vrsta_placanja( "0", "TRING" )
   ENDIF

   _total_plac := 0

   xml_subnode( "VrstePlacanja", .F. )
   xml_subnode( "VrstaPlacanja", .F. )

   xml_node( "Oznaka", _vr_plac )
   xml_node( "Iznos", AllTrim( Str( _total_plac ) ) )

   xml_subnode( "VrstaPlacanja", .T. )
   xml_subnode( "VrstePlacanja", .T. )

   xml_node( "Napomena", "racun br: " + _racun_broj )

   IF storno
      xml_node( "BrojRacuna", _reklamni_racun )
   ELSE
      xml_node( "BrojRacuna", _racun_broj )
   ENDIF

   xml_subnode( "NoviObjekat", .T. )

   xml_subnode( "RacunZahtjev", .T. )

   close_xml()

   RETURN _err_level


// ----------------------------------------------
// polog novca u uredjaj
// ----------------------------------------------
FUNCTION tring_polog( dev_param )

   LOCAL cFileName
   LOCAL _xml
   LOCAL _zahtjev_broj := "0"
   LOCAL _zahtjev_vrsta := "7"
   LOCAL _cash := 0
   LOCAL _trig := 6

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Unesi polog:" GET _cash ;
      PICT "999999.99"
   READ
   BoxC()

   IF _cash = 0 .OR. LastKey() == K_ESC
      RETURN
   ENDIF

   cFileName := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_p_in )

   IF _cash < 0
      // ovo je povrat
      _zahtjev_vrsta := "8"
      cFileName := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_p_out )
      _trig := 7
   ENDIF

   // brisi answer
   tring_delete_answer( dev_param, _trig )

   // c:\tring\xml\unosnovca.001
   _xml := dev_param[ "out_dir" ] + cFileName

   // otvori xml
   create_xml( _xml )

   // upisi header
   xml_head()

   xml_subnode( "RacunZahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", _zahtjev_broj )
   xml_node( "VrstaZahtjeva", _zahtjev_vrsta )

   xml_subnode( "NoviObjekat", .F. )

   xml_node( "Oznaka", "Gotovina" )
   xml_node( "Iznos", AllTrim( Str( _cash, 12, 2 ) ) )

   xml_subnode( "NoviObjekat", .T. )

   xml_subnode( "RacunZahtjev", .T. )

   close_xml()

   RETURN




// ----------------------------------------------
// prepis dokumenata
// ----------------------------------------------
FUNCTION tring_double( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL cBr_zahtjeva := "0"
   LOCAL cVr_zahtjeva := "3"
   LOCAL nFisc_no := 0
   LOCAL nTrigg := 8

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Duplikat racuna:" GET nFisc_no
   READ
   BoxC()

   IF nFisc_no = 0 .OR. LastKey() == K_ESC
      RETURN
   ENDIF

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_dbl )

   // c:\tring\xml\stampatiperiodicniizvjestaj.001
   cXML := dev_param[ "out_dir" ] + cF_out

   // brisi answer
   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Zahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", AllTrim( Str( nFisc_no ) ) )
   xml_node( "VrstaZahtjeva", cVr_zahtjeva )
   xml_node( "Parametri", "" )

   xml_subnode( "Zahtjev", .T. )

   close_xml()

   RETURN .T.


// ----------------------------------------------
// periodicni izvjestaj
// ----------------------------------------------
FUNCTION tring_per_rpt( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL cBr_zahtjeva := "0"
   LOCAL cVr_zahtjeva := "5"
   LOCAL cDatumOd := ""
   LOCAL cDatumDo := ""
   LOCAL dD_od := Date() -30
   LOCAL dD_do := Date()
   LOCAL nTrigg := 4

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Od datuma:" GET dD_od
   @ box_x_koord() + 1, Col() + 1 SAY "do:" GET dD_do
   READ
   BoxC()

   cDatumOd := fprint_formatiranje_datuma( dD_od )
   cDatumDo := fprint_formatiranje_datuma( dD_do )

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_prep )

   // c:\tring\xml\stampatiperiodicniizvjestaj.001
   cXML := dev_param[ "out_dir" ] + cF_out

   // brisi answer
   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Zahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", cBr_zahtjeva )
   xml_node( "VrstaZahtjeva", cVr_zahtjeva )

   xml_subnode( "Parametri", .F. )

   xml_subnode( "Parametar", .F. )
   xml_node( "Naziv", "odDatuma" )
   xml_node( "Vrijednost", cDatumOd )
   xml_subnode( "Parametar", .T. )

   xml_subnode( "Parametar", .F. )
   xml_node( "Naziv", "doDatuma" )
   xml_node( "Vrijednost", cDatumDo )
   xml_subnode( "Parametar", .T. )

   xml_subnode( "Parametri", .T. )

   xml_subnode( "Zahtjev", .T. )

   // zatvori fajl...
   close_xml()

   RETURN

// ----------------------------------------------
// reset zahtjeva
// ----------------------------------------------
FUNCTION tring_reset( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL nTrigg := 9

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_x )

   // c:\tring\xml\reset.001
   cXML := dev_param[ "out_dir" ] + cF_out

   // brisi answer
   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_node( "boolean", "false" )

   // zatvori fajl...
   close_xml()

   RETURN


// ----------------------------------------------
// inicijalizacija
// ----------------------------------------------
FUNCTION tring_init( dev_param, cOper, cPwd )

   LOCAL cF_out
   LOCAL cXml
   LOCAL nTrigg := 10

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_init )

   cOper := AllTrim( dev_param[ "op_id" ] )

   // c:\tring\xml\inicijalizacija.001
   cXML := dev_param[ "out_dir" ] + cF_out

   // brisi answer
   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Operator " + __xml_head, .F. )

   xml_node( "BrojOperatora", cOper )
   xml_node( "Lozinka", cPwd )

   xml_subnode( "Operator", .T. )


   RETURN close_xml()



// ----------------------------------------------
// prekini racun
// ----------------------------------------------
FUNCTION tring_close_rn( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL cBr_zahtjeva := "0"
   LOCAL cVr_zahtjeva := "9"
   LOCAL nTrigg := 11

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_crac )

   // c:\tring\xml\prekiniracun.001
   cXML := dev_param[ "out_dir" ] + cF_out

   // brisi out
   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Zahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", cBr_zahtjeva )
   xml_node( "VrstaZahtjeva", cVr_zahtjeva )
   xml_node( "Parametri", "" )

   xml_subnode( "Zahtjev", .T. )

   // zatvori fajl...
   close_xml()

   RETURN


// ----------------------------------------------
// presjek stanja
// ----------------------------------------------
FUNCTION tring_x_rpt( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL cBr_zahtjeva := "0"
   LOCAL cVr_zahtjeva := "3"
   LOCAL nTrigg := 5

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_xrpt )

   // c:\tring\xml\stampatidnevniizvjestaj.001
   cXML := dev_param[ "out_dir" ] + cF_out

   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Zahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", cBr_zahtjeva )
   xml_node( "VrstaZahtjeva", cVr_zahtjeva )
   xml_node( "Parametri", "" )

   xml_subnode( "Zahtjev", .T. )

   // zatvori fajl...
   close_xml()

   RETURN


// ----------------------------------------------
// dnevni izvjestaj
// ----------------------------------------------
FUNCTION tring_daily_rpt( dev_param )

   LOCAL cF_out
   LOCAL cXml
   LOCAL cBr_zahtjeva := "0"
   LOCAL cVr_zahtjeva := "4"
   LOCAL nTrigg := 3
   LOCAL _param_date, _param_time
   LOCAL _rpt_type := "Z"

   IF Pitanje(, "Stampati dnevni izvjestaj", "D" ) == "N"
      RETURN .F.
   ENDIF

   _param_date := "zadnji_" + _rpt_type + "_izvjestaj_datum"
   _param_time := "zadnji_" + _rpt_type + "_izvjestaj_vrijeme"

   // iscitaj zadnje formirane izvjestaje...
   _last_date := fetch_metric( _param_date, NIL, CToD( "" ) )
   _last_time := PadR( fetch_metric( _param_time, NIL, "" ), 5 )

   IF Date() == _last_date
      MsgBeep( "Zadnji dnevni izvjestaj radjen " + DToC( _last_date ) + " u " + _last_time )
   ENDIF

   cF_out := fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _tr_drep )

   // c:\tring\xml\stampatidnevniizvjestaj.001
   cXML := dev_param[ "out_dir" ] + cF_out

   tring_delete_answer( dev_param, nTrigg )

   // otvori xml
   create_xml( cXml )

   // upisi header
   xml_head()

   xml_subnode( "Zahtjev " + __xml_head, .F. )

   xml_node( "BrojZahtjeva", cBr_zahtjeva )
   xml_node( "VrstaZahtjeva", cVr_zahtjeva )
   xml_node( "Parametri", "" )

   xml_subnode( "Zahtjev", .T. )

   // zatvori fajl...
   close_xml()

   // upisi zadnji dnevni izvjestaj
   set_metric( _param_date, NIL, Date() )
   set_metric( _param_time, NIL, Time() )

   // nakon ovoga provjeri

   RETURN .T.


// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
FUNCTION tring_delete_out( dev_param, trig )

   LOCAL _trig := trg_trig( trig )
   LOCAL _file

   _file := dev_param[ "out_dir" ] + fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _trig )

   IF File( _file )
      FErase( _file )
   ENDIF

   RETURN


// ----------------------------------------------
// brise fajlove iz direktorija odgovora
// ----------------------------------------------
FUNCTION tring_delete_answer( dev_param, trig )

   LOCAL _trig := trg_trig( trig )
   LOCAL _file

   _file := dev_param[ "out_dir" ] + _d_answer + SLASH + ;
      fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _trig )

   IF File( _file )
      FErase( _file )
   ENDIF

   RETURN


// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
FUNCTION tring_delete_tmp( dev_param, cPodDir )

   LOCAL cTmp

   IF cPodDir == nil
      cPodDir := ""
   ENDIF

   MsgO( "brisem tmp fajlove..." )

   cF_path := dev_param[ "out_dir" ]

   IF !Empty( cPoddir )
      cF_path += cPodDir + SLASH
   ENDIF

   cTmp := "*.*"

   AEval( Directory( cF_path + cTmp ), {| aFile| FErase( cF_path + ;
      AllTrim( aFile[ 1 ] ) ) } )

   sleep( 1 )

   MsgC()

   RETURN




// ---------------------------------------------
// fiksiraj datum za xml
// ---------------------------------------------
STATIC FUNCTION fprint_formatiranje_datuma( dDate, cPattern )

   LOCAL cRet := ""
   LOCAL nYear := Year( dDate )
   LOCAL nMonth := Month ( dDate )
   LOCAL nDay := Day ( dDate )

   IF cPattern == nil
      cPattern := ""
   ENDIF

   IF Empty( cPattern )

      cRet := AllTrim( Str ( nDay ) ) + "." + ;
         AllTrim( Str( nMonth ) ) + "." + ;
         AllTrim( Str( nYear ) )

      RETURN cRet

   ENDIF

   // MM.DD.YYYY

   cPattern := StrTran( cPattern, "MM", AllTrim( Str( nMonth ) ) )
   cPattern := StrTran( cPattern, "DD", AllTrim( Str( nDay ) ) )
   cPattern := StrTran( cPattern, "YYYY", AllTrim( Str( nYear ) ) )
   // if .YY in pattern
   cPattern := StrTran( cPattern, "YY", AllTrim( PadL( Str( nYear ), 2 ) ) )

   cRet := cPattern

   RETURN cRet




// ------------------------------------------
// procitaj gresku
// ------------------------------------------
FUNCTION tring_read_error( dev_param, fisc_no, trig )

   LOCAL nErr := 0
   LOCAL _trig := trg_trig( trig )
   LOCAL cFileName
   LOCAL nI, _time
   LOCAL _err_data, _scan, cErrorTxt
   LOCAL _ok
   LOCAL oFile
   LOCAL cFiskalniTxt

   _time := dev_param[ "timeout" ]

   // primjer: c:\tring\xml\odgovori\sfr.001
   cFileName := dev_param[ "out_dir" ] + ;
      _d_answer + ;
      SLASH + ;
      fiscal_out_filename( dev_param[ "out_file" ], __zahtjev_nula, _trig )

   _err_data := {}

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Uredjaj ID: " + AllTrim( Str( dev_param[ "id" ] ) ) + ;
      " : " + PadR( dev_param[ "name" ], 40 )

   DO WHILE _time > 0

      -- _time
      IF File( cFileName )
         // fajl se pojavio - izadji iz petlje !
         EXIT
      ENDIF

      @ box_x_koord() + 3, box_y_koord() + 2 SAY PadR( "Cekam na fiskalni uredjaj: " + AllTrim( Str( _time ) ), 48 )

      sleep( 1 )

   ENDDO

   BoxC()

   IF !File( cFileName )
      MsgBeep( "Fajl " + cFileName + " ne postoji !" )
      fisc_no := 0
      nErr := -9
      RETURN nErr
   ENDIF

   fisc_no := 0

   oFile := TFileRead():New( cFileName )
   oFile:Open()

   IF oFile:Error()
      MsgBeep( oFile:ErrorMsg( "Problem sa otvaranjem fajla: " + cFileName ) )
      RETURN -9
   ENDIF

   cFiskalniTxt := ""
   _ok := .F.

   // prodji kroz svaku liniju i procitaj zapise
   WHILE oFile:MoreToRead()

      // uzmi u cErr liniju fajla
      cErrorTxt := hb_StrToUTF8( oFile:ReadLine() )

      // ovo je dodavanje artikla
      IF ( "<?xml" $ cErrorTxt ) .OR. ;
            ( "<KasaOdgovor" $ cErrorTxt ) .OR. ;
            ( "</KasaOdgovor" $ cErrorTxt ) .OR. ;
            ( "<Odgovor" $ cErrorTxt ) .OR. ;
            ( "</Odgovor" $ cErrorTxt )
         // preskoci
         LOOP
      ENDIF

      AAdd( _err_data, cErrorTxt )

   ENDDO

   oFile:Close()

   // sad imam matricu sa linijama
   // aErr_data[1, "<Naziv>OK</Naziv>"]
   // aErr_data[2, "<Vrijednost></Vrijednost>"]
   // aErr_data[3, "<Naziv>BrojFiskalnogRacuna</Naziv>"]
   // aErr_data[4, "<Vrijednost>5</Vrijednost>"]
   // ... itd...

   // prvo provjeri da li je komanda ok
   _scan := AScan( _err_data, {| val | "<VrstaOdgovora>OK" $ val } )
   IF _scan <> 0
      // ovo je ok racun ili bilo koja komanda
      _ok := .T.
   ENDIF

   IF _ok == .F.
      // nije ispravna komanda
      nErr := 1
      RETURN nErr
   ENDIF

   // sada cemo potraziti broj fiskalnog racuna
   _scan := AScan( _err_data, ;
      {| val | "<Naziv>BrojFiskalnogRacuna" $ val } )

   IF _scan <> 0
      // imamo racun
      // ali se krije na sljedecoj liniji
      // zato + 1
      fisc_no := fisc_get_broj_fiskalnog_racuna( _err_data[ _scan + 1 ] )
   ENDIF

   RETURN nErr




// ------------------------------------------------------
// vraca broj fiskalnog racuna iz linije fajla
// ------------------------------------------------------
STATIC FUNCTION fisc_get_broj_fiskalnog_racuna( row )

   LOCAL _fiscal_no := 0

   row := StrTran( row, '<Vrijednost xsi:type="xsd:long">', '' )
   row := StrTran( row, '</Vrijednost>', '' )
   // ostatak bi trebao da bude samo broj fiskalnog racuna :)
   IF !Empty( row )
      _fiscal_no := Val( AllTrim( row ) )
   ENDIF

   RETURN _fiscal_no





// ------------------------------------------
// vraca triger za tring filename
// ------------------------------------------
FUNCTION trg_trig( nTrig )

   LOCAL cTrig := ""

   DO CASE
   CASE nTrig = 1
      // stampa racuna
      cTrig := _tr_rac
   CASE nTrig = 2
      // stampa reklamnog racuna
      cTrig := _tr_rrac
   CASE nTrig = 3
      // stampa dnevnog izvjestaja
      cTrig := _tr_drep
   CASE nTrig = 4
      // stampa periodicnog izvjestaja
      cTrig := _tr_prep
   CASE nTrig = 5
      // stampa presjeka stanja
      cTrig := _tr_xrep
   CASE nTrig = 6
      // polog in
      cTrig := _tr_p_in
   CASE nTrig = 7
      // polog out
      cTrig := _tr_p_out
   CASE nTrig = 8
      // duplikat
      cTrig := _tr_dbl
   CASE nTrig = 9
      // reset podataka na serveru
      cTrig := _tr_x
   CASE nTrig = 10
      // inicijalizacija
      cTrig := _tr_init
   CASE nTrig = 11
      // ponisti racun
      cTrig := _tr_crac
   OTHERWISE
      // u drugom slucaju nema trigera
      cTrig := "xxx"
   ENDCASE

   RETURN cTrig
