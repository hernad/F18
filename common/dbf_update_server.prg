/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*
  update podataka za jedan dbf zapis na serveru
  mijenja zapis na serveru, pa ako je sve ok onda uradi update dbf-a

 update_rec_server_and_dbf( cTabela, hRecord, 1, "FULL") - zapocni/zavrsi transakciju unutar funkcije
*/

FUNCTION update_rec_server_and_dbf( cTabela, hRecord, nAlgoritam, cTransaction )

   LOCAL _ids := {}
   LOCAL _pos
   LOCAL cFullIdDbf, cFullIdMem
   LOCAL _dbf_pkey_search
   LOCAL _field
   LOCAL cWhereString, cWhereStringDbf
   LOCAL _t_field, _t_field_dec
   LOCAL hDbfRec, hAlgoritam
   LOCAL cMsg
   LOCAL hRecDbf
   LOCAL _alg_tag := ""
   LOCAL lRet
   LOCAL lLock
   LOCAL hParams

   lRet := .T.

   IF cTransaction == "FULL"
      lLock := .T.
   ELSE
      lLock := .F.
   ENDIF

  // IF "roba_p" $ cTabela
  //    AltD()
  // ENDIF

   // trebamo where str za hRecord rec
   set_table_values_algoritam_vars( @cTabela, @hRecord, @nAlgoritam, @cTransaction, @hDbfRec, @hAlgoritam, @cWhereString, @_alg_tag )

   IF Alias() <> hDbfRec[ "alias" ]
      cMsg := "ERR "  + RECI_GDJE_SAM0 + " ALIAS() = " + Alias() + " <> " + hDbfRec[ "alias" ]
      log_write( cMsg, 2 )
      Alert( cMsg )
      error_bar( "update", cMsg )
      RETURN .F.
   ENDIF

   // log_write( "START: update_rec_server_and_dbf " + cTabela, 9 )
   hRecDbf := dbf_get_rec()

   // trebamo where str za stanje dbf-a
   set_table_values_algoritam_vars( @cTabela, @hRecDbf, @nAlgoritam, @cTransaction, @hDbfRec, @hAlgoritam, @cWhereStringDbf, @_alg_tag )

   IF cTransaction $ "FULL#BEGIN"
      run_sql_query( "BEGIN" )
      unlock_semaphore( cTabela )
      lock_semaphore( cTabela )
   ENDIF

   IF !sql_table_update( cTabela, "del", NIL, cWhereString ) // izbrisi sa servera stare vrijednosti za hRecord

      IF cTransaction == "FULL"
         run_sql_query( "ROLLBACK" )
      ENDIF

      cMsg := "ERROR: sql delete " + cTabela +  " , ROLLBACK, where: " + cWhereString
      log_write( cMsg, 1 )
      Alert( cMsg )

      lRet := .F.

   ENDIF

   IF lRet .AND.  ( cWhereStringDbf != cWhereString )

      // izbrisi i stare vrijednosti za hRecDbf
      // ovo nam treba ako se uradi npr. ispravku ID-a sifre
      // id je u dbf = ID=id_stari, NAZ=stari
      //
      // ispravljamo i id, i naz, pa u hRecord imamo
      // id je bio ID=id_novi.  NAZ=naz_novi
      //
      // nije dovoljno da uradimo delete where id=id_novi
      // trebamo uraditi i delete id=id_stari
      // to radimo upravo u sljedecoj sekvenci
      //
      IF !sql_table_update( cTabela, "del", NIL, cWhereStringDbf )

         IF cTransaction == "FULL"
            run_sql_query( "ROLLBACK" )
         ENDIF

         cMsg := "ERROR: sql delete " + cTabela +  " , ROLLBACK, where: " + cWhereStringDbf
         ?E cMsg
         error_bar( "sql_table", cMsg )

         RETURN .F.

      ENDIF

   ENDIF


   IF lRet .AND. !sql_table_update( cTabela, "ins", hRecord )

      IF cTransaction == "FULL"
         run_sql_query( "ROLLBACK" )
         // unlock_semaphore( cTabela )
      ENDIF

      cMsg := RECI_GDJE_SAM + "ERRORY: sql_insert: " + cTabela + " , ROLLBACK hRecord: " + pp( hRecord )
      log_write( cMsg, 1 )
      Alert( cMsg )

      RETURN .F.

   ENDIF

   cFullIdDbf := get_dbf_rec_primary_key( hAlgoritam[ "dbf_key_fields" ], hRecDbf ) // stanje u dbf-u (hRecDbf)
   cFullIdMem := get_dbf_rec_primary_key( hAlgoritam[ "dbf_key_fields" ], hRecord ) // stanje podataka u mem rec varijabli hRecord


   AAdd( _ids, _alg_tag + cFullIdMem ) // stavi id-ove na server
   IF ( cFullIdDbf <> cFullIdMem ) .AND. !Empty( cFullIdDbf )
      AAdd( _ids, _alg_tag + cFullIdDbf )
   ENDIF

   IF !push_ids_to_semaphore( cTabela, _ids )

      IF cTransaction == "FULL"
         run_sql_query( "ROLLBACK" )
         ?E "ERR ", RECI_GDJE_SAM0, + "push_ids_to_semaphore " + cTabela + "/ ids=", _alg_tag, _ids, " ! ROLLBACK"
      ENDIF

      // log_write( cMsg, 1 )
      // Alert( cMsg )
      lRet := .F.

   ENDIF

   IF lRet

      IF dbf_update_rec( hRecord )

         IF cTransaction $ "FULL#END"
            hParams := hb_Hash()
            hParams[ "unlock" ] := { cTabela }
            run_sql_query( "COMMIT" )
         ENDIF
         lRet := .T.

      ELSE

         IF cTransaction == "FULL"
            run_sql_query( "ROLLBACK" )
         ENDIF

         cMsg := "ERR: " + RECI_GDJE_SAM0 + "dbf_update_rec " + cTabela +  " ! ROLLBACK"
         log_write( cMsg, 1 )
         Alert( cMsg )

         lRet := .F.

      ENDIF

   ENDIF

   // log_write( "END update_rec_server_and_dbf " + cTabela, 9 )

   RETURN lRet


