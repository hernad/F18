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

FUNCTION pos_pregled_racuna( lAdmin )

   LOCAL dDatum := NIL
   LOCAL cDanasnjiRacuni := "D"
   LOCAL GetList := {}
   PRIVATE aVezani := {}

   IF lAdmin == NIL
      lAdmin := .F.
   ENDIF

   // o_pos_tables()

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



FUNCTION pos_lista_racuna( dDatum, cBroj, fPrep, cPrefixFilter, qIdRoba )

   LOCAL i
   LOCAL cFilter
   LOCAL cIdPos, cRacun

   PRIVATE fMark := .F.

   PRIVATE ImeKol := {}
   PRIVATE Kol := {}

   IF cPrefixFilter == NIL
      cPrefixFilter := ".t."
   ENDIF

   cFilter := cPrefixFilter

   IF fPrep == NIL
      fPrep := .F.
   ELSE
      fPrep := fPrep
   ENDIF

   IF cBroj == NIL
      cRacun := Space( FIELD_LEN_POS_BRDOK )
   ELSE
      cRacun := AllTrim( cBroj )
   ENDIF

   cIdPos := Left( cRacun, At( "-", cRacun ) - 1 )
   cIdPos := PadR( cIdPOS, Len( gIdPos ) )

   seek_pos_doks( cIdPos, "42", dDatum, cRacun )

   IF !Empty( cIdPos ) .AND. cIdPOS <> gIdPos
      MsgBeep( "Račun nije napravljen na ovoj kasi!#" + "Ne možete napraviti promjenu!", 20 )
      RETURN ( .F. )
   ENDIF

   cBroj := Right( cRacun, Len( cRacun ) - At( "-", cRacun ) )
   cBroj := PadL( cBroj, 6 )

   AAdd( ImeKol, { _u( "Broj računa" ), {|| PadR( Trim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok ), 9 ) } } )
   AAdd( ImeKol, { "Fisk.rn", {|| field->fisc_rn } } )
   AAdd( ImeKol, { "Iznos", {|| Str ( pos_iznos_racuna( field->idpos, field->idvd, field->datum, field->brdok ), 13, 2 ) } } )
   AAdd( ImeKol, { "Smj", {||  field->smjena } } )
   AAdd( ImeKol, { "Datum", {|| field->datum } } )
   AAdd( ImeKol, { "Vr.Pl", {|| field->idvrstep } } )
   AAdd( ImeKol, { "Partner", {|| field->idgost } } )
   AAdd( ImeKol, { "Vrijeme", {|| field->vrijeme } } )
   AAdd( ImeKol, { "Placen",     {|| iif ( field->Placen == PLAC_NIJE, "  NE", "  DA" ) } } )

   FOR i := 1 TO Len( ImeKol )
      AAdd( kol, i )
   NEXT

   SELECT pos_doks

   // IF fScope = nil
   // fScope := .T.
   // ENDIF

   // IF fScope
   // SET SCOPEBOTTOM TO "W"
   // ENDIF

   //IF gVrstaRS == "S" .OR. pos_admin()
    //  AAdd( ImeKol, { "Radnik", {|| IdRadnik } } )
    //  AAdd( Kol, Len( ImeKol ) )
      //cFilter += ".and. (Idpos=" + dbf_quote( gIdPos ) + " .or. IdPos='X ')"
   //ELSE
      cFilter += ".and. IdRadnik=" + dbf_quote( gIdRadnik ) + ".and. Idpos=" + dbf_quote( gIdPos )
   //ENDIF

   // IF dDatum <> NIL
   // cFilter += '.and. Datum=' + dbf_quote( dDatum )
   // ENDIF

   IF qIdRoba <> NIL .AND. !Empty( qIdRoba )
      cFilter += ".and. pos_racun_sadrzi_artikal(IdPos, IdVd, datum, BrDok, " + dbf_quote( qIdRoba ) + ")"
   ENDIF

   SET FILTER TO &cFilter
   GO TOP

   IF !Empty( cBroj )
      // SEEK2( cIdPos + "42" + DToS( dDat ) + cBroj )

      IF !Eof()
         cBroj := AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok )
         dDat := pos_doks->datum
         RETURN( .T. )
      ENDIF
      // ELSE
      // GO BOTTOM
   ENDIF

   IF fPrep
      cFnc := "<Enter>-Odabir   <+>-Markiraj/Demarkiraj   <P>-Pregled"
      fMark := .T.
      bMarkF := {|| RacObilj () }
   ELSE
      cFnc := "<Enter>-Odabir          <P>-Pregled"
      bMarkF := NIL
   ENDIF

   KEYBOARD '\'
   my_browse( "pos_rn", f18_max_rows() - 12, f18_max_cols() - 25, {| nCh | lista_racuna_key_handler( nCh ) }, _u( " POS RAČUNI " ), "", NIL, cFnc,, bMarkF )

   SET FILTER TO

   cBroj := AllTrim( pos_doks->IdPos ) + "-" + AllTrim( pos_doks->BrDok )

   IF cBroj = '-'
      cBroj := Space( 9 )
   ENDIF

   dDat := pos_doks->datum

   IF LastKey() == K_ESC
      RETURN( .F. )
   ENDIF

   RETURN( .T. )



STATIC FUNCTION lista_racuna_key_handler( nCh )

   // LOCAL cLevel
   // LOCAL ii
   LOCAL nTrec
   LOCAL nTrec2
   LOCAL hRec

   // IF nCh == 0
   // RETURN ( DE_CONT )
   // ENDIF


   // o_pos_odj()
   // o_pos_strad()

   // select_o_pos_strad( gStrad )
   // cLevel := field->prioritet
   // USE

   // SELECT pos_doks

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
      pos_stampa_priprema( IdPos, DToS( datum ) + BrDok, .T., NIL, .T. )
      SELECT pos_doks
      f7_pf_traka( .T. )
      SELECT pos_doks

      RETURN DE_REFRESH
   ENDIF

   IF Upper( Chr( nCh ) ) == "S"

      pos_storno_rn( .T., pos_doks->brdok, pos_doks->datum, PadR( AllTrim( Str( pos_doks->fisc_rn ) ), 10 ) )
      MsgBeep( "Storno račun se nalazi u pripremi !" )

      SELECT pos_doks
      RETURN DE_REFRESH

   ENDIF

   IF nCh == K_CTRL_V

      IF pos_doks->idvd <> "42"
         RETURN DE_CONT
      ENDIF

      nFisc_no := pos_doks->fisc_rn

      Box(, 1, 40 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "Broj fiskalnog računa: " GET nFisc_no
      READ
      BoxC()

      IF LastKey() <> K_ESC

         hRec := dbf_get_rec()
         hRec[ "fisc_rn" ] := nFisc_no

         update_rec_server_and_dbf( "pos_doks", hRec, 1, "FULL" )

         RETURN DE_REFRESH

      ENDIF

   ENDIF

/*
   IF ( LastKey() == K_ESC ) .OR. ( LastKey() == K_ENTER )
      RETURN ( DE_ABORT )
   ENDIF
*/

   RETURN ( DE_CONT )
