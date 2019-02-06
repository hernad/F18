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

MEMVAR m

FUNCTION fin_sint_kart_po_mjesecima()

   cIdFirma := self_organizacija_id()
   qqKonto := ""
   dDatOd := dDAtDo := CToD( "" )

   IF fin_dvovalutno()
      M := "------------- ---------------- ----------------- ----------------- ------------- ------------- -------------"
   ELSE
      M := "------------- ---------------- ----------------- ------------------"
   ENDIF

   // o_partner()

   o_params()
   PRIVATE cSection := "2", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c1", @cIdFirma ); RPar( "c2", @qqKonto ); RPar( "d1", @dDatOd ); RPar( "d2", @dDatDo )
   cIdFirma := self_organizacija_id()
   qqKonto := PadR( qqKonto, 100 )

   Box( "", 5, 75 )
   DO WHILE .T.
      SET CURSOR ON
      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "KARTICA (SINTETIČKI KONTO) PO MJESECIMA"


      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()

      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto: " GET qqKonto PICTURE "@S50"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Datum od:" GET dDatOd
      @ box_x_koord() + 4, Col() + 2 SAY "do:" GET dDatDo
      cIdRJ := ""
      IF gFinRj == "D" .AND. gSAKrIz == "D"
         cIdRJ := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
         @ box_x_koord() + 5, box_y_koord() + 2 SAY "Radna jedinica (999999-sve): " GET cIdRj
      ENDIF
      READ;  ESC_BCR

      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   IF cIdRj == REPLICATE("9", FIELD_LEN_FIN_RJ_ID ); cIdrj := ""; ENDIF
   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. "." $ cidrj
      cidrj := Trim( StrTran( cidrj, ".", "" ) )
      // odsjeci ako je tacka. prakticno "01. " -> sve koje pocinju sa  "01"
   ENDIF

   cIdFirma := Left( cIdFirma, 2 )
   qqKonto := Trim( qqKonto )

   //IF Params2()
      WPar( "c1", @cIdFirma ); WPar( "c2", @qqKonto ); WPar( "d1", @dDatOd ); WPar( "d2", @dDatDo )
   //ENDIF
   SELECT params
   USE


   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
      otvori_sint_anal_kroz_temp( .T., "IDRJ='" + cIdRJ + "'" )
   ELSE
      o_sint()
   ENDIF
   o_konto()

   SELECT SINT

   cFilt1 := aUsl1


   find_sint_by_konto_za_period( cIdFirma, NIL, dDatOd, dDatDo )

   IF !( cFilt1 == ".t." )
      SET FILTER TO &cFilt1
   ENDIF

   EOF RET

   nStr := 0

   IF !start_print()
      RETURN .F.
   ENDIF

   IF nStr == 0; ZaglSink2(); ENDIF
   nSviD := nSviP := nSviD2 := nSviP2 := 0

   DO WHILE idfirma == cidfirma .AND. !Eof()
      cIdkonto := IdKonto
      nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0

      IF PRow() > 55 + dodatni_redovi_po_stranici(); FF; ZaglSink2(); ENDIF

      ? m
      select_o_konto(  cIdKonto )
      ? "KONTO   "; @ PRow(), PCol() + 1 SAY cIdKonto
      @ PRow(), PCol() + 2 SAY konto->naz
      SELECT SINT

      ? m

      nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0
      DO WHILE !Eof() .AND. idfirma == cidfirma .AND. cIdKonto == IdKonto
         IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglSink2();ENDIF
         nMonth := Month( DatNal )
         nDBHD := nPBHD := nDDEM := nPDEM := 0
         nPSDBHD := nPSPBHD := nPSDDEM := nPSPDEM := 0
         DO WHILE !Eof() .AND. idfirma == cidfirma .AND. cIdKonto == IdKonto .AND. Month( datnal ) == nMonth
            IF idvn == "00"
               nPSDBhd += DugBHD; nPSPBHD += PotBHD
               nPSDDEM += DugDEM; nPSPDEM += PotDEM
            ELSE
               nDBhd += DugBHD; nPBHD += PotBHD
               nDDEM += DugDEM; nPDEM += PotDEM
            ENDIF
            SKIP
         ENDDO
         IF Round( nPSDBHD, 4 ) <> 0 .OR. Round( nPSPBHD, 4 ) <> 0 // pocetno stanje
            @ PRow() + 1, 3 SAY " PS"
            nC1 := PCol() + 8
            @ PRow(), PCol() + 8 SAY nPSDBHD PICTURE PicBHD
            @ PRow(), PCol() + 2 SAY nPSPBHD PICTURE picBHD
            nDugBHD += nPSDBHD; nPotBHD += nPSPBHD
            nDugDEM += nPSDDEM; nPotDEM += nPSPDEM
            @ PRow(), PCol() + 2 SAY nDugBHD - nPotBHD PICTURE PicBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 2 SAY nPSDDEM PICTURE PicDEM
               @ PRow(), PCol() + 2 SAY nPSPDEM PICTURE picDEM
               @ PRow(), PCol() + 2 SAY nDugDEM - nPotDEM PICTURE PicDEM
            ENDIF
         ENDIF
         @ PRow() + 1, 3 SAY Str( nMonth, 3 )
         nC1 := PCol() + 8
         @ PRow(), PCol() + 8 SAY nDBHD PICTURE PicBHD
         @ PRow(), PCol() + 2 SAY nPBHD PICTURE picBHD
         nDugBHD += nDBHD; nPotBHD += nPBHD
         nDugDEM += nDDEM; nPotDEM += nPDEM
         @ PRow(), PCol() + 2 SAY nDugBHD - nPotBHD PICTURE PicBHD
         IF fin_dvovalutno()
            @ PRow(), PCol() + 2 SAY nDDEM PICTURE PicDEM
            @ PRow(), PCol() + 2 SAY nPDEM PICTURE picDEM
            @ PRow(), PCol() + 2 SAY nDugDEM - nPotDEM PICTURE PicDEM
         ENDIF
      ENDDO

      IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglSink2(); ENDIF
      ? M
      ? "UKUPNO ZA:" + cIdKonto
      @ PRow(), nC1            SAY nDugBHD     PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nPotBHD     PICTURE PicBHD
      @ PRow(), PCol() + 2  SAY nDugBHD - nPotBHD PICTURE PicBHD
      IF fin_dvovalutno()
         @ PRow(), PCol() + 2  SAY nDugDEM     PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nPotDEM     PICTURE PicDEM
         @ PRow(), PCol() + 2  SAY nDugDEM - nPotDEM PICTURE PicDEM
      ENDIF
      ? M

      nSviD += nDugBHD; nSviP += nPotBHD
      nSviD2 += nDugDEM; nSviP2 += nPotDEM

      check_nova_strana( {|| ZaglSink2() } )


   ENDDO // eof()

   IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglSink2(); ENDIF
   ? M
   ? "ZA SVA KONTA:"
   @ PRow(), nC1            SAY nSviD           PICTURE PicBHD
   @ PRow(), PCol() + 2  SAY nSviP           PICTURE PicBHD
   @ PRow(), PCol() + 2  SAY nSviD - nSviP     PICTURE PicBHD
   IF fin_dvovalutno()
      @ PRow(), PCol() + 2  SAY nSviD2          PICTURE PicDEM
      @ PRow(), PCol() + 2  SAY nSviP2          PICTURE PicDEM
      @ PRow(), PCol() + 2  SAY nSviD2 - nSviP2   PICTURE PicDEM
   ENDIF
   ? M

   FF
   end_print()

   my_close_all_dbf()

   RETURN



