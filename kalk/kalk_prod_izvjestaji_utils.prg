/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * ERP software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR m
MEMVAR cIdFirma, cIdvd, cBrDok
MEMVAR nStr

FUNCTION kalk_pripr_rekap_tarife( bCheckPDFNovaStrana )

   LOCAL _pict := "99999999999.99"
   LOCAL nKolona
   LOCAL aPKonta
   LOCAL nRec, i, nCntKonto
   LOCAL nTot1
   LOCAL nTot2
   LOCAL nTot3
   LOCAL cIdtarifa
   LOCAL nMPV
   LOCAL nPDV
   LOCAL nMPVSaPDV
   LOCAL nCol1
   LOCAL nMpc, nKolicina

   IF bCheckPDFNovaStrana != NIL
      Eval( bCheckPDFNovaStrana )
   ELSE
      IF PRow() > ( RPT_PAGE_LEN  + dodatni_redovi_po_stranici() )
         FF
         @ PRow(), 123 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF
   ENDIF

   nRec := RecNo()
   SELECT kalk_pripr

   IF my_rddName() == "SQLMIX" // hernad hack, azurirani dokument
      GO TOP
   ELSE
      SET ORDER TO TAG "2"
      SEEK cIdFirma + cIdVd + cBrDok
   ENDIF

   m := "------ ----------"

   nKolona := 3
   FOR i := 1 TO nKolona
      m += " --------------"
   NEXT

   ? m
   ?  "* Tar.*  PDV%    *      MPV     *      PDV     *     MPV     *"
   ?  "*     *          *    bez PDV   *     iznos    *    sa PDV   *"
   ? m

   aPKonta := PKontoCnt( cIdFirma + cIdvd + cBrDok )
   nCntKonto := Len( aPKonta )

   FOR i := 1 TO nCntKonto

      SEEK cIdFirma + cIdVd + cBrdok
      nTot1 := 0
      nTot2 := 0
      nTot3 := 0
      DO WHILE !Eof() .AND. cIdFirma + cIdVd + cBrDok == field->idfirma + field->idvd + field->brdok

         IF aPKonta[ i ] <> field->pkonto
            SKIP
            LOOP
         ENDIF

         cIdtarifa := field->idtarifa
         nMPV := 0
         nPDV := 0
         nMPVSaPDV := 0
         select_o_tarifa( cIdtarifa )
         SELECT kalk_pripr
         DO WHILE !Eof() .AND. cIdfirma + cIdvd + cBrDok == field->idfirma + field->idvd + field->brdok ;
               .AND. field->idtarifa == cIdTarifa

            IF aPKonta[ i ] <> field->pkonto
               SKIP
               LOOP
            ENDIF
            select_o_roba(  kalk_pripr->idroba )
            SELECT kalk_pripr
            nMpc := field->mpc
            nKolicina := field->kolicina
            nMPV += nMpc * nKolicina
            nPDV += nMpc * pdv_procenat_by_tarifa( cIdTarifa ) * nKolicina
            nMPVSaPDV += field->mpcsapp * nKolicina
            SKIP

         ENDDO

         nTot1 += nMPV
         nTot2 += nPDV
         nTot3 += nMPVSaPDV
         ? cIdTarifa

         @ PRow(), PCol() + 1 SAY pdv_procenat_by_tarifa( cIdTarifa ) * 100 PICT picproc()
         nCol1 := PCol() + 1
         @ PRow(), PCol() + 1   SAY nMPV PICT _pict
         @ PRow(), PCol() + 1   SAY nPDV PICT _pict
         @ PRow(), PCol() + 1   SAY nMPVSaPDV PICT _pict

      ENDDO

      IF bCheckPDFNovaStrana != NIL
         Eval( bCheckPDFNovaStrana, .F.,  )
      ELSE
         IF PRow() > page_length()
            FF
            @ PRow(), 123 SAY "Str:" + Str( ++nStr, 3 )
         ENDIF
      ENDIF
      ? m
      ? "UKUPNO " + aPKonta[ i ]
      @ PRow(), nCol1 SAY nTot1 PICT _pict
      @ PRow(), PCol() + 1 SAY nTot2 PICT _pict
      @ PRow(), PCol() + 1 SAY nTot3 PICT _pict
      ? m

   NEXT

   SET ORDER TO TAG "1"
   GO nRec

   RETURN .T.


FUNCTION PKontoCnt( cSeek )

   LOCAL nPos, aPKonta

   aPKonta := {}
   // baza: kalk_pripr, order: 2
   SEEK cSeek
   DO WHILE !Eof() .AND. ( kalk_pripr->IdFirma + kalk_pripr->Idvd + kalk_pripr->BrDok ) == cSeek
      nPos := AScan( aPKonta, kalk_pripr->PKonto )
      IF nPos < 1
         AAdd( aPKonta, kalk_pripr->PKonto )
      ENDIF
      SKIP
   ENDDO

   RETURN aPKonta
