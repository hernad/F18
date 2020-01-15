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

/* fin_spec_otv_stavke_rocni_intervali(lKartica)
 *  Otvorene stavke grupisano po brojevima veze
 */

FUNCTION fin_spec_otv_stavke_rocni_intervali( lKartica )

   LOCAL nCol1 := 72
   LOCAL cSvi := "N"
   LOCAL lPrikSldNula := .F.
   LOCAL lExpRpt := .F.
   LOCAL cExpRpt := "N"
   LOCAL aExpFld
   LOCAL cStart
   LOCAL cP_naz := ""
   PRIVATE cIdPartner

   IF lKartica == NIL
      lKartica := .F.
   ENDIF

   IF lKartica
      cPoRN := "D"
   ELSE
      cPoRN := "N"
   ENDIF

   cDokument := Space( 8 )

   picBHD := FormPicL( gPicBHD, 14 )
   picDEM := FormPicL( pic_iznos_eur(), 10 )

   IF fin_dvovalutno()
      m := "----------- ------------- -------------- -------------- ---------- ---------- ---------- -------------------------"
   ELSE
      m := "----------- ------------- -------------- -------------- -------------------------"
   ENDIF

   m := "-------- -------- " + m

   nStr := 0
   fVeci := .F.
   cPrelomljeno := "N"

   o_suban()
   //o_partner()
   //o_konto()


   cIdFirma := self_organizacija_id()
   cIdkonto := Space( 7 )
   cIdPartner := PadR( "", FIELD_LEN_PARTNER_ID )
   dNaDan := Date()
   cOpcine := Space( 20 )
   cValuta := "1"
   cPrikNule := "N"

   cSaRokom := "N"
   nDoDana1 :=  8
   nDoDana2 := 15
   nDoDana3 := 30
   nDoDana4 := 60

   PICPIC := PadR( fetch_metric( "fin_spec_po_dosp_picture", NIL, "99999999.99" ), 15 )

   Box(, 18, 60 )


   @ box_x_koord() + 1, box_y_koord() + 2 SAY "Firma: " + cIdFirma


   @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto:               " GET cIdkonto   PICT "@!"  VALID p_konto( @cIdkonto )
   IF cPoRN == "D"
      @ box_x_koord() + 3, box_y_koord() + 2 SAY "Partner (prazno svi):" GET cIdpartner PICT "@!"  VALID Empty( cIdpartner )  .OR. ( "." $ cidpartner ) .OR. ( ">" $ cidpartner ) .OR. p_partner( @cIdPartner )
   ENDIF

   // @ box_x_koord()+ 5,box_y_koord()+2 SAY "Prikaz prebijenog stanja " GET cPrelomljeno valid cPrelomljeno $ "DN" pict "@!"
   @ box_x_koord() + 6, box_y_koord() + 2 SAY "Izvjestaj se pravi na dan:" GET dNaDan
   @ box_x_koord() + 7, box_y_koord() + 2 SAY "Prikazati rocne intervale (D/N) ?" GET cSaRokom VALID cSaRokom $ "DN" PICT "@!"
   @ box_x_koord() + 8, box_y_koord() + 2 SAY "Interval 1: do (dana)" GET nDoDana1 WHEN cSaRokom == "D" PICT "999"
   @ box_x_koord() + 9, box_y_koord() + 2 SAY "Interval 2: do (dana)" GET nDoDana2 WHEN cSaRokom == "D" PICT "999"
   @ box_x_koord() + 10, box_y_koord() + 2 SAY "Interval 3: do (dana)" GET nDoDana3 WHEN cSaRokom == "D" PICT "999"
   @ box_x_koord() + 11, box_y_koord() + 2 SAY "Interval 4: do (dana)" GET nDoDana4 WHEN cSaRokom == "D" PICT "999"
   @ box_x_koord() + 13, box_y_koord() + 2 SAY "Prikaz iznosa (format)" GET PICPIC PICT "@!"
   @ box_x_koord() + 14, box_y_koord() + 2 SAY "Uslov po opcini (prazno - nista)" GET cOpcine
   @ box_x_koord() + 15, box_y_koord() + 2 SAY "Prikaz stavki kojima je saldo 0 (D/N)?" GET cPrikNule VALID cPrikNule $ "DN" PICT "@!"

   IF cPoRN == "N"
      @ box_x_koord() + 16, box_y_koord() + 2 SAY8 "Prikaz izvještaja u (1)KM (2)EURO" GET cValuta VALID cValuta $ "12"
   ENDIF
   @ box_x_koord() + 18, box_y_koord() + 2 SAY "Export u XLSX?" GET cExpRpt VALID cExpRpt $ "DN" PICT "@!"
   READ
   ESC_BCR
   Boxc()

   PICPIC := AllTrim( PICPIC )
   set_metric( "fin_spec_po_dosp_picture", NIL, PICPIC )

   lExpRpt := ( cExpRpt == "D" )

   IF cPrikNule == "D"
      lPrikSldNula := .T.
   ENDIF

   IF "." $ cIdPartner
      cIdPartner := StrTran( cIdPartner, ".", "" )
      cIdPartner := Trim( cIdPartner )
   ENDIF
   IF ">" $ cIdPartner
      cIdPartner := StrTran( cIdPartner, ">", "" )
      cIdPartner := Trim( cIdPartner )
      fVeci := .T.
   ENDIF
   IF Empty( cIdpartner )
      cIdPartner := ""
   ENDIF

   cSvi := cIdpartner

   IF lExpRpt == .T.
      aExpFld := get_ost_fields( cSaRokom, FIELD_LEN_PARTNER_ID )
      xlsx_export_init( aExpFld )
   ENDIF

   SELECT ( F_TRFP2 )
   IF !Used()
      o_trfp2()
   ENDIF

   HSEEK "99 " + Left( cIdKonto, 1 )
   DO WHILE !Eof() .AND. IDVD == "99" .AND. Trim( idkonto ) != Left( cIdKonto, Len( Trim( idkonto ) ) )
      SKIP 1
   ENDDO

   IF idvd == "99" .AND. Trim( idkonto ) == Left( cIdKonto, Len( Trim( idkonto ) ) )
      cDugPot := D_P
   ELSE
      cDugPot := "1"
      Box(, 3, 60 )
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto " + cIdKonto + " duguje / potrazuje (1/2)" GET cdugpot  VALID cdugpot $ "12" PICT "9"
      READ
      Boxc()
   ENDIF

   fin_create_pom_table( nil, FIELD_LEN_PARTNER_ID )
   // kreiraj pomocnu bazu

   o_trfp2()
   o_suban()
   //o_partner()
   o_konto()

   IF cPoRN == "D"
      gaZagFix := { 5, 3 }
   ELSE
      IF cSaRokom == "N"
         gaZagFix := { 4, 4 }
      ELSE
         gaZagFix := { 4, 5 }
      ENDIF
   ENDIF

   IF !start_print()
      RETURN .F.
   ENDIF

   nUkDugBHD := 0
   nUkPotBHD := 0

   // SELECT suban
   // SET ORDER TO TAG "3"

   IF cSvi == "D"
      // SEEK cIdFirma + cIdKonto
      find_suban_by_konto_partner( cIdFirma, cIdKonto )
   ELSE
      find_suban_by_konto_partner( cIdFirma, cIdKonto, cIdPartner )
      // SEEK cIdFirma + cIdKonto + cIdPartner
   ENDIF

   DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto

      cIdPartner := idpartner
      nUDug2 := 0
      nUPot2 := 0
      nUDug := 0
      nUPot := 0

      fPrviprolaz := .T.

      DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner

         cBrDok := BrDok
         cOtvSt := otvst
         nDug2 := nPot2 := 0
         nDug := nPot := 0
         aFaktura := { CToD( "" ), CToD( "" ), CToD( "" ) }

         DO WHILE !Eof() .AND. idfirma == cIdfirma .AND. cIdKonto == IdKonto .AND. cIdPartner == IdPartner .AND. brdok == cBrDok

            IF D_P == "1"
               nDug += IznosBHD
               nDug2 += IznosDEM
            ELSE
               nPot += IznosBHD
               nPot2 += IznosDEM
            ENDIF

            IF D_P == cDugPot
               aFaktura[ 1 ] := DATDOK
               aFaktura[ 2 ] := DATVAL
            ENDIF

            IF aFaktura[ 3 ] < DatDok  // datum zadnje promjene
               aFaktura[ 3 ] := DatDok
            ENDIF

            SKIP 1
         ENDDO

         IF Round( ndug - npot, 2 ) == 0
            // nista
         ELSE
            fPrviProlaz := .F.
            IF cPrelomljeno == "D"
               IF ( ndug - npot ) > 0
                  nDug := nDug - nPot
                  nPot := 0
               ELSE
                  nPot := nPot - nDug
                  nDug := 0
               ENDIF
               IF ( ndug2 - npot2 ) > 0
                  nDug2 := nDug2 - nPot2
                  nPot2 := 0
               ELSE
                  nPot2 := nPot2 - nDug2
                  nDug2 := 0
               ENDIF
            ENDIF
            SELECT POM
            APPEND BLANK
            Scatter()
            _idpartner := cIdPartner
            _datdok    := aFaktura[ 1 ]
            _datval    := aFaktura[ 2 ]
            _datzpr    := aFaktura[ 3 ]
            _brdok     := cBrDok
            _dug       := nDug
            _pot       := nPot
            _dug2      := nDug2
            _pot2      := nPot2
            _otvst     := IF( IF( Empty( _datval ), _datdok > dNaDan, _datval > dNaDan ), " ", "1" )
            Gather()
            SELECT SUBAN
         ENDIF
      ENDDO // partner

      IF PRow() > 58 + dodatni_redovi_po_stranici()
         FF
         Zfin_spec_otv_stavke_rocni_intervali( nil, nil, PICPIC )
      ENDIF

      IF ( !fveci .AND. idpartner = cSvi ) .OR. fVeci

      ELSE
         EXIT
      ENDIF
   ENDDO

   SELECT POM
   IF cSaRokom == "D"
      INDEX ON IDPARTNER + OTVST + Rocnost() + DToS( DATDOK ) + DToS( iif( Empty( DATVAL ), DATDOK, DATVAL ) ) + BRDOK TAG "2"
   ELSE
      INDEX ON IDPARTNER + OTVST + DToS( DATDOK ) + DToS( iif( Empty( DATVAL ), DATDOK, DATVAL ) ) + BRDOK TAG "2"
   ENDIF
   SET ORDER TO TAG "2"
   GO TOP

   nTUDug := nTUPot := nTUDug2 := nTUPot2 := 0
   nTUkUVD := nTUkUVP := nTUkUVD2 := nTUkUVP2 := 0
   nTUkVVD := nTUkVVP := nTUkVVD2 := nTUkVVP2 := 0

   IF cSaRokom == "D"
      // D,TD    P,TP   D2,TD2  P2,TP2
      anInterUV := { { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 1
         { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 2
      { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 3
         { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 4
      { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } } }        // preko intervala 4

      // D,TD    P,TP   D2,TD2  P2,TP2
      anInterVV := { { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 1
         { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 2
      { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 3
         { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }, ;        // do - interval 4
      { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } } }        // preko intervala 4
   ENDIF

   cLastIdPartner := ""
   IF cPoRN == "N"
      fPrviProlaz := .T.
   ENDIF

   DO WHILE !Eof()

      IF cPoRN == "D"
         fPrviProlaz := .T.
      ENDIF

      cIdPartner := IDPARTNER

      // provjeri saldo partnera
      IF !lPrikSldNula .AND. saldo_nula( cIdPartner )
         SKIP
         LOOP
      ENDIF

      IF !Empty( cOpcine ) // provjeri opcine
         select_o_partner( cIdPartner )
         IF At( partn->idops, cOpcine ) <> 0
            SELECT pom
            SKIP
            LOOP
         ENDIF
         SELECT pom
      ENDIF

      nUDug := nUPot := nUDug2 := nUPot2 := 0
      nUkUVD := nUkUVP := nUkUVD2 := nUkUVP2 := 0
      nUkVVD := nUkVVP := nUkVVD2 := nUkVVP2 := 0

      cFaza := otvst

      IF cSaRokom == "D"
         FOR i := 1 TO Len( anInterUV )
            FOR j := 1 TO Len( anInterUV[ i ] )
               anInterUV[ i, j, 1 ] := 0
               anInterVV[ i, j, 1 ] := 0
            NEXT
         NEXT
         nFaza := RRocnost()
      ENDIF

      IF PRow() > 52 + dodatni_redovi_po_stranici()
         FF
         Zfin_spec_otv_stavke_rocni_intervali( .T., nil, PICPIC )
         fPrviProlaz := .F.
      ENDIF

      IF fPrviProlaz
         Zfin_spec_otv_stavke_rocni_intervali( nil, nil, PICPIC )
         fPrviProlaz := .F.
      ENDIF

      SELECT pom

      DO WHILE !Eof() .AND. cIdPartner == IdPartner

         IF cPoRn == "D"
            ? datdok, datval, PadR( brdok, 10 )
            nCol1 := PCol() + 1
            ?? " "
            ?? Transform( dug, picbhd ), Transform( pot, picbhd ), Transform( dug - pot, picbhd )
            IF fin_dvovalutno()
               ?? " " + Transform( dug2, picdem ), Transform( pot2, picdem ), Transform( dug2 - pot2, picdem )
            ENDIF
         ELSEIF cLastIdPartner != cIdPartner .OR. Len( cLastIdPartner ) < 1
            qqout_sa_x_x( cIdPartner )
            select_o_partner( cIdPartner )
            cP_naz := PadR( partn->naz, 25 )
            select pom
            qqout_sa_x( cP_naz )
            cLastIdPartner := cIdPartner
         ENDIF

         IF otvst == " "
            IF cPoRn == "D"
               ?? "   U VALUTI" + IF( cSaRokom == "D", IspisRocnosti(), "" )
            ENDIF
            nUkUVD  += Dug
            nUkUVP  += Pot
            nUkUVD2 += Dug2
            nUkUVP2 += Pot2
            IF cSaRokom == "D"
               anInterUV[ nFaza, 1, 1 ] += dug
               anInterUV[ nFaza, 2, 1 ] += pot
               anInterUV[ nFaza, 3, 1 ] += dug2
               anInterUV[ nFaza, 4, 1 ] += pot2
            ENDIF
         ELSE
            IF cPoRn == "D"
               ?? " VAN VALUTE" + IF( cSaRokom == "D", IspisRocnosti(), "" )
            ENDIF
            nUkVVD  += Dug
            nUkVVP  += Pot
            nUkVVD2 += Dug2
            nUkVVP2 += Pot2
            IF cSaRokom == "D"
               anInterVV[ nFaza, 1, 1 ] += dug
               anInterVV[ nFaza, 2, 1 ] += pot
               anInterVV[ nFaza, 3, 1 ] += dug2
               anInterVV[ nFaza, 4, 1 ] += pot2
            ENDIF
         ENDIF
         nUDug += Dug
         nUPot += Pot
         nUDug2 += Dug2
         nUPot2 += Pot2

         SKIP 1
         // znaci da treba
         IF cFaza != otvst .OR. Eof() .OR. cIdPartner != idpartner // <-+ prikazati
            IF cPoRn == "D"
               ? m
            ENDIF                           // + subtotal
            IF cFaza == " "
               IF cSaRokom == "D"
                  SKIP -1
                  IF cPoRn == "D"
                     ? "UK.U VALUTI" + IspisRocnosti() + ":"
                     @ PRow(), nCol1 SAY anInterUV[ nFaza, 1, 1 ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 2, 1 ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 1, 1 ] -anInterUV[ nFaza, 2, 1 ] PICTURE picBHD

                     IF fin_dvovalutno()
                        @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 3, 1 ] PICTURE picdem
                        @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 4, 1 ] PICTURE picdem
                        @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 3, 1 ] -anInterUV[ nFaza, 4, 1 ] PICTURE picdem
                     ENDIF
                  ENDIF
                  anInterUV[ nFaza, 1, 2 ] += anInterUV[ nFaza, 1, 1 ]
                  anInterUV[ nFaza, 2, 2 ] += anInterUV[ nFaza, 2, 1 ]
                  anInterUV[ nFaza, 3, 2 ] += anInterUV[ nFaza, 3, 1 ]
                  anInterUV[ nFaza, 4, 2 ] += anInterUV[ nFaza, 4, 1 ]
                  IF cPoRn == "D"
                     ? m
                  ENDIF
                  SKIP 1
               ENDIF
               IF cPoRn == "D"
                  ? "UKUPNO U VALUTI:"
                  @ PRow(), nCol1 SAY nUkUVD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nUkUVP PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nUkUVD - nUkUVP PICTURE picBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 1 SAY nUkUVD2 PICTURE picdem
                     @ PRow(), PCol() + 1 SAY nUkUVP2 PICTURE picdem
                     @ PRow(), PCol() + 1 SAY nUkUVD2 - nUkUVP2 PICTURE picdem
                  ENDIF
               ENDIF
               nTUkUVD  += nUkUVD
               nTUkUVP  += nUkUVP
               nTUkUVD2 += nUkUVD2
               nTUkUVP2 += nUkUVP2
            ELSE
               IF cSaRokom == "D"
                  SKIP -1
                  IF cPoRn == "D"
                     ? "UK.VAN VALUTE" + IspisRocnosti() + ":"
                     @ PRow(), nCol1 SAY anInterVV[ nFaza, 1, 1 ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 2, 1 ] PICTURE picBHD
                     @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 1, 1 ] -anInterVV[ nFaza, 2, 1 ] PICTURE picBHD
                     IF fin_dvovalutno()
                        @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 3, 1 ] PICTURE picdem
                        @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 4, 1 ] PICTURE picdem
                        @ PRow(), PCol() + 1 SAY 44 PICTURE picdem
                        @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 3, 1 ] -anInterVV[ nFaza, 4, 1 ] PICTURE picdem
                     ENDIF
                  ENDIF
                  anInterVV[ nFaza, 1, 2 ] += anInterVV[ nFaza, 1, 1 ]
                  anInterVV[ nFaza, 2, 2 ] += anInterVV[ nFaza, 2, 1 ]
                  anInterVV[ nFaza, 3, 2 ] += anInterVV[ nFaza, 3, 1 ]
                  anInterVV[ nFaza, 4, 2 ] += anInterVV[ nFaza, 4, 1 ]
                  IF cPoRn == "D"
                     ? m
                  ENDIF
                  SKIP 1
               ENDIF
               IF cPoRn == "D"
                  ? "UKUPNO VAN VALUTE:"
                  @ PRow(), nCol1 SAY nUkVVD PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nUkVVP PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY nUkVVD - nUkVVP PICTURE picBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 1 SAY nUkVVD2 PICTURE picdem
                     @ PRow(), PCol() + 1 SAY nUkVVP2 PICTURE picdem
                     @ PRow(), PCol() + 1 SAY nUkVVD2 - nUkVVP2 PICTURE picdem
                  ENDIF
               ENDIF
               nTUkVVD  += nUkVVD
               nTUkVVP  += nUkVVP
               nTUkVVD2 += nUkVVD2
               nTUkVVP2 += nUkVVP2
            ENDIF
            IF cPoRn == "D"
               ? m
            ENDIF
            cFaza := otvst
            IF cSaRokom == "D"
               nFaza := RRocnost()
            ENDIF
         ELSEIF cSaRokom == "D" .AND. nFaza != RRocnost()
            SKIP -1
            IF cPoRn == "D"
               ? m
            ENDIF
            IF cFaza == " "
               IF cPoRn == "D"
                  ? "UK.U VALUTI" + IspisRocnosti() + ":"
                  @ PRow(), nCol1 SAY anInterUV[ nFaza, 1, 1 ] PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 2, 1 ] PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 1, 1 ] -anInterUV[ nFaza, 2, 1 ] PICTURE picBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 3, 1 ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 4, 1 ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY anInterUV[ nFaza, 3, 1 ] -anInterUV[ nFaza, 4, 1 ] PICTURE picdem
                  ENDIF
               ENDIF
               anInterUV[ nFaza, 1, 2 ] += anInterUV[ nFaza, 1, 1 ]
               anInterUV[ nFaza, 2, 2 ] += anInterUV[ nFaza, 2, 1 ]
               anInterUV[ nFaza, 3, 2 ] += anInterUV[ nFaza, 3, 1 ]
               anInterUV[ nFaza, 4, 2 ] += anInterUV[ nFaza, 4, 1 ]
            ELSE
               IF cPoRn == "D"
                  ? "UK.VAN VALUTE" + IspisRocnosti() + ":"
                  @ PRow(), nCol1 SAY anInterVV[ nFaza, 1, 1 ] PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 2, 1 ] PICTURE picBHD
                  @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 1, 1 ] -anInterVV[ nFaza, 2, 1 ] PICTURE picBHD
                  IF fin_dvovalutno()
                     @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 3, 1 ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 4, 1 ] PICTURE picdem
                     @ PRow(), PCol() + 1 SAY anInterVV[ nFaza, 3, 1 ] -anInterVV[ nFaza, 4, 1 ] PICTURE picdem
                  ENDIF
               ENDIF
               anInterVV[ nFaza, 1, 2 ] += anInterVV[ nFaza, 1, 1 ]
               anInterVV[ nFaza, 2, 2 ] += anInterVV[ nFaza, 2, 1 ]
               anInterVV[ nFaza, 3, 2 ] += anInterVV[ nFaza, 3, 1 ]
               anInterVV[ nFaza, 4, 2 ] += anInterVV[ nFaza, 4, 1 ]
            ENDIF
            IF cPoRn == "D"
               ? m
            ENDIF
            SKIP 1
            nFaza := RRocnost()
         ENDIF

      ENDDO

      IF PRow() > 58 + dodatni_redovi_po_stranici()
         FF
         Zfin_spec_otv_stavke_rocni_intervali( .T., nil, PICPIC )
      ENDIF

      SELECT POM
      IF !fPrviProlaz  // bilo je stavki
         IF cPoRn == "D"
            ? M
            ? "UKUPNO:"
            @ PRow(), nCol1 SAY nUDug PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUPot PICTURE picBHD
            @ PRow(), PCol() + 1 SAY nUDug - nUPot PICTURE picBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY nUDug2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUPot2 PICTURE picdem
               @ PRow(), PCol() + 1 SAY nUDug2 - nUPot2 PICTURE picdem
            ENDIF
            ? m
         ELSE
            IF cSaRokom == "D"
               FOR i := 1 TO Len( anInterUV )
                  IF ( cValuta == "1" )
                     qqout_sa_x( Transform( anInterUV[ i, 1, 1 ] -anInterUV[ i, 2, 1 ], PICPIC ) )
                  ELSE
                     qqout_sa_x( Transform( anInterUV[ i, 3, 1 ] -anInterUV[ i, 4, 1 ], PICPIC ) )
                  ENDIF
               NEXT

               IF ( cValuta == "1" )
                  qqout_sa_x( Transform( nUkUVD - nUkUVP, PICPIC ) )
               ELSE
                  qqout_sa_x( Transform( nUkUVD2 - nUkUVP2, PICPIC ) )
               ENDIF

               FOR i := 1 TO Len( anInterVV )
                  IF ( cValuta == "1" )
                     qqout_sa_x( Transform( anInterVV[ i, 1, 1 ] -anInterVV[ i, 2, 1 ], PICPIC ) )
                  ELSE
                     qqout_sa_x( Transform( anInterVV[ i, 3, 1 ] -anInterVV[ i, 4, 1 ], PICPIC ) )
                  ENDIF
               NEXT
               IF ( cValuta == "1" )
                  qqout_sa_x( Transform( nUkVVD - nUkVVP, PICPIC ) )
                  qqout_sa_x( Transform( nUDug - nUPot, PICPIC ) )
               ELSE
                  qqout_sa_x( Transform( nUkVVD2 - nUkVVP2, PICPIC ) )
                  qqout_sa_x( Transform( nUDug2 - nUPot2, PICPIC ) )
               ENDIF

               IF lExpRpt == .T.
                  IF cValuta == "1"
                     fill_ost_tbl( cSaRokom, cIdPartner, cP_naz, nUkUVD - nUkUVP, nUkVVD - nUkVVP, nUDug - nUPot, anInterUV[ 1, 1, 1 ] - anInterUV[ 1, 2, 1 ], anInterUV[ 2, 1, 1 ] - anInterUV[ 2, 2, 1 ], anInterUV[ 3, 1, 1 ] - anInterUV[ 3, 2, 1 ], anInterUV[ 4, 1, 1 ] - anInterUV[ 4, 2, 1 ], anInterUV[ 5, 1, 1 ] - anInterUV[ 5, 2, 1 ], anInterVV[ 1, 1, 1 ] - anInterVV[ 1, 2, 1 ], anInterVV[ 2, 1, 1 ] - anInterVV[ 2, 2, 1 ], anInterVV[ 3, 1, 1 ] - anInterVV[ 3, 2, 1 ], anInterVV[ 4, 1, 1 ] - anInterVV[ 4, 2, 1 ], anInterVV[ 5, 1, 1 ] - anInterVV[ 5, 2, 1 ] )
                  ELSE
                     fill_ost_tbl( cSaRokom, cIdPartner, cP_naz, nUkUVD2 - nUkUVP2, nUkVVD2 - nUkVVP2, nUDug2 - nUPot2, anInterUV[ 1, 3, 1 ] - anInterUV[ 1, 4, 1 ], anInterUV[ 2, 3, 1 ] - anInterUV[ 2, 4, 1 ], anInterUV[ 3, 3, 1 ] - anInterUV[ 3, 4, 1 ], anInterUV[ 4, 3, 1 ] - anInterUV[ 4, 4, 1 ], anInterUV[ 5, 3, 1 ] - anInterUV[ 5, 4, 1 ], anInterVV[ 1, 3, 1 ] - anInterVV[ 1, 4, 1 ], anInterVV[ 2, 3, 1 ] - anInterVV[ 2, 4, 1 ], anInterVV[ 3, 3, 1 ] - anInterVV[ 3, 4, 1 ], anInterVV[ 4, 3, 1 ] - anInterVV[ 4, 4, 1 ], anInterVV[ 5, 3, 1 ] - anInterVV[ 5, 4, 1 ] )
                  ENDIF
               ENDIF
            ELSE
               IF ( cValuta == "1" )
                  qqout_sa_x( Transform( nUkUVD - nUkUVP, PICPIC ) )
                  qqout_sa_x( Transform( nUkVVD - nUkVVP, PICPIC ) )
                  qqout_sa_x( Transform( nUDug - nUPot, PICPIC ) )
               ELSE
                  qqout_sa_x( Transform( nUkUVD2 - nUkUVP2, PICPIC ) )
                  qqout_sa_x( Transform( nUkVVD2 - nUkVVP2, PICPIC ) )
                  qqout_sa_x( Transform( nUDug2 - nUPot2, PICPIC ) )
               ENDIF

               IF lExpRpt == .T.
                  IF cValuta == "1"
                     fill_ost_tbl( cSaRokom, cIdPartner, cP_naz, nUkUVD - nUkUVP, nUkVVD - nUkVVP, nUDug - nUPot )

                  ELSE
                     fill_ost_tbl( cSaRokom, cIdPartner, cP_naz, nUkUVD2 - nUkUVP2, nUkVVD2 - nUkVVP2, nUDug2 - nUPot2 )

                  ENDIF
               ENDIF


            ENDIF
         ENDIF
      ENDIF

      IF cPoRn == "D"
         ?
         ?
         ?
      ENDIF

      nTUDug += nUDug
      nTUDug2 += nUDug2
      nTUPot += nUPot
      nTUPot2 += nUPot2
   ENDDO

   IF cPoRn == "D" .AND. Len( cSvi ) < Len( idpartner ) .AND. ;
         ( Round( nTUDug, 2 ) != 0 .OR. Round( nTUPot, 2 ) != 0 .OR. ;
         Round( nTUkUVD, 2 ) != 0 .OR. Round( nTUkUVP, 2 ) != 0 .OR. ;
         Round( nTUkVVD, 2 ) != 0 .OR. Round( nTUkVVP, 2 ) != 0 )

      // prikazimo total
      FF
      Zfin_spec_otv_stavke_rocni_intervali( .T., .T., PICPIC )
      ? m2 := StrTran( M, "-", "=" )
      IF cSaRokom == "D"
         FOR i := 1 TO Len( anInterUV )
            ? "PARTN.U VAL." + IspisRoc2( i ) + ":"
            @ PRow(), nCol1 SAY anInterUV[ i, 1, 2 ] PICTURE picBHD
            @ PRow(), PCol() + 1 SAY anInterUV[ i, 2, 2 ] PICTURE picBHD
            @ PRow(), PCol() + 1 SAY anInterUV[ i, 1, 2 ] -anInterUV[ i, 2, 2 ] PICTURE picBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY anInterUV[ i, 3, 2 ] PICTURE picdem
               @ PRow(), PCol() + 1 SAY anInterUV[ i, 4, 2 ] PICTURE picdem
               @ PRow(), PCol() + 1 SAY anInterUV[ i, 3, 2 ] -anInterUV[ i, 4, 2 ] PICTURE picdem
            ENDIF
         NEXT
         ? m
      ENDIF
      ? "PARTNERI UKUPNO U VALUTI  :"
      @ PRow(), nCol1 SAY nTUkUVD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUkUVP PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUkUVD - nTUkUVP PICTURE picBHD
      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY nTUkUVD2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUkUVP2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUkUVD2 - nTUkUVP2 PICTURE picdem
      ENDIF
      ? m2
      IF cSaRokom == "D"
         FOR i := 1 TO Len( anInterVV )
            ? "PARTN.VAN VAL." + IspisRoc2( i ) + ":"
            @ PRow(), nCol1 SAY anInterVV[ i, 1, 2 ] PICTURE picBHD
            @ PRow(), PCol() + 1 SAY anInterVV[ i, 2, 2 ] PICTURE picBHD
            @ PRow(), PCol() + 1 SAY anInterVV[ i, 1, 2 ] -anInterVV[ i, 2, 2 ] PICTURE picBHD
            IF fin_dvovalutno()
               @ PRow(), PCol() + 1 SAY anInterVV[ i, 3, 2 ] PICTURE picdem
               @ PRow(), PCol() + 1 SAY anInterVV[ i, 4, 2 ] PICTURE picdem
               @ PRow(), PCol() + 1 SAY anInterVV[ i, 3, 2 ] -anInterVV[ i, 4, 2 ] PICTURE picdem
            ENDIF
         NEXT
         ? m
      ENDIF

      ? "PARTNERI UKUPNO VAN VALUTE:"
      @ PRow(), nCol1 SAY nTUkVVD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUkVVP PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUkVVD - nTUkVVP PICTURE picBHD
      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY nTUkVVD2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUkVVP2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUkVVD2 - nTUkVVP2 PICTURE picdem
      ENDIF
      ? m2
      ? "PARTNERI UKUPNO           :"
      @ PRow(), nCol1 SAY nTUDug PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUPot PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nTUDug - nTUPot PICTURE picBHD
      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY nTUDug2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUPot2 PICTURE picdem
         @ PRow(), PCol() + 1 SAY nTUDug2 - nTUPot2 PICTURE picdem
      ENDIF
      ? m2

   ENDIF // total

   IF cPoRn == "N"

      cTmpL := ""

      // uzmi liniju
      _get_line1( @cTmpL, cSaRokom, PICPIC )

      ? cTmpL

      qqout_sa_x_x( PadR( "UKUPNO", Len( POM->IDPARTNER + PadR( PARTN->naz, 25 ) ) + 1 ) )

      _get_line2( @cTmpL, cSaRokom, PICPIC )

      IF cSaRokom == "D"
         FOR i := 1 TO Len( anInterUV )
            IF ( cValuta == "1" )
               qqout_sa_x( Transform( anInterUV[ i, 1, 2 ] -anInterUV[ i, 2, 2 ], PICPIC ) )
            ELSE
               qqout_sa_x( Transform( anInterUV[ i, 3, 2 ] -anInterUV[ i, 4, 2 ], PICPIC ) )
            ENDIF
         NEXT
         IF ( cValuta == "1" )
            qqout_sa_x( Transform( nTUkUVD - nTUkUVP, PICPIC ) )
         ELSE
            qqout_sa_x( Transform( nTUkUVD2 - nTUkUVP2, PICPIC ) )
         ENDIF

         FOR i := 1 TO Len( anInterVV )
            IF ( cValuta == "1" )
               qqout_sa_x( Transform( anInterVV[ i, 1, 2 ] -anInterVV[ i, 2, 2 ], PICPIC ) )
            ELSE
               qqout_sa_x( Transform( anInterVV[ i, 3, 2 ] -anInterVV[ i, 4, 2 ], PICPIC ) )
            ENDIF
         NEXT

         IF ( cValuta == "1" )
            qqout_sa_x( Transform( nTUkVVD - nTUkVVP, PICPIC ) )
            qqout_sa_x( Transform( nTUDug - nTUPot, PICPIC ) )
         ELSE
            qqout_sa_x( Transform( nTUkVVD2 - nTUkVVP2, PICPIC ) )
            qqout_sa_x( Transform( nTUDug2 - nTUPot2, PICPIC ) )
         ENDIF

         IF lExpRpt == .T.

            IF cValuta == "1"
               fill_ost_tbl( cSaRokom, "UKUPNO", "", nTUkUVD - nTUkUVP, nTUkVVD - nTUkVVP, nTUDug - nTUPot, anInterUV[ 1, 1, 2 ] - anInterUV[ 1, 2, 2 ], anInterUV[ 2, 1, 2 ] - anInterUV[ 2, 2, 2 ], anInterUV[ 3, 1, 2 ] - anInterUV[ 3, 2, 2 ], anInterUV[ 4, 1, 2 ] - anInterUV[ 4, 2, 2 ], anInterUV[ 5, 1, 2 ] - anInterUV[ 5, 2, 2 ], anInterVV[ 1, 1, 2 ] - anInterVV[ 1, 2, 2 ], anInterVV[ 2, 1, 2 ] - anInterVV[ 2, 2, 2 ], anInterVV[ 3, 1, 2 ] - anInterVV[ 3, 2, 2 ], anInterVV[ 4, 1, 2 ] - anInterVV[ 4, 2, 2 ], anInterVV[ 5, 1, 2 ] - anInterVV[ 5, 2, 2 ] )
            ELSE
               fill_ost_tbl( cSaRokom, "UKUPNO", "", nTUkUVD2 - nTUkUVP2, nTUkVVD2 - nTUkVVP2, nTUDug2 - nTUPot2, anInterUV[ 1, 3, 2 ] - anInterUV[ 1, 4, 2 ], anInterUV[ 2, 3, 2 ] - anInterUV[ 2, 4, 2 ], anInterUV[ 3, 3, 2 ] - anInterUV[ 3, 4, 2 ], anInterUV[ 4, 3, 2 ] - anInterUV[ 4, 4, 2 ], anInterUV[ 5, 3, 2 ] - anInterUV[ 5, 4, 2 ], anInterVV[ 1, 3, 2 ] - anInterVV[ 1, 4, 2 ], anInterVV[ 2, 3, 2 ] - anInterVV[ 2, 4, 2 ], anInterVV[ 3, 3, 2 ] - anInterVV[ 3, 4, 2 ], anInterVV[ 4, 3, 2 ] - anInterVV[ 4, 4, 2 ], anInterVV[ 5, 3, 2 ] - anInterVV[ 5, 4, 2 ] )
            ENDIF

         ENDIF

      ELSE
         IF ( cValuta == "1" )
            qqout_sa_x( Transform( nTUkUVD - nTUkUVP, PICPIC ) )
            qqout_sa_x( Transform( nTUkVVD - nTUkVVP, PICPIC ) )
            qqout_sa_x( Transform( nTUDug - nTUPot, PICPIC ) )
         ELSE
            qqout_sa_x( Transform( nTUkUVD2 - nTUkUVP2, PICPIC ) )
            qqout_sa_x( Transform( nTUkVVD2 - nTUkVVP2, PICPIC ) )
            qqout_sa_x( Transform( nTUDug2 - nTUPot2, PICPIC ) )
         ENDIF

         IF lExpRpt == .T.

            IF cValuta == "1"
               fill_ost_tbl( cSaRokom, "UKUPNO", "", nTUkUVD - nTUkUVP, nTUkVVD - nTUkVVP, nTUDug - nTUPot )
            ELSE
               fill_ost_tbl( cSaRokom, "UKUPNO", "", nTUkUVD2 - nTUkUVP2, nTUkVVD2 - nTUkVVP2, nTUDug2 - nTUPot2 )
            ENDIF

         ENDIF

      ENDIF

      ? cTmpL

   ENDIF

   FF

   end_print()

   IF lExpRpt == .T.
      open_exported_xlsx()
   ENDIF

   SELECT ( F_POM )
   USE

   CLOSERET

   RETURN


