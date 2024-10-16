/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC s_nThreadCount := 0
STATIC s_mtxMutex
STATIC s_mainThreadID
STATIC s_aThreads
STATIC s_aEval := {}
STATIC s_aQueueDbfRefresh := {}
STATIC s_nProcessQueueSeconds := 0

PROCEDURE f18_init_threads()

   s_mainThreadID := hb_threadSelf()
   s_mtxMutex := hb_mutexCreate()
   s_aThreads := {}

   RETURN


FUNCTION main_thread()

   RETURN s_mainThreadID


FUNCTION is_in_main_thread()

   RETURN hb_threadSelf() == main_thread()


FUNCTION open_thread( cInfo, lOpenSQLConnection, cTable )

   LOCAL nCounter := 0

   hb_default( @lOpenSQLConnection, .T. )

#ifdef F18_DEBUG_THREAD
   ?E "open_thread func start", cInfo, lOpenSQLConnection, cTable
#endif

   DO WHILE s_nThreadCount > MAX_THREAD_COUNT

      ++nCounter

#ifdef F18_DEBUG_THREAD
      IF nCounter % 1000 == 0
         ?E Time(), cInfo, "thread count>", MAX_THREAD_COUNT, " (", AllTrim( Str( s_nThreadCount ) ), ")"
         print_threads( "thread_cnt_max" + cInfo )
      ENDIF
#endif
      IF cTable != NIL .AND. nCounter > 10000
         add_to_dbf_refresh_queue( cTable ) // refresh se ne moze trenutno napraviti, staviti u queue
         RETURN .F.
      ENDIF

      IF nCounter % 2000 == 0
         ?E Time(), "max threads limit reached (", AllTrim( Str( s_nThreadCount ) ), ") waiting ... ", cInfo, "/", nCounter
         hb_idleSleep( 0.5 )
      ENDIF


   ENDDO
#ifdef F18_DEBUG_THREAD
   ?E ">>>>> START: thread: ", cInfo, " cnt:(", AllTrim( Str( s_nThreadCount ) ), ") in main_thread:", is_in_main_thread(), " <<<<<"
#endif

   add_thread( cInfo )

   IF lOpenSQLConnection
      IF !my_server_login()
         remove_thread( hb_threadSelf(), cInfo )
         error_bar( "thread", "login error: " + cInfo )
         RETURN .F.
      ENDIF
      set_sql_search_path()
      set_f18_home( my_server_params()[ "database" ] )

   ELSE // hernad 06.04.2016: trenutno nema thread-ova bez svojih konekcija
      idle_add_for_eval( "my_home", {||  my_home() } )
      // idle_add_for_eval( "my_server_params", {||  my_server_params() } )
      my_home( idle_get_eval( "my_home" ) ) // my_home iz glavnog thread-a
      // my_server_params( idle_get_eval( "my_server_params" ) )
      my_server_params()

   ENDIF

   init_parameters_cache()

   RETURN .T.



FUNCTION is_in_dbf_refresh_queue( cTable )

   LOCAL nPos

   // IF hb_mutexLock( s_mtxMutex )
   nPos := AScan( s_aQueueDbfRefresh, {| aItem |  ValType( aItem ) == "A" .AND. aItem[ 1 ] == my_database() .AND. aItem[ 2 ] == cTable } )
   // hb_mutexUnlock( s_mtxMutex )

   RETURN  ( nPos > 0 )
// ENDIF

   RETURN .F.


FUNCTION add_to_dbf_refresh_queue( cTable )

   LOCAL nPos, lRet := .F.

#ifdef F18_DEBUG_SYNC

   ?E "add_to_dbf_refresh_queue", cTable
