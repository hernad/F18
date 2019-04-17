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

STATIC s_cPath, s_cFlinkPath2, s_cName

THREAD STATIC F_POS_RN := "POS_RN" // pos komande


FUNCTION fiskalni_flink_racun( hFiskalniParams, aRacunData, lStorno )

   LOCAL cSeparator := ";"
   LOCAL aFlinkArray := {}
   LOCAL aFlinkStruct := {}
   LOCAL nErr := 0
   LOCAL cFName, cFPath
   LOCAL cDatum, cTime

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   cFName := flink_name( hFiskalniParams[ "out_file" ] )
   cFPath := flink_path( hFiskalniParams[ "out_dir" ] )

altd()

   flink_delete_ulazni_dir()
   flink_error_delete( cFPath, cFName )

// RETURN nErr

// --------------------------------------------------------
// fiskalni racun pos (FLINK)
// cFPath - putanja do fajla
// cFName - naziv fajla
// aData - podaci racuna
// lStorno - da li se stampa storno ili ne (.T. ili .F. )
// --------------------------------------------------------
// FUNCTION fiskalni_flink_racun( cFPath, cFName, aData, lStorno, cError )

// LOCAL cSep := ";"
// LOCAL aPosData := {}
// LOCAL aStruct := {}
// LOCAL nErr := 0
// LOCAL cDatum, cTime
//
// IF lStorno == nil
// lStorno := .F.
// ENDIF
// IF cError == nil
// cError := "N"
// ENDIF

   // pobrisi temp fajlove
   // cFName := flink_filepos( aData[ 1, 1 ] ) // naziv fajla
   // izbrisi fajl greske odmah na pocetku ako postoji
   // uzmi strukturu tabele za pos racun
   // aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   // iscitaj pos matricu


   aFlinkStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN ) // uzmi strukturu tabele za pos racun
   // aFlinkArray := fisk_fprint_get_array( aRacunData, aKupac, lStorno, hFiskalniParams )
   // aPosData := flink_pos_rn_matrica( aData, lStorno )

   aFLinkArray := flink_pos_rn_matrica( aRacunData, lStorno )


   cDatum := DToC( Date() )
   cTime := Time()

   fiskalni_array_to_fajl( cFPath, cFName, aFlinkStruct, aFlinkArray )

   // IF cError == "D"

   // MsgO( "Provjera grešaka ..." )
   // Sleep( 3 )
   // MsgC()
   // nErr := flink_pos_error( cFPath, cFName, cDatum, cTime ) // provjeri da li je racun odstampan
   // ENDIF

   RETURN nErr


FUNCTION flink_pos_error( cFPath, cFName, cDate, cTime )

   LOCAL nErr := 0
   LOCAL aDir := {}
   LOCAL cTmp
   LOCAL cDatumError
   LOCAL cPatternErrorFajl
   LOCAL cErrorPatternPretraga
   LOCAL cErrorFileName

   // error file time-hour, min, sec.
   LOCAL cErrorHour
   LOCAL cErrorMinute
   LOCAL cErrorSekunde
   // origin file time-hour, min, sec.
   LOCAL cFileTimeHour := SubStr( cTime, 1, 2 )
   LOCAL cFileTimeMin := SubStr( cTime, 4, 2 )
   LOCAL cFileTimeSec := SubStr( cTime, 7, 2 )
   LOCAL i

   IF !Empty( AllTrim( flink_path_errors() ) )
      cTmp := cFPath + AllTrim( flink_path_errors() ) + SLASH + cFName
   ELSE
      cTmp := cFPath + "printe~1" + SLASH + cFName
   ENDIF

   aDir := Directory( cTmp )
   IF Len( aDir ) == 0  // nema fajla
      RETURN nErr
   ENDIF

   // napravi pattern za pretragu unutar matrice
   // <filename> + <date> + <file hour> + <file minute>
   // primjer:
   //
   // 21100000.inp + 10.10.10 + 12 + 15 = "21100000.inp10.10.101215"
   cPatternErrorFajl := AllTrim( Upper( cFName ) ) + cDate + cFileTimeHour + cFileTimeMin

   // ima fajla, provjeri jos samo datum i vrijeme
   FOR i := 1 TO Len( aDir )
      cErrorFileName := Upper( AllTrim( aDir[ i, 1 ] ) )
      // datum fajla
      cDatumError := DToC( aDir[ i, 3 ] )
      // vrijeme fajla
      cErrorHour := SubStr( AllTrim( aDir[ i, 4 ] ), 1, 2 )
      cErrorMinute := SubStr( AllTrim( aDir[ i, 4 ] ), 4, 2 )
      cErrorSekunde := SubStr( AllTrim( aDir[ i, 4 ] ), 7, 2 )
      // patern pretrage
      cErrorPatternPretraga := AllTrim( cErrorFileName ) + cDatumError + cErrorHour + cErrorMinute
      IF cErrorPatternPretraga == cPatternErrorFajl // imamo error fajl !!!
         nErr := 1
         EXIT
      ENDIF
   NEXT

   RETURN nErr


