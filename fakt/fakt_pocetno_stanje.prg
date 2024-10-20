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




FUNCTION fakt_pocetno_stanje()

   LOCAL _param := hb_Hash()
   LOCAL _data := NIL
   LOCAL _ps := .T.
   LOCAL _n_br_dok
   LOCAL _count := 0
   LOCAL _ulaz, _izlaz, _stanje
   LOCAL _txt := ""
   LOCAL cIdPartner := PadR( "10", 6 )

   IF fakt_lager_lista_vars( @_param, _ps ) == 0
      RETURN .F.
   ENDIF

   MsgO( "Formiranje lager liste sql query u toku..." )

   _data := fakt_lager_lista_sql( _param, _ps )

   MsgC()

   IF _data == NIL
      MsgBeep( "FAKT.PS: Ne postoje traženi podaci !" )
      RETURN .F.
   ENDIF

   MsgC()

   //o_roba()
   //o_partner()
   //o_sifk()
   //o_sifv()
   o_fakt_pripr()

   _n_br_dok := PadR( "00000", 8 )

   MsgO( "Formiranje dokumenta početnog stanja u toku... " )

   DO WHILE !_data:Eof()

      _row := _data:GetRow()

      cIdRoba := hb_UTF8ToStr( _row:FieldGet( _row:FieldPos( "idroba" ) ) )
      _ulaz := _row:FieldGet( _row:FieldPos( "ulaz" ) )
      _izlaz := _row:FieldGet( _row:FieldPos( "izlaz" ) )
      _stanje := ( _ulaz - _izlaz )

      select_o_roba( cIdRoba )

      IF roba->tip == "U" .OR. Round( _stanje, 2 ) == 0
         _data:Skip()
         LOOP
      ENDIF

      select_o_partner( cIdPartner )

      SELECT fakt_pripr
      APPEND BLANK

      _rec := dbf_get_rec()

      aMemo := fakt_ftxt_decode( _rec[ "txt" ] )

      _rec[ "idfirma" ] := _param[ "id_firma" ]
      _rec[ "idtipdok" ] := "00"
      _rec[ "brdok" ] := _n_br_dok
      _rec[ "rbr" ] := rbr_u_char( ++_count )
      _rec[ "datdok" ] := _param[ "datum_ps" ]
      _rec[ "dindem" ] := "KM "
      _rec[ "idpartner" ] := cIdPartner
      aMemo[ 2 ] := AllTrim( partn->naz ) + ", " + AllTrim( partn->mjesto )
      aMemo[ 3 ] := "Početno stanje"
      _rec[ "txt" ] := fakt_memo_field_to_txt( aMemo )
      _rec[ "idroba" ] := cIdRoba
      _rec[ "kolicina" ] := _stanje
      _rec[ "cijena" ] := roba->vpc

      dbf_update_rec( _rec )

      _data:Skip()

   ENDDO

   MsgC()

   IF _count > 0
      MsgBeep( "Formiran dokument početnog stanja i nalazi se u pripremi !!!" )
   ENDIF

   RETURN .T.