// -----------------------------------------------------
// vraca liniju za report varijanta 1
// -----------------------------------------------------
STATIC FUNCTION _get_line1( cTmpL, cSaRokom, cPicForm )

   LOCAL cStart := "+"
   LOCAL cMidd := "+"
   LOCAL cLine := "+"
   LOCAL cEnd := "+"
   LOCAL cFill := "+"
   LOCAL nFor := 3

   IF cSaRokom == "D"
      nFor := 13
   ENDIF

   cTmpL := cStart
   cTmpL += Replicate( cFill, FIELD_LEN_PARTNER_ID )
   cTmpL += cMidd
   cTmpL += Replicate( cFill, 25 )

   FOR i := 1 TO nFor
      cTmpL += cLine
      cTmpL += Replicate( cFill, Len( cPicForm ) )
   NEXT

   cTmpL += cEnd

   RETURN

// ------------------------------------------------------
// vraca liniju varijantu 2
// ------------------------------------------------------
STATIC FUNCTION _get_line2( cTmpL, cSaRokom, cPicForm )

   LOCAL cStart := "+"
   LOCAL cLine := "+"
   LOCAL cEnd := "+"
   LOCAL cFill := "+"
   LOCAL nFor := 3

   IF cSaRokom == "D"
      nFor := 13
   ENDIF

   cTmpL := cStart
   cTmpL += Replicate( cFill, FIELD_LEN_PARTNER_ID )
   cTmpL += cLine
   cTmpL += Replicate( cFill, 25 )

   FOR i := 1 TO nFor
      cTmpL += cLine
      cTmpL += Replicate( cFill, Len( cPicForm ) )
   NEXT

   cTmpL += cEnd

   RETURN .T.



