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

STATIC LEN_TRAKA := 40
STATIC LEN_RAZMAK := 1
STATIC PIC_UKUPNO := "9999999.99"
STATIC s_oPDF

FUNCTION realizacija_kase

   PARAMETERS fZaklj, dDatum0, dDatum1, cVarijanta
   LOCAL xPrintOpt
   LOCAL bZagl

   PRIVATE cIdOdj := Space( 2 )
   PRIVATE cRadnici := Space( 60 )
   PRIVATE cVrsteP := Space( 60 )
   PRIVATE cSmjena := Space( 1 )
   PRIVATE cIdPos := gIdPos
   PRIVATE cRD

   // PRIVATE cIdDio := gIdDio
   PRIVATE aNiz
   PRIVATE aUsl1 := {}
   PRIVATE aUsl2 := {}
   PRIVATE fPrik := "O"
   PRIVATE cFilter := ".t."
   PRIVATE cSifraDob := Space( 8 )
   PRIVATE cPartId := Space( 8 )

   IF fZaklj == nil
      fZaklj := .F.
   ENDIF

   SET CURSOR ON

   cK1 := "N"

   IF fZaklj
      cPVrstePl := "D"
   ENDIF

   IF ( dDatum0 == NIL )
      dDatum0 := danasnji_datum()
      dDatum1 := danasnji_datum()
   ENDIF

   IF ( cVarijanta == NIL )
      cVarijanta := "0"
   ELSEIF ( cVarijanta == "2" )
      cVarijanta := "0"
      cK1 := "D"
   ENDIF

   pos_realizacija_tbl_cre_pom()
   o_pos_tables()
   o_pom_table()

   cPVrstePl := "N"
   cAPrometa := "N"
   cVrijOd := "00:00"
   cVrijDo := "23:59"
   cGotZir := " "

   // IF fZaklj
   // cK1 := "N"
   // cIdPos := gIdPos
   // dDatum0 := dDatum1 := danasnji_datum()
   // cSmjena := gSmjena
   // cRD := "R"
   // cVrijOd := "00:00"
   // cVrijDo := "23:59"
   // aUsl1 := ".t."
   // aUsl2 := ".t."
   // ELSE


   IF pos_get_vars_izvjestaj_realizacija( @cK1, @cIdPos, @dDatum0, @dDatum1, @cSmjena, @cRD, @cVrijOd, @cVrijDo, @aUsl1, @aUsl2, @cVrsteP, @cAPrometa, @cGotZir, @cSifraDob, @cPartId ) == 0
      RETURN 0
   ENDIF


   s_oPDF := PDFClass():New()
   xPrintOpt := hb_Hash()
   xPrintOpt[ "tip" ] := "PDF"
   xPrintOpt[ "layout" ] := "portrait"
   xPrintOpt[ "opdf" ] := s_oPDF
   xPrintOpt[ "font_size" ] := 9
   IF f18_start_print( NIL, xPrintOpt,  "POS REALIZACIJA NA DAN: " + DToC( Date() ) ) == "X"
      RETURN .F.
   ENDIF

   // IF fZaklj
   // STARTPRINTPORT CRET gLocPort, .F.

   // pos_zagl_realizacijaZ( dDatum0, dDatum1, cIdPos, cSmjena, cRadnici, cVrsteP, cIdOdj )
   // ELSE
   bZagl := {|| pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cSmjena, cRadnici, cVrsteP, cIdOdj, cGotZir ) }

   Eval( bZagl )
   // ENDIF // fZaklj

   o_pos_tables()
   o_pom_table()

   SELECT pos_doks

   pos_set_filter_pos_doks( @cFilter, aUsl1, aUsl2, cVrijOd, cVrijDo, cGotZir, cPartId )

   // fZaklj - zakljucenje smjene
   // IF !fZaklj
   pos_kasa_pripremi_pom_za_izvjestaj( "01", cSifraDob )
   // ENDIF

   pos_kasa_pripremi_pom_za_izvjestaj( "42", cSifraDob )

   PRIVATE nTotal := 0

   // Nenaplaceno ili Popust (zavisno od varijante)
   PRIVATE nTotal3 := 0

   IF ( cRD $ "RB" )

      SELECT POM
      SET ORDER TO TAG "1"

      IF ( fPrik $ "PO" )
         check_nova_strana( bZagl, s_oPDF )
         pos_realizacija_po_radnicima( fPrik, @nTotal3 )
      ENDIF

   ENDIF

   IF ( cRD $ "OB" )
      check_nova_strana( bZagl, s_oPDF )
      pos_realizacija_po_odjeljenjima( fPrik, @nTotal3 )
   ENDIF

   check_nova_strana( bZagl, s_oPDF )

   pos_pdv_po_tarifama( dDatum0, dDatum1, cIdPos, NIL, cIdodj )

   // IF Round( Abs( nTotal3 ), 4 ) <> 0
   // check_nova_strana( bZagl, s_oPDF )
   // pos_pdv_po_tarifama( dDatum0, dDatum1, cIdPos, "3" )  // STA JE OVO? => APOTEKE!!
   // ENDIF

   // ENDIF

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_get_vars_izvjestaj_realizacija( cK1, cIdPos, dDatum0, dDatum1, cSmjena, cRD, cVrijOd, cVrijDo, aUsl1, aUsl2, cVrsteP, cAPrometa, cGotZir, cSifraDob, cPartId )

   LOCAL aNiz

   aNiz := {}
   cIdPos := gIdPos


   AAdd( aNiz, { "Prod. mjesto (prazno-sve)", "cIdPos", "cidpos='X'.or.EMPTY(cIdPos) .or. p_pos_kase(@cIdPos)", "@!", } )
   AAdd( aNiz, { "Radnici (prazno-svi)", "cRadnici",, "@!S30", } )
   AAdd( aNiz, { "Vrste placanja (prazno-sve)", "cVrsteP",, "@!S30", } )

   AAdd( aNiz, { "Izvjestaj se pravi od datuma", "dDatum0",,, } )
   AAdd( aNiz, { "                   do datuma", "dDatum1",,, } )
   AAdd( aNiz, { "Smjena (prazno-sve)", "cSmjena",,, } )
   fPrik := "O"
   AAdd( aNiz, { "Prikazati Pazar/Robe/Oboje (P/R/O)?", "fPrik", "fPrik$'PRO'", "@!", } )
   cRD := "R"

   IF cK1 == "D"
      cRd := "O"
   ELSE
      AAdd( aNiz, { "Po Radnicima/Odjeljenjima/oBoje (R/O/B)?", "cRD", "cRD$'ROB'", "@!", } )
   ENDIF

   AAdd( aNiz, { "Prikazati pregled po vrstama placanja ?", "cPVrstePl", "cPVrstePl$'DN'", "@!", } )
   AAdd( aNiz, { "Vrijeme od", "cVrijOd",, "99:99", } )
   AAdd( aNiz, { "Vrijeme do", "cVrijDo", "cVrijDo>=cVrijOd", "99:99", } )

   IF gPVrsteP
      AAdd( aNiz, { "Izvrsiti azuriranje tabele prometa prodavnice (D/N)", "cAPrometa", "cAPrometa$'DN'", "@!", } )
   ENDIF

   AAdd( aNiz, { "Dobavljac (prazno-svi)", "cSifraDob", ".t.",, } )
   AAdd( aNiz, { "Partner (prazno-svi)", "cPartId", ".t.",, } )

   DO WHILE .T.
      IF cVarijanta <> "1"  // onda nema read-a
         IF !VarEdit( aNiz, 6, 5, 24, 74, "USLOVI ZA IZVJESTAJ: REALIZACIJA KASE-PRODAJNOG MJESTA", "B1" )
            CLOSE ALL
            RETURN 0
         ENDIF
      ENDIF
      aUsl1 := Parsiraj( cRadnici, "IdRadnik" )
      aUsl2 := Parsiraj( cVrsteP, "IdVrsteP" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL .AND. dDatum0 <= dDatum1
         EXIT
      ELSEIF aUsl1 == nil
         Msg( "Kriterij za radnike nije korektno postavljen!" )
      ELSEIF aUsl2 == nil
         Msg( "Kriterij za vrste placanja nije korektno postavljen!" )
      ELSE
         Msg( "'Datum do' ne smije biti stariji od 'datum od'!" )
      ENDIF

   ENDDO

   RETURN 1


STATIC FUNCTION pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cSmjena, cRadnici, cVrsteP, cIdOdj, cGotZir )

   // ?? gP12CPI

   // IF glRetroakt
   // ? PadC( "REALIZACIJA NA DAN " + FormDat1( dDatum1 ), LEN_TRAKA )
   // ELSE
   // ? PadC( "REALIZACIJA NA DAN " + FormDat1( danasnji_datum() ), LEN_TRAKA )
   // ENDIF

   // ? PadC( "-------------------------------------", LEN_TRAKA )

   IF Empty( cIdPos )
      IF ( grbReduk < 2 )
         ? "PRODAJNO MJESTO: SVA"
      ENDIF
   ELSE
      ? "PRODAJNO MJESTO: " + cIdPos + "-" + find_pos_kasa_naz( cIdPos )
   ENDIF

   IF Empty( cRadnici )
      IF ( grbReduk < 2 )
         ? "RADNIK     :  SVI"
      ENDIF
   ELSE
      ? "RADNIK     : " + cRadnici + "-" + RTrim( find_pos_osob_naziv( cRadnici ) )
   ENDIF

   IF Empty( cVrsteP )
      IF ( grbReduk < 2 )
         ?U "VR.PLAĆANJA: SVE"
      ENDIF
   ELSE
      ?U "VR.PLAĆANJA: " + RTrim( cVrsteP )
   ENDIF

   IF Empty( cGotZir )
      IF ( grbReduk < 2 )
         ? "PLACANJE: gotovinsko i ziralno"
      ENDIF
   ELSE
      ?U "PLAĆANJE: " + IF( cGotZir <> "Z", "gotovinsko", "ziralno" )
   ENDIF


   ? "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )

   IF Empty( cSmjena )
      IF ( grbReduk < 2 )
         ? "SMJENA     : SVE"
      ENDIF
   ELSE
      ? "SMJENA     : " + cSmjena
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_set_filter_pos_doks( cFilter, aUsl1, aUsl2, cVrijOd, cVrijDo, cGotZir, cPartId )

   SELECT pos_doks
   SET ORDER TO TAG "2"  // "2" - "IdVd+DTOS (Datum)+Smjena"

   IF aUsl1 <> ".t."
      cFilter += ".and." + aUsl1
   ENDIF

   IF aUsl2 <> ".t."
      cFilter += ".and." + aUsl2
   ENDIF

   IF !( cVrijOd == "00:00" .AND. cVrijDo == "23:59" )
      cFilter += ".and. Vrijeme>='" + cVrijOd + "'.and. Vrijeme<='" + cVrijDo + "'"
   ENDIF

   IF !Empty( cGotZir )
      IF cGotZir == "Z"
         cFilter += ".and. placen=='Z'"
      ELSE
         cFilter += ".and. placen<>'Z'"
      ENDIF
   ENDIF

   IF !Empty( cPartId )
      cFilter += ".and. idPartner==" + dbf_quote( cPartId )
   ENDIF

   IF !( cFilter == ".t." )
      SET FILTER TO &cFilter
   ENDIF

   RETURN .T.


