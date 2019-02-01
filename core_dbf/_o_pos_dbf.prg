/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2018 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"


FUNCTION o_pos_doks()

   // RETURN o_dbf_table( F_POS_DOKS, "pos_doks", "1" )
   seek_pos_doks( "XX", "XX" )

   RETURN .T.


FUNCTION o_pos_pos()

   // RETURN o_dbf_table( F_POS_POS, "pos_pos", "1" )
   seek_pos_pos( "XX", "XX" )

   RETURN .T.


//FUNCTION o_pos_dokspf()

//   seek_pos_dokspf( "XX", "XX" )
//   SET ORDER TO TAG "1"

//   RETURN .T.


FUNCTION o_pos_promvp()

   seek_pos_promvp( danasnji_datum() )

   RETURN .T.
