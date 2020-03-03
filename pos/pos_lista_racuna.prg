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

MEMVAR Kol, ImeKol, gIdRadnik
MEMVAR Tb, Ch

FUNCTION pos_pregled_racuna()

   LOCAL dDatum := danasnji_datum()
   LOCAL GetList := {}
   LOCAL hParams := hb_Hash()

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Datum:" GET dDatum
   READ
   BoxC()

   hParams[ "datum" ] := dDatum
   hParams[ "browse" ] := .T.
   hParams[ "idpos" ] := pos_pm()
   pos_lista_racuna( hParams )
   my_close_all_dbf()

   RETURN .T.


FUNCTION pos_lista_racuna( hParams )

   LOCAL i
   LOCAL cFilter := ".t."
   LOCAL bRacunMarkiran := NIL
   LOCAL cFnc

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   IF !hb_HHasKey( hParams, "idpos" )
      hParams[ "idpos" ] := pos_pm()
   ENDIF
   IF !hb_HHasKey( hParams, "idvd" )
      hParams[ "idvd" ] := POS_IDVD_RACUN
   ENDIF
   IF !hb_HHasKey( hParams, "datum" )
      hParams[ "datum" ] := NIL
   ENDIF
   IF !hb_HHasKey( hParams, "brdok" )
      hParams[ "brdok" ] := NIL
   ENDIF
   IF !hb_HHasKey( hParams, "idroba" )
      hParams[ "idroba" ] := NIL
   ENDIF
   IF !hb_HHasKey( hParams, "browse" )
      hParams[ "browse" ] := .F.
   ENDIF
   IF !hb_HHasKey( hParams, "dat_od" )
      hParams[ "dat_od" ] := NIL
   ENDIF
   IF !hb_HHasKey( hParams, "dat_do" )
      hParams[ "dat_do" ] := NIL
   ENDIF

   IF hParams[ "brdok" ] == NIL
      hParams[ "brdok" ] := Space( FIELD_LEN_POS_BRDOK )
   ENDIF

   IF hParams[ "idpos" ] <> pos_pm()
      MsgBeep( "Račun nije napravljen na ovoj kasi!#" + "Ne možete napraviti promjenu!", 20 )
      RETURN ( .F. )
   ENDIF

   IF !Empty( hParams[ "brdok" ] )
      hParams[ "brdok" ] := PadL( AllTrim( hParams[ "brdok" ] ),  FIELD_LEN_POS_BRDOK )
   ENDIF

   // seek_pos_doks( hParams[ "idpos" ], "42", hParams[ "datum" ], hParams[ "brdok" ] )
   seek_pos_doks_h( hParams )

   AAdd( ImeKol, { _u( "Broj računa" ), {|| PadR( Trim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), 9 ) } } )
   AAdd( ImeKol, { "Datum", {|| field->datum } } )
   AAdd( ImeKol, { "Fisk.rn", {|| pos_get_broj_fiskalnog_racuna_str( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->brdok ) } } )
   AAdd( ImeKol, { "Iznos", {|| Str ( pos_iznos_racuna( field->idpos, field->idvd, field->datum, field->brdok ), 13, 2 ) } } )
   AAdd( ImeKol, { "Vr.Pl", {|| field->idvrstep } } )
   AAdd( ImeKol, { "Partner", {|| field->idPartner } } )
   AAdd( ImeKol, { "Vrijeme", {|| field->vrijeme } } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( kol, i )
   NEXT

   SELECT pos_doks
   // cFilter += ".and. IdRadnik=" + dbf_quote( gIdRadnik ) + ".and. Idpos=" + dbf_quote( hParams[ "idpos" ] )

   IF hParams[ "idroba" ] <> NIL .AND. !Empty( hParams[ "idroba" ] )
      cFilter += ".and. pos_racun_sadrzi_artikal(IdPos, IdVd, datum, BrDok, " + dbf_quote( hParams[ "idroba" ] ) + ")"
   ENDIF

   SET FILTER TO &cFilter
   GO TOP

   IF RecCount() == 1 .AND. !Empty( pos_doks->brdok )
      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "idvd" ] := pos_doks->idvd
      hParams[ "brdok" ] := pos_doks->brdok
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "idradnik" ] := pos_doks->idradnik
      IF !hParams[ "browse" ]
         RETURN .T.
      ENDIF
   ENDIF

   IF hParams[ "browse" ]
      cFnc := "<Enter> ili <P>-Pregled, <S> Storno, <R> Napravi fiskalni"
   ELSE
      cFnc := "<Enter>-Odabir   <P>-Pregled"
   ENDIF

   KEYBOARD '\'
   my_browse( "pos_rn", f18_max_rows() - 12, f18_max_cols() - 25, {| nCh | lista_racuna_key_handler( nCh, @hParams ) }, _u( " POS RAČUNI PROD: " ) + pos_prodavnica_str() + "/" + pos_pm(), "", NIL, cFnc,, bRacunMarkiran )

   SET FILTER TO

   hParams[ "idpos" ] := pos_doks->idpos
   hParams[ "idvd" ] := pos_doks->idvd
   hParams[ "brdok" ] := pos_doks->brdok
   hParams[ "datum" ] := pos_doks->datum
   hParams[ "idradnik" ] := pos_doks->idradnik
   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   RETURN .T.


