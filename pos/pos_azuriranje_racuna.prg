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
   LOCAL cUUIDFiskStorniran
   LOCAL nOldFiskRn
   LOCAL cMsg
   LOCAL nFiskBroj, cBroj


   o_pos_tables()
   IF !racun_se_moze_azurirati( hParams[ "idpos" ], hParams[ "idvd" ], danasnji_datum(), hParams[ "brdok" ] )
      RETURN .F.
   ENDIF


   create_pos_tmp( hParams )

   IF !is_pos_tmp_empty( hParams )
      Alert("POS[tmp] se koristi!")
      RETURN .F.
   ENDIF
   
   SELECT _pos_pripr
   GO TOP

 
   cDokument := pos_dokument_sa_vrijeme(hParams)

   MsgO( "POS[tmp] Ažuriranje " + cDokument + " u toku ..." )


   hRec := dbf_get_rec()
   hRec[ "idpos" ] := hParams[ "idpos" ]
   hRec[ "idvd" ] := POS_IDVD_RACUN
   hRec[ "datum" ] := danasnji_datum()
   hRec[ "brdok" ] := hParams[ "brdok" ]
   hRec[ "vrijeme" ] := hParams[ "vrijeme" ]
   hRec[ "idvrstep" ] := hParams[ "idvrstep" ]
   hRec[ "idpartner" ] := hParams[ "idpartner" ]
   hRec[ "idradnik" ] := _pos_pripr->idradnik
   // ako je racun u pripremu ubacen operacijom storniranja ovaj broj je postavljem uuid-om originalnog fiskalnog racuna
   cUUIDFiskStorniran := _pos_pripr->fisk_id

   //lOk := update_rec_server_and_dbf( "pos_doks", hRec, 1, "CONT" )
   lOk := insert_pos_tmp( hRec )
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
         //lOk := update_rec_server_and_dbf( "pos_pos", hRec, 1, "CONT" )
         lOk := insert_pos_items_tmp( hRec )
         IF !lOk
            EXIT
         ENDIF
         SELECT _pos_pripr
         SKIP
      ENDDO

   ENDIF

   MsgC()

   
   IF lOk
      IF !fiscal_opt_active()
         IF Pitanje(, "Fiskalni štampač nije aktivan. Svejedno ažurirati?", " " ) == "D"
           lOk := .T.
         ELSE
           lOk := .F.
         ENDIF
      ELSE
         
         IF !Empty( cUUIDFiskStorniran ) .AND. !is_flink_fiskalni()
            altd()
            IF ( nOldFiskRn := pos_fisk_broj_rn_by_storno_ref( cUUIDFiskStorniran ) ) <> 0
               cMsg := "Već postoji storno istog RN, broj FISK: " + AllTrim( Str( nOldFiskRn ) )
               MsgBeep( cMsg )
               error_bar( "fisk", cMsg )
               lOk := .F.
            ENDIF
         ENDIF

         // unutar pos_fiskaliziraj_racun se desava transakcija
         // auto-plu set_params (TREBA LI?!) ; zato ovo nije unutar PSQL transakcije
         IF lOk .AND. pos_fiskaliziraj_racun( @hParams )

            run_sql_query( "BEGIN" )
            IF pos_tmp_to_pos( hParams ) != -1
               lOk := pos_set_broj_fiskalnog_racuna( hParams )

               // stornirani racun, set referencu na originalni 
               IF !Empty( cUUIDFiskStorniran ) .AND. !is_flink_fiskalni()
                     // PSQL p2.set_ref_storno_fisk_dok( cIdPos, cIdVd, dDatDok, cBrDok, uuidFiskStorniran )
                     pos_set_ref_storno_fisk_dok( hRec[ "idpos" ], hRec[ "idvd" ], hRec[ "datum" ], hRec[ "brdok" ], cUUIDFiskStorniran )
                     info_bar( "fisk", "storniran dok " + cUUIDFiskStorniran )
                     lOk := .T.
               ENDIF

            ELSE
               lOk := .F.
            ENDIF

            IF lOk
               lRet := .T.
               run_sql_query( "COMMIT" )
               log_write( "PS azur_rn: " + cDokument, 2 )

               pos_brisi_pripremu_racuna()
            ELSE
               lRet := .F.
               run_sql_query( "ROLLBACK" ) //, hTranParams )
               log_write( "POS ERR_azur_rn_ERR: " + cDokument, 2 )
            ENDIF

         ELSE
            lOk := .F.
         ENDIF
      ENDIF
   ENDIF

   cleanup_pos_tmp( hParams )
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


