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
   LOCAL cIdFirma
   LOCAL cIdVd
   LOCAL cBrDok
   LOCAL hRecDelete
   LOCAL nTrec
   LOCAL lOk := .T.
   LOCAL hParams
   LOCAL GetList := {}

   o_kalk_pripr()
   cIdFirma := self_organizacija_id()
   cIdVd := Space( 2 )
   cBrDok := Space( 8 )

   Box( "", 1, 35 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Dokument:"
   @ box_x_koord() + 1, Col() + 1 SAY cIdFirma

   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVd PICT "@!"
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrDok VALID {|| cBrDok := kalk_fix_brdok( cBrDok ), .T. }
   READ
   ESC_BCR
   BoxC()

   IF cBrDok = "."
      // kalk_povrat_prema_kriteriju()
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF !kalk_dokument_postoji( cIdFirma, cIdVd, cBrDok )
      MsgBeep( "Traženi dokument ne postoji na serveru !"  )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   IF Pitanje( "", "Kalk. " + cIdFirma + "-" + cIdVd + "-" + cBrDok + " vratiti u pripremu (D/N) ?", "D" ) == "N"
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   lBrisiKumulativ := Pitanje(, "Izbrisati dokument iz kumulativne tabele (D/N) ?", "D" ) == "D"
   kalk_kopiraj_dokument_u_tabelu_pripreme( cIdFirma, cIdVd, cBrDok )
   IF lBrisiKumulativ

      run_sql_query( "BEGIN" )
      // IF !f18_lock_tables( { "kalk_doks", "kalk_kalk" }, .T. )
      // run_sql_query( "COMMIT" )
      // MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju povrata." )
      // RETURN .F.
      // ENDIF

      o_kalk_za_azuriranje()
      MsgO( "Brisanje KALK dokumenata iz kumulativa ..." )
      find_kalk_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )

      IF Found()
         hRecDelete := dbf_get_rec()
      ENDIF
      IF lOk
         lOk := brisi_dokument_iz_tabele_kalk( cIdFirma, cIdVd, cBrDok )
      ENDIF
      IF lOk
         lOk := brisi_dokument_iz_tabele_doks( cIdFirma, cIdVd, cBrDok )
      ENDIF
      MsgC()

      IF lOk
         hParams := hb_Hash()
         // hParams[ "unlock" ] :=  { "kalk_doks", "kalk_kalk" }
         run_sql_query( "COMMIT", hParams )
         log_write( "F18_DOK_OPER: KALK DOK_POV: " + cIdFirma + "-" + cIdVd + "-" + AllTrim( cBrDok ), 2 )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Operacija povrata dokumenta u pripremu neuspješna !" )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN .T.


FUNCTION kalk_povrat_dokumenta_by_idfirma_idvd_brdok( cIdFirma, cIdVd, cBrDok )

   LOCAL lBrisiKumulativ
   LOCAL hRec
   LOCAL hRecDelete
   LOCAL nTrec
   LOCAL lOk := .T.
   LOCAL hParams
   LOCAL GetList := {}

   o_kalk_pripr()
   IF !kalk_dokument_postoji( cIdFirma, cIdVd, cBrDok )
      MsgBeep( "Traženi dokument ne postoji na serveru !"  )
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   lBrisiKumulativ := .T.
   kalk_kopiraj_dokument_u_tabelu_pripreme( cIdFirma, cIdVd, cBrDok )
   IF lBrisiKumulativ

      run_sql_query( "BEGIN" )
      o_kalk_za_azuriranje()
      find_kalk_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
      IF Found()
         hRecDelete := dbf_get_rec()
      ENDIF
      IF lOk
         lOk := brisi_dokument_iz_tabele_kalk( cIdFirma, cIdVd, cBrDok )
      ENDIF
      IF lOk
         lOk := brisi_dokument_iz_tabele_doks( cIdFirma, cIdVd, cBrDok )
      ENDIF

      IF lOk
         hParams := hb_Hash()
         run_sql_query( "COMMIT", hParams )
         log_write( "F18_DOK_OPER: KALK DOK_POV: " + cIdFirma + "-" + cIdVd + "-" + AllTrim( cBrDok ), 2 )
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



