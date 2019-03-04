/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


// stampanje dokumenata .t. or .f.
STATIC __stampaj
STATIC __partn
STATIC __mkonto
STATIC __trosk

// ----------------------------------------------
// Menij opcije import txt
// ----------------------------------------------
FUNCTION meni_import_csv()

   PRIVATE izbor := 1
   PRIVATE opc := {}
   PRIVATE opcexe := {}

   __stampaj := .F.
   __trosk := .F.

   IF gAImpPrint == "D"
      __stampaj := .T.
   ENDIF

   AAdd( opc, "1. import csv racun                 " )
   AAdd( opcexe, {|| ImpCsvDok() } )
   AAdd( opc, "2. import csv - ostalo " )
   AAdd( opcexe, {|| ImpCsvOst() } )
   AAdd( opc, "6. podesenja importa " )
   AAdd( opcexe, {|| kalk_auto_import_setup() } )

   f18_menu_sa_priv_vars_opc_opcexe_izbor( "ics" )

   RETURN .T.


// ----------------------------------
// podesenja importa
// ----------------------------------
STATIC FUNCTION kalk_auto_import_setup()

   LOCAL nX
   LOCAL GetList := {}

   LOCAL cAImpRKonto := PadR( kalk_imp_txt_param_auto_import_podataka_konto(), 7 )

   nX := 1

   Box(, 10, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Podešenja importa ********"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Štampati dokumente pri auto obradi (D/N)" GET gAImpPrint VALID gAImpPrint $ "DN" PICT "@!"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Automatska ravnoteža naloga na konto: " GET cAImpRKonto
   READ
   BoxC()

   IF LastKey() <> K_ESC

      kalk_imp_txt_param_auto_import_podataka_konto( cAImpRKonto )
      o_params()

      PRIVATE cSection := "7"
      PRIVATE cHistory := " "
      PRIVATE aHistory := {}

      WPar( "ap", gAImpPrint )


      SELECT params
      USE

   ENDIF

   RETURN .T.

// ----------------------------------------
// setuj glavne parametre importa
// ----------------------------------------
STATIC FUNCTION _g_params()

   LOCAL cMKto
   LOCAL cPart
   PRIVATE GetList := {}

   cMKto := PadR( "1312", 7 )
   cPart := PadR( "", 6 )

   o_params()

   PRIVATE cSection := "8"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   RPar( "ik", @cMKto )
   RPar( "ip", @cPart )

   Box(, 5, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "*** parametri importa dokumenta"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto zaduzuje  :" GET cMKto VALID P_Konto( @cMKto )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Sifra dobavljaca:" GET cPart VALID p_partner( @cPart )
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   o_params()
   PRIVATE cSection := "8"
   PRIVATE cHistory := " "
   PRIVATE aHistory := {}

   WPar( "ik", cMKto )
   WPar( "ip", cPart )

   SELECT params
   USE

   // setuj staticke varijable
   __mkonto := cMKto
   __partn := cPart

   RETURN 1

// -----------------------------------------------------
// import CSV fajla - ostalo, partneri npr...
// -----------------------------------------------------
FUNCTION ImpCSVOst()

   PRIVATE cExpPath
   PRIVATE cImpFile

   // setuj varijablu putanje exportovanih fajlova
   cExpPath := get_liste_za_import_path()

   // daj mi filter za CSV fajlove
   cFFilt := GetImpFilter()

   // daj mi pregled fajlova za import, te setuj varijablu cImpFile
   IF get_file_list( cFFilt, cExpPath, @cImpFile ) == 0
      RETURN
   ENDIF

   // provjeri da li je fajl za import prazan
   IF fajl_get_broj_linija( cImpFile ) == 0
      MsgBeep( "Odabrani fajl je prazan!#!!! Prekidam operaciju !!!" )
      RETURN
   ENDIF

   PRIVATE aDbf := {}
   PRIVATE aFaktEx

   // setuj polja temp tabele u matricu aDbf
   SetTblOST( @aDbf )

   // prebaci iz txt => temp tbl
   Txt2TOst( aDbf, cImpFile )

   // importuj podatke u partnere
   ImportOst()

   kalk_imp_brisi_txt( cImpFile, .T. )

   RETURN


// --------------------------------------
// Import dokumenta iz csv fajla
// --------------------------------------
FUNCTION ImpCSVDok()

   PRIVATE cExpPath
   PRIVATE cImpFile

   // setuj varijablu putanje exportovanih fajlova
   cExpPath := get_liste_za_import_path()

   // daj mi filter za import MP ili VP
   cFFilt := GetImpFilter()

   // daj mi pregled fajlova za import, te setuj varijablu cImpFile
   IF get_file_list( cFFilt, cExpPath, @cImpFile ) == 0
      RETURN
   ENDIF

   // uzmi bitne parametre importa fajla
   IF _g_params() == 0
      RETURN
   ENDIF

   // provjeri da li je fajl za import prazan
   IF fajl_get_broj_linija( cImpFile ) == 0
      MsgBeep( "Odabrani fajl je prazan!#!!! Prekidam operaciju !!!" )
      RETURN
   ENDIF

   PRIVATE aDbf := {}
   PRIVATE aFaktEx

   // setuj polja temp tabele u matricu aDbf
   SetTblDok( @aDbf )

   // prebaci iz txt => temp tbl
   kalk_imp_csv_to_temp( aDbf, cImpFile )

   IF !CheckDok()
      MsgBeep( "Prekidamo operaciju !!!#Nepostojece sifre!!!" )
      RETURN .F.
   ENDIF

   IF CheckBrFakt( @aFaktEx ) == 0
      MsgBeep( "Operacija prekinuta!" )
      RETURN .F.
   ENDIF

   IF TTbl2Kalk() == 0
      MsgBeep( "Operacija prekinuta!" )
      RETURN
   ENDIF

   // obrada dokumenata iz pript tabele
   MnuObrDok()

   kalk_imp_brisi_txt( cImpFile, .T. )

   RETURN


// ----------------------------------------------
// Vraca filter za naziv dokumenta
// ----------------------------------------------
STATIC FUNCTION GetImpFilter()

   LOCAL cRet := "*.csv"

   RETURN cRet


// ------------------------------------------------
// Obrada dokumenata iz pomocne tabele
// ------------------------------------------------
STATIC FUNCTION MnuObrDok()

   IF Pitanje(, "Obraditi automatski dokument iz kalk_pripreme (D/N)?", "N" ) == "D"
      kalk_import_csv_obradi_dokument( NIL, NIL, __stampaj )
   ELSE
      MsgBeep( "Dokument nije obradjen!#Obradu uradite iz kalk_pripreme!" )
      my_close_all_dbf()
   ENDIF

   RETURN


// -------------------------------------------------------
// Setuj matricu sa poljima tabele dokumenata OSTALO
// -------------------------------------------------------
STATIC FUNCTION SetTblOST( aDbf )

   AAdd( aDbf, { "idpartner", "C", 6, 0 } )
   AAdd( aDbf, { "idrefer",   "C", 10, 0 } )

   RETURN

// -------------------------------------------------------
// Setuj matricu sa poljima tabele dokumenata RACUN
// -------------------------------------------------------
STATIC FUNCTION SetTblDok( aDbf )

   AAdd( aDbf, { "idfirma", "C", 2, 0 } )
   AAdd( aDbf, { "idtipdok", "C", 2, 0 } )
   AAdd( aDbf, { "brdok", "C", 8, 0 } )
   AAdd( aDbf, { "datdok", "D", 8, 0 } )
   AAdd( aDbf, { "idpartner", "C", 6, 0 } )
   AAdd( aDbf, { "rbr", "C", 3, 0 } )
   AAdd( aDbf, { "idroba", "C", 10, 0 } )
   AAdd( aDbf, { "nazroba", "C", 100, 0 } )
   AAdd( aDbf, { "kolicina", "N", 14, 5 } )
   AAdd( aDbf, { "cijena", "N", 14, 5 } )
   AAdd( aDbf, { "rabat", "N", 14, 5 } )
   AAdd( aDbf, { "porez", "N", 14, 5 } )
   AAdd( aDbf, { "rabatp", "N", 14, 5 } )
   AAdd( aDbf, { "datval", "D", 8, 0 } )
   AAdd( aDbf, { "trosk1", "N", 14, 5 } )
   AAdd( aDbf, { "trosk2", "N", 14, 5 } )
   AAdd( aDbf, { "trosk3", "N", 14, 5 } )
   AAdd( aDbf, { "trosk4", "N", 14, 5 } )
   AAdd( aDbf, { "trosk5", "N", 14, 5 } )

   RETURN .T.



FUNCTION get_liste_za_import_path()

   LOCAL cPath

   IF is_windows()
      cPath := "c:" + SLASH + "liste" + SLASH
   ELSE
      cPath :=  "/data/liste/"
   ENDIF

   RETURN cPath


// --------------------------------------------------------
// Kreiranje temp tabele, te prenos zapisa iz text fajla
// "cTextFile" u tabelu
// - param aDbf - struktura tabele
// - param cTxtFile - txt fajl za import
// --------------------------------------------------------
FUNCTION Txt2TOst( aDbf, cTxtFile )

   LOCAL cDelimiter := ";"
   LOCAL _o_file

   // prvo kreiraj tabelu temp
   my_close_all_dbf()

   CreTemp( aDbf, .F. )
   O_TEMP

   IF !File( f18_ime_dbf( "TEMP" ) )
      MsgBeep( "Ne mogu kreirati fajl TEMP.DBF!" )
      RETURN
   ENDIF

   // zatim iscitaj fajl i ubaci podatke u tabelu

   cTxtFile := AllTrim( cTxtFile )

   _o_file := TFileRead():New( cTxtFile )
   _o_file:Open()

   IF _o_file:Error()
      MsgBeep( _o_file:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
      RETURN
   ENDIF


   // prodji kroz svaku liniju i insertuj zapise u temp.dbf
   WHILE _o_file:MoreToRead()

      // uzmi u cText liniju fajla
      cVar := hb_StrToUTF8( _o_file:ReadLine() )

      IF Empty( cVar )
         LOOP
      ENDIF

      aRow := csvrow2arr( cVar, cDelimiter )

      // selektuj temp tabelu
      SELECT TEMP
      // dodaj novi zapis
      APPEND BLANK

      // struktura podataka u csv-u je
      // [1] - redni broj
      // [2] - broj narudzbe

      // pa uzimamo samo sta nam treba
      cTmp := AllTrim( aRow[ 1 ] )

      IF Len( cTmp ) = 4
         cTmp := "10" + cTmp
      ELSEIF Len( cTmp ) = 5
         cTmp := "1" + cTmp
      ENDIF

      REPLACE idpartner WITH cTmp
      REPLACE idrefer WITH AllTrim( aRow[ 2 ] )

   ENDDO

   _o_file:Close()

   SELECT TEMP

   MsgBeep( "Import txt => temp - OK" )

   RETURN .T.



// -------------------------------------------
// importuj podatke ostalo
// -------------------------------------------
STATIC FUNCTION importost()

   LOCAL nTarea := Select()
   LOCAL cPartId
   LOCAL cRefId
   LOCAL nCnt := 0

   o_partner()

   SELECT TEMP
   GO TOP

   DO WHILE !Eof()

      cPartId := field->idpartner
      cRefId := field->idrefer

      SELECT partn
      GO TOP
      SEEK cPartId

      IF Found() .AND. AllTrim( partn->idrefer ) <> AllTrim( cRefId )
         ++nCnt
         REPLACE idrefer WITH cRefId
      ENDIF

      SELECT TEMP

      SKIP
   ENDDO

   IF nCnt > 0
      MsgBeep( "zamjenjeno " + AllTrim( Str( nCnt ) ) + " stavki..." )
   ENDIF

   SELECT ( nTarea )

   RETURN .T.


// --------------------------------------------------------
// Kreiranje temp tabele, te prenos zapisa iz text fajla
// "cTextFile" u tabelu putem aRules pravila
// - param aDbf - struktura tabele
// - param cTxtFile - txt fajl za import
// --------------------------------------------------------
STATIC FUNCTION kalk_imp_csv_to_temp( aDbf, cTxtFile )

   LOCAL cDelimiter := ";"
   LOCAL cBrFakt
   LOCAL dDatDok
   LOCAL dDatIsp
   LOCAL dDatVal
   LOCAL nTrosk1
   LOCAL nTrosk2
   LOCAL nTrosk3
   LOCAL nTrosk4
   LOCAL nTrosk5
   LOCAL aFMat
   LOCAL cFirstRow
   LOCAL _o_file

   // prvo kreiraj tabelu temp
   my_close_all_dbf()

   CreTemp( aDbf )
   O_TEMP

   IF !File( f18_ime_dbf( "TEMP" ) )
      MsgBeep( "Ne mogu kreirati fajl TEMP.DBF!" )
      RETURN .F.
   ENDIF

   // zatim iscitaj fajl i ubaci podatke u tabelu
   cTxtFile := AllTrim( cTxtFile )

   _o_file := TFileRead():New( cTxtFile )
   _o_file:Open()

   IF _o_file:Error()
      MsgBeep( _o_file:ErrorMsg( "Problem sa otvaranjem fajla: " ) )
      RETURN
   ENDIF

   // prvi red csv fajla je ovo:
   cFirstRow := hb_StrToUTF8( _o_file:ReadLine() )

   // napuni ga u matricu
   aFirstRow := csvrow2arr( cFirstRow, cDelimiter )

   // struktura bi trebala da bude ovakva:
   // [1] - broj dokumenta fakture
   // [2] - godina fakture "2008" npr
   // [3] - datum fakture
   // [4] - datum isporuke
   // [5] - datum valute
   // [6] - ukupno faktura u EUR
   // [7]..[11] - troskovi manualno uneseni

   // setuj glavne stavke dokumenta
   cBrDok := aFirstRow[ 1 ]
   dDatDok := CToD( aFirstRow[ 3 ] )
   dDatIsp := CToD( aFirstRow[ 4 ] )
   dDatVal := CToD( aFirstRow[ 5 ] )

   // troskovi
   nTrosk1 := 0
   nTrosk2 := 0
   nTrosk3 := 0
   nTrosk4 := 0
   nTrosk5 := 0

   IF Len( aFirstRow ) > 6
      nTrosk1 := _g_num( aFirstRow[ 7 ] )
   ENDIF
   IF Len( aFirstRow ) > 7
      nTrosk2 := _g_num( aFirstRow[ 8 ] )
   ENDIF
   IF Len( aFirstRow ) > 8
      nTrosk3 := _g_num( aFirstRow[ 9 ] )
   ENDIF
   IF Len( aFirstRow ) > 9
      nTrosk4 := _g_num( aFirstRow[ 10 ] )
   ENDIF
   IF Len( aFirstRow ) > 10
      nTrosk5 := _g_num( aFirstRow[ 11 ] )
   ENDIF

   // provjeri hoce li se koristiti automatski troskovi
   IF ( ( nTrosk1 + nTrosk2 + nTrosk3 + nTrosk4 + nTrosk5 ) <> 0 )
      __trosk := .T.
   ENDIF

   // prodji kroz svaku liniju i insertuj zapise u temp.dbf
   WHILE _o_file:MoreToRead()

      // uzmi u cText liniju fajla
      cVar := hb_StrToUTF8( _o_file:ReadLine() )

      IF Empty( cVar )
         LOOP
      ENDIF

      aRow := csvrow2arr( cVar, cDelimiter )

      // selektuj temp tabelu
      SELECT TEMP
      // dodaj novi zapis
      APPEND BLANK

      // struktura podataka u csv-u je
      // [1] - redni broj
      // [2] - broj narudzbe
      // [3] - sifra artikla
      // [4] - zamjenska sifra artikla
      // [5] - rabatna skupina
      // [6] - naziv artikla
      // [7] - jmj
      // [8] - porijeklo
      // [9] - broj narudzbe iz torina
      // [10] - kolicina
      // [11] - tezina
      // [12] - cijena
      // [13] - ukupno stavka (kol*cijena)
      // [14] - broj hitne narudzbe

      // pa uzimamo samo sta nam treba

      REPLACE idfirma WITH self_organizacija_id()
      REPLACE idtipdok WITH "01"
      REPLACE brdok WITH cBrDok
      REPLACE datdok WITH dDatDok
      REPLACE idpartner WITH "TEST"
      REPLACE datval WITH dDatVal
      REPLACE rbr WITH aRow[ 1 ]
      REPLACE idroba WITH PadR( AllTrim( aRow[ 3 ] ), 10 )
      REPLACE nazroba WITH AllTrim( aRow[ 6 ] )
      REPLACE kolicina WITH _g_num( aRow[ 10 ] )
      REPLACE cijena WITH _g_num( aRow[ 12 ] )
      REPLACE rabat WITH 0
      REPLACE porez WITH 0
      REPLACE rabatp WITH 0
      REPLACE trosk1 WITH nTrosk1
      REPLACE trosk2 WITH nTrosk2
      REPLACE trosk3 WITH nTrosk3
      REPLACE trosk4 WITH nTrosk4
      REPLACE trosk5 WITH nTrosk5

   ENDDO

   _o_file:Close()

   SELECT TEMP

   MsgBeep( "Import txt => temp - OK" )

   RETURN




// ----------------------------------------------------------------
// Kreira tabelu my_home()/TEMP.DBF prema definiciji polja iz aDbf
// ----------------------------------------------------------------
STATIC FUNCTION CreTemp( aDbf, lIndex )

   cTmpTbl := "TEMP"

   IF lIndex == nil
      lIndex := .T.
   ENDIF

   IF File( f18_ime_dbf( cTmpTbl ) ) .AND. FErase( f18_ime_dbf( cTmpTbl ) ) == -1
      MsgBeep( "Ne mogu izbrisati TEMP.DBF!" )

   ENDIF

   DbCreate2( cTmpTbl, aDbf )

   IF lIndex
      create_index( "1", "idfirma+idtipdok+brdok+rbr", cTmpTbl )
   ENDIF

   RETURN .T.

// -----------------------------------------------------------------
// Provjeri da li postoji broj fakture u azuriranim dokumentima
// -----------------------------------------------------------------
STATIC FUNCTION CheckBrFakt( aFakt )

   LOCAL aPomFakt

   aPomFakt := FaktExist()

   IF Len( aPomFakt ) > 0

      START PRINT CRET
      ?
      ? "Kontrola azuriranih dokumenata:"
      ? "-------------------------------"
      ? "Broj fakture => kalkulacija"
      ? "-------------------------------"
      ?

      FOR i := 1 TO Len( aPomFakt )
         ? aPomFakt[ i, 1 ] + " => " + aPomFakt[ i, 2 ]
      NEXT

      ?
      ? "Kontrolom azuriranih dokumenata, uoceno da se vec pojavljuju"
      ? "navedeni brojevi faktura iz fajla za import !"
      ?

      FF
      ENDPRINT

      aFakt := aPomFakt
      RETURN 0

   ENDIF

   aFakt := aPomFakt

   RETURN 1



// ---------------------------------------------------------------
// Provjera da li postoje sve sifre u sifarnicima za dokumente
// ---------------------------------------------------------------
STATIC FUNCTION CheckDok()

   LOCAL aPomArt

   aPomArt  := kalk_imp_partn_exist()

   IF ( Len( aPomArt ) > 0 )

      start_print_editor()

      IF ( Len( aPomArt ) > 0 )
         ? "Lista nepostojećih artikala:"
         ? "-----------------------------------------"
         ?
         FOR ii := 1 TO Len( aPomArt )

            // sifra
            ? aPomArt[ ii, 1 ]

            // naziv artikla
            ?? Space( 2 ) + "-" + Space( 1 ) + aPomArt[ ii, 2 ]

         NEXT
         ?
      ENDIF

      end_print_editor()

      RETURN .F.

   ENDIF

   RETURN .T.


// ----------------------------------------------------------
// Vraca kalk tip dokumenta na osnovu fakt tip dokumenta
// ----------------------------------------------------------
STATIC FUNCTION GetKTipDok( cFaktTD )

   LOCAL cRet := ""

   IF ( cFaktTD == "" .OR. cFaktTD == NIL )
      RETURN "XX"
   ENDIF

   DO CASE
      // ulazni racun fakt
      // FAKT 01 -> KALK 10
   CASE cFaktTD == "01"
      cRet := "10"

   ENDCASE

   RETURN cRet


// ---------------------------------------------------------------
// vraca matricu sa parovima faktura -> pojavljuje se u azur.kalk
// ---------------------------------------------------------------
STATIC FUNCTION FaktExist()

   o_kalk_doks()

   SELECT TEMP
   GO TOP

   aRet := {}

   cDok := "XXXXXX"
   DO WHILE !Eof()

      cBrFakt := AllTrim( temp->brdok )

      IF cBrFakt == cDok
         SKIP
         LOOP
      ENDIF

      SELECT kalk_doks
      SET ORDER TO TAG "V_BRF"
      GO TOP
      SEEK cBrFakt

      IF Found()
         AAdd( aRet, { cBrFakt, kalk_doks->idfirma + "-" + kalk_doks->idvd + "-" + AllTrim( kalk_doks->brdok ) } )
      ENDIF

      SELECT TEMP
      SKIP

      cDok := cBrFakt
   ENDDO

   RETURN aRet


// ---------------------------------------------------------------
// kopira podatke iz pomocne tabele u tabelu KALK->PRIPT
// ---------------------------------------------------------------
STATIC FUNCTION TTbl2Kalk()

   LOCAL cBrojKalk
   LOCAL cTipDok
   LOCAL cIdKonto
   LOCAL cIdKonto2

   o_kalk_pripr()
   // o_kalk()
   // o_kalk_doks()
// o_roba()

   SELECT TEMP
   SET ORDER TO TAG "1"
   GO TOP

   nRbr := 0
   nUvecaj := 1


   cFakt := AllTrim( temp->brdok ) // osnovni podaci ove kalkulacije
   cTDok := GetKTipDok( AllTrim( temp->idtipdok ) )


   cBrojKalk :=  kalk_get_next_broj_v5( self_organizacija_id(), cTDok, NIL )

   DO WHILE !Eof()

      cTmpArt := AllTrim( temp->idroba )
      select_o_roba( cTmpArt )

      // dodaj zapis u kalk_pripr
      SELECT kalk_pripr
      APPEND BLANK

      REPLACE idfirma WITH self_organizacija_id()
      REPLACE rbr WITH Str( ++nRbr, 3 )

      // uzmi pravilan tip dokumenta za kalk
      REPLACE idvd WITH cTDok

      REPLACE brdok WITH cBrojKalk
      REPLACE datdok WITH temp->datdok
      REPLACE idpartner WITH __partn
      REPLACE idtarifa WITH ROBA->idtarifa
      REPLACE brfaktp WITH cFakt
      REPLACE datfaktp WITH temp->datdok

      // konta:
      // =====================
      // zaduzuje
      REPLACE idkonto WITH __mkonto
      REPLACE mkonto WITH __mkonto
      REPLACE mu_i WITH "1"

      // razduzuje
      REPLACE idkonto2 WITH ""

      REPLACE kolicina WITH temp->kolicina
      REPLACE idroba WITH roba->id

      // posto je cijena u eur-u konvertuj u KM
      // prema tekucem kursu

      nCijena := Round( temp->cijena, 5 )

      REPLACE fcj WITH nCijena
      REPLACE nc WITH nCijena
      REPLACE vpc WITH roba->vpc
      REPLACE rabatv WITH temp->rabatp

      // troskovi
      REPLACE tprevoz WITH "R"
      REPLACE tbanktr WITH "R"
      REPLACE tspedtr WITH "R"
      REPLACE tcardaz WITH "R"
      REPLACE tzavtr WITH "R"
      IF nRbr == 1
         REPLACE prevoz WITH temp->trosk1
         REPLACE banktr WITH temp->trosk2
         REPLACE spedtr WITH temp->trosk3
         REPLACE cardaz WITH temp->trosk4
         REPLACE zavtr WITH temp->trosk5
      ENDIF

      SELECT TEMP
      SKIP
   ENDDO

   RETURN 1


STATIC FUNCTION kalk_import_csv_obradi_dokument( lAsPokreni, lStampaj )

   LOCAL lTrosk := .F.

   // 1. pokreni asistenta
   // 2. azuriraj kalk
   // 3. azuriraj FIN

   // PRIVATE lKalkAsistentUToku := .F.

   IF lAsPokreni == nil
      lAsPokreni := .T.
   ENDIF

   IF lStampaj == nil
      lStampaj := .T.
   ENDIF

   IF lAsPokreni
      kalk_pripr_obrada_stavki_sa_asistentom()
      IF __trosk == .T.
         o_kalk_edit()
         kalk_raspored_troskova( .T. ) // fSilent = .t.
      ENDIF
   ELSE
      o_kalk_edit()
   ENDIF

   IF lStampaj
      kalk_stampa_dokumenta_priprema( .T. )
   ENDIF

   kalk_azuriranje_dokumenta_auto_bez_stampe() // azuriraj kalk

   o_kalk_edit()

   RETURN .T.


FUNCTION fajl_get_broj_linija( cImeF )

   LOCAL nOfset := 0
   LOCAL nSlobMem := 0
   LOCAL cPom := ""
   LOCAL nVrati := 0

   IF FileStr( cImeF, 2, VelFajla( cImeF ) - 2 ) != NRED_DOS
      nVrati := 1
   ENDIF
   DO WHILE Len( cPom ) >= nSlobMem
      nSlobMem := Memory( 1 ) * 1024 - 100
      cPom := FileStr( cImeF, nSlobMem, nOfset )
      nOfset = nOfset + nSlobMem - 1
      nVrati = nVrati + NumAt( NRED_DOS, cPom )
   ENDDO

   RETURN nVrati


FUNCTION VelFajla( cImeF, cAttr )

   LOCAL aPom := Directory( cImeF, cAttr )

   RETURN IF ( !Empty( aPom ), aPom[ 1, 2 ], 0 )
