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
STATIC __doc_stat
STATIC __doc_desc

FUNCTION rnal_azuriraj_dokument( cDesc )

   LOCAL _ok := .T.
   LOCAL lDokumentPostoji := .F.
   LOCAL hParams

   IF cDesc == nil
      cDesc := ""
   ENDIF

   rnal_o_tables( .T. )

   rnal_ukloni_filter_lokalnih_tabela()

   SELECT _docs
   GO TOP

   IF RECCOUNT2() == 0
      MsgBeep( "U pripremi nema stavki za ažuriranje." )
      RETURN 0
   ENDIF

   IF !_provjeri_prije_azuriranja()
      MsgBeep( "Redni brojevi u nalogu nisu ispravni, provjeriti !" )
      RETURN 0
   ENDIF

   SELECT _docs
   GO TOP

   __doc_desc := cDesc
   __doc_no := _docs->doc_no
   __doc_stat := _docs->doc_status

   lDokumentPostoji := rnal_dokument_postoji( __doc_no )

   IF __doc_stat < 3 .AND. !lDokumentPostoji

      MsgBeep( "Nalog " + AllTrim( Str( __doc_no ) ) + " nije moguce ažurirati !#Status dokumenta = " + AllTrim( Str( __doc_stat ) ) )
      resetuj_broj_naloga_na_0_u_pripremi()
      MsgBeep( "Ponovite operaciju štampe i ažuriranja naloga !" )

      RETURN 0

   ELSEIF __doc_stat == 10 .AND. lDokumentPostoji

      MsgBeep( "Nalog " + AllTrim( Str( __doc_no ) ) + " nije moguće ažurirati !#Već postoji ažuriran." )
      resetuj_broj_naloga_na_0_u_pripremi()

      RETURN 0

   ENDIF

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "docs", "doc_it", "doc_it2", "doc_ops" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele !?# Prekid operacije ažuriranja" )
      RETURN 0
   ENDIF

   MsgO( "Ažuriranje naloga u toku..." )

   Beep( 1 )

   IF __doc_stat == 3

      _ok := rnal_logiraj_promjenu_naloga( __doc_no, __doc_desc )

      doc_erase( __doc_no )

      O_DOCS

   ENDIF

   IF _ok
      _ok := _docs_insert( __doc_no )
   ENDIF

   IF _ok
      _ok := _doc_it_insert( __doc_no )
   ENDIF

   IF _ok
      _ok := _doc_it2_insert( __doc_no )
   ENDIF

   IF _ok
      _ok := _doc_op_insert( __doc_no )
   ENDIF

   IF _ok

      set_doc_marker( __doc_no, 0, "CONT" ) // setuj da je nalog opet otvoren

      // ako nije bio u doradi logiraj promjene inicijalne
      IF __doc_stat <> 3
         _ok := rnal_logiraj_novi_nalog( __doc_no )
      ENDIF

      __doc_stat := 0

   ENDIF

   IF _ok

      hParams := hb_Hash()
      hParams[ "unlock" ] := { "docs", "doc_it", "doc_it2", "doc_ops" }
      run_sql_query( "COMMIT", hParams )

      log_write( "F18_DOK_OPER: rnal, azuriranje dokumenta broj: " + AllTrim( Str( __doc_no ) ) + ;
         ", status: " + AllTrim( Str( __doc_stat ) ), 2 )

   ELSE

      run_sql_query( "ROLLBACK" )
      MsgC()
      doc_erase( __doc_no )
      beep( 3 )
      rnal_o_tables( .T. )
      MsgBeep( "Ažuriranje naloga nje uspješno izvršeno !" )

      RETURN 0

   ENDIF

   brisi_tabele_pripreme()
   Beep( 1 )
   rnal_o_tables( .T. )
   MsgC()

   RETURN 1



STATIC FUNCTION brisi_tabele_pripreme()

   SELECT _docs
   my_dbf_zap()

   SELECT _doc_it
   my_dbf_zap()

   SELECT _doc_it2
   my_dbf_zap()

   SELECT _doc_ops
   my_dbf_zap()

   RETURN .T.



/*
   Opis: resetuje broj naloga na 0 u tabelama pripreme
*/

STATIC FUNCTION resetuj_broj_naloga_na_0_u_pripremi()

   SELECT _docs

   rnal_set_broj_naloga_u_pripremi( 0, .T. )

   SELECT _docs
   GO TOP

   RETURN .T.



FUNCTION rnal_ukloni_filter_lokalnih_tabela()

   SELECT _docs
   SET FILTER TO

   SELECT _doc_it
   SET FILTER TO

   SELECT _doc_it2
   SET FILTER TO

   SELECT _doc_ops
   SET FILTER TO

   RETURN .T.


