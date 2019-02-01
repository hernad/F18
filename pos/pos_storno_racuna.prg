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

MEMVAR gIdPos

FUNCTION pos_vrati_broj_racuna_iz_fiskalnog( cFiskalniBroj, cBrojRacuna, dDatumRacuna )

   LOCAL cQuery, _qry_ret, oTable
   LOCAL nI, oRow
   LOCAL cIdPos := gIdPos
   LOCAL aPosStavke
   LOCAL _rn_broj := ""
   LOCAL lOk := .F.

   cQuery := " SELECT pd.datum, pd.brdok, pd.fisc_rn, " + ;
      " SUM( pp.kolicina * pp.cijena ) as iznos, " + ;
      " SUM( pp.kolicina * pp.ncijena ) as popust " + ;
      " FROM " + f18_sql_schema( "pos_pos" ) + " pp " + ;
      " LEFT JOIN " + f18_sql_schema( "pos_doks" ) + " pd " + ;
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

      lOk := .T.

   ELSE

      IF oTable:LastRec() == 0
         RETURN lOk
      ENDIF

      lOk := .T.
      oRow := oTable:GetRow()
      cBrojRacuna := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
      dDatumRacuna := oRow:FieldGet( oRow:FieldPos( "datum" ) )

   ENDIF

   RETURN lOk




STATIC FUNCTION izaberi_racun_iz_liste( arr, cBrojRacuna, dDatumRacuna )

   LOCAL nRet := 0
   LOCAL nI, _n
   LOCAL cTmp
   LOCAL nIzbor := 1
   LOCAL aOpc := {}
   LOCAL aOpcExe := {}
   LOCAL _m_x := box_x_koord()
   LOCAL _m_y := box_y_koord()

   FOR nI := 1 TO Len( arr )

      cTmp := ""
      cTmp += DToC( arr[ nI, 1 ] )
      cTmp += " cBrRacuna: "
      cTmp += PadR( PadL( AllTrim( gIdPos ), 2 ) + "-" + AllTrim( arr[ nI, 2 ]  ), 10 )
      cTmp += PadL( AllTrim( Str( arr[ nI, 4 ] - arr[ nI, 5 ], 12, 2 ) ), 10 )
      AAdd( aOpc, cTmp )
      AAdd( aOpcExe, {|| "" } )

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      nIzbor := meni_0( "choice", aOpc, nIzbor, .F. )
      IF nIzbor == 0
         EXIT
      ELSE
         cBrojRacuna := arr[ nIzbor, 2 ]
         dDatumRacuna := arr[ nIzbor, 1 ]
         nIzbor := 0
      ENDIF
   ENDDO

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN nRet



STATIC FUNCTION pos_fix_broj_racuna( cBrRacuna )

   LOCAL _a_rn := {}

   IF !Empty( cBrRacuna ) .AND. ( "-" $ cBrRacuna )
      _a_rn := TokToNiz( cBrRacuna, "-" )
      IF !Empty( _a_rn[ 2 ] )
         cBrRacuna := PadR( AllTrim( _a_rn[ 2 ] ), FIELD_LEN_POS_BRDOK )
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


FUNCTION pos_storno_rn( lSilent, cBrDokStornirati, dSt_date, cSt_fisc )

   LOCAL nTArea := Select()
   LOCAL hRec
   LOCAL GetList := {}

   LOCAL _datum := danasnji_datum()
   LOCAL cDanasnjiDN := "D"

   // PRIVATE GetList := {}
   PRIVATE aVezani := {}

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF cBrDokStornirati == nil
      cBrDokStornirati := Space( FIELD_LEN_POS_BRDOK )
   ENDIF

   IF dSt_date == nil
      dSt_date := Date()
   ENDIF

   IF cSt_fisc == nil
      cSt_fisc := Space( 10 )
   ENDIF


   Box(, 4, 55 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Račun je današnji (D/N) ?" GET cDanasnjiDN VALID cDanasnjiDN $ "DN" PICT "@!"
   READ

   IF cDanasnjiDN == "N"
      _datum := NIL
   ENDIF

   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "stornirati pos račun broj:" GET cBrDokStornirati VALID {|| pos_lista_racuna( @_datum, @cBrDokStornirati, .T. ), pos_fix_broj_racuna( @cBrDokStornirati ), dSt_date := _datum,  .T. }
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "od datuma:" GET dSt_date
   READ

   cBrDokStornirati := PadL( AllTrim( cBrDokStornirati ), FIELD_LEN_POS_BRDOK )
   IF Empty( cSt_fisc )
      seek_pos_doks( gIdPos, "42", dSt_date, cBrDokStornirati )
      cSt_fisc := PadR( AllTrim( Str( pos_doks->fisc_rn ) ), 10 )
   ENDIF

   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "broj fiskalnog isječka:" GET cSt_fisc
   READ

   BoxC()

   IF LastKey() == K_ESC
      SELECT ( nTArea )
      RETURN .F.
   ENDIF

   IF Empty( cBrDokStornirati )
      SELECT ( nTArea )
      RETURN .F.
   ENDIF

   SELECT ( nTArea )

   napravi_u_pripremi_storno_dokument( dSt_date, cBrDokStornirati, cSt_fisc )
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
      hRec[ "datum" ] := danasnji_datum()
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
