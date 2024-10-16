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

STATIC __doc_no

/*
   Opis: logiranje stavki novog naloga prilikom ažuriranja
         podaci naloga, podaci stavki naloga, podaci operacija
*/
FUNCTION rnal_logiraj_novi_nalog()

   LOCAL cDesc := ""
   LOCAL aArr

   SELECT _docs
   GO TOP

   __doc_no := field->doc_no

   cDesc := "Inicijalni osnovni podaci"

   aArr := podaci_naloga_za_log_osnovni( field->cust_id, field->doc_priori )

   IF !logiraj_osnovne_podatke_naloga( __doc_no, cDesc, nil, aArr )
      RETURN .F.
   ENDIF

   SELECT _docs
   GO TOP

   cDesc := "Inicijalni podaci isporuke"
   aArr := podaci_naloga_za_log_isporuka( field->obj_id, ;
      field->doc_dvr_da, ;
      field->doc_dvr_ti, ;
      field->doc_ship_p )

   IF !logiraj_podatke_isporuke_za_nalog( __doc_no, cDesc, nil, aArr )
      RETURN .F.
   ENDIF

   SELECT _docs
   GO TOP

   cDesc := "Inicijalni podaci kontakta"
   aArr := podaci_naloga_za_log_kontakti( field->cont_id, field->cont_add_d )

   IF !logiraj_podatke_kontakta_naloga( __doc_no, cDesc, nil, aArr )
      RETURN .F.
   ENDIF

   SELECT _docs
   GO TOP

   cDesc := hb_Utf8ToStr( "Inicijalni podaci plaćanja" )
   aArr := podaci_naloga_za_log_placanje( field->doc_pay_id, field->doc_paid, field->doc_pay_de )

   IF !logiraj_podatke_placanja_za_nalog( __doc_no, cDesc, nil, aArr )
      RETURN .F.
   ENDIF

   SELECT _doc_it
   GO TOP

   cDesc := "Inicijalni podaci stavki"
   IF !logiraj_stavke_naloga( __doc_no, cDesc )
      RETURN .F.
   ENDIF

   cDesc := "Inicijalni podaci dodatnih operacija"
   IF !logiraj_dodatne_operacije_naloga( __doc_no, cDesc )
      RETURN .F.
   ENDIF

   RETURN .T.



// -------------------------------------------------
// puni matricu sa osnovnim podacima dokumenta
// aArr = { customer_id, doc_priority }
// -------------------------------------------------
FUNCTION podaci_naloga_za_log_osnovni( nCustId, nPriority )

   LOCAL aArr := {}

   AAdd( aArr, { nCustId, nPriority } )

   RETURN aArr


// -------------------------------------------------
// puni matricu sa podacima placanja
// aArr = { doc_pay_id, doc_paid, doc_pay_desc }
// -------------------------------------------------
FUNCTION podaci_naloga_za_log_placanje( nPayId, cDocPaid, cDocPayDesc )

   LOCAL aArr := {}

   AAdd( aArr, { nPayId, cDocPaid, cDocPayDesc } )

   RETURN aArr


// -------------------------------------------------
// puni matricu sa podacima isporuke
// aArr = { doc_dvr_date, doc_dvr_time, doc_ship_place }
// -------------------------------------------------
FUNCTION podaci_naloga_za_log_isporuka( nObj_id, dDate, cTime, cPlace )

   LOCAL aArr := {}

   AAdd( aArr, { nObj_id, dDate, cTime, cPlace } )

   RETURN aArr


// -------------------------------------------------
// puni matricu sa podacima kontakta
// aArr = { cont_id, cont_add_desc }
// -------------------------------------------------
FUNCTION podaci_naloga_za_log_kontakti( nCont_id, cCont_desc )

   LOCAL aArr := {}

   AAdd( aArr, { nCont_id, cCont_desc } )

   RETURN aArr



// ----------------------------------------------------
// logiranje osnovnih podataka
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// aMain - matrica sa osnovnim podacima
// ----------------------------------------------------
FUNCTION logiraj_osnovne_podatke_naloga( nDoc_no, cDesc, cAction, aArr )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "10"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )

   IF lOk
      lOk := rnal_log_tip_10_insert( cAction, nDoc_no, nDoc_log_no, aArr )
   ENDIF

   RETURN lOk



