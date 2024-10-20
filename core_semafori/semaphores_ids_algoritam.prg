/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

/*
 synchro dbf tabele na osnovu id-ova koje su poslali drugi
*/

FUNCTION ids_synchro( cTable )

   LOCAL nI, hIdsQueries
   LOCAL _zap, aDbfRec
   LOCAL lRet := NIL
   LOCAL cMsg
   LOCAL nIdsCnt := 0

#ifdef F18_DEBUG
   ?E "START IDS synchro", cTable
#endif

   aDbfRec := get_a_dbf_rec( cTable, .T. )
   hIdsQueries := create_queries_from_ids( aDbfRec[ "cTable" ] )

   IF hIdsQueries == NIL
#ifdef F18_DEBUG
      ?E "ERR IDS synchro", cTable, " hIdsQueries NIL?! "
#endif
      RETURN .F.
   ENDIF

   // hIdsQueries["ids"] = {  {"00113333 1", "0011333 2"}, {"00224444"}  }
   // hIdsQueries["qry"] = {  "select .... in ... rpad('0011333  1') ...", "select .. in ... rpad("0022444")" }

   // log_write( "START ids_synchro", 9 )
   // log_write( "ids_synchro ids_queries: " + pp( hIdsQueries ), 7 )

   DO WHILE .T.

      // ovo je posebni query koji se pojavi ako se nadje ids '#F'
      _zap := AScan( hIdsQueries[ "qry" ], "UZMI_STANJE_SA_SERVERA" )

      IF _zap <> 0

         full_synchro( cTable, 50000, " IDS: UZMI_STANJE_SA_SERVERA " )
         ADel( _zap, hIdsQueries[ "qry" ] )
         // ponovo kreiraj hIdsQueries u slucaju da je bilo jos azuriranja
         hIdsQueries := create_queries_from_ids( aDbfRec[ 'cTable' ] )

      ELSE
         EXIT
      ENDIF

   ENDDO

   FOR nI := 1 TO Len( hIdsQueries[ "ids" ] )

      IF hIdsQueries[ "ids" ][ nI ] != NIL // ako nema id-ova po algoritmu nI, onda ova varijabla NIL

         nIdsCnt += Len( hIdsQueries[ "ids" ][ nI ] )

#ifdef F18_DEBUG_SYNC
         ?E "ids_synchro ids_queries: [" + AllTrim( Str( nI ) ) + "]=" + pp( hIdsQueries[ "ids" ][ nI ]  )
#endif
         IF !delete_ids_in_dbf( aDbfRec[ 'cTable' ], hIdsQueries[ "ids" ][ nI ], nI )
            RETURN .F.
         ENDIF

         lRet := fill_dbf_from_server( aDbfRec[ 'cTable' ], hIdsQueries[ "qry" ][ nI ] )
         IF !lRet
            EXIT
         ENDIF

      ENDIF
   NEXT

   IF lRet != NIL

      cMsg := "syn ids: " + aDbfRec[ 'cTable' ] + " : " + AllTrim( Str( nIdsCnt ) )
      IF lRet
         info_bar( "syn_ids", cMsg )
      ELSE
         error_bar( "syn_ids", cMsg )
      ENDIF

   ELSE
      lRet := .T.
   ENDIF

   RETURN lRet


