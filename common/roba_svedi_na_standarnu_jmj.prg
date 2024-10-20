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


STATIC s_cRobaTraziPoSifradob := NIL



// ----------------------------------------------------------
// sredi sifru dobavljaca, poravnanje i popunjavanje
// ako je sifra manja od LEN(5) popuni na LEN(8) sa "0"
//
// cSifra - sifra dobavljaca
// nLen - na koliko provjeravati
// cFill - cime popuniti
// ----------------------------------------------------------
FUNCTION fix_sifradob( cSifra, nLen, cFill )

   LOCAL nTmpLen

   IF is_roba_trazi_po_sifradob()

      nTmpLen := Len( roba->sifradob )
      IF Len( AllTrim( cSifra ) ) < 5 // dodaj prefiks ako je ukucano manje od 5
         cSifra := PadR( PadL( AllTrim( cSifra ), nLen, cFill ), nTmpLen )
      ENDIF
   ENDIF

   RETURN .T.


FUNCTION roba_trazi_po_sifradob( cSet )

   IF s_cRobaTraziPoSifradob == NIL
      s_cRobaTraziPoSifradob := fetch_metric( "roba_trazi_po_sifradob", NIL, Space( 20 ) )
   ENDIF

   IF cSet != NIL
      s_cRobaTraziPoSifradob  := cSet
      set_metric( "roba_trazi_po_sifradob", NIL, cSet )
   ENDIF

   RETURN Trim( s_cRobaTraziPoSifradob )


FUNCTION is_roba_trazi_po_sifradob()

   IF roba_trazi_po_sifradob() == "SIFRADOB"
      RETURN .T.
   ENDIF

   RETURN .F.




/* ----------------------------------
 svedi na standardnu jedinicu mjere
 ( npr. KOM->LIT ili KOM->KG )
*/

FUNCTION svedi_na_jedinicu_mjere( nKol, cIdRoba, cJMJ )

   LOCAL nVrati := 0, nArr := Select(), aNaz := {}, nKoeficijent := 1, nPozicija := 0
   LOCAL cSvedi
   LOCAL cPom, cJmjRoba, oError

   cSvedi := get_sifk_sifv( "ROBA", "SJMJ", cIdRoba, .F. )

   IF !Empty( cSvedi )
      nPozicija := At( "_", cSvedi ) // slijedi preracunavanje 0.1_KG
      IF nPozicija > 0
         cPom   := AllTrim( SubStr( cSvedi, nPozicija + 1 ) )
         BEGIN SEQUENCE WITH {| err| Break( err ) }
            nKoeficijent   := &cPom  // "0.1" => 0.1 numeric
         RECOVER USING oError
            error_bar( "sjmj_" + cIdRoba,  oError:description + " : " + cPom )
         END SEQUENCE
         nVrati := nKol * nKoeficijent
         cJMJ   := AllTrim( Left( cSvedi, nPozicija - 1 ) )
      ELSE
         nVrati := nKol
      ENDIF

   ELSE
      cJmjRoba := find_roba_jmj( cIdRoba )
      IF cJmjRoba == "KOM" // nema definisano svodjenje na jednicu mjere
         error_bar( "sjmj_" + AllTrim( cIdRoba ), cIdRoba + " nema definisanu težinu !?" )
      ENDIF
      nVrati := nKol // artikal je vec u osnovnoj JMJ
   ENDIF

   SELECT ( nArr )

   RETURN nVrati


FUNCTION find_roba_jmj( cIdRoba )

   LOCAL cRet

   PushWa()
   select_o_roba( cIDRoba )
   cRet := roba->jmj
   PopWa()

   RETURN cRet