STATIC FUNCTION pos_zagl_realizacijaZ( dDatum0, dDatum1, cIdPos, cSmjena, cRadnici, cVrsteP, cIdOdj )

   ?
   ?? PadC( "ZAKLJUCENJE KASE", LEN_TRAKA )
   ? PadC( gPosNaz )


   // IF gVSmjene == "D"
   // ? PadC( FormDat1( danasnji_datum() ) + " Smjena: " + gSmjena, LEN_TRAKA )
   // ELSE
   ? PadC( FormDat1( danasnji_datum() ), LEN_TRAKA )
   // ENDIF
   ?

   RETURN .T.



FUNCTION pos_realizacija_po_vrstama_placanja()

   // Rekapitulacija vrsta placanja

   LOCAL nTotal
   LOCAL nTotal3
   LOCAL nTotPos
   LOCAL nTotPos3
   LOCAL nTotVP
   LOCAL nTotVP2
   LOCAL nTotVP3

   ?
   ? PadC( "REKAPITULACIJA PO VRSTAMA PLACANJA", LEN_TRAKA )
   ? PadC( "------------------------------------", LEN_TRAKA )
   ?
   ? Space( 5 ) + PadR( "Naziv vrste p.", 20 ), PadC( "Iznos", 14 )
   ? Space( 5 ) + Replicate( "-", 20 ), Replicate( "-", 14 )

   nTotal := 0
   nTotal3 := 0

   SELECT POM
   SET ORDER TO TAG "4"
   GO TOP

   DO WHILE !Eof()

      _IdPos := pom->IdPos

      IF Empty( cIdPos )
         select_o_pos_kase( _IdPos )
         ?
         ? Replicate( "-", LEN_TRAKA )
         ? Space( 1 ) + _IdPos + ":", + kase->Naz
         ? Replicate( "-", LEN_TRAKA )
      ENDIF

      nTotPos := 0
      nTotPos3 := 0

      DO WHILE !Eof() .AND. pom->IdPos == _IdPos
         nTotVP := 0
         nTotVP2 := 0
         nTotVP3 := 0
         _IdVrsteP := pom->IdVrsteP
         select_o_vrstep( _IdVrsteP )
         ? Space( 5 ) + vrstep->Naz
         SELECT pom
         DO WHILE !Eof() .AND. pom->( IdPos + IdVrsteP ) == ( _IdPos + _IdVrsteP )
            nTotVP += pom->Iznos
            nTotVP2 += pom->Iznos2
            nTotVP3 += pom->Iznos3
            SKIP
         ENDDO
         ?? Str( nTotVP, 14, 2 )
         nTotPos += nTotVP
         nTotPos3 += nTotVP3
      ENDDO

      pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "N", "-" )

      nTotal += nTotPos
      nTotal3 += nTotPos3

   ENDDO

   IF Empty( cIdPos )

      ? REPL ( "=", LEN_TRAKA )
      ? PadC ( "SVE KASE", 20 ) + Str ( nTotal, 20, 2 )
      ? REPL ( "=", LEN_TRAKA )

   ENDIF

   RETURN .T.