// -------------------------------------------------
// stavi id-ove za dbf tabelu na server
// -------------------------------------------------
FUNCTION push_ids_to_semaphore( cTable, aIds, lToMySelf )

   LOCAL _tbl
   LOCAL _result
   LOCAL _user := f18_user()
   LOCAL _ret
   LOCAL cQuery
   LOCAL _sql_ids
   LOCAL nI
   LOCAL _set_1, _set_2

   IF skip_semaphore_sync( cTable )
      RETURN .T.
   ENDIF

   IF Len( aIds ) < 1
      RETURN .T.
   ENDIF

   // stavi semafor i samom sebi
   IF lToMySelf == NIL
      lToMySelf := .F.
   ENDIF

   // log_write( "START push_ids_to_semaphore", 9 )
   // log_write( "push ids: " + cTable + " / " + pp( aIds ), 5 )

   _tbl := "sem." + Lower( cTable )

   // treba dodati id za sve DRUGE korisnike
   _result := table_count( _tbl, iif( lToMySelf, NIL, "user_code <> " + sql_quote( _user ) ) )

   IF _result < 1
      // jedan korisnik
      // log_write( "push_ids_to_semaphore: samo je jedan korisnik, nista nije pushirano", 9 )
      RETURN .T.
   ENDIF

   cQuery := ""

   FOR nI := 1 TO Len( aIds )
      _sql_ids := "ARRAY[" + sql_quote( aIds[ nI ] ) + "]"
      // full synchro
      IF aIds[ nI ] == "#F"
         // svi raniji id-ovi su nebitni
         // brisemo kompletnu tabelu - radimo full synchro
         _set_1 := "set ids = "
         _set_2 := ""
      ELSE
         // dodajemo postojece
         _set_1 := "SET ids = ids || "
         _set_2 := " AND ((ids IS NULL) OR NOT ( (" + _sql_ids + " <@ ids) OR ids = ARRAY['#F'] ) )"
      ENDIF

      cQuery += "UPDATE " + _tbl + " " + _set_1 + _sql_ids + " WHERE "
      IF !lToMySelf
         cQuery += "user_code <> " + sql_quote( _user )
      ELSE
         cQuery += "true"
      ENDIF
      cQuery +=  _set_2 + ";"

   NEXT

   // ako id sadrzi vise od 2000 stavki, korisnik je dugo neaktivan, pokreni full sync
   cQuery += "UPDATE " + _tbl + " SET ids = ARRAY['#F']  WHERE "
   IF !lToMySelf
      cQuery += "user_code <> " + sql_quote( _user ) + " AND "
   ENDIF
   cQuery += "ids IS NOT NULL AND array_length(ids,1) > 2000"

#ifdef F18_DEBUG_SYNC
   ?E "push_ids_to_semaphore", cQuery
#endif

   _ret := run_sql_query( cQuery )
   IF sql_error_in_query( _ret, "UPDATE" )
      error_bar( "syn_ids", "UPDATE push_ids: " + cTable )
      RETURN .F.
   ENDIF

   // log_write( "END push_ids_to_semaphore", 9 )


   IF !update_semaphore_version_after_push( cTable, lToMySelf ) // na kraju uraditi update verzije semafora, push operacija
      error_bar( "syn_ids", "push_ids: " + cTable )
      RETURN .F.
   ENDIF

   RETURN .T.


/*
  vrati matricu id-ova za dbf tabelu
*/

FUNCTION get_ids_from_semaphore( cTable )

   LOCAL _tbl
   LOCAL _tbl_obj, _update_obj, oQry
   LOCAL cQuery
   LOCAL cIds, _num_arr, _arr, nI
   LOCAL _user := f18_user()
   LOCAL _tok, _versions, _tmp
   LOCAL _log_level := log_level()
   LOCAL lAllreadyInTransaction := .F.
   LOCAL hParams := hb_Hash()
   LOCAL _server := sql_data_conn()
   LOCAL cLogMsg := "", cMsg
   LOCAL nCnt := 0

   IF skip_semaphore_sync( cTable )
      RETURN .T.
   ENDIF

   // IF _server:TransactionStatus() > 0
   // lAllreadyInTransaction := .T.
   // ENDIF

   // log_write( "START get_ids_from_semaphore", 7 )

   _tbl := "sem." + Lower( cTable )
   hParams[ "tran_name" ] := "ids_" + cTable
   hParams[ "retry" ] := 1

   // IF !lAllreadyInTransaction
   DO WHILE nCnt < 10

      nCnt ++
#ifdef F18_DEBUG_SYNC
      ?E "BEGIN SET TRANS ISOLATION LSER", cTable, nCnt
#endif
      oQry := run_sql_query( "BEGIN; SET TRANSACTION ISOLATION LEVEL SERIALIZABLE", hParams )
      IF sql_error_in_query( oQry, "BEGIN" )
         run_sql_query( "ROLLBACK", hParams )
         LOG_CALL_STACK cLogMsg
         ?E cLogMsg
         error_bar( "sem", "IDS ROLLBACK BEGIN " + cTable + " / " + AllTrim( Str( nCnt ) ) )
         LOOP
      ENDIF


