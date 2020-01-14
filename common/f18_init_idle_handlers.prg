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
#include "f18_color.ch"

STATIC aIdleHandlers := {}
STATIC s_nIdleRefresh := 0 // start idle refresh in seconds()
STATIC s_nIdleDisplayCounter := 0 // counter
STATIC s_lNoRefreshOperation := .F.
STATIC s_nFinNalogCount := 0

FUNCTION add_global_idle_handlers()

   if is_electron_host()
       RETURN .T.
   endif

   AAdd( aIdleHandlers, hb_idleAdd( {||  pq_receive() } ) )

   // AAdd( aIdleHandlers, hb_idleAdd( {||  hb_DispOutAt( f18_max_rows(),  f18_max_cols() - 8, Time(), F18_COLOR_INFO_PANEL ) } ) )

   RETURN .T.

PROCEDURE pq_receive()

LOCAL nRow, nCol
    //? "START PQ_RECEIVE"
    LOCAL aNotify := PQReceive( sql_data_conn():pDB )
    // hb_idleSleep(5)
    //? "KRAJ PQ_RECEIVE"

    //nRow := hb_RandomInt( 0, f18_max_rows())
    //nCol := hb_RandomInt( 0, f18_max_cols())
    //@ nRow, nCol  SAY "hello"
    //?E nRow, nCol

    IF aNotify != NIL
       // ? pp( aNotify )
       error_bar( "notify", pp(aNotify) )
    ENDIF

   RETURN


/*
    1) procesiranje dbf_refresh_queue-a
    2) dbf refresh tekuce tabele, na osnovu aliasa
*/

PROCEDURE on_idle_dbf_refresh()

   LOCAL cAlias, aDBfRec, oQry

   IF s_nIdleRefresh > 0
      IF Seconds() - s_nIdleDisplayCounter > 15
         ?E "already in idle dbf refresh", Seconds(), s_nIdleRefresh
         s_nIdleDisplayCounter := Seconds()
      ENDIF
      RETURN

   ELSE

      s_nIdleRefresh := Seconds()
      IF Seconds() - s_nIdleDisplayCounter > 15
#ifdef F18_DEBUG_THREAD
         ?E "START in idle dbf refresh", Seconds()
#endif
         s_nIdleDisplayCounter := Seconds()
      ENDIF
   ENDIF


   IF is_in_main_thread_sql_transaction()
      IF Seconds() - s_nIdleDisplayCounter > 15
         ?E "in sql transaction - dbf refresh otkazati"
         s_nIdleDisplayCounter := Seconds()
      ENDIF
      s_nIdleRefresh := 0
      RETURN
   ENDIF

   IF my_database() == "?undefined?"
      s_nIdleRefresh := 0
      RETURN
   ENDIF

   IF in_cre_all_dbfs()
      s_nIdleRefresh := 0
      RETURN
   ENDIF

   IF in_no_refresh_operations()
      s_nIdleRefresh := 0
      RETURN
   ENDIF

   update_fin_nalog_count()
   process_dbf_refresh_queue()

   cAlias := Alias()

   IF Empty( cAlias ) .OR. ( my_rddName() != DBFENGINE )
      s_nIdleRefresh := 0
      RETURN
   ENDIF

   aDbfRec := get_a_dbf_rec( cAlias, .T. )

   IF aDBfRec == NIL
      RETURN
   ENDIF

   IF we_need_dbf_refresh( aDbfRec[ "table" ] )
      thread_dbfs( hb_threadStart(  @thread_dbf_refresh(), aDbfRec[ "table" ] ) )
#ifdef F18_DEBUG_THREAD
      ?E "alias_dbf_refresh thread start", aDbfRec[ "table" ], "main thread:", main_thread()
#endif
#ifdef F18_DEBUG_THREAD
   ELSE
      ?E "alias_dbf_refresh ne treba", aDbfRec[ "table" ]
#endif

   ENDIF

   s_nIdleRefresh := 0

   RETURN


PROCEDURE update_fin_nalog_count()

   /*
   LOCAL oQry

   IF my_database() != "?undefined?" .AND. my_login():lOrganizacijaSpojena
    --  oQry := run_sql_query( "SELECT count(*) from fmk.fin_nalog" )
      IF sql_error_in_query( oQry, "SELECT" )
         MsgBeep( "ERR fin_nalog ne postoji?! " + my_database() )
         QUIT
      ENDIF
      s_nFinNalogCount := oQry:FieldGet( 1 )
      IF ValType( s_nFinNalogCount ) != "N"
         RETURN
      ENDIF
      hb_DispOutAt( f18_max_rows() + 1,  f18_max_cols() - 10, "FIN.Nal.Cnt: " + AllTrim( Str( fin_nalog_count() ) ), F18_COLOR_INFO_PANEL )
   ENDIF
   */

   RETURN

FUNCTION fin_nalog_count()
   RETURN s_nFinNalogCount


PROCEDURE stop_refresh_operations()

   s_lNoRefreshOperation := .T.

   RETURN

PROCEDURE dbf_refresh_stop()

   stop_refresh_operations()

   RETURN


PROCEDURE start_refresh_operations()

   s_lNoRefreshOperation := .F.

   RETURN


PROCEDURE dbf_refresh_start()

   start_refresh_operations()

   RETURN


FUNCTION in_no_refresh_operations()

   RETURN s_lNoRefreshOperation


FUNCTION remove_global_idle_handlers()

   AEval( aIdleHandlers, {| pHandlerID | hb_idleDel( pHandlerID ) } )
   aIdleHandlers := {}

   RETURN .T.


INIT PROCEDURE idle_init()
   //OutStd('init-1' + hb_eol())
   RETURN
