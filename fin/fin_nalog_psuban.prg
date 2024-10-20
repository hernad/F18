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

STATIC s_oPDF

MEMVAR M

#define LEN_OPIS 67

/*
   Štampa (su)banalitičkog finansijski nalog
   - ako smo na fin_pripr onda puni psuban sa sadržajem fin_pripr
*/

FUNCTION fin_nalog_stampa_fill_psuban( cNalog12Dnevnik3, lStampa, dDatNal, oNalog, aNaloziObradjeni )

   LOCAL nArr := Select()
   LOCAL aRez := {}
   LOCAL aOpis := {}
   LOCAL lVrstePlacanja
   LOCAL hParams := fin_params()
   LOCAL nColI, i
   LOCAL cIdFirma, cIdVN, cBrNal
   LOCAL b2
   LOCAL nPOk
   LOCAL bZagl

#ifdef F18_DEBUG_FIN_AZUR

   AltD() // F18_DEBUG_FIN_AZUR
#endif

   IF aNaloziObradjeni == NIL
      aNaloziObradjeni := {}
   ENDIF

   IF lStampa == NIL
      lStampa := .T.
   ENDIF

   IF dDatNal == NIL
      dDatNal := Date()
   ENDIF

   lVrstePlacanja := .F.

   // o_partner()

   PicBHD := "@Z " + FormPicL( gPicBHD, 15 )
   PicDEM := "@Z " + FormPicL( pic_iznos_eur(), 10 )

   M := iif( cNalog12Dnevnik3 == "3", "------ -------------- --- ", "" )
   IF hParams[ "fin_tip_dokumenta" ]
      M +=  + "---- ------- " + REPL( "-", FIELD_LEN_PARTNER_ID ) + " ----------------------------"
      M +=  " -- ------------- ----------- -------- -------- --------------- ---------------"
   ELSE
      M +=  "---- ------- "
      M += REPL( "-", FIELD_LEN_PARTNER_ID ) + " ----------------------------"
      // brdok 20
      M += " " + REPLICATE("-", 20+1) + " -------- -------- --------------- ---------------"
   ENDIF
   M += iif( fin_jednovalutno(), "-", " ---------- ----------" )

   IF cNalog12Dnevnik3 $ "1#2"
      nUkDugBHD := nUkPotBHD := nUkDugDEM := nUkPotDEM := 0
      nStr := 0
   ENDIF


   SELECT ( nArr ) // fin_pripr
   my_flock()

   cIdFirma := field->IdFirma
   cIdVN := field->IdVN
   cBrNal := field->BrNal

   b2 := {|| cIdFirma == field->IdFirma .AND. cIdVN == field->IdVN .AND. cBrNal == field->BrNal }

   IF cNalog12Dnevnik3 $ "1#2" .AND. lStampa
      bZagl := {|| fin_nalog_zaglavlje( dDatNal, cIdFirma, cIdVN, cBrNal ) }
      Eval( bZagl )
   ENDIF


   DO WHILE !Eof() .AND. Eval( b2 )

      Scatter()  // fin_pripr zaokruzenje iznosa na dvije decimale
      _iznosbhd := Round( _iznosbhd, 2 )
      _iznosdem := Round( _iznosdem, 2 )
      Gather()

      IF oNalog != NIL
         oNalog:addStavka( field->datDok )
      ENDIF

      IF lStampa

         // IF PRow() > 61 + iif( cNalog12Dnevnik3 == "3", -7, 0 ) + dodatni_redovi_po_stranici()
         IF cNalog12Dnevnik3 == "3" // dnevnik naloga
            fin_stampa_prenos_na_sljedecoj_strani()
            fin_nalog_zaglavlje( dDatnal, cIdFirma, cIdVN, cBrNal )
         ELSE
            check_nova_strana( bZagl, s_oPDF )
            // Eval(bZagl)
         ENDIF

         // ENDIF
         // P_NRED
         ?

         IF cNalog12Dnevnik3 == "3"
            @ PRow(), 0 SAY Str( ++nRBrDN, 6 )
            @ PRow(), PCol() + 1 SAY cIdFirma + "-" + cIdVN + "-" + cBrNal
            @ PRow(), PCol() + 1 SAY " " + Left( DToC( dDatNal ), 2 )
            @ PRow(), PCol() + 1 SAY RBr
         ELSE
            @ PRow(), 1 SAY RBr PICT "9999"
         ENDIF

         @ PRow(), PCol() + 1 SAY IdKonto

         _kto_naz := ""
         _part_naz := ""
         _part_naz2 := ""

         IF !Empty( IdPartner )

            IF gVSubOp == "D"

               IF select_o_konto( ( nArr )->idkonto )
                  _kto_naz := konto->naz
               ENDIF

               IF select_o_partner( ( nArr )->idpartner )
                  _part_naz := partn->naz
                  _part_naz2 := partn->naz2
               ENDIF

               cStr := Trim( _kto_naz ) + " (" + Trim( Trim( _part_naz ) + " " + Trim( _part_naz2 ) ) + ")"

            ELSE

               IF select_o_partner( ( nArr )->idpartner )
                  _part_naz := partn->naz
                  _part_naz2 := partn->naz2
               ENDIF

               cStr := Trim( _part_naz ) + " " + Trim( _part_naz2 )

            ENDIF
         ELSE

            IF select_o_konto( ( nArr )->idkonto )
               _kto_naz := konto->naz
            ENDIF

            cStr := _kto_naz

         ENDIF

         SELECT ( nArr )

         aRez := SjeciStr( cStr, 28 ) // konto partner
         cStr := opis
         aOpis := SjeciStr( cStr, LEN_OPIS )


         @ PRow(), PCol() + 1 SAY Idpartner( idpartner ) // šifra partnera
         nColStr := PCol() + 1


         @  PRow(), PCol() + 1 SAY PadR( aRez[ 1 ], 28 )
         nColDok := PCol() + 1

         IF hParams[ "fin_tip_dokumenta" ]

            @ PRow(), PCol() + 1 SAY IdTipDok
            select_o_tdok( ( nArr )->idtipdok )
            @ PRow(), PCol() + 1 SAY PadR( naz, 13 )

            SELECT ( nArr )
            @ PRow(), PCol() + 1 SAY PadR( BrDok, 20+1 )

         ELSE
            @ PRow(), PCol() + 1 SAY PadR( BrDok, 20+1 )
         ENDIF

         @ PRow(), PCol() + 1 SAY DatDok
         IF gDatVal == "D"
            @ PRow(), PCol() + 1 SAY get_datval_field()
         ELSE
            @ PRow(), PCol() + 1 SAY Space( 8 )
         ENDIF
         s_nColIzn := PCol() + 1

      ENDIF

      IF D_P == "1"
         IF lStampa
            @ PRow(), PCol() + 1 SAY IznosBHD PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicBHD
         ENDIF
         nUkDugBHD += IznosBHD
         IF cNalog12Dnevnik3 == "3"
            nTSDugBHD += IznosBHD
         ENDIF

      ELSE

         IF lStampa
            @ PRow(), PCol() + 1 SAY 0 PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY IznosBHD PICTURE PicBHD
         ENDIF
         nUkPotBHD += IznosBHD
         IF cNalog12Dnevnik3 == "3"
            nTSPotBHD += IznosBHD
         ENDIF

      ENDIF

      IF fin_dvovalutno()

         IF D_P == "1"
            IF lStampa
               @ PRow(), PCol() + 1 SAY IznosDEM PICTURE PicDEM
               @ PRow(), PCol() + 1 SAY 0 PICTURE PicDEM
            ENDIF
            nUkDugDEM += IznosDEM
            IF cNalog12Dnevnik3 == "3"
               nTSDugDEM += IznosDEM
            ENDIF

         ELSE

            IF lStampa
               @ PRow(), PCol() + 1 SAY 0 PICTURE PicDEM
               @ PRow(), PCol() + 1 SAY IznosDEM PICTURE PicDEM
            ENDIF
            nUkPotDEM += IznosDEM
            IF cNalog12Dnevnik3 == "3"
               nTSPotDEM += IznosDEM
            ENDIF
         ENDIF

      ENDIF

      IF lStampa

         nPok := 0
         FOR i := 2 TO Max( Len( aRez ), Len( aOpis ) + 1 )
            IF i <= Len( aRez )
               @ PRow() + 1, nColStr SAY aRez[ i ]
            ELSE
               nPok := 1
            ENDIF

            @ PRow() + nPok, nColDok SAY iif( i - 1 <= Len( aOpis ), aOpis[ i - 1 ], Space( LEN_OPIS ) )
            IF i == 2 .AND. ( !Empty( k1 + k2 + k3 + k4 ) .OR. gFinRj == "D" .OR. gFinFunkFond == "D" )
               ?? " " + k1 + "-" + k2 + "-" + K3Iz256( k3 ) + "-" + k4
               IF lVrstePlacanja
                  ?? "(" + get_vrstep_naz( k4 ) + ")"
               ENDIF
               IF gFinRj == "D"
                  ?? " RJ:", idrj
               ENDIF
               IF gFinFunkFond == "D"
                  ?? "    Funk:", Funk
                  ?? "    Fond:", Fond
               ENDIF
            ENDIF
         NEXT

      ENDIF

      IF cNalog12Dnevnik3 == "1" .AND. AScan( aNaloziObradjeni, cIdFirma + cIdVN + cBrNal ) == 0

         SELECT ( nArr ) // fin_pripr
         Scatter()
         SELECT PSUBAN
         APPEND BLANK   // fin_pripr - > psuban
         Gather()

      ENDIF

      SELECT ( nArr )
      SKIP 1
   ENDDO

   my_unlock()

   IF cNalog12Dnevnik3 $ "1#2" .AND. lStampa

      // IF PRow() > 58 + dodatni_redovi_po_stranici()
      // FF
      // fin_nalog_zaglavlje( dDatNal, cIdFirma, cIdVN, cBrNal )
      // ENDIF
      // Eval( bZagl )
      check_nova_strana( bZagl, s_oPDF, .F., 5 )

      P_NRED
      ?? M
      P_NRED

      ?? "Z B I R   N A L O G A:"
      @ PRow(), s_nColIzn  SAY nUkDugBHD PICTURE picBHD
      @ PRow(), PCol() + 1 SAY nUkPotBHD PICTURE picBHD

      IF fin_dvovalutno()
         @ PRow(), PCol() + 1 SAY nUkDugDEM PICTURE picDEM
         @ PRow(), PCol() + 1 SAY nUkPotDEM PICTURE picDEM
      ENDIF

      P_NRED
      ?? M

      nUkDugBHD := nUKPotBHD := nUkDugDEM := nUKPotDEM := 0

      IF gPotpis == "D"
         IF PRow() > 58 + dodatni_redovi_po_stranici()
            FF
            fin_nalog_zaglavlje( dDatNal, cIdFirma, cIdVN, cBrNal )
         ENDIF
         // P_NRED
         // P_NRED
         // F12CPI
         // P_NRED
         ?
         ?
         ?
         @ PRow(), 55 SAY "Obrada AOP "; ?? Replicate( "_", 20 )
         ?
         // P_NRED
         @ PRow(), 55 SAY "Kontirao   "; ?? Replicate( "_", 20 )
      ENDIF
      // FF

   ELSEIF cNalog12Dnevnik3 == "3" // glavna knjiga
      IF PRow() > 54 + dodatni_redovi_po_stranici()
         fin_stampa_prenos_na_sljedecoj_strani()
      ENDIF
   ENDIF

   RETURN .T.



