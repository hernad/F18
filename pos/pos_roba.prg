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

STATIC s_cTezinkiBarkodDN := NIL
STATIC s_cPredhodniIdRoba := ""

MEMVAR ImeKol, Kol
MEMVAR _kolicina, _cijena

FUNCTION param_tezinski_barkod( read_par )

   IF read_par != NIL
      s_cTezinkiBarkodDN := fetch_metric( "barkod_tezinski_barkod", NIL, "N" )
   ENDIF

   RETURN s_cTezinkiBarkodDN


FUNCTION pos_postoji_roba( cId, nRow, nCol, cBarkodVratiti, aGetList )

   LOCAL aZabrane
   LOCAL nI
   LOCAL cBarkod := ""
   LOCAL lSveJeOk := .F.
   //LOCAL nTezina := 0

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   PushWA()
   IF cId != NIL .AND. !Empty( cId )
      select_o_roba( "XXXXXXX" ) // cId je zadan, otvoriti samo dummy tabelu sa 0 zapisa
   ELSE
      select_o_roba()
   ENDIF

   cId := pos_sifra_ako_je_pretraga_uvijek_po_nazivu( cId )
   pos_unset_key_handler_ispravka_racuna()

   IF ValType( aGetList ) == "A" .AND. Len( aGetList ) > 1 // zapamtiti zadnji artikal iz GetListe, ako sa <ESC> izadjemo iz browse-a robe
      s_cPredhodniIdRoba := aGetList[ 1 ]:original
   ENDIF

   AAdd( ImeKol, { _u( "Šifra" ), {|| roba->id }, "" } )
   AAdd( ImeKol, { PadC( "Naziv", 40 ), {|| PadR( roba->naz, 40 ) }, "" } )
   AAdd( ImeKol, { PadC( "JMJ", 5 ), {|| PadC( roba->jmj, 5 ) }, "" } )
   AAdd( ImeKol, { "BARKOD", {|| roba->barkod }, "" } )
   AAdd( ImeKol, { "Cijena", {|| Transform( roba->mpc, "99999.99" ) }, "" } )
   FOR nI := 1 TO Len( ImeKol )
      AAdd( Kol, nI )
   NEXT
   IF pos_prodavac()
      aZabrane := { K_CTRL_T, K_CTRL_N, K_F4, K_F2, k_ctrl_f9() }
   ELSE
      aZabrane := {}
   ENDIF

   // IF !tezinski_barkod( @cId, @nTezina )
   cBarkod := barkod_or_roba_id( @cId )
   // ELSE
   // cBarkod := PadR( "T", 13 )
   // ENDIF

   lSveJeOk := p_sifra( F_ROBA, "ID", f18_max_rows() - 15, f18_max_cols() - 7, "POS artikli", @cId, NIL, NIL, NIL, NIL, NIL, aZabrane )

   IF LastKey() == K_ESC
      cId := s_cPredhodniIdRoba
      lSveJeOk := .F.
   ELSE

      @ box_x_koord() + nRow, box_y_koord() + nCol SAY PadR( AllTrim( roba->naz ) + " (" + AllTrim( roba->jmj ) + ")", 50 )
      //IF nTezina <> 0
      //   _kolicina := nTezina
      //ENDIF
      IF roba->tip <> "T"
         _cijena := pos_get_mpc()
      ENDIF

   ENDIF
   cBarkodVratiti := cBarkod

   PopWA()

   RETURN lSveJeOk




STATIC FUNCTION pos_sifra_ako_je_pretraga_uvijek_po_nazivu( cId )

   LOCAL nIdLen

   IF gPosPretragaRobaUvijekPoNazivu == "N"
      RETURN cId
   ENDIF
   IF Empty( cId )
      RETURN cId
   ENDIF
   IF Len( AllTrim( cID ) ) == 10
      RETURN cId
   ENDIF
   IF Right( AllTrim( cID ), 1 ) == "."
      RETURN cId
   ENDIF
   cId := PadR( AllTrim( cId ) + ".", 10 )

   RETURN cId
