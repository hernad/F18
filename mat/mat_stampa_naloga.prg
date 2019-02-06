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

STATIC PicDEM := "@Z 9999999.99"
STATIC PicBHD := "@Z 999999999.99"
STATIC PicKol := "@Z 999999.999"


FUNCTION mat_stampa_naloga()

   LOCAL _izbor := 1
   LOCAL _opc := {}
   LOCAL _opcexe := {}

   AAdd( _opc, "1. subanalitika     " )
   AAdd( _opcexe, {|| mat_st_anal_nalog( .F. ) } )
   AAdd( _opc, "2. analitika" )
   AAdd( _opcexe, {|| mat_st_sint_nalog() } )

   f18_menu( "onal", .F., _izbor, _opc, _opcexe )

   RETURN .T.



FUNCTION mat_st_sint_nalog( fnovi )

   IF PCount() == 0
      fnovi := .F.
   ENDIF

   o_konto()
   o_tnal()
   IF fnovi
      O_MAT_PANAL2
      cIdFirma := idFirma
      cIdVN := idvn
      cBrNal := brnal
   ELSE
      O_MAT_ANAL
      SELECT mat_anal
      SET ORDER TO TAG "2"
      cIdFirma := self_organizacija_id()
      cIdVN := Space( 2 )
      cBrNal := Space( 4 )
   ENDIF


   IF !fnovi
      Box( "", 1, 35 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Nalog:"

         @ box_x_koord() + 1, Col() + 1 SAY cIdFirma

      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVN
      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrNal
      read; ESC_BCR
      BoxC()
   ENDIF

   SEEK cidfirma + cidvn + cbrNal
   NFOUND CRET

   nStr := 0

   START PRINT CRET
   ?

   A := 0
   IF gkonto == "N"  .AND. g2Valute == "D"
      M := "--- -------- ------- --------------------------------------------------------- ---------- ---------- ------------ ------------"
   ELSE
      M := "--- -------- ------- --------------------------------------------------------- ------------ ------------"
   ENDIF

   nStr := 0

   b1 := {|| !Eof() }
   b2 := {|| cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal }
   IF a <> 0;EJECTA0; Zagl12(); ENDIF

   nRbr2 := 0
   nDug11 := nPot11 := nDug22 := nPot22 := 0
   DO WHILE Eval( b1 ) .AND. Eval( b2 )     // jedan nalog

      cSinKon := Left( IdKonto, 3 )
      b3 := {|| cSinKon == Left( IdKonto, 3 ) }

      nDug1 := 0;nPot1 := 0
      nDug2 := 0;nPot2 := 0
      nRbr := 0
      DO WHILE  Eval( b1 ) .AND. Eval( b2 ) .AND. Eval( b3 )  // mat_sinteticki konto
         cIdKonto := IdKonto
         select_o_konto( cIdKonto )
         SELECT mat_anal

         IF A == 0; Zagl12(); ENDIF
         IF A > 63; EJECTA0; Zagl12(); ENDIF

         @ ++A, 0 SAY ++nRBr PICTURE '999'
         @ A, PCol() + 1 SAY datnal
         @ A, PCol() + 1 SAY cIdKonto
         @ A, PCol() + 1 SAY konto->naz
         nCI := PCol() + 1
         @ A, PCol() + 1 SAY Dug PICTURE g_picdem_mat()
         @ A, PCol() + 1 SAY Pot PICTURE g_picdem_mat()
         IF gkonto == "N" .AND. g2Valute == "D"
            @ A, PCol() + 1 SAY Dug2 PICTURE gPicdin
            @ A, PCol() + 1 SAY Pot2 PICTURE gPicdin
         ENDIF
         nDug1 += Dug; nPot1 += Pot
         nDug2 += Dug2;nPot2 += Pot2
         SKIP

      ENDDO  // mat_sinteticki konto
      IF A > 61; EJECTA0; Zagl12(); ENDIF
      @ ++A, 0 SAY M
      @ ++A, 2 SAY ++nRBr2 PICTURE '999'
      @ A, 13 SAY cSinKon
      select_o_konto( cSinKon )
      @ A, PCol() + 5 SAY naz
      SELECT mat_anal

      @ a, ncI - 1 SAY ""
      @ A, PCol() + 1 SAY nDug1 PICTURE g_picdem_mat()
      @ A, PCol() + 1 SAY nPot1 PICTURE g_picdem_mat()
      IF gkonto == "N" .AND. g2Valute == "D"
         @ A, PCol() + 1 SAY nDug2 PICTURE gPicdin
         @ A, PCol() + 1 SAY nPot2 PICTURE gPicdin
      ENDIF
      @ ++A, 0 SAY M

      nDug11 += nDug1; nPot11 += nPot1
      nDug22 += nDug2; nPot22 += nPot2
   ENDDO  // nalog

   IF A > 61; EJECTA0; Zagl12(); ENDIF
   @ ++A, 0 SAY M
   @ ++A, 0 SAY "ZBIR NALOGA:"
   @ a, ncI - 1 SAY ""
   @ A, PCol() + 1  SAY nDug11  PICTURE  g_picdem_mat()
   @ A, PCol() + 1  SAY nPot11  PICTURE  g_picdem_mat()
   IF gkonto == "N" .AND. g2Valute == "D"
      @ A, PCol() + 1  SAY nDug22 PICTURE  gPicdin
      @ A, PCol() + 1  SAY nPot22 PICTURE  gpicdin
   ENDIF
   @ ++A, 0 SAY M


   // FF


   EJECTA0

   ENDPRINT

   my_close_all_dbf()

   RETURN

STATIC FUNCTION Zagl12()

   LOCAL nArr

   ?
   P_COND
   @ A, 0 SAY "MAT.P: ANALITICKI NALOG ZA KNJIZENJE BROJ :"
   @ A, PCol() + 2 SAY cIdFirma + " - " + cIdVn + " - " + cBrNal
   nArr := Select()
   SELECT TNAL; HSEEK cIDVN; @ A, 90 SAY naz; Select( nArr )
   @ a, PCol() + 3 SAY "Str " + Str( ++nStr, 3 )
   @ ++A, 0 SAY M
   IF gkonto == "N" .AND. g2Valute == "D"
      @ ++A, 0 SAY "*R.*  Datum  *         K O N T O                                              *  I Z N O S   " + valuta_domaca_skraceni_naziv() + "   *   I Z N O S   " + ValPomocna() + "     *"
      @ ++A, 0 SAY "*Br*                                                                           --------------------- -------------------------"
      @ ++A, 0 SAY "*  *         *                                                                *   DUG    *    POT   *    DUG     *    POT    *"
   ELSE
      @ ++A, 0 SAY "*R.*  Datum  *         K O N T O                                              *   I Z N O S   " + valuta_domaca_skraceni_naziv() + "     *"
      @ ++A, 0 SAY "*Br*                                                                           -------------------------"
      @ ++A, 0 SAY "*  *         *                                                                *    DUG     *    POT    *"
   ENDIF
   @ ++A, 0 SAY M

   RETURN

FUNCTION g_picdem_mat()
   RETURN iif( g2Valute == "N", gPicDin, kalk_pic_iznos_bilo_gpicdem() )
