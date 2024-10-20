/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC __doc_no
STATIC __oper_id


FUNCTION m_changes( nDoc_no )

   LOCAL opc := {}
   LOCAL opcexe := {}
   LOCAL izbor := 1
   LOCAL _x := box_x_koord()
   LOCAL _y := box_y_koord()

   __doc_no := nDoc_no
   __oper_id := f18_get_user_id( f18_user() )

   AAdd( opc, "promjena, osnovni podaci naloga " )
   AAdd( opcexe, {|| _ch_main() } )
   AAdd( opc, "promjena, podaci isporuke " )
   AAdd( opcexe, {|| _ch_ship() } )
   AAdd( opc, "promjena, podaci o placanju " )
   AAdd( opcexe, {|| _ch_pay() } )
   AAdd( opc, "promjena, podaci kontakta" )
   AAdd( opcexe, {|| _ch_cont() } )
   AAdd( opc, "promjena, napomene i opisi" )
   AAdd( opcexe, {|| _ch_description() } )
   AAdd( opc, "promjena, novi kontakt naloga " )
   AAdd( opcexe, {|| _ch_cont( .T. ) } )
   AAdd( opc, "promjena, lom artikala " )
   AAdd( opcexe, {|| rnal_evidencija_loma_stakla( __oper_id ) } )
   AAdd( opc, "napravi neuskladjeni proizvod " )
   AAdd( opcexe, {|| rnal_damage_doc_generate( __doc_no ) } )

   f18_menu( "changes", .F., izbor, opc, opcexe )

   box_x_koord( _x )
   box_y_koord( _y )

   RETURN



