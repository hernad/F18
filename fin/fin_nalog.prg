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

STATIC s_nColIzn := 20
STATIC s_oPDF

MEMVAR M
MEMVAR cIdFirma, cIdVn, cBrNal, dDatNal


FUNCTION fin_nalog_suban_stampa_azurirani_dokument()

   LOCAL dDatNal
   LOCAL GetList := {}
   LOCAL xPrintOpt


   PRIVATE fK1 := fk2 := fk3 := fk4 := "N", gnLOst := 0, gPotpis := "N"

   fin_read_params()

   cIdVN := Space( 2 )
   cIdFirma := self_organizacija_id()
   cBrNal := Space( 8 )

   Box( "", 2, 35 )

   SET CURSOR ON

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Nalog:"
   @ box_x_koord() + 1, Col() + 1 SAY cIdFirma
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVN PICT "@!"
   @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrNal VALID fin_fix_broj_naloga( @cBrNal )

   READ
   ESC_BCR

   BoxC()

   find_nalog_by_broj_dokumenta( cIdFirma, cIdvn, cBrnal )
   GO TOP
   EOF CRET

   dDatNal := datnal

   find_suban_by_broj_dokumenta( cIdFirma, cIdvn, cBrnal )

/*
   IF !start_print()
      RETURN .F.
   ENDIF
   */

   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "font_size" ] := 8
   xPrintOpt[ "opdf" ] := s_oPDF
   fin_nalog_set_pdf( s_oPDF )
   IF f18_start_print( NIL, xPrintOpt,  "FIN NALOG " + fin_dokument_str( cIdFirma, cIdVn, cBrNal ) + "  NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   fin_nalog_stampa_fill_psuban( "2", .T., dDatNal, NIL, NIL )
   my_close_all_dbf()

   f18_end_print( NIL, xPrintOpt )


   RETURN .T.


FUNCTION fin_nalog_k_ctrl_p()

   my_close_all_dbf()
   fin_gen_ptabele_stampa_nalozi()

   RETURN NIL


FUNCTION kalk_generisi_finansijski_nalog( lAuto, lStampa )

   IF !f18_use_module( "fin" )
      RETURN .F.
   ENDIF

   IF kalk_kontiranje_fin_naloga( .T., lAuto )
      RETURN fin_nalog_stampa_nakon_kontiranja( lAuto, lStampa )
   ENDIF

   RETURN .F.


/*
   Koristi se u KALK za štampu finansijskog naloga
*/

FUNCTION fin_nalog_stampa_nakon_kontiranja( lAuto, lStampa )

   PRIVATE gDatNal := "N"
   PRIVATE gRavnot := "D"
   PRIVATE cDatVal := "D"

   IF ( lAuto == NIL )
      lAuto := .F.
   ENDIF

   hb_default( @lStampa, .F. )

   IF !fin_nalog_fix_greska_zaokruzenja_fin_pripr( NIL, NIL, NIL, lAuto )
      RETURN .F.
   ENDIF

   IF !lAuto .OR. ( lAuto .AND. lStampa )
      fin_gen_ptabele_stampa_nalozi( lAuto, lStampa ) // nije auti, ili jeste auto + stampa da
   ELSE
      fin_gen_psuban_stavke_auto_import()
      fin_gen_sint_stavke_auto_import()
   ENDIF

   IF !is_fin_nalog_u_ravnotezi() // pretpostavlja da je u fin_pripr jedan fin nalog
      RETURN .F.
   ENDIF

   IF lStampa  // ako se nalog stampa, onda pitati korisnika za azuriranje
      lAuto := .F.
   ENDIF

   RETURN fin_azuriranje_naloga( lAuto )



FUNCTION fin_nalog_fix_greska_zaokruzenja_fin_pripr( cIdFirma, cIdVn, cBrNal, lAuto )

   LOCAL nDuguje := 0
   LOCAL nDuguje2 := 0
   LOCAL nPotrazuje := 0
   LOCAL nPotrazuje2 := 0
   LOCAL lRet := .T.
   LOCAL hRec
   LOCAL cUravnotezitiDN := "N"

   hb_default( @lAuto, .F. ) // .T. - ispravka se vrsi bez pitanja
   PushWa()

   SELECT F_FIN_PRIPR
   IF !Used()
      o_fin_pripr()
   ENDIF

   SELECT fin_pripr
   IF cIdFirma == NIL
      GO TOP
      cIdFirma := field->idfirma
      cIdVn := field->idvn
      cBrNal := field->brnal
   ENDIF

   SEEK cIdFirma + cIdVn + cBrNal

   my_flock()
   DO WHILE  !Eof() .AND. ( field->IdFirma + field->IdVn + field->BrNal == cIdFirma + cIdVn + cBrNal )

      REPLACE field->iznosbhd WITH Round( field->iznosbhd, 2 ), ; // iznos KM dvije decimale
         field->iznosdem WITH Round( field->iznosdem, 2 )

      IF field->D_P == "1"
         nDuguje += Round( field->IznosBHD, 2 )
         nDuguje2 += Round( field->iznosdem, 2 )
      ELSE
         nPotrazuje += Round( field->IznosBHD, 2 )
         nPotrazuje2 += Round( field->iznosdem, 2 )
      ENDIF

      SKIP
   ENDDO
   my_unlock()

   SKIP -1

   hRec := dbf_get_rec()

   IF fin_automatska_ravnoteza_kod_azuriranja()
      cUravnotezitiDN := "D"
   ELSE
      cUravnotezitiDN := "N"
   ENDIF

   IF Round( nDuguje - nPotrazuje, 2 ) == 0
      lRet := .T.
   ELSE

      //IF  ( lAuto .OR. ( Pitanje(, "Želite li uravnotežiti nalog (D/N) ?", cUravnotezitiDN ) == "D" ) )
         hRec[ "opis" ] := "GRESKA ZAOKRUZ."
         hRec[ "brdok" ] := ""
         hRec[ "d_p" ] := "2"
         hRec[ "idkonto" ] := kalk_imp_txt_param_auto_import_podataka_konto()

         hRec[ "rbr" ] := hRec[ "rbr" ] + 1 // posljednja stavka Rbr + 1
         hRec[ "idpartner" ] := ""
         hRec[ "iznosbhd" ] := nDuguje - nPotrazuje
         hRec[ "iznosdem" ] := Round( konverzija_km_dem( hRec[ "datdok" ], hRec[ "iznosbhd" ] ), 2 )
         APPEND BLANK
         dbf_update_rec( hRec )
         lRet := .T.
      //ELSE
      //   lRet := .F.
      //ENDIF

   ENDIF

   PopWa()

   RETURN lRet




FUNCTION fin_gen_ptabele_auto_bez_stampe()
   RETURN fin_gen_ptabele_stampa_nalozi( .T., .F. )

/*
   generisi psuban, psint, pnalog, štampaj sve naloge
*/

FUNCTION fin_gen_ptabele_stampa_nalozi( lAuto, lStampa )

   LOCAL dDatNal := Date()

   IF lAuto == NIL
      lAuto := .F.
   ENDIF

   IF lStampa == NIL
      lStampa := .T.
   ENDIF

   IF fin_gen_psuban_stampa_nalozi( lAuto, lStampa, @dDatNal )
      IF lAuto
         lStampa := .F. // kada je auto, ne stampati sintetiku
      ENDIF
      fin_gen_sint_stavke( lStampa, dDatNal )
   ENDIF

   RETURN .T.



FUNCTION fin_stampa_prenos_na_sljedecoj_strani()

   ? m
   ? PadR( "UKUPNO NA STRANI " + AllTrim( Str( nStr ) ), 30 ) + ":"
   @ PRow(), s_nColIzn  SAY nTSDugBHD PICTURE picBHD
   @ PRow(), PCol() + 1 SAY nTSPotBHD PICTURE picBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY nTSDugDEM PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nTSPotDEM PICTURE picDEM
   ENDIF
   ? m
   ? PadR( "DONOS SA PRETHODNE STRANE", 30 ) + ":"
   @ PRow(), s_nColIzn  SAY nUkDugBHD - nTSDugBHD PICTURE picBHD
   @ PRow(), PCol() + 1 SAY nUkPotBHD - nTSPotBHD PICTURE picBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY nUkDugDEM - nTSDugDEM PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nUkPotDEM - nTSPotDEM PICTURE picDEM
   ENDIF
   ? m
   ? PadR( "PRENOS NA NAREDNU STRANU", 30 ) + ":"
   @ PRow(), s_nColIzn  SAY nUkDugBHD PICTURE picBHD
   @ PRow(), PCol() + 1 SAY nUkPotBHD PICTURE picBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 1 SAY nUkDugDEM PICTURE picDEM
      @ PRow(), PCol() + 1 SAY nUkPotDEM PICTURE picDEM
   ENDIF
   ? m
   FF
   nTSDugBHD := nTSPotBHD := nTSDugDEM := nTSPotDEM := 0   // tekuca strana

   RETURN .T.