// STATIC FUNCTION brisi_dokument_iz_tabele_doks2( cIdFirma, cIdVd, cBrDok )
//
// LOCAL lOk := .T.
// LOCAL hRec
//
// IF find_kalk_doks2_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )
// hRec := dbf_get_rec()
// lOk := delete_rec_server_and_dbf( "kalk_doks2", hRec, 1, "CONT" )
// ENDIF
//
// RETURN lOk


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

   find_kalk_doks_by_broj_dokumenta( cFirma, cIdVd, cBroj )
   find_kalk_by_broj_dokumenta( cFirma, cIdVd, cBroj )

   MsgO( "Prebacujem dokument u pripremu ..." )

   DO WHILE !Eof() .AND. cFirma == field->IdFirma .AND. cIdVd == field->IdVD .AND. cBroj == field->BrDok

      SELECT kalk
      hRec := dbf_get_rec()
      SELECT kalk_pripr
      APPEND ncnl
      hRec[ "error" ] := ""
      hRec[ "opis"  ] := kalk_doks->opis
      hRec[ "dat_od"  ] := kalk_doks->dat_od
      hRec[ "dat_do"  ] := kalk_doks->dat_do
      hRec[ "datval"  ] := kalk_doks->datval
      hRec[ "opis"  ] := kalk_doks->opis
      hRec[ "datfaktp" ] := kalk_doks->datfaktp
      hRec[ "brfaktp" ] := kalk_doks->brfaktp
      dbf_update_rec( hRec )
      SELECT kalk
      SKIP

   ENDDO

   MsgC()

   RETURN .T.


/*
STATIC FUNCTION kalk_povrat_prema_kriteriju()

   LOCAL cBrDokUslov := Space( 80 )
   LOCAL cDatDokUslov := Space( 80 )
   LOCAL cIdVdUslov := Space( 80 )
   LOCAL cBrDokFilter
   LOCAL cDatDokFilter
   LOCAL cIdVdFilter
   LOCAL lBrisiKumulativ := .F.
   LOCAL cFilter
   LOCAL hRec
   LOCAL hRecDelete
   LOCAL cIdFirma := self_organizacija_id(), cIdVd, cBrDok
   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hParams
   LOCAL nTrec
   LOCAL GetList := {}

   IF !spec_funkcije_sifra()
      my_close_all_dbf()
      RETURN lRet
   ENDIF

   Box(, 3, 60 )

   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Vrste kalk.    " GET cIdVdUslov PICT "@S40"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Broj dokumenata" GET cBrDokUslov PICT "@S40"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datumi         " GET cDatDokUslov PICT "@S40"
      READ
      cBrDokFilter := Parsiraj( cBrDokUslov, "BrDok", "C" )
      cDatDokFilter := Parsiraj( cDatDokUslov, "DatDok", "D" )
      cIdVdFilter := Parsiraj( cIdVdUslov, "IdVD", "C" )
      IF cBrDokFilter <> NIL .AND. cDatDokFilter <> NIL .AND. cIdVdFilter <> NIL
         EXIT
      ENDIF
   ENDDO

   Boxc()

   IF Pitanje(, "Vratiti u pripremu kalk dokumente sa ovim kriterijom (D/N) ?", "N" ) == "D"

      lBrisiKumulativ := Pitanje(, "Izbrisati dokument iz kumulativne tabele (D/N) ?", "D" ) == "D"
      SELECT kalk

      cFilter := "IDFIRMA==" + dbf_quote( cIdFirma ) + ".and." + cBrDokFilter + ".and." + cIdVdFilter + ".and." + cDatDokFilter
      cFilter := StrTran( cFilter, ".t..and.", "" )
      IF cFilter != ".t."
         SET FILTER TO &( cFilter )
      ENDIF

      SELECT kalk
      SET ORDER TO TAG "1"
      GO TOP

      IF !lBrisiKumulativ
         my_close_all_dbf()
         RETURN lRet
      ENDIF

      MsgO( "Brišem tabele sa servera ..." )

      run_sql_query( "BEGIN" )
      //IF !f18_lock_tables( { "kalk_doks", "kalk_kalk" }, .T. )
      //   run_sql_query( "ROLLBACK" )
      //   MsgBeep( "Ne mogu zaključati tabele !#Prekidam proceduru povrata." )
      //   RETURN lRet
      //ENDIF

      DO WHILE !Eof()

         cIdFirma := field->idfirma
         cIdVd := field->idvd
         cBrDok := field->brdok
         hRecDelete := dbf_get_rec()
         DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvd == cIdVd .AND. field->brdok == cBrDok
            SKIP
         ENDDO

         nTrec := RecNo()
         lOk := .T.
         IF lOk
            lOk := delete_rec_server_and_dbf( "kalk_kalk", hRecDelete, 2, "CONT" )
         ENDIF

         IF lOk
            SELECT kalk_doks
            GO TOP
            SEEK cIdFirma + cIdVd + cBrDok
            IF Found()
               log_write( "F18_DOK_OPER: kalk brisanje vise dokumenata: " + cIdFirma + cIdVd + cBrDok, 2 )
               hRecDelete := dbf_get_rec()
               lOk :=  delete_rec_server_and_dbf( "kalk_doks", hRecDelete, 1, "CONT" )
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
         //lRet := .T.
         //hParams := hb_Hash()
         //hParams[ "unlock" ] := { "kalk_doks", "kalk_kalk" }
         run_sql_query( "COMMIT" )
      ELSE
         run_sql_query( "ROLLBACK" )
         MsgBeep( "Problem sa brisanjem podataka iz KALK server tabela !" )
      ENDIF

   ENDIF

   my_close_all_dbf()

   RETURN lRet
*/
