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

MEMVAR gIdPos, dDatum0, dDatum1

FUNCTION realizacija_kase

   PARAMETERS dDatum0, dDatum1 // funkcije VarEdit zahtjevaju privatne varijable

   LOCAL xPrintOpt
   LOCAL bZagl
   LOCAL cVarijanta := "0"

   PRIVATE cRadnici := Space( 60 )
   PRIVATE cVrsteP := Space( 60 )
   PRIVATE cIdPos := gIdPos
   PRIVATE cRD

   PRIVATE aNiz
   PRIVATE aUsl1 := {}
   PRIVATE aUsl2 := {}
   PRIVATE fPrik := "O"
   PRIVATE cFilter := ".t."
   PRIVATE cSifraDob := Space( 8 )
   PRIVATE cPartId := Space( 8 )

   SET CURSOR ON

   IF ( dDatum0 == NIL )
      dDatum0 := danasnji_datum()
      dDatum1 := danasnji_datum()
   ENDIF


   pos_realizacija_tbl_cre_pom()
   o_pos_tables()
   o_pom_table()

   cPVrstePl := "N"
   cAPrometa := "N"
   cVrijOd := "00:00"
   cVrijDo := "23:59"


   IF pos_get_vars_izvjestaj_realizacija( @cIdPos, @dDatum0, @dDatum1, @cRD, @cVrijOd, @cVrijDo, @aUsl1, @aUsl2, @cVrsteP, @cAPrometa, @cSifraDob, @cPartId ) == 0
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


   bZagl := {|| pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cRadnici, cVrsteP ) }

   Eval( bZagl )

   o_pos_tables()
   o_pom_table()

   SELECT pos_doks

   pos_set_filter_pos_doks( @cFilter, aUsl1, aUsl2, cVrijOd, cVrijDo, cPartId )


   pos_kasa_pripremi_pom_za_izvjestaj( "01", cSifraDob )
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

   pos_pdv_po_tarifama( dDatum0, dDatum1, cIdPos, NIL )

   f18_end_print( NIL, xPrintOpt )
   my_close_all_dbf()

   RETURN .T.


STATIC FUNCTION pos_get_vars_izvjestaj_realizacija( cIdPos, dDatum0, dDatum1, cRD, cVrijOd, cVrijDo, aUsl1, aUsl2, cVrsteP, cAPrometa, cSifraDob, cPartId )

   LOCAL aNiz

   aNiz := {}
   cIdPos := gIdPos

   AAdd( aNiz, { "Prod. mjesto (prazno-sve)", "cIdPos", "cidpos='X'.or.EMPTY(cIdPos) .or. p_pos_kase(@cIdPos)", "@!", } )
   AAdd( aNiz, { "Radnici (prazno-svi)", "cRadnici",, "@!S30", } )
   AAdd( aNiz, { "Vrste plaćanja (prazno-sve)", "cVrsteP",, "@!S30", } )

   AAdd( aNiz, { "Izvještaj se pravi od datuma", "dDatum0",,, } )
   AAdd( aNiz, { "                   do datuma", "dDatum1",,, } )

   fPrik := "O"
   AAdd( aNiz, { "Prikazati Pazar/Robe/Oboje (P/R/O)?", "fPrik", "fPrik$'PRO'", "@!", } )
   cRD := "R"

   AAdd( aNiz, { "Po Radnicima/Odjeljenjima/oBoje (R/O/B)?", "cRD", "cRD$'ROB'", "@!", } )
   AAdd( aNiz, { "Prikazati pregled po vrstama plaćanja ?", "cPVrstePl", "cPVrstePl$'DN'", "@!", } )
   AAdd( aNiz, { "Vrijeme od", "cVrijOd",, "99:99", } )
   AAdd( aNiz, { "Vrijeme do", "cVrijDo", "cVrijDo>=cVrijOd", "99:99", } )

   AAdd( aNiz, { "Dobavljač (prazno-svi)", "cSifraDob", ".t.",, } )
   AAdd( aNiz, { "Partner (prazno-svi)", "cPartId", ".t.",, } )

   DO WHILE .T.

      IF !VarEdit( aNiz, 6, 5, 24, 74, "USLOVI ZA IZVJEŠTAJ: REALIZACIJA KASE-PRODAJNOG MJESTA", "B1" )
         CLOSE ALL
         RETURN 0
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


