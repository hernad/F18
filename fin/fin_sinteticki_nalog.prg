/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2018 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

MEMVAR m, PicBHD, PicDEM

FUNCTION fin_sinteticki_nalog_stampa( lAzuriraniDokument )

   LOCAL dDatNal

   IF lAzuriraniDokument == NIL
      lAzuriraniDokument := .T.
   ENDIF

   PicBHD := "@Z " + FormPicL( gPicBHD, 17 )
   PicDEM := "@Z " + FormPicL( pic_iznos_eur(), 12 )

   M := "---- -------- ------- --------------------------------------------- ----------------- -----------------" + IIF( fin_jednovalutno(), "-", " ------------ ------------" )

   IF lAzuriraniDokument

      close_open_panal()

      cIdVN := Space( 2 )
      cIdFirma := self_organizacija_id()
      cBrNal := Space( 8 )

      Box( "", 1, 35 )
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Nalog:"

      @ box_x_koord() + 1, Col() + 1 SAY cIdFirma

      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVN PICT "@!"
      @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrNal VALID fin_fix_broj_naloga( @cBrNal )
      READ
      ESC_BCR
      BoxC()

      IF !find_nalog_by_broj_dokumenta( cIdFirma, cIdVn, cBrNal )
         my_close_all_dbf()
         RETURN .F.
      ENDIF

      dDatNal := field->datnal

      // SELECT PANAL
      find_anal_by_broj_dokumenta( cIdFirma, cIdVN, cBrNal, "PANAL" )

   ELSE
      cIdFirma := idfirma
      cIdvn := idvn
      cBrNal := brnal
      dDatNal := datnal
      SEEK cIdfirma + cIdvn + cBrNal
   ENDIF


   START PRINT RET
   nStr := 0

   b1 := {|| !Eof() }

   nCol1 := 70

   cIdFirma := IdFirma; cIDVn = IdVN
   cBrNal := BrNal
   b2 := {|| cIdFirma == IdFirma .AND. cIdVN == IdVN .AND. cBrNal == BrNal }
   b3 := {|| cIdSinKon == Left( IdKonto, 3 ) }
   b4 := {|| cIdKonto == IdKonto }
   nDug3 := nPot3 := 0
   nRbr2 := 0
   nRbr := 0
   nUkUkDugBHD := nUkUkPotBHD := nUkUkDugDEM := nUkUkPotDEM := 0

   zagl_sinteticki_nalog( dDatNal )

   DO WHILE Eval( b1 ) .AND. Eval( b2 )

      nova_strana( dDatNal )

      cIdSinKon := Left( IdKonto, 3 )
      nUkDugBHD := nUkPotBHD := nUkDugDEM := nUkPotDEM := 0

      DO WHILE  Eval( b1 ) .AND. Eval( b2 ) .AND. Eval( b3 )

         cIdKonto := IdKonto
         nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0

         nova_strana( dDatNal )

         DO WHILE  Eval( b1 ) .AND. Eval( b2 ) .AND. Eval( b4 )
            select_o_konto( cIdkonto )
            SELECT PANAL
            P_NRED
            @ PRow(), 0 SAY  ++nRBr PICTURE '9999'
            @ PRow(), PCol() + 1 SAY IF( gDatNal == "D", Space( 8 ), datnal )
            @ PRow(), PCol() + 1 SAY cIdKonto
            @ PRow(), PCol() + 1 SAY Left( KONTO->naz, 45 )
            nCol1 := PCol() + 1
            @ PRow(), nCol1 SAY DugBHD PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY PotBHD PICTURE PicBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY DugDEM PICTURE PicDEM
               @ PRow(), PCol() + 1 SAY PotDEM PICTURE PicDEM
            ENDIF
            nDugBHD += DugBHD
            nDugDEM += DUGDEM
            nPotBHD += PotBHD
            nPotDEM += POTDEM
            SKIP
         ENDDO

         nUkDugBHD += nDugBHD
         nUkPotBHD += nPotBHD
         nUkDugDEM += nDugDEM
         nUkPotDEM += nPotDEM

      ENDDO

      nova_strana( dDatNal )

      P_NRED
      ?? M
      P_NRED

      @ PRow(), 1 SAY ++nRBr2 PICTURE '999'
      @ PRow(), PCol() + 1 SAY PadR( cIdSinKon, 6 )

      select_o_konto( cIdSinKon )

      @ PRow(), PCol() + 1 SAY Left( Naz, 45 )

      SELECT PANAL

      @ PRow(), nCol1 SAY nUkDugBHD PICTURE PicBHD
      @ PRow(), PCol() + 1 SAY nUkPotBHD PICTURE PicBHD

      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY nUkDugDEM PICTURE PicDEM
         @ PRow(), PCol() + 1 SAY nUkPotDEM PICTURE PicDEM
      ENDIF

      P_NRED
      ?? M

      nUkUkDugBHD += nUkDugBHD
      nUKUkPotBHD += nUkPotBHD
      nUkUkDugDEM += nUkDugDEM
      nUkUkPotDEM += nUkPotDEM

   ENDDO

   nova_strana( dDatnal )

   P_NRED
   ?? M
   P_NRED

   ?? "ZBIR NALOGA:"

   @ PRow(), nCol1 SAY nUkUkDugBHD PICTURE PicBHD
   @ PRow(), PCol() + 1 SAY nUkUkPotBHD PICTURE PicBHD

   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY nUkUkDugDEM PICTURE PicDEM
      @ PRow(), PCol() + 1 SAY nUkUkPotDEM PICTURE PicDEM
   ENDIF

   P_NRED
   ?? M

   FF

   end_print()

   IF lAzuriraniDokument
      my_close_all_dbf()
   ENDIF

   RETURN .T.