#endif

   IF cTable == NIL
      RETURN .F.
   ENDIF

   IF hb_mutexLock( s_mtxMutex )
      nPos := AScan( s_aQueueDbfRefresh, {| aItem |  ValType( aItem ) == "A" .AND. aItem[ 1 ] == my_database() .AND. aItem[ 2 ] == cTable } )
      IF nPos == 0
         AAdd( s_aQueueDbfRefresh, { my_database(), cTable } )
         lRet := .T.
      ENDIF
      hb_mutexUnlock( s_mtxMutex )
   ENDIF
#ifdef F18_DEBUG_SYNC
   ?E "END add_to_dbf_refresh_queue", cTable, lRet
#endif

   RETURN lRet


FUNCTION remove_from_dbf_refresh_queue( cDatabase, cTable )

   LOCAL nPos, lRet := .F.

   IF cTable == NIL
      RETURN .F.
   ENDIF

   IF hb_mutexLock( s_mtxMutex )
      nPos := AScan( s_aQueueDbfRefresh, {| aItem |  ValType( aItem ) == "A" .AND. aItem[ 1 ] == cDatabase .AND. aItem[ 2 ] == cTable } )
      IF nPos > 0
         ADel( s_aQueueDbfRefresh, nPos )
         ASize( s_aQueueDbfRefresh, Len( s_aQueueDbfRefresh ) - 1 )
         lRet := .T.
      ENDIF
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   RETURN lRet



PROCEDURE process_dbf_refresh_queue()

   LOCAL aItem, nQLength := 0, nQLength2 := 0, nQLength3 := 0
   LOCAL cTable

   IF ( Seconds() - s_nProcessQueueSeconds ) < ( MIN_LAST_REFRESH_SEC * 2 )
      RETURN
   ENDIF


   FOR EACH aItem IN s_aQueueDbfRefresh
      IF ValType( aItem ) == "A"
         // info_bar( "idle", "dbf refresh queue " + aItem[ 1 ] + " " + aItem[ 2 ] )
         IF aItem[ 1 ] == my_database()
            cTable := aItem[ 2 ]
            IF we_need_dbf_refresh( cTable )
               remove_from_dbf_refresh_queue( aItem[ 1 ],  cTable )
               thread_dbfs( hb_threadStart(  @thread_dbf_refresh(), cTable ) )
               nQLength++
            ENDIF
         ELSE
            nQLength2++
         ENDIF

      ELSE
         error_bar( "idle", "dbf refresh queue != A?!" )
         nQLength3++
      ENDIF
   NEXT
   IF nQLength != 0 .OR. nQLength2 != 0 .OR. nQLength3 != 0
      info_bar( "idle", "dbf refresh queue " + AllTrim( Str( nQLength ) ) + "/" + AllTrim( Str( nQLength2 ) ) + "/" + AllTrim( Str( nQLength3 ) ) )
   ENDIF

   s_nProcessQueueSeconds := Seconds()

   RETURN


PROCEDURE close_thread( cInfo )

   remove_thread( hb_threadSelf(), cInfo )

#ifdef F18_DEBUG_THREAD
   ?E "<<<<<< END: thread", cInfo, "thread count:", s_nThreadCount
#endif

   my_server_close()

   RETURN



STATIC PROCEDURE add_thread( cInfo )

   LOCAL lSet := .F.

#ifdef F18_DEBUG_THREAD

   ?E "add_thread start:", cInfo
   print_threads( "open_thread:" + cInfo )
#endif

   DO WHILE !lSet

      IF hb_mutexLock( s_mtxMutex )
         lSet := .T.
         AAdd( s_aThreads, { hb_threadSelf(), cInfo, Time() } )
         s_nThreadCount++
         hb_mutexUnlock( s_mtxMutex )
#ifdef F18_DEBUG_THREAD
      ELSE
         ?E "add_thread mutex lock error:", cInfo
#endif
      ENDIF
   ENDDO

#ifdef F18_DEBUG_THREAD
   ?E "add_thread end:", cInfo
#endif

   RETURN


STATIC FUNCTION remove_thread( pThread, cInfo )

   LOCAL lSet := .F., nPos

