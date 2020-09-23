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

/*
   kopiranje vrijednosti nekog polja u neko SIFK polje
*/

FUNCTION copy_to_sifk()

   LOCAL cTable := Alias()
   LOCAL cFldFrom := Space( 8 )
   LOCAL cFldTo := Space( 4 )
   LOCAL cEraseFld := "D"
   LOCAL cRepl := "D"
   LOCAL nTekX
   LOCAL nTekY
   LOCAL nRec
   LOCAL GetList := {}

   // LOCAL lSql
   LOCAL nTRec

   Box(, 6, 65, .F. )

   set_cursor_on()

   nTekX := box_x_koord()
   nTekY := box_y_koord()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadL( "Polje iz kojeg kopiramo (polje 1)", 40 ) GET cFldFrom VALID !Empty( cFldFrom ) .AND. val_fld( cFldFrom )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY PadL( "SifK polje u koje kopiramo (polje 2)", 40 ) GET cFldTo VALID g_sk_flist( @cFldTo )

   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Brisati vrijednost (polje 1) nakon kopiranja ?" GET cEraseFld VALID cEraseFld $ "DN" PICT "@!"

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "*** izvrsiti zamjenu ?" GET cRepl VALID cRepl $ "DN" PICT "@!"
   READ

   BoxC()

   // lSql := get_a_dbf_rec( Alias() )[ 'sql' ]

   IF cRepl == "N"
      RETURN 0
   ENDIF

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   nTRec := RecNo()
   GO TOP

   DO WHILE !Eof()

      SKIP
      nRec := RecNo()
      SKIP -1

      cCpVal := ( Alias() )->&cFldFrom
      IF !Empty( cCpval )
         // USifK( Alias(), cFldTo,  Unicode():New( ( Alias() )->id, lSql ), cCpVal )
         USifK( Alias(), cFldTo,  ( Alias() )->id, cCpVal )
      ENDIF

      IF cEraseFld == "D"
         REPLACE ( Alias() )->&cFldFrom WITH ""
      ENDIF

      GO ( nRec )
   ENDDO

   GO ( nTRec )

   RETURN 0


// --------------------------------------------------
// zamjena vrijednosti sifk polja
// --------------------------------------------------
FUNCTION repl_sifk_item()

   LOCAL cTable := Alias()
   LOCAL cField := Space( 4 )
   LOCAL cOldVal
   LOCAL cNewVal
   LOCAL cCurrVal
   LOCAL cPtnField
   LOCAL GetList := {}

   // LOCAL lSql := is_sql_table()
   LOCAL nTekX, nTekY, nTRec

   Box(, 3, 60, .F. )
   set_cursor_on()

   nTekX := box_x_koord()
   nTekY := box_y_koord()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY " SifK polje:" GET cField VALID g_sk_flist( @cField )
   READ

   cCurrVal := "wSifk_" + cField
   &cCurrVal := get_sifk_sifv( Alias(), cField )
   cOldVal := &cCurrVal
   cNewVal := Space( Len( cOldVal ) )

   box_x_koord( nTekX )
   box_y_koord( nTekY )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "      Traži:"  GET cOldVal
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Zamijeni sa:" GET cNewVal

   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN 0
   ENDIF

   IF Pitanje( , "Izvršiti zamjenu polja? (D/N)", "D" ) == "N"
      RETURN 0
   ENDIF

   nTRec := RecNo()

   DO WHILE !Eof()
      &cCurrVal := get_sifk_sifv( Alias(), cField )
      IF &cCurrVal == cOldVal
         // USifK( Alias(), cField, Unicode():New( ( Alias() )->id, lSql ), cNewVal )
         USifK( Alias(), cField, ( Alias() )->id, cNewVal )
      ENDIF
      SKIP
   ENDDO

   GO ( nTRec )

   RETURN 0



