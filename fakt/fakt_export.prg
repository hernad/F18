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



FUNCTION fakt_export_tbl_fakt()

   LOCAL dD_f
   LOCAL dD_t
   LOCAL cId_f
   LOCAL cId_td

   IF get_vars( @dD_f, @dD_t, @cId_f, @cId_td ) == 0
      RETURN .F.
   ENDIF

   // kreiraj export tabelu
   cre_export_table()
   o_r_export_legacy()
   INDEX ON idfirma + idtipdok + brdok TAG "1"

   fill_export_table( dD_f, dD_t, cId_f, cId_td )

   RETURN .T.


STATIC FUNCTION fill_export_table( dD_f, dD_t, cId_f, cId_td )

   LOCAL cFilt := ""
   LOCAL cIdFirma
   LOCAL cIdTipDok
   LOCAL cBrDok
   LOCAL cIdRoba
   LOCAL nCount := 0

   o_r_export_legacy()
   // o_roba()


   IF !Empty( cId_f )
      cFilt += Parsiraj( AllTrim( cId_f ), "idfirma", "C" )
   ENDIF

   IF !Empty( cId_td )
      IF !Empty( cFilt )
         cFilt += " .and. "
      ENDIF
      cFilt += Parsiraj( AllTrim( cId_td ), "idtipdok", "C" )
   ENDIF

   seek_fakt()

   IF !Empty( cFilt )
      SET FILTER TO &cFilt
      GO TOP
   ENDIF

   DO WHILE !Eof()

      // provjeri datum
      IF ( field->datdok < dD_f .OR. field->datdok > dD_t )
         SKIP
         LOOP
      ENDIF

      cIdFirma := field->idfirma
      cIdTipDok := field->idtipdok
      cBrDok := field->brdok
      cIdRoba := field->idroba

      // pozicioniraj se na doks
      seek_fakt_doks( cIdFirma, cIdTipdok, cBrDok )

      SELECT r_export
      APPEND BLANK

      ++nCount

      REPLACE idfirma WITH fakt->idfirma
      REPLACE idtipdok WITH fakt->idtipdok
      REPLACE brdok WITH fakt->brdok
      REPLACE datdok WITH fakt->datdok
      REPLACE idpartner WITH fakt_doks->idpartner
      REPLACE idroba WITH fakt->idroba
      REPLACE kolicina WITH fakt->kolicina
      REPLACE cijena WITH fakt->cijena
      REPLACE rabat WITH fakt->rabat

      IF fakt->( FieldPos( "IDRELAC" ) ) <> 0
         REPLACE idrel WITH fakt->idrelac
      ENDIF

      SELECT fakt
      SKIP
   ENDDO

   IF nCount > 0
      MsgBeep( "Exportovao " + AllTrim( Str( nCount ) ) + " zapisa u r_exp !" )
   ENDIF

   RETURN .T.


STATIC FUNCTION cre_export_table()

   LOCAL aDbf

   aDbf := get_export_fields()
   IF !xlsx_export_init( aDbf )
      RETURN .F.
   ENDIF

   RETURN .T.



STATIC FUNCTION get_export_fields()

   LOCAL aRet := {}

   AAdd( aRet, { "IDFIRMA", "C", 2, 0 } )
   AAdd( aRet, { "IDTIPDOK", "C", 2, 0 } )
   AAdd( aRet, { "BRDOK", "C", 8, 0 } )
   AAdd( aRet, { "DATDOK", "D", 8, 0 } )
   AAdd( aRet, { "IDPARTNER", "C", 6, 0 } )
   AAdd( aRet, { "IDROBA", "C", 10, 0 } )
   AAdd( aRet, { "KOLICINA", "N", 20, 5 } )
   AAdd( aRet, { "CIJENA", "N", 20, 5 } )
   AAdd( aRet, { "RABAT", "N", 20, 5 } )
   AAdd( aRet, { "IDREL", "C", 5, 0 } )

   RETURN aRet



STATIC FUNCTION get_vars( dD_f, dD_t, cId_f, cId_td )

   LOCAL nRet := 1
   LOCAL GetList := {}

   dD_f := Date() - 60
   dD_t := Date()
   cId_f := PadR( self_organizacija_id() + ";", 100 )
   cId_td := PadR( "10;", 100 )

   Box(, 5, 65 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Datum od" GET dD_f
   @ box_x_koord() + 1, Col() + 1 SAY "do" GET dD_t
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma (prazno-sve):" GET cId_f  PICT "@S20"
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Tip dokumenta (prazno-svi:)" GET cId_td  PICT "@S20"
   READ
   BoxC()

   IF LastKey() == K_ESC
      nRet := 0
   ENDIF

   RETURN nRet
