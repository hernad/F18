/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC l_new_ops
STATIC _doc
STATIC __item_no
STATIC __art_id
STATIC __art_type
STATIC _form_article
STATIC _a_elem
STATIC _a_arr

// ------------------------------------------
// unos ispravka operacija naloga
// nDoc_no - dokument broj
// lNew - nova stavka .t. or .f.
// nItem_no - stavka broj
// nArt_id - artikal id
// ------------------------------------------
FUNCTION e_doc_ops( nDoc_no, lNew, nArt_id, nItem_no )

   LOCAL nX := box_x_koord()
   LOCAL nY := box_y_koord()
   LOCAL nGetBoxX := 16
   LOCAL nGetBoxY := 70
   LOCAL cBoxNaz := "unos dodatnih operacija stavke"
   LOCAL nRet := 0
   LOCAL nFuncRet := 0
   LOCAL _rec
   PRIVATE GetList := {}

   IF nItem_no == nil
      nItem_no := 0
   ENDIF

   _doc := nDoc_no
   __item_no := nItem_no
   __art_id := nArt_id
   _from_article := .F.

   IF nItem_no > 0
      _from_article := .T.
   ENDIF

   _a_arr := {}

   rnal_matrica_artikla( __art_id, @_a_arr )

   _g_art_elements( @_a_elem, __art_id )

   __art_type := Len( _a_elem )

   IF lNew == nil
      lNew := .T.
   ENDIF

   l_new_ops := lNew

   IF l_new_ops == .F.
      cBoxNaz := "ispravka dodatne operacije stavke"
   ENDIF

   SELECT _doc_ops

   Box(, nGetBoxX, nGetBoxY, .F., "Unos dodatnih operacija naloga" )

   set_opc_box( nGetBoxX, 50 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY PadL( "***** " + cBoxNaz, nGetBoxY - 2 )
   @ box_x_koord() + nGetBoxX, box_y_koord() + 2 SAY PadL( "(*) popuna obavezna", nGetBoxY - 2 ) COLOR "BG+/B"

   DO WHILE .T.

      set_global_memvars_from_dbf()

      nFuncRet := _e_box_item( nGetBoxX, nGetBoxY )

      IF nFuncRet == 1

         SELECT _doc_ops

         IF l_new_ops
            APPEND BLANK
         ENDIF

         _rec := get_hash_record_from_global_vars( NIL, .F. )

         dbf_update_rec( _rec )

         IF l_new_ops
            LOOP
         ENDIF

      ENDIF

      BoxC()
      SELECT _doc_ops

      nRet := RECCOUNT2()

      EXIT

   ENDDO

   SELECT _docs

   box_x_koord( nX )
   box_y_koord( nY )

   RETURN nRet


// -------------------------------------------------------
// kopiranje operacija sa prethodne stavke
// -------------------------------------------------------
FUNCTION _cp_oper( nDoc_no, nArt_id, nDoc_it_no )

   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL nRec
   LOCAL nSrchItem := nDoc_it_no - 1
   LOCAL nCnt := 0

   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no ) + docit_str( nSrchItem )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no ;
         .AND. field->doc_it_no == nSrchItem

      SKIP 1

      nRec := RecNo()

      SKIP -1

      _rec := dbf_get_rec()

      APPEND BLANK

      _rec[ "doc_it_no" ] := nDoc_it_no

      dbf_update_rec( _rec )

      ++ nCnt

      GO ( nRec )

   ENDDO

   SELECT ( nTArea )
   GO ( nTRec )

   IF nCnt > 0
      MsgBeep( "Kopirano: " + AllTrim( Str( nCnt ) ) + " operacija !" )
   ENDIF

   RETURN