// --------------------------------------------------------
// provjeri da li je saldo partnera 0, vraca .t. ili .f.
// --------------------------------------------------------
FUNCTION saldo_nula( cIdPartn )

   LOCAL nPRecNo
   LOCAL nLRecNo
   LOCAL nDug := 0
   LOCAL nPot := 0

   nPRecNo := RecNo()

   DO WHILE !Eof() .AND. idpartner == cIdPartn
      nDug += dug
      nPot += pot
      SKIP
   ENDDO

   SKIP -1

   nLRecNo := RecNo()

   IF ( Round( nDug, 2 ) - Round( nPot, 2 ) == 0 )
      GO ( nLRecNo )
      RETURN .T.
   ENDIF

   GO ( nPRecNo )

   RETURN .F.


   /* Zfin_spec_otv_stavke_rocni_intervali(fStrana,lSvi)
    *     Zaglavlje izvjestaja specifikacije po dospjecu
    *   param: fStrana
    *   param: lSvi
    */

FUNCTION Zfin_spec_otv_stavke_rocni_intervali( fStrana, lSvi, PICPIC )

   LOCAL nII
   LOCAL cTmp

   ?

   IF cSaRokom == "D" .AND. ( ( Len( AllTrim( PICPIC ) ) * 13 ) + 46 ) > 170
      ?? "#%LANDS#"
   ENDIF

   IF cPoRn == "D"
      IF fin_dvovalutno()
         P_COND2
      ELSE
         P_COND
      ENDIF
   ELSE
      IF cSaRokom == "D"
         P_COND2
      ELSE
         P_10CPI
      ENDIF
   ENDIF

   IF lSvi == NIL
      lSvi := .F.
   ENDIF

   IF fStrana == NIL
      fStrana := .F.
   ENDIF

   IF nStr = 0
      fStrana := .T.
   ENDIF

   IF cPoRn == "D"
      ??U "FIN.P:  SPECIFIKACIJA OTVORENIH STAVKI PO ROČNIM INTERVALIMA NA DAN "; ?? dNaDan
      IF fStrana
         @ PRow(), 110 SAY "Str:" + Str( ++nStr, 3 )
      ENDIF

      select_o_partner( cIdFirma )

      ? "FIRMA:", cIdFirma, "-", self_organizacija_naziv()

      select_o_konto( cIdKonto )

      ? "KONTO  :", cIdKonto, naz

      IF lSvi
         ? "PARTNER: SVI"
      ELSE
         select_o_partner( cIdPartner )
         ? "PARTNER:", cIdPartner, Trim( PadR( naz, 25 ) ), " ", Trim( naz2 ), " ", Trim( mjesto )
      ENDIF

      ? m
      ?

      ?? "Dat.dok.*Dat.val.* "

      IF fin_dvovalutno()
         ?? "  BrDok   *   dug " + valuta_domaca_skraceni_naziv() + "  *   pot " + valuta_domaca_skraceni_naziv() + "   *  saldo  " + valuta_domaca_skraceni_naziv() + " * dug " + ValPomocna() + " * pot " + ValPomocna() + " *saldo " + ValPomocna() + "*      U/VAN VALUTE      *"
      ELSE
         ?? "  BrDok   *   dug " + valuta_domaca_skraceni_naziv() + "  *   pot " + valuta_domaca_skraceni_naziv() + "   *  saldo  " + valuta_domaca_skraceni_naziv() + " *      U/VAN VALUTE      *"
      ENDIF

      ? m

   ELSE
      ??U "FIN.P:  SPECIFIKACIJA OTVORENIH STAVKI PO ROČNIM INTERVALIMA NA DAN "; ?? dNaDan
      select_o_partner( cIdFirma )
      ? "FIRMA:", cIdFirma, "-", self_organizacija_naziv()
      select_o_konto( cIdKonto )

      ? "KONTO  :", cIdKonto, naz

      IF cSaRokom == "D"

         // prvi red
         cTmp := "+"
         cTmp += Replicate( "+", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += Replicate( "+", 25 )
         cTmp += "+"
         cTmp += Replicate( "+", ( Len( PICPIC ) * 5 ) + 4 )
         cTmp += "+"
         cTmp += Replicate( "+", Len( PICPIC ) )
         cTmp += "+"
         cTmp += Replicate( "+", ( Len( PICPIC ) * 5 ) + 4 )
         cTmp += "+"
         cTmp += Replicate( "+", Len( PICPIC ) )
         cTmp += "+"
         cTmp += Replicate( "+", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp

         // drugi red
         cTmp := "+"
         cTmp += Replicate( " ", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += Replicate( " ", 25 )
         cTmp += "+"
         cTmp += _f_text( "U      V  A  L  U  T  I", ( Len( PICPIC ) * 5 ) + 4 )

         cTmp += "+"
         cTmp += Replicate( " ", Len( PICPIC ) )

         cTmp += "+"
         cTmp += _f_text( "V  A  N      V  A  L  U  T  E", ( Len( PICPIC ) * 5 ) + 4 )
         cTmp += "+"
         cTmp += Replicate( " ", Len( PICPIC ) )
         cTmp += "+"
         cTmp += Replicate( " ", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp


         // treci red
         cTmp := "+"
         cTmp += PadC( "SIFRA", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += _f_text( "NAZIV  PARTNERA", 25 )
         cTmp += "+"

         FOR nII := 1 TO 5
            cTmp += Replicate( "+", Len( PICPIC ) )

            IF nII == 5
               cTmp += "+"
            ELSE
               cTmp += "+"
            ENDIF

         NEXT

         cTmp += _f_text( " ", Len( PICPIC ) )
         cTmp += "+"

         FOR nII := 1 TO 5
            cTmp += Replicate( "+", Len( PICPIC ) )

            IF nII == 5
               cTmp += "+"
            ELSE
               cTmp += "+"
            ENDIF
         NEXT

         cTmp += _f_text( " ", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp

         cTmp := "+"
         cTmp += PadC( "PARTN.", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += _f_text( " ", 25 )

         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana1, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana2, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana3, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana4, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "PR." + Str( nDoDana4, 2 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana1, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana2, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana3, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "DO" + Str( nDoDana4, 3 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "PR." + Str( nDoDana4, 2 ) + " D.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( " ", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp

         cTmp := "+"
         cTmp += Replicate( "+", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += Replicate( "+", 25 )

         FOR nII := 1 TO 13
            cTmp += "+"
            cTmp += Replicate( "+", Len( PICPIC ) )
         NEXT

         cTmp += "+"

         ? cTmp

      ELSE

         // 1 red
         cTmp := "+"
         cTmp += Replicate( "+", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += Replicate( "+", 25 )

         FOR nII := 1 TO 3
            cTmp += "+"
            cTmp += Replicate( "+", Len( PICPIC ) )
         NEXT

         cTmp += "+"

         ? cTmp


         // 2 red

         cTmp := "+"
         cTmp += PadC( "SIFRA", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += _f_text( " ", 25 )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( " ", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp

         // 3 red

         cTmp := "+"
         cTmp += PadC( "PARTN.", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += _f_text( "NAZIV PARTNERA", 25 )
         cTmp += "+"
         cTmp += _f_text( "U VALUTI", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "VAN VAL.", Len( PICPIC ) )
         cTmp += "+"
         cTmp += _f_text( "UKUPNO", Len( PICPIC ) )
         cTmp += "+"

         ? cTmp

         // 4 red
         cTmp := "+"
         cTmp += REPL( "+", FIELD_LEN_PARTNER_ID )
         cTmp += "+"
         cTmp += Replicate( "+", 25 )

         FOR nII := 1 TO 3
            cTmp += "+"
            cTmp += Replicate( "+", Len( PICPIC ) )
         NEXT

         cTmp += "+"

         ? cTmp
      ENDIF
   ENDIF

   RETURN .T.


// ---------------------------------------------
// formatiraj tekst ... na nLen
// ---------------------------------------------
STATIC FUNCTION _f_text( cTxt, nLen )
   RETURN PadC( cTxt, nLen )


FUNCTION qqout_sa_x_x( xVal )

   ? "+"
   ?? xVal
   ?? "+"

   RETURN .T.

// -------------------------------------------
// prikaz vrijednosti na izvjestaju
// -------------------------------------------
FUNCTION qqout_sa_x( xVal )

   ?? xVal
   ?? "+"

   RETURN .T.
