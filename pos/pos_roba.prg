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

STATIC __tezinski_barkod := NIL


FUNCTION param_tezinski_barkod( read_par )

   IF read_par != NIL
      __tezinski_barkod := fetch_metric( "barkod_tezinski_barkod", NIL, "N" )
   ENDIF

   RETURN __tezinski_barkod


FUNCTION pos_postoji_roba( cId, dx, dy, barkod )

   LOCAL _zabrane
   LOCAL nI
   LOCAL cBarkod := ""
   LOCAL lSveJeOk := .F.
   LOCAL _tezina := 0
   LOCAL _order

   // LOCAL _area := Select()
   PRIVATE ImeKol := {}
   PRIVATE Kol := {}


   PushWA()

   IF cId != NIL .AND. !Empty( cId )
      select_o_roba( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_roba()
   ENDIF

   sif_uv_naziv( @cId )

   pos_unset_key_handler_ispravka_racuna()

   IF ValType( GetList ) == "A" .AND. Len( GetList ) > 1
      PrevId := GetList[ 1 ]:original
   ENDIF

   AAdd( ImeKol, { _u( "Šifra" ), {|| id }, "" } )
   AAdd( ImeKol, { PadC( "Naziv", 40 ), {|| PadR( naz, 40 ) }, "" } )
   AAdd( ImeKol, { PadC( "JMJ", 5 ), {|| PadC( jmj, 5 ) }, "" } )
   AAdd( ImeKol, { "Cijena set: " + gSetMPCijena, {|| PadL( AllTrim( Str( pos_get_mpc(), 12, 3 ) ), 12 ) }, "" } )
   AAdd( ImeKol, { "BARKOD", {|| roba->barkod }, "" } )
   //AAdd( ImeKol, { "K7", {|| roba->k7 }, "" } )

   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT

   IF pos_prodavac()
      _zabrane := { K_CTRL_T, K_CTRL_N, K_F4, K_F2, k_ctrl_f9() }
   ELSE
      _zabrane := {}
   ENDIF

   IF !tezinski_barkod( @cId, @_tezina )
      cBarkod := barkod_or_roba_id( @cId )
   ELSE
      cBarkod := PadR( "T", 13 )
   ENDIF

   // SELECT ( _area )

   lSveJeOk := p_sifra( F_ROBA, "ID", f18_max_rows() - 15, f18_max_cols() - 7, "Roba ( artikli ) ", @cId, NIL, NIL, NIL, NIL, NIL, _zabrane )

   IF LastKey() == K_ESC
      cId := PrevID
      lSveJeOk := .F.
   ELSE

      @ box_x_koord() + dx, box_y_koord() + dy SAY PadR( AllTrim( roba->naz ) + " (" + AllTrim( roba->jmj ) + ")", 50 )

      IF _tezina <> 0
         _kolicina := _tezina
      ENDIF

      IF roba->tip <> "T"
         _cijena := pos_get_mpc()
      ENDIF

   ENDIF

   IF fetch_metric( "pos_kontrola_cijene_pri_unosu_stavke", NIL, "N" ) == "D"
      IF Round( _cijena, 5 ) == 0
         MsgBeep( "Cijena 0.00, ne mogu napraviti račun !##STOP!" )
         lSveJeOk := .F.
      ENDIF
   ENDIF

   pos_set_key_handler_ispravka_racuna()

   barkod := cBarkod

   PopWA()

   // SELECT roba
   // SET ORDER TO TAG "ID"
   // SELECT ( _area )

   RETURN lSveJeOk




FUNCTION sif_uv_naziv( cId )

   LOCAL nIdLen

   IF gSifUvPoNaz == "N"
      RETURN
   ENDIF
   IF Empty( cId )
      RETURN
   ENDIF
   IF Len( AllTrim( cID ) ) == 10
      RETURN
   ENDIF
   IF Right( AllTrim( cID ), 1 ) == "."
      RETURN
   ENDIF
   cId := PadR( AllTrim( cId ) + ".", 10 )

   RETURN .T.
