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

/* Kurs(dDat,cValIz,cValU)
 *   param: dDat - datum na koji se trazi omjer
 *   param: cValIz - valuta iz koje se vrsi preracun iznosa
 *   param: cValU  - valuta u koju se preracunava iznos valute cValIz
 *   param: cValIz i cValU se mogu zadati kao sifre valuta ili kao tipovi
 *   param: Npr. tip "P" oznacava pomocnu, a tip "D" domacu valutu
 *   param: Ako nisu zadani, uzima se da je cValIz="P", a cValU="D"
 *   param: Ako je zadano samo neko cValIz<>"P", cValU ce biti "P"
 *
 *  return f-ja vraca protuvrijednost jedinice valute cValIz u valuti cValU
 */
FUNCTION Kurs( datum, val_iz, val_u )

   LOCAL oDataSet, cQuery, _tmp_1, _tmp_2, oRow

   _tmp_1 := 1
   _tmp_2 := 1

   IF val_iz == NIL
      val_iz := "P"
   ENDIF

   IF val_u == NIL
      IF val_iz == "P"
         val_u := "D"
      ELSE
         val_u := "P"
      ENDIF
   ENDIF

   IF ( val_iz == "P" .OR. val_iz == "D" )
      _where := " tip = " + sql_quote( val_iz )
   ELSE
      _where := " id = " + sql_quote( val_iz )
   ENDIF

   IF !Empty( datum )
      _where += " AND ( " + _sql_date_parse( "datum", NIL, datum ) + ") "
   ENDIF

   cQuery := "SELECT * FROM " + f18_sql_schema("valute")
   cQuery += " WHERE " + _where
   cQuery += " ORDER BY id, datum"

   oDataSet := run_sql_query( cQuery )
   oDataSet:GoTo( 1 )
   oRow := oDataSet:GetRow( 1 )

   IF oDataSet:LastRec() == 0
      Msg( "Nepostojeća valuta iz koje se pretvara iznos:## '" + val_iz + "' !" )
      _tmp_1 := 1
   ELSEIF !Empty( datum ) .AND. ( DToS( datum ) < DToS( oRow:FieldGet( oRow:FieldPos( "datum" ) ) ) )
      Msg( "Nepostojeći kurs valute iz koje se pretvara iznos:## '" + val_iz + "'. Provjeriti datum !" )
      _tmp_1 := 1
   ELSE
      _id := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "id" ) ) )
      DO WHILE !oDataSet:Eof() .AND. _id == hb_UTF8ToStr( oDataSet:FieldGet( oDataSet:FieldPos( "id" ) ) )
         oRow := oDataSet:GetRow()
         _tmp_1 := oRow:FieldGet( oRow:FieldPos( "kurs1" ) )
         IF !Empty( datum ) .AND. ( DToS( datum ) >= DToS( oRow:FieldGet( oRow:FieldPos( "datum" ) ) ) )
            oDataSet:Skip()
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF

   // valuta u
   IF ( val_u == "P" .OR. val_u == "D" )
      _where := " tip = " + sql_quote( val_u )
   ELSE
      _where := " id = " + sql_quote( val_u )
   ENDIF

   IF !Empty( datum )
      _where += " AND ( " + _sql_date_parse( "datum", NIL, datum ) + ") "
   ENDIF

   cQuery := "SELECT * FROM " + f18_sql_schema( "valute" )
   cQuery += " WHERE " + _where
   cQuery += " ORDER BY id, datum"

   oDataSet := run_sql_query( cQuery )
   oDataSet:GoTo( 1 )
   oRow := oDataSet:GetRow( 1 )

   IF oDataSet:LastRec() == 0
      Msg( "Nepostojeća valuta u koju se pretvara iznos:## '" + val_u + "' !" )
      _tmp_1 := 1
      _tmp_2 := 1
   ELSEIF !Empty( datum ) .AND. ( DToS( datum ) < DToS( oRow:FieldGet( oRow:FieldPos( "datum" ) ) ) )
      Msg( "Nepostojeći kurs valute u koju se pretvara iznos:## '" + val_u + "'. Provjeriti datum !" )
      _tmp_1 := 1
      _tmp_2 := 1
   ELSE
      _id := hb_UTF8ToStr( oRow:FieldGet( oRow:FieldPos( "id" ) ) )
      DO WHILE !oDataSet:Eof() .AND. _id == hb_UTF8ToStr( oDataSet:FieldGet( oDataSet:FieldPos( "id" ) ) )
         oRow := oDataSet:GetRow()
         _tmp_2 := oRow:FieldGet( oRow:FieldPos( "kurs1" ) )
         IF !Empty( datum ) .AND. ( DToS( datum ) >= DToS( oRow:FieldGet( oRow:FieldPos( "datum" ) ) ) )
            oDataSet:Skip()
         ELSE
            EXIT
         ENDIF
      ENDDO
   ENDIF

   RETURN ( _tmp_2 / _tmp_1 )




FUNCTION valuta_domaca_skraceni_naziv()

   LOCAL cRet := sql_get_field_za_uslov( F18_PSQL_SCHEMA + ".valute", "naz2", { { "tip", "D" } } )

   IF ValType( cRet ) == "C"
     cRet := hb_UTF8ToStr( cRet )
   ELSE
     cRet := "???"
   ENDIF

   RETURN cRet



