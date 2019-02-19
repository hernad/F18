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


FUNCTION pos_azuriraj_racun( cIdPos, cBrDok, cVrijeme, cNacPlac, cIdPartner )

   LOCAL cDokument := ""
   LOCAL hRec
   LOCAL nCount := 0
   LOCAL lOk := .T.
   LOCAL lRet := .F.
   LOCAL hParams := hb_Hash()

   hParams[ "tran_name" ] := "pos_rn_azur"

   o_pos_tables()
   IF !racun_se_moze_azurirati( cIdPos, POS_IDVD_RACUN, danasnji_datum(), cBrDok )
      RETURN lRet
   ENDIF

   SELECT _pos_pripr
   GO TOP

   run_sql_query( "BEGIN", hParams )

   cDokument := AllTrim( cIdPos ) + "-" + POS_IDVD_RACUN + "-" + AllTrim( cBrDok ) + " " + DToC( danasnji_datum() )

   MsgO( "POS Ažuriranje " + cDokument + " u toku ..." )

   IF Select( "pos_doks" ) == 0
      o_pos_doks()
   ELSE
      SELECT POS_DOKS
   ENDIF

   APPEND BLANK

   hRec := dbf_get_rec()
   hRec[ "idpos" ] := cIdPos
   hRec[ "idvd" ] := POS_IDVD_RACUN
   hRec[ "datum" ] := danasnji_datum()
   hRec[ "brdok" ] := cBrDok
   hRec[ "vrijeme" ] := cVrijeme
   hRec[ "idvrstep" ] := iif( cNacPlac == NIL, POS_IDVRSTEP_GOTOVINSKO_PLACANJE, cNacPlac )
   hRec[ "idpartner" ] := iif( cIdPartner == NIL, "", cIdPartner )
   hRec[ "idradnik" ] := _pos_pripr->idradnik
   hRec[ "brdokstorn" ] := _pos_pripr->brdokStorn

   lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )
   IF lOk

      SELECT _pos_pripr
      DO WHILE !Eof() .AND. _pos_pripr->IdPos + _pos_pripr->IdVd + DToS( _pos_pripr->Datum ) + _pos_pripr->BrDok  == ( cIdPos + "42" + DToS( danasnji_datum() ) + POS_BRDOK_PRIPREMA )

         SELECT pos
         APPEND BLANK
         hRec := dbf_get_rec()
         hRec[ "idpos" ] := cIdPos
         hRec[ "idvd" ] := POS_IDVD_RACUN
         hRec[ "datum" ] := danasnji_datum()
         hRec[ "brdok" ] := cBrDok
         hRec[ "rbr" ] := PadL( AllTrim( Str( ++nCount ) ), FIELD_LEN_POS_RBR )
         //hRec[ "idradnik" ] := _pos_pripr->idradnik
         hRec[ "idroba" ] := _pos_pripr->idroba
         hRec[ "idtarifa" ] := _pos_pripr->idtarifa
         hRec[ "kolicina" ] := _pos_pripr->kolicina
         hRec[ "ncijena" ] := _pos_pripr->ncijena
         hRec[ "cijena" ] := _pos_pripr->cijena
         lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
         IF !lOk
            EXIT
         ENDIF
         SELECT _pos_pripr
         SKIP

      ENDDO

   ENDIF

   MsgC()

   IF lOk
      lRet := .T.
      run_sql_query( "COMMIT", hParams )
      log_write( "F18_DOK_OPER, ažuriran računa " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK", hParams )
      log_write( "F18_DOK_OPER, greška sa ažuriranjem računa " + cDokument, 2 )
   ENDIF

   IF lOk
      pos_brisi_pripremu_racuna()
   ENDIF
   priprema_set_order_to()

   RETURN lRet


STATIC FUNCTION pos_brisi_pripremu_racuna()

   SELECT _pos_pripr
   my_dbf_zap()

   RETURN .T.


STATIC FUNCTION priprema_set_order_to()

   SELECT _pos_pripr
   SET ORDER TO

   RETURN .T.


STATIC FUNCTION racun_se_moze_azurirati( cIdPos, cIdVd, dDatum, cBroj )

   LOCAL lRet := .F.

   IF pos_dokument_postoji( cIdPos, cIdVd, dDatum, cBroj )
      MsgBeep( "Dokument već postoji ažuriran pod istim brojem !" )
      RETURN lRet
   ENDIF

   SELECT _pos_pripr
   IF RecCount() == 0
      MsgBeep( "Priprema računa je prazna, ažuriranje nije moguće !" )
      RETURN lRet
   ENDIF

   SELECT _pos_pripr
   SET ORDER TO TAG "2"
   GO TOP

   IF field->brdok <> "PRIPR" .AND. field->idpos <> cIdPos
      MsgBeep( "Pogrešne stavke računa !#Ažuriranje onemogućeno." )
      RETURN lRet
   ENDIF

   lRet := .T.

   RETURN lRet