// -------------------------------------------------
// forma za unos podataka
// -------------------------------------------------
STATIC FUNCTION _e_box_item( nBoxX, nBoxY )

   LOCAL nX := 1
   LOCAL nLeft := 27
   LOCAL cAop := ""
   LOCAL cAopAtt := ""
   LOCAL nH
   LOCAL nW
   LOCAL nElement := 0
   LOCAL nTick := 0

   IF l_new_ops

      _doc_no := _doc
      _doc_op_no := inc_docop( _doc )
      _doc_it_el_ := 0
      _aop_id := 0
      _aop_att_id := 0
      _doc_op_des := PadR( "", Len( field->doc_op_des ) )
      _doc_it_no := __item_no
      _aop_value := PadR( "", Len( field->aop_value ) )

      cAop := PadR( "", 10 )
      cAopAtt := PadR( "", 10 )

   ELSE

      cAop := PadL( Str( _aop_id, 10 ), 10 )
      cAopAtt := PadL( Str( _aop_att_id, 10 ), 10 )

   ENDIF


   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "r.br operacije (*):", nLeft ) GET _doc_op_no ;
      WHEN {|| set_opc_box( nBoxX, 50 ), _doc_op_no == 0 }

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "odnosi se na stavku (*):", nLeft ) GET _doc_it_no ;
      VALID {|| _item_range( _doc_it_no ) .AND. ;
      show_it( g_item_desc( _doc_it_no ), 26 ) } ;
      WHEN {|| set_opc_box( nBoxX, 50, "ova operacija ce se odnositi", "eksplicitno na unesenu stavku" ), ;
      _from_article == .F. }

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( " -> element stavke (*):", nLeft ) GET _doc_it_el_ ;
      VALID {|| get_it_element( @_doc_it_el_, @nElement ), ;
      show_it( get_elem_desc( _a_elem, _doc_it_el_ ), 26 ) } ;
      WHEN {|| _g_art_elements( @_a_elem, _g_art_it_no( _doc_it_no ) ), ;
      set_opc_box( nBoxX, 50, "odnosi se na odredjeni element stavke", "" ) }

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "dodatna operacija (*):", nLeft ) GET cAop ;
      VALID {|| s_aops( @cAop, cAop ), ;
      set_var( @_aop_id, @cAop ), ;
      show_it( g_aop_desc( _aop_id ), 20 ), ;
      rule_aop( g_aop_joker( _aop_id ), _a_arr ) } ;
      WHEN set_opc_box( nBoxX, 50, "odaberi dodatnu operaciju", "0 - otvori sifrarnik" )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "atribut dod. operacije:", nLeft ) GET cAopAtt ;
      VALID {|| s_aops_att( @cAopAtt, _aop_id, cAopAtt ), ;
      set_var( @_aop_att_id, @cAopAtt ), ;
      show_it( g_aop_att_desc( _aop_att_id ), 20 ), ;
      rule_aop( g_aatt_joker( _aop_att_id ), _a_arr ) } ;
      WHEN set_opc_box( nBoxX, 50, "odaberi atribut dodatne operacije", "99 - otvori sifrarnik" )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "vrijednost:", nLeft ) GET _aop_value ;
      VALID {|| _g_dim_it_no( _doc_it_no, nElement, @nH, @nW, @nTick ) .AND. ;
      is_g_config( @_aop_value, _aop_att_id, nH, nW, nTick ) } ;
      PICT "@S40" ;
      WHEN set_opc_box( nBoxX, 50, "vrijednost operacije ako postoji", "kod brusenja, poliranja..." )

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "dodatni opis:", nLeft ) GET _doc_op_des ;
      PICT "@S40" ;
      WHEN set_opc_box( nBoxX, 50, "dodatni opis vezan uz navedene", "operacije" )

   READ

   ESC_RETURN 0

   RETURN 1



// --------------------------------------------
// vraca opis iz matrice - opis elementa
// --------------------------------------------
FUNCTION get_elem_desc( aElem, nVal, nLen )

   LOCAL xRet := ""
   LOCAL nChoice

   IF nLen == nil
      nLen := 17
   ENDIF

   nChoice := AScan( aElem, {| xVal| xVal[ 1 ] == nVal } )

   IF nChoice > 0
      xRet := aElem[ nChoice, 2 ]
   ENDIF

   xRet := PadR( xRet, nLen )

   RETURN xRet



