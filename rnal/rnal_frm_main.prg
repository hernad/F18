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

STATIC l_new_doc
STATIC _oper_id
STATIC _doc


FUNCTION rnal_unos_osnovnih_podataka_naloga( lNew )

   LOCAL nRecCnt := 0
   LOCAL nGetBoxX := 22
   LOCAL nGetBoxY := 70
   PRIVATE GetList := {}

   nRecCnt := RECCOUNT2()

   IF lNew .AND. nRecCnt == 1
      MsgBeep( "Već postoji definisan nalog !#Dodavanje novih stavki onemogućeno !" )
      RETURN 0
   ENDIF

   l_new_doc := lNew

   _oper_id := f18_get_user_id( f18_user() )

   SELECT _docs

   Box(, nGetBoxX, nGetBoxY, .F., "Unos osnovnih podataka naloga" )
   @ box_x_koord() + nGetBoxX, box_y_koord() + 2 SAY PadL( "(*) popuna obavezna", nGetBoxY - 2 ) COLOR "BG+/B"

   set_opc_box( nGetBoxX, 50 )

   Scatter()
   _doc := _doc_no

   IF forma_osnovnih_podataka( nGetBoxX, nGetBoxY ) == 0

      SELECT _docs
      BoxC()
      RETURN 0

   ENDIF

   BoxC()

   SELECT _docs

   IF l_new_doc
      APPEND BLANK
   ENDIF

   my_rlock()
   Gather()
   my_unlock()

   RETURN 1



// -----------------------------------------------
// setuj box na dnu kao pomoc
// nX - x kordinata max
// nLeft - LEFT vrijednost
// cTxt1...cTxt3 - mogucnost 3 reda teksta
// cColor - mogucnost zadavanja boje, def: BG+/B
// -----------------------------------------------
FUNCTION set_opc_box( nX, nLeft, ;
      cTxt1, cTxt2, cTxt3, ;
      cColor )

   LOCAL i

   IF nX == nil
      nX := 20
   ENDIF

   IF nLeft == nil
      nLeft := 50
   ENDIF

   IF cTxt1 == nil
      cTxt1 := ""
   ENDIF

   IF cTxt2 == nil
      cTxt2 := ""
   ENDIF

   IF cTxt3 == nil
      cTxt3 := ""
   ENDIF

   IF cColor == nil
      cColor := "BG+/B"
   ENDIF

   cTxt1 := PadR( cTxt1, nLeft )
   cTxt2 := PadR( cTxt2, nLeft )
   cTxt3 := PadR( cTxt3, nLeft )

   @ box_x_koord() + nX - 2, box_y_koord() + 2 SAY8 cTxt1 COLOR cColor
   @ box_x_koord() + nX - 1, box_y_koord() + 2 SAY8 cTxt2 COLOR cColor

   IF !Empty( cTxt3 )
      @ box_x_koord() + nX, box_y_koord() + 2 SAY8 cTxt3 COLOR cColor
   ENDIF

   RETURN .T.



