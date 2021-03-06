/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

// --------------------------------------------------
// automatski napravi lami staklo od obicnog
// nEl_nr - redni broj elementa
// nFolNr - broj folija lami stakla
// --------------------------------------------------
FUNCTION rnal_generisi_lamistal_staklo( nEl_nr, nFolNr, nArt_id )

   LOCAL i
   LOCAL nTRec := RecNo()
   LOCAL nLastNo
   LOCAL cTmp
   LOCAL cSchema
   LOCAL lLast := .T.
   LOCAL _rec

   DO WHILE !Eof() .AND. field->art_id == nArt_id
      lLast := .F.
      SKIP
   ENDDO

   SKIP -1

   IF lLast == .F.

      nLastNo := field->el_no
      nNewNo := nLastNo + ( nFolNr * 2 )

      DO WHILE !Bof() .AND. field->art_id == nArt_id

         IF RecNo() == nTRec
            EXIT
         ENDIF

         _rec := dbf_get_rec()
         _rec[ "el_no" ] := nNewNo
         dbf_update_rec( _rec )

         nNewNo -= 1

         SKIP -1

      ENDDO

   ENDIF

   nTRec := RecNo()
   cTmp := "FL-G"
   cSchema := ""

   FOR i := 1 TO nFolNr

      IF i <> 1
         cSchema += "-"
      ENDIF

      cSchema += cTmp

   NEXT

   generisi_elemente_iz_sheme( nArt_id, nil, cSchema, nEl_nr )

   RETURN DE_REFRESH