/*
   nAlgoritam = 1 - nivo zapisa, 2 - dokument ...
*/

FUNCTION delete_rec_server_and_dbf( cTabela, hRecord, nAlgoritam, cTransaction )

   LOCAL _ids := {}
   LOCAL _pos
   LOCAL _full_id
   LOCAL _dbf_pkey_search
   LOCAL _field, nCount
   LOCAL cWhereString
   LOCAL _t_field, _t_field_dec
   LOCAL hDbfRec, hAlgoritam
   LOCAL cMsg
   LOCAL _alg_tag := ""
   LOCAL lRet
   LOCAL lIndex := .T.
   LOCAL lLock
   LOCAL hParams

   IF cTransaction == "FULL"
      lLock := .T.
   ELSE
      lLock := .F.
   ENDIF

   lRet := .T.

   set_table_values_algoritam_vars( @cTabela, @hRecord, @nAlgoritam, @cTransaction, @hDbfRec, @hAlgoritam, @cWhereString, @_alg_tag )

   IF Alias() <> hDbfRec[ "alias" ]
      cMsg := "ERR "  + RECI_GDJE_SAM0 + " ALIAS() = " + Alias() + " <> " + hDbfRec[ "alias" ]
      log_write( cMsg, 1 )
      error_bar( "del_rec", cMsg )
      RaiseError( cMsg )
   ENDIF

   // log_write( "delete rec server, poceo", 9 )

   IF  !hDbfRec[ "sql" ] .AND. cTransaction $ "FULL#BEGIN"
      run_sql_query( "BEGIN" )
      unlock_semaphore( cTabela )
      lock_semaphore( cTabela )
   ENDIF


   IF sql_table_update( cTabela, "del", NIL, cWhereString )

      IF hDbfRec[ "sql" ]
         DELETE
         RETURN .T.
      ELSE
         _full_id := get_dbf_rec_primary_key( hAlgoritam[ "dbf_key_fields" ], hRecord )
         AAdd( _ids, _alg_tag + _full_id )
         push_ids_to_semaphore( cTabela, _ids )

         SELECT ( hDbfRec[ "wa" ] )
         IF !Used()
            my_use( hDbfRec[ "table" ] )
         ENDIF
      ENDIF


      IF index_tag_num( hAlgoritam[ "dbf_tag" ] ) < 1
         IF !hDbfRec[ "sql" ]

            IF cTransaction == "FULL"
               run_sql_query( "ROLLBACK" )
               // unlock_semaphore( cTabela )
            ENDIF

            cMsg := "ERROR: " + RECI_GDJE_SAM0 + " tabela: " + cTabela + " DBF_TAG " + hAlgoritam[ "dbf_tag" ]
            error_bar( "del_rec", cMsg )
            ?E cMsg
            RaiseError( cMsg )
            RETURN .F.
         ELSE
            lIndex := .F.
         ENDIF
      ELSE
         lIndex := .T.
         SET ORDER TO TAG ( hAlgoritam[ "dbf_tag" ] )
      ENDIF

      IF my_flock()

         nCount := 0
         IF lIndex
            SEEK _full_id

            WHILE Found()
               ++nCount
               DELETE
               // sve dok budes nalazio pod ovim kljucem brisi
               SEEK _full_id
            ENDDO
         ELSE
            IF Alias() != "SIFV"
               DELETE
            ENDIF
         ENDIF

         my_unlock()