/*
       Zaglavlje (sub)analitickog naloga
*/

FUNCTION fin_nalog_zaglavlje( dDatNal, cIdFirma, cIdVN, cBrNal )

   LOCAL nArr, lDnevnik := is_stampa_dnevnika_naloga()
   LOCAL hParams := fin_params()
   LOCAL cTmp

   // IF "DNEVNIKN" == PadR( Upper( ProcName( 1 ) ), 8 ) .OR. "DNEVNIKN" == PadR( Upper( ProcName( 2 ) ), 8 )
   // lDnevnik := .T.
   // ENDIF


   ?
   IF hParams[ "fin_tip_dokumenta" ] .AND. fin_dvovalutno()
      //P_COND2
   ELSE
      //P_COND
   ENDIF

   //B_ON

   ?? Upper( tip_organizacije() ) + ":", self_organizacija_naziv()
   ?
   nArr := Select()

   IF hParams[ "fin_tip_dokumenta" ]
      select_o_partner( cIdfirma )
      SELECT ( nArr )
      ? cIdfirma, "-", AllTrim( partn->naz )
   ENDIF

   ?
   IF lDnevnik
      ?U "FIN:      D N E V N I K    K NJ I Ž E NJ A    Z A    " + ;
         Upper( NazMjeseca( Month( dDatNal ) ) ) + " " + Str( Year( dDatNal ) ) + ". GODINE"
   ELSE
      ?U "FIN: NALOG ZA KNJIŽENJE BROJ :"
      @ PRow(), PCol() + 2 SAY cIdFirma + " - " + cIdVn + " - " + cBrNal
   ENDIF

   //B_OFF
   IF gDatNal == "D" .AND. !lDnevnik
      @ PRow(), PCol() + 4 SAY "DATUM: "
      ?? dDatNal
   ENDIF

   IF !lDnevnik
      select_o_tnal( cIdVN )
      @ PRow(), PCol() + 4 SAY tnal->naz
   ENDIF

   @ PRow(), PCol() + 15 SAY "Str:" + Str( ++nStr, 4 )

   //P_NRED
   ?

   ?? M

   IF !hParams[ "fin_tip_dokumenta" ]
      //P_NRED
      ?
      cTmp := iif( lDnevnik, "R.BR. *   BROJ   *DAN*", "" ) + "*R. * KONTO *" + PadC( "PART", FIELD_LEN_PARTNER_ID )
      cTmp +=  "*" + "    NAZIV PARTNERA ILI      "  + "*        D  O  K  U  M  E  N  T         *         IZNOS U  " + valuta_domaca_skraceni_naziv() + "         *"
      cTmp += iif( fin_jednovalutno(), "", "    IZNOS U " + ValPomocna() + "        *" )
      ??U cTmp
      ?

      cTmp := iif( lDnevnik, "U DNE-*  NALOGA  *   *", "" ) + "             " + PadC( "NER", FIELD_LEN_PARTNER_ID ) + " "
      cTmp += "                             " +  REPLICATE("-", 20) + "------------------- -------------------------------- "
      cTmp += iif( fin_jednovalutno(), "", "---------------------" )
      ??U cTmp
      //P_NRED
      ?

      cTmp := iif( lDnevnik, "VNIKU *          *   *", "" ) + "*BR *       *" + REPL( " ", FIELD_LEN_PARTNER_ID ) + "*"
      cTmp += "    NAZIV KONTA             "  + "*      BROJ VEZE      * DATUM  * VALUTA *  DUGUJE " + valuta_domaca_skraceni_naziv() + "  * POTRAŽUJE " + valuta_domaca_skraceni_naziv() + "*"
      cTmp += iif( fin_jednovalutno(), "", " DUG. " + ValPomocna() + "* POT." + ValPomocna() + "*" )
      ??U cTmp

   ELSE
      //P_NRED
      ?

      cTmp := iif( lDnevnik, "R.BR. *   BROJ   *DAN*", "" ) + "*R.   * KONTO *" + PadC( "PART", FIELD_LEN_PARTNER_ID ) + "*"
      cTmp += "    NAZIV PARTNERA ILI      "  + "*           D  O  K  U  M  E  N  T             *         IZNOS U  " + valuta_domaca_skraceni_naziv() + "         *"
      cTmp += iif( fin_jednovalutno(), "", "    IZNOS U " + ValPomocna() + "    *" )
      ??U cTmp
      //P_NRED
      ?

      cTmp := iif( lDnevnik, "U DNE-*  NALOGA  *   *", "" ) + "               " + PadC( "NER", FIELD_LEN_PARTNER_ID ) + " "
      cTmp += "                             " + REPLICATE("-", 20)  + "------------------------------------ -------------------------------- "
      cTmp += iif( fin_jednovalutno(), "", "---------------------" )
      ??U cTmp
      //P_NRED
      ?

      cTmp := iif( lDnevnik, "VNIKU *          *   *", "" ) + "*BR   *       *" + REPL( " ", FIELD_LEN_PARTNER_ID ) + "*"
      cTmp += "    NAZIV KONTA             " + "*  TIP I NAZIV   *      BROJ VEZE      * DATUM  * VALUTA *  DUGUJE " + valuta_domaca_skraceni_naziv() + "  * POTRAŽUJE " + valuta_domaca_skraceni_naziv() + "*"
      cTmp +=  iif( fin_jednovalutno(), "", " DUG. " + ValPomocna() + "* POT." + ValPomocna() + "*" )
      ??U cTmp

   ENDIF

   //P_NRED
   ?
   ?? M

   Select( nArr )

   RETURN .T.




