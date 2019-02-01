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

MEMVAR _idpos, _rbr, _brdok, _idvd, _datum

FUNCTION pos_azuriraj_zaduzenje( cBrDok, cIdVd )

   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hRec
   LOCAL nCount := 0
   LOCAL cDokument := ""
   LOCAL hParams

   run_sql_query( "BEGIN" )

   SELECT PRIPRZ
   GO TOP
   set_global_memvars_from_dbf()

   SELECT pos_doks
   APPEND BLANK
   _brdok := cBrDok
   _idvd := cIdVd

   cDokument := AllTrim( _idpos ) + "-" + _idvd + "-" + AllTrim( _brdok ) + " " + DToC( _datum )

   hRec := get_hash_record_from_global_vars()
   hRec[ "rabat" ] := 0
   hRec[ "ukupno" ] := 0
   lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )

   IF lOk

      SELECT PRIPRZ
      DO WHILE !Eof()

         SELECT PRIPRZ
         lOk := pos_azuriraj_artikal_u_sifarniku( cIdVd )
         IF !lOk
            EXIT
         ENDIF

         SELECT PRIPRZ
         set_global_memvars_from_dbf()

         SELECT pos
         APPEND BLANK
         _brdok := cBrDok
         _idvd := cIdVd
         _rbr := PadL( AllTrim( Str( ++nCount ) ), 5 )

         hRec := get_hash_record_from_global_vars()
         lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF
         SELECT priprz
         SKIP

      ENDDO

   ENDIF

   IF lOk
      lRet := .T.
      hParams := hb_Hash()
      //hParams[ "unlock" ] :=  { "pos_pos", "pos_doks", "roba" }
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER, ažuriran pos dokument " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK" )
      log_write( "F18_DOK_OPER, greška sa ažuriranjem pos dokumenta " + cDokument, 2 )
   ENDIF

   IF lOk
      brisi_tabelu_pripreme()
   ENDIF

/*
   IF lOk .AND. fiscal_opt_active()
      setuj_plu_kodove_artikala_nakon_azuriranja()
   ENDIF
*/
   SELECT PRIPRZ

   RETURN lRet



STATIC FUNCTION brisi_tabelu_pripreme()

   MsgO( "Brisanje tabele pripreme u toku ..." )

   SELECT priprz
   my_dbf_zap()

   MsgC()

   RETURN .T.

/*
STATIC FUNCTION setuj_plu_kodove_artikala_nakon_azuriranja()

   LOCAL nDeviceId
   LOCAL hDeviceParams

   nDeviceId := odaberi_fiskalni_uredjaj( NIL, .T., .F. )

   IF nDeviceId > 0
      hDeviceParams := get_fiscal_device_params( nDeviceId, my_user() )
      IF hDeviceParams[ "plu_type" ] == "P"
         gen_all_plu( .T. )
      ENDIF
   ENDIF

   RETURN .T.
*/


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
   hRec[ "idgost" ] := priprz->idgost
   hRec[ "idradnik" ] := priprz->idradnik
   hRec[ "m1" ] := priprz->m1
   hRec[ "prebacen" ] := priprz->prebacen
   hRec[ "smjena" ] := priprz->smjena

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
         hRec[ "m1" ] := priprz->m1
         hRec[ "prebacen" ] := priprz->prebacen
         hRec[ "idodj" ] := priprz->idodj
         hRec[ "idcijena" ] := priprz->idcijena
         hRec[ "idradnik" ] := priprz->idradnik
         hRec[ "idroba" ] := priprz->idroba
         hRec[ "idtarifa" ] := priprz->idtarifa
         hRec[ "kolicina" ] := priprz->kolicina
         hRec[ "kol2" ] := priprz->kol2
         hRec[ "mu_i" ] := priprz->mu_i
         hRec[ "ncijena" ] := priprz->ncijena
         hRec[ "cijena" ] := priprz->cijena
         hRec[ "smjena" ] := priprz->smjena
         hRec[ "c_1" ] := priprz->c_1
         hRec[ "c_2" ] := priprz->c_2
         hRec[ "c_3" ] := priprz->c_3
         hRec[ "rbr" ] := PadL( AllTrim( Str( ++nCount ) ), 5 )

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Stavka " + AllTrim( Str( nCount ) ) + " roba: " + hRec[ "idroba" ]

         lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF

         SELECT PRIPRZ
         IF cTipDok <> "IN"
            pos_azuriraj_artikal_u_sifarniku(cIdVd)
         ENDIF

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


STATIC FUNCTION pos_azuriraj_artikal_u_sifarniku(cIdVd)

   LOCAL lOk := .T.
   LOCAL hRec
   LOCAL _update := .F.
   LOCAL cFieldPOSMPC

   IF gSetMPCijena == "1"
      cFieldPOSMPC := "mpc"
   ELSE
      cFieldPOSMPC := "mpc" + AllTrim( gSetMPCijena )
   ENDIF

   lNovi := .F.

   IF !select_o_roba( priprz->idroba )
      APPEND BLANK
      hRec := dbf_get_rec()
      hRec[ "id" ] := priprz->idroba
      _update := .T.
   ELSE
      hRec := dbf_get_rec()
   ENDIF

   hRec[ "naz" ] := priprz->robanaz
   hRec[ "jmj" ] := priprz->jmj

   IF cIdVd == "NI"
      hRec[ cFieldPOSMPC ] := Round( priprz->ncijena, 3 )
   ELSE
      hRec[ cFieldPOSMPC ] := Round( priprz->cijena, 3 )
   ENDIF

   hRec[ "idtarifa" ] := priprz->idtarifa
   hRec[ "k1" ] := priprz->k1
   hRec[ "k2" ] := priprz->k2
   hRec[ "k7" ] := priprz->k7
   hRec[ "k8" ] := priprz->k8
   hRec[ "k9" ] := priprz->k9
   hRec[ "n1" ] := priprz->n1
   hRec[ "n2" ] := priprz->n2
   hRec[ "barkod" ] := priprz->barkod
   lOk := update_rec_server_and_dbf( "roba", hRec, 1, "CONT" )

   RETURN lOk