STATIC FUNCTION flink_error_delete( cFPath, cFName )

   LOCAL cTmp := cFPath + "printe~1" + SLASH + cFName

   FErase( cTmp )

   RETURN .T.


STATIC FUNCTION flink_filepos( cBrRn )

   LOCAL cRet := PadL( AllTrim( cBrRn ), 8, "0" ) + ".inp"

   RETURN cRet



// ----------------------------------------------
// brise fajlove iz ulaznog direktorija
// ----------------------------------------------
STATIC FUNCTION flink_delete_ulazni_dir()

   LOCAL cTmp, cFilePath

   MsgO( "brisem tmp fajlove..." )

   cFilePath := AllTrim( flink_path() )
   cTmp := "*.inp"

   AEval( Directory( cFilePath + cTmp ), {| aFile | FErase( cFilePath +  AllTrim( aFile[ 1 ] ) ) } )
   Sleep( 1 )
   MsgC()

   RETURN .T.



/*
// fiskalno upisivanje robe
// cFPath - putanja do fajla
// aData - podaci racuna

FUNCTION fc_pos_art( cFPath, cFName, aData )

   LOCAL cSep := ";"
   LOCAL aPosData := {}
   LOCAL aStruct := {}

   // uzmi strukturu tabele za pos racun
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )

   // iscitaj pos matricu
   aPosData := flink_pos_artikal( aData )

   fiskalni_array_to_fajl( cFPath, cFName, aStruct, aPosData )

   RETURN .T.
*/

// ------------------------------------------------------
// vraca popunjenu matricu za upis artikla u memoriju
// ------------------------------------------------------
STATIC FUNCTION flink_pos_artikal( aData )

   LOCAL aArr := {}
   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL i

   // ocekivana struktura
   // aData = { idroba, nazroba, cijena, kolicina, porstopa, plu }

   // nemam pojma sta ce ovdje biti logic ?
   cLogic := "1"

   FOR i := 1 TO Len( aData )
      cTmp := "U"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      // naziv artikla
      cTmp += AllTrim( aData[ i, 2 ] )
      cTmp += cSep
      // cjena 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 3 ], 12, 2 ) )
      cTmp += cSep
      // kolicina 0-99999.99
      cTmp += AllTrim( Str( aData[ i, 4 ], 12, 2 ) )
      cTmp += cSep
      // stand od 1-9
      cTmp += "1"
      cTmp += cSep
      // grupa artikla 1-99
      cTmp += "1"
      cTmp += cSep
      // poreska grupa artikala 1 - 4
      cTmp += "1"
      cTmp += cSep
      // 0 ???
      cTmp += "0"
      cTmp += cSep
      // kod PLU
      cTmp += AllTrim( aData[ i, 1 ] )
      cTmp += cSep
      AAdd( aArr, { cTmp } )

   NEXT

   RETURN aArr



