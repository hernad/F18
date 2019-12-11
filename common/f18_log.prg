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


STATIC s_psqlServer_log := .F. // logiranje na server

#ifdef F18_DEBUG
STATIC s_nLogLevel := F18_DEFAULT_LOG_LEVEL_DEBUG
#else
STATIC s_nLogLevel := F18_DEFAULT_LOG_LEVEL
#endif


PROCEDURE F18_OutErr( ... )
  LOCAL nI, cMsg

  cMsg := hb_PValue( 1 )
  FOR nI := 2 TO PCount()
      cMsg += " " + hb_ValToStr( hb_PValue( nI ) )
  NEXT

  log_write_file( cMsg )
RETURN

FUNCTION log_level( nLevel )

   IF ValType( nLevel ) == "N"
      s_nLogLevel := nLevel
   ENDIF

   RETURN s_nLogLevel



   FUNCTION log_write( cMsg, nLevel, lSilent )

      LOCAL cMsgTime
   
      IF nLevel == NIL
   #ifdef F18_DEBUG
         nLevel := F18_DEFAULT_LOG_LEVEL_DEBUG
   #else
         nLevel := F18_DEFAULT_LOG_LEVEL
   #endif
      ENDIF
   
      IF lSilent == NIL
         lSilent := .F.
      ENDIF
   
      IF nLevel > log_level()
         RETURN .T.
      ENDIF
   
      cMsgTime := DToC( Date() )
      cMsgTime += ", "
      cMsgTime += PadR( Time(), 8 )
      cMsgTime += ": "
   
      //?E cMsgTime, cMsg
   
      IF server_log()
         server_log_write( cMsg, lSilent )
      ENDIF
   
      RETURN .T.
   
   
   FUNCTION danasnji_log_file()

      RETURN my_home_root() + "F18_" + DToS( Date() ) + ".log"
   
   
   FUNCTION log_write_file( cMsg, nLevel, lSilent )
   
      LOCAL cMsgTime
      LOCAL cLogFile := danasnji_log_file()
      LOCAL nHandle
   
      IF nLevel == NIL
   #ifdef F18_DEBUG
         nLevel := F18_DEFAULT_LOG_LEVEL_DEBUG
   #else
         nLevel := F18_DEFAULT_LOG_LEVEL
   #endif
      ENDIF
   
      IF lSilent == NIL
         lSilent := .F.
      ENDIF
   
      IF nLevel > log_level()
         RETURN .T.
      ENDIF
   
      IF !File( cLogFile )
         nHandle := hb_vfOpen( cLogFile, FO_CREAT + FO_TRUNC + FO_WRITE )
      ELSE
         nHandle := hb_vfOpen( cLogFile, FO_WRITE )
         hb_vfSeek( nHandle, 0, FS_END )
      ENDIF
   
      cMsgTime := PadR( Time(), 8 )
      cMsgTime += ": "
   
      hb_vfWrite( nHandle, cMsgTime + cMsg + hb_eol() )
      hb_vfClose( nHandle )
   
      //?E cMsgTime + cMsg
   
      RETURN .T.
   
   


FUNCTION server_log()
   RETURN s_psqlServer_log


FUNCTION server_log_disable()

   s_psqlServer_log := .F.
   RETURN .T.


FUNCTION server_log_enable()

   s_psqlServer_log := .T.
   RETURN .T.

FUNCTION f18_view_log( hParams )

   LOCAL oData
   LOCAL lPrintToFile := .F.
   LOCAL cLogFile

   IF PCount() > 0
      lPrintToFile := .T.
   ENDIF

   IF hParams == NIL .AND. !uslovi_pregleda_loga( @hParams )
      RETURN .F.
   ENDIF

   oData := query_log_data( hParams )
   cLogFile := print_log_data( oData, hParams, lPrintToFile )

   RETURN cLogFile