FUNCTION g_sk_flist( cField )

   LOCAL aFields := {}
   LOCAL cCurrAlias := Alias()
   LOCAL nArr
   LOCAL nField

   nArr := Select()

   SELECT sifk
   SET ORDER TO TAG "ID"
   cCurrAlias := PadR( cCurrAlias, 8 )
   SEEK cCurrAlias

   DO WHILE !Eof() .AND. field->id == cCurrAlias
      AAdd( aFields, { field->oznaka, field->naz } )
      SKIP
   ENDDO

   SELECT ( nArr )

   IF !Empty( cField ) .AND. AScan( aFields, {| xVal | xVal[ 1 ] == cField } ) > 0
      RETURN .T.
   ENDIF

   IF Len( aFields ) > 0
      PRIVATE Izbor := 1
      PRIVATE opc := {}
      PRIVATE opcexe := {}
      PRIVATE GetList := {}

      FOR i := 1 TO Len( aFields )
         AAdd( opc, PadR( aFields[ i, 1 ] + " - " + aFields[ i, 2 ], 40 ) )
         AAdd( opcexe, {|| nField := Izbor, Izbor := 0 } )
      NEXT

      Izbor := 1
      f18_menu_sa_priv_vars_opc_opcexe_izbor( "skf" )
   ENDIF

   cField := aFields[ nField, 1 ]

   RETURN .T.



FUNCTION get_partn_sifk_sifv( cDbfName, cOznaka, cIdSif, return_nil )

   LOCAL xSif

   xSif := cIdSif

   RETURN  get_sifk_sifv( "PARTN", cDbfName, cOznaka, xSif, return_nil )


   
FUNCTION IzSifkKonto( cDbfName, cOznaka, cIdSif, return_nil )

   LOCAL xSif

   xSif := cIdSif

   RETURN  get_sifk_sifv( "KONTO", cDbfName, cOznaka, xSif, return_nil )


FUNCTION IzSifkRoba( cDbfName, cOznaka, cIdSif, return_nil )

   LOCAL xSif


   xSif := cIdSif

   RETURN  get_sifk_sifv( "ROBA", cDbfName, cOznaka, xSif, return_nil )




// -----------------------------------------------------------
// get_karakter_value
// Izvlaci vrijednost iz tabele SIFK
// param cDbfName ime DBF-a
// param oznaka oznaka BARK , GR1 itd
// param cIdSif       sifra u sifrarniku, npr  000000232  ,
// ili "00000232,XXX1233233" pri pretrazivanju

/*
  get_sifk_value( "PARTN", "BANK", "K01", NIL )

  => "0123456789012345,0123456789012349"
  => NIL - ne postoji SIFK PARTN/BANK
  => PADR("", 190) ako postoji SIFV ili je prazan zapis


  - return_nil  = NIL => NIL - NIL za nedefinisanu vrijednost,
                  .T. => ""  - "" za nedefinisanu vrijednost
*/



FUNCTION get_sifk_sifv( cDbfName, cOznaka, cIdSif, return_nil )

   LOCAL nArea := Select()
   LOCAL xRet := ""
   LOCAL cSifkTip, nSifkDuzina, cSifkVeza, cIdSif2

   IF cIdSif == NIL
      cIdSif := ( cDbfName )->ID
   ENDIF

   cDbfName := PadR( cDbfName, FIELD_LEN_SIFK_ID )
   cOznaka := PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA )
   cIdSif2 := PadR( cIdSif, FIELD_LEN_SIFK_IDSIF )

   IF !use_sql_sifk( cDbfName, cOznaka )
      ?E "ERROR 2 GET SIFK ?!", cDbfName, cOznaka
      SELECT ( nArea )
      IF return_nil == NIL
         RETURN NIL
      ELSE
         RETURN ""
      ENDIF

   ENDIF
   xRet := NIL

   GO TOP
   IF Eof()  // uopste ne postoji takva karakteristika
      IF return_nil <> NIL
         xRet := "" // get_sifv_value_by_tip( "X", "" ) ovo ce dati ?NEPTIP?
      ELSE
         xRet := NIL
      ENDIF
      SELECT ( nArea )
      RETURN xRet
   ENDIF

   nSifkDuzina := sifk->duzina
   cSifkTip    := sifk->tip
   cSifkVeza   := sifk->veza

   IF !use_sql_sifv( cDbfName, cOznaka, cIdSif )    //IF Eof() // nema sifv
      xRet := get_sifv_value_by_tip( cSifkTip, nSifkDuzina, "" )
      IF cSifkVeza == "N"
         xRet := PadR( xRet, 190 )
      ENDIF
      SELECT ( nArea )
      RETURN xRet
   ENDIF

   xRet := get_sifv_value_by_tip( cSifkTip, nSifkDuzina, sifv->naz )

   IF cSifkVeza == "N" // n vrijednosti
      xRet := ToStr( xRet )
      SKIP
      DO WHILE !Eof() .AND.  ( ( sifv->id + sifv->oznaka + sifv->idsif ) == ( cDbfName + cOznaka + cIdSif2 ) )
         xRet += "," + ToStr( get_sifv_value_by_tip( cSifkTip, nSifkDuzina, sifv->naz ) )
         SKIP
      ENDDO
      xRet := PadR( xRet, 190 )
   ENDIF

   SELECT ( nArea )

   RETURN xRet