// --------------------------------------------------
// provjera prije azuriranja dokumenta...
// --------------------------------------------------
STATIC FUNCTION _provjeri_prije_azuriranja()

   LOCAL _ok := .T.
   LOCAL nDbfArea := Select()
   LOCAL _tmp

   SELECT _doc_it
   GO TOP

   DO WHILE !Eof()

      _tmp := field->doc_it_no
      SKIP 1

      IF _tmp == field->doc_it_no
         GO TOP
         SELECT ( nDbfArea )
         _ok := .F.
         RETURN _ok
      ENDIF

   ENDDO

   GO TOP

   SELECT ( nDbfArea )

   RETURN _ok



// --------------------------------------------------
// azuriranje DOCS
// --------------------------------------------------
STATIC FUNCTION _docs_insert( nDoc_no )

   LOCAL _rec
   LOCAL _ok := .T.
   LOCAL lNovi := .F.

   SELECT _docs
   SET ORDER TO TAG "1"
   GO TOP

   _rec := dbf_get_rec()

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF !Found()
      APPEND BLANK
      lNovi := .T.
   ENDIF

   _ok := update_rec_server_and_dbf( "rnal_docs", _rec, 1, "CONT" )

   IF !_ok .AND. lNovi
      delete_with_rlock()
   ENDIF

   SET ORDER TO TAG "1"

   RETURN _ok


// ------------------------------------------
// azuriranje tabele _DOC_IT
// ------------------------------------------
STATIC FUNCTION _doc_it_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.
   LOCAL lNovi := .F.

   SELECT _doc_it

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      _rec := dbf_get_rec()

      SELECT doc_it

      APPEND BLANK

      _ok := update_rec_server_and_dbf( "rnal_doc_it", _rec, 1, "CONT" )

      IF !_ok
         delete_with_rlock()
      ENDIF

      SELECT _doc_it

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok

// ------------------------------------------
// azuriranje tabele _DOC_IT2
// ------------------------------------------
STATIC FUNCTION _doc_it2_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.

   SELECT _doc_it2

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      _rec := dbf_get_rec()

      SELECT doc_it2

      APPEND BLANK

      _ok := update_rec_server_and_dbf( "rnal_doc_it2", _rec, 1, "CONT" )

      IF !_ok
         delete_with_rlock()
      ENDIF

      SELECT _doc_it2

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok





// ------------------------------------------
// azuriranje tabele _DOC_OP
// ------------------------------------------
STATIC FUNCTION _doc_op_insert( nDoc_no )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL _ok := .T.

   SELECT _doc_ops

   IF RECCOUNT2() == 0
      RETURN _ok
   ENDIF

   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

      IF field->aop_id + field->aop_att_id <> 0

         _rec := dbf_get_rec()

         SELECT doc_ops
         APPEND BLANK

         _ok := update_rec_server_and_dbf( "rnal_doc_ops", _rec, 1, "CONT" )

      ENDIF

      IF !_ok
         delete_with_rlock()
      ENDIF

      SELECT _doc_ops

      IF !_ok
         RETURN _ok
      ENDIF

      SKIP

   ENDDO

   RETURN _ok



// -------------------------------------------
// procedura povrata dokumenta u pripremu...
// -------------------------------------------
FUNCTION doc_2__doc( nDoc_no )

   rnal_o_tables( .T. )

   rnal_ukloni_filter_lokalnih_tabela()

   IF !rnal_dokument_postoji( nDoc_no )
      MsgBeep( "Nalog " + AllTrim( Str( nDoc_no ) ) + " ne postoji !!!" )
   ENDIF

   SELECT _docs

   IF RECCOUNT2() > 0
      MsgBeep( "U pripremi već postoji dokument#ne može se izvršiti povrat#operacija prekinuta !" )
      RETURN 0
   ENDIF

   MsgO( "Vršim povrat dokumenta u pripremu ..." )

   // markiraj da je dokument busy
   set_doc_marker( nDoc_no, 3 )

   _docs_erase( nDoc_no )
   _doc_it_erase( nDoc_no )
   _doc_it2_erase( nDoc_no )
   _doc_op_erase( nDoc_no )

   SELECT docs
   USE

   rnal_o_tables( .T. )

   MsgC()

   RETURN 1


// ----------------------------------------
// markiranje statusa dokumenta busy
// nDoc_no - dokument broj
// nMarker - 0, 1, 2, 3, 4, 5
// ----------------------------------------
FUNCTION set_doc_marker( nDoc_no, nMarker, cont )

   LOCAL _rec, _id_fields, _where_bl
   LOCAL nTArea

   nTArea := Select()

   IF cont == NIL
      cont := "FULL"
   ENDIF

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()

      _rec := dbf_get_rec()
      _rec[ "doc_status" ] := nMarker

      update_rec_server_and_dbf( "docs", _rec, 1, cont )

   ENDIF

   SELECT ( nTArea )

   RETURN



// ------------------------------------
// provjerava da li je dokument zauzet
// ------------------------------------
FUNCTION is_doc_busy()

   LOCAL lRet := .F.

   IF field->doc_status == 3
      lRet := .T.
   ENDIF

   RETURN lRet


// -------------------------------------
// provjerava da li je dokument rejected
// -------------------------------------
FUNCTION is_doc_rejected()

   LOCAL lRet := .F.

   IF field->doc_status == 2
      lRet := .T.
   ENDIF

   RETURN lRet



