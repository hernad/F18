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


FUNCTION epdv_gen_kuf()

   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cSezona := Space( 4 )
   LOCAL GetList := {}

   dDatOd := Date()
   dDatDo := Date()

   Box(, 6, 40 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Generacija KUF"

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum do " GET dDatOd
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "      do " GET dDatDo

   @ box_x_koord() + 6, box_y_koord() + 2 SAY "sezona" GET cSezona
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF


   select_o_epdv_p_kuf()

   IF RECCOUNT2() <> 0
      MsgBeep( "KUF Priprema nije prazna !" )
      IF Pitanje(, "Isprazniti KUF pripremu ?", "N" ) == "D"
         SELECT p_kuf
         my_dbf_zap()
      ENDIF
   ENDIF


   Box(, 5, 60 )

   kalk_kuf( dDatOd, dDatDo, cSezona )
   epdv_generacija_fin_kuf( dDatOd, dDatDo, cSezona )

   epdv_renumeracija_rbr( "P_KUF", .F. )
   BoxC()

   RETURN .T.



FUNCTION epdv_gen_kif()

   LOCAL dDatOd
   LOCAL dDatDo
   LOCAL cSezona
   LOCAL cIdRj := self_organizacija_id()
   LOCAL GetList := {}

   dDatOd := Date()
   dDatDo := Date()
   cSezona := Space( 4 )

   Box(, 4, 40 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "FAKT RJ " GET cIdRj
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum od: " GET dDatOd
   @ box_x_koord() + 2, Col() + 2 SAY "do:" GET dDatDo
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "sezona" GET cSezona

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF


   select_o_epdv_p_kif()

   IF RECCOUNT2() <> 0
      MsgBeep( "KIF Priprema nije prazna !" )
      IF Pitanje(, "Isprazniti KIF pripremu ?", "N" ) == "D"
         SELECT p_kif
         my_dbf_zap()
      ENDIF
   ENDIF

   Box(, 5, 60 )
   epdv_fakt_kif( cIdRj, dDatOd, dDatDo, cSezona )

   kalk_kif( dDatOd, dDatDo, cSezona )

   tops_kif( dDatOd, dDatDo, cSezona )

   fin_kif( dDatOd, dDatDo, cSezona )

   epdv_renumeracija_rbr( "P_KIF", .F. )
   BoxC()

   RETURN .T.