STATIC FUNCTION get_sifv_value_by_tip( cSifkTip, nSifkDuzina, cNazValue )

   LOCAL xRet

   DO CASE
   CASE cSifkTip == "C"
      xRet := PadR( cNazValue, nSifkDuzina )

   CASE cSifkTip == "N"
      xRet := Val( AllTrim( cNazValue ) )

   CASE cSifkTip == "D"
      xRet := SToD( Trim( cNazValue ) )
   OTHERWISE
      xRet := "?NEPTIP?"

   ENDCASE

   RETURN xRet

/*

  get_sifk_naz( "ROBA", "GR1" ) => "Grupa 1  "
  get_sifk_naz( "ROBA", "XYZ" ) => "         "

*/
FUNCTION get_sifk_naz( cDBF, cOznaka )

   LOCAL xRet := ""

   PushWA()

   cDBF := PadR( cDBF, FIELD_LEN_SIFK_ID )
   cOznaka := PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA )

   IF !use_sql_sifk( cDBF, cOznaka )
      PopWa()
      RETURN "?ERR?"
   ENDIF
   xRet := field->NAZ

   PopWA()

   RETURN xRet



FUNCTION IzSifkWV( cDBF, cOznaka, cWhen, cValid )

   PushWA()

   cDBF := PadR( cDBF, FIELD_LEN_SIFK_ID )
   cOznaka := PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA )
   SELECT F_SIFK
   IF !use_sql_sifk( cDBF, cOznaka )
      ?E "ERROR 3 GET SIFK:", cDbf, cOznaka
      PopWA()
      RETURN .F.
   ENDIF
   cWhen  := sifk->KWHEN
   cValid := sifk->KVALID

   PopWa()

   RETURN .T.


// -------------------------------------------------------
// USifk
// Postavlja vrijednost u tabelu SIFK
// cDBF ime DBF-a
// cOznaka oznaka xxxx
// cIdSif  Id u sifrarniku npr. 2MON0001
// xValue  vrijednost (moze biti tipa C,N,D)
//
// veza: 1
// USifK("PARTN", "ROKP", temp->idpartner, temp->rokpl)
// USifK("PARTN", "PORB", temp->idpartner, temp->porbr)

// veza: N
// USifK( "PARTN", "BANK", cPartn, "1400000000001,131111111111112" )
// iz ovoga se vidi da je "," nedozvoljen znak u ID-u
// ------------------------------------------------------------------