STATIC FUNCTION pos_realizacija_po_radnicima()

   ?
   ? "SIFRA PREZIME I IME RADNIKA"
   ? "-----", Replicate( "-", 34 )

   nTotal := 0
   nTotal3 := 0

   SELECT pom
   GO TOP

   DO WHILE !Eof()
      nTotPos := 0
      nTotPos3 := 0
      _IdPos := pom->IdPos
      DO WHILE !Eof() .AND. pom->IdPos == _IdPos
         nTotRadn := 0
         nTotRadn3 := 0
         _IdRadnik := pom->IdRadnik
         find_pos_osob_by_naz( _IdRadnik )
         SELECT pom
         ? IdRadnik + "  " + PadR( osob->Naz, 34 )
         ? Replicate( "-", 5 ), Replicate( "-", 34 )
         DO WHILE !Eof() .AND. pom->( IdPos + IdRadnik ) == ( _IdPos + _IdRadnik )
            nTotVP := 0
            nTotVP3 := 0
            _IdVrsteP := pom->IdVrsteP
            select_o_vrstep( _IdVrsteP )
            SELECT pom
            ? Space( 6 ) + PadR( vrstep->Naz, 20 )
            DO WHILE !Eof() .AND. pom->( IdPos + IdRadnik + IdVrsteP ) == ( _IdPos + _IdRadnik + _IdVrsteP )
               nTotVP += pom->Iznos
               nTotVP3 += pom->Iznos3
               SKIP
            ENDDO
            ?? Str( nTotVP, 14, 2 )
            nTotRadn += nTotVP
            nTotRadn3 += nTotVP3
         ENDDO // radnik
         ? Space( 6 ) + Replicate( "-", 34 )
         ? Space( 6 ) + PadL( "UKUPNO", 20 ) + Str( nTotRadn, 14, 2 )

         IF nTotRadn3 <> 0
            ? Space( 6 ) + PadL( NenapPop(), 20 ) + Str( nTotRadn3, 14, 2 )
            ? Space( 6 ) + PadL( "UKUPNO NAPLATA:", 20 ) + Str( nTotRadn - nTotRadn3, 14, 2 )
         ENDIF
         ? Space( 6 ) + Replicate( "-", 34 )
         nTotPos += nTotRadn
         nTotPos3 += nTotRadn3
      ENDDO  // kasa
      ? Replicate( "-", 40 )
      ? PadC( "UKUPNO KASA " + _IdPos, 20 ) + Str( nTotPos, 20, 2 )

      IF nTotPos3 <> 0
         ? PadL( NenapPop(), 20 ) + Str( nTotPos3, 20, 2 )
         ? PadL( "UKUPNO NAPLATA:", 20 ) + Str( nTotPos - nTotPos3 + nTotPos2, 20, 2 )
      ENDIF
      ? Replicate( "-", 40 )
      nTotal += nTotPos
      nTotal3 += nTotPos3
   ENDDO // ! pom->eof()
   IF Empty( cIdPos )
      ? Replicate( "=", 40 )
      ? PadC( "SVE KASE", 20 ) + Str( nTotal, 20, 2 )
      ? Replicate( "=", 40 )
   ENDIF

   // idemo skupno sa vrstama placanja
   IF cPVrstePl == "D"
      pos_realizacija_po_vrstama_placanja()
   ENDIF

   IF !fZaklj .AND. fPrik $ "RO"
      // ako je zakljucenje NE realizacija po robama

      set_pos_zagl_realizacija()
      nTotal := 0
      nTotal3 := 0

      SELECT POM
      SET ORDER TO TAG "3"
      GO TOP
      DO WHILE !Eof()
         nTotPos := 0
         nTotPos3 := 0
         _IdPos := POM->IdPos
         IF Empty( cIdPos )
            select_o_pos_kase( _IdPos )
            ? REPL ( "-", LEN_TRAKA )
            ? Space( 1 ) + _idpos + ":", + KASE->Naz
            ? REPL ( "-", LEN_TRAKA )
         ENDIF
         SELECT POM

         DO WHILE !Eof() .AND. pom->idPos == _IdPos
            select_o_roba( pom->idRoba )

            cStr1 := ""
            IF grbStId == "D"
               cStr1 += AllTrim( pom->idroba ) + " "
            ENDIF

            cStr1 += AllTrim( roba->naz )
            cStr1 += " (" + AllTrim( roba->jmj ) + ") "
            nLen1 := Len( cStr1 )

            SELECT POM

            _IdRoba := POM->idRoba
            nRobaIzn := 0
            nRobaKol := 0
            nSetova := 0
            nRobaIzn2 := 0
            nRobaIzn3 := 0
            DO WHILE !Eof() .AND. POM->( IdPos + IdRoba ) == ( _IdPos + _IdRoba )
               nKol := 0
               nIzn := 0
               nIzn2 := 0
               nIzn3 := 0
               _IdCijena := POM->IdCijena
               DO WHILE !Eof() .AND. POM->( IdPos + IdRoba + IdCijena ) == ( _IdPos + _IdRoba + _IdCijena )
                  nKol += POM->Kolicina
                  nIzn += POM->Iznos
                  nIzn2 += POM->Iznos2
                  nIzn3 += POM->Iznos3

                  SKIP

               ENDDO

               cStr2 := ""
               cStr2 += show_number( nKol, NIL, - 8 )
               nLen2 := Len( cStr2 )

               cStr3 := show_number( nIzn, PIC_UKUPNO )
               nLen3 := Len( cStr3 )

               aReal := SjeciStr( cStr1, LEN_TRAKA )

               FOR i := 1 TO Len( aReal )
                  ? RTrim( aReal[ i ] )
                  nLenRow := Len( RTrim( aReal[ i ] ) )
               NEXT

               IF  nLen2 + 1 + nLen3 > LEN_TRAKA - nLenRow
                  ? PadL( cStr2 + Space( LEN_RAZMAK ) + cStr3, LEN_TRAKA )
               ELSE
                  ?? PadL( cStr2 + Space( LEN_RAZMAK ) + cStr3, LEN_TRAKA - nLenRow )
               ENDIF

               IF glPorNaSvStRKas
                  pos_prikazi_porez( nIzn, roba->idTarifa )
               ENDIF

               nRobaIzn += nIzn
               nRobaIzn2 += nIzn2
               nRobaIzn3 += nIzn3
               nRobaKol += nKol
               nSetova++
               SELECT POM
            ENDDO
            IF nSetova > 1
               ? PadL( "Ukupno roba ", 16 ), Str( nRobaKol, 10, 3 )
               ?? Transform( nRobaIzn, "999,999,999.99" )
            ENDIF
            nTotPos += nRobaIzn
            nTotPos3 += nRobaIzn3
         ENDDO

         pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "N", "-" )
         nTotal += nTotPos
         nTotal3 += nTotPos3
      ENDDO
      IF Empty( cIdPos )
         ? REPL( "-", LEN_TRAKA )
         ? PadC( "SVE KASE UKUPNO:", 25 ), Transform( nTotal, "999,999,999.99" )
         ? REPL( "-", LEN_TRAKA )
      ENDIF
   ENDIF

   RETURN .T.


