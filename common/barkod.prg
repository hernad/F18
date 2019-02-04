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


FUNCTION roba_ocitaj_barkod( cIdRoba )

   LOCAL nDbfArea := Select()
   LOCAL cBarKod := ""

   IF !Empty( cIdRoba )
      select_o_roba( cIdRoba )
      cBarKod := field->barkod
      SELECT ( nDbfArea )
   ENDIF

   RETURN cBarKod



FUNCTION roba_valid_barkod( nCh, cIdRoba, cBarkodId )

   LOCAL cIdRoba2, cMsg

   // IF Empty( cBarkod ) //.AND. my_get_from_ini( "BARKOD", "Auto", "N", SIFPATH ) == "D" .AND. my_get_from_ini( "BARKOD", "Svi", "N", SIFPATH ) == "D" .AND. ( Pitanje(, "Formirati Barkod ?", "N" ) == "D" )
   // cBK := NoviBK_A()
   // ENDIF

   IF Empty( cBarKodId ) // artikal bez barkod-a je dopusten
         RETURN .T.
   ENDIF

   cIdRoba2 := find_roba_id_by_barkod( cBarkodId )


   IF Empty( cIdRoba2 )
      RETURN .T.
   ENDIF

   cMsg := "barkod: '" + Trim( cBarKodId ) + "' već postoji ?!: " + cIdRoba2

   IF nCh == K_CTRL_N .OR. nCh == K_F4
      IF !Empty( cBarKodId )
         error_bar( "barkod", cMsg )
         RETURN .F.
      ENDIF
   ELSE
      IF cIdRoba != cIdRoba2
         error_bar( "barkod", cMsg )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.




/*
 @function    NoviBK_A
 @abstract    Novi Barkod - automatski
 @discussion  Ova fja treba da obezbjedi da program napravi novi interni barkod
              tako sto ce pogledati Barkod/Prefix iz fmk.ini i naci zadnji

       dodjeljen barkod. Njeno ponasanje ovisno je op parametru
              Barkod / EAN ; Za EAN=13 vraca trinaestocifreni EANKOD,
              Kada je EAN<>13 vraca broj duzine DuzSekvenca BEZ PREFIXA
*/
FUNCTION NoviBK_A( cPrefix )

   LOCAL cPom, xRet
   LOCAL nDuzPrefix, nDuzSekvenca, cEAN

   PushWA()

   nCount := 1

   IF cPrefix = NIL
      cPrefix := my_get_from_ini( "Barkod", "Prefix", "", SIFPATH )
   ENDIF
   cPrefix := Trim( cPrefix )
   nDuzPrefix := Len( cPrefix )

   nDuzSekv :=  Val ( my_get_from_ini( "Barkod", "DuzSekvenca", "", SIFPATH ) )
   cEAN := my_get_from_ini( "Barkod", "EAN", "", SIFPATH )

   cRez := PadL(  AllTrim( Str( 1 ) ), nDuzSekv, "0" )
   IF cEAN = "13"
      cRez := cPrefix + cRez + KEAN13( cRez )
      // 0387202   000001   6
   ELSE
      cRez := cRez
   ENDIF

   SET FILTER TO // pocisti filter
   SET ORDER TO TAG "BARKOD"
   SEEK cPrefix + "á" // idi na kraj
   SKIP -1 // lociraj se na zadnji slog iz grupe prefixa
   IF Left( barkod, nDuzPrefix ) == cPrefix
      IF cEAN == "13"
         cPom :=   AllTrim ( Str( Val ( SubStr( BARKOD, nDuzPrefix + 1, nDuzSekv ) ) + 1 ) )
         cPom :=   PadL( cPom, nDuzSekv, "0" )
         cRez :=   cPrefix + cPom
         cRez :=   cRez + KEAN13( cRez )
      ELSE
         // interni barkod varijanta planika koristicemo Code128 standard
         cPom :=   AllTrim ( Str( Val ( SubStr( BARKOD, nDuzPrefix + 1, nDuzSekv ) ) + 1 ) )
         cPom :=   PadL( cPom, nDuzSekv, "0" )
         cRez :=   cPom  // Prefix dio ce dodati glavni alogritam
      ENDIF
   ENDIF

   PopWa()

   RETURN cRez


/*
 @function   KEAN13 ( ckod)
 @abstract   Uvrdi ean13 kontrolni broj
 @discussion xx
 @param      ckod   kod od dvanaest mjesta
*/

FUNCTION KEAN13( cKod )

   LOCAL nB2, nB4
   LOCAL nB1 := Val( SubStr( cKod, 2, 1 ) ) + Val( SubStr( cKod, 4, 1 ) ) + Val( SubStr( ckod, 6, 1 ) ) + Val( SubStr ( ckod, 8, 1 ) ) + Val( SubStr( ckod, 10, 1 ) ) + Val( SubStr( ckod, 12, 1 ) )
   LOCAL nB3 := Val( SubStr( cKod, 1, 1 ) ) + Val( SubStr( cKod, 3, 1 ) ) + Val( SubStr( ckod, 5, 1 ) ) + Val( SubStr ( ckod, 7, 1 ) ) + Val( SubStr( ckod, 9, 1 ) ) + Val( SubStr( ckod, 11, 1 ) )

   nB2 := nB1 * 3

   nB4 := nB2 + nB3
   nB4 := nB4 % 10
   IF nB4 = 0
      RETURN  "0"   // n5
   ELSE
      RETURN  Str( 10 - nB4, 1 )   // n5
   ENDIF