// ----------------------------------------------
// povrat dokumenta iz tabele DOCS
// ----------------------------------------------
STATIC FUNCTION _docs_erase( nDoc_no )

   LOCAL _rec

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()

      SELECT docs

      _rec := dbf_get_rec()

      SELECT _docs

      APPEND BLANK

      dbf_update_rec( _rec )

   ENDIF

   SELECT docs

   RETURN


// ----------------------------------------------
// povrat tabele DOC_IT
// ----------------------------------------------
STATIC FUNCTION _doc_it_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_it

         _rec := dbf_get_rec()

         SELECT _doc_it

         APPEND BLANK

         dbf_update_rec( _rec )

         SELECT doc_it

         SKIP
      ENDDO
   ENDIF

   SELECT doc_it

   RETURN


// ----------------------------------------------
// povrat tabele DOC_IT2
// ----------------------------------------------
STATIC FUNCTION _doc_it2_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_it2

         _rec := dbf_get_rec()

         SELECT _doc_it2

         APPEND BLANK

         dbf_update_rec( _rec )

         SELECT doc_it2

         SKIP
      ENDDO
   ENDIF

   SELECT doc_it2

   RETURN


// ----------------------------------------------
// povrat tabele DOC_OP
// ----------------------------------------------
STATIC FUNCTION _doc_op_erase( nDoc_no )

   LOCAL _rec

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nDoc_no )

   IF Found()

      DO WHILE !Eof() .AND. ( field->doc_no == nDoc_no )

         SELECT doc_ops
         _rec := dbf_get_rec()

         SELECT _doc_ops
         APPEND BLANK
         dbf_update_rec( _rec )

         SELECT doc_ops

         SKIP
      ENDDO

   ENDIF

   SELECT doc_ops

   RETURN



// -----------------------------------------------
// brisi sve vezano za dokument iz kumulativa
// -----------------------------------------------
STATIC FUNCTION doc_erase( nDoc_no )

   LOCAL _del_rec

   SELECT docs
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "docs", _del_rec, 1, "CONT" )
   ENDIF

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_it", _del_rec, 2, "CONT" )
   ENDIF

   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_it2", _del_rec, 2, "CONT" )
   ENDIF

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   SEEK docno_str( nDoc_no )

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "doc_ops", _del_rec, 2, "CONT" )
   ENDIF

   RETURN 1



/*
   Opis: provjerava postojanje dokumenta na serveru
*/

FUNCTION rnal_dokument_postoji( nDoc_no )

   LOCAL lExist := .F.
   LOCAL cWhere

   cWhere := "doc_no = " + AllTrim( Str( nDoc_no ) )

   IF table_count( F18_PSQL_SCHEMA_DOT + "rnal_docs", cWhere ) > 0
      lExist := .T.
   ENDIF

   RETURN lExist




/*
   Opis: puni tabele pripreme sa brojem naloga

   Usage: rnal_set_broj_naloga_u_pripremi( nDoc_no, lForce )
*/

FUNCTION rnal_set_broj_naloga_u_pripremi( nDoc_no, lForce )

   LOCAL nTRec
   LOCAL nTArea
   LOCAL nAPPRec
   LOCAL _rec

   IF lForce == nil
      lForce := .F.
   ENDIF

   IF ( nDoc_no == 0 .AND. lForce == .F. )
      RETURN .F.
   ENDIF

   nTArea := Select()
   nTRec := RecNo()

   SELECT _docs
   SET ORDER TO TAG "1"
   GO TOP

   _rec := dbf_get_rec()

   _rec[ "doc_no" ] := nDoc_no
   IF Empty( _rec[ "doc_time" ] )
      _rec[ "doc_time" ] := PadR( Time(), 5 )
   ENDIF

   dbf_update_rec( _rec )

   SELECT _doc_it
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   SELECT _doc_it2
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   SELECT _doc_ops
   SET ORDER TO TAG "1"
   GO TOP
   DO WHILE !Eof()

      SKIP
      nAPPRec := RecNo()
      SKIP -1

      _rec := dbf_get_rec()
      _rec[ "doc_no" ] := nDoc_no
      dbf_update_rec( _rec )

      GO ( nAPPRec )
   ENDDO

   SELECT ( nTArea )
   GO ( nTRec )

   RETURN .T.


// -----------------------------------------
// formira string za _doc_status - opened
// -----------------------------------------
STATIC FUNCTION dokument_otvoren()
   RETURN Str( 0, 2 )

// -----------------------------------------
// formira string za _doc_status - closed
// -----------------------------------------
STATIC FUNCTION dokument_zatvoren()
   RETURN Str( 1, 2 )

// -----------------------------------------
// formira string za _doc_status - rejected
// -----------------------------------------
STATIC FUNCTION dokument_odbacen()
   RETURN Str( 2, 2 )

// -----------------------------------------
// formira string za _doc_status - busy
// -----------------------------------------
STATIC FUNCTION dokument_zauzet()
   RETURN Str( 3, 2 )
