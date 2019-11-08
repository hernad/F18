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

FUNCTION pos_vrati_broj_racuna_iz_fiskalnog( cFiskalniBroj, cBrojRacuna, dDatumRacuna )

   LOCAL cQuery, _qry_ret, oTable
   LOCAL nI, oRow
   LOCAL cIdPos := gIdPos
   LOCAL aPosStavke
   LOCAL _rn_broj := ""
   LOCAL _ok := .F.

   cQuery := " SELECT pd.datum, pd.brdok, pd.fisc_rn, " + ;
      " SUM( pp.kolicina * pp.cijena ) as iznos, " + ;
      " SUM( pp.kolicina * pp.ncijena ) as popust " + ;
      " FROM " + F18_PSQL_SCHEMA_DOT + "pos_pos pp " + ;
      " LEFT JOIN " + F18_PSQL_SCHEMA_DOT + " pos_doks pd " + ;
      " ON pd.idpos = pp.idpos AND pd.idvd = pp.idvd AND pd.brdok = pp.brdok AND pd.datum = pp.datum " + ;
      " WHERE pd.idpos = " + sql_quote( cIdPos ) + ;
      " AND pd.idvd = '42' AND pd.fisc_rn = " + AllTrim( Str( cFiskalniBroj ) ) + ;
      " GROUP BY pd.datum, pd.brdok, pd.fisc_rn " + ;
      " ORDER BY pd.datum, pd.brdok, pd.fisc_rn "

   oTable := run_sql_query( cQuery )
   oTable:GoTo( 1 )

   IF oTable:LastRec() > 1

      aPosStavke := {}

      DO WHILE !oTable:Eof()
         oRow := oTable:GetRow()
         AAdd( aPosStavke, { oRow:FieldGet( 1 ), oRow:FieldGet( 2 ), oRow:FieldGet( 3 ), oRow:FieldGet( 4 ), oRow:FieldGet( 5 ) } )
         oTable:Skip()
      ENDDO

      izaberi_racun_iz_liste( aPosStavke, @cBrojRacuna, @dDatumRacuna )

      _ok := .T.

   ELSE

      IF oTable:LastRec() == 0
         RETURN _ok
      ENDIF

      _ok := .T.
      oRow := oTable:GetRow()
      cBrojRacuna := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
      dDatumRacuna := oRow:FieldGet( oRow:FieldPos( "datum" ) )

   ENDIF

   RETURN _ok




STATIC FUNCTION izaberi_racun_iz_liste( arr, cBrojRacuna, dDatumRacuna )

   LOCAL _ret := 0
   LOCAL nI, _n
   LOCAL _tmp
   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _m_x := box_x_koord()
   LOCAL _m_y := box_y_koord()

   FOR nI := 1 TO Len( arr )

      _tmp := ""
      _tmp += DToC( arr[ nI, 1 ] )
      _tmp += " cBrRacuna: "
      _tmp += PadR( PadL( AllTrim( gIdPos ), 2 ) + "-" + AllTrim( arr[ nI, 2 ]  ), 10 )
      _tmp += PadL( AllTrim( Str( arr[ nI, 4 ] - arr[ nI, 5 ], 12, 2 ) ), 10 )

      AAdd( _opc, _tmp )
      AAdd( _opcexe, {|| "" } )

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      _izbor := meni_0( "choice", _opc, _izbor, .F. )
      IF _izbor == 0
         EXIT
      ELSE
         cBrojRacuna := arr[ _izbor, 2 ]
         dDatumRacuna := arr[ _izbor, 1 ]
         _izbor := 0
      ENDIF
   ENDDO

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN _ret



// ---------------------------------------------------------------
// koriguje broj racuna
// ---------------------------------------------------------------
STATIC FUNCTION pos_fix_rn_no( cBrRacuna )

   LOCAL _a_rn := {}

   IF !Empty( cBrRacuna ) .AND. ( "-" $ cBrRacuna )

      _a_rn := TokToNiz( cBrRacuna, "-" )

      IF !Empty( _a_rn[ 2 ] )
         cBrRacuna := PadR( AllTrim( _a_rn[ 2 ] ), 6 )
      ENDIF

   ENDIF

   RETURN .T.



