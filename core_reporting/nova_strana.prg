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


FUNCTION zagl_organizacija( nLeft )

   ? " "
   ? Space( nLeft ) + AllTrim( tip_organizacije() ) + " :", AllTrim( self_organizacija_naziv() )
      //+ " " + f18_baza_server_host()
   ? " "

   RETURN .T.



FUNCTION check_nova_strana( bZagl, oPDF, lForceBreakPage, nOduzmi, nPraznihRedovaIliNovaStrana )

   LOCAL nMaxRow, nTmp

   hb_default( @lForceBreakPage, .F. )
   hb_default( @nOduzmi, 0 )
   hb_default( @nPraznihRedovaIliNovaStrana, 0 )


   IF ValType( oPDF ) == "O"
      nMaxRow := oPDF:MaxRow()
   ELSE
      nMaxRow := page_length()
   ENDIF

   FOR nTmp := 1 TO nPraznihRedovaIliNovaStrana // dodaj prazne redove
      IF PRow() <= ( nMaxRow - nOduzmi )
         ?
      ENDIF
   NEXT

   IF lForceBreakPage .OR. ( PRow() > ( nMaxRow - nOduzmi ) )

      IF ValType( oPDF ) == "O"
         // oPDF:DrawText( oPDF:MaxRow(), 0, "" )
         oPDF:PageHeader()
      ELSE
         // txt obicni
         FF
      ENDIF
      SetPRC( 0, 0 )
      IF ( bZagl <> NIL )
         PushWa()
         Eval( bZagl )
         PopWa()
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.