/* ZaglSinK2()
 *     Zaglavlje sinteticke kartice varijante 2
 */

FUNCTION ZaglSink2()

   ?
   P_COND
   ?? "FIN.P: SINTETICKA KARTICA  PO MJESECIMA NA DAN: "; ?? Date()
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ?? "   ZA PERIOD OD", dDatOd, "DO", dDatDo
   ENDIF
   @ PRow(), 125 SAY "Str." + Str( ++nStr, 3 )


   ? "Firma:", self_organizacija_id(), "-", self_organizacija_naziv()

   IF gFinRj == "D" .AND. gSAKrIz == "D" .AND. Len( cIdRJ ) <> 0
      ? "Radna jedinica ='" + cIdRj + "'"
   ENDIF

   SELECT SINT

   IF fin_jednovalutno(); F10CPI; ENDIF
   ?  m
   IF fin_dvovalutno()
      ?  "*  MJESEC    *             I Z N O S     U     " + valuta_domaca_skraceni_naziv() + "               *       I Z N O S     U     " + ValPomocna() + "         *"
      ?  "              ---------------------------------------------------- -----------------------------------------"
      ?U  "*            *    DUGUJE      *     POTRAŽUJE   *      SALDO      *   DUGUJE    *  POTRA@UJE  *    SALDO   *"
   ELSE
      ?  "*  MJESEC    *             I Z N O S     U     " + valuta_domaca_skraceni_naziv() + "               *"
      ?  "              -----------------------------------------------------"
      ?U  "*            *    DUGUJE      *     POTRAŽUJE   *      SALDO      *"
   ENDIF
   ?  m

   RETURN .T.
