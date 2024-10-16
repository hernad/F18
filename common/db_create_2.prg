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

FUNCTION open_sif_tables_1()

   //o_konto()
   //o_partner()
   //o_tnal()
   //o_tdok()
   //o_valute()
   //o_rj()
   //o_banke()
   //o_ops()
   //o_sifk()
   //o_sifv()
   //o_fakt_objekti()

   RETURN .T.


FUNCTION OSifVindija()

   //o_relac()
   //O_VOZILA
   //O_KALPOS

   RETURN .T.


FUNCTION OSifFtxt()

   o_fakt_txt()

   RETURN .T.


/*
FUNCTION OSifUgov()

--   o_ugov()
   //o_rugov()
   o_dest()
   //o_partner()
   //o_roba()
   //o_sifk()
   //o_sifv()

   RETURN .T.
*/

// ---------------------------
// dodaje polje match_code
// ---------------------------
FUNCTION add_f_mcode( aDbf )

   AAdd( aDbf, { "MATCH_CODE", "C", 10, 0 } )

   RETURN .T.

// ------------------------------------
// kreiranje indexa matchcode
// ------------------------------------
FUNCTION index_mcode( dummy, alias )

   IF FieldPos( "MATCH_CODE" ) <> 0
      CREATE_INDEX( "MCODE", "match_code", alias )
   ENDIF

   RETURN .T.


// --------------------------------------------
// provjerava da li polje postoji, samo za ops
// --------------------------------------------
FUNCTION PoljeExist( cNazPolja )

   o_ops()

   IF OPS->( FieldPos( cNazPolja ) ) <> 0
      USE
      RETURN .T.
   ELSE
      USE
      RETURN .F.
   ENDIF