FUNCTION create_pos_tmp( hParams )

   LOCAL cQuery
   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL oQry
   LOCAL cSqlTableTmpPosItems := cShema + ".pos_items_tmp_" + AllTrim(hParams["idpos"])
   LOCAL cSqlTableTmpPos := cShema + ".pos_tmp_" + AllTrim(hParams["idpos"])

   cQuery := "CREATE TABLE IF NOT EXISTS " + cSqlTableTmpPosItems
   cQuery += " AS TABLE " + cShema + ".pos_items WITH NO DATA;"

   cQuery += "CREATE TABLE IF NOT EXISTS " + cSqlTableTmpPos
   cQuery += " AS TABLE " + cShema + ".pos WITH NO DATA;"
   
   cQuery += "SELECT count(*) FROM " + cSqlTableTmpPos + ";"

   oQry := run_sql_query( cQuery )

   IF sql_error_in_query( oQry, "SELECT" )
      RETURN .F.
   ENDIF

   RETURN .T.


FUNCTION cleanup_pos_tmp( hParams )

   LOCAL cQuery
   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL oQry
   LOCAL cSqlTableTmpPosItems := cShema + ".pos_items_tmp_" + AllTrim(hParams["idpos"])
   LOCAL cSqlTableTmpPos := cShema + ".pos_tmp_" + AllTrim(hParams["idpos"])

   
   cQuery := "DELETE from " + cSqlTableTmpPosItems + ";"
   cQuery += "DELETE from " + cSqlTableTmpPos + ";"
   cQuery += "SELECT count(*) FROM " + cSqlTableTmpPos + ";"

   oQry := run_sql_query( cQuery )

   IF sql_error_in_query( oQry, "SELECT" )
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION is_pos_tmp_empty( hParams )

   LOCAL cQuery
   LOCAL oQry
   LOCAL cSqlTableTmpPos := pos_prodavnica_sql_schema() + ".pos_tmp_" + AllTrim(hParams["idpos"])
   
   cQuery := "SELECT count(*) FROM " + cSqlTableTmpPos + ";"
   oQry := run_sql_query( cQuery )
   
   IF sql_error_in_query( oQry, "SELECT" )
       RETURN .T.
   ENDIF

   RETURN oQry:FieldGet(1) == 0



STATIC FUNCTION insert_pos_tmp( hRec )

   LOCAL cQuery
   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL oQry

   cQuery := "INSERT INTO " + cShema + ".pos_tmp_" + hRec["idpos"]
   cQuery += "(idpos,idvd,datum,brdok,vrijeme,idvrstep,idpartner,idradnik)"

   cQuery += " VALUES("
   cQuery += sql_quote(hRec[ "idpos" ]) + ","
   cQuery += sql_quote(hRec[ "idvd" ]) + ","
   cQuery += sql_quote(hRec[ "datum" ]) + ","
   cQuery += sql_quote(hRec[ "brdok" ]) + ","
   cQuery += sql_quote(hRec[ "vrijeme" ]) + ","
   cQuery += sql_quote(hRec[ "idvrstep" ]) + ","
   cQuery += sql_quote(hRec[ "idpartner" ]) + ","
   cQuery += sql_quote(hRec[ "idradnik" ])
   cQuery += ")"
   
   oQry := run_sql_query( cQuery )
   IF sql_error_in_query( oQry, "INSERT" )
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION insert_pos_items_tmp( hRec )

   LOCAL cQuery
   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL oQry

   cQuery := "INSERT INTO " + cShema + ".pos_items_tmp_" + hRec["idpos"]
   cQuery += "(idpos,idvd,datum,brdok,rbr,idroba,idtarifa,kolicina,cijena,ncijena)"
   cQuery += " VALUES("
   cQuery += sql_quote(hRec[ "idpos" ]) + ","
   cQuery += sql_quote(hRec[ "idvd" ]) + ","
   cQuery += sql_quote(hRec[ "datum" ]) + ","
   cQuery += sql_quote(hRec[ "brdok" ]) + ","
   cQuery += sql_quote(hRec[ "rbr" ]) + ","
   cQuery += sql_quote(hRec[ "idroba" ]) + ","
   cQuery += sql_quote(hRec[ "idtarifa" ]) + ","
   cQuery += sql_quote(hRec[ "kolicina" ]) + ","
   cQuery += sql_quote(hRec[ "cijena" ]) + ","
   cQuery += sql_quote(hRec[ "ncijena" ])
   cQuery += ")"
   
   oQry := run_sql_query( cQuery )
   IF sql_error_in_query( oQry, "INSERT" )
      RETURN .F.
   ENDIF

   RETURN .T.



   