STATIC FUNCTION set_pos_zagl_realizacija()

   LOCAL cLinija

   cLinija := Replicate( "-", LEN_TRAKA )

   ?

   IF ( grbReduk < 2 )
      ? cLinija
   ENDIF

   ? PadC( "REALIZACIJA PO ROBAMA", LEN_TRAKA )

   IF ( grbReduk < 2 )
      ? cLinija
   ENDIF

   ?

   cStr1 := ""

   IF grbStId == "D"
      cStr1 += "Sifra, naziv, jmj, kolicina"
   ELSE
      cStr1 += "Naziv, jmj, kolicina"
   ENDIF

   cHead := cStr1 + PadL( "vrijednost", LEN_TRAKA - Len( cStr1 ) )

   ? cHead

   ? cLinija

   RETURN


/* pos_realizacija_po_odjeljenjima(fPrik, nTotal3)
 *     Prikaz realizacije po odjeljenjima
 */

STATIC FUNCTION pos_realizacija_po_odjeljenjima( fPrik, nTotal3 )

   IF ( fPrik $ "PO" )
      // daj mi pazar
      ?
      IF cK1 == "D"
         ? PadC( "PROMET PO GRUPAMA", LEN_TRAKA )
      ELSE
         ? PadC( "PROMET PO ODJELJENJIMA", LEN_TRAKA )
      ENDIF
      ? PadC( "------------------------------------", LEN_TRAKA )
      ?
      ? "Sifra Naziv odjeljenja          IZNOS"
      ? "----- ----------------------- ----------"
      // 0123456789012345678901234567890123456789
      nTotal := 0
      nTotal3 := 0
      SELECT POM
      SET ORDER TO TAG "2"
      GO TOP
      WHILE !Eof()
         _IdPos := pom->IdPos
         IF Empty( cIdPos )
            select_o_pos_kase( _IdPos )
            ? REPL( "-", LEN_TRAKA )
            ? Space( 1 ) + _idpos + ":", KASE->Naz
            ? REPL( "-", LEN_TRAKA )
            SELECT POM
         ENDIF
         nTotPos := 0
         nTotPos3 := 0
         DO WHILE ( !Eof() .AND. pom->IdPos == _IdPos )
            nTotOdj := 0
            nTotOdj3 := 0
            _IdOdj := POM->IdOdj

            SELECT POM
            DO WHILE !Eof() .AND. pom->( IdPos + IdOdj ) == ( _IdPos + _IdOdj )
               nTotOdj += pom->Iznos
               nTotOdj3 += pom->Iznos3
               SKIP
            ENDDO
            ?? Transform( nTotOdj, "999,999.99" )
            nTotPos += nTotOdj
            nTotPos3 += nTotOdj3
         ENDDO
         pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "N", "-" )
         nTotal += nTotPos
         nTotal3 += nTotPos3
      ENDDO
      IF Empty( cIdPos )
         ? REPL( "=", LEN_TRAKA )
         ? PadC( "SVE KASE UKUPNO", 25 ) + Transform( nTotal, "999,999,999.99" )
         ? REPL( "=", LEN_TRAKA )
      ENDIF
   ENDIF

   IF ( fPrik $ "RO" ) .OR. cK1 == "D"
      // realizacija kase, po odjeljenjima, ROBNO
      nTotal := 0
      SELECT POM
      IF cK1 == "D"
         SET ORDER TO TAG "K1"   // IdPos+IdOdj+IdRoba+IdCijena
      ELSE
         SET ORDER TO TAG "2"   // IdPos+IdOdj+IdRoba+IdCijena
      ENDIF
      GO TOP
      DO WHILE !Eof()
         _IdPos := POM->IdPos
         IF Empty( cIdPos )
            select_o_pos_kase( _IdPos )
            ? REPL( "-", LEN_TRAKA )
            ? Space( 1 ) + _idpos + ":", KASE->Naz
            ? REPL( "-", LEN_TRAKA )
            SELECT POM
         ENDIF
         nTotPos := 0
         nTotPos3 := 0
         nTotPosK := 0
         DO WHILE !Eof() .AND. pom->IdPos == _IdPos
            IF cK1 == "D"
               _IdOdj := pom->k1
               bOdj := {|| pom->k1 }
            ELSE
               _IdOdj := POM->IdOdj
               bOdj := {|| pom->idodj }
            ENDIF
            ? Replicate ( "-", LEN_TRAKA )
            ? "SIFRA    NAZIV", Space ( 19 ), "(JMJ)"
            ? Space( 10 ) + "Set c.  Kolicina    Vrijednost"
            ? Replicate( "-", LEN_TRAKA )
            nTotOdj := 0
            nTotOdj3 := 0
            nTotOdjK := 0
            SELECT POM
            DO WHILE !Eof() .AND. POM->( IdPos ) + Eval( bOdj ) == ( _IdPos + _IdOdj )
               _IdRoba := POM->IdRoba
               select_o_roba( _IdRoba )
               ? _IdRoba, Left( ROBA->Naz, 25 ), "(" + ROBA->Jmj + ")"
               IF cK1 == "D"
                  _K2 := roba->k2
                  IF roba->tip $ "TU"  // usluge ili tarife
                     _K2 := "X"
                  ENDIF
               ELSE
                  _K2 := ""
               ENDIF
               SELECT POM
               nRobaIzn := 0
               nRobaIzn2 := 0
               nRobaIzn3 := 0
               nRobaKol := 0
               nSetova := 0
               DO WHILE !Eof() .AND. pom->idPos + Eval( bOdj ) + pom->IdRoba == ( _IdPos + _IdOdj + _IdRoba )
                  _IdCijena := POM->IdCijena
                  nKol := 0
                  nIzn := 0
                  nIzn3 := 0
                  DO WHILE !Eof() .AND. pom->IdPos + Eval( bOdj ) + pom->( IdRoba + IdCijena ) == ( _IdPos + _IdOdj + _IdRoba + _IdCijena )
                     nKol += POM->Kolicina
                     nIzn += POM->Iznos
                     nIzn3 += POM->Iznos3
                     SKIP
                  ENDDO
                  ? Space( 10 ) + PadC( _IdCijena, 6 ) + Str( nKol, 10, 3 ) + Transform( nIzn, "999,999,999.99" )
                  nRobaIzn += nIzn
                  nRobaKol += nKol
                  nRobaIzn3 += nIzn3
                  nSetova++
                  SELECT POM
               ENDDO
               IF nSetova > 1
                  ? PadL( "Ukupno roba ", 15 ), Str( nRobaKol, 10, 3 ) + Transform( nRobaIzn, "999,999,999.99" )
               ENDIF
               nTotOdj += nRobaIzn
               nTotOdj3 += nRobaIzn3
               IF !( _K2 = "X" )
                  nTotOdjk += nRobaKol
               ENDIF
            ENDDO
            ? REPL( "-", LEN_TRAKA )
            IF cK1 == "D"
               ? PadC( "UKUPNO " + _idodj, 16 )
               ?? Str( nTotOdjk, 10, 2 )
            ELSE
               ? PadC( "UKUPNO ODJELJENJE", 26 )
            ENDIF
            ?? Transform( nTotOdj, "999,999,999.99" )
            ? REPL( "-", LEN_TRAKA )
            ?
            nTotPos += nTotOdj
            nTotPosK += nTotOdjk
         ENDDO

         pos_total_kasa( _IdPos, nTotPos, nTotPos3, nTotPosk, cK1, "=" )
         nTotal += nTotPos
         nTotal3 += nTotPos3
      ENDDO
      IF Empty( cIdPos )
         ? REPL( "*", LEN_TRAKA )
         ? PadC( "SVE KASE UKUPNO", 25 ), Transform( nTotal, "999,999,999.99" )
         ? REPL( "*", LEN_TRAKA )
      ENDIF
   ENDIF

   RETURN .T.



