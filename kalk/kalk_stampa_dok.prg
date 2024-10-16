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

MEMVAR cIdfirma, cIdvd, cBrdok
MEMVAR gFakt
MEMVAR __print_opt
MEMVAR  PicCDEM, PicProc, PicDEM, PicKol, gPicPROC, gPicNC

MEMVAR nStr

FUNCTION kalk_stampa_svih_dokumenata_u_pripremi()
   RETURN kalk_stampa_dokumenta( .F., .T. )

FUNCTION kalk_stampa_dokumenta_priprema( lBezPitanjaDok )
   RETURN kalk_stampa_dokumenta( .F., lBezPitanjaDok )

FUNCTION kalk_stampa_azuriranog_dokumenta_by_hparams( hParams )
   RETURN kalk_stampa_dokumenta( .T., .T., hParams )

FUNCTION kalk_stampa_azuriranog_dokumenta()
   RETURN kalk_stampa_dokumenta( .T., .F. )

FUNCTION kalk_stampa_dokumenta( lAzuriraniDokument, lBezPitanjaBrDok, hParams )

   LOCAL cOk
   LOCAL cNaljepniceDN := "N"
   LOCAL GetList := {}
   LOCAL lDokumentZaPOS, lDokumentZaFakt
   LOCAL lCloseAllNaKraju := .T., lStampaJedanDokument := .F.
   LOCAL hGrupnaStampa := NIL
   
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
      IF hParams <> NIL
         cIdFirma := hParams[ "idfirma" ]
         cIdVd := hParams[ "idvd" ]
         cBrDok := hParams[ "brdok" ]
         lCloseAllNaKraju := .F.
         lStampaJedanDokument := .T.
         IF hb_hhaskey( hParams, "vise_dokumenata")
            hGrupnaStampa := hb_hash()
            hGrupnaStampa[ "vise_dokumenata" ] := hParams[ "vise_dokumenata" ]
            hGrupnaStampa[ "prvi_dokument" ] := hParams[ "prvi_dokument" ]
            hGrupnaStampa[ "posljednji_dokument" ] := hParams[ "posljednji_dokument" ]
         ENDIF
      ENDIF
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
         set_cursor_on()
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
      // IF !Empty( cOk := kalkulacija_ima_sve_cijene( cIdFirma, cIdVd, cBrDok ) ) // provjeri da li kalkulacija ima sve cijene ?
      // MsgBeep( "Unutar kalkulacije nedostaju pojedine cijene bitne za obračun!##Stavke: " + cOk )
      // ENDIF

      EOF CRET
      IF !pdf_kalk_dokument( cIdVd )
         START PRINT CRET
         ?
         Preduzece()
      ENDIF

      IF cIdVD == "10"
         kalk_stampa_dok_10( hGrupnaStampa )

      ELSEIF ( cIdvd $ "11#12#13#21#22" )
         kalk_stampa_dok_11( hGrupnaStampa )

      ELSEIF ( cIdvd $ "14#KO" )
         kalk_stampa_dok_14( hGrupnaStampa )

      ELSEIF ( cIdvd $ "16#95#96" )
         kalk_stampa_dok_16_95_96( hGrupnaStampa )

      ELSEIF ( cIdvd $ "41#42#49" )
         IF hGrupnaStampa == NIL  // ovi dokumenti se moraju stampati pojedinicno
         kalk_stampa_dok_41_42_49()
         ENDIF

      ELSEIF ( cIdvd == "18" )
         IF hGrupnaStampa == NIL
            kalk_stampa_dok_18()
         ENDIF

      ELSEIF ( cIdvd $ "19#29#71#79#72" )
         IF hGrupnaStampa == NIL
           kalk_stampa_dok_19_79()
         ENDIF

      ELSEIF ( cIdvd $ "01#02#03#80#61" )
         IF hGrupnaStampa == NIL  
            kalk_stampa_dok_01_03_80()
         ENDIF

      ELSEIF ( cIdvd $ "81#89" )
         IF hGrupnaStampa == NIL
           kalk_stampa_dok_81()
         ENDIF

      ELSEIF ( cIdvd == "IM" )
         IF hGrupnaStampa == NIL 
            kalk_stampa_dok_im()
         ENDIF

      ELSEIF ( cIdvd $ "IP#90" )
         IF hGrupnaStampa == NIL
            kalk_stampa_dok_ip()
         ENDIF

      ELSEIF ( cIdvd == "RN" )
         IF hGrupnaStampa == NIL
           IF !lAzuriraniDokument
              kalk_raspored_troskova( .T. )
           ENDIF
           kalk_stampa_dok_rn()
         ENDIF

      ELSEIF ( cIdvd == "PR" )
         IF hGrupnaStampa == NIL
            kalk_stampa_dok_pr()
         ENDIF
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

      IF lCloseAllNaKraju
         my_close_all_dbf()
      ENDIF

      IF !pdf_kalk_dokument( cIdVd )
         ENDPRINT
      ENDIF

      // ------------------- kraj stampe jedne kalkulacije
      kalk_open_tables_unos( lAzuriraniDokument )
      PopWa()

      IF ( cIdvd $ "80#11#81#IP#19" )
         lDokumentZaPOS := .T.
      ENDIF

      IF ( cIdVd $ "10#11#81" )
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

      IF lStampaJedanDokument
         EXIT
      ENDIF

   ENDDO  // vrti kroz kalkulacije


   IF ( lDokumentZaFakt .AND. !lAzuriraniDokument .AND. gFakt != "0 " )

      start PRINT cret
      o_kalk_edit()
      SELECT kalk_pripr
      SET ORDER TO TAG "1"
      GO TOP
      cIdFirma := kalk_pripr->IdFirma
      cBrDok := kalk_pripr->BrDok
      cIdVD := kalk_pripr->IdVD
      // IF ( cIdVd $ "11#12" )
      // kalk_stampa_dok_11( .T. )
      // ELSEIF ( cIdVd == "10" )
      // kalk_stampa_dok_10()
      // ELSEIF ( cIdVd == "81" )
      // kalk_stampa_dok_81( .T. )
      // ENDIF
      IF lCloseAllNaKraju
         my_close_all_dbf()
      ENDIF
      FF
      ENDPRINT

   ENDIF

   IF lCloseAllNaKraju
      my_close_all_dbf()
   ENDIF

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

   RETURN cIdVd $ "10#14#19#01#80#41#42#11#71#79#49#16#95#96#IM#21#22#72#02#03#81#89#61#90#IP#29"