/*
   p2.pos_items_tmp_1 -> p2.pos_items
   p2.pos_tmp_1 -> p2.pos 

   RET:
    0 - tmp tables NOT exists
   -1 - tmp tables exists, transaction ERROR
   +1 - tmp tables exists, transaction OK 
*/

STATIC FUNCTION pos_tmp_to_pos( hParams )

   LOCAL cQuery, cWhere
   LOCAL cShema := pos_prodavnica_sql_schema()
   LOCAL oQry
   LOCAL cSqlTablePosItems := pos_prodavnica_sql_schema() + ".pos_items_tmp_" + AllTrim(hParams["idpos"])
   LOCAL cSqlTablePos := pos_prodavnica_sql_schema() + ".pos_tmp_" + AllTrim(hParams["idpos"])
   LOCAL cPosFields, cPosItemFields
   
   // test p2.pos_items_tmp_1 exists
   cQuery := "SELECT to_regclass('" + cSqlTablePos + "')"
   oQry := run_sql_query( cQuery )
   IF !(oQry:FieldGet(1) $  cSqlTablePos)
       RETURN 0
   ENDIF

   cWhere := "idpos=" + sql_quote(hParams["idpos"]) 
   cWhere += " AND idvd=" + sql_quote(hParams["idvd"]) + " AND brdok=" + sql_quote(hParams["brdok"])
   cWhere += " AND datum=" + sql_quote(hParams["datum"])

   cPosFields := "idpos,idvd,brdok,datum,idpartner,idradnik,idvrstep,vrijeme,ukupno,opis"
   cPosItemFields := "idpos,idvd,brdok,datum,idroba,idtarifa,kolicina,kol2,cijena,ncijena,rbr,robanaz,jmj"


   cQuery := "INSERT INTO " + cShema + ".pos(" + cPosFields + ")"
   cQuery += " (SELECT " + cPosFields + " FROM " + cSqlTablePos + " WHERE " + cWhere + ");"

   cQuery += "INSERT INTO " + cShema + ".pos_items(" + cPosItemFields + ")"
   cQuery += " (SELECT " + cPosItemFields + " FROM " + cSqlTablePosItems + " WHERE " + cWhere + ");"

   cQuery += "UPDATE " + cShema + ".pos_items SET dok_id=" + cShema + ".pos_dok_id(" + sql_quote(hParams["idpos"]) + "," + sql_quote(hParams["idvd"]) + "," + sql_quote(hParams["brdok"]) + "," + sql_quote(hParams["datum"]) + ")"
   cQuery += " WHERE " + cWhere + ";" 

   cQuery += "DELETE FROM " + cSqlTablePos + ";"
   cQuery += "DELETE FROM " + cSqlTablePosItems + ";"
   
   cQuery += "SELECT count(*) FROM " + cShema + ".pos WHERE " + cWhere + ";"
   oQry := run_sql_query( cQuery )

   // u pos mora biti count(*) = 1 pos zapis
   IF sql_error_in_query( oQry, "SELECT" ) .OR. oQry:FieldGet(1) <> 1
      RETURN -1
   ENDIF

   RETURN 1
   