STATIC FUNCTION uslovi_pregleda_loga( hParams )

   LOCAL lOk := .F.
   LOCAL nLimit := 0
   LOCAL _datum_od := Date()
   LOCAL _datum_do := Date()
   LOCAL cUser := PadR( f18_user(), 200 )
   LOCAL nX := 1
   LOCAL _conds_true := Space( 600 )
   LOCAL _conds_false := Space( 600 )
   LOCAL cSamoOperacijeNaDokumentimaDN := "N"
   LOCAL GetList := {}

   Box(, 12, 70 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Uslovi za pregled log-a..."

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od" GET _datum_od
   @ box_x_koord() + nX, Col() + 1 SAY "do" GET _datum_do

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Korisnik (prazno svi):" GET cUser PICT "@S40"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "LIKE uslovi:"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "  sadrži:" GET _conds_true PICT "@S40"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "nesadrži:" GET _conds_false PICT "@S40"

   ++ nX
   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Pregledaj samo operacije nad dokumentima (D/N)?" GET cSamoOperacijeNaDokumentimaDN VALID cSamoOperacijeNaDokumentimaDN $ "DN" PICT "@!"

   ++ nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Limit na broj zapisa (0-bez limita)" GET nLimit PICT "999999"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN lOk
   ENDIF

   lOk := .T.

   IF !Empty( _conds_true )
      _conds_true := AllTrim( _conds_true ) + Space( 1 )
   ELSE
      _conds_true := ""
   ENDIF

   IF !Empty( _conds_false )
      _conds_false := AllTrim( _conds_false ) + Space( 1 )
   ELSE
      _conds_false := ""
   ENDIF

   hParams := hb_Hash()
   hParams[ "date_from" ] := _datum_od
   hParams[ "date_to" ] := _datum_do
   hParams[ "user" ] := AllTrim( cUser )
   hParams[ "limit" ] := nLimit
   hParams[ "conds_true" ] := _conds_true
   hParams[ "conds_false" ] := _conds_false
   hParams[ "doc_oper" ] := cSamoOperacijeNaDokumentimaDN

   RETURN lOk


STATIC FUNCTION query_log_data( hParams )

   LOCAL cUser := ""
   LOCAL _dat_from := hParams[ "date_from" ]
   LOCAL _dat_to := hParams[ "date_to" ]
   LOCAL nLimit := hParams[ "limit" ]
   LOCAL _conds_true := hParams[ "conds_true" ]
   LOCAL _conds_false := hParams[ "conds_false" ]
   LOCAL _is_doc_oper := hParams[ "doc_oper" ] == "D"
   LOCAL cQuery, cWhere
   LOCAL _server := sql_data_conn()
   LOCAL oData

   IF hb_HHasKey( hParams, "user" )
      cUser := hParams[ "user" ]
   ENDIF

   cWhere := _sql_date_parse( "l_time", _dat_from, _dat_to )

   IF !Empty( cUser )
      cWhere += " AND " + _sql_cond_parse( "user_code", cUser )
   ENDIF

   IF !Empty( _conds_true )
      cWhere += " AND (" + _sql_cond_parse( "msg", _conds_true ) + ")"
   ENDIF

   IF !Empty( _conds_false )
      cWhere += " AND (" + _sql_cond_parse( "msg", _conds_false, .T. ) + ")"
   ENDIF

   IF _is_doc_oper
      cWhere += " AND ( msg LIKE '%F18_DOK_OPER%' ) "
   ENDIF

   cQuery := "SELECT id, user_code, l_time, msg"
   cQuery += " FROM " + f18_sql_schema("log")
   cQuery += " WHERE " + cWhere
   cQuery += " ORDER BY l_time DESC "
   IF nLimit > 0
      cQuery += " LIMIT " + AllTrim( Str( nLimit ) )
   ENDIF

   info_bar( "log_get_data", "qry:" + cQuery )
   oData := run_sql_query( cQuery )

   IF sql_error_in_query( oData, "SELECT" )
      RETURN NIL
   ENDIF

   RETURN oData


STATIC FUNCTION print_log_data( data, hParams, print_to_file )

   LOCAL oRow
   LOCAL cUser, cTxt, dDatum
   LOCAL _a_txt, _tmp, nI, _pos_y
   LOCAL _txt_len := 100
   LOCAL _log_file := DToS( Date() ) + "_" + StrTran( Time(), ":", "" ) + "_log.txt"
   LOCAL _log_path := my_home_root()

   IF data == NIL .OR. data:LastRec() == 0
      IF !print_to_file
         MsgBeep( "Za zadati uslov ne postoje podaci u log-u !" )
      ENDIF
      RETURN .F.
   ENDIF

   IF print_to_file
      f18_start_print( _log_path + _log_file, "D" )
   ELSE
      IF !start_print()
         RETURN .F.
      ENDIF
   ENDIF

   ?
   P_COND

   ? "PREGLED LOG-a"
   ? Replicate( "-", 130 )
   ? PadR( "Datum / vrijeme", 19 ), PadR( "Korisnik", 10 ), "operacija"
   ? Replicate( "-", 130 )

   DO WHILE !data:Eof()

      oRow := data:GetRow()

      dDatum := data:FieldGet( data:FieldPos( "l_time" ) )
      cUser := hb_UTF8ToStr( data:FieldGet( data:FieldPos( "user_code" ) ) )
      cTxt := hb_UTF8ToStr( data:FieldGet( data:FieldPos( "msg" ) ) )

      ?
      @ PRow(), PCol() + 1 SAY PadR( dDatum, 19 )
      @ PRow(), _pos_y := PCol() + 1 SAY PadR( cUser, 10 )

      _a_txt := SjeciStr( cTxt, _txt_len )

      FOR nI := 1 TO Len( _a_txt )
         IF nI > 1
            ?
            @ PRow(), _pos_y SAY Pad( _a_txt[ nI ], _txt_len )
         ELSE
            @ PRow(), _pos_y := PCol() + 1 SAY PadR( _a_txt[ nI ], _txt_len )
         ENDIF
      NEXT

      data:Skip()

   ENDDO

   IF print_to_file
      f18_end_print( _log_path + _log_file, "D" )
   ELSE
      FF
      end_print()
   ENDIF

   RETURN _log_file


FUNCTION f18_log_delete()

   LOCAL hParams := hb_Hash()
   LOCAL _curr_log_date := Date()
   LOCAL _last_log_date := fetch_metric( "log_last_delete_date", NIL, CToD( "" ) )
   LOCAL _delete_log_level := fetch_metric( "log_delete_level", NIL, 30 )

   info_bar( "init", "f18_log_delete - start" )

   IF _delete_log_level == 0
      RETURN .F.
   ENDIF

   IF ( _curr_log_date - _delete_log_level ) > _last_log_date

      hParams[ "delete_level" ] := _delete_log_level
      hParams[ "current_date" ] := _curr_log_date

      IF sql_log_delete( hParams )
         set_metric( "log_last_delete_date", NIL,  _curr_log_date )
      ENDIF

   ENDIF
   info_bar( "init", "f18_log_delete - stop" )

   RETURN .T.


STATIC FUNCTION sql_log_delete( hParams )

   LOCAL lOk := .T.
   LOCAL cQuery, cWhere
   LOCAL _result
   LOCAL _dok_oper := "%F18_DOK_OPER%"
   LOCAL _delete_level := hParams[ "delete_level" ]
   LOCAL _curr_date := hParams[ "current_date" ]
   LOCAL _delete_date := ( _curr_date - _delete_level )

   cWhere := "( l_time::char(8) <= " + sql_quote( _delete_date )
   cWhere += " AND msg NOT LIKE " + sql_quote( _dok_oper ) + " ) "
   cWhere += " OR "
   cWhere += "( EXTRACT( YEAR FROM l_time ) < EXTRACT( YEAR FROM CURRENT_DATE ) "
   cWhere += " AND "
   cWhere += " msg LIKE " + sql_quote( _dok_oper ) + " ) "

   cQuery := "DELETE FROM " + f18_sql_schema( "log")
   cQuery += " WHERE " + cWhere

   _result := run_sql_query( cQuery )

   IF sql_error_in_query( _result )
      RETURN .F.
   ENDIF

   RETURN .T.
