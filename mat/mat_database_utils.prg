/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


// otvara potrebne tabele za povrat
STATIC FUNCTION _o_tables()

   O_MAT_SUBAN
   O_MAT_ANAL
   O_MAT_SINT
   O_MAT_NALOG
   O_MAT_PRIPR
   //o_roba()
   //o_sifk()
   //o_sifv()

   RETURN


// ---------------------------------------------
// povrat naloga u pripremu
// ---------------------------------------------
FUNCTION mat_povrat_naloga( lStorno )

   LOCAL _rec
   LOCAL nRec
   LOCAL _del_rec, _ok
   LOCAL _field_ids, _where_block

   IF lStorno == NIL
      lStorno := .F.
   ENDIF

   _o_tables()

   SELECT MAT_SUBAN
   SET ORDER TO TAG "4"

   cIdFirma := self_organizacija_id()
   cIdFirma2 := self_organizacija_id()
   cIdVN := cIdVN2  := Space( 2 )
   cBrNal := cBrNal2 := Space( 4 )

   Box( "", iif( lStorno, 3, 1 ), iif( lStorno, 65, 35 ) )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Nalog:"


    @ box_x_koord() + 1, Col() + 1 SAY cIdFirma PICT "@!"


   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVN PICT "@!"
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrNal VALID !Empty( cBrNal )

   IF lStorno

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Broj novog naloga (naloga storna):"

      @ box_x_koord() + 3, Col() + 1 SAY cIdFirma2


      @ box_x_koord() + 3, Col() + 1 SAY "-" GET cIdVN2 PICT "@!"
      @ box_x_koord() + 3, Col() + 1 SAY "-" GET cBrNal2

   ENDIF

   READ
   ESC_BCR

   BoxC()


   IF Pitanje(, "Nalog " + cIdFirma + "-" + cIdVN + "-" + cBrNal + iif( lStorno, " stornirati", " povuci u pripremu" ) + " (D/N) ?", "D" ) == "N"
      my_close_all_dbf()
      RETURN
   ENDIF

   lBrisi := .T.

   IF !lStorno
      lBrisi := ( Pitanje(, "Nalog " + cIdFirma + "-" + cIdVN + "-" + cBrNal + " izbrisati iz baze azuriranih dokumenata (D/N) ?", "D" ) == "D" )
   ENDIF

   MsgO( "Punim pripremu sa mat_suban: " + cIdfirma + cIdvn + cBrNal )

   SELECT MAT_SUBAN
   SEEK cIdfirma + cIdvn + cBrNal

   DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal

      SELECT mat_pripr

      SELECT mat_suban

      _rec := dbf_get_rec()

      SELECT mat_pripr

      IF lStorno
         _rec[ "idfirma" ]  := cIdFirma2
         _rec[ "idvn" ]     := cIdVn2
         _rec[ "brnal" ]    := cBrNal2
         _rec[ "iznos" ] := -_iznos
         _rec[ "iznos2" ] := -_iznos2
      ENDIF

      APPEND BLANK

      dbf_update_rec( _rec )

      SELECT MAT_SUBAN
      SKIP

   ENDDO

   MsgC()

   IF !lBrisi
      my_close_all_dbf()
      RETURN
   ENDIF

   IF !lStorno
      IF !brisi_mat_nalog( cIdFirma, cIdVn, cBrNal )
         MsgBeep( "Problem sa brisanjem naloga ..." )
      ELSE
         log_write( "F18_DOK_OPER: mat, povrat naloga u pripremu: " + cIdFirma + "-" + cIdVn + "-" + cBrNal, 2 )
      ENDIF
   ENDIF

   my_close_all_dbf()

   RETURN


// ---------------------------------------------------------
// brisanje mat naloga iz kumulativa
// ---------------------------------------------------------
FUNCTION brisi_mat_nalog( cIdFirma, cIdVn, cBrNal )

   LOCAL _del_rec
   LOCAL _ok := .T.
   LOCAL hParams

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "mat_suban", "mat_sint", "mat_anal", "mat_nalog" } )
      run_sql_query( "ROLLBACK" )
      RETURN .F.
   ENDIF



   SELECT mat_suban
   SET ORDER TO TAG "4"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "mat_suban", _del_rec, 2, "CONT" )
   ENDIF

   SELECT mat_sint
   SET ORDER TO TAG "2"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "mat_sint", _del_rec, 2, "CONT" )
   ENDIF

   SELECT mat_anal
   SET ORDER TO TAG "2"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "mat_anal", _del_rec, 2, "CONT" )
   ENDIF

   SELECT mat_nalog
   SET ORDER TO TAG "1"
   GO TOP
   SEEK cIdFirma + cIdVn + cBrNal

   IF Found()
      _del_rec := dbf_get_rec()
      delete_rec_server_and_dbf( "mat_nalog", _del_rec, 1, "CONT" )
   ENDIF

   hParams := hb_Hash()
   hParams[ "unlock" ] := { "mat_suban", "mat_sint", "mat_anal", "mat_nalog" }
   run_sql_query( "COMMIT", hParams )

   RETURN _ok