#ifdef F18_DEBUG_AZUR
      // uzmi verziju i stanje iz semafora prije pocetka
      _versions := get_semaphore_version_h( Lower( cTable ) )
      _tmp := "prije SELECT, tabela: " + Lower( cTable )
      _tmp += " version: " + AllTrim( Str( _versions[ "version" ] ) )
      _tmp += " last version: " + AllTrim( Str( _versions[ "last_version" ] ) )

      ?E _tmp

#endif

      cQuery := "SELECT ids FROM " + _tbl + " WHERE user_code=" + sql_quote( _user )
      _tbl_obj := run_sql_query( cQuery )
      IF sql_error_in_query( _tbl_obj, "SELECT" )
         run_sql_query( "ROLLBACK", hParams )
         LOG_CALL_STACK cLogMsg
         ?E cLogMsg
         error_bar( "sem", "IDS ROLLBACK SELECT " + cTable + " / " + AllTrim( Str( nCnt ) ) )
         LOOP

      ENDIF

      cQuery := "UPDATE " + _tbl + " SET  ids=NULL, dat=NULL, version=last_trans_version"
      cQuery += " WHERE user_code =" + sql_quote( _user )
      _update_obj := run_sql_query( cQuery )
      IF sql_error_in_query( _update_obj, "UPDATE" )
         run_sql_query( "ROLLBACK", hParams )
         LOG_CALL_STACK cLogMsg
         ?E cLogMsg
         error_bar( "sem", "IDS ROLLBACK UPDATE " + cTable + " / " + AllTrim( Str( nCnt ) ) )
         LOOP
      ENDIF

#ifdef F18_DEBUG
      // IF _log_level > 6

      _versions := get_semaphore_version_h( Lower( cTable ) ) // uzmi verziju i stanje verzija na kraju transakcije

      _tmp := "nakon UPDATE, tabela: " + Lower( cTable )
      _tmp += " version: " + AllTrim( Str( _versions[ "version" ] ) )
      _tmp += " last version: " + AllTrim( Str( _versions[ "last_version" ] ) )

      // log_write( _tmp, 7 )
      // ENDIF
#endif

      // IF !lAllreadyInTransaction
      run_sql_query( "COMMIT", hParams )
      // ENDIF

      cIds := _tbl_obj:FieldGet( 1 )

      _arr := {}
      IF cIds == NIL
         RETURN _arr
      ENDIF

      cIds := hb_UTF8ToStr( cIds )
      // {id1,id2,id3}
      cIds := SubStr( cIds, 2, Len( cIds ) -2 )

      _num_arr := NumToken( cIds, "," )

      FOR nI := 1 TO _num_arr
         _tok := Token( cIds, ",", nI )
         IF Left( _tok, 1 ) == '"' .AND. Right( _tok, 1 ) == '"'
            // odsjeci duple navodnike "..."
            _tok := SubStr( _tok, 2, Len( _tok ) -2 )
         ENDIF
         AAdd( _arr, _tok )
      NEXT

      // log_write( "END get_ids_from_semaphore", 7 )
      EXIT
   ENDDO

   RETURN _arr