FUNCTION ValPomocna()

   LOCAL _ret
   _ret := hb_UTF8ToStr( sql_get_field_za_uslov( F18_PSQL_SCHEMA + ".valute", "naz2", { { "tip", "P" } } ) )

   RETURN _ret



FUNCTION P_Valute( cId, dx, dy )

   LOCAL i, lRet
   PRIVATE ImeKol
   PRIVATE Kol

   ImeKol := {}
   Kol := {}

   PushWA()

   o_valute()
   AAdd( ImeKol,   { "ID ",    {|| id }, "id"        } )
   AAdd( ImeKol,   { "Naziv",  {|| naz }, "naz"       } )
   AAdd( ImeKol,   { ToStrU( "Skrać." ), {|| naz2 }, "naz2"      } )
   AAdd( ImeKol,   { "Datum",  {|| datum }, "datum"     } )
   AAdd( ImeKol,   { "Kurs",   {|| kurs1 }, "kurs1", NIL, NIL, NIL, "9999.99999999"   } )
   AAdd( ImeKol,   { "Tip(D/P/O)", {|| tip }, "tip", ;
      {|| .T. }, ;
      {|| wtip $ "DPO" } } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( Kol, i )
   NEXT

   lRet := p_sifra( F_VALUTE, 2, 10, 77, "Valute", @cid, dx, dy )

   PopWa( F_VALUTE )

   RETURN lRet




FUNCTION ValSekund()

   IF gBaznaV == "D"
      RETURN ValPomocna()
   ELSE
      RETURN valuta_domaca_skraceni_naziv()
   ENDIF



FUNCTION OmjerVal( ckU, ckIz, dD )

   LOCAL nU := 0
   LOCAL nIz := 0
   LOCAL nArr := Select()

   SELECT ( F_VALUTE )
   IF !Used()
      o_valute()
   ENDIF

   PRIVATE cFiltV := "( naz2==" + dbf_quote( PadR( ckU, 4 ) ) + " .or. naz2==" + dbf_quote( PadR( ckIz, 4 ) ) + " ) .and. DTOS(datum)<=" + dbf_quote( DToS( dD ) )
   SET FILTER TO &cFiltV
   SET ORDER TO TAG "ID2"
   GO TOP
   DO WHILE !Eof()
      IF naz2 == PadR( ckU, 4 )
         nU  := IF( kurslis == "1", kurs1, IF( kurslis == "2", kurs2, kurs3 ) )
      ELSEIF naz2 == PadR( ckIz, 4 )
         nIz := IF( kurslis == "1", kurs1, IF( kurslis == "2", kurs2, kurs3 ) )
      ENDIF
      SKIP 1
   ENDDO
   SET FILTER TO

   SELECT ( nArr )
   IF nIz == 0
      MsgBeep( "Greska! Za valutu " + ckIz + " na dan " + DToC( dD ) + " nemoguce utvrditi kurs!" )
   ENDIF
   IF nU == 0
      MsgBeep( "Greska! Za valutu " + ckU + " na dan " + DToC( dD ) + " nemoguce utvrditi kurs!" )
   ENDIF

   RETURN IF( nIz == 0 .OR. nU == 0, 0, ( nU / nIz ) )




FUNCTION ImaUSifVal( cKratica )

   LOCAL lIma := .F., nArr := Select()

   SELECT ( F_VALUTE )
   IF !Used()
      o_valute()
   ENDIF
   GO TOP
   DO WHILE !Eof()
      IF naz2 == PadR( cKratica, 4 )
         lIma := .T.
         EXIT
      ENDIF
      SKIP 1
   ENDDO
   SELECT ( nArr )

   RETURN lIma




// -------------------------------------
// pretvori u baznu valutu
// -------------------------------------
FUNCTION UBaznuValutu( dDatdok )

   LOCAL  cIz

   IF gBaznaV == "P"
      cIz := "D"
   ELSE
      cIz := "P"
   ENDIF

   RETURN Kurs( dDatdok, cIz, gBaznaV )




FUNCTION ValBazna()

   IF gBaznaV == "P"
      RETURN ValPomocna()
   ELSE
      RETURN valuta_domaca_skraceni_naziv()
   ENDIF


/*
    OmjerVal(v1,v2)
    Omjer valuta
    v1  - valuta 1
    v2  - valuta 2
 */

FUNCTION OmjerVal2( v1, v2 )

   LOCAL nArr := Select(), n1 := 1, n2 := 1, lv1 := .F., lv2 := .F.

   SELECT VALUTE
   SET ORDER TO TAG "ID2"
   GO BOTTOM
   DO WHILE !Bof() .AND. ( !lv1 .OR. !lv2 )
      IF !lv1 .AND. naz2 == v1; n1 := kurs1; lv1 := .T. ; ENDIF
      IF !lv2 .AND. naz2 == v2; n2 := kurs1; lv2 := .T. ; ENDIF
      SKIP -1
   ENDDO
   SELECT ( nArr )

   RETURN ( n1 / n2 )
