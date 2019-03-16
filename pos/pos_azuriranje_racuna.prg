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


FUNCTION pos_azuriraj_racun( hParams )

   LOCAL cDokument
   LOCAL hRec
   LOCAL nCount := 0
   LOCAL lOk
   LOCAL lRet := .F.
   LOCAL hTranParams := hb_Hash()
   LOCAL cUUIDFiskStorniran
   LOCAL nOldFiskRn
   LOCAL cMsg

   hTranParams[ "tran_name" ] := "pos_rn_azur"

   o_pos_tables()
   IF !racun_se_moze_azurirati( hParams[ "idpos" ], hParams[ "idvd" ], danasnji_datum(), hParams[ "brdok" ] )
      RETURN .F.
   ENDIF

   SELECT _pos_pripr
   GO TOP

   run_sql_query( "BEGIN", hTranParams )

   cDokument := pos_dokument_sa_vrijeme( hParams)

   MsgO( "POS Ažuriranje " + cDokument + " u toku ..." )

   IF Select( "pos_doks" ) == 0
      o_pos_doks()
   ELSE
      SELECT POS_DOKS
   ENDIF

   APPEND BLANK

   hRec := dbf_get_rec()
   hRec[ "idpos" ] := hParams[ "idpos" ]
   hRec[ "idvd" ] := POS_IDVD_RACUN
   hRec[ "datum" ] := danasnji_datum()
   hRec[ "brdok" ] := hParams[ "brdok" ]
   hRec[ "vrijeme" ] := hParams[ "vrijeme" ]
   hRec[ "idvrstep" ] := hParams[ "idvrstep" ]
   hRec[ "idpartner" ] := hParams[ "idpartner" ]
   hRec[ "idradnik" ] := _pos_pripr->idradnik
   cUUIDFiskStorniran := _pos_pripr->fisk_id

   lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )
   IF lOk
      SELECT _pos_pripr
      DO WHILE !Eof() .AND. _pos_pripr->IdPos + _pos_pripr->IdVd + DToS( _pos_pripr->Datum ) + _pos_pripr->BrDok  == hParams[ "idpos" ] + "42" + DToS( danasnji_datum() ) + POS_BRDOK_PRIPREMA
         SELECT pos
         APPEND BLANK
         hRec := dbf_get_rec()
         hRec[ "idpos" ] := hParams[ "idpos" ]
         hRec[ "idvd" ] := POS_IDVD_RACUN
         hRec[ "datum" ] := danasnji_datum()
         hRec[ "brdok" ] := hParams[ "brdok" ]
         hRec[ "rbr" ] := ++nCount
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

   IF lOk
      IF !Empty( cUUIDFiskStorniran )

         IF ( nOldFiskRn := pos_fisk_broj_rn_by_storno_ref( cUUIDFiskStorniran ) ) <> 0
            cMsg := "Već postoji storno istog RN, broj FISK: " + AllTrim( Str( nOldFiskRn ) )
            MsgBeep( cMsg )
            error_bar( "fisk", cMsg )
            lOk := .F.
         ELSE
            // u pos_fisk_doks ubaciti zapis koji se odnosi na ovaj racun, broj_rn = NULL
            IF pos_set_broj_fiskalnog_racuna( hRec[ "idpos" ], hRec[ "idvd" ], hRec[ "datum" ], hRec[ "brdok" ], - 1 )
               pos_set_ref_storno_fisk_dok( hRec[ "idpos" ], hRec[ "idvd" ], hRec[ "datum" ], hRec[ "brdok" ], cUUIDFiskStorniran )
               info_bar( "fisk", "storniran dok " + cUUIDFiskStorniran )
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   MsgC()


   IF lOk
      IF !fiscal_opt_active() .AND. Pitanje(, "Fiskalni štampač nije aktivan. Svejedno ažurirati?", " " ) == "D"
         lOk := .F.
      ELSE
         lOk := pos_stampa_fiskalni_racun( hParams )
      ENDIF
   ENDIF

   IF lOk
      lRet := .T.
      run_sql_query( "COMMIT", hTranParams )
      log_write( "F18_DOK_OPER, ažuriran računa " + cDokument, 2 )
   ELSE
      run_sql_query( "ROLLBACK", hTranParams )
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