// ---------------------------------------------------------------
// storniranje racuna po fiskalnom isjecku
// ---------------------------------------------------------------
FUNCTION pos_storno_fisc_no()

   LOCAL nTArea := Select()
   LOCAL hRec
   LOCAL _datum, _broj_rn
   LOCAL _fisc_broj := 0
   PRIVATE GetList := {}
   PRIVATE aVezani := {}

   Box(, 1, 55 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "broj fiskalnog isječka:" GET _fisc_broj ;
      VALID pos_vrati_broj_racuna_iz_fiskalnog( _fisc_broj, @_broj_rn, @_datum ) ;
      PICT "9999999999"
   READ
   BoxC()

   IF LastKey() == K_ESC
      SELECT ( nTArea )
      RETURN
   ENDIF

   napravi_u_pripremi_storno_dokument( _datum, _broj_rn, Str( _fisc_broj, 10 ) )

   SELECT ( nTArea )

   oBrowse:goBottom()
   oBrowse:refreshAll()
   oBrowse:dehilite()

   DO WHILE !oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
   ENDDO

   RETURN .T.


FUNCTION pos_storno_rn( lSilent, cSt_rn, dSt_date, cSt_fisc )

   LOCAL nTArea := Select()
   LOCAL hRec
   LOCAL GetList := {}

   LOCAL _datum := gDatum
   LOCAL _danasnji := "D"

   // PRIVATE GetList := {}
   PRIVATE aVezani := {}

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF cSt_rn == nil
      cSt_rn := Space( 6 )
   ENDIF

   IF dSt_date == nil
      dSt_date := Date()
   ENDIF

   IF cSt_fisc == nil
      cSt_fisc := Space( 10 )
   ENDIF

   // SELECT ( F_POS )
   // IF !Used()
   // o_pos_pos()
   // ENDIF

// SELECT ( F_POS_DOKS )
// IF !Used()
   // o_pos_doks()
   // ENDIF

   Box(, 4, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Račun je današnji (D/N) ?" GET _danasnji VALID _danasnji $ "DN" PICT "@!"

   READ

   IF _danasnji == "N"
      _datum := NIL
   ENDIF

   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "stornirati pos račun broj:" GET cSt_rn VALID {|| pos_lista_racuna( @_datum, @cSt_rn, .T. ), pos_fix_rn_no( @cSt_rn ), dSt_date := _datum,  .T. }
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "od datuma:" GET dSt_date

   READ

   cSt_rn := PadL( AllTrim( cSt_rn ), 6 )

   IF Empty( cSt_fisc )
      // SELECT pos_doks
      // SEEK gIdPos + "42" + DToS( dSt_date ) + cSt_rn
      seek_pos_doks( gIdPos, "42", dSt_date, cSt_rn )
      cSt_fisc := PadR( AllTrim( Str( pos_doks->fisc_rn ) ), 10 )
   ENDIF

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "broj fiskalnog isječka:" GET cSt_fisc

   READ

   BoxC()

   IF LastKey() == K_ESC
      SELECT ( nTArea )
      RETURN .F.
   ENDIF

   IF Empty( cSt_rn )
      SELECT ( nTArea )
      RETURN .F.
   ENDIF

   SELECT ( nTArea )

   napravi_u_pripremi_storno_dokument( dSt_date, cSt_rn, cSt_fisc )

   // SELECT ( F_POS )
   // USE
   // SELECT ( F_POS_DOKS )
   // USE

   SELECT ( nTArea )

   IF lSilent == .F.

      oBrowse:goBottom()
      oBrowse:refreshAll()
      oBrowse:dehilite()

      DO WHILE !oBrowse:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

   ENDIF

   RETURN .T.


STATIC FUNCTION napravi_u_pripremi_storno_dokument( dDatDok, cBrDok, cBrojFiskalnogRacuna )

   LOCAL nDbfArea := Select()
   LOCAL _t_roba, hRec

   //SELECT ( F_POS )
   //IF !Used()
    //  o_pos_pos()
   //ENDIF
   //SELECT pos
   //SEEK gIdPos + "42" + DToS( dDatDok ) + cBrDok
   seek_pos_pos( gIdPos, "42", dDatDok, cBrDok )

   DO WHILE !Eof() .AND. field->idpos == gIdPos .AND. field->brdok == cBrDok  .AND. field->idvd == "42"

      _t_roba := field->idroba

      select_o_roba( _t_roba )

      SELECT pos

      hRec := dbf_get_rec()
      hb_HDel( hRec, "rbr" )

      SELECT _pos_pripr
      APPEND BLANK

      hRec[ "brdok" ] :=  "PRIPRE"
      hRec[ "kolicina" ] := ( hRec[ "kolicina" ] * -1 )
      hRec[ "robanaz" ] := roba->naz
      hRec[ "datum" ] := gDatum
      hRec[ "idvrstep" ] := "01"

      IF Empty( cBrojFiskalnogRacuna )
         hRec[ "c_1" ] := AllTrim( cBrDok )
      ELSE
         hRec[ "c_1" ] := AllTrim( cBrojFiskalnogRacuna )
      ENDIF

      dbf_update_rec( hRec )

      SELECT pos
      SKIP

   ENDDO

   SELECT pos
   USE

   SELECT ( nDbfArea )

   RETURN .T.
