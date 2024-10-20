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


// kopiraj stavke u pript tabelu iz KALK

FUNCTION kalk_copy_kalk_azuriran_u_pript( cIdFirma, cIdVd, cBrDok )

   LOCAL hRec

   // kreiraj pript
   cre_kalk_priprt()

   o_kalk_pript()
   o_kalk()

   IF find_kalk_by_broj_dokumenta( cIdFirma, cIDVd, cBrDok )
      MsgO( "Kopiram dokument u pript..." )
      DO WHILE !Eof()  // .AND. ( kalk->( idfirma + idvd + brdok ) == cIdFirma + cIdVd + cBrDok )
         hRec := dbf_get_rec()
         SELECT pript
         APPEND BLANK
         dbf_update_rec( hRec )
         SELECT kalk
         SKIP
      ENDDO
      MsgC()
   ELSE
      MsgBeep( "Dokument " + cIdFirma + "-" + cIdVd + "-" + AllTrim( cBrDok ) + " ne postoji !" )
      RETURN .F.
   ENDIF

   RETURN .T.
