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


FUNCTION fin_anal_kartica()

   LOCAL nCOpis := 0, cOpis := ""
   LOCAL bZagl := {|| zagl_anal_kartica() }
   LOCAL oPdf, xPrintOpt
   LOCAL lKarticaNovaStrana := .F., nTmp
   LOCAL GetList := {}

   cIdFirma := self_organizacija_id()
   qqKonto := ""
   cBrza := "D"
   cPTD := "N"
   IF fin_dvovalutno()
      M := "------- -------- ---- -------- ---------------- ----------------- ----------------- ------------- ------------- -------------"
   ELSE
      M := "------- -------- ---- -------- ---------------- ----------------- ------------------"
   ENDIF

   //o_partner()
   o_konto()

   dDatOd := dDAtDo := CToD( "" )
   cPredh := "2"

   o_params()
   PRIVATE cSection := "3", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c1", @cIdFirma ); RPar( "c2", @qqKonto ); RPar( "d1", @dDatOd ); RPar( "d2", @dDatDo )
   RPar( "c3", @cBrza )
   RPar( "c4", @cPredh )
   RPar( "c8", @cPTD )
   //IF gNW == "D";
   cIdFirma := self_organizacija_id()
   // ENDIF

   Box( "", 9, 65, .F. )
   DO WHILE .T.
      SET CURSOR ON
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "ANALITIČKA KARTICA"
      //IF gNW == "D"
         @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      //ELSE
      //   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| Empty( cIdFirma ) .OR. p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
      //ENDIF
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Brza kartica (D/N/S)" GET cBrza PICT "@!" VALID cBrza $ "DNS"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "BEZ/SA prethodnim prometom (1/2):" GET cPredh VALID cPredh $ "12"
      READ
      ESC_BCR

      IF cBrza == "D"
         qqKonto := PadR( qqKonto, 7 )
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Konto: " GET qqKonto VALID P_Konto( @qqKonto )
      ELSE
         qqKonto := PadR( qqKonto, 60 )
         @ box_x_koord() + 6, box_y_koord() + 2 SAY "Konto: " GET qqKonto PICTURE "@S50"
      ENDIF

    //  IF gNW == "N"
    //     @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikaz tipa dokumenta (D/N)" GET cPTD PICT "@!" VALID cPTD $ "DN"
    //  ENDIF

      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Datum od:" GET dDatOd
      @ box_x_koord() + 8, Col() + 2 SAY "do:" GET dDatDo
      cIdRJ := ""
      IF gFinRj == "D" .AND. gSAKrIz == "D"
         cIdRJ := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
         @ box_x_koord() + 9, box_y_koord() + 2 SAY "Radna jedinica (999999-sve): " GET cIdRj
      ENDIF
      READ
      ESC_BCR

      IF cBrza == "N" .OR. cBrza == "S"
         qqKonto := Trim( qqKonto )
         aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
         IF aUsl1 <> NIL
          exit
         ENDIF
      ELSE
         EXIT
      ENDIF
   ENDDO
   BoxC()

   IF cIdRj ==  REPLICATE("9", FIELD_LEN_FIN_RJ_ID ); cIdrj := ""; ENDIF

   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. "." $ cidrj
      cidrj := Trim( StrTran( cidrj, ".", "" ) )
      // odsjeci ako je tacka. prakticno "01. " -> sve koje pocinju sa  "01"
   ENDIF

   //IF Params2()
      WPar( "c1", PadR( cIdFirma, 2 ) ); WPar( "c2", @qqKonto ); WPar( "d1", @dDatOd ); WPar( "d2", @dDatdo )
      WPar( "c3", cBrza )
      WPar( "c4", cPredh )
      WPar( "c8", cPTD )
   //ENDIF
   SELECT params
   USE

   MsgO( "Preuzimanje podataka sa SQL servera ..." )


   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
      otvori_sint_anal_kroz_temp( .F., "IDRJ='" + cIdRJ + "'" )
   ELSE

      IF cBrza == "D"
         find_anal_by_konto( cIdFirma, qqKonto )

      ELSE
         find_anal_by_konto( cIdFirma )
      ENDIF

   ENDIF

   //o_konto()

   SELECT ANAL

   IF cBrza == "S"
      SET ORDER TO TAG "3"  // anal
   ENDIF

   cFilt1 := ".t." + iif( cBrza == "D", "", ".and." + aUsl1 ) + ;
      iif( Empty( dDatOd ) .OR. cPredh == "2", "", ".and.DATNAL>=" + dbf_quote( dDatOd ) ) + ;
      iif( Empty( dDatDo ), "", ".and.DATNAL<=" + dbf_quote( dDatDo ) )

   cFilt1 := StrTran( cFilt1, ".t..and.", "" )

   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF

   GO TOP
   MsgC()
   EOF CRET

   nStr := 0

   IF cBrza == "S"
      m := "------- " + m
   ENDIF

   IF !is_legacy_ptxt()
      oPDF := PDFClass():New()
      xPrintOpt := hb_Hash()
      xPrintOpt[ "tip" ] := "PDF"
      xPrintOpt[ "layout" ] := "portrait"
      xPrintOpt[ "font_size" ] := 7
      xPrintOpt[ "opdf" ] := oPDF
      xPrintOpt[ "left_space" ] := 0
   ENDIF

   IF !start_print( xPrintOpt )
      RETURN .F.
   ENDIF

   Eval( bZagl )

   nSviD := nSviP := nSviD2 := nSviP2 := 0
   DO WHILE !Eof() .AND. IdFirma = cIdFirma

      IF cBrza == "D"
         IF qqKonto <> IdKonto; exit; ENDIF
      ENDIF

      nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0
      cIdkonto := IdKonto


      check_nova_strana( bZagl, oPdf, .F., 5 )

      ? m
      select_o_konto( cIdKonto )
      SELECT anal
      IF cBrza == "S"
         ? "KONTA: ", qqKonto
      ELSE
         ? "KONTO:  ", cIdKonto, AllTrim( konto->naz )
      ENDIF
      ? m

      nDugBHD := nPotBHD := DugDEM := nPotDEM := 0
      fPProm := .T.
      DO WHILE !Eof() .AND. IdFirma = cIdFirma .AND. ( cIdKonto == IdKonto .OR. cBrza == "S" )
         // ********* prethodni promet *********************************
         IF cPredh == "2"
            IF dDatOd > datnal .AND. fPProm == .T.
               nDugBHD += DugBHD; nPotBHD += PotBHD
               nDugDEM += DugDEM; nPotDEM += PotDEM
               skip; LOOP
            ELSE
               IF fPProm
                  ? "Prethodno stanje"
                  @ PRow(), 31 SAY nDugBHD     PICTURE PicBHD
                  @ PRow(), PCol() + 2  SAY nPotBHD     PICTURE PicBHD
                  @ PRow(), PCol() + 2  SAY nDugBHD - nPotBHD PICTURE PicBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 2  SAY nDugDEM     PICTURE PicDEM
                     @ PRow(), PCol() + 2  SAY nPotDEM     PICTURE PicDEM
                     @ PRow(), PCol() + 2  SAY nDugDEM - nPotDEM PICTURE PicDEM
                  ENDIF
               ENDIF
               fPProm := .F.
            ENDIF
         ENDIF


         check_nova_strana( bZagl, oPdf )

         IF cBrza == "S"
            @ PRow() + 1, 3 SAY IdKonto
            @ PRow(), 11 SAY IdVN
            @ PRow(), 16 SAY BrNal
            @ PRow(), 25 SAY RBr
            @ PRow(), 31 SAY DatNal
         ELSE
            @ PRow() + 1, 3 SAY IdVN
            @ PRow(), 8 SAY BrNal
            @ PRow(), 17 SAY RBr
            @ PRow(), 22 SAY DatNal
         ENDIF

         @ PRow(), 31  + IF( cBrza == "S", 8, 0 ) SAY DugBHD PICTURE PicBHD
         @ PRow(), PCol() + 2 SAY PotBHD PICTURE picBHD
         nDugBHD += DugBHD; nPotBHD += PotBHD
         @ PRow(), PCol() + 2 SAY nDugBHD - nPotBHD PICTURE PicBHD
         IF fin_dvovalutno()
            @ PRow(), PCol() + 2 SAY DugDEM PICTURE PicDEM
            @ PRow(), PCol() + 2 SAY PotDEM PICTURE picDEM
            nDugDEM += DugDEM; nPotDEM += PotDEM
            @ PRow(), PCol() + 2 SAY nDugDEM - nPotDEM PICTURE PicDEM
         ENDIF
         fin_print_ostatak_opisa( cOpis, nCOpis, bZagl )
         SKIP
      ENDDO

      check_nova_strana( bZagl, oPdf, .F., 4 )

      ? M
      IF cBrza == "S"
         ? "UKUPNO ZA KONTA:" + qqKonto
      ELSE
         ? "UKUPNO ZA KONTO:" + cIdKonto
      ENDIF


      @ PRow(), 31 + iif( cBrza == "S", 8, 0 ) SAY nDugBHD  PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nPotBHD           PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nDugBHD - nPotBHD   PICTURE PicBHD

      IF fin_dvovalutno()
         @ PRow(), PCol() + 2  SAY nDugDEM           PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nPotDEM           PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nDugDEM - nPotDEM   PICTURE PicDEM
      ENDIF
      ? M

      nSviD += nDugBHD; nSviP += nPotBHD
      nSviD2 += nDugDEM; nSviP2 += nPotDEM


      IF lKarticaNovaStrana
         check_nova_strana( bZagl, oPDF, .T. )
      ELSE
         check_nova_strana( bZagl, oPDF, .F., 0, 3 )
      ENDIF


   ENDDO // eof()

   IF cBrza == "N"

      check_nova_strana( bZagl, oPdf, .F., 4 )
      ? M
      ? "UKUPNO ZA SVA KONTA:"
      @ PRow(), 31 SAY nSviD  PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nSviP             PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nSviD - nSviP       PICTURE PicBHD

      IF fin_dvovalutno()
         @ PRow(), PCol() + 2  SAY nSviD2            PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nSviP2            PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nSviD2 - nSviP2     PICTURE PicDEM
      ENDIF
      ? m
   ENDIF

   FF

   end_print( xPrintOpt )

   closeret

