/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1994-2024 by bring.out d.o.o Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including knowhow ERP specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"


// -----------------------------------------------------------------------------
// Blagajna dnevni izvjestaj
// -----------------------------------------------------------------------------
FUNCTION fin_blagajna_dnevni_izvjestaj()

   LOCAL nRbr, nCOpis := 0, cOpis := ""
   LOCAL _idvn
   LOCAL _rec
   LOCAL _nCol1

   lSumiraj := .F.

   //o_konto()
   o_anal()
   o_fin_pripr()

   GO TOP

   _idvn := field->idvn

   cIdfirma := idfirma
   cBrdok := brnal

   IF DABLAGAS

      cKontoBlag := PadR( my_get_from_ini( "BLAGAJNA", "Konto", "202000", my_home() ), 7 )

      SET ORDER TO TAG "2"
      SEEK cidfirma + _idvn + cBrDok + cKontoBlag
      IF !Found() .OR. Pitanje(, "Postoji knjizenje na kontu blagajne! Regenerisati knjizenje? (D/N)", "N" ) == "D"
         IF Found()
            DO WHILE !Eof() .AND. cidfirma + _idvn + cBrDok + cKontoBlag == idFirma + IdVN + BrNal + IdKonto
               SKIP 1; nRec := RecNo(); SKIP -1
               MY_DELETE
               GO ( nRec )
            ENDDO
         ENDIF

         SET ORDER TO TAG "1"
         GO TOP
         lEOF := .F.
         DO WHILE !Eof() .AND. !lEOF .AND. cIdfirma + _idvn + cBrDok == idFirma + IdVN + BrNal
            SKIP 1
            lEOF := Eof()
            nRec := RecNo()
            SKIP -1

            _rec := dbf_get_rec()
            APPEND BLANK

            // promijeni konto i predznak, te nuliraj partnera, rj, funk i fond
            _rec[ "idkonto" ]    := cKontoBlag
            _rec[ "id_partner" ] := Space( Len( _rec[ "idpartner" ] ) )
            _rec[ "d_p" ]        := iif( _rec[ "d_p" ] == "1", "2", "1" )

            IF ( gFinRj == "D" )
               _rec[ "idrj" ] := Space( Len( _rec[ "idrj" ] ) )
            ENDIF

            IF gFinFunkFond == "D"
            //   _rec[ "funk" ] := Space( Len( _rec[ "funk" ] ) )
            //   _rec[ "fond" ] := Space( Len( _rec[ "fond" ] ) )
            ENDIF

            dbf_update_rec( _rec, .T. )
            GO ( nRec )

         ENDDO
      ENDIF
      SET ORDER TO TAG "1"
      GO TOP
   ENDIF

   cDinDem := "1"

   Box(, 3, 60 )

   @ box_x_koord() + 1, box_y_koord() + 2 SAY valuta_domaca_skraceni_naziv() + "/" + ValPomocna() + " blagajnicki izvjestaj (1/2):" GET cDinDem

   READ

   IF cDinDem == "1"
      cIdKonto := fetch_metric( "fin_blagajna_def_konto_km", NIL, PadR( "2050", 7 ) )
      pici := FormPicL( "9," + gPicBHD, 12 )
   ELSE
      cIdKonto := fetch_metric( "fin_blagajna_def_konto_dem", NIL, PadR( "2020", 7 ) )
   ENDIF

   IF DABLAGAS
      cIdKonto := cKontoBlag
   ENDIF

   dDatdok := datdok

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Datum:" GET dDatDok
   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Konto blagajne:" GET cIdKonto PICT "@S7" VALID P_Konto( @cIdKonto )

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   // snimi parametre
   IF cDinDem == "1"
      set_metric( "fin_blagajna_def_konto_km", NIL, cIdKonto )
   ELSE
      set_metric( "fin_blagajna_def_konto_dem", NIL, cIdKonto )
   ENDIF

   SELECT fin_pripr

   IF !start_print()
      RETURN .F.
   ENDIF
   ?
   F12CPI
   ?? Space( 12 )

   IF cDinDem == "1"
      ?? "(" + valuta_domaca_skraceni_naziv() + ")"
   ELSE
      ?? "DEVIZNI (" + ValPomocna() + ")"
   ENDIF

   ?? hb_UTF8ToStr( " BLAGAJNIČKI IZVJESTAJ OD " ), dDatDok
   ?? Space( 8 ), "Broj:", cBrDok
   ?
   ?

   nRbr := 0
   nDug := nPot := 0
   nCol1 := 45

   ? "    ------- ------------------------- --------------------- -------------- ---------------"
   ? "    * Redni*       Temeljnica        *        OPIS         *    ULAZ      *    IZLAZ     *"
   ? "    * broj *                         *                     *              *              *"
   ? "    *      *            *            *                     *              *              *"
   ? m := "    ------- ------------ ------------ --------------------- -------------- ---------------"
   DO WHILE !Eof()
      IF PRow() > 49 + dodatni_redovi_po_stranici()
         PZagBlag( nDug, nPot, m, cBrDok, pici, cDinDem, dDatDok )
      ENDIF

      IF lSumiraj
         nPomD := nPomP := 0
         cBrDok2 := brdok
         cOpis := ""
         nStavki := 0
         DO WHILE !Eof() .AND. brdok == cBrDok2
            IF idkonto <> cidkonto
               SKIP 1
               LOOP
            ELSE
               IF nPomD <> 0 .AND. d_p == "2" .OR. nPomP <> 0 .AND. d_p == "1"
                  // ovo se moze desiti ako su iste temeljnice za naplatu i isplatu
                  EXIT
               ENDIF
            ENDIF
            IF cDinDem == "1"

               IF d_p == "1"
                  nPomD += iznosbhd
               ELSE
                  nPomP += iznosbhd
               ENDIF

            ELSE

               IF d_p == "1"
                  nPomD += iznosdem
               ELSE
                  nPomP += iznosdem
               ENDIF

            ENDIF
            IF !Empty( opis )
               cOpis += opis
               ++nStavki
            ENDIF
            SKIP 1
         ENDDO
         IF PRow() > 49 + dodatni_redovi_po_stranici() - nStavki
            PZagBlag( nDug, nPot, m, cBrDok, pici, cDinDem, dDatDok )
         ENDIF
         ? "    *", Str( ++nRbr, 3 ) + ". *"
         IF nPomD <> 0
            ?? " " + cbrdok2 + " *" + Space( 12 ) + "*"
         ELSE
            ?? Space( 12 ) + "* " + PadR( cbrdok2, 11 ) + "*"
         ENDIF

         nCOpis := PCol() + 1
         ?? " " + PadR( cOpis, 20 )
         nCol1 := PCol() + 1

         @ PRow(), PCol() + 1 SAY PadL( Transform( nPomD, pici ), 14 )
         @ PRow(), PCol() + 1 SAY PadL( Transform( nPomP, pici ), 14 )
         nDug += nPomD
         nPot += nPomP
         fin_print_ostatak_opisa( cOpis, nCOpis )

      ELSE

         IF field->idkonto <> cIdKonto
            SKIP
            LOOP
         ENDIF

         ? "    *", Str( ++nRbr, 3 ) + ". *"
         IF d_p == "1"
            ?? " " + brdok + " *" + Space( 12 ) + "*"
         ELSE
            ?? Space( 12 ) + "* " + PadR( brdok, 11 ) + "*"
         ENDIF

         nCOpis := PCol() + 1
         ?? " " + PadR( cOpis := AllTrim( opis ), 20 )
         nCol1 := PCol() + 1

         IF cdindem == "1"

            IF d_p == "1"
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosbhd, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               nDug += iznosbhd
            ELSE
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosbhd, pici ), 14 )
               nPot += iznosbhd
            ENDIF

         ELSE

            IF d_p == "1"
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosdem, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               nDug += iznosdem
            ELSE
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosdem, pici ), 14 )
               nPot += iznosdem
            ENDIF

         ENDIF
         fin_print_ostatak_opisa( cOpis, nCOpis )
         SKIP 1
      ENDIF
   ENDDO
   SELECT anal


   find_anal_by_konto( cIdFirma, cIdkonto )

   nDugSt := nPotSt := 0
   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. idkonto == cIdkonto .AND. datnal <= dDatDok

      IF cDindem == "1"
         nDugSt += dugbhd
         nPotSt += potbhd
      ELSE
         nDugSt += dugdem
         nPotSt += potdem
      ENDIF

      SKIP
   ENDDO
   ? m
   @ PRow() + 1, 10 SAY "Promet blagajne:"
   @ PRow(), ncol1 SAY PadL( Transform( ndug, pici ), 14 )
   @ PRow(), PCol() + 1 SAY PadL( Transform( npot, pici ), 14 )
   ? m
   @ PRow() + 1, 10 SAY "Saldo od " + DToC( ddatdok - 1 ) + ":"
   @ PRow(), ncol1 SAY PadL( Transform( ndugst - npotst, pici ), 14 )
   ? m
   @ PRow() + 1, 10 SAY "Ukupan primitak:"
   @ PRow(), ncol1 SAY PadL( Transform( ndugst - npotst + ndug, pici ), 14 )

   @ PRow() + 1, 10 SAY "Izdatak:"
   @ PRow(), ncol1 SAY PadL( Transform( npot, pici ), 14 )

   ? m
   @ PRow() + 1, 10 SAY "Saldo na dan:"
   @ PRow(), ncol1 SAY PadL( Transform( ndugst - npotst + ndug - npot, pici ), 14 )
   ? m
   @ PRow() + 1, 10 SAY "Slovima:"
   @ PRow(), PCol() + 1 SAY Slovima( Round( ndugst - npotst + ndug - npot, 2 ), iif( cdindem == "1", valuta_domaca_skraceni_naziv(), ValPomocna() ) )
   ? m
   ?
   ?
   @ PRow() + 1, 25 SAY "  ___________________            ______________________"
   @ PRow() + 1, 25 SAY "     Blagajna                           Kontrola       "
   FF
   end_print()
   closeret