STATIC FUNCTION pos_total_kasa( cIdPos, nTotPos, nTotPos3, nTotPosk, cK1, cPodvuci )

   ? REPL( cPodvuci, LEN_TRAKA )
   IF cK1 == "D"
      ? PadC( "UKUPNO KASA " + _idpos, 16 ), Str( nTotPosK, 10, 2 )
      ?? Transform( nTotPos, "999,999,999.99" )
   ELSE
      ? PadC( "UKUPNO KASA " + _idpos, 25 ), Transform( nTotPos, "999,999,999.99" )
   ENDIF

   IF nTotPos3 <> 0
      ? PadL( NenapPop(), 25 ) + Str( nTotPos3, 15, 2 )
      ? PadL( "UKUPNO NAPLATA:", 25 ) + Str( nTotPos - nTotPos3 + nTotPos2, 15, 2 )
   ENDIF
   ? REPL( cPodvuci, LEN_TRAKA )
   ?

   RETURN .T.



STATIC FUNCTION pos_prikazi_porez( nIznosSt, cIdTarifa )

   LOCAL nArr
   LOCAL nMpVBP, nPPPIznos, nPPIznos, nPPUIznos, nPPP, nPPU

   nArr := Select()

   select_o_tarifa( cIdTarifa )

   nPPP := tarifa->opp
   nPPU := tarifa->ppp

   nMpVBP := nIznosSt / ( zpp / 100 + ( 1 + opp / 100 ) * ( 1 + ppp / 100 ) )
   nPPPIznos := nMPVBP * opp / 100
   nPPIznos := nMPVBP * zpp / 100


   ? Space( 1 ) + "PPP(" + AllTrim( Str( nPPP ) ) + "%) " + AllTrim( Str( nPPPIznos ) )

   nPPUIznos := ( nMPVBP + nPPPIznos ) * ppp / 100

   ?? " PPU(" + AllTrim( Str( nPPU ) ) + "%) " + AllTrim( Str( nPPUIznos ) )

   SELECT ( nArr )

   RETURN .T.


