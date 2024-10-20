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

THREAD STATIC nSlogova := 0

MEMVAR cTag, cKljucIz, cFilter

FUNCTION create_index( cImeInd, xKljuc, cAlias, lSilent, lDescending )

   LOCAL cImeCDX, cImeDbf
   LOCAL nOrder
   LOCAL hRec, hTmpRec
   LOCAL _tag
   LOCAL cKljuc
   LOCAL _unique := .F.
   LOCAL lPostoji
   LOCAL nPom, cOrdKey

   PRIVATE cTag
   PRIVATE cKljuciz
   PRIVATE cFilter

   IF lSilent == nil
      lSilent := .F.
   ENDIF

   IF ValType( xKljuc ) == "C"
      cKljuc := xKljuc
      cFilter := NIL
   ELSE
      cKljuc := xKljuc[ 1 ]
      cFilter := xKljuc[ 2 ]
      IF Len( xKljuc ) == 3
         _unique := xKljuc[ 3 ]
      ENDIF
   ENDIF

   IF lDescending == NIL
      lDescending := .F.
   ENDIF

   CLOSE ALL

   cAlias := FILEBASE( cAlias )
   hTmpRec := hb_Hash()

   hRec := get_a_dbf_rec( cAlias, .T. )

   hTmpRec[ 'full_table' ] := f18_ime_dbf( hRec )
   hTmpRec[ 'table' ] := hRec[ 'table' ]
   hTmpRec[ 'alias' ] := "CREIND__" + hRec[ "alias" ]
   hTmpRec[ 'wa' ] := hRec[ 'wa' ] + 5000

   FOR EACH _tag in { cTag, "DEL" }

      cImeDbf := hTmpRec[ 'full_table' ]
      cImeCdx := ImeDbfCdx( cImeDbf )

      nPom := RAt( SLASH, cImeInd )
      cTag := ""

      cKljucIz := cKljuc

      IF nPom <> 0
         cTag := SubStr( cImeInd, nPom + 1 )
      ELSE
         cTag := cImeInd
      ENDIF

      IF _tag == "DEL"
         cTag    := "DEL"
         cKljuc  := "deleted()"
         cImeInd := cTag
      ENDIF

      lPostoji := .T.

      my_use_temp( hTmpRec, NIL, .F., .F., .T. ) // shared: my_use_temp( hDbfRec, table, new_area, excl, lOpenIndex )

      IF Used()
         nOrder := index_tag_num( cTag )
         cOrdKey := ordKey( cTag )
         SELECT ( hTmpRec[ 'wa' ] )
         USE
      ELSE
         log_write( "create_index: Ne mogu otvoriti " + cImeDbf, 3 )
         lPostoji := .F.
      ENDIF

      IF !lPostoji
         RETURN .F.
      ENDIF

      IF nOrder <= 0 .OR. AllTrim( Upper( cOrdKey ) ) <> AllTrim( Upper( cKljuc ) )

         my_use_temp( hTmpRec, NIL, .F., .T., .F. ) // exclusive : my_use_temp( hDbfRec, table, new_area, excl, lOpenIndex )

         IF !lSilent
            info_bar( "-", "DBF: " + cImeDbf + ", Kreiram index-tag :" + cImeInd + "#" + ExFileName( cImeCdx ) )
         ENDIF
         ?E  "DBF: " + cImeDbf + "  index-tag :" + cImeInd + "#" + ExFileName( cImeCdx )

         log_write( "indeksiranje " + cImeDbf + " / " + cImeInd, 7 )

         nPom := RAt( SLASH, cImeInd )

         PRIVATE cTag := ""
         PRIVATE cKljuciz := cKljuc

         IF nPom <> 0
            cTag := SubStr( cImeInd, nPom )
         ELSE
            cTag := cImeInd
         ENDIF

         // provjeriti indeksiranje na nepostojecim poljima ID_J, _M1_
         IF  !( Left( cTag, 4 ) == "ID_J" .AND. FieldPos( "ID_J" ) == 0 ) .AND. !( cTag == "_M1_" .AND. FieldPos( "_M1_" ) == 0 )

            cImeCdx := StrTran( cImeCdx, "." + INDEXEXT, "" )

            log_write( "index on " + cKljucIz + " / " + cTag + " / " + cImeCdx + " FILTER: " + iif( cFilter != NIL, cFilter, "-" ) + " / alias=" + cAlias + " / used() = " + hb_ValToStr( Used() ), 5 )
            IF _tag == "DEL"
               INDEX ON Deleted() TAG "DEL" TO ( cImeCdx ) FOR Deleted()
            ELSE
               IF cFilter != NIL
                  IF _unique
                     INDEX ON &cKljucIz  TAG ( cTag )  TO ( cImeCdx ) FOR &cFilter UNIQUE
                  ELSE
                     INDEX ON &cKljucIz  TAG ( cTag )  TO ( cImeCdx ) FOR &cFilter
                  ENDIF
               ELSE
                  IF lDescending
                     INDEX ON &cKljucIz  TAG ( cTag ) TO ( cImeCdx ) DESCENDING
                  ELSE
                     INDEX ON &cKljucIz  TAG ( cTag ) TO ( cImeCdx )
                  ENDIF
               ENDIF
            ENDIF
            USE

         ENDIF

         USE

      ENDIF

   NEXT

   CLOSE ALL

   RETURN .T.
