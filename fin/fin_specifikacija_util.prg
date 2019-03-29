/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// ----------------------------------
// puni tabelu za export
// ----------------------------------
FUNCTION fill_ost_tbl( cIntervals, cIdPart, cP_naz, ;
      nTUVal, nTVVal, nTotal, ;
      nUVal1, nUVal2, nUVal3, nUVal4, nUValP, ;
      nVVal1, nVVal2, nVVal3, nVVal4, nVValP )

   LOCAL nArr

   nArr := Select()

   o_r_export()
   APPEND BLANK
   REPLACE field->idpart WITH cIdPart
   REPLACE field->p_naz WITH cP_naz
   REPLACE field->t_vval WITH nTVVal
   REPLACE field->t_uval WITH nTUVal
   REPLACE field->TOTAL WITH nTotal

   IF cIntervals == "D"
      // u valuti
      REPLACE field->uval_1 WITH nUVal1
      REPLACE field->uval_2 WITH nUVal2
      REPLACE field->uval_3 WITH nUVal3
      REPLACE field->uval_4 WITH nUVal4
      REPLACE field->uvalp WITH nUValP
      // van valute
      REPLACE field->vval_1 WITH nVVal1
      REPLACE field->vval_2 WITH nVVal2
      REPLACE field->vval_3 WITH nVVal3
      REPLACE field->vval_4 WITH nVVal4
      REPLACE field->vvalp WITH nVValP
   ENDIF

   SELECT ( nArr )

   RETURN



// ------------------------------------------
// vraca matricu sa ostav poljima
// cIntervals - da li postoje intervali "DN"
//
// ------------------------------------------
FUNCTION get_ost_fields( cIntervals, nPartLen )

   IF cIntervals == nil
      cIntervals := "N"
   ENDIF

   IF nPartLen == nil
      nPartLen := 6
   ENDIF

   aFields := {}

   AAdd( aFields, { "idpart", "C", nPartLen, 0 } )
   AAdd( aFields, { "p_naz", "C", 40, 0 } )

   IF cIntervals == "D"

      AAdd( aFields, { "UVal_1", "N", 15, 2 } )
      AAdd( aFields, { "UVal_2", "N", 15, 2 } )
      AAdd( aFields, { "UVal_3", "N", 15, 2 } )
      AAdd( aFields, { "UVal_4", "N", 15, 2 } )
      AAdd( aFields, { "UValP", "N", 15, 2 } )
   ENDIF

   AAdd( aFields, { "T_UVal", "N", 15, 2 } )

   IF cIntervals == "D"
      AAdd( aFields, { "VVal_1", "N", 15, 2 } )
      AAdd( aFields, { "VVal_2", "N", 15, 2 } )
      AAdd( aFields, { "VVal_3", "N", 15, 2 } )
      AAdd( aFields, { "VVal_4", "N", 15, 2 } )
      AAdd( aFields, { "VValP", "N", 15, 2 } )
   ENDIF

   AAdd( aFields, { "T_VVal", "N", 15, 2 } )
   AAdd( aFields, { "Total", "N", 15, 2 } )

   RETURN aFields



// -------------------------------
// vraca naz2 iz partnera
// -------------------------------
FUNCTION PN2()
   RETURN ( if( cN2Fin == "D", " " + Trim( PARTN->naz2 ), "" ) )



// ---------------------------------------------
// Rasclanjuje radne jedinice
// ---------------------------------------------
FUNCTION RasclanRJ()

   IF cRasclaniti == "D"
      RETURN cRasclan == suban->( idrj )
      // sasa, 12.02.04
      // return cRasclan==suban->(idrj+funk+fond)
   ELSE
      RETURN .T.
   ENDIF



   // ------------------------------------------
   // prikaz vrijednosti na izvjestaju
   // ------------------------------------------











/* TekRec()
 * Vraca tekuci zapis
 */

STATIC FUNCTION TekRec()

   @ box_x_koord() + 1, box_y_koord() + 2 SAY RecNo()

   RETURN NIL




/*
 *     Pita za polja od K1 do K4
 *   param: nYDelta
 *   param: lK
 */

FUNCTION fin_get_k1_k4_funk_fond( GetList, nYDelta, lK )

   LOCAL _k1, _k2, _k3, _k4
   LOCAL _params := fin_params()

   _k1 := _params[ "fin_k1" ]
   _k2 := _params[ "fin_k2" ]
   _k3 := _params[ "fin_k3" ]
   _k4 := _params[ "fin_k4" ]

   IF lK == NIL
      lK := .T.
   ENDIF

   IF lK
      IF _k1
         @ box_x_koord() + nYDelta, box_y_koord() + 2 SAY "K1 (9 svi) :" GET cK1
      ENDIF
      IF _k2
         @ box_x_koord() + nYDelta, Col() + 2 SAY "K2 (9 svi) :" GET cK2
      ENDIF
      IF _k3
         @ box_x_koord() + nYDelta + 1, box_y_koord() + 2 SAY "K3 (" + cK3 + " svi):" GET cK3
      ENDIF
      IF _k4
         @ box_x_koord() + nYDelta + 1, Col() + 1 SAY "K4 (99 svi):" GET cK4
      ENDIF
   ENDIF

   IF gFinRj == "D"
      //IF gDugiUslovFirmaRJFinSpecif == "D" .AND. ( ProcName( 1 ) == UPPER( "fin_spec_po_suban_kontima" ) .OR. ProcName( 1 ) == UPPER("fin_suban_kartica") )
      //   @ box_x_koord() + nYDelta + 2, box_y_koord() + 2 SAY "RJ:" GET cIdRj PICT "@!S20"
      //ELSE
         @ box_x_koord() + nYDelta + 2, box_y_koord() + 2 SAY "RJ:" GET cIdRj
      //ENDIF
   ENDIF

   IF gFinFunkFond == "D"
      @ box_x_koord() + nYDelta + 3, box_y_koord() + 2 SAY "Funk:" GET cFunk
      @ box_x_koord() + nYDelta + 3, Col() + 2 SAY "Fond: " GET cFond
   ENDIF

   RETURN .T.



