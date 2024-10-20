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

FUNCTION is_pdv_obveznik( cIdPartner )

   RETURN partner_is_pdv_obveznik( cIdPartner )


FUNCTION partner_is_pdv_obveznik( cIdPartner )

   LOCAL cPdvBroj

   cPdvBroj := ALLTRIM( firma_pdv_broj( cIdPartner ) )

   IF LEN( cPdvBroj ) == 12
      RETURN .T.
   ENDIF

   RETURN .F.



/*
       Ino partner
       - PDV broj je prazan
       - Id broj sadrži manje od 13 cifri: npr. ENG105
   */

FUNCTION partner_is_ino( cIdPartner, lShow )


   LOCAL cIdBroj
   LOCAL cPdvBroj

   cPdvBroj := ALLTRIM( firma_pdv_broj( cIdPartner ) )
   cIdBroj :=  ALLTRIM( firma_id_broj( cIdPartner ) )

   IF !Empty( cIdBroj ) .AND. cIdBroj != "?NEPTIP?" // bug #36648

      IF EMPTY( cPdvBroj ) .AND. Len( cIdBroj ) < 13 .AND. Len( cIdBroj ) > 0
         RETURN .T.
      ELSE
         RETURN .F.
      ENDIF

   ENDIF

   RETURN .F.




/*
   Opis: da li id broj ima 13 cifara
*/
FUNCTION is_idbroj_13cifara( cIdBroj )

   IF LEN( ALLTRIM( cIdBroj ) ) == 13
      RETURN .T.
   ENDIF

   RETURN .F.

/*
    primjer: PdvParIIIF ( cIdPartner, 1.17, 1, 0)
    ako je partner pdv obvezinik return 1.17
    ako je no pdv return 1
    ako je ino return 0
*/

FUNCTION PdvParIIIF( cIdPartner, nPdvObv, nNoPdv, nIno, nUndefined )

   IF !is_postoji_partner( cIdPartner )
      RETURN nUndefined
   ENDIF

   IF partner_is_pdv_obveznik( cIdPartner )
      RETURN nPdvObv
   ENDIF

   IF partner_is_ino( cIdPartner )
      RETURN nIno
   ELSE
      RETURN nNoPdv
   ENDIF



/*
   u ovo polje se stavlja clan zakona o pdv-u ako postoji
   osnova za oslobadjanje
*/

FUNCTION pdv_oslobodjen( cIdPartner )

   LOCAL cIdBroj

   RETURN cIdBroj := get_partn_sifk_sifv( "PDVO", cIdPartner, .F. )


/*
 da li je partner oslobodjen po clanu
*/

FUNCTION is_part_pdv_oslob_po_clanu( cIdPartner )

   LOCAL lRet := .F.
   LOCAL cClan

   cClan := pdv_oslobodjen( cIdPartner )

   IF cClan <> NIL .AND. !Empty( cClan )
      lRet := .T.
   ENDIF

   RETURN lRet