STATIC FUNCTION pos_zagl_realizacija( dDatum0, dDatum1, cIdPos, cRadnici, cVrsteP )

   IF Empty( cIdPos )
      ? "PRODAJNO MJESTO: SVA"
   ELSE
      ? "PRODAJNO MJESTO: " + cIdPos + "-" + find_pos_kasa_naz( cIdPos )
   ENDIF

   IF Empty( cRadnici )
      ? "RADNIK     :  SVI"
   ELSE
      ? "RADNIK     : " + cRadnici + "-" + RTrim( find_pos_osob_naziv( cRadnici ) )
   ENDIF

   IF Empty( cVrsteP )

      ?U "VR.PLAĆANJA: SVE"
   ELSE
      ?U "VR.PLAĆANJA: " + RTrim( cVrsteP )
   ENDIF

   ? "PERIOD     : " + FormDat1( dDatum0 ) + " - " + FormDat1( dDatum1 )

   RETURN .T.


STATIC FUNCTION pos_set_filter_pos_doks( cFilter, aUsl1, aUsl2, cVrijOd, cVrijDo, cPartId )

   SELECT pos_doks
   SET ORDER TO TAG "2"  // "2" - "IdVd+DTOS (Datum)"

   IF aUsl1 <> ".t."
      cFilter += ".and." + aUsl1
   ENDIF

   IF aUsl2 <> ".t."
      cFilter += ".and." + aUsl2
   ENDIF

   IF !( cVrijOd == "00:00" .AND. cVrijDo == "23:59" )
      cFilter += ".and. Vrijeme>='" + cVrijOd + "'.and. Vrijeme<='" + cVrijDo + "'"
   ENDIF


   IF !Empty( cPartId )
      cFilter += ".and. idPartner==" + dbf_quote( cPartId )
   ENDIF

   IF !( cFilter == ".t." )
      SET FILTER TO &cFilter
   ENDIF

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

      pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "-" )

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
            ? Space( 6 ) + PadL( pos_popust_prikaz(), 20 ) + Str( nTotRadn3, 14, 2 )
            ? Space( 6 ) + PadL( "UKUPNO NAPLATA:", 20 ) + Str( nTotRadn - nTotRadn3, 14, 2 )
         ENDIF
         ? Space( 6 ) + Replicate( "-", 34 )
         nTotPos += nTotRadn
         nTotPos3 += nTotRadn3
      ENDDO  // kasa
      ? Replicate( "-", 40 )
      ? PadC( "UKUPNO KASA " + _IdPos, 20 ) + Str( nTotPos, 20, 2 )

      IF nTotPos3 <> 0
         ? PadL( pos_popust_prikaz(), 20 ) + Str( nTotPos3, 20, 2 )
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

   IF fPrik $ "RO"
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


            nRobaIzn3 := 0
            DO WHILE !Eof() .AND. POM->IdPos + POM->IdRoba == _IdPos + _IdRoba

               nRobaKol += POM->Kolicina
               nRobaIzn += POM->Iznos
               nRobaIzn3 += POM->Iznos3

               SKIP
            ENDDO

            cStr2 := ""
            cStr2 += show_number( nRobaKol, NIL, - 8 )
            nLen2 := Len( cStr2 )

            cStr3 := show_number( nRobaIzn, PIC_UKUPNO )
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

            SELECT POM

            nTotPos += nRobaIzn
            nTotPos3 += nRobaIzn3
         ENDDO

         pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "-" )
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
   ? cLinija
   ? PadC( "REALIZACIJA PO ROBAMA", LEN_TRAKA )
   ? cLinija
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

   RETURN .T.


/* pos_realizacija_po_odjeljenjima(fPrik, nTotal3)
 *     Prikaz realizacije po odjeljenjima
 */