/*
    provjerava i pozicionira sifranik artikala na polje barkod po trazeno uslovu
*/

FUNCTION barkod_or_roba_id( cId )

   LOCAL cIdRoba := ""
   LOCAL cBarkod := ""

   gOcitBarKod := .F.

   // SELECT roba

   IF !Empty( cId )

      // SET ORDER TO TAG "BARKOD"
      // GO TOP
      // SEEK cId
      IF find_roba_by_barkod( cID )
         IF PadR( cId, 13 ) == field->barkod
            cId := field->id
            gOcitBarKod := .T.
            cBarkod := AllTrim( field->barkod )
         ENDIF
      ENDIF

   ENDIF

   cId := PadR( cId, 10 )

   RETURN cBarkod




#ifdef F18_POS

FUNCTION tezinski_barkod_get_tezina( barkod, tezina )

   LOCAL _tb := param_tezinski_barkod()
   LOCAL _tb_prefix := AllTrim( fetch_metric( "barkod_prefiks_tezinskog_barkoda", NIL, "" ) )
   LOCAL _tb_barkod, _tb_tezina
   LOCAL _bk_len := fetch_metric( "barkod_tezinski_duzina_barkoda", NIL, 0 )
   LOCAL _tez_len := fetch_metric( "barkod_tezinski_duzina_tezina", NIL, 0 )
   LOCAL _tez_div := fetch_metric( "barkod_tezinski_djelitelj", NIL, 10000 )
   LOCAL _val_tezina := 0
   LOCAL _a_prefix
   LOCAL nI

   IF _tb == "N"
      RETURN .F.
   ENDIF

   // matrica sa prefiksima...
   // "55"
   // "21"
   // itd...
   _a_prefix := TokToNiz( _tb_prefix, ";" )

   IF AScan( _a_prefix, {| VAR | VAR == PadR( barkod, Len( VAR ) ) } ) == 0
      RETURN .F.
   ENDIF

   // odrezi ocitano na 7, tu je barkod koji trebam pretraziti
   _tb_barkod := Left( barkod, _bk_len )

   IF Len( AllTrim( _tb_barkod ) ) <> _bk_len
      // ne slaze se sa tezinskim barkodom... ovo je laznjak..
      RETURN .F.
   ENDIF

   _tb_tezina := PadR( Right( barkod, _tez_len ), _tez_len - 1 )


   IF !Empty( _tb_tezina ) // sredi i tezinu
      _val_tezina := Val( _tb_tezina )
      tezina := Round( ( _val_tezina / _tez_div ), 4 )
      RETURN .T.
   ENDIF

   RETURN .F.


FUNCTION tezinski_barkod( id, tezina, pop_push )

   LOCAL _ocitao := .F.
   LOCAL _tb := param_tezinski_barkod()
   LOCAL _tb_prefix := AllTrim( fetch_metric( "barkod_prefiks_tezinskog_barkoda", NIL, "" ) )
   LOCAL _tb_barkod, _tb_tezina
   LOCAL _bk_len := fetch_metric( "barkod_tezinski_duzina_barkoda", NIL, 0 )
   LOCAL _tez_len := fetch_metric( "barkod_tezinski_duzina_tezina", NIL, 0 )
   LOCAL _tez_div := fetch_metric( "barkod_tezinski_djelitelj", NIL, 10000 )
   LOCAL _val_tezina := 0
   LOCAL _a_prefix
   LOCAL nI

   IF pop_push == NIL
      pop_push := .T.
   ENDIF

   gOcitBarKod := _ocitao

   IF _tb == "N"
      RETURN _ocitao
   ENDIF

   IF Empty( id )
      RETURN _ocitao
   ENDIF

   // matrica sa prefiksima...
   // "55"
   // "21"
   // itd...
   _a_prefix := TokToNiz( _tb_prefix, ";" )

   IF AScan( _a_prefix, {| VAR | VAR == PadR( id, Len( VAR ) ) } ) <> 0
      // ovo je ok...
   ELSE
      RETURN _ocitao
   ENDIF

   // odrezi ocitano na 7, tu je barkod koji trebam pretraziti
   _tb_barkod := Left( id, _bk_len )
   _tb_tezina := PadR( Right( id, _tez_len ), _tez_len - 1 )

   IF pop_push
      PushWA()
   ENDIF

   SELECT roba
   SET ORDER TO TAG "BARKOD"
   SEEK _tb_barkod

   IF Found() .AND. AllTrim( _tb_barkod ) == AllTrim( field->barkod )

      id := roba->id
      _ocitao := .T.

      gOcitBarKod := _ocitao


      IF !Empty( _tb_tezina )

         _val_tezina := Val( _tb_tezina )
         tezina := Round( ( _val_tezina / _tez_div ), 4 )

      ENDIF

   ENDIF

   id := PadR( id, 10 )

   SELECT roba
   SET ORDER TO TAG "ID"

   IF pop_push
      PopWa()
   ENDIF

   RETURN _ocitao


#else

FUNCTION tezinski_barkod_get_tezina()
   RETURN .F.

#endif