#ifdef F18_DEBUG_THREAD

   ?E "remove_thread start:", pThread, cInfo
#endif

   DO WHILE !lSet

#ifdef F18_DEBUG_THREAD
      print_threads( "close_thread:" + cInfo )
#endif
      IF hb_mutexLock( s_mtxMutex )
         nPos := AScan( s_aThreads, {| aItem | ValType( aItem ) == "A" .AND. aItem[ 1 ] == pThread } )
         IF nPos > 0
            s_nThreadCount--
            ADel( s_aThreads, nPos )
            ASize( s_aThreads, Len( s_aThreads ) - 1 )
         ELSE
            ?E "ERR: thread nije u listi:", hb_threadSelf()
         ENDIF
         lSet := .T.
         hb_mutexUnlock( s_mtxMutex )
      ENDIF
   ENDDO

   RETURN lSet


PROCEDURE print_threads( cInfo )

   LOCAL aThread

   IF hb_mutexLock( s_mtxMutex )
      ?E "THREADS:", Time(), Seconds(), cInfo
      ?E Replicate( "-", 80 )
      FOR EACH aThread IN s_aThreads
         IF ValType( aThread ) == "A"
            ?E s_nThreadCount, aThread[ 3 ], aThread[ 1 ], aThread[ 2 ]
         ELSE
            ?E s_nThreadCount,  ValType( aThread ),  aThread
         ENDIF
      NEXT
      ?E Replicate( ".", 80 )
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   RETURN


FUNCTION print_dbf_refresh_queue()

   LOCAL aItem, nCount := 0

   ?E "DBF refresh queue:"
   ?E Replicate( "Q", 50 )
   FOR EACH aItem IN s_aQueueDbfRefresh
      IF ValType( aItem ) == "A"
         ?E ++nCount, aItem[ 1 ], aItem[ 2 ]
      ELSE
         ?E "dbf refresh queue item != A?!"
      ENDIF
   NEXT
   ?E Replicate( "q", 60 )

   RETURN .T.

PROCEDURE idle_add_for_eval( cId, bExpression )

   IF hb_mutexLock( s_mtxMutex )
      AAdd( s_aEval, { "X", cId, bExpression, NIL } )
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   RETURN


/*
    EVAL
*/
PROCEDURE idle_eval()

   LOCAL aItem

   IF hb_mutexLock( s_mtxMutex )

      FOR EACH aItem IN s_aEval
         IF aItem[ 1 ] == "X"
            aItem[ 4 ] := Eval( aItem[ 3 ] )
            aItem[ 1 ] := "OK"
         ENDIF
      NEXT
      hb_mutexUnlock( s_mtxMutex )
   ENDIF

   RETURN


/*
      ?E "IDLE ADD EVAL 1+1"
      idle_add_for_eval( "1+1", { || 1 + 1 } )
      ?E "IDLE GET EVAL 1+1:", idle_get_eval( "1+1" )
      idle_add_for_eval( "count konto", {|| table_count( "konto") } )
      info_bar("idle", "IDLE GET EVAL count konto:" +  hb_ValToStr( idle_get_eval( "count konto" ) ) )
*/

FUNCTION idle_get_eval( cId )

   LOCAL nPos := 0, xRet

   DO WHILE nPos == 0

      nPos := AScan( s_aEval, {| aItem | aItem[ 2 ] == cId .AND. aItem[ 1 ] == "OK" } )
      IF nPos > 0

         IF hb_mutexLock( s_mtxMutex )
            xRet := s_aEval[ nPos, 4 ]
            ADel( s_aEval, nPos )
            ASize( s_aEval, Len( s_aEval )  - 1 )
            hb_mutexUnlock( s_mtxMutex )
         ENDIF

      ELSE
         hb_idleSleep( 0.5 )
      ENDIF
   ENDDO

   RETURN xRet