FUNCTION USifk( cDbfName, cOznaka, cIdSif, xValue, cTransaction )

   LOCAL nI
   LOCAL ntrec, numtok
   LOCAL _sifk_rec
   LOCAL _tran

   // LOCAL cIdSif

   IF cTransaction == NIL
      cTransaction := "FULL"
   ENDIF

   IF xValue == NIL
      RETURN .F.
   ENDIF

   // cIdSif := ( Unicode():New( cIdSif ) ):getString()
   PushWA()

   cDbfName := PadR( cDbfName, FIELD_LEN_SIFK_ID )
   cOznaka  := PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA )
   cIdSif   := PadR( cIdSif, FIELD_LEN_SIFK_IDSIF )

   SELECT F_SIFK
   IF !use_sql_sifk( cDbfName, cOznaka )
      ?E "ERROR 5 GET SIFK ", cDbfName, cOznaka
      PopWa()
      RETURN .F.
   ENDIF
   GO TOP
   IF Eof() .OR. !( sifk->tip $ "CDN" )
      PopWa()
      RETURN .F.
   ENDIF

   use_sql_sifv( cDbfName, cOznaka, cIdSif )

   SELECT sifk
   _sifk_rec := dbf_get_rec()

   IF cTransaction == "FULL"
      _tran := "BEGIN"
      sql_table_update( NIL, _tran )
   ENDIF

   IF sifk->veza == "N"
      IF !update_sifv_n_relation( _sifk_rec, cIdSif, xValue )
         RETURN .F.
      ENDIF
   ELSE
      IF !update_sifv_1_relation( _sifk_rec, cIdSif, xValue )
         RETURN .F.
      ENDIF
   ENDIF

   IF cTransaction == "FULL"
      _tran := "END"
      sql_table_update( NIL, _tran )
   ENDIF

   PopWa()

   RETURN .T.



STATIC FUNCTION update_sifv_n_relation( hRecSifk, cIdSif, cValues )

   LOCAL nI, nNumTokens, _tmp, _naz, _values
   LOCAL _sifv_rec

   _sifv_rec := hb_Hash()
   _sifv_rec[ "id" ] := hRecSifk[ "id" ]
   _sifv_rec[ "oznaka" ] := hRecSifk[ "oznaka" ]
   _sifv_rec[ "idsif" ] := cIdSif

   // veza 1->N posebno se tretira
   SELECT sifv
   brisi_sifv_item( hRecSifk[ "id" ], hRecSifk[ "oznaka" ], cIdSif )

   IF ! HB_ISCHAR( cValues )
      ?E "update_sifv_n_relation cValues != char"
   ENDIF
   nNumTokens := NumToken( cValues, "," )

   FOR nI := 1 TO nNumTokens

      _tmp := Token( cValues, ",", nI )
      APPEND BLANK

      _sifv_rec[ "naz" ] := PadR( get_sifv_naz( _tmp, hRecSifk ), 50 )

      update_rec_server_and_dbf( "sifv", _sifv_rec, 1, "CONT" )

   NEXT

   RETURN .T.




STATIC FUNCTION update_sifv_1_relation( hRecSifk, cIdSif, cValue )

   LOCAL _sifv_rec

   _sifv_rec := hb_Hash()
   _sifv_rec[ "id" ] := hRecSifk[ "id" ]
   _sifv_rec[ "oznaka" ] := hRecSifk[ "oznaka" ]
   _sifv_rec[ "idsif" ] := cIdSif

   cValue := PadR( cValue, hRecSifk[ "duzina" ] )

   // veza 1-1
   SELECT  SIFV
   brisi_sifv_item( hRecSifk[ "id" ], hRecSifk[ "oznaka" ], cIdSif )

   APPEND BLANK

   _sifv_rec[ "naz" ] := get_sifv_naz( cValue, hRecSifk )
   _sifv_rec[ "naz" ] := PadR( _sifv_rec[ "naz" ], 50 )

   update_rec_server_and_dbf( "sifv", _sifv_rec, 1, "CONT" ) // zakljucavanje se desava u nadfunkciji

   RETURN .T.



FUNCTION brisi_sifv_item( cDbfName, cOznaka, cIdSif, cTran )

   LOCAL _sifv_rec := hb_Hash()

   hb_default( @cTran, "CONT" )
   _sifv_rec[ "id" ]     := cDbfName
   _sifv_rec[ "oznaka" ] := cOznaka
   _sifv_rec[ "idsif" ]  := cIdSif

   RETURN delete_rec_server_and_dbf( "sifv", _sifv_rec, 2, cTran )