// ----------------------------------------------------
// logiranje podataka isporuke
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// aArr - matrica sa podacima
// ----------------------------------------------------
FUNCTION logiraj_podatke_isporuke_za_nalog( nDoc_no, cDesc, cAction, aArr )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "11"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   IF lOk
      lOk := rnal_log_tip_11_insert( cAction, nDoc_no, nDoc_log_no, aArr )
   ENDIF

   RETURN lOk


// ----------------------------------------------------
// logiranje podataka kontakata
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// aArr - matrica sa podacima
// ----------------------------------------------------
FUNCTION logiraj_podatke_kontakta_naloga( nDoc_no, cDesc, cAction, aArr )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "12"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   IF lOk
      lOk := rnal_log_tip_12_insert( cAction, nDoc_no, nDoc_log_no, aArr )
   ENDIF

   RETURN lOk


// ----------------------------------------------------
// logiranje podataka placanja
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// aArr - matrica sa osnovnim podacima
// ----------------------------------------------------
FUNCTION logiraj_podatke_placanja_za_nalog( nDoc_no, cDesc, cAction, aArr )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "13"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   IF lOk
      lOk := rnal_log_tip_13_insert( cAction, nDoc_no, nDoc_log_no, aArr )
   ENDIF

   RETURN lOk




// ----------------------------------------------------
// logiranje podataka o lomu...
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// ----------------------------------------------------
FUNCTION logiraj_podatke_loma_na_staklima( nDoc_no, cDesc, cAction )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.
   LOCAL hParams

   SELECT _tmp1

   IF RecCount() == 0
      RETURN .F.
   ENDIF

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "doc_log", "doc_lit" }, .T. )
      run_sql_query( "ROLLBACK" )
      lOk := .F.
      RETURN lOk
   ENDIF

   cDoc_log_type := "21"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )

   IF lOk

       SELECT _tmp1
       GO TOP

       DO WHILE !Eof()

          IF field->art_marker <> "*"
             SKIP
             LOOP
          ENDIF

          lOk := rnal_log_tip_21_insert( cAction, nDoc_no, nDoc_log_no, ;
                field->art_id,  ;
                field->art_desc, ;
                field->glass_no, ;
                field->doc_it_no, ;
                field->doc_it_qtt, ;
                field->damage )

          IF !lOk
             EXIT
          ENDIF

          SELECT _tmp1
          SKIP

       ENDDO

   ENDIF

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "doc_log", "doc_lit" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Podaci o lomu na staklima nisu ažurirani.#Greška u transakciji." )
   ENDIF

   RETURN .T.



// ----------------------------------------------------
// logiranje podataka stavki naloga
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// ----------------------------------------------------
FUNCTION logiraj_stavke_naloga( nDoc_no, cDesc, cAction )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   SELECT _doc_it
   IF RecCount() == 0
      RETURN lOk
   ENDIF

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "20"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )

   IF !lOk
      RETURN lOk
   ENDIF

   SELECT _doc_it
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      lOk := rnal_log_tip_20_insert( cAction, nDoc_no, nDoc_log_no, ;
         field->art_id,  ;
         field->doc_it_des, ;
         field->doc_it_sch, ;
         field->doc_it_qtt,  ;
         field->doc_it_hei, ;
         field->doc_it_wid )

      IF !lOk
         EXIT
      ENDIF

      SELECT _doc_it
      SKIP

   ENDDO

   RETURN lOk


// ----------------------------------------------------
// logiranje podataka dodatnih operacija
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// ----------------------------------------------------
FUNCTION logiraj_dodatne_operacije_naloga( nDoc_no, cDesc, cAction )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL lOk := .T.

   SELECT _doc_ops
   IF RecCount() == 0
      RETURN lOk
   ENDIF

   IF ( cAction == nil )
      cAction := "+"
   ENDIF

   cDoc_log_type := "30"
   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )

   IF !lOk
      RETURN lOk
   ENDIF

   SELECT _doc_ops
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      lOk := rnal_log_tip_30_insert( cAction, nDoc_no, nDoc_log_no, ;
         field->aop_id,  ;
         field->aop_att_id,  ;
         field->doc_op_des )

      IF !lOk
         EXIT
      ENDIF

      SELECT _doc_ops
      SKIP

   ENDDO

   RETURN lOk