STATIC FUNCTION pos_realizacija_tbl_cre_pom()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IdPos", "C",  2, 0 } )
   AAdd( aDbf, { "IdRadnik", "C",  4, 0 } )
   AAdd( aDbf, { "IdVrsteP", "C",  2, 0 } )
   AAdd( aDbf, { "IdOdj", "C",  2, 0 } )
   AAdd( aDbf, { "IdRoba", "C", 10, 0 } )
   AAdd( aDbf, { "IdCijena", "C",  1, 0 } )
   AAdd( aDbf, { "Kolicina", "N", 12, 3 } )
   AAdd( aDbf, { "Iznos", "N", 20, 5 } )
   AAdd( aDbf, { "Iznos2", "N", 20, 5 } )
   AAdd( aDbf, { "Iznos3", "N", 20, 5 } )
   AAdd( aDbf, { "K1", "C",  4, 0 } )
   AAdd( aDbf, { "K2", "C",  4, 0 } )

   pos_cre_pom_dbf( aDbf )

   RETURN .T.


STATIC FUNCTION o_pom_table()

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )
   SET ORDER TO TAG "1"

   INDEX ON ( IdPos + IdRadnik + IdVrsteP + IdOdj + IdRoba + IdCijena ) TAG "1"
   INDEX ON ( IdPos + IdOdj + IdRoba + IdCijena ) TAG "2"
   INDEX ON ( IdPos + IdRoba + IdCijena ) TAG "3"
   INDEX ON ( IdPos + IdVrsteP ) TAG "4"
   INDEX ON ( IdPos + K1 + idroba ) TAG "K1"

   RETURN .T.
