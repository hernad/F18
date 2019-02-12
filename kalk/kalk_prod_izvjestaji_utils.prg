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


// PDV obracun
FUNCTION kalk_pripr_rekap_tarife( bCheckPDFNovaStrana )

   LOCAL _pict := "99999999999.99"
   LOCAL nKolona
   LOCAL aPKonta
   LOCAL nIznPRuc
   PRIVATE aPorezi

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

   aPorezi := {}

   FOR i := 1 TO nCntKonto

      SEEK cIdFirma + cIdVd + cBrdok
      nTot1 := 0
      nTot2 := 0
      nTot2b := 0
      nTot3 := 0
      nTot4 := 0
      nTot5 := 0
      nTot6 := 0
      nTot7 := 0

      DO WHILE !Eof() .AND. cIdFirma + cIdVd + cBrDok == field->idfirma + field->idvd + field->brdok

         IF aPKonta[ i ] <> field->pkonto
            SKIP
            LOOP
         ENDIF

         cIdtarifa := field->idtarifa

         // mpv
         nU1 := 0
         // pdv
         nU2 := 0
         // mpv sa porezom
         nU3 := 0

         select_o_tarifa( cIdtarifa )

         SELECT kalk_pripr

         DO WHILE !Eof() .AND. cIdfirma + cIdvd + cBrDok == field->idfirma + field->idvd + field->brdok ;
               .AND. field->idtarifa == cIdTarifa

            IF aPKonta[ i ] <> field->pkonto
               SKIP
               LOOP
            ENDIF

            select_o_roba(  kalk_pripr->idroba )
            set_pdv_array_by_koncij_region_roba_idtarifa_2_3( kalk_pripr->pkonto, kalk_pripr->idroba, @aPorezi, cIdTarifa )
            SELECT kalk_pripr

            nMpc := kalk_mpc_by_vrsta_dokumenta( field->idvd, aPorezi )

            IF field->idvd == "19"

               // nova cijena
               nMpcsaPdv1 := field->mpcSaPP + field->fcj
               nMpc1 := MpcBezPor( nMpcsaPdv1, aPorezi,, field->nc )
               aIPor1 := kalk_porezi_maloprodaja_legacy_array( aPorezi, nMpc1, nMpcsaPdv1, field->nc )

               // stara cijena
               nMpcsaPdv2 := field->fcj
               nMpc2 := MpcBezPor( nMpcsaPdv2, aPorezi,, field->nc )
               aIPor2 := kalk_porezi_maloprodaja_legacy_array( aPorezi, nMpc2, nMpcsaPdv2, field->nc )
               aIPor := { 0, 0, 0 }
               aIPor[ 1 ] := aIPor1[ 1 ] - aIPor2[ 1 ]

            ELSE

               aIPor := kalk_porezi_maloprodaja_legacy_array( aPorezi, nMpc, field->mpcsapp, field->nc )

            ENDIF

            nKolicina := DokKolicina( field->idvd )
            nU1 += nMpc * nKolicina
            nU2 += aIPor[ 1 ] * nKolicina
            nU3 += field->mpcsapp * nKolicina

            // ukupna bruto marza
            nTot6 += ( nMpc - kalk_pripr->nc ) * nKolicina

            SKIP 1

         ENDDO

         nTot1 += nU1
         nTot2 += nU2

         nTot3 += nU3

         ? cIdTarifa

         @ PRow(), PCol() + 1 SAY aPorezi[ POR_PDV ] PICT picproc


         nCol1 := PCol() + 1

         @ PRow(), PCol() + 1   SAY nU1 PICT _pict
         @ PRow(), PCol() + 1   SAY nU2 PICT _pict

         @ PRow(), PCol() + 1   SAY nU3 PICT _pict

      ENDDO

      IF PRow() > page_length()
         FF
         @ PRow(), 123 SAY "Str:" + Str( ++nStr, 3 )
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



/* PKontoCnt(cSeek)
 *     Kreira niz prodavnickih konta koji se nalaze u zadanom dokumentu
 *   param: cSeek - firma + tip dok + broj dok
 */

FUNCTION PKontoCnt( cSeek )

   LOCAL nPos, aPKonta

   aPKonta := {}
   // baza: kalk_pripr, order: 2
   SEEK cSeek
   DO WHILE !Eof() .AND. ( IdFirma + Idvd + BrDok ) = cSeek
      nPos := AScan( aPKonta, PKonto )
      IF nPos < 1
         AAdd( aPKonta, PKonto )
      ENDIF
      SKIP
   ENDDO

   RETURN aPKonta


FUNCTION DokKolicina( cIdVd )

   LOCAL nKol

   IF cIdVd == "IP"

      // kolicina = popisana kolicina
      // gkolicina = knjizna kolicina

      // nKol := ( field->kolicina - field->gkolicina )
      nKol := field->kolicina
      // stajalo je nKol := gKolicin2 ali mi je rekapitulacija davala pogresnu
      // stvar

   ELSE
      nKol := field->kolicina
   ENDIF

   RETURN nKol



FUNCTION kalk_mpc_by_vrsta_dokumenta( cIdVd, aPorezi )

   LOCAL nMpc

   IF cIdVd == "IP"
      nMpc := MpcBezPor( field->mpcsapp, aPorezi, , field->nc )
   ELSE
      nMpc := field->mpc
   ENDIF

   RETURN nMpc