#ifdef F18_DEBUG_SYNC
         ?E "cTabela: " + cTabela + ", pobrisano iz lokalnog dbf-a broj zapisa = " + AllTrim( Str( nCount ) )
#endif

         IF cTransaction $ "FULL#END"
            hParams := hb_Hash()
            hParams[ "unlock" ] := { cTabela }
            run_sql_query( "COMMIT", hParams )
         ENDIF
         lRet := .T.

      ELSE

         IF cTransaction == "FULL"
            run_sql_query( "ROLLBACK" )
            cMsg := "delete rec server " + cTabela + " nije lockovana ! ROLLBACK"
            ?E cMsg
            Alert( cMsg )
         ENDIF
         lRet := .F.

      ENDIF

   ELSE

      IF cTransaction == "FULL"
         run_sql_query( "ROLLBACK" )
         cMsg := "delete rec server, " + cTabela + " transakcija neuspjesna ! ROLLBACK"
         Alert( cMsg )
         ?E cMsg
      ENDIF
      lRet := .F.

   ENDIF

   // log_write( "delete rec server, zavrsio", 9 )

   RETURN lRet




FUNCTION delete_all_dbf_and_server( cTabela )

   LOCAL _ids := {}
   LOCAL _pos
   LOCAL _field
   LOCAL cWhereString
   LOCAL hDbfRec
   LOCAL cMsg
   LOCAL hRec

   hDbfRec := get_a_dbf_rec( cTabela, .T. )
   reopen_exclusive( hDbfRec[ "table" ] )

   unlock_semaphore(  hDbfRec[ "table" ] )
   IF !lock_semaphore( hDbfRec[ "table" ] )
      RETURN .F.
   ENDIF
   run_sql_query( "BEGIN" )

   hRec := hb_Hash()
   hRec[ "id" ] := NIL


   IF sql_table_update( hDbfRec[ "table" ], "del", hRec, "true" )

      push_ids_to_semaphore( hDbfRec[ "table" ], { "#F" } )
      run_sql_query( "COMMIT" )
      unlock_semaphore( hDbfRec[ "table" ] )
      my_dbf_zap( hDbfRec[ "table" ] )

      RETURN .T.

   ELSE

      cMsg := cTabela + "transakcija neuspjesna ! ROLLBACK"
      Alert( cMsg )
      log_write( cMsg, 1 )

      run_sql_query( "ROLLBACK" )
      RETURN .F.

   ENDIF

   RETURN .T.


