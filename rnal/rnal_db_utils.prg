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


FUNCTION m_adm()

   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. pregled artikala bez definisanih elemenata  " )
   AAdd( _opcexe, {|| rpt_artikli_bez_elemenata() } )
   AAdd( _opc, "2. FMK rules" )
   AAdd( _opcexe, {|| p_rules( , , , aRuleSpec, bRuleBlock ) } )

   f18_menu( "adm", .F., _izbor, _opc, _opcexe )

   RETURN .T.



// ------------------------------------------------
// otvori tabele potrebne za rad sa RNAL
// lTemporary - .t. i pripremne tabele
// ------------------------------------------------
FUNCTION rnal_o_tables( lTemporary )

   IF lTemporary == nil
      lTemporary := .F.
   ENDIF

   rnal_o_sif_tables()

   O_RULES

   O_DOCS
   O_DOC_IT
   O_DOC_IT2
   O_DOC_OPS

   IF lTemporary == .T.
      O__DOCS
      O__DOC_IT
      O__DOC_IT2
      O__DOC_OPS
   ENDIF

   RETURN .T.


FUNCTION rnal_o_sif_tables()

   O_E_GROUPS
   O_E_GR_ATT
   O_E_GR_VAL
   O_ARTICLES
   O_ELEMENTS
   O_E_AOPS
   O_E_ATT
   O_CUSTOMS
   O_CONTACTS
   O_OBJECTS
   O_AOPS
   O_AOPS_ATT
   O_RAL
  // o_sifk()
//   o_sifv()
//   o_roba()

   RETURN .T.



// -----------------------------
// otvori tabelu _TMP1
// -----------------------------
FUNCTION o_tmp1()

   SELECT ( F__TMP1 )
   USE
   my_use_temp( "_TMP1", my_home() + "_tmp1", .F., .T. )

   RETURN .T.



// -----------------------------
// otvori tabelu _TMP2
// -----------------------------
FUNCTION o_tmp2()

   SELECT ( F__TMP2 )
   USE
   my_use_temp( "_TMP2", my_home() + "_tmp2", .F., .T. )

   RETURN .T.


// -----------------------------------------
// konvert doc_no -> STR(doc_no, 10)
// -----------------------------------------
FUNCTION doc_str( nId )
   RETURN Str( nId, 10 )


// -----------------------------------------
// konvert doc_no -> STR(doc_no, 10)
// -----------------------------------------
FUNCTION docno_str( nId )
   RETURN Str( nId, 10 )


// -----------------------------------------
// konvert doc_op -> STR(doc_op, 4)
// -----------------------------------------
FUNCTION docop_str( nId )
   RETURN Str( nId, 4 )


// -----------------------------------------
// konvert doc_it -> STR(doc_it, 4)
// -----------------------------------------
FUNCTION docit_str( nId )
   RETURN Str( nId, 4 )


/*
  Opis: setuje novi zapis u tabeli i dodjeljuje novi ID po uslovnom polju

  Usage: setuj_novi_id_tabele( @nId, "EL_ID" )

    Parameters:
      - nId - vrijednost uvećanog polja
      - cIdField - polje tabele koje treba uvećati
      - lAuto - .T. dodaj novi zapis bez ispitivanja LastKey(), .F. - ispituj LastKey()
      - cont - tip transakcije "CONT" ili "FULL", funkcija se može pozvati unutar transakcije

    Primjer:

       SELECT elements
       nId := 0
       setuj_novi_id_tabele( @nId, "EL_ID", .T., "FULL" )

       kao rezultat dobijamo novi zapis u tabeli ELEMENTS sa uvećanim brojem polja EL_ID

*/