STATIC FUNCTION flink_pos_rn_matrica( aRacunData, lStorno )

   LOCAL aArr := {}
   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL i
   LOCAL cRek_rn := ""
   LOCAL cRnBroj
   LOCAL nTotal := 0
   LOCAL cPoreznaStopa

   // ocekuje se matrica formata
   // aRacunData { brrn, rbr, idroba, nazroba, cijena, kolicina, porstopa, rek_rn, plu, cVrPlacanja, nTotal }

   // !!! nije broj racuna !!!!
   // prakticno broj racuna
   // cLogic := ALLTRIM( aRacunData[1, 1] )

   AltD()
   // broj racuna
   cRnBroj := AllTrim( aRacunData[ 1, FISK_INDEX_BRDOK ] )

   // logic je uvijek "1"
   cLogic := "1"

   IF lStorno == .T.
      cRek_rn := AllTrim( aRacunData[ 1, FISK_INDEX_FISK_RACUN_STORNIRATI ] )
      cTmp := "K"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += cRek_rn
      AAdd( aArr, { cTmp } )

   ENDIF

   FOR i := 1 TO Len( aRacunData )
      cPoreznaStopa := aRacunData[ i, FISK_INDEX_TARIFA ]
      cTmp := "S"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += AllTrim( aRacunData[ i, FISK_INDEX_ROBANAZIV ] )
      cTmp += cSep
      // cjena 0-99999.99
      cTmp += AllTrim( Str( aRacunData[ i, FISK_INDEX_CIJENA ], 12, 2 ) )
      cTmp += cSep
      // kolicina 0-99999.99
      cTmp += AllTrim( Str( aRacunData[ i, FISK_INDEX_KOLICINA ], 12, 2 ) )
      cTmp += cSep
      // stand od 1-9
      cTmp += PadR( "1", 1 )
      cTmp += cSep
      // grupa artikla 1-99
      cTmp += "1"
      cTmp += cSep
      // poreska grupa artikala 1 - 4
      IF cPoreznaStopa == "E"
         cTmp += "2"
      ELSE
         cTmp += "1"
      ENDIF
      cTmp += cSep
      // -0 ???
      cTmp += "-0"
      cTmp += cSep
      // kod PLU
      cTmp += AllTrim( aRacunData[ i, FISK_INDEX_IDROBA ] )
      cTmp += cSep
      AAdd( aArr, { cTmp } )

   NEXT

   // podnozje
   cTmp := "Q"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += "1"
   cTmp += cSep
   cTmp += "pos rn: " + cRnBroj

   AAdd( aArr, { cTmp } )


   // vrsta placanja
   IF aRacunData[ 1, FISK_INDEX_VRSTA_PLACANJA ] <> "0"
      nTotal := aRacunData[ 1, FISK_INDEX_TOTAL ]
      // zatvaranje racuna
      cTmp := "T"
      cTmp += cLogSep
      cTmp += cLogic
      cTmp += cLogSep
      cTmp += Replicate( "_", 6 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 1 )
      cTmp += cLogSep
      cTmp += Replicate( "_", 2 )
      cTmp += cSep
      cTmp += aRacunData[ 1, FISK_INDEX_VRSTA_PLACANJA ]
      cTmp += cSep
      cTmp += AllTrim( Str( nTotal, 12, 2 ) )
      cTmp += cSep
      AAdd( aArr, { cTmp } )

   ENDIF

   // zatvaranje racuna
   cTmp := "T"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr


FUNCTION flink_polog( cFPath, cFName, nPolog )

   LOCAL cSep := ";"
   LOCAL aPolog := {}
   LOCAL aStruct := {}
   LOCAL GetList := {}

   IF nPolog == nil
      nPolog := 0
   ENDIF

   // ako je polog 0, pozovi formu za unos
   IF nPolog = 0
      Box(, 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Zadužujem kasu za:" GET nPolog PICT "999999.99"
      READ
      BoxC()

      IF nPolog == 0
         MsgBeep( "Polog mora biti <> 0 !" )
         RETURN .F.
      ENDIF
      IF LastKey() == K_ESC
         RETURN .F.
      ENDIF

   ENDIF

   cFName := flink_filepos( "0" )
   flink_delete_ulazni_dir()

   flink_error_delete( cFPath, cFName )
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )

   aPolog := flink_polog_array( nPolog )
   fiskalni_array_to_fajl( cFPath, cFName, aStruct, aPolog )

   RETURN .T.



FUNCTION flink_reset_racuna( cFPath, cFName )

   LOCAL cSep := ";"
   LOCAL aReset := {}
   LOCAL aStruct := {}

   flink_delete_ulazni_dir()
   cFName := flink_filepos( "0" )
   flink_error_delete( cFPath, cFName )
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aReset := flink_reset_array()
   fiskalni_array_to_fajl( cFPath, cFName, aStruct, aReset )

   RETURN .T.