STATIC FUNCTION lista_racuna_key_handler( nCh, hParamsInOut )

   LOCAL nTrec
   LOCAL nTrec2
   LOCAL hRec
   LOCAL nFiskalniRn
   LOCAL GetList := {}
   LOCAL hParams := hb_Hash()

   SELECT pos_doks

   IF !hParamsInOut[ "browse" ]
      IF nCh == K_ENTER
         hParamsInOut[ "idpos" ] := pos_doks->idpos
         hParamsInOut[ "datum" ] := pos_doks->datum
         hParamsInOut[ "brdok" ] := pos_doks->brdok
         hParamsInOut[ "idradnik" ] := pos_doks->idradnik
         hParamsInOut[ "idvrstep" ] := pos_doks->idvrstep
         hParamsInOut[ "vrijeme" ] := pos_doks->vrijeme
         RETURN DE_ABORT
      ELSE
         RETURN DE_CONT
      ENDIF
   ENDIF

   IF Chr( nCh ) == '\'
      DO WHILE !( Tb:hitTop .OR. TB:hitBottom )
         Tb:down()
         TB:Stabilize()
      ENDDO
   ENDIF

   IF Upper( Chr( nCh ) ) == "P" .OR. ( hParamsInOut[ "browse" ]  .AND. nCh == K_ENTER )
      pos_pregled_stavki_dokumenta( pos_doks->IdPos, pos_doks->idvd, pos_doks->datum, pos_doks->BrDok )
      RETURN DE_REFRESH
   ENDIF

/*
   IF Upper( Chr( nCh ) ) == "F"
      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "brdok" ] := pos_doks->brdok
      hParams[ "idradnik" ] := pos_doks->idradnik
      hParams[ "idvrstep" ] := pos_doks->idvrstep
      hParams[ "vrijeme" ] := pos_doks->vrijeme
      hParams[ "samo_napuni_rn_dbf" ] := .T.
      hParams[ "priprema" ] := .F.
      pos_napuni_drn_rn_dbf( hParams )

      // SELECT pos_doks
      pos_porezna_faktura_traka( .T. )
      SELECT pos_doks
      RETURN DE_REFRESH
   ENDIF
*/

   IF Upper( Chr( nCh ) ) == "S"
      // Alert( "TODO pos_storno" )

      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "brdok" ] := pos_doks->brdok

      pos_storno_racuna( hParams )
      Tb:goBottom()
      Tb:refreshAll()
      Tb:dehilite()
      DO WHILE !Tb:Stabilize() .AND. ( ( Ch := Inkey() ) == 0 )
      ENDDO

      MsgBeep( "Storno račun se nalazi u pripremi !" )
      SELECT pos_doks
      RETURN DE_REFRESH

   ENDIF

   IF Upper( Chr( nCh ) ) == "R"

      hParams[ "idpos" ] := pos_doks->idpos
      hParams[ "datum" ] := pos_doks->datum
      hParams[ "brdok" ] := pos_doks->brdok

      nFiskalniRn := pos_get_broj_fiskalnog_racuna( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->brdok )

      IF nFiskalniRn == NIL .OR. nFiskalniRn == 0
         hParams[ "fiskalni_izdat" ] := .F.
         hParams[ "uplaceno" ] := -1
         pos_stampa_fiskalni_racun( hParams )
      ELSE
         MsgBeep( "Postoji fiskalni račun " + AllTrim( Str( nFiskalniRn ) ) + "?!" )
      ENDIF

      SELECT pos_doks
      RETURN DE_REFRESH

   ENDIF

   IF nCh == K_CTRL_V
      IF pos_doks->idvd <> "42"
         RETURN DE_CONT
      ENDIF
      nFiskalniRn := pos_get_broj_fiskalnog_racuna( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->brdok )
      Box(, 1, 40 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj fiskalnog računa: " GET nFiskalniRn PICT "99999"
      READ
      BoxC()

      IF LastKey() <> K_ESC
         IF pos_set_broj_fiskalnog_racuna( pos_doks->IdPos, pos_doks->IdVd, pos_doks->datum, pos_doks->brdok, nFiskalniRn )
            MsgBeep( "setovan broj fiskalnog računa: " + AllTrim( Str( nFiskalniRn ) ) )
         ELSE
            Alert( _u("Setovanje fiskalnog računa neuspješno ?!") )
         ENDIF
         RETURN DE_REFRESH
      ENDIF

   ENDIF

   RETURN ( DE_CONT )
