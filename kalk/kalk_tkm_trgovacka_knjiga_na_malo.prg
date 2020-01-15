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

STATIC s_nOpis := 70

FUNCTION kalk_tkm()

   LOCAL hParams
   LOCAL nCount := 0

   IF !get_vars( @hParams )
      RETURN .F.
   ENDIF

   nCount := kalk_gen_fin_stanje_prodavnice( hParams )
   IF nCount > 0
      stampaj_tkm( hParams )
   ENDIF

   RETURN .T.


STATIC FUNCTION get_vars( hParams )

   LOCAL lRet := .F.
   LOCAL nX := 1
   LOCAL _konta := fetch_metric( "kalk_tkm_konto", my_user(), Space( 200 ) )
   LOCAL _d_od := fetch_metric( "kalk_tkm_datum_od", my_user(), Date() - 30 )
   LOCAL _d_do := fetch_metric( "kalk_tkm_datum_do", my_user(), Date() )
   LOCAL _vr_dok := fetch_metric( "kalk_tkm_vrste_dok", my_user(), Space( 200 ) )
   LOCAL _usluge := fetch_metric( "kalk_tkm_gledaj_usluge", my_user(), "N" )
   LOCAL cViseKontaDN := "D"
   LOCAL cXlsxDN := "D"
   LOCAL GetList := {}

   Box(, 14, 72 )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "*** maloprodaja - izvjestaj TKM"

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Datum od" GET _d_od
   @ box_x_koord() + nX, Col() + 1 SAY "do" GET _d_do

   ++nX
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY8 "Konto (jedan, sint, više):" GET _konta PICT "@S35"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "jedan: 13300 sint: 133 vise: 13300;13301;"
   ++nX
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Vrste dok. (prazno-svi):" GET _vr_dok PICT "@S35"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Gledati usluge (D/N) ?" GET _usluge PICT "@!" VALID _usluge $ "DN"
   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Export XLSX (D/N) ?" GET cXlsxDN PICT "@!" VALID cXlsXDN $ "DN"

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN lRet
   ENDIF

   lRet := .T.

   hParams := hb_Hash()
   hParams[ "datum_od" ] := _d_od
   hParams[ "datum_do" ] := _d_do
   hParams[ "konto" ] := _konta
   hParams[ "vrste_dok" ] := _vr_dok
   hParams[ "gledati_usluge" ] := _usluge
   hParams[ "xlsx" ] := iif( cXlsXDN == "D", .T., .F. )

   IF Right( AllTrim( _konta ), 1 ) != ";"
      cViseKontaDN := "N"
      hParams[ "konto" ] := PadR( hParams[ "konto" ], 7 )
   ENDIF
   hParams[ "vise_konta" ] := cViseKontaDN

   set_metric( "kalk_tkm_konto", my_user(), _konta )
   set_metric( "kalk_tkm_datum_od", my_user(), _d_od )
   set_metric( "kalk_tkm_datum_do", my_user(), _d_do )
   set_metric( "kalk_tkm_vrste_dok", my_user(), _vr_dok )
   set_metric( "kalk_tkm_gledati_usluge", my_user(), _usluge )

   RETURN lRet



