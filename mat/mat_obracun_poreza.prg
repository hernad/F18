/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

FUNCTION pornar()

   LOCAL nPPU := nPPP := 0, nt1 := nt2 := nt3 := nt4 := nT5 := 0, nCol1 := 1, nCijena := 0

   // obracun poreza na realizaciju


   O_MAT_SUBAN


   dDatOd := CToD( "" )
   dDatDo := Date()

   cIdFirma := self_organizacija_id()
   qqKonto := Space( 80 )
   cNalPr := PadR( gNalPr, 20 )
   Box( "pnar", 8, 60, .F. )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "OBRACUN POREZA NA REALIZACIJU"

         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto:  " GET qqKonto PICTURE "@S50"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "Za period od" GET dDatOd
      @ box_x_koord() + 6, Col() + 2 SAY "do" GET dDatDo
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Nalozi realizacije" GET cNalPr
      READ;  ESC_BCR
      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   cNalPr := Trim( cNalPR )

   cIdFirma := Left( cIdFirma, 2 )

   aDbf := { { "IDTARIFA", "C", 6, 0 },;
      { "ppp", "N", 6, 2 },;
      { "ppu", "N", 6, 2 },;
      { "MPV", "N", 16, 3 },;
      { "MPVSAP", "N", 16, 3 } ;
      }
   dbcreate2( "real", aDbf )
   SELECT 95
   my_use ( "real" )

   // dbcreateind(my_home()+"reali1","d()+idtarifa",{|| d()+idtarifa})

   SELECT mat_suban; SET FILTER TO Tacno( aUsl1 ) .AND. IdFirma == cIdFirma .AND. ;
      idvn $ cNalPr .AND. u_i == "2" .AND. dDatOd <= datdok .AND. dDatDo >= datdok
   GO TOP
   EOF CRET

   START PRINT CRET
   P_12CPI

   DO WHILE !Eof()
      select_o_roba( mat_suban->idroba )
      select_o_tarifa( roba->idtarifa )
      SELECT mat_suban
      IF Iznos <> 0 .AND. Kolicina <> 0
         nCijena := Iznos / Kolicina
      ELSE
         nCijena := 0
      ENDIF
      SELECT real
      SEEK tarifa->id
      IF !Found()
         dbAppend()
      ENDIF

      REPLACE idtarifa WITH tarifa->id, ;
         ppp WITH tarifa->opp, ;
         ppu WITH tarifa->ppp, ;
         mpvsap WITH mpvsap + suban->kolicina * ncijena, ;
         mpv WITH mpv + suban->kolicina * ncijena / ( 1 + ppu / 100 ) / ( 1 + ppp / 100 )
      SELECT mat_suban
      SKIP
   ENDDO
   SELECT real
   GO TOP
   m := "------- ------ ------- ----------- ----------- ----------- ----------- -----------"
   ? "MAT: Porez na realizaciju za period", ddatOd, "-", dDatDo
   ? m
   ? "Tarifa   PPP     PPU      MPV       Iznos PPP   Iznos PPU   Iznos Por   MPV sa Por"
   ? m
   DO WHILE !Eof()
      ? idtarifa

      nPPP := MPV * ppp / 100
      nPPU := MPV * ( 1 + ppp / 100 ) * ppu / 100
      @ PRow(), PCol() + 1 SAY PPP PICT "999.99%"
      @ PRow(), PCol() + 1 SAY PPU PICT "999.99%"
      nCol1 := PCol() + 1
      @ PRow(), PCol() + 1 SAY MPV PICT picdem
      @ PRow(), PCol() + 1 SAY nPPP PICT picdem
      @ PRow(), PCol() + 1 SAY nPPU PICT picdem
      @ PRow(), PCol() + 1 SAY nPPP + nPPU PICT picdem
      @ PRow(), PCol() + 1 SAY MPVSap PICT picdem
      nT1 += mpv
      nT2 += nPPP
      nT3 += nPPU
      nT4 += nPPU + nPPP
      nT5 += MPVSaP
      SKIP
   ENDDO
   ? m
   ? "Ukupno:"
   @ PRow(), nCol1 SAY nT1  PICT picdem
   @ PRow(), PCol() + 1 SAY nT2  PICT picdem
   @ PRow(), PCol() + 1 SAY nT3  PICT picdem
   @ PRow(), PCol() + 1 SAY nT4  PICT picdem
   @ PRow(), PCol() + 1 SAY nT5  PICT picdem
   ? m
   ENDPRINT
   closeret
