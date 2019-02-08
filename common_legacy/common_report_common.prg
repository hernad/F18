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


/* print_nova_strana(nColumn, nStr, nSlijediRedovaZajedno)
 *   Prelazak na novu stranicu
 *  param nColumn - kolona na kojoj se stampa "Str: XXX"
 *  param nStr  - stranica
 *  param nSlijediRedovaZajedno - koliko nakon ove funkcije redova zelimo odstampati, nakon preloma se treba zajedno odstmpati "nSlijediRedova"; za vrijednost -1 stampa bez obzira na trenutnu poziciju (koristiti za stampu na prvoj strani)
 */

FUNCTION print_nova_strana( nColumn, nStr, nSlijediRedovaZajedno )

   IF ( nSlijediRedovaZajedno == NIL )
      nSlijediRedovaZajedno := 1
   ENDIF

   IF ( nSlijediRedovaZajedno == -1 ) .OR. ( PRow() > ( 59 + dodatni_redovi_po_stranici() - nSlijediRedovaZajedno ) )

      IF ( nSlijediRedovaZajedno <> -1 )
         FF
      ENDIF

      @ PRow(), nColumn SAY "Str:" + Str( ++nStr, 3 )

   ENDIF

   RETURN .T.




FUNCTION NovaStrana( bZagl, nOdstampatiStrana )

   IF ( nOdstampatiStrana == NIL )
      nOdstampatiStrana := 1
   ENDIF

   IF PRow() > ( page_length() - nOdstampatiStrana )
      FF
      IF ( bZagl <> NIL )
         Eval( bZagl )
      ENDIF
   ENDIF

   RETURN .T.




FUNCTION kalk_clanovi_komisije()

   LOCAL nSirina := 10

   ?
   ?U Space( nSirina ), "Članovi komisije:"
   ?
   ? Space( nSirina ),  "1. ___________________"
   ?
   ?U Space( nSirina ), "2. ___________________"
   ?
   ?U Space( nSirina ), "3. ___________________"
   ?

   RETURN .T.




FUNCTION FSvaki2()

   RETURN .T.



/* IspisFirme(cIdRj)
 *     Ispisuje naziv fime
 *   param: cIdRj  - Oznaka radne jedinice
 */

FUNCTION IspisFirme( cIdRj )

   LOCAL nOArr := Select()

   ?? "Firma: "
   B_ON
   ?? self_organizacija_naziv()
   B_OFF
   IF !Empty( cidrj )
      select_o_rj( cIdrj )
      Select( nOArr )
      ?? "  RJ", rj->naz
   ENDIF

   RETURN .T.


FUNCTION IspisNaDan( nEmptySpace )

   ?? Replicate( " ", nEmptySpace ) + " Na dan: " + DToC( Date() )

   RETURN .T.
