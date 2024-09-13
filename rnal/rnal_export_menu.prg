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

FUNCTION rnal_export_menu( nDoc_no, aDocList, lTemp, lWriteRel )

   LOCAL mX := box_x_koord()
   LOCAL mY := box_y_koord()
   LOCAL _opc := {}
   LOCAL _opcexe := {}
   LOCAL _izbor := 1

   AAdd( _opc, "1. rnal -> GPS.opt (Lisec)         " )
   AAdd( _opcexe, {|| exp_2_lisec( nDoc_no, lTemp, lWriteRel ), _izbor := 0 } )
   AAdd( _opc, "2. rnal -> FAKT   " )
   AAdd( _opcexe, {|| exp_2_fmk( lTemp, nDoc_no, aDocList ), _izbor := 0 } )
   AAdd( _opc, "3. rnal -> FAKT (zadnja otpremnica) " )
   AAdd( _opcexe, {|| exp_2_fmk( lTemp, nDoc_no, aDocList, .T. ), _izbor := 0 } )

   f18_menu( "export", .f., @_izbor, _opc, _opcexe )

   box_x_koord( mX )
   box_y_koord( mY )

   RETURN
