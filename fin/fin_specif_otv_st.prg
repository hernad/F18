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


FUNCTION fin_specif_otvorene_stavke()

   LOCAL nKolTot := 85
   PRIVATE bZagl := {|| ZaglSPK() }

   cIdFirma := self_organizacija_id()
   nRok := 0
   cIdKonto := Space( 7 )
   picBHD := FormPicL( "9 " + gPicBHD, 21 )
   picDEM := FormPicL( "9 " + pic_iznos_eur(), 21 )

   cIdRj := REPLICATE("9", FIELD_LEN_FIN_RJ_ID )
   cFunk := "99999"
   cFond := "999"

   qqBrDok := Space( 40 )

   // o_partner()
   M := "---- " + REPL( "-", FIELD_LEN_PARTNER_ID ) + " ------------------------------------- ----- ----------------- ---------- ---------------------- --------------------"
   o_konto()
   dDatOd := dDatDo := CToD( "" )

   cPrelomljeno := "D"
   Box( "Spec", 13, 75, .F. )

   DO WHILE .T.
      set_cursor_on()
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "SPECIFIKACIJA OTVORENIH STAVKI"
      IF gNW == "D"
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
      ELSE
         @ box_x_koord() + 3, box_y_koord() + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
      ENDIF
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto    " GET cIdKonto VALID p_konto( @cIDKonto ) PICT "@!"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "Od datuma" GET dDatOd
      @ box_x_koord() + 5, Col() + 2 SAY "do" GET dDatdo
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "Uslov za broj veze (prazno-svi) " GET qqBrDok PICT "@!S20"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Prikaz prebijenog stanja " GET cPrelomljeno VALID cPrelomljeno $ "DN" PICT "@!"

      fin_get_k1_k4_funk_fond( @GetList, 9, .F. )

      READ
      ESC_BCR
      aBV := Parsiraj( qqBrDok, "UPPER(BRDOK)", "C" )
      IF aBV <> NIL
         EXIT
      ENDIF
   ENDDO

   BoxC()

   B := 0

   IF cPrelomljeno == "N"
      m += " --------------------"
   ENDIF

   nStr := 0

   o_suban()

   CistiK1k4( .F. )



   cFilt1 := "OTVST==' '"

   IF !Empty( qqBrDok )
      cFilt1 += ( ".and." + aBV )
   ENDIF

   IF !Empty( dDatOd )
      cFilt1 += ".and. IIF( EMPTY(datval) , datdok>=" + dbf_quote( dDatOd ) + " , datval>=" + dbf_quote( dDatOd ) + " )"
   ENDIF

   IF !Empty( dDatDo )
      cFilt1 += ".and. IIF( EMPTY(datval) , datdok<=" + dbf_quote( dDatDo ) + " , datval<=" + dbf_quote( dDatDo ) + " )"
   ENDIF

   GO TOP

   IF gFinRj == "D" .AND. Len( cIdrj ) <> 0
      cFilt1 += ( ".and. idrj='" + cidrj + "'" )
   ENDIF

   IF gFinFunkFond == "D" .AND. Len( cFunk ) <> 0
      cFilt1 += ( ".and. Funk='" + cFunk + "'" )
   ENDIF

   IF gFinFunkFond == "D" .AND. Len( cFond ) <> 0
      cFilt1 += ( ".and. Fond='" + cFond + "'" )
   ENDIF

   // SELECT SUBAN
   // IdFirma+IdKonto+IdPartner+BrDok+dtos(DatDok)
   // SET ORDER TO TAG "3"
   // SEEK cidfirma + cidkonto
   find_suban_by_konto_partner( cIdFirma, cIdKonto )

   SET FILTER TO &cFilt1
   GO TOP
   EOF CRET

   START PRINT  CRET

   nDugBHD := nPotBHD := 0


   DO WHILE !Eof() .AND. cIDFirma == idfirma .AND. cIdKonto = IdKonto
      cIdPartner := IdPartner
      DO WHILE  !Eof() .AND. cIDFirma == idfirma .AND. cIdKonto = IdKonto .AND. cIdPartner = IdPartner


         IF PRow() == 0
            Eval( bZagl )
         ENDIF

         NovaStrana( bZagl )

         cBrDok := BrDok
         nIznD := 0; nIznP := 0
         DO WHILE  !Eof() .AND. cIdKonto = IdKonto .AND. cIdPartner = IdPartner .AND. cBrDok == BrDok
            IF D_P == "1"; nIznD += IznosBHD; else; nIznP += IznosBHD; ENDIF
            SKIP
         ENDDO
         @ PRow() + 1, 0 SAY ++B PICTURE '9999'
         @ PRow(), 5 SAY cIdPartner

         select_o_partner( cIdPartner )

         @ PRow(), PCol() + 1 SAY PadR( naz, 37 )
         @ PRow(), PCol() + 1 SAY PadR( PTT, 5 )
         @ PRow(), PCol() + 1 SAY PadR( Mjesto, 17 )

         SELECT SUBAN

         @ PRow(), PCol() + 1 SAY PadR( cBrDok, 10 )

         IF cPrelomljeno == "D"
            IF Round( nIznD - nIznP, 4 ) > 0
               nIznD := nIznD - nIznP
               nIznP := 0
            ELSE
               nIznP := nIznP - nIznD
               nIznD := 0
            ENDIF
         ENDIF

         nKolTot := PCol() + 1
         @ PRow(), nKolTot      SAY nIznD PICTURE picBHD

         @ PRow(), PCol() + 1 SAY nIznP PICTURE picBHD
         IF cPrelomljeno == "N"
            @ PRow(), PCol() + 1 SAY nIznD - nIznP PICTURE picBHD
         ENDIF
         nDugBHD += nIznD
         nPotBHD += nIznP


      ENDDO // partner
   ENDDO  // konto

   NovaStrana( bZagl )

   ? M
   ? "UKUPNO za KONTO:"
   @ PRow(), nKolTot  SAY nDugBHD PICTURE picBHD
   @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD

   IF cPrelomljeno == "N"
      @ PRow(), PCol() + 1 SAY nDugBHD - nPotBHD PICTURE picBHD
   ELSE

      ? " S A L D O :"
      IF nDugBhd - nPotBHD > 0
         nDugBHD := nDugBHD - nPotBHD
         nPotBHD := 0
      ELSE
         nPotBHD := nPotBHD - nDugBHD
         nDugBHD := 0
      ENDIF
      @ PRow(), nKolTot  SAY nDugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD

   ENDIF
   ? M

   nDugBHD := nPotBHD := 0

   FF
   end_print()

   my_close_all_dbf()

   RETURN .T.