/*
  Cisti polja od K1 do K4
 */

FUNCTION CistiK1K4( lK )

   IF lK == NIL; lK := .T. ; ENDIF
   IF lK
      IF ck1 == "9"; ck1 := ""; ENDIF
      IF ck2 == "9"; ck2 := ""; ENDIF
      IF ck3 == REPL( "9", Len( ck3 ) )
         ck3 := ""
      ELSE
         ck3 := k3u256( ck3 )
      ENDIF
      IF ck4 == "99"; ck4 := ""; ENDIF
   ENDIF
   //IF gDugiUslovFirmaRJFinSpecif == "D" .AND. ( ProcName( 1 ) == UPPER( "fin_spec_po_suban_kontima" ) .OR. ProcName( 1 ) == UPPER( "fin_suban_kartica" ) )
  //    cIdRj := Trim( cIdRj )
   //ELSE
      IF cIdRj == REPLICATE("9", FIELD_LEN_FIN_RJ_ID ) ; cIdrj := ""; ENDIF
      IF "." $ cidrj
         cIdrj := Trim( StrTran( cIdrj, ".", "" ) )  // odsjeci ako je tacka. prakticno "01. " -> sve koje pocinju sa  "01"
      ENDIF
   //ENDIF
   IF cFunk == "99999"; cFunk := ""; ENDIF
   IF "." $ cfunk
      cfunk := Trim( StrTran( cfunk, ".", "" ) )
   ENDIF
   IF cFond == "9999"; cFond := ""; ENDIF
   IF "." $ cfond
      cfond := Trim( StrTran( cfond, ".", "" ) )
   ENDIF

   RETURN .T.



/*
 *     Prikazi polja od K1 do K4, radnu jedinicu
 *   param: lK
 */

FUNCTION prikaz_k1_k4_rj( lK )

   LOCAL lProsao := .F.
   LOCAL nArr := Select()
   LOCAL hParamsFakt := fakt_params()
   LOCAL _fin_params := fin_params()

   LOCAL lVrsteP := hParamsFakt[ "fakt_vrste_placanja" ]

   IF lK == NIL
      lK := .T.
   ENDIF

   IF lVrsteP
      SELECT ( F_VRSTEP )
      IF !Used()
         o_vrstep()
      ENDIF
      SELECT ( nArr )
   ENDIF

   cM := Replicate( "-", 55 )

   cStr := "Pregled odabranih kriterija :"

   IF gFinRJ == "D" .AND. Len( cIdRJ ) <> 0
      cRjNaz := ""
      nArr := Select()
      //o_rj()
      select_o_rj( cIdRj )

      IF PadR( rj->id, 6 ) == PadR( cIdRj, 6 )
         cRjNaz := rj->naz
      ENDIF

      SELECT   ( nArr )
      IF !lProsao
         ? cM
         ? cStr
         lProsao := .T.
      ENDIF
      ? "Radna jedinica: " + cIdRj + " - " + cRjNaz
   ENDIF

   IF lK
      IF _fin_params[ "fin_k1" ] .AND. !Len( ck1 ) == 0
         IF !lProsao
            ? cM
            ? cStr
            lProsao := .T.
         ENDIF
         ? "K1 =", ck1
      ENDIF

      IF _fin_params[ "fin_k2" ] .AND. !Len( ck2 ) = 0
         IF !lProsao
            ? cM
            ? cStr
            lProsao := .T.
         ENDIF
         ? "K2 =", ck2
      ENDIF

      IF _fin_params[ "fin_k3" ] .AND. !Len( ck3 ) = 0
         IF !lProsao
            ? cM
            ? cStr
            lProsao := .T.
         ENDIF
         ? "K3 =", k3iz256( ck3 )
      ENDIF
      IF _fin_params[ "fin_k4" ] .AND. !Len( ck4 ) = 0
         IF !lProsao
            ? cM
            ? cStr
            lProsao := .T.
         ENDIF
         ? "K4 =", ck4
         IF lVrsteP .AND. Len( ck4 ) > 1
            ?? "-" + get_vrstep_naz( cK4 )
         ENDIF
      ENDIF
   ENDIF

   IF gFinFunkFond == "D" .AND. Len( cFunk ) <> 0
      IF !lProsao
         ? cM
         ? cStr
         lProsao := .T.
      ENDIF
      ? "Funkcionalna klasif. ='" + cFunk + "'"
   ENDIF

   IF gFinFunkFond == "D" .AND. Len( cFond ) <> 0
      IF !lProsao
         ? cM
         ? cStr
         lProsao := .T.
      ENDIF
      ? "                Fond ='" + cFond + "'"
   ENDIF

   IF lProsao
      ? cM
      ?
   ENDIF

   RETURN .T.
