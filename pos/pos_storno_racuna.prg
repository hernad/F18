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

MEMVAR gPosProdajnoMjesto, Ch

/*
FUNCTION pos_vrati_broj_racuna_iz_fiskalnog( cFiskalniBroj, cBrDok, dDatumRacuna )

   LOCAL cQuery, oTable
   LOCAL nI, oRow
   LOCAL cIdPos := gPosProdajnoMjesto
   LOCAL aPosStavke
   LOCAL _rn_broj := ""
   LOCAL lOk := .F.

   ALERT( "todo pos_storno")
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
      izaberi_racun_iz_liste( aPosStavke, @cBrDok, @dDatumRacuna )
      lOk := .T.

   ELSE

      IF oTable:LastRec() == 0
         RETURN lOk
      ENDIF
      lOk := .T.
      oRow := oTable:GetRow()
      cBrDok := oRow:FieldGet( oRow:FieldPos( "brdok" ) )
      dDatumRacuna := oRow:FieldGet( oRow:FieldPos( "datum" ) )

   ENDIF

   RETURN lOk
*/



STATIC FUNCTION izaberi_racun_iz_liste( arr, cBrDok, dDatumRacuna )

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
      cTmp += PadR( PadL( AllTrim( gPosProdajnoMjesto ), 2 ) + "-" + AllTrim( arr[ nI, 2 ]  ), 10 )
      cTmp += PadL( AllTrim( Str( arr[ nI, 4 ] - arr[ nI, 5 ], 12, 2 ) ), 10 )
      AAdd( aOpc, cTmp )
      AAdd( aOpcExe, {|| "" } )

   NEXT

   DO WHILE .T. .AND. LastKey() != K_ESC
      nIzbor := meni_0( "choice", aOpc, nIzbor, .F. )
      IF nIzbor == 0
         EXIT
      ELSE
         cBrDok := arr[ nIzbor, 2 ]
         dDatumRacuna := arr[ nIzbor, 1 ]
         nIzbor := 0
      ENDIF
   ENDDO

   box_x_koord( _m_x )
   box_y_koord( _m_y )

   RETURN nRet




FUNCTION pos_storno_racuna( hParams )

   LOCAL GetList := {}
   LOCAL nOldFiskRn, cMsg

   IF !hb_HHasKey( hParams, "datum" )
      hParams[ "datum" ] := NIL
   ENDIF

   IF !hb_HHasKey( hParams, "brdok" )
      hParams[ "brdok" ] := NIL
   ENDIF

   IF !hb_HHasKey( hParams, "idpos" )
      hParams[ "idpos" ] := pos_pm()
   ENDIF

   IF hParams[ "datum" ] == nil
      hParams[ "datum" ] := danasnji_datum()
   ENDIF
   IF hParams[ "brdok" ] == nil
      hParams[ "brdok" ] := Space( FIELD_LEN_POS_BRDOK )
   ENDIF
   hParams[ "browse" ] := .F.

   PushWA()
   Box(, 5, 55 )
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum:" GET hParams[ "datum" ]
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Stornirati POS račun broj:" GET hParams[ "brdok" ] VALID {|| pos_lista_racuna( @hParams ), .T. }

   READ
   BoxC()

   hParams[ "idvd" ] := "42"
   hParams[ "fisk_rn" ] := pos_get_broj_fiskalnog_racuna( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ] )
   hParams[ "fisk_id" ] := pos_get_fiskalni_dok_id( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ] )

   IF ( nOldFiskRn := pos_fisk_broj_rn_by_storno_ref( hParams[ "fisk_id" ] ) ) <> 0
      cMsg := "Već postoji storno istog RN, broj FISK: " + AllTrim( Str( nOldFiskRn ) )
      MsgBeep( cMsg )
      error_bar( "fisk", cMsg )
      PopWa()
      RETURN .F.
   ENDIF

   info_bar( "fisk", "Broj fiskalnog računa: " +  AllTrim( Str( hParams[ "fisk_rn" ] ) ) )
   IF LastKey() == K_ESC .OR. hParams[ "fisk_rn" ] == 0
      MsgBeep( "Broj fiskalnog računa 0?! Ne može storno!" )
      PopWa()
      RETURN .F.
   ENDIF

   IF Pitanje(, "Stornirati POS " + pos_dokument( hParams ) + " broj fiskalng računa [" + AllTrim( Str( hParams[ "fisk_rn" ] ) ) + "] ?", "D" ) == "D"
      pos_napravi_u_pripremi_storno_dokument( hParams )
   ENDIF

   PopWa()

   RETURN .T.


//STATIC FUNCTION pos_pripr_set_fisk_rn( hParams )
//
//   SELECT _POS_PRIPR
//   PushWa()
//
//   SET ORDER TO
//   GO TOP
//   DO WHILE !Eof()
//      RREPLACE fisk_rn WITH hParams[ "fisk_rn" ]
//      SKIP
//   ENDDO
//   PopWa()
//
//   RETURN .T.

STATIC FUNCTION pos_napravi_u_pripremi_storno_dokument( hParams )

   LOCAL cIdRoba, hRec

   SELECT _POS_PRIPR
   my_dbf_zap()

   seek_pos_pos( hParams[ "idpos" ], hParams[ "idvd" ], hParams[ "datum" ], hParams[ "brdok" ] )
   DO WHILE !Eof() .AND. field->idpos == hParams[ "idpos" ] .AND. field->brdok == hParams[ "brdok" ]  .AND. field->idvd == hParams[ "idvd" ]  .AND. field->datum == hParams[ "datum" ]

      cIdRoba := field->idroba
      select_o_roba( cIdRoba )
      SELECT pos

      hRec := dbf_get_rec()
      hb_HDel( hRec, "rbr" )

      SELECT _pos_pripr
      APPEND BLANK

      hRec[ "brdok" ] :=  POS_BRDOK_PRIPREMA
      hRec[ "kolicina" ] := hRec[ "kolicina" ] * -1
      hRec[ "robanaz" ] := roba->naz
      hRec[ "datum" ] := danasnji_datum()
      hRec[ "idvrstep" ] := "01"
      hRec[ "idradnik" ] := hParams[ "idradnik" ]
      hRec[ "fisk_rn" ] := hParams[ "fisk_rn" ]
      hRec[ "fisk_id" ] := hParams[ "fisk_id" ]

      dbf_update_rec( hRec )
      SELECT pos
      SKIP

   ENDDO

   SELECT pos
   USE

   RETURN .T.