// ---------------------------------------------------------------------------------------------------------
// napraviti array qry, za sve dostupne ids algoritme
//
// ret["qry"] := { "select .... where .. uslov za podsifra ..", "select ... where ... uslov za sifra .." }
// ret["ids"] := { "01/1", "01/2" }, {"03", "04"}
//
// u gornjem primjeru imamo dva algoritma i dva seta ids-ova - prvi na nivou sifra/podsifra ("01/1", "01/2")
// a drugi na nivou sifre "01", "04"
//
// algoritmi se nalaze u hash varijabli koju nam vraca funkcija f18_dbfs()
// set_a_dbf... funkcije definišu tu hash varijablu
//
// ova util funkcija daje nam id-ove i sql queries potrebne da
// sinhroniziramo dbf sa promjenama koje su napravili drugi korisnici
// -------------------------------------------------------------------------------------------------------------
FUNCTION create_queries_from_ids( cTable )

   LOCAL aDbfRec, _msg
   LOCAL _queries     := {}
   LOCAL _ids, _ids_2 := {}
   LOCAL _sql_ids := {}
   LOCAL nI, _id
   LOCAL _ret := hb_Hash()
   LOCAL _sql_fields
   LOCAL _algoritam, _alg
   LOCAL _sql_tbl

   IF skip_semaphore_sync( cTable )
      RETURN .T.
   ENDIF

   aDbfRec := get_a_dbf_rec( cTable, .F. )

   _sql_fields := sql_fields( aDbfRec[ "dbf_fields" ] )
   _alg := aDbfRec[ "algoritam" ]

   _sql_tbl := f18_sql_schema( cTable )

   FOR nI := 1 TO Len( _alg )
      AAdd( _queries, "SELECT " + _sql_fields + " FROM " + _sql_tbl + " WHERE " )
      AAdd( _sql_ids, NIL )
      AAdd( _ids_2, NIL )
   NEXT

   // IF lock_semaphore( cTable )
   _ids := get_ids_from_semaphore( cTable )
   // unlock_semaphore( cTable )
   // ELSE
   // RETURN .F.
   // ENDIF

   IF _ids == NIL
      ?E "ERR IDS create_queries_from_ids = NIL?"
      RETURN NIL
   ENDIF
   // nuliraj_ids_and_update_my_semaphore_ver(cTable)

   // log_write( "create_queries..(), poceo", 9 )

   // primjer
   // suban 00-11-2222 rbr 1, rbr 2
   // kompletan nalog (#2) 00-11-3333
   // Full synchro (#F)
   // _ids := { "00112222 1", "00112222 2", "#200113333", "#F" }

   FOR EACH _id in _ids

      IF Left( _id, 1 ) == "#"

         IF SubStr( _id, 2, 1 ) == "F"
            // full sinchro
            _algoritam := 99
            _id := "X"
         ELSE
            // algoritam "#2" => algoritam 2
            _algoritam := Val( SubStr( _id, 2, 1 ) )
            _id := SubStr( _id, 3 )
         ENDIF

      ELSE
         _algoritam := 1
      ENDIF

      IF _algoritam == 99
         // full sync zahtjev
         AAdd( _queries, "UZMI_STANJE_SA_SERVERA" )
         AAdd( _sql_ids, NIL )
      ELSE
         // ne moze biti "#3" a da tabela ima definisana samo dva algoritma
         IF _algoritam > Len( _alg )
            _msg := "nasao sam ids " + _id + ". Ovaj algoritam nije podrzan za " + cTable
            Alert( _msg )
#ifdef F18_DEBUG
            ?E "create_queries " + _msg
#endif
            RaiseError( _msg )
            QUIT_1
         ENDIF

         IF _sql_ids[ _algoritam ] == NIL
            _sql_ids[ _algoritam ] := "("
            _ids_2[ _algoritam ] := {}
         ENDIF

         _sql_ids[ _algoritam ] += sql_quote( _id ) + ","
         AAdd( _ids_2[ _algoritam ], _id )

      ENDIF
   NEXT

   FOR nI := 1 TO Len( _alg )

      IF _sql_ids[ nI ] != NIL
         // odsjeci zarez na kraju
         _sql_ids[ nI ] := Left( _sql_ids[ nI ], Len( _sql_ids[ nI ] ) - 1 )
         _sql_ids[ nI ] += ")"
         _queries[ nI ] +=  "(" + _alg[ nI ][ "sql_in" ]  + ") IN " + _sql_ids[ nI ]
      ELSE
         _queries[ nI ] := NIL
      ENDIF

   NEXT

   // log_write( "create_queries ret[qry]=" + pp( _queries ), 9 )
   // log_write( "create_queries ret[ids]=" + pp( _ids_2 ), 9 )
   // log_write( "create_queries zavrsio", 9 )
   _ret[ "qry" ] := _queries
   _ret[ "ids" ] := _ids_2

   RETURN _ret




