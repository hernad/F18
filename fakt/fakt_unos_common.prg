#include "f18.ch"

MEMVAR GetList


FUNCTION fakt_getlist_rj_read( nX, nY, GetList, cIdFirma, lPraznoOk )

   hb_default( @lPraznoOk, .T. )

   @ nX, nY SAY "RJ" + iif( lPraznoOk, " prazno svi:", ":") GET cIdFirma VALID {|| fakt_valid_rj( @cIdFirma, lPraznoOk ) }

   RETURN .T.


STATIC FUNCTION fakt_Valid_rj( cIdFirma, lPraznoOk )

   IF lPraznoOk .AND. Empty( cIdfirma )
      RETURN .T.
   ENDIF

   IF cIdfirma == self_organizacija_id()
      RETURN .T.
   ENDIF

   cIdFirma := PadR( cIdfirma, FIELD_LEN_RJ_ID )
   P_RJ( @cIdFirma )

   cIdFirma := Left( cIdFirma, 2 )

   RETURN .T.