/* ZaglSpK()
 *     Zaglavlje specifikacije
 */

FUNCTION ZaglSpK()

   LOCAL nDSP := 0

   ?
   P_COND
   ?? "FIN.P: SPECIFIKACIJA OTVORENIH STAVKI  ZA KONTO ", cIdKonto
   IF !( Empty( dDatOd ) .AND. Empty( dDatDo ) )
      ?? " ZA PERIOD ", dDatOd, "-", dDatDo
   ENDIF
   ?? "     NA DAN:", Date()
   IF !Empty( qqBrDok )
      ? "Izvjestaj pravljen po uslovu za broj veze/racuna: '" + Trim( qqBrDok ) + "'"
   ENDIF

   @ PRow(), 125 SAY "Str:" + Str( ++nStr, 3 )

   //IF gNW == "D"
      ? "Firma:", self_organizacija_id(), self_organizacija_naziv()
   //ELSE
  //    SELECT PARTN; HSEEK cIdFirma
  //    ? "Firma:", cidfirma, partn->naz, partn->naz2
   //ENDIF

   IF cPrelomljeno == "N"
      P_COND2
   ENDIF

   ?
   prikaz_k1_k4_rj( .F. )

   nDSP := FIELD_LEN_PARTNER_ID

   ? M
   ?U "*R. *" + PadC( "SIFRA", nDSP ) + "*       NAZIV POSLOVNOG PARTNERA      * PTT *      MJESTO     *  BROJ    *               IZNOS                      *" + iif( cPrelomljeno == "N", "                    *", "" )
   ?U "     " + Space( nDSP ) + "                                                                          ---------------------- --------------------" + iif( cPrelomljeno == "N", " --------------------", "" )
   ?U "*BR.*" + Space( nDSP ) + "*                                     * BROJ*                 *  VEZE    *         DUGUJE       *      POTRAZUJE    *" + iif( cPrelomljeno == "N", "       SALDO        *", "" )
   ? M
   SELECT SUBAN

   RETURN .T.
