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


FUNCTION kalk_storno_dokumenat()

   o_kalk_edit()
   cIdFirma := self_organizacija_id()
   cIdVdU   := "  "
   cBrDokU  := Space( Len( kalk_pripr->brdok ) )
   cBrDokI := cBrDokU
   dDatDok    := CToD( "" )

   Box(, 6, 75 )
   @ box_x_koord() + 0, box_y_koord() + 5 SAY "STORNO DOKUMENTA PROMJENOM PREDZNAKA NA KOLICINI"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument: " + cIdFirma + "-"
   @ Row(), Col() GET cIdVdU
   @ Row(), Col() SAY "-" GET cBrDokU VALID is_kalk_postoji_dokument( cIdFirma, cIdVdU, cBrDokU )
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum dokumenta koji se formira" GET dDatDok VALID !Empty( dDatDok )
   READ; ESC_BCR
   BoxC()

   kalk_set_brkalk_za_idvd( cIdVdU, @cBrDokI )

   find_kalk_by_broj_dokumenta( cIdFirma, cIdVDU, cBrDokU )
   DO WHILE !Eof() .AND. cIdFirma + cIdVDU + cBrDokU == IDFIRMA + IDVD + BRDOK
      PushWA()
      Scatter()
      SELECT kalk_pripr
      APPEND BLANK
      _brdok     := cBrDokI
      _datdok    := dDatDok
      _brfaktp   := Trim( _BrFaktP ) + "/STORNO"
      _kolicina  := -_kolicina
      _error     := "0"
      Gather()
      SELECT KALK
      PopWA()
      SKIP 1
   ENDDO

   CLOSERET

   RETURN .T.



/* is_kalk_postoji_dokument(cDok)
 *     Ispituje postojanje zadanog dokumenta medju azuriranim
 */

FUNCTION is_kalk_postoji_dokument( cIdFirma, cIdvd, cBrDok )


   LOCAL lVrati := .F., nArr := Select()

   find_kalk_doks_by_broj_dokumenta( cIdFirma, cIdVd, cBrDok )

   IF !EOF()
      lVrati := .T.
   ELSE
      MsgBeep( "Dokument pod brojem koji ste unijeli ne postoji!" )
   ENDIF
   SELECT ( nArr )

   RETURN lVrati