STATIC FUNCTION forma_osnovnih_podataka( nBoxX, nBoxY )

   LOCAL nX := 1
   LOCAL nLeft := 21
   LOCAL cCustId
   LOCAL cContId
   LOCAL cObjId

   IF l_new_doc

      _doc_date := danasnji_datum()
      _doc_dvr_da := _doc_date + 2
      _doc_dvr_ti := PadR( PadR( Time(), 5 ), 8 )
      _doc_ship_p := PadR( "", Len( _doc_ship_p ) )
      _doc_priori := 2
      _doc_pay_id := 1
      _doc_paid := "D"
      _doc_pay_de := Space( Len( _doc_pay_de ) )
      _doc_status := 10
      _doc_sh_des := Space( Len( _doc_sh_des ) )
      _doc_type := Space( 2 )

      cCustId := PadR( "", 10 )
      cContId := PadR( "", 10 )
      cObjId := PadR( "", 10 )
   ELSE

      cCustId := Str( _cust_id, 10 )
      cContId := Str( _cont_id, 10 )
      cObjId := Str( _obj_id, 10 )

   ENDIF

   _operater_i := _oper_id

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Datum naloga (*):" GET _doc_date WHEN set_opc_box( nBoxX, 50 )

   @ box_x_koord() + nX, Col() + 2 SAY8 "Tip naloga (*):" GET _doc_type WHEN set_opc_box( nBoxX, 50, "prazno - klasicni nalog, NP - neuskladjen proizvod" ) ;
      VALID _doc_type $ "  #NP"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Naručioc (*):", nLeft ) GET cCustid VALID {|| s_customers( @cCustId, cCustId ), set_var( @_cust_id, @cCustId ), show_it( g_cust_desc( _cust_id ), 35 ) } WHEN set_opc_box( nBoxX, 50, "0 - otvori sifrarnik" )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Datum isporuke (*):", nLeft ) GET _doc_dvr_da ;
        VALID must_enter( _doc_dvr_da ) .AND. valid_datum_isporuke( _doc_dvr_da, _doc_date ) ;
        WHEN set_opc_box( nBoxX, 50 )

   @ box_x_koord() + nX, Col() + 2 SAY8 PadL( "Vrijeme isporuke (*):", nLeft ) GET _doc_dvr_ti VALID must_enter( _doc_dvr_ti ) WHEN set_opc_box( nBoxX, 50, "format: HH:MM" )

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Objekat isporuke (*):", nLeft ) GET cObjId VALID {|| s_objects( @cObjid, _cust_id, cObjId ), set_var( @_obj_id, @cObjid ), show_it( g_obj_desc( _obj_id ), 35 ) } WHEN set_opc_box( nBoxX, 50, "Objekat u koji se isporučuje", "0 - otvori šifarnik" )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Mjesto isporuke :", nLeft ) GET _doc_ship_p VALID {|| sh_place_pattern( @_doc_ship_p ) } PICT "@S46" WHEN set_opc_box( nBoxX, 50, "mjesto gdje se roba isporucuje", "/RP - rg prod. /T - tvornica nar." )
   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Kontakt osoba (*):", nLeft ) GET cContid VALID {|| s_contacts( @cContid, _cust_id, cContId ), set_var( @_cont_id, @cContid ), show_it( g_cont_desc( _cont_id ), 35 ) } WHEN set_opc_box( nBoxX, 50, "0 - otvori sifrarnik" )

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "dodatni opis:", nLeft + 2 ) GET _cont_add_d PICT "@S44" WHEN set_opc_box( nBoxX, 50, "dodatni opis kontakta" )
   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   nX += 3

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Prioritet (*):", nLeft ) GET _doc_priori VALID {|| ( _doc_priori > 0 .AND. _doc_priori < 4 ), show_it( s_priority( _doc_priori ), 40 ) } PICT "9" WHEN set_opc_box( nBoxX, 50, "1 - high, 2 - normal, 3 - low" )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Vrsta plaćanja (*):", nLeft ) GET _doc_pay_id VALID {|| ( _doc_pay_id > 0 .AND. _doc_pay_id < 3 ), show_it( s_pay_id( _doc_pay_id ), 40 ) } PICT "9"  WHEN set_opc_box( nBoxX, 50, "1 - ziro racun, 2 - gotovina" )

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 PadL( "Plaćeno (D/N)? (*):", nLeft ) GET _doc_paid VALID _doc_paid $ "DN" PICT "@!" WHEN set_opc_box( nBoxX, 50 )

   @ box_x_koord() + nX, Col() + 2 SAY8 "dod.nap.plać:" GET _doc_pay_de PICT "@S29" WHEN set_opc_box( nBoxX, 50, "dodatne napomene vezane za placanje" )
   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   nX += 2

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Kratki opis (*):", nLeft ) GET _doc_sh_des VALID !Empty( _doc_sh_des ) PICT "@S46" WHEN set_opc_box( nBoxX, 50, "kratki opis naloga (asocijacija)", "npr: ulazna stijena, vrata ..." )
   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   nX += 1

   @ box_x_koord() + nX, box_y_koord() + 2 SAY PadL( "Dod.opis naloga:", nLeft ) GET _doc_desc VALID chk_mandatory( _doc_desc, _doc_priori ) PICT "@S46" WHEN set_opc_box( nBoxX, 50, "dodatni opis naloga" )
   @ box_x_koord() + nX, Col() SAY ">" COLOR f18_color_i()

   READ

   ESC_RETURN 0

   RETURN 1




