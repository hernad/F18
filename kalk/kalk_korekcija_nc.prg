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

/* TraziRbr(cKljuc)
 *     Utvrdjuje posljednji redni broj stavke zadanog dokumenta u kalk_pripremi
 */

FUNCTION TraziRbr( cKljuc )


   LOCAL cVrati := "  1"
   SELECT kalk_pripr
   GO TOP
   SEEK cKljuc
   SKIP -1
   IF idfirma + idvd + brdok == Left( cKljuc, 12 )
      cVrati := Str( Val( rbr ) + 1, 3 )
   ENDIF

   RETURN cVrati



/* TraziNC(cTrazi,dDat)
 *     Utvrdjuje najcescu NC zadane robe na zadanom kontu do zadanog datuma


FUNCTION TraziNC( cTrazi, dDat )


   LOCAL nSlog := 0, aNiz := { { 0, 0 } }, nPom := 0, nVrati := 0


  // SELECT KALK
  // nSlog := RecNo()
  // SET ORDER TO TAG "3"
  // GO TOP

  find_kalk_by_mkonto_idroba( cIdFirma, cIdKonto )
   GO TOP

   SEEK cTrazi
   DO WHILE cTrazi == idfirma + mkonto + idroba .AND. datdok <= dDat .AND. !Eof()
      nPom := AScan( aNiz, {| x| KALK->nc == x[ 1 ] } )
      IF nPom > 0
         aNiz[ nPom, 2 ] += 1
      ELSE
         AAdd( aNiz, { KALK->nc, 1 } )
      ENDIF
      SKIP 1
   ENDDO
   SET ORDER TO TAG "1"
   GO nSlog
   ASort( aNiz,,, {| x, y| x[ 2 ] > y[ 2 ] } )
   IF aNiz[ 1, 1 ] > 0
      nVrati := aNiz[ 1, 1 ]
   ELSEIF Len( aNiz ) > 1
      nVrati := aNiz[ 2, 1 ]
   ENDIF
   SELECT kalk_pripr

   RETURN nVrati
*/