FUNCTION setuj_novi_id_tabele( nId, cIdField, lAuto, cont )

   LOCAL nTArea := Select()
   LOCAL nTime
   LOCAL cIndex
   LOCAL _rec
   PRIVATE GetList := {}

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF cIdField == "ART_ID"
      cIndex := "1"
   ELSE
      cIndex := "2"
   ENDIF

   IF cont == NIL
      cont := "CONT"
   ENDIF

   rnal_uvecaj_id( @nId, cIdField, cIndex, lAuto )

   set_global_memvars_from_dbf()

   APPEND BLANK

   cIdField := "_" + cIdField

   &cIdField := nId

   _rec := get_hash_record_from_global_vars( NIL, .F. )

   update_rec_server_and_dbf( Alias(), _rec, 1, cont )

   SELECT ( nTArea )

   RETURN 1



// ------------------------------------------
// kreiranje tabele my_home() + _TMP1
// ------------------------------------------
FUNCTION cre_tmp1( aFields )

   LOCAL cTbName := "_tmp1"

   IF Len( aFields ) == 0
      MsgBeep( "Nema definicije polja u matrici!" )
      RETURN
   ENDIF

   _del_tmp( my_home() + cTbName + ".dbf" )
   _del_tmp( my_home() + cTbName + ".cdx" )

   dbCreate( my_home() + cTbName + ".dbf", aFields )

   RETURN

// ------------------------------------------
// kreiranje tabele my_home() + _TMP1
// ------------------------------------------
FUNCTION cre_tmp2( aFields )

   LOCAL cTbName := "_tmp2"

   IF Len( aFields ) == 0
      MsgBeep( "Nema definicije polja u matrici!" )
      RETURN
   ENDIF

   _del_tmp( my_home() + cTbName + ".dbf" )
   _del_tmp( my_home() + cTbName + ".cdx" )

   dbCreate( my_home() + cTbName + ".dbf", aFields )

   RETURN



// --------------------------------------------
// brisanje fajla
// --------------------------------------------
STATIC FUNCTION _del_tmp( cPath )

   IF File( cPath )
      FErase( cPath )
   ENDIF

   RETURN


// ----------------------------------------------
// promjena broja naloga
// servisna opcija, zasticena password-om
// ----------------------------------------------
FUNCTION rnal_promjena_broja_naloga( old_doc )

   LOCAL _new_no := old_doc
   LOCAL lOk := .T.
   LOCAL hParams

   IF !spec_funkcije_sifra( "PRBRNO" )
      RETURN .F.
   ENDIF

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "setuj novi broj:" GET _new_no VALID _new_no <> old_doc
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   run_sql_query( "BEGIN" )

   IF !f18_lock_tables( { "docs", "doc_it", "doc_it2", "doc_ops" }, .T. )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele#Prekid opcije promjene broja naloga." )
      RETURN .F.
   ENDIF

   lOk := zamjeni_broj_u_docs( old_doc, _new_no )

   IF lOk
       lOk := zamjeni_broj_u_doc_it( old_doc, _new_no )
   ENDIF

   IF lOk
       lOk := zamjeni_broj_u_doc_it2( old_doc, _new_no )
   ENDIF

   IF lOk
       lOk := zamjeni_broj_u_doc_ops( old_doc, _new_no )
   ENDIF

   IF lOk
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "docs", "doc_it", "doc_it2", "doc_ops" }
      run_sql_query( "COMMIT", hParams )
   ELSE
      run_sql_query( "ROLLBACK" )
   ENDIF

   RETURN lOk




STATIC FUNCTION zamjeni_broj_u_docs( nStari, nNovi )

   LOCAL _rec
   LOCAL lOk := .T.

   _rec := dbf_get_rec()
   _rec[ "doc_no" ] := nNovi
   lOk := update_rec_server_and_dbf( "rnal_docs", _rec, 1, "CONT" )

   RETURN lOk



STATIC FUNCTION zamjeni_broj_u_doc_it( nStari, nNovi )

   LOCAL _rec
   LOCAL lOk := .T.

   SELECT doc_it
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nStari )

   IF Found()

      SET ORDER TO 0

      DO WHILE !Eof() .AND. field->doc_no == nStari
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := nNovi
         lOk := update_rec_server_and_dbf( "rnal_doc_it", _rec, 1, "CONT" )

         IF !lOk
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF

   RETURN lOk


