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

/*

   o_dbf_table( F_KUF, { "KUF", "epdv_kuf" }, "DATUM" )

*/

FUNCTION o_dbf_table( nArea, xTable, cTag )

   LOCAL lUsed := .F.
   LOCAL nCount := 0
   LOCAL cTable, cAlias
   LOCAL lMyUse

   IF ValType( xTable ) == "C"
      cAlias := NIL
      cTable := xTable
   ENDIF

   IF ValType( xTable ) == "A"
      cAlias := xTable[ 1 ]
      cTable := xTable[ 2 ]
   ENDIF

   SELECT ( nArea )
   DO WHILE !lUsed .AND. nCount <= DBF_TRY_OPEN_COUNT

      IF cAlias != NIL
         lMyUse := my_use( cAlias, cTable )
      ELSE
         lMyUse := my_use( cTable )
      ENDIF

      IF lMyUse
         lUsed := .T.
         IF cTag != NIL
            ordSetFocus( cTag )
            IF Empty( ordKey() )
               lUsed := .F.
               ?E "ERR o_table tag:", cTable, cTag
               USE
            ENDIF
         ENDIF
      ELSE
         hb_idleSleep( 1.5 )
         error_bar( "o_dbf", "open dbf err: " + cTable + "/" + cTag + " cnt:" + AllTrim( Str( nCount ) ) )
         nCount++
      ENDIF

   ENDDO

   RETURN lUsed


/*
   select_o_dbf( "FAKT_DOKS", F_FAKT_DOKS, "fakt_doks", "1" )
*/

FUNCTION select_o_dbf( cAlias, nArea, xTable, cTag )

   IF Select( cAlias ) == 0
      RETURN o_dbf_table( nArea, xTable, cTag )
   ENDIF

   Select( nArea )
   IF my_rddName() == "SQLMIX" // ako je otvoren kao sql, zatvori, pa otvori kao dbf
      USE
      RETURN o_dbf_table( nArea, xTable, cTag )
   ENDIF

   RETURN .T.