STATIC FUNCTION stampaj_tkm( hParams )

   LOCAL _red_br := 0
   LOCAL cLine, cOpisKnjizenja
   LOCAL _n_opis, _n_iznosi
   LOCAL nTDug, nTPot, _t_rabat
   LOCAL _a_opis := {}
   LOCAL nI

   cLine := _get_line()

   START PRINT CRET

   ?
   P_COND

   tkm_zaglavlje( hParams )

   ? cLine
   tkm_header()
   ? cLine

   nTDug := 0
   nTPot := 0
   _t_rabat := 0

   SELECT r_export
   GO TOP

   DO WHILE !Eof()

      IF ( Round( field->mp_saldo, 2 ) == 0 .AND. Round( field->nv_saldo, 2 ) == 0 )
         SKIP
         LOOP
      ENDIF

      ? PadL( AllTrim( Str( ++_red_br ) ), 6 ) + "."

      @ PRow(), PCol() + 1 SAY field->datum

      cOpisKnjizenja := AllTrim( field->vr_dok )
      cOpisKnjizenja += " "
      cOpisKnjizenja += "broj: "
      cOpisKnjizenja += AllTrim( field->idvd ) + "-" + AllTrim( field->brdok )
      cOpisKnjizenja += ", "
      cOpisKnjizenja += "veza: " + AllTrim( field->br_fakt )

      IF !Empty( field->opis )
         cOpisKnjizenja += ", "
         cOpisKnjizenja += AllTrim( field->opis )
      ENDIF

      IF !Empty( field->part_naz )
         cOpisKnjizenja += ", "
         cOpisKnjizenja += AllTrim( field->part_naz )
         cOpisKnjizenja += ", "
         cOpisKnjizenja += AllTrim( field->part_adr )
         cOpisKnjizenja += ", "
         cOpisKnjizenja += AllTrim( field->part_mj )
      ENDIF

      _a_opis := SjeciStr( cOpisKnjizenja, s_nOpis )

      @ PRow(), _n_opis := PCol() + 1 SAY _a_opis[ 1 ]
      @ PRow(), _n_iznosi := PCol() + 1 SAY Str( field->mpp_dug + ( - field->mp_rabat ), 12, 2 )
      @ PRow(), PCol() + 1 SAY Str( ( field->mp_pot + field->mp_porez ), 12, 2 )

      nTDug += field->mpp_dug + ( - field->mp_rabat )
      nTPot += field->mp_pot + field->mp_porez
      _t_rabat += field->mp_rabat

      FOR nI := 2 TO Len( _a_opis )
         ?
         @ PRow(), _n_opis SAY _a_opis[ nI ]
      NEXT

      SKIP

   ENDDO

   ? cLine

   ? "UKUPNO:"
   @ PRow(), _n_iznosi SAY Str( nTDug, 12, 2 )
   @ PRow(), PCol() + 1 SAY Str( nTPot, 12, 2 )

   ?U "SALDO TRGOVAČKE KNJIGE:"
   @ PRow(), _n_iznosi SAY Str( nTDug - nTPot, 12, 2 )

   ? cLine

   FF
   ENDPRINT

   IF hParams[ "xlsx" ]
      open_exported_xlsx()
   ENDIF

   RETURN .T.



STATIC FUNCTION tkm_zaglavlje( hParams )

   ?U self_organizacija_id(), "-", AllTrim( self_organizacija_naziv() )
   ?
   ?U Space( 10 ), "TRGOVAČKA KNJIGA NA MALO (TKM) za period od:"
   ?? hParams[ "datum_od" ], "do:", hParams[ "datum_do" ]
   ?
   ?U "Uslov za prodavnice: "

   IF !Empty( AllTrim( hParams[ "konto" ] ) )
      ?? AllTrim( hParams[ "konto" ] )
   ELSE
      ?? " sve prodavnice"
   ENDIF

   ? "na dan", Date()
   ?

   RETURN .T.


STATIC FUNCTION tkm_header()

   LOCAL cRow1, cRow2

   cRow1 := ""
   cRow2 := ""

   cRow1 += PadR( "R.Br", 7 )
   cRow2 += PadR( "", 7 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Datum", 8 )
   cRow2 += PadC( "dokum.", 8 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadR( "", s_nOpis )
   cRow2 += PadR( "Opis knjiženja", s_nOpis )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Zaduženje", 12 )
   cRow2 += PadC( "sa PDV", 12 )

   cRow1 += Space( 1 )
   cRow2 += Space( 1 )

   cRow1 += PadC( "Razduženje", 12 )
   cRow2 += PadC( "sa PDV", 12 )

   ?U cRow1
   ?U cRow2

   RETURN .T.


STATIC FUNCTION _get_line()

   LOCAL cLine

   cLine := ""
   cLine += Replicate( "-", 7 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 8 )
   cLine += Space( 1 )
   cLine += Replicate( "-", s_nOpis )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )
   cLine += Space( 1 )
   cLine += Replicate( "-", 12 )

   RETURN cLine