FUNCTION flink_dnevni_izvjestaj( cFPath, cFName )

   LOCAL cSep := ";"
   LOCAL aRpt := {}
   LOCAL aStruct := {}
   LOCAL cRpt := "Z"
   LOCAL GetList := {}

   Box(, 6, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Dnevni izvještaji:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Z - dnevni izvještaj"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "X - presjek stanja"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "         ------------>" GET cRpt VALID cRpt $ "ZX" PICT "@!"

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   flink_delete_ulazni_dir()
   cFName := flink_filepos( "0" )
   flink_error_delete( cFPath, cFName )
   aStruct := fiskalni_get_struct_za_gen_fajlova( F_POS_RN )
   aRpt := flink_dnevni_izvjestaj_array( cRpt )
   fiskalni_array_to_fajl( cFPath, cFName, aStruct, aRpt )

   RETURN .T.




STATIC FUNCTION flink_polog_array( nIznos )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}
   LOCAL cZnak := "0"

   // :tip
   // 0 - uplata
   // 1 - isplata
   IF nIznos < 0
      cZnak := "1"
   ENDIF

   cLogic := "1"
   cTmp := "I"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   cTmp += cZnak
   cTmp += cSep
   cTmp += AllTrim( Str( Abs( nIznos ) ) )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION flink_dnevni_izvjestaj_array( cTip )

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"
   cTmp := cTip
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr



STATIC FUNCTION flink_reset_array()

   LOCAL cTmp := ""
   LOCAL cLogic
   LOCAL cLogSep := ","
   LOCAL cSep := ";"
   LOCAL aArr := {}

   cLogic := "1"
   cTmp := "N"
   cTmp += cLogSep
   cTmp += cLogic
   cTmp += cLogSep
   cTmp += Replicate( "_", 6 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 1 )
   cTmp += cLogSep
   cTmp += Replicate( "_", 2 )
   cTmp += cSep
   AAdd( aArr, { cTmp } )

   RETURN aArr

/*
     _err_level := fakt_to_flink( id_firma, tip_dok, br_dok, _items_data, _partn_data, _storno )
*/

FUNCTION fakt_to_flink( hDeviceParams, cIdFirma, cIdTipDok, cBrDok )

   LOCAL aItems := {}
   LOCAL aTxt := {}
   LOCAL aPla_data := {}
   LOCAL aSem_data := {}
   LOCAL lStorno := .T.
   LOCAL aMemo := {}
   LOCAL nBrDok
   LOCAL nReklRn := 0
   LOCAL cStPatt := "/S"
   LOCAL GetList := {}
   LOCAL nStornoIdentifikator, nTRec
   LOCAL nSifRoba
   LOCAL nTotal

   find_fakt_dokument( cIdFirma, cIdTipDok, cBrDok )
   flink_name( hDeviceParams[ "out_file" ] )
   flink_path( hDeviceParams[ "out_dir" ] )

   IF cStPatt $ AllTrim( field->brdok )  // ako je storno racun
      nReklRn := Val( StrTran( AllTrim( field->brdok ), cStPatt, "" ) )
   ENDIF

   nBrDok := Val( AllTrim( field->brdok ) )
   nTotal := field->iznos
   nReklRn := 0