// --------------------------------------------------------------------------------------------------------------
// inicijalizacija varijabli koje koriste update and delete_from_server_and_dbf  funkcije
// ---------------------------------------------------------------------------------------------------------------
STATIC FUNCTION set_table_values_algoritam_vars( cTabela, hRecord, nAlgoritam, cTransaction, hDbfRec, hAlgoritam, where_str, alg_tag )

   LOCAL cKey
   LOCAL nCount := 0
   LOCAL _use_tag := .F.
   LOCAL cAlias
   LOCAL lSqlTable, uValue
   LOCAL cMsg

   IF cTabela == NIL
      cTabela := Alias()
   ENDIF

   hDbfRec := get_a_dbf_rec( cTabela )

   cTabela := hDbfRec[ "table" ]    // ako je alias proslijedjen kao ulazni parametar, prebaci se na dbf_table

   IF " _p" $ cTabela  // HACK "roba _p"
      cTabela := StrTran( cTabela, " _p", "" )
   ENDIF

   IF hRecord == NIL
      cAlias := Alias()
      hRecord := dbf_get_rec()
      IF ( hDbfRec[ "alias" ] != cAlias )
         RaiseError( "hRecord matrica razlicita od tabele ALIAS():" + cAlias + " cTabela=" + cTabela )
      ENDIF

   ENDIF

   IF nAlgoritam == NIL
      nAlgoritam = 1
   ENDIF


   IF cTransaction == NIL  // nema zapoceta transakcija
      cTransaction := "FULL"   // pocni i zavrsi trasakciju
   ENDIF


   hAlgoritam := hDbfRec[ "algoritam" ][ nAlgoritam ]
   lSqlTable := hDbfRec[ "sql" ]

   FOR EACH cKey in hAlgoritam[ "dbf_key_fields" ]

      ++nCount
      IF ValType( cKey ) == "C"

         IF !hb_HHasKey( hRecord, cKey )  // ne gledati numericke kljuceve, koji su array stavke
            AltD() // nepostojeci kljuc
            cMsg := RECI_GDJE_SAM + "# tabela:" + cTabela + "#bug - nepostojeći kljuc:" + cKey +  "#hRecord:" + pp( hRecord )
            log_write( cMsg, 1 )
            MsgBeep( cMsg )
            error_bar( "set_t_alg", cMsg )
            RETURN .F.
         ENDIF

         IF ValType( hRecord[ cKey ] ) == "C"

            // ako je dbf_fields_len['id'][2] = 6
            // karakterna polja se moraju PADR-ovati
            // hRecord['id'] = '0' => '0     '
            set_rec_from_dbstruct( @hDbfRec )


/* uvijek je  hRecord db_get_rec()  uvijek cp852 enkodiran
            uValue := Unicode():New( hRecord[ cKey ], lSqlTable ) // unicode value

            hRecord[ cKey ] := uValue:PadR( hDbfRec[ "dbf_fields_len" ][ cKey ][ 2 ] )
            IF !lSqlTable
               // DBFCDX tabela mora sadržati CP 852 string
               hRecord[ cKey ] := hb_UTF8ToStr( hRecord[ cKey ] )
            ENDIF
*/

            // provjeri prvi dio kljuca
            // ako je # onda obavezno setuj tag
            IF nCount == 1
               IF PadR( hRecord[ cKey ], 1 ) == "#"
                  _use_tag := .T.
               ENDIF
            ENDIF

         ENDIF

      ENDIF

   NEXT

   BEGIN SEQUENCE WITH {| err | err:cargo := { "var",  "hRecord", hRecord }, GlobalErrorHandler( err ) }
      where_str := sql_where_from_dbf_key_fields( hAlgoritam[ "dbf_key_fields" ], hRecord, lSqlTable )
   END SEQUENCE

   IF nAlgoritam > 1 .OR. _use_tag == .T.
      alg_tag := "#" + AllTrim( Str( nAlgoritam ) )
   ENDIF

   RETURN .T.