// ----------------------------------------------------
// logiranje zatvaranje
// nDoc_no - dokument no
// cDesc - opis
// cAction - akcija
// ----------------------------------------------------
FUNCTION logiraj_zatvaranje_naloga( nDoc_no, cDesc, nDoc_status )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type
   LOCAL cAction := "+"
   LOCAL lOk := .T.
   LOCAL hParams

   DO CASE

   CASE nDoc_status == 1
      // closed
      cDoc_log_type := "99"
   CASE nDoc_status == 2
      // rejected
      cDoc_log_type := "97"
   CASE nDoc_status == 4
      // partialy done
      cDoc_log_type := "98"
   CASE nDoc_status == 5
      // closed but not delivered
      cDoc_log_type := "96"

   ENDCASE

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "doc_log", "doc_lit" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabelu !#Prekidam operaciju." )
      lOk := .F.
      RETURN lOk
   ENDIF

   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   IF lOk
      lOk := rnal_log_tip_99_insert( cAction, nDoc_no, nDoc_log_no, nDoc_status )
   ENDIF

   IF lOk
       hParams := hb_Hash()
       hParams[ "unlock" ] := { "doc_log", "doc_lit" }
       run_sql_query( "COMMIT", hParams )
   ELSE
       run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lOk



FUNCTION rnal_logiraj_promjenu_naloga( nDoc_no, cDesc )

   LOCAL nTArea := Select()
   LOCAL lOk := .T.

   IF cDesc == nil
      cDesc := ""
   ENDIF

   SELECT _docs
   SET FILTER TO
   SELECT _doc_it
   SET FILTER TO
   SELECT _doc_ops
   SET FILTER TO
   SELECT docs
   SET FILTER TO
   SELECT doc_ops
   SET FILTER TO
   SELECT doc_it
   SET FILTER TO

   lOk := logiraj_deltu_stavki_naloga( nDoc_no, cDesc )

   IF lOk
      lOk := logiraj_deltu_operacija_naloga( nDoc_no, cDesc )
   ENDIF

   SELECT ( nTArea )

   RETURN lOk


// -------------------------------------------------
// function _doc_it_delta() - delta stavki dokumenta
// nDoc_no - broj naloga
// funkcija gleda _doc_it na osnovu doc_it i trazi
// 1. stavke koje nisu iste
// 2. stavke koje su izbrisane
// -------------------------------------------------
STATIC FUNCTION logiraj_deltu_stavki_naloga( nDoc_no, cDesc )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type := "20"
   LOCAL cAction
   LOCAL lLogAppend := .F.
   LOCAL lOk := .T.

   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      nDoc_it_no := field->doc_it_no
      nArt_id := field->art_id
      nDoc_it_qtty := field->doc_it_qtt
      nDoc_it_heigh := field->doc_it_hei
      nDoc_it_width := field->doc_it_wid
      cDoc_it_desc := field->doc_it_des
      cDoc_it_sch := field->doc_it_sch

      // DOC_IT -> _DOC_IT - provjeri da li je sta brisano
      // akcija "-"

      IF !item_exist( nDoc_no, nDoc_it_no, nArt_id, .F. )

         cAction := "-"

         lOk := rnal_log_tip_20_insert( cAction, nDoc_no, nDoc_log_no, ;
            nArt_id, ;
            cDoc_it_desc, ;
            cDoc_it_sch, ;
            nDoc_it_qtty, ;
            nDoc_it_heigh, ;
            nDoc_it_width )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

         SELECT doc_it

         SKIP
         LOOP

      ENDIF

      // DOC_IT -> _DOC_IT - da li je sta mjenjano od podataka
      // akcija "E"

      IF !item_value( nDoc_no, nDoc_it_no, nArt_id, ;
            nDoc_it_qtty, ;
            nDoc_it_heigh, ;
            nDoc_it_width, .F. )

         cAction := "E"

         lOk := rnal_log_tip_20_insert( cAction, nDoc_no, nDoc_log_no, ;
            _doc_it->art_id, ;
            _doc_it->doc_it_des, ;
            _doc_it->doc_it_sch, ;
            _doc_it->doc_it_qtt, ;
            _doc_it->doc_it_hei, ;
            _doc_it->doc_it_wid )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

      ENDIF

      SELECT doc_it

      SKIP

   ENDDO

   IF !lOk
      RETURN lOk
   ENDIF

   // pozicioniraj se na _DOC_IT
   SELECT _doc_it
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      nDoc_it_no := field->doc_it_no
      nArt_id := field->art_id
      nDoc_it_qtty := field->doc_it_qtt
      nDoc_it_heigh := field->doc_it_hei
      nDoc_it_width := field->doc_it_wid
      cDoc_it_desc := field->doc_it_des
      cDoc_it_sch := field->doc_it_sch

      // _DOC_IT -> DOC_IT, da li stavka postoji u kumulativu
      // akcija "+"

      IF !item_exist( nDoc_no, nDoc_it_no, nArt_id, .T. )

         cAction := "+"

         lOk := rnal_log_tip_20_insert( cAction, nDoc_no, nDoc_log_no, ;
            nArt_id, ;
            cDoc_it_desc, ;
            cDoc_it_sch, ;
            nDoc_it_qtty, ;
            nDoc_it_heigh, ;
            nDoc_it_width )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

      ENDIF

      SELECT _doc_it

      SKIP

   ENDDO

   IF lOk .AND. lLogAppend
      lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   ENDIF

   RETURN lOk