FUNCTION PZagBlag( nDug, nPot, m, cBrDok, pici, cDinDem, dDatDok )

   // zavrsetak prethodne stranice:
   // -----------------------------
   ? m
   @ PRow() + 1, 10 SAY "Promet blagajne, prenos:"
   @ PRow(), ncol1 SAY PadL( Transform( ndug, pici ), 14 )
   @ PRow(), PCol() + 1 SAY PadL( Transform( npot, pici ), 14 )
   ? m
   FF
   // sljedeca stranica:
   // ------------------
   F12CPI
   ?? Space( 12 )
   IF cDinDem == "1"
      ?? "(" + valuta_domaca_skraceni_naziv() + ")"
   ELSE
      ?? "DEVIZNI (" + ValPomocna() + ")"
   ENDIF
   ?? " BLAGAJNICKI IZVJESTAJ OD ", dDatDok
   ?? Space( 8 ), "Broj:", cBrDok
   ?
   ?
   ? "    ------- ------------------------- --------------------- -------------- ---------------"
   ? "    * Redni*       Temeljnica        *        OPIS         *    ULAZ      *    IZLAZ     *"
   ? "    * broj *                         *                     *              *              *"
   ? "    *      *            *            *                     *              *              *"
   ? m
   @ PRow() + 1, 10 SAY "Promet blagajne, donos:"
   @ PRow(), ncol1 SAY PadL( Transform( ndug, pici ), 14 )
   @ PRow(), PCol() + 1 SAY PadL( Transform( npot, pici ), 14 )
   ? m

   RETURN .T.




