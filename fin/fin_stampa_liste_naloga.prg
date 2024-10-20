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

MEMVAR m, __print_opt
MEMVAR picDem, picBHD
MEMVAR gPicBHD

#define PRINT_LEFT_SPACE 6

THREAD STATIC s_oPDF

FIELD d_p, IDFirma, Idvn, Brnal, DUGBHD, DUGDEM, POTBHD, POTDEM, DatNal, sifra
MEMVAR fK1, fK2, fK3, fK4, gnLOst, gPotpis


FUNCTION fin_stampa_liste_naloga()

   LOCAL nDug
   LOCAL nPot
   LOCAL nPos := 15
   LOCAL cInteg, nSort, cIdVN, nBrNalLen
   LOCAL nRBr, nDugBHD, nPotBHD, nDugDEM, nPotDEM
   LOCAL bZagl
   LOCAL xPrintOpt

   LOCAL dDatOd := CToD( "" ), dDatDo := CToD( "" ), cOrderBy

   cInteg := "N"
   nSort := 1

   cIdVN := "  "
   Box(, 9, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Provjeriti integritet podataka"
   @ box_x_koord() + 2, box_y_koord() + 2 SAY "u odnosu na datoteku naloga D/N/Q ?"  GET cInteg  PICT "@!" VALID cInteg $ "DN"
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Sortiranje dokumenata po:  1-(firma,vn,brnal) "
   @ box_x_koord() + 5, box_y_koord() + 2 SAY "2-(firma,brnal,vn),    3-(datnal,firma,vn,brnal) " GET nSort PICT "9"
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Vrsta naloga (prazno-svi) " GET cIDVN PICT "@!"

   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Datum od:" GET dDatOd
   @ box_x_koord() + 9, Col() + 2 SAY "do:" GET dDatDo

   READ
   ESC_BCR
   BoxC()

   DO CASE
   CASE nSort == 1
      cOrderBy := "idfirma,idvn,brnal"
   CASE nSort == 2
      cOrderBy := "idfirma,brnal,idvn"
   OTHERWISE
      cOrderBy := "datnal,idfirma,vn,brnal"
   ENDCASE

   IF Empty( dDatOd )
      dDatOd := NIL
   ENDIF
   IF Empty( dDatDo )
      dDatDo := NIL
   ENDIF
   IF Empty( cIdVn )
      cIdVN := NIL
   ENDIF

   IF !find_nalog_za_period( self_organizacija_id(), cIdVn, dDatOd, dDatDo, cOrderBy  )
      MsgBeep( "Nema naloga za prikaz !?" )
      RETURN .F.
   ENDIF

   IF cInteg == "D"
      o_suban()
      SET ORDER TO TAG "4"
      o_anal()
      SET ORDER TO TAG "2"
      o_sint()
      SET ORDER TO TAG "2"
   ENDIF

   SELECT NALOG
   SET ORDER TO nSort
   GO TOP

   nBrNalLen := Len( field->brnal )

   EOF CRET

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  "LISTA FINANSIJSKIH NALOGA NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   m := Space( PRINT_LEFT_SPACE ) + "------- --- --- " + Replicate( "-", nBrNalLen + 1 ) + " -------- ---------------- ----------------"

   IF fin_dvovalutno()
      m += " ------------ ------------"
   ENDIF

   IF FieldPos( "SIFRA" ) <> 0
      m += " ------"
   ENDIF

   IF cInteg == "D"
      m := m + " ---  --- ----"
   ENDIF

   nRBr := 0

   nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0

   picBHD := "@Z " + FormPicL( gPicBHD, 16 )
   picDEM := "@Z " + FormPicL( pic_iznos_eur(), 12 )
   bZagl := {||  zagl( nBrNalLen, cInteg ) }

   Eval( bZagl )

   DO WHILE !Eof()

      IF !Empty( cIdVN ) .AND. idvn <> cIDVN
         SKIP
         LOOP
      ENDIF

      check_nova_strana( bZagl, s_oPDF )

      @ PRow() + 1, 0 SAY Space( PRINT_LEFT_SPACE )
      @ PRow(), PCol() + 0 SAY ++nRBr PICTURE "999999"
      @ PRow(), PCol() + 2 SAY IdFirma
      @ PRow(), PCol() + 2 SAY IdVN
      @ PRow(), PCol() + 2 SAY BrNal
      @ PRow(), PCol() + 1 SAY DatNal
      @ PRow(), nPos := PCol() + 1 SAY DugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY PotBHD PICTURE picBHD
      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY DugDEM PICTURE picDEM
         @ PRow(), PCol() + 1 SAY PotDEM PICTURE picDEM
      ENDIF

      IF FieldPos( "SIFRA" ) <> 0
         @ PRow(), PCol() + 1 SAY iif( Empty( sifra ), Space( 2 ), Left( Crypt( sifra ), 2 ) )
      ENDIF

      IF cInteg == "D"

         find_suban_by_broj_dokumenta( nalog->IdFirma, nalog->IdVN, nalog->BrNal )
         nDug := 0.00
         nPot := 0.00
         DO WHILE ( IDFirma + Idvn + Brnal ) == NALOG->( IDFirma + Idvn + Brnal )  .AND. !Eof()
            IF d_p = "1"
               nDug += field->iznosbhd
            ELSE
               nPot += field->iznosbhd
            ENDIF
            SKIP
         ENDDO
         SELECT NALOG
         IF Str( nDug, 20, 2 ) == Str( field->DugBHd, 20, 2 ) .AND. Str( nPot, 20, 2 ) == Str( field->PotBHD, 20, 2 )
            ?? "     "
         ELSE
            ?? " ERR "
         ENDIF

         find_anal_by_broj_dokumenta( nalog->IdFirma, nalog->IdVN, nalog->BrNal )
         nDug := 0.00
         nPot := 0.00
         DO WHILE ( IDFirma + Idvn + Brnal ) == NALOG->( IDFirma + Idvn + Brnal ) .AND. !Eof()
            nDug += dugbhd
            nPot += potbhd
            SKIP
         ENDDO

         SELECT NALOG
         IF Str( nDug, 20, 2 ) == Str( DugBHd, 20, 2 ) .AND. Str( nPot, 20, 2 ) == Str( PotBHD, 20, 2 )
            ?? "     "
         ELSE
            ?? " ERR "
         ENDIF

         find_sint_by_broj_dokumenta( nalog->IdFirma, nalog->IdVN, nalog->BrNal )
         nDug := 0.00
         nPot := 0.00
         DO WHILE ( IDFirma + Idvn + Brnal ) == NALOG->( IDFirma + Idvn + Brnal ) .AND. !Eof()
            nDug += dugbhd
            nPot += potbhd
            SKIP
         ENDDO

         SELECT NALOG
         IF Str( nDug, 20, 2 ) == Str( DugBHd, 20, 2 ) .AND. Str( nPot, 20, 2 ) == Str( PotBHD, 20, 2 )
            ?? "     "
         ELSE
            ?? " ERR "
         ENDIF

      ENDIF

      nDugBHD += DugBHD
      nPotBHD += PotBHD
      nDugDEM += DugDEM
      nPotDEM += PotDEM
      SKIP
   ENDDO

   check_nova_strana( bZagl, s_oPDF )

   ? m
   ? Space( PRINT_LEFT_SPACE ) + "   UKUPNO:"

   @ PRow(), nPos SAY nDugBHD PICTURE picBHD
   @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD

   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY nDugDEM PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picDEM
   ENDIF

   ? m
   f18_end_print( NIL, xPrintOpt )

   RETURN .T.


STATIC FUNCTION zagl( nBrNalLen, cInteg )

   zagl_organizacija( PRINT_LEFT_SPACE )

   ? m
   ?U Space( PRINT_LEFT_SPACE ) + "* R.br *FIR* V *" + PadR( " BR", nBrNalLen + 1 ) + "* DAT    *   DUGUJE       *   POTRAŽUJE   *" + iif( fin_dvovalutno(), "   DUGUJE   * POTRAZUJE *", "" )

   IF FieldPos( "SIFRA" ) <> 0
      ?? "  OP. *"
   ENDIF

   IF cInteg == "D"
      ?? "  1  * 2 * 3 *"
   ENDIF

   ? Space( PRINT_LEFT_SPACE ) + "*      *MA * N *" + PadR( " NAL", nBrNalLen + 1 ) + "* NAL    *    " + valuta_domaca_skraceni_naziv() + "        *      " + valuta_domaca_skraceni_naziv() + "     *"

   IF fin_dvovalutno()
      ?? "    " + ValPomocna() + "    *    " + ValPomocna() + "   *"
   ENDIF

   IF FieldPos( "SIFRA" ) <> 0
      ?? "      *"
   ENDIF

   IF cInteg == "D"
      ?? "     *   *   *"
   ENDIF

   ? m

   RETURN .T.
