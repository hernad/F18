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


FUNCTION kalk_povrat_dokumenta()

   LOCAL lBrisiKumulativ
   LOCAL hRec
   LOCAL _id_firma
   LOCAL _id_vd
   LOCAL _br_dok
   LOCAL _del_rec
   LOCAL nTrec
   LOCAL _hAttrId, oAttr
   LOCAL lOk := .T.
   LOCAL hParams

/*
   IF dozvoljeno_azuriranje_sumnjivih_stavki() .AND. Pitanje(, "Zadati broj (D) / Povrat po hronologiji obrade (N) ?", "D" ) = "N"
      Beep( 1 )
      povrat_najnovije_kalkulacije()
      my_close_all_dbf()
      RETURN .F.
   ENDIF
*/

   o_kalk_pripr()

   _id_firma := self_organizacija_id()
   _id_vd := Space( 2 )
   _br_dok := Space( 8 )

   Box( "", 1, 35 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"
   @ box_x_koord() + 1, Col() + 1 SAY _id_firma

   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _id_vd PICT "@!"
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET _br_dok VALID {|| _br_dok := kalk_fix_brdok( _br_dok ), .T. }
   READ
   ESC_BCR
   BoxC()

   IF _br_dok = "."
      kalk_povrat_prema_kriteriju()
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF !kalk_dokument_postoji( _id_firma, _id_vd, _br_dok )
      MsgBeep( "Traženi dokument ne postoji na serveru !"  )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF Pitanje( "", "Kalk. " + _id_firma + "-" + _id_vd + "-" + _br_dok + " vratiti u pripremu (D/N) ?", "D" ) == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   lBrisiKumulativ := Pitanje(, "Izbrisati dokument iz kumulativne tabele (D/N) ?", "D" ) == "D"

   kalk_kopiraj_dokument_u_tabelu_pripreme( _id_firma, _id_vd, _br_dok )

   _hAttrId := hb_Hash()
   _hAttrId[ "idfirma" ] := _id_firma
   _hAttrId[ "idtipdok" ] := _id_vd
   _hAttrId[ "brdok" ] := _br_dok

   oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
   oAttr:hAttrId := _hAttrId
   oAttr:get_attr_from_server_to_dbf()

   IF lBrisiKumulativ

      run_sql_query( "BEGIN" )

      IF !f18_lock_tables( { "kalk_doks", "kalk_kalk" }, .T. )
         run_sql_query( "COMMIT" )
         MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju povrata." )
         RETURN .F.
      ENDIF

      o_kalk_za_azuriranje()

      MsgO( "Brisanje KALK dokumenata iz kumulativa ..." )
      find_kalk_by_broj_dokumenta( _id_firma, _id_vd, _br_dok )

      IF Found()
         _del_rec := dbf_get_rec()
         lOk := oAttr:delete_attr_from_server()
      ENDIF

      IF lOk
         lOk := brisi_dokument_iz_tabele_kalk( _id_firma, _id_vd, _br_dok )
      ENDIF

      IF lOk
         lOk := brisi_dokument_iz_tabele_doks( _id_firma, _id_vd, _br_dok )
      ENDIF

      //IF lOk
      //   lOk := brisi_dokument_iz_tabele_doks2( _id_firma, _id_vd, _br_dok )
      //ENDIF

      MsgC()

      IF lOk

         hParams := hb_Hash()
         hParams[ "unlock" ] :=  { "kalk_doks", "kalk_kalk" }
         run_sql_query( "COMMIT", hParams )
         log_write( "F18_DOK_OPER: KALK DOK_POV: " + _id_firma + "-" + _id_vd + "-" + AllTrim( _br_dok ), 2 )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Operacija povrata dokumenta u pripremu neuspješna !" )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION brisi_dokument_iz_tabele_doks( cIdFirma, cIdVd, cBrDok )

   LOCAL lOk := .T.
   LOCAL hRec

   IF find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
      hRec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( "kalk_doks", hRec, 1, "CONT" )
   ENDIF

   RETURN lOk



//STATIC FUNCTION brisi_dokument_iz_tabele_doks2( cIdFirma, cIdVd, cBrDok )
//
//   LOCAL lOk := .T.
//   LOCAL hRec
//
//   IF find_kalk_doks2_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
//      hRec := dbf_get_rec()
//      lOk := delete_rec_server_and_dbf( "kalk_doks2", hRec, 1, "CONT" )
//   ENDIF
//
//   RETURN lOk


STATIC FUNCTION brisi_dokument_iz_tabele_kalk( cIdFirma, cIdVd, cBrDok )

   LOCAL lOk := .T.
   LOCAL hRec

   IF find_kalk_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
      hRec := dbf_get_rec()
      lOk := delete_rec_server_and_dbf( "kalk_kalk", hRec, 2, "CONT" )
   ENDIF

   RETURN lOk


STATIC FUNCTION kalk_kopiraj_dokument_u_tabelu_pripreme( cFirma, cIdVd, cBroj )

   LOCAL hRec

   find_kalk_by_broj_dokumenta( cFirma, cIdVd, cBroj )

   MsgO( "Prebacujem dokument u pripremu ..." )

   DO WHILE !Eof() .AND. cFirma == field->IdFirma .AND. cIdVd == field->IdVD .AND. cBroj == field->BrDok

      SELECT kalk
      hRec := dbf_get_rec()
      SELECT kalk_pripr

      IF ! ( hRec[ "idvd" ] $ "97" .AND. hRec[ "tbanktr" ] == "X" )
         APPEND ncnl
         hRec[ "error" ] := ""
         dbf_update_rec( hRec )
      ENDIF

      SELECT kalk
      SKIP

   ENDDO

   MsgC()

   RETURN .T.



STATIC FUNCTION kalk_povrat_prema_kriteriju()

   LOCAL _br_dok := Space( 80 )
   LOCAL _dat_dok := Space( 80 )
   LOCAL _id_vd := Space( 80 )
   LOCAL _usl_br_dok
   LOCAL _usl_dat_dok
   LOCAL _usl_id_vd
   LOCAL lBrisiKumulativ := .F.
   LOCAL _filter
   LOCAL _id_firma := self_organizacija_id()
   LOCAL hRec
   LOCAL _del_rec
   LOCAL _hAttrId, oAttr, __firma, __idvd, __brdok
   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hParams
   LOCAL nTrec

   IF !spec_funkcije_sifra()
      my_close_all_dbf()
      RETURN lRet
   ENDIF

   Box(, 3, 60 )

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Vrste kalk.    " GET _id_vd PICT "@S40"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj dokumenata" GET _br_dok PICT "@S40"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datumi         " GET _dat_dok PICT "@S40"
      READ
      _usl_br_dok := Parsiraj( _br_dok, "BrDok", "C" )
      _usl_dat_dok := Parsiraj( _dat_dok, "DatDok", "D" )
      _usl_id_vd := Parsiraj( _id_vd, "IdVD", "C" )
      IF _usl_br_dok <> NIL .AND. _usl_dat_dok <> NIL .AND. _usl_id_vd <> NIL
         EXIT
      ENDIF
   ENDDO

   Boxc()

   IF Pitanje(, "Vratiti u pripremu kalk dokumente sa ovim kriterijom (D/N) ?", "N" ) == "D"

      lBrisiKumulativ := Pitanje(, "Izbrisati dokument iz kumulativne tabele (D/N) ?", "D" ) == "D"

      SELECT kalk

      _filter := "IDFIRMA==" + dbf_quote( _id_firma ) + ".and." + _usl_br_dok + ".and." + _usl_id_vd + ".and." + _usl_dat_dok
      _filter := StrTran( _filter, ".t..and.", "" )

      IF !( _filter == ".t." )
         SET FILTER TO &( _filter )
      ENDIF

      SELECT kalk
      GO TOP

      MsgO( "Prolaz kroz kumulativnu datoteku KALK..." )

      DO WHILE !Eof()

         SELECT kalk

         __firma := field->idfirma
         __idvd := field->idvd
         __brdok := field->brdok

         hRec := dbf_get_rec()

         SELECT kalk_pripr
         IF ! ( hRec[ "idvd" ] $ "97" .AND. hRec[ "tbanktr" ] == "X" )

            APPEND ncnl
            hRec[ "error" ] := ""
            dbf_update_rec( hRec )

            _hAttrId := hb_Hash()
            _hAttrId[ "idfirma" ] := __firma
            _hAttrId[ "idtipdok" ] := __idvd
            _hAttrId[ "brdok" ] := __brdok

            oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
            oAttr:hAttrId := _hAttrId
            oAttr:get_attr_from_server_to_dbf()

         ENDIF

         SELECT kalk
         SKIP

      ENDDO

      MsgC()

      SELECT kalk
      SET ORDER TO TAG "1"
      GO TOP

      IF !lBrisiKumulativ
         my_close_all_dbf()
         RETURN lRet
      ENDIF

      MsgO( "Brišem tabele sa servera ..." )

      run_sql_query( "BEGIN" )

      IF !f18_lock_tables( { "kalk_doks", "kalk_kalk" }, .T. )
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Ne mogu zaključati tabele !#Prekidam proceduru povrata." )
         RETURN lRet
      ENDIF

      DO WHILE !Eof()

         _id_firma := field->idfirma
         _id_vd := field->idvd
         _br_dok := field->brdok
         _del_rec := dbf_get_rec()

         DO WHILE !Eof() .AND. field->idfirma == _id_firma .AND. field->idvd == _id_vd .AND. field->brdok == _br_dok
            SKIP
         ENDDO

         nTrec := RecNo()
         _ok := .T.

         _hAttrId := hb_Hash()
         _hAttrId[ "idfirma" ] := _id_firma
         _hAttrId[ "idtipdok" ] := _id_vd
         _hAttrId[ "brdok" ] := _br_dok

         oAttr := DokAttr():new( "kalk", F_KALK_ATTR )
         oAttr:hAttrId := _hAttrId

         lOk := oAttr:delete_attr_from_server()

         IF lOk
            lOk := delete_rec_server_and_dbf( "kalk_kalk", _del_rec, 2, "CONT" )
         ENDIF

         IF lOk
            SELECT kalk_doks
            GO TOP
            SEEK _id_firma + _id_vd + _br_dok

            IF Found()
               log_write( "F18_DOK_OPER: kalk brisanje vise dokumenata: " + _id_firma + _id_vd + _br_dok, 2 )
               _del_rec := dbf_get_rec()
               lOk :=  delete_rec_server_and_dbf( "kalk_doks", _del_rec, 1, "CONT" )
            ENDIF
         ENDIF

         IF !lOk
            EXIT
         ENDIF

         SELECT kalk
         GO ( nTrec )

      ENDDO

      MsgC()

      IF lOk
         lRet := .T.
         hParams := hb_Hash()
         hParams[ "unlock" ] := { "kalk_doks", "kalk_kalk" }
         run_sql_query( "COMMIT", hParams )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Problem sa brisanjem podataka iz KALK server tabela !" )
      ENDIF


   ENDIF

   my_close_all_dbf()

   RETURN lRet
