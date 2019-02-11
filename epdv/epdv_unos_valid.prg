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



FUNCTION epdv_valid_id_tar( cIdTar, nOsnov, nPdv,  nShow, lNova )

   LOCAL nStopa
   LOCAL nPrerPdv

   PushWA()

   P_Tarifa( @cIdTar )

   select_o_tarifa( cIdTar )
   nStopa := tarifa->pdv

   nPrerPdv := Round( nOsnov * nStopa / 100, ZAO_IZN() )

   IF lNova
      nPdv := nPrerPdv
   ELSE

      IF ( ( Round( nPrerPdv, 4 ) <> Round( nPdv, 4 ) ) )
         IF Pitanje( "", "Preračunati prema stopi PDV-a (D/N) ?", "N" ) == "D"
            nPdv := nPrerPdv
         ENDIF
      ENDIF
   ENDIF

   IF nShow <> nil
      @ Row(), nShow + 2 SAY "Tarifa:" + stopa_pdv( nStopa )
      @ Row(), Col() + 2 SAY "iznos PDV: "
      @ Row(), Col() + 2 SAY nPdV PICT PIC_IZN()
   ENDIF

   PopWa()

   RETURN .T.


FUNCTION epdv_valid_partner( cIdPart, cIdTar, cTbl, lShow )

   IF lShow == nil
      lShow := .T.
   ENDIF

   p_partner( @cIdPart )

   IF partner_is_ino( cIdPart )
      IF lShow
         IF cTbl == "KUF"
            MsgBeep( "Ino dobavljač, setuje tarifu na PDV7UV !" )
            cIdTar := PadR( "PDV7UV", 6 )
         ELSE
            MsgBeep( "Ino kupac, setuje tarifu na PDV0IZ !" )
            cIdTar := PadR( "PDV0IZ", 6 )

         ENDIF
      ENDIF
   ENDIF

   IF IsUio( cIdPart )
      cIdTar := PadR( "UIO", 6 )
   ENDIF

   RETURN .T.


FUNCTION valid_nazad( nNazad )

   LOCAL i

   FOR i := 1 TO nNazad
      KEYBOARD K_UP
   NEXT

   RETURN .T.
