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


// ------------------------------------------
// da li radnik ide u benef osnovu
// ------------------------------------------
FUNCTION is_radn_k4_bf_ide_u_benef_osnovu()

   IF radn->k4 == "BF"
      RETURN .T.
   ENDIF

   RETURN .F.


// ----------------------------------------
// vraca benef stepen za radnika
// ----------------------------------------
FUNCTION BenefStepen()

   LOCAL nRet := 0
   LOCAL nTArea := Select()
   LOCAL cTmp

   SELECT radn

   cTmp := AllTrim( radn->k3 )

   IF Empty( cTmp )
      SELECT ( nTArea )
      RETURN 0
   ENDIF

   SELECT F_KBENEF
   IF !Used()
      o_koef_beneficiranog_radnog_staza()
   ENDIF

   select_o_kbenef( cTmp )

   IF !Eof()
      nRet := field->iznos
   ENDIF

   SELECT ( nTArea )

   RETURN nRet


// --------------------------------------------------------------
// vraca iznos doprinosa, osnovice za beneficirani staž
// --------------------------------------------------------------
FUNCTION get_benef_osnovica( a_benef, benef_id )

   LOCAL _iznos := 0
   LOCAL _scan

   IF a_benef == NIL .OR. Len( a_benef ) == 0
      RETURN _iznos
   ENDIF

   _scan := AScan( a_benef, {| var | VAR[ 1 ] == benef_id } )

   IF _scan <> 0 .AND. a_benef[ _scan, 3 ] <> 0
      _iznos := a_benef[ _scan, 3 ]
   ENDIF

   RETURN _iznos


// --------------------------------------------------------------
// dodaj u matricu benef
// --------------------------------------------------------------
FUNCTION add_to_a_benef( a_benef, benef_id, benef_st, osnovica )

   LOCAL _scan

   // a_benef[1] = benef_id
   // a_benef[2] = benef_stepen
   // a_benef[3] = osnova

   _scan := AScan( a_benef, {| VAR | VAR[ 1 ] == benef_id } )

   IF _scan == 0
      AAdd( a_benef, { benef_id, benef_st, osnovica } )
   ELSE
      a_benef[ _scan, 3 ] := a_benef[ _scan, 3 ] + osnovica
   ENDIF

   RETURN .T.




FUNCTION PrikKBOBenef( a_benef )

   LOCAL nI
   LOCAL _ben_osn := 0

   IF a_benef == NIL .OR. Len( a_benef ) == 0
      RETURN
   ENDIF

   FOR nI := 1 TO Len( a_benef )
      _ben_osn += a_benef[ nI, 3 ]
   NEXT

   nBO := 0

   ? _l( "Koef. Bruto osnove benef.(KBO):" ), Transform( parobr->k3, "999.99999%" )
   ? Space( 3 ), _l( "BRUTO OSNOVA = NETO OSNOVA.BENEF * KBO =" )
   @ PRow(), PCol() + 1 SAY nBo := ROUND2( parobr->k3 / 100 * _ben_osn, gZaok2 ) PICT gpici
   ?

   RETURN .T.