// stampa blagajne na osnovu azuriranog dokumenta
FUNCTION blag_azur()

   LOCAL nCol1
   LOCAL nRbr := 0
   LOCAL nCOpis := 0
   LOCAL cOpis := ""
   LOCAL lSumiraj
   PRIVATE pici := FormPicL( "9," + pic_iznos_eur(), 12 )
   PRIVATE cLine := ""

   // lSumiraj := ( my_get_from_ini("BLAGAJNA","DBISumirajPoBrojuVeze","N",my_home())=="D" )
   lSumiraj := .F.

   //o_partner()
   o_konto()
   o_anal()
   o_suban()

   cDinDem := "1"

   Box(, 4, 60 )
   @ box_x_koord() + 1, box_y_koord() + 2 SAY valuta_domaca_skraceni_naziv() + "/" + ValPomocna() + " blagajnicki izvjestaj (1/2):" GET cDinDem
   READ
   IF cDinDem == "1"
      cIdKonto := PadR( "2020", 7 )
      pici := FormPicL( "9," + gPicBHD, 12 )
   ELSE
      cIdKonto := PadR( "2050", 7 )
   ENDIF

   dDatdok := datdok
   cIdFirma := self_organizacija_id()
   cTipDok := Space( 2 )
   cBrDok := Space( 8 )

   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Dokument:" GET cIdFirma VALID !Empty( cIdFirma )
   @ box_x_koord() + 2, box_y_koord() + 15 SAY "-" GET cTipDok VALID !Empty( cTipDok )
   @ box_x_koord() + 2, box_y_koord() + 20 SAY "-" GET cBrDok VALID !Empty( cBrDok )

   READ

   // precesljaj dokument radi konta i datuma, pa ponudi
   dat_kto_blag( @dDatDok, @cIdKonto, cIdFirma, cTipDok, cBrDok )

   @ box_x_koord() + 3, box_y_koord() + 2 SAY "Datum:" GET dDatDok
   @ box_x_koord() + 4, box_y_koord() + 2 SAY "Konto blagajne:" GET cIdKonto VALID P_Konto( @cIdKonto )
   READ
   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF


   find_suban_by_broj_dokumenta( cIdFirma, cTipDok, cBrDok )

   IF Eof()
      MsgBeep( "Dokument " + cIdFirma + "-" + cTipDok + "-" + cBrDok + " ne postoji!" )
      RETURN .F.
   ENDIF

   IF !start_print()
      RETURN .F.
   ENDIF


   nRbr := 0
   nDug := 0
   nPot := 0
   nCol1 := 20

   // setuj liniju reporta
   set_line( @cLine )

   // stampaj zaglavlje reporta
   st_bl_zagl( cLine, cDinDem, cIdFirma, cTipDok, cBrDok, dDatDok )

   DO WHILE !Eof() .AND. field->idfirma == cIdFirma .AND. field->idvn == cTipDok .AND. field->brnal == cBrDok

      IF PRow() > 49 + dodatni_redovi_po_stranici()
         PZagBlag( nDug, nPot, cLine, cBrDok, pici, cDinDem, dDatDok )
      ENDIF
      IF lSumiraj
         nPomD := nPomP := 0
         cBrDok2 := brdok
         cOpis := ""
         nStavki := 0
         DO WHILE !Eof() .AND. brdok == cBrDok2
            IF idkonto <> cIdKonto
               SKIP 1
               LOOP
            ELSE
               IF nPomD <> 0 .AND. d_p == "2" .OR. nPomP <> 0 .AND. d_p == "1"
                  // ovo se moze desiti ako su iste
                  // temeljnice za naplatu i isplatu
                  EXIT
               ENDIF
            ENDIF
            IF cDinDem == "1"  // dinari !!!!
               IF d_p == "1"
                  nPomD += iznosbhd
               ELSE
                  nPomP += iznosbhd
               ENDIF
            ELSE
               IF d_p == "1"
                  nPomD += iznosdem
               ELSE
                  nPomP += iznosdem
               ENDIF
            ENDIF
            IF !Empty( opis )
               cOpis += opis
               ++nStavki
            ENDIF
            SKIP 1
         ENDDO
         IF PRow() > 49 + dodatni_redovi_po_stranici() - nStavki
            PZagBlag( nDug, nPot, m, cBrDok, pici, cDinDem, dDatDok )
         ENDIF

         ? "    *", Str( ++nRbr, 3 ) + ". *"

         IF nPomD <> 0
            ?? " " + cBrDok2 + " *" + Space( 12 ) + "*"
         ELSE
            ?? Space( 12 ) + "* " + PadR( cBrDok2, 11 ) + "*"
         ENDIF

         nCOpis := PCol() + 1
         ?? " " + PadR( cOpis, 20 )
         nCol1 := PCol() + 1
         @ PRow(), PCol() + 1 SAY PadL( Transform( nPomD, pici ), 14 )
         @ PRow(), PCol() + 1 SAY PadL( Transform( nPomP, pici ), 14 )
         nDug += nPomD
         nPot += nPomP
         fin_print_ostatak_opisa( cOpis, nCOpis )
      ELSE

         // lSumiraj := .f.

         IF idkonto <> cIdkonto
            SKIP
            LOOP
         ENDIF
         ? "    *", Str( ++nRbr, 3 ) + ". *"
         IF d_p == "1"
            ?? " " + brdok + " *" + Space( 12 ) + "*"
         ELSE
            ?? Space( 12 ) + "* " + PadR( brdok, 11 ) + "*"
         ENDIF
         nCOpis := PCol() + 1
         ?? " " + PadR( cOpis := AllTrim( opis ), 20 )
         nCol1 := PCol() + 1
         IF cDinDem == "1"  // dinari !!!!
            IF d_p == "1"
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosbhd, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               nDug += iznosbhd
            ELSE
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosbhd, pici ), 14 )
               nPot += iznosbhd
            ENDIF
         ELSE
            IF d_p == "1"
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosdem, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               nDug += iznosdem
            ELSE
               @ PRow(), PCol() + 1 SAY PadL( Transform( 0, pici ), 14 )
               @ PRow(), PCol() + 1 SAY PadL( Transform( iznosdem, pici ), 14 )
               nPot += iznosdem
            ENDIF
         ENDIF
         fin_print_ostatak_opisa( cOpis, nCOpis )
         SKIP 1
      ENDIF
   ENDDO

   // procesljaj staro stanje
   find_anal_by_konto( cIdFirma, cIdKonto )

   nDugSt := 0
   nPotSt := 0

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. idkonto == cIdkonto .AND. datnal < dDatDok
      IF cDinDem == "1"
         nDugSt += dugbhd
         nPotSt += potbhd
      ELSE
         nDugSt += dugdem
         nPotSt += potdem
      ENDIF
      SKIP
   ENDDO

   ? cLine
   @ PRow() + 1, 10 SAY "Promet blagajne:"
   @ PRow(), ncol1 SAY PadL( Transform( nDug, pici ), 14 )
   @ PRow(), PCol() + 1 SAY PadL( Transform( nPot, pici ), 14 )
   ? cLine
   @ PRow() + 1, 10 SAY "Saldo od " + DToC( dDatDok - 1 ) + ":"
   @ PRow(), ncol1 SAY PadL( Transform( nDugst - nPotst, pici ), 14 )
   ? cLine
   @ PRow() + 1, 10 SAY "Ukupan primitak:"
   @ PRow(), ncol1 SAY PadL( Transform( nDugSt - nPotSt + nDug, pici ), 14 )
   @ PRow() + 1, 10 SAY "Izdatak:"
   @ PRow(), ncol1 SAY PadL( Transform( nPot, pici ), 14 )
   ? cLine
   @ PRow() + 1, 10 SAY "Saldo na dan:"
   @ PRow(), ncol1 SAY PadL( Transform( nDugSt - nPotSt + nDug - nPot, pici ), 14 )
   ? cLine
   @ PRow() + 1, 10 SAY "Slovima:"
   @ PRow(), PCol() + 1 SAY Slovima( Round( ndugst - npotst + ndug - npot, 2 ), iif( cdindem == "1", valuta_domaca_skraceni_naziv(), ValPomocna() ) )
   ? cLine
   ?
   ?

   @ PRow() + 1, 25 SAY "  ___________________            ______________________"
   @ PRow() + 1, 25 SAY "     Blagajna                           Kontrola       "

   FF

   end_print()

   closeret

   RETURN


