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

MEMVAR cIdfirma, cIdvd, cBrdok
MEMVAR gTops, gFakt
MEMVAR __print_opt
MEMVAR  PicCDEM, PicProc, PicDEM, PicKol, gPicPROC, gPicNC

MEMVAR nStr

FUNCTION kalk_stampa_svih_dokumenata_u_pripremi()
   RETURN kalk_stampa_dokumenta( .F., .T. )

FUNCTION kalk_stampa_dokumenta_priprema( lBezPitanjaDok )
   RETURN kalk_stampa_dokumenta( .F., lBezPitanjaDok )

FUNCTION kalk_stampa_azuriranog_dokumenta_na_osnovu_doks()
   RETURN kalk_stampa_dokumenta( .T., .T. )

FUNCTION kalk_stampa_azuriranog_dokumenta()
   RETURN kalk_stampa_dokumenta( .T., .F. )

FUNCTION kalk_stampa_dokumenta( lAzuriraniDokument, lBezPitanjaBrDok )

   LOCAL cOk
   LOCAL cNaljepniceDN := "N"
   LOCAL GetList := {}
   LOCAL lDokumentZaPOS, lDokumentZaFakt
   PRIVATE cIdfirma, cIdvd, cBrdok


   PRIVATE PicCDEM := kalk_pic_cijena_bilo_gpiccdem()
   PRIVATE PicProc := gPICPROC
   PRIVATE PicDEM  := kalk_pic_iznos_bilo_gpicdem()
   PRIVATE Pickol  := kalk_pic_kolicina_bilo_gpickol()
   PRIVATE nStr := 0

   IF ( PCount() == 0 )
      lAzuriraniDokument := .F.
   ENDIF
   IF ( lAzuriraniDokument == NIL )
      lAzuriraniDokument := .F.
   ENDIF
   IF ( lBezPitanjaBrDok == NIL )
      lBezPitanjaBrDok := .F.
   ENDIF

   IF lAzuriraniDokument .AND. lBezPitanjaBrDok
      cIdFirma := kalk_doks->IdFirma
      cIdVd := kalk_doks->IdVd
      cBrDok := kalk_doks->BrDok
      open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok )
   ELSE
      my_close_all_dbf()
      kalk_open_tables_unos( lAzuriraniDokument )
   ENDIF

   SELECT kalk_pripr
   SET ORDER TO TAG "1"
   GO TOP

   lDokumentZaPOS := .F.
   lDokumentZaFakt := .F.

   DO WHILE .T.
      cIdFirma := kalk_pripr->IdFirma
      cBrDok := kalk_pripr->BrDok
      cIdVD := kalk_pripr->IdVD
      IF Eof()
         EXIT
      ENDIF
      IF Empty( cIdvd + cBrdok + cIdfirma )
         SKIP
         LOOP
      ENDIF
      IF !lBezPitanjaBrDok
         Box( "", 6, 65 )
         SET CURSOR ON
         @ box_x_koord() + 1, box_y_koord() + 2 SAY "KALK Dok broj:"

         @ box_x_koord() + 1, Col() + 2  SAY cIdFirma
         @ box_x_koord() + 1, Col() + 1 SAY "-" GET cIdVD  PICT "@!"
         @ box_x_koord() + 1, Col() + 1 SAY "-" GET cBrDok VALID {|| cBrdok := kalk_fix_brdok( cBrDok ), .T. }
         @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "(Brdok: '00000022', '22' -> '00000022', "
         @ box_x_koord() + 4, box_y_koord() + 2 SAY8 "        '22#  ' -> '22   ', '0022' -> '00000022' ) "
         @ box_x_koord() + 6, box_y_koord() + 2 SAY8 "Štampa naljepnica D/N ?" GET cNaljepniceDN  PICT "@!" VALID cNaljepniceDN $ "DN"
         READ
         ESC_BCR
         BoxC()

         IF lAzuriraniDokument // stampa azuriranog KALK dokumenta
            open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok )
         ENDIF

      ENDIF

      HSEEK cIdFirma + cIdVD + cBrDok
      //IF !Empty( cOk := kalkulacija_ima_sve_cijene( cIdFirma, cIdVd, cBrDok ) ) // provjeri da li kalkulacija ima sve cijene ?
      //   MsgBeep( "Unutar kalkulacije nedostaju pojedine cijene bitne za obračun!##Stavke: " + cOk )
      //ENDIF

      EOF CRET
      IF !pdf_kalk_dokument( cIdVd )
         START PRINT CRET
         ?
      ENDIF

      IF !pdf_kalk_dokument( cIdVd )
         Preduzece()
      ENDIF

      IF cIdVD == "10"
         kalk_stampa_dok_10()

      ELSEIF ( cIdvd $ "11#12#13" )
         kalk_stampa_dok_11()

      ELSEIF ( cIdvd $ "14#KO" )
         kalk_stampa_dok_14()

      ELSEIF ( cIdvd $ "16#95#96" )
         kalk_stampa_dok_16_95_96()

      ELSEIF ( cIdvd $ "41#42#49" )
         kalk_stampa_dok_41_42_49()

      ELSEIF ( cIdvd == "18" )
         kalk_stampa_dok_18()

      ELSEIF ( cIdvd $ "19#71#79" )
         kalk_stampa_dok_19_79()

      ELSEIF ( cIdvd == "80" )
         kalk_stampa_dok_80()

      ELSEIF ( cIdvd == "81" )
         kalk_stampa_dok_81()

      ELSEIF ( cIdvd == "IM" )
         kalk_stampa_dok_im()

      ELSEIF ( cIdvd == "IP" )
         kalk_stampa_dok_ip()

      ELSEIF ( cIdvd == "RN" )
         IF !lAzuriraniDokument
            kalk_raspored_troskova( .T. )
         ENDIF
         kalk_stampa_dok_rn()

      ELSEIF ( cIdvd == "PR" )
         kalk_stampa_dok_pr()
      ENDIF

      /*
      IF !pdf_kalk_dokument( cIdVd )

         IF ( gPotpis == "D" )
            IF ( PRow() > 57 + dodatni_redovi_po_stranici() )
               FF
               @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )
            ENDIF
            ?
            ?
            P_12CPI
            @ PRow() + 1, 47 SAY "Obrada AOP  "; ?? Replicate( "_", 20 )
            @ PRow() + 1, 47 SAY "Komercijala "; ?? Replicate( "_", 20 )
            @ PRow() + 1, 47 SAY "Likvidatura "; ?? Replicate( "_", 20 )
         ENDIF
         ?
         ?
         FF
      ENDIF
      */

      PushWA()
      my_close_all_dbf()

      IF !pdf_kalk_dokument( cIdVd )
         ENDPRINT
      ENDIF

      // ------------------- kraj stampe jedne kalkulacije
      kalk_open_tables_unos( lAzuriraniDokument )
      PopWa()

      IF ( cIdvd $ "80#11#81#IP#19" )
         lDokumentZaPOS := .T.
      ENDIF

      IF ( cIdvd $ "10#11#81" )
         lDokumentZaFakt := .T.
      ENDIF

      IF lAzuriraniDokument // stampa azuriranog KALK dokumenta
         IF cNaljepniceDN == "D"
            kalk_roba_naljepnice_stampa( cIdFirma, cIdVd, cBrDok  )
         ENDIF
         cBrDok := kalk_fix_brdok_add_1( cBrDok )
         open_kalk_as_pripr( cIdFirma, cIdVd, cBrDok )

      ELSE // priprema
         IF cNaljepniceDN == "D"
            kalk_roba_naljepnice_stampa()
            o_kalk_edit()
            EXIT // podrazumjevamo da je u pripremi jedan dokument
         ENDIF
      ENDIF

   ENDDO  // vrti kroz kalkulacije

   IF ( lDokumentZaPOS .AND. !lAzuriraniDokument .AND. gTops != "0 " )
      IF !pdf_kalk_dokument( cIdVd )
         START PRINT CRET
      ENDIF
      SELECT kalk_pripr
      SET ORDER TO TAG "1"
      GO TOP
      cIdFirma := kalk_pripr->IdFirma
      cBrDok := kalk_pripr->BrDok
      cIdVD := kalk_pripr->IdVD
      IF ( cIdVd $ "11#12" )
         kalk_stampa_dok_11( .T. )  // maksuzija za tops - bez NC
      ELSEIF ( cIdVd == "80" )
         kalk_stampa_dok_80( .T. )
      ELSEIF ( cIdVd == "81" )
         kalk_stampa_dok_81_tops( .T. )
      ELSEIF ( cIdVd == "IP" )
         kalk_stampa_dok_ip( .T. )
      ELSEIF ( cIdVd $ "19#71#79" )
         kalk_stampa_dok_19_79()
      ENDIF
      my_close_all_dbf()
      IF !pdf_kalk_dokument( cIdVd )
         FF
         ENDPRINT
      ENDIF

      kalk_generisi_tops_dokumente()

   ENDIF

   IF ( lDokumentZaFakt .AND. !lAzuriraniDokument .AND. gFakt != "0 " )

      start PRINT cret
      o_kalk_edit()
      SELECT kalk_pripr
      SET ORDER TO TAG "1"
      GO TOP
      cIdFirma := kalk_pripr->IdFirma
      cBrDok := kalk_pripr->BrDok
      cIdVD := kalk_pripr->IdVD
      IF ( cIdVd $ "11#12" )
         kalk_stampa_dok_11( .T. )
      ELSEIF ( cIdVd == "10" )
         kalk_stampa_dok_10()
      ELSEIF ( cIdVd == "81" )
         kalk_stampa_dok_81( .T. )
      ENDIF
      my_close_all_dbf()
      FF
      ENDPRINT

   ENDIF

   my_close_all_dbf()

   RETURN NIL


FUNCTION picdem( cPic )

   IF cPic != NIL
      picdem := cPic
   ENDIF

   RETURN picdem

FUNCTION picnc()
   RETURN gPicNC


FUNCTION pickol( cPic )

   IF cPic != NIL
      pickol := cPic
   ENDIF

   RETURN pickol

FUNCTION piccdem( cPic )

   IF cPic != NIL
      piccdem := cPic
   ENDIF

   RETURN piccdem

FUNCTION picproc( cPic )

   IF cPic != NIL
      picproc := cPic
   ENDIF

   RETURN picproc

STATIC FUNCTION pdf_kalk_dokument( cIdVd )

   // IF is_legacy_ptxt()
   // RETURN .F.
   // ENDIF

   RETURN cIdVd $ "10#14#19#80#41#42#11#71#79#49#16#95#96"  // implementirano za ove dokumente