// -------------------------------------------------
// function _doc_op_delta() - delta d.operacija
// nDoc_no - broj naloga
// funkcija gleda _doc_ops na osnovu doc_ops i trazi
// 1. stavke koje nisu iste
// 2. stavke koje su izbrisane
// -------------------------------------------------
STATIC FUNCTION logiraj_deltu_operacija_naloga( nDoc_no, cDesc )

   LOCAL nDoc_log_no
   LOCAL cDoc_log_type := "30"
   LOCAL cAction
   LOCAL lLogAppend := .F.
   LOCAL lOk := .T.

   nDoc_log_no := rnal_novi_broj_loga( nDoc_no )

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      nDoc_it_no := field->doc_it_no
      nDoc_op_no := field->doc_op_no

      nAop_id := field->aop_id
      nAop_att_id := field->aop_att_id
      cDoc_op_desc := field->doc_op_des

      // DOC_OPS -> _DOC_OPS - provjeri da li je sta brisano
      // akcija "-"

      IF !aop_exist( nDoc_no, nDoc_it_no, nDoc_op_no, nAop_id, nAop_att_id, .F. )

         cAction := "-"

         lOk := rnal_log_tip_30_insert( cAction, nDoc_no, nDoc_log_no, ;
            nAop_id, ;
            nAop_att_id, ;
            cDoc_op_desc )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

         SELECT doc_ops

         SKIP
         LOOP

      ENDIF

      // DOC_OPS -> _DOC_OPS - da li je sta mjenjano od podataka
      // akcija "E"

      IF !aop_value( nDoc_no, nDoc_it_no, nDoc_op_no, nAop_id, ;
            nAop_att_id, ;
            cDoc_op_desc, .F. )

         cAction := "E"

         lOk := rnal_log_tip_30_insert( cAction, nDoc_no, nDoc_log_no, ;
            _doc_ops->aop_id, ;
            _doc_ops->aop_att_id, ;
            _doc_ops->doc_op_des )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

      ENDIF

      SELECT doc_ops

      SKIP

   ENDDO

   IF !lOk
      RETURN lOk
   ENDIF

   // pozicioniraj se na _DOC_IT
   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. field->doc_no == nDoc_no

      nDoc_it_no := field->doc_it_no
      nDoc_op_no := field->doc_op_no
      nAop_id := field->aop_id
      nAop_att_id := field->aop_att_id
      cDoc_op_desc := field->doc_op_des

      // _DOC_OPS -> DOC_OPS, da li stavka postoji u kumulativu
      // akcija "+"

      IF !aop_exist( nDoc_no, nDoc_it_no, nDoc_op_no, nAop_id, nAop_att_id, .T. )

         cAction := "+"

         lOk := rnal_log_tip_30_insert( cAction, nDoc_no, nDoc_log_no, ;
            nAop_id, ;
            nAop_att_id, ;
            cDoc_op_desc )

         IF !lOk
            EXIT
         ENDIF

         lLogAppend := .T.

      ENDIF

      SELECT _doc_ops

      SKIP

   ENDDO

   IF lOk .AND. lLogAppend
      lOk := rnal_log_insert( nDoc_no, nDoc_log_no, cDoc_log_type, cDesc )
   ENDIF

   RETURN lOk



