#include "f18.ch"

FUNCTION get_broj_stakala( nNalog )

   LOCAL cQuery, oRez

   cQuery := "SELECT sum(doc_it_qtt) FROM " + F18_PSQL_SCHEMA_DOT + "rnal_doc_it" + ;
      " WHERE doc_no = " + docno_str( nNalog )

   oRez := run_sql_query( cQuery )

   IF oRez == NIL
      RETURN -1
   ENDIF

   RETURN oRez:FieldGet( 1 )