// ------------------------------------------------------
// sve ids-ove pobrisi iz dbf-a
// ids       := {"#20011", "#2012"}
// algoritam := 2
// ------------------------------------------------------
FUNCTION delete_ids_in_dbf( cTable, ids, nAlgoritam )

   LOCAL aDbfRec, _alg
   LOCAL _counter
   LOCAL _fnd, _tmp_id, _rec
   LOCAL _dbf_tag
   LOCAL _key_block
   LOCAL cSyncAlias, cFullDbf, cFullIdx

   // log_write( "delete_ids_in_dbf START", 9 )

   aDbfRec := get_a_dbf_rec( cTable )

   IF skip_semaphore_sync( aDbfRec[ "cTable" ] )
      RETURN .T.
   ENDIF

   _alg := aDbfRec[ "algoritam" ]
   _dbf_tag := _alg[ nAlgoritam ][ "dbf_tag" ]
   _key_block := _alg[ nAlgoritam ][ "dbf_key_block" ]

   _counter := 0

   IF ValType( ids ) != "A"
      Alert( "ids type ? " + ValType( ids ) )
   ENDIF

   cSyncAlias := Upper( 'SYNC__' + aDbfRec[ 'cTable' ] )
   PushWa()

   cFullDbf := my_home() + aDbfRec[ 'cTable' ]
   cFullIdx := ImeDbfCDX( cFullDbf )

   IF Select( cSyncAlias ) == 0
      SELECT ( aDbfRec[ 'wa' ] + 1000 )
      USE ( cFullDbf ) Alias ( cSyncAlias ) SHARED
      IF File( cFullIdx )
         dbSetIndex( cFullIdx )
      ENDIF
   ELSE
      Alert( "sync alias used ?:" + cSyncAlias )
      log_write( "error sync alias used " + cSyncAlias, 2 )
   ENDIF

   // pobrisimo sve dbf zapise na kojima su drugi radili

   SET ORDER TO TAG ( _dbf_tag )
   IF Empty( ordName() )
      Alert( "delete ordname error: " + Alias() + " / " + _dbf_tag )
      QUIT_1
   ENDIF

   DO WHILE .T.

      _fnd := .F.
      FOR EACH _tmp_id in ids

         HSEEK _tmp_id
         DO WHILE !Eof() .AND. Eval( _key_block ) == _tmp_id
            SKIP
            _rec := RecNo()
            SKIP -1
            delete_with_rlock()
            GO _rec

            _fnd := .T.
            ++ _counter
         ENDDO
      NEXT

      IF !_fnd
         EXIT
      ENDIF
   ENDDO

   IF Select( cSyncAlias ) > 0
      USE
   ENDIF

   PopWa()

   // log_write( "delete_ids_in_dbf cTable: " + cTable + "/ dbf_tag =" + _dbf_tag + " pobrisao iz lokalnog dbf-a zapisa = " + AllTrim( Str( _counter ) ), 5 )
   // log_write( "delete_ids_in_dbf END", 9 )

   RETURN .T.


// ----------------------------------------------------------
// util funkcija za ids algoritam kreira dbf kljuc potreban
// za brisanje zapisa koje su drugi mijenjali
//
// dbf_fields - {"id", {"iznos", 12, 2} }
// hRec - { "01", 15.5 }
//
// => "01       15.50"
// ----------------------------------------------------------
FUNCTION get_dbf_rec_primary_key( hDbfKeyFields, hRec )

   LOCAL xField, cFieldName, nFieldDecimalnihMjesta
   LOCAL cKljuc := ""

   FOR EACH xField in hDbfKeyFields

      IF ValType( xField ) == "A"
         cFieldName := xField[ 1 ]
         nFieldDecimalnihMjesta := xField[ 2 ]
         cKljuc += Str( hRec[ cFieldName ], nFieldDecimalnihMjesta )
      ELSE
         cFieldName := xField
         IF ValType( hRec[ cFieldName ] ) == "D"
            cKljuc += DToS( hRec[ cFieldName ] )
         ELSE
            cKljuc += hRec[ cFieldName ] // hRec[ "id" ]
         ENDIF
      ENDIF

   NEXT

   RETURN cKljuc
