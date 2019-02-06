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

MEMVAR _idpos, _rbr, _brdok, _idvd, _datum, _cijena, _kolicina

FUNCTION pos_azuriraj_zaduzenje( cIdPos, cIdVd, cBrDok, dDatum )

   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hRec
   LOCAL nCount := 0
   LOCAL cDokument := ""
   LOCAL nUkupno
   LOCAL hParams

   run_sql_query( "BEGIN" )

   SELECT PRIPRZ
   GO TOP
   set_global_memvars_from_dbf()


   cDokument := AllTrim( _idpos ) + "-" + _idvd + "-" + AllTrim( _brdok ) + " " + DToC( _datum )

   hRec := get_hash_record_from_global_vars()
   hRec[ "idpos" ] := cIdPos
   hRec[ "brdok" ] := cBrDok
   hRec[ "idvd" ] := cIdVd
   hRec[ "datum" ] := dDatum
   hRec[ "ukupno" ] := nUkupno

   SELECT PRIPRZ
   nUkupno := 0
   DO WHILE !Eof()

      SELECT pos
      APPEND BLANK

      hRec["rbr"] := PadL( AllTrim( Str( ++nCount ) ), FIELD_LEN_POS_RBR )
      hRec["cijena"] := priprz->cijena
      hRec["kolicina"] := priprz->kolicina
      nUkupno += priprz->cijena * priprz->kolicina

      lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
      IF !lOk
         EXIT
      ENDIF
      SELECT priprz
      SKIP

   ENDDO

   IF lOk
      SELECT pos_doks
      APPEND BLANK
      lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )
   ENDIF

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      // hParams[ "unlock" ] :=  { "pos_pos", "pos_doks", "roba" }
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER, ažuriran pos dokument " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER, greška sa ažuriranjem pos dokumenta " + cDokument, 2 )
   ENDIF

   IF lOk
      brisi_tabelu_pripreme()
   ENDIF

   SELECT PRIPRZ

   RETURN lRet



STATIC FUNCTION brisi_tabelu_pripreme()

   MsgO( "Brisanje tabele pripreme u toku ..." )

   SELECT priprz
   my_dbf_zap()

   MsgC()

   RETURN .T.



FUNCTION pos_azuriraj_inventura_nivelacija()

   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL nTotalCount
   LOCAL nCount := 0
   LOCAL hRec, nTrec
   LOCAL cTipDok, cDokument
   LOCAL hParams

   run_sql_query( "BEGIN" )
   IF !f18_lock_tables( { "pos_pos", "pos_doks" } )
      run_sql_query( "ROLLBACK" )
      MsgBeep( "Ne mogu zaključati tabele !#Prekidam operaciju." )
      RETURN lRet
   ENDIF

   Box(, 3, 60 )

   nTotalCount := priprz->( RecCount() )

   SELECT PRIPRZ
   GO TOP
   seek_pos_doks( "XX", "XX" )
   APPEND BLANK

   hRec := dbf_get_rec()
   hRec[ "idpos" ] := priprz->idpos
   hRec[ "idvd" ] := priprz->idvd
   hRec[ "datum" ] := priprz->datum
   hRec[ "brdok" ] := priprz->brdok
   hRec[ "vrijeme" ] := priprz->vrijeme
   hRec[ "idvrstep" ] := priprz->idvrstep
   hRec[ "idpartner" ] := priprz->idPartner
   hRec[ "idradnik" ] := priprz->idradnik
   hRec[ "brdokstorn" ] := priprz->brdokStorn

   cTipDok := hRec[ "idvd" ]
   cDokument := AllTrim( hRec[ "idpos" ] ) + "-" + hRec[ "idvd" ] + "-" + AllTrim( hRec[ "brdok" ] ) + " " + DToC( hRec[ "datum" ] )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "    AŽURIRANJE DOKUMENTA U TOKU ..."
   @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "Formiran dokument: " + cDokument +  " / zap: " + AllTrim( Str( nTotalCount ) )
   lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )


   IF lOk

      seek_pos_pos( "XX", "XX" )
      SELECT PRIPRZ
      DO WHILE !Eof()

         nTrec := RecNo()
         SELECT POS
         APPEND BLANK
         hRec := dbf_get_rec()
         hRec[ "idpos" ] := priprz->idpos
         hRec[ "idvd" ] := priprz->idvd
         hRec[ "datum" ] := priprz->datum
         hRec[ "brdok" ] := priprz->brdok
         hRec[ "idradnik" ] := priprz->idradnik
         hRec[ "idroba" ] := priprz->idroba
         hRec[ "idtarifa" ] := priprz->idtarifa
         hRec[ "kolicina" ] := priprz->kolicina
         hRec[ "kol2" ] := priprz->kol2
         hRec[ "ncijena" ] := priprz->ncijena
         hRec[ "cijena" ] := priprz->cijena
         hRec[ "rbr" ] := PadL( AllTrim( Str( ++nCount ) ), FIELD_LEN_POS_RBR )

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Stavka " + AllTrim( Str( nCount ) ) + " roba: " + hRec[ "idroba" ]

         lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF

         SELECT PRIPRZ

         SELECT PRIPRZ
         GO ( nTrec )
         SKIP

      ENDDO

   ENDIF

   BoxC()

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      hParams[ "unlock" ] := { "pos_pos", "pos_doks" }
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER, ažuriran pos dokument: " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER, greška sa ažuriranjem pos dokumenta: " + cDokument, 2 )
   ENDIF

   IF lOk
      brisi_tabelu_pripreme()
   ENDIF

   RETURN lRet
