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

MEMVAR Kol, ImeKol, gIdPos, gIdRadnik

FUNCTION pos_pregled_racuna( lAdmin )

   LOCAL dDatum := NIL
   LOCAL cDanasnjiRacuni := "D"
   LOCAL GetList := {}

   IF lAdmin == NIL
      lAdmin := .F.
   ENDIF

   Box(, 1, 50 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Samo današnji ? (D/N)" GET cDanasnjiRacuni VALID cDanasnjiRacuni $ "DN" PICT "!@"
   READ
   BoxC()

   IF cDanasnjiRacuni == "D"
      dDatum := Date()
   ENDIF

   pos_lista_racuna( dDatum )
   my_close_all_dbf()

   RETURN .T.


FUNCTION pos_lista_racuna( dDatum, cBrDok, fPrep, cPrefixFilter, qIdRoba )

   LOCAL i
   LOCAL cFilter
   LOCAL cIdPos
   LOCAL bRacunMarkiran := NIL
   LOCAL cFnc

   // PRIVATE  := .F.

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   IF cPrefixFilter == NIL
      cPrefixFilter := ".t."
   ENDIF

   cFilter := cPrefixFilter
   IF fPrep == NIL
      fPrep := .F.
   ENDIF

   IF cBrdok == NIL
      cBrDok := Space( FIELD_LEN_POS_BRDOK )
   ELSE
      cBrDok := AllTrim( cBrDok )
   ENDIF

   cIdPos := Left( cBrDok, At( "-", cBrDok ) - 1 )
   cIdPos := PadR( cIdPOS, Len( gIdPos ) )

   seek_pos_doks( cIdPos, "42", dDatum, cBrDok )

   IF !Empty( cIdPos ) .AND. cIdPOS <> gIdPos
      MsgBeep( "Račun nije napravljen na ovoj kasi!#" + "Ne možete napraviti promjenu!", 20 )
      RETURN ( .F. )
   ENDIF

   cBrDok := Right( cBrDok, Len( cBrDok ) - At( "-", cBrDok ) )
   cBrDok := PadL( cBrDok, FIELD_LEN_POS_BRDOK )

   AAdd( ImeKol, { _u( "Broj računa" ), {|| PadR( Trim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), 9 ) } } )
   AAdd( ImeKol, { "Fisk.rn", {|| field->fisc_rn } } )
   AAdd( ImeKol, { "Iznos", {|| Str ( pos_iznos_racuna( field->idpos, field->idvd, field->datum, field->brdok ), 13, 2 ) } } )
   AAdd( ImeKol, { "Smj", {||  field->smjena } } )
   AAdd( ImeKol, { "Datum", {|| field->datum } } )
   AAdd( ImeKol, { "Vr.Pl", {|| field->idvrstep } } )
   AAdd( ImeKol, { "Partner", {|| field->idPartner } } )
   AAdd( ImeKol, { "Vrijeme", {|| field->vrijeme } } )
   AAdd( ImeKol, { _u("Plaćen"),     {|| iif ( field->Placen == PLAC_NIJE, "  NE", "  DA" ) } } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( kol, i )
   NEXT

   SELECT pos_doks

   cFilter += ".and. IdRadnik=" + dbf_quote( gIdRadnik ) + ".and. Idpos=" + dbf_quote( gIdPos )

   IF qIdRoba <> NIL .AND. !Empty( qIdRoba )
      cFilter += ".and. pos_racun_sadrzi_artikal(IdPos, IdVd, datum, BrDok, " + dbf_quote( qIdRoba ) + ")"
   ENDIF

   SET FILTER TO &cFilter
   GO TOP

   IF !Empty( cBrDok )
      IF !Eof()
         cBrDok := AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok )
         dDat := pos_doks->datum
         RETURN( .T. )
      ENDIF
   ENDIF

   IF fPrep
      cFnc := "<Enter>-Odabir   <P>-Pregled"
      // fMark := .T.
      // bRacunMarkiran := {|| pos_racun_obiljezen () }
   ELSE
      cFnc := "<Enter>-Odabir          <P>-Pregled"
      // bRacunMarkiran := NIL
   ENDIF

   KEYBOARD '\'
   my_browse( "pos_rn", f18_max_rows() - 12, f18_max_cols() - 25, {| nCh | lista_racuna_key_handler( nCh ) }, _u( " POS RAČUNI " ), "", NIL, cFnc,, bRacunMarkiran )

   SET FILTER TO

   cBrDok := AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok )
   IF cBrDok = '-'
      cBrDok := Space( 3 + FIELD_LEN_POS_BRDOK )
   ENDIF

   dDat := pos_doks->datum
   IF LastKey() == K_ESC
      RETURN( .F. )
   ENDIF

   RETURN( .T. )


STATIC FUNCTION lista_racuna_key_handler( nCh )

   LOCAL nTrec
   LOCAL nTrec2
   LOCAL hRec
   LOCAL nFiscNo
   LOCAL GetList := {}
   LOCAL hParams := hb_Hash()

   SELECT pos_doks

   IF Chr( nCh ) == '\'
      DO WHILE !( Tb:hitTop .OR. TB:hitBottom )
         Tb:down()
         TB:Stabilize()
      ENDDO
   ENDIF

   IF Upper( Chr( nCh ) ) == "P"
      pos_pregled_stavki_racuna( pos_doks->IdPos, pos_doks->datum, pos_doks->BrDok )
      RETURN DE_REFRESH
   ENDIF

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

   IF Upper( Chr( nCh ) ) == "S"
      pos_storno_racuna( TB, .T., pos_doks->brdok, pos_doks->datum, PadR( AllTrim( Str( pos_doks->fisc_rn ) ), 10 ) )
      MsgBeep( "Storno račun se nalazi u pripremi !" )
      SELECT pos_doks
      RETURN DE_REFRESH

   ENDIF

   IF nCh == K_CTRL_V

      IF pos_doks->idvd <> "42"
         RETURN DE_CONT
      ENDIF
      nFiscNo := pos_doks->fisc_rn
      Box(, 1, 40 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj fiskalnog računa: " GET nFiscNo
      READ
      BoxC()

      IF LastKey() <> K_ESC
         hRec := dbf_get_rec()
         hRec[ "fisc_rn" ] := nFiscNo
         update_rec_server_and_dbf( "pos_doks", hRec, 1, "FULL" )
         RETURN DE_REFRESH
      ENDIF

   ENDIF

   RETURN ( DE_CONT )
