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

MEMVAR gOsSii

FUNCTION os_sii_da_li_postoji_polje( cField )

   LOCAL lRet := .F.

   IF gOsSii == "O"
      IF os->( FieldPos( cField ) ) <> 0
         lRet := .T.
      ENDIF
   ELSE
      IF sii->( FieldPos( cField ) ) <> 0
         lRet := .T.
      ENDIF
   ENDIF

   RETURN lRet



FUNCTION os_sii_table_name()

   IF gOsSii == "O"
      RETURN "os_os"
   ENDIF

   RETURN "sii_sii"


FUNCTION promj_table_name()

   IF gOsSii == "O"
      RETURN "os_promj"
   ENDIF

   RETURN "sii_promj"




// -----------------------------------------
// unificiraj invent. brojeve
// -----------------------------------------
FUNCTION Unifid()

   LOCAL nTrec, nTSRec
   LOCAL nIsti
   LOCAL _rec

   o_os_sii()

   SET ORDER TO TAG "1"

   DO WHILE !Eof()

      cId := field->id
      nIsti := 0

      DO WHILE !Eof() .AND. field->id == cId
         ++nIsti
         SKIP
      ENDDO

      IF nIsti > 1
         // ima duplih slogova
         SEEK cId
         // prvi u redu
         nProlaz := 0
         DO WHILE !Eof() .AND. field->id == cId
            SKIP
            ++nProlaz
            nTrec := RecNo()   // sljedeci
            SKIP -1
            nTSRec := RecNo()
            cNovi := ""
            IF Len( Trim( cid ) ) <= 8
               cNovi := Trim( id ) + idrj
            ELSE
               cNovi := Trim( id ) + Chr( 48 + nProlaz )
            ENDIF
            SEEK cnovi
            IF Found()
               MsgBeep( "vec postoji " + cid )
            ELSE
               GO nTSRec
               _rec := dbf_get_rec()
               _rec[ "id" ] := cNovi
               update_rec_server_and_dbf( Alias(), _rec, 1, "FULL" )
            ENDIF
            GO nTrec
         ENDDO
      ENDIF

   ENDDO

   RETURN



FUNCTION RazdvojiDupleInvBr()

   IF spec_funkcije_sifra( "UNIF" )
      IF pitanje(, "Razdvojiti duple inv.brojeve ?", "N" ) == "D"
         UnifId()
      ENDIF
   ENDIF

   RETURN
