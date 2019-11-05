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


/*
   1000-01-01 => CtoD("")
*/
FUNCTION fix_dat_var( xVar, lNilToDate )

   hb_default( @lNilToDate, .F. )

   IF lNilToDate .AND. xVar == NIL
      RETURN CToD( "" )
   ENDIF

   IF ValType( xVar ) != "D"
      RETURN xVar
   ENDIF

   IF xVar < SToD( "10010101" )
      RETURN CToD( "" )
   ENDIF

   RETURN xVar




FUNCTION coalesce_num_zarez( cField, cFormat )

   RETURN coalesce_num( cField, cFormat, .T. )


FUNCTION coalesce_num_num_zarez( cField, nNum, nDec )

   RETURN coalesce_num_num( cField, nNum, nDec, .T. )


FUNCTION coalesce_num( cField, cFormat, lZarez )

   default_if_nil( @lZarez, .F. )

   RETURN  " COALESCE( " + cField + ",0)::" + cFormat + " AS " + cField + iif( lZarez, ", ", "" )


/*
   primjer: coalesce_num_num( 'broj', 12, 7 )
            => COALESCE( broj, 0)::numeric( 12, 7 ) AS broj
*/
FUNCTION coalesce_num_num( cField, nNum, nDec, lZarez )

   LOCAL cFormat

   default_if_nil( @nDec, 0 )
   default_if_nil( @lZarez, .F. )

   cFormat := "numeric(" + AllTrim( Str( nNum ) ) + "," + AllTrim( Str( nDec ) ) +  ")"

   RETURN coalesce_num( cField, cFormat, lZarez )



FUNCTION coalesce_int( cField, lZarez )

   LOCAL cFormat

   default_if_nil( @lZarez, .F. )

   cFormat := "integer"

   RETURN coalesce_num( cField, cFormat, lZarez )


FUNCTION coalesce_int_zarez( cField )

   RETURN coalesce_int( cField, .T. )


FUNCTION coalesce_real_zarez( cField )

   RETURN coalesce_real( cField, .T. )


FUNCTION coalesce_real( cField, lZarez )

   LOCAL cFormat

   default_if_nil( @lZarez, .F. )

   cFormat := "real"

   RETURN coalesce_num( cField, cFormat, lZarez )



FUNCTION coalesce_char_zarez( cField, nNum )
   RETURN coalesce_char( cField, nNum, .T. )

/*
   primjer: coalesce_char( 'idroba', 10 )
            => COALESCE( idroba, '' )::char(10) as idroba
*/
FUNCTION coalesce_char( cField, nNum, lZarez )

   LOCAL cFormat, cFieldAs, nPos

   default_if_nil( @lZarez, .F. )
   cFormat := "char(" + AllTrim( Str( nNum ) ) + ")"

   nPos := At( ".", cField )
   IF nPos > 0
      cFieldAs := SubStr( cField, nPos + 1 )
   ELSE
      cFieldAs := cField
   ENDIF

   RETURN " COALESCE( " + cField + ", '')::" + cFormat + " AS " + cFieldAs + iif( lZarez, ", ", "" )
