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


FUNCTION server_show( var )

   LOCAL cQuery
   LOCAL oRet

   cQuery := "SHOW " + var
   oRet := run_sql_query( cQuery )

   IF !is_var_objekat_tpqquery( oRet )
      RETURN -1
   ENDIF

   IF oRet:Eof()
      RETURN -1
   ENDIF

   RETURN oRet:FieldGet( 1 )


FUNCTION server_sys_info( var )

   LOCAL cQuery
   LOCAL oRet
   LOCAL hRet := hb_Hash()
   LOCAL hParams := hb_hash()

   cQuery := "select inet_client_addr(), inet_client_port(), inet_server_addr(), inet_server_port(), current_user"

   hParams[ "log" ] := .F.
   oRet := run_sql_query( cQuery, hParams )

   IF sql_error_in_query( oRet )
      RETURN NIL
   ENDIF

   hRet[ "client_addr" ] := oRet:FieldGet( 1 )
   hRet[ "client_port" ] := oRet:FieldGet( 2 )
   hRet[ "server_addr" ] := oRet:FieldGet( 3 )
   hRet[ "server_port" ] := oRet:FieldGet( 4 )
   hRet[ "user" ]        := oRet:FieldGet( 5 )

   RETURN hRet
