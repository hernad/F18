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



FUNCTION RptInvObrPopisa()

   LOCAL nRecNo
   PRIVATE nStr := 0

   cLin := "--- --------------------------------------------- ------------ ------------"

   cIdFirma := idFirma
   cIdTipDok := idTipDok
   cBrDok := brDok

   nRecNo := RecNo()

   START PRINT CRET

   ZInvp( cLin )

   GO TOP
   DO WHILE !Eof()
      select_o_roba( fakt_pripr->idRoba )
      SELECT fakt_pripr

      print_nova_strana( 125, @nStr, 1 )

      @ PRow() + 1, 0 SAY field->rbr PICTURE "XXX"
      @ PRow(), 4 SAY ""

      ?? PadR( field->idRoba + "" + Trim( Left( roba->naz, 40 ) ) + " (" + roba->jmj + ")", 37 )

      // popisana kolicina
      ?? Space( 10 ) + Replicate( "_", Len( fakt_pic_kolicina() ) -1 ) + Space( 2 )

      // VP cijena
      ?? Transform( field->cijena, fakt_pic_cijena() )
      SKIP
   ENDDO

   print_nova_strana( 125, @nStr, 4 )

   ? cLin

   kalk_clanovi_komisije()

   ENDPRINT

   SELECT fakt_pripr
   GO nRecNo

   RETURN .T.


STATIC FUNCTION ZInvp( cLinija )

   ?
   P_10CPI
   ?? "OBRAZAC POPISA INVENTURE :"
   P_COND2
   ?
   ? "DOKUMENT BR. :", cIdFirma + "-" + cIdTipDok + "-" + cBrDok, Space( 2 ), "Datum:", DatDok
   ?
   print_nova_strana( 125, @nStr, -1 )

   ? cLinija
   ? "*R * ROBA                                        *  Popisana  *   Cijena   *"
   ? "*BR*                                             *  Kolicina  *     VP     *"
   ? cLinija

   RETURN .T.