STATIC FUNCTION zamjeni_broj_u_doc_it2( nStari, nNovi )

   LOCAL _rec
   LOCAL lOk := .T.

   SELECT doc_it2
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nStari )

   IF Found()

      SET ORDER TO 0

      DO WHILE !Eof() .AND. field->doc_no == nStari
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := nNovi
         lOk := update_rec_server_and_dbf( "rnal_doc_it2", _rec, 1, "CONT" )

         IF !lOk
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF

   RETURN lOk



STATIC FUNCTION zamjeni_broj_u_doc_ops( nStari, nNovi )

   LOCAL _rec
   LOCAL lOk := .T.

   SELECT doc_ops
   SET ORDER TO TAG "1"
   GO TOP

   SEEK docno_str( nStari )

   IF Found()

      SET ORDER TO 0

      DO WHILE !Eof() .AND. field->doc_no == nStari
         _rec := dbf_get_rec()
         _rec[ "doc_no" ] := nNovi
         lOk := update_rec_server_and_dbf( "rnal_doc_ops", _rec, 1, "CONT" )

         IF !lOk
            EXIT
         ENDIF

         SKIP

      ENDDO

   ENDIF

   RETURN lOk



// ------------------------------------------------------------
// resetuje brojač dokumenta ako smo pobrisali dokument
// ------------------------------------------------------------
FUNCTION rnal_reset_doc_no( doc_no )

   LOCAL _param
   LOCAL _broj := 0

   // param: rnal_doc_no
   _param := "rnal_doc_no"
   _broj := fetch_metric( _param, nil, _broj )

   IF doc_no == _broj
      -- _broj
      // smanji globalni brojac za 1
      set_metric( _param, nil, _broj )
   ENDIF

   RETURN



// ------------------------------------------------------------------
// rnal, uzimanje novog broja za rnal dokument
// ------------------------------------------------------------------
FUNCTION rnal_novi_broj_dokumenta()

   LOCAL _broj := 0
   LOCAL _broj_doks := 0
   LOCAL _param
   LOCAL _tmp, _rest
   LOCAL _ret := ""
   LOCAL nDbfArea := Select()


   _param := "rnal_doc_no" // param: rnal_doc_no

   _broj := fetch_metric( _param, nil, _broj )

   // konsultuj i doks uporedo
   O_DOCS
   SET ORDER TO TAG "1"
   GO TOP
   SEEK "X"
   SKIP -1

   _broj_doks := field->doc_no

   // uzmi sta je vece, doks broj ili globalni brojac
   _broj := Max( _broj, _broj_doks )

   // uvecaj broj
   ++ _broj

   // upisi ga u globalni parametar
   set_metric( _param, nil, _broj )

   SELECT ( nDbfArea )

   RETURN _broj





FUNCTION rnal_treba_setovati_broj_naloga( doc_no )

   LOCAL _null_brdok

   SELECT _docs
   GO TOP

   _null_brdok := 0

   IF field->doc_no <> _null_brdok
      // nemam sta raditi, broj je vec setovan
      RETURN .F.
   ENDIF


   doc_no := rnal_novi_broj_dokumenta() // novi broj dokumenta

   RETURN .T.



// ------------------------------------------------------------
// setovanje parametra brojaca na admin meniju
// ------------------------------------------------------------
FUNCTION rnal_set_param_broj_dokumenta()

   LOCAL _param
   LOCAL _broj := 0
   LOCAL _broj_old

   Box(, 2, 60 )

   // param: rnal_doc_no
   _param := "rnal_doc_no"
   _broj := fetch_metric( _param, nil, _broj )
   _broj_old := _broj

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Zadnji broj dokumenta:" GET _broj PICT "9999999999"

   READ

   BoxC()

   IF LastKey() != K_ESC
      // snimi broj u globalni brojac
      IF _broj <> _broj_old
         set_metric( _param, nil, _broj )
      ENDIF
   ENDIF

   RETURN
