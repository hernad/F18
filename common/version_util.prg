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


FUNCTION get_version_num( major, minor, patch )

   IF ValType( major ) == "C"
      RETURN  Val( major ) * 10000 +  Val( minor ) * 100 + Val( patch )
   ELSE
      RETURN  major * 10000 +  minor * 100 + patch
   ENDIF


FUNCTION get_version_str( num )

   LOCAL _prev, _ret := "", _div, _rest

   _prev := num
   _div := num % 10000
   num := _div

   _ret += AllTrim( Str( Round( ( _prev - _div ) / 10000, 0 ), 0 ) )

   _prev := num
   _div := num % 100
   num := _div
   _ret += "." + AllTrim( Str( Round( ( _prev - _div ) / 100, 0 ), 0 ) )

   _ret += "." + AllTrim( Str( num, 0 ) )

   RETURN _ret