FUNCTION zagl_sinteticki_nalog( dDatNal )

   LOCAL nArr

   ?
   P_COND
   F10CPI
   ?? tip_organizacije() + ":", self_organizacija_naziv()
/*
   IF gNW == "N"
      -- SELECT partn
      -- HSEEK cIdfirma
      SELECT panal
      ? cidfirma, "-", partn->naz
   ENDIF
*/
   ?
   P_COND
   ?U "FIN: ANALITIKA/SINTETIKA -  NALOG ZA KNJIŽENJE BROJ : "
   @ PRow(), PCol() + 2 SAY cIdFirma + " - " + cIdVn + " - " + cBrNal

   IF gDatNal == "D"
      @ PRow(), PCol() + 4 SAY "DATUM: "
      ?? dDatNal
   ENDIF

   select_o_tnal( cIdVN )
   SELECT PANAL

   @ PRow(), PCol() + 4 SAY tnal->naz
   @ PRow(), PCol() + 15 SAY "Str:" + Str( ++nStr, 3 )

   P_NRED
   ?? m
   P_NRED
   ?? "*RED*" + PadC( iif( gDatNal == "D", "", "DATUM" ), 8 ) + "*           NAZIV KONTA                               *            IZNOS U " + valuta_domaca_skraceni_naziv() + "           *" + IF( fin_jednovalutno(), "", "     IZNOS U " + ValPomocna() + "       *" )
   P_NRED
   ?? "    *        *                                                      ----------------------------------- " + IF( fin_jednovalutno(), "", "-------------------------" )
   P_NRED
   ?? "*BR *        *                                                     * DUGUJE  " + valuta_domaca_skraceni_naziv() + "    * POTRAZUJE  " + valuta_domaca_skraceni_naziv() + " *" + IF( fin_jednovalutno(), "", " DUG. " + ValPomocna() + "  * POT. " + ValPomocna() + " *" )
   P_NRED
   ?? m

   RETURN .T.



STATIC FUNCTION nova_strana( dDatNal )

   IF PRow() > ( 61 + dodatni_redovi_po_stranici() )
      FF
      zagl_sinteticki_nalog( dDatnal )
   ENDIF

   RETURN .T.



STATIC FUNCTION close_open_panal()

   my_close_all_dbf()

   // SELECT ( F_ANAL )
   // my_use( "panal", "fin_anal" )

   // o_konto()
   // o_partner()
   //o_tnal()
   o_nalog()

   RETURN .T.