// --------------------------------------
// da li postoji item u tabelama
// _DOC_IT, DOC_IT
// --------------------------------------
STATIC FUNCTION item_exist( nDoc_no, nDoc_it_no, nArt_id, lKumul )

   LOCAL nF_DOC_IT := F__DOC_IT
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL lRet := .F.

   IF ( lKumul == nil )
      lKumul := .F.
   ENDIF

   IF ( lKumul == .T. )
      nF_DOC_IT := F_DOC_IT
   ENDIF

   SELECT ( nF_DOC_IT )
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no ) + artid_str( nArt_id )

   IF Found()
      lRet := .T.
   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN lRet



// --------------------------------------
// da li je stavka sirovina ista....
// --------------------------------------
STATIC FUNCTION item_value( nDoc_no, nDoc_it_no, nArt_id, ;
      nDoc_it_qtty, nDoc_it_heigh, nDoc_it_width, lKumul )

   LOCAL nF_DOC_IT := F__DOC_IT
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL lRet := .F.

   IF ( lKumul == nil )
      lKumul := .F.
   ENDIF

   IF ( lKumul == .T. )
      nF_DOC_IT := F_DOC_IT
   ENDIF

   SELECT ( nF_DOC_IT )
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no ) + docit_str( nDoc_it_no ) + artid_str( nArt_id )

   IF ( field->doc_it_qtt == nDoc_it_qtty ) .AND. ;
         ( field->doc_it_hei == nDoc_it_heigh ) .AND. ;
         ( field->doc_it_wid == nDoc_it_width )
      lRet := .T.
   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN lRet



// --------------------------------------
// da li postoji item u tabelama
// _DOC_OPS, DOC_OPS
// --------------------------------------
STATIC FUNCTION aop_exist( nDoc_no, nDoc_it_no, nDoc_op_no, ;
      nAop_id, nAop_att_id, lKumul )

   LOCAL nF_DOC_OPS := F__DOC_OPS
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL lRet := .F.

   IF ( lKumul == nil )
      lKumul := .F.
   ENDIF

   IF ( lKumul == .T. )
      nF_DOC_OPS := F_DOC_OPS
   ENDIF

   SELECT ( nF_DOC_OPS )
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no ) + ;
      docit_str( nDoc_it_no ) + ;
      docop_str( nDoc_op_no ) + ;
      aopid_str( nAop_id ) + ;
      aopid_str( nAop_att_id )

   IF Found()
      lRet := .T.
   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN lRet



// --------------------------------------
// da li je stavka operacije ista....
// --------------------------------------
STATIC FUNCTION aop_value( nDoc_no, nDoc_it_no, nDoc_op_no, nAop_id, ;
      nAop_att_id, nDoc_op_desc, lKumul )

   LOCAL nF_DOC_OPS := F__DOC_OPS
   LOCAL nTArea := Select()
   LOCAL nTRec := RecNo()
   LOCAL lRet := .F.

   IF ( lKumul == nil )
      lKumul := .F.
   ENDIF

   IF ( lKumul == .T. )
      nF_DOC_OPS := F_DOC_OPS
   ENDIF

   SELECT ( nF_DOC_OPS )
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no ) + ;
      docit_str( nDoc_it_no ) + ;
      docop_str( nDoc_op_no )

   IF ( field->aop_id == nAop_id ) .AND. ;
         ( field->aop_att_id == nAop_att_id ) .AND. ;
         ( field->doc_op_des == nDoc_op_desc )
      lRet := .T.
   ENDIF

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN lRet