STATIC FUNCTION get_sifv_naz( xValue, hRecSifk )

   DO CASE
   CASE hRecSifk[ "tip" ] == "C"
      RETURN PadR( xValue, hRecSifk[ "duzina" ] )
   CASE hRecSifk[ "tip" ] == "N"
      RETURN xValue
   CASE hRecSifk[ "tip" ] == "D"
      RETURN DToS( xValue )
   END CASE



/*
    ImauSifv
    Povjerava ima li u sifv vrijednost ...
    ImaUSifv("ROBA","BARK","BK0002030300303",@cIdSif)

    cDBF ime DBF-a
    cOznaka oznaka BARK , GR1 itd
    cVOznaka oznaka BARK003030301
    cIDSif   ROBA01 - idroba
*/

FUNCTION ImaUSifv( cDBF, cOznaka, cVrijednost, cIdSif )

   LOCAL cJedanod := ""
   LOCAL xRet := ""
   LOCAL nTr1, nTr2, xVal
   LOCAL lRet := .F.
   PRIVATE cPom := ""

   cDBF    := PadR( cDBF, FIELD_LEN_SIFK_ID )
   cOznaka := PadR( cOznaka, FIELD_LEN_SIFK_OZNAKA )

   xVal := NIL

   PushWA()

   SELECT F_SIFV
   use_sql_sifv( cDbf, cOznaka, NIL, cVrijednost )
   GO TOP
   IF !Eof()
      cIdSif := field->IdSif
      lRet := .T.
   ENDIF
   PopWa()

   RETURN lRet


FUNCTION update_sifk_na_osnovu_ime_kol_from_global_var( aImeKolone, cVariablePrefix, lNovi, cTransaction )

   LOCAL nI, cId  // , uId
   LOCAL cAlias
   LOCAL _field_b
   LOCAL _a_dbf_rec

   // LOCAL lSql := is_sql_table( Alias() )
   LOCAL lOk := .T.
   LOCAL lRet := .F.

   cAlias := Alias()

   FOR nI := 1 TO Len( aImeKolone )
      IF Left( aImeKolone[ nI, 3 ], 6 ) == "SIFK->"
         _field_b :=  MemVarBlock( cVariablePrefix + "SIFK_" + SubStr( aImeKolone[ nI, 3 ], 7 ) )
         // uId := Unicode():New( ( cAlias )->id,  lSql )
         cId := ( cAlias )->id
         IF get_sifk_sifv( cAlias, SubStr( aImeKolone[ nI, 3 ], 7 ), cId ) <> NIL
            lOk := USifk( cAlias, SubStr( aImeKolone[ nI, 3 ], 7 ), cId, Eval( _field_b ), cTransaction )
         ENDIF
         IF !lOk
            EXIT
         ENDIF
      ENDIF
   NEXT

   lRet := lOk

   RETURN lRet


// --------------------------------------------
// validacija da li polje postoji
// --------------------------------------------
STATIC FUNCTION val_fld( cField )

   LOCAL lRet := .T.

   IF ( Alias() )->( FieldPos( cField ) ) == 0
      lRet := .F.
   ENDIF

   IF lRet == .F.
      MsgBeep( "Polje ne postoji !!!" )
   ENDIF

   RETURN lRet


// ------------------------------------------------------------------
// formiranje matrice na osnovu podataka iz tabele sifv
// ------------------------------------------------------------------
FUNCTION array_from_sifv( dbf, oznaka, cIdSif )

   LOCAL _arr := {}
   LOCAL nDbfArea := Select()

   dbf := PadR( dbf, 8 )
   oznaka := PadR( oznaka, 4 )

   SELECT F_SIFV
   use_sql_sifv( dbf, oznaka, cIdSif )
   SET ORDER TO TAG "ID"
   GO TOP

   DO WHILE !Eof() .AND. field->id + field->oznaka + field->idsif = dbf + oznaka + cIdSif
      IF !Empty( naz )
         AAdd( _arr, AllTrim( field->naz ) )
      ENDIF
      SKIP
   ENDDO

   SELECT ( nDbfArea )

   RETURN _arr