FUNCTION _ch_main()

   LOCAL nTRec := RecNo()
   LOCAL nCustId
   LOCAL nDoc_priority
   LOCAL cDesc
   LOCAL nDoc_no
   LOCAL aArr
   LOCAL _rec

   IF Pitanje(, "Zelite izmjeniti osnovne podatke naloga (D/N)?", "D" ) == "N"
      RETURN
   ENDIF

   SELECT docs

   nCustId := field->cust_id
   nDoc_priority := field->doc_priori
   nDoc_no := field->doc_no

   // box sa unosom podataka
   IF _box_main( @nCustId, @nDoc_priority, @cDesc ) == 0
      RETURN
   ENDIF

   aArr := podaci_naloga_za_log_osnovni( nCustId, nDoc_priority )
   logiraj_osnovne_podatke_naloga( __doc_no, cDesc, "E", aArr )

   SELECT docs
   _rec := dbf_get_rec()

   IF _rec[ "cust_id" ] <> nCustId
      _rec[ "cust_id" ] := nCustId
   ENDIF
   IF _rec[ "doc_priori" ] <> nDoc_priority
      _rec[ "doc_priori" ] := nDoc_priority
   ENDIF

   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   log_write( "F18_DOK_OPER: rnal, promjena osnovnih podataka naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )

   SKIP

   SELECT docs
   GO ( nTRec )

   RETURN


STATIC FUNCTION _box_main( nCust, nPrior, cDesc )

   LOCAL cCust := Space( 10 )

   Box(, 7, 65 )
   cDesc := Space( 150 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Osnovni podaci naloga:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "Naručioc:" GET cCust VALID {|| s_customers( @cCust, cCust ), set_var( @nCust, @cCust ), show_it( g_cust_desc( nCust ) ) }
   @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "Prioritet (1/2/3):" GET nPrior VALID nPrior > 0 .AND. nPrior < 4
   @ box_x_koord() + 7, box_y_koord() + 2 SAY8 "Opis promjene:" GET cDesc PICT "@S40"
   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1



FUNCTION _ch_ship()

   LOCAL nTRec := RecNo()
   LOCAL cShipPlace
   LOCAL cDvrTime
   LOCAL dDvrDate
   LOCAL nObj_id
   LOCAL nDoc_no
   LOCAL cObj_id
   LOCAL cDesc
   LOCAL aArr
   LOCAL nCust_id

   IF Pitanje(, "Zelite izmjeniti podatke o isporuci naloga (D/N)?", "D" ) == "N"
      RETURN
   ENDIF

   SELECT docs

   cShipPlace := field->doc_ship_p
   dDvrDate := field->doc_dvr_da
   cDvrTime := field->doc_dvr_ti
   nObj_id := field->obj_id
   nCust_id := field->cust_id
   nDoc_no := field->doc_no

   IF _box_ship( @nObj_id, @cShipPlace, @cDvrTime, @dDvrDate, @cDesc, nCust_id ) == 0
      RETURN
   ENDIF

   aArr := podaci_naloga_za_log_isporuka( nObj_id, dDvrDate, cDvrTime, cShipPlace )
   logiraj_podatke_isporuke_za_nalog( __doc_no, cDesc, "E", aArr )

   SELECT docs

   set_global_memvars_from_dbf()

   IF _doc_ship_p <> cShipPlace
      _doc_ship_p := cShipPlace
   ENDIF

   IF _doc_dvr_ti <> cDvrTime
      _doc_dvr_ti := cDvrTime
   ENDIF

   IF _doc_dvr_da <> dDvrDate
      _doc_dvr_da := dDvrDate
   ENDIF

   IF _obj_id <> nObj_id
      _obj_id := nObj_id
   ENDIF

   _rec := get_hash_record_from_global_vars()
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   log_write( "F18_DOK_OPER: rnal, promjena podataka isporuke naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )

   SELECT docs
   GO ( nTRec )

   RETURN


STATIC FUNCTION _box_ship( nObj_id, cShip, cTime, dDate, cDesc, nCust_id )

   LOCAL cObj_id := PadR( Str( nObj_id, 10 ), 10 )

   Box(, 8, 65 )
   cDesc := Space( 150 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Promjena podataka o isporuci:"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "Novi objekat isporuke:", 22 ) GET cObj_id VALID {|| s_objects( @cObj_id, nCust_id, cObj_id ), set_var( @nObj_id, @cObj_id ), show_it( AllTrim( g_obj_desc( nObj_id ) ) )  }
   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "Novo mjesto isporuke:", 22 ) GET cShip VALID !Empty( cShip ) PICT "@S30"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY PadL( "Novo vrijeme isporuke:", 22 ) GET cTime VALID !Empty( cTime )
   @ box_x_koord() + 6, box_y_koord() + 2 SAY PadL( "Novi datum isporuke:", 22 ) GET dDate VALID !Empty( dDate )
   @ box_x_koord() + 8, box_y_koord() + 2 SAY PadL( "Opis promjene:", 22 ) GET cDesc PICT "@S40"
   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1


FUNCTION _ch_pay()

   LOCAL nTRec := RecNo()
   LOCAL cDoc_paid
   LOCAL nDoc_pay_id
   LOCAL cDoc_pay_desc
   LOCAL cDesc
   LOCAL aArr
   LOCAL nDoc_no

   IF Pitanje(, "Zelite izmjeniti podatke o placanju naloga (D/N)?", "D" ) == "N"
      RETURN
   ENDIF

   SELECT docs

   cDoc_paid := field->doc_paid
   nDoc_pay_id := field->doc_pay_id
   cDoc_pay_desc := field->doc_pay_de
   nDoc_no := field->doc_no

   IF _box_pay( @nDoc_pay_id, @cDoc_paid, @cDoc_pay_desc, @cDesc ) == 0
      RETURN
   ENDIF

   aArr := podaci_naloga_za_log_placanje( nDoc_pay_id, cDoc_paid, cDoc_pay_desc )
   logiraj_podatke_placanja_za_nalog( __doc_no, cDesc, "E", aArr )

   SELECT docs

   set_global_memvars_from_dbf()

   IF _doc_paid <> cDoc_paid
      _doc_paid := cDoc_paid
   ENDIF

   IF _doc_pay_de <> cDoc_pay_desc
      _doc_pay_de := cDoc_pay_desc
   ENDIF

   IF _doc_pay_id <> nDoc_pay_id
      _doc_pay_id := nDoc_pay_id
   ENDIF

   _rec := get_hash_record_from_global_vars()
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   log_write( "F18_DOK_OPER: rnal, promjena podataka placanja naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )

   SELECT docs

   RETURN


STATIC FUNCTION _box_pay( nPay_id, cPaid, cPayDesc, cDesc )

   Box(, 7, 65 )
   cDesc := Space( 150 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Promjena podataka o placanju:"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "Vrsta placanja:", 22 ) GET nPay_id VALID {|| nPay_id > 0 .AND. nPay_id < 3, show_it( s_pay_id( nPay_id ) )  }
   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "Placeno (D/N):", 22 ) GET cPaid VALID cPaid $ "DN"
   @ box_x_koord() + 5, box_y_koord() + 2 SAY PadL( "dod.napomene:", 22 ) GET cPayDesc PICT "@S40"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY PadL( "Opis promjene:", 22 ) GET cDesc PICT "@S40"
   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1


FUNCTION _ch_cont( lNew )

   LOCAL nTRec := RecNo()
   LOCAL cDesc
   LOCAL aArr
   LOCAL cType := "E"
   LOCAL nCont_id := Val( Str( 0, 10 ) )
   LOCAL cCont_desc := Space( 150 )
   LOCAL nCust_id := Val( Str( 0, 10 ) )
   LOCAL nDoc_no

   IF lNew == nil
      lNew := .F.
   ENDIF

   IF !lNew

      SELECT docs

      nCust_id := field->cust_id
      nCont_id := field->cont_id
      cCont_desc := field->cont_add_d

   ENDIF

   nDoc_no := field->doc_no

   IF _box_cont( @nCust_id, @nCont_id, @cCont_desc, @cDesc ) == 0
      RETURN
   ENDIF

   // logiraj promjenu kontakta
   aArr := podaci_naloga_za_log_kontakti( nCont_id, cCont_desc )

   IF lNew
      cType := "+"
   ENDIF

   logiraj_podatke_kontakta_naloga( __doc_no, cDesc, cType, aArr )

   SELECT docs

   set_global_memvars_from_dbf()

   IF _cont_id <> nCont_id
      _cont_id := nCont_id
   ENDIF
   IF _cont_add_d <> cCont_desc
      _cont_add_d := cCont_desc
   ENDIF

   _rec := get_hash_record_from_global_vars()
   update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )

   log_write( "F18_DOK_OPER: rnal, promjena podataka kontakta naloga broj: " + AllTrim( Str( nDoc_no ) ), 2 )

   SELECT docs
   GO ( nTRec )

   RETURN


STATIC FUNCTION _box_cont( nCust, nCont, cContdesc, cDesc )

   LOCAL lNew := .F.
   LOCAL cCont := Space( 10 )

   cCont := PadR( AllTrim( Str( nCont ) ), 10 )

   IF nCont == 0
      lNew := .T.
   ENDIF

   Box(, 7, 65 )

   cDesc := Space( 150 )

   IF lNew == .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Novi kontakti naloga:"
   ELSE
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka kontakta naloga:"
   ENDIF

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "Kontakt:", 20 ) GET cCont VALID {|| s_contacts( @cCont, nCust, cCont ), set_var( @nCont, @cCont ), show_it( g_cont_desc( nCont ) ) }

   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "Kontakt, dodatni opis:", 20 ) GET cContDesc PICT "@S30"

   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Opis promjene:" GET cDesc PICT "@S40"
   READ
   BoxC()

   ESC_RETURN 0

   RETURN 1



FUNCTION _ch_description()

   LOCAL nTrec := RecNo()
   LOCAL _add_desc
   LOCAL _ch_desc := Space( 200 )
   LOCAL _sh_desc
   LOCAL _doc_no
   LOCAL _rec
   LOCAL _update := .F.

   SELECT docs

   _add_desc := field->doc_desc
   _sh_desc := field->doc_sh_des
   _doc_no := field->doc_no

   IF _box_descr( @_sh_desc, @_add_desc, @_ch_desc ) == 0
      RETURN
   ENDIF

   SELECT docs
   _rec := dbf_get_rec()

   IF _rec[ "doc_desc" ] <> _add_desc
      _rec[ "doc_desc" ] := _add_desc
      _update := .T.
   ENDIF

   IF _rec[ "doc_sh_des" ] <> _sh_desc
      _rec[ "doc_sh_des" ] := _sh_desc
      _update := .T.
   ENDIF

   IF _update
      update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
      log_write( "F18_DOK_OPER: rnal, promjena opisa i napomena naloga broj: " + AllTrim( Str( _doc_no ) ) + ;
         ", opis: " + AllTrim( _ch_desc ), 2 )
   ENDIF

   SELECT docs
   GO ( nTrec )

   RETURN


STATIC FUNCTION _box_descr( sh_desc, add_desc, ch_desc )

   Box(, 7, 65 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Ispravka opisa i napomena naloga:"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY PadL( "Kratki opis:", 20 ) GET sh_desc PICT "@S30"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY PadL( "Dodatni opis:", 20 ) GET add_desc PICT "@S30"

   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Opis promjene:" GET ch_desc PICT "@S40"

   READ

   BoxC()

   ESC_RETURN 0

   RETURN 1