/*
   IF nReklRn <> 0
      Box( , 1, 60 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Broj rekl.fiskalnog racuna:"  GET nReklRn PICT "99999" VALID ( nReklRn > 0 )
      READ
      BoxC()
   ENDIF
*/

   seek_fakt( cIdFirma, cIdTipDok, cBrDok )
   nTRec := RecNo()

   // da li se radi o storno racunu ?
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      IF field->kolicina > 0
         lStorno := .F.
         EXIT
      ENDIF
      SKIP

   ENDDO

   // nTipRac = 1 - maloprodaja
   // nTipRac = 2 - veleprodaja

   // nSemCmd = semafor komanda
   // 0 - stampa mp racuna
   // 1 - stampa storno mp racuna
   // 20 - stampa vp racuna
   // 21 - stampa storno vp racuna

   nSemCmd := 0
   nPartnId := 0

   IF cIdTipDok $ "10#"

      nTipRac := 2 // veleprodajni racun
      nPartnId := get_sifra_partner( fakt_doks->idpartner ) // daj mi partnera za ovu fakturu
      nSemCmd := 20 // stampa vp racuna

      IF lStorno == .T.
         // stampa storno vp racuna
         nSemCmd := 21
      ENDIF

   ELSEIF cIdTipDok $ "11#"

      // maloprodajni racun
      nTipRac := 1
      // nema parnera
      nPartnId := 0

      // stampa mp racuna
      nSemCmd := 0

      IF lStorno == .T.
         // stampa storno mp racuna
         nSemCmd := 1
      ENDIF

   ENDIF

   GO ( nTRec ) // vrati se opet na pocetak

   // upisi u [items] stavke
   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idtipdok == cIdTipDok .AND. field->brdok == cBrDok

      select_o_roba( fakt->idroba )
      SELECT fakt

      nStornoIdentifikator := 0
      IF ( field->kolicina < 0 ) .AND. lStorno == .F.
         nStornoIdentifikator := 1
      ENDIF

      nSifRoba := flink_get_sifra_dobavljaca( field->idroba )
      // cNazRoba := AllTrim( to_xml_encoding( roba->naz ) )
      cNazRoba := flink_konverzija_znakova( AllTrim( roba->naz ) )
      cBarKod := AllTrim( roba->barkod )
      nGrRoba := 1
      nPorStopa := 1
      nR_cijena := Abs( field->cijena )
      nR_kolicina := Abs( field->kolicina )

      AAdd( aItems, { nBrDok, ;
         nTipRac, ;
         nStornoIdentifikator, ;
         nSifRoba, ;
         cNazRoba, ;
         cBarKod, ;
         nGrRoba, ;
         nPorStopa, ;
         nR_cijena, ;
         nR_kolicina } )

      SKIP
   ENDDO

   // tip placanja
   // --------------------
   // 0 - gotovina
   // 1 - cek
   // 2 - kartica
   // 3 - virman

   nTipPla := 0
   IF lStorno == .F.
      // povrat novca
      nPovrat := 0
      // uplaceno novca
      nUplaceno := nTotal
   ELSE
      // povrat novca
      nPovrat := nTotal
      // uplaceno novca
      nUplaceno := 0
   ENDIF

   // upisi u [pla_data] stavke
   AAdd( aPla_data, { nBrDok,  nTipRac, nTipPla,  Abs( nUplaceno ), Abs( nTotal ),  Abs( nPovrat ) } )
   // RACUN.MEM data
   AAdd( aTxt, { "fakt: " + cIdTipDok + "-" + cBrDok } )

   // reklamirani racun uzmi sa box-a
   // nReklRn := nRekRn
   // print memo od - do
   nPrMemoOd := 1
   nPrMemoDo := 1

   // upisi stavke za [semafor]
   AAdd( aSem_data, { nBrDok, ;
      nSemCmd, ;
      nPrMemoOd, ;
      nPrMemoDo, ;
      nPartnId, ;
      nReklRn } )

   IF nTipRac == 2
      flink_racun_veleprodaja( flink_path(), aItems, aTxt, aPla_data, aSem_data )   // veleprodaja, posalji na fiskalni stampac

   ELSEIF nTipRac == 1
      flink_racun_maloprodaja( flink_path(), aItems, aTxt, aPla_data, aSem_data ) // maloprodaja posalji na fiskalni stampac

   ENDIF

   RETURN 0


FUNCTION flink_path( cSet )

   // RETURN PadR( "c:" + SLASH + "fiscal" + SLASH, 150 )
   IF cSet != NIL
      IF Right( cSet ) != SLASH
         cSet += SLASH
      ENDIF
      s_cPath := cSet
   ENDIF

   RETURN  s_cPath


FUNCTION flink_path_errors( cSet )

   IF cSet != NIL
      IF Right( cSet ) != SLASH
         cSet += SLASH
      ENDIF
      s_cFlinkPath2 := cSet
   ENDIF
   // RETURN PadR( "", 150 )

   RETURN s_cFlinkPath2


FUNCTION flink_name( cSet )

   // RETURN  PadR( "OUT.TXT", 150 )
   IF cSet != NIL
      s_cName := cSet
   ENDIF

   RETURN s_cName


FUNCTION flink_type()

   RETURN "FPRINT"



STATIC FUNCTION flink_get_sifra_dobavljaca( cIdRoba )

   LOCAL nRet := 0

   PushWa()
   IF select_o_roba( cIdRoba )
      nRet := Val( AllTrim( field->sifradob ) )
   ENDIF
   PopWa()

   RETURN nRet


STATIC FUNCTION get_sifra_partner( cIdPartner )

   LOCAL nRet := 0
   LOCAL cTmp

   cTmp := Right( AllTrim( cIdPartner ), 5 )
   nRet := Val( cTmp )

   RETURN nRet


STATIC FUNCTION flink_konverzija_znakova( cIn )

   LOCAL cOut := cIn

   cOut := StrTran( cOut, hb_UTF8ToStr( "š" ), "s" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Š" ), "S" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "ć" ), "c" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Ć" ), "C" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "č" ), "c" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Č" ), "C" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "ž" ), "z" )
   cOut := StrTran( cOut, hb_UTF8ToStr( "Ž" ), "Z" )

   RETURN cOut
