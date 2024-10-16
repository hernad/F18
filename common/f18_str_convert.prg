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


// -----------------------------------------------------
// konvertuje nase karaktere u US format
// -----------------------------------------------------
FUNCTION to_us_encoding( cp852_str )

   LOCAL _us_str
   LOCAL _cnt
   LOCAL _arr := _get_us_codes_array()

   _us_str := hb_StrToUTF8( cp852_str )

   FOR _cnt := 1 TO Len( _arr )
      _us_str := StrTran( _us_str, _arr[ _cnt, 1 ], _arr[ _cnt, 2 ] )
   NEXT

   RETURN _us_str


// -------------------------------------------------
// vraca matricu sa US kodovima
// -------------------------------------------------
STATIC FUNCTION _get_us_codes_array()

   LOCAL _arr := {}

   AAdd( _arr, { "Ž", "Z" } )
   AAdd( _arr, { "ž", "z" } )
   AAdd( _arr, { "Č", "C" } )
   AAdd( _arr, { "č", "c" } )
   AAdd( _arr, { "Ć", "C" } )
   AAdd( _arr, { "ć", "c" } )
   AAdd( _arr, { "Đ", "Dj" } )
   AAdd( _arr, { "đ", "dj" } )
   AAdd( _arr, { "Š", "S" } )
   AAdd( _arr, { "š", "s" } )

   RETURN _arr


// -----------------------------------------------------
// konvertuje nase karaktere u windows-1250 format
// -----------------------------------------------------
FUNCTION to_win1250_encoding( cp852_str, convert_852 )

   LOCAL _win_str
   LOCAL _cnt
   LOCAL _arr := _get_win_1250_codes_array()

   IF convert_852 == NIL
      convert_852 := .T.
   ENDIF

   _win_str := cp852_str

   FOR _cnt := 1 TO Len( _arr )
      _win_str := StrTran( _win_str, _arr[ _cnt, 1 ], if( convert_852, _arr[ _cnt, 2 ], _arr[ _cnt, 3 ] ) )
   NEXT

   RETURN _win_str


// -------------------------------------------------
// vraca matricu sa windows 1250 kodovima
// -------------------------------------------------
STATIC FUNCTION _get_win_1250_codes_array()

   LOCAL _arr := {}

   AAdd( _arr, { "Č", Chr( 200 ), "C" } )
   AAdd( _arr, { "č", Chr( 232 ), "c" } )
   AAdd( _arr, { "Ć", Chr( 198 ), "C" } )
   AAdd( _arr, { "ć", Chr( 230 ), "c" } )
   AAdd( _arr, { "Ž", Chr( 142 ), "Z" } )
   AAdd( _arr, { "ž", Chr( 158 ), "z" } )
   AAdd( _arr, { "Đ", Chr( 208 ), "Dj" } )
   AAdd( _arr, { "đ", Chr( 240 ), "dj" } )
   AAdd( _arr, { "Š", Chr( 138 ), "S" } )
   AAdd( _arr, { "š", Chr( 154 ), "s" } )

   RETURN _arr





// --------------------------------------------------------------------
// pretvara specijalne string karaktere u xml encoding kraktere
// npr: Č -> &#262; itd...
// to_xml_encoding( "Čekić" )
// => "&#262;eki&#269;"
// --------------------------------------------------------------------
FUNCTION to_xml_encoding( cString, lUtf )

   LOCAL _ent_arr := _get_ent_codes_array()
   LOCAL _cnt


   hb_default( @lUtf, .F. )

   IF !lUtf
      cString := hb_StrToUTF8( cString )
   ENDIF

   FOR _cnt := 1 TO Len( _ent_arr )
      cString := StrTran( cString, _ent_arr[ _cnt, 1 ], _ent_arr[ _cnt, 2 ] )
   NEXT

   RETURN cString


// ------------------------------------------------
// napuni i vrati matricu sa parovima
// utf8 karakter, xml entity code
// ------------------------------------------------
STATIC FUNCTION _get_ent_codes_array()

   LOCAL _arr := {}

   // rezervisani znakovi
   AAdd( _arr, { "&", "&amp;" } )
   AAdd( _arr, { "!", "&#33;" } )
   AAdd( _arr, { '"', "&quot;" } )
   AAdd( _arr, { "'", "&#39;" } )
   AAdd( _arr, { ",", "&#44;" } )
   AAdd( _arr, { "<", "&lt;" } )
   AAdd( _arr, { ">", "&gt;" } )

   // bh karakteri
   AAdd( _arr, { "č", "&#269;" } )
   AAdd( _arr, { "ć", "&#263;" } )
   AAdd( _arr, { "ž", "&#382;" } )
   AAdd( _arr, { "š", "&#353;" } )
   AAdd( _arr, { "đ", "&#273;" } )
   AAdd( _arr, { "Č", "&#268;" } )
   AAdd( _arr, { "Ć", "&#262;" } )
   AAdd( _arr, { "Ž", "&#381;" } )
   AAdd( _arr, { "Š", "&#352;" } )
   AAdd( _arr, { "Đ", "&#272;" } )

   RETURN _arr