// ----------------------------------------------
// generacija dokumenta pocetnog stanja
// ----------------------------------------------
FUNCTION mat_prenos_podataka()

   LOCAL _nule := "D"
   LOCAL _po_partneru := "N"
   LOCAL _r_br := 0

   O_MAT_PRIPR

   IF reccount2() <> 0
      MsgBeep( "Tabela pripreme mora biti prazna !!!" )
      my_close_all_dbf()
      RETURN
   ENDIF

   my_dbf_zap()

   SET ORDER TO TAG "4"
   GO TOP

   Box(, 5, 60 )
   nMjesta := 3
   dDatDo := Date()
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum do kojeg se promet prenosi" GET dDatDo
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Prenositi stavke sa saldom 0 (D/N)" GET _nule VALID _nule $ "DN" PICT "!@"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Prenos raditi po partneru (D/N)" GET _po_partneru VALID _po_partneru $ "DN" PICT "!@"

   READ
   ESC_BCR
   BoxC()

   START PRINT CRET

   O_MAT_SUBAN

   // ovo je bio stari indeks, stari prenos bez partnera
   // set order to tag "3"
   // "3" - "IdFirma+IdKonto+IdRoba+dtos(DatDok)"

   SET ORDER TO TAG "5"
   // "5" - "IdFirma+IdKonto+IdPartner+IdRoba+dtos(DatDok)"

   ? "Prolazim kroz bazu...."
   SELECT mat_suban
   GO TOP

   // idfirma, idkonto, idpartner, idroba, datdok
   DO WHILE !Eof()

      nRbr := 0
      cIdFirma := idfirma

      DO WHILE !Eof() .AND. cIdFirma == IdFirma

         cIdKonto := IdKonto
         SELECT mat_suban

         nDin := 0
         nDem := 0

         DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto

            cIdPartner := idpartner

            DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdPartner == cIdPartner

               cIdRoba := IdRoba

               ? "Konto:", cIdKonto, ", partner:", cIdPartner, ", roba:", cIdRoba

               DO WHILE !Eof() .AND. cIdFirma == IdFirma .AND. cIdKonto == IdKonto .AND. IdRoba == cIdRoba .AND. idpartner == cIdPartner

                  IF _nule == "N" .AND. Round( mat_suban->kolicina, 2 ) == 0
                     SKIP
                     LOOP
                  ENDIF

                  SELECT mat_pripr
                  SET ORDER TO TAG "4"
                  GO TOP

                  IF _po_partneru == "D"
                     SEEK mat_suban->idfirma + mat_suban->idkonto + mat_suban->idpartner + mat_suban->idroba
                  ELSE
                     SEEK mat_suban->idfirma + mat_suban->idkonto + Space( 6 ) + mat_suban->idroba
                  ENDIF

                  IF !Found()

                     APPEND BLANK

                     REPLACE idfirma WITH cIdFirma
                     REPLACE idkonto WITH cIdkonto

                     IF _po_partneru == "D"
                        REPLACE idpartner WITH cIdPartner
                     ELSE
                        REPLACE idpartner WITH ""
                     ENDIF

                     REPLACE idRoba  WITH cIdRoba
                     REPLACE datdok WITH dDatDo + 1
                     REPLACE datkurs WITH dDatDo + 1
                     REPLACE idvn WITH "00"
                     REPLACE idtipdok WITH "00"
                     REPLACE brnal WITH "0001"
                     REPLACE d_p WITH "1"
                     REPLACE u_i WITH "1"
                     REPLACE rbr WITH PadL( AllTrim( Str( ++_r_br ) ), 4 )
                     REPLACE kolicina with ;
                        iif( mat_suban->U_I == "1", mat_suban->kolicina, ;
                        -mat_suban->kolicina )
                     REPLACE iznos with ;
                        iif( mat_suban->D_P == "1", mat_suban->iznos, ;
                        -mat_suban->iznos )
                     REPLACE iznos2 with ;
                        iif( mat_suban->D_P == "1", mat_suban->iznos2, ;
                        -mat_suban->iznos2 )

                  ELSE

                     REPLACE kolicina with ;
                        kolicina + iif( mat_suban->U_I == "1", ;
                        mat_suban->kolicina, -mat_suban->kolicina )

                     REPLACE iznos with ;
                        iznos + iif( mat_suban->D_P == "1", ;
                        mat_suban->iznos, -mat_suban->iznos )

                     REPLACE iznos2 with ;
                        iznos2 + iif( mat_suban->D_P == "1", ;
                        mat_suban->iznos2, -mat_suban->iznos2 )

                  ENDIF

                  SELECT mat_suban
                  SKIP

               ENDDO
               // roba

            ENDDO
            // partner

         ENDDO
         // konto

      ENDDO
      // firma

   ENDDO
   // eof

   SELECT mat_pripr
   my_flock()
   SET ORDER TO
   GO TOP
   DO WHILE !Eof()
      IF Round( iznos, 2 ) == 0 .AND. Round( iznos2, 2 ) == 0 .AND. ;
            Round( kolicina, 3 ) == 0
         dbdelete2()
      ENDIF
      SKIP
   ENDDO
   my_unlock()
   my_dbf_pack()

   SET ORDER TO TAG "1"
   GO TOP

   nTrec := 0

   my_flock()
   DO WHILE !Eof()
      cIdFirma := idfirma
      nRbr := 0
      DO WHILE !Eof() .AND. cIdFirma == IdFirma
         SKIP
         nTrec := RecNo()
         SKIP -1
         REPLACE rbr WITH Str( ++nRbr, 4 )
         REPLACE cijena WITH iif( Kolicina <> 0, Iznos / Kolicina, 0 )
         GO nTrec
      ENDDO
   ENDDO
   my_unlock()

   my_close_all_dbf()
   ENDPRINT

   RETURN .T.
