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

FUNCTION fin_cisti_polja_k4k4_funk_fond( lK, cIdRj, cK1, cK2, cK3, cK4, cFunk, cFond )

   IF lK == NIL; lK := .T. ; ENDIF

   IF lK
      IF cK1 == "9"; cK1 := ""; ENDIF
      IF cK2 == "9"; cK2 := ""; ENDIF
      IF cK3 == REPL( "9", Len( ck3 ) )
         cK3 := ""
      ELSE
         cK3 := k3u256( cK3 )
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
   IF "." $ cFond
      cfond := Trim( StrTran( cFond, ".", "" ) )
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