// --------------------------------------------------
// vraca arr sa elementima artikla...
// --------------------------------------------------
FUNCTION get_it_element( nDoc_it_e_id, nElement )

   LOCAL nXX := box_x_koord()
   LOCAL nYY := box_y_koord()

   IF nDoc_it_e_id > 0
      nElement := _get_a_element( _a_elem, nDoc_it_e_id )
      RETURN .T.
   ENDIF

   // odaberi element
   nDoc_it_e_id := _pick_element( _a_elem, @nElement )

   box_x_koord( nXX )
   box_y_koord( nYY )

   RETURN .T.



// ------------------------------------------------
// vraca element iz matrice
// ------------------------------------------------
STATIC FUNCTION _get_a_element( aElem, nEl_no )

   LOCAL nTmp
   LOCAL nElement := 0

   nTmp := AScan( aElem, {|xVal| xVal[ 1 ] = nEl_no } )

   IF nTmp <> 0
      nElement := aElem[ nTmp, 3 ]
   ENDIF

   RETURN nElement




// -----------------------------------------
// uzmi element...
// -----------------------------------------
STATIC FUNCTION _pick_element( aElem, nChoice )

   LOCAL nRet
   LOCAL i
   LOCAL cPom
   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}
   PRIVATE GetList := {}

   nChoice := 1

   FOR i := 1 TO Len( aElem )

      cPom := PadL( AllTrim( Str( i ) ) + ")", 3 ) + " " + PadR( aElem[ i, 2 ], 40 )

      AAdd( _opc, cPom )
      AAdd( _opcexe, {|| nChoice := _izbor, _izbor := 0 } )

   NEXT

   f18_menu( "izbor", .F., @_izbor, _opc, _opcexe )

   IF LastKey() == K_ESC
      nChoice := 0
      nRet := 0
   ELSE
      nRet := aElem[ nChoice, 1 ]
   ENDIF

   RETURN nRet




// ---------------------------------------------
// da li je stavka u rangu stavki tabele
// ---------------------------------------------
STATIC FUNCTION _item_range( nItemNo )

   LOCAL lRet := .T.
   LOCAL nTArea := Select()
   LOCAL nDocItRec, nTrec

   SELECT _doc_it
   nTrec := RecNo()
   GO TOP
   SEEK docno_str( _doc ) + docit_str( nItemNo )

   IF nItemNo <= 0 .OR. !Found()
      lRet := .F.
   ENDIF

   GO ( nTrec )

   SELECT ( nTArea )

   IF lRet == .F.
      MsgBeep( "Nepostojeca stavka naloga !!!" )
   ENDIF

   RETURN lRet


// --------------------------------------------
// vrati opis odnosi se na stavku
// --------------------------------------------
STATIC FUNCTION g_item_desc( doc_it_no )

   LOCAL xRet := ""

   xRet := "na " + AllTrim( Str( doc_it_no ) ) + " stavku naloga"

   RETURN xRet


// ----------------------------------------------------
// vraca dimenzije stavke
// ----------------------------------------------------
STATIC FUNCTION _g_dim_it_no( nDoc_it_no, nElement, nH, nW, nTick )

   LOCAL nArt_id := 0
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL aArr := {}

   nH := 0
   nW := 0
   nTick := 0

   SELECT _doc_it
   SET ORDER TO TAG "1"
   SEEK docno_str( _doc ) + docit_str( nDoc_it_no )

   IF Found()

      nH := field->doc_it_hei
      nW := field->doc_it_wid

      // uzmi debljinu...

      nTick := g_gl_tickness( _a_arr, nElement )

   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN .T.


// ---------------------------------------------
// vraca artikal za stavku
// ---------------------------------------------
STATIC FUNCTION _g_art_it_no( nDoc_it_no )

   LOCAL nArt_id := 0
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()

   SELECT _doc_it
   SET ORDER TO TAG "1"
   SEEK docno_str( _doc ) + docit_str( nDoc_it_no )

   IF Found()
      nArt_id  := field->art_id
   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN nArt_id



// -------------------------------------------
// uvecaj broj stavke naloga
// -------------------------------------------
FUNCTION inc_docop( nDoc_no )

   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL nRet := 0

   SELECT _doc_ops
   GO TOP
   SET ORDER TO TAG "1"
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no
      nRet := field->doc_op_no
      SKIP
   ENDDO

   nRet += 1

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN nRet