// vrati konto naloga
STATIC FUNCTION dat_kto_blag( dDatum, cKonto, cFirma, cIdVn, cBrNal )

   LOCAL nLenKto
   LOCAL cTmpKto


   find_suban_by_broj_dokumenta( cIdFirma, cTipDok, cBrNal )

   // nisam pronasao dokument
   IF EOF()
      MsgBeep( "Dokument " + cFirma + "-" + cIdVn + "-" + cBrNal + " ne postoji!" )
      RETURN .F.
   ENDIF

   DO WHILE !Eof() .AND. suban->( idfirma + idvn + brnal ) == cFirma + cIdVn + cBrNal
      nTmpKto := field->idkonto
      nLenKto := Len( AllTrim( nTmpKto ) )
      IF nLenKto > 4
         IF Left( nTmpKto, 4 ) == "2020"
            cKonto := nTmpKto
            dDatum := field->datdok
            EXIT
         ENDIF
      ENDIF
      SKIP
   ENDDO

   RETURN


// setovanje linije za izvjestaj
STATIC FUNCTION set_line( cLine )

   LOCAL cRazmak := Space( 1 )

   cLine := ""
   cLine += Space( 4 )
   cLine += Replicate( "-", 7 )
   cLine += cRazmak
   cLine += Replicate( "-", 25 )
   cLine += cRazmak
   cLine += Replicate( "-", 21 )
   cLine += cRazmak
   cLine += Replicate( "-", 14 )
   cLine += cRazmak
   cLine += Replicate( "-", 15 )

   RETURN


// stampa zaglavlja blagajne
FUNCTION st_bl_zagl( cLine, cDinDem, cIdFirma, cTipDok, cBrDok, dDatDok )

   ?
   F12CPI

   ?? Space( 12 )

   IF cDinDem == "1"
      ?? "(" + valuta_domaca_skraceni_naziv() + ")"
   ELSE
      ?? "DEVIZNI (" + ValPomocna() + ")"
   ENDIF

   ?? hb_UTF8ToStr( " BLAGAJNIČKI IZVJESTAJ OD " ), dDatDok
   ?? Space( 8 ), "Broj:", cBrDok
   ? Space( 20 )
   ?? "na osnovu dokumenta: " + cIdFirma + "-" + cTipDok + "-" + cBrDok
   ?
   ?
   ? cLine
   ? "    * Redni*       Temeljnica        *        OPIS         *    ULAZ      *    IZLAZ     *"
   ? "    * broj *                         *                     *              *              *"
   ? "    *      *            *            *                     *              *              *"
   ? cLine

   RETURN