STATIC FUNCTION pos_realizacija_po_odjeljenjima( fPrik, nTotal3 )

   IF ( fPrik $ "PO" )
      // daj mi pazar
      ?
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

            SELECT POM
            DO WHILE !Eof() .AND. pom->IdPos == _IdPos
               nTotOdj += pom->Iznos
               nTotOdj3 += pom->Iznos3
               SKIP
            ENDDO
            ?? Transform( nTotOdj, "999,999.99" )
            nTotPos += nTotOdj
            nTotPos3 += nTotOdj3
         ENDDO
         pos_total_kasa( _IdPos, nTotPos, nTotPos3, 0, "-" )
         nTotal += nTotPos
         nTotal3 += nTotPos3
      ENDDO
      IF Empty( cIdPos )
         ? REPL( "=", LEN_TRAKA )
         ? PadC( "SVE KASE UKUPNO", 25 ) + Transform( nTotal, "999,999,999.99" )
         ? REPL( "=", LEN_TRAKA )
      ENDIF
   ENDIF

   IF fPrik $ "RO" // realizacija kase, po odjeljenjima, ROBNO
      nTotal := 0
      SELECT POM
      SET ORDER TO TAG "2"   // IdPos+IdRoba

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

            ? Replicate ( "-", LEN_TRAKA )
            ? "SIFRA    NAZIV", Space ( 19 ), "(JMJ)"
            ? Space( 10 ) + "Set c.  Kolicina    Vrijednost"
            ? Replicate( "-", LEN_TRAKA )
            nTotOdj := 0
            nTotOdj3 := 0
            nTotOdjK := 0
            SELECT POM
            DO WHILE !Eof() .AND. POM->IdPos == _IdPos
               _IdRoba := POM->IdRoba
               select_o_roba( _IdRoba )
               ? _IdRoba, Left( ROBA->Naz, 25 ), "(" + ROBA->Jmj + ")"
               _K2 := ""
               SELECT POM
               nRobaIzn := 0
               nRobaIzn2 := 0
               nRobaIzn3 := 0
               nRobaKol := 0
               nSetova := 0
               DO WHILE !Eof() .AND. pom->idPos + pom->IdRoba == _IdPos + _IdRoba

                  nKol := 0
                  nIzn := 0
                  nIzn3 := 0
                  DO WHILE !Eof() .AND. pom->IdPos + pom->IdRoba ==  _IdPos + _ + _IdRoba
                     nKol += POM->Kolicina
                     nIzn += POM->Iznos
                     nIzn3 += POM->Iznos3
                     SKIP
                  ENDDO
                  ? Space( 10 ) + Str( nKol, 10, 3 ) + Transform( nIzn, "999,999,999.99" )
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

            ? PadC( "UKUPNO", 26 )

            ?? Transform( nTotOdj, "999,999,999.99" )
            ? REPL( "-", LEN_TRAKA )
            ?
            nTotPos += nTotOdj
            nTotPosK += nTotOdjk
         ENDDO

         pos_total_kasa( _IdPos, nTotPos, nTotPos3, nTotPosk, "=" )
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



STATIC FUNCTION pos_total_kasa( cIdPos, nTotPos, nTotPos3, nTotPosk, cPodvuci )

   ? REPL( cPodvuci, LEN_TRAKA )
   ? PadC( "UKUPNO KASA " + _idpos, 25 ), Transform( nTotPos, "999,999,999.99" )

   IF nTotPos3 <> 0
      ? PadL( pos_popust_prikaz(), 25 ) + Str( nTotPos3, 15, 2 )
      ? PadL( "UKUPNO NAPLATA:", 25 ) + Str( nTotPos - nTotPos3 + nTotPos2, 15, 2 )
   ENDIF
   ? REPL( cPodvuci, LEN_TRAKA )
   ?

   RETURN .T.


STATIC FUNCTION pos_realizacija_tbl_cre_pom()

   LOCAL aDbf := {}

   AAdd( aDbf, { "IdPos", "C",  2, 0 } )
   AAdd( aDbf, { "IdRadnik", "C",  4, 0 } )
   AAdd( aDbf, { "IdVrsteP", "C",  2, 0 } )
   AAdd( aDbf, { "IdRoba", "C", 10, 0 } )
   AAdd( aDbf, { "Kolicina", "N", 12, 3 } )
   AAdd( aDbf, { "Iznos", "N", 20, 5 } )
   AAdd( aDbf, { "Iznos2", "N", 20, 5 } )
   AAdd( aDbf, { "Iznos3", "N", 20, 5 } )

   pos_cre_pom_dbf( aDbf )

   RETURN .T.


STATIC FUNCTION o_pom_table()

   SELECT ( F_POM )
   IF Used()
      USE
   ENDIF

   my_use_temp( "POM", my_home() + "pom", .F., .T. )
   SET ORDER TO TAG "1"

   INDEX ON ( IdPos + IdRadnik + IdVrsteP + IdRoba ) TAG "1"
   INDEX ON ( IdPos + IdRoba ) TAG "2"
   INDEX ON ( IdPos + IdVrsteP ) TAG "4"

   RETURN .T.
