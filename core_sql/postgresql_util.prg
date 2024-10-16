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

FUNCTION pg_terminate_all_data_db_connections()

   LOCAL cQuery, oQry

   cQuery :=  "SELECT pg_terminate_backend( pid ), pid "
   cQuery +=  " FROM pg_stat_activity "
   cQuery +=  " WHERE  pid in "
   cQuery +=  " (SELECT pid FROM pg_stat_activity where datname <> 'postgres')"

   // client_addr=inet_client_addr() and

   oQry := postgres_sql_query( cQuery )

   RETURN sql_error_in_query( oQry, "SELECT", sql_postgres_conn() )


FUNCTION pg_terminate_data_db_connection()

   LOCAL cQuery, oQry

   cQuery :=  "SELECT pg_terminate_backend( pid ), pid "
   cQuery +=  " FROM pg_stat_activity "
   cQuery +=  " WHERE  pid in "
   cQuery +=  " (SELECT pid FROM pg_stat_activity where username=current_user AND client_port=inet_client_port() AND datname <> 'postgres')"


   oQry := postgres_sql_query( cQuery )

   RETURN sql_error_in_query( oQry, "SELECT", sql_postgres_conn() )