/*
   filovanje potrebnih tabela kod auto importa
*/
FUNCTION fin_gen_psuban_stavke_auto_import()

   LOCAL b2
   LOCAL cIdFirma, cIdVN, cBrNal

   my_close_all_dbf()

   o_fin_pripr()
   // o_konto()
   // o_partner()
   // o_tnal()
   // o_tdok()
   o_fin_psuban()

   SELECT PSUBAN
   my_dbf_zap()

   SELECT fin_pripr
   SET ORDER TO TAG "1"
   GO TOP

   IF Eof()
      my_close_all_dbf()
      RETURN .F.
   ENDIF

   DO WHILE !Eof()

      cIdFirma := fin_pripr->IdFirma
      cIdVN := fin_pripr->IdVN
      cBrNal := fin_pripr->BrNal

      b2 := {|| cIdFirma == field->IdFirma .AND. cIdVN == field->IdVN .AND. cBrNal == field->BrNal }

      DO WHILE !Eof() .AND. Eval( b2 )

         SELECT PSUBAN
         Scatter()
         SELECT fin_pripr
         Scatter()

         SELECT PSUBAN
         APPEND BLANK
         Gather()

         SELECT fin_pripr
         SKIP

      ENDDO

   ENDDO

   my_close_all_dbf()

   RETURN .T.


FUNCTION fin_nalog_set_pdf( oPDF )

   s_oPDF := oPDF

   RETURN .T.