FUNCTION zagl_anal_kartica()

   P_COND
   ?U "FIN.P: ANALITIČKA KARTICA  NA DAN: "; ?? Date()
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ?? "   ZA PERIOD OD", dDatOd, "DO", dDatDo
   ENDIF

   IF is_legacy_ptxt()
      @ PRow(), 125 SAY "Str." + Str( ++nStr, 3 )
   ENDIF

   ?U "Firma:", self_organizacija_id(), "-", self_organizacija_naziv()

   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
      ? "Radna jedinica ='" + cIdRj + "'"
   ENDIF

   SELECT ANAL

   IF fin_dvovalutno()

      ?U iif( cBrza == "S", "------- ", "" ) + "------- -------- ---- --------" + " ---------------------------------------------------- -----------------------------------------"
      ?U iif( cBrza == "S", "*      *", "" ) + "*VRSTA * BROJ   *REDN* DATUM  " + "*             I Z N O S     U     " + valuta_domaca_skraceni_naziv() + "               *        I Z N O S     U     " + ValPomocna() + "        *"
      ?U iif( cBrza == "S", " KONTO  ", "" ) + "                              " + " ---------------------------------------------------- -----------------------------------------"
      ?U iif( cBrza == "S", "*      *", "" ) + "*NALOGA*NALOGA  *BROJ*        " + "*     DUGUJE     *   POTRAŽUJE     *       SALDO     *   DUGUJE   *  POTRAZUJE  *    SALDO    *"
   ELSE

      F12CPI

      ?U iif( cBrza == "S", "------- ", "" ) + "------- -------- ---- --------" + " -----------------------------------------------------"
      ?U iif( cBrza == "S", "*      *", "" ) + "*VRSTA * BROJ   *REDN* DATUM  " + "*             I Z N O S     U     " + valuta_domaca_skraceni_naziv() + "               *"
      ?U iif( cBrza == "S", " KONTO  ", "" ) + "                              " + " -----------------------------------------------------"
      ?U iif( cBrza == "S", "*      *", "" ) + "*NALOGA*NALOGA  *BROJ*        " + "*     DUGUJE     *   POTRAŽUJE     *       SALDO     *"
   ENDIF
   ? M

   RETURN .T.