STATIC FUNCTION valid_datum_isporuke( dDatIsp, dDatNaloga )

   LOCAL lRet := .F.

   IF dDatIsp < dDatNaloga
      MsgBeep( "Datum isporuke mora biti identičan ili veći od datuma naloga !" )
      RETURN lRet
   ENDIF

   lRet := .T.

   RETURN lRet


// --------------------------------------------
// provjerava da li je popunjena varijabla
// --------------------------------------------
FUNCTION empty_var( xVar )

   LOCAL nRet := .T.
   LOCAL cVarType := ValType( xVar )

   DO CASE
   CASE cVarType == "C"
      IF Empty( xVar )
         lRet := .F.
      ENDIF
   CASE cVarType == "N"
      IF xVar == 0
         lRet := .F.
      ENDIF
   ENDCASE

   RETURN lRet


// ------------------------------------------
// set N polje iz C varijable
// ------------------------------------------
FUNCTION set_var( _field, xVar, nLen )

   IF nLen == nil
      nLen := 10
   ENDIF

   // convert to "C"
   IF ValType( xVar ) == "N"

      // set field
      _field := xVar

      // convert to "C"
      xVar := PadL( Str( xVar, nLen ), nLen )

   ENDIF

   RETURN .T.



// -----------------------------------------------------
// setuje nazive za mjesto isporuke prema patternu
// recimo /RP - ramaglas prodaja
// "/" + nastavak je pattern
// -----------------------------------------------------
STATIC FUNCTION sh_place_pattern( cPattern )

   LOCAL nLen := Len( cPattern )

   DO CASE
   CASE AllTrim( cPattern ) == "/RP"
      cPattern := PadR( "Rama-glas prodaja", nLen )
   CASE AllTrim( cPattern ) == "/T"
      cPattern := PadR( "Tvornica narucioca", nLen )
   ENDCASE

   RETURN .T.



// ---------------------------------------------------------
// prvovjeri da li je polje neophodno na osnovu prioriteta
// ---------------------------------------------------------
STATIC FUNCTION chk_mandatory( cDesc, nDocPriority )

   LOCAL lRet := .T.

   DO CASE
   CASE nDocPriority < 2 .AND. Empty( cDesc )
      lRet := .F.

   ENDCASE

   IF lRet == .F.
      MsgBeep( "Unos polja obavezan, prioritet = " + ;
         s_priority( nDocPriority ) )
   ENDIF

   RETURN lRet


// ----------------------------
// vrati opis prioriteta
// ----------------------------
FUNCTION s_priority( _doc_prior )

   LOCAL xRet := ""

   DO CASE
   CASE _doc_prior == 1
      xRet := "HIGH"
   CASE _doc_prior == 2
      xRet := "NORMAL"
   CASE _doc_prior == 3
      xRet := "LOW"
   ENDCASE

   RETURN xRet

// ------------------------------
// vrati opis vrste placanja
// ------------------------------
FUNCTION s_pay_id( _pay_id )

   LOCAL xRet := ""

   DO CASE
   CASE _pay_id == 1
      xRet := "ziro racun"
   CASE _pay_id == 2
      xRet := "gotovina"
   ENDCASE

   RETURN xRet